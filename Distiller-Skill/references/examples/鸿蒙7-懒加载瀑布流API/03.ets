// 来源：documentId = API参考/ArkUI_方舟UI框架/ArkTS组件/滚动与滑动/LazyVWaterFlowLayout/ts-container-lazyvwaterflowlayout
// 行范围：L544-L663
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

import {
  LengthMetrics,
  LazyColumnLayout,
  LazyColumnLayoutAttribute,
  LazyVWaterFlowLayout,
  LazyVWaterFlowLayoutAttribute,
} from '@kit.ArkUI';
// MyDataSource是自定义数据源类，实现了LazyForEach所需的IDataSource接口
import { MyDataSource } from './MyDataSource';

@Entry
@Component
struct LazyVWaterFlowLayoutColumnsTemplateDemo {
  private autoFillData: MyDataSource<number> = new MyDataSource<number>();
  private breakpointData: MyDataSource<number> = new MyDataSource<number>();
  private breakpointPolicy: ItemFillPolicy = { fillType: PresetFillType.BREAKPOINT_DEFAULT };

  aboutToAppear(): void {
    // 初始化固定数量的数据，不进行滚动触底加载
    for (let i = 0; i < 18; i++) {
      this.autoFillData.pushData(i);
      this.breakpointData.pushData(i);
    }
  }

  private itemHeight(index: number): number {
    return 80 + (index * 37 % 121)
  }

  private itemColor(index: number): string {
    const colors: string[] = ['#CDE7FF', '#D8F5D0', '#FFE6A8', '#F8D7DA', '#E4D7FF', '#D2F4EA']
    return colors[index % colors.length]
  }

  @Builder
  ModeTitle(title: string, description: string) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#182230')
      Text(description)
        .fontSize(12)
        .fontColor('#667085')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ bottom: 8 })
  }

  @Builder
  AutoFillHeader() {
    this.ModeTitle('repeat(auto-fill, 96vp)',
      '固定列宽为96vp，LazyVWaterFlowLayout根据可用宽度自动计算瀑布流列数。')
  }

  @Builder
  BreakpointHeader() {
    this.ModeTitle('ItemFillPolicy: BREAKPOINT_DEFAULT',
      '根据组件宽度对应的断点类型确定列数，sm及以下为2列，md为3列，lg及以上为5列。')
  }

  @Builder
  WaterFlowItemBuilder(item: number) {
    Text('item ' + item)
      .height(this.itemHeight(item))
      .width('100%')
      .borderRadius(8)
      .backgroundColor(this.itemColor(item))
      .fontColor('#182230')
      .textAlign(TextAlign.Center)
  }

  build() {
    Column() {
      Scroll() {
        LazyColumnLayout() {
          // repeat(auto-fill, 96vp)：固定列宽为96vp，根据可用宽度自动计算瀑布流列数
          LazyVWaterFlowLayout() {
            LazyForEach(this.autoFillData, (item: number) => {
              this.WaterFlowItemBuilder(item)
            })
          }
          .columnsTemplate('repeat(auto-fill, 96)')
          .rowsGap(LengthMetrics.vp(8))
          .columnsGap(LengthMetrics.vp(8))
          .header(this.AutoFillHeader)
          .padding(8)
          .backgroundColor('#F7F9FC')
          .border({ width: 1, color: '#D0D5DD' })
          .borderRadius(8)

          // ItemFillPolicy：根据组件宽度对应的断点类型确定列数
          LazyVWaterFlowLayout() {
            LazyForEach(this.breakpointData, (item: number) => {
              this.WaterFlowItemBuilder(item)
            })
          }
          .columnsTemplate(this.breakpointPolicy)
          .rowsGap(LengthMetrics.vp(8))
          .columnsGap(LengthMetrics.vp(8))
          .header(this.BreakpointHeader)
          .padding(8)
          .backgroundColor('#F7F9FC')
          .border({ width: 1, color: '#D0D5DD' })
          .borderRadius(8)
        }
        .space(LengthMetrics.vp(16))
        .width('100%')
      }
      .width('100%')
      .scrollable(ScrollDirection.Vertical)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ top: 48, left: 12, right: 12, bottom: 12 })
  }
}
```
