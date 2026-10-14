// 来源：documentId = 版本说明/26_0_0/OS平台能力/OS平台行为变更说明/26_0_0_Beta1引入的行为变更/UX样式或效果的变更/changelogs-ux-7001
// 行范围：L67-L75
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

@Entry
struct ButtonExample {
  build() {
    Button('xxxxx')
      .controlSize(ControlSize.SMALL)
      .responseRegion(undefined)
  }
}
```
