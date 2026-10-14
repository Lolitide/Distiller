/*
 * Mock 数据 —— **只为 UI 联调 / 走查用，不是真实数据，不许当数据源接进调用链**。
 * 形状与 `entry/src/main/ets/model/Models.ets` 的 `Task` 完全一致（14 个字段）。
 * 覆盖面：`docs/开发指南.md` §9.3 状态机的全部 6 态 + 契约里各种字段组合 + 最小合法数据。
 */
import { Task, TaskPriority, TaskRepeat, TaskStatus } from '../model';

/** 把「2026 年某月某日某时」写成人能读的样子，避免在下面堆裸毫秒数（本地时区） */
function at(month: number, day: number, hour: number, minute: number): number {
  return new Date(2026, month - 1, day, hour, minute, 0, 0).getTime();
}

export const MOCK_TASKS: Task[] = [
  {
    id: 1,
    status: TaskStatus.IN_PROGRESS,
    title: '高数作业第三章',
    steps: [
      { content: '做完 3.1 习题' },
      { content: '做完 3.2 习题' },
      { content: '整理错题' }
    ],
    dueAt: at(10, 16, 23, 59),
    remindAt: at(10, 16, 19, 0),
    reminderId: 101,
    repeat: TaskRepeat.NONE,
    estimatedHours: 3,
    priority: TaskPriority.IMPORTANT,
    source: 'QQ',
    category: '作业',
    tags: ['数学', '期末周'],
    detail: '老师说要交纸质版，别忘了带去教室'
  },
  {
    id: 2,
    status: TaskStatus.PENDING_CONFIRM,
    title: '英语四级报名',
    dueAt: at(10, 19, 23, 59),
    repeat: TaskRepeat.NONE,
    priority: TaskPriority.NORMAL,
    source: '微信',
    category: '考试',
    detail: '群里只说了「下周一截止」，具体时间不确定，待确认'
  },
  {
    id: 3,
    status: TaskStatus.CONFIRMED,
    title: '物理实验报告提交',
    steps: [{ content: '画电路图' }, { content: '写误差分析' }],
    dueAt: at(10, 19, 17, 0),
    remindAt: at(10, 19, 9, 0),
    repeat: TaskRepeat.NONE,
    estimatedHours: 5,
    priority: TaskPriority.URGENT,
    source: 'QQ',
    category: '作业',
    tags: ['物理'],
    detail: '实验数据在实验台电脑上，记得先拷走'
  },
  {
    id: 4,
    status: TaskStatus.COMPLETED,
    title: '社团例会',
    remindAt: at(10, 16, 18, 30),
    reminderId: 104,
    repeat: TaskRepeat.WEEKLY,
    estimatedHours: 1,
    priority: TaskPriority.NORMAL,
    source: '微信',
    category: '自定义晚自习',
    tags: ['社团'],
    detail: '每周五 19:00，教室 B203'
  },
  {
    id: 5,
    status: TaskStatus.EXPIRED,
    title: '交学杂费',
    dueAt: at(10, 10, 23, 59),
    repeat: TaskRepeat.NONE,
    priority: TaskPriority.URGENT,
    source: '自定义教务系统',
    detail: '已经过期了，还在考虑要不要补交'
  },
  {
    id: 6,
    status: TaskStatus.DELETED,
    title: '临时测试任务',
    repeat: TaskRepeat.NONE,
    priority: TaskPriority.NORMAL,
    source: '自定义',
    detail: '用户删掉了，不该出现在时间线里，留着验证过滤'
  },
  {
    id: 7,
    status: TaskStatus.CONFIRMED,
    title: '只填了名称和紧急程度',
    priority: TaskPriority.URGENT
  },
  {
    id: 8,
    status: TaskStatus.IN_PROGRESS,
    title: '整理期末复习计划',
    steps: [{ content: '列考试科目' }, { content: '排每天复习量' }],
    dueAt: at(11, 1, 23, 59),
    repeat: TaskRepeat.CUSTOM,
    repeatText: '每周一三五各一次',
    estimatedHours: 2,
    priority: TaskPriority.IMPORTANT,
    category: '自定义复习',
    tags: ['期末周', '计划', '长期'],
    detail: '自定义重复的写法还没定，这里先按原样存文本'
  }
];

/** 详情页按 id 取一条 */
export function findMockTask(id: number): Task | undefined {
  return MOCK_TASKS.find((item: Task) => item.id === id);
}
