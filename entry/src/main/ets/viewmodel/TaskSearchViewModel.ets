/**
 * 搜索页的 ViewModel：只做「关键词怎么匹配」和「结果怎么分组」，不碰存储、不碰界面。
 *
 * 分组**直接复用任务列表页那套**（`TaskListViewModel.groupByDay`）：搜索结果也用
 * `TaskDayGroup`，这样页面上就能直接用列表页的 `TaskGroupHeader` + `TaskCard`（袁正锟 2026-10-16：
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
    return query.trim().length === 0;
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
    if (task.title.toLowerCase().includes(needle)) {
      return true;
    }
    const tags: string[] | undefined = task.tags;
    if (tags !== undefined && TaskSearchViewModel.anyContains(tags, needle)) {
      return true;
    }
    const detail: string | undefined = task.detail;
    if (detail !== undefined && detail.toLowerCase().includes(needle)) {
      return true;
    }
    const category: string | undefined = task.category;
    if (category !== undefined && category.toLowerCase().includes(needle)) {
      return true;
    }
    const source: string | undefined = task.source;
    if (source !== undefined && source.toLowerCase().includes(needle)) {
      return true;
    }
    const steps = task.steps;
    if (steps !== undefined) {
      const contents: string[] = [];
      steps.forEach((step) => contents.push(step.content));
      if (TaskSearchViewModel.anyContains(contents, needle)) {
        return true;
      }
    }
    return false;
  }

  private static anyContains(values: string[], needle: string): boolean {
    for (let i = 0; i < values.length; i++) {
      if (values[i].toLowerCase().includes(needle)) {
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
