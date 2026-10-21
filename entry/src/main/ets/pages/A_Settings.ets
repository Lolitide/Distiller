/*
 * 设置页（一级页，底部页签第二个）。
 *
 * ## 2026-10-19 第二版重做（作者反馈）
 *
 * 上一版被批「滥用按钮」：密度、提前量、解析方式全铺成一排按钮。
 * 这一版按作者的原话改：
 *   · **主题色** → 三个**颜色圆点**（不写色名）；
 *   · **卡片密度 / 提醒提前量 / 解析方式** → **点一行弹选择器**，不再铺按钮；
 *   · 权限管理补齐 **通知 / 日历 / 订阅消息管理** 三项（先占位，如实标未接入）；
 *   · 修「滑到底看不全」：`Scroll` 加 `contentEndOffset`，最后一项不再被页签栏压住；
 *   · 修「大标题压住内容」：让位段做成内容首项，与任务列表同一套。
 *
 * 取值纪律：颜色/间距/字号来自 `utils/Theme.ets` 或官方语义 token。
 */
import { common } from '@kit.AbilityKit';
import { bundleManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';
import {
  ACCENT_OPTIONS,
  AccentOption,
  DENSITY_COMPACT,
  DENSITY_STANDARD,
  Theme,
  ThemeStore
} from '../utils/Theme';
import {
  DEFAULT_PARSE_MODE,
  DEFAULT_REMIND_LEAD,
  ParseMode,
  SettingsRepository
} from '../repository/SettingsRepository';
import { OptionPickerBody } from '../components/OptionPickerBody';
import { SettingsNavRow } from '../components/SettingsNavRow';
import { PopupSelector } from '../components/PopupSelector';
import { ToggleSlider } from '../components/ToggleSlider';
import { Task } from '../model';
import { TaskListStore } from '../viewmodel/TaskListStore';
import { WindowInsets } from '../utils/WindowInsets';

const DOMAIN: number = 0x0000;
const TAG: string = 'A_Settings';

/** 行高（vp） */
const ROW_HEIGHT_VP: number = 56;
/** 行左右内边距（vp） */
const ROW_SIDE_PADDING_VP: number = 16;
/** 左列标签宽度（vp） */
const LABEL_WIDTH_VP: number = 108;
/** 分组之间留白（vp） */
const SECTION_GAP_VP: number = 16;
/** 页面左右留白（vp） */
const PAGE_SIDE_PADDING_VP: number = 16;
/**
 * 让开浮层标题栏的高度（vp）：与任务列表同一个来历 —— 把这一段做成**内容首项**，
 * 标题才会跟着滚动收缩；用固定 `padding-top` 的话，滚起来大字会压在内容上（上一版就是这么坏的）。
 */
const TITLE_CLEARANCE_VP: number = 64;
/** 让开悬浮页签栏（vp）：与 `A_TaskList.LIST_BOTTOM_CLEARANCE_VP` 同值 */
const BOTTOM_CLEARANCE_VP: number = 80;

/**
 * 底部渐变遮罩高度（vp）：与 A_TaskList.BOTTOM_MASK_VP 同值同理由 ——
 * 弃用 HdsTabs 后 gradientMask 跟着没了，内容会在视口底边被齐切（2026-10-20 截图下方两个箭头）。
 * 取 100 而不是当时的 140，理由见 `A_TaskList.BOTTOM_MASK_VP`（实色渐变比旧的 40% 遮罩强，140 会洗白最后一项）。
 */
const BOTTOM_MASK_VP: number = 140;
/** 分隔线宽（vp） */
const DIVIDER_WIDTH_VP: number = 0.5;
/** 分组标题内缩 / 与卡片间距（vp） */
const SECTION_TITLE_INSET_VP: number = 4;
const SECTION_TITLE_GAP_VP: number = 8;
/** 主题色圆点直径（vp） */
const ACCENT_DOT_SIZE_VP: number = 28;
/**
 * 主题色选中时，叠加在色板上的「白圈」与色板边缘之间的间距（vp）。
 * 白圈直径 = 色板直径 − 2×本值 → 它比按钮小一圈，色板只剩一道色环。
 */
const ACCENT_SELECT_RING_VP: number = 5;

/** 提醒提前量的可选档（分钟）：0 ＝ 到点提醒 */
const REMIND_LEAD_OPTIONS: number[] = [0, 5, 15, 30, 60];
/** 解析方式的档位文案 */
const PARSE_MODE_OPTIONS: string[] = ['自动（端侧优先）', '仅本机', '服务端'];
/** 卡片密度的档位文案 */
const DENSITY_OPTIONS: string[] = ['标准', '紧凑'];

/** 当前打开的选择器（卡片密度已改成页内滑动控件，不再走弹窗） */
const SHEET_NONE: number = 0;
const SHEET_REMIND_LEAD: number = 2;
const SHEET_PARSE_MODE: number = 3;

@ComponentV2
export struct A_Settings {
  /** 任务 store：清空任务 + 提醒提前量同步 */
  @Require @Param store: TaskListStore;

  /**
   * 滚动控制器：由 `A_Main` 创建、经 `MainTabBar` 传进来，
   * `HdsNavigation.bindToScrollable` 要绑同一个对象 —— 不绑的话导航栏大标题
   * 在设置页滚动时不会收缩，会**静默压在内容上**（实测过）。
   */
  @Require @Param scroller: Scroller;

  /** 视觉个性化状态（跨页共享，见 utils/Theme.ets） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /**
   * 底部遮罩的两端色（`GradientDirection.Bottom`：第一项画在**上**边，所以上透下实）。
   * 与 `A_TaskList.bottomMaskColors` 同一套算法，色相都取当前主题的 `surface`。
   */
  @Computed
  get bottomMaskColors(): Array<[ResourceColor, number]> {
    const surface: string = this.themeStore.scheme.surface;
    const colors: Array<[ResourceColor, number]> = [
      // 与 `A_TaskList.bottomMaskColors` 同一套 6 档色标（理由见那里：胶囊上沿要有 ~55% 遮挡）
      [Theme.withAlpha(surface, '00'), 0.0],
      [Theme.withAlpha(surface, '40'), 0.25],
      [Theme.withAlpha(surface, '8C'), 0.49],
      [Theme.withAlpha(surface, 'CC'), 0.70],
      [Theme.withAlpha(surface, 'EE'), 0.85],
      [Theme.withAlpha(surface, 'FF'), 1.0]
    ];
    return colors;
  }

  /**
   * 状态栏高度（vp）：窗口全屏后页面铺到屏幕顶端，内容要让开这一截（见 utils/WindowInsets）。
   */
  @Local statusBarVp: number = 0;

  @Local remindLead: number = DEFAULT_REMIND_LEAD;
  @Local parseMode: number = DEFAULT_PARSE_MODE;

  /** 当前打开的选择器 */
  @Local sheetKind: number = SHEET_NONE;
  /** 选择器草稿 */
  @Local remindLeadDraft: number = DEFAULT_REMIND_LEAD;
  @Local parseModeDraft: number = DEFAULT_PARSE_MODE;

  aboutToAppear(): void {
    this.loadSettings();
    // 窗口全屏后页面铺到屏幕顶端，顶部让位要补上状态栏高度（见 utils/WindowInsets）
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context !== undefined) {
      WindowInsets.topPx(context).then((px: number) => {
        this.statusBarVp = px > 0 ? this.getUIContext().px2vp(px) : 0;
      });
    }
  }

  private hostContext(): common.Context | undefined {
    return this.getUIContext().getHostContext();
  }

  private async loadSettings(): Promise<void> {
    const context: common.Context | undefined = this.hostContext();
    if (context === undefined) {
      return;
    }
    this.remindLead = await SettingsRepository.getRemindLead(context);
    this.parseMode = await SettingsRepository.getParseMode(context);
    this.store.remindLeadMinutes = this.remindLead;
    // 视觉效果持久化（2026-10-19）：主题色与卡片密度重启后要记住
    this.themeStore.accentIndex = await SettingsRepository.getThemeAccent(context, this.themeStore.accentIndex);
    this.themeStore.density = await SettingsRepository.getDensity(context, this.themeStore.density);
  }

  /* ── 文案 ── */

  /** 提醒提前量的文案数组（PopupSelector 要整组文案） */
  @Computed
  get remindLeadOptionLabels(): string[] {
    return REMIND_LEAD_OPTIONS.map((minutes: number) => this.remindLeadLabel(minutes));
  }

  private remindLeadLabel(minutes: number): string {
    if (minutes === 0) {
      return '到点提醒';
    }
    if (minutes === 60) {
      return '提前 1 小时';
    }
    return `提前 ${minutes} 分钟`;
  }

  private parseModeLabel(mode: number): string {
    return PARSE_MODE_OPTIONS[mode < 0 || mode >= PARSE_MODE_OPTIONS.length ? 0 : mode];
  }

  /** 版本号从安装包读，不写死 */
  @Computed
  get versionLabel(): string {
    try {
      const info: bundleManager.BundleInfo = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      return info.versionName === undefined ? '—' : info.versionName;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'read version failed: %{public}s', err.message);
      return '—';
    }
  }

  /* ── 写入 ── */

  private applyRemindLead(minutes: number): void {
    this.remindLead = minutes;
    // 同步给 store：列表铃铛按它算 remindAt（页签切换不会重跑 aboutToAppear，必须直接写）
    this.store.remindLeadMinutes = minutes;
    const context: common.Context | undefined = this.hostContext();
    if (context !== undefined) {
      SettingsRepository.setRemindLead(context, minutes);
    }
  }

  /** 切换主题色：先改内存（界面立刻变色），再异步落盘 */
  private applyAccent(index: number): void {
    this.themeStore.accentIndex = index;
    const context: common.Context | undefined = this.hostContext();
    if (context !== undefined) {
      SettingsRepository.setThemeAccent(context, index);
    }
  }

  /** 切换卡片密度：同上 */
  private applyDensity(index: number): void {
    this.themeStore.density = index;
    const context: common.Context | undefined = this.hostContext();
    if (context !== undefined) {
      SettingsRepository.setDensity(context, index);
    }
  }

  private applyParseMode(mode: number): void {
    this.parseMode = mode;
    const context: common.Context | undefined = this.hostContext();
    if (context !== undefined) {
      SettingsRepository.setParseMode(context, mode);
    }
  }

  /* ── 选择器 ── */

  private openSheet(kind: number): void {
    if (kind === SHEET_REMIND_LEAD) {
      const index: number = REMIND_LEAD_OPTIONS.indexOf(this.remindLead);
      this.remindLeadDraft = index < 0 ? 0 : index;
    } else if (kind === SHEET_PARSE_MODE) {
      this.parseModeDraft = this.parseMode;
    }
    this.sheetKind = kind;
  }

  private closeSheet(): void {
    this.sheetKind = SHEET_NONE;
  }

  private confirmSheet(): void {
    if (this.sheetKind === SHEET_REMIND_LEAD) {
      this.applyRemindLead(REMIND_LEAD_OPTIONS[this.remindLeadDraft]);
    } else if (this.sheetKind === SHEET_PARSE_MODE) {
      this.applyParseMode(this.parseModeDraft);
    }
    this.sheetKind = SHEET_NONE;
  }

  @Computed
  get sheetTitle(): ResourceStr {
    if (this.sheetKind === SHEET_REMIND_LEAD) {
      return '提醒提前量';
    }
    return '解析方式';
  }

  @Builder
  sheetBody() {
    if (this.sheetKind === SHEET_REMIND_LEAD) {
      OptionPickerBody({
        options: [
          this.remindLeadLabel(0), this.remindLeadLabel(5), this.remindLeadLabel(15),
          this.remindLeadLabel(30), this.remindLeadLabel(60)
        ],
        selectedIndex: this.remindLeadDraft,
        onSelectedIndexChange: (index: number) => {
          this.remindLeadDraft = index;
        },
        onCancel: () => {
          this.closeSheet();
        },
        onConfirm: () => {
          this.confirmSheet();
        }
      })
    } else {
      OptionPickerBody({
        options: PARSE_MODE_OPTIONS,
        selectedIndex: this.parseModeDraft,
        onSelectedIndexChange: (index: number) => {
          this.parseModeDraft = index;
        },
        onCancel: () => {
          this.closeSheet();
        },
        onConfirm: () => {
          this.confirmSheet();
        }
      })
    }
  }

  /* ── 数据清理 ── */

  private toast(message: ResourceStr): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'toast failed: %{public}s', err.message);
    }
  }

  private clearAllTasks(): void {
    const total: number = this.store.totalCount;
    if (total === 0) {
      this.toast($r('app.string.settings_clear_empty'));
      return;
    }
    this.getUIContext().getPromptAction().showDialog({
      title: $r('app.string.settings_clear_tasks'),
      message: $r('app.string.settings_clear_confirm'),
      buttons: [
        { text: $r('app.string.action_cancel'), color: $r('sys.color.ohos_id_color_text_primary') },
        { text: $r('app.string.action_delete'), color: $r('sys.color.ohos_id_color_warning') }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index !== 1) {
        return;
      }
      const ids: number[] = [];
      this.store.allTasks().forEach((task: Task) => {
        ids.push(task.id);
      });
      let removed: number = 0;
      ids.forEach((id: number) => {
        if (this.store.deleteTask(id)) {
          removed++;
        }
      });
      this.toast($r('app.string.settings_clear_done', removed));
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'clear dialog failed: %{public}d, %{public}s', error.code, error.message);
    });
  }

  /* ── 视图构件 ── */

  @Builder
  sectionTitle(title: ResourceStr) {
    Text(title)
      .fontSize(Theme.FONT_CAPTION)
      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      .width('100%')
      .padding({ left: SECTION_TITLE_INSET_VP, bottom: SECTION_TITLE_GAP_VP })
      .textAlign(TextAlign.Start)
  }

  @Builder
  rowDivider() {
    Divider()
      .strokeWidth(DIVIDER_WIDTH_VP)
      .color($r('sys.color.comp_divider'))
      .margin({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
  }

  /** 「左标签 + 右说明」的只读行（未接入项用） */
  @Builder
  infoRow(label: ResourceStr, value: string) {
    Row() {
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .layoutWeight(1)
        .maxLines(1)
        .textAlign(TextAlign.Start)
      Text(value)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .maxLines(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .height(ROW_HEIGHT_VP)
    .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 卡片密度：**二档滑动控件**（2026-10-19 作者要求）。
   *
   * 之前是「点一行 → 弹选择器 → 再点确定」，两个动作才改一个二选一的开关；
   * 而且右侧那行值因为 `@Builder` 值参数不刷新，选完还显示旧值。
   * 现在一行内直接滑动切换，值也由 `@Param` 响应式驱动。
   */
  @Builder
  densityRow() {
    Row() {
      Text('卡片密度')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .width(LABEL_WIDTH_VP)
        .maxLines(1)
        .textAlign(TextAlign.Start)

      Blank()

      ToggleSlider({
        options: DENSITY_OPTIONS,
        selectedIndex: this.themeStore.density,
        onSelect: (index: number) => {
          this.applyDensity(index);
        }
      })
    }
    .width('100%')
    .height(ROW_HEIGHT_VP)
    .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
  }

  /** 主题色：三个**颜色圆点**，不写色名（2026-10-19 作者要求） */
  @Builder
  accentDots() {
    Row() {
      Text('主题色')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .layoutWeight(1)
        .maxLines(1)
        .textAlign(TextAlign.Start)

      Row({ space: Theme.GAP_M }) {
        ForEach(ACCENT_OPTIONS, (option: AccentOption, index: number) => {
          Stack() {
            // 色板本体：整圆（这一个就是"按钮"）
            Row()
              .width(ACCENT_DOT_SIZE_VP)
              .height(ACCENT_DOT_SIZE_VP)
              .backgroundColor(option.light)
              .borderRadius(ACCENT_DOT_SIZE_VP / 2)

            // 选中态：**一个略小于按钮的白圈**（2026-10-19 作者要求）。
            // 之前是给外圈加深色描边，跟色板本身的形状打架；
            // 现在在色板上叠一个居中的白色实心圆，色板只剩一道色环，
            // 一眼能看出当前选的是哪一个，也不遮挡颜色本身。
            if (this.themeStore.accentIndex === index) {
              Row()
                .width(ACCENT_DOT_SIZE_VP - ACCENT_SELECT_RING_VP * 2)
                .height(ACCENT_DOT_SIZE_VP - ACCENT_SELECT_RING_VP * 2)
                .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
                .borderRadius((ACCENT_DOT_SIZE_VP - ACCENT_SELECT_RING_VP * 2) / 2)
                .transition(TransitionEffect.OPACITY.animation({ duration: 150 }))
            }
          }
          .width(Theme.HIT_MIN)
          .height(Theme.HIT_MIN)
          .onClick(() => {
            this.applyAccent(index);
          })
          .accessibilityText(option.label)
        }, (option: AccentOption, index: number) => `${option.label}-${index}`)
      }
    }
    .width('100%')
    .height(ROW_HEIGHT_VP)
    .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
  }

  build() {
    // 外面套一层 Stack：底部要叠一条渐变遮罩（内容淡出而不是被齐切）
    Stack({ alignContent: Alignment.Bottom }) {
    Column() {
      // **让位放在 Scroll 外面**（2026-10-19 修「滚动后内容压在标题上」）：
      // 原来这段占位是 Scroll 的**内容首项**，滚动时它会带着正文一起上移，
      // 正文就钻到标题栏/状态栏区域、与「设置」叠字（实测状态栏变成  8:1提醒提前量）。
      // 放到外面后，**滚动视口本身**从标题栏下方开始，正文永远进不了标题区。
      Row().width('100%').height(TITLE_CLEARANCE_VP + this.statusBarVp)

      Scroll() {
      Column() {

        // ① 视觉个性化
        this.sectionTitle('视觉个性化')
        Column() {
          this.accentDots()
          this.rowDivider()
          // 卡片密度：**二档滑动控件**（2026-10-19 作者要求，不再弹选择器）
          this.densityRow()
        }
        .width('100%')
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ② 通知个性化
        Column() {
          this.sectionTitle('通知个性化')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          // 2026-10-19：改成**锚定浮窗**（图二样式），不再是整屏底部面板
          PopupSelector({
            label: '提醒提前量',
            value: this.remindLeadLabel(this.remindLead),
            options: this.remindLeadOptionLabels,
            selectedIndex: REMIND_LEAD_OPTIONS.indexOf(this.remindLead),
            onSelect: (index: number) => {
              this.applyRemindLead(REMIND_LEAD_OPTIONS[index]);
            }
          })
        }
        .width('100%')
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ③ 权限管理：通知 / 日历 / 订阅消息（先占位，如实标未接入）
        Column() {
          this.sectionTitle('权限管理')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          this.infoRow('通知权限', '未接入')
          this.rowDivider()
          this.infoRow('日历权限', '未接入')
          this.rowDivider()
          this.infoRow('订阅消息管理', '未接入')
        }
        .width('100%')
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ④ 解析
        Column() {
          this.sectionTitle('解析')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          PopupSelector({
            label: '解析方式',
            value: this.parseModeLabel(this.parseMode),
            options: PARSE_MODE_OPTIONS,
            selectedIndex: this.parseMode,
            onSelect: (index: number) => {
              this.applyParseMode(index);
            }
          })
        }
        .width('100%')
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ⑤ 数据
        Column() {
          this.sectionTitle('数据')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          Row() {
            Text($r('app.string.settings_clear_tasks'))
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_warning'))
              .layoutWeight(1)
              .maxLines(1)
              .textAlign(TextAlign.Start)
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.clearAllTasks();
          })

          this.rowDivider()
          this.infoRow($r('app.string.settings_cloud_off'), '')
        }
        .width('100%')
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ⑥ 关于
        Column() {
          this.sectionTitle('关于')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          this.infoRow('版本', this.versionLabel)
          this.rowDivider()
          this.infoRow('隐私说明', '未接入')
        }
        .width('100%')
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // 底部让开悬浮页签栏：不留这段的话最后一项会被压住（上一版就是漏了它）
        Row().width('100%').height(BOTTOM_CLEARANCE_VP)
      }
      .width('100%')
      .padding({ left: PAGE_SIDE_PADDING_VP, right: PAGE_SIDE_PADDING_VP })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    // M3：设置页底色 = `surface`（与任务列表一致）。
    // ⚠️ 这里原来**后面还有一句** `.backgroundColor($r('sys.color.ohos_id_color_sub_background'))`
    // —— 后写者生效，把 surface 覆盖成了系统浅蓝，导致设置页底色与暖色主题不搭
    //（作者 2026-10-19 截图箭头指的就是这块）。已删掉那一句。
    .backgroundColor(this.themeStore.scheme.surface)
    .scrollBar(BarState.Off)
    // 2026-10-19 作者：「设置页滑动怎么没有像任务页一样的回弹效果」——
    // 任务页的 List 有 `EdgeEffect.Spring`，这里漏了，补上。
    .edgeEffect(EdgeEffect.Spring)
    .layoutWeight(1)
    // 2026-10-19 设置页调研：**底部要让开悬浮页签栏**。
    // 任务页有 `LIST_BOTTOM_CLEARANCE_VP`(80)，设置页漏了 →
    // 实测「云端同步（未接入）」「关于」被底部胶囊压住一半（截图 CA1-settings-audit.png）。
    .contentEndOffset(80)
    .align(Alignment.Top)
    .width('100%')
    .layoutWeight(1)
    .bindSheet(this.sheetKind !== SHEET_NONE, this.sheetBody(), {
      title: { title: this.sheetTitle },
      preferType: SheetType.CENTER,
      height: SheetSize.FIT_CONTENT,
      showClose: false,
      dragBar: false,
      onDisappear: () => {
        this.sheetKind = SHEET_NONE;
      }
    })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeStore.scheme.surface)
    // 2026-10-20 取消全屏沉浸：原来这里还有一行 `.expandSafeArea([SYSTEM], [BOTTOM])`，
    // 让底色铺到手势条底下。现在页面不再伸进系统栏，底部那截交给系统栏背景色（`A_Main.applyWindowTheme`）。

    // **底部渐变遮罩**：与任务列表同一套做法，内容滑到胶囊/＋ 那一带时淡出
    Column()
      .width('100%')
      .height(BOTTOM_MASK_VP)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: this.bottomMaskColors
      })
      .hitTestBehavior(HitTestMode.None)
    }
    .width('100%')
    .height('100%')
  }
}
