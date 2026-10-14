/**
 * 底部导航：待办 / 群聊 / 设置。
 * 三个页面各自把它挂在最底下，点别处就 replaceUrl 过去（不留返回栈，符合 tab 语义）。
 */
const TAB_TODO: string = 'todo';
const TAB_GROUP: string = 'group';
const TAB_SETTINGS: string = 'settings';

@Component
export struct BottomNav {
  /** 当前页签：'todo' | 'group' | 'settings' */
  @Prop current: string;

  private urlOf(key: string): string {
    if (key === TAB_GROUP) {
      return 'pages/GroupListPage';
    }
    if (key === TAB_SETTINGS) {
      return 'pages/SettingsPage';
    }
    return 'pages/HomePage';
  }

  private labelOf(key: string): string {
    if (key === TAB_GROUP) {
      return '群聊';
    }
    if (key === TAB_SETTINGS) {
      return '设置';
    }
    return '待办';
  }

  @Builder
  tabItem(key: string) {
    Column({ space: 2 }) {
      Text(this.labelOf(key))
        .fontSize(13)
        .fontColor(key === this.current ? '#2E75B6' : '#999999')
        .fontWeight(key === this.current ? FontWeight.Bold : FontWeight.Normal)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (key === this.current) {
        return;
      }
      this.getUIContext().getRouter().replaceUrl({ url: this.urlOf(key) });
    })
  }

  build() {
    Row() {
      this.tabItem(TAB_TODO)
      this.tabItem(TAB_GROUP)
      this.tabItem(TAB_SETTINGS)
    }
    .width('100%')
    .height(56)
    .backgroundColor(Color.White)
    .border({ width: { top: 1 }, color: '#EEEEEE' })
  }
}
