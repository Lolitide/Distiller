// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/沉浸光感/沉浸光感开发指导/开启沉浸光感/arkts-immersive-light-sense-enable
// 行范围：L27-L41
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

{
  "module": {
    "name": "entry",
    "type": "entry",
    // ...
    "metadata": [{
      "name": "ohos.arkui.UIMaterial.state",
      "value": "enable"
    }],
    // ...
  }
}
```

开发者可以通过uiMaterial.getMaterialInfo()获取当前应用的沉浸式系统材质配置状态MaterialState，MaterialState中的DEFAULT、ENABLE和DISABLE，分别对应module.json5配置文件中default、enable和disable三个value值。
