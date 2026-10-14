// 来源：documentId = API参考/ArkUI_方舟UI框架/ArkTS组件/行列与堆叠/ContainerReader/ts-container-containerreader
// 行范围：L191-L253
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

// xxx.ets
import { ContainerReader, Size } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State containerSize: Size = { width: 0, height: 0 };
  @State widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_XS;
  @State heightBp: HeightBreakpoint = HeightBreakpoint.HEIGHT_SM;
  @State columnWidth: number = 180

  build() {
    Column({space: 10}) {
      Column({space: 10}) {
        ContainerReader({
          size: this.containerSize!!,
          widthBreakpoint: this.widthBp!!,
          heightBreakpoint: this.heightBp!!
        }) {
          if (this.widthBp === WidthBreakpoint.WIDTH_XS || this.widthBp === WidthBreakpoint.WIDTH_SM) {
            Column({space: 10}) {
              Text('窄屏布局')
                .fontSize(16)
              Text(`宽度断点: ${this.widthBp}`)
            }
            .width('100%')
            .height('100%')
            .backgroundColor('#D5D5D5')
            .justifyContent(FlexAlign.Center)
          } else {
            Row({space: 10}) {
              Text('宽屏布局')
                .fontSize(16)
              Text(`宽度断点: ${this.widthBp}`)
            }
            .width('100%')
            .height('100%')
            .backgroundColor('#2787D9')
            .justifyContent(FlexAlign.Center)
          }
        }
        .height(100)
        .width('100%')
        .backgroundColor('#F0FAFF')
        .breakpointConfig({ width: [100, 200, 400, 500], height: [0.8, 1.2] })
      }
      .height('20%')
      .width(this.columnWidth)

      Button('改变Column宽度')
        .onClick(()=>{
          if (this.columnWidth == 180) {
            this.columnWidth = 320;
          } else {
            this.columnWidth = 180;
          }
        })
    }
    .height('100%')
    .width('100%')
  }
}
```
