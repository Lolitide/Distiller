/*
 * 任务详情页（**二级页**，按 §9.1 用 `B_` 前缀）。
 *
 * 当前进度（需求方 2026-10-16）：
 *  ① 「点任务卡片 → 滑进来一个详情页 → 能返回」✓（与搜索页同一套顶栏）；
 *  ② 正文第一块：**可编辑的任务名** ✓ —— 字号/字重用与列表页导航栏 mainTitle **同一套官方 token**，
 *     名称前带卡片前缀里那个**状态圆圈**，已完成时名称变灰，点名称进入编辑、按回车提交。
 *  其余详情内容（备注 / 原文对照 / 地点 / 对象 / 类型 / 链接 / 置信度 / 缺失字段 / 步骤…）**待做**。
 *
 * 页面级约定（前几轮踩出来的，别再犯）：
 *  · `HdsNavDestination` 的 `titleMode` 默认 **MINI ＝ 56vp**（不是主页 FREE 的 112vp）；
 *  · 页面底色要自己刷 `ohos_id_color_sub_background`（主页那层灰是 HdsTabBar 的 HdsTabs 刷的）；
 *  · 底部安全区用 `expandSafeArea` 把灰刷进去；
 *  · 本页有输入框，键盘避让改 `RESIZE`（默认 `OFFSET` 在光标位置靠上时**不会上抬页面**，见 #117）。
 */
import { HdsNavDestination } from '@kit.UIDesignKit';
import { ColorMetrics, KeyboardAvoidMode, LengthMetrics } from '@kit.ArkUI';
import { MainTitleBar } from '../components/MainTitleBar';
import { TaskStatusIcon } from '../components/TaskStatusIcon';
import { TaskStepsSection } from '../components/TaskStepsSection';
import { TaskStatus } from '../model';
import { TaskDetailParam } from '../viewmodel/TaskNavParams';

/** 二级页标题栏高度（vp）：`HdsNavDestination.titleMode` 默认 MINI，官方写作「标题栏高度为 56vp」 */
const DEST_TITLE_BAR_HEIGHT_VP: number = 56;

/** 内容左右留白（vp）：官方 `padding_level8` = 16，与列表页一致 */
const CONTENT_SIDE_PADDING_VP: number = 16;

/** 标题行与标题栏、标题行下方的间距（vp）：官方 `padding_level8` */
const CONTENT_GAP_VP: number = 16;

/** 改名输入框的组件 id：`beginEditName()` 用它抢焦点（`focusControl.requestFocus`） */
const NAME_INPUT_ID: string = 'taskNameInput';

/**
 * 二级页的实例化方法 —— **官方系统路由表要的就是它**（`router_map.json` 里的 `buildFunction`）。
 * `param` 是点卡片时塞进来的 `TaskDetailParam`。
 */
@Builder
export function TaskDetailPageBuilder(name: string, param: Object) {
  B_TaskDetail({ param: param as TaskDetailParam });
}

@ComponentV2
export struct B_TaskDetail {
  /** 跳转参数：任务对象 + store（`Task` 是 `@ObservedV2`，改字段卡片会跟着刷新） */
  @Require @Param param: TaskDetailParam;

  /** 是否正在改任务名 */
  @Local editingName: boolean = false;
  /** 改名时的草稿（提交前不写回任务） */
  @Local draftName: string = '';
  /** 改名输入框的控制器：进入编辑时把光标放到文本末尾（不默认全选） */
  private nameController: TextInputController = new TextInputController();

  aboutToAppear(): void {
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);
  }

  aboutToDisappear(): void {
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.OFFSET);
  }

  /** 点名称 → 进入编辑：草稿从当前值起（抢焦点交给输入框的 `onAppear`，见 nameRow） */
  private beginEditName(): void {
    this.draftName = this.param.task.name;
    this.editingName = true;
  }

  /** 回车 / 键盘完成键 → 提交。**空名不提交**（保持原名，避免把任务名清空） */
  private commitName(): void {
    const trimmed: string = this.draftName.trim();
    if (trimmed.length > 0) {
      this.param.task.name = trimmed;
    }
    this.editingName = false;
  }

  /**
   * 名称前面那个状态圆圈 —— 与卡片前缀**同一个组件**（`TaskStatusIcon`）。
   * 在详情页顺手让它可点（完成/退回），和卡片上的操作一致。
   */
  @Builder
  statusIcon() {
    TaskStatusIcon({
      task: this.param.task,
      onTap: () => {
        this.param.store.toggleComplete(this.param.task);
      }
    })
  }

  /**
   * 任务名（第一块正文）。
   *
   * · 字号/字重与列表页导航栏 mainTitle **同一套官方 token**：
   *   `titlebar_main_title_text_font_size` + `title_primary_weight`（`fontSize` 吃 `Resource`、
   *   `fontWeight` 的签名是 `number | FontWeight | ResourceStr`，两个都能直接收资源 ✓）；
   * · 已完成 → 名称变灰（`ohos_id_color_text_tertiary`），与卡片"完成态灰化"一致；
   * · 点名称进入编辑，回车提交（本页没有"保存"按钮，符合需求方「点击回车就算修改完成」）。
   */
  @Builder
  nameRow() {
    Row() {
      this.statusIcon()

      if (this.editingName) {
        TextInput({ text: this.draftName, controller: this.nameController })
          .id(NAME_INPUT_ID)
          // 一点名称就直接进输入态（不用点第二下）；抢焦点同样放在 `onAppear`
          .onAppear(() => {
            focusControl.requestFocus(NAME_INPUT_ID);
          })
          // 编辑态**不要默认全选**，光标落到文本末尾（需求方 2026-10-16）
          .onFocus(() => {
            // 推到下一帧再设：框架"聚焦后的默认处理"可能晚于 onFocus，立刻设会被覆盖
            setTimeout(() => {
              this.nameController.caretPosition(this.draftName.length);
            }, 0);
          })
          // 去掉外面的焦点蓝框，只留光标（需求方 2026-10-16）
          .focusBox({ strokeWidth: LengthMetrics.vp(0), strokeColor: ColorMetrics.rgba(0, 0, 0, 0) })
          .layoutWeight(1)
          // 编辑态与展示态用同一套字号/字重，进入/退出编辑时不会跳
          .fontSize($r('sys.float.titlebar_title_primary_size'))
          // ⚠️ 这里用**枚举 `FontWeight.Bold`**，不用 `font_weight_bold` 资源 ——
          // 资源形式的字重 `TextInput` 吃不上（需求方 2026-10-16：「字体不粗啊」）。
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          // ⚠️ `TextInputStyle.Inline` ＝ 官方"内联输入样式"，**没有背板、没有下划线、没有圆角**
          // （官方原文：Inline 为内联输入样式）。之前只设 `backgroundColor(Transparent)` 不够，
          // 那道浅色"遮罩"还在（需求方 2026-10-16：「修改状态有那个文本框的遮罩」）。
          .style(TextInputStyle.Default)
          // 背景不要纯白，与页面底色一致（需求方 2026-10-16：「用TextInput 把里面的背景不要纯白 和背景一致颜色」）
          .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
          // 双保险：Inline 之外再把下划线与边框明确关掉，避免不同版本主题给它补回来
          .showUnderline(false)
          .borderWidth(0)
          .borderRadius(0)
          .padding(0)
          // ⚠️ **不要给 `height`**：之前钉成 24vp（字号 token），而字重是 Bold、字号 30vp，
          // 结果文字被上下裁掉（需求方 2026-10-16 截图里字的下沿是切平的）。用 `TextInput` 默认高度最稳。
          .maxLines(1)
          .enterKeyType(EnterKeyType.Done)
          .margin({ left: CONTENT_GAP_VP })
          .onChange((value: string) => {
            this.draftName = value;
          })
          .onSubmit(() => {
            this.commitName();
          })
          // 失焦也提交：用户"点一下改完就去干别的"是最常见操作，不该把编辑态挂在那儿。
          // （需求方 2026-10-16 的要求是「点击回车就算修改完成」，这条是它的超集）
          .onBlur(() => {
            if (this.editingName) {
              this.commitName();
            }
          })
      } else {
        Text(this.param.task.name)
          .layoutWeight(1)
          .fontSize($r('sys.float.titlebar_title_primary_size'))
          // 与编辑态同一个字重（枚举），两态之间不会"变细"
          .fontWeight(FontWeight.Bold)
          .fontColor(this.param.task.status === TaskStatus.COMPLETED
            ? $r('sys.color.ohos_id_color_text_tertiary')
            : $r('sys.color.ohos_id_color_text_primary'))
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: CONTENT_GAP_VP })
          // 点名称 → 改名（需求方 2026-10-16）
          .onClick(() => {
            this.beginEditName();
          })
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({
      left: CONTENT_SIDE_PADDING_VP,
      right: CONTENT_SIDE_PADDING_VP,
      top: CONTENT_GAP_VP
    })
  }

  build() {
    HdsNavDestination() {
      Column() {
        // 顶部让开**二级页自己的**标题栏（MINI = 56vp）
        Row().width('100%').height(DEST_TITLE_BAR_HEIGHT_VP)

        // 第一块正文：状态圆圈 + 可编辑任务名
        this.nameRow()

        // 第二块：步骤（需求方 2026-10-16 的 4 张交互图，见 `TaskStepsSection` 顶部注释）
        Column() {
          TaskStepsSection({ task: this.param.task })
        }
        .width('100%')
        .padding({
          left: CONTENT_SIDE_PADDING_VP,
          right: CONTENT_SIDE_PADDING_VP,
          top: CONTENT_GAP_VP
        })

        // 其余详情内容**待做**
        Column() {
          Text($r('app.string.task_detail_placeholder'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .padding({ top: CONTENT_GAP_VP })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
      // 底部安全区（手势条那一条）也要同一个灰
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    // 标题栏与搜索页同一套官方风格；**标题固定写「任务详情」**，不显示任务名
    // （需求方 2026-10-16：「任务详情顶部栏不是显示任务名称 就显示任务详情」）
    .titleBar({
      style: MainTitleBar.STYLE,
      content: {
        title: { mainTitle: $r('app.string.title_task_detail') }
      }
    })
    // 默认就带返回图标，显式写出来（官方示例也是这么写的）
    .hideBackButton(false)
  }
}
