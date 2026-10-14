// 来源：documentId = API参考/ArkUI_方舟UI框架/ArkTS_API/UI界面/ohos_arkui_uiMaterial_系统材质_/arkts-apis-uimaterial
// 行范围：L694-L730
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

        // 在不支持沉浸式材质的设备上，设置systemMaterial无作用，资源值的背景色属性生效
        .systemMaterial(new uiMaterial.ImmersiveMaterial({
          style: uiMaterial.ImmersiveStyle.REGULAR,
          materialColor: $r('sys.color.comp_background_emphasize')
        }))
      }
      .justifyContent(FlexAlign.End)
    }
    .backgroundColor('#99000000')
    .width('100%')
    .height(100)
  }

  build() {
    Stack() {
      // $r('app.media.invert')需要替换为开发者所需的图像资源文件
      Image($r('app.media.invert'))

      Navigation() {
        Column() {
          Text(`MaterialLevel: ${this.materialLevel}`)
            .fontSize(16)

          Text(`IsImmersiveMaterialSupported: ${this.isSupported}`)
            .fontSize(16)
        }
        .backgroundColor(Color.White)
        .margin({ top: 100 })
        .padding(15)
      }
      .title(this.CustomMenuBuilder())
    }
    .width('100%')
    .height('100%')
  }
}
```
