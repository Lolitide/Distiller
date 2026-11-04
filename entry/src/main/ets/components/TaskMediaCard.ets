/**
 * 任务详情 · 图片 / 文件 / 扫码链接卡片。
 *
 * 位置：步骤下方、提醒（属性卡）上方。
 * 交互：图片点开**系统图片预览器**（官方能力，不自造）；文件/链接点开系统查看器。
 * 数据：`Task.urls`（本机图片/文件 uri）与 `Task.linkUrl`（扫码得到的 URL）。
 *
 * ⚠️ 2026-11-03 AGC 审核实测 bug（HarmonyOS 6.1 / Pura 80 Ultra）：
 * 「任务列表 → 任务 → 图片与文件 → 点图」报「该文件可能移动或重命名，预览失败」。
 * 一共三个原因，分别修在三处：
 *  ① 存的 URI 是**相册临时 URI**（进程结束即失效）→ 选图时先复制进应用沙箱再存
 *     （`service/system/MediaPickService.ets`）；
 *  ② 交给系统预览器时**没给读授权** → `flags: FLAG_AUTH_READ_URI_PERMISSION`（沙箱文件别的应用读不到）；
 *  ③ 交给系统预览器的 `type` 给了通配 `image/*` → 预览器日志里是
 *     `mimeType: "image/*"` + `LOAD FAILED, openType: 8`，界面就是「预览失败」；
 *     必须给**与扩展名一致的精确 MIME**（官方 FAQ `faqs-ability-124`：type 必须与 uri 文件类型一致）。
 *
 * 另外：升级前创建的任务里存的是已失效的相册 URI，读不出来时缩略图换成「原图已不可用」占位，
 * 并**不给点**（点了只会再弹一次系统的「预览失败」）。
 */
import { common, wantConstant } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Theme, ThemeStore } from '../utils/Theme';
import { Task } from '../model';

const DOMAIN: number = 0x0000;
const TAG: string = 'TaskMediaCard';
const IMAGE_EXTS: string[] = ['.png', '.jpg', '.jpeg', '.webp', '.bmp', '.gif', '.heic'];
const THUMB_SIZE_VP: number = 92;

/**
 * 扩展名 → 精确 MIME（给系统预览器用）。
 *
 * 为什么不能笼统给 `image/*`：见文件头 ③，预览器会按 type 选内部 loader，通配符直接判 LOAD FAILED。
 */
const IMAGE_MIME: Map<string, string> = new Map<string, string>([
  ['.png', 'image/png'],
  ['.jpg', 'image/jpeg'],
  ['.jpeg', 'image/jpeg'],
  ['.webp', 'image/webp'],
  ['.bmp', 'image/bmp'],
  ['.gif', 'image/gif'],
  ['.heic', 'image/heic']
]);

@ComponentV2
export struct TaskMediaCard {
  @Local themeStore: ThemeStore = ThemeStore.instance();
  @Require @Param task: Task;
  /** 读不出来的图（老数据里的相册临时 URI、用户清过缓存的）：显示占位，不再显示裂图 */
  @Local brokenUris: string[] = [];

  private isImage(uri: string): boolean {
    const lower: string = uri.toLowerCase();
    for (let i: number = 0; i < IMAGE_EXTS.length; i++) {
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
    for (let i: number = 0; i < urls.length; i++) {
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
    for (let i: number = 0; i < urls.length; i++) {
      if (!this.isImage(urls[i])) {
        out.push(urls[i]);
      }
    }
    return out;
  }

  private isBroken(uri: string): boolean {
    return this.brokenUris.indexOf(uri) >= 0;
  }

  /** 记下读不出来的图（整组换新数组，V2 才能观测到） */
  private markBroken(uri: string): void {
    if (this.isBroken(uri)) {
      return;
    }
    this.brokenUris = this.brokenUris.concat([uri]);
  }

  /** 只取 uri 最后一段给用户看（不显示完整沙箱路径） */
  private displayName(uri: string): string {
    const pos: number = uri.lastIndexOf('/');
    return pos >= 0 ? uri.substring(pos + 1) : uri;
  }

  /** 图片的精确 MIME（非图片返回 undefined，让系统按扩展名自己匹配） */
  private mimeOf(uri: string): string | undefined {
    const lower: string = uri.toLowerCase();
    for (let i: number = 0; i < IMAGE_EXTS.length; i++) {
      if (lower.endsWith(IMAGE_EXTS[i])) {
        return IMAGE_MIME.get(IMAGE_EXTS[i]);
      }
    }
    return undefined;
  }

  /** 单独取链接（避免在 build 里写类型断言） */
  private openLink(): void {
    const url: string | undefined = this.task.linkUrl;
    if (url !== undefined && url.length > 0) {
      this.open(url);
    }
  }

  /**
   * 交给系统打开（图片 → 系统图片预览器；文件 → 系统查看器）。
   *
   * ⚠️ 两件事都不能少，否则系统预览器就是一句「预览失败」：
   *  ① `FLAG_AUTH_READ_URI_PERMISSION` —— URI 是**本应用沙箱**里的文件，别的应用默认读不到；
   *  ② `type` 给**精确 MIME**（`image/png` 而不是 `image/*`，见 `IMAGE_MIME`）。
   */
  private open(uri: string): void {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    const ability: common.UIAbilityContext = context as common.UIAbilityContext;
    ability.startAbility({
      action: 'ohos.want.action.viewData',
      uri: uri,
      type: this.mimeOf(uri),
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION
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

  /** 读不出来的图：占位块（**不给点**，点了只会再弹一次系统「预览失败」） */
  @Builder
  brokenThumb() {
    Column({ space: 2 }) {
      SymbolGlyph($r('sys.symbol.exclamationmark_circle'))
        .fontSize(18)
        .fontColor([this.themeStore.scheme.outline])
      Text('原图已不可用')
        .fontSize(9)
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .maxLines(1)
    }
    .width(THUMB_SIZE_VP)
    .height(THUMB_SIZE_VP)
    .borderRadius(10)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.themeStore.scheme.surfaceContainerHigh)
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
              if (this.isBroken(uri)) {
                this.brokenThumb()
              } else {
                Image(uri)
                  .width(THUMB_SIZE_VP)
                  .height(THUMB_SIZE_VP)
                  .borderRadius(10)
                  .objectFit(ImageFit.Cover)
                  .onError((err: ImageError) => {
                    const code: number = err.error !== undefined ? err.error.code : 0;
                    hilog.warn(DOMAIN, TAG, 'thumb image failed: code=%{public}d msg=%{public}s', code, err.message);
                    this.markBroken(uri);
                  })
                  .onClick(() => {
                    this.open(uri);
                  })
              }
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
