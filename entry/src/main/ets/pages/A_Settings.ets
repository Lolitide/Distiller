/*
 * 设置页（一级页，底部页签第二个）。
 *
 * 分组依据（2026-10-19 重新排布）：
 *   视觉个性化 / 通知个性化 / 权限管理 / 解析 / 数据 / 关于
 * 其中「提醒提前量、解析方式、数据清理」来自 `docs/开发指南.md` W2-T09；
 * 「云端数据」一节来自 W3-T06（P1，本轮**只占位**）；
 * 「视觉个性化 / 通知个性化 / 权限管理 / 关于」四类由 2026-10-19 的需求补齐。
 *
 * 交互约定（2026-10-19：「模态动画滥用」）：
 *   能在页面上直接选的三档就**内联分段按钮**，不再开半模态；
 *   只有「清空数据」这类危险动作才弹官方确认框。
 *
 * 取值纪律（技能硬约束第 5 条）：颜色/间距/字号一律来自 `utils/Theme.ets`
 * 或官方语义 token（`$r('sys.*')`），本文件不写裸色值。
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
import { Task } from '../model';
import { TaskListStore } from '../viewmodel/TaskListStore';

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
/** 顶部留白（vp）：让开浮层标题栏（值同 MainTitleBar.CONTENT_TOP_OFFSET_VP） */
const PAGE_TOP_PADDING_VP: number = 112;
/** 分隔线宽（vp） */
const DIVIDER_WIDTH_VP: number = 0.5;
/** 分组标题内缩 / 与卡片间距（vp） */
const SECTION_TITLE_INSET_VP: number = 4;
const SECTION_TITLE_GAP_VP: number = 8;
/** 分段按钮的高度与圆角（vp） */
const SEGMENT_HEIGHT_VP: number = 32;
/** 分段按钮之间的间距（vp） */
const SEGMENT_GAP_VP: number = 8;

/** 提醒提前量的可选档（分钟）：0 ＝ 到点提醒 */
const REMIND_LEAD_OPTIONS: number[] = [0, 5, 15, 30, 60];

@ComponentV2
export struct A_Settings {
  /** 任务 store：只为「清空全部任务」这一项 */
  @Require @Param store: TaskListStore;

  /** 视觉个性化状态（跨页共享，见 utils/Theme.ets） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 提醒提前量（分钟），异步读回来前先用默认值 */
  @Local remindLead: number = DEFAULT_REMIND_LEAD;
  /** 解析方式 */
  @Local parseMode: number = DEFAULT_PARSE_MODE;

  aboutToAppear(): void {
    this.loadSettings();
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
    // 启动时把已存的提前量同步给 store，否则首次进列表时铃铛算不出 remindAt
    this.store.remindLeadMinutes = this.remindLead;
    this.parseMode = await SettingsRepository.getParseMode(context);
  }

  private parseModeLabel(mode: number): string {
    if (mode === ParseMode.LOCAL) {
      return '仅本机';
    }
    if (mode === ParseMode.SERVER) {
      return '服务端';
    }
    return '自动';
  }

  /** 提醒提前量：先落内存（界面立刻变），再异步写盘 */
  private applyRemindLead(minutes: number): void {
    this.remindLead = minutes;
    // 同步给 store：列表卡片的铃铛按它算 remindAt。
    // （`A_Main.aboutToAppear` 只在启动时跑一次，页签切换不会重跑 → 不在这写就永远不生效）
    this.store.remindLeadMinutes = minutes;
    const context: common.Context | undefined = this.hostContext();
    if (context !== undefined) {
      SettingsRepository.setRemindLead(context, minutes);
    }
  }

  private applyParseMode(mode: number): void {
    this.parseMode = mode;
    const context: common.Context | undefined = this.hostContext();
    if (context !== undefined) {
      SettingsRepository.setParseMode(context, mode);
    }
  }

  /** 版本号**从安装包读**，不写死（写死会随发版漂移） */
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

  /* ── 数据清理 ── */

  private toast(message: ResourceStr): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'toast failed: %{public}s', err.message);
    }
  }

  /**
   * 清空本机全部任务：先弹官方警告弹窗确认，确认后逐条软删（与详情页删除同一语义）。
   */
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
  rowLabel(label: ResourceStr) {
    Text(label)
      .fontSize($r('sys.float.ohos_id_text_size_body1'))
      .fontColor($r('sys.color.ohos_id_color_text_primary'))
      .width(LABEL_WIDTH_VP)
      .maxLines(1)
      .textAlign(TextAlign.Start)
  }

  @Builder
  rowDivider() {
    Divider()
      .strokeWidth(DIVIDER_WIDTH_VP)
      .color($r('sys.color.comp_divider'))
      .margin({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
  }

  /**
   * 内联分段按钮（一颗）。
   *
   * ⚠️ `@Builder` 的**值参数不随状态刷新**（本项目踩过两次：卡片行、详情信息卡）。
   * 所以 `selected` 不能在构建后靠参数更新 —— 各行的 `selected` 必须在**调用点**读
   * `this.*` 状态、由外层重渲染时重新求值（见下面每个 `xxxRow()`）。
   */
  @Builder
  segment(text: string, selected: boolean, onTap: () => void) {
    Text(text)
      .fontSize(Theme.FONT_BODY)
      .fontColor(selected
        ? $r('sys.color.ohos_id_color_text_primary_contrary')
        : $r('sys.color.ohos_id_color_text_primary'))
      .height(SEGMENT_HEIGHT_VP)
      .padding({ left: Theme.GAP_S, right: Theme.GAP_S })
      .backgroundColor(selected
        ? ThemeStore.instance().accent.light
        : $r('sys.color.comp_background_secondary'))
      .borderRadius(SEGMENT_HEIGHT_VP / 2)
      .textAlign(TextAlign.Center)
      .onClick(onTap)
  }

  /* ① 视觉个性化：主题色 */

  @Builder
  accentRow() {
    Row() {
      this.rowLabel('主题色')
      Row({ space: SEGMENT_GAP_VP }) {
        ForEach(ACCENT_OPTIONS, (option: AccentOption, index: number) => {
          this.segment(option.label, this.themeStore.accentIndex === index, () => {
            this.themeStore.accentIndex = index;
          })
        }, (option: AccentOption, index: number) => `${option.label}-${index}`)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .height(ROW_HEIGHT_VP)
    .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
  }

  /* ① 视觉个性化：卡片密度 */

  @Builder
  densityRow() {
    Row() {
      this.rowLabel('卡片密度')
      Row({ space: SEGMENT_GAP_VP }) {
        this.segment('标准', this.themeStore.density === DENSITY_STANDARD, () => {
          this.themeStore.density = DENSITY_STANDARD;
        })
        this.segment('紧凑', this.themeStore.density === DENSITY_COMPACT, () => {
          this.themeStore.density = DENSITY_COMPACT;
        })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .height(ROW_HEIGHT_VP)
    .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
  }

  /* ② 通知个性化：提醒提前量 */

  /**
   * 提醒提前量：**标签在上、分段占满整行**。
   *
   * 这一行有 5 个档位，和左侧 108vp 标签挤在同一行时放不下：
   * 实测 377vp 屏上「60 分」被压到只剩 52px（文字被裁）。所以本行改成两段式布局，
   * 其余只有 2~3 档的行仍用「左标签 + 右分段」的一行式。
   */
  @Builder
  remindLeadRow() {
    Column() {
      Text('提醒提前量')
        .fontSize(Theme.FONT_BODY)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .width('100%')
        .maxLines(1)
        .textAlign(TextAlign.Start)

      Row({ space: SEGMENT_GAP_VP }) {
        // 文案取最短形态（「到点」「5分」…），5 个分段要挤进 329vp
        ForEach(REMIND_LEAD_OPTIONS, (minutes: number) => {
          this.segment(minutes === 0 ? '到点' : `${minutes}分`,
            this.remindLead === minutes, () => {
              this.applyRemindLead(minutes);
            })
        }, (minutes: number) => `${minutes}`)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .margin({ top: Theme.GAP_S })
    }
    .width('100%')
    .padding({
      left: ROW_SIDE_PADDING_VP,
      right: ROW_SIDE_PADDING_VP,
      top: Theme.GAP_M,
      bottom: Theme.GAP_M
    })
    .alignItems(HorizontalAlign.Start)
  }

  /* ③ 权限管理（未接入，如实标注） */

  @Builder
  permissionRow() {
    Row() {
      this.rowLabel('通知权限')
      Text('未接入')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .layoutWeight(1)
        .maxLines(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .height(ROW_HEIGHT_VP)
    .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
  }

  /* ④ 解析：解析方式 */

  @Builder
  parseModeRow() {
    Row() {
      this.rowLabel('解析方式')
      Row({ space: SEGMENT_GAP_VP }) {
        this.segment('自动', this.parseMode === ParseMode.AUTO, () => {
          this.applyParseMode(ParseMode.AUTO);
        })
        this.segment('仅本机', this.parseMode === ParseMode.LOCAL, () => {
          this.applyParseMode(ParseMode.LOCAL);
        })
        this.segment('服务端', this.parseMode === ParseMode.SERVER, () => {
          this.applyParseMode(ParseMode.SERVER);
        })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .height(ROW_HEIGHT_VP)
    .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
  }

  /** 一行普通文本（左标签 + 右说明），给"只读 / 未接入"项用 */
  @Builder
  plainRow(label: ResourceStr, value: string) {
    Row() {
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .layoutWeight(1)
        .maxLines(1)
        .textAlign(TextAlign.Start)
      if (value !== '') {
        Text(value)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .maxLines(1)
          .textAlign(TextAlign.End)
      }
    }
    .width('100%')
    .height(ROW_HEIGHT_VP)
    .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Scroll() {
      Column() {
        // ① 视觉个性化
        this.sectionTitle('视觉个性化')
        Column() {
          this.accentRow()
          this.rowDivider()
          this.densityRow()
        }
        .width('100%')
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ② 通知个性化
        Column() {
          this.sectionTitle('通知个性化')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          this.remindLeadRow()
        }
        .width('100%')
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ③ 权限管理
        Column() {
          this.sectionTitle('权限管理')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          this.permissionRow()
        }
        .width('100%')
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ④ 解析
        Column() {
          this.sectionTitle('解析')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          this.parseModeRow()
        }
        .width('100%')
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
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
          // 云端同步：P1 未接入，如实标注，不做假开关
          this.plainRow($r('app.string.settings_cloud_off'), '')
        }
        .width('100%')
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ⑥ 关于
        Column() {
          this.sectionTitle('关于')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          this.plainRow('版本', this.versionLabel)
          this.rowDivider()
          this.plainRow('隐私说明', '未接入')
        }
        .width('100%')
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)
      }
      .width('100%')
      .padding({
        left: PAGE_SIDE_PADDING_VP,
        right: PAGE_SIDE_PADDING_VP,
        top: PAGE_TOP_PADDING_VP,
        bottom: SECTION_GAP_VP
      })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}
