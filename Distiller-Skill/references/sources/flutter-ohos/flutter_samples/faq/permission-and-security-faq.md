# Flutter OH 原生侧权限申请说明

Flutter OH 应用在调用某些系统功能时（如网络、相机、定位、存储等），需要在 ohos 原生侧声明对应权限。若未正确申请权限，可能导致 API 调用失败或应用崩溃。

<a id="section695847"></a>

## 权限声明位置

**现象：**

需要为 Flutter OH 应用声明系统权限。

**原因：**

调用网络、相机、定位、存储等系统能力时，必须在 ohos 原生侧声明对应权限，否则 API 调用失败或应用崩溃。

**解决方案：**

在 `ohos/entry/src/main/module.json5` 文件的 `module` 内配置 `requestPermissions` 声明权限：

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet"
    ],
    "pages": "$profile:main_pages",
    // 权限声明在此处
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

配置权限之后，需要重新签名：

File → Project Structure → Project → Signing Configs

---

<a id="section482915"></a>

## flutter 输入框长按无法粘贴

**现象：**

flutter 输入框长按无法粘贴。

**原因：**

应用未申请剪贴板权限 `ohos.permission.READ_PASTEBOARD`。

**解决方案：**

申请剪贴板权限：

```json5
"requestPermissions": [
  {
    "name": "ohos.permission.READ_PASTEBOARD",
    "reason": "$string:EntryAbility_desc",
    "usedScene": {
      "abilities": [
        "EntryAbility"
      ],
      "when": "inuse"
    }
  }
]
```

---

<a id="section613728"></a>

## flutter 无法保存图片到相册

**现象：**

flutter 无法保存图片到相册。

**原因：**

应用未申请保存图片权限 `ohos.permission.WRITE_IMAGEVIDEO`。

**解决方案：**

申请保存图片权限：

```json5
"requestPermissions": [
  {
    "name": "ohos.permission.WRITE_IMAGEVIDEO",
    "reason": "$string:EntryAbility_desc",
    "usedScene": {
      "abilities": [
        "EntryAbility"
      ],
      "when": "inuse"
    }
  }
]
```

---

<a id="section731204"></a>

## flutter 播放音频退到后台后停止

**现象：**

flutter 应用在前台播放音频正常，退到后台后音频停止播放。

**原因：**

应用未申请后台运行权限 `ohos.permission.KEEP_BACKGROUND_RUNNING`，且未声明音频后台模式。系统会将未声明音频后台模式的后台应用挂起，音频随进程冻结而停止。

**解决方案：**

在 `module.json5` 中声明权限与音频后台模式：

```json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.KEEP_BACKGROUND_RUNNING"
      }
    ],
    "abilities": [
      {
        "name": "EntryAbility",
        "backgroundModes": [
          "audioPlayback"
        ]
      }
    ]
  }
}
```

---

<a id="section954780"></a>

## 功能与权限对照表

**现象：**

需要根据功能场景确定应申请的权限。

**原因：**

不同功能对应不同权限与授权方式，需对照申请以避免遗漏。

**解决方案：**

开发 Flutter OH 应用时，请根据功能场景，在 ohos 原生侧申请对应权限：

> 表格仅列出常用权限，更多权限请参考 [应用权限列表](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-permissions)

| 功能场景             | 所需权限                                                     | 授权方式 |
| :------------------- | :----------------------------------------------------------- | :------- |
| **网络请求**         | `ohos.permission.INTERNET`                                   | 系统授权 |
| **获取本应用信息**   | `ohos.permission.GET_BUNDLE_INFO`                            | 系统授权 |
| **获取设备位置信息** | `ohos.permission.LOCATION_IN_BACKGROUND`<br/>`ohos.permission.LOCATION`<br/>`ohos.permission.APPROXIMATELY_LOCATION` | 用户授权 |
| **相机**             | `ohos.permission.CAMERA`                                     | 用户授权 |
| **麦克风**           | `ohos.permission.MICROPHONE`                                 | 用户授权 |
| **通讯录**           | `ohos.permission.READ_CONTACTS`<br/>`ohos.permission.WRITE_CONTACTS` | 用户授权 |
| **日历**             | `ohos.permission.READ_CALENDAR`<br/>`ohos.permission.WRITE_CALENDAR`<br/>`ohos.permission.READ_WHOLE_CALENDAR`<br/>`ohos.permission.WRITE_WHOLE_CALENDAR` | 用户授权 |
| **运动数据**         | `ohos.permission.ACTIVITY_MOTION`                            | 用户授权 |
| **身体传感器**       | `ohos.permission.READ_HEALTH_DATA`                           | 用户授权 |
| **图片和视频**       | `ohos.permission.WRITE_IMAGEVIDEO`<br/>`ohos.permission.READ_IMAGEVIDEO`<br/>`ohos.permission.MEDIA_LOCATION` | 用户授权 |
| **音乐和音频**       | `ohos.permission.WRITE_AUDIO`<br/>`ohos.permission.READ_AUDIO` | 用户授权 |
| **音频后台播放**     | `ohos.permission.KEEP_BACKGROUND_RUNNING`                    | 系统授权 |
| **跨应用关联**       | `ohos.permission.APP_TRACKING_CONSENT`                       | 用户授权 |
| **设备发现和连接**   | `ohos.permission.ACCESS_BLUETOOTH`<br/>`ohos.permission.ACCESS_NEARLINK`<br/>`ohos.permission.DISTRIBUTED_DATASYNC` | 用户授权 |
| **剪贴板**           | `ohos.permission.READ_PASTEBOARD`                            | 用户授权 |
| **截屏**             | `ohos.permission.CUSTOM_SCREEN_CAPTURE`                      | 用户授权 |
| **文件夹**           | `ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY`<br/>`ohos.permission.READ_WRITE_DESKTOP_DIRECTORY`<br/>`ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY` | 用户授权 |

---

<a id="section974943"></a>

## 权限与 Profile

**现象：**

需要了解权限与签名 Profile 的关系。

**原因：**

开发调试与发布对权限签名的要求不同：调试时可授权到临时签名，发布时需通过发布 Profile 申明权限。

**解决方案：**

- 开发调试时，权限可以授权到临时签名文件里。
- 发布应用时，需要 [申请发布 Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-release-profile-0000002248341090)。
