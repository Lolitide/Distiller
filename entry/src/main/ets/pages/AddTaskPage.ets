/**
 * 手动添加任务（对应设计稿「添加任务.svg」）。
 *
 * v2：解析切到后端 POST /api/relay/parse（07_前后端对接方案 §5.2）——
 *   文字 / 截图 / 文件三来源统一云端抽取（OCR + 规则/模型），响应 data.text
 *   回显到输入框，用户改完再保存；隐私上后端「只处理、不存储」。
 * 端侧不做文件/图片解析（与后端约定）：后端不支持（501/400）时，
 *   提示用户**自己把要点总结成文字**再解析；纯文本且后端连不上时退回本机规则。
 *
 * 两条兜底（都不要求后端有多模态模型）：
 *   ① 后端缺 `ocr` 能力位、或后端连不上、或后端回 501 时，截图改走**端侧
 *      Core Vision Kit OCR**（`ImageRecognizer.recognizeBase64`）转成文字再解析；
 *   ② 「确定」按钮**不依赖解析成功**——没解析过就用本机规则兜底成一条待办。
 */
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { picker, fileIo, fileUri } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { Store } from '../common/Store';
import { ParseService } from '../common/ParseService';
import { ApiClient } from '../common/ApiClient';
import { ImageRecognizer, ImageRecognizeResult } from '../common/ImageRecognizer';
import { EntityIcon, safeToast } from '../common/UiParts';
import {
  HealthData, ParseCandidate, ParseData, ParsedEntity, ParsedInfo,
  RobotMessage, MessageAttachment, nowTimestamp, parseCandidateToEvent
} from '../common/Types';
import { CampusEvent, isActionable, EVENT_NOTICE, EVENT_PLAN, EVENT_TODO } from '../nlp/EventTypes';
import { timeSlotDisplay } from '../nlp/TimeParser';

const LOCAL_GROUP_OPENID: string = 'local_manual';
const LOCAL_GROUP_LABEL: string = '手动添加';
/** /parse 的 base64 上限与后端一致（b64 字符数）：图片 8MB、文件 4MB */
const IMAGE_B64_CAP: number = 8 * 1024 * 1024;
const FILE_B64_CAP: number = 4 * 1024 * 1024;
/** 后端跑 OCR + 抽取可能 10s+（模型冷启动更久），单独放宽（其余接口 8s） */
const PARSE_TIMEOUT_MS: number = 60000;
/** 文件选择器放行的后缀（与后端 _PARSE_*_EXTS 对齐；.doc/.xls/.ppt 老格式后端会 400 引导转存） */
const FILE_SUFFIX_FILTERS: string[] =
  ['文档|.txt,.md,.csv,.log,.json,.docx,.xlsx,.pptx,.pdf', '图片|.png,.jpg,.jpeg,.webp,.bmp'];

/** 读取 uri 指向的文件并转 base64（picker 已授予只读临时权限，无需额外权限）。 */
function readUriAsBase64(uri: string): string {
  try {
    const file: fileIo.File = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    try {
      const stat = fileIo.statSync(file.fd);
      const buf = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buf);
      const helper = new util.Base64Helper();
      return helper.encodeToStringSync(new Uint8Array(buf));
    } finally {
      try {
        fileIo.closeSync(file);
      } catch (e) {
        // 关闭失败：fd 由系统回收，无需处理
      }
    }
  } catch (e) {
    const err: BusinessError = e as BusinessError;
    throw new Error('读取文件失败：' + err.message);
  }
}

/**
 * 从 picker 返回的 URI 里取**真文件名**。
 *
 * picker 给的是系统 URI，中文名在其中是**百分号编码**的
 * （`.../%E6%9C%97%E8%AF%BB%E6%96%87%E7%AB%A0.docx`），直接截最后一段就会显示成
 * 一长串乱码（用户反馈的「一大串字符串」）。官方做法是用 `FileUri.name`——文档明确说
 * 它会把百分号编码字符解码后拼接；URI 格式不被接受时（如 datashare://）再手工兜底。
 */
function displayNameFromUri(uri: string): string {
  if (uri.length === 0) {
    return '文件';
  }
  try {
    const name: string = new fileUri.FileUri(uri).name;
    if (name.length > 0) {
      return name;
    }
  } catch (e) {
    // URI 格式不被 fileUri 接受：走下面的兜底
  }
  let s: string = uri;
  const q: number = s.indexOf('?');
  if (q >= 0) {
    s = s.substring(0, q);
  }
  const h: number = s.indexOf('#');
  if (h >= 0) {
    s = s.substring(0, h);
  }
  const tail: string = s.substring(s.lastIndexOf('/') + 1);
  if (tail.length === 0) {
    return '文件';
  }
  try {
    return decodeURIComponent(tail);
  } catch (e2) {
    return tail;
  }
}

@Entry
@Component
struct AddTaskPage {
  @State inputText: string = '';
  @State parsing: boolean = false;
  @State saving: boolean = false;
  @State parsed: ParsedInfo | null = null;
  @State entities: ParsedEntity[] = [];
  @State hint: string = '';
  @State imageName: string = '';
  @State fileName: string = '';
  /** 解析用的草稿消息（msg_id 带 local_ 前缀，保存时直接入库，保证 event.msgId 与之一致） */
  private draft: RobotMessage | null = null;
  /** 最近一次云端解析返回的候选（null = 本机规则解析或未解析） */
  private candidate: ParseCandidate | null = null;
  private caps: string[] = [];
  private imageB64: string = '';
  private fileB64: string = '';
  private fileRealName: string = '';
  /**
   * 沙箱里的文件副本：选中即拷一份，存为待办时挂到任务上——
   * 否则待办/详情页只看得到 /parse 抽出来的文字，看不到文件（2026-10-15 报的问题）。
   */
  private fileSavedPath: string = '';
  private fileSavedName: string = '';
  private fileSize: number = 0;

  async aboutToAppear(): Promise<void> {
    // 能力协商：截图直传后端 OCR 需要 capabilities 含 "ocr"（05 文档 §2.4）
    const res = await ApiClient.get<HealthData>('/api/relay/health');
    if (res.ok && res.data !== undefined) {
      this.caps = res.data.capabilities ?? [];
    }
  }

  hasCap(name: string): boolean {
    return this.caps.indexOf(name) >= 0;
  }

  /** 构造一条本地消息（手动添加）。msg_id 不会与服务端消息撞车。 */
  buildDraft(text: string): RobotMessage {
    const msg: RobotMessage = {
      seq: 0,
      group_openid: LOCAL_GROUP_OPENID,
      group_label: LOCAL_GROUP_LABEL,
      sender: '我',
      content: text,
      timestamp: nowTimestamp(),
      msg_id: 'local_' + Date.now(),
      event_type: 'MANUAL_CREATE',
      read: true,
      handled: false
    };
    // 选过文件就挂上去：这样「待办」和详情页都能看到这个文件（沙箱副本）
    if (this.fileSavedPath.length > 0) {
      const atts: MessageAttachment[] = [];
      const att: MessageAttachment = {
        content_type: 'file',
        filename: this.fileSavedName.length > 0 ? this.fileSavedName : '文件',
        size: this.fileSize,
        url: 'file://' + this.fileSavedPath
      };
      atts.push(att);
      msg.attachments = atts;
    }
    return msg;
  }

  /** 输入/附件变化后旧解析结果作废，避免「改了字但结果还是上一版」的假象 */
  invalidate(): void {
    this.parsed = null;
    this.entities = [];
    this.draft = null;
    this.candidate = null;
  }

  clearImage(): void {
    this.imageB64 = '';
    this.imageName = '';
    this.invalidate();
  }

  clearFile(): void {
    this.fileB64 = '';
    this.fileName = '';
    this.fileRealName = '';
    this.fileSavedPath = '';
    this.fileSavedName = '';
    this.fileSize = 0;
    this.invalidate();
  }

  /** 上传用的 base64 已被解析消费掉，但**保留沙箱副本**（保存为待办时要挂到任务上）。 */
  consumeFile(): void {
    this.fileB64 = '';
    this.fileName = '';
    this.invalidate();
  }

  /** 把选中的文件拷进应用沙箱（picker 的临时授权不持久，待办要能一直看到文件）。 */
  copyToSandbox(uri: string, name: string): string {
    const ctx = Store.getAppContext();
    if (ctx === null) {
      return '';
    }
    // 内部名带 task_<时间戳>_ 前缀保证唯一；**展示/预览时用原名**，见 MessageDetailPage.previewFile
    const dest: string = ctx.filesDir + '/task_' + Date.now() + '_' + name;
    let src: fileIo.File | undefined = undefined;
    let dst: fileIo.File | undefined = undefined;
    try {
      src = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const size: number = fileIo.statSync(src.fd).size;
      if (size <= 0) {
        return '';
      }
      // 不用 fileIo.copyFile(fd, fd)：实测会写出 0 字节文件，预览就是一片空白
      const buf: ArrayBuffer = new ArrayBuffer(size);
      fileIo.readSync(src.fd, buf);
      dst = fileIo.openSync(dest,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(dst.fd, buf);
      // 自检：字节数对不上就当拷贝失败（宁可不挂文件，也不留个空文件骗人）
      return fileIo.statSync(dest).size === size ? dest : '';
    } catch (e) {
      return '';
    } finally {
      if (dst !== undefined) {
        try {
          fileIo.closeSync(dst);
        } catch (e2) {
          // 关闭失败：fd 由系统回收
        }
      }
      if (src !== undefined) {
        try {
          fileIo.closeSync(src);
        } catch (e3) {
          // 同上
        }
      }
    }
  }

  /** 沙箱文件的字节数（拿不到就 0）。 */
  sandboxSize(path: string): number {
    if (path.length === 0) {
      return 0;
    }
    try {
      return fileIo.statSync(path).size;
    } catch (e) {
      return 0;
    }
  }

  async pickImage(): Promise<void> {
    try {
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const result: photoAccessHelper.PhotoSelectResult = await photoPicker.select(options);
      if (result.photoUris.length === 0) {
        return;
      }
      const b64: string = readUriAsBase64(result.photoUris[0]);
      if (b64.length > IMAGE_B64_CAP) {
        this.hint = '截图过大（上限约 6MB），请裁剪或压缩后再试';
        return;
      }
      this.imageB64 = b64;
      this.imageName = '已选截图 ' + Math.round(b64.length / 1024) + 'KB';
      this.hint = '';
      this.invalidate();
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      this.hint = '选图失败：' + e.message;
    }
  }

  async pickFile(): Promise<void> {
    try {
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = FILE_SUFFIX_FILTERS;
      const filePicker = new picker.DocumentViewPicker();
      const uris: Array<string> = await filePicker.select(options);
      if (uris.length === 0) {
        return;
      }
      const uri: string = uris[0];
      const b64: string = readUriAsBase64(uri);
      if (b64.length > FILE_B64_CAP) {
        this.hint = '文件过大（上限约 3MB），请拆分或摘录重点';
        return;
      }
      this.fileB64 = b64;
      // 文件名要的是「朗读文章.docx」，不是 URI 里那串百分号编码（见 displayNameFromUri）
      this.fileRealName = displayNameFromUri(uri);
      this.fileSavedName = this.fileRealName;
      this.fileSavedPath = this.copyToSandbox(uri, this.fileRealName);
      this.fileSize = this.sandboxSize(this.fileSavedPath);
      this.fileName = this.fileRealName + ' ' + Math.round(b64.length / 1024) + 'KB';
      this.hint = '';
      this.invalidate();
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      this.hint = '选文件失败：' + e.message;
    }
  }

  /** 本机规则解析（纯文本、后端连不上时的兜底；原文不出本机）。 */
  async parseLocal(text: string): Promise<void> {
    await this.localParse(text, '连不上后端，已用本机规则解析（纯本地，不上传）');
  }

  /** 本机规则解析主体：note 非空时写进提示。 */
  async localParse(text: string, note: string): Promise<void> {
    const draft: RobotMessage = this.buildDraft(text);
    const info: ParsedInfo = await ParseService.parseOne(draft, false);
    const ents: ParsedEntity[] = await ParseService.entitiesOf(text);
    this.draft = draft;
    this.parsed = info;
    this.entities = ents;
    if (note.length > 0) {
      this.hint = note;
    }
  }

  /** 端侧 OCR（Core Vision Kit）：识别已选截图里的文字；失败返回空串。 */
  async ocrSelectedImage(): Promise<string> {
    if (this.imageB64.length === 0) {
      return '';
    }
    const rec: ImageRecognizeResult = await ImageRecognizer.recognizeBase64(this.imageB64);
    return rec.text.trim();
  }

  /** 「确定」：不必等解析成功。没解析过就用本机规则兜底，然后存为待办。 */
  async confirmSave(): Promise<void> {
    if (this.saving || this.parsing) {
      return;
    }
    this.saving = true;
    try {
      let text: string = this.inputText.trim();
      if (this.parsed === null && text.length === 0 && this.imageB64.length > 0) {
        // 只选了截图、没打字：先端侧 OCR 认字，再走本机规则
        text = await this.ocrSelectedImage();
      }
      if (this.parsed === null) {
        if (text.length === 0) {
          this.hint = '请先输入要记录的内容（或先「解析」截图/文件）';
          return;
        }
        await this.localParse(text, '');
      }
    } finally {
      this.saving = false;
    }
    this.saveTask();
  }

  async parseNow(): Promise<void> {
    if (this.parsing) {
      return;
    }
    const text: string = this.inputText.trim();
    const hasImage: boolean = this.imageB64.length > 0;
    const hasFile: boolean = this.fileB64.length > 0;
    if (text.length === 0 && !hasImage && !hasFile) {
      this.hint = '先输入文字，或选一张截图/一个文件';
      return;
    }
    if (hasFile && !this.hasCap('parse')) {
      this.hint = '后端不支持文件解析，请自己把要点总结成文字';
      return;
    }
    this.parsing = true;
    this.hint = '';
    // 后端没有多模态模型（缺 ocr 能力位）时不再拒绝图片：改走端侧 Core Vision Kit OCR，
    // 认出文字后按纯文本送解析。
    let sendImage: boolean = hasImage;
    let payloadText: string = text;
    let ocrDone: boolean = false;
    if (hasImage && !this.hasCap('ocr')) {
      const ocrText: string = await this.ocrSelectedImage();
      ocrDone = true;
      if (ocrText.length === 0) {
        this.parsing = false;
        this.hint = '没能从截图里认出文字（模拟器不支持端侧 OCR），请手动输入要点';
        return;
      }
      payloadText = payloadText.length > 0 ? payloadText + '\n' + ocrText : ocrText;
      sendImage = false;
      this.clearImage();
    }
    try {
      const body: Record<string, string> = {};
      if (payloadText.length > 0) {
        body['text'] = payloadText;
      }
      if (sendImage) {
        body['image_b64'] = this.imageB64;
      }
      if (hasFile) {
        body['file_b64'] = this.fileB64;
        body['file_name'] = this.fileRealName;
      }
      body['source'] = hasImage ? 'manual_image' : (hasFile ? 'manual_file' : 'manual_text');
      const res = await ApiClient.post<ParseData>('/api/relay/parse', body, PARSE_TIMEOUT_MS);
      if (res.ok && res.data !== undefined) {
        const c: ParseCandidate = res.data.candidate;
        const mergedText: string = res.data.text;
        // 回显合并文本到输入框（可改）；已消费的截图/文件清掉，避免重解析时重复拼接
        this.inputText = mergedText;
        this.clearImage();
        this.consumeFile();
        const draft: RobotMessage = this.buildDraft(mergedText);
        const ev: CampusEvent = parseCandidateToEvent(c, mergedText, draft.msg_id, draft.timestamp);
        const info: ParsedInfo = {
          parsedAt: new Date().toISOString(),
          parseOk: true,
          category: c.kind,
          summary: c.summary,
          entities: [],
          event: ev
        };
        this.candidate = c;
        this.draft = draft;
        this.parsed = info;
        this.entities = [];
        return;
      }
      const code: string = res.error?.code ?? '';
      const message: string = res.error?.message ?? '';
      if (code === 'network') {
        // 后端连不上：文本走本机规则；截图还能救——端侧 OCR 出文字再走本机规则
        if (hasFile) {
          this.hint = '连不上后端，无法解析文件；可自己把要点总结成文字';
          return;
        }
        let localText: string = payloadText;
        if (hasImage && !ocrDone) {
          const ocrText: string = await this.ocrSelectedImage();
          if (ocrText.length > 0) {
            localText = localText.length > 0 ? localText + '\n' + ocrText : ocrText;
          }
        }
        if (localText.trim().length === 0) {
          this.hint = '连不上后端，也没能从截图里认出文字；请手动输入要点';
          return;
        }
        await this.localParse(localText, '连不上后端，已用端侧 OCR + 本机规则解析（原文不出本机）');
        return;
      }
      if (code === 'not_supported') {
        // 501：截图（本机模型不在）或 pdf（未装 pypdf）。截图还能端侧 OCR 救回重解析
        if (hasImage && !ocrDone) {
          const ocrText: string = await this.ocrSelectedImage();
          if (ocrText.length > 0) {
            const merged: string = text.length > 0 ? text + '\n' + ocrText : ocrText;
            this.clearImage();
            this.consumeFile();
            this.inputText = merged;
            this.parsing = false;
            await this.parseNow();
            return;
          }
        }
        if (hasFile) {
          this.consumeFile();
          if (text.length > 0) {
            this.parsing = false;
            await this.parseNow();
            return;
          }
        }
        this.hint = message + '；请自己把要点总结成文字';
        return;
      }
      // 其余（400 等）：后端返回的中文提示已含引导（如「请截图后按图片上传」）
      this.hint = message.length > 0 ? message : '解析失败，请重试';
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      this.hint = '解析出错：' + e.message;
    } finally {
      this.parsing = false;
    }
  }

  saveTask(): void {
    const info: ParsedInfo | null = this.parsed;
    const draft: RobotMessage | null = this.draft;
    if (info === null || draft === null || this.saving) {
      return;
    }
    this.saving = true;
    draft.parsedAt = info.parsedAt;
    draft.parseOk = info.parseOk;
    draft.category = info.category;
    draft.summary = info.summary;
    draft.entities = this.entities;
    draft.event = info.event;
    Store.addMessage(draft);
    AppStorage.setOrCreate<number>('msgVersion', (AppStorage.get<number>('msgVersion') ?? 0) + 1);
    this.saving = false;
    safeToast(this.getUIContext(), '已保存，列表见「待办」');
    this.getUIContext().getRouter().back();
  }

  hasEventCard(): boolean {
    const e: CampusEvent | undefined = this.parsed?.event;
    return e !== undefined && isActionable(e.kind);
  }

  evKind(): string {
    return this.parsed?.event?.kind ?? '';
  }

  evTitle(): string {
    return this.parsed?.event?.title ?? '';
  }

  evTimeText(): string {
    const e: CampusEvent | undefined = this.parsed?.event;
    if (e === undefined || e.time === null) {
      return '';
    }
    return timeSlotDisplay(e.time);
  }

  evPlace(): string {
    return this.parsed?.event?.place ?? '';
  }

  evDeadline(): string {
    return this.parsed?.event?.deadline ?? '';
  }

  evItemsText(): string {
    const arr: string[] = this.parsed?.event?.items ?? [];
    return arr.join('、');
  }

  evConf(): number {
    return this.parsed?.event?.confidence ?? 0;
  }

  evConfText(): string {
    const c: number = this.evConf();
    if (c >= 0.8) {
      return '高置信';
    }
    return c >= 0.5 ? '置信度 ' + c.toFixed(2) : '待确认（字段不完整）';
  }

  evConfColor(): string {
    const c: number = this.evConf();
    if (c >= 0.8) {
      return '#3E9E6B';
    }
    return c >= 0.5 ? '#888888' : '#C1663D';
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

  build() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        Button('返回')
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
        Text('添加任务')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 4 })

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 8 }) {
            Text('文字/截图/文件由后端解析（只处理、不存储）；后端没模型时截图走端侧 OCR；「确定」可直接存为待办')
              .fontSize(12)
              .fontColor(Color.Gray)
              .width('100%')
            TextArea({ text: this.inputText, placeholder: '例如：明天下午两点在主楼A103开班会，记得带学生证' })
              .onChange((value: string) => {
                this.inputText = value;
                this.invalidate();
              })
              .fontSize(15)
              .height(110)
              .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Row({ space: 8 }) {
            Button('选截图')
              .fontSize(13)
              .onClick(() => {
                this.pickImage();
              })
            Button('选文件')
              .fontSize(13)
              .onClick(() => {
                this.pickFile();
              })
            if (this.imageName.length > 0) {
              Text(this.imageName)
                .fontSize(12)
                .fontColor('#2E75B6')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
              Text('×')
                .fontSize(16)
                .fontColor(Color.Gray)
                .onClick(() => {
                  this.clearImage();
                })
            }
            if (this.fileName.length > 0 || this.fileSavedName.length > 0) {
              Text(this.fileName.length > 0
                ? this.fileName
                : ('已随任务保存：' + this.fileSavedName))
                .fontSize(12)
                .fontColor('#2E75B6')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
              Text('×')
                .fontSize(16)
                .fontColor(Color.Gray)
                .onClick(() => {
                  this.clearFile();
                })
            }
          }
          .width('100%')

          Row({ space: 12 }) {
            Button(this.parsing ? '解析中…' : '解析')
              .fontSize(15)
              .enabled(!this.parsing && (this.inputText.trim().length > 0
                || this.imageName.length > 0 || this.fileName.length > 0))
              .onClick(() => {
                this.parseNow();
              })
            Button(this.saving ? '保存中…' : '确定')
              .fontSize(15)
              .enabled(!this.saving && !this.parsing
                && (this.inputText.trim().length > 0 || this.parsed !== null
                  || this.imageName.length > 0))
              .onClick(() => {
                this.confirmSave();
              })
          }
          .width('100%')

          if (this.hint.length > 0) {
            Text(this.hint)
              .fontSize(12)
              .fontColor('#C1663D')
              .width('100%')
          }

          if (this.parsed !== null) {
            Column({ space: 8 }) {
              Text('解析结果')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .width('100%')

              Row({ space: 6 }) {
                Text(this.evKind().length > 0 ? this.evKind() : '未分类')
                  .fontSize(12)
                  .fontColor(Color.White)
                  .backgroundColor(this.evKindColor())
                  .borderRadius(4)
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                Text(this.evTitle().length > 0 ? this.evTitle() : this.inputText.trim())
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
                Text(this.evConfText())
                  .fontSize(11)
                  .fontColor(this.evConfColor())
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)

              if (!this.hasEventCard()) {
                Text('这句话更像闲聊/无明确事项，仍可保存为低优先级待办')
                  .fontSize(12)
                  .fontColor('#C1663D')
                  .width('100%')
              }

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
              if (this.evDeadline().length > 0) {
                Text('截止：' + this.evDeadline())
                  .fontSize(14)
                  .fontColor('#B8434E')
                  .width('100%')
              }
              if (this.evItemsText().length > 0) {
                Text('需带/注意：' + this.evItemsText())
                  .fontSize(14)
                  .fontColor('#2F8F9D')
                  .width('100%')
              }

              if (this.entities.length > 0) {
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.entities, (e: ParsedEntity, index: number) => {
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
                  }, (e: ParsedEntity, index: number) => index + '_' + e.type + '_' + e.text)
                }
                .width('100%')
              }

              Text(this.candidate !== null
                ? '来源：后端解析（' + (this.candidate.engine === 'llm' ? '模型' : '规则') + '）'
                : '来源：本机规则解析')
                .fontSize(12)
                .fontColor(Color.Gray)
                .width('100%')
            }
            .width('100%')
            .padding(12)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor('#F5F3FA')
            .borderRadius(8)
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 24 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
  }
}
