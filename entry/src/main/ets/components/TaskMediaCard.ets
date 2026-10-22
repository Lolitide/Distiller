/**
 * 任务详情 · 图片 / 文件 / 扫码链接卡片。
 *
 * 位置：步骤下方、提醒（属性卡）上方。
 * 交互：图片点开大图（系统预览），文件/链接点开系统查看器。
 * 数据：`Task.urls`（本机图片/文件 uri）与 `Task.linkUrl`（扫码得到的 URL）。
 */
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Theme, ThemeStore } from '../utils/Theme';
import { Task } from '../model';

const IMAGE_EXTS: string[] = ['.png', '.jpg', '.jpeg', '.webp', '.bmp', '.gif', '.heic'];
const THUMB_SIZE_VP: number = 92;

@ComponentV2
export struct TaskMediaCard {
  @Local themeStore: ThemeStore = ThemeStore.instance();
  @Require @Param task: Task;

  private isImage(uri: string): boolean {
    const lower: string = uri.toLowerCase();
    for (let i = 0; i < IMAGE_EXTS.length; i++) {
      if (lower.endsWith(IMAGE_EXTS[i])) {
        return true;
      }
    }
    return false;
  }

  private images(): string[] {
    const out: string[] = [];
    const urls: string[] | undefined = this.task.urls;
    if (urls === undefined) {
      return out;
    }
    for (let i = 0; i < urls.length; i++) {
      if (this.isImage(urls[i])) {
        out.push(urls[i]);
      }
    }
    return out;
  }

  private files(): string[] {
    const out: string[] = [];
    const urls: string[] | undefined = this.task.urls;
    if (urls === undefined) {
      return out;
    }
    for (let i = 0; i < urls.length; i++) {
      if (!this.isImage(urls[i])) {
        out.push(urls[i]);
      }
    }
    return out;
  }

  /** 只取 uri 最后一段给用户看（不显示完整沙箱路径） */
  private displayName(uri: string): string {
    const pos: number = uri.lastIndexOf('/');
    return pos >= 0 ? uri.substring(pos + 1) : uri;
  }

  /** 单独取链接（避免在 build 里写类型断言） */
  private openLink(): void {
    const url: string | undefined = this.task.linkUrl;
    if (url !== undefined && url.length > 0) {
      this.open(url);
    }
  }

  private open(uri: string): void {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    const ability: common.UIAbilityContext = context as common.UIAbilityContext;
    ability.startAbility({
      action: 'ohos.want.action.viewData',
      uri: uri
    }).catch((error: BusinessError) => {
      try {
        this.getUIContext().getPromptAction().showToast({ message: '打不开：' + error.message });
      } catch (e2) {
        // toast 失败不影响主流程
      }
    });
  }

  @Builder
  fileRow(uri: string) {
    Row({ space: 10 }) {
      Text(this.displayName(uri))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
      Text('打开')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(this.themeStore.scheme.primary)
    }
    .width('100%')
    .height(40)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.open(uri);
    })
  }

  build() {
    Column({ space: 10 }) {
      Text('图片与文件')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .width('100%')
        .textAlign(TextAlign.Start)

      if (this.images().length > 0) {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.images(), (uri: string) => {
              Image(uri)
                .width(THUMB_SIZE_VP)
                .height(THUMB_SIZE_VP)
                .borderRadius(10)
                .objectFit(ImageFit.Cover)
                .onClick(() => {
                  this.open(uri);
                })
            }, (uri: string) => uri)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }

      ForEach(this.files(), (uri: string) => {
        this.fileRow(uri)
      }, (uri: string) => uri)

      if (this.task.linkUrl !== undefined && this.task.linkUrl.length > 0) {
        Row({ space: 10 }) {
          SymbolGlyph($r('sys.symbol.link'))
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor([this.themeStore.scheme.primary])
          Text(this.task.linkUrl)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(this.themeStore.scheme.primary)
            .decoration({ type: TextDecorationType.Underline })
          Text('打开')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(this.themeStore.scheme.primary)
        }
        .width('100%')
        .height(40)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.openLink();
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
    .borderRadius(Theme.RADIUS_CARD)
    .alignItems(HorizontalAlign.Start)
  }
}
