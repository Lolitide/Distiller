import { pasteboard } from '@kit.BasicServicesKit';
import { Store } from '../common/Store';
import { RobotMessage, DetailParams } from '../common/Types';

@Entry
@Component
struct MessageDetailPage {
  @State msg: RobotMessage | undefined = undefined;

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as DetailParams;
    const id: string = params?.msgId ?? '';
    if (id.length === 0) {
      return;
    }
    const list: RobotMessage[] = Store.getMessages();
    for (let i = 0; i < list.length; i++) {
      if (list[i].msg_id === id) {
        this.msg = list[i];
        return;
      }
    }
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
        Column({ space: 12 }) {
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

          Row({ space: 12 }) {
            if (!this.msg.handled) {
              Button('转成待办')
                .onClick(() => {
                  this.handleToTask();
                })
            } else {
              Text('已转成待办')
                .fontColor(Color.Green)
            }
            Button('复制正文')
              .onClick(() => {
                this.copyContent();
              })
            Button('删除')
              .onClick(() => {
                this.deleteMessage();
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .height('100%')
  }
}
