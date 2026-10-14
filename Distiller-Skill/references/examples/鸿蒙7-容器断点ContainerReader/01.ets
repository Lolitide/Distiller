// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/组件布局/构建布局/容器断点_ContainerReader/arkts-layout-development-container-reader
// 行范围：L32-L160
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

import {ContainerReader,  Size} from '@kit.ArkUI';
@Entry
@Component
struct Example {
  @State containerSize: Size = { width: 0, height: 0 };
  @State widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;
  build() {
    Flex({ direction: FlexDirection.Row }) {
      ContainerReader({
        size: this.containerSize!!,
        widthBreakpoint: this.widthBp!!
      }) {
        Column() {
          Text('Adaptive Content')
        }
        .width('100%')
        .height('100%')
      }
      .backgroundColor('#F7F7F7')
    }
    .padding(10)
    .width('100%')
    .height(200)
    .backgroundColor('#D5D5D5')
  }
}
```

ContainerReader作为Flex、Row或Column的子组件使用时，会优先为非ContainerReader类型的子组件测算尺寸，再结合父容器剩余空间与开发者设置为ContainerReader组件分配空间。这在固定内容与自适应内容并存的场景中较为适用。

```
import {ContainerReader,  Size} from '@kit.ArkUI';
@Entry
@Component
struct Example {
  @State containerSize: Size = { width: 0, height: 0 };
  @State widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;
  build() {
    Flex({ direction: FlexDirection.Row }) {
      Column() {
        Text('Text')
          .width(100)
          .height('100%')
      }
      .width(100)
      .height('100%')
      .backgroundColor('#D5D5D5')
      ContainerReader({
        size: this.containerSize!!,
        widthBreakpoint: this.widthBp!!
      }) {
        Column() {
          Text('ContainerReader')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .backgroundColor('#F7F7F7')
    }
    .width('100%')
    .height(300)
    .backgroundColor('#F0FAFF')
    .padding(10)
  }
}
```

当Flex、Row或Column容器中有多个ContainerReader子组件时，按开发者书写顺序第一个ContainerReader会占满剩余空间，此时其余ContainerReader组件的主轴大小为0。但开发者可以通过layoutWeight属性使多个ContainerReader平分剩余空间。

```
import {ContainerReader,  Size} from '@kit.ArkUI';
@Entry
@Component
struct Example {
  @State containerSize: Size = { width: 0, height: 0 };
  @State widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;
  @State containerSize1: Size = { width: 0, height: 0 };
  @State widthBp1: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;
  build() {
    Flex({ direction: FlexDirection.Row }) {
      // 固定宽度的兄弟组件，优先测算
      Column() {
        Text('Text')
          .width(80)
          .height('100%')

      }
      .width(80)
      .height('100%')
      .backgroundColor('#D5D5D5')

      // 第一个ContainerReader，通过layoutWeight(1)分配1/2剩余空间
      ContainerReader({
        size: this.containerSize!!,
        widthBreakpoint: this.widthBp!!
      }) {
        Column() {
          Text('ContainerReader1')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .layoutWeight(1)
      .backgroundColor('#F7F7F7')

      // 第二个ContainerReader，同样layoutWeight(1)分配1/2剩余空间
      ContainerReader({
        size: this.containerSize1!!,
        widthBreakpoint: this.widthBp1!!
      }) {
        Column() {
          Text('ContainerReader2')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .layoutWeight(1)
      .backgroundColor('#707070')
    }
    .width('100%')
    .height(300)
    .backgroundColor('#F0FAFF')
    .padding(10)
  }
}
```
