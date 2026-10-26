/*
 * 「添加标签」时浮在**输入法上方**的**已有标签选择条**（独立组件，需求方 2026-10-27）。
 *
 * 要解决的问题（需求方原话）：「任务详情页添加标签时不能选择已有标签，可以在添加标签时在输入法上方
 * 显示一个悬浮的选择已有标签的组件，即将所有已创建标签置于输入法上方横向排布，注意避让输入栏和输入法；
 * 如要管理已创建的标签，可以在这些标签上长按，标签变为删除，再次点击即删除。」
 *
 * 造型（需求方 2026-10-27 两轮）：第一轮「不用做这个 card 样子，直接用 ChipGroup，后面背景是白色」
 * → 去掉白卡 + 圆角 + 投影；第二轮「背景颜色改成和页面一样的 md 取色」
 * → 底色改用**详情页正文那档 `surface`**（与 `B_TaskDetail` 根节点同一个 M3 角色），
 * 于是这条带子和页面没有接缝，只剩一排**官方 `Chip` 组件**（`ChipSize.SMALL`，
 * 与任务列表顶部筛选芯片同一套官方控件、同一套 M3 取色）浮在上面。
 *
 * 位置与避让（关键）：
 *  · **不**用 `position` 浮层、也不用 `bindSheet`：本组件由页面放进**底部固定的一段布局**里，
 *    整页在 `KeyboardAvoidMode.RESIZE` 下会随键盘收缩，所以它天然落在「输入行下方、键盘上方」这条带子上
 *    —— 既不会盖住标签卡里的内联输入框（那个在可滚区里，被挤到这条带子上方），也不会被键盘挡住。
 *    相对地，浮层方案要自己算键盘高度，且一定会压住下面的内容。
 *
 * 为什么不是 `ChipGroup`、而是一颗颗 `Chip`：
 * `ChipGroup` 的芯片是它内部生成的，**槽位不对外暴露**，挂不上"逐颗长按"（长按只能挂在整个
 * ChipGroup 外面，拿不到按下的是哪一颗）。而需求要的正是「长按某颗 → 这颗变成删除」，
 * 所以改用**同一个组件库里的 `Chip`**逐个排（官方尺寸档与取色完全一致），
 * 手势挂在每颗外面那层 `Row` 上。
 *
 * 手势为什么用 `GestureGroup(GestureMode.Exclusive, LongPress, Tap)`：
 * 官方 FAQ《实现Text长按和点击弹出不同的菜单》给的就是这条：互斥组合里长按成功后点按不再触发，
 * 所以「长按变删除」不会被同一次抬手立刻当成「再点一次」而误删。
 * 另外 `duration` 取 **400ms**（< 500）：官方长按手势文档写明，可默认拖拽的组件（Text/Image 等）
 * 在长按时长 ≥500ms 时**优先响应拖拽**，取 400 才是稳定的"长按"。
 *
 * ⚠️ 芯片的**点击不用 `Chip.onClicked`**，故意和长按一起放进同一个互斥手势组里：
 * 两条回调各自监听的话，长按抬手可能顺带触发一次 `onClicked`，「长按变删除」会被同一次抬手
 * 立刻当成"再点一次"而误删。`onClicked` 不传时 Chip 只是不派发点击事件，触摸照样能被外层手势收到。
 */
import { Chip, ChipOptions, ChipSize, SymbolGlyphModifier } from '@kit.ArkUI';
import { Theme, ThemeStore } from '../utils/Theme';

/** 条子左右内边距（vp）：与页面正文的 16 对齐，芯片不会贴着屏幕边 */
const BAR_SIDE_PADDING_VP: number = 16;
/** 条子上下内边距（vp）：上面紧贴可滚区，下面紧贴键盘，只留一点呼吸 */
const BAR_TOP_PADDING_VP: number = 6;
const BAR_BOTTOM_PADDING_VP: number = 8;
/** 提示行高度（vp） */
const HINT_HEIGHT_VP: number = 18;
/** 芯片行（横向滚动区）高度（vp） */
const CHIP_ROW_HEIGHT_VP: number = 40;
/** 芯片之间的间距（vp）：与列表页筛选芯片一致 */
const CHIP_GAP_VP: number = 8;
/** 长按判定时长（ms）：必须 < 500，见文件头说明 */
const LONG_PRESS_DURATION_MS: number = 400;
/** 「已删除」回执显示多久（ms） */
const DELETED_HINT_MS: number = 2000;

@ComponentV2
export struct TagSuggestBar {
  /** 视觉个性化：M3 色系（底色与页面同档 `surface`，删除态用 `errorContainer`） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 全部已创建的标签（去重；页面传 `TaskListStore.allTags`）—— 为空时页面不该渲染本组件 */
  @Require @Param tags: string[];
  /** 当前任务已经有的标签（决定这颗芯片画不画成「已添加」） */
  @Require @Param selected: string[];

  /** 点了一颗芯片：交给页面决定"加到本任务"还是"从本任务拿掉" */
  @Event onPick: (tag: string) => void = () => {};
  /** 确认（第二次点击）全局删除这个标签 */
  @Event onDelete: (tag: string) => void = () => {};

  /** 正处在「删除」态的标签；空串 = 没有在管理标签 */
  @Local deletingTag: string = '';
  /**
   * 刚删掉的标签（在提示行上回一句"已删除「xx」"，2 秒后自动消失）。
   *
   * 为什么回执放在条子自己这里、而不用 `showToast`：这条交互**永远发生在键盘弹起时**，
   * 而 toast 是独立窗口、落点跟着窗口底边走 —— 实测键盘弹着的时候 `showToast` 连窗口都不建，
   * 用户什么也看不到。写在提示行上是百分百可见的（它就在键盘正上方）。
   */
  @Local justDeleted: string = '';
  /** 「已删除」回执的定时器（组件销毁时要清掉，别对着已经拆掉的节点写状态） */
  private deletedTimer: number = -1;

  /** 这个标签是不是已经在当前任务上 */
  private isSelected(tag: string): boolean {
    return this.selected.indexOf(tag) >= 0;
  }

  /**
   * 单颗芯片的 key：**标签名 + 三态**。
   *
   * ⚠️ 这里必须把状态编进 key，不能只用 `tag`：官方 `Chip` 是**高级组件**，
   * `ChipOptions` 是**创建时**吃进去的，父组件重渲染时它**不会**跟着改外观
   * （实测：点一下就加进任务了、标签卡也跟着多了那一行，但芯片仍是灰的；长按同理不变红）。
   * 而 `ForEach` 只在 key 变化时重建节点 —— 所以把三态编进 key，状态一变这颗芯片就整颗重建，
   * 新的 `ChipOptions` 才真的生效。芯片很小，重建一颗的代价可以忽略。
   */
  private chipKey(tag: string): string {
    if (this.deletingTag === tag) {
      return `${tag}|delete`;
    }
    return this.isSelected(tag) ? `${tag}|selected` : `${tag}|normal`;
  }

  /**
   * 芯片被点一下：
   *  · 没有删除态 → 交给页面「选中 / 取消选中」；
   *  · 删除态下点**同一颗** → 真删（需求方：「再次点击即删除」）；
   *  · 删除态下点**别颗** → 先退出删除态，不做别的（此时手指大概率是想取消，不该顺手加标签）。
   */
  private handleTap(tag: string): void {
    if (this.deletingTag.length === 0) {
      this.onPick(tag);
      return;
    }
    if (this.deletingTag === tag) {
      this.deletingTag = '';
      this.justDeleted = tag;
      this.onDelete(tag);
      // 2 秒后收起回执（先清上一个定时器，连删两个标签时不至于被前一个提前抹掉）
      if (this.deletedTimer >= 0) {
        clearTimeout(this.deletedTimer);
      }
      this.deletedTimer = setTimeout(() => {
        this.justDeleted = '';
        this.deletedTimer = -1;
      }, DELETED_HINT_MS);
      return;
    }
    this.deletingTag = '';
  }

  aboutToDisappear(): void {
    if (this.deletedTimer >= 0) {
      clearTimeout(this.deletedTimer);
      this.deletedTimer = -1;
    }
  }

  /**
   * 一颗芯片的官方 `ChipOptions`，三态各一套（取色口径与列表页筛选芯片、表单里的标签芯片一致）：
   *  · 普通（还没加进本任务）：`surfaceContainerHighest` 底 + `onSurface` 字；
   *  · 已添加：官方**激活态**，`secondaryContainer` 底 + `onSecondaryContainer` 字（自带对勾）；
   *  · 删除态：`errorContainer` 底 + `onErrorContainer` 字 + 垃圾桶前缀图标（需求方：「标签变为删除」）。
   */
  private chipOptions(tag: string): ChipOptions {
    if (this.deletingTag === tag) {
      return {
        size: ChipSize.SMALL,
        // 这里不用官方那个默认「× 关闭」：删除是「长按 → 再点一次」，一颗芯片上不放两种删法
        allowClose: false,
        activated: false,
        backgroundColor: this.themeStore.scheme.errorContainer,
        label: {
          text: tag,
          fontColor: this.themeStore.scheme.onErrorContainer
        },
        prefixSymbol: {
          normal: new SymbolGlyphModifier($r('sys.symbol.trash'))
            .fontColor([this.themeStore.scheme.onErrorContainer])
        }
      };
    }
    if (this.isSelected(tag)) {
      return {
        size: ChipSize.SMALL,
        allowClose: false,
        activated: true,
        backgroundColor: this.themeStore.scheme.secondaryContainer,
        activatedBackgroundColor: this.themeStore.scheme.secondaryContainer,
        label: {
          text: tag,
          fontColor: this.themeStore.scheme.onSecondaryContainer,
          activatedFontColor: this.themeStore.scheme.onSecondaryContainer
        },
        // ⚠️ 实测：**单颗 `Chip`** 的 `activated` 只换底色，**不会**自带对勾
        //（列表页那排芯片的对勾是 `ChipGroup` 加的）。所以「已在本任务」这一态自己补一颗对勾，
        // 与列表页筛选芯片的选中观感对齐；颜色取 `onSecondaryContainer`，压在浅底上看得清。
        prefixSymbol: {
          normal: new SymbolGlyphModifier($r('sys.symbol.checkmark'))
            .fontColor([this.themeStore.scheme.onSecondaryContainer]),
          activated: new SymbolGlyphModifier($r('sys.symbol.checkmark'))
            .fontColor([this.themeStore.scheme.onSecondaryContainer])
        }
      };
    }
    return {
      size: ChipSize.SMALL,
      allowClose: false,
      activated: false,
      backgroundColor: this.themeStore.scheme.surfaceContainerHighest,
      label: {
        text: tag,
        fontColor: this.themeStore.scheme.onSurface
      }
    };
  }

  /** 提示行文案：删完回一句回执，删除态提示「再点一次」，平时教动作 */
  @Computed
  get hint(): ResourceStr {
    if (this.justDeleted.length > 0) {
      return $r('app.string.tag_deleted', this.justDeleted);
    }
    return this.deletingTag.length === 0
      ? $r('app.string.tag_suggest_hint')
      : $r('app.string.tag_suggest_delete_hint');
  }

  /** 提示行颜色：删除态红（警示），其余灰（辅助说明） */
  private hintColor(): ResourceColor {
    return this.deletingTag.length === 0
      ? $r('sys.color.ohos_id_color_text_secondary')
      : this.themeStore.scheme.onErrorContainer;
  }

  build() {
    Column() {
      // ① 提示行（删除态右侧多一个「取消」，因为此时点芯片是删除，需要一个明确的退出口）
      Row() {
        Text(this.hint)
          .fontSize($r('sys.float.ohos_id_text_size_caption'))
          .fontColor(this.hintColor())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        if (this.deletingTag.length > 0) {
          Text($r('app.string.action_cancel'))
            .fontSize($r('sys.float.ohos_id_text_size_caption'))
            .fontColor(this.themeStore.scheme.primary)
            .maxLines(1)
            .margin({ left: Theme.GAP_S })
            .onClick(() => {
              this.deletingTag = '';
            })
        }
      }
      .width('100%')
      .height(HINT_HEIGHT_VP)
      .alignItems(VerticalAlign.Center)

      // ② 已有标签：官方 Chip 横排，可左右滑动（标签再多也不换行把条子撑高）
      Scroll() {
        Row({ space: CHIP_GAP_VP }) {
          /*
           * ⚠️ 状态一律在 build() 里**直接读**（`this.deletingTag`、`selected`）再交给 `chipOptions()`，
           * 不抽成"带值的 @Builder"——值参数不随状态刷新（本工程已经踩过，见 TaskTagsCard 顶部注释）。
           */
          ForEach(this.tags, (tag: string) => {
            // 外层 Row 只负责给这颗芯片挂手势（`Chip(...)` 是 @Builder 调用，不能直接链式挂属性）
            Row() {
              Chip(this.chipOptions(tag))
            }
            .gesture(
              GestureGroup(GestureMode.Exclusive,
                LongPressGesture({ repeat: false, duration: LONG_PRESS_DURATION_MS })
                  .onAction(() => {
                    this.deletingTag = tag;
                  }),
                TapGesture({ count: 1, fingers: 1 })
                  .onAction(() => {
                    this.handleTap(tag);
                  })
              )
            )
          }, (tag: string) => this.chipKey(tag))
        }
        .height(CHIP_ROW_HEIGHT_VP)
        .alignItems(VerticalAlign.Center)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height(CHIP_ROW_HEIGHT_VP)
      .align(Alignment.Start)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: BAR_SIDE_PADDING_VP,
      right: BAR_SIDE_PADDING_VP,
      top: BAR_TOP_PADDING_VP,
      bottom: BAR_BOTTOM_PADDING_VP
    })
    // 底色跟**详情页正文**同一档 M3 取色（`surface`，见 `B_TaskDetail` 的根节点）——
    // 需求方 2026-10-27：先要「背景是白色」，再改成「和页面一样的 md 取色」，
    // 于是这条带子和页面**看不出接缝**，只有芯片浮在上面。
    // **没有圆角、没有投影、没有描边**，不再是一张卡。
    .backgroundColor(this.themeStore.scheme.surface)
  }
}
