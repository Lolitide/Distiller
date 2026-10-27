/*
 * 《会离开手机的字段》独立页（二级页，2026-10-27）。
 *
 * 需求方：「这个不用系统 showDialog，用一个新的页面展示」——
 * 原先是设置 → 云端数据 →「会离开手机的字段」那一行点「查看」弹的一个系统对话框，
 * 正文是三段较长的话，塞在系统弹窗里字号小、行宽窄、读起来挤（截图里已经六七行换行），
 * 所以改成和《隐私政策》同一种**独立页面**：大标题 + 分节 + 14vp/22 行高的正文。
 *
 * 内容口径与 `repository`/`service` 实际行为对齐（写错就是虚假陈述）：
 *  · 上传项来自 `SyncService` / `FeedbackService` / `PushRegistrar` 三条链路；
 *  · 「原文只保留 30 分钟、不落盘」是后端中继的约定（见 `SyncService` 顶部注释）；
 *  · 本机字段对应 `Task` 模型与 `AddTaskDraft` 草稿。
 *
 * 入口：设置 → 云端数据 →「会离开手机的字段」。
 * 路由：`resources/base/profile/router_map.json` 里注册为 `CloudFieldsPage`。
 */
import { HdsNavDestination } from '@kit.UIDesignKit';
import { common } from '@kit.AbilityKit';
import { WindowInsets } from '../utils/WindowInsets';
import { MainTitleBar } from '../components/MainTitleBar';
import { Theme, ThemeStore } from '../utils/Theme';

/** 小节之间的留白（vp） */
const SECTION_GAP_VP: number = 16;
/** 段落之间的留白（vp） */
const PARAGRAPH_GAP_VP: number = 10;
/** 内容左右留白（vp）：官方 `padding_level8` */
const SIDE_PADDING_VP: number = 16;

/** 一段正文：标题 + 若干行文案 */
class FieldSection {
  readonly title: string;
  readonly lines: string[];

  constructor(title: string, lines: string[]) {
    this.title = title;
    this.lines = lines;
  }
}

const SECTIONS: FieldSection[] = [
  new FieldSection('一、同步开启后会上传到你的服务器的信息', [
    '· 设备标识与访问令牌：注册设备时生成，用于让服务器把结果推给正确的手机。',
    '· 绑定关系与群订阅列表：记录你绑定了哪个 QQ、订阅了哪些群，决定把哪些群的消息整理成候选。',
    '· 采纳 / 忽略反馈计数：用于减少你不需要的候选；只记次数，不含任务正文。',
    '· Push 令牌：服务端在到点时给你下发提醒用；没有开通推送权益或还未接入时，这一项不存在。'
  ]),
  new FieldSection('二、服务器如何保存群消息原文', [
    '· 群消息原文由服务器在内存中临时保留，不超过 30 分钟，不写入磁盘。',
    '· 保留期内只用于生成你看到的候选与「原文对照」；过期即清除。',
    '· 原文不会再从服务器回传给你的手机以外的任何地方。'
  ]),
  new FieldSection('三、只留在本机的信息', [
    '· 任务名称、备注、原文、步骤、截止与提醒时间、分类与标签、重要程度、地点。',
    '· 添加任务时的草稿（未保存也会暂存在本机，便于下次接着写）。',
    '· 你的视觉偏好（主题色、卡片密度）与提醒提前量等设置项。',
    '· 以上内容不会随同步上传，卸载应用即一并删除。'
  ]),
  new FieldSection('四、我们不会做的事', [
    '· 不出售、不出租你的信息，也不用于广告投放或用户画像。',
    '· 不接入第三方统计、广告或社交 SDK。',
    '· 除法律法规要求或你明确同意外，不与第三方共享、不转让、不公开披露。'
  ])
];

/** 二级页的实例化方法 —— 官方系统路由表要的就是它（`router_map.json` 的 `buildFunction`） */
@Builder
export function CloudFieldsPageBuilder(name: string, param: Object) {
  B_CloudFields();
}

@ComponentV2
export struct B_CloudFields {
  /** 视觉个性化：M3 色系（与设置页同一档 `surface`） */
  @Local themeStore: ThemeStore = ThemeStore.instance();
  /** 状态栏高度（vp）：窗口全屏后内容从窗口顶端起算，要先让开这一截 */
  @Local statusBarVp: number = 0;

  aboutToAppear(): void {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    WindowInsets.topPx(context).then((px: number) => {
      this.statusBarVp = px > 0 ? this.getUIContext().px2vp(px) : 0;
    });
  }

  /** 一节正文 */
  @Builder
  section(section: FieldSection) {
    Column({ space: PARAGRAPH_GAP_VP }) {
      Text(section.title)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .width('100%')
        .textAlign(TextAlign.Start)

      ForEach(section.lines, (line: string) => {
        Text(line)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .lineHeight(`${Theme.LINE_BODY}vp`)
          .width('100%')
          .textAlign(TextAlign.Start)
          .wordBreak(WordBreak.BREAK_ALL)
      }, (line: string) => line)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 只负责颜色的底色层：把手势条那一带也刷成 `surface`（与详情页/隐私政策页同一处修）
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.themeStore.scheme.surface)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .hitTestBehavior(HitTestMode.None)

        Column() {
          // 顶部让开「状态栏 + 二级页标题栏（MINI = 56vp）」
          Row().width('100%').height(MainTitleBar.SUB_PAGE_TITLE_BAR_VP + this.statusBarVp)

          Scroll() {
            Column({ space: SECTION_GAP_VP }) {
              Text('同步只发送「让服务器能把结果送到你手机上」所必需的字段；'
                + '任务正文与原文都留在本机。下面按「会上传」「服务器怎么存原文」「只在本机」分开写。')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .lineHeight(`${Theme.LINE_BODY}vp`)
                .width('100%')
                .textAlign(TextAlign.Start)

              ForEach(SECTIONS, (section: FieldSection) => {
                this.section(section)
              }, (section: FieldSection) => section.title)

              Text('想彻底停止上传：设置 → 关于 → 隐私说明 →「撤回隐私授权」，'
                + '撤回后云端同步、服务端解析、推送上报都会停用，本机基础功能仍然可用。')
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .lineHeight(`${Theme.LINE_BODY}vp`)
                .width('100%')
                .textAlign(TextAlign.Start)
                .padding({ top: Theme.GAP_M, bottom: Theme.GAP_XL })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding({ left: SIDE_PADDING_VP, right: SIDE_PADDING_VP, bottom: Theme.GAP_XL })
          }
          .layoutWeight(1)
          .width('100%')
          .align(Alignment.Top)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
    }
    .titleBar({
      avoidLayoutSafeArea: true,
      style: MainTitleBar.style(this.themeStore.scheme.surface, this.themeStore.scheme.onSurface),
      content: {
        title: { mainTitle: '会离开手机的字段' }
      }
    })
    .hideBackButton(false)
  }
}
