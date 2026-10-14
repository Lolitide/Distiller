# 外接纹理问题定位指南

> 返回 [README.md](README.md)

---

## 1. 什么是外接纹理？

### 1.1 通俗解释

外接纹理（External Texture）是一种让原生侧（视频播放器、相机、动画等）把画面"喂"给 Flutter 显示的机制。

> **打个比方**：想象一条"画面传送带"：
> - **生产者**（视频播放器/相机）把画面一帧一帧放到传送带上
> - **消费者**（Flutter 引擎）从传送带上取画面，画到屏幕上
>
> 如果传送带出了问题（生产太快消费不过来、生产者停了、消费者卡了），画面就会黑屏、卡顿或冻结。

### 1.2 什么场景会用到外接纹理？

| 场景 | 生产者 | 典型问题 |
|------|--------|---------|
| 视频播放 | 视频播放器插件 | 画面黑屏/卡顿 |
| 相机预览 | 相机插件 | 预览画面不更新 |
| 动画播放 | 动画插件 | 动画卡顿 |
| WebView | WebView 插件 | 画面不更新 |
| 直播 | 直播 SDK | 画面延迟/卡顿 |

### 1.3 问题类型速查

| 你看到的现象 | 可能的原因 | 去看哪一节 |
|-------------|-----------|-----------|
| 视频/相机画面黑屏 | 纹理创建失败 / 生产者没产出帧 | §5 |
| 画面第一帧后不更新 | 帧闸门开启 / Surface 销毁 / onInactive 被误触发 | §6, §7 |
| 画面卡顿/丢帧 | 消费过慢 / 跳帧 | §8 |
| 画面拉伸/变形 | 尺寸变更未收敛 | §9 |
| 应用闪退 | 纹理释放后还在访问 | §10 |
| 退后台后还在耗电 | 可见区域监控未启用 | §7 |

---

## 2. 外接纹理架构

### 2.1 画面传送带模型

```
原生生产者               Flutter 消费者
(视频/相机/动画)          (Raster 线程)
      │                       │
      │  把画面写入窗口       │  从窗口取出画面
      ▼                       ▼
┌─────────────────────────────────────┐
│      OH_NativeImage 缓冲队列          │
│     (画面传送带)                      │
└─────────────────────────────────────┘
      │                       │
      │  "新画面来了!"          │  生成 GPU 图像
      ▼                       ▼
  通知 Flutter 重绘         画到屏幕上
```

| 角色 | 通俗理解 | 实现类 |
|------|---------|--------|
| 生产者 | 把画面放到传送带上的人 | 原生侧通过 surfaceId 获取窗口写入 |
| 消费者 | 从传送带取画面画到屏幕的人 | `OHOSExternalTexture`（Raster 线程） |
| 传送带 | 中间的缓冲队列 | `OH_NativeImage` BufferQueue |

### 2.2 两种渲染后端

| 后端 | 什么时候用 | 通俗解释 |
|------|-----------|---------|
| OpenGL ES | `RenderingApi = kOpenGLES` | 用 GL 纹理显示画面 |
| Vulkan (Impeller) | `RenderingApi = kImpellerVulkan` | 用 Vulkan 信号量同步画面 |

> 注册时会输出 `RegisterExternalTexture api type <N> texture_id <id>`，`N` 就是渲染后端编号。

### 2.3 开发者 API

如果你是插件开发者，通过 `TextureRegistry` 使用外接纹理：

| 方法 | 作用 | 什么时候用 |
|------|------|-----------|
| `registerTexture(id)` | 注册纹理，返回 surfaceId | 创建视频/相机纹理时 |
| `registerPixelMap(pixelMap)` | 注册静态图片纹理 | 显示一张图片 |
| `unregisterTexture(id)` | 注销纹理 | 不再需要时（**先停生产者再注销！**） |
| `setTextureBufferSize(id,w,h)` | 设置生产者窗口尺寸 | 画面尺寸变化时 |
| `setExternalNativeImagePtr(id,img)` | 替换为外部 NativeImage | 高级用法 |

---

## 3. 纹理生命周期

### 3.1 注册流程（创建传送带）

```
registerTexture(textureId)
│
├─ 创建 OH_NativeImage（创建传送带）
│  ├─ 成功 → 继续
│  └─ 失败 → 日志 "OH_NativeImage_Create() failed"
│
├─ 获取 NativeWindow（获取传送带入口）
│  ├─ 成功 → 继续
│  └─ 失败 → 日志 "OH_NativeImage_AcquireNativeWindow() failed"
│
├─ 获取 surfaceId（给生产者用的地址）
│  └─ 失败 → 日志 "OH_NativeImage_GetSurfaceId() failed"
│
└─ 注册到引擎
   → 日志 "RegisterExternalTexture api type N texture_id X"
```

**成功的日志**：
```
I Flutter:  RegisterExternalTexture api type 2 texture_id 1
I Flutter: OH_NativeImage_AcquireNativeWindow() success
I Flutter: OH_NativeImage_GetSurfaceId() success, surfaceId = 12345678
```

### 3.2 注销流程（拆除传送带）

> **顺序很重要！** 必须先停生产者，再注销纹理。否则生产者还在往已拆除的传送带上放东西，会崩溃。

```
✅ 正确顺序：
1. 停止生产者（暂停视频/相机）
2. 调用 unregisterTexture

❌ 错误顺序：
1. 调用 unregisterTexture（传送带拆了）
2. 生产者还在写入 → 崩溃！
```

---

## 4. 帧调度（传送带怎么运转）

### 4.1 帧序号机制

引擎用两个计数器跟踪画面的生产和消费：

| 计数器 | 通俗理解 | 含义 |
|--------|---------|------|
| `now_new_frame_seq_num` | "生产了多少帧" | 生产者产出的帧数 |
| `now_paint_frame_seq_num` | "画了多少帧" | 消费者已绘制的帧数 |

如果"生产的"远大于"画了的"，说明消费跟不上，引擎会**主动跳帧**（丢掉一些旧画面，只画最新的），保证实时性。

### 4.2 跳帧策略

| 缓冲队列大小 | 跳帧阈值 | 通俗解释 |
|------------|---------|---------|
| ≤ 5 | size - 1 | 普通场景，保留 1 个缓冲 |
| > 5 | size * 2/3 | 视频/相机场景，保留更多缓冲 |

**跳帧日志**：
```
I Flutter: external_texture skip one frame(slow consumer): ... buffer_queue_size 5 max_jank_frame 4
I Flutter: MarkNewFrameAvailable avail-seq 120 paint-seq 100 texture_id 1
```

> `skip one frame(slow consumer)` = 消费太慢了，跳过了一些帧

---

## 5. 纹理黑屏/不显示

### 5.1 排查流程

```
画面黑屏
│
├─ 搜索 "RegisterExternalTexture api type"
│  └─ 没搜到 → 纹理根本没注册，检查 registerTexture 调用
│
├─ 搜索 "OH_NativeImage_Create() failed"
│  └─ 搜到了 → 创建失败，检查系统资源
│
├─ 搜索 "OH_NativeImage_GetSurfaceId() failed"
│  └─ 搜到了 → surfaceId 获取失败，纹理没真正注册
│
├─ 搜索 "No DlImage available"
│  └─ 搜到了 → 传送带上没有画面（生产者没产出帧）
│     ├─ 检查原生侧是否已向 surfaceId 写入数据
│     └─ 检查 Texture 控件的 size 是否为 0
│
└─ 检查渲染后端是否匹配
```

### 5.2 常见原因和修复方法

| 原因 | 通俗解释 | 怎么修 |
|------|---------|--------|
| 纹理未注册 | 压根没调用 `registerTexture` | 检查注册代码 |
| NativeImage 创建失败 | 系统资源不足 | 检查系统资源 |
| 生产者没产出帧 | 视频还没开始播放 / 相机没启动 | 确保生产者已开始写入 |
| Texture 控件 size 为 0 | 画面区域是 0x0 | 检查 Widget 布局 |
| surfaceId 不对 | 生产者写入了错误的 surfaceId | 确认 surfaceId 传递正确 |

---

## 6. 帧闸门（Frame Gate）

### 6.1 通俗解释

当应用退到后台时，引擎会开启"帧闸门"——**继续排空传送带上的画面（防止生产者阻塞），但不再调度重绘**（反正用户看不到）。

> **打个比方**：就像快递柜——你退后台后快递还在往柜子里放（排空队列），但你不取快递了（不渲染）。回前台后恢复正常取件。

### 6.2 状态切换

| 时机 | 帧闸门状态 | 日志 |
|------|-----------|------|
| 退后台 | 开启（不渲染但排空） | `frame gate enabled, drain-only for texture X` |
| 回前台 | 关闭（恢复正常） | `ExecuteReclaimRestore - restoring foreground state` |

### 6.3 排查"纹理不更新"

如果纹理在后台回前台后不更新：

1. 搜索 `frame gate enabled` → 确认帧闸门是否仍开启
2. 搜索 `ExecuteReclaimRestore` → 确认是否已恢复
3. 搜索 `Surface REBUILT` → 确认 Surface 重建是否成功
4. 搜索 `NotifyDestroyed` → 确认 Surface 是否已销毁

---

## 7. 可见区域监控

### 7.1 通俗解释

3.35 版本新增了"可见区域监控"功能。当 PlatformView（嵌入 Flutter 的原生组件）不可见时，可以**自动暂停**纹理的生产（比如暂停视频/动画），避免不可见时的无效耗电。

> **打个比方**：就像你走开不看 TV 时，TV 自动暂停播放。

### 7.2 怎么启用？

默认是**关闭**的（`enable=false`），插件需要重写 `getPlatformViewVisibleAreaEventOptions()` 来开启：

```typescript
// 在你的 PlatformView 子类中重写
getPlatformViewVisibleAreaEventOptions(): PlatformViewVisibleAreaEventOptions {
  return {
    enable: true,                              // 开启监控
    ratios: [0.0, 1.0],                        // 可见比例阈值
    expectedUpdateInterval: 1000,              // 期望回调间隔（毫秒）
    onInactiveThreshold: 0.0,                  // 可见比例 ≤ 此值时触发 onInactive()（暂停）
    onActiveThreshold: 1.0,                    // 可见比例 ≥ 此值时触发 onActive()（恢复）
  } as PlatformViewVisibleAreaEventOptions;
}

// 暂停纹理生产（比如暂停视频）
onInactive(): void {
  this.videoPlayer?.pause();
}

// 恢复纹理生产
onActive(): void {
  this.videoPlayer?.play();
}
```

### 7.3 关键日志

```
I Flutter: setPlatformViewVisibleAreaEventCallback surfaceId:12345, enable:true
I Flutter: PlatformViewVisibleAreaEventCallback surfaceId:12345, isExpanding:false, currentRatio:0
```

| 日志 | 含义 |
|------|------|
| `isExpanding:false, currentRatio:0` | 不可见了，触发 `onInactive()`（暂停） |
| `isExpanding:true, currentRatio:1` | 完全可见，触发 `onActive()`（恢复） |

---

## 8. 纹理卡顿/丢帧

### 8.1 排查流程

```
画面卡顿
│
├─ 搜索 "skip one frame(slow consumer)"
│  └─ 搜到了 → 消费过慢，引擎在跳帧
│     ├─ 检查 Raster 线程是否被其他任务阻塞
│     └─ 检查 buffer_queue_size 是否过小
│
├─ 搜索 "MarkNewFrameAvailable avail-seq"
│  ├─ avail-seq 不增长 → 生产者没产出帧
│  └─ avail-seq 增长但 paint-seq 不增长 → Raster 线程卡了
│
├─ 搜索 "GpuReclaim"
│  └─ 搜到了 → GPU 回收导致中断（详见 dfx-memory.md）
│
└─ 搜索 "get error buffer queue size"
   └─ 搜到了 → 缓冲队列异常（>100）
```

---

## 9. 画面拉伸/变形

### 9.1 排查

搜索 `size change` 相关日志：

| 日志 | 含义 |
|------|------|
| `size change took N frames` | 尺寸变更在 N 帧内完成（正常） |
| `stop size change state: frame > 10` | 尺寸变更超过 10 帧（异常） |
| `direct release size changed buffer` | 缓冲尺寸变了但绘制区域没变（防拉伸） |

**修复**：确保 `setTextureBufferSize` 和 `notifyTextureResizing` 调用一致。

---

## 10. 纹理访问崩溃

### 10.1 通俗解释

就像你把快递箱扔了，但还有人去箱子里拿东西——当然会出问题。

**常见原因**：
1. `unregisterTexture` 后原生侧还在写入 surfaceId
2. 外部 NativeImage 被提前释放
3. GPU 上下文销毁后还引用 GPU 资源

**修复**：**先停生产者，再注销纹理**：
```typescript
// ✅ 正确顺序
stopProducer();                              // 先停
textureRegistry.unregisterTexture(textureId); // 后注销
```

> 详见 [dfx-crash.md](dfx-crash.md) §2.6 场景 2。

---

## 11. 日志关键字速查表

| 搜索这个关键字 | 含义 | 严重程度 |
|--------------|------|---------|
| `RegisterExternalTexture api type` | 纹理注册 | — |
| `OH_NativeImage_Create() failed` | 创建失败 | 高 |
| `No DlImage available` | 无可绘制画面（黑屏） | 中 |
| `frame gate enabled, drain-only` | 后台帧闸门开启 | 正常 |
| `skip one frame(slow consumer)` | 消费过慢跳帧 | 中 |
| `MarkNewFrameAvailable avail-seq` | 帧序号监控 | — |
| `OnGrContextCreated texture_id` | GPU 上下文重建 | — |
| `size change took N frames` | 尺寸变更完成 | 正常 |
| `PlatformViewVisibleAreaEventCallback` | 可见区域变化 | — |
| `UnRegisterExternalTexture` | 纹理注销 | — |
| `~OHOSExternalTexture` | 纹理析构 | — |

---

## 12. 排查清单

### 黑屏/不显示

- [ ] 搜索 `RegisterExternalTexture` 确认纹理已注册
- [ ] 搜索 `OH_NativeImage_Create() failed` 确认创建成功
- [ ] 搜索 `No DlImage available` 确认是否有画面
- [ ] 检查原生侧是否已向 surfaceId 写入数据
- [ ] 检查 Texture 控件 size 是否为 0

### 不更新

- [ ] 搜索 `frame gate enabled` 确认帧闸门状态
- [ ] 搜索 `NotifyDestroyed` 确认 Surface 是否存活
- [ ] 搜索 `OnGrContextCreated/Destroyed` 确认 GPU 上下文
- [ ] 搜索 `PlatformViewVisibleAreaEventCallback` 确认是否被 `onInactive` 暂停

### 卡顿

- [ ] 搜索 `skip one frame` 确认跳帧类型
- [ ] 搜索 `MarkNewFrameAvailable avail-seq` 对比生产/消费序号
- [ ] 搜索 `GpuReclaim` 确认是否伴随 GPU 回收

### 后台行为

- [ ] 搜索 `frame gate enabled` 确认帧闸门开启
- [ ] 搜索 `ExecuteReclaimRestore` 确认回前台后恢复
- [ ] 检查 `onInactive/onActive` 是否实现
