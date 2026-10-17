/*
 * 「添加任务 · 截图」内容区 —— 点一下拉起系统相册选一张截图，选完就地预览。
 *
 * 需求方 2026-10-17：「下面做一块内容区…点击截图是选择截图」。
 *
 * 交互：
 *  · 未选 —— 「图示 ＋ 选择截图」一块可点区域（底色 `comp_background_secondary`、圆角官方档）；
 *  · 已选 —— 同一块区域换成图片预览（`ImageFit.Cover`，同样的圆角），**再点一次就重新选**。
 *
 * 系统能力不出这个组件：选图走 `service/system` 的桶（`pickSingleImage`），
 * 组件只拿结果、不 import photoAccessHelper（`references/02-编码规约.md` 落位规则 2）。
 * 选图**不需要任何权限**：系统 picker 是安全组件，返回的 URI 带持久授权（见 `MediaPickService` 顶部注释）。
 *
 * ⚠️ 还没做的：选中截图之后的**文字识别（OCR）与字段抽取** —— 那是下一步，
 * 要按项目纪律走 `service/ai`（Core Vision Kit 的 OCR **不支持模拟器、且必须动态 import**）。
 */
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MediaPickResult, pickSingleImage } from '../service/system';
import { AddTaskDraft } from '../viewmodel/AddTaskDraft';

const DOMAIN: number = 0x0000;
const TAG: string = 'AddTaskScreenshotPicker';

/**
 * 选图区高度（vp）。
 * 取值依据：设计稿 `api/知了设计UI/添加任务.svg`（428 宽画板）里那块图片区高 **124**，
 * 换算到 428→360vp 的手机屏约 104vp；这里取整到 **120vp**，既能放下缩略图预视，也不至于把半模态撑满。
 * 官方没有"图片选择区高度"这类 token，所以按约定提成常量并在此标注出处（与 `MainTabBar.ADD_BUTTON_SIZE` 同一个做法）。
 */
const PICK_AREA_HEIGHT_VP: number = 120;

@ComponentV2
export struct AddTaskScreenshotPicker {
  /** 表单草稿：选中的图片 URI 存 `draft.imageUri`（保存时作为任务的 `urls` 落进去） */
  @Require @Param draft: AddTaskDraft;
  /** 防止连点重复拉起 picker（拉起时页面会被系统页盖住，连点会造成两次 select） */
  @Local picking: boolean = false;

  /** 拉起系统相册选一张图；取消不动、失败给一次可见反馈 */
  private async pick(): Promise<void> {
    if (this.picking) {
      return;
    }
    this.picking = true;
    const result: MediaPickResult = await pickSingleImage();
    this.picking = false;
    if (result.uri !== '') {
      this.draft.imageUri = result.uri;
      return;
    }
    if (result.cancelled) {
      return;
    }
    hilog.error(DOMAIN, TAG, 'pick failed, code=%{public}d', result.errorCode);
    try {
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.add_task_pick_failed') });
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'show toast failed: %{public}d, %{public}s', err.code, err.message);
    }
  }

  /** 未选态：可点的占位块（图示 + 一句提示） */
  @Builder
  emptyArea() {
    Column({ space: $r('sys.float.padding_level2') }) {
      SymbolGlyph($r('sys.symbol.picture'))
        .fontSize($r('sys.float.subheader_right_icon_size'))
        .fontColor([$r('sys.color.icon_secondary')])

      Text($r('app.string.add_task_screenshot_hint'))
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
    }
    .width('100%')
    .height(PICK_AREA_HEIGHT_VP)
    .justifyContent(FlexAlign.Center)
    // 需求方 2026-10-17：「内容区背景太灰了 和 button 那个背景灰一样吧」——
    // 原来用 `comp_background_secondary`（比页面灰还深一档），改成**来源按钮那条胶囊轨道的灰**
    // （`segment_button_v2_capsule_button_background`），两块观感统一。
    .backgroundColor($r('sys.color.segment_button_v2_capsule_button_background'))
    .borderRadius($r('sys.float.corner_radius_level8'))
    .onClick(() => {
      this.pick();
    })
    .accessibilityText($r('app.string.add_task_screenshot_hint'))
  }

  /** 已选态：就地预览，再点一次重新选 */
  @Builder
  previewArea() {
    Image(this.draft.imageUri)
      .width('100%')
      .height(PICK_AREA_HEIGHT_VP)
      .objectFit(ImageFit.Cover)
      .borderRadius($r('sys.float.corner_radius_level8'))
      .onClick(() => {
        this.pick();
      })
      .accessibilityText($r('app.string.add_task_screenshot_reselect'))
  }

  build() {
    // 根节点用一个 Stack 兜住两种态（build 必须有唯一容器）
    Stack() {
      if (this.draft.imageUri === '') {
        this.emptyArea()
      } else {
        this.previewArea()
      }
    }
    .width('100%')
  }
}
