import { Store } from '../common/Store';
import { RobotMessage, formatTime } from '../common/Types';
import { CampusEvent, EVENT_NOTICE, EVENT_PLAN, EVENT_TODO } from '../nlp/EventTypes';
import { clusterEvents, pickDigestClusters, EventCluster } from '../nlp/EventCluster';
import { clip } from '../nlp/TextUtil';

/**
 * 群汇总详情：展开全部事件簇。
 * 与首页那张卡片用同一套 pickDigestClusters 排序，保证两处口径一致。
 */
@Entry
@Component
struct DigestPage {
  @State clusters: EventCluster[] = [];
  @State totalMessages: number = 0;

  aboutToAppear(): void {
    const msgs: RobotMessage[] = Store.getMessages();
    this.totalMessages = msgs.length;
    const evs: CampusEvent[] = [];
    for (let i = 0; i < msgs.length; i++) {
      const e: CampusEvent | undefined = msgs[i].event;
      if (e !== undefined) {
        evs.push(e);
      }
    }
    this.clusters = pickDigestClusters(clusterEvents(evs));
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

  tagText(c: EventCluster): string {
    let s: string = '';
    for (let i = 0; i < c.tags.length; i++) {
      s = s.length === 0 ? c.tags[i] : s + ' · ' + c.tags[i];
    }
    return s;
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Button('返回')
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
        Text('群汇总')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 4 })

      Text(this.clusters.length + ' 个事件 · 来自 ' + this.totalMessages + ' 条消息')
        .fontSize(13)
        .fontColor(Color.Gray)
        .width('100%')
        .padding({ left: 16, right: 16 })

      if (this.clusters.length === 0) {
        Column({ space: 8 }) {
          Text('暂无可汇总的事件')
            .fontSize(16)
            .fontColor(Color.Gray)
          Text('消息多为闲聊或噪声时不会生成事件')
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
                  Text(clip(c.oneLine))
                    .fontSize(13)
                    .fontColor('#333333')
                    .width('100%')
                    .maxLines(3)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                if (c.tags.length > 0) {
                  Text(this.tagText(c))
                    .fontSize(11)
                    .fontColor('#3E9E6B')
                    .width('100%')
                }
                if (c.place.length > 0) {
                  Text('地点：' + c.place)
                    .fontSize(12)
                    .fontColor('#333333')
                    .width('100%')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                Text(formatTime(c.spanStart) + ' → ' + formatTime(c.spanEnd))
                  .fontSize(11)
                  .fontColor('#999999')
                  .width('100%')
                Text('来自：' + this.senderText(c))
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
        .padding({ left: 16, right: 16, bottom: 16 })
      }
    }
    .width('100%')
    .height('100%')
  }
}
