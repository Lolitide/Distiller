// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/组件布局/构建布局/容器断点_ContainerReader/arkts-layout-development-container-reader
// 行范围：L277-L303
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
