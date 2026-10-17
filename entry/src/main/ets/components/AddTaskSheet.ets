/*
 * 「添加任务」半模态（`bindSheet`）的**内容区**。
 *
 * 需求方 2026-10-17：「点击底部页签的添加按钮后 显示一个 bindSheet 先完成这个功能」
 * —— 这一步只打通「点底部页签右侧那颗圆形『＋』→ 从底部拉起半模态」这条链路，
 * **表单本体还没做**，所以内容区先是一句占位。
 *
 * 拉起它的地方在 `pages/A_Main.ets`（`.bindSheet(this.addSheetShown!!, …)`，标题也在那儿的
 * `SheetOptions.title` 里给，不在这里画）。为什么半模态挂在**页面**而不是那颗粒按钮上：
 * 半模态是"严格和宿主节点绑在一起"的弹窗（官方原文），挂在页面根节点上，宿主不会因为
 * 页签切换/迷你栏折叠而重建；显隐状态也归页面持有，`MainTabBar` 只管发 `onAdd` 事件。
 *
 * 下一步要接的东西（按开发指南 §2 的调用链，**不许页面直接调系统能力**）：
 *   原文输入 → `service/ai/`（动态 `import()` 的实体抽取）→ 字段确认 → `repository/` 落库 → 回列表。
 *
 * 两条已经查证、留给下一步的事实（别重复查）：
 *  · 半模态内容区**不会自己避让软键盘**，要用 `SheetOptions.keyboardAvoidMode`
 *    （官方 FAQ：半模态可用 `keyboardAvoidMode` 避让，全模态 `bindContentCover` 不行）；
 *  · 内容区里若放 `List` / `Scroll`，必须按官方《绑定半模态页面》给滚动容器设 `nestedScroll`
 *    （`scrollForward: PARENT_FIRST` / `scrollBackward: SELF_FIRST`），
 *    否则「拖挡位」和「滚内容」会互相抢手势。
 */
@ComponentV2
export struct AddTaskSheet {
  build() {
    Column() {
      // 占位：文案走资源（`base/element/string.json` 的 `add_task_placeholder`），不硬编码中文
      Text($r('app.string.add_task_placeholder'))
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
    }
    .width('100%')
    .height('100%')
    .padding($r('sys.float.padding_level8'))
    .justifyContent(FlexAlign.Center)
  }
}
