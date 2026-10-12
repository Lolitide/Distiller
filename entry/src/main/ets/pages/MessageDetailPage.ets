import { pasteboard } from '@kit.BasicServicesKit';
import { Store } from '../common/Store';
import { ParseService } from '../common/ParseService';
import { RobotMessage, DetailParams, ParsedEntity } from '../common/Types';
import { EntityIcon } from '../common/UiParts';

@Entry
@Component
struct MessageDetailPage {
  @State msg: RobotMessage | undefined = undefined;
  @State reparsing: boolean = false;
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
              Text(this.msg.content)
                .fontSize(16)
                .width('100%')
                .textAlign(TextAlign.Start)
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
