// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/沉浸光感/沉浸光感常见问题/arkts-immersive-light-sense-faq
// 行范围：L156-L178
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

// 错误写法：不透明背景色会覆盖在材质层之上，导致材质效果不可见
Column() {
  Text('沉浸光感')
}
.width(328)
.height(56)
.borderRadius(28)
.systemMaterial(new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.THIN,
}))
.backgroundColor(Color.White)
// 推荐写法：将背景色设为透明，确保材质效果可见
Column() {
  Text('沉浸光感')
}
.width(328)
.height(56)
.borderRadius(28)
.backgroundColor(Color.Transparent)
.systemMaterial(new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.THIN,
}))
```
