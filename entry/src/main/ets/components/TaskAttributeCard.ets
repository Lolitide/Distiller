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
/** 选择器面板底部按钮条：行高与中间竖分割线高度（vp） */
const SHEET_FOOTER_HEIGHT_VP: number = 48;
const SHEET_FOOTER_DIVIDER_VP: number = 20;
/**
 * 「重复」选择器的选项。**顺序即 index 口径** —— 末尾那几个下标常量与它一一对应，改顺序要一起改。
 *
 * 为什么只有这五档：`RepeatFrequency` 在契约里就四档（每年/每月/每周/每天，
 * 与官方 `calendarManager.RecurrenceFrequency` 取值一致），加一个「不重复」正好五档。
 * 「每周一、三、五」这种**多天**、以及「每两周」这种**间隔**，一列文本表达不了 ——
 * 现在按「锚点日的周几 / 号数」生成单条规则，要支持多选得再做一个二级选择器（见 `applyRepeat` 注释）。
 */
const REPEAT_OPTIONS: string[] = ['不重复', '每天', '每周', '每月', '每年'];
const REPEAT_INDEX_NONE: number = 0;
const REPEAT_INDEX_DAILY: number = 1;
const REPEAT_INDEX_WEEKLY: number = 2;
const REPEAT_INDEX_MONTHLY: number = 3;
const REPEAT_INDEX_YEARLY: number = 4;

/** `Date.getDay()`（0=周日…6=周六）→ 契约里的 `daysOfWeek`（**1~7 ＝ 周一~周日**，官方 range [1,7]） */
function toDaysOfWeek(date: Date): number {
  const weekday: number = date.getDay();
  return weekday === 0 ? 7 : weekday;
}

/** 把「日期取 `date`、时分取 `time`」合成一个新的 `Date`（`Date` 不可变，只能造新的） */
function mergeDate(date: Date, time: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(),
    time.getHours(), time.getMinutes(), 0, 0);
}

/** 把「日期取 `date`、时分换成本次的 `hour`/`minute`」合成一个新的 `Date` */
function mergeTime(date: Date, hour: number, minute: number): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(), hour, minute, 0, 0);
}

@ComponentV2
export struct TaskAttributeCard {
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
  @Local remindDraft: Date = new Date();
  @Local dueSheetOpen: boolean = false;
  @Local dueDraft: Date = new Date();
  @Local repeatSheetOpen: boolean = false;
  /** 重复面板的草稿档位（`REPEAT_OPTIONS` 的下标） */
  @Local repeatDraftIndex: number = REPEAT_INDEX_NONE;

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
   * 重复文案：有规则时**把周几列出来**（「每周一、二、四」），规则表达不了时退回 `repeatText`，
   * 都没有就给「不重复」。
   */
  @Computed
  get repeatLabel(): ResourceStr {
    const rules: RepeatRule[] | undefined = this.task.repeat;
    if (rules !== undefined && rules.length > 0) {
      const parts: string[] = [];
      rules.forEach((rule: RepeatRule) => {
        const interval: number = rule.interval === undefined ? 1 : rule.interval;
        // 「每 1 个周期」读作「每」：`interval = 1` 时拼成「每天 / 每周五 / 每月 1 号 / 每年」，
        // 只有真的隔了 N 个周期才写「每 2 周…」。选择器目前只产出 `interval = 1`，
        // 所以这里的第一种写法就是它的常态显示。
        const prefix: string = interval === 1 ? '每' : `每 ${interval} `;
        if (rule.frequency === RepeatFrequency.WEEKLY) {
          const days: number[] | undefined = rule.daysOfWeek;
          if (days !== undefined && days.length > 0) {
            const names: string[] = [];
            days.forEach((d: number) => {
              // daysOfWeek 用 1~7 ＝ 周一~周日
              names.push(WEEKDAY_SHORT_CN[(d - 1 + 7) % 7]);
            });
            parts.push(`${prefix}周${names.join('、')}`);
          } else {
            parts.push(`${prefix}周`);
          }
        } else if (rule.frequency === RepeatFrequency.DAILY) {
          parts.push(`${prefix}天`);
        } else if (rule.frequency === RepeatFrequency.MONTHLY) {
          const days: number[] | undefined = rule.daysOfMonth;
          parts.push(days !== undefined && days.length > 0 ? `${prefix}月 ${days.join('、')} 号` : `${prefix}月`);
        } else {
          parts.push(`${prefix}年`);
        }
      });
      return parts.join('；');
    }
    const text: string | undefined = this.task.repeatText;
    return text === undefined || text.length === 0 ? $r('app.string.attr_no_repeat') : text;
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

  @Computed
  get repeatSet(): boolean {
    const rules: RepeatRule[] | undefined = this.task.repeat;
    const text: string | undefined = this.task.repeatText;
    return (rules !== undefined && rules.length > 0) || (text !== undefined && text.length > 0);
  }

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
    this.remindSheetOpen = true;
  }

  /** 关掉提醒面板（点「取消」/ 点遮罩 / 返回键）：草稿丢弃，下次打开按任务现状重填 */
  private closeRemindSheet(): void {
    this.remindSheetOpen = false;
  }

  /** 提醒面板「确定」 */
  private confirmRemind(): void {
    this.applyRemind(this.remindDraft.getTime());
    this.remindSheetOpen = false;
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
    this.dueSheetOpen = true;
  }

  /** 关掉到期面板（草稿丢弃） */
  private closeDueSheet(): void {
    this.dueSheetOpen = false;
  }

  /** 到期面板「确定」 */
  private confirmDue(): void {
    this.applyDue(this.dueDraft.getTime());
    this.dueSheetOpen = false;
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
    this.repeatDraftIndex = this.repeatSeedIndex();
    this.repeatSheetOpen = true;
  }

  /** 关掉重复面板（草稿丢弃） */
  private closeRepeatSheet(): void {
    this.repeatSheetOpen = false;
  }

  /** 重复面板「确定」：把草稿档位写成规则再收起 */
  private confirmRepeat(): void {
    this.applyRepeat(this.repeatDraftIndex);
    this.repeatSheetOpen = false;
  }

  /**
   * 选择器打开时停在哪一档：按**第一条**规则的频率倒推。
   * 没有规则就停在「不重复」。
   *
   * ⚠️ 现有规则可能是**多条**（如「每周一」+「每月 15 号」，契约支持并集），
   * 一列文本只能显示其中一档 —— 这里按第一条显示，改动时会整体替换（见 `applyRepeat`）。
   */
  private repeatSeedIndex(): number {
    const rules: RepeatRule[] | undefined = this.task.repeat;
    if (rules === undefined || rules.length === 0) {
      return REPEAT_INDEX_NONE;
    }
    const frequency: RepeatFrequency = rules[0].frequency;
    if (frequency === RepeatFrequency.DAILY) {
      return REPEAT_INDEX_DAILY;
    }
    if (frequency === RepeatFrequency.WEEKLY) {
      return REPEAT_INDEX_WEEKLY;
    }
    if (frequency === RepeatFrequency.MONTHLY) {
      return REPEAT_INDEX_MONTHLY;
    }
    return REPEAT_INDEX_YEARLY;
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
  private applyRepeat(index: number): void {
    if (index === REPEAT_INDEX_NONE) {
      this.task.repeat = [];
      this.task.repeatText = undefined;
      return;
    }
    const anchor: Date = this.repeatAnchorDay();
    const rule: RepeatRule = new RepeatRule();
    rule.interval = 1;
    if (index === REPEAT_INDEX_DAILY) {
      rule.frequency = RepeatFrequency.DAILY;
    } else if (index === REPEAT_INDEX_WEEKLY) {
      rule.frequency = RepeatFrequency.WEEKLY;
      rule.daysOfWeek = [toDaysOfWeek(anchor)];
    } else if (index === REPEAT_INDEX_MONTHLY) {
      rule.frequency = RepeatFrequency.MONTHLY;
      rule.daysOfMonth = [anchor.getDate()];
    } else {
      rule.frequency = RepeatFrequency.YEARLY;
      rule.monthsOfYear = [anchor.getMonth() + 1];
      rule.daysOfMonth = [anchor.getDate()];
    }
    this.task.repeat = [rule];
    this.task.repeatText = undefined;
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
        .fill($r('sys.color.ohos_id_color_emphasize'))
      SymbolGlyph(icon)
        .fontSize(ICON_GLYPH_SIZE_VP)
        .fontColor([$r('sys.color.ohos_id_color_text_primary_contrary')])
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
   * 选择器面板底部那一条「取消 / 确定」：照官方弹窗的排布 —— 等分、中间一条竖细分割线、纯文字。
   * 参数只是回调、不带「会变的值」，所以不受「@Builder 值参数不刷新」那条坑影响。
   */
  @Builder
  sheetFooter(onCancel: () => void, onConfirm: () => void) {
    Row() {
      Text($r('app.string.action_cancel'))
        .layoutWeight(1)
        .height(SHEET_FOOTER_HEIGHT_VP)
        .textAlign(TextAlign.Center)
        .fontSize($r('sys.float.ohos_id_text_size_button1'))
        .fontColor($r('sys.color.font_emphasize'))
        .onClick(() => {
          onCancel();
        })

      Divider()
        .vertical(true)
        .height(SHEET_FOOTER_DIVIDER_VP)
        .color($r('sys.color.comp_divider'))

      Text($r('app.string.action_confirm'))
        .layoutWeight(1)
        .height(SHEET_FOOTER_HEIGHT_VP)
        .textAlign(TextAlign.Center)
        .fontSize($r('sys.float.ohos_id_text_size_button1'))
        .fontColor($r('sys.color.font_emphasize'))
        .onClick(() => {
          onConfirm();
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 提醒面板内容：官方 `DatePicker` + `TimePicker`，改的是草稿，点「确定」才写回任务 */
  @Builder
  remindSheet() {
    Column() {
      DatePicker({ selected: this.remindDraft })
        .width('100%')
        .onDateChange((value: Date) => {
          // 只取日期部分，时分保留草稿里的（DatePicker 回来的 Date 带的是系统时分）
          this.remindDraft = mergeDate(value, this.remindDraft);
        })

      TimePicker({ selected: this.remindDraft })
        .useMilitaryTime(true)
        .width('100%')
        .onChange((value: TimePickerResult) => {
          this.remindDraft = mergeTime(this.remindDraft, value.hour, value.minute);
        })

      this.sheetFooter(() => {
        this.closeRemindSheet();
      }, () => {
        this.confirmRemind();
      })
    }
    .width('100%')
  }

  /** 到期面板内容：与提醒同一个造型，读的是到期草稿 */
  @Builder
  dueSheet() {
    Column() {
      DatePicker({ selected: this.dueDraft })
        .width('100%')
        .onDateChange((value: Date) => {
          this.dueDraft = mergeDate(value, this.dueDraft);
        })

      TimePicker({ selected: this.dueDraft })
        .useMilitaryTime(true)
        .width('100%')
        .onChange((value: TimePickerResult) => {
          this.dueDraft = mergeTime(this.dueDraft, value.hour, value.minute);
        })

      this.sheetFooter(() => {
        this.closeDueSheet();
      }, () => {
        this.confirmDue();
      })
    }
    .width('100%')
  }

  /** 重复面板内容：官方 `TextPicker`（一列五档），改草稿档位，点「确定」才映射成规则 */
  @Builder
  repeatSheet() {
    Column() {
      TextPicker({ range: REPEAT_OPTIONS, selected: this.repeatDraftIndex })
        .width('100%')
        .onChange((value: string | string[], index: number | number[]) => {
          // 单列选择器运行时 index 一定是 number；先收窄再赋值
          if (typeof index === 'number') {
            this.repeatDraftIndex = index;
          }
        })

      this.sheetFooter(() => {
        this.closeRepeatSheet();
      }, () => {
        this.confirmRepeat();
      })
    }
    .width('100%')
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
      // 面板绑在这一行上：抬头用官方 `SheetOptions.title`；
      // `preferType: CENTER` 只在宽度 ≥600vp（平板/2in1）生效，手机上是底部面板（官方限制，见 openRemindSheet）
      .bindSheet(this.remindSheetOpen, this.remindSheet(), {
        title: { title: $r('app.string.picker_title_remind') },
        preferType: SheetType.CENTER,
        height: SheetSize.FIT_CONTENT,
        showClose: false,
        dragBar: false,
        onDisappear: () => {
          // 点遮罩 / 返回键关掉面板时把开关同步回来，否则下次点行打不开
          this.remindSheetOpen = false;
        }
      })

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
      .bindSheet(this.dueSheetOpen, this.dueSheet(), {
        title: { title: $r('app.string.picker_title_due') },
        preferType: SheetType.CENTER,
        height: SheetSize.FIT_CONTENT,
        showClose: false,
        dragBar: false,
        onDisappear: () => {
          this.dueSheetOpen = false;
        }
      })

      this.rowDivider()

      // ③ 重复
      Row() {
        Row() {
          this.iconCircle($r('sys.symbol.repeat'))
          Scroll() {
            Text(this.repeatLabel)
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor(this.repeatSet
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
    // 卡片白：与列表页卡片同一个官方 token
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
    .clip(true)
  }
}
