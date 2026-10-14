// 来源：documentId = API参考/ArkUI_方舟UI框架/ArkTS组件/滚动与滑动/LazyVWaterFlowLayout/ts-container-lazyvwaterflowlayout
// 行范围：L437-L535
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

import { LengthMetrics, LazyVWaterFlowLayout, LazyVWaterFlowLayoutAttribute } from '@kit.ArkUI';
// MyDataSource是自定义数据源类，实现了LazyForEach所需的IDataSource接口
import { MyDataSource } from './MyDataSource';

@Entry
@Component
struct LazyVWaterFlowLayoutStickyDemo {
  private arr : MyDataSource<number> = new MyDataSource<number>();

  // 返回随机高度
  private itemHeight(index: number): number {
    return 80 + (index * 37 % 121);
  }

  private itemColor(index: number): string {
    const colors: string[] = ['#FFE0B2', '#C8E6C9', '#BBDEFB', '#F8BBD0', '#D1C4E9', '#FFF9C4'];
    return colors[index % colors.length];
  }

  // 构建头部组件
  @Builder
  HeaderBuilder() {
    Column() {
      Text('Header')
        .fontSize(16)
        .fontColor(Color.Black)
    }
    .height(50)
    .width('100%')
    .borderRadius(8)
    .backgroundColor('#BBDEFB')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  FooterBuilder() {
    Column() {
      Text('Footer')
        .fontSize(16)
        .fontColor(Color.Black)
    }
    .height(40)
    .width('100%')
    .borderRadius(8)
    .backgroundColor('#D1C4E9')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Scroll() {
        LazyVWaterFlowLayout() {
          LazyForEach(this.arr, (item: number) => {
            Column() {
              Text('item ' + item.toString())
                .fontSize(16)
                .fontColor(Color.Black)
            }
            .height(this.itemHeight(item))
            .width('100%')
            .borderRadius(8)
            .backgroundColor(this.itemColor(item))
            .justifyContent(FlexAlign.Center)
          })
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(LengthMetrics.vp(10))
        .columnsGap(LengthMetrics.vp(10))
        .header(this.HeaderBuilder)
        .footer(this.FooterBuilder)
        // 设置头部和尾部同时吸附
        .sticky(StickyStyle.BOTH)
        .onVisibleIndexesChange((start: number, end: number) => {
          console.info('LazyVWaterFlowLayout visible indexes: start: ' + start + ', end: ' + end);
          // 滚动监听：即将触底时提前加载更多数据
          if (end + 20 >= this.arr.totalCount()) {
            // 添加100个新数据到数据源
            let currentCount = this.arr.totalCount();
            for (let i = currentCount; i < currentCount + 100; i++) {
              this.arr.pushData(i);
            }
          }
        })
      }
      .padding(10)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#DCDCDC')
  }

  aboutToAppear(): void {
    for (let i = 0; i < 100; i++) {
      this.arr.pushData(i);
    }
  }
}
```
