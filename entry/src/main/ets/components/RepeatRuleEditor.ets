/*
 * 周期规则编辑器（半模态内容）。
 *
 * 解决 2026-10-19 反馈：「根本就没有可以自定义设置出周期性任务的地方，
 * 即自定义每周的哪几天，每月的月初、月中、月末」。
 *
 * 能录入的东西与 `RepeatRule`（`model/Models.ets`）逐字段对应：
 *   · 频率：不重复 / 每天 / 每周 / 每月 / 每年（`recurrenceFrequency`）
 *   · 每周：**一~日多选**（`daysOfWeek`，官方 range [1,7]，1 = 周一）
 *   · 每月：**月初 / 月中 / 月末**（见下）
 *   · 间隔：每 N 个周期（`interval`）
 *
 * ## 「月初 / 月中 / 月末」怎么落成规则
 *
 * `daysOfMonth` 只接受 **1~31 的正整数**，官方原文「当月没有 29/30/31 号时这几个值无效」——
 * **没有"倒数第几天"这种写法**，所以：
 *   · 月初 → `daysOfMonth: [1]`（规则能表达）
 *   · 月中 → `daysOfMonth: [15]`（规则能表达）
 *   · 月末 → **只能用 `dates` 存未来若干个月的"当月最后一天"具体时间戳**（本机扩展字段）
 *
 * **2026-10-19 作者已确认**：月初 = 1 号、月中 = 15 号、月末 = 当月最后一天。
 * 预生成 **12 个月**（一个学期够用）；**第 13 个月起该月末规则不再触发** —— 这是 `dates`
 * 方案的固有限制，不是 bug。要延长只需改 `MONTH_END_MONTHS` 一个常量。
 */
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { RepeatFrequency, RepeatRule } from '../model';
import { Theme } from '../utils/Theme';

const DOMAIN: number = 0x0000;
const TAG: string = 'RepeatRuleEditor';

/** 月初落成的日期 */
const MONTH_START_DAY: number = 1;
/** 月中落成的日期 */
const MONTH_MID_DAY: number = 15;
/** 月末要预生成多少个月的最后一天（一年，够用一个学期） */
const MONTH_END_MONTHS: number = 12;

/** 间隔上限：与「每 12 周/月」对齐，再大基本没人用 */
const INTERVAL_MAX: number = 12;

/** 频率档位（与 `RepeatFrequency` 的枚举值一一对应：0 每年 / 1 每月 / 2 每周 / 3 每天） */
const FREQ_YEARLY: number = 0;
const FREQ_MONTHLY: number = 1;
const FREQ_WEEKLY: number = 2;
const FREQ_DAILY: number = 3;

/** 编辑器里的频率选中值：-1 = 不重复（否则等于 `RepeatFrequency` 的值） */
const FREQ_NONE: number = -1;

/** 每月档位 */
const MONTH_MODE_START: number = 0;
const MONTH_MODE_MID: number = 1;
const MONTH_MODE_END: number = 2;

/** 分段按钮尺寸（vp） */
const SEGMENT_HEIGHT_VP: number = 32;
const SEGMENT_GAP_VP: number = 8;
/** 底部操作条高度（vp） */
const FOOTER_HEIGHT_VP: number = 56;
/** 正文区高度上限（vp）：超出由 `Scroll` 承担 */
const EDITOR_MAX_HEIGHT_VP: number = 420;

@ComponentV2
export struct RepeatRuleEditor {
  /** 进来时要回填的规则（没有就传 undefined） */
  @Param initialRule: RepeatRule | undefined = undefined;
  @Event onCancel: () => void = () => {};
  /** 确定：返回 `undefined` 表示"不重复" */
  @Event onConfirm: (rule: RepeatRule | undefined) => void = () => {};

  /** 频率选中值（`FREQ_NONE` 或 `RepeatFrequency` 的值） */
  @Local frequency: number = FREQ_NONE;
  /** 每 N 个周期 */
  @Local interval: number = 1;
  /** 每周：选中的星期（1~7） */
  @Local weekdays: number[] = [];
  /** 每月：月初 / 月中 / 月末 */
  @Local monthMode: number = MONTH_MODE_START;

  aboutToAppear(): void {
    this.seed();
  }

  /** 用已有规则回填草稿 */
  private seed(): void {
    const rule: RepeatRule | undefined = this.initialRule;
    if (rule === undefined) {
      this.frequency = FREQ_NONE;
      return;
    }
    this.frequency = rule.frequency;
    const interval: number = rule.interval === undefined ? 1 : rule.interval;
    this.interval = interval < 1 ? 1 : interval;

    const days: number[] | undefined = rule.daysOfWeek;
    if (days !== undefined) {
      this.weekdays = days.slice();
    }

    // 每月档位：有 daysOfMonth 就看是 1 号还是 15 号；只有 dates 就认为"月末"
    const monthDays: number[] | undefined = rule.daysOfMonth;
    const dates: number[] | undefined = rule.dates;
    if (monthDays !== undefined && monthDays.length > 0) {
      this.monthMode = monthDays[0] === MONTH_MID_DAY ? MONTH_MODE_MID : MONTH_MODE_START;
    } else if (dates !== undefined && dates.length > 0) {
      this.monthMode = MONTH_MODE_END;
    }
  }

  /* ── 草稿 → 规则 ── */

  /** 点星期圆圈：一~日多选 */
  private toggleWeekday(day: number): void {
    const next: number[] = this.weekdays.slice();
    const index: number = next.indexOf(day);
    if (index >= 0) {
      next.splice(index, 1);
    } else {
      next.push(day);
    }
    next.sort((a: number, b: number): number => a - b);
    this.weekdays = next;
  }

  private adjustInterval(delta: number): void {
    const next: number = this.interval + delta;
    if (next < 1 || next > INTERVAL_MAX) {
      return;
    }
    this.interval = next;
  }

  /**
   * 生成"未来 N 个月的当月最后一天"时间戳。
   * 月末在官方规则里没有表达方式，只能用具体日期列表。
   */
  private monthEndDates(): number[] {
    const list: number[] = [];
    const base: Date = new Date();
    for (let i = 0; i < MONTH_END_MONTHS; i++) {
      // 下个月的第 0 天 ＝ 本月最后一天
      const lastDay: Date = new Date(base.getFullYear(), base.getMonth() + i + 1, 0);
      lastDay.setHours(23, 59, 0, 0);
      list.push(lastDay.getTime());
    }
    return list;
  }

  private buildRule(): RepeatRule | undefined {
    if (this.frequency === FREQ_NONE) {
      return undefined;
    }
    const rule: RepeatRule = new RepeatRule();
    if (this.frequency === FREQ_DAILY) {
      rule.frequency = RepeatFrequency.DAILY;
    } else if (this.frequency === FREQ_WEEKLY) {
      rule.frequency = RepeatFrequency.WEEKLY;
    } else if (this.frequency === FREQ_MONTHLY) {
      rule.frequency = RepeatFrequency.MONTHLY;
    } else {
      rule.frequency = RepeatFrequency.YEARLY;
    }
    if (this.interval > 1) {
      rule.interval = this.interval;
    }

    if (rule.frequency === RepeatFrequency.WEEKLY) {
      // 没选星期就不写 daysOfWeek：`repeatLabel` 会退成「每周」
      if (this.weekdays.length > 0) {
        rule.daysOfWeek = this.weekdays.slice();
      }
    } else if (rule.frequency === RepeatFrequency.MONTHLY) {
      if (this.monthMode === MONTH_MODE_END) {
        rule.dates = this.monthEndDates();
      } else {
        rule.daysOfMonth = [this.monthMode === MONTH_MODE_MID ? MONTH_MID_DAY : MONTH_START_DAY];
      }
    }
    return rule;
  }

  /** 确定前的最小校验：选了「每周」却一天没选，等于没设 */
  private canConfirm(): boolean {
    if (this.frequency === FREQ_WEEKLY) {
      return this.weekdays.length > 0;
    }
    return true;
  }

  private confirm(): void {
    if (!this.canConfirm()) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: '请至少选一天' });
      } catch (error) {
        const err = error as BusinessError;
        hilog.error(DOMAIN, TAG, 'toast failed: %{public}s', err.message);
      }
      return;
    }
    this.onConfirm(this.buildRule());
  }

  /* ── 文案 ── */

  private freqLabel(): string {
    if (this.frequency === FREQ_DAILY) {
      return '天';
    }
    if (this.frequency === FREQ_WEEKLY) {
      return '周';
    }
    if (this.frequency === FREQ_MONTHLY) {
      return '月';
    }
    return '年';
  }

  /* ── 视图 ── */

  @Builder
  segment(text: string, selected: boolean, onTap: () => void) {
    Text(text)
      .fontSize(Theme.FONT_BODY)
      .fontColor(selected
        ? $r('sys.color.ohos_id_color_text_primary_contrary')
        : $r('sys.color.ohos_id_color_text_primary'))
      .height(SEGMENT_HEIGHT_VP)
      .padding({ left: Theme.GAP_M, right: Theme.GAP_M })
      .backgroundColor(selected
        ? $r('sys.color.ohos_id_color_emphasize')
        : $r('sys.color.comp_background_secondary'))
      .borderRadius(SEGMENT_HEIGHT_VP / 2)
      .textAlign(TextAlign.Center)
      .onClick(onTap)
      .accessibilityText(text)
  }

  /** 星期圆圈：选中实心，未选中描边 */
  @Builder
  weekdayCircle(day: number, label: string) {
    Text(label)
      .fontSize(Theme.FONT_BODY)
      .fontColor(this.weekdays.indexOf(day) >= 0
        ? $r('sys.color.ohos_id_color_text_primary_contrary')
        : $r('sys.color.ohos_id_color_text_primary'))
      .width(Theme.HIT_MIN)
      .height(Theme.HIT_MIN)
      .textAlign(TextAlign.Center)
      .borderRadius(Theme.HIT_MIN / 2)
      .backgroundColor(this.weekdays.indexOf(day) >= 0
        ? $r('sys.color.ohos_id_color_emphasize')
        : $r('sys.color.comp_background_secondary'))
      .onClick(() => {
        this.toggleWeekday(day);
      })
      .accessibilityText(label)
  }

  @Builder
  intervalStepper() {
    Row() {
      Text(`每 ${this.interval} ${this.freqLabel()}`)
        .fontSize(Theme.FONT_BODY)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .layoutWeight(1)
        .maxLines(1)
        .textAlign(TextAlign.Start)

      Row({ space: Theme.GAP_S }) {
        Button('−', { type: ButtonType.Circle })
          .width(Theme.HIT_MIN)
          .height(Theme.HIT_MIN)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .onClick(() => {
            this.adjustInterval(-1);
          })
        Button('＋', { type: ButtonType.Circle })
          .width(Theme.HIT_MIN)
          .height(Theme.HIT_MIN)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .onClick(() => {
            this.adjustInterval(1);
          })
      }
    }
    .width('100%')
    .height(Theme.HIT_MIN + Theme.GAP_S)
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // ① 频率
          Row({ space: SEGMENT_GAP_VP }) {
            this.segment('不重复', this.frequency === FREQ_NONE, () => {
              this.frequency = FREQ_NONE;
            })
            this.segment('每天', this.frequency === FREQ_DAILY, () => {
              this.frequency = FREQ_DAILY;
            })
            this.segment('每周', this.frequency === FREQ_WEEKLY, () => {
              this.frequency = FREQ_WEEKLY;
            })
            this.segment('每月', this.frequency === FREQ_MONTHLY, () => {
              this.frequency = FREQ_MONTHLY;
            })
            this.segment('每年', this.frequency === FREQ_YEARLY, () => {
              this.frequency = FREQ_YEARLY;
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)

          // ② 每周：选星期
          if (this.frequency === FREQ_WEEKLY) {
            Text('选择星期')
              .fontSize(Theme.FONT_CAPTION)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .width('100%')
              .padding({ top: Theme.GAP_L, bottom: Theme.GAP_S })
              .textAlign(TextAlign.Start)

            Row({ space: Theme.GAP_S }) {
              this.weekdayCircle(1, '一')
              this.weekdayCircle(2, '二')
              this.weekdayCircle(3, '三')
              this.weekdayCircle(4, '四')
              this.weekdayCircle(5, '五')
              this.weekdayCircle(6, '六')
              this.weekdayCircle(7, '日')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          }

          // ③ 每月：月初 / 月中 / 月末
          if (this.frequency === FREQ_MONTHLY) {
            Text('选择日期')
              .fontSize(Theme.FONT_CAPTION)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .width('100%')
              .padding({ top: Theme.GAP_L, bottom: Theme.GAP_S })
              .textAlign(TextAlign.Start)

            Row({ space: SEGMENT_GAP_VP }) {
              this.segment('月初（1 号）', this.monthMode === MONTH_MODE_START, () => {
                this.monthMode = MONTH_MODE_START;
              })
              this.segment('月中（15 号）', this.monthMode === MONTH_MODE_MID, () => {
                this.monthMode = MONTH_MODE_MID;
              })
              this.segment('月末', this.monthMode === MONTH_MODE_END, () => {
                this.monthMode = MONTH_MODE_END;
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.Start)

            if (this.monthMode === MONTH_MODE_END) {
              Text(`月末无法用规则表达，将记录未来 ${MONTH_END_MONTHS} 个月的最后一天`)
                .fontSize(Theme.FONT_CAPTION)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .width('100%')
                .padding({ top: Theme.GAP_S })
                .textAlign(TextAlign.Start)
            }
          }

          // ④ 间隔
          if (this.frequency !== FREQ_NONE) {
            this.intervalStepper()
          }
        }
        .width('100%')
        .padding({ left: Theme.GAP_L, right: Theme.GAP_L, top: Theme.GAP_L })
      }
      .width('100%')
      .constraintSize({ maxHeight: EDITOR_MAX_HEIGHT_VP })
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

      // 底部操作条：取消 / 确定
      Row() {
        Text('取消')
          .fontSize(Theme.FONT_TITLE)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .layoutWeight(1)
          .height('100%')
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onCancel();
          })
        Text('确定')
          .fontSize(Theme.FONT_TITLE)
          .fontColor($r('sys.color.ohos_id_color_emphasize'))
          .layoutWeight(1)
          .height('100%')
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.confirm();
          })
      }
      .width('100%')
      .height(FOOTER_HEIGHT_VP)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
  }
}
