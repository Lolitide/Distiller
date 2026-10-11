import { ApiClient } from '../common/ApiClient';
import { Store } from '../common/Store';
import { PollService } from '../service/PollService';
import { MyData, DeletedData } from '../common/Types';

const PRIVACY_TEXT = '本应用通过 QQ 机器人接收您主动订阅的群聊中公开可见的文本消息，用于生成您个人待办与提醒。\n' +
  '我们的服务器不保存聊天消息正文：消息仅用于判断是否属于您的订阅范围，并只在服务器内存中保留最多 30 分钟供您同步；超过 30 分钟未同步的消息将被自动删除且无法找回。\n' +
  '服务器保存的仅为您的订阅关系（您选择了哪些群）与匿名设备标识；您可随时撤回订阅，或一键删除服务器上属于您的全部数据。\n' +
  '未订阅的群、他人订阅的群的消息，我们既不保存，也不会向您分发。';

@Entry
@Component
struct SettingsPage {
  @State baseUrlInput: string = '';
  @State maxSeq: number = 0;
  @State msgCount: number = 0;
  @State lastSync: string = '';
  @State boundTail: string = '';
  @State myData: string = '';

  aboutToAppear(): void {
    this.baseUrlInput = Store.getBaseUrl();
    this.refreshLocal();
    this.loadMyData();
  }

  refreshLocal(): void {
    this.maxSeq = Store.getMaxSeq();
    this.msgCount = Store.getMessages().length;
    this.lastSync = PollService.lastSyncAt;
    this.boundTail = Store.getBoundTail();
  }

  async loadMyData(): Promise<void> {
    const res = await ApiClient.get<MyData>('/api/relay/my/data');
    if (res.ok && res.data !== undefined) {
      this.myData = '设备 ' + res.data.device_count + ' · 绑定 ' + res.data.bindings +
        ' · 订阅 ' + res.data.subscriptions + ' · 队列 ' + res.data.queue_items;
    } else {
      this.myData = '无法获取（' + (res.error?.message ?? '') + '）';
    }
  }

  saveBaseUrl(): void {
    if (this.baseUrlInput.length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '地址不能为空' });
      return;
    }
    Store.setBaseUrl(this.baseUrlInput);
    PollService.stop();
    PollService.start();
    this.getUIContext().getPromptAction().showToast({ message: '已保存并重启轮询' });
  }

  clearLocalMessages(): void {
    Store.clearMessages();
    AppStorage.setOrCreate<number>('msgVersion', (AppStorage.get<number>('msgVersion') ?? 0) + 1);
    this.refreshLocal();
    this.getUIContext().getPromptAction().showToast({ message: '已清空本机消息' });
  }

  confirmDeleteServer(): void {
    this.getUIContext().showAlertDialog({
      title: '删除我在服务端的全部数据',
      message: '删除后本机令牌立即失效，需要重新绑定。确定删除吗？',
      primaryButton: {
        value: '删除',
        action: () => {
          this.deleteServerData();
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
        }
      }
    });
  }

  async deleteServerData(): Promise<void> {
    const res = await ApiClient.del<DeletedData>('/api/relay/my/data');
    if (res.ok) {
      Store.clearAll();
      AppStorage.setOrCreate<number>('msgVersion', (AppStorage.get<number>('msgVersion') ?? 0) + 1);
      this.getUIContext().getPromptAction().showToast({ message: '已删除服务端数据' });
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/OnboardingPage' });
    } else {
      this.getUIContext().getPromptAction().showToast({ message: res.error?.message ?? '删除失败' });
    }
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Button('返回')
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
        Text('设置与隐私')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 4 })

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 8 }) {
            Text('服务器地址')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            TextInput({ placeholder: 'http://192.0.2.10:8730', text: this.baseUrlInput })
              .onChange((value: string) => {
                this.baseUrlInput = value;
              })
              .width('100%')
            Button('保存并重启轮询')
              .onClick(() => {
                this.saveBaseUrl();
              })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          Column({ space: 4 }) {
            Text('同步状态')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Text('游标 max_seq：' + this.maxSeq).fontSize(13)
            Text('本机消息条数：' + this.msgCount).fontSize(13)
            Text('上次同步时间：' + (this.lastSync.length > 0 ? this.lastSync : '尚未同步')).fontSize(13)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          Column({ space: 8 }) {
            Text('绑定信息')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Text(this.boundTail.length > 0 ? '已绑定（' + this.boundTail + '）' : '未绑定').fontSize(13)
            Text('服务端数据概览：' + (this.myData.length > 0 ? this.myData : '加载中…')).fontSize(13)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          Column({ space: 8 }) {
            Text('清理')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Button('清空本机消息')
              .onClick(() => {
                this.clearLocalMessages();
              })
            Button('删除我在服务端的数据')
              .onClick(() => {
                this.confirmDeleteServer();
              })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          Column({ space: 8 }) {
            Text('隐私说明')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Text(PRIVACY_TEXT)
              .fontSize(12)
              .fontColor(Color.Gray)
              .lineHeight(18)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
  }
}
