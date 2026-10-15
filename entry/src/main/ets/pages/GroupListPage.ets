import { Store } from '../common/Store';
import { RobotMessage, formatTime } from '../common/Types';
import { safePush } from '../common/UiParts';
import { GroupCard, GroupParams, buildGroupCards } from '../common/GroupIndex';
import { BottomNav } from '../common/BottomNav';

/**
 * 群聊页：按群列出卡片（哪个群有多少条事项），点进去只看这个群的事项。
 * 解决「所有群的通知混在一起、看不出是哪个群」的问题。
 */
@Entry
@Component
struct GroupListPage {
  @State cards: GroupCard[] = [];
  @State totalMessages: number = 0;

  aboutToAppear(): void {
    const msgs: RobotMessage[] = Store.getMessages();
    this.totalMessages = msgs.length;
    this.cards = buildGroupCards(msgs);
  }

  openGroup(openid: string): void {
    const p: GroupParams = { openid: openid };
    safePush(this.getUIContext(), 'pages/GroupDetailPage', p);
  }

  @Builder
  groupCard(c: GroupCard) {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        Text(c.label.length > 0 ? c.label : c.openid)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        if (c.todo > 0) {
          Text(c.todo + ' 条事项')
            .fontSize(12)
            .fontColor(Color.White)
            .backgroundColor('#B8434E')
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        } else {
          Text('暂无事项')
            .fontSize(12)
            .fontColor('#999999')
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(c.total + ' 条消息' + (c.lastTime.length > 0 ? ' · 最近 ' + formatTime(c.lastTime) : ''))
        .fontSize(12)
        .fontColor('#999999')
        .width('100%')
    }
    .width('100%')
    .padding(12)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .border({ width: 1, color: '#EEEEEE' })
    .onClick(() => {
      this.openGroup(c.openid);
    })
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Text('群聊')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        Text(this.cards.length + ' 个群 · ' + this.totalMessages + ' 条消息')
          .fontSize(12)
          .fontColor(Color.Gray)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.cards.length === 0) {
        Column({ space: 8 }) {
          Text('还没有收到消息')
            .fontSize(16)
            .fontColor(Color.Gray)
          Text('确认机器人已进群、且已订阅这些群')
            .fontSize(12)
            .fontColor(Color.Gray)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.cards, (c: GroupCard, index: number) => {
            ListItem() {
              this.groupCard(c)
            }
          }, (c: GroupCard, index: number) => c.openid + '_' + c.total + '_' + c.todo)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
      }

      BottomNav({ current: 'group' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }
}
