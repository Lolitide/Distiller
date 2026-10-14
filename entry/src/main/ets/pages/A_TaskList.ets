import { Task, TaskStatus } from '../model';
import { MOCK_TASKS } from '../mock/MockTasks';
import { MainTitleBar } from '../components/MainTitleBar';
import { TaskCard } from '../components/TaskCard';
import { TaskGroupHeader } from '../components/TaskGroupHeader';
import { TaskDayGroup, TaskListViewModel } from '../viewmodel/TaskListViewModel';

@ComponentV2
export struct A_TaskList {
  @Local groups: TaskDayGroup[] = TaskListViewModel.groupByDay(MOCK_TASKS, new Date());

  /** 点圆圈＝完成这项任务。已完成的不再重复处理（需求方只说「点击后完成」） */
  private completeTask(task: Task): void {
    if (task.status === TaskStatus.COMPLETED) {
      return;
    }
    task.status = TaskStatus.COMPLETED;
  }

  /**
   * 拨「响铃提醒」开关。开关状态由 `reminderId` 派生，所以这里就是给它置值 / 清空。
   * TODO(需求方): 真接 `service/system/ReminderService` 后，这里要改成调用「发布提醒 / 撤销提醒」，
   * `reminderId` 由服务返回，不许再在页面里凭空造。
   */
  private setRemind(task: Task, isOn: boolean): void {
    task.reminderId = isOn ? -1 : undefined;
  }

  @Builder
  groupHeader(group: TaskDayGroup) {
    TaskGroupHeader({
      group: group,
      onToggle: () => {
        group.expanded = !group.expanded;
      }
    })
  }

  build() {
    List() {
      ForEach(this.groups, (group: TaskDayGroup) => {
        ListItemGroup({ header: this.groupHeader(group) }) {
          if (group.expanded) {
            ForEach(group.tasks, (task: Task) => {
              ListItem() {
                TaskCard({
                  task: task,
                  onComplete: () => {
                    this.completeTask(task);
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
  }
}
