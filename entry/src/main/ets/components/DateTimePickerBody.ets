/*
 * 官方「日期 ＋ 时间」选择面板（**内容区**），给 `bindSheet` 当 body 用。
 *
 * 需求方 2026-10-17：「现在做设置截止日期 可以参考任务详情里面的设置到期时间的选择器」——
 * 详情页那套（`TaskAttributeCard.dueSheet()`）是官方 `DatePicker` + `TimePicker` + 底部「取消 / 确定」，
 * 这里把它抽成可复用组件，**两份界面不再各写一遍**（`02-编码规约.md` §10 规则 3）。
 *
 * 为什么不用 `showDatePickerDialog`：详情页那边已经查证过 —— 官方固定样式弹窗的 options 里**没有 title 字段**
 * （本机 SDK 的 `date_picker.d.ts` / `time_picker.d.ts` 全量 grep 都没有），而我们要带标题，
 * 所以只能 `bindSheet` + 官方 picker 自己摆底部按钮。
 *
 * ⚠️ 底部那条的高度/竖线**必须给普通数字**（vp），不能给 `LengthMetrics` ——
 * 第一版把 `LengthMetrics.vp(...)` 喂给 `.height()`，它没被当成长度处理，结果那条 Row 撑满剩余高度、
 * 竖细线拉成 700 多像素、两个按钮被挤出屏幕（`.cache/due-1-picker.png`）。
 *
 * 草稿由**父组件**持有（`@Param selected` 进来、`@Event onSelectedChange` 出去）：
 * 面板里的滑动选择器是即时跟手的，任务字段只在点「确定」时写回，否则滑到一半反悔点取消就已经改了。
 * `Date` 不可变，所以每次都是「整根换新」。
 */
import { PickerFooter } from './PickerFooter';

/** 日期取 `date`、时分保留 `time` 的时分 */
function mergeDatePart(date: Date, time: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(),
    time.getHours(), time.getMinutes(), 0, 0);
}

/** 日期保留 `date`、时分换成本次的 `hour`/`minute` */
function mergeTimePart(date: Date, hour: number, minute: number): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(), hour, minute, 0, 0);
}

@ComponentV2
export struct DateTimePickerBody {
  /** 当前草稿（父组件持有）；日期/时间任一变化都通过 `onSelectedChange` 交回父组件 */
  @Require @Param selected: Date;
  /** 草稿变了 */
  @Event onSelectedChange: (date: Date) => void = () => {};
  /** 点「取消」 */
  @Event onCancel: () => void = () => {};
  /** 点「确定」 */
  @Event onConfirm: () => void = () => {};

  build() {
    Column() {
      DatePicker({ selected: this.selected })
        .width('100%')
        .onDateChange((value: Date) => {
          // 只取日期部分，时分保留草稿里的（DatePicker 回来的 Date 带的是系统时分）
          this.onSelectedChange(mergeDatePart(value, this.selected));
        })

      TimePicker({ selected: this.selected })
        .useMilitaryTime(true)
        .width('100%')
        .onChange((value: TimePickerResult) => {
          this.onSelectedChange(mergeTimePart(this.selected, value.hour, value.minute));
        })

      // 底部「取消 / 确定」与单列文本面板共用同一个组件（不各写一份）
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
