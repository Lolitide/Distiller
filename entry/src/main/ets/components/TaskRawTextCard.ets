/**
 * 任务详情 · 原文卡：显示这条待办是从哪段原文整理出来的（粘贴、截图 OCR、语音转写或群消息）。
 *
 * 为什么放详情页：确认时用户已经看过一次；事后想核对「当时到底说了什么」，
 * 应该在这条任务自己的详情里能找到，而不是回添加页找。
 */
import { Task } from '../model';
import { Theme, ThemeStore } from '../utils/Theme';

@ComponentV2
export struct TaskRawTextCard {
  @Require @Param task: Task;
  @Local themeStore: ThemeStore = ThemeStore.instance();
  @Local expanded: boolean = false;

  private hasRaw(): boolean {
    return this.task.rawText !== undefined && this.task.rawText.trim().length > 0;
  }

  build() {
    if (this.hasRaw()) {
      Column({ space: 8 }) {
        Row() {
          Text('原文')
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.themeStore.scheme.onSurface)
          Blank()
          Text(this.expanded ? '收起' : '展开')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(this.themeStore.scheme.primary)
            .onClick(() => {
              this.expanded = !this.expanded;
            })
        }
        .width('100%')

        Text(this.task.rawText)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.themeStore.scheme.onSurfaceVariant)
          .lineHeight(19)
          .maxLines(this.expanded ? 50 : 3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
      .borderRadius(Theme.RADIUS_CARD)
    }
  }
}
