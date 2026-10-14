// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/沉浸光感/沉浸光感常见问题/arkts-immersive-light-sense-faq
// 行范围：L431-L444
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

// 材质效果的显示层级问题示例
Row() {
  Text('TextArea组件：')
    .fontColor(Color.Black)
  TextArea()
    .width(100)
    .height(40)
    .backgroundColor('#cc999999') // 不建议同时使用沉浸式系统材质和背景色接口
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
      interactive: true
    }))
}
```
