import { ApiClient } from '../common/ApiClient';
import { Config } from '../common/Config';
import { Store } from '../common/Store';
import { Discovery } from '../common/Discovery';
import { pasteboard } from '@kit.BasicServicesKit';
import { PollService } from '../service/PollService';
import { BindCodeData, BindCodeBody, BindStatusData, MyData, DeletedData } from '../common/Types';

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
  @State bound: boolean = false;
  @State boundKnown: boolean = false;
  @State myData: string = '';
  @State scanning: boolean = false;
  @State bindPhase: string = 'idle';
  @State pairCode: string = '';
  @State bindHint: string = '';
  private bindTimerId: number = -1;
  private bindPollCount: number = 0;
  private baselineBoundAt: string = '';

  aboutToAppear(): void {
    this.baseUrlInput = Store.getBaseUrl();
    this.refreshLocal();
    this.loadMyData();
    this.loadBindStatus();
  }

  aboutToDisappear(): void {
    this.stopBindPoll();
  }

  refreshLocal(): void {
    this.maxSeq = Store.getMaxSeq();
    this.msgCount = Store.getMessages().length;
    this.lastSync = PollService.lastSyncAt;
    this.boundTail = Store.getBoundTail();
  }

  async loadBindStatus(): Promise<void> {
    const res = await ApiClient.get<BindStatusData>('/api/relay/bind/status');
    if (res.ok && res.data !== undefined) {
      this.boundKnown = true;
      this.bound = res.data.bound;
      this.boundTail = res.data.bound ? (res.data.user_openid_tail ?? '') : '';
      Store.setBoundTail(this.boundTail);
    } else {
      this.boundKnown = false;
    }
  }

  bindText(): string {
    if (!this.boundKnown) {
      return this.boundTail.length > 0 ? '已绑定（本地缓存 ' + this.boundTail + '）' : '绑定状态未知（未连上服务端）';
    }
    if (!this.bound) {
      return '未绑定';
    }
    return this.boundTail.length > 0 ? '已绑定（' + this.boundTail + '）' : '已绑定';
  }

  async startRebind(): Promise<void> {
    this.stopBindPoll();
    this.pairCode = '';
    const cur = await ApiClient.get<BindStatusData>('/api/relay/bind/status');
    if (cur.ok && cur.data !== undefined) {
      this.boundKnown = true;
      this.bound = cur.data.bound;
      this.boundTail = cur.data.bound ? (cur.data.user_openid_tail ?? '') : '';
      this.baselineBoundAt = cur.data.bound ? (cur.data.bound_at ?? '') : '';
    } else {
      this.baselineBoundAt = '';
    }
    const body: BindCodeBody = {};
    const res = await ApiClient.post<BindCodeData>('/api/relay/bind/code', body);
    if (res.ok && res.data !== undefined) {
      this.pairCode = res.data.code;
      this.bindHint = res.data.hint;
      this.bindPollCount = 0;
      this.bindPhase = 'waiting';
      this.startBindPoll();
    } else {
      this.bindPhase = 'idle';
      this.getUIContext().getPromptAction().showToast({ message: res.error?.message ?? '生成配对码失败，请检查服务器地址' });
    }
  }

  startBindPoll(): void {
    this.stopBindPoll();
    this.bindTimerId = setInterval(() => {
      this.pollBindStatus();
    }, Config.bindPollIntervalMs);
  }

  stopBindPoll(): void {
    if (this.bindTimerId >= 0) {
      clearInterval(this.bindTimerId);
      this.bindTimerId = -1;
    }
  }

  async pollBindStatus(): Promise<void> {
    this.bindPollCount++;
    const res = await ApiClient.get<BindStatusData>('/api/relay/bind/status');
    if (res.ok && res.data !== undefined && res.data.bound) {
      const at: string = res.data.bound_at ?? '';
      const isNewBinding: boolean = this.baselineBoundAt.length === 0 || (at.length > 0 && at !== this.baselineBoundAt);
      if (isNewBinding) {
        this.stopBindPoll();
        this.boundKnown = true;
        this.bound = true;
        this.boundTail = res.data.user_openid_tail ?? '';
        Store.setBoundTail(this.boundTail);
        this.bindPhase = 'success';
        this.loadMyData();
      }
    } else if (this.bindPollCount >= Config.bindPollMaxTimes) {
      this.stopBindPoll();
      this.bindPhase = 'timeout';
    }
  }

  cancelRebind(): void {
    this.stopBindPoll();
    this.bindPhase = 'idle';
    this.pairCode = '';
  }

  async copyCode(): Promise<void> {
    if (this.pairCode.length === 0) {
      return;
    }
    try {
      const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.pairCode);
      const sp: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      await sp.setData(pasteData);
      this.getUIContext().getPromptAction().showToast({ message: '已复制配对码' });
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: '复制失败' });
    }
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

  async autoScan(): Promise<void> {
    this.scanning = true;
    this.getUIContext().getPromptAction().showToast({ message: '正在扫描局域网，约 5~10 秒…' });
    const found: string = await Discovery.autoFind();
    this.scanning = false;
    if (found.length > 0) {
      this.baseUrlInput = found;
      Store.setBaseUrl(found);
      PollService.stop();
      PollService.start();
      this.getUIContext().getPromptAction().showToast({ message: '已找到并切换到 ' + found });
    } else {
      this.getUIContext().getPromptAction().showToast({ message: '没找到电脑上的服务' });
    }
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
            Button(this.scanning ? '扫描中…' : '自动扫描局域网地址')
              .enabled(!this.scanning)
              .onClick(() => {
                this.autoScan();
              })
            Text('自动在手机所在的 Wi-Fi 网段里查找电脑上的后端（端口 ' + Config.discoveryPort + '）')
              .fontSize(12)
              .fontColor(Color.Gray)
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
            Text(this.bindText()).fontSize(13)
            Text('服务端数据概览：' + (this.myData.length > 0 ? this.myData : '加载中…')).fontSize(13)

            if (this.bindPhase === 'idle') {
              Button(this.bound ? '重新绑定 / 换号' : '去绑定 QQ')
                .onClick(() => {
                  this.startRebind();
                })
            } else if (this.bindPhase === 'waiting') {
              Text(this.pairCode)
                .fontSize(40)
                .fontWeight(FontWeight.Bold)
              Text(this.bindHint)
                .fontSize(14)
              Row({ space: 12 }) {
                Button('复制配对码')
                  .onClick(() => {
                    this.copyCode();
                  })
                Button('取消')
                  .onClick(() => {
                    this.cancelRebind();
                  })
              }
              Text(this.bound ? '当前已绑定，请用要换成的那个 QQ 号私聊机器人发送上面的配对码，发送后即换成新号（2 分钟内有效）' : '等待绑定中…请在 QQ 里私聊机器人发送上面的配对码（2 分钟内有效）')
                .fontSize(12)
                .fontColor(Color.Gray)
            } else if (this.bindPhase === 'success') {
              Text('绑定成功' + (this.boundTail.length > 0 ? '（' + this.boundTail + '）' : ''))
                .fontColor(Color.Green)
              Button('完成')
                .onClick(() => {
                  this.cancelRebind();
                })
            } else {
              Text('没检测到绑定，请重新生成配对码')
                .fontColor(Color.Orange)
              Button('重新生成配对码')
                .onClick(() => {
                  this.startRebind();
                })
            }
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
