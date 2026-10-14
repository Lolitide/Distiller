import { pasteboard } from '@kit.BasicServicesKit';
import { Config } from '../common/Config';
import { ApiClient } from '../common/ApiClient';
import { Store } from '../common/Store';
import { ApiResult, HealthData, RegisterData, BindCodeData, BindStatusData, RegisterBody, BindCodeBody } from '../common/Types';

@Entry
@Component
struct OnboardingPage {
  @State phase: string = 'checking';
  @State healthMsg: string = '';
  @State pairCode: string = '';
  @State bindHint: string = '';
  @State bindState: string = 'idle';
  @State boundTail: string = '';
  @State baseUrlInput: string = '';
  private bindTimerId: number = -1;
  private bindPollCount: number = 0;

  aboutToAppear(): void {
    Store.init(getContext(this));
    this.baseUrlInput = Store.getBaseUrl();
    this.checkHealth();
  }

  aboutToDisappear(): void {
    this.stopBindPoll();
  }

  async checkHealth(): Promise<void> {
    this.phase = 'checking';
    const res = await ApiClient.get<HealthData>('/api/relay/health');
    if (res.ok) {
      this.phase = 'connected';
      this.healthMsg = '已连接到后端的服务';
      await this.ensureIdentity();
      return;
    }
    this.phase = 'error';
    this.healthMsg = res.error?.message ?? '连不上服务器';
  }

  async ensureIdentity(): Promise<void> {
    if (Store.hasIdentity()) {
      const probe: ApiResult<BindStatusData> = await ApiClient.get<BindStatusData>('/api/relay/bind/status');
      if (probe.ok) {
        return;
      }
      const code: string = probe.error?.code ?? '';
      if (code !== 'unauthorized') {
        return;
      }
      Store.clearIdentity();
    }
    await this.registerDevice();
  }

  async registerDevice(): Promise<void> {
    const body: RegisterBody = { name: '' };
    const res = await ApiClient.post<RegisterData>('/api/relay/device/register', body);
    if (res.ok && res.data !== undefined) {
      Store.setIdentity(res.data.device_id, res.data.token);
    }
  }

  async generateCode(): Promise<void> {
    const body: BindCodeBody = {};
    const res = await ApiClient.post<BindCodeData>('/api/relay/bind/code', body);
    if (res.ok && res.data !== undefined) {
      this.pairCode = res.data.code;
      this.bindHint = res.data.hint;
      this.bindState = 'waiting';
      this.bindPollCount = 0;
      this.startBindPoll();
    } else {
      this.showToast(res.error?.message ?? '生成配对码失败');
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
      this.stopBindPoll();
      this.bindState = 'success';
      this.boundTail = res.data.user_openid_tail ?? '';
      Store.setBoundTail(this.boundTail);
    } else if (this.bindPollCount >= Config.bindPollMaxTimes) {
      this.stopBindPoll();
      this.bindState = 'timeout';
    }
  }

  async copyCode(): Promise<void> {
    if (this.pairCode.length === 0) {
      return;
    }
    try {
      const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.pairCode);
      const sp: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      await sp.setData(pasteData);
      this.showToast('已复制配对码');
    } catch (e) {
      this.showToast('复制失败');
    }
  }

  showToast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  goHome(): void {
    this.getUIContext().getRouter().replaceUrl({ url: 'pages/HomePage' });
  }

  goGroups(): void {
    this.getUIContext().getRouter().replaceUrl({ url: 'pages/GroupSubPage' });
  }

  saveAndRetry(): void {
    if (this.baseUrlInput.length === 0) {
      this.showToast('地址不能为空');
      return;
    }
    Store.setBaseUrl(this.baseUrlInput);
    this.checkHealth();
  }

  build() {
    Column({ space: 16 }) {
      Text('机器人通道 · 首次设置')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      if (this.phase === 'checking') {
        Text('正在连接电脑上的服务…')
      } else if (this.phase === 'error') {
        Text(this.healthMsg)
          .fontColor(Color.Red)
        Text('当前地址：' + Config.baseUrl)
          .fontSize(12)
        TextInput({ placeholder: 'https://你的穿透地址', text: this.baseUrlInput })
          .onChange((value: string) => {
            this.baseUrlInput = value;
          })
          .width('100%')
        Button('保存地址并重试')
          .onClick(() => {
            this.saveAndRetry();
          })
        Text('请手动填入后端地址（内网穿透的固定地址）。为安全起见不再自动扫描局域网。')
          .fontSize(12)
          .fontColor(Color.Gray)
        Button('重试')
          .onClick(() => {
            this.checkHealth();
          })
      } else {
        Text(this.healthMsg)
          .fontColor(Color.Green)

        if (this.bindState === 'idle') {
          Button('绑定 QQ')
            .onClick(() => {
              this.generateCode();
            })
        } else if (this.bindState === 'waiting') {
          Text(this.pairCode)
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
          Text(this.bindHint)
            .fontSize(14)
          Button('复制配对码')
            .onClick(() => {
              this.copyCode();
            })
          Text('等待绑定中…')
            .fontSize(12)
            .fontColor(Color.Gray)
        } else if (this.bindState === 'success') {
          Text('绑定成功' + (this.boundTail.length > 0 ? '（' + this.boundTail + '）' : ''))
            .fontColor(Color.Green)
          Button('下一步')
            .onClick(() => {
              this.goGroups();
            })
        } else {
          Text('没检测到绑定，请重新生成配对码')
            .fontColor(Color.Orange)
          Button('重新生成配对码')
            .onClick(() => {
              this.generateCode();
            })
        }

        Button('先跳过，稍后绑定')
          .onClick(() => {
            this.goHome();
          })
      }
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .justifyContent(FlexAlign.Center)
  }
}
