@ComponentV2
export struct A_Settings {
  build() {
    Column() {
      Text($r('app.string.tab_settings'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
