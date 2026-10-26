/*
 * **演示数据**（演示模式用）：5 条示例任务，覆盖 4 种分类与不同的创建/截止时间。
 *
 * 2026-10-27 从 `A_TaskList` 搬出来（需求方：「任务列表页删去『样例』按钮，转而统一到设置的
 * 『关于』下新增『演示模式』开关」）：
 *  · 数据构造留在这一层（纯函数，不碰 store / 页面）；
 *  · 开关的开/关在设置页：开 → `store.upsertAll(buildDemoTasks())`，
 *    关 → `store.removeTasksByClientIdPrefix(DEMO_TASK_PREFIX)`；
 *  · 每条演示任务的 `clientTaskId` 都带 `DEMO_TASK_PREFIX` 前缀，关掉时**按前缀精确摘除**，
 *    不会动到用户自己建的、或后端推来的任务；`upsertAll` 又按 `clientTaskId` 幂等合并，
 *    所以反复开关也不会堆出重复卡片。
 */
import { Task, TaskPriority, TaskStatus } from '../model';

/** 演示任务的 `clientTaskId` 前缀（关掉演示模式时按它摘除） */
export const DEMO_TASK_PREFIX: string = 'sample-';

/** 小时毫秒数 */
const HOUR_MS: number = 3600000;

/**
 * 造一组演示任务。
 * @param now 基准时刻（默认当前时刻）：创建时间往回错开、截止时间往后错开，
 *            这样列表里能同时看到「已过期 / 几小时后截止 / 几天后截止」三种状态。
 */
export function buildDemoTasks(now: number = Date.now()): Task[] {
  const list: Task[] = [];
  list.push(makeDemoTask('sample-notice-library', '图书馆临时闭馆通知',
    '因设备检修，今晚 18:00 后闭馆，请提前借还书', '通知', '通知',
    now - 19 * HOUR_MS, now + 3 * HOUR_MS));
  list.push(makeDemoTask('sample-notice-course', '选课系统维护通知',
    '选课系统本周六 00:00-06:00 维护，期间无法选课', '通知', '通知',
    now - 15 * HOUR_MS, now + 26 * HOUR_MS));
  list.push(makeDemoTask('sample-homework-practice', '提交社会实践材料',
    '把实践报告和照片打包交给辅导员', '作业', '作业',
    now - 11 * HOUR_MS, now + 50 * HOUR_MS));
  list.push(makeDemoTask('sample-exam-math', '复习高等数学',
    '重点看极限、导数和积分应用，做两套真题', '考试', '考试',
    now - 7 * HOUR_MS, now + 74 * HOUR_MS));
  list.push(makeDemoTask('sample-activity-club', '社团招新摆摊',
    '下午三点到东广场集合，带好宣传物料', '活动', '活动',
    now - 3 * HOUR_MS, now + 98 * HOUR_MS));
  return list;
}

/** 单条演示任务 */
function makeDemoTask(key: string, name: string, note: string, tag: string, category: string,
  createdAt: number, dueAt: number): Task {
  const task: Task = new Task();
  task.clientTaskId = key;
  task.name = name;
  task.note = note;
  task.category = category;
  task.tags = [tag];
  task.status = TaskStatus.CONFIRMED;
  task.priority = TaskPriority.NORMAL;
  task.createdAt = createdAt;
  task.dueAt = dueAt;
  task.dueText = dueText(dueAt);
  return task;
}

/** `M月d日 HH:mm`：与后端 `due_text` 的写法一致，列表卡片直接显示它 */
function dueText(ms: number): string {
  const date: Date = new Date(ms);
  const hour: string = date.getHours() < 10 ? `0${date.getHours()}` : `${date.getHours()}`;
  const minute: string = date.getMinutes() < 10 ? `0${date.getMinutes()}` : `${date.getMinutes()}`;
  return `${date.getMonth() + 1}月${date.getDate()}日 ${hour}:${minute}`;
}
