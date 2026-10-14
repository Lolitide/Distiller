// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/组件布局/构建布局/容器断点_ContainerReader/arkts-layout-development-container-reader
// 行范围：L169-L191
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

// 正确用法 - 使用!!触发双向绑定
@State containerSize: Size = { width: 0, height: 0 };
@State widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;

ContainerReader({
  size: this.containerSize!!,
  widthBreakpoint: this.widthBp!!
})

// 错误用法1 - 未使用!!后缀，双向绑定不生效
ContainerReader({
  size: this.containerSize,
  widthBreakpoint: this.widthBp
})

// 错误用法2 - 使用非状态变量
const containerSize: Size = { width: 0, height: 0 };

ContainerReader({
  size: containerSize,  // 必须是@State修饰的状态变量
  widthBreakpoint: WidthBreakpoint.WIDTH_MD
})
```
