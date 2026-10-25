import { ThemeStore } from '../utils/Theme';
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
import { HdsNavigationMenuContentOptions, HdsNavDestination } from '@kit.UIDesignKit';
import { ColorMetrics, KeyboardAvoidMode, LengthMetrics } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { WindowInsets } from '../utils/WindowInsets';
import { MainTitleBar } from '../components/MainTitleBar';
import { TaskStatusIcon } from '../components/TaskStatusIcon';
import { TaskStepsSection } from '../components/TaskStepsSection';
import { TaskAttributeCard } from '../components/TaskAttributeCard';
import { TaskMetaCard } from '../components/TaskMetaCard';
import { TaskInfoCard } from '../components/TaskInfoCard';
import { TaskTagsCard } from '../components/TaskTagsCard';
import { TaskNoteCard } from '../components/TaskNoteCard';
import { TaskMediaCard } from '../components/TaskMediaCard';
import { TaskAlarm, TaskStatus } from '../model';
import { NAV_STACK_KEY, TaskDetailParam } from '../viewmodel/TaskNavParams';
import { showDeleteConfirmDialog } from '../utils/DeleteConfirmDialog';

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
  /** 视觉个性化：M3 色系（详情页底色 = surface） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 跳转参数：任务对象 + store（`Task` 是 `@ObservedV2`，改字段卡片会跟着刷新） */
  @Require @Param param: TaskDetailParam;

  /** 是否正在改任务名 */
  @Local editingName: boolean = false;
  /**
   * 状态栏高度（vp）：窗口全屏后内容区从窗口顶端起算，要先让开这一截（见 `syncStatusBarHeight`）。
   * 首帧从缓存同步取，所以正常情况下不会有 0 → 39vp 的跳变。
   */
  @Local statusBarVp: number = 0;
  /** 改名时的草稿（提交前不写回任务） */
  @Local draftName: string = '';
  /** 改名输入框的控制器：进入编辑时把光标放到文本末尾（不默认全选） */
  private nameController: TextInputController = new TextInputController();

  /**
   * 右上角两个图标按钮（需求方 2026-10-17）：**响铃 + 删除**。
   *
   * 响铃**只在任务有提醒时间时出现** —— 与列表卡片 `TaskCard.remindSwitch` 同一条规则
   * （`remindAt === undefined` 时卡片上也不给开关）；图标反映 `alarm`（用户意图）：
   * 开＝铃铛、关＝带斜杠。点它调 `store.setRemind`，与卡片 Switch **同一个写入口**，
   * 所以两处的状态天然一致，不需要额外同步。
   *
   * 依赖 `this.param.task.remindAt / alarm`（都是 `@Trace`），改了菜单会跟着重算。
   */
  @Computed
  get navMenu(): HdsNavigationMenuContentOptions {
    const hasRemind: boolean = this.param.task.remindAt !== undefined;
    const remindOn: boolean = this.param.task.alarm === TaskAlarm.ON;
    return MainTitleBar.detailMenu(hasRemind, remindOn, () => {
      this.toggleRemind();
    }, () => {
      this.confirmDelete();
    });
  }

  aboutToAppear(): void {
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);
    this.syncStatusBarHeight();
  }

  /**
   * 状态栏高度（vp）—— 内容顶部让白的**第一截**。
   *
   * 2026-10-21 修「任务详情导航栏和内容重合」：
   * 窗口是**全屏**的（`EntryAbility` 里 `setWindowLayoutFullScreen(true)`），而 `HdsNavDestination`
   * 只让**自己**（标题栏）避开状态栏，**内容区仍从窗口顶端 y=0 开始**。
   * 之前这里只留了 `SUB_PAGE_TITLE_BAR_VP`(56vp)，于是内容整体上移了一个状态栏的高度，
   * 大标题直接压在「任务详情」小标题上（需求方截图标注）。
   *
   * 布局探针实测（Mate 90 Pro 模拟器，密度 3.5）：
   *  · `HdsTitleBar`       y=137 → 332px ＝ 状态栏 39.1vp ＋ 标题栏 56vp；
   *  · 内容 `Scroll`       y=196px（＝只让了 56vp，少了 137px 那截）；
   *  · 任务名 `Text`       y=252 → 375px，与标题文字 193→275px **重叠 23px**。
   * 所以让白必须写「状态栏 + 标题栏」，与任务列表页 `A_TaskList.statusBarVp` 同一口径。
   *
   * 先读**同步缓存**（根页面启动时已查过一次）→ 首帧就落在正确位置，导航进场动画里不会跳；
   * 再异步刷新一次兜底（转屏/折叠态变化后状态栏高度会变）。
   */
  private syncStatusBarHeight(): void {
    this.statusBarVp = this.getUIContext().px2vp(WindowInsets.topPxCached());
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    WindowInsets.topPx(context).then((px: number) => {
      this.statusBarVp = px > 0 ? this.getUIContext().px2vp(px) : 0;
    });
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
   * 顶栏铃铛：切换「响铃提醒」。
   *
   * 走的是**列表卡片 Switch 同一个写入口** `TaskListStore.setRemind` —— 它只置 `alarm`
   * （用户意图，字段表第 16 项），句柄交给 `ReminderService`（TODO 里已记）。
   * 所以这里改完，卡片上的 Switch 状态立刻跟着变，反之亦然，不存在两份状态。
   */
  private toggleRemind(): void {
    const on: boolean = this.param.task.alarm === TaskAlarm.ON;
    this.param.store.setRemind(this.param.task, !on);
  }

  /**
   * 删除任务：先弹**官方警告弹窗**确认，确认后走 `store.deleteTask`（契约软删：`status = DELETED`），
   * 再从导航栈退回列表。
   *
   * 弹窗本体是 `utils/DeleteConfirmDialog.showDeleteConfirmDialog` —— 列表多选删除、步骤删除
   * 与这里**共用同一份实现**（需求方 2026-10-17），所以三处观感不会再漂移。
   */
  private confirmDelete(): void {
    showDeleteConfirmDialog(this.getUIContext(), $r('app.string.action_delete_task'),
      $r('app.string.delete_task_confirm'), () => {
        this.deleteTask();
      });
  }

  /** 真删：软删任务 + 退回列表（`groupByDay` 会过滤 DELETED，列表里自然就没了） */
  private deleteTask(): void {
    this.param.store.deleteTask(this.param.task.id);
    this.popBack();
  }

  /**
   * 退回列表：详情页是 `pushPathByName` 压进来的，弹栈即可。
   * 导航栈存在 `AppStorage`（官方《Navigation 页面路由》方式一），与点卡片进来时同一份。
   */
  private popBack(): void {
    const stack: NavPathStack | undefined = AppStorage.get<NavPathStack>(NAV_STACK_KEY);
    if (stack !== undefined) {
      stack.pop();
    }
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
        // 名称过长**不换行**、单行显示，装进**横向 Scroll** 让用户可以左右滑动看全文
        // （需求方 2026-10-16：「如果任务名称和步骤过长 不要换行 用户可以左右滑动文本查看」）
        Scroll() {
          Text(this.param.task.name)
            .fontSize($r('sys.float.titlebar_title_primary_size'))
            // 与编辑态同一个字重（枚举），两态之间不会"变细"
            .fontWeight(FontWeight.Bold)
            .fontColor(this.param.task.status === TaskStatus.COMPLETED
              ? $r('sys.color.ohos_id_color_text_tertiary')
              : $r('sys.color.ohos_id_color_text_primary'))
            .maxLines(1)
            // 点名称 → 改名（需求方 2026-10-16）
            .onClick(() => {
              this.beginEditName();
            })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .margin({ left: CONTENT_GAP_VP })
        .align(Alignment.Start)
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
      // 2026-10-21 修「详情页底部导航条颜色未跟随页面」：
      // `HdsNavDestination` 的内容区只到 2758（让开了 28vp 底部安全区），
      // 而它自己那层**默认白底**铺到窗口最底 ⇒ 手势条那一带露出白条。
      // 这里补一层**只负责颜色**的底色（用 expandSafeArea 铺进安全区），
      // 内容层保持原样、仍然让开安全区 —— 观感上就是"底部不露白、但内容不沉浸"。
      Stack({ alignContent: Alignment.TopStart }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.themeStore.scheme.surface)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .hitTestBehavior(HitTestMode.None)

      Column() {        // 顶部让开**状态栏 + 二级页自己的标题栏**（MINI = 56vp，两截都要补，见 statusBarVp）
        Row().width('100%').height(MainTitleBar.SUB_PAGE_TITLE_BAR_VP + this.statusBarVp)

        // ⚠️ 正文必须能滚：详情页现在有四张卡（步骤 / 属性 / 元信息 / 标签），
        // 装不下是常态。之前这里是裸 `Column`，卡片一多「添加标签」那一行就被裁在屏幕外
        // （需求方 2026-10-17 报的标签卡点不到，就是这个）。
        // 让位那条 `Row` 留在 `Scroll` 外面 —— 它是标题栏的占位，不该跟着内容滚。
        Scroll() {
          Column() {
            // 第一块正文：状态圆圈 + 可编辑任务名
            //
            // 与顶部标题栏的距离（2026-10-25 需求方：「任务详情页的任务名称和上面的导航栏距离有点远 改小一些」）：
            // 上一轮（2026-10-22）为了「一行与标题离得太近」在这里加了 **24vp**，加上 `nameRow` 自带的
            // `CONTENT_GAP_VP`(16vp)，标题栏下沿 → 任务名墨迹共 **40vp**（布局探针实测 332 → 472px，
            // 密度 3.5）。这次收到 **8vp**，总距离 **24vp**（≈84px）：仍然和标题分得开，
            // 又不会在标题下面空出一条。
            Column() {
              this.nameRow()
            }
            .width('100%')
            .padding({ top: 8 })

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

            // 第二块之后：图片 / 文件 / 扫码链接（步骤下方、提醒上方）
            if ((this.param.task.urls !== undefined && this.param.task.urls.length > 0)
              || (this.param.task.linkUrl !== undefined && this.param.task.linkUrl.length > 0)) {
              Column() {
                TaskMediaCard({ task: this.param.task })
              }
              .width('100%')
              .padding({
                left: CONTENT_SIDE_PADDING_VP,
                right: CONTENT_SIDE_PADDING_VP,
                top: CONTENT_GAP_VP
              })
            }

            // 第三块：属性编辑卡（提醒 / 到期 / 重复，照官方设置页造型）
            // 需求方 2026-10-16：「这个卡片放到步骤下方」
            Column() {
              TaskAttributeCard({ task: this.param.task, store: this.param.store })
            }
            .width('100%')
            .padding({
              left: CONTENT_SIDE_PADDING_VP,
              right: CONTENT_SIDE_PADDING_VP,
              top: CONTENT_GAP_VP
            })

            // 第四块：元信息卡（重要程度 / 来源，需求方 2026-10-17 的设计图）
            // 与属性卡同样的卡片造型、同样的「点行改 / 点 × 清」交互；「预计耗时」按裁定先不做
            Column() {
              TaskMetaCard({ task: this.param.task })
            }
            .width('100%')
            .padding({
              left: CONTENT_SIDE_PADDING_VP,
              right: CONTENT_SIDE_PADDING_VP,
              top: CONTENT_GAP_VP
            })

            // 第五块：标签卡（每条标签一行 + 固定「＋ 添加标签」）
            // —— 与第四块的「重要程度 / 来源」同属**分类与标记**，紧挨着放，不再被更多信息卡隔开
            Column() {
              TaskTagsCard({ task: this.param.task })
            }
            .width('100%')
            .padding({
              left: CONTENT_SIDE_PADDING_VP,
              right: CONTENT_SIDE_PADDING_VP,
              top: CONTENT_GAP_VP
            })

            // 第六块：备注卡（多行、自动换行、卡片随内容变长）
            Column() {
              TaskNoteCard({ task: this.param.task })
            }
            .width('100%')
            .padding({
              left: CONTENT_SIDE_PADDING_VP,
              right: CONTENT_SIDE_PADDING_VP,
              top: CONTENT_GAP_VP
            })

            // 第七块：更多信息卡（状态 / 难易程度 / 类型 / 地点 / 链接 / 置信度 / 创建于 / 完成于）
            // **挪到最后**（2026-10-19「详情部分的显示优先级、分组可做优化调整」）：
            // 这张卡里一半是只读读数（置信度、两个时间戳），属于"平时不看"，压到页面底部；
            // 上面几块才是用户每天要动的：属性 → 分类标记 → 备注。
            // 「状态」是本卡第一行（需求方 2026-10：「添加到重要性那个 card 里面的第一个」），
            // 它要 `store` —— 状态写回只走 `store.setStatus`。
            Column() {
              TaskInfoCard({ task: this.param.task, store: this.param.store })
            }
            .width('100%')
            .padding({
              left: CONTENT_SIDE_PADDING_VP,
              right: CONTENT_SIDE_PADDING_VP,
              top: CONTENT_GAP_VP
            })

            // 底部留白：最后一张卡（备注卡）不要贴着手势条。
            // 原来这里还有一块「任务详情待做」占位 —— 五张卡做完就撤了（需求方 2026-10-17：「把底部的任务待做去掉」）
            Column()
              .width('100%')
              .height(CONTENT_GAP_VP)
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.Top)
        .scrollBar(BarState.Off)
        // 滚到底要有回弹，手势条那一带的灰才连得住
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      // 2026-10-20 取消全屏沉浸：布局区已自动让开状态栏/导航条，
      // 原来的 `.padding({ top: this.sbVp })` 与 `.expandSafeArea(...)` 一并删掉。
      // 2026-10-19 全局 MD3：底色从系统浅蓝 `ohos_id_color_sub_background` 换成 M3 `surface`，
      // 与任务列表 / 设置页同一套色系（作者：「详情页的背景底色也没加」）。
      .backgroundColor(this.themeStore.scheme.surface)
      }
      .width('100%')
      .height('100%')
    }
    // 标题栏与搜索页同一套官方风格；**标题固定写「任务详情」**，不显示任务名
    // （需求方 2026-10-16：「任务详情顶部栏不是显示任务名称 就显示任务详情」）
    .titleBar({
      // 2026-10-21 窗口改回全屏：必须 `true`，否则二级页标题栏会顶到状态栏底下（与主页同一口径）
      avoidLayoutSafeArea: true,
      // 2026-10-21：入参改成 M3 `surface`（实色背板），图标圆底由 `MainTitleBar.style()` 内部推导
      style: MainTitleBar.style(this.themeStore.scheme.surface, this.themeStore.scheme.onSurface),
      content: {
        title: { mainTitle: $r('app.string.title_task_detail') },
        // 右上角：响铃（有提醒时间才出现）+ 删除
        menu: this.navMenu
      }
    })
    // 默认就带返回图标，显式写出来（官方示例也是这么写的）
    .hideBackButton(false)
  }
}
