// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/列表与网格/创建懒加载布局_LazyColumnLayout_LazyVGridLayout_LazyVWaterFlowLayout/arkts-layout-development-create-lazy-layout
// 行范围：L156-L176
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

  // 子组件
  // ...
}
.columnsTemplate('1fr 1fr 1fr') // 设置为3列，每列等宽
// ...
LazyVWaterFlowLayout() {
  // 子组件
  // ...
}
.columnsTemplate('1fr 2fr') // 设置为2列，第一列占1份，第二列占2份
```

columnsTemplate还支持通过repeat关键字自动计算列数，格式为'repeat(auto-fit/auto-fill/auto-stretch, track-size)'，其中repeat、auto-fit、auto-fill、auto-stretch为关键字，track-size为列宽，支持px、vp、%等单位，默认单位为vp，也支持无单位的有效数字。track-size至少包含一个有效列宽。

与LazyVGridLayout组件不同的是，LazyVWaterFlowLayout组件的columnsTemplate属性还支持设置为ItemFillPolicy类型的枚举值，此时会根据组件宽度对应的栅格容器断点类型自动确定列数。例如，设置为ItemFillPolicy.BREAKPOINT_DEFAULT，组件宽度属于sm及更小的断点区间时LazyVWaterFlowLayout显示2列，属于md断点区间时显示3列，属于lg及更大的断点区间时显示5列，且每列均为1fr。

| 模式 | 示例 | 说明 |
| --- | --- | --- |
| auto-fit | 'repeat(auto-fit, 80vp)' | 设置最小列宽，自动计算列数和实际列宽。仅支持一个有效列宽值。 |
| auto-fill | 'repeat(auto-fill, 80vp)' | 设置固定列宽，自动计算列数。支持一个或多个有效列宽，如'repeat(auto-fill, 20 80px)'。 |
| auto-stretch | 'repeat(auto-stretch, 80vp)' | 设置固定列宽，以columnsGap为最小列间距，自动计算列数和实际列间距。仅支持一个有效列宽值，不支持单位%。 |
