/*
 * 设置页（一级页，底部页签第二个）。
 *
 * 文档依据：`docs/开发指南.md` W2-T09「设置页（提醒提前量、解析方式、数据清理）」，
 * W3-T06 另有一条「云端数据：查看字段清单、一键清空、同步开关」——那是 P1，本轮**只做占位说明**，不假装接通。
 *
 * 造型沿用详情页那套「卡片 + 标签–值行」：同一套视觉语言，减少新样式。
 *
 * 持久化走 `repository/SettingsRepository`（`preferences`），页面不直接碰 `preferences`。
 * 异步读回来的值放在 `@Local`，读到再覆盖默认值（先渲染默认值，不闪空白）。
 */
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';
import { OptionPickerBody } from '../components/OptionPickerBody';
import { MainTitleBar } from '../components/MainTitleBar';
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

/** 行高（vp）：与详情页信息卡一致 */
const ROW_HEIGHT_VP: number = 56;
/** 行左右内边距（vp） */
const ROW_SIDE_PADDING_VP: number = 16;
/** 左列标签宽度（vp） */
const LABEL_WIDTH_VP: number = 120;
/** 分组之间留白（vp） */
const SECTION_GAP_VP: number = 16;
/** 页面左右留白（vp） */
const PAGE_SIDE_PADDING_VP: number = 16;
/**
 * 顶部留白（vp）：让开浮层标题栏（大标题 + 收拢态）。
 * **必须用与列表页同一个常量**（`MainTitleBar.CONTENT_TOP_OFFSET_VP`）——写死一个小值会让
 * 第一个分组标题压在「设置」大标题下面（实测 96vp 仍重叠）。
 */
const PAGE_TOP_PADDING_VP: number = MainTitleBar.CONTENT_TOP_OFFSET_VP;
/** 分隔线宽（vp） */
const DIVIDER_WIDTH_VP: number = 0.5;
/** 分组标题相对卡片左缘的内缩（vp） */
const SECTION_TITLE_INSET_VP: number = 4;
/** 分组标题与卡片间距（vp） */
const SECTION_TITLE_GAP_VP: number = 8;

/** 提醒提前量的可选档（分钟）：0 ＝ 到点提醒 */
const REMIND_LEAD_OPTIONS: number[] = [0, 5, 15, 30, 60];

/** 打开的面板 */
const SHEET_NONE: number = 0;
const SHEET_REMIND_LEAD: number = 1;
const SHEET_PARSE_MODE: number = 2;

@ComponentV2
export struct A_Settings {
  /** 任务 store：只为「清空全部任务」这一项（其余设置项与本机任务数据无关） */
  @Require @Param store: TaskListStore;

  /** 提醒提前量（分钟），异步读回来前先用默认值 */
  @Local remindLead: number = DEFAULT_REMIND_LEAD;
  /** 解析方式 */
  @Local parseMode: number = DEFAULT_PARSE_MODE;
  /** 面板草稿 */
  @Local remindLeadDraft: number = DEFAULT_REMIND_LEAD;
  @Local parseModeDraft: number = DEFAULT_PARSE_MODE;
  /** 当前面板 */
  @Local sheetKind: number = SHEET_NONE;

  aboutToAppear(): void {
    this.loadSettings();
  }

  private hostContext(): common.Context | undefined {
    return this.getUIContext().getHostContext();
  }

  /** 读首选项。读失败就保持默认值（不把错误抛到界面） */
  private async loadSettings(): Promise<void> {
    const context: common.Context | undefined = this.hostContext();
    if (context === undefined) {
      return;
    }
    this.remindLead = await SettingsRepository.getRemindLead(context);
    this.parseMode = await SettingsRepository.getParseMode(context);
  }

  /* ── 文案 ── */

  private labelText(label: Resource): string {
    try {
      const context = this.getUIContext().getHostContext();
      return context === undefined ? '' : context.resourceManager.getStringSync(label.id);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'resolve label failed: %{public}s', err.message);
      return '';
    }
  }

  /** 提醒提前量档 → 中文（0 档不说「提前 0 分钟」，说「到点提醒」） */
  private remindLeadLabel(minutes: number): string {
    if (minutes === 5) {
      return this.labelText($r('app.string.settings_remind_lead_5'));
    }
    if (minutes === 15) {
      return this.labelText($r('app.string.settings_remind_lead_15'));
    }
    if (minutes === 30) {
      return this.labelText($r('app.string.settings_remind_lead_30'));
    }
    if (minutes === 60) {
      return this.labelText($r('app.string.settings_remind_lead_60'));
    }
    return this.labelText($r('app.string.settings_remind_lead_0'));
  }

  /** 解析方式档 → 中文 */
  private parseModeLabel(mode: number): string {
    if (mode === ParseMode.LOCAL) {
      return this.labelText($r('app.string.settings_parse_local'));
    }
    if (mode === ParseMode.SERVER) {
      return this.labelText($r('app.string.settings_parse_server'));
    }
    return this.labelText($r('app.string.settings_parse_auto'));
  }

  /** 提醒提前量的选项文案（`OptionPickerBody` 只吃字符串数组） */
  @Computed
  get remindLeadOptionTexts(): string[] {
    const texts: string[] = [];
    REMIND_LEAD_OPTIONS.forEach((minutes: number) => {
      texts.push(this.remindLeadLabel(minutes));
    });
    return texts;
  }

  @Computed
  get parseModeOptionTexts(): string[] {
    return [
      this.labelText($r('app.string.settings_parse_auto')),
      this.labelText($r('app.string.settings_parse_local')),
      this.labelText($r('app.string.settings_parse_server'))
    ];
  }

  /* ── 面板 ── */

  private openRemindLeadSheet(): void {
    const index: number = REMIND_LEAD_OPTIONS.indexOf(this.remindLead);
    this.remindLeadDraft = index < 0 ? 0 : index;
    this.sheetKind = SHEET_REMIND_LEAD;
  }

  private openParseModeSheet(): void {
    this.parseModeDraft = this.parseMode;
    this.sheetKind = SHEET_PARSE_MODE;
  }

  private closeSheet(): void {
    this.sheetKind = SHEET_NONE;
  }

  /** 确定才写：先落内存（界面立刻变），再异步写盘（写失败只打日志） */
  private confirmSheet(): void {
    const context: common.Context | undefined = this.hostContext();
    if (this.sheetKind === SHEET_REMIND_LEAD) {
      this.remindLead = REMIND_LEAD_OPTIONS[this.remindLeadDraft];
      if (context !== undefined) {
        SettingsRepository.setRemindLead(context, this.remindLead);
      }
    } else if (this.sheetKind === SHEET_PARSE_MODE) {
      this.parseMode = this.parseModeDraft;
      if (context !== undefined) {
        SettingsRepository.setParseMode(context, this.parseMode);
      }
    }
    this.sheetKind = SHEET_NONE;
  }

  @Computed
  get sheetTitle(): Resource {
    return this.sheetKind === SHEET_REMIND_LEAD
      ? $r('app.string.picker_title_remind_lead')
      : $r('app.string.picker_title_parse_mode');
  }

  @Builder
  sheetBody() {
    if (this.sheetKind === SHEET_REMIND_LEAD) {
      OptionPickerBody({
        options: this.remindLeadOptionTexts,
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
        options: this.parseModeOptionTexts,
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

  /**
   * 清空本机全部任务：先弹官方警告弹窗确认，确认后逐条删除（走 `store.deleteTask`，软删语义）。
   * 用软删而不是物理删除：与详情页删除保持同一语义，将来接 `relationalStore` 时调用方式不用改。
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

  /* ── 视图 ── */

  @Builder
  sectionTitle(title: Resource) {
    Text(title)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      .width('100%')
      .padding({ left: SECTION_TITLE_INSET_VP, bottom: SECTION_TITLE_GAP_VP })
      .textAlign(TextAlign.Start)
  }

  @Builder
  rowLabel(label: Resource) {
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

  build() {
    Scroll() {
      Column() {
        // ① 提醒
        this.sectionTitle($r('app.string.settings_section_remind'))
        Column() {
          Row() {
            this.rowLabel($r('app.string.settings_remind_lead'))
            Text(this.remindLeadLabel(this.remindLead))
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .layoutWeight(1)
              .maxLines(1)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.openRemindLeadSheet();
          })
          .bindSheet(this.sheetKind === SHEET_REMIND_LEAD, this.sheetBody(), {
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
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
        .clip(true)

        // ② 解析
        Column() {
          this.sectionTitle($r('app.string.settings_section_parse'))
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          Row() {
            this.rowLabel($r('app.string.settings_parse_mode'))
            Text(this.parseModeLabel(this.parseMode))
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .layoutWeight(1)
              .maxLines(1)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.openParseModeSheet();
          })
          .bindSheet(this.sheetKind === SHEET_PARSE_MODE, this.sheetBody(), {
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
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
        .clip(true)

        // ③ 数据
        Column() {
          this.sectionTitle($r('app.string.settings_section_data'))
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          // 清空全部任务（危险操作，文案用警示色）
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

          // 云端同步：P1 未接入，**如实标"未接入"**，不做成可点的假开关
          Row() {
            Text($r('app.string.settings_cloud_off'))
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .layoutWeight(1)
              .maxLines(1)
              .textAlign(TextAlign.Start)
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
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
