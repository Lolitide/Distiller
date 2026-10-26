/**
 * 搜索页的 ViewModel：只做「关键词怎么匹配」和「结果怎么分组」，不碰存储、不碰界面。
 *
 * 分组**直接复用任务列表页那套**（`TaskListViewModel.groupByDay`）：搜索结果也用
 * `TaskDayGroup`，这样页面上就能直接用列表页的 `TaskGroupHeader` + `TaskCard`（需求方 2026-10-16：
 * 「把 List 页的那些 ListGroup、Card 直接弄过来复用」）。
 */
import { Task } from '../model';
import { TaskDayGroup, TaskListViewModel } from './TaskListViewModel';

/** 搜索页的三种显示状态 */
export enum SearchState {
  /** 还没输入关键词 */
  IDLE = 0,
  /** 有关键词、也有结果 */
  RESULTS = 1,
  /** 有关键词、但一条都没匹配上 */
  NO_RESULT = 2
}

export class TaskSearchViewModel {
  /** 关键词是不是空的（只有空白也算空） */
  static isEmptyQuery(query: string): boolean {
    return TaskSearchViewModel.text(query).trim().length === 0;
  }

  /**
   * 把可能为 `undefined` 的字符串归一成字符串。
   *
   * 🔴 为什么必须有这一层（2026-10-23「搜索页一输入字符就闪退」的**直接触发点**）：
   * `Task.name` 声明成 `string`，但本机 `preferences` 里的旧数据**没有这个键** ——
   * 2026-10-17 的 `refactor: 接口字段对齐` 把 `title` 改名成了 `name`（同时 `detail` → `note`），
   * 旧版本落盘的 JSON 读出来 `name` 就是 `undefined`。这里对它调 `.toLowerCase()` 会抛
   * `TypeError: Cannot read property toLowerCase of undefined`，而搜索跑在 `@Monitor` 里 ——
   * 框架把该异常当 RuntimeError 上报，**整个进程退出**，不是"某个组件坏掉"。
   *
   * 数据侧已在 `TaskRepository.revive` 做旧字段迁移与兜底；这里是第二道，
   * 保证以后任何一条脏数据最多是"没搜到"，不会再把 App 带走。
   */
  private static text(value: string | undefined): string {
    return value === undefined ? '' : value;
  }

  /**
   * 一条任务是否命中关键词：**标题 / 标签 / 备注 / 类型 / 来源 / 步骤** 任一包含就算命中
   * （大小写不敏感；只做子串匹配，不含分词与模糊 —— 以后要分词/拼音再单开一轮）。
   */
  static matches(task: Task, query: string): boolean {
    const needle: string = query.trim().toLowerCase();
    if (needle.length === 0) {
      return false;
    }
    if (TaskSearchViewModel.text(task.name).toLowerCase().includes(needle)) {
      return true;
    }
    const tags: string[] | undefined = task.tags;
    if (tags !== undefined && TaskSearchViewModel.anyContains(tags, needle)) {
      return true;
    }
    const note: string | undefined = task.note;
    if (note !== undefined && TaskSearchViewModel.text(note).toLowerCase().includes(needle)) {
      return true;
    }
    const category: string | undefined = task.category;
    if (category !== undefined && TaskSearchViewModel.text(category).toLowerCase().includes(needle)) {
      return true;
    }
    // 来源：v1 起 `source` 是枚举（paste/share/bot/voice/manual），**显示与检索用的是 `originDetail`**
    const originDetail: string | undefined = task.originDetail;
    if (originDetail !== undefined && TaskSearchViewModel.text(originDetail).toLowerCase().includes(needle)) {
      return true;
    }
    const steps = task.steps;
    if (steps !== undefined) {
      const contents: string[] = [];
      steps.forEach((step) => contents.push(TaskSearchViewModel.text(step.content)));
      if (TaskSearchViewModel.anyContains(contents, needle)) {
        return true;
      }
    }
    return false;
  }

  private static anyContains(values: string[], needle: string): boolean {
    for (let i = 0; i < values.length; i++) {
      if (TaskSearchViewModel.text(values[i]).toLowerCase().includes(needle)) {
        return true;
      }
    }
    return false;
  }

  /**
   * 搜索结果：先按关键词过滤，再**复用列表页的分组**。
   * ⚠️ 结果里**所有分组一律展开**（`groupByDay` 默认只展开「今天」）—— 搜索结果是给人一条条看的，
   * 折叠起来还得再点一下，不合理。
   */
  static search(tasks: Task[], query: string, today: Date): TaskDayGroup[] {
    if (TaskSearchViewModel.isEmptyQuery(query)) {
      return [];
    }
    const hit: Task[] = tasks.filter((task: Task) => TaskSearchViewModel.matches(task, query));
    const groups: TaskDayGroup[] = TaskListViewModel.groupByDay(hit, today);
    groups.forEach((group: TaskDayGroup) => {
      group.expanded = true;
    });
    return groups;
  }

  /** 页面该显示哪一种状态 */
  static state(results: TaskDayGroup[], query: string): SearchState {
    if (TaskSearchViewModel.isEmptyQuery(query)) {
      return SearchState.IDLE;
    }
    return results.length > 0 ? SearchState.RESULTS : SearchState.NO_RESULT;
  }
}
