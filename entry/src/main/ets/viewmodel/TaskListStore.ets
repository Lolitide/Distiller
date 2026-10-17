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
import { Task, TaskAlarm, TaskPriority, TaskStatus } from '../model';
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

  /**
   * 重新分组 —— 任务的**日期类字段**变了（典型：详情页清掉到期时间）必须调它，
   * 否则 `groups` 还是创建时算好的那份，任务会赖在原来那天、不会掉进「未安排日期」。
   *
   * 🔴 为什么必须「**就地更新**」而不能整体换一批新对象（袁正锟 2026-10-16 报的
   * 「清掉到期时间后任务直接消失、没归入未安排日期」的真因）：
   *
   * 列表是用 `ForEach(this.store.groups, ..., (group) => `${group.sortValue}-${group.hasDate}`)`
   * 渲染的，而官方《ForEach：循环渲染》写明：「系统会为每个数组元素生成一个唯一且持久的键值……
   * **当键值变化时**，ArkUI 框架会视为该数组元素已被替换或修改，并会基于新的键值创建一个新的组件」
   * —— 反过来说，**键值不变的项不会重建**，它的内容还是按**旧的那个组对象**读出来的。
   * （FAQ `faqs-arkui-41` 也是同一句：「ForEach 会捕捉到 key 的变化，从而通过重建组件节点来刷新」。）
   *
   * 于是上一版「整批 new 一遍再赋给 groups」的写法会同时出两个错：
   *  ① 任务原来那天**空了** → 那一组从数组里消失 → 键值没了 → 旧节点被销毁；
   *  ② 「未安排日期」这一组的键值（`0-false`）**没变** → 节点被复用，而它闭包里抓的还是**旧组对象**
   *     （旧的 `tasks`、旧的 `expanded`）→ 新任务读不到。
   * 两头一夹，任务在界面上就哪儿都不在了。
   *
   * 修法：**同一个「那一天」沿用同一个组对象**，只改它的 `@Trace` 字段（`tasks` / `expanded`），
   * 让已经建好的节点按 V2 的常规路径刷新；只有**真的新增的那一天**才用新对象（新键 → 新节点）。
   * 附带好处：各组的展开/收起状态天然保留，不用再像上一版那样建 map 搬来搬去。
   */
  refreshGroups(expandTaskId?: number): void {
    const rebuilt: TaskDayGroup[] = TaskListViewModel.groupByDay(this.allTasks(), new Date());
    const merged: TaskDayGroup[] = [];
    rebuilt.forEach((fresh: TaskDayGroup) => {
      const kept: TaskDayGroup | undefined = this.findGroup(fresh.sortValue, fresh.hasDate);
      if (kept === undefined) {
        // 全新的一天：键值变了，ForEach 会新建节点，直接用新算出来的这份
        this.expandIfContains(fresh, expandTaskId);
        merged.push(fresh);
        return;
      }
      // 同一天：**复用旧对象**（对象身份不能变，见上面的注释），只换可观测的字段
      kept.tasks = fresh.tasks;
      this.expandIfContains(kept, expandTaskId);
      merged.push(kept);
    });
    this.groups = merged;
  }

  /** 找「那一天」现在已经存在的组对象（判据与 `groupByDay` 的分组口径一致：日期键 + 有无日期） */
  private findGroup(sortValue: number, hasDate: boolean): TaskDayGroup | undefined {
    const current: TaskDayGroup[] = this.groups;
    for (let i = 0; i < current.length; i++) {
      if (current[i].hasDate === hasDate && current[i].sortValue === sortValue) {
        return current[i];
      }
    }
    return undefined;
  }

  /**
   * 指定的任务落进这一组时把这一组**展开** —— 否则它一换组就躲进收起的组里，
   * 看起来像任务被删掉了（袁正锟 2026-10-16：「清掉后发现这条任务直接没了」）。
   */
  private expandIfContains(group: TaskDayGroup, taskId?: number): void {
    if (taskId === undefined) {
      return;
    }
    const contains: boolean = group.tasks.some((task: Task) => task.id === taskId);
    if (contains) {
      group.expanded = true;
    }
  }

  /**
   * 删除**单条**任务（详情页右上角的删除按钮）。
   *
   * 与列表的多选删除不同，这里走**契约里的软删**：把 `status` 置成 `DELETED`。
   * `groupByDay` 本来就会过滤 `TaskStatus.DELETED`（§9.3「已删除任务不进时间线」），
   * 所以只要 `refreshGroups` 一次，列表里就立刻看不到它 —— 不需要动数组元素。
   *
   * 顺手把提醒收掉：`alarm` 置 OFF、`reminderId` 清空（已发布的本地提醒句柄跟着作废；
   * 真接 `ReminderService` 后这里要先撤销提醒再软删）。
   */
  deleteTask(taskId: number): boolean {
    const found: Task | undefined = this.findTask(taskId);
    if (found === undefined) {
      return false;
    }
    found.status = TaskStatus.DELETED;
    found.alarm = TaskAlarm.OFF;
    found.reminderId = undefined;
    this.refreshGroups();
    return true;
  }

  /** 按 id 在现有分组里找任务 */
  private findTask(taskId: number): Task | undefined {
    const all: Task[] = this.allTasks();
    for (let i = 0; i < all.length; i++) {
      if (all[i].id === taskId) {
        return all[i];
      }
    }
    return undefined;
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

  /**
   * 点圆圈：未完成 → 完成；已完成 → 退回完成前的状态。
   *
   * v1 契约（字段表 §1）带来的两处变化：
   *  · 完成时要写 **`finishedAt`**（第 13 项：「完成态卡片显示的就是它」），退回时清空；
   *  · 「响铃提醒」的**用户意图**是 `alarm`（第 16 项），所以完成时把 `alarm` 置 OFF、退回时按
   *    「有提醒时间才开」恢复成 ON；`reminderId`（已发布句柄）跟着清空 —— 它由 `ReminderService` 给，
   *    页面里不许凭空造。
   */
  toggleComplete(task: Task): void {
    if (task.status === TaskStatus.COMPLETED) {
      const previous: TaskStatus | undefined = this.statusBeforeCompleted.get(task.id);
      task.status = previous === undefined ? TaskStatus.CONFIRMED : previous;
      task.finishedAt = undefined;
      this.statusBeforeCompleted.delete(task.id);
      // 退回未完成时把响铃提醒重新打开（袁正锟 2026-10-14）：只有带提醒时间的任务才有这个开关
      if (task.remindAt !== undefined) {
        task.alarm = TaskAlarm.ON;
      }
      return;
    }
    this.statusBeforeCompleted.set(task.id, task.status);
    task.status = TaskStatus.COMPLETED;
    task.finishedAt = Date.now();
    // 完成时自动关掉响铃提醒：用户意图置 OFF，已发布句柄一并撤销
    task.alarm = TaskAlarm.OFF;
    task.reminderId = undefined;
  }

  /**
   * 拨「响铃提醒」开关。
   *
   * v1 契约把"用户意图"和"已发布句柄"分开了：**`alarm`(0/1) 是意图**（字段表第 16 项，开关读它），
   * `reminderId` 是「已发布的本地提醒键」；官方语义里「`reminderId` 为空而 `alarm=1` ⇒ 开了但未生效」，
   * 所以这里**只置 `alarm`**，句柄交给服务。
   * TODO(袁正锟): 真接 `service/system/ReminderService` 后，这里要改成调用「发布提醒 / 撤销提醒」，
   * 成功后再写 `reminderId`，失败（如超 30 条报 1700002）则把 `alarm` 回滚。
   */
  setRemind(task: Task, isOn: boolean): void {
    task.alarm = isOn ? TaskAlarm.ON : TaskAlarm.OFF;
    if (!isOn) {
      task.reminderId = undefined;
    }
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
