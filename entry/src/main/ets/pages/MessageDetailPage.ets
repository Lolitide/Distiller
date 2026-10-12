import { pasteboard } from '@kit.BasicServicesKit';
import { Store } from '../common/Store';
import { ParseService } from '../common/ParseService';
import { RobotMessage, DetailParams, ParsedEntity, firstImageUrl } from '../common/Types';
import { EntityIcon } from '../common/UiParts';
import { CampusEvent, EVENT_NOTICE, EVENT_PLAN, EVENT_TODO } from '../nlp/EventTypes';
import { timeSlotDisplay } from '../nlp/TimeParser';

@Entry
@Component
struct MessageDetailPage {
  @State msg: RobotMessage | undefined = undefined;
  @State reparsing: boolean = false;
  @State imageFailed: boolean = false;
  @State showFullImageText: boolean = false;
  private currentId: string = '';

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as DetailParams;
    this.currentId = params?.msgId ?? '';
    this.loadMsg();
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
        return;
      }
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

  handleToTask(): void {
    if (this.msg === undefined) {
      return;
    }
    Store.markAsTaskSource(this.msg);
    this.setHandled(this.msg.msg_id);
    this.getUIContext().getPromptAction().showToast({ message: '已交给解析' });
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
    this.getUIContext().getPromptAction().showToast({ message: '已重新解析' });
  }

  async copyContent(): Promise<void> {
    if (this.msg === undefined) {
      return;
    }
    try {
      const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.msg.content);
      const sp: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      await sp.setData(pasteData);
      this.getUIContext().getPromptAction().showToast({ message: '已复制正文' });
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: '复制失败' });
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

              if (this.hasImage() && !this.imageFailed) {
                Image(this.imageUrl())
                  .width('100%')
                  .constraintSize({ maxHeight: 320 })
                  .objectFit(ImageFit.Contain)
                  .onError(() => {
                    this.imageFailed = true;
                  })
              } else if (this.hasImage()) {
                Text('[图片加载失败或链接已过期]')
                  .fontSize(13)
                  .fontColor(Color.Gray)
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

            Flex({ wrap: FlexWrap.Wrap }) {
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
