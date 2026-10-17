import { pasteboard, BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { picker, fileIo, fileUri } from '@kit.CoreFileKit';
import { common, Want, wantConstant } from '@kit.AbilityKit';
import { Store } from '../common/Store';
import { ParseService } from '../common/ParseService';
import { ApiClient } from '../common/ApiClient';
import { AttachmentStore } from '../common/AttachmentStore';
import { FeedbackService, ACTION_ACCEPT, ACTION_DISMISS } from '../service/FeedbackService';
import { CalendarService, CalendarResult } from '../service/CalendarService';
import {
  RobotMessage, DetailParams, ParsedEntity, ServeParse, MessageEditFields, MessageUpdateData,
  firstImageUrl, firstImageIndex, firstFileIndex, fileAttachmentLabel, isLocalAttachment,
  applyParsedEvent, splitListInput, joinListInput, mergeLocalParse, dueAtOf
} from '../common/Types';
import { EntityIcon, safeToast } from '../common/UiParts';
import {
  CampusEvent, EVENT_TODO, EVENT_NOTICE, EVENT_ACTIVITY, EVENT_PLAN, EVENT_CHAT, EVENT_IGNORE
} from '../nlp/EventTypes';
import { timeSlotDisplay } from '../nlp/TimeParser';

/** 可选的「待办类别」：与后端 kind 取值一致（改完原样回传） */
const EDIT_KINDS: string[] =
  [EVENT_TODO, EVENT_NOTICE, EVENT_ACTIVITY, EVENT_PLAN, EVENT_CHAT, EVENT_IGNORE];

@Entry
@Component
struct MessageDetailPage {
  @State msg: RobotMessage | undefined = undefined;
  @State reparsing: boolean = false;
  @State imageFailed: boolean = false;
  @State showFullImageText: boolean = false;
  /** 原图（经后端 /attachment 取回后解码）；undefined = 没有/还没取到 */
  @State imagePm: image.PixelMap | undefined = undefined;
  @State imageLoading: boolean = false;
  /** 群文件正在取回/落盘 */
  @State fileSaving: boolean = false;
  /** 正在准备打开文件（取回 + 拉起系统应用） */
  @State fileOpening: boolean = false;
  /** 正在写入系统日历 */
  @State calSaving: boolean = false;
  /** 「编辑待办」：就地改 kind / 摘要 / 时间 / 地点 / 需带 / 标签 */
  @State editing: boolean = false;
  @State editSaving: boolean = false;
  @State editKind: string = '';
  @State editTitle: string = '';
  @State editSummary: string = '';
  @State editTimeText: string = '';
  @State editPlace: string = '';
  @State editWho: string = '';
  @State editDeadline: string = '';
  @State editItems: string = '';
  @State editTags: string = '';
  private currentId: string = '';

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as DetailParams;
    this.currentId = params?.msgId ?? '';
    this.loadMsg();
    this.ensureEntities();
  }

  /**
   * 批处理已不跑 NL Kit（那套只在详情页按需跑），所以进详情页时补一次实体抽取。
   * `ensureNlp` 内部按 msg_id 去重，重复进入不会重复跑。
   */
  async ensureEntities(): Promise<void> {
    const before: ParsedEntity[] = this.msg?.entities ?? [];
    if (before.length > 0) {
      return;
    }
    const done: boolean = await ParseService.ensureNlp(this.currentId);
    if (done) {
      this.loadMsg();
    }
  }

  loadMsg(): void {
    if (this.currentId.length === 0) {
      return;
    }
    const list: RobotMessage[] = Store.getMessages();
    for (let i = 0; i < list.length; i++) {
      if (list[i].msg_id === this.currentId) {
        this.imageFailed = false;
        this.showFullImageText = false;
        this.msg = list[i];
        this.loadImage();
        return;
      }
    }
  }

  aboutToDisappear(): void {
    this.releaseImage();
  }

  /** 释放上一张原图（PixelMap 必须显式 release，否则一直占内存）。 */
  async releaseImage(): Promise<void> {
    const pm: image.PixelMap | undefined = this.imagePm;
    this.imagePm = undefined;
    if (pm !== undefined) {
      await pm.release();
    }
  }

  /**
   * 取回原图并解码成 PixelMap 渲染。
   *
   * 不直接用附件里的 QQ 直链：CDN 链接带**时效 rkey**，端上直连常常失败、过期后更取不到。
   * 取字节统一交给 `ensureBytes`：**先读本机落盘的副本**（轮询时趁 30 分钟窗口存下的，
   * 所以窗口过期后照样能看原图）→ 再回退后端 `/attachment` 过路。
   */
  async loadImage(): Promise<void> {
    const m: RobotMessage | undefined = this.msg;
    if (m === undefined) {
      return;
    }
    const idx: number = firstImageIndex(m.attachments);
    if (idx < 0) {
      return;
    }
    await this.releaseImage();
    this.imageLoading = true;
    this.imageFailed = false;
    try {
      const buf: ArrayBuffer | null = await this.ensureBytes(idx);
      if (buf === null) {
        this.imageFailed = true;
        return;
      }
      const source: image.ImageSource = image.createImageSource(buf);
      try {
        this.imagePm = await source.createPixelMap();
      } finally {
        await source.release();
      }
    } catch (e) {
      this.imageFailed = true;
    } finally {
      this.imageLoading = false;
    }
  }

  isPending(): boolean {
    return this.msg === undefined || this.msg.parsedAt === undefined || this.msg.parsedAt.length === 0;
  }

  isParsedOk(): boolean {
    return this.msg !== undefined && this.msg.parseOk === true;
  }

  categoryText(): string {
    return this.msg?.category ?? '';
  }

  summaryText(): string {
    return this.msg?.summary ?? '';
  }

  entityList(): ParsedEntity[] {
    return this.msg?.entities ?? [];
  }

  imageUrl(): string {
    return this.msg === undefined ? '' : firstImageUrl(this.msg.attachments);
  }

  hasImage(): boolean {
    return this.imageUrl().length > 0;
  }

  imageText(): string {
    return this.msg?.imageText ?? '';
  }

  /** 文件附件的标签：QQ 文件消息 content 为空，正文就是附件本身。 */
  fileLabel(): string {
    return this.msg === undefined ? '' : fileAttachmentLabel(this.msg.attachments);
  }

  fileIndex(): number {
    const m: RobotMessage | undefined = this.msg;
    if (m === undefined) {
      return -1;
    }
    return firstFileIndex(m.attachments);
  }

  fileNameOf(): string {
    const m: RobotMessage | undefined = this.msg;
    const idx: number = this.fileIndex();
    if (m === undefined || m.attachments === undefined || idx < 0) {
      return 'attachment.bin';
    }
    const n: string = m.attachments[idx].filename ?? '';
    return n.length > 0 ? n : 'attachment.bin';
  }

  /** 这个文件是不是本机沙箱副本（手动添加时存下来的，不用再去后端取）。 */
  isLocalFile(): boolean {
    const m: RobotMessage | undefined = this.msg;
    const idx: number = this.fileIndex();
    if (m === undefined || m.attachments === undefined || idx < 0) {
      return false;
    }
    return isLocalAttachment(m.attachments[idx]);
  }

  /** 本机附件的沙箱路径（`file://` 后面那段）；不是本机文件返回空串。 */
  localPathOf(): string {
    const m: RobotMessage | undefined = this.msg;
    const idx: number = this.fileIndex();
    if (m === undefined || m.attachments === undefined || idx < 0) {
      return '';
    }
    const url: string = m.attachments[idx].url ?? '';
    return url.indexOf('file://') === 0 ? url.substring('file://'.length) : '';
  }

  /**
   * 取这条消息第 index 个附件的字节，优先级：
   *   ① 手动添加时存下来的沙箱副本（url 本身是 file://）
   *   ② AttachmentStore 落盘的副本（轮询时趁 30 分钟窗口存下的，**过期也能用**）
   *   ③ 现在去后端 `/attachment` 取一次并顺手落盘
   */
  async ensureBytes(index: number): Promise<ArrayBuffer | null> {
    const m: RobotMessage | undefined = this.msg;
    if (m === undefined || index < 0 || m.attachments === undefined) {
      return null;
    }
    const url: string = m.attachments[index].url ?? '';
    if (url.indexOf('file://') === 0) {
      return this.readLocalFile(url.substring('file://'.length));
    }
    const local: ArrayBuffer | null = AttachmentStore.readLocal(m.group_openid, m.msg_id, index);
    if (local !== null) {
      return local;
    }
    const ok: boolean = await AttachmentStore.ensureSaved(m.group_openid, m.msg_id, index, url);
    return ok ? AttachmentStore.readLocal(m.group_openid, m.msg_id, index) : null;
  }

  /** 读本机沙箱文件的字节（失败返回 null）。 */
  readLocalFile(path: string): ArrayBuffer | null {
    let f: fileIo.File | undefined = undefined;
    try {
      f = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
      const size: number = fileIo.statSync(f.fd).size;
      if (size <= 0) {
        return null;
      }
      const buf: ArrayBuffer = new ArrayBuffer(size);
      fileIo.readSync(f.fd, buf);
      return buf;
    } catch (e) {
      return null;
    } finally {
      if (f !== undefined) {
        try {
          fileIo.closeSync(f);
        } catch (e2) {
          // 关闭失败：fd 由系统回收
        }
      }
    }
  }

  /**
   * 预览文件：把文件交给系统里能打开它的应用（隐式 Want + 只读授权）。
   *
   * 关键点：预览前一律先落到 `cacheDir/<**原文件名**>` 再打开——否则打开的是沙箱里那个
   * 内部名 `task_<时间戳>_原名`，用户看到的标题全是 task 开头的怪名字。
   * 群文件先经 `/attachment` 取回；手动添加的文件从沙箱副本读。
   */
  async previewFile(): Promise<void> {
    const m: RobotMessage | undefined = this.msg;
    const idx: number = this.fileIndex();
    if (m === undefined || idx < 0 || this.fileOpening) {
      return;
    }
    this.fileOpening = true;
    try {
      const buf: ArrayBuffer | null = await this.ensureBytes(idx);
      if (buf === null || buf.byteLength === 0) {
        safeToast(this.getUIContext(), '取不回这个文件：本机没存过，且已超 30 分钟窗口');
        return;
      }
      const appCtx: Context | null = Store.getAppContext();
      if (appCtx === null) {
        safeToast(this.getUIContext(), '拿不到应用上下文，无法打开');
        return;
      }
      // 用原文件名落到缓存目录：打开后的标题才正常，后缀也让系统能按类型匹配应用
      const path: string = appCtx.cacheDir + '/' + this.fileNameOf();
      const f: fileIo.File = fileIo.openSync(
        path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
      try {
        fileIo.writeSync(f.fd, buf);
      } finally {
        fileIo.closeSync(f);
      }
      const want: Want = {
        action: 'ohos.want.action.viewData',
        uri: fileUri.getUriFromPath(path),
        flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION
      };
      const abilityCtx: common.UIAbilityContext = appCtx as common.UIAbilityContext;
      await abilityCtx.startAbility(want);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      safeToast(this.getUIContext(), '打不开这个文件（可能没装能打开它的应用）：' + e.message);
    } finally {
      this.fileOpening = false;
    }
  }

  /**
   * 把群文件存到手机：经 `/attachment` 取回字节 → 系统「保存文件」框落盘。
   * QQ 直链带时效 rkey、端上直连不可靠，所以统一走后端过路。
   */
  async saveFileToPhone(): Promise<void> {
    const m: RobotMessage | undefined = this.msg;
    const idx: number = this.fileIndex();
    if (m === undefined || idx < 0 || this.fileSaving) {
      return;
    }
    this.fileSaving = true;
    try {
      const buf: ArrayBuffer | null = await this.ensureBytes(idx);
      if (buf === null) {
        safeToast(this.getUIContext(), '取回失败：本机没存过，且已超 30 分钟窗口');
        return;
      }
      const name: string = this.fileNameOf();
      const options = new picker.DocumentSaveOptions();
      options.newFileNames = [name];
      const uris: Array<string> = await new picker.DocumentViewPicker().save(options);
      if (uris.length === 0) {
        return;
      }
      const file: fileIo.File = fileIo.openSync(uris[0], fileIo.OpenMode.READ_WRITE);
      try {
        fileIo.writeSync(file.fd, buf);
      } finally {
        fileIo.closeSync(file);
      }
      safeToast(this.getUIContext(), '已保存：' + name);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      safeToast(this.getUIContext(), '保存文件失败：' + e.message);
    } finally {
      this.fileSaving = false;
    }
  }

  /** 识别文字的压缩摘要（整屏 OCR 直接展示是一堵墙） */
  imageSummary(): string {
    return this.msg?.imageSummary ?? '';
  }

  imageSectionTitle(): string {
    return this.msg?.imageKind === 'qr' ? '二维码内容' : '图片文字（OCR）';
  }

  hasEvent(): boolean {
    return this.msg?.event !== undefined;
  }

  evKind(): string {
    return this.msg?.event?.kind ?? '';
  }

  evTitle(): string {
    return this.msg?.event?.title ?? '';
  }

  evTimeText(): string {
    const e: CampusEvent | undefined = this.msg?.event;
    if (e === undefined || e.time === null) {
      return '';
    }
    return timeSlotDisplay(e.time);
  }

  evPlace(): string {
    return this.msg?.event?.place ?? '';
  }

  evWho(): string {
    return this.msg?.event?.who ?? '';
  }

  evDeadline(): string {
    return this.msg?.event?.deadline ?? '';
  }

  evConf(): number {
    return this.msg?.event?.confidence ?? 0;
  }

  evTags(): string[] {
    return this.msg?.event?.tags ?? [];
  }

  evKindColor(): string {
    const k: string = this.evKind();
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

  /** 进入编辑：把当前（可能是后端 AI 给的）值填进表单 */
  beginEdit(): void {
    const m: RobotMessage | undefined = this.msg;
    const p: ServeParse | undefined = m?.parse;
    const e: CampusEvent | undefined = m?.event;
    this.editKind = p?.kind ?? e?.kind ?? '';
    this.editTitle = p?.title ?? e?.title ?? '';
    this.editSummary = p?.summary ?? m?.summary ?? '';
    this.editTimeText = p?.timeText ?? e?.time?.text ?? '';
    this.editPlace = p?.place ?? e?.place ?? '';
    this.editWho = p?.who ?? e?.who ?? '';
    this.editDeadline = p?.deadline ?? e?.deadline ?? '';
    this.editItems = joinListInput(p?.items ?? e?.items);
    this.editTags = joinListInput(p?.tags ?? e?.tags);
    this.editing = true;
  }

  cancelEdit(): void {
    this.editing = false;
  }

  /**
   * 保存修改：先给后端（覆盖它下发的 parse，别的设备 / 下次拉取也一致）；
   * 后端存不下（30 分钟窗口过了、群没订阅）也照样在本机生效——用户改了就一定生效。
   */
  // ---------------------------------------------------------------- 卡片字段编辑
  //
  // 这些字段（重要性/难度/重复/提醒/完成）在《任务字段表》里属于**本机 Task**，
  // 不是后端解析结果，所以**只存本机**、不走 `/messages/update`
  // （后端那份白名单里也没有它们，发过去会被 400 拒掉）。

  evPriority(): number {
    return this.msg?.event?.priority ?? 0;
  }

  evLevel(): number {
    return this.msg?.event?.level ?? 1;
  }

  evRepeat(): string {
    return this.msg?.event?.repeat ?? 'none';
  }

  evDueAt(): number {
    const e: CampusEvent | undefined = this.msg?.event;
    if (e === undefined) {
      return 0;
    }
    if (e.dueAt !== undefined && e.dueAt > 0) {
      return e.dueAt;
    }
    return dueAtOf(e.time?.normalized ?? '');
  }

  canAlarm(): boolean {
    return this.evDueAt() > 0;
  }

  alarmOn(): boolean {
    return this.msg?.alarm === true;
  }

  doneOn(): boolean {
    return this.msg?.done === true;
  }

  /** 写一条本地卡片改动：改本机存储里的这条消息，并让当前页重新读一次。 */
  private patchLocal(msgId: string, fn: (m: RobotMessage) => void): void {
    const list: RobotMessage[] = Store.getMessages();
    let changed: boolean = false;
    for (let i = 0; i < list.length; i++) {
      if (list[i].msg_id === msgId) {
        fn(list[i]);
        changed = true;
      }
    }
    if (!changed) {
      return;
    }
    Store.saveMessages(list);
    AppStorage.setOrCreate<number>('msgVersion', (AppStorage.get<number>('msgVersion') ?? 0) + 1);
    this.refreshMsg();
  }

  /** 只重读当前这条消息（**不**重新 loadImage，避免每点一下都去取原图）。 */
  private refreshMsg(): void {
    const list: RobotMessage[] = Store.getMessages();
    for (let i = 0; i < list.length; i++) {
      if (list[i].msg_id === this.currentId) {
        this.msg = list[i];
        return;
      }
    }
  }

  setPriority(p: number): void {
    const m: RobotMessage | undefined = this.msg;
    if (m === undefined) {
      return;
    }
    this.patchLocal(m.msg_id, (x: RobotMessage) => {
      if (x.event !== undefined) {
        x.event.priority = p;
      }
    });
  }

  setLevel(l: number): void {
    const m: RobotMessage | undefined = this.msg;
    if (m === undefined) {
      return;
    }
    this.patchLocal(m.msg_id, (x: RobotMessage) => {
      if (x.event !== undefined) {
        x.event.level = l;
      }
    });
  }

  setRepeat(r: string): void {
    const m: RobotMessage | undefined = this.msg;
    if (m === undefined) {
      return;
    }
    this.patchLocal(m.msg_id, (x: RobotMessage) => {
      if (x.event !== undefined) {
        x.event.repeat = r;
        if (r === 'none') {
          x.event.repeatText = '';
        }
      }
    });
  }

  setAlarm(on: boolean): void {
    const m: RobotMessage | undefined = this.msg;
    if (m === undefined) {
      return;
    }
    this.patchLocal(m.msg_id, (x: RobotMessage) => {
      x.alarm = on;
    });
    safeToast(this.getUIContext(), on ? '已打开提醒' : '已关闭提醒');
  }

  setDone(done: boolean): void {
    const m: RobotMessage | undefined = this.msg;
    if (m === undefined) {
      return;
    }
    this.patchLocal(m.msg_id, (x: RobotMessage) => {
      x.done = done;
      x.doneAt = done ? Date.now() : 0;
    });
  }

  async saveEdit(): Promise<void> {
    const m: RobotMessage | undefined = this.msg;
    if (m === undefined || this.editSaving) {
      return;
    }
    this.editSaving = true;
    const fields: MessageEditFields = {
      kind: this.editKind,
      title: this.editTitle,
      summary: this.editSummary,
      timeText: this.editTimeText,
      place: this.editPlace,
      who: this.editWho,
      deadline: this.editDeadline,
      items: splitListInput(this.editItems),
      tags: splitListInput(this.editTags)
    };
    let backendOk: boolean = false;
    let reason: string = '';
    try {
      const body: Record<string, Object> = { 'msg_id': m.msg_id, 'fields': fields };
      const res = await ApiClient.post<MessageUpdateData>('/api/relay/messages/update', body);
      if (res.ok && res.data !== undefined) {
        backendOk = true;
        this.writeLocal(m.msg_id, res.data.parse);
      } else {
        const code: string = res.error?.code ?? '';
        reason = code === 'not_found'
          ? '消息已过 30 分钟窗口或该群未订阅'
          : (res.error?.message ?? '后端保存失败');
        this.writeLocal(m.msg_id, mergeLocalParse(m.parse, fields));
      }
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      reason = e.message;
      this.writeLocal(m.msg_id, mergeLocalParse(m.parse, fields));
    } finally {
      this.editSaving = false;
    }
    this.editing = false;
    this.loadMsg();
    AppStorage.setOrCreate<number>('msgVersion', (AppStorage.get<number>('msgVersion') ?? 0) + 1);
    safeToast(this.getUIContext(), backendOk ? '已保存（后端 + 本机）' : '已保存到本机：' + reason);
  }

  /** 把新的 parse 落进本机这条消息，并重建事件对象（列表/详情立刻反映改动）。 */
  writeLocal(msgId: string, next: ServeParse): void {    const list: RobotMessage[] = Store.getMessages();
    for (let i = 0; i < list.length; i++) {
      if (list[i].msg_id === msgId) {
        list[i].parse = next;
        applyParsedEvent(list[i]);
        list[i].parsedAt = new Date().toISOString();
        list[i].parseOk = true;
        list[i].summary = next.summary;
        list[i].category = next.category;
        Store.saveMessages(list);
        return;
      }
    }
  }

  /** 实体里的链接/邮箱点开：交给系统（浏览器 / 邮件）。 */
  async openEntity(type: string, text: string): Promise<void> {
    const ctx: Context | null = Store.getAppContext();
    if (ctx === null || text.length === 0) {
      return;
    }
    let uri: string = text;
    if (type === 'email') {
      if (text.indexOf('mailto:') !== 0) {
        uri = 'mailto:' + text;
      }
    } else if (uri.indexOf('http') !== 0) {
      uri = 'https://' + uri;
    }
    try {
      const want: Want = { action: 'ohos.want.action.viewData', uri: uri };
      const abilityCtx: common.UIAbilityContext = ctx as common.UIAbilityContext;
      await abilityCtx.startAbility(want);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      safeToast(this.getUIContext(), '打不开这个链接：' + e.message);
    }
  }

  /** 把这条待办一键写进系统日历（Calendar Kit；首次会弹日历授权）。 */
  async writeToCalendar(): Promise<void> {
    const m: RobotMessage | undefined = this.msg;
    if (m === undefined || this.calSaving) {
      return;
    }
    const ev: CampusEvent | undefined = m.event;
    if (ev === undefined) {
      safeToast(this.getUIContext(), '这条还没解析出事项，先「重新解析」再写日历');
      return;
    }
    const ctx: Context | null = Store.getAppContext();
    if (ctx === null) {
      safeToast(this.getUIContext(), '拿不到应用上下文');
      return;
    }
    this.calSaving = true;
    try {
      const res: CalendarResult =
        await CalendarService.writeEvent(ctx as common.UIAbilityContext, ev, m.content);
      safeToast(this.getUIContext(), res.message);
    } finally {
      this.calSaving = false;
    }
  }

  handleToTask(): void {
    if (this.msg === undefined) {
      return;
    }
    Store.markAsTaskSource(this.msg);
    this.setHandled(this.msg.msg_id);
    // 接受候选：本地先行，反馈异步回传（后端只记计数；老后端自动跳过）
    FeedbackService.send(this.msg, ACTION_ACCEPT);
    safeToast(this.getUIContext(), '已交给解析');
    this.getUIContext().getRouter().back();
  }

  /** 忽略候选：本地标记隐藏 + dismiss 回传 */
  ignoreMessage(): void {
    if (this.msg === undefined) {
      return;
    }
    const msg: RobotMessage = this.msg;
    Store.setDismissed(msg.msg_id);
    AppStorage.setOrCreate<number>('msgVersion', (AppStorage.get<number>('msgVersion') ?? 0) + 1);
    FeedbackService.send(msg, ACTION_DISMISS);
    safeToast(this.getUIContext(), '已忽略');
    this.getUIContext().getRouter().back();
  }

  setHandled(msgId: string): void {
    const list: RobotMessage[] = Store.getMessages();
    for (let i = 0; i < list.length; i++) {
      if (list[i].msg_id === msgId) {
        list[i].handled = true;
      }
    }
    Store.saveMessages(list);
    AppStorage.setOrCreate<number>('msgVersion', (AppStorage.get<number>('msgVersion') ?? 0) + 1);
  }

  async reparse(): Promise<void> {
    if (this.currentId.length === 0 || this.reparsing) {
      return;
    }
    this.reparsing = true;
    await ParseService.reparse(this.currentId);
    this.loadMsg();
    this.reparsing = false;
    safeToast(this.getUIContext(), '已重新解析');
  }

  async copyContent(): Promise<void> {
    if (this.msg === undefined) {
      return;
    }
    try {
      const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.msg.content);
      const sp: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      await sp.setData(pasteData);
      safeToast(this.getUIContext(), '已复制正文');
    } catch (e) {
      safeToast(this.getUIContext(), '复制失败');
    }
  }

  deleteMessage(): void {
    if (this.msg === undefined) {
      return;
    }
    const msgId: string = this.msg.msg_id;
    const list: RobotMessage[] = Store.getMessages();
    const rest: RobotMessage[] = [];
    for (let i = 0; i < list.length; i++) {
      if (list[i].msg_id !== msgId) {
        rest.push(list[i]);
      }
    }
    Store.saveMessages(rest);
    AppStorage.setOrCreate<number>('msgVersion', (AppStorage.get<number>('msgVersion') ?? 0) + 1);
    this.getUIContext().getRouter().back();
  }

  build() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        Button('返回')
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
        Text('消息详情')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 4 })

      if (this.msg === undefined) {
        Text('消息不存在或已被删除')
          .fontColor(Color.Gray)
          .margin(16)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            // ---- 卡片字段（只存本机；对应《任务字段表》的可编辑列）----
            if (this.hasEvent()) {
              Column({ space: 8 }) {
                Text('卡片字段（只存本机）')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .width('100%')

                Row({ space: 8 }) {
                  Text('重要性')
                    .fontSize(13)
                    .fontColor(Color.Gray)
                    .width(56)
                  Text('普通')
                    .fontSize(13)
                    .fontColor(this.evPriority() === 0 ? Color.White : '#1F3A5F')
                    .backgroundColor(this.evPriority() === 0 ? '#2E75B6' : '#EAF1FA')
                    .borderRadius(10)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.setPriority(0);
                    })
                  Text('重要')
                    .fontSize(13)
                    .fontColor(this.evPriority() === 1 ? Color.White : '#1F3A5F')
                    .backgroundColor(this.evPriority() === 1 ? '#2E75B6' : '#EAF1FA')
                    .borderRadius(10)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.setPriority(1);
                    })
                  Text('紧急')
                    .fontSize(13)
                    .fontColor(this.evPriority() === 2 ? Color.White : '#1F3A5F')
                    .backgroundColor(this.evPriority() === 2 ? '#2E75B6' : '#EAF1FA')
                    .borderRadius(10)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.setPriority(2);
                    })
                }
                .width('100%')

                Row({ space: 8 }) {
                  Text('难度')
                    .fontSize(13)
                    .fontColor(Color.Gray)
                    .width(56)
                  Text('易')
                    .fontSize(13)
                    .fontColor(this.evLevel() === 0 ? Color.White : '#1F3A5F')
                    .backgroundColor(this.evLevel() === 0 ? '#2E75B6' : '#EAF1FA')
                    .borderRadius(10)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.setLevel(0);
                    })
                  Text('中')
                    .fontSize(13)
                    .fontColor(this.evLevel() === 1 ? Color.White : '#1F3A5F')
                    .backgroundColor(this.evLevel() === 1 ? '#2E75B6' : '#EAF1FA')
                    .borderRadius(10)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.setLevel(1);
                    })
                  Text('难')
                    .fontSize(13)
                    .fontColor(this.evLevel() === 2 ? Color.White : '#1F3A5F')
                    .backgroundColor(this.evLevel() === 2 ? '#2E75B6' : '#EAF1FA')
                    .borderRadius(10)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.setLevel(2);
                    })
                }
                .width('100%')

                Row({ space: 8 }) {
                  Text('重复')
                    .fontSize(13)
                    .fontColor(Color.Gray)
                    .width(56)
                  Text('不重复')
                    .fontSize(13)
                    .fontColor(this.evRepeat() === 'none' ? Color.White : '#1F3A5F')
                    .backgroundColor(this.evRepeat() === 'none' ? '#2E75B6' : '#EAF1FA')
                    .borderRadius(10)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.setRepeat('none');
                    })
                  Text('每天')
                    .fontSize(13)
                    .fontColor(this.evRepeat() === 'day' ? Color.White : '#1F3A5F')
                    .backgroundColor(this.evRepeat() === 'day' ? '#2E75B6' : '#EAF1FA')
                    .borderRadius(10)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.setRepeat('day');
                    })
                  Text('每周')
                    .fontSize(13)
                    .fontColor(this.evRepeat() === 'week' ? Color.White : '#1F3A5F')
                    .backgroundColor(this.evRepeat() === 'week' ? '#2E75B6' : '#EAF1FA')
                    .borderRadius(10)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.setRepeat('week');
                    })
                  Text('每月')
                    .fontSize(13)
                    .fontColor(this.evRepeat() === 'month' ? Color.White : '#1F3A5F')
                    .backgroundColor(this.evRepeat() === 'month' ? '#2E75B6' : '#EAF1FA')
                    .borderRadius(10)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.setRepeat('month');
                    })
                }
                .width('100%')

                Row({ space: 12 }) {
                  Text('提醒')
                    .fontSize(13)
                    .fontColor(Color.Gray)
                    .width(56)
                  if (this.canAlarm()) {
                    Toggle({ type: ToggleType.Switch, isOn: this.alarmOn() })
                      .onChange((on: boolean) => {
                        this.setAlarm(on);
                      })
                  } else {
                    Text('没有截止时刻，定不了提醒点')
                      .fontSize(12)
                      .fontColor(Color.Gray)
                  }
                }
                .width('100%')

                Row({ space: 12 }) {
                  Text('状态')
                    .fontSize(13)
                    .fontColor(Color.Gray)
                    .width(56)
                  Text('未完成')
                    .fontSize(13)
                    .fontColor(!this.doneOn() ? Color.White : '#1F3A5F')
                    .backgroundColor(!this.doneOn() ? '#2E75B6' : '#EAF1FA')
                    .borderRadius(10)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.setDone(false);
                    })
                  Text('已完成')
                    .fontSize(13)
                    .fontColor(this.doneOn() ? Color.White : '#1F3A5F')
                    .backgroundColor(this.doneOn() ? '#2E75B6' : '#EAF1FA')
                    .borderRadius(10)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .onClick(() => {
                      this.setDone(true);
                    })
                }
                .width('100%')
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
            }

            Column({ space: 8 }) {
              Text('事件')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .width('100%')
              if (!this.hasEvent()) {
                Text('尚未整理（本条不是待办/通知/出行计划）')
                  .fontSize(13)
                  .fontColor(Color.Gray)
                  .width('100%')
              } else {
                Row({ space: 6 }) {
                  Text(this.evKind())
                    .fontSize(12)
                    .fontColor(Color.White)
                    .backgroundColor(this.evKindColor())
                    .borderRadius(4)
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  Text(this.evTitle())
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)

                if (this.evTimeText().length > 0) {
                  Row({ space: 6 }) {
                    EntityIcon({ type: 'datetime', size: 15, color: '#2E75B6' })
                    Text(this.evTimeText())
                      .fontSize(14)
                      .fontColor('#333333')
                      .layoutWeight(1)
                  }
                  .width('100%')
                }
                if (this.evPlace().length > 0) {
                  Row({ space: 6 }) {
                    EntityIcon({ type: 'location', size: 15, color: '#2E75B6' })
                    Text(this.evPlace())
                      .fontSize(14)
                      .fontColor('#333333')
                      .layoutWeight(1)
                  }
                  .width('100%')
                }
                if (this.evWho().length > 0) {
                  Row({ space: 6 }) {
                    EntityIcon({ type: 'name', size: 15, color: '#2E75B6' })
                    Text(this.evWho())
                      .fontSize(14)
                      .fontColor('#333333')
                      .layoutWeight(1)
                  }
                  .width('100%')
                }
                if (this.evDeadline().length > 0) {
                  Text('截止：' + this.evDeadline())
                    .fontSize(14)
                    .fontColor('#B8434E')
                    .width('100%')
                }
                if (this.summaryText().length > 0) {
                  Text(this.summaryText())
                    .fontSize(14)
                    .fontColor('#333333')
                    .width('100%')
                }
                if (this.evTags().length > 0) {
                  Flex({ wrap: FlexWrap.Wrap }) {
                    ForEach(this.evTags(), (t: string, index: number) => {
                      Text(t)
                        .fontSize(11)
                        .fontColor('#3E9E6B')
                        .backgroundColor('#EAF6EF')
                        .borderRadius(4)
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        .margin({ right: 6, bottom: 6 })
                    }, (t: string, index: number) => index + '_' + t)
                  }
                  .width('100%')
                }
                Text(this.evConf() < 0.5
                  ? '置信度 ' + this.evConf().toFixed(2) + '（字段不完整，建议人工确认）'
                  : '置信度 ' + this.evConf().toFixed(2))
                  .fontSize(12)
                  .fontColor('#888888')
                  .width('100%')
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Divider()

            Column({ space: 8 }) {
              Text('解析结果')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .width('100%')

              if (this.isPending()) {
                Text('解析中…')
                  .fontSize(14)
                  .fontColor(Color.Gray)
                  .width('100%')
              } else if (this.isParsedOk()) {
                Row({ space: 6 }) {
                  if (this.categoryText().length > 0) {
                    Text(this.categoryText())
                      .fontSize(12)
                      .fontColor(Color.White)
                      .backgroundColor('#2E75B6')
                      .borderRadius(4)
                      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  }
                  Text(this.summaryText())
                    .fontSize(16)
                    .layoutWeight(1)
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)

                if (this.entityList().length > 0) {
                  Flex({ wrap: FlexWrap.Wrap }) {
                    ForEach(this.entityList(), (e: ParsedEntity, index: number) => {
                      Row({ space: 4 }) {
                        EntityIcon({ type: e.type, size: 15, color: '#2E75B6' })
                        Text(e.text)
                          .fontSize(13)
                          .fontColor('#2E75B6')
                      }
                      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                      .backgroundColor('#EAF1FA')
                      .borderRadius(4)
                      .margin({ right: 6, bottom: 6 })
                      .onClick(() => {
                        // 链接/邮箱可点开（后端抽出来的 url 常是纯域名，补 https://）
                        if (e.type === 'url' || e.type === 'email') {
                          this.openEntity(e.type, e.text);
                        }
                      })
                    }, (e: ParsedEntity, index: number) => index + '_' + e.type + '_' + e.text)
                  }
                  .width('100%')
                }
              } else {
                Text('未解析（设备可能不支持实体抽取，或本次解析失败）')
                  .fontSize(13)
                  .fontColor(Color.Gray)
                  .width('100%')
              }

              if (this.imageText().length > 0) {
                Text(this.imageSectionTitle())
                  .fontSize(13)
                  .fontColor(Color.Gray)
                  .width('100%')
                Text(this.imageSummary().length > 0 ? this.imageSummary() : this.imageText())
                  .fontSize(15)
                  .fontColor('#333333')
                  .width('100%')
                if (this.imageSummary().length > 0) {
                  Text(this.showFullImageText ? '收起完整文字' : '查看完整文字 ›')
                    .fontSize(12)
                    .fontColor('#2E75B6')
                    .width('100%')
                    .onClick(() => {
                      this.showFullImageText = !this.showFullImageText;
                    })
                  if (this.showFullImageText) {
                    Text(this.imageText())
                      .fontSize(13)
                      .fontColor('#666666')
                      .width('100%')
                      .padding({ top: 4 })
                  }
                }
              } else if (this.hasImage() && !this.isPending()) {
                Text('图片未识别出文字')
                  .fontSize(13)
                  .fontColor(Color.Gray)
                  .width('100%')
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Divider()

            Column({ space: 8 }) {
              Text('原消息')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .width('100%')
              Text(this.msg.group_label)
                .fontSize(14)
                .fontColor(Color.Gray)
              Text('发送者：' + this.msg.sender)
                .fontSize(14)
                .fontColor(Color.Gray)
              Text('时间：' + this.msg.timestamp)
                .fontSize(14)
                .fontColor(Color.Gray)

              if (this.imagePm !== undefined) {
                Image(this.imagePm)
                  .width('100%')
                  .constraintSize({ maxHeight: 320 })
                  .objectFit(ImageFit.Contain)
              } else if (this.imageLoading) {
                Row({ space: 8 }) {
                  LoadingProgress()
                    .width(18)
                    .height(18)
                  Text('正在取原图…')
                    .fontSize(13)
                    .fontColor(Color.Gray)
                }
                .width('100%')
              } else if (this.hasImage()) {
                Text(this.imageFailed
                  ? '[原图取不回：本机没存过，且已超 30 分钟窗口]'
                  : '[图片待加载]')
                  .fontSize(13)
                  .fontColor(Color.Gray)
                  .width('100%')
              }

              if (this.fileLabel().length > 0) {
                Text(this.fileLabel())
                  .fontSize(14)
                  .fontColor('#2E75B6')
                  .width('100%')
                  .onClick(() => {
                    this.previewFile();
                  })
                Row({ space: 12 }) {
                  Button(this.fileOpening ? '打开中…' : '预览文件')
                    .fontSize(13)
                    .enabled(!this.fileOpening)
                    .onClick(() => {
                      this.previewFile();
                    })
                  if (this.isLocalFile()) {
                    Text('已随任务存在本机')
                      .fontSize(12)
                      .fontColor(Color.Gray)
                  } else {
                    Button(this.fileSaving ? '取回中…' : '保存到手机')
                      .fontSize(13)
                      .enabled(!this.fileSaving)
                      .onClick(() => {
                        this.saveFileToPhone();
                      })
                  }
                }
                .width('100%')
              }

              if (this.msg.content.length > 0) {
                Text(this.msg.content)
                  .fontSize(16)
                  .width('100%')
                  .textAlign(TextAlign.Start)
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            if (this.editing) {
              Column({ space: 8 }) {
                Text('编辑待办（改完保存，本机立刻生效）')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .width('100%')
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(EDIT_KINDS, (k: string) => {
                    Text(k)
                      .fontSize(12)
                      .fontColor(this.editKind === k ? Color.White : '#666666')
                      .backgroundColor(this.editKind === k ? '#2E75B6' : '#F0F0F0')
                      .borderRadius(10)
                      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                      .margin({ right: 6, bottom: 6 })
                      .onClick(() => {
                        this.editKind = k;
                      })
                  }, (k: string) => k)
                }
                .width('100%')
                TextInput({ text: this.editTitle, placeholder: '标题' })
                  .fontSize(14)
                  .onChange((v: string) => {
                    this.editTitle = v;
                  })
                TextArea({ text: this.editSummary, placeholder: '摘要 / 总结' })
                  .fontSize(14)
                  .height(70)
                  .onChange((v: string) => {
                    this.editSummary = v;
                  })
                TextInput({ text: this.editTimeText, placeholder: '时间原话（如：明天下午两点）' })
                  .fontSize(14)
                  .onChange((v: string) => {
                    this.editTimeText = v;
                  })
                TextInput({ text: this.editPlace, placeholder: '地点' })
                  .fontSize(14)
                  .onChange((v: string) => {
                    this.editPlace = v;
                  })
                TextInput({ text: this.editWho, placeholder: '对象 / 负责人' })
                  .fontSize(14)
                  .onChange((v: string) => {
                    this.editWho = v;
                  })
                TextInput({ text: this.editDeadline, placeholder: '截止' })
                  .fontSize(14)
                  .onChange((v: string) => {
                    this.editDeadline = v;
                  })
                TextInput({ text: this.editItems, placeholder: '需带 / 注意（顿号分隔）' })
                  .fontSize(14)
                  .onChange((v: string) => {
                    this.editItems = v;
                  })
                TextInput({ text: this.editTags, placeholder: '标签（顿号分隔）' })
                  .fontSize(14)
                  .onChange((v: string) => {
                    this.editTags = v;
                  })
                Row({ space: 12 }) {
                  Button(this.editSaving ? '保存中…' : '保存修改')
                    .fontSize(14)
                    .enabled(!this.editSaving)
                    .onClick(() => {
                      this.saveEdit();
                    })
                  Button('取消')
                    .fontSize(14)
                    .onClick(() => {
                      this.cancelEdit();
                    })
                }
                .width('100%')
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFF7E6')
              .borderRadius(8)
              .alignItems(HorizontalAlign.Start)
            }

            Flex({ wrap: FlexWrap.Wrap }) {
              Button(this.editing ? '收起编辑' : '编辑')
                .margin({ right: 12, bottom: 8 })
                .onClick(() => {
                  if (this.editing) {
                    this.cancelEdit();
                  } else {
                    this.beginEdit();
                  }
                })
              Button(this.calSaving ? '写入中…' : '写入日历')
                .margin({ right: 12, bottom: 8 })
                .enabled(!this.calSaving)
                .onClick(() => {
                  this.writeToCalendar();
                })
              if (!this.msg.handled) {
                Button('转成待办')
                  .margin({ right: 12, bottom: 8 })
                  .onClick(() => {
                    this.handleToTask();
                  })
              } else {
                Text('已转成待办')
                  .fontColor(Color.Green)
                  .margin({ right: 12, bottom: 8 })
              }
              Button(this.reparsing ? '解析中…' : '重新解析')
                .enabled(!this.reparsing)
                .margin({ right: 12, bottom: 8 })
                .onClick(() => {
                  this.reparse();
                })
              Button('忽略此条')
                .margin({ right: 12, bottom: 8 })
                .onClick(() => {
                  this.ignoreMessage();
                })
              Button('复制正文')
                .margin({ right: 12, bottom: 8 })
                .onClick(() => {
                  this.copyContent();
                })
              Button('删除')
                .margin({ right: 12, bottom: 8 })
                .onClick(() => {
                  this.deleteMessage();
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 24 })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.Top)
      }
    }
    .width('100%')
    .height('100%')
  }
}
