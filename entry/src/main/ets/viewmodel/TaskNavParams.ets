/**
 * 二级页路由与跳转参数的公共约定（**别在页面里各写一份**）。
 *
 * 路由怎么生效（官方系统路由表）：
 *  · `resources/base/profile/router_map.json` 里按 `name` 注册页面源文件与 `@Builder` 实例化方法；
 *  · 跳转用 `NavPathStack.pushPathByName(name, param)`；
 *  · ⚠️ **不要**走 `HdsNavigation.navDestination(builder)` 那条路（实测整页空白，见台账 #113）。
 */
import { Task } from '../model';
import { TaskListStore } from './TaskListStore';

/** 搜索页 */
export const ROUTE_SEARCH: string = 'SearchPage';
/** 任务详情页 */
export const ROUTE_TASK_DETAIL: string = 'TaskDetailPage';

/**
 * 导航栈在 `AppStorage` 里的键。
 *
 * 为什么用 AppStorage：官方《Navigation 页面路由》给了两种在子页面里拿栈的写法，
 * 方式一就是「使用 AppStorage 存储与获取」（方式二是 `NavDestination.onReady`）。
 * 这里需要的是**根页面里的栈**，而点卡片发生在 `A_TaskList` / `B_Search` 这两个更深的组件里 ——
 * 一层层往下传参数（`A_Main → MainTabBar → A_TaskList`）太绕，走官方的方式一更直接。
 */
export const NAV_STACK_KEY: string = 'appNavPathStack';

/** 任务详情页的跳转参数：把任务对象本身 + store 一起带过去（`Task` 是 `@ObservedV2`，改字段详情页能跟着刷新） */
export class TaskDetailParam {
  task: Task;
  store: TaskListStore;
  /** 待确认消息详情：底部显示「保留 / 忽略」，不显示普通反馈 */
  pendingMode: boolean;

  constructor(task: Task, store: TaskListStore, pendingMode: boolean = false) {
    this.task = task;
    this.store = store;
    this.pendingMode = pendingMode;
  }
}
