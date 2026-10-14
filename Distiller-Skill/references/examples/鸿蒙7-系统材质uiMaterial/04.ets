// 来源：documentId = API参考/ArkUI_方舟UI框架/ArkTS_API/UI界面/ohos_arkui_uiMaterial_系统材质_/arkts-apis-uimaterial
// 行范围：L564-L627
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

// xxx.ets
import { uiMaterial } from '@kit.ArkUI';

@Styles
function systemMaterialStyle() {
  .margin(5)
  .width(70)
  .height(70)
  .borderRadius(50)
}

@Entry
@Component
struct NavigationTitleMaterialDemo {
  @State myMaterial: uiMaterial.ImmersiveMaterial = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    interactive: true,
    lightEffect: {},
  });

  @Builder
  CustomMenuBuilder() {
    Stack() {
      Row() {
        Text('Title')
          .fontSize(30)
          .fontColor(Color.White)
          .margin({ right: 50 })

        Column() {
        }
        .systemMaterialStyle()
        .systemMaterial(this.myMaterial)

        Column() {
        }
        .systemMaterialStyle()
        .systemMaterial(this.myMaterial)

        Column() {
        }
        .systemMaterialStyle()
        .systemMaterial(this.myMaterial)
      }
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .height(100)
  }

  build() {
    Stack() {
      // $r('app.media.invert')需要替换为开发者所需的图像资源文件
      Image($r('app.media.invert'))
      Navigation() {
        // 页面内容
      }
      .title(this.CustomMenuBuilder())
    }
    .width('100%')
    .height('100%')
  }
}
```
