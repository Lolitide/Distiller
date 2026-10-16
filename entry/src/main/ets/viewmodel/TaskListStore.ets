/*
 * 任务列表页的「数据 ＋ 编辑态」store。
 *
 * 为什么要单独一个 store（而不是把状态挂在页面上）：
 * 编辑态要**同时**被三处读到 —— 导航栏右上角（编辑↔取消/全选）、底部悬浮栏（添加↔删除）、
 * 以及列表里的每张卡片（圆圈↔方框勾选框）。数据（分组）又必须留在列表这一侧。
 * 所以按 V2 的官方姿势做成 **`@ObservedV2` 对象 + `@Trace` 字段**，由 `A_Main` `new` 一个实例
 * （⚠️ 官方 FAQ：`@ObservedV2` 的类**必须 `new` 出来**才可观测，对象字面量不行）按引用传给
 * `MainTabBar` / `A_TaskList` / `TaskCard`。谁改了里面的 `@Trace` 字段，读到它的组件都会刷新。
 *
 * 字段与动作的边界：
 *   · `groups`  —— 分组数据（分组规则在 `TaskListViewModel.groupByDay`），删除会改它
 *   · `editing` —— 是否处于编辑（多选）模式
 *   · `selectedIds` —— 已勾选的任务 id（用**整体换新数组**的方式改，观测最稳）
 * 只做内存里的增删；真落库要走 `repository/`（见 `deleteSelected` 的 TODO）。
 */
import { Task, TaskPriority, TaskStatus } from '../model';
import { MOCK_TASKS } from '../mock/MockTasks';
import { TaskDayGroup, TaskListViewModel } from './TaskListViewModel';

/** 固定筛选项的键（与文案分开：以后"设置里让用户选固定哪几个"就是让用户勾这几个 key） */
export const FILTER_ALL: string = 'all';
export const FILTER_DONE: string = 'done';
export const FILTER_TODO: string = 'todo';
export const FILTER_URGENT: string = 'urgent';
/** 标签项的键前缀（键 = 前缀 + 标签原文） */
export const FILTER_TAG_PREFIX: string = 'tag:';

/** 一个筛选项（Chip）：`key` 给逻辑用、`label` 给显示用（标签项是用户数据，label 是纯字符串） */
export class TaskFilterChip {
  key: string = '';
  label: ResourceStr = '';

  constructor(key: string, label: ResourceStr) {
    this.key = key;
    this.label = label;
  }
}

/** 某个标签被点选的次数（`chips` 排序用；`clicks` 用数组整体替换的方式更新，保证可观测） */
export class TagUsage {
  tag: string = '';
  clicks: number = 0;
}

/**
 * 固定项：**顺序即优先级，永远排在标签项前面**（袁正锟 2026-10-16）。
 * 「全部」是官方 ChipGroup 的必需品 —— 它的 `selectedIndexes` 默认 `[0]` 且单选模式下**总会有一个被选中**，
 * 没有「全部」就没法回到不过滤的状态。
 * TODO(袁正锟): 以后把「固定哪几个」开放到设置里 —— 就是让用户从这个数组里勾选子集。
 */
const FIXED_CHIPS: TaskFilterChip[] = [
  new TaskFilterChip(FILTER_ALL, $r('app.string.filter_all')),
  new TaskFilterChip(FILTER_DONE, $r('app.string.filter_done')),
  new TaskFilterChip(FILTER_TODO, $r('app.string.filter_todo')),
  new TaskFilterChip(FILTER_URGENT, $r('app.string.filter_urgent'))
];

@ObservedV2
export class TaskListStore {
  /** 按天分好组的任务 */
  @Trace groups: TaskDayGroup[] = TaskListViewModel.groupByDay(MOCK_TASKS, new Date());
  /** 是否处于编辑（多选）模式 */
  @Trace editing: boolean = false;
  /** 已勾选的任务 id */
  @Trace selectedIds: number[] = [];
  /** 当前生效的筛选键（默认「全部」） */
  @Trace activeFilter: string = FILTER_ALL;
  /** 标签项的点选次数（用于「按点击次数自动排序」） */
  @Trace tagUsages: TagUsage[] = [];

  /** 勾选条数 */
  get selectedCount(): number {
    return this.selectedIds.length;
  }

  /** 有勾选才允许删除（底部删除按钮的灰/亮看它） */
  get canDelete(): boolean {
    return this.selectedIds.length > 0;
  }

  /** 当前列表里全部任务的数量（「全选」是否已经全勾上，看它） */
  get totalCount(): number {
    let total: number = 0;
    this.groups.forEach((group: TaskDayGroup) => {
      total += group.tasks.length;
    });
    return total;
  }

  /** 把分组摊平成一份任务列表（搜索页要从这里按关键词过滤） */
  allTasks(): Task[] {
    const tasks: Task[] = [];
    this.groups.forEach((group: TaskDayGroup) => {
      group.tasks.forEach((task: Task) => tasks.push(task));
    });
    return tasks;
  }

  /** 当前筛选下还剩多少任务（空状态、组头副标题都看它） */
  get visibleCount(): number {
    let total: number = 0;
    this.groups.forEach((group: TaskDayGroup) => {
      total += this.visibleTasks(group).length;
    });
    return total;
  }

  /**
   * 当前**有效**的筛选键。
   *
   * 🔴 为什么不能直接用 `activeFilter`（袁正锟 2026-10-16 报的 bug）：
   * 标签芯片是**跟着任务一起长出来的** —— 某个标签的任务被全删光之后，那个芯片就从 `chips` 里消失了，
   * 界面于是回到「全部」（`selectedIndexes` 找不到就退第 0 个），但 `activeFilter` 还指着那个**已经不存在的标签**，
   * 列表继续按老条件筛 → 出现「芯片显示全部、列表却说『没有符合条件的任务』」的自相矛盾。
   * 所以读筛选条件的地方一律走这个 getter：**芯片没了就等于没在筛**。
   */
  get effectiveFilter(): string {
    const key: string = this.activeFilter;
    if (key === FILTER_ALL) {
      return FILTER_ALL;
    }
    const list: TaskFilterChip[] = this.chips;
    for (let i = 0; i < list.length; i++) {
      if (list[i].key === key) {
        return key;
      }
    }
    return FILTER_ALL;
  }

  /** 现在是不是「有筛选条件但一条都没匹配上」（此时空状态的文案要换一句） */
  get filteredEmpty(): boolean {
    return this.effectiveFilter !== FILTER_ALL && this.visibleCount === 0;
  }

  /** 当前任务里出现过的标签（去重，不限顺序 —— 顺序由 `chips` 排） */
  get allTags(): string[] {
    const tags: string[] = [];
    this.groups.forEach((group: TaskDayGroup) => {
      group.tasks.forEach((task: Task) => {
        const own: string[] | undefined = task.tags;
        if (own === undefined) {
          return;
        }
        own.forEach((tag: string) => {
          if (tags.indexOf(tag) < 0) {
            tags.push(tag);
          }
        });
      });
    });
    return tags;
  }

  /**
   * 页面顶部那一排 Chip：**固定项在前（顺序固定）**，之后是标签项。
   * 标签项按「**点选次数降序 → 字典序**」排（袁正锟 2026-10-16：「可以根据用户的点击次数自动排序
   * 但是固定项的优先级最高 最开始用固定项+字典序吧」）—— 一开始次数都是 0，所以现在就是字典序。
   */
  get chips(): TaskFilterChip[] {
    const list: TaskFilterChip[] = [];
    FIXED_CHIPS.forEach((chip: TaskFilterChip) => {
      list.push(chip);
    });
    const tags: string[] = this.allTags;
    tags.sort((a: string, b: string) => {
      const clicksA: number = this.tagClicks(a);
      const clicksB: number = this.tagClicks(b);
      if (clicksA !== clicksB) {
        return clicksB - clicksA;
      }
      // 字典序（按码点比较，稳定可预期）
      if (a < b) {
        return -1;
      }
      return a > b ? 1 : 0;
    });
    tags.forEach((tag: string) => {
      list.push(new TaskFilterChip(`${FILTER_TAG_PREFIX}${tag}`, tag));
    });
    return list;
  }

  /** 某个标签被点选过几次 */
  tagClicks(tag: string): number {
    for (let i = 0; i < this.tagUsages.length; i++) {
      if (this.tagUsages[i].tag === tag) {
        return this.tagUsages[i].clicks;
      }
    }
    return 0;
  }

  /**
   * 按 Chip 的 key 过滤：
   * · `all` 不过滤；`done` 已完成；`todo` 未完成；`urgent` 紧急（`TaskPriority.URGENT`）；
   * · `tag:xxx` 任务身上的标签里有 xxx。
   */
  matchesFilter(task: Task): boolean {
    const key: string = this.effectiveFilter;
    if (key === FILTER_ALL) {
      return true;
    }
    if (key === FILTER_DONE) {
      return task.status === TaskStatus.COMPLETED;
    }
    if (key === FILTER_TODO) {
      return task.status !== TaskStatus.COMPLETED;
    }
    if (key === FILTER_URGENT) {
      return task.priority === TaskPriority.URGENT;
    }
    if (key.startsWith(FILTER_TAG_PREFIX)) {
      const tag: string = key.substring(FILTER_TAG_PREFIX.length);
      const own: string[] | undefined = task.tags;
      return own !== undefined && own.indexOf(tag) >= 0;
    }
    return true;
  }

  /** 某组里**当前筛选下可见**的任务（页面只渲染这个） */
  visibleTasks(group: TaskDayGroup): Task[] {
    return group.tasks.filter((task: Task) => this.matchesFilter(task));
  }

  /** 某组里当前筛选下可见、且未完成的条数（组头副标题的左半边） */
  visiblePendingCount(group: TaskDayGroup): number {
    let pending: number = 0;
    this.visibleTasks(group).forEach((task: Task) => {
      if (task.status !== TaskStatus.COMPLETED) {
        pending++;
      }
    });
    return pending;
  }

  /** 切筛选：顺便给标签项记一次点选次数（用于自动排序） */
  applyFilter(key: string): void {
    this.activeFilter = key;
    if (!key.startsWith(FILTER_TAG_PREFIX)) {
      return;
    }
    const tag: string = key.substring(FILTER_TAG_PREFIX.length);
    const next: TagUsage[] = [];
    let found: boolean = false;
    this.tagUsages.forEach((usage: TagUsage) => {
      if (usage.tag === tag) {
        const bumped: TagUsage = new TagUsage();
        bumped.tag = tag;
        bumped.clicks = usage.clicks + 1;
        next.push(bumped);
        found = true;
        return;
      }
      next.push(usage);
    });
    if (!found) {
      const created: TagUsage = new TagUsage();
      created.tag = tag;
      created.clicks = 1;
      next.push(created);
    }
    this.tagUsages = next;
  }

  isSelected(id: number): boolean {
    return this.selectedIds.indexOf(id) >= 0;
  }

  /**
   * 记「完成前是什么状态」，供再点一次圆圈时回退（袁正锟 2026-10-14：再点恢复未完成状态）。
   *
   * 放在 store（而不是页面）：**列表页和搜索页都要这套行为** —— 搜索页复用同一个 `TaskCard`
   * （袁正锟 2026-10-16：「把 List 页的那些 ListGroup、Card 直接弄过来复用」），
   * 行为也应当一套。它是 UI 的撤销记忆、`Task` 契约里没有这个字段，所以只活在内存里。
   */
  private statusBeforeCompleted: Map<number, TaskStatus> = new Map();

  /** 点圆圈：未完成 → 完成（同时关掉响铃提醒）；已完成 → 退回完成前的状态，并把响铃提醒重新打开 */
  toggleComplete(task: Task): void {
    if (task.status === TaskStatus.COMPLETED) {
      const previous: TaskStatus | undefined = this.statusBeforeCompleted.get(task.id);
      task.status = previous === undefined ? TaskStatus.CONFIRMED : previous;
      this.statusBeforeCompleted.delete(task.id);
      // 退回未完成时把响铃提醒重新打开（袁正锟 2026-10-14）。
      // 有提醒时间的任务才有开关，所以只在这种情况置值；置 -1 是占位的假提醒键，
      // TODO(袁正锟): 真接 ReminderService 后要改成「发布提醒」并拿服务返回的键。
      if (task.remindAt !== undefined) {
        task.reminderId = -1;
      }
      return;
    }
    this.statusBeforeCompleted.set(task.id, task.status);
    task.status = TaskStatus.COMPLETED;
    // 完成时自动关掉响铃提醒：开关由 reminderId 派生，清空即关
    task.reminderId = undefined;
  }

  /**
   * 拨「响铃提醒」开关。开关状态由 `reminderId` 派生，所以这里就是给它置值 / 清空。
   * TODO(袁正锟): 真接 `service/system/ReminderService` 后，这里要改成调用「发布提醒 / 撤销提醒」，
   * `reminderId` 由服务返回，不许再在页面里凭空造。
   */
  setRemind(task: Task, isOn: boolean): void {
    task.reminderId = isOn ? -1 : undefined;
  }

  /** 进入编辑（多选）模式：每次进来都从「一条没勾」开始 */
  enterEdit(): void {
    this.selectedIds = [];
    this.editing = true;
  }

  /** 退出编辑模式（右上角「取消」） */
  exitEdit(): void {
    this.editing = false;
    this.selectedIds = [];
  }

  /** 勾上 / 取消勾选一条 */
  toggleSelect(id: number): void {
    if (this.isSelected(id)) {
      this.selectedIds = this.selectedIds.filter((each: number) => each !== id);
      return;
    }
    const next: number[] = this.selectedIds.slice();
    next.push(id);
    this.selectedIds = next;
  }

  /**
   * 当前**筛选下可见**（能匹配上的）任务 id。
   * 「全选」的范围就是它 —— 也就是说在某个 Chip 下点全选，只勾这一条筛选下的任务。
   */
  visibleTaskIds(): number[] {
    const ids: number[] = [];
    this.groups.forEach((group: TaskDayGroup) => {
      group.tasks.forEach((task: Task) => {
        if (this.matchesFilter(task)) {
          ids.push(task.id);
        }
      });
    });
    return ids;
  }

  /**
   * 全选：**只勾当前筛选下的任务**（袁正锟 2026-10-16：「在某一个 Chip 下 编辑全选删除后是删除全部
   * 而不是删除这个 Chip 下的全部任务」—— 原来这里把 `groups` 里**所有**任务都勾上了，没看筛选）。
   *
   * ⚠️ 注意范围是「匹配当前筛选的全部任务」，**含折叠分组里的**：折叠只是显示状态，用户选的筛选才是范围。
   */
  selectAll(): void {
    this.selectedIds = this.visibleTaskIds();
  }

  /**
   * 删除已勾选的任务：从各组里摘掉，**空的组直接丢掉**（组头副标题的计数由 `TaskDayGroup` 的 getter 自动跟着变），
   * **并自动退出编辑模式**（袁正锟 2026-10-16），返回删掉的条数。
   *
   * TODO(袁正锟): 真删要走 `repository/` 落库（现在只动内存里的 Mock 数据，重启即还原）；
   * 另外「删除要不要二次确认」未定 —— 现在点了立刻删。
   */
  deleteSelected(): number {
    const ids: number[] = this.selectedIds;
    if (ids.length === 0) {
      return 0;
    }
    const kept: TaskDayGroup[] = [];
    this.groups.forEach((group: TaskDayGroup) => {
      const remain: Task[] = group.tasks.filter((task: Task) => ids.indexOf(task.id) < 0);
      group.tasks = remain;
      if (remain.length > 0) {
        kept.push(group);
      }
    });
    this.groups = kept;
    // 删掉的如果是**最后一个带某标签的任务**，那个标签芯片会跟着消失 → 把筛选键也收回「全部」，
    // 免得界面回到「全部」、列表却还按那个不存在的标签筛（见 `effectiveFilter` 的说明）。
    // 这里顺手把状态写正，`effectiveFilter` 只是兜底。
    if (this.effectiveFilter === FILTER_ALL) {
      this.activeFilter = FILTER_ALL;
    }
    // 删完**自动退出编辑模式**（袁正锟 2026-10-16：「删除完成后自动退出编辑状态」）：
    // 这样右上角直接回到「编辑/搜索」、底部直接回到「＋」，不用用户再点一次「取消」。
    this.exitEdit();
    return ids.length;
  }
}
