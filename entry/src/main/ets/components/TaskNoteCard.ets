/*
 * 任务详情的「备注」卡（需求方 2026-10-17 的设计图：一块高一点的卡片，左上角写「添加备注」）。
 *
 * 与上面几张卡不同，这张**本身就是可编辑的多行文本框**（不是「点一下才变成输入框」）：
 * 备注是一整块文字，点进来就该能直接写，多一次「点开」没有意义。
 *
 * 两个硬要求都靠官方 `TextArea` 的默认行为满足（API 参考《TextArea》原话：
 * 「**高度未设置时，组件无默认高度，自适应内容高度**。宽度未设置时，默认撑满最大宽度」；
 * 「当输入的文本内容超过组件宽度时会自动换行显示」）：
 *  ① **自动换行** —— 不设 maxLines、不设 `textOverflow`；
 *  ② **卡片往下变长** —— 不设 `height`，只给 `constraintSize({ minHeight })` 保底，
 *     内容变多时 TextArea 自己长高、外层卡片跟着长（卡片只负责白底与圆角，不锁高度）。
 *
 * 数据口径：读写 `Task.note`（字段表第 5 项「备注（总结）」）。
 * ⚠️ 字段表 §3 数据边界写明 `note` **绝不出手机** —— 所以这里只在本地改，不发任何请求。
 * 写入时机：**失焦 / 离开页面**时提交（不是每次按键都写），空白则清成 `undefined`。
 */
import { Task } from '../model';
import { ThemeStore } from '../utils/Theme';

/** 备注区左右内边距（vp）：官方 `padding_level8` */
const NOTE_SIDE_PADDING_VP: number = 16;
/** 备注区上下内边距（vp） */
const NOTE_VERTICAL_PADDING_VP: number = 16;
/**
 * 空备注时的最小高度（vp）：留出「一块可以写字的区域」，
 * 与设计稿里那个明显比其它行高出一截的卡片一致。
 * 只设**下限**，内容多了靠 TextArea 自适应往上长 —— 千万别改成固定 height。
 */
const NOTE_MIN_HEIGHT_VP: number = 72;
/** 备注输入框的组件 id（自动化/无障碍定位用） */
const NOTE_INPUT_ID: string = 'noteInput';

@ComponentV2
export struct TaskNoteCard {
  /** 要编辑的任务（`@ObservedV2`，改 `note` 后列表卡片也会跟着刷新） */
  @Require @Param task: Task;

  /** 视觉个性化：卡片底与输入框背板都取 M3 容器色（见卡片上 `backgroundColor` 的说明） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /**
   * 备注草稿：进入页面时从任务里取一次，之后由输入框驱动。
   * 为什么用草稿而不是直接双向绑 `task.note`：`TextArea` 的 `text` 只在初始化时生效，
   * 提交时机也要可控（失焦/离开页面才写回，见 `commitNote`）。
   */
  @Local noteDraft: string = '';

  aboutToAppear(): void {
    const note: string | undefined = this.task.note;
    this.noteDraft = note === undefined ? '' : note;
  }

  /** 离开页面时兜底提交：用户直接按返回键时输入框未必先收到 blur */
  aboutToDisappear(): void {
    this.commitNote();
  }

  /**
   * 写回备注：**空白就存 `undefined`**（「没写」与「写了空白」在契约里不是一回事，
   * `missingFields` / 卡片描述行的判空都按 `undefined` 走）。
   * 内容不做 trim：用户敲的换行与缩进原样保留，只判「是不是全空白」。
   */
  private commitNote(): void {
    const text: string = this.noteDraft;
    const next: string | undefined = text.trim().length === 0 ? undefined : text;
    if (next !== this.task.note) {
      this.task.note = next;
    }
  }

  build() {
    Column() {
      TextArea({ text: this.noteDraft, placeholder: $r('app.string.note_hint') })
        .id(NOTE_INPUT_ID)
        .width('100%')
        // ⚠️ **不设 height**：高度由内容自适应（多行自动换行、卡片随之变长）；
        // 只给最小高度兜底，空备注时也有「一块能写字的区域」
        .constraintSize({ minHeight: NOTE_MIN_HEIGHT_VP })
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .placeholderColor($r('sys.color.ohos_id_color_text_secondary'))
        // 输入框背板填**卡片底色**（M3 `surface-container-low`），否则会露一条色带（与标签卡同一条坑）
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderWidth(0)
        .borderRadius(0)
        .padding(0)
        .onChange((value: string) => {
          this.noteDraft = value;
        })
        .onBlur(() => {
          this.commitNote();
        })
    }
    .width('100%')
    .padding({
      left: NOTE_SIDE_PADDING_VP,
      right: NOTE_SIDE_PADDING_VP,
      top: NOTE_VERTICAL_PADDING_VP,
      bottom: NOTE_VERTICAL_PADDING_VP
    })
    // 卡片底 = M3 `surface-container-low` + 官方圆角：与详情页其它卡片同一档（不再是系统纯白）
    .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
    .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
    .clip(true)
  }
}
