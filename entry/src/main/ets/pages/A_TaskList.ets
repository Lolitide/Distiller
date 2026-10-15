import { LengthMetrics } from '@kit.ArkUI';
import { Task, TaskStatus } from '../model';
import { MOCK_TASKS } from '../mock/MockTasks';
import { MainTitleBar } from '../components/MainTitleBar';
import { TaskCard } from '../components/TaskCard';
import { TaskGroupHeader } from '../components/TaskGroupHeader';
import { TaskDayGroup, TaskListViewModel } from '../viewmodel/TaskListViewModel';

@ComponentV2
export struct A_TaskList {
  @Local groups: TaskDayGroup[] = TaskListViewModel.groupByDay(MOCK_TASKS, new Date());

  /**
   * 记「完成前是什么状态」，供再点一次圆圈时回退（袁正锟 2026-10-14：再点恢复未完成状态）。
   * 放在页面是因为 `Task` 契约里没有这个字段 —— 它是 UI 的撤销记忆，不该进落库字段。
   * 页面重建会丢（丢了就回退到 `CONFIRMED`）。
   */
  private statusBeforeCompleted: Map<number, TaskStatus> = new Map();

  /** 点圆圈：未完成 → 完成（同时关掉响铃提醒）；已完成 → 退回完成前的状态，并把响铃提醒重新打开 */
  private toggleComplete(task: Task): void {
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
  private setRemind(task: Task, isOn: boolean): void {
    task.reminderId = isOn ? -1 : undefined;
  }

  /**
   * 分组头。
   *
   * 外面套一层 `Column` 是为了加**分组头与卡片之间的间隔**：`ListItemGroup` 的 `space`/`spaceWidth`
   * 只管「列表项之间」，不含分组头，官方没给「头与首项之间」的选项。
   * `SubHeader` 自己不能设通用属性（官方文档明说会多生成 `__Common__` 节点，属性可能不生效），
   * 所以间隔只能加在外层的这层壳上。
   */
  @Builder
  groupHeader(group: TaskDayGroup) {
    Column() {
      TaskGroupHeader({
        group: group,
        onToggle: () => {
          group.expanded = !group.expanded;
        }
      })
    }
    .width('100%')
    .padding({ bottom: LengthMetrics.resource($r('sys.float.padding_level8')) })
  }

  build() {
    List() {
      ForEach(this.groups, (group: TaskDayGroup) => {
        ListItemGroup({
          header: this.groupHeader(group),
          spaceWidth: $r('sys.float.padding_level4')
        }) {
          if (group.expanded) {
            ForEach(group.tasks, (task: Task) => {
              ListItem() {
                TaskCard({
                  task: task,
                  onToggleComplete: () => {
                    this.toggleComplete(task);
                  },
                  onRemindChange: (isOn: boolean) => {
                    this.setRemind(task, isOn);
                  }
                })
              }
            }, (task: Task) => `${task.id}`)
          }
        }
      }, (group: TaskDayGroup) => `${group.sortValue}-${group.hasDate}`)
    }
    .width('100%')
    .height('100%')
    .contentStartOffset(MainTitleBar.CONTENT_TOP_OFFSET_VP)
    .contentEndOffset($r('sys.float.padding_level4'))
  }
}
