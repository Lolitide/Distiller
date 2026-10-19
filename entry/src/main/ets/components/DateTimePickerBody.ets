/*
 * 官方「日期 ＋ 时间」选择面板（**内容区**），给 `bindSheet` 当 body 用。
 *
 * 袁正锟 2026-10-17：「现在做设置截止日期 可以参考任务详情里面的设置到期时间的选择器」——
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
import { Theme } from '../utils/Theme';


/** 日期取 `date`、时分保留 `time` 的时分 */
function mergeDatePart(date: Date, time: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(),
    time.getHours(), time.getMinutes(), 0, 0);
}

/** 日期保留 `date`、时分换成本次的 `hour`/`minute` */
function mergeTimePart(date: Date, hour: number, minute: number): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(), hour, minute, 0, 0);
}

/** 补零到两位 */
function pad2(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

/** `Date` → `2026-10-19 14:30`（回填给输入框的格式，与解析格式一致） */
function formatStamp(date: Date): string {
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`
    + ` ${pad2(date.getHours())}:${pad2(date.getMinutes())}`;
}

/**
 * `2026-10-19 14:30` → `Date`。
 *
 * 宽松接受三种写法（用户手打不会严格按一种来）：
 *   `2026-10-19 14:30` / `2026/10/19 14:30` / `2026-10-19`（不带时分 ⇒ 默认 23:59，即"当天结束前"）
 * 解析不出来返回 `undefined`，由调用方决定怎么提示。
 */
function parseStamp(text: string): Date | undefined {
  const trimmed: string = text.trim();
  const match: RegExpMatchArray | null =
    trimmed.match(/^(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:\s+(\d{1,2}):(\d{1,2}))?$/);
  if (match === null) {
    return undefined;
  }
  const year: number = Number(match[1]);
  const month: number = Number(match[2]);
  const day: number = Number(match[3]);
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return undefined;
  }
  const hasTime: boolean = match[4] !== undefined;
  const hour: number = hasTime ? Number(match[4]) : 23;
  const minute: number = hasTime ? Number(match[5]) : 59;
  if (hour > 23 || minute > 59) {
    return undefined;
  }
  const result: Date = new Date(year, month - 1, day, hour, minute, 0, 0);
  // 回读校验：防止 2 月 30 日这种被 Date 自动进位成 3 月 2 日
  if (result.getFullYear() !== year || result.getMonth() !== month - 1 || result.getDate() !== day) {
    return undefined;
  }
  return result;
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

  /** 输入框里的文本（切到输入模式时由当前选择回填） */
  @Local inputText: string = '';

  build() {
    Column() {
      // ① 手动输入框：**和滚轮同屏**（2026-10-19 作者要求：
      //    「手动输入文本框和滚轮放一块，同时更新，用户指哪改哪」）。
      //    上一版做成「滚轮 / 手动输入」二选一的模式按钮，属于多此一举，已删掉。
      Column() {
        TextInput({ text: this.inputText, placeholder: '例如 2026-10-19 14:30' })
          .id('dateTimeInput')
          .width('100%')
          .height(Theme.HIT_MIN + Theme.GAP_S)
          .fontSize(Theme.FONT_BODY)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .placeholderColor($r('sys.color.ohos_id_color_text_tertiary'))
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(Theme.RADIUS_CHIP)
          .padding({ left: Theme.GAP_M, right: Theme.GAP_M })
          .maxLines(1)
          .enterKeyType(EnterKeyType.Done)
          .onChange((value: string) => {
            this.inputText = value;
            // 打得出合法时间就立刻同步给滚轮（滚轮跟着走）
            const parsed: Date | undefined = parseStamp(value);
            if (parsed !== undefined) {
              this.onSelectedChange(parsed);
            }
          })

        if (this.inputInvalid) {
          Text('格式不认识，请用「2026-10-19 14:30」这样的写法')
            .fontSize(Theme.FONT_CAPTION)
            .fontColor($r('sys.color.ohos_id_color_warning'))
            .width('100%')
            .padding({ top: Theme.GAP_S })
            .textAlign(TextAlign.Start)
        }
      }
      .width('100%')
      .padding({ left: Theme.GAP_L, right: Theme.GAP_L, top: Theme.GAP_M })

      // ② 滚轮：官方 DatePicker + TimePicker（改它 → `syncInputText` 把输入框也刷成新值）
      DatePicker({ selected: this.selected })
        .width('100%')
        .onDateChange((value: Date) => {
          // 只取日期部分，时分保留草稿里的（DatePicker 回来的 Date 带的是系统时分）
          this.onSelectedChange(mergeDatePart(value, this.selected));
          this.syncInputText();
        })

      TimePicker({ selected: this.selected })
        .useMilitaryTime(true)
        .width('100%')
        .onChange((value: TimePickerResult) => {
          this.onSelectedChange(mergeTimePart(this.selected, value.hour, value.minute));
          this.syncInputText();
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
    .onAppear(() => {
      // 面板一打开就把当前选择回填进输入框，两处从同一个值起步
      this.syncInputText();
    })
  }

  /** 把当前草稿同步成输入框文本（滚轮改动后调用，实现双向「指哪改哪」） */
  private syncInputText(): void {
    const next: string = formatStamp(this.selected);
    if (this.inputText !== next) {
      this.inputText = next;
    }
  }

  /** 输入框里的内容解析不出来时给红字提示（空串不算错，用户可能正在清空重打） */
  @Computed
  get inputInvalid(): boolean {
    const text: string = this.inputText.trim();
    return text.length > 0 && parseStamp(text) === undefined;
  }
}
