# 03 · OCR（图片文字识别）与 ASR（语音转文字）的约束、权限、模拟器支持与降级方案

> **取证目标环境**：HarmonyOS 6.0.2(22) 真机（手机）
> **本机 SDK**：HarmonyOS 26.0.0 Beta2
> **本机可用模拟器**：Pura 90 / HarmonyOS 6.1.1(24)、Pura X View / HarmonyOS 7.0.0 Beta2
> **取证日期口径**：以本机 `devecocli docs` 本地文档库 + 本机 SDK `.d.ts` 声明文件为准

---

## 0. 来源约定

### 0.1 SDK 声明文件根目录（下文路径均相对于此）

| 类别 | 绝对路径 |
| :-- | :-- |
| HMS | `D:\Coding\DevEco\DevEco Studio beta\DevEco Studio\sdk\default\hms\ets\api\` |
| HMS Kit 桶 | `D:\Coding\DevEco\DevEco Studio beta\DevEco Studio\sdk\default\hms\ets\kits\` |
| OpenHarmony | `D:\Coding\DevEco\DevEco Studio beta\DevEco Studio\sdk\default\openharmony\ets\api\` |

下文写作 `hms/ets/kits/@kit.CoreVisionKit.d.ts:9` 形式，即根目录 + 相对路径 + 行号。

### 0.2 文档库 documentId 写法

下文写作 `[documentId] 开发指南/Core_Vision_Kit_基础视觉服务/...`，可直接用于 `devecocli docs read '<documentId>'`。

### 0.3 关键 documentId 清单

| 简称 | documentId |
| :-- | :-- |
| 【CV简介】 | `开发指南/Core_Vision_Kit_基础视觉服务/Core_Vision_Kit简介/core-vision-introduction` |
| 【CV指南】 | `开发指南/Core_Vision_Kit_基础视觉服务/通用文字识别/core-vision-text-recognition` |
| 【CV API】 | `API参考/Core_Vision_Kit_基础视觉服务/ArkTS_API/textRecognition_文字识别/core-vision-text-recognition-api` |
| 【CV FAQ】 | `FAQ/机器学习/基础视觉_Core_Vision/图片文字识别方法及识别准确度优化/faqs-core-vision-3` |
| 【CS简介】 | `开发指南/Core_Speech_Kit_基础语音服务/Core_Speech_Kit简介/core-speech-introduction` |
| 【CS指南】 | `开发指南/Core_Speech_Kit_基础语音服务/语音识别/speechrecognizer-guide` |
| 【CS API】 | `API参考/Core_Speech_Kit_基础语音服务/ArkTS_API/speechRecognizer_语音识别/hms-ai-speechrecognizer` |
| 【NL简介】 | `开发指南/Natural_Language_Kit_自然语言理解服务/Natural_Language_Kit简介/natural-language-introduction` |
| 【NL指南】 | `开发指南/Natural_Language_Kit_自然语言理解服务/实体抽取/natural-language-getentity` |
| 【模拟器差异】 | `开发指南/使用模拟器运行应用/概述/模拟器与真机的差异/ide-emulator-specification` |
| 【模拟器FAQ】 | `FAQ/模拟器/模拟器_真机_预览器调试具有哪些差异/faqs-simulator-5` |
| 【模拟器扩展FAQ】 | `FAQ/模拟器/使用模拟器扩展能力的常见问题/faqs-simulator-8` |
| 【ArkData简介】 | `开发指南/ArkData_方舟数据管理/ArkData简介/data-mgmt-overview` |
| 【代理提醒】 | `开发指南/Background_Tasks_Kit_后台任务开发服务/代理提醒_ArkTS/agent-powered-reminder` |
| 【Share简介】 | `开发指南/Share_Kit_分享服务/Share_Kit简介/share-introduction` |
| 【通知简介】 | `开发指南/Notification_Kit_用户通知服务/Notification_Kit简介/notification-overview` |
| 【AudioCapturer指南】 | `开发指南/Audio_Kit_音频服务/音频录制/使用AudioCapturer开发音频录制功能_ArkTS/using-audiocapturer-for-recording` |

---

## 1. 图片文字识别（Core Vision Kit / `@hms.ai.ocr.textRecognition`）

### 1.1 是否支持模拟器 —— **不支持**

【CV简介】末节原文（`#### 模拟器支持情况` 小节）：

> #### 模拟器支持情况
>
> 本Kit暂不支持模拟器。

**结论**：Core Vision Kit **整体**在模拟器上不可用（文字识别、人脸检测、人脸比对、主体分割、多目标识别、骨骼点检测、图像超分同属该 Kit）。本项目两个模拟器（6.1.1(24) / 7.0.0 Beta2）与 API 版本无关，**均不可用**。

**失败形态**（【模拟器差异】「Kit能力差异」节给出通用报错模板）：

> 如遇到因Kit能力不支持导致的应用闪退问题，可以尝试使用[动态引入Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-dynamic-import#动态import实现方案介绍)的方式规避此异常问题。
>
> Kit不支持导致的报错信息如：
>
> `LastFatalMessage:[default] [LoadJSPandaFile:00] resolveBufferCallback get hsp buffer failed，hsp path:/data/storage/el1/bundle/com.huawei.hmos.{KitName}.kit`

> 即：**若在模拟器上以静态 import 引入 `@kit.CoreVisionKit`，应用会在加载 Kit HSP 时直接闪退**，而不是抛一个可 catch 的 `BusinessError`。这是《知了》在模拟器上跑 P1 链路必须处理的第一个坑。

### 1.2 权限与 Kit 授权

| 项目 | 结论 | 来源 |
| :-- | :-- | :-- |
| 系统能力（SysCap） | `SystemCapability.AI.OCR.TextRecognition` | `hms/ets/api/@hms.ai.ocr.textRecognition.d.ts:31`；【CV API】 |
| 需要 `ohos.permission.*` | **未取证到任何权限声明**。【CV指南】「开发步骤」全文只 import 了 `@kit.CoreVisionKit` / `@kit.BasicServicesKit` / `@kit.CoreFileKit` / `@kit.MediaLibraryKit`，`module.json5` 的 `requestPermissions` 段落中未出现任何权限 | 【CV指南】开发步骤 1 |
| 是否需要申请「开放能力」 | **未取证**。本地文档库在 Core Vision Kit 全部相关文档中未出现「开放能力」「AGC 申请」「签名证书」「Profile」等前置申请步骤；SDK 侧也无 `@permission` 标签 | — |

**间接证据（可作工程参考，非官方明文）**：官方示例经 `photoAccessHelper.PhotoViewPicker`（系统图库**选择器**）取图，选择器属于「临时授权」路径，因此不触发 `ohos.permission.READ_IMAGEVIDEO`。这一点是**从官方示例零权限声明反推**，不是文档明文。

### 1.3 输入必须是 RGBA_8888 的 `PixelMap` —— 官方标准路径

**输入类型约束**（SDK 原文）：

> `hms/ets/api/@hms.ai.ocr.textRecognition.d.ts:59-62`
>
> ```
> Visual information to be recognized. Currently, only the visual information of the
> PixelMap type in color data format RGBA_8888 is supported.
> ```

```ts
// hms/ets/api/@hms.ai.ocr.textRecognition.d.ts:68-80
export interface VisionInfo {
    readonly pixelMap: image.PixelMap;   // :79
}
```

中文文档同义表述（【CV API】`#### VisionInfo`）：

> 待识别的视觉信息，目前仅支持颜色数据格式为RGBA_8888的PixelMap类型的视觉信息。

**标准获取路径（官方开发步骤 3，【CV指南】）**：

```
图库选择器 → URI → fileIo.open(fd) → image.createImageSource(fd) → createPixelMap() → VisionInfo.pixelMap
```

官方原文关键行：

> 3. 通过`photoAccessHelper.PhotoViewPicker`拉起图库选择图片，使用`fileIo`与`image`模块将URI转换为[PixelMap](...)，为后续识别接口准备输入数据。

```ts
// 【CV指南】开发步骤 1：import
import { textRecognition } from '@kit.CoreVisionKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

// 【CV指南】开发步骤 2：初始化 / 释放（aboutToAppear / aboutToDisappear）
async aboutToAppear(): Promise<void> {
  const initResult = await textRecognition.init();   // 加载模型
}
// aboutToDisappear 中调用 textRecognition.release()

// 【CV指南】开发步骤 3：图库选图 → PixelMap
private async openPhoto(): Promise<string> {
  return new Promise<string>((resolve) => {
    let photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
    photoPicker.select({
      MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
      maxSelectNumber: 1
    }).then((res: photoAccessHelper.PhotoSelectResult) => {
      resolve(res.photoUris[0]);
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'OCRDemo', `Failed to get photo image uri. code: ${err.code}, message: ${err.message}`);
      resolve('');
    });
  });
}

// 使用 fileIo + image 把 URI 转 PixelMap
setTimeout(async () => {
  let fileSource = await fileIo.open(name, fileIo.OpenMode.READ_ONLY);
  this.imageSource = image.createImageSource(fileSource.fd);
  this.chooseImage = await this.imageSource.createPixelMap();
  await fileIo.close(fileSource);
}, 100);

// 【CV指南】开发步骤 4：构造 VisionInfo 并识别
let visionInfo: textRecognition.VisionInfo = {
  pixelMap: this.chooseImage
};
let textConfiguration: textRecognition.TextRecognitionConfiguration = {
  isDirectionDetectionSupported: false
};
let recognitionResult = await textRecognition.recognizeText(visionInfo, textConfiguration);
```

**「分享进来的图片」注意事项（未取证）**：本地文档库未给出「从 Share Kit 接收的 `sharedData` URI 直接转 `PixelMap`」的官方示例。已取证的通用做法是先把 URI 落到应用沙箱（`fileIo`），再走 `createImageSource(fd)`。此路径可行但**无官方明文**，标为「架构推断」。

### 1.4 语言支持与中文识别质量

**支持语言（五种）**，两处一致：

> 【CV API】开头：目前本服务支持识别的语言有：简体中文、英文、日文、韩文、繁体中文五种语言。
>
> 【CV简介】能力限制表：支持的语言：简体中文、英文、日文、韩文、繁体中文。

SDK 英文原文（`hms/ets/api/@hms.ai.ocr.textRecognition.d.ts:26-27`）：

> `Currently, this service can recognize simplified Chinese, English, Japanese, Korean, and traditional Chinese.`

**`getSupportedLanguages()` 返回什么** —— 返回语言标签字符串数组（【CV API】`#### 语言类型列表`）：

| 语言（英） | 语言（中） |
| :-- | :-- |
| `zh-CN` | 简体中文 |
| `en` | 英文 |
| `ja` | 日文 |
| `ko` | 韩文 |
| `zh-TW` | 繁体中文 |

```ts
// hms/ets/api/@hms.ai.ocr.textRecognition.d.ts:273 / :286
function getSupportedLanguages(): Promise<Array<string>>;
function getSupportedLanguages(callback: AsyncCallback<Array<string>>): void;
```

| 项 | 值 | 来源 |
| :-- | :-- | :-- |
| 两个重载 @since | `4.0.0(10)` | d.ts:271 / :284 |
| 错误码 | `1001400001` Failed to run, please try again. / `1001400002` The service is abnormal. | 【CV API】 |
| 系统能力 / 模型约束 | `SystemCapability.AI.OCR.TextRecognition` / `@stagemodelonly` | d.ts:282-283 |

**中文识别质量官方说明**：【CV FAQ】给出的准确度优化建议原文（逐条）：

> - 输入图像具有合适的成像质量（建议720p以上）和高宽比例（建议2:1以下，接近手机屏幕高宽比例为宜）。
> - 文本与拍摄角度夹角在正负30度范围内。
> - 使用高动态范围模式（如[DynamicRangeMode.HIGH](...)）提升图像细节，减少过曝或欠曝导致的文字模糊。
> - 在Image组件中设置[enableAnalyzer(true)](...)属性，激活系统自带的智能文本分析与图像处理能力。
> - 通过优化像素格式，提升图像解析清晰度。
> - 对识别结果中的数字部分进行正则匹配，自动纠正小数点位置。

> ⚠️ **两处数值冲突**：【CV FAQ】建议「高宽比例建议 **2:1** 以下」，而【CV简介】能力限制表写「高宽比例建议 **10:1** 以下」。以 Kit 简介（更权威、更宽松）的 **10:1** 为硬约束，FAQ 的 2:1 视为更保守的经验值。

【CV FAQ】另有一条否证性结论：

> Q：textRecognition可以支持中英日韩繁的文字识别，还有可以支持更多语种的OCR能力吗？或者是否有支持HarmonyOS的第三方库？
>
> A：textRecognition目前不支持其他语种，可使用其他平台文字识别SDK或Tesseract OCR等第三方能力。

### 1.5 一次能识别多大图片 / 尺寸与耗时限值

【CV简介】`#### 约束与限制` → `能力限制` 表「文字识别」行原文：

> - 支持的图片格式：JPEG、JPG、PNG。
> - 支持的语言：简体中文、英文、日文、韩文、繁体中文。
> - 文本长度：不超过10000字符。
> - 支持文档印刷体识别，在识别手写字体方面能力有所欠缺。
> - 输入图像具有合适成像的质量（建议720p以上），100px<高度<15210px，100px<宽度<10000px，高宽比例建议10:1以下（高度小于宽度的10倍），接近手机屏幕高宽比例为宜。
> - 拍摄角度与文本所在平面垂直方向的夹角应小于30度。

**耗时限值**：**未取证到官方数值**（无「超时 N 秒」类明文）。文档中唯一与超时相关的信号是错误码：

> `hms/ets/api/@hms.ai.ocr.textRecognition.d.ts` / 【CV API】错误码表
>
> | 错误码ID | 错误信息 |
> | :-- | :-- |
> | 200 | Run timed out, please try again later. |
> | 401 | The parameter check failed. |
> | 1001400001 | Failed to run, please try again. |
> | 1001400002 | The service is abnormal. |

**并发限制**（【CV简介】，同一段落也出现在【NL简介】）：

> Core Vision Kit的特性支持多用户同时接入，但是不支持同一用户并发调用同一个特性，如同一个特性被同一进程同一时间多次调用，则返回系统繁忙错误，不同进程调用同一特性，则同一时间只有一个进程业务在处理，其他进程进入队列排队。

> ⚠️ 对《知了》的含义：**OCR 必须串行调用**。批量识别多张截图时必须排队，否则会收到「系统繁忙」错误（该错误码在 API 参考的错误码表中未单列，属未取证）。

**适用设备与地域**（【CV简介】）：

> #### \[h2\] 支持的设备
>
> Phone、Tablet、PC/2in1。
>
> #### \[h2\] 支持的国家/地区
>
> 仅适用于中国境内（香港特别行政区、澳门特别行政区、中国台湾除外）。

### 1.6 OCR 相关 SDK 版本与模型约束速查

| 接口 / 类型 | @since | @stagemodelonly | @syscap | 来源 |
| :-- | :-- | :-- | :-- | :-- |
| `declare namespace textRecognition` | `4.0.0(10)` | ✅ | `SystemCapability.AI.OCR.TextRecognition` | `hms/ets/api/@hms.ai.ocr.textRecognition.d.ts:31-35` |
| `TextRecognitionConfiguration` | `4.0.0(10)` | ✅ | 同上 | d.ts:39-43 |
| `isDirectionDetectionSupported?: boolean`（`@default true`） | `4.0.0(10)` | ✅ | 同上 | d.ts:52-57 |
| `VisionInfo` | `4.0.0(10)` | ✅ | 同上 | d.ts:64-68 |
| `readonly pixelMap: image.PixelMap` | `4.0.0(10)` | ✅ | 同上 | d.ts:75-79 |
| `recognizeText(visionInfo, callback)` | `4.0.0(10)` | ✅ | 同上 | 【CV API】 |
| `recognizeText(visionInfo, configuration?)` → `Promise` | `4.0.0(10)` | ✅ | 同上 | d.ts:239-243 |
| `recognizeText(visionInfo, configuration, callback)` | `4.0.0(10)` | ✅ | 同上 | d.ts:256-260 |
| `getSupportedLanguages()` 两重载 | `4.0.0(10)` | ✅ | 同上 | d.ts:269-286 |
| `init()` / `release()` | `5.0.0(12)` | ✅ | 同上 | d.ts:292-303 区段；【CV API】 |

---

## 2. 语音转文字（Core Speech Kit / `@hms.ai.speechRecognizer`）

### 2.1 是否支持模拟器 —— **支持（自 6.0.0(20) 起）**

【CS简介】末节原文：

> #### 模拟器支持情况
>
> 本Kit能力从6.0.0(20)版本开始支持模拟器。
>
> 模拟器与真机存在通用差异，详情请参见“[模拟器与真机的差异](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-emulator-specification)”。

**结论**：本项目两个模拟器 API 版本（**6.1.1(24)**、**7.0.0 Beta2**）**均 ≥ 6.0.0(20)**，因此 Core Speech Kit **在模拟器上具备官方支持**。

> ⚠️ **但需保留一条实测风险**：【模拟器差异】「其他差异」表把**麦克风**列入硬件依赖项：
>
> > 摄像头/麦克风 | 依赖电脑设备，不支持多摄像头切换（广角/长焦）、闪光灯、降噪算法等
>
> 也就是说 Kit 级「支持模拟器」并不等价于「模拟器麦克风可用」。若走 `recognitionMode: 0`（引擎实时录音），需在模拟器上**实测**；若实测不可用，退到「本地 pcm 文件 + `writeAudio`」路径（该路径完全不依赖麦克风，见 2.4）。**该风险为推断，官方未给出文字结论，标为未取证。**

### 2.2 是否支持 `online: 1`（离线）与 `zh-CN` —— **两者都支持，且只支持离线**

SDK 命名空间首段（`hms/ets/api/@hms.ai.speechRecognizer.d.ts:10-12`）：

> ```
> This module converts speech into text so that users can interact with their devices in real time through speech.
>
> Currently, this service is available only in Chinese and supports only the offline model.
> ```

```ts
// hms/ets/api/@hms.ai.speechRecognizer.d.ts:263-304
export interface CreateEngineParams {
    language: string;                    // :271
    online: number;                      // :281
    extraParams?: Record<string, Object>;// :303
}
```

| 字段 | SDK 原文注释（英文） | 中文文档（【CS API】） |
| :-- | :-- | :-- |
| `language`（:264-271） | `Language. Currently, only **zh-CN** is supported.` | 语种，当前仅支持“zh-CN”中文。 |
| `online`（:272-281） | `Mode. **1**: offline. Currently, only the offline mode is supported.` | 模式。1为离线，当前仅支持离线模式。 |
| `extraParams['locate']`（:283-286） | `Optional. If this parameter is not set, the default value **CN** will be used. Currently, only **CN** is supported.` | 可选，不设置时默认为“CN”，当前仅支持“CN”。 |
| `extraParams['recognizerMode']`（:288-291） | `Optional. If this parameter is not set, the default value **short** will be used. Currently, **short** and **long** are supported.` | 可选，不设置时默认为“short”，当前支持“short”和“long”。 |
| `extraParams['sysGeneralLexicon']`（:293-297） | `Optional. This parameter is empty by default when it is not set. You can configure up to **200** hotwords, each of which contains **2 to 20** characters.` | 系统热词。支持配置热词提高识别率。系统热词针对应用，在整个识别过程中都生效。 |

官方 createEngine 示例原文（【CS API】）：

```ts
// 设置创建引擎参数
let extraParams: Record<string, Object> = { 'locate': 'CN', 'recognizerMode': 'short' };
let initParamsInfo: speechRecognizer.CreateEngineParams = {
  language: 'zh-CN',
  online: 1,
  extraParams: extraParams
};
// 调用createEngine方法
```

> ⚠️ **`sysGeneralLexicon` 是校园场景的关键优化点**：可配置最多 200 个热词、每个 2–20 字（SDK 明文）。把「知了」「教务处」「一卡通」「学分绩点」等校名词加进热词可提升识别率。热词上限 200 / 单条 2–20 字为**官方数字**。

### 2.3 权限：`MICROPHONE` 需要；`INTERNET` **未取证**

| 权限 | 结论 | 依据 |
| :-- | :-- | :-- |
| `ohos.permission.MICROPHONE` | **需要**（实时录音识别路径） | ①【CS API】`StartParams.extraParams['recognitionMode']` 说明原文：「0：实时录音识别（需应用开启录音权限：ohos.permission.MICROPHONE）」；②【CS指南】步骤 10 原文：「需要在[module.json5配置文件](...)中添加`ohos.permission.MICROPHONE`权限，确保麦克风使用正常。」；③ 错误码 `1002200012` 没有获取麦克风权限 |
| `ohos.permission.INTERNET` | **未取证**。对【CS指南】与【CS API】全文检索 `INTERNET` **零命中**；且文档反复声明「当前仅支持离线模式」，无联网识别路径。**本地文档库中不存在要求 `INTERNET` 的依据** | 【CS指南】【CS API】 |

【CS指南】步骤 10 给出的 `module.json5` 声明原文：

```json5
'requestPermissions': [
  {
    'name': 'ohos.permission.MICROPHONE',
    'reason': '$string:reason',
    'usedScene': {
      'abilities': [
        'EntryAbility'
      ],
      // when: 'inuse'（官方用于前台/后台场景区分）
    }
  }
]
```

运行时申请（【CS指南】）：

```ts
let atManager = abilityAccessCtrl.createAtManager();
atManager.requestPermissionsFromUser(this.context, ['ohos.permission.MICROPHONE']).then((data) => {
  hilog.info(0x0000, 'testTag', 'data:' + JSON.stringify(data));
  hilog.info(0x0000, 'testTag', 'data permissions:' + data.permissions);
  hilog.info(0x0000, 'testTag', 'data authResults:' + data.authResults);
}).catch((err: BusinessError) => {
  // ...
});
```

### 2.4 录音侧用什么 —— 官方指南**没有给 AudioCapturer 示例**

这是本次取证里最需要澄清的一点。

**【CS指南】实际给出的音频输入方式只有两条，且都不是 `AudioCapturer`**：

> 5. 传入音频流，调用`writeAudio`方法，开始写入音频流。读取音频文件时，开发者需预先准备一个pcm格式音频文件。
>
> ```ts
> let uint8Array: Uint8Array = new Uint8Array();
> // 可以通过如下方式获取音频流：1、通过录音获取音频流；2、从音频文件中读取音频流
> // 写入音频流，音频流长度仅支持640或1280
> asrEngine?.writeAudio(sessionId, uint8Array);
> ```
>
> 1. 如需通过录音获取音频流，请打开麦克风权限，参考步骤10配置相关权限。
> 2. 如需从音频文件中读取音频流，请在项目中的 `main\resources\resfile` 路径下存放pcm文件。

官方随附的采集工具是 **`FileCapturer.ets`（读本地 pcm 文件）**，不是 AudioCapturer：

```ts
// 【CS指南】FileCapturer.ets
import { fileIo } from '@kit.CoreFileKit';
const TAG = 'FileCapturer';
const SEND_SIZE: number = 1280;   // ← 与「音频流长度仅支持640或1280」对应

export default class FileCapturer {
  // 循环 fileIo.readSync，每片回调给上层 writeAudio
}
```

调用侧（【CS指南】）：

```ts
let filePath: string = ctx.resourceDir + '/' + filenames[0];
(this.mFileCapturer as FileCapturer).setFilePath(filePath);
this.mFileCapturer.init((dataBuffer: ArrayBuffer) => {
  data = dataBuffer;
  let uint8Array: Uint8Array = new Uint8Array(data);
  asrEngine?.writeAudio(this.sessionId2, uint8Array);
});
await this.mFileCapturer.start();
asrEngine?.finish(this.sessionId);
this.mFileCapturer.release();
```

**确切参数要求（这是唯一的硬约束来源）** —— `AudioInfo`（SDK 原文 + 中文文档）：

```ts
// hms/ets/api/@hms.ai.speechRecognizer.d.ts:383-429
export interface AudioInfo {
    audioType: string;     // :393
    sampleRate: number;    // :403
    soundChannel: number;  // :413
    sampleBit: number;     // :423
}
```

| 字段 | 中文文档原句（【CS API】） | SDK 英文原句（行号） |
| :-- | :-- | :-- |
| `audioType` | `pcm` | `Only **pcm** is supported currently.`（:386-387） |
| `sampleRate` | 音频的采样率。当前仅支持 **16000** 采样率。 | `Currently, only **16000** is supported.`（:395-397） |
| `soundChannel` | 音频返回的通道数信息。当前仅支持通道 **1**。 | `Currently, only channel **1** is supported.`（:405-407） |
| `sampleBit` | 音频返回的采样位数。当前仅支持 **16** 位。 | `Currently, only **16** is supported.`（:415-417） |

官方 `StartParams` 示例原文（【CS API】）：

```ts
let recognizerParams: speechRecognizer.StartParams = {
  sessionId: '123456',
  audioInfo: { audioType: 'pcm', sampleRate: 16000, soundChannel: 1, sampleBit: 16 }
};
```

**若项目自行用 `AudioCapturer` 采集，应如何配置** —— 这是**官方两套文档未打通的地方**：

- 【AudioCapturer指南】给出的官方示例是 **48000 / 双声道**，与 Core Speech Kit 要求**不一致**：

```ts
// 【AudioCapturer指南】官方示例（注意：不是16000/单声道）
let audioStreamInfo: audio.AudioStreamInfo = {
  samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_48000, // 采样率。
  channels: audio.AudioChannel.CHANNEL_2,                  // 通道。
  sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 采样格式。
  encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW  // 编码格式。
};
let audioCapturerInfo: audio.AudioCapturerInfo = {
  source: audio.SourceType.SOURCE_TYPE_MIC, // 音源类型:Mic音频源。根据业务场景配置,参考SourceType。
};
```

- 要对齐 Core Speech Kit，需改成下列枚举值（枚举存在于本机 SDK，行号已核）：

```ts
// 组合目标：pcm / 16000 / 单声道 / 16bit
let audioStreamInfo: audio.AudioStreamInfo = {
  samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,   // openharmony/ets/api/@ohos.multimedia.audio.d.ts:1074
  channels: audio.AudioChannel.CHANNEL_1,                    // 同文件:937
  sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 同文件:890
  encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW    // 同文件:1187
};
```

> **取证边界说明**：上述 `AudioCapturer` 配置组合是**依据两侧枚举定义对齐而来**（Core Speech Kit 的 `AudioInfo` 硬约束 + `@ohos.multimedia.audio` 的枚举定义），**不是官方文档中的一份现成示例**。官方文档中**不存在**「AudioCapturer + speechRecognizer」的联合示例 —— 这一点是明确的未取证项。

**更省事的官方路径**：`recognitionMode: 0` 时由**引擎自己录音**，应用侧不必写 `AudioCapturer`，只需 `MICROPHONE` 权限。见下节。

### 2.5 时长上限与 `recognizerMode` / `recognitionMode`

**注意：这是两个不同的参数，容易混淆。**

| 参数 | 位置 | 语义 | 取值 |
| :-- | :-- | :-- | :-- |
| `recognizerMode` | `CreateEngineParams.extraParams` | **语言/语音模式**（`short`/`long`） | 可选，不设置时默认为 `short`，当前支持 `short` 和 `long` |
| `recognitionMode` | `StartParams.extraParams` | **识别模式**（是否由引擎录音） | 0 / 1 |

**`recognitionMode` 官方原文（【CS API】`StartParams.extraParams`）**：

> - `<‘recognitionMode’, number>` 实时语音识别模式。
>
>   0：实时录音识别（需应用开启录音权限：`ohos.permission.MICROPHONE`），若需结束录音，则调用`finish`或者`cancel`方法；
>
>   1：实时音频转文字识别，开启此模式时需要额外调用`writeAudio`方法，传入待识别音频流；
>
>   可选，不传参时默认为1。

官方 `StartParams` 完整示例（【CS API】）：

```ts
let recognizerOption: RecognizerOption = {'enablePartialResult': false};
let extraParam: Record<string, Object> = {
  'recognitionMode': 0,
  'vadBegin': 2000,
  'vadEnd': 3000,
  'maxAudioDuration': 20000,
  'srcType': 1,
  'recognizerOption': recognizerOption
};
let recognizerParams: speechRecognizer.StartParams = {
  sessionId: '123456',
  audioInfo: { audioType: 'pcm', sampleRate: 16000, soundChannel: 1, sampleBit: 16 },
  extraParams: extraParam
};
```

**时长相关约束（逐条原文）**：

| 约束 | 原文 | 来源 |
| :-- | :-- | :-- |
| `maxAudioDuration` | 「最大支持音频时长，不传参时默认20000ms。短语音模式支持范围\[20000-60000\]，单位ms。长语音模式支持范围\[20000 - 8 \* 60 \* 60 \* 1000\]，单位ms。」 | 【CS API】 |
| VAD 静音检测 | 「可选，不传参时，短语音默认为**800ms**支持配置，长语音默认为**500ms**不支持配置。」 | 【CS API】 |
| Kit 级时长 | 「语音时长：短语音模式不超过**60s**，长语音模式不超过**8h**。」 | 【CS简介】能力限制表「语音识别」行 |
| `writeAudio` 分片 | 「写入音频流，音频流长度仅支持**640**或**1280**」 | 【CS指南】步骤 5 |

> **数值自洽性核对**：`maxAudioDuration` 短语音上限 60000ms = 60s，与【CS简介】「短语音模式不超过60s」一致；长语音上限 8\*60\*60\*1000ms = 8h，与「长语音模式不超过8h」一致。✅

**是否需要 `recognizerMode`**：**不是必填**。不设置时默认为 `short`（【CS API】原文）。只有需要长语音（单次 > 60s，最长 8h）时才必须显式设为 `'long'`，并同步把 `maxAudioDuration` 提到 > 60000ms。

### 2.6 ASR 相关 SDK 版本与模型约束速查

| 接口 / 类型 | @since | @stagemodelonly | @syscap | 来源 |
| :-- | :-- | :-- | :-- | :-- |
| `declare namespace speechRecognizer` | `4.1.0(11)` | ✅ | `SystemCapability.AI.SpeechRecognizer` | `hms/ets/api/@hms.ai.speechRecognizer.d.ts:16-20` |
| `createEngine(params, callback)` | `4.1.0(11)` | ✅ | 同上 | d.ts:31-35 |
| `createEngine(params)` → `Promise` | `4.1.0(11)` | ✅ | 同上 | d.ts:46-50 |
| `SpeechRecognitionEngine` | `4.1.0(11)` | ✅ | 同上 | d.ts:57-61 |
| `CreateEngineParams` | `4.1.0(11)` | ✅ | 同上 | d.ts:259-263 |
| `LanguageQuery` | `4.1.0(11)` | ✅ | 同上 | d.ts:309-313 |
| `AudioInfo` | `4.1.0(11)` | ✅ | 同上 | d.ts:379-383 |

**createEngine 错误码**（SDK `@throws` 原文，d.ts:27-30 / :42-45）：

| 错误码 | 含义 |
| :-- | :-- |
| `1002200001` | Create engine failed.（语种不支持、模式不支持、初始化超时、资源不存在等） |
| `1002200006` | The engine of SpeechRecognition is busy. |
| `1002200008` | The engine of SpeechRecognition is being destroyed. |
| `1002200009` | Internal Service Error. `[since 5.1.0(18)]` |

**其它错误码**（【CS API】）：`1002200011` 语音识别异常 / `1002200012` 没有获取麦克风权限。

**数据隐私（官方 FAQ 原文）**：

> Q：Core Speech Kit 语音识别会上传数据吗？
>
> A：Core Speech Kit语音识别的数据是不会保存到华为服务器上的。Core Speech Kit语音识别是在用户手机上处理的，HarmonyOS侧不会保存处理结果到华为服务器的，即使没有网络也是可以使用该能力的。

> 来源：`FAQ/机器学习/基础语音_Core_Speech/实时语音识别与音频文件识别的功能实现/faqs-core-speech-4`

---

## 3. 模拟器能力总览（逐项官方原文）

> **取原文的方法**：各 Kit 简介文档末尾均有 `#### 模拟器支持情况` 小节；【模拟器差异】「Kit能力差异」节明确指路 ——
>
> > 当前部分Kit在模拟器上使用时，和真机存在差异，具体请参考对应Kit简介。

### 3.1 逐项对照表

| # | Kit / 能力 | 官方「模拟器支持情况」原文 | documentId |
| :-- | :-- | :-- | :-- |
| 1 | **Natural Language Kit 实体抽取** | 「该能力当前不支持模拟器。」（能力页 约束与限制 节）<br>「本Kit暂不支持模拟器。」（Kit 简介 模拟器支持情况 节） | 【NL指南】<br>【NL简介】 |
| 2 | **Core Vision Kit 文字识别** | 「本Kit暂不支持模拟器。」 | 【CV简介】 |
| 3 | **Core Speech Kit 语音识别** | 「本Kit能力从6.0.0(20)版本开始支持模拟器。」 | 【CS简介】 |
| 4 | **Background Tasks Kit 代理提醒** | 「从API version 20开始，本能力支持模拟器开发。」 | 【代理提醒】 |
| 5 | **Share Kit 分享接收** | 「本Kit支持模拟器。」 | 【Share简介】 |
| 6 | **ArkData（relationalStore / preferences）** | 「本Kit支持模拟器，但与真机存在部分能力差异，具体差异如下。」<br>「KV-Store只支持在模拟器使用本地数据库增删改查能力，其余能力不支持。」<br>「RelationalStore只支持在模拟器使用本地数据库增删改查能力，其余能力不支持。」<br>「DataObject端端能力依赖接续框架，当前接续框架在模拟器上只支持手机。」 | 【ArkData简介】 |
| 7 | **Notification Kit 通知** | 「本Kit支持模拟器。」 | 【通知简介】 |

### 3.2 逐项核实说明

**① Natural Language Kit 实体抽取 —— 不支持（已核实）**

【NL指南】`#### 约束与限制` 节原文：

> #### 约束与限制
>
> 该能力当前不支持模拟器。
>
> | AI能力 | 约束 |
> | :-- | :-- |
> | 实体抽取 | - 支持的语言：简体中文、英文、繁体中文。 |

【NL简介】末节：

> #### 模拟器支持情况
>
> 本Kit暂不支持模拟器。

【NL简介】另有与 Core Vision Kit 完全同款的并发限制段：

> Natural Language Kit的特性支持多用户同时接入，但是不支持同一用户并发调用同一个特性，如同一个特性被同一进程同一时间多次调用，则返回系统繁忙错误，不同进程调用同一特性，则同一时间只有一个进程业务在处理，其他进程进入队列排队。

**② Core Vision Kit 文字识别 —— 不支持**（原文见 §1.1）

**③ Core Speech Kit 语音识别 —— 支持，门槛 6.0.0(20)**（原文见 §2.1）
→ 本机两模拟器（6.1.1(24) / 7.0.0 Beta2）**均在门槛之上**。

**④ Background Tasks Kit 代理提醒 —— 已核实，原文确认**：

> #### 模拟器支持情况
>
> 从API version 20开始，本能力支持模拟器开发。

→ 用户给定信息「从API version 20开始，本能力支持模拟器开发」**核实为真**，且是本机文档的**逐字原文**。
→ 对《知了》：目标环境 6.0.2(22) ≥ 20，**代理提醒在真机与模拟器上均可用**。

**⑤ Share Kit 分享接收 —— 支持（已核实）**

> #### 模拟器支持情况
>
> 本Kit支持模拟器。
>
> 模拟器与真机存在通用差异，详情请参见“[模拟器与真机的差异](...)”。

**⑥ ArkData（关系型数据库 / 首选项）—— 支持，但能力被裁剪（已核实）**

【ArkData简介】原文：

> #### 模拟器支持情况
>
> 本Kit支持模拟器，但与真机存在部分能力差异，具体差异如下。
>
> - 通用差异：请参见[模拟器与真机的差异](...)。
> - KV-Store只支持在模拟器使用本地数据库增删改查能力，其余能力不支持。
> - RelationalStore只支持在模拟器使用本地数据库增删改查能力，其余能力不支持。
> - DataObject端端能力依赖接续框架，当前接续框架在模拟器上只支持手机。

**补充取证**：

- 【`data-persistence-by-rdb-store`】《通过关系型数据库实现数据持久化(ArkTS)》**全文检索「模拟器」零命中** → 该指南**没有** `#### 模拟器支持情况` 小节，模拟器口径只存在于 Kit 级（【ArkData简介】）。
- 【`data-persistence-by-preferences`】《通过用户首选项实现数据持久化(ArkTS)》**全文检索「模拟器」零命中**；【`js-apis-data-preferences`】API 参考同样零命中。
- 【ArkData简介】的差异清单**只点名了 KV-Store / RelationalStore / DataObject，未点名 Preferences** → 推断 Preferences 属「支持模拟器」的默认情形。**「Preferences 在模拟器上的具体差异」为未取证项**。

**对《知了》的结论**：本地数据库增删改查在模拟器上可用 → **DAO/Repository 层可以在模拟器上完整开发与联调**；受影响的是跨设备同步、端云同步、DataShare 静默访问、端端接续等「其余能力」。

**⑦ Notification Kit 通知 —— 支持（已核实）**

> #### 模拟器支持情况
>
> 本Kit支持模拟器。
>
> 模拟器与真机存在通用差异，详情请参见“[模拟器与真机的差异](...)”。

### 3.3 模拟器通用差异（横向约束，影响所有 Kit）

【模拟器差异】给出的与 AI/媒体链路相关的条目：

| 维度 | 官方原文 |
| :-- | :-- |
| 图形接口 | 不支持 OpenGL ES 3.1、3.2；Vulkan 在 DevEco Studio 6.1.0 Beta2 之前不支持，自 6.1.0 Beta2 起支持除 `vkGetSwapchainGrallocUsageOHOS`、`vkAcquireImageOHOS`、`vkQueueSignalReleaseImageOHOS` 之外的接口 |
| 多媒体 | 「模拟器不支持heif格式的图片。」「视频播放：模拟器仅支持h264文件格式，并且是RGBA像素格式的视频文件。」「模拟器不支持视频录制/转码/处理、屏幕录像。」 |
| NPU | 「部分AI相关Kit暂不支持，详情参考[AI Kit简介](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hmaf-introduction)」 |
| 摄像头/麦克风 | 「依赖电脑设备，不支持多摄像头切换（广角/长焦）、闪光灯、降噪算法等」 |
| 生物识别 / 电源 / SIM卡 / USB / 蓝牙 / 星闪 / NFC / TEE | 均列为模拟器不支持或受限 |

【模拟器FAQ】补充：

> - 模拟器不支持屏幕亮度调节。
> - 模拟器暂不支持 root。
> - 模拟器暂不支持通过连接WiFi访问互联网，模拟器上网实际走的是以太网，跟电脑共享同一网络。
> - 手机模拟器不支持浏览器和应用市场。
> - 预览器暂不支持深色模式。
> - 目前HarmonyOS 5及以上应用/元服务仅支持单机调试场景。（单机调试：申请单台设备进行调试，用于调试应用在指定机型上的表现。）

---

## 4. 降级方案：无真机时官方推荐怎么做

### 4.1 路径一：云调试（官方 FAQ 明文首推）

【模拟器FAQ】原文：

> 官方文档模拟器与真机的差异清楚的描述了模拟器对各种Kit的支持情况，开发者在无真机或者模拟器不具备支持能力的情况时可以使用[云调试](https://developer.huawei.com/consumer/cn/agconnect/cloud-adjust?ha_source=sousuo&ha_sourceId=89000251)。

同一 FAQ 中多次重复该建议（高德 SDK 定位、Wallet Kit、手机模拟器缺浏览器）：

> Q：手机模拟器里面能否使用浏览器之类的搜索功能，或者通过应用市场之类的安装应用？
>
> A：手机模拟器不支持浏览器和应用市场，若场景需要可以使用真机或者[云调试](...)。

**约束**：

> 目前HarmonyOS 5及以上应用/元服务仅支持单机调试场景。

→ **云调试 = 单台设备单机调试**，不能做多设备协同场景验证。

相关 FAQ documentId（供进一步排查）：`FAQ/应用调试/云调试应用安装失败常见问题排查与解决方案/faqs-app-debugging-80`、`FAQ/应用调试/云调试应用期间出现黑屏如何处理/faqs-app-debugging-79`。

### 4.2 路径二：动态引入 Kit（官方明文，用于避免闪退）

【模拟器差异】「Kit能力差异」节原文：

> 如遇到因Kit能力不支持导致的应用闪退问题，可以尝试使用[动态引入Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-dynamic-import#动态import实现方案介绍)的方式规避此异常问题。

→ 这是官方对「Kit 不支持导致闪退」的**唯一明文规避手段**，也是《知了》在模拟器上跑 P1/P2 的必备架构约束：**`@kit.CoreVisionKit` 与（若需兼容低版本）`@kit.CoreSpeechKit` 必须走动态 `import()`，且 `catch` 后进入降级分支**，不能静态 import。

### 4.3 路径三：预览器（仅 UI，限制很多）

【模拟器FAQ】原文：

> 使用预览器进行调试不支持以下场景：
>
> - 不支持Attach调试。
> - 不支持跨Ability调试。
> - 不支持C++调试。
> - 不支持Hot Reload。
> - 不支持多进程和worker/taskpool调试。

其他限制：

> - 预览不支持引用HSP。引用了HSP的模块不支持预览，需要直接在HSP内预览或模拟HSP。
> - 预览器暂不支持深色模式，请使用模拟器或真机进行测试。
> - 预览器不支持页面自动旋转，预览器页面上提供了orientation按钮，可以点击该按钮切换设备的横竖屏状态。
> - Inspector双向预览：@Entry装饰器装饰的组件支持Inspector，@Preview不支持。

【模拟器差异】补充预览器定位：

> DevEco Studio预览器：预览器的主要目的是提供快速的代码修改和界面预览，它可能不会进行完整的编译和安装过程，因此在某些情况下，预览器中运行的代码可能与在模拟器或真机上运行的结果不完全一致。

### 4.4 「本地模拟 / 假数据」的官方做法 —— **未取证到**

| 待查项 | 结论 |
| :-- | :-- |
| OCR 是否有官方 mock / 假数据注入开关 | **未取证**。本地文档库中对 Core Vision Kit 全部文档、DevEco 模拟器相关文档均未出现 |
| ASR 是否有官方 mock / 假数据注入开关 | **未取证**。同上 |
| DevEco 是否有「模拟 Kit 能力」的开关 | **未取证**。可查到的模拟器侧配置入口只有性能相关：修改 `...\Emulator\deployed\lists.json` 的 `cpuNumber`、`...\Emulator\deployed\{EmulatorName}\config.ini` 的 `hw.cpu.ncore`（改 CPU 核心数），以及创建模拟器时设定较小 RAM 来模拟低内存环境 |
| 官方是否提供离线假数据机制 | 无明文。**唯一可用的官方机制是「动态引入 Kit + 自建降级分支」** —— 即官方把「能力缺失时该怎么办」交给应用自己实现 |

**间接可用的官方做法（用于 P2 语音链路）**：【CS指南】步骤 5 明文支持**从本地 pcm 文件读取音频流**：

> 2. 如需从音频文件中读取音频流，请在项目中的`main\resources\resfile`路径下存放pcm文件。

→ 这是官方**明文认可**的「不依赖麦克风的确定性输入」路径。在没有真机、且模拟器麦克风可用性存疑时，**用 `resfile` 里的 pcm 样音驱动完整 ASR 链路**是官方支持的演示方案（`recognitionMode: 1` + `writeAudio` + `FileCapturer`）。**这是本次取证中唯一可直接落地的「无真机演示」官方做法。**

**对《知了》的工程建议（属工程判断，非官方）**：

1. `OcrService` / `AsrService` 抽象为接口，实现分 `RealImpl`（动态 import Kit）/ `FakeImpl`（返回预置文本）两支，按 `canIUse('SystemCapability.AI.OCR.TextRecognition')` 或动态 import 成败切换。
2. 模拟器上验证 UI/状态机/持久化，真机（或云调试）上验证 OCR/ASR 真实输出。
3. P1 的演示可用「预置截图 + FakeImpl」保证流程可走通；P2 的演示用 `resfile` pcm + 真实 `speechRecognizer` —— 后者在 6.1.1(24) 模拟器上有官方支持依据。

---

## 5. Kit 桶导出：`@since` 与 `@stagemodelonly` 核实

### 5.1 `@kit.CoreVisionKit`

```ts
// hms/ets/kits/@kit.CoreVisionKit.d.ts
/**
 * @file Defines the capabilities of core vision kit.
 * @kit CoreVisionKit
 * @since 4.1.0(11)          // ← :7
 */
import textRecognition from '@hms.ai.ocr.textRecognition';   // :9
// ... 其余 8 个能力
export { visionBase, textRecognition, faceDetector, faceComparator, subjectSegmentation,
         objectDetection, skeletonDetection, imageSuperResolution, textSearchImage };  // :18
```

| 项 | 值 |
| :-- | :-- |
| 桶文件 `@since` | **`4.1.0(11)`**（`@kit.CoreVisionKit.d.ts:7`） |
| 桶文件 `@stagemodelonly` | **无该标签** |
| 内部模块 `textRecognition` 的 `@since` | **`4.0.0(10)`**（`hms/ets/api/@hms.ai.ocr.textRecognition.d.ts:33`），**早于桶文件** |

> ⚠️ **版本号陷阱**：Kit 桶的 `@since`（4.1.0）**不等于** 能力的 `@since`（4.0.0）。`textRecognition` 是 4.0.0 引入、4.1.0 起才被 `@kit.CoreVisionKit` 统一导出。以**模块 d.ts 的 `@since` 为准**判断设备兼容性。

### 5.2 `@kit.CoreSpeechKit`

```ts
// hms/ets/kits/@kit.CoreSpeechKit.d.ts
/**
 * @file Defines the capabilities of core speech kit.
 * @kit CoreSpeechKit
 * @since 4.1.0(11)          // ← :7
 */
import speechRecognizer from '@hms.ai.speechRecognizer';   // :9
import textToSpeech from '@hms.ai.textToSpeech';           // :10
export { speechRecognizer, textToSpeech };                 // :11
```

| 项 | 值 |
| :-- | :-- |
| 桶文件 `@since` | **`4.1.0(11)`** |
| 桶文件 `@stagemodelonly` | **无该标签** |
| 内部模块 `speechRecognizer` 的 `@since` | **`4.1.0(11)`**（`hms/ets/api/@hms.ai.speechRecognizer.d.ts:18`）—— 与桶一致 |

### 5.3 `@kit.NaturalLanguageKit`

```ts
// hms/ets/kits/@kit.NaturalLanguageKit.d.ts
/**
 * @file Defines the capabilities of NaturalLanguage kit.
 * @kit NaturalLanguageKit
 * @since 5.0.0(12)          // ← :7
 */
import { EntityType } from '@hms.ai.nlp.textProcessing';   // :9
import textProcessing from '@hms.ai.nlp.textProcessing';   // :10
export { textProcessing, EntityType };                     // :11
```

| 项 | 值 |
| :-- | :-- |
| 桶文件 `@since` | **`5.0.0(12)`** |
| 桶文件 `@stagemodelonly` | **无该标签** |
| 内部模块 `textProcessing` 的 `@since` | **`5.0.0(12)`**（`hms/ets/api/@hms.ai.nlp.textProcessing.d.ts:14`）—— 与桶一致 |

### 5.4 `@stagemodelonly` 的正确理解

| 层级 | 是否带 `@stagemodelonly` | 证据 |
| :-- | :-- | :-- |
| Kit 桶文件（`@kit.*.d.ts`） | **否**（三个文件均无） | `@kit.CoreVisionKit.d.ts` 全文 / `@kit.CoreSpeechKit.d.ts` 全文 / `@kit.NaturalLanguageKit.d.ts` 全文 |
| 模块命名空间（`declare namespace ...`） | **是** | `@hms.ai.ocr.textRecognition.d.ts:32`、`@hms.ai.speechRecognizer.d.ts:17`、`@hms.ai.nlp.textProcessing.d.ts:13` |
| 各接口 / 各成员 | **是**（逐条重复标注） | 如 `@hms.ai.ocr.textRecognition.d.ts:40,54,65,76,...` |

中文文档对应表述（使用「**模型约束**」这个词，而非「stagemodelonly」）：

> **模型约束：** 此接口仅可在Stage模型下使用。

→ 来源：【CV API】【CS API】每个接口条目下。**结论：三个 Kit 的全部 API 均仅支持 Stage 模型**，FA/类 Web 模型不可用。

### 5.5 apiVersion 26 中的新变化

在 `hms/ets/api/@hms.ai.nlp.textProcessing.d.ts` 中发现一处 **`@since 26.0.0`** 的新增声明（本机 SDK 为 26.0.0 Beta2）：

```ts
// hms/ets/api/@hms.ai.nlp.textProcessing.d.ts:24-44
export interface EntityConfig {
    entityTypes?: EntityType[];   // :34, @since 5.0.0(12)

    /**
     * Reference timestamp.
     * The value is an integer.
     *
     * @syscap SystemCapability.AI.NaturalLanguage.TextProcessing
     * @stagemodelonly
     * @since 26.0.0              // ← :41
     */
    timestamp?: number;           // :43
}
```

> **含义**：`EntityConfig` 在 API 26 新增了可选字段 `timestamp`（参考时间戳，整数），用于时间类实体抽取的相对时间解析。
>
> ⚠️ **与目标环境冲突**：该字段 `@since 26.0.0`，而《知了》目标环境是 **HarmonyOS 6.0.2(22)** —— **不可使用**。另外 Natural Language Kit 实体抽取在模拟器上本就不支持（§3.2①）。
>
> Core Vision Kit / Core Speech Kit 的模块 d.ts 在 apiVersion 26 中**未见新增 `@since 26.0.0` 的成员**（`@hms.ai.ocr.textRecognition.d.ts` / `@hms.ai.speechRecognizer.d.ts` 中除 `1002200009 [since 5.1.0(18)]` 外无更高版本标记）。

---

## 6. 未取证清单（明确标注，禁止据此编码）

| # | 未取证项 | 检索范围 |
| :-- | :-- | :-- |
| 1 | OCR 是否需要申请「开放能力」（AGC 侧） | Core Vision Kit 全部本地文档 + SDK d.ts 无相关表述 |
| 2 | OCR 单次识别的**耗时限值**（秒数） | 仅有错误码 `200 Run timed out`，无官方数值 |
| 3 | OCR 的 `SystemCapability.AI.OCR.TextRecognition` 与「开放能力」申请的关系 | 同上 |
| 4 | 从 **Share Kit 接收的 sharedData URI** 直接转 `PixelMap` 的官方路径 | 无官方示例（已取证的通用做法见 §1.3） |
| 5 | ASR 是否需要 `ohos.permission.INTERNET` | 【CS指南】【CS API】全文检索 `INTERNET` **零命中**；文档反复声明仅支持离线模式 |
| 6 | `AudioCapturer` + `speechRecognizer` 的**官方联合示例** | 官方文档中不存在；参数对齐依据为枚举定义（§2.4） |
| 7 | 模拟器**麦克风**对 Core Speech Kit `recognitionMode: 0` 的实际可用性 | Kit 级「支持模拟器」与硬件级「麦克风依赖电脑设备」并存，官方无文字结论 → **需实测** |
| 8 | **Preferences（首选项）** 在模拟器上的具体差异 | 【ArkData简介】差异清单只点名 KV-Store / RelationalStore / DataObject |
| 9 | OCR / ASR 的官方 **mock / 假数据** 开发开关 | 全部本地文档零命中 |
| 10 | 「系统繁忙」错误（并发调用同一特性时返回）的**确切错误码** | 【CV API】错误码表未单列 |
| 11 | `@kit.CoreVisionKit` 桶文件是否隐含 `@stagemodelonly` | 桶文件无标签；但其所导出的每个模块均有 → 实质等价，措辞上不确定 |

---

## 7. 对《知了》P1 / P2 的落地结论（依据上文的工程判断）

> 以下为**基于已取证事实的工程结论**，非官方原文。

| 项 | 结论 | 支撑事实 |
| :-- | :-- | :-- |
| P1 图片文字识别在模拟器上能否跑通 | **不能**。必须走动态 import + 降级分支，否则静态 import 直接闪退 | 【CV简介】「本Kit暂不支持模拟器」；【模拟器差异】Kit 缺失报错模板 `resolveBufferCallback get hsp buffer failed` |
| P1 的真机可用性 | **可用**。目标 6.0.2(22) ≥ 4.0.0(10)（模块级）；输入须为 RGBA_8888 `PixelMap`；中文（zh-CN）在支持列表内 | d.ts:33 / :59-79；【CV API】语言类型列表 |
| P2 语音转文字在模拟器上能否跑通 | **有官方支持依据**（6.1.1(24) / 7.0.0 Beta2 均 ≥ 6.0.0(20)）。麦克风路径需实测；`resfile` pcm 路径**无需麦克风**，是官方明文的确定性方案 | 【CS简介】模拟器支持情况；【CS指南】步骤 5 第 2 条 |
| P2 的引擎参数（照抄即可） | `language: 'zh-CN'`、`online: 1`、`locate: 'CN'`、`recognizerMode: 'short'`；`audioInfo: { audioType: 'pcm', sampleRate: 16000, soundChannel: 1, sampleBit: 16 }` | d.ts:264-297 / :383-423 |
| P2 的时长规划 | 单次 ≤ 60s 用默认 `short`；更长必须显式 `recognizerMode: 'long'` + `maxAudioDuration` > 60000（长语音上限 8h） | 【CS简介】能力限制表；【CS API】`maxAudioDuration` |
| P2 的校园场景优化 | 用 `sysGeneralLexicon` 注入校名/术语热词，**上限 200 条、每条 2–20 字** | d.ts:293-297 |
| P2 的权限声明 | `module.json5` 仅需 `ohos.permission.MICROPHONE`（`INTERNET` 无取证依据，当前离线模式也无需联网） | 【CS指南】步骤 10；【CS API】 |
| P2 的音频采集 | 优先 `recognitionMode: 0`（引擎自采，省掉 AudioCapturer）；若自采须按 `SAMPLE_RATE_16000` / `CHANNEL_1` / `SAMPLE_FORMAT_S16LE` / `ENCODING_TYPE_RAW` 对齐，`writeAudio` 分片长度 **640 或 1280** | 【CS API】`recognitionMode`；【CS指南】步骤 5；`@ohos.multimedia.audio.d.ts:890/937/1074/1187` |
| 代理提醒 | 真机与模拟器均可用（6.0.2(22) ≥ 20） | 【代理提醒】模拟器支持情况 |
| 本地持久化 | 模拟器上 RDB/Preferences 增删改查可用，跨设备/端云同步不可用 | 【ArkData简介】模拟器支持情况 |
| 通知 | 真机与模拟器均可用 | 【通知简介】模拟器支持情况 |
| 分享接收 | 真机与模拟器均可用 | 【Share简介】模拟器支持情况 |
| 实体抽取 | 模拟器不可用；且 API 26 新增的 `timestamp` 字段在目标 6.0.2(22) 上**不可用** | 【NL指南】【NL简介】；`@hms.ai.nlp.textProcessing.d.ts:41` |
