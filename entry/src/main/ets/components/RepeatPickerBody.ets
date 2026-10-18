/*
 * 重复规则面板（`bindSheet` 的 body）：**档位 ＋ 星期多选 ＋ 间隔**。
 *
 * 为什么不用现成的 `OptionPickerBody`：字段表 §1.1 要求 `repeat` 能表达「每若干天里的某几天」
 * （例子：「每周一、周二、周四」），而单列 `TextPicker` 只能选「每周」这种粗粒度档位，
 * **录不进具体星期**。所以这里在档位轮下方补一行星期多选 + 一个间隔步进器。
 *
 * 只在档位＝「每周」时展开星期与间隔：其余档位（每天/每月/每年）的锚点由截止日推出（见 `AddTaskDraft.repeatRules`），
 * 展开一堆用不上的控件反而干扰。
 *
 * 草稿由父组件持有（`@Param` 进来、`@Event` 出去）：选择器跟手改的是草稿，点「确定」才落库 ——
 * 与 `DateTimePickerBody` / `OptionPickerBody` 同一套约定。
 */
import { PickerFooter } from './PickerFooter';

/** 档位下标：与 `AddTaskAttributeChips` / `AddTaskDraft` / 详情页的 `REPEAT_OPTIONS` **同序** */
const REPEAT_INDEX_WEEKLY: number = 2;

/** 间隔上限：官方 `RecurrenceRule.interval` 没有上限，但「每 12 周」已经够表达一学期，再多没意义 */
const INTERVAL_MAX: number = 12;

/** 星期的最小/最大取值：1~7 ＝ 周一~周日（官方 `daysOfWeek` 的 range 就是 [1,7]，第 1 天是周一） */
const WEEKDAY_MIN: number = 1;
const WEEKDAY_MAX: number = 7;

@ComponentV2
export struct RepeatPickerBody {
  /** 档位文案（**已经是字符串**：`TextPicker.range` 只吃字符串数组） */
  @Require @Param options: string[];
  /** 当前草稿档位 */
  @Require @Param selectedIndex: number;
  /** 当前草稿选中的星期（1~7）；空数组 ＝ 跟随截止日那一天 */
  @Require @Param daysOfWeek: number[];
  /** 当前草稿的间隔（每 N 周），最小 1 */
  @Require @Param interval: number;
  /** 档位变了 */
  @Event onSelectedIndexChange: (index: number) => void = () => {};
  /** 星期选择变了（传回**新的**数组，不用原地改） */
  @Event onDaysOfWeekChange: (days: number[]) => void = () => {};
  /** 间隔变了 */
  @Event onIntervalChange: (interval: number) => void = () => {};
  /** 点「取消」 */
  @Event onCancel: () => void = () => {};
  /** 点「确定」 */
  @Event onConfirm: () => void = () => {};

  /** 只有「每周」才需要选星期与间隔 */
  @Computed
  get weekly(): boolean {
    return this.selectedIndex === REPEAT_INDEX_WEEKLY;
  }

  /** 星期标签：1~7 → 一~日（顺序与官方 `daysOfWeek` 一致） */
  private weekdayLabel(day: number): Resource {
    if (day === 1) {
      return $r('app.string.weekday_short_mon');
    }
    if (day === 2) {
      return $r('app.string.weekday_short_tue');
    }
    if (day === 3) {
      return $r('app.string.weekday_short_wed');
    }
    if (day === 4) {
      return $r('app.string.weekday_short_thu');
    }
    if (day === 5) {
      return $r('app.string.weekday_short_fri');
    }
    if (day === 6) {
      return $r('app.string.weekday_short_sat');
    }
    return $r('app.string.weekday_short_sun');
  }

  private isPicked(day: number): boolean {
    return this.daysOfWeek.indexOf(day) >= 0;
  }

  /** 点某一天：已选就取消，未选就加入（结果按 1~7 排序，便于阅读与比对） */
  private toggleDay(day: number): void {
    const next: number[] = [];
    let picked: boolean = false;
    this.daysOfWeek.forEach((item: number) => {
      if (item === day) {
        picked = true;
      } else {
        next.push(item);
      }
    });
    if (!picked) {
      next.push(day);
    }
    next.sort((a: number, b: number) => a - b);
    this.onDaysOfWeekChange(next);
  }

  private stepInterval(delta: number): void {
    const next: number = this.interval + delta;
    if (next < WEEKDAY_MIN || next > INTERVAL_MAX) {
      return;
    }
    this.onIntervalChange(next);
  }

  @Builder
  weekdayChip(day: number) {
    Text(this.weekdayLabel(day))
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(this.isPicked(day)
        ? $r('sys.color.ohos_id_color_text_primary_contrary')
        : $r('sys.color.ohos_id_color_text_primary'))
      .width(WEEKDAY_CHIP_SIZE_VP)
      .height(WEEKDAY_CHIP_SIZE_VP)
      .textAlign(TextAlign.Center)
      .borderRadius(WEEKDAY_CHIP_SIZE_VP / 2)
      .backgroundColor(this.isPicked(day)
        ? $r('sys.color.ohos_id_color_emphasize')
        : $r('sys.color.comp_background_secondary'))
      .onClick(() => {
        this.toggleDay(day);
      })
      .accessibilityText(this.weekdayLabel(day))
  }

  build() {
    Column() {
      TextPicker({ range: this.options, selected: this.selectedIndex })
        .width('100%')
        .onChange((value: string | string[], index: number | number[]) => {
          // 单列选择器运行时 index 一定是 number；先收窄再上报
          if (typeof index === 'number') {
            this.onSelectedIndexChange(index);
          }
        })

      if (this.weekly) {
        Column({ space: $r('sys.float.padding_level4') }) {
          Text($r('app.string.repeat_weekday_hint'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .width('100%')
            .textAlign(TextAlign.Start)

          // 周一~周日：七个等宽圆形按钮，可多选
          Row({ space: WEEKDAY_GAP_VP }) {
            ForEach(WEEKDAYS, (day: number) => {
              this.weekdayChip(day)
            }, (day: number) => `${day}`)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          // 间隔：每 N 周。N=1 时显示「每 1 周」＝ 每周，避免用户以为是"关闭"
          Row() {
            Text(`${this.interval}`)
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))

            Blank()

            Row({ space: WEEKDAY_GAP_VP }) {
              Button(INTERVAL_STEP_DOWN_TEXT, { buttonStyle: ButtonStyleMode.TEXTUAL })
                .enabled(this.interval > WEEKDAY_MIN)
                .onClick(() => {
                  this.stepInterval(-1);
                })
              Button(INTERVAL_STEP_UP_TEXT, { buttonStyle: ButtonStyleMode.TEXTUAL })
                .enabled(this.interval < INTERVAL_MAX)
                .onClick(() => {
                  this.stepInterval(1);
                })
            }
          }
          .width('100%')
        }
        .width('100%')
        .padding({
          left: $r('sys.float.padding_level8'),
          right: $r('sys.float.padding_level8')
        })
      }

      PickerFooter({
        onCancel: () => {
          this.onCancel();
        },
        onConfirm: () => {
          this.onConfirm();
        }
      })
    }
    .width('100%')
  }
}

/** 1~7 的固定顺序（周一在前，与官方 `daysOfWeek` 一致）：资源名不能运行时拼接，只能逐个列 */
const WEEKDAYS: number[] = [1, 2, 3, 4, 5, 6, 7];
/** 星期按钮直径（vp） */
const WEEKDAY_CHIP_SIZE_VP: number = 32;
/** 星期按钮间距（vp） */
const WEEKDAY_GAP_VP: number = 6;
/** 间隔步进按钮的文字：纯符号，不涉及中文，故不走资源 */
const INTERVAL_STEP_DOWN_TEXT: string = '−';
const INTERVAL_STEP_UP_TEXT: string = '＋';
