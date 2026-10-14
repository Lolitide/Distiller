# Flutter OH Impeller 与 Skia 渲染引擎切换指南

本文说明如何在 Flutter OH 应用中通过配置文件切换 Impeller 与 Skia 渲染引擎。

---

## 1. 背景

当前 Flutter OH 支持 Impeller（Vulkan 后端）和 Skia 两种渲染模式，可通过配置文件控制是否开启 Impeller。

| 渲染引擎 | 支持版本 |
| ------------ | ---------------------- |
| **Impeller** | Flutter OH 3.22.0 以上 |
| **Skia**     | Flutter OH 3.7.12 以上 |

---

## 2. 配置文件位置

渲染模式通过项目 `ohos` 目录下的配置文件控制：`ohos/entry/src/main/resources/base/profile/buildinfo.json5`。

该文件是 Flutter OH 项目自动生成的渲染配置文件，包含 `enable_impeller` 字段。

---

## 3. 切换步骤

**步骤 1：** 启用 Impeller（默认模式）。编辑 `buildinfo.json5`，将 `enable_impeller` 的值设为 `"true"`：

```json5
{
  "string": [
    {
      "name": "enable_impeller",
      "value": "true"
    }
  ]
}
```

**步骤 2：** 切换为 Skia 渲染模式。编辑 `buildinfo.json5`，将 `enable_impeller` 的值设为 `"false"`：

```json5
{
  "string": [
    {
      "name": "enable_impeller",
      "value": "false"
    }
  ]
}
```

> **注意**：修改配置后需要重新构建项目才能生效，仅热重载（Hot Reload）不会切换渲染引擎。

### 工程初始化说明

新建工程默认开启 `Impeller`。对于旧工程，可将 `buildinfo.json5` 文件复制到工程目录的 `ohos/entry/src/main/resources/base/profile/` 路径下，并修改 `value` 值实现开关功能。如果不添加开关，则默认开启 `Impeller` 渲染模式。
