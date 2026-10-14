# Permission Application on the Flutter OH Native Side

When a Flutter OH application calls certain system features (such as network, camera, location, and storage), it must declare the corresponding permissions on the ohos native side. If permissions are not properly requested, API calls may fail or the application may crash.

<a id="section695847"></a>

## Where to Declare Permissions

**Symptom:**

System permissions need to be declared for a Flutter OH application.

**Cause:**

When calling system capabilities such as network, camera, location, and storage, the corresponding permissions must be declared on the ohos native side; otherwise, API calls fail or the application crashes.

**Solution:**

Configure `requestPermissions` within `module` in the `ohos/entry/src/main/module.json5` file to declare permissions:

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
    // Declare permissions here
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

After configuring the permissions, re-sign the application:

File → Project Structure → Project → Signing Configs

---

<a id="section482915"></a>

## Long-Press Paste Not Working in a Flutter Input Field

**Symptom:**

Long-pressing a Flutter input field does not paste.

**Cause:**

The application has not requested the clipboard permission `ohos.permission.READ_PASTEBOARD`.

**Solution:**

Request the clipboard permission:

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

## Flutter Cannot Save Images to the Album

**Symptom:**

Flutter cannot save images to the album.

**Cause:**

The application has not requested the permission for saving images, `ohos.permission.WRITE_IMAGEVIDEO`.

**Solution:**

Request the permission for saving images:

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

## Flutter Audio Playback Stops in the Background

**Symptom:**

Audio plays normally while the Flutter application is in the foreground but stops after the app goes to the background.

**Cause:**

The application has not requested the background running permission `ohos.permission.KEEP_BACKGROUND_RUNNING` and has not declared the audio background mode. The system suspends such background applications, and audio stops as the process is frozen.

**Solution:**

Declare the permission and the audio background mode in `module.json5`:

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

## Feature and Permission Mapping

**Symptom:**

The permissions to request need to be determined based on the feature scenario.

**Cause:**

Different features require different permissions and authorization methods, and the permissions must be requested accordingly to avoid omissions.

**Solution:**

When developing a Flutter OH application, request the corresponding permissions on the ohos native side based on your feature scenario:

> This table lists only common permissions. For more permissions, see [Application Permission List](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-permissions).

| Feature Scenario     | Required Permission                                            | Authorization Method |
| :------------------- | :----------------------------------------------------------- | :------- |
| **Network requests**         | `ohos.permission.INTERNET`                                   | system_grant |
| **Obtaining information about the current application**   | `ohos.permission.GET_BUNDLE_INFO`                            | system_grant |
| **Obtaining device location** | `ohos.permission.LOCATION_IN_BACKGROUND`<br/>`ohos.permission.LOCATION`<br/>`ohos.permission.APPROXIMATELY_LOCATION` | user_grant |
| **Camera**             | `ohos.permission.CAMERA`                                     | user_grant |
| **Microphone**           | `ohos.permission.MICROPHONE`                                 | user_grant |
| **Contacts**           | `ohos.permission.READ_CONTACTS`<br/>`ohos.permission.WRITE_CONTACTS` | user_grant |
| **Calendar**             | `ohos.permission.READ_CALENDAR`<br/>`ohos.permission.WRITE_CALENDAR`<br/>`ohos.permission.READ_WHOLE_CALENDAR`<br/>`ohos.permission.WRITE_WHOLE_CALENDAR` | user_grant |
| **Motion data**         | `ohos.permission.ACTIVITY_MOTION`                            | user_grant |
| **Body sensors**       | `ohos.permission.READ_HEALTH_DATA`                           | user_grant |
| **Images and videos**       | `ohos.permission.WRITE_IMAGEVIDEO`<br/>`ohos.permission.READ_IMAGEVIDEO`<br/>`ohos.permission.MEDIA_LOCATION` | user_grant |
| **Music and audio**       | `ohos.permission.WRITE_AUDIO`<br/>`ohos.permission.READ_AUDIO` | user_grant |
| **Background audio playback**     | `ohos.permission.KEEP_BACKGROUND_RUNNING`                    | system_grant |
| **Cross-app tracking**       | `ohos.permission.APP_TRACKING_CONSENT`                       | user_grant |
| **Device discovery and connection**   | `ohos.permission.ACCESS_BLUETOOTH`<br/>`ohos.permission.ACCESS_NEARLINK`<br/>`ohos.permission.DISTRIBUTED_DATASYNC` | user_grant |
| **Clipboard**           | `ohos.permission.READ_PASTEBOARD`                            | user_grant |
| **Screen capture**             | `ohos.permission.CUSTOM_SCREEN_CAPTURE`                      | user_grant |
| **Folders**           | `ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY`<br/>`ohos.permission.READ_WRITE_DESKTOP_DIRECTORY`<br/>`ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY` | user_grant |

---

<a id="section974943"></a>

## Permissions and Profile

**Symptom:**

The relationship between permissions and the signing Profile needs to be understood.

**Cause:**

Development and debugging versus release have different requirements for permission signing: during debugging, permissions can be granted in a temporary signing file; for release, permissions must be declared through a release Profile.

**Solution:**

- During development and debugging, permissions can be granted in the temporary signing file.
- To release an application, you need to [apply for a release Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-release-profile-0000002248341090).
