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
  new FieldSection('一、服务端保存什么', [
    '· 设备标识与访问令牌：用于把结果送到正确的手机。',
    '· 绑定关系、Bot AppID 与加密后的 AppSecret：仅用于连接你自己创建的 QQ Bot。',
    '· Push 令牌：仅在开启通知时保存，用于下发提醒。',
    '· 采纳 / 忽略计数：只记次数，不含任务正文。'
  ]),
  new FieldSection('二、服务端不保存什么', [
    '· 不保存群聊正文：自动群采集已关闭，Bot 不接收、不落库群消息。',
    '· 不保存转发正文：只在内存转发队列保留不超过 30 分钟，App 取走后删除。',
    '· 不做跨消息上下文或聚类，每条转发独立处理。'
  ]),
  new FieldSection('三、只留在本机', [
    '· 任务名称、备注、原文、步骤、截止与提醒时间、分类与标签、地点。',
    '· 添加任务时的草稿，以及主题色、卡片密度、提醒提前量等设置。',
    '· 以上内容不上传；卸载应用即一并删除。'
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
              Text('这里只列服务端实际保存的内容。自动群采集已关闭，不保存群聊正文；'
                + '转发内容只在内存短暂停留，App 取走后即删除。')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .lineHeight(`${Theme.LINE_BODY}vp`)
                .width('100%')
                .textAlign(TextAlign.Start)

              ForEach(SECTIONS, (section: FieldSection) => {
                this.section(section)
              }, (section: FieldSection) => section.title)

              Text('删除方式：设置 → 云端数据 →「删除服务端数据」。'
                + '会停止并删除你的 Bot、绑定关系与 Push 令牌，同时清空本机任务。')
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
