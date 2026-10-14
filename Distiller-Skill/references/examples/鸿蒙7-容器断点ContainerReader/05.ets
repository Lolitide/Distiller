// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/组件布局/构建布局/容器断点_ContainerReader/arkts-layout-development-container-reader
// 行范围：L311-L365
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

import {ContainerReader,  Size} from '@kit.ArkUI';
@Entry
@Component
struct MultiContainerExample {
  // 左右两个ContainerReader各自拥有独立的状态变量，互不影响
  @State leftContainerSize: Size = { width: 0, height: 0 };
  @State rightContainerSize: Size = { width: 0, height: 0 };
  @State leftWidthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;
  @State rightWidthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;

  build() {
    Row({ space: 10 }) {
      // 左侧容器，独立感知自身尺寸和断点
      Flex({ direction: FlexDirection.Column }) {
        ContainerReader({
          size: this.leftContainerSize!!,
          widthBreakpoint: this.leftWidthBp!!
        }) {
          Column() {
            Text('Left Container')
          }
          .width('100%')
          .height('100%')
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F0FAFF')
      }
      .layoutWeight(1)
      .height(300)

      // 右侧容器，独立感知自身尺寸和断点
      Flex({ direction: FlexDirection.Column }) {
        ContainerReader({
          size: this.rightContainerSize!!,
          widthBreakpoint: this.rightWidthBp!!
        }) {
          Column() {
            Text('Right Container')
          }
          .width('100%')
          .height('100%')
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#D5D5D5')
      }
      .layoutWeight(1)
      .height(300)
    }
    .width('100%')
    .padding(20)
  }
}
```
