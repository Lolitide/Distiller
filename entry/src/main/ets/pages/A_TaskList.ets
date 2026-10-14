import { Task } from '../model';
import { MOCK_TASKS } from '../mock/MockTasks';
import { MainTitleBar } from '../components/MainTitleBar';
import { TaskGroupHeader } from '../components/TaskGroupHeader';
import { TaskDayGroup, TaskListViewModel } from '../viewmodel/TaskListViewModel';

@ComponentV2
export struct A_TaskList {
  @Local groups: TaskDayGroup[] = TaskListViewModel.groupByDay(MOCK_TASKS, new Date());

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
                Text(task.title)
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
