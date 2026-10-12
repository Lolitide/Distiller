import { PollService } from '../service/PollService';
import { Store } from '../common/Store';
import { RobotMessage, DetailParams, ParsedEntity, formatTime, hasImageAttachment } from '../common/Types';
import { EntityIcon } from '../common/UiParts';
import { CampusEvent, isActionable, EVENT_NOTICE, EVENT_PLAN, EVENT_TODO } from '../nlp/EventTypes';
import { timeSlotDisplay } from '../nlp/TimeParser';
import { clusterEvents, EventCluster } from '../nlp/EventCluster';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'HomePage';

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
  /** T3 汇总：把零散消息聚成若干事件 */
  @State digest: EventCluster[] = [];
  private statusTimer: number = -1;
  private bannerTimer: number = -1;
  private digestSig: string = '';

  aboutToAppear(): void {
    this.messages = Store.getMessages();
    this.hideSelf = Store.getHideSelf();
    this.refreshDigest();
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
    this.refreshDigest();
  }

  /** T3：把当前可见消息的事件聚成簇，取最有信息量的前几条做「群汇总」 */
  refreshDigest(): void {
    const list: RobotMessage[] = this.visibleMessages();
    const evs: CampusEvent[] = [];
    for (let i = 0; i < list.length; i++) {
      const e: CampusEvent | undefined = list[i].event;
      if (e !== undefined) {
        evs.push(e);
      }
    }
    const clusters: EventCluster[] = clusterEvents(evs);
    const picked: EventCluster[] = [];
    for (let i = 0; i < clusters.length; i++) {
      const c: EventCluster = clusters[i];
      // 单条闲聊不算「事件」，不进汇总
      if (c.kind === '闲聊' && c.count < 2) {
        continue;
      }
      picked.push(c);
    }
    // 待办/通知/出行计划优先，其次按条数、置信度
    picked.sort((a: EventCluster, b: EventCluster): number => {
      const pa: number = isActionable(a.kind) ? 0 : 1;
      const pb: number = isActionable(b.kind) ? 0 : 1;
      if (pa !== pb) {
        return pa - pb;
      }
      if (a.count !== b.count) {
        return b.count - a.count;
      }
      return b.confidence - a.confidence;
    });
    this.digest = picked.slice(0, 3);
    // 只在汇总内容变化时打一条日志，便于排查又不刷屏
    let sig: string = '';
    for (let i = 0; i < this.digest.length; i++) {
      const c: EventCluster = this.digest[i];
      sig += c.kind + ':' + c.title + ':' + c.count + ' | ';
    }
    if (sig !== this.digestSig) {
      this.digestSig = sig;
      hilog.info(DOMAIN, TAG, 'digest changed: %{public}s', sig);
    }
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

  summaryText(item: RobotMessage): string {
    return item.summary ?? '';
  }

  categoryText(item: RobotMessage): string {
    return item.category ?? '';
  }

  entityListFor(item: RobotMessage): ParsedEntity[] {
    const list: ParsedEntity[] = item.entities ?? [];
    return list.length > 4 ? list.slice(0, 4) : list;
  }

  isPending(item: RobotMessage): boolean {
    return item.parsedAt === undefined || item.parsedAt.length === 0;
  }

  /**
   * ForEach 的 key：必须包含会影响列表项渲染的状态。
   * 若只用 msg_id，解析完成/已读/已处理发生变化时 key 不变，ArkUI 会复用旧节点而不重建，
   * 导致列表项一直停留在「解析中…」。
   */
  itemKey(item: RobotMessage): string {
    const parsedMark: string = item.parsedAt ?? '';
    const readMark: string = item.read ? '1' : '0';
    const handledMark: string = item.handled ? '1' : '0';
    const imageMark: string = item.imageText ?? '';
    const kindMark: string = item.imageKind ?? '';
    const evMark: string = (item.event?.kind ?? '') + '#' + this.evConf(item);
    return item.msg_id + '|' + parsedMark + '|' + readMark + '|' + handledMark + '|' + imageMark
      + '|' + kindMark + '|' + evMark;
  }

  hasImage(item: RobotMessage): boolean {
    return hasImageAttachment(item.attachments);
  }

  imageLabel(item: RobotMessage): string {
    return item.imageKind === 'qr' ? '二维码' : '图片';
  }

  /** 这条消息是否做成了结构化事件卡片 */
  hasEventCard(item: RobotMessage): boolean {
    const e: CampusEvent | undefined = item.event;
    return e !== undefined && isActionable(e.kind);
  }

  evKind(item: RobotMessage): string {
    return item.event?.kind ?? '';
  }

  evTitle(item: RobotMessage): string {
    return item.event?.title ?? '';
  }

  evTimeText(item: RobotMessage): string {
    const e: CampusEvent | undefined = item.event;
    if (e === undefined || e.time === null) {
      return '';
    }
    return timeSlotDisplay(e.time);
  }

  evPlace(item: RobotMessage): string {
    return item.event?.place ?? '';
  }

  evDeadline(item: RobotMessage): string {
    return item.event?.deadline ?? '';
  }

  evSource(item: RobotMessage): string {
    return item.event?.sourceText ?? '';
  }

  evConf(item: RobotMessage): number {
    return item.event?.confidence ?? 0;
  }

  evNeedConfirm(item: RobotMessage): boolean {
    return this.evConf(item) < 0.5;
  }

  evConfText(item: RobotMessage): string {
    const c: number = this.evConf(item);
    if (c >= 0.8) {
      return '高置信';
    }
    return c >= 0.5 ? c.toFixed(2) : '待确认';
  }

  evConfColor(item: RobotMessage): string {
    const c: number = this.evConf(item);
    if (c >= 0.8) {
      return '#3E9E6B';
    }
    return c >= 0.5 ? '#888888' : '#C1663D';
  }

  evKindColor(item: RobotMessage): string {
    const k: string = this.evKind(item);
    if (k === EVENT_TODO) {
      return '#2E75B6';
    }
    if (k === EVENT_NOTICE) {
      return '#B8434E';
    }
    if (k === EVENT_PLAN) {
      return '#2F8F9D';
    }
    return '#8A5CC7';
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
    this.refreshDigest();
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
            if (this.digest.length > 0) {
              ListItem() {
                Column({ space: 6 }) {
                  Row() {
                    Text('群汇总')
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .layoutWeight(1)
                    Text(this.messages.length + ' 条消息')
                      .fontSize(12)
                      .fontColor(Color.Gray)
                  }
                  .width('100%')

                  ForEach(this.digest, (c: EventCluster, index: number) => {
                    Row({ space: 6 }) {
                      Text(c.kind)
                        .fontSize(10)
                        .fontColor(Color.White)
                        .backgroundColor('#8A5CC7')
                        .borderRadius(3)
                        .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                      Text(c.title)
                        .fontSize(13)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1)
                      Text(c.count + ' 条')
                        .fontSize(11)
                        .fontColor(Color.Gray)
                    }
                    .width('100%')
                  }, (c: EventCluster, index: number) => index + '_' + c.kind + '_' + c.title)
                }
                .width('100%')
                .padding(12)
                .alignItems(HorizontalAlign.Start)
                .backgroundColor('#F5F3FA')
                .borderRadius(8)
              }
            }

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

                  if (this.hasEventCard(item)) {
                    Row({ space: 6 }) {
                      Text(this.evKind(item))
                        .fontSize(11)
                        .fontColor(Color.White)
                        .backgroundColor(this.evKindColor(item))
                        .borderRadius(4)
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      if (this.hasImage(item)) {
                        Text(this.imageLabel(item))
                          .fontSize(11)
                          .fontColor('#2E75B6')
                          .backgroundColor('#EAF1FA')
                          .borderRadius(4)
                          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      }
                      Text(this.evTitle(item))
                        .fontSize(15)
                        .fontWeight(FontWeight.Medium)
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1)
                      Text(this.evConfText(item))
                        .fontSize(11)
                        .fontColor(this.evConfColor(item))
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Top)

                    if (this.evTimeText(item).length > 0) {
                      Row({ space: 4 }) {
                        EntityIcon({ type: 'datetime', size: 13, color: '#2E75B6' })
                        Text(this.evTimeText(item))
                          .fontSize(12)
                          .fontColor('#333333')
                          .layoutWeight(1)
                      }
                      .width('100%')
                    }
                    if (this.evPlace(item).length > 0) {
                      Row({ space: 4 }) {
                        EntityIcon({ type: 'location', size: 13, color: '#2E75B6' })
                        Text(this.evPlace(item))
                          .fontSize(12)
                          .fontColor('#333333')
                          .layoutWeight(1)
                      }
                      .width('100%')
                    }
                    if (this.evDeadline(item).length > 0) {
                      Text('截止：' + this.evDeadline(item))
                        .fontSize(12)
                        .fontColor('#B8434E')
                        .width('100%')
                    }
                    if (this.evNeedConfirm(item)) {
                      Text('字段不完整，建议人工确认')
                        .fontSize(11)
                        .fontColor('#C1663D')
                        .width('100%')
                    }
                    Text('「' + this.evSource(item) + '」')
                      .fontSize(12)
                      .fontColor('#888888')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                  } else if (this.isPending(item)) {
                    Text('解析中…')
                      .fontSize(14)
                      .fontColor(Color.Gray)
                      .width('100%')
                  } else if (this.hasImage(item) && this.evSource(item).length === 0) {
                    Text('[图片] 未识别出文字')
                      .fontSize(14)
                      .fontColor(Color.Gray)
                      .width('100%')
                  } else {
                    if (this.evKind(item).length > 0) {
                      Row({ space: 6 }) {
                        Text(this.evKind(item))
                          .fontSize(11)
                          .fontColor('#888888')
                          .backgroundColor('#F0F0F0')
                          .borderRadius(4)
                          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      }
                    }
                    Text(this.evSource(item).length > 0 ? this.evSource(item) : item.content)
                      .fontSize(14)
                      .fontColor('#666666')
                      .maxLines(3)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                  }

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
            }, (item: RobotMessage) => this.itemKey(item))
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
