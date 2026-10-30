/**
 * 回收站（二级页）：
 *  · 「忽略的消息」= 待确认里点忽略的消息；
 *  · 「删除的待办」= 时间线/待确认里删掉的任务；
 *  · 两者都保留删除时的 status，只打 `trashKind` 标记；
 *  · 支持搜索、多选、恢复、彻底删除。
 *
 * 2026-10-29 需求方：「回收站页里的父子卡片改成和任务列表页一样的样式，可以折叠/收起；
 * 多选按钮改成和任务列表右上角一样的按钮」。
 * 所以这一页不再自己画「一张大卡片里套小卡片」的分区，而是**完全复用任务列表那套分组结构**：
 *   · 组头 = 官方 `SubHeader`（标题 + 「N 条」副标题）+ 右侧 chevron，点击整行折叠/展开；
 *   · 组内卡片直接铺在页面 `surface` 上（卡片自己是 `surfaceContainerLow`），不再套一层父卡片；
 *   · 折叠/展开包 `animateTo`，卡片配同款淡入 + 位移 transition；
 *   · 多选入口搬到标题栏右上角，和任务列表同一个图标（`MainTitleBar.multiSelectMenu`），
 *     编辑态再用同一套「取消 / 全选」纯文字菜单（`MainTitleBar.editModeMenu`）。
 */
import { HdsNavDestination, HdsNavigationMenuContentOptions } from '@kit.UIDesignKit';
import { KeyboardAvoidMode, LengthMetrics, SubHeader } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { WindowInsets } from '../utils/WindowInsets';
import { MainTitleBar } from '../components/MainTitleBar';
import { SearchField } from '../components/SearchField';
import { TaskCard } from '../components/TaskCard';
import { GROUP_HEADER_LIST_PULL_UP_VP } from '../components/TaskGroupHeader';
import { Task, TaskStatus } from '../model';
import { TaskListStore } from '../viewmodel/TaskListStore';
import { ThemeStore } from '../utils/Theme';
import { showDeleteConfirmDialog } from '../utils/DeleteConfirmDialog';
import { NAV_STACK_KEY, ROUTE_TASK_DETAIL, TaskDetailParam } from '../viewmodel/TaskNavParams';

/** 分组折叠/展开动画时长（毫秒）：与任务列表分组同一档 */
const GROUP_EXPAND_ANIM_MS: number = 180;
/** 展开时卡片淡入的起始纵向偏移（vp）：与任务列表一致 */
const CARD_ENTER_OFFSET_VP: number = 16;

@Builder
export function RecycleBinPageBuilder(name: string, param: Object) {
  B_RecycleBin({ store: param as TaskListStore });
}

@ComponentV2
export struct B_RecycleBin {
  @Local themeStore: ThemeStore = ThemeStore.instance();
  @Require @Param store: TaskListStore;
  @Local query: string = '';
  @Local statusBarVp: number = 0;
  @Local ignoredExpanded: boolean = true;
  @Local deletedExpanded: boolean = true;

  aboutToAppear(): void {
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);
    this.store.exitEdit();
    this.statusBarVp = this.getUIContext().px2vp(WindowInsets.topPxCached());
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context !== undefined) {
      WindowInsets.topPx(context).then((px: number) => {
        this.statusBarVp = px > 0 ? this.getUIContext().px2vp(px) : 0;
      });
    }
  }

  aboutToDisappear(): void {
    this.store.exitEdit();
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.OFFSET);
  }

  private matches(task: Task): boolean {
    const q: string = this.query.trim().toLowerCase();
    if (q.length === 0) {
      return true;
    }
    const name: string = (task.name !== undefined ? task.name : '').toLowerCase();
    const note: string = (task.note !== undefined ? task.note : '').toLowerCase();
    const raw: string = (task.rawText !== undefined ? task.rawText : '').toLowerCase();
    return name.indexOf(q) >= 0 || note.indexOf(q) >= 0 || raw.indexOf(q) >= 0;
  }

  @Computed
  get ignoredTasks(): Task[] {
    return this.store.trashTasks('ignored').filter((task: Task) => this.matches(task));
  }

  @Computed
  get deletedTasks(): Task[] {
    return this.store.trashTasks('deleted').filter((task: Task) => this.matches(task));
  }

  /**
   * 右上角菜单随编辑态切换：
   * · 普通态 —— 一颗「多选」图标按钮（与任务列表那颗同图标）；
   * · 编辑态 —— 「取消 / 全选」两个纯文字按钮（与任务列表编辑态完全一致）。
   */
  @Computed
  get navMenu(): HdsNavigationMenuContentOptions {
    if (this.store.editing) {
      return MainTitleBar.editModeMenu(() => {
        this.store.exitEdit();
      }, () => {
        this.selectAllTrash();
      });
    }
    return MainTitleBar.multiSelectMenu(() => {
      this.store.enterEdit();
    });
  }

  private selectAllTrash(): void {
    const ids: number[] = [];
    this.ignoredTasks.forEach((task: Task) => ids.push(task.id));
    this.deletedTasks.forEach((task: Task) => ids.push(task.id));
    this.store.selectedIds = ids;
  }

  private groupCount(kind: string): number {
    return kind === 'ignored' ? this.ignoredTasks.length : this.deletedTasks.length;
  }

  private isExpanded(kind: string): boolean {
    return kind === 'ignored' ? this.ignoredExpanded : this.deletedExpanded;
  }

  /** 折叠 / 展开一个分组：状态变更包在 `animateTo` 里，卡片会被 transition 反向播放 */
  private toggleGroup(kind: string): void {
    this.getUIContext().animateTo({
      duration: GROUP_EXPAND_ANIM_MS,
      curve: Curve.FastOutSlowIn
    }, () => {
      if (kind === 'ignored') {
        this.ignoredExpanded = !this.ignoredExpanded;
      } else {
        this.deletedExpanded = !this.deletedExpanded;
      }
    });
  }

  /**
   * 分组头：和任务列表的组头同一套官方排版。
   * 标题/副标题走 `SubHeader`（官方组件），折叠图标画在它外侧、整行可点（同 `TaskGroupHeader`）。
   */
  @Builder
  groupHeader(kind: string) {
    Row({ space: 8 }) {
      Column() {
        SubHeader({
          primaryTitle: kind === 'ignored' ? '忽略的消息' : '删除的待办',
          secondaryTitle: String(this.groupCount(kind)) + ' 条'
        })
      }
      .layoutWeight(1)

      SymbolGlyph(this.isExpanded(kind) ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
        .fontSize($r('sys.float.subheader_right_icon_size'))
        .fontColor([$r('sys.color.icon_primary')])
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ end: LengthMetrics.resource($r('sys.float.padding_level8')) })
    .onClick(() => {
      this.toggleGroup(kind);
    })
  }

  /** 两组都空了：不画任何组头，直接给一行小字（2026-10-29 需求方） */
  @Computed
  get isEmpty(): boolean {
    return this.ignoredTasks.length === 0 && this.deletedTasks.length === 0;
  }

  @Builder
  emptyHint() {
    Column() {
      Text('还没有删除的消息/待办')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  trashCard(task: Task) {
    Column() {
      TaskCard({
        task: task,
        store: this.store,
        pendingMode: task.status === TaskStatus.PENDING_CONFIRM,
        onOpen: () => {
          if (this.store.editing) {
            this.store.toggleSelect(task.id);
            return;
          }
          AppStorage.get<NavPathStack>(NAV_STACK_KEY)
            ?.pushPathByName(ROUTE_TASK_DETAIL, new TaskDetailParam(
              task, this.store, task.status === TaskStatus.PENDING_CONFIRM, true));
        }
      })
    }
    .width('100%')
    .margin({ bottom: this.themeStore.listItemSpace })
    .transition(
      TransitionEffect.OPACITY
        .combine(TransitionEffect.translate({ y: -CARD_ENTER_OFFSET_VP }))
        .animation({ duration: GROUP_EXPAND_ANIM_MS, curve: Curve.FastOutSlowIn })
    )
  }

  /** 编辑态底部操作条：恢复 / 彻底删除（普通态不出现，页面只留列表） */
  @Builder
  editActionBar() {
    Row({ space: 12 }) {
      Button('恢复')
        .layoutWeight(1)
        .height(44)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(this.themeStore.scheme.primary)
        .backgroundColor(this.themeStore.scheme.surfaceContainerHigh)
        .enabled(this.store.selectedCount > 0)
        .opacity(this.store.selectedCount > 0 ? 1 : 0.4)
        .onClick(() => {
          this.store.restoreSelected();
        })
      Button('彻底删除')
        .layoutWeight(1)
        .height(44)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(this.themeStore.scheme.error)
        .backgroundColor(this.themeStore.scheme.errorContainer)
        .enabled(this.store.selectedCount > 0)
        .opacity(this.store.selectedCount > 0 ? 1 : 0.4)
        .onClick(() => {
          showDeleteConfirmDialog(this.getUIContext(), '彻底删除',
            '删除后不可恢复，确定继续吗？', () => {
              this.store.purgeSelected();
            });
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 16 })
    .backgroundColor(this.themeStore.scheme.surface)
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.themeStore.scheme.surface)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .hitTestBehavior(HitTestMode.None)

        Column() {
          Row()
            .width('100%')
            .height(MainTitleBar.SUB_PAGE_TITLE_BAR_VP + this.statusBarVp)

          Row() {
            SearchField({
              onChange: (text: string) => {
                this.query = text;
              }
            })
          }
          .width('100%')
          .padding({
            left: $r('sys.float.padding_level8'),
            right: $r('sys.float.padding_level8')
          })

          if (this.isEmpty) {
            this.emptyHint()
          } else {
            List({ space: 0 }) {
              // 组里一条都没有就**不画父卡片/组头**（2026-10-29 需求方）
              if (this.ignoredTasks.length > 0) {
                ListItemGroup({ header: this.groupHeader('ignored') }) {
                  if (this.ignoredExpanded) {
                    ForEach(this.ignoredTasks, (task: Task) => {
                      ListItem() {
                        this.trashCard(task)
                      }
                    }, (task: Task) => 'ignored-' + task.id)
                  }
                }
                .margin({ top: -GROUP_HEADER_LIST_PULL_UP_VP })
              }

              if (this.deletedTasks.length > 0) {
                ListItemGroup({ header: this.groupHeader('deleted') }) {
                  if (this.deletedExpanded) {
                    ForEach(this.deletedTasks, (task: Task) => {
                      ListItem() {
                        this.trashCard(task)
                      }
                    }, (task: Task) => 'deleted-' + task.id)
                  }
                }
                .margin({ top: -GROUP_HEADER_LIST_PULL_UP_VP })
              }
            }
            .width('100%')
            .layoutWeight(1)
            .padding({
              top: 8
            })
            .scrollBar(BarState.Off)
            .contentEndOffset(24)
          }

          if (this.store.editing) {
            this.editActionBar()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.themeStore.scheme.surface)
      }
      .width('100%')
      .height('100%')
    }
    .titleBar({
      avoidLayoutSafeArea: true,
      style: MainTitleBar.style(this.themeStore.scheme.surface, this.themeStore.scheme.onSurface),
      content: {
        title: { mainTitle: '回收站' },
        menu: this.navMenu
      }
    })
    .hideBackButton(false)
  }
}
