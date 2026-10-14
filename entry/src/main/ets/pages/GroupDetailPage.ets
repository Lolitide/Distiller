import { Store } from '../common/Store';
import { RobotMessage, formatTime } from '../common/Types';
import { GroupParams, messagesOfGroup, labelOfGroup } from '../common/GroupIndex';
import { CampusEvent, isActionable, EVENT_NOTICE, EVENT_PLAN, EVENT_TODO } from '../nlp/EventTypes';
import { clusterEvents, EventCluster } from '../nlp/EventCluster';
import { clip } from '../nlp/TextUtil';
import { BottomNav } from '../common/BottomNav';

/**
 * 某个群的事项页：只看这个群的待办/通知/活动/出行计划。
 * 与群聊卡片用同一套 event.kind 判定，保证两处口径一致。
 */
@Entry
@Component
struct GroupDetailPage {
  @State clusters: EventCluster[] = [];
  @State groupLabel: string = '';
  @State msgCount: number = 0;

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as GroupParams;
    const openid: string = params !== undefined && params.openid !== undefined ? params.openid : '';
    const all: RobotMessage[] = Store.getMessages();
    const mine: RobotMessage[] = messagesOfGroup(all, openid);
    this.groupLabel = labelOfGroup(all, openid);
    this.msgCount = mine.length;

    const evs: CampusEvent[] = [];
    for (let i = 0; i < mine.length; i++) {
      const e: CampusEvent | undefined = mine[i].event;
      if (e !== undefined && isActionable(e.kind)) {
        evs.push(e);
      }
    }
    this.clusters = clusterEvents(evs);
  }

  kindColor(kind: string): string {
    if (kind === EVENT_TODO) {
      return '#2E75B6';
    }
    if (kind === EVENT_NOTICE) {
      return '#B8434E';
    }
    if (kind === EVENT_PLAN) {
      return '#2F8F9D';
    }
    return '#8A5CC7';
  }

  senderText(c: EventCluster): string {
    let s: string = '';
    for (let i = 0; i < c.senders.length; i++) {
      s = s.length === 0 ? c.senders[i] : s + '、' + c.senders[i];
    }
    return s.length === 0 ? '未知' : s;
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Button('返回')
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
        Column({ space: 2 }) {
          Text(this.groupLabel.length > 0 ? this.groupLabel : '群事项')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.clusters.length + ' 条事项 · 来自 ' + this.msgCount + ' 条消息')
            .fontSize(12)
            .fontColor(Color.Gray)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.clusters.length === 0) {
        Column({ space: 8 }) {
          Text('这个群暂无事项')
            .fontSize(16)
            .fontColor(Color.Gray)
          Text('待办 / 通知 / 活动 / 出行计划才会进这里')
            .fontSize(12)
            .fontColor(Color.Gray)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.clusters, (c: EventCluster, index: number) => {
            ListItem() {
              Column({ space: 6 }) {
                Row({ space: 6 }) {
                  Text(c.kind)
                    .fontSize(11)
                    .fontColor(Color.White)
                    .backgroundColor(this.kindColor(c.kind))
                    .borderRadius(4)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  Text(c.title)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                  Text(c.count + ' 条')
                    .fontSize(12)
                    .fontColor(Color.Gray)
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)

                if (c.oneLine.length > 0) {
                  Text(clip(c.oneLine, 80))
                    .fontSize(13)
                    .fontColor('#333333')
                    .width('100%')
                    .maxLines(3)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                if (c.place.length > 0) {
                  Text('地点：' + c.place)
                    .fontSize(12)
                    .fontColor('#333333')
                    .width('100%')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                Text(formatTime(c.spanStart) + ' → ' + formatTime(c.spanEnd) + ' · 来自：' + this.senderText(c))
                  .fontSize(11)
                  .fontColor('#999999')
                  .width('100%')
              }
              .width('100%')
              .padding(12)
              .alignItems(HorizontalAlign.Start)
              .backgroundColor(Color.White)
              .borderRadius(8)
              .border({ width: 1, color: '#EEEEEE' })
            }
          }, (c: EventCluster, index: number) => index + '_' + c.kind + '_' + c.title + '_' + c.count)
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
