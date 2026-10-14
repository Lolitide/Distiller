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
          spaceWidth: $r('sys.float.padding_level8')
        }) {
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
