// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/沉浸光感/沉浸光感常见问题/arkts-immersive-light-sense-faq
// 行范围：L49-L136
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

import { CircleShape, TitleBarType, uiMaterial } from '@kit.ArkUI';

@Entry
@Component
struct MaterialScopeAdaptExample {
  private arr: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

  @Builder
  NavigationTitle() {
    Row() {
      // 请将$r('app.string.title_bar')替换为实际资源文件，在本示例中该资源文件的value值为"标题栏"
      Text($r('app.string.title_bar'))
        .fontColor('#182431')
        .fontSize(30)
        .lineHeight(41)
        .fontWeight(700)
      Blank()
      Column() {
        SymbolGlyph($r('sys.symbol.a_3d_square_fill'))
      }
      .width(50)
      .height(50)
      .clipShape(new CircleShape({
        width: 50,
        height: 50
      }))
      .justifyContent(FlexAlign.Center)
      .backgroundColor(Color.Transparent)
      // 在Navigation标题栏中开启沉浸光感，处于生效范围内，沉浸光感效果生效
      .systemMaterial(new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.THIN,
      }))
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .padding(16)
  }

  build() {
    Column() {
      Navigation() {
        Column() {
          Row() {
            // 请将$r('app.string.content_area')替换为实际资源文件，在本示例中该资源文件的value值为"内容区"
            Text($r('app.string.content_area'))

            Blank()

            Column() {
              SymbolGlyph($r('sys.symbol.a_3d_square_fill'))
            }
            .width(50)
            .height(50)
            .clipShape(new CircleShape({
              width: 50,
              height: 50
            }))
            .justifyContent(FlexAlign.Center)
            .backgroundColor(Color.Transparent)
            // 在Navigation内容中开启沉浸光感，处于生效范围外，不生效沉浸光感效果
            .systemMaterial(new uiMaterial.ImmersiveMaterial({
              style: uiMaterial.ImmersiveStyle.THIN,
            }))
          }
          .width('100%')
          .padding(16)
          .borderRadius(16)
        }
        .width('100%')
        .height('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .linearGradient({
          angle: 0,
          colors: [
            ['#004AAF', 0.0],
            ['#2787D9', 0.5],
            ['#F0FAFF', 1.0]
          ]
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .title(this.NavigationTitle, { barStyle: BarStyle.STACK })
    }.width('100%').height('100%').backgroundColor('#F1F3F5')
  }
}
```
