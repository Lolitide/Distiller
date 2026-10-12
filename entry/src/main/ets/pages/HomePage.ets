import { PollService } from '../service/PollService';
import { Store } from '../common/Store';
import { RobotMessage, DetailParams, formatTime } from '../common/Types';

@Entry
@Component
struct HomePage {
  @StorageLink('msgVersion') @Watch('onVersionChanged') msgVersion: number = 0;
  @StorageLink('needOnboarding') @Watch('onNeedOnboarding') needOnboarding: boolean = false;
  @StorageLink('newMsgBanner') @Watch('onBannerChanged') newMsgBanner: string = '';
  @State messages: RobotMessage[] = [];
  @State statusText: string = '';
  @State refreshing: boolean = false;
  @State hideSelf: boolean = false;
  private statusTimer: number = -1;
  private bannerTimer: number = -1;

  aboutToAppear(): void {
    this.messages = Store.getMessages();
    this.hideSelf = Store.getHideSelf();
    PollService.start();
    this.updateStatus();
    this.statusTimer = setInterval(() => {
      this.updateStatus();
    }, 10000);
  }

  onPageShow(): void {
    // 从设置页返回时重新读取显示开关，立即生效
    this.hideSelf = Store.getHideSelf();
    this.messages = Store.getMessages();
  }

  visibleMessages(): RobotMessage[] {
    if (!this.hideSelf) {
      return this.messages;
    }
    const out: RobotMessage[] = [];
    for (let i = 0; i < this.messages.length; i++) {
      if (this.messages[i].is_self !== true) {
        out.push(this.messages[i]);
      }
    }
    return out;
  }

  aboutToDisappear(): void {
    PollService.stop();
    if (this.statusTimer >= 0) {
      clearInterval(this.statusTimer);
      this.statusTimer = -1;
    }
    if (this.bannerTimer >= 0) {
      clearTimeout(this.bannerTimer);
      this.bannerTimer = -1;
    }
  }

  onVersionChanged(): void {
    this.messages = Store.getMessages();
  }

  onBannerChanged(): void {
    if (this.newMsgBanner.length > 0) {
      if (this.bannerTimer >= 0) {
        clearTimeout(this.bannerTimer);
      }
      this.bannerTimer = setTimeout(() => {
        this.clearBanner();
      }, 5000);
    }
  }

  clearBanner(): void {
    this.newMsgBanner = '';
    if (this.bannerTimer >= 0) {
      clearTimeout(this.bannerTimer);
      this.bannerTimer = -1;
    }
  }

  onNeedOnboarding(): void {
    if (this.needOnboarding) {
      AppStorage.setOrCreate<boolean>('needOnboarding', false);
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/OnboardingPage' });
    }
  }

  updateStatus(): void {
    if (PollService.lastError.length > 0) {
      this.statusText = PollService.lastError;
    } else if (PollService.lastSyncAt.length > 0) {
      this.statusText = '已连接 · 上次同步 ' + PollService.lastSyncAt;
    } else {
      this.statusText = '正在连接…';
    }
  }

  async onRefresh(): Promise<void> {
    this.refreshing = true;
    try {
      await PollService.sync();
    } catch (e) {
      // 忽略，状态条会显示错误
    }
    this.refreshing = false;
    this.updateStatus();
  }

  openDetail(item: RobotMessage): void {
    this.setRead(item.msg_id);
    const p: DetailParams = { msgId: item.msg_id };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/MessageDetailPage', params: p });
  }

  handleToTask(item: RobotMessage): void {
    Store.markAsTaskSource(item);
    this.setHandled(item.msg_id);
    this.getUIContext().getPromptAction().showToast({ message: '已交给解析' });
  }

  deleteMessage(msgId: string): void {
    const list: RobotMessage[] = Store.getMessages();
    const rest: RobotMessage[] = [];
    for (let i = 0; i < list.length; i++) {
      if (list[i].msg_id !== msgId) {
        rest.push(list[i]);
      }
    }
    Store.saveMessages(rest);
    this.bumpVersion();
  }

  setHandled(msgId: string): void {
    const list: RobotMessage[] = Store.getMessages();
    for (let i = 0; i < list.length; i++) {
      if (list[i].msg_id === msgId) {
        list[i].handled = true;
      }
    }
    Store.saveMessages(list);
    this.bumpVersion();
  }

  setRead(msgId: string): void {
    const list: RobotMessage[] = Store.getMessages();
    for (let i = 0; i < list.length; i++) {
      if (list[i].msg_id === msgId) {
        list[i].read = true;
      }
    }
    Store.saveMessages(list);
    this.bumpVersion();
  }

  bumpVersion(): void {
    AppStorage.setOrCreate<number>('msgVersion', (AppStorage.get<number>('msgVersion') ?? 0) + 1);
  }

  goSubs(): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/GroupSubPage' });
  }

  goSettings(): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/SettingsPage' });
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Text('机器人消息')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Button('订阅管理')
          .fontSize(12)
          .onClick(() => {
            this.goSubs();
          })
        Button('设置')
          .fontSize(12)
          .onClick(() => {
            this.goSettings();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 4 })

      Text(this.statusText)
        .fontSize(12)
        .fontColor(Color.Gray)
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 4 })

      if (this.newMsgBanner.length > 0) {
        Row({ space: 8 }) {
          Text(this.newMsgBanner)
            .fontSize(13)
            .fontColor(Color.White)
            .layoutWeight(1)
          Text('×')
            .fontSize(16)
            .fontColor(Color.White)
            .onClick(() => {
              this.clearBanner();
            })
        }
        .width('90%')
        .backgroundColor('#2E75B6')
        .borderRadius(4)
        .padding(8)
        .margin({ left: 16, right: 16, bottom: 4 })
        .onClick(() => {
          this.clearBanner();
        })
      }

      if (this.visibleMessages().length === 0) {
        Column({ space: 12 }) {
          Text(this.hideSelf && this.messages.length > 0 ? '你已隐藏自己发的消息，暂无其他消息' : '还没有收到消息')
            .fontSize(16)
            .fontColor(Color.Gray)
          Text('请确认机器人已在群里收到过消息')
            .fontSize(12)
            .fontColor(Color.Gray)
          Button('去订阅群')
            .onClick(() => {
              this.goSubs();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Refresh({ refreshing: this.refreshing }) {
          List({ space: 8 }) {
            ForEach(this.visibleMessages(), (item: RobotMessage) => {
              ListItem() {
                Column({ space: 6 }) {
                  Row() {
                    Text(item.group_label)
                      .fontSize(13)
                      .fontColor(Color.Gray)
                      .layoutWeight(1)
                    Text(formatTime(item.timestamp))
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    if (!item.read) {
                      Text('●')
                        .fontSize(12)
                        .fontColor(Color.Blue)
                    }
                  }
                  .width('100%')

                  Text(item.sender + '：' + item.content)
                    .fontSize(15)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  Row({ space: 12 }) {
                    if (!item.handled) {
                      Button('转成待办')
                        .fontSize(12)
                        .onClick(() => {
                          this.handleToTask(item);
                        })
                    } else {
                      Text('已转成待办')
                        .fontSize(12)
                        .fontColor(Color.Green)
                    }
                    Button('删除')
                      .fontSize(12)
                      .onClick(() => {
                        this.deleteMessage(item.msg_id);
                      })
                  }
                }
                .width('100%')
                .padding(12)
                .alignItems(HorizontalAlign.Start)
                .onClick(() => {
                  this.openDetail(item);
                })
              }
            }, (item: RobotMessage) => item.msg_id)
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .onRefreshing(() => {
          this.onRefresh();
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
