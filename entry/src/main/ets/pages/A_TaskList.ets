@ComponentV2
export struct A_TaskList {
  build() {
    Column() {
      Text($r('app.string.tab_task_list'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
