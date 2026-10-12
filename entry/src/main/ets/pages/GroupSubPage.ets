import { ApiClient } from '../common/ApiClient';
import { Store } from '../common/Store';
import { GroupsData, GroupItem, SubscribeData, LocalSubscription, ApiResult, SubscribeBody, UnsubscribeBody } from '../common/Types';

@Entry
@Component
struct GroupSubPage {
  @State groups: GroupItem[] = [];
  @State loading: boolean = false;
  @State error: string = '';
  @State busyOpenid: string = '';

  aboutToAppear(): void {
    this.loadGroups();
  }

  async loadGroups(): Promise<void> {
    this.loading = true;
    this.error = '';
    const res = await ApiClient.get<GroupsData>('/api/relay/groups');
    this.loading = false;
    if (res.ok && res.data !== undefined) {
      this.groups = res.data.groups;
      Store.saveGroups(this.groups);
      this.syncSubs();
    } else {
      this.error = res.error?.message ?? '加载群列表失败';
    }
  }

  async toggleSub(item: GroupItem, isOn: boolean): Promise<void> {
    if (this.busyOpenid.length > 0) {
      return;
    }
    this.busyOpenid = item.group_openid;
    let res: ApiResult<SubscribeData>;
    if (isOn) {
      const body: SubscribeBody = { group_openid: item.group_openid, keywords: '', min_priority: 'all', mute: false };
      res = await ApiClient.post<SubscribeData>('/api/relay/subscribe', body);
    } else {
      const body: UnsubscribeBody = { group_openid: item.group_openid };
      res = await ApiClient.post<SubscribeData>('/api/relay/unsubscribe', body);
    }
    this.busyOpenid = '';
    if (res.ok) {
      item.subscribed = isOn;
      this.groups = this.groups.slice();
      Store.saveGroups(this.groups);
      this.syncSubs();
    } else {
      this.showToast(res.error?.message ?? '操作失败');
    }
  }

  syncSubs(): void {
    const subs: LocalSubscription[] = [];
    for (let i = 0; i < this.groups.length; i++) {
      const g: GroupItem = this.groups[i];
      if (g.subscribed) {
        subs.push({
          group_openid: g.group_openid,
          label: g.label,
          keywords: '',
          min_priority: 'all',
          mute: false,
          enabled: true
        });
      }
    }
    Store.saveSubs(subs);
  }

  showToast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  goBack(): void {
    const router = this.getUIContext().getRouter();
    // 首次安装经 OnboardingPage replaceUrl 进来时，本页是栈底，back() 会直接退出应用；
    // 这种情况回到主页面（消息页）。
    if (router.getStackSize() > 1) {
      router.back();
    } else {
      router.replaceUrl({ url: 'pages/HomePage' });
    }
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Button('返回')
          .onClick(() => {
            this.goBack();
          })
        Text('订阅管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.loading) {
        Text('加载中…')
          .margin(16)
      } else if (this.error.length > 0) {
        Column({ space: 8 }) {
          Text(this.error)
            .fontColor(Color.Red)
          Button('重试')
            .onClick(() => {
              this.loadGroups();
            })
        }
        .margin(16)
      } else if (this.groups.length === 0) {
        Text('机器人还没有在任何群里收到消息。请在 QQ 群里 @ 一下机器人。')
          .fontSize(14)
          .fontColor(Color.Gray)
          .margin(16)
      } else {
        List({ space: 8 }) {
          ForEach(this.groups, (item: GroupItem) => {
            ListItem() {
              Row({ space: 12 }) {
                Column({ space: 4 }) {
                  Text(item.label)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                  Text('消息 ' + item.message_count + ' 条')
                    .fontSize(12)
                    .fontColor(Color.Gray)
                  if (!item.bot_present) {
                    Text('机器人已不在该群')
                      .fontSize(12)
                      .fontColor(Color.Red)
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Toggle({ type: ToggleType.Switch, isOn: item.subscribed })
                  .enabled(this.busyOpenid.length === 0)
                  .onChange((isOn: boolean) => {
                    this.toggleSub(item, isOn);
                  })
              }
              .width('100%')
              .padding(12)
            }
          }, (item: GroupItem) => item.group_openid)
        }
        .width('100%')
        .layoutWeight(1)
      }

      Text('只接收你勾选的群；服务端不保存聊天内容。')
        .fontSize(12)
        .fontColor(Color.Gray)
        .width('100%')
        .padding(12)
    }
    .width('100%')
    .height('100%')
  }
}
