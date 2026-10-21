/*
 * Mock 数据 —— **只为 UI 联调 / 走查用，不是真实数据，不许当数据源接进调用链**。
 * 形状与 `entry/src/main/ets/model/Models.ets` 的 `Task` 完全一致（**v1 定稿 28 字段**）。
 * 覆盖：§9.3 状态机的全部 6 态 + 契约里各种字段组合 + 最小合法数据。
 *
 * ⚠️⚠️ 必须用 `new Task()` 创建，**绝不能用对象字面量**：
 *   官方 FAQ《使用@ObservedV2和@Trace深度观测对象时，数据改变而UI未刷新》原文 ——
 *   「使用 @ObservedV2 与 @Trace 装饰器的类，**需通过 new 操作符实例化后，才具备被观测变化的能力**」；
 *   案例里用字面量初始化的对象「**不具备可被观测的能力**」。
 *   踩过：mock 用字面量造 Task，卡片上拨「响铃提醒」开关改成 off，描述行的倒计时**不消失**
 *   （数据改了、界面不刷新）。
 *   同一条规矩对 repository 也成立：以后从关系库读出来的行**必须** `new Task()` 再逐字段赋值。
 */
import { RepeatFrequency, RepeatRule, Task, TaskAlarm, TaskLevel, TaskPriority, TaskSource, TaskStatus, TaskStep } from '../model';

/** 把「2026 年某月某日某时」写成人能读的样子，避免在下面堆裸毫秒数（本地时区） */
function at(month: number, day: number, hour: number, minute: number): number {
  return new Date(2026, month - 1, day, hour, minute, 0, 0).getTime();
}

/** 造一条重复规则（`daysOfWeek` 里 **1~7 ＝ 周一~周日**，与官方同义） */
function weekly(daysOfWeek: number[], interval?: number): RepeatRule {
  const rule: RepeatRule = new RepeatRule();
  rule.frequency = RepeatFrequency.WEEKLY;
  rule.daysOfWeek = daysOfWeek;
  if (interval !== undefined) {
    rule.interval = interval;
  }
  return rule;
}

/** 用 new 建任务：先给必填项（`id`/`status`/`name`/`createdAt`/`priority`/`alarm`），其余按需再赋 */
function newTask(id: number, status: TaskStatus, name: string, priority: TaskPriority): Task {
  const created: Task = new Task();
  created.id = id;
  created.status = status;
  created.name = name;
  created.priority = priority;
  // 必填：创建时刻（非用户填，真实场景由 repository / 解析层给）
  created.createdAt = at(10, 8, 9, 30);
  // 默认不提醒（用户意图），要提醒的条目下面单独置 alarm + remindAt
  created.alarm = TaskAlarm.OFF;
  return created;
}

function buildMockTasks(): Task[] {
  // —— 1. 有步骤、有提醒、重复、多个标签：字段最全的一条 ——
  const high: Task = newTask(1, TaskStatus.IN_PROGRESS, '高数作业第三章', TaskPriority.IMPORTANT);
  high.steps = [{ content: '读 3.1 节', done: 1 }, { content: '做 3.2 课后题', done: 0 }, { content: '整理错题', done: 0 }] as TaskStep[];
  high.dueAt = at(10, 16, 23, 59);
  high.dueText = '今晚 23:59 前';
  high.remindAt = at(10, 16, 20, 0);
  high.alarm = TaskAlarm.ON;
  high.reminderId = 101;
  high.repeat = [weekly([1, 2, 4])];
  high.level = TaskLevel.HARD;
  high.category = '作业';
  high.tags = ['数学', '期末周'];
  high.source = TaskSource.SHARE;
  high.originDetail = 'HMOS 知了APP开发';
  high.note = '老师说要交纸质版，别忘了带去教室';
  high.rawText = '第三章作业：3.1 节读完，3.2 节课后题全做，下周二、周四检查，今晚先把错题整理了';
  high.rawJson = '{"title":"高数作业第三章","time_text":"今晚 23:59 前","priority":1}';
  high.certainty = 86;
  high.clientTaskId = 'cand_1001';

  // —— 2. 待确认 + 截止原文模糊 + 缺地点/对象：验证「缺失不猜测」——
  const cet: Task = newTask(2, TaskStatus.PENDING_CONFIRM, '英语四级报名', TaskPriority.NORMAL);
  cet.dueAt = at(10, 19, 23, 59);
  cet.dueText = '下周一截止';
  cet.repeatText = '';
  cet.category = '通知';
  cet.tags = ['四六级'];
  cet.note = '群里只说了「下周一截止」，具体时间不确定，待确认';
  cet.rawText = '教务处通知：2026 年 12 月四六级报名下周一开始，具体截止时间待定';
  cet.rawJson = '{"title":"英语四级报名","time_text":"下周一截止"}';
  cet.source = TaskSource.SHARE;
  cet.originDetail = '微信';
  cet.certainty = 62;
  cet.missingFields = ['place', 'who'];
  cet.clientTaskId = 'cand_1002';

  // —— 3. 有两步步骤、无标签、紧急 ——
  const physics: Task = newTask(3, TaskStatus.CONFIRMED, '物理实验报告提交', TaskPriority.URGENT);
  physics.steps = [{ content: '画电路图', done: 0 }, { content: '写误差分析', done: 0 }] as TaskStep[];
  physics.dueAt = at(10, 19, 17, 0);
  physics.dueText = '下周一 17:00';
  physics.remindAt = at(10, 19, 15, 0);
  physics.alarm = TaskAlarm.ON;
  physics.reminderId = 103;
  physics.level = TaskLevel.HARD;
  physics.category = '作业';
  physics.place = '实验楼 B302';
  physics.who = '小组';
  physics.note = '实验数据在实验台电脑上，记得先拷走';
  physics.rawText = '把上次实验的报告交上来，下周一 17:00 前放在实验楼 B302，小组合作完成';
  physics.rawJson = '{"title":"物理实验报告提交","time_text":"下周一 17:00"}';
  physics.source = TaskSource.VOICE;
  physics.originDetail = '语音记录';
  physics.certainty = 78;
  physics.clientTaskId = 'cand_1003';

  // —— 4. 已完成：有完成时刻、有提醒 ——
  const club: Task = newTask(4, TaskStatus.COMPLETED, '社团例会', TaskPriority.NORMAL);
  club.dueAt = at(10, 16, 19, 0);
  club.dueText = '每周五 19:00';
  club.finishedAt = at(10, 16, 18, 40);
  club.alarm = TaskAlarm.ON;
  club.reminderId = 104;
  club.repeat = [weekly([5])];
  club.category = '活动';
  club.tags = ['社团'];
  club.place = '教室 B203';
  club.note = '每周五 19:00，教室 B203';
  club.rawText = '本周例会照常，周五 19:00 教室 B203';
  club.source = TaskSource.PASTE;
  club.originDetail = '社团群';
  club.certainty = 95;
  club.clientTaskId = 'cand_1004';

  // —— 5. 已过期（只有系统能写这个状态）——
  const fee: Task = newTask(5, TaskStatus.EXPIRED, '交学杂费', TaskPriority.URGENT);
  fee.dueAt = at(10, 10, 23, 59);
  fee.dueText = '10 月 10 日 23:59';
  fee.category = '通知';
  fee.who = '本人';
  fee.note = '已经过期了，还在考虑要不要补交';
  fee.rawText = '请于 10 月 10 日前缴纳本学期学杂费';
  fee.source = TaskSource.SHARE;
  fee.originDetail = '班级群';
  fee.certainty = 91;
  fee.missingFields = ['place'];
  fee.clientTaskId = 'cand_1005';

  // —— 6. 已删除：不进时间线（验证过滤）——
  const deleted: Task = newTask(6, TaskStatus.DELETED, '临时测试任务', TaskPriority.NORMAL);
  deleted.category = '其他';
  deleted.note = '用户删掉了，不该出现在时间线里，留着验证过滤';
  deleted.rawText = '测试用例';
  deleted.source = TaskSource.MANUAL;
  deleted.clientTaskId = 'cand_1006';

  // —— 7. 最小合法数据：只有名称 + 紧急程度 ——
  const minimal: Task = newTask(7, TaskStatus.CONFIRMED, '只填了名称和紧急程度', TaskPriority.URGENT);
  minimal.certainty = 30;
  minimal.missingFields = ['dueAt', 'place', 'who'];
  minimal.clientTaskId = 'cand_1007';

  // —— 8. 第二条规则用「规则表达不了就写原话」的兜底 ——
  const review: Task = newTask(8, TaskStatus.IN_PROGRESS, '整理期末复习计划', TaskPriority.IMPORTANT);
  review.steps = [{ content: '列考试科目', done: 1 }, { content: '排每天复习量', done: 0 }] as TaskStep[];
  review.dueAt = at(11, 1, 23, 59);
  review.dueText = '11 月 1 日前';
  review.repeatText = '每学期第 3 周交一次';
  review.level = TaskLevel.MEDIUM;
  review.category = '作业';
  review.tags = ['期末周', '计划', '长期'];
  review.note = '自定义重复的写法还没定，这里先按原样存原话';
  review.rawText = '复习计划每学期第 3 周交一次，先列科目再排每天的量';
  review.source = TaskSource.BOT;
  review.originDetail = '知了机器人';
  review.certainty = 58;
  review.clientTaskId = 'cand_1008';

  return [high, cet, physics, club, fee, deleted, minimal, review];
}

/** Mock 任务表（每次取值都是同一批 `new` 出来的对象） */
export const MOCK_TASKS: Task[] = buildMockTasks();
