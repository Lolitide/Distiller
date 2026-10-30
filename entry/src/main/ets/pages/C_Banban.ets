/**
 * 「板板」页：专门看**有 ddl 的任务**。
 *
 * 布局（2026-10-22 需求）：
 *  · 上 80%：选中任务的简要详情（标题 / 步骤 / ddl / 可选来源·重复·图片·文件 / 重要性 / 难易 / 类型），
 *    底部按钮跳到完整任务详情；
 *  · 下 20%：甘特图 —— 顶部时间刻度（月/日），左侧按**标签**分轨；
 *    每根条从 `createdAt`（添加到 App 的时刻）画到 `dueAt`。
 *
 * 为什么用 Canvas：轨道的坐标要按时间比例算，用组件堆 `position` 既难对齐也难画刻度。
 */
import { common } from '@kit.AbilityKit';
import { i18n } from '@kit.LocalizationKit';
import { display, LengthMetrics } from '@kit.ArkUI';
import { Theme, ThemeStore } from '../utils/Theme';
import { WindowInsets } from '../utils/WindowInsets';
import { Task, TaskPriority, TaskStatus, TaskStep } from '../model';
import { TaskListStore } from '../viewmodel/TaskListStore';
import { TaskListViewModel } from '../viewmodel/TaskListViewModel';
import { NAV_STACK_KEY, ROUTE_TASK_DETAIL, TaskDetailParam } from '../viewmodel/TaskNavParams';
import { EmptyHint } from '../components/EmptyHint';
import { showDeleteConfirmDialog } from '../utils/DeleteConfirmDialog';

/** 甘特图左侧轨道名列宽（vp） */
const GANTT_LABEL_W_VP: number = 64;
/** 副标题相对标题栏的上提量（vp）：收掉标题栏底部自带的留白 */
const SUBTITLE_PULL_UP_VP: number = 10;

/** 顶部时间刻度区默认高度（vp），可拖动顶部拉条调整 */
const GANTT_AXIS_H_VP: number = 28;
/** 表头顶部「拉长条」高度（vp） */
const GANTT_STRIP_VP: number = 12;
/** 绘图区向左偏移（vp）：轨道名不动，只有网格/条/刻度左移 */
const PLOT_SHIFT_VP: number = 25;
/** 轨道之间缝隙（vp） */
const LANE_GAP_VP: number = 4;
/** 最多同时显示几条轨道（超出的上下滚动） */
const VISIBLE_LANES: number = 3;
/** 每条轨道固定高度（vp） */
const LANE_H_VP: number = 26;
/** 缩放档位：时间窗口长度（天）。默认 3 天（下标 1） */
const ZOOM_DAYS: number[] = [1, 3, 7, 14, 30];
const DEFAULT_ZOOM_INDEX: number = 1;
/** 底部渐变遮罩高度（vp）：与任务列表 / 设置页同一套，内容滑到胶囊和＋下方时淡出 */
const BOTTOM_MASK_VP: number = 140;
/** 底部悬浮导航让位高度（vp）：胶囊 56 + 边距 16 + 安全区，甘特背景要一直铺到屏幕底 */
const BOTTOM_NAV_CLEARANCE_VP: number = 112;
/** 在旧上限之上再多给一点上拉空间（vp）：只加高度，不做半屏态 */
const GANTT_EXTRA_PULL_VP: number = 48;
/** 甘特条配色（按轨道轮换；与主题无关，保证相邻轨道可分） */
const LANE_COLORS: string[] = ['#5B8FF9', '#61DDAA', '#F6BD16', '#7262FD', '#78D3F8', '#9661BC', '#E8684A'];

/** 已完成任务标题右侧对钩的颜色（绿色） */
const COMPLETED_CHECK_COLOR: string = '#2E7D32';
/** 已完成对钩图标尺寸（vp） */
const COMPLETED_CHECK_SIZE: number = 22;
/** 左滑操作按钮：删除的警示红、按钮宽度（vp） */
const SWIPE_DELETE_COLOR: string = '#D32F2F';
/** 已完成任务的「撤销」按钮：黑底白标 */
const SWIPE_UNDO_COLOR: string = '#1F1F1F';
const SWIPE_ACTION_WIDTH_VP: number = 56;
/** 按钮区左侧留白（vp）：露出的总宽度 = 56 + 8 */
const SWIPE_ACTION_PADDING_VP: number = 8;
/** 左滑展开宽度（vp） */
const SWIPE_REVEAL_VP: number = SWIPE_ACTION_WIDTH_VP + SWIPE_ACTION_PADDING_VP;

/**
 * 甘特条命中矩形（像素坐标）：用来判断**同一轨道内**哪些时间段有多条任务重叠。
 * 重叠部分画成深色，非重叠部分保持原来的轨道色。
 */
class GanttBar {
  laneIndex: number = 0;
  x0: number = 0;
  x1: number = 0;
}

/** 重叠段颜色 = 轨道色 × 该系数（只比原色稍深一点，太深会显得脏） */
const OVERLAP_DARKEN_FACTOR: number = 0.85;

@ComponentV2
export struct C_Banban {
  @Require @Param store: TaskListStore;
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 底部遮罩颜色：取甘特面板同色，铺到屏幕底时不出现一条突兀的白色 */
  @Computed
  get bottomMaskColors(): Array<[ResourceColor, number]> {
    const panel: string = this.themeStore.scheme.surfaceContainerLow;
    return [
      [Theme.withAlpha(panel, '00'), 0.0],
      [Theme.withAlpha(panel, '40'), 0.25],
      [Theme.withAlpha(panel, '8C'), 0.49],
      [Theme.withAlpha(panel, 'CC'), 0.70],
      [Theme.withAlpha(panel, 'EE'), 0.85],
      [Theme.withAlpha(panel, 'FF'), 1.0]
    ];
  }
  /** 当前时间轴的位置（毫秒）；拖动时间轴时更新，上方简要详情显示它穿过的事件 */
  @Local cursorMs: number = 0;
  /** 缩放档位（只有用户点 + / − 才变） */
  @Local zoomIndex: number = DEFAULT_ZOOM_INDEX;
  /** 时间窗起点（拖动到边缘时平移） */
  @Local windowStartMs: number = 0;
  /** 正在按下的卡片（按下微缩） */
  @Local pressedTaskId: number = -1;
  /** 正在按下的左滑按钮 key（`任务id-check` / `任务id-trash`），用于下浮动画 */
  @Local pressedActionKey: string = '';
  /** 当前处于展开（左滑）状态的任务 id；-1 表示没有 */
  @Local swipeOpenTaskId: number = -1;
  /** 硬切收起时：临时禁用该卡片的出入场 transition，避免重建时闪一下 */
  @Local suppressEnterTaskId: number = -1;
  /** 每个任务的 key 版本号：需要硬切时 +1，让该 ListItem 重建（左滑状态直接归零） */
  private swipeTokens: Record<string, number> = {};
  /** 摘要卡列表的控制器：点操作按钮后用它收起左滑（原生 swipeAction 的复位入口） */
  private summaryScroller: ListScroller = new ListScroller();
  /** 拉条额外展开的高度：露出更多轨道（轨道全露或表头顶到屏幕中线就停） */
  @Local ganttExpandVp: number = 0;
  /** 是否正在拖表头拉条（拖动时给表头加一道向上的阴影） */
  @Local headerDragging: boolean = false;
  private cursorInit: boolean = false;
  /** 是否正在拖可动轴底部的圆标 */
  /** 轨道区纵向滚动器（自己接管手势，保证与横向拖轴互斥） */
  private ganttScroller: Scroller = new Scroller();
  private stripStartY: number = 0;
  private stripStartExpand: number = 0;
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);
  /** 表头（时间刻 + 金色下三角）单独一块画布，纵向滚动时固定不动 */
  private headerSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private headerCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.headerSettings);
  private redrawTimer: number = -1;
  /** 状态栏高度（vp）：本页隐藏了 HDS 标题栏，自己画标题行，需要让开系统栏 */
  @Local statusBarVp: number = 0;

  /**
   * 标题下方那行「现在是 10月30日 星期五 上午 12:15」（2026-10-27 需求方：「把副标题加回去啊」）。
   *
   * ⚠️ 为什么**不**再交给 HDS 的 `subTitle`：MINI 标题栏把主标题 + 副标题上下排在同一档高度里，
   * 一有副标题就把主标题顶高 ~9vp（实测三页标题框 y：任务列表/设置=180，板板带副标题时=148），
   * 而需求方刚要求「板板 mainTitle 和其他两页一致」。两件事要同时成立，只能把副标题**画在标题栏下方**
   * 的第一行位置 —— 视觉上仍是"标题 + 副标题"，但不参与标题栏的排版。
   */
  @Local nowLabel: string = '';

  aboutToAppear(): void {
    const ctx: common.Context | undefined = this.getUIContext().getHostContext();
    if (ctx !== undefined) {
      WindowInsets.topPx(ctx).then((px: number) => {
        this.statusBarVp = px > 0 ? this.getUIContext().px2vp(px) : 0;
      });
    }
    // 副标题先算一次，别等第一次定时器
    this.refreshNowLabel();
    // 同步会持续往 store 里 upsert，甘特图每 5 秒重画一次即可（不做高频动画）；
    // 副标题（分钟精度）搭同一趟车刷新，不另开一个时钟定时器
    this.redrawTimer = setInterval(() => {
      this.drawGantt();
      this.refreshNowLabel();
    }, 5000);
  }

  aboutToDisappear(): void {
    if (this.redrawTimer >= 0) {
      clearInterval(this.redrawTimer);
      this.redrawTimer = -1;
    }
  }

  /**
   * 副标题文案：**跟随系统是 12 还是 24 小时制**（2026-10-27 需求方：
   * 「这个时间能不能根据系统是 24 小时制还是 12 小时制显示」）。
   *
   *  · 24 小时制：`现在是  10月30日  星期五  22:25`
   *  · 12 小时制：`现在是  10月30日  星期五  晚上 10:25`（带"凌晨/上午/下午/晚上"时段）
   *
   * 判定用官方 `i18n.System.is24HourClock()`（@ohos.i18n，API 9 起）。
   * 每次刷新都重新读一次 —— 用户在系统设置里改了格式，几秒内就会跟着变，不用重进页面。
   */
  private refreshNowLabel(): void {
    const d: Date = new Date();
    const datePart: string = `现在是  ${TaskListViewModel.pad2(d.getMonth() + 1)}月`
      + `${TaskListViewModel.pad2(d.getDate())}日  `
      + `${TaskListViewModel.weekdayCn(d.getDay())}`;
    const minute: string = TaskListViewModel.pad2(d.getMinutes());
    let use24: boolean = true;
    try {
      use24 = i18n.System.is24HourClock();
    } catch (error) {
      // 查询失败就按 24 小时制显示（本工程默认口径），不能因为一个格式查询把副标题弄没
      use24 = true;
    }
    const clock: string = use24
      ? `${TaskListViewModel.pad2(d.getHours())}:${minute}`
      : `${TaskListViewModel.periodLabel(d.getHours())} ${TaskListViewModel.hour12(d.getHours())}:${minute}`;
    this.nowLabel = `${datePart}  ${clock}`;
  }

  /**
   * 有 ddl 的任务，按截止时间升序。
   *
   * ⚠️ `store.allTasks()` 把「待确认消息」也摊平进来了（见 TaskListStore.allTasks），
   * 而板板只该画**已确认的待办** —— 待确认还只是候选，用户没点「保留」前不该出现在甘特图上。
   * 所以这里显式过滤掉 `PENDING_CONFIRM`（2026-10-29 修 bug）。
   */
  private dueTasks(): Task[] {
    const out: Task[] = [];
    const all: Task[] = this.store.allTasks();
    for (let i = 0; i < all.length; i++) {
      const t: Task = all[i];
      if (t.status === TaskStatus.PENDING_CONFIRM) {
        continue;
      }
      if (t.dueAt !== undefined && t.dueAt > 0) {
        out.push(t);
      }
    }
    // ⚠️ 这里**不按完成状态排序**：轨道顺序与每根条的纵向位置只由 ddl 决定，
    // 任务被勾完成时甘特图必须保持原样，不能因为排序变化把轨道搬到别处（2026-10-29 需求方）。
    // 「已完成排到最后」只作用于上方摘要列表（见 `detailTasks`）。
    out.sort((a: Task, b: Task) => (a.dueAt as number) - (b.dueAt as number));
    return out;
  }

  /** 时间轴当前命中的任务（起止时间覆盖 cursorMs 的甘特条） */
  private detailTasks(): Task[] {
    const list: Task[] = this.dueTasks();
    const out: Task[] = [];
    if (list.length === 0) {
      return out;
    }
    const start: number = this.windowStart();
    const end: number = start + this.windowMs();
    const cursor: number = Math.min(Math.max(this.cursorMs > 0 ? this.cursorMs : Date.now(), start), end);
    for (let i = 0; i < list.length; i++) {
      const t: Task = list[i];
      const t0: number = t.createdAt > 0 ? t.createdAt : 0;
      const t1: number = t.dueAt as number;
      if (cursor >= t0 && cursor <= t1) {
        out.push(t);
      }
    }
    // 与图表左侧轨道从上到下同序；同一轨道内按 ddl 先后；已完成的任务排最后
    const lanes: string[] = this.lanes();
    out.sort((a: Task, b: Task) => {
      const ac: number = a.status === TaskStatus.COMPLETED ? 1 : 0;
      const bc: number = b.status === TaskStatus.COMPLETED ? 1 : 0;
      if (ac !== bc) {
        return ac - bc;
      }
      const ia: number = lanes.indexOf(this.laneOf(a));
      const ib: number = lanes.indexOf(this.laneOf(b));
      if (ia !== ib) {
        return ia - ib;
      }
      return (a.dueAt as number) - (b.dueAt as number);
    });
    return out;
  }

  private rangeStart(): number {
    const list: Task[] = this.dueTasks();
    let start: number = Number.MAX_SAFE_INTEGER;
    for (let i = 0; i < list.length; i++) {
      start = Math.min(start, list[i].createdAt);
    }
    return start === Number.MAX_SAFE_INTEGER ? Date.now() : start;
  }

  /** 固定时间窗口长度（不再按任务跨度自动拉伸，只有用户缩放才变） */
  private windowMs(): number {
    return ZOOM_DAYS[this.zoomIndex] * 86400000;
  }

  /**
   * 蓝色背景板高度：默认露出 VISIBLE_LANES 条轨道；
   * 按住顶部拉条往上拖会多露轨道（不是加高空白表头），轨道全露或顶到屏幕中线就停。
   */
  private ganttBoxHeight(): number {
    // 完全收起时只留顶部触发行（表头 + 轨道区一起隐藏）
    if (this.ganttCollapsed()) {
      return GANTT_STRIP_VP + 16;
    }
    return GANTT_STRIP_VP + GANTT_AXIS_H_VP + this.ganttVisibleBodyHeight() + 16;
  }

  /** 是否已折叠到只剩顶部拉条（触发行） */
  private ganttCollapsed(): boolean {
    return this.ganttVisibleBodyHeight() <= 0;
  }

  /** 默认可见的轨道区高度（最多 VISIBLE_LANES 条） */
  private ganttBaseBodyHeight(): number {
    const count: number = Math.min(Math.max(1, this.lanes().length), VISIBLE_LANES);
    return count * LANE_H_VP + (count - 1) * LANE_GAP_VP;
  }

  /** 往上最多还能拖出多少高度（轨道全部露出来为止） */
  private ganttMaxExpand(): number {
    return Math.max(0, this.ganttLanesHeight() - this.ganttBaseBodyHeight());
  }

  /** 往下最多能收多少：可以一路收掉表头与轨道区，只剩顶部触发行 */
  private ganttMinExpand(): number {
    return -(GANTT_AXIS_H_VP + this.ganttBaseBodyHeight());
  }

  /**
   * 最大展开：轨道全露 / 面板顶到屏幕中线再多给一点空间，两者取小。
   * 只把旧上限抬高 `GANTT_EXTRA_PULL_VP`，不再进入半屏态。
   */
  private ganttExpandCap(): number {
    const screenVp: number = px2vp(display.getDefaultDisplaySync().height);
    const boxAtBase: number = GANTT_STRIP_VP + GANTT_AXIS_H_VP + this.ganttBaseBodyHeight() + 16;
    const byScreen: number = Math.max(0, screenVp * 0.5 - BOTTOM_NAV_CLEARANCE_VP - boxAtBase);
    return Math.max(0, Math.min(this.ganttMaxExpand(), byScreen + GANTT_EXTRA_PULL_VP));
  }

  /** 甘特面板总高：贴底但不改变图表位置；底部多出的 112vp 只是背景延伸 */
  private ganttPanelHeight(): number {
    return this.ganttBoxHeight() + BOTTOM_NAV_CLEARANCE_VP;
  }

  /** 当前轨道区可见高度 = 默认 + 拉条展开（不超过全部轨道；可一直收到 0） */
  private ganttVisibleBodyHeight(): number {
    const want: number = this.ganttBaseBodyHeight() + this.ganttExpandVp;
    return Math.min(this.ganttLanesHeight(), Math.max(0, want));
  }

  /** 轨道 = 去重后的「第一个标签」；没有标签归到「未分类」 */
  private lanes(): string[] {
    const out: string[] = [];
    const list: Task[] = this.dueTasks();
    for (let i = 0; i < list.length; i++) {
      const lane: string = this.laneOf(list[i]);
      if (out.indexOf(lane) < 0) {
        out.push(lane);
      }
    }
    return out;
  }

  private laneOf(task: Task): string {
    const tags: string[] | undefined = task.tags;
    if (tags !== undefined && tags.length > 0 && tags[0].length > 0) {
      return tags[0];
    }
    return '未分类';
  }

  /** 任务所在轨道 → 与甘特条同色（卡片上的类型 tag 用） */
  private laneColorOf(task: Task): string {
    const lanes: string[] = this.lanes();
    let index: number = lanes.indexOf(this.laneOf(task));
    if (index < 0) {
      index = 0;
    }
    return LANE_COLORS[index % LANE_COLORS.length];
  }

  /** 同色但更浅的一层底色（`#AARRGGBB`），用来托住文字 */
  private laneTintOf(task: Task): string {
    const color: string = this.laneColorOf(task);
    return `#33${color.substring(1)}`;
  }

  /** 表头顶部拉条：按住上下拖，调整轨道可见高度；上限比旧版多 48vp */
  private handleStripTouch(event: TouchEvent): void {
    if (event.touches.length === 0) {
      return;
    }
    const p: TouchObject = event.touches[0];
    if (event.type === TouchType.Down) {
      this.getUIContext().animateTo({ duration: 160, curve: Curve.EaseOut }, () => {
        this.headerDragging = true;
      });
      // 用屏幕坐标：面板变高时控件本身会移动，组件内坐标会跟着漂
      this.stripStartY = p.screenY;
      this.stripStartExpand = this.ganttExpandVp;
    } else if (event.type === TouchType.Move) {
      // 卡片底边固定、上沿跟手：往上拖 → 多露出轨道
      const want: number = this.stripStartExpand + (this.stripStartY - p.screenY);
      const cap: number = this.ganttExpandCap();
      // 收起方向允许到负值，但最少保留 1 条轨道
      this.ganttExpandVp = Math.min(cap, Math.max(this.ganttMinExpand(), want));
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.getUIContext().animateTo({ duration: 160, curve: Curve.EaseOut }, () => {
        this.headerDragging = false;
      });
    }
  }

  /** 甘特画布总高（表头 + 轨道） */
  private ganttHeight(): number {
    const count: number = Math.max(1, this.lanes().length);
    return GANTT_AXIS_H_VP + count * LANE_H_VP + (count - 1) * LANE_GAP_VP;
  }

  /** 只算轨道区高度（表头固定在外面，不参与纵向滚动） */
  private ganttLanesHeight(): number {
    const count: number = Math.max(1, this.lanes().length);
    return count * LANE_H_VP + (count - 1) * LANE_GAP_VP;
  }

  /** 时间刻度步长：按窗口长度选档（表头与图表共用，保证竖线对齐） */
  private tickStep(span: number): number {
    const day: number = 86400000;
    if (span <= 1.5 * day) {
      // 最小比例尺（1 天）：每 6 小时一条竖线 + 时间刻
      return 6 * 3600000;
    }
    if (span <= 4 * day) {
      return day;
    }
    if (span <= 10 * day) {
      return 2 * day;
    }
    if (span <= 40 * day) {
      return 7 * day;
    }
    return 30 * day;
  }

  /** 最晚截止时刻（用于限制平移范围） */
  private latestDue(): number {
    const list: Task[] = this.dueTasks();
    let end: number = 0;
    for (let i = 0; i < list.length; i++) {
      end = Math.max(end, list[i].dueAt as number);
    }
    return end;
  }

  /** 时间窗起点（可被平移到边缘），并夹在数据范围内 */
  private windowStart(): number {
    const minStart: number = this.rangeStart();
    const maxStart: number = Math.max(minStart, this.latestDue() - this.windowMs());
    if (this.windowStartMs <= 0) {
      return minStart;
    }
    return Math.min(Math.max(this.windowStartMs, minStart), maxStart);
  }

  /** 按窗口长度的比例平移（拖到边缘时用） */
  private panBy(ratio: number): void {
    const minStart: number = this.rangeStart();
    const maxStart: number = Math.max(minStart, this.latestDue() - this.windowMs());
    const next: number = this.windowStart() + this.windowMs() * ratio;
    this.windowStartMs = Math.min(Math.max(next, minStart), maxStart);
  }

  /**
   * DDL 文案（2026-10-29 需求方）：
   *  · 今天 / 明天 / 后天 → 只写「今天 / 明天 / 后天」，不再重复日期；
   *  · 其它日期 → 统一 `YYYY.MM.DD`；
   *  · 时间 → 时段前缀（凌晨 / 上午 / 正午 / 下午 / 晚上 / 深夜）+ 12 小时制时间。
   */
  private formatDate(ms: number): string {
    const d: Date = new Date(ms);
    const now: Date = new Date();
    const dayStart: number = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
    const nowStart: number = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const offset: number = Math.round((dayStart - nowStart) / 86400000);
    let datePart: string;
    if (offset === 0) {
      datePart = '今天';
    } else if (offset === 1) {
      datePart = '明天';
    } else if (offset === 2) {
      datePart = '后天';
    } else {
      // 本周内 → 周X；下周 → 下周X；再往后才显示日期
      const nowWeekStart: number = this.weekStartMs(nowStart);
      const dueWeekStart: number = this.weekStartMs(dayStart);
      const weekday: string = this.weekdayLabel(d.getDay());
      if (dueWeekStart === nowWeekStart) {
        datePart = weekday;
      } else if (dueWeekStart === nowWeekStart + 7 * 86400000) {
        datePart = '下' + weekday;
      } else {
        const mo: string = d.getMonth() + 1 < 10 ? '0' + (d.getMonth() + 1) : '' + (d.getMonth() + 1);
        const day: string = d.getDate() < 10 ? '0' + d.getDate() : '' + d.getDate();
        datePart = `${d.getFullYear()}.${mo}.${day}`;
      }
    }
    // DDL 时间跟随系统 12/24 小时制（2026-10-27 需求方：「板板的这些卡片的时间也改成
    // 和用户系统的时间制一样显示」）—— 与标题副标题共用 `clockText`，不各写一份
    return `${datePart} ${TaskListViewModel.clockText(d.getHours(), d.getMinutes())}`;
  }

  /** 本周 / 下周判断用：把某天的 0 点归到所在周（周一）的 0 点 */
  private weekStartMs(dayStart: number): number {
    const d: Date = new Date(dayStart);
    // getDay(): 周日=0；换成「周一=0」的偏移
    const offset: number = (d.getDay() + 6) % 7;
    return dayStart - offset * 86400000;
  }

  /** 0=周日 … 6=周六 → 周日 / 周一 … 周六 */
  private weekdayLabel(index: number): string {
    if (index === 0) {
      return '周日';
    }
    if (index === 1) {
      return '周一';
    }
    if (index === 2) {
      return '周二';
    }
    if (index === 3) {
      return '周三';
    }
    if (index === 4) {
      return '周四';
    }
    if (index === 5) {
      return '周五';
    }
    return '周六';
  }

  /** 刻度文字：小于一天用 HH:mm，否则 M.D */
  private formatTick(ms: number, step: number): string {
    const d: Date = new Date(ms);
    if (step < 86400000) {
      const hh: string = d.getHours() < 10 ? `0${d.getHours()}` : `${d.getHours()}`;
      const mm: string = d.getMinutes() < 10 ? `0${d.getMinutes()}` : `${d.getMinutes()}`;
      return `${hh}:${mm}`;
    }
    return `${d.getMonth() + 1}.${d.getDate()}`;
  }

  /**
   * 表头：时间刻文字 + 金色「现在」下三角。
   * 它在纵向滚动区**外面**，上下滑图表时固定不动。
   */
  drawHeader(): void {
    const ctx: CanvasRenderingContext2D = this.headerCtx;
    const w: number = ctx.width;
    const h: number = ctx.height;
    if (w <= 0 || h <= 0) {
      return;
    }
    ctx.clearRect(0, 0, w, h);
    if (this.dueTasks().length === 0) {
      return;
    }

    const start: number = this.windowStart();
    const end: number = start + this.windowMs();
    const span: number = Math.max(1, end - start);
    const plotX: number = GANTT_LABEL_W_VP - PLOT_SHIFT_VP;
    const plotW: number = Math.max(10, w - plotX - 8);
    const step: number = this.tickStep(span);

    ctx.font = '12vp sans-serif';
    ctx.fillStyle = this.themeStore.scheme.onSurfaceVariant;
    ctx.textAlign = 'center';
    let tick: number = this.firstTickOf(start, step);
    while (tick <= end) {
      const x: number = plotX + ((tick - start) / span) * plotW;
      if (x >= plotX - 1 && x <= w - 8 + 1) {
        ctx.fillText(this.formatTick(tick, step), x, h - 9);
      }
      tick += step;
    }

    // 金色「现在」标记：竖线在被滚动的图表层里，这里只留下三角，指向那条线
    const nowMs: number = Date.now();
    if (nowMs >= start && nowMs <= end) {
      const nx: number = plotX + ((nowMs - start) / span) * plotW;
      ctx.fillStyle = '#FFB300';
      ctx.beginPath();
      ctx.moveTo(nx - 5, h - 5);
      ctx.lineTo(nx + 5, h - 5);
      ctx.lineTo(nx, h + 1);
      ctx.closePath();
      ctx.fill();
    }
  }

  /**
   * 第一个 ≤ start 的刻度点，锚在**固定的绝对时间栅格**上：
   * 日/多日档按天栅格对齐，小时档对齐到当天 00:00 起的整 step。
   * 栅格与窗口起点无关，所以平移时刻度线/辅助线连续滑动，不会跨天时整排跳一格。
   */
  private firstTickOf(start: number, step: number): number {
    const day: number = 86400000;
    if (step >= day) {
      const d: Date = new Date(start);
      d.setHours(0, 0, 0, 0);
      const days: number = Math.max(1, Math.round(step / day));
      // 以 2000-01-01 本地零点为参照，保证跨天时栅格不重新对齐
      const ref: Date = new Date(2000, 0, 1, 0, 0, 0, 0);
      const n: number = Math.round((d.getTime() - ref.getTime()) / day);
      const aligned: number = Math.floor(n / days) * days;
      return ref.getTime() + aligned * day;
    }
    const d: Date = new Date(start);
    d.setHours(0, 0, 0, 0);
    const base: number = d.getTime();
    const n: number = Math.floor((start - base) / step);
    return base + n * step;
  }

  private isImage(uri: string): boolean {
    const lower: string = uri.toLowerCase();
    return lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg')
      || lower.endsWith('.webp') || lower.endsWith('.bmp') || lower.endsWith('.gif');
  }

  private priorityLabel(p: TaskPriority | undefined): string {
    if (p === TaskPriority.URGENT) {
      return '紧急';
    }
    if (p === TaskPriority.IMPORTANT) {
      return '重要';
    }
    return '普通';
  }

  private levelLabel(level: number | undefined): string {
    if (level === 2) {
      return '难';
    }
    if (level === 1) {
      return '中';
    }
    return '易';
  }

  /** 点卡片任意位置 → 进完整详情 */
  private openDetailFor(task: Task): void {
    const stack: NavPathStack | undefined = AppStorage.get<NavPathStack>(NAV_STACK_KEY);
    if (stack === undefined) {
      return;
    }
    stack.pushPathByName(ROUTE_TASK_DETAIL, new TaskDetailParam(task, this.store));
  }

  // ---------------------------------------------------------------- 甘特图

  drawGantt(): void {
    const ctx: CanvasRenderingContext2D = this.canvasCtx;
    const w: number = ctx.width;
    const h: number = ctx.height;
    if (w <= 0 || h <= 0) {
      return;
    }
    ctx.clearRect(0, 0, w, h);
    // 表头与图表共用窗口/步长，统一在这里重画（表头画布未就绪时会自行跳过）
    this.drawHeader();


    const tasks: Task[] = this.dueTasks();
    if (tasks.length === 0) {
      // 空态提示由页面中的居中覆盖层负责，这里不要再画一遍
      return;
    }

    // 时间窗口固定：从「最早添加时刻」起，长度由缩放档位决定（默认 3 天）。
    // 不再按任务跨度自动拉伸 —— 比例固定，只有用户点 +/− 才变。
    const start: number = this.windowStart();
    const end: number = start + this.windowMs();
    const span: number = end - start;

    // 绘图区左移（轨道名仍固定在最左侧）
    const plotX: number = GANTT_LABEL_W_VP - PLOT_SHIFT_VP;
    const plotW: number = Math.max(10, w - plotX - 8);
    // 表头已独立成固定行，这里的坐标系从轨道区顶部开始
    const plotY: number = 0;

    // ① 时间刻度竖线：步长与表头共用（标签画在表头那块画布上）
    const step: number = this.tickStep(span);
    ctx.font = '12vp sans-serif';
    ctx.fillStyle = this.themeStore.scheme.onSurfaceVariant;
    ctx.strokeStyle = this.themeStore.scheme.outlineVariant;
    ctx.lineWidth = 1;
    ctx.textAlign = 'center';
    // 刻度锚在**绝对时间**（本地零点/整点），而不是窗口起点：
    // 这样平移窗口时刻度线与辅助线随窗口连续滑动，不会变成「固定在 0/1/2 格、只有文字跳档」
    let tick: number = this.firstTickOf(start, step);
    while (tick <= end) {
      const x: number = plotX + ((tick - start) / span) * plotW;
      if (x >= plotX - 1 && x <= w - 8 + 1) {
        ctx.beginPath();
        ctx.moveTo(x, plotY);
        ctx.lineTo(x, h);
        ctx.stroke();
      }
      tick += step;
    }

    // ② 轨道 + 甘特条
    const lanes: string[] = this.lanes();
    const laneH: number = LANE_H_VP;
    const pitch: number = LANE_H_VP + LANE_GAP_VP;
    for (let i = 0; i < lanes.length; i++) {
      const y: number = plotY + i * pitch;
      // 轨道名（左对齐，不受绘图区左移影响）
      ctx.textAlign = 'left';
      ctx.fillStyle = this.themeStore.scheme.onSurfaceVariant;
      ctx.font = '12vp sans-serif';
      const label: string = lanes[i].length > 4 ? lanes[i].substring(0, 4) : lanes[i];
      ctx.fillText(label, 2, y + laneH / 2 + 4);
      // 轨道底线
      ctx.strokeStyle = this.themeStore.scheme.outlineVariant;
      ctx.beginPath();
      ctx.moveTo(plotX, y + laneH - 1);
      ctx.lineTo(w - 8, y + laneH - 1);
      ctx.stroke();
    }

    // 事件矩形高度减半，并在轨道内垂直居中（所有轨道共用同一高度）
    const barH: number = Math.max(8, (laneH - 8) / 2);
    const bars: GanttBar[] = [];
    for (let i = 0; i < tasks.length; i++) {
      const t: Task = tasks[i];
      const laneIndex: number = lanes.indexOf(this.laneOf(t));
      const due: number = t.dueAt as number;
      const t0: number = t.createdAt > 0 ? t.createdAt : start;
      // 超出固定窗口的部分裁掉（缩放后还能看全）
      const clamp0: number = Math.max(t0, start);
      const clamp1: number = Math.min(due, end);
      if (clamp1 <= start || clamp0 >= end) {
        continue;
      }
      const x: number = plotX + ((clamp0 - start) / span) * plotW;
      const barW: number = Math.max(6, ((clamp1 - clamp0) / span) * plotW);
      const y: number = plotY + laneIndex * pitch + (laneH - barH) / 2;
      ctx.fillStyle = LANE_COLORS[laneIndex % LANE_COLORS.length];
      // 圆角矩形（不做任何选中态：点事件没有反应）
      this.fillRoundRect(ctx, x, y, barW, barH);
      // 记下这根条的像素范围，稍后画重叠段
      const bar: GanttBar = new GanttBar();
      bar.laneIndex = laneIndex;
      bar.x0 = x;
      bar.x1 = x + barW;
      bars.push(bar);
    }

    // ②-b 同一轨道内**多条任务在时间上重叠**的部分画深色（2026-10-29 需求方）：
    // 只把重叠那一段加深，不是整根条加深，所以逐对求交集后只填交集区间。
    for (let lane = 0; lane < lanes.length; lane++) {
      const base: string = LANE_COLORS[lane % LANE_COLORS.length];
      ctx.fillStyle = this.darkenHex(base, OVERLAP_DARKEN_FACTOR);
      const y: number = plotY + lane * pitch + (laneH - barH) / 2;
      for (let a = 0; a < bars.length; a++) {
        if (bars[a].laneIndex !== lane) {
          continue;
        }
        for (let b = a + 1; b < bars.length; b++) {
          if (bars[b].laneIndex !== lane) {
            continue;
          }
          const ox0: number = Math.max(bars[a].x0, bars[b].x0);
          const ox1: number = Math.min(bars[a].x1, bars[b].x1);
          if (ox1 - ox0 > 0.5) {
            this.fillRoundRect(ctx, ox0, y, ox1 - ox0, barH);
          }
        }
      }
    }

    // ③ 金色「现在」轴：固定不随拖动，只表示当前真实时间
    const nowMs: number = Date.now();
    if (nowMs >= start && nowMs <= end) {
      const nx: number = plotX + ((nowMs - start) / span) * plotW;
      ctx.strokeStyle = '#FFB300';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(nx, plotY);
      ctx.lineTo(nx, h);
      ctx.stroke();
    }

    // ④ 当前时间轴（可拖动）：拖动时上方显示它穿过的事件
    const cursor: number = this.cursorInit
      ? Math.min(Math.max(this.cursorMs, start), end)
      : Math.min(Math.max(Date.now(), start), end);
    if (!this.cursorInit) {
      this.cursorMs = cursor;
      this.cursorInit = true;
    }
    const cx: number = plotX + ((cursor - start) / span) * plotW;
    ctx.strokeStyle = this.themeStore.scheme.primary;
    // 可动轴细一半（原来 2vp，太抢眼）
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(cx, plotY);
    ctx.lineTo(cx, h);
    ctx.stroke();

  }

  /** 轴锁定：上下滚动与左右拖轴二选一，避免斜着同时动 */
  private ganttTouchMode: number = 0;
  private touchStartX: number = 0;
  private touchStartY: number = 0;
  private touchLastY: number = 0;

  private handleGanttTouch(event: TouchEvent): void {
    if (event.touches.length === 0) {
      return;
    }
    const p: TouchObject = event.touches[0];
    if (event.type === TouchType.Down) {
      this.ganttTouchMode = 0;
      this.touchStartX = p.x;
      this.touchStartY = p.y;
      this.touchLastY = p.y;
      return;
    }
    if (event.type === TouchType.Move) {
      if (this.ganttTouchMode === 0) {
        const dx: number = Math.abs(p.x - this.touchStartX);
        const dy: number = Math.abs(p.y - this.touchStartY);
        if (Math.max(dx, dy) < 6) {
          return;
        }
        // 先动哪根轴就锁哪根，全程只走一个方向
        this.ganttTouchMode = dx > dy ? 1 : 2;
        if (this.ganttTouchMode === 1) {
          this.updateCursor(p.x);
        }
      } else if (this.ganttTouchMode === 1) {
        this.updateCursor(p.x);
      } else {
        const dy: number = p.y - this.touchLastY;
        this.touchLastY = p.y;
        this.ganttScroller.scrollBy(0, -dy);
      }
      return;
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      // 轻点：直接把可动轴移到手指位置（不做纵向滚动）
      if (this.ganttTouchMode === 0 && event.type === TouchType.Up) {
        this.updateCursor(p.x);
      }
      this.ganttTouchMode = 0;
    }
  }
  /** 圆角矩形（Canvas 没有 roundRect，手工画路径） */
  private fillRoundRect(ctx: CanvasRenderingContext2D, x: number, y: number,
    w: number, h: number): void {
    const r: number = Math.min(6, w / 2, h / 2);
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.lineTo(x + w - r, y);
    ctx.arcTo(x + w, y, x + w, y + r, r);
    ctx.lineTo(x + w, y + h - r);
    ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
    ctx.lineTo(x + r, y + h);
    ctx.arcTo(x, y + h, x, y + h - r, r);
    ctx.lineTo(x, y + r);
    ctx.arcTo(x, y, x + r, y, r);
    ctx.closePath();
    ctx.fill();
  }

  /** 把 `#RRGGBB` 按系数调暗（用于重叠段的深色） */
  private darkenHex(hex: string, factor: number): string {
    const value: string = hex.startsWith('#') ? hex.substring(1) : hex;
    if (value.length !== 6) {
      return hex;
    }
    const r: number = Math.round(parseInt(value.substring(0, 2), 16) * factor);
    const g: number = Math.round(parseInt(value.substring(2, 4), 16) * factor);
    const b: number = Math.round(parseInt(value.substring(4, 6), 16) * factor);
    return `#${this.hex2(r)}${this.hex2(g)}${this.hex2(b)}`;
  }

  private hex2(value: number): string {
    const clamped: number = Math.max(0, Math.min(255, value));
    const text: string = clamped.toString(16);
    return text.length === 1 ? '0' + text : text;
  }

  /** 拖动时间轴：把手指 x 换算成时间，刷新上方列表 */
  private updateCursor(x: number): void {
    const ctx: CanvasRenderingContext2D = this.canvasCtx;
    const w: number = ctx.width;
    if (w <= 0) {
      return;
    }
    const start: number = this.windowStart();
    const end: number = start + this.windowMs();
    const span: number = Math.max(1, end - start);
    const plotX: number = GANTT_LABEL_W_VP - PLOT_SHIFT_VP;
    const plotW: number = Math.max(10, w - plotX - 8);
    const edge: number = 16;
    if (x < plotX + edge) {
      // 越靠边滚得越快（进入边缘区后按距离线性加速），平移是逐帧的，看起来是连续滑动
      const depth: number = (plotX + edge - x) / edge;
      this.panBy(-0.004 - 0.012 * Math.min(1, depth));
      this.cursorMs = this.windowStart();
    } else if (x > w - 8 - edge) {
      const depth: number = (x - (w - 8 - edge)) / edge;
      this.panBy(0.004 + 0.012 * Math.min(1, depth));
      this.cursorMs = this.windowStart() + this.windowMs();
    } else {
      const rel: number = Math.min(Math.max(x, plotX), w - 8);
      this.cursorMs = start + ((rel - plotX) / plotW) * Math.max(1, end - start);
    }
    this.cursorInit = true;
    this.drawGantt();
  }


  /** 缩放：只有用户点 +/− 才改窗口长度，并重画 */
  private zoomBy(delta: number): void {
    const next: number = Math.min(ZOOM_DAYS.length - 1, Math.max(0, this.zoomIndex + delta));
    if (next === this.zoomIndex) {
      return;
    }
    this.zoomIndex = next;
    // 缩放后把时间轴夹回窗口内，避免详情显示窗口外的事件
    const start: number = this.rangeStart();
    this.cursorMs = Math.min(Math.max(this.cursorMs, start), start + this.windowMs());
    this.drawGantt();
  }

  // ---------------------------------------------------------------- UI

  @Builder
  summaryChip(text: string, tone: string) {
    Text(text)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(tone)
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .backgroundColor(this.themeStore.scheme.surfaceContainerHigh)
      .borderRadius(10)
  }

  /** 类型 tag：底色/文字取该任务所在轨道的甘特条颜色 */
  @Builder
  summaryTypeChip(task: Task) {
    Text(task.category !== undefined ? task.category : '')
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontWeight(FontWeight.Medium)
      .fontColor(this.laneColorOf(task))
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .backgroundColor(this.laneTintOf(task))
      .borderRadius(10)
  }

  @Builder
  summary(task: Task | undefined) {
    if (task !== undefined) {
      this.summaryBody(task)
    }
  }

  @Builder
  summaryBody(task: Task) {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text(task.name)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 已完成任务：标题右侧绿色对钩（2026-10-29 需求方）
        if (task.status === TaskStatus.COMPLETED) {
          SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
            .fontSize(COMPLETED_CHECK_SIZE)
            .fontColor([COMPLETED_CHECK_COLOR])
            .accessibilityText('已完成')
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      // 2026-10-29 需求方：摘要区不再显示「AI 生成」chip（详情页标识条保留）。
      // 类型 tag 放最前，并用甘特条同色，方便和下方图表对照；
      // 后面依次是 重要性 / 难易 / 重复 / 来源 / 附件
      Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(6), cross: LengthMetrics.vp(6) } }) {
        if (task.category !== undefined && task.category.length > 0) {
          this.summaryTypeChip(task)
        }
        this.summaryChip(this.priorityLabel(task.priority), this.themeStore.scheme.primary)
        this.summaryChip('难度 ' + this.levelLabel(task.level), this.themeStore.scheme.primary)
        if (task.repeatText !== undefined && task.repeatText.length > 0) {
          this.summaryChip(task.repeatText, this.themeStore.scheme.primary)
        } else if (task.repeat !== undefined && task.repeat.length > 0) {
          this.summaryChip('重复', this.themeStore.scheme.primary)
        }
        if (task.originDetail !== undefined && task.originDetail.length > 0) {
          this.summaryChip('来自 ' + task.originDetail, this.themeStore.scheme.primary)
        }
        if (task.urls !== undefined && task.urls.length > 0) {
          this.summaryChip('附件 ' + task.urls.length, this.themeStore.scheme.primary)
        }
      }
      .width('100%')

      // ddl：一律用完整日期（dueText 可能只有半句，曾被截成「2026年10月19」）
      Row({ space: 8 }) {
        Text('DDL')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        Text(this.formatDate(task.dueAt as number))
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor(this.themeStore.scheme.primary)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 步骤
      if (task.steps !== undefined && task.steps.length > 0) {
        Column({ space: 6 }) {
          ForEach(task.steps, (step: TaskStep, index: number) => {
            Row({ space: 8 }) {
              Text('' + (index + 1) + '.')
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .width(20)
              Text(step.content)
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .layoutWeight(1)
            }
            .width('100%')
          }, (step: TaskStep) => step.content)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      // 图片（可选）：最多展示 3 张缩略图，预览走完整详情页
      if (task.urls !== undefined && task.urls.length > 0) {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(task.urls, (uri: string) => {
              if (this.isImage(uri)) {
                Image(uri)
                  .width(56)
                  .height(56)
                  .borderRadius(8)
                  .objectFit(ImageFit.Cover)
              }
            }, (uri: string) => uri)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
    .borderRadius(Theme.RADIUS_CARD)
    .alignItems(HorizontalAlign.Start)
    // 出/入场：轻微上下浮动 + 淡入淡出；
    // 硬切复位时用 IDENTITY，重建 ListItem 不会闪一下（2026-10-29）
    .transition(this.suppressEnterTaskId === task.id
      ? TransitionEffect.IDENTITY
      : TransitionEffect.OPACITY
        .combine(TransitionEffect.translate({ y: 16 }))
        .animation({ duration: 220, curve: Curve.EaseOut }))
    // 按压：微微下浮、阴影收一点；松开恢复
    .scale({ x: this.pressedTaskId === task.id ? 0.985 : 1, y: this.pressedTaskId === task.id ? 0.985 : 1 })
    .translate({ y: this.pressedTaskId === task.id ? 2 : 0 })
    .shadow({
      radius: this.pressedTaskId === task.id ? 2 : 8,
      color: '#22000000',
      offsetY: this.pressedTaskId === task.id ? 0 : 3
    })
    .animation({ duration: 120, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedTaskId = task.id;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedTaskId = -1;
      }
    })
    .onClick(() => {
      // 左滑展开时点卡片只收起（避免误进详情页）
      if (this.swipeOpenTaskId === task.id) {
        this.closeSwipeAnimated();
        return;
      }
      this.openDetailFor(task);
    })
  }

  /**
   * 左滑卡片露出的两个操作按钮（2026-10-29 需求方）：
   * 上＝未完成时绿底白对钩 / 已完成时黑底白「撤销」；下＝红底白垃圾桶（确认后删除）。
   * 小按钮与卡片使用同一套「按下下浮」动画。
   */
  @Builder
  taskSwipeActions(task: Task) {
    Column({ space: 8 }) {
      Button({ type: ButtonType.Normal, stateEffect: false }) {
        SymbolGlyph(task.status === TaskStatus.COMPLETED
          ? $r('sys.symbol.undo')
          : $r('sys.symbol.checkmark'))
          .fontSize(20)
          .fontColor([Color.White])
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(task.status === TaskStatus.COMPLETED
        ? SWIPE_UNDO_COLOR
        : COMPLETED_CHECK_COLOR)
      .borderRadius(12)
      // 阴影与大卡片同一套（radius 8 / offsetY 3）
      .shadow({ radius: 8, color: '#22000000', offsetY: 3 })
      .scale({
        x: this.pressedActionKey === this.actionKey(task, 'check') ? 0.93 : 1,
        y: this.pressedActionKey === this.actionKey(task, 'check') ? 0.93 : 1
      })
      .translate({ y: this.pressedActionKey === this.actionKey(task, 'check') ? 1.5 : 0 })
      .animation({ duration: 100, curve: Curve.EaseOut })
      .onTouch((event: TouchEvent) => {
        this.markActionPressed(task, 'check', event);
      })
      .onClick(() => {
        this.completeFromSwipe(task);
      })

      Button({ type: ButtonType.Normal, stateEffect: false }) {
        SymbolGlyph($r('sys.symbol.trash'))
          .fontSize(20)
          .fontColor([Color.White])
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(SWIPE_DELETE_COLOR)
      .borderRadius(12)
      // 阴影与大卡片同一套（radius 8 / offsetY 3）
      .shadow({ radius: 8, color: '#22000000', offsetY: 3 })
      .scale({
        x: this.pressedActionKey === this.actionKey(task, 'trash') ? 0.93 : 1,
        y: this.pressedActionKey === this.actionKey(task, 'trash') ? 0.93 : 1
      })
      .translate({ y: this.pressedActionKey === this.actionKey(task, 'trash') ? 1.5 : 0 })
      .animation({ duration: 100, curve: Curve.EaseOut })
      .onTouch((event: TouchEvent) => {
        this.markActionPressed(task, 'trash', event);
      })
      .onClick(() => {
        this.confirmDeleteFromSwipe(task);
      })
    }
    .width(SWIPE_REVEAL_VP)
    // 原生 swipeAction 会把这里按 ListItem 的高度测量，所以 100% 是卡片高度（不会变成视口高度）
    .height('100%')
    .padding({ left: SWIPE_ACTION_PADDING_VP })
  }

  private actionKey(task: Task, kind: string): string {
    return task.id + '-' + kind;
  }

  /** 小按钮的按下/松开（只记录状态，点击本身仍由 onClick 触发） */
  private markActionPressed(task: Task, kind: string, event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.pressedActionKey = this.actionKey(task, kind);
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.pressedActionKey = '';
    }
  }

  /** 带收起动画地复位（卡片位置不变时使用） */
  private closeSwipeAnimated(): void {
    try {
      this.summaryScroller.closeAllSwipeActions();
    } catch (error) {
      // 没有展开项 / 控制器未绑定：忽略
    }
    this.swipeOpenTaskId = -1;
  }

  /**
   * 硬切复位（卡片会换位置时使用）：给该任务的 ListItem 换 key，
   * 节点重建后左滑状态直接归零，不播放收起动画；同时临时禁用出入场 transition。
   */
  private hardCutSwipe(taskId: number): void {
    this.swipeOpenTaskId = -1;
    this.suppressEnterTaskId = taskId;
    const key: string = String(taskId);
    const token: number | undefined = this.swipeTokens[key];
    this.swipeTokens[key] = token === undefined ? 1 : token + 1;
    // 重建完成后清掉标记，避免影响这张卡之后的正常入场动画
    setTimeout(() => {
      if (this.suppressEnterTaskId === taskId) {
        this.suppressEnterTaskId = -1;
      }
    }, 120);
  }

  /** 模拟「切换完成状态」后该任务在摘要列表里的下标（排序口径与 detailTasks 一致） */
  private detailIndexOf(taskId: number, assumeCompleted: boolean): number {
    const list: Task[] = this.detailTasks().slice();
    const lanes: string[] = this.lanes();
    list.sort((a: Task, b: Task) => {
      const ac: number = (a.id === taskId ? assumeCompleted : a.status === TaskStatus.COMPLETED) ? 1 : 0;
      const bc: number = (b.id === taskId ? assumeCompleted : b.status === TaskStatus.COMPLETED) ? 1 : 0;
      if (ac !== bc) {
        return ac - bc;
      }
      const ia: number = lanes.indexOf(this.laneOf(a));
      const ib: number = lanes.indexOf(this.laneOf(b));
      if (ia !== ib) {
        return ia - ib;
      }
      return (a.dueAt as number) - (b.dueAt as number);
    });
    return list.findIndex((t: Task) => t.id === taskId);
  }

  /** 切换完成状态后卡片是否换位置：换位置 → 硬切；位置不变 → 播收起动画 */
  private willChangePosition(task: Task): boolean {
    const currentIndex: number = this.detailTasks().findIndex((t: Task) => t.id === task.id);
    if (currentIndex < 0) {
      return false;
    }
    const willComplete: boolean = task.status !== TaskStatus.COMPLETED;
    return this.detailIndexOf(task.id, willComplete) !== currentIndex;
  }

  /** 左滑动作：完成 ↔ 撤销（已完成的任务显示撤销图标） */
  private completeFromSwipe(task: Task): void {
    if (this.willChangePosition(task)) {
      this.hardCutSwipe(task.id);
    } else {
      this.closeSwipeAnimated();
    }
    this.store.toggleComplete(task);
  }

  /** 左滑删除：先收起左滑，再弹官方确认弹窗，确认后软删除（进回收站） */
  private confirmDeleteFromSwipe(task: Task): void {
    this.closeSwipeAnimated();
    showDeleteConfirmDialog(this.getUIContext(), '删除任务',
      '确定要删除这个任务吗？删除后可在回收站恢复。', () => {
        this.store.deleteTask(task.id);
      });
  }

  build() {
    // 空态提示要落在**整屏正中间**，所以最外层用 Stack：内容铺满，提示作为居中覆盖层
    Stack({ alignContent: Alignment.Center }) {
      // 内容 + 底部遮罩单独一层：遮罩只占底部 140vp，不再用整屏覆盖层挡手势。
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          // 副标题（旧版是 HDS 标题栏的 subTitle，为了让主标题与另两页同高，改成标题下方的一行）
          // 2026-10-27 第二轮：「减小一下这个间距，再把副标题字号大一号」——
          //  · 字号 caption(12) → body(14)；
          //  · 标题栏自己会在标题下方留一截（实测标题框底 → 副标题框顶 73px ≈ 21vp），
          //    用负 margin 收 10vp，实际间距 ≈ 11vp（与详情页「标题→正文」的节奏一致）。
          Text(this.nowLabel)
            .fontSize(Theme.FONT_BODY)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .textAlign(TextAlign.Start)
            .padding({ left: 16, right: 16, bottom: 4 })
            .margin({ top: -SUBTITLE_PULL_UP_VP })

          // ── 上 70%：简要详情 ──
        Column() {
          if (this.dueTasks().length === 0) {
            // 空态提示统一由下面的覆盖层负责
            Column()
          } else {
          // 用 List + ListItem 承接卡片：只有 ListItem 才有 `.swipeAction()`，
          // 左滑露出的操作按钮才能跟着卡片一起走（2026-10-29 需求方）。
          List({ scroller: this.summaryScroller, space: 12 }) {
            // 时间轴穿过几条甘特条，这里就显示几条事件
            if (this.detailTasks().length === 0) {
              ListItem() {
                Text('时间轴没有经过任何事件（拖动下方蓝线试试）')
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .padding({ top: 24 })
              }
            } else {
              ForEach(this.detailTasks(), (t: Task) => {
                ListItem() {
                  this.summary(t)
                }
                // 原生 swipeAction：按钮高度/层级/卡片阴影都由框架处理。
                // `SwipeEdgeEffect.None` = 到边界立即停住：
                //  · 未定义 start → 向右没有内容，且不会再有回弹位移；
                //  · 向左最多展开到按钮宽度，不能继续过度左滑。
                .swipeAction({
                  end: {
                    builder: () => {
                      this.taskSwipeActions(t);
                    },
                    onStateChange: (state: SwipeActionState) => {
                      if (state === SwipeActionState.EXPANDED) {
                        this.swipeOpenTaskId = t.id;
                      } else if (this.swipeOpenTaskId === t.id) {
                        this.swipeOpenTaskId = -1;
                      }
                    }
                  },
                  edgeEffect: SwipeEdgeEffect.None
                })
              }, (t: Task) => t.id + '-' + (this.swipeTokens[String(t.id)] ?? 0))
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 12 })
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          // 让上面的内容撑满 70%（否则列表按内容高度收缩，下面会空出一大块）
          .layoutWeight(1)
        }
      }
      .layoutWeight(1)
      .width('100%')

      // ── 底部：甘特图（没有 ddl 时整块不显示）──
      // 背景板高度跟内容走（不是固定 35%），始终贴着底部；轨道过多时内部滚动
      if (this.dueTasks().length > 0) {
        Column() {
          // 表头区：顶部拉条（按住上下拖可加高/压低表头）+ 时间刻 + 缩放键
          Column() {
            Row() {
              Column()
                .width(40)
                .height(4)
                .borderRadius(2)
                .backgroundColor(this.headerDragging
                  ? this.themeStore.scheme.outline
                  : this.themeStore.scheme.outlineVariant)
            }
            .width('100%')
            .height(GANTT_STRIP_VP)
            .justifyContent(FlexAlign.Center)
            .onTouch((event: TouchEvent) => {
              this.handleStripTouch(event);
            })

            // 收起到只剩触发行时，时间刻度与缩放键一起隐藏
            if (!this.ganttCollapsed()) {
            Stack({ alignContent: Alignment.TopEnd }) {
            Canvas(this.headerCtx)
              .width('100%')
              .height(GANTT_AXIS_H_VP)
              .onReady(() => {
                this.drawHeader();
              })
              .onAreaChange(() => {
                this.drawHeader();
              })

            // 缩放键：− / ＋ 合进一个胶囊容器，点按钮才改时间比例
            Row() {
              Button({ type: ButtonType.Circle, stateEffect: true }) {
                Text('−')
                  .fontSize(14)
                  .fontColor(this.themeStore.scheme.onPrimary)
              }
              .width(24)
              .height(24)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.zoomBy(-1);
              })

              Column()
                .width(1)
                .height(11)
                .backgroundColor(this.themeStore.scheme.onPrimary)
                .opacity(0.35)

              Button({ type: ButtonType.Circle, stateEffect: true }) {
                Text('＋')
                  .fontSize(12)
                  .fontColor(this.themeStore.scheme.onPrimary)
              }
              .width(24)
              .height(24)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.zoomBy(1);
              })
            }
            .padding({ left: 2, right: 2 })
            .backgroundColor(this.themeStore.scheme.primary)
            .borderRadius(14)
            .margin({ right: 10, top: 2 })
          }
          .width('100%')
          .height(GANTT_AXIS_H_VP)
          }
          }
          .width('100%')

          // 轨道区：表头固定，这一层内部纵向滚动（手势自己接管，见 handleGanttTouch）
          if (!this.ganttCollapsed()) {
          Scroll(this.ganttScroller) {
            Canvas(this.canvasCtx)
              .width('100%')
              .height(this.ganttLanesHeight())
              .onReady(() => {
                this.drawGantt();
              })
              .onAreaChange(() => {
                this.drawGantt();
              })
              .onTouch((event: TouchEvent) => {
                this.handleGanttTouch(event);
              })
          }
          .scrollable(ScrollDirection.Vertical)
          // 关掉系统滚动：避免横拖时表格也跟着斜着走
          .enableScrollInteraction(false)
          .scrollBar(BarState.Off)
          .width('100%')
          .layoutWeight(1)
          }
        }
        .width('100%')
        .height(this.ganttPanelHeight())
        // 底部多留出悬浮导航的 112vp，但背景仍然铺到屏幕底；上半部分图表位置不变
        .padding({ left: 12, right: 12, top: 8, bottom: 8 + BOTTOM_NAV_CLEARANCE_VP })
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderRadius({ topLeft: Theme.RADIUS_CARD, topRight: Theme.RADIUS_CARD })
        // 默认留一点点上浮阴影；拖动时明显加深，强调面板被拉起
        .shadow({
          radius: this.headerDragging ? 18 : 6,
          color: this.headerDragging ? '#55000000' : '#14000000',
          offsetY: this.headerDragging ? -6 : -1
        })
      }
      }
        .width('100%')
        .height('100%')
        // 底部悬浮导航的让位改到甘特面板内部（见 ganttPanelHeight），
        // 这样甘特背景能一直铺到屏幕底，而图表本身的位置保持不变。
        .padding({ top: this.statusBarVp + 64 })
        .backgroundColor(this.themeStore.scheme.surface)
        // 2026-10-25：本页自绘的标题行（「板板」+ 右侧可动轴时间）**已删除** ——
        // 标题栏改由 `A_Main` 的 HDS 标题栏统一画，与设置页同一个组件、同一套样式。
        // 原来那行是 `.position({ y: statusBarVp + 4 })` 的浮层，字号 28 / 左右 20vp 都是手写的，
        // 与 HDS 的 MINI 标题栏对不齐，这正是作者说的「和设置页面的不一样」。
        // 内容顶部让白保留 `statusBarVp + 64`（与 `A_Settings` 的 `TITLE_CLEARANCE_VP + statusBarVp` 同档）。

        // 底部渐变遮罩：只占底部 140vp，且不参与命中测试，不能挡住甘特拖动
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

      // 空态（2026-10-25，作者：「板板页面无任务的时候，也像任务列表页面一样显示一个图标再加文字」）：
      // **复用 `EmptyHint`** —— 任务列表的空态和搜索页的两种空态用的就是它（图示 + 一句灰字），
      // 三个页面的空态从此是同一个组件、同一套观感（组件化约定：长得像的块必须复用同一个组件）。
      // 它自己 `width/height 100%` + 居中，所以放在这个 `Stack` 里就是**整屏正中**，
      // 原来那句裸 `Text` 的 `padding({left/right: 32})` 也就不需要了。
      if (this.dueTasks().length === 0) {
        EmptyHint({ message: $r('app.string.empty_banban') })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeStore.scheme.surface)
  }
}
