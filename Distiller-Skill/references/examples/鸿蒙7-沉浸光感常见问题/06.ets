// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/沉浸光感/沉浸光感常见问题/arkts-immersive-light-sense-faq
// 行范围：L359-L410
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

// 材质渲染区域与组件可视区域不一致示例
Row() {
  Text('Checkbox组件：')
    .fontColor(Color.Black)
  Checkbox()
    .width(40)
    .height(40)
    .borderWidth(1)
    .borderColor(Color.Blue)
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
      interactive: true
    }))
}
Row() {
  Text('Text组件：')
    .fontColor(Color.Black)
  Text("hello")
    .width(100)
    .height(40)
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
      interactive: true
    }))
}

Row() {
  Text('Progress组件：')
    .fontColor(Color.Black)
  Progress({value: 40, type: ProgressType.Capsule})
    .width(100)
    .height(40)
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
      interactive: true
    }))
}

// 材质渲染区域与组件可视区域一致示例
Row() {
  Text('Progress组件：')
    .fontColor(Color.Black)
  Progress({value: 40, type: ProgressType.Capsule})
    .width(100)
    .height(40)
    .borderRadius(20) // 设置borderRadius属性使材质渲染区域与组件可视区域一致
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
      interactive: true
    }))
}
```
