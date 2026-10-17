import { PollService } from '../service/PollService';
import { FeedbackService, ACTION_ACCEPT, ACTION_DISMISS } from '../service/FeedbackService';
import { Store } from '../common/Store';
import { RobotMessage, DetailParams, ParsedEntity, formatTime, hasImageAttachment, fileAttachmentLabel, dueLabel, repeatLabel, dueAtOf } from '../common/Types';
import { EntityIcon, safePush, safeReplace, safeToast } from '../common/UiParts';
import { CampusEvent, CandidateStep, isActionable, EVENT_NOTICE, EVENT_PLAN, EVENT_TODO, EVENT_ACTIVITY, EVENT_CHAT, PRIORITY_IMPORTANT, PRIORITY_URGENT } from '../nlp/EventTypes';
import { timeSlotDisplay } from '../nlp/TimeParser';
import { clusterEvents, pickDigestClusters, EventCluster } from '../nlp/EventCluster';
import { clip } from '../nlp/TextUtil';
import { BottomNav } from '../common/BottomNav';
import { common } from '@kit.AbilityKit';
import { NotificationService } from '../service/NotificationService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'HomePage';

function pad2(n: number): string {
  return n < 10 ? '0' + n : '' + n;
}

@Entry
@Component
struct HomePage {
  @StorageLink('msgVersion') @Watch('onVersionChanged') msgVersion: number = 0;
  @StorageLink('needOnboarding') @Watch('onNeedOnboarding') needOnboarding: boolean = false;
  @StorageLink('newMsgBanner') @Watch('onBannerChanged') newMsgBanner: string = '';
  /** 通知点进来要看的消息 id（EntryAbility 写入，这里消费后清空） */
  @StorageLink('pendingMsgId') @Watch('onPendingMsg') pendingMsgId: string = '';
  @State messages: RobotMessage[] = [];
  @State statusText: string = '';
  @State refreshing: boolean = false;
  @State hideSelf: boolean = false;
  /** 副卡片折叠状态（按 msg_id 记；默认展开，点「收起」才进这个数组） */
  @State collapsedIds: string[] = [];
  /** 筛选：类别芯片（'' = 全部）+ 关键词（标题/摘要/正文）——纯前端就够，个人数据量小 */
  @State filterKind: string = '';
  @State keyword: string = '';
  /** T3 汇总：把零散消息聚成若干事件 */
  @State digest: EventCluster[] = [];
  /** 汇总里总共有多少个事件（卡片只展示前 3 个） */
  @State digestTotal: number = 0;
  private statusTimer: number = -1;
  private bannerTimer: number = -1;
  private digestSig: string = '';

  /** 通知授权状态：关着的话列表顶部给一条「去开启」的入口 */
  @State notifyOn: boolean = true;

  aboutToAppear(): void {
    this.messages = Store.getMessages();
    this.hideSelf = Store.getHideSelf();
    this.refreshDigest();
    PollService.start();
    this.updateStatus();
    this.refreshNotifyState();
    // 冷启动时通知点进来的（EntryAbility 已把 msgId 放进 AppStorage，@Watch 不会补触发）
    this.onPendingMsg();
    this.statusTimer = setInterval(() => {
      this.updateStatus();
    }, 10000);
  }

  /** 刷新通知授权状态（进页面、从系统设置回来时都要重查）。 */
  refreshNotifyState(): void {
    NotificationService.isEnabled().then((on: boolean) => {
      this.notifyOn = on;
    });
  }

  /**
   * 「去开启」：先走**授权弹窗**（`requestEnableNotification`，只在用户还没拒过时才会弹），
   * 拿不到再退到系统「通知管理」面板——被拒过一次后授权弹窗再也弹不出来，只能去面板开。
   */
  async openNotifySettings(): Promise<void> {
    const ctx: Context | null = Store.getAppContext();
    if (ctx === null) {
      return;
    }
    const abilityCtx: common.UIAbilityContext = ctx as common.UIAbilityContext;
    let on: boolean = await NotificationService.ensureEnabled(abilityCtx);
    if (!on) {
      on = await NotificationService.openSettings(abilityCtx);
    }
    this.notifyOn = on;
    safeToast(this.getUIContext(), on
      ? '通知已开启；想让它弹横幅，还要在通知设置里把「横幅」打开'
      : '还没开启通知，待办提醒收不到');
  }

  /**
   * 通知点击 → 跳该条详情。
   * `EntryAbility.takeWant` 只负责把 msgId 放进 `pendingMsgId`，跳转在这里做：
   * 页面自己的 UIContext 一定可用，冷启动/热启动都稳。
   */
  onPendingMsg(): void {
    if (this.pendingMsgId.length === 0) {
      return;
    }
    const id: string = this.pendingMsgId;
    AppStorage.setOrCreate<string>('pendingMsgId', '');
    const params: DetailParams = { msgId: id };
    safePush(this.getUIContext(), 'pages/MessageDetailPage', params);
  }

  onPageShow(): void {
    // 从设置页返回时重新读取显示开关，立即生效
    this.hideSelf = Store.getHideSelf();
    this.messages = Store.getMessages();
    this.refreshDigest();
    this.refreshNotifyState();
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
    const picked: EventCluster[] = pickDigestClusters(clusters);
    this.digestTotal = picked.length;
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

  /** 类别筛选芯片 */
  kindFilters(): string[] {
    return ['', EVENT_TODO, EVENT_NOTICE, EVENT_ACTIVITY, EVENT_PLAN, EVENT_CHAT];
  }

  kindLabel(value: string): string {
    return value.length === 0 ? '全部' : value;
  }

  /** 当前有没有在用筛选（类别或关键词）。 */
  filterActive(): boolean {
    return this.filterKind.length > 0 || this.keyword.trim().length > 0;
  }

  clearFilter(): void {
    this.filterKind = '';
    this.keyword = '';
  }

  /** 这条消息过不过当前的筛选（类别 + 关键词）。 */
  matchFilter(item: RobotMessage): boolean {
    if (this.filterKind.length > 0) {
      const k: string = item.event?.kind ?? item.parse?.kind ?? '';
      if (k !== this.filterKind) {
        return false;
      }
    }
    const kw: string = this.keyword.trim();
    if (kw.length === 0) {
      return true;
    }
    const bag: string = (item.event?.title ?? '') + ' ' + (item.summary ?? '') + ' '
      + (item.event?.sourceText ?? '') + ' ' + (item.content ?? '');
    return bag.indexOf(kw) >= 0;
  }

  visibleMessages(): RobotMessage[] {
    const out: RobotMessage[] = [];
    for (let i = 0; i < this.messages.length; i++) {
      // 用户明确「忽略」过的不再出现在列表里（数据保留在本地）
      if (this.messages[i].dismissed === true) {
        continue;
      }
      if (this.hideSelf && this.messages[i].is_self === true) {
        continue;
      }
      if (!this.matchFilter(this.messages[i])) {
        continue;
      }
      out.push(this.messages[i]);
    }
    // 排序（《任务字段表》§2.3）：priority 降序 -> level 降序 -> 时间近的在前。
    // level 刻意**不跨档翻盘**：卡片上唯一可见的排序信号是 priority 那个红圈，
    // 若难度能跨档，用户会看到「红圈少的排前面」，以为排序坏了。
    out.sort((a: RobotMessage, b: RobotMessage): number => {
      const pa: number = this.priorityOf(a);
      const pb: number = this.priorityOf(b);
      if (pa !== pb) {
        return pb - pa;
      }
      const la: number = a.event?.level ?? 1;
      const lb: number = b.event?.level ?? 1;
      if (la !== lb) {
        return lb - la;
      }
      const da: number = this.dueAtOfItem(a);
      const db: number = this.dueAtOfItem(b);
      if (da > 0 && db > 0 && da !== db) {
        return da - db;
      }
      return (b.timestamp ?? '').localeCompare(a.timestamp ?? '');
    });
    return out;
  }

  // ---------------------------------------------------------------- 卡片字段

  /** 0 普通 / 1 重要 / 2 紧急（卡片上那个红圈）。 */
  priorityOf(item: RobotMessage): number {
    return item.event?.priority ?? 0;
  }

  dueAtOfItem(item: RobotMessage): number {
    const e: CampusEvent | undefined = item.event;
    if (e === undefined) {
      return 0;
    }
    if (e.dueAt !== undefined && e.dueAt > 0) {
      return e.dueAt;
    }
    return dueAtOf(e.time?.normalized ?? '');
  }

  /** 第二行里那段截止文案（今天/明天/后天/N 天后/__h 后/已过期）。 */
  cardDueText(item: RobotMessage): string {
    if (item.done === true) {
      return this.doneText(item);
    }
    return dueLabel(this.dueAtOfItem(item), Date.now());
  }

  doneText(item: RobotMessage): string {
    const at: number = item.doneAt ?? 0;
    if (at <= 0) {
      return '已完成';
    }
    const d: Date = new Date(at);
    return '完成于 ' + pad2(d.getMonth() + 1) + '.' + pad2(d.getDate())
      + ' ' + pad2(d.getHours()) + ':' + pad2(d.getMinutes());
  }

  /** 第二行最多放两个标签胶囊（再多卡片就挤了）。 */
  cardTags(item: RobotMessage): string[] {
    const all: string[] = item.event?.tags ?? [];
    const out: string[] = [];
    for (let i = 0; i < all.length && out.length < 2; i++) {
      if (all[i].length > 0) {
        out.push(all[i]);
      }
    }
    return out;
  }

  cardRepeat(item: RobotMessage): string {
    const e: CampusEvent | undefined = item.event;
    if (e === undefined) {
      return '';
    }
    return repeatLabel(e.repeat, e.repeatText ?? '');
  }

  /** 有截止时刻才给提醒开关（没有时间的任务没法定提醒点）。 */
  canAlarm(item: RobotMessage): boolean {
    return this.dueAtOfItem(item) > 0;
  }

  stepsOf(item: RobotMessage): CandidateStep[] {
    return item.event?.steps ?? [];
  }

  hasSteps(item: RobotMessage): boolean {
    return this.stepsOf(item).length > 0;
  }

  stepsDoneCount(item: RobotMessage): number {
    const list: CandidateStep[] = this.stepsOf(item);
    let n: number = 0;
    for (let i = 0; i < list.length; i++) {
      if (list[i].done === 1) {
        n++;
      }
    }
    return n;
  }

  /** 副卡片默认展开；只有点过「收起」的才记在 collapsedIds 里。 */
  isExpanded(msgId: string): boolean {
    return this.collapsedIds.indexOf(msgId) < 0;
  }

  toggleExpanded(msgId: string): void {
    const next: string[] = [];
    let found: boolean = false;
    for (let i = 0; i < this.collapsedIds.length; i++) {
      if (this.collapsedIds[i] === msgId) {
        found = true;
      } else {
        next.push(this.collapsedIds[i]);
      }
    }
    if (!found) {
      next.push(msgId);
    }
    this.collapsedIds = next;
  }

  cardName(item: RobotMessage): string {
    const e: CampusEvent | undefined = item.event;
    if (e !== undefined && e.title.length > 0) {
      return e.title;
    }
    const t: string = (item.content ?? '').trim();
    return t.length > 0 ? t : this.fileLabel(item);
  }

  isOverdue(item: RobotMessage): boolean {
    if (item.done === true) {
      return false;
    }
    const d: number = this.dueAtOfItem(item);
    return d > 0 && d < Date.now();
  }

  // ---------------------------------------------------------------- 卡片操作

  /** 改一条消息的本地状态并落库（只动这一条）。 */
  private patchMessage(msgId: string, patch: (m: RobotMessage) => void): void {
    const list: RobotMessage[] = Store.getMessages();
    let changed: boolean = false;
    for (let i = 0; i < list.length; i++) {
      if (list[i].msg_id === msgId) {
        patch(list[i]);
        changed = true;
      }
    }
    if (changed) {
      Store.saveMessages(list);
      for (let i = 0; i < this.messages.length; i++) {
        if (this.messages[i].msg_id === msgId) {
          patch(this.messages[i]);
        }
      }
      AppStorage.setOrCreate<number>('msgVersion', (AppStorage.get<number>('msgVersion') ?? 0) + 1);
    }
  }

  toggleDone(item: RobotMessage): void {
    const next: boolean = item.done !== true;
    this.patchMessage(item.msg_id, (m: RobotMessage) => {
      m.done = next;
      m.doneAt = next ? Date.now() : 0;
    });
  }

  toggleAlarm(item: RobotMessage): void {
    const next: boolean = item.alarm !== true;
    this.patchMessage(item.msg_id, (m: RobotMessage) => {
      m.alarm = next;
    });
    safeToast(this.getUIContext(), next ? '已打开提醒' : '已关闭提醒');
  }

  toggleStep(item: RobotMessage, index: number): void {
    this.patchMessage(item.msg_id, (m: RobotMessage) => {
      const e: CampusEvent | undefined = m.event;
      if (e === undefined || e.steps === undefined) {
        return;
      }
      if (index < 0 || index >= e.steps.length) {
        return;
      }
      e.steps[index].done = e.steps[index].done === 1 ? 0 : 1;
    });
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
    // 卡片字段：勾选/提醒/重要性/步骤变了都必须换 key，否则 ArkUI 复用旧节点
    const cardMark: string = (item.done ? '1' : '0') + (item.alarm ? '1' : '0')
      + '#' + this.priorityOf(item) + '#' + this.stepsDoneCount(item) + '#' + this.stepsOf(item).length
      + '#' + (item.doneAt ?? 0);
    return item.msg_id + '|' + parsedMark + '|' + readMark + '|' + handledMark + '|' + imageMark
      + '|' + kindMark + '|' + evMark + '|' + cardMark;
  }

  hasImage(item: RobotMessage): boolean {
    return hasImageAttachment(item.attachments);
  }

  imageLabel(item: RobotMessage): string {
    return item.imageKind === 'qr' ? '二维码' : '图片';
  }

  /** 文件附件的展示标签：QQ 文件消息 content 为空，正文就是附件本身（name + 体积）。 */
  fileLabel(item: RobotMessage): string {
    return fileAttachmentLabel(item.attachments);
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

  /** 需带物品 / 注意事项：由后端小模型抽取（每条都是原文子串），拼成一行 */
  evItems(item: RobotMessage): string {
    const arr: string[] = item.event?.items ?? [];
    return arr.join('、');
  }

  evSource(item: RobotMessage): string {
    return item.event?.sourceText ?? '';
  }

  /** 列表正文：图片消息优先显示识别文字的「摘要」，其次事件原话，最后才是原文（都做长度截断） */
  displayText(item: RobotMessage): string {
    const imgSummary: string = item.imageSummary ?? '';
    if (imgSummary.length > 0) {
      return clip(imgSummary);
    }
    const src: string = this.evSource(item);
    return clip(src.length > 0 ? src : item.content);
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
      safeReplace(this.getUIContext(), 'pages/OnboardingPage');
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
    safePush(this.getUIContext(), 'pages/MessageDetailPage', p);
  }

  openDigest(): void {
    safePush(this.getUIContext(), 'pages/DigestPage');
  }

  handleToTask(item: RobotMessage): void {
    Store.markAsTaskSource(item);
    this.setHandled(item.msg_id);
    // 接受候选：本地先行，反馈异步回传（后端只记计数；老后端自动跳过）
    FeedbackService.send(item, ACTION_ACCEPT);
    safeToast(this.getUIContext(), '已交给解析');
  }

  /** 忽略候选：本地从列表隐藏 + dismiss 回传 */
  dismissMessage(item: RobotMessage): void {
    Store.setDismissed(item.msg_id);
    this.bumpVersion();
    FeedbackService.send(item, ACTION_DISMISS);
    safeToast(this.getUIContext(), '已忽略');
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
    safePush(this.getUIContext(), 'pages/GroupSubPage');
  }

  goAddTask(): void {
    safePush(this.getUIContext(), 'pages/AddTaskPage');
  }

  /** 筛选条：类别芯片 + 关键词搜索（都在本机算，不发请求）。 */
  @Builder
  filterBar() {
    Column({ space: 8 }) {
      TextInput({ text: this.keyword, placeholder: '搜索标题 / 内容' })
        .fontSize(14)
        .height(36)
        .width('100%')
        .onChange((v: string) => {
          this.keyword = v;
        })
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.kindFilters(), (k: string) => {
          Text(this.kindLabel(k))
            .fontSize(12)
            .fontColor(this.filterKind === k ? Color.White : '#666666')
            .backgroundColor(this.filterKind === k ? '#2E75B6' : '#F0F0F0')
            .borderRadius(10)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .margin({ right: 6, bottom: 6 })
            .onClick(() => {
              this.filterKind = k;
            })
        }, (k: string) => k)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 4 })
  }

  /**
   * 重要性标识（《任务字段表》§2.1）：
   *   priority 1 -> 红圈 + 红感叹号；2 -> 红实心圆 + 白感叹号；0 不显示。
   */
  @Builder
  priorityBadge(p: number) {
    Text('!')
      .fontSize(11)
      .fontWeight(FontWeight.Bold)
      .fontColor(p >= PRIORITY_URGENT ? Color.White : '#D93025')
      .width(16)
      .height(16)
      .borderRadius(8)
      .textAlign(TextAlign.Center)
      .backgroundColor(p >= PRIORITY_URGENT ? '#D93025' : Color.Transparent)
      .border({ width: 1.5, color: '#D93025' })
  }

  /** 副卡片：步骤列表 + 每步勾选 + 折叠（《任务字段表》§2.4，打卡进度条不在 MVP）。 */
  @Builder
  stepsCard(item: RobotMessage) {
    Column({ space: 6 }) {
      Row({ space: 6 }) {
        Text('步骤 ' + this.stepsDoneCount(item) + '/' + this.stepsOf(item).length)
          .fontSize(12)
          .fontColor('#5C6673')
          .layoutWeight(1)
        Text(this.isExpanded(item.msg_id) ? '收起' : '展开')
          .fontSize(12)
          .fontColor('#2E75B6')
          .onClick(() => {
            this.toggleExpanded(item.msg_id);
          })
      }
      .width('100%')

      if (this.isExpanded(item.msg_id)) {
        ForEach(this.stepsOf(item), (s: CandidateStep, index: number) => {
          Row({ space: 8 }) {
            Text(s.done === 1 ? '✓' : '')
              .width(18)
              .height(18)
              .borderRadius(9)
              .border({ width: 1, color: s.done === 1 ? '#2E75B6' : '#C4CAD2' })
              .textAlign(TextAlign.Center)
              .fontSize(11)
              .fontColor('#2E75B6')
              .onClick(() => {
                this.toggleStep(item, index);
              })
            Text(s.content)
              .fontSize(13)
              .fontColor(s.done === 1 ? '#9AA0A6' : '#3C4652')
              .decoration({
                type: s.done === 1 ? TextDecorationType.LineThrough : TextDecorationType.None
              })
              .layoutWeight(1)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
        }, (s: CandidateStep, index: number) => item.msg_id + '#' + index + '#' + s.done)
      }
    }
    .width('100%')
    .padding({ left: 36, top: 2 })
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Text('机器人消息')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Button('＋ 添加')
          .fontSize(12)
          .onClick(() => {
            this.goAddTask();
          })
        Button('订阅管理')
          .fontSize(12)
          .onClick(() => {
            this.goSubs();
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

      // 通知被拒过就再也弹不出授权框：这里给一条常驻入口，点它去系统里打开
      if (!this.notifyOn) {
        Column({ space: 2 }) {
          Row({ space: 8 }) {
            Text('通知未开启 —— 待办来了提醒不到你')
              .fontSize(12)
              .fontColor('#8A5CC7')
              .layoutWeight(1)
            Text('去开启 ›')
              .fontSize(12)
              .fontColor('#2E75B6')
              .onClick(() => {
                this.openNotifySettings();
              })
          }
          .width('100%')
          Text('（开启后若要弹横幅，还要在通知设置里把「横幅」打开）')
            .fontSize(11)
            .fontColor('#999999')
            .width('100%')
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 4 })
      }

      // 筛选栏常驻（只要收到过消息）：选完芯片 / 搜完词结果为空时也必须留着，
      // 否则整块被空状态替换，用户点不回「全部」——这就是「选中一个 tag 筛选栏就没了」的根因。
      if (this.messages.length > 0) {
        this.filterBar()
      }

      if (this.visibleMessages().length === 0) {
        Column({ space: 12 }) {
          Text(this.filterActive()
            ? '没有符合筛选条件的消息'
            : (this.hideSelf && this.messages.length > 0 ? '你已隐藏自己发的消息，暂无其他消息' : '还没有收到消息'))
            .fontSize(16)
            .fontColor(Color.Gray)
          if (this.filterActive()) {
            Button('清除筛选')
              .onClick(() => {
                this.clearFilter();
              })
          } else {
            Text('请确认机器人已在群里收到过消息')
              .fontSize(12)
              .fontColor(Color.Gray)
            Button('去订阅群')
              .onClick(() => {
                this.goSubs();
              })
          }
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
                    Text(this.digestTotal + ' 个事件 · ' + this.messages.length + ' 条消息')
                      .fontSize(12)
                      .fontColor(Color.Gray)
                    Text('查看全部 ›')
                      .fontSize(12)
                      .fontColor('#2E75B6')
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
                .onClick(() => {
                  this.openDigest();
                })
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
                    // ---- 主卡片（两行，无第三行）----
                    // 左：完成圆圈 / 中：任务名 + 第二行四样 / 右：提醒铃
                    Row({ space: 10 }) {
                      Text(item.done === true ? '✓' : '')
                        .width(26)
                        .height(26)
                        .borderRadius(13)
                        .border({
                          width: 1.5,
                          color: item.done === true ? '#2E75B6' : '#C4CAD2',
                          style: item.done === true ? BorderStyle.Solid : BorderStyle.Dashed
                        })
                        .textAlign(TextAlign.Center)
                        .fontSize(15)
                        .fontColor('#2E75B6')
                        .onClick(() => {
                          this.toggleDone(item);
                        })

                      Column({ space: 5 }) {
                        // 第一行：任务名
                        Text(this.cardName(item))
                          .fontSize(15)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(item.done === true ? '#9AA0A6' : '#1F2A37')
                          .decoration({
                            type: item.done === true
                              ? TextDecorationType.LineThrough : TextDecorationType.None
                          })
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .width('100%')

                        // 第二行：标签胶囊 → 重要性 → 截止 → 重复
                        Row({ space: 6 }) {
                          ForEach(this.cardTags(item), (t: string) => {
                            Text(t)
                              .fontSize(11)
                              .fontColor('#2E75B6')
                              .backgroundColor('#EAF1FA')
                              .borderRadius(9)
                              .padding({ left: 7, right: 7, top: 1, bottom: 1 })
                          }, (t: string) => item.msg_id + '#' + t)

                          if (this.priorityOf(item) > 0) {
                            this.priorityBadge(this.priorityOf(item))
                          }

                          if (this.cardDueText(item).length > 0) {
                            Text(this.cardDueText(item))
                              .fontSize(12)
                              .fontColor(item.done === true ? '#9AA0A6'
                                : (this.isOverdue(item) ? '#B8434E' : '#5C6673'))
                              .layoutWeight(1)
                              .maxLines(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                          }

                          if (this.cardRepeat(item).length > 0) {
                            Text(this.cardRepeat(item))
                              .fontSize(11)
                              .fontColor('#7A5AA8')
                              .maxLines(1)
                          }
                        }
                        .width('100%')
                        .alignItems(VerticalAlign.Center)
                      }
                      .layoutWeight(1)
                      .alignItems(HorizontalAlign.Start)

                      // 右：提醒开关（没有截止时刻就不显示整个铃铛）
                      if (this.canAlarm(item)) {
                        Text(item.alarm === true ? '🔔' : '🔕')
                          .fontSize(18)
                          .opacity(item.alarm === true ? 1 : 0.4)
                          .onClick(() => {
                            this.toggleAlarm(item);
                          })
                      }
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Top)

                    // ---- 副卡片：步骤（有步骤才出现）----
                    if (this.hasSteps(item)) {
                      this.stepsCard(item)
                    }

                    Text('「' + this.evSource(item) + '」')
                      .fontSize(12)
                      .fontColor('#888888')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                  } else if (this.fileLabel(item).length > 0 && this.displayText(item).length === 0) {
                    Text(this.fileLabel(item))
                      .fontSize(14)
                      .fontColor('#2E75B6')
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
                    Text(this.displayText(item))
                      .fontSize(14)
                      .fontColor('#666666')
                      .maxLines(3)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                    if (this.fileLabel(item).length > 0) {
                      Text(this.fileLabel(item))
                        .fontSize(12)
                        .fontColor('#2E75B6')
                        .backgroundColor('#EAF1FA')
                        .borderRadius(4)
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        .margin({ top: 4 })
                        .width('100%')
                    }
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
                    Button('忽略')
                      .fontSize(12)
                      .onClick(() => {
                        this.dismissMessage(item);
                      })
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

      BottomNav({ current: 'todo' })
    }
    .width('100%')
    .height('100%')
  }
}
