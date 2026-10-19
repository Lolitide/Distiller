/*
 * 「添加任务」的**属性芯片行**（截止日期 / 提醒我 / 重复 / 重要程度 / 来源 / 添加标签）。
 *
 * 袁正锟 2026-10-17（贴图）：「下面加一个 ChipGroup 一行装不下了自动再开一行 排版如图 去掉完成耗时」；
 * 随后两条：「现在做设置截止日期…选到时间了 Chip 就显示 xx月xx日 到期 后面有一个叉叉 点击后清空这一项」、
 * 「现在做提醒我…选到时间了 Chip 就显示 在 xx月xx日 xx:xx 提醒我 后面有一个叉叉 点击后清空这一项」。
 *
 * 🔴 **为什么不是官方 `ChipGroup`**：官方 `ChipGroup` 只有**一行** —— 文档里没有任何换行/溢出参数，
 * 项目里 `TaskFilterChips` 就是因为它既不滚动也不换行，才在外面套了一层横向 `Scroll`；
 * 而 V2 版 `ChipGroupV2` 是 **`@since 26.0.0`**，本项目 target 6.0.2(22) 用不了。
 * 所以这里用**官方 `Chip` 组件**（`@since 11`）＋ `Flex({ wrap: FlexWrap.Wrap })`：
 * chip 本身还是官方的，「一行装不下自动换行」交给 Flex 的 wrap。
 *
 * **已接好交互的两项**（截止日期 / 提醒我）走同一套形态：
 *  · 没选 → chip 显示「设置到期日期」/「提醒我」，点它拉起**日期＋时间**面板；
 *  · 选了 → chip 显示「10月20日 到期」/「在 10月20日 23:59 提醒我」，末尾带 **×**（官方 `Chip` 的 `allowClose`）：
 *    点 × 清空这一项，点 chip 本体则是重新选；
 *  · 草稿与「确定才写回」的规矩与详情页一致：面板跟手改的是 draft，点「确定」才落库。
 *
 * **一个面板管两项**（`pickerKind`）：`bindSheet` 挂两处容易互相打架，所以只有一个宿主、一份 body，
 * 标题与 body 按 `pickerKind` 切（到期 → `picker_title_due`，提醒 → `picker_title_remind`）。
 *
 * ⚠️ 官方 `Chip` 的三处约束（前两条与 `TaskFilterChips` 踩过的一致）：
 *  · `label.text` 只吃 **string**（`LabelOptions.text: string`），`$r()` 资源要先解成字符串；
 *  · 前缀图标走 `prefixSymbol.normal: SymbolGlyphModifier`（HM Symbol），不是 `prefixIcon` 的位图；
 *  · **不显式 `allowClose: false` 就自带一个 × 删除按钮**；而「有值 / 无值」必须渲染成**两个分支**
 *    （两个节点）—— 否则点过自带的 × 之后整颗 chip 会消失（见 `dueChip()` 的注释）。
 *
 * 其余三项（重复 / 重要程度 / 来源）与「添加标签」**还没接**交互，等下一步照同一套铺开。
 */
import { Chip, ChipSize, LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { TaskListViewModel } from '../viewmodel/TaskListViewModel';
import { AddTaskDraft } from '../viewmodel/AddTaskDraft';
import { DateTimePickerBody } from './DateTimePickerBody';
import { OptionPickerBody } from './OptionPickerBody';
import { RepeatRuleEditor } from './RepeatRuleEditor';
import { RepeatRule } from '../model';
import { TagInputBody } from './TagInputBody';

const DOMAIN: number = 0x0000;
const TAG: string = 'AddTaskAttributeChips';

/** chip 间距（vp）：主/交叉轴各 8vp，＝官方 `sys.float.padding_level4` */
const CHIP_GAP_VP: number = 8;

/** 自绘 chip 里「图标 ↔ 文字」的间距（vp）：＝官方 `chip_small_text_margin`(4vp)，`Row({space})` 只吃 number */
const CHIP_TEXT_MARGIN_VP: number = 4;

/**
 * chip 末尾那颗 × 的**点击区**边长（vp）。
 * 图标本身只有 `chip_small_icon_size`（约 16vp），实测直接点它很容易点空（`.cache/src-5-set.png` 那次就没点中，
 * 反而命中了上一行的 chip）。给它一个 24vp 的稳定热区，图标在里面居中。
 */
const CHIP_CLEAR_HIT_VP: number = 24;

/** 「还没设置」的哨兵值（0 不可能是合法的时间戳） */
const UNSET: number = 0;

/** 当前打开的是哪个面板（0 ＝ 没开） */
const PICKER_NONE: number = 0;
const PICKER_DUE: number = 1;
const PICKER_REMIND: number = 2;
const PICKER_REPEAT: number = 3;
const PICKER_PRIORITY: number = 4;
const PICKER_SOURCE: number = 5;
const PICKER_TAG: number = 6;

/**
 * 重复面板的固定高度（vp）。
 * 要能同时装下：档位轮（约 200vp）+ 星期提示与七个圆钮（约 70vp）+ 间隔行（约 50vp）+ 底部条（约 60vp）。
 */
const REPEAT_SHEET_HEIGHT_VP: number = 460;

/**
 * 来源档位下标 —— 顺序与任务详情页元信息卡的 `SOURCE_OPTIONS` / `SOURCE_VALUES` 一致
 * （粘贴 / 分享 / 机器人 / 语音 / 手动）。来源是**可空**项，所以另有一个"未设置"哨兵 `SOURCE_UNSET`。
 */
const SOURCE_UNSET: number = -1;

/**
 * 重复档位下标 —— **顺序与任务详情页的 `REPEAT_OPTIONS` 完全一致**
 * （`['不重复','每天','每周','每月','每年']`），以后接 `RepeatRule` 时两边能直接对表。
 * 默认 **0 ＝ 不重复**（袁正锟 2026-10-17：「但是这个默认是不重复」）。
 */
const REPEAT_NONE: number = 0;

/**
 * 重要程度档位下标 —— 与 `TaskPriority` 的取值一一对应（0 普通 / 1 重要 / 2 紧急），
 * 也与任务详情页元信息卡的 `PRIORITY_OPTIONS` 同序。
 * 它是**必填项**（没有空值态），所以默认 `0 ＝ 普通`（袁正锟 2026-10-17：「因为这个值是必填嘛 所以默认显示普通」）。
 */
const PRIORITY_NORMAL: number = 0;

@ComponentV2
export struct AddTaskAttributeChips {
  /**
   * 表单草稿（`AddTaskSheet` `new` 出来、按引用传下来）：截止/提醒/重复/重要程度/来源/标签**都存在这里**。
   * 这样标题栏上的「保存」按钮能读到全部字段拼出 `Task` —— 不必把状态在几层之间来回搬，
   * 也没有"组件内一份、页面一份"的漂移（`@ObservedV2` + `@Trace` 会自己驱动刷新）。
   */
  @Require @Param draft: AddTaskDraft;
  /** 标签输入面板的草稿 */
  @Local tagDraft: string = '';
  /** 打开的是哪个面板：`PICKER_NONE` / `PICKER_DUE` / `PICKER_REMIND` / `PICKER_REPEAT` / `PICKER_PRIORITY` / `PICKER_SOURCE` */
  @Local pickerKind: number = PICKER_NONE;
  /** 截止面板草稿（点「确定」才落到 `dueAt`） */
  @Local dueDraft: Date = new Date();
  /** 提醒面板草稿（点「确定」才落到 `remindAt`） */
  @Local remindDraft: Date = new Date();
  /** 重复面板草稿档位（点「确定」才落到 `repeatIndex`） */
  @Local repeatDraftIndex: number = REPEAT_NONE;
  /** 重复面板草稿：选中的星期（1~7，空数组＝跟随截止日） */
  @Local repeatDraftDays: number[] = [];
  /** 重复面板草稿：每 N 周（最小 1） */
  @Local repeatDraftInterval: number = 1;
  /** 重要程度面板草稿档位（点「确定」才落到 `priorityIndex`） */
  @Local priorityDraftIndex: number = PRIORITY_NORMAL;
  /** 来源面板草稿档位（点「确定」才落到 `sourceIndex`） */
  @Local sourceDraftIndex: number = 0;

  /* —— 文案：全部走资源，`getStringSync(id, ...args)` 做占位替换，不在代码里拼中文 —— */

  /** 把资源文案解成字符串（官方 `Chip` 的 `label.text` 只收 string） */
  private labelText(label: Resource): string {
    try {
      const context = this.getUIContext().getHostContext();
      return context === undefined ? '' : context.resourceManager.getStringSync(label.id);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'resolve chip label failed: %{public}s', err.message);
      return '';
    }
  }

  /* —— 重复档位：文案与下标一一对应（顺序＝详情页 `REPEAT_OPTIONS`）—— */

  /** 重复档位的资源（下标即档位） */
  private repeatOptionResources: Resource[] = [
    $r('app.string.repeat_option_none'),
    $r('app.string.repeat_option_daily'),
    $r('app.string.repeat_option_weekly'),
    $r('app.string.repeat_option_monthly'),
    $r('app.string.repeat_option_yearly')
  ];

  /** 给 `TextPicker.range` 用的字符串数组（它只吃 `string[]`） */
  @Computed
  get repeatOptionTexts(): string[] {
    const texts: string[] = [];
    this.repeatOptionResources.forEach((res: Resource) => {
      texts.push(this.labelText(res));
    });
    return texts;
  }

  /** 重复 chip 文案：不重复 → 「重复」；否则显示档位名（「每天」/「每周」…） */
  @Computed
  get repeatChipLabel(): string {
    // 编辑器给过完整规则时，**直接显示规则文案**（「每周一、二、四」「每月月末」），
    // 比只显示「每周」「每月」这种档位名更有信息量 —— 否则用户看不出自己选的是月末。
    const rule: RepeatRule | undefined = this.draft.repeatRule;
    if (rule !== undefined) {
      const text: string = TaskListViewModel.oneRepeatLabel(rule);
      if (text.length > 0) {
        return text;
      }
    }
    if (this.draft.repeatIndex === REPEAT_NONE) {
      return this.labelText($r('app.string.chip_repeat'));
    }
    const index: number = this.draft.repeatIndex;
    if (index < 0 || index >= this.repeatOptionResources.length) {
      return this.labelText($r('app.string.chip_repeat'));
    }
    return this.labelText(this.repeatOptionResources[index]);
  }

  /* —— 重要程度：三档必填，文案与下标一一对应（顺序＝详情页 `PRIORITY_OPTIONS`）—— */

  /** 重要程度档位的资源（下标即档位：0 普通 / 1 重要 / 2 紧急） */
  private priorityOptionResources: Resource[] = [
    $r('app.string.priority_option_normal'),
    $r('app.string.priority_option_important'),
    $r('app.string.priority_option_urgent')
  ];

  /** 给 `TextPicker.range` 用的字符串数组（它只吃 `string[]`） */
  @Computed
  get priorityOptionTexts(): string[] {
    const texts: string[] = [];
    this.priorityOptionResources.forEach((res: Resource) => {
      texts.push(this.labelText(res));
    });
    return texts;
  }

  /** 重要程度 chip 文案：必填项，所以永远显示当前档位（默认「普通」） */
  @Computed
  get priorityChipLabel(): string {
    const index: number = this.draft.priorityIndex;
    if (index < 0 || index >= this.priorityOptionResources.length) {
      return this.labelText(this.priorityOptionResources[PRIORITY_NORMAL]);
    }
    return this.labelText(this.priorityOptionResources[index]);
  }

  /* —— 来源：五档通道（可空），文案与下标一一对应（顺序＝详情页 `SOURCE_OPTIONS`）—— */

  /** 来源档位的资源（下标即档位：0 粘贴 / 1 分享 / 2 机器人 / 3 语音 / 4 手动） */
  private sourceOptionResources: Resource[] = [
    $r('app.string.source_option_paste'),
    $r('app.string.source_option_share'),
    $r('app.string.source_option_bot'),
    $r('app.string.source_option_voice'),
    $r('app.string.source_option_manual')
  ];

  /** 给 `TextPicker.range` 用的字符串数组（它只吃 `string[]`） */
  @Computed
  get sourceOptionTexts(): string[] {
    const texts: string[] = [];
    this.sourceOptionResources.forEach((res: Resource) => {
      texts.push(this.labelText(res));
    });
    return texts;
  }

  /** 来源 chip 文案：未设 → 「来源」；已设 → 「来源于 语音」 */
  @Computed
  get sourceChipLabel(): string {
    const index: number = this.draft.sourceIndex;
    if (index === SOURCE_UNSET || index < 0 || index >= this.sourceOptionResources.length) {
      return this.labelText($r('app.string.chip_source'));
    }
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) {
        return '';
      }
      return context.resourceManager.getStringSync($r('app.string.chip_source_set').id,
        this.labelText(this.sourceOptionResources[index]));
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'resolve source label failed: %{public}s', err.message);
      return '';
    }
  }

  /** 截止日期 chip 文案：未设 → 「设置到期日期」；已设 → 「10月20日 到期」 */
  @Computed
  get dueChipLabel(): string {
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) {
        return '';
      }
      if (this.draft.dueAt === UNSET) {
        return context.resourceManager.getStringSync($r('app.string.chip_set_due').id);
      }
      const date: Date = new Date(this.draft.dueAt);
      return context.resourceManager.getStringSync($r('app.string.chip_due_set').id,
        date.getMonth() + 1, date.getDate());
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'resolve due label failed: %{public}s', err.message);
      return '';
    }
  }

  /** 提醒 chip 文案：未设 → 「提醒我」；已设 → 「在 10月20日 23:59 提醒我」 */
  @Computed
  get remindChipLabel(): string {
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) {
        return '';
      }
      if (this.draft.remindAt === UNSET) {
        return context.resourceManager.getStringSync($r('app.string.chip_remind_me').id);
      }
      const date: Date = new Date(this.draft.remindAt);
      return context.resourceManager.getStringSync($r('app.string.chip_remind_set').id,
        date.getMonth() + 1, date.getDate(), TaskListViewModel.hhmm(this.draft.remindAt));
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'resolve remind label failed: %{public}s', err.message);
      return '';
    }
  }

  /* —— 面板的开关与草稿种子 —— */

  /** 面板标题随 `pickerKind` 变（官方 `SheetOptions.title` 只吃 `ResourceStr`） */
  @Computed
  get pickerTitle(): Resource {
    if (this.pickerKind === PICKER_REMIND) {
      return $r('app.string.picker_title_remind');
    }
    if (this.pickerKind === PICKER_REPEAT) {
      return $r('app.string.picker_title_repeat');
    }
    if (this.pickerKind === PICKER_PRIORITY) {
      return $r('app.string.picker_title_priority');
    }
    if (this.pickerKind === PICKER_SOURCE) {
      return $r('app.string.picker_title_source');
    }
    if (this.pickerKind === PICKER_TAG) {
      return $r('app.string.chip_add_tag');
    }
    return $r('app.string.picker_title_due');
  }

  @Computed
  get pickerOpen(): boolean {
    return this.pickerKind !== PICKER_NONE;
  }

  /**
   * 截止面板的草稿种子：已设过就停在上次那个时刻；没设过＝**当天 23:59**
   * （与任务详情页同一条口径：「这一天结束前」）。
   */
  private dueSeed(): Date {
    if (this.draft.dueAt !== UNSET) {
      return new Date(this.draft.dueAt);
    }
    const now: Date = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 0, 0);
  }

  /**
   * 提醒面板的草稿种子：有提醒就用提醒 → 否则借**截止时刻**（同一刻，用户自己挪）→ 都没有就用「现在」。
   * 与详情页 `remindSeed` 一致；也**不擅自造「提前量」**（那是设置页的事，还没做）。
   */
  private remindSeed(): Date {
    if (this.draft.remindAt !== UNSET) {
      return new Date(this.draft.remindAt);
    }
    if (this.draft.dueAt !== UNSET) {
      return new Date(this.draft.dueAt);
    }
    return new Date();
  }

  private openDuePicker(): void {
    this.dueDraft = this.dueSeed();
    this.pickerKind = PICKER_DUE;
  }

  private openRemindPicker(): void {
    this.remindDraft = this.remindSeed();
    this.pickerKind = PICKER_REMIND;
  }

  /** 重复面板：草稿从当前档位 / 星期 / 间隔起（默认不重复、不选星期、间隔 1） */
  private openRepeatPicker(): void {
    this.repeatDraftIndex = this.draft.repeatIndex;
    this.repeatDraftDays = this.draft.repeatDaysOfWeek.slice();
    this.repeatDraftInterval = this.draft.repeatInterval;
    this.pickerKind = PICKER_REPEAT;
  }

  /** 重要程度面板：草稿从当前档位起（默认普通） */
  private openPriorityPicker(): void {
    this.priorityDraftIndex = this.draft.priorityIndex;
    this.pickerKind = PICKER_PRIORITY;
  }

  /** 来源面板：草稿从当前档位起（未设就停在第一档「粘贴」） */
  private openSourcePicker(): void {
    this.sourceDraftIndex = this.draft.sourceIndex === SOURCE_UNSET ? 0 : this.draft.sourceIndex;
    this.pickerKind = PICKER_SOURCE;
  }

  /** 添加标签面板：草稿清空 */
  private openTagPicker(): void {
    this.tagDraft = '';
    this.pickerKind = PICKER_TAG;
  }

  /** 加一个标签：**去空白、去重、空串不加**；加完关面板 */
  private confirmTag(): void {
    const name: string = this.tagDraft.trim();
    if (name.length > 0 && !this.draft.tags.includes(name)) {
      // 整体换新数组，保证 `@Local` 变化能被观察到
      const next: string[] = [];
      this.draft.tags.forEach((tag: string) => {
        next.push(tag);
      });
      next.push(name);
      this.draft.tags = next;
    }
    this.tagDraft = '';
    this.pickerKind = PICKER_NONE;
  }

  /** 删掉一个标签 */
  private removeTag(name: string): void {
    const next: string[] = [];
    this.draft.tags.forEach((tag: string) => {
      if (tag !== name) {
        next.push(tag);
      }
    });
    this.draft.tags = next;
  }

  /** 关面板（草稿丢弃） */
  private closePicker(): void {
    this.pickerKind = PICKER_NONE;
  }

  /** 「确定」才写回：把当前草稿落到对应字段 */
  private confirmPicker(): void {
    if (this.pickerKind === PICKER_DUE) {
      this.draft.dueAt = this.dueDraft.getTime();
    } else if (this.pickerKind === PICKER_REMIND) {
      this.draft.remindAt = this.remindDraft.getTime();
    } else if (this.pickerKind === PICKER_REPEAT) {
      this.draft.repeatIndex = this.repeatDraftIndex;
      // 只有「每周」才把星期与间隔写回；其它档位的星期留在草稿里不影响规则生成（`repeatRules` 只在 WEEKLY 读它）
      this.draft.repeatDaysOfWeek = this.repeatDraftDays.slice();
      this.draft.repeatInterval = this.repeatDraftInterval;
    } else if (this.pickerKind === PICKER_PRIORITY) {
      this.draft.priorityIndex = this.priorityDraftIndex;
    } else if (this.pickerKind === PICKER_SOURCE) {
      this.draft.sourceIndex = this.sourceDraftIndex;
    }
    this.pickerKind = PICKER_NONE;
  }

  private clearDue(): void {
    this.draft.dueAt = UNSET;
  }

  private clearRemind(): void {
    this.draft.remindAt = UNSET;
  }

  /** 点 × 清空这一项 → 回到「不重复」（不是"未设置"，重复本来就有默认档） */
  private clearRepeat(): void {
    this.draft.repeatIndex = REPEAT_NONE;
  }

  /** 点 × 清空这一项 → 来源回到「未设置」 */
  private clearSource(): void {
    this.draft.sourceIndex = SOURCE_UNSET;
  }

  /* —— chip：有值 / 无值必须是两个分支（两个节点），否则点过自带的 × 之后整颗 chip 会消失 —— */

  /**
   * chip 末尾那颗 × —— 四颗有状态的 chip 共用。
   *
   * 给图标一个 **24vp 的稳定热区**（`CHIP_CLEAR_HIT_VP`）：图标只有约 16vp，实测直接点图标容易点空、
   * 反而命中上一行的 chip（`.cache/src-5-set.png` 那次）。参数只有回调、不带会变的值，
   * 所以不受「@Builder 值参数不刷新」那条坑影响（与详情页 `clearButton` 同一个做法）。
   */
  @Builder
  chipClear(onClear: () => void) {
    Row() {
      SymbolGlyph($r('sys.symbol.xmark'))
        .fontSize($r('sys.float.chip_small_icon_size'))
        .fontColor([$r('sys.color.icon_secondary')])
    }
    .width(CHIP_CLEAR_HIT_VP)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ left: $r('sys.float.chip_show_close_icon_margin') })
    .accessibilityText($r('app.string.action_clear_attribute'))
    .onClick(() => {
      onClear();
    })
  }

  /**
   * 截止日期 chip（**自绘**，不用官方 `Chip`，原因见 `remindChip()` 的注释：官方 Chip 的 label 会被压缩截断）。
   * 造型全部取官方 chip 的 token，所以和旁边的官方 Chip 看起来是一套。
   * ⚠️ 文案**直接在 build 里读 `this.dueChipLabel`**，不通过 `@Builder` 参数传 —— `@Builder` 的值参数不随状态刷新
   * （详情页 #? 的「点叉没生效」就是栽在这条上）。
   */
  @Builder
  dueChip() {
    Row({ space: CHIP_TEXT_MARGIN_VP }) {
      SymbolGlyph($r('sys.symbol.calendar'))
        .fontSize($r('sys.float.chip_small_icon_size'))
        .fontColor([$r('sys.color.icon_emphasize')])

      Text(this.dueChipLabel)
        .fontSize($r('sys.float.chip_small_font_size'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .maxLines(1)

      if (this.draft.dueAt !== UNSET) {
        // 末尾的 ×：点它清空这一项（官方 chip 的 × 是同一位置/同色）
        this.chipClear(() => {
          this.clearDue();
        })
      }
    }
    .height($r('sys.float.chip_small_height'))
    .padding({
      left: $r('sys.float.chip_small_text_padding'),
      right: $r('sys.float.chip_small_text_padding')
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('sys.color.segment_button_v2_capsule_button_background'))
    .borderRadius($r('sys.float.chip_border_radius_small'))
    .onClick(() => {
      this.openDuePicker();
    })
    .accessibilityText(this.dueChipLabel)
  }

  /**
   * 提醒我 chip（**自绘**）。
   *
   * 为什么不用官方 `Chip`：已设置时文案是「在 10月17日 23:59 提醒我」（14 个字），官方 `Chip` 的 label
   * 只能拿到约 **96vp** 就被省略号截断（实测 `.cache/rem-4-set.png`；给外层 Row 设 `width('100%')` 也不行 ——
   * 限制在 Chip 自己内部，不在 Flex），而官方没给"label 最大宽度"这种口子。
   * 自绘的 `Row` 宽度由内容撑开，文字完整显示；配色/高度/圆角/内边距/图标尺寸全取官方 chip token，
   * 与旁边真正的 `Chip` 观感一致。
   */
  @Builder
  remindChip() {
    Row({ space: CHIP_TEXT_MARGIN_VP }) {
      SymbolGlyph($r('sys.symbol.bell'))
        .fontSize($r('sys.float.chip_small_icon_size'))
        .fontColor([$r('sys.color.icon_emphasize')])

      Text(this.remindChipLabel)
        .fontSize($r('sys.float.chip_small_font_size'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .maxLines(1)

      if (this.draft.remindAt !== UNSET) {
        this.chipClear(() => {
          this.clearRemind();
        })
      }
    }
    .height($r('sys.float.chip_small_height'))
    .padding({
      left: $r('sys.float.chip_small_text_padding'),
      right: $r('sys.float.chip_small_text_padding')
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('sys.color.segment_button_v2_capsule_button_background'))
    .borderRadius($r('sys.float.chip_border_radius_small'))
    .onClick(() => {
      this.openRemindPicker();
    })
    .accessibilityText(this.remindChipLabel)
  }

  /**
   * 重复 chip（**自绘**，与另外两颗有状态 chip 同一套造型）。
   * 默认就是「不重复」→ 显示「重复」且**没有 ×**；选了档位后显示档位名（「每天」…）并带 × 可以清回「不重复」。
   */
  @Builder
  repeatChip() {
    Row({ space: CHIP_TEXT_MARGIN_VP }) {
      SymbolGlyph($r('sys.symbol.repeat'))
        .fontSize($r('sys.float.chip_small_icon_size'))
        .fontColor([$r('sys.color.icon_emphasize')])

      Text(this.repeatChipLabel)
        .fontSize($r('sys.float.chip_small_font_size'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .maxLines(1)

      if (this.draft.repeatIndex !== REPEAT_NONE) {
        this.chipClear(() => {
          this.clearRepeat();
        })
      }
    }
    .height($r('sys.float.chip_small_height'))
    .padding({
      left: $r('sys.float.chip_small_text_padding'),
      right: $r('sys.float.chip_small_text_padding')
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('sys.color.segment_button_v2_capsule_button_background'))
    .borderRadius($r('sys.float.chip_border_radius_small'))
    .onClick(() => {
      this.openRepeatPicker();
    })
    .accessibilityText(this.repeatChipLabel)
  }

  /**
   * 重要程度 chip（**自绘**，与其它有状态 chip 同一套造型）。
   *
   * 它是**必填项**（`TaskPriority` 只有 0/1/2，没有空值态），所以：
   *  · **默认显示「普通」**（袁正锟 2026-10-17：「因为这个值是必填嘛 所以默认显示普通」）；
   *  · **永远没有 ×** —— 清空一个必填项没有语义（详情页那边「清除」也是回到普通，不是清空）。
   */
  @Builder
  priorityChip() {
    Row({ space: CHIP_TEXT_MARGIN_VP }) {
      SymbolGlyph($r('sys.symbol.star'))
        .fontSize($r('sys.float.chip_small_icon_size'))
        .fontColor([$r('sys.color.icon_emphasize')])

      Text(this.priorityChipLabel)
        .fontSize($r('sys.float.chip_small_font_size'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .maxLines(1)
    }
    .height($r('sys.float.chip_small_height'))
    .padding({
      left: $r('sys.float.chip_small_text_padding'),
      right: $r('sys.float.chip_small_text_padding')
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('sys.color.segment_button_v2_capsule_button_background'))
    .borderRadius($r('sys.float.chip_border_radius_small'))
    .onClick(() => {
      this.openPriorityPicker();
    })
    .accessibilityText(this.priorityChipLabel)
  }

  /**
   * 来源 chip（**自绘**，与其它有状态 chip 同一套造型）。
   * 未设 → 「来源」、没有 ×；设了 → 「来源于 语音」＋ ×，点 × 清空回未设。
   */
  @Builder
  sourceChip() {
    Row({ space: CHIP_TEXT_MARGIN_VP }) {
      SymbolGlyph($r('sys.symbol.link'))
        .fontSize($r('sys.float.chip_small_icon_size'))
        .fontColor([$r('sys.color.icon_emphasize')])

      Text(this.sourceChipLabel)
        .fontSize($r('sys.float.chip_small_font_size'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .maxLines(1)

      if (this.draft.sourceIndex !== SOURCE_UNSET) {
        this.chipClear(() => {
          this.clearSource();
        })
      }
    }
    .height($r('sys.float.chip_small_height'))
    .padding({
      left: $r('sys.float.chip_small_text_padding'),
      right: $r('sys.float.chip_small_text_padding')
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('sys.color.segment_button_v2_capsule_button_background'))
    .borderRadius($r('sys.float.chip_border_radius_small'))
    .onClick(() => {
      this.openSourcePicker();
    })
    .accessibilityText(this.sourceChipLabel)
  }

  /**
   * 已添加的标签 —— 每个标签一颗 chip（**标签图标 ＋ 文字 ＋ ×**，点 × 删掉这个标签）。
   * 袁正锟 2026-10-17：「添加了标签 Chip 加一个标签的图标」→ 前缀用官方 Symbol **`label`**
   * （官方符号库里没有叫 `tag` 的；`label` 就是"标签/价签"那个图形），与其它几颗 chip 的图标同色同尺寸。
   */
  @Builder
  tagChips() {
    ForEach(this.draft.tags, (tag: string) => {
      Row({ space: CHIP_TEXT_MARGIN_VP }) {
        SymbolGlyph($r('sys.symbol.label'))
          .fontSize($r('sys.float.chip_small_icon_size'))
          .fontColor([$r('sys.color.icon_emphasize')])

        Text(tag)
          .fontSize($r('sys.float.chip_small_font_size'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .maxLines(1)

        this.chipClear(() => {
          this.removeTag(tag);
        })
      }
      .height($r('sys.float.chip_small_height'))
      .padding({
        left: $r('sys.float.chip_small_text_padding'),
        right: $r('sys.float.chip_small_text_padding')
      })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('sys.color.segment_button_v2_capsule_button_background'))
      .borderRadius($r('sys.float.chip_border_radius_small'))
      .accessibilityText(tag)
    }, (tag: string) => tag)
  }

  /** 面板内容：一个 body 按 `pickerKind` 切，日期/时间的草稿各自独立（与详情页同一套组件） */
  @Builder
  pickerBody() {    if (this.pickerKind === PICKER_REMIND) {
      DateTimePickerBody({
        selected: this.remindDraft,
        onSelectedChange: (date: Date) => {
          this.remindDraft = date;
        },
        onCancel: () => {
          this.closePicker();
        },
        onConfirm: () => {
          this.confirmPicker();
        }
      })
    } else if (this.pickerKind === PICKER_REPEAT) {
      // 重复面板：与详情页**同一个** `RepeatRuleEditor`（2026-10-19 统一）。
      // 旧的 `RepeatPickerBody` 只有「档位 + 星期多选 + 间隔」，没有「每月月初/月中/月末」，
      // 所以两处口径会对不上 —— 现在两处都走编辑器，产出的都是完整 `RepeatRule`。
      RepeatRuleEditor({
        initialRule: this.draft.firstRepeatRule(),
        onCancel: () => {
          this.closePicker();
        },
        onConfirm: (rule: RepeatRule | undefined) => {
          this.draft.applyRepeatRule(rule);
          this.closePicker();
        }
      })
    } else if (this.pickerKind === PICKER_PRIORITY) {
      // 同一个单列文本选择器，只是选项换成三档重要程度（与详情页元信息卡的选择器同源）
      OptionPickerBody({
        options: this.priorityOptionTexts,
        selectedIndex: this.priorityDraftIndex,
        onSelectedIndexChange: (index: number) => {
          this.priorityDraftIndex = index;
        },
        onCancel: () => {
          this.closePicker();
        },
        onConfirm: () => {
          this.confirmPicker();
        }
      })
    } else if (this.pickerKind === PICKER_SOURCE) {
      // 同一个单列文本选择器，选项换成五档来源通道（与详情页元信息卡的来源选择器同源）
      OptionPickerBody({
        options: this.sourceOptionTexts,
        selectedIndex: this.sourceDraftIndex,
        onSelectedIndexChange: (index: number) => {
          this.sourceDraftIndex = index;
        },
        onCancel: () => {
          this.closePicker();
        },
        onConfirm: () => {
          this.confirmPicker();
        }
      })
    } else if (this.pickerKind === PICKER_TAG) {
      // 标签输入面板（新组件 TagInputBody：官方 TextInput ＋ 共用底部条）
      TagInputBody({
        text: this.tagDraft,
        placeholder: $r('app.string.tag_input_hint'),
        onTextChange: (text: string) => {
          this.tagDraft = text;
        },
        onCancel: () => {
          this.closePicker();
        },
        onConfirm: () => {
          this.confirmTag();
        }
      })
    } else {
      DateTimePickerBody({
        selected: this.dueDraft,
        onSelectedChange: (date: Date) => {
          this.dueDraft = date;
        },
        onCancel: () => {
          this.closePicker();
        },
        onConfirm: () => {
          this.confirmPicker();
        }
      })
    }
  }

  build() {
    // 官方 Flex 换行：一行装不下自动开下一行（袁正锟 2026-10-17 的要求）
    Flex({
      wrap: FlexWrap.Wrap,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center,
      space: { main: LengthMetrics.vp(CHIP_GAP_VP), cross: LengthMetrics.vp(CHIP_GAP_VP) }
    }) {
      // ① 截止日期（有状态、可清空）
      this.dueChip()
      // ② 提醒我（有状态、可清空）
      this.remindChip()
      // ③ 重复（默认不重复；选了档位后可 × 清回不重复）
      this.repeatChip()
      // ④ 重要程度（**必填、默认普通、没有 ×**）
      this.priorityChip()
      // ⑤ 来源（可空；设了显示「来源于 语音」＋ ×）
      this.sourceChip()
      // ⑥ 已添加的标签（每个一颗 chip，点 × 删掉）
      this.tagChips()

      // ⑦「＋ 添加标签」：动作型芯片 —— 强调容器浅底 ＋ 强调色文字，点它弹输入框
      Chip({
        label: {
          text: this.labelText($r('app.string.chip_add_tag')),
          fontColor: $r('sys.color.font_emphasize')
        },
        prefixSymbol: {
          normal: new SymbolGlyphModifier($r('sys.symbol.plus')).fontColor([$r('sys.color.icon_emphasize')])
        },
        size: ChipSize.SMALL,
        allowClose: false,
        backgroundColor: $r('sys.color.comp_emphasize_secondary'),
        onClicked: () => {
          this.openTagPicker();
        }
      })
    }
    .width('100%')
    // 一个面板管两项：挂在 chip 行的根节点上（半模态必须挂在已上树的宿主上）；
    // 造型与详情页那三个选择器面板一致（居中、FIT_CONTENT、无拖拽条、只要标题）。
    .bindSheet(this.pickerOpen, this.pickerBody(), {
      title: { title: this.pickerTitle },
      preferType: SheetType.CENTER,
      // 重复面板要装「档位轮 + 星期多选 + 间隔 + 底部条」，`FIT_CONTENT` 会在开面板时就把高度定死，
      // 之后切换到「每周」时多出来的星期行会被裁掉 → 这一个面板给它固定高度。
      height: this.pickerKind === PICKER_REPEAT ? REPEAT_SHEET_HEIGHT_VP : SheetSize.FIT_CONTENT,
      showClose: false,
      dragBar: false,
      onDisappear: () => {
        this.pickerKind = PICKER_NONE;
      }
    })
  }
}
