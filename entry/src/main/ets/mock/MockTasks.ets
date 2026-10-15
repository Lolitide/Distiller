/*
 * Mock 数据 —— **只为 UI 联调 / 走查用，不是真实数据，不许当数据源接进调用链**。
 * 形状与 `entry/src/main/ets/model/Models.ets` 的 `Task` 完全一致（15 个字段）。
 * 覆盖：`docs/开发指南.md` §9.3 状态机的全部 6 态 + 契约里各种字段组合 + 最小合法数据。
 *
 * ⚠️⚠️ 必须用 `new Task()` 创建，**绝不能用对象字面量**：
 *   官方 FAQ《使用@ObservedV2和@Trace深度观测对象时，数据改变而UI未刷新》原文 ——
 *   「使用 @ObservedV2 与 @Trace 装饰器的类，**需通过 new 操作符实例化后，才具备被观测变化的能力**」；
 *   案例里用字面量初始化的对象「**不具备可被观测的能力**」。
 *   踩过：mock 用字面量造 Task，卡片上拨「响铃提醒」开关改成 off，描述行的倒计时**不消失**
 *   （数据改了、界面不刷新）。而分组能正常展开收起，是因为 `TaskDayGroup` 本来就是 `new` 出来的。
 *
 *   同一条规矩对 repository 也成立：以后从关系库读出来的行**必须** `new Task()` 再逐字段赋值。
 */
import { Task, TaskPriority, TaskRepeat, TaskStatus } from '../model';

/** 把「2026 年某月某日某时」写成人能读的样子，避免在下面堆裸毫秒数（本地时区） */
function at(month: number, day: number, hour: number, minute: number): number {
  return new Date(2026, month - 1, day, hour, minute, 0, 0).getTime();
}

/** 用 new 建任务：先只给 4 个必填（`title` / `priority` 是契约里的必填项），其余按需再赋 */
function newTask(id: number, status: TaskStatus, title: string, priority: TaskPriority): Task {
  const created: Task = new Task();
  created.id = id;
  created.status = status;
  created.title = title;
  created.priority = priority;
  return created;
}

function buildMockTasks(): Task[] {
  const high: Task = newTask(1, TaskStatus.IN_PROGRESS, '高数作业第三章', TaskPriority.IMPORTANT);
  high.steps = [
    { content: '做完 3.1 习题' },
    { content: '做完 3.2 习题' },
    { content: '整理错题' }
  ];
  high.dueAt = at(10, 16, 23, 59);
  high.remindAt = at(10, 16, 19, 0);
  high.reminderId = 101;
  high.repeat = TaskRepeat.NONE;
  high.estimatedHours = 3;
  high.source = 'QQ';
  high.category = '作业';
  high.tags = ['数学', '期末周'];
  high.detail = '老师说要交纸质版，别忘了带去教室';

  const cet: Task = newTask(2, TaskStatus.PENDING_CONFIRM, '英语四级报名', TaskPriority.NORMAL);
  cet.dueAt = at(10, 19, 23, 59);
  cet.repeat = TaskRepeat.NONE;
  cet.source = '微信';
  cet.category = '考试';
  cet.detail = '群里只说了「下周一截止」，具体时间不确定，待确认';

  const physics: Task = newTask(3, TaskStatus.CONFIRMED, '物理实验报告提交', TaskPriority.URGENT);
  physics.steps = [{ content: '画电路图' }, { content: '写误差分析' }];
  physics.dueAt = at(10, 19, 17, 0);
  physics.remindAt = at(10, 19, 9, 0);
  physics.repeat = TaskRepeat.NONE;
  physics.estimatedHours = 5;
  physics.source = 'QQ';
  physics.category = '作业';
  physics.tags = ['物理'];
  physics.detail = '实验数据在实验台电脑上，记得先拷走';

  const club: Task = newTask(4, TaskStatus.COMPLETED, '社团例会', TaskPriority.NORMAL);
  club.remindAt = at(10, 16, 18, 30);
  club.reminderId = 104;
  club.repeat = TaskRepeat.WEEKLY;
  club.estimatedHours = 1;
  club.source = '微信';
  club.category = '自定义晚自习';
  club.tags = ['社团'];
  club.detail = '每周五 19:00，教室 B203';

  const fee: Task = newTask(5, TaskStatus.EXPIRED, '交学杂费', TaskPriority.URGENT);
  fee.dueAt = at(10, 10, 23, 59);
  fee.repeat = TaskRepeat.NONE;
  fee.source = '自定义教务系统';
  fee.detail = '已经过期了，还在考虑要不要补交';

  const deleted: Task = newTask(6, TaskStatus.DELETED, '临时测试任务', TaskPriority.NORMAL);
  deleted.repeat = TaskRepeat.NONE;
  deleted.source = '自定义';
  deleted.detail = '用户删掉了，不该出现在时间线里，留着验证过滤';

  const minimal: Task = newTask(7, TaskStatus.CONFIRMED, '只填了名称和紧急程度', TaskPriority.URGENT);

  const review: Task = newTask(8, TaskStatus.IN_PROGRESS, '整理期末复习计划', TaskPriority.IMPORTANT);
  review.steps = [{ content: '列考试科目' }, { content: '排每天复习量' }];
  review.dueAt = at(11, 1, 23, 59);
  review.repeat = TaskRepeat.CUSTOM;
  review.repeatText = '每周一三五各一次';
  review.estimatedHours = 2;
  review.category = '自定义复习';
  review.tags = ['期末周', '计划', '长期'];
  review.detail = '自定义重复的写法还没定，这里先按原样存文本';

  return [high, cet, physics, club, fee, deleted, minimal, review];
}

export const MOCK_TASKS: Task[] = buildMockTasks();

/** 详情页按 id 取一条 */
export function findMockTask(id: number): Task | undefined {
  return MOCK_TASKS.find((item: Task) => item.id === id);
}
