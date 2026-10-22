/*
 * 任务详情的「属性编辑」卡（需求方 2026-10-16 给的官方设置页截图）。
 *
 * 造型照官方设置列表：白卡片 + 行内「圆形图标 + 文案 + 右侧操作」+ 行间细分隔线。
 * 图标底色用官方蓝（`ohos_id_color_emphasize`）实心圆 + 白色字形。
 *
 * 三个语义（需求方 2026-10-16 追加）：
 *  ① **三项固定显示** —— 没设提醒/到期/重复时行也在，只显示「未设置提醒 / 未设置到期时间 / 不重复」；
 *  ② 右侧的 **× 是"清除这一项"**（清字段），**不是删除整行**；
 *  ③ 点行本身要能改这一项（提醒时间 / 到期时间 / 重复类型）——
 *    三项都走**带标题的选择器面板**（需求方 2026-10-17：「给每个选择器加上 title」），
 *    即 `bindSheet` + `SheetOptions.title` + 官方 `DatePicker` / `TimePicker` / `TextPicker`。
 */
import { RepeatFrequency, RepeatRule, Task, TaskAlarm } from '../model';
import { TaskListViewModel } from '../viewmodel/TaskListViewModel';
import { TaskListStore } from '../viewmodel/TaskListStore';
import { DateTimePickerBody } from './DateTimePickerBody';
import { CenterDialogFrame, DialogTitle } from './CenterDialogFrame';
import { OptionPickerBody } from './OptionPickerBody';
import { RepeatRuleEditor } from './RepeatRuleEditor';
import { Theme, ThemeStore } from '../utils/Theme';

/** 圆形图标直径（vp） */
const ICON_CIRCLE_SIZE_VP: number = 32;
/** 圆内字形尺寸（vp） */
const ICON_GLYPH_SIZE_VP: number = 20;
/** 行高（vp） */
const ROW_HEIGHT_VP: number = 56;
/** 行左右内边距（vp）：官方 `padding_level8` */
const ROW_SIDE_PADDING_VP: number = 16;
/** 圆形图标与文案之间的间距（vp） */
const ICON_TEXT_GAP_VP: number = 12;
/** 右侧「清除」按钮点击热区直径（vp）：40 够好按，视觉上仍是一个小图标 */
const CLEAR_BUTTON_SIZE_VP: number = 40;
/** 周几的中文（0=周日 … 6=周六） */
const WEEKDAY_CN: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
/** 周几的序号中文（`daysOfWeek` 是 1~7 ＝ 周一~周日） */
const WEEKDAY_SHORT_CN: string[] = ['一', '二', '三', '四', '五', '六', '日'];
/**
 * 新设到期时间时的默认时刻：**当天 23:59**（「这一天结束前」，需求方既定口径「选中日 23:59」）。
 * 只决定选择器**打开时停在哪**，用户想改到 17:00 依然可以在面板里的时间选择器上改。
 */
const DUE_DEFAULT_HOUR: number = 23;
const DUE_DEFAULT_MINUTE: number = 59;
/**
 * 「重复」选择器的选项。**顺序即 index 口径** —— 末尾那几个下标常量与它一一对应，改顺序要一起改。
 *
 * 为什么只有这五档：`RepeatFrequency` 在契约里就四档（每年/每月/每周/每天，
 * 与官方 `calendarManager.RecurrenceFrequency` 取值一致），加一个「不重复」正好五档。
 * 「每周一、三、五」这种**多天**、以及「每两周」这种**间隔**，一列文本表达不了 ——
 * 现在按「锚点日的周几 / 号数」生成单条规则，要支持多选得再做一个二级选择器（见 `applyRepeat` 注释）。
 */
const REPEAT_OPTIONS: string[] = ['不重复', '每天', '每周', '每月', '每年'];

@ComponentV2
export struct TaskAttributeCard {
  /** 视觉个性化：图标圈用 M3 primary / onPrimary */
  @Local themeStore: ThemeStore = ThemeStore.instance();
  /** 要编辑的任务 */
  @Require @Param task: Task;
  /** 列表 store：清掉日期类字段后要让列表**重新分组**（否则任务会赖在原分组里） */
  @Require @Param store: TaskListStore;

  /*
   * 三个选择器面板的开关与**草稿**（需求方 2026-10-17：「给每个选择器加上 title」）。
   *
   * 为什么要有草稿：面板里的滑动选择器是**即时跟着手指变**的，而任务字段只在点「确定」时写回 ——
   * 否则用户滑到一半反悔、点「取消」，任务已经被改了。
   * `Date` 不可变，所以日期/时间是「整根换新」：`mergeDate` / `mergeTime` 造新对象赋给 `@Local`。
   */
  @Local remindSheetOpen: boolean = false;
  /** 提醒弹窗的 dialogId（openCustomDialog 返回，-1 表示未打开） */
  @Local remindDialogId: number = -1;
  @Local remindDraft: Date = new Date();
  @Local dueSheetOpen: boolean = false;
  /** 到期弹窗的 dialogId */
  @Local dueDialogId: number = -1;
  @Local dueDraft: Date = new Date();
  @Local repeatSheetOpen: boolean = false;
  /** 重复面板的草稿档位（`REPEAT_OPTIONS` 的下标） */

  /** 提醒文案：如「在 10月16日 20:00 提醒我」；没设提醒时给「未设置提醒」 */
  @Computed
  get remindLabel(): ResourceStr {
    const remind: number | undefined = this.task.remindAt;
    if (remind === undefined) {
      return $r('app.string.attr_no_remind');
    }
    const date: Date = new Date(remind);
    return `在 ${date.getMonth() + 1}月${date.getDate()}日 ${TaskListViewModel.hhmm(remind)} 提醒我`;
  }

  /** 到期文案：如「10月16日周五 到期」；没设到期时给「未设置到期时间」 */
  @Computed
  get dueLabel(): ResourceStr {
    const due: number | undefined = this.task.dueAt;
    if (due === undefined) {
      return $r('app.string.attr_no_due');
    }
    const date: Date = new Date(due);
    return `${date.getMonth() + 1}月${date.getDate()}日${WEEKDAY_CN[date.getDay()]} 到期`;
  }

  /**
   * 重复文案：**统一由 `TaskListViewModel.repeatLabel` 生成**（「每周一、二、四」/「每 2 周周二」…），
   * 本卡不再自己拼一遍——两处各写一份必然会漂移（原来这里就有一份等价实现）。
   * 规则与 `repeatText` 都没有时给「不重复」。
   */
  @Computed
  get repeatLabel(): ResourceStr {
    const label: string = TaskListViewModel.repeatLabel(this.task);
    return label.length === 0 ? $r('app.string.attr_no_repeat') : label;
  }

  /** 这一行有没有值（没值时文案是「未设置…」，且**用灰色**显示） */
  @Computed
  get remindSet(): boolean {
    return this.task.remindAt !== undefined;
  }

  @Computed
  get dueSet(): boolean {
    return this.task.dueAt !== undefined;
  }

  /*
   * 说明：这里**没有** `repeatSet`。重复那一行只有两种文案（规则 / `repeatText` 原话 / 「不重复」），
   * 其中「不重复」是**合法档位**而不是「未设置」，所以整行恒用正文黑色、不需要灰/黑两态。
   */

  /**
   * 清提醒：用户意图关掉 + 清已发布句柄。
   *
   * ⚠️ 清完同样要 `refreshGroups` —— 分组规则是「`dueAt` 优先，回退 `remindAt`」
   * （见 `TaskListViewModel` 顶部注释），所以**没有到期时间、只有提醒时间**的任务是靠提醒时间入组的；
   * 提醒被清掉它就变成「未安排日期」，不重新分组的话它会赖在原来那天不动。
   */
  private clearRemind(): void {
    this.task.alarm = TaskAlarm.OFF;
    this.task.reminderId = undefined;
    this.task.remindAt = undefined;
    this.store.refreshGroups(this.task.id);
  }

  /** 清到期 */
  private clearDue(): void {
    this.task.dueAt = undefined;
    this.task.dueText = undefined;
    // 到期时间决定任务落在哪一天（没有日期就进「未安排日期」），所以必须让列表重新分组
    this.store.refreshGroups(this.task.id);
  }

  /** 清重复 */
  private clearRepeat(): void {
    this.task.repeat = [];
    this.task.repeatText = undefined;
  }

  /**
   * 点「提醒」行 → 打开**带标题的选择器面板**。
   *
   * 为什么不再用 `showDatePickerDialog`：官方**固定样式**弹窗的 options 里**没有 title 字段** ——
   * 本机 SDK 的 `date_picker.d.ts` / `time_picker.d.ts` / `text_picker.d.ts` 全量 grep 都没有
   * `title`（日期弹窗顶部那行显示的是**选中的值**，文本弹窗干脆没有抬头），要标题只能自己搭壳。
   * 搭法全部用官方件：`bindSheet` 的 `SheetOptions.title` 做抬头，里面放官方
   * `DatePicker` + `TimePicker`，底部自己摆「取消 / 确定」。
   *
   * ⚠️ **手机上是底部面板，不是居中弹窗** —— 这是官方规定，不是本页偷懒：
   * API 参考《半模态转场》`preferType` 原文：「宽度 < 600vp：**底部、全屏**。默认底部样式。
   * 600vp <= 宽度 < 840vp：底部、**居中**、跟手、侧边、全屏」。本项目 `deviceTypes: ["phone"]`，
   * 竖屏宽度不足 600vp，`SheetType.CENTER` **不生效**（实测就是底部面板）。
   * 这里仍写着 `preferType: SheetType.CENTER` 是为了平板/2in1（宽度 ≥ 600vp）上自动居中，
   * 手机端则由系统落到默认的底部样式。
   *
   * 附带好处：日期和时间**同时可见**，不用像 `showTime: true` 那样点标题切页。
   *
   * 草稿口径：打开时按 `remindSeed()` 填草稿，改动只落在草稿上，点「确定」才写回任务。
   */
  private openRemindSheet(): void {
    this.remindDraft = this.remindSeed();
    // 2026-10-19 作者要求：日期时间改成**系统日历那样的居中弹窗**（不是底部面板）。
    // `bindSheet` 的 `preferType: CENTER` 只在宽度 ≥600vp（平板/2in1）生效，
    // 手机上仍是底部面板，所以这里直接换 `openCustomDialog` + 居中。
    this.remindDialogId = -1;
    this.getUIContext().getPromptAction().openCustomDialog({
      builder: () => {
        this.remindDialog();
      },
      alignment: DialogAlignment.Center,
      isModal: true
    }).then((id: number) => {
      this.remindDialogId = id;
    });
  }

  /** 关掉提醒面板（点「取消」）：草稿丢弃，下次打开按任务现状重填 */
  private closeRemindSheet(): void {
    this.dismissDialog(this.remindDialogId);
    this.remindDialogId = -1;
  }

  /** 提醒面板「确定」 */
  private confirmRemind(): void {
    this.applyRemind(this.remindDraft.getTime());
    this.closeRemindSheet();
  }

  /** 关掉一个弹出的自定义对话框（`dialogId` 无效时什么也不做） */
  private dismissDialog(id: number): void {
    if (id >= 0) {
      this.getUIContext().getPromptAction().closeCustomDialog(id);
    }
  }

  /**
   * 选择器的初始时刻：有提醒就用提醒；否则借截止时刻（同一刻，用户自己挪）；
   * 都没有就用「现在」。
   *
   * ⚠️ 这里**不擅自造「提前量」**：契约里「按设置页『提醒提前量』从 `dueAt` 算得」是设置页的事，
   * 那个设置项还没做，硬编码一个「提前 1 小时」会让两处口径打架。
   */
  private remindSeed(): Date {
    const remind: number | undefined = this.task.remindAt;
    if (remind !== undefined) {
      return new Date(remind);
    }
    const due: number | undefined = this.task.dueAt;
    if (due !== undefined) {
      return new Date(due);
    }
    return new Date();
  }

  /**
   * 写入提醒时刻。
   *
   * · `alarm = ON`：用户**意图**开提醒（字段表第 16 项）；卡片右侧开关读它；
   * · `reminderId` 清空：它是**已发布的本地提醒句柄**，由 `service/system/ReminderService` 发，
   *   页面里不许凭空造（§`Task` 字段第 18 项）—— 改了时刻，旧的句柄就已经作废；
   * · `refreshGroups`：分组规则是「`dueAt` 优先，回退 `remindAt`」，所以**只有提醒时间**的任务会按它入组，
   *   不重新分组就会赖在原分组里不动。
   *
   * TODO(需求方): 接 `ReminderService` 后，这里要改成「先发布提醒、成功再写 `reminderId`」，
   * 失败（如超 30 条报 1700002）时把 `alarm` 回滚并把错误提示出来。
   */
  private applyRemind(timestamp: number): void {
    this.task.remindAt = timestamp;
    this.task.alarm = TaskAlarm.ON;
    this.task.reminderId = undefined;
    this.store.refreshGroups(this.task.id);
  }

  /**
   * 点「到期」行 → 同一个带标题的选择器面板（抬头「设置到期时间」），选完写 `dueAt`。
   *
   * 为什么这里也带时间（而不是只选日期、写死 23:59）：
   * `dueAt` 本来就**有时分**，而且它是要显示出来的 —— 卡片副标题是「在 HH:mm 截止」
   * （`TaskListViewModel.dueLabel`）。只让用户选日期、把时刻钉死，等于把「截止 17:00」这种
   * 明确要求改成了「当天 23:59」，和 mock / 真实数据里 `17:00`、`19:00` 这类值也对不上。
   *
   * 但**默认值仍然是「当天 23:59」**（见 `dueSeed`）：只改日期、不动时间的用户，拿到的就是
   * 原方案里那个「选中日 23:59」的结果，不会让用户多操作一步。
   */
  private openDueSheet(): void {
    this.dueDraft = this.dueSeed();
    // 同上：改成居中弹窗（作者 2026-10-19 要求，与系统日历创建日程一致）
    this.dueDialogId = -1;
    this.getUIContext().getPromptAction().openCustomDialog({
      builder: () => {
        this.dueDialog();
      },
      alignment: DialogAlignment.Center,
      isModal: true
    }).then((id: number) => {
      this.dueDialogId = id;
    });
  }

  /** 关掉到期面板（草稿丢弃） */
  private closeDueSheet(): void {
    this.dismissDialog(this.dueDialogId);
    this.dueDialogId = -1;
  }

  /** 到期面板「确定」 */
  private confirmDue(): void {
    this.applyDue(this.dueDraft.getTime());
    this.closeDueSheet();
  }

  /**
   * 选择器的初始时刻：
   *  · 已设过到期 → 就用它（再次打开停在上次的位置）；
   *  · 没设过 → **今天 23:59**（「当天最后一刻」，与原方案「选中日 23:59」的口径一致）。
   *
   * 不借用 `remindAt`：提醒一般是**截止之前**的某个时刻，拿它当截止默认值会把「一天的最后」
   * 变成一个更早的时间点，反而不符合直觉。
   */
  private dueSeed(): Date {
    const due: number | undefined = this.task.dueAt;
    if (due !== undefined) {
      return new Date(due);
    }
    const now: Date = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate(), DUE_DEFAULT_HOUR, DUE_DEFAULT_MINUTE, 0, 0);
  }

  /**
   * 写入到期时刻。
   *
   * · `dueText`（截止**原文**，如「今晚 23:59 前」）**不动**：它记录的是来源消息当时说的话，
   *   属于溯源字段（`rawText` / `rawJson` 那一类），清除按钮才是「用户主动抹掉」的地方；
   * · `refreshGroups`：分组是「`dueAt` 优先，回退 `remindAt`」，到期一变任务就换天，
   *   不重新分组它会赖在原分组里。
   *
   * TODO(需求方): `task.missingFields` 里可能还留着 `'dueAt'`（它是解析层按 place/who/dueAt 是否为空
   * 推出来的）。现在详情页还没渲染这一栏，所以看不出矛盾；真要显示「缺失字段」之前，
   * 得把这里改成写回 `missingFields`（或者干脆由 ViewModel 现算）。
   */
  private applyDue(timestamp: number): void {
    this.task.dueAt = timestamp;
    this.store.refreshGroups(this.task.id);
  }

  /**
   * 点「重复」行 → 同一个带标题的选择器面板（抬头「设置重复」），里面是官方 `TextPicker`。
   *
   * 为什么一列五档：契约里 `frequency` 就四档（每年/每月/每周/每天），加「不重复」共五档，
   * 一列文本正好装下；要「一选多天（周一、三、五）/ 间隔 N」得再上一层二级选择器（见 `applyRepeat`）。
   */
  private openRepeatSheet(): void {
    this.repeatSheetOpen = true;
  }

  /** 关掉重复面板（草稿丢弃） */
  private closeRepeatSheet(): void {
    this.repeatSheetOpen = false;
  }

  /**
   * 交给编辑器的**回填规则**：取第一条。
   *
   * 契约允许多条规则（并集），但编辑器一次只编一条 —— 这是已知限制：
   * 编辑完会**整体替换** `repeat`。要支持"多规则并存编辑"得再做规则列表页，本轮不做。
   */
  private firstRule(): RepeatRule | undefined {
    const rules: RepeatRule[] | undefined = this.task.repeat;
    if (rules === undefined || rules.length === 0) {
      return undefined;
    }
    return rules[0];
  }

  /**
   * 选择器结果的「锚点日」：**优先用到期那天** —— 周五截止的作业设成「每周」，
   * 得到的自然是「每周五」；没有到期时间才落到今天。
   *
   * 不拿 `remindAt` 当锚点：提醒通常比截止早，拿它推周几/号数会整体错位。
   */
  private repeatAnchorDay(): Date {
    const due: number | undefined = this.task.dueAt;
    if (due !== undefined) {
      return new Date(due);
    }
    return new Date();
  }

  /**
   * 把选中的那一档写成 `RepeatRule[]`（契约里是**数组**，这里只产出一条规则）。
   *
   * · 不重复 → `repeat = []`；
   * · 每天 → `DAILY`（不带 `daysOfWeek`/`daysOfMonth`）；
   * · 每周 → `WEEKLY` + `daysOfWeek: [锚点日的周几]`（**1~7 ＝ 周一~周日**）；
   * · 每月 → `MONTHLY` + `daysOfMonth: [锚点日的号数]`；
   * · 每年 → `YEARLY` + `monthsOfYear` + `daysOfMonth`（官方字段名，与日历 `RecurrenceRule` 同名）。
   *
   * 一律 `interval = 1`（「每 1 个周期」），因为这一档选择器**表达不了「每两周」**。
   * `repeatText`（规则表达不了的补充原话，如「每学期第 3 周交一次」）会被一并清掉：
   * 用户既然用选择器改了，卡片上就不该再挂一句与之无关的旧原话。
   *
   * TODO(需求方): 要做「一选多天（周一、三、五）/ 间隔 N」就得再上一层二级选择器
   * （文本列只有单值，单选多列也不行），届时要能**合并**而不是整体替换 `repeat`。
   */
  /**
   * 把编辑器产出的规则写回任务。
   *
   * 2026-10-19 起改由 `RepeatRuleEditor` 产出**完整规则**（含每周多天 / 每月月初月中月末 / 间隔），
   * 这里只负责落库 + 清掉 `repeatText`（规则是唯一真值源，手写原话会与规则漂移）。
   * `undefined` ＝ 不重复。
   */
  private applyRepeatRule(rule: RepeatRule | undefined): void {
    if (rule === undefined) {
      this.task.repeat = [];
      this.task.repeatText = undefined;
    } else {
      this.task.repeat = [rule];
      this.task.repeatText = undefined;
    }
    this.repeatSheetOpen = false;
  }

  /**
   * 一行：蓝圆图标 ＋ 文案 ＋ 右侧 ×（×＝清除这一项，不是删行）。
   * `dim` 为真表示这一项**还没设置**，文案用灰色。
   *
   * ⚠️ 左边"可点区"和右边的 × 是**并列的兄弟节点**，外层 `Row` **不挂 onClick** ——
   * 之前把整行都挂了 onClick、× 又嵌在行里面，结果点 × 被外层的点击吞掉，
   * 表现为"点叉没生效"（需求方 2026-10-16）。
   */
  /** 官方蓝实心圆 + 白色字形（图 1 的设置项观感） */
  @Builder
  iconCircle(icon: Resource) {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(ICON_CIRCLE_SIZE_VP)
        .height(ICON_CIRCLE_SIZE_VP)
        .fill(this.themeStore.scheme.primary)
      SymbolGlyph(icon)
        .fontSize(ICON_GLYPH_SIZE_VP)
        .fontColor([this.themeStore.scheme.onPrimary])
    }
  }

  /** 每行右侧的「清除这一项」按钮（透明底的圆形 Button，热区稳定） */
  @Builder
  clearButton(onClear: () => void) {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      SymbolGlyph($r('sys.symbol.xmark'))
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor([$r('sys.color.icon_secondary')])
    }
    .width(CLEAR_BUTTON_SIZE_VP)
    .height(CLEAR_BUTTON_SIZE_VP)
    .padding(0)
    .backgroundColor(Color.Transparent)
    .accessibilityText($r('app.string.action_clear_attribute'))
    .onClick(() => {
      onClear();
    })
  }

  @Builder
  rowDivider() {
    Divider()
      .color($r('sys.color.comp_divider'))
      .strokeWidth(0.5)
      .margin({ left: ROW_SIDE_PADDING_VP + ICON_CIRCLE_SIZE_VP + ICON_TEXT_GAP_VP })
  }

  /**
   * 提醒面板内容 —— **复用 `components/DateTimePickerBody.ets`**（官方 `DatePicker` ＋ `TimePicker` ＋ 共用底部条）。
   * 原来这里内联了一份同样的内容（连 `sheetFooter`、`mergeDate`/`mergeTime` 一起）；
   * 「添加任务」那边的面板也用它，按 `references/02-编码规约.md` §10 规则 3 收成同一个组件。
   */
  @Builder
  remindDialog() {
    CenterDialogFrame() {
      DialogTitle({ text: '设置提醒时间' })
      DateTimePickerBody({
        selected: this.remindDraft,
        onSelectedChange: (date: Date) => {
          this.remindDraft = date;
        },
        onCancel: () => {
          this.closeRemindSheet();
        },
        onConfirm: () => {
          this.confirmRemind();
        }
      })
    }
  }

  /** 到期面板内容 —— 同一个 `DateTimePickerBody`，读的是到期草稿；同样放在 M3 居中弹窗里 */
  @Builder
  dueDialog() {
    CenterDialogFrame() {
      DialogTitle({ text: '设置到期时间' })
      DateTimePickerBody({
        selected: this.dueDraft,
        onSelectedChange: (date: Date) => {
          this.dueDraft = date;
        },
        onCancel: () => {
          this.closeDueSheet();
        },
        onConfirm: () => {
          this.confirmDue();
        }
      })
    }
  }

  /**
   * 重复面板内容 —— 换成 **`RepeatRuleEditor`**（2026-10-19）。
   * 旧的 `OptionPickerBody` 只有「不重复/每天/每周/每月/每年」五档，
   * 选「每周」也只能落成锚点日那一天，**没法自定义周几、也没法选月初/月中/月末**。
   */
  @Builder
  repeatSheet() {
    RepeatRuleEditor({
      initialRule: this.firstRule(),
      onCancel: () => {
        this.closeRepeatSheet();
      },
      onConfirm: (rule: RepeatRule | undefined) => {
        this.applyRepeatRule(rule);
      }
    })
  }

  /*
   * ⚠️ 三行**不抽成带值的 @Builder**：`@Builder` 的**值参数不会随状态刷新**，
   * 之前把「文案 + 灰色标记」当参数传进去，点 × 后状态变了但界面不更新
   * （需求方 2026-10-16：「点叉没有生效」的真正原因）。
   * 现在文案直接写在 `build()` 里读 `@Computed`，才会跟着字段变化重绘。
   */
  build() {
    Column() {
      // ① 提醒
      Row() {
        Row() {
          this.iconCircle($r('sys.symbol.bell'))
          // 三行的文案统一「过长不换行、不用省略号截断」，装进**横向 Scroll** 让用户左右滑动看全文
          // （需求方 2026-10-17：「都统一成横向滑动」；与任务名、步骤、标签同一套做法）
          Scroll() {
            Text(this.remindLabel)
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor(this.remindSet
                ? $r('sys.color.ohos_id_color_text_primary')
                : $r('sys.color.ohos_id_color_text_secondary'))
              .maxLines(1)
              .textAlign(TextAlign.Start)
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .margin({ left: ICON_TEXT_GAP_VP })
          .align(Alignment.Start)
        }
        .layoutWeight(1)
        .height('100%')
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          // 提醒：带标题的选择器面板（抬头「设置提醒」）
          this.openRemindSheet();
        })

        this.clearButton(() => {
          this.clearRemind();
        })
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)
      // 2026-10-19：面板已改成 `openCustomDialog` 的**居中弹窗**，不再用 `bindSheet`。
      // 原因：`preferType: CENTER` 只在宽度 ≥600vp（平板/2in1）生效，手机上仍是底部面板。

      this.rowDivider()

      // ② 到期
      Row() {
        Row() {
          this.iconCircle($r('sys.symbol.calendar'))
          Scroll() {
            Text(this.dueLabel)
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor(this.dueSet
                ? $r('sys.color.ohos_id_color_text_primary')
                : $r('sys.color.ohos_id_color_text_secondary'))
              .maxLines(1)
              .textAlign(TextAlign.Start)
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .margin({ left: ICON_TEXT_GAP_VP })
          .align(Alignment.Start)
        }
        .layoutWeight(1)
        .height('100%')
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          // 到期：同一个带标题的面板（抬头「设置到期时间」）
          this.openDueSheet();
        })

        this.clearButton(() => {
          this.clearDue();
        })
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)
      // 到期也已改成居中弹窗（2026-10-19），不再 bindSheet

      this.rowDivider()

      // ③ 重复
      Row() {
        Row() {
          this.iconCircle($r('sys.symbol.repeat'))
          Scroll() {
            Text(this.repeatLabel)
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              // **「不重复」也用正文黑色**（需求方 2026-10-17：「不重复变成黑色吧」）：
              // 它和「未设置提醒 / 未设置到期时间」不是一类 —— 那两项是**没填**，
              // 而「不重复」是重复选择器里的**一个合法档位**（等于「普通」之于重要程度），
              // 所以这一行没有灰色未设置态，`repeatSet` 也因此不再需要。
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .maxLines(1)
              .textAlign(TextAlign.Start)
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .margin({ left: ICON_TEXT_GAP_VP })
          .align(Alignment.Start)
        }
        .layoutWeight(1)
        .height('100%')
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          // 重复：带标题的面板（抬头「设置重复」），里面是官方 TextPicker
          this.openRepeatSheet();
        })

        this.clearButton(() => {
          this.clearRepeat();
        })
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)
      .bindSheet(this.repeatSheetOpen, this.repeatSheet(), {
        title: { title: $r('app.string.picker_title_repeat') },
        preferType: SheetType.CENTER,
        height: SheetSize.FIT_CONTENT,
        showClose: false,
        dragBar: false,
        onDisappear: () => {
          this.repeatSheetOpen = false;
        }
      })
    }
    .width('100%')
    // 卡片底 = M3 `surface-container-low`（2026-10-21 需求方：「详情页这些卡片的背景颜色都和设置页的卡片一样
    // 用 md 取色，不要白色」）。原来取的是系统 `ohos_id_color_card_bg`，浅色主题下就是**纯白**，
    // 与设置页 / 元信息卡的 M3 容器色系对不上。色值只从 `ThemeStore.scheme` 取，不写死。
    .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
    .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
    .clip(true)
  }
}
