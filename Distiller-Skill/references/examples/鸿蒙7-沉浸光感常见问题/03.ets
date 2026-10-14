// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/沉浸光感/沉浸光感常见问题/arkts-immersive-light-sense-faq
// 行范围：L214-L225
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

// 错误写法：纯不透明颜色遮挡了材质效果
new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.THIN,
  materialColor: Color.Red, // 不透明，材质滤镜效果被完全遮挡
})

// 推荐写法：使用带透明度的颜色
new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.THIN,
  materialColor: '#80FF0000', // 带有50%透明度的红色
})
```
