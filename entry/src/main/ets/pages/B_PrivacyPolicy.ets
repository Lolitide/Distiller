/*
 * 《隐私政策》独立页面（**二级页**，2026-10-27）。
 *
 * 需求方原话：「隐私说明、隐私政策未合规撰写，且应放至独立页面，用官方的规范，
 * 且支持用户撤回，撤回后可使用最基本功能，与所有 AI、云相关功能分隔」。
 *
 * 于是：
 *   · **独立页面**（不再是一个居中弹窗）—— 弹窗里塞不下一篇合规的隐私政策；
 *   · **按官方审核要求的结构撰写**（AGC 元数据审核：需包含收集个人信息的**目的、方式、范围**，
 *     需提供中文版、需易于访问和阅读 —— 所以做到正文 14vp / 行高 22vp、分节带小标题、段落留白）；
 *   · **支持撤回**：底部一颗「撤回隐私授权」，撤回后 AI 与云相关能力全部停用
 *     （`service/system/PrivacyConsent.ets` 里的门禁），本地基础功能不受影响；
 *   · **与 AI / 云功能分隔**：政策里把「只在本机」和「会上传到服务器」两类逐条分开写，
 *     撤回只影响后者与 AI 能力。
 *
 * 入口：设置 → 关于 → 隐私说明（`A_Settings.openPrivacyPage()`）。
 * 路由：`resources/base/profile/router_map.json` 里注册为 `PrivacyPolicyPage`。
 */
import { HdsNavDestination } from '@kit.UIDesignKit';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { WindowInsets } from '../utils/WindowInsets';
import { MainTitleBar } from '../components/MainTitleBar';
import { PrivacyConsent } from '../service/system/PrivacyConsent';
import { SyncService } from '../service/cloud/SyncService';
import { SettingsRepository } from '../repository/SettingsRepository';
import { Theme, ThemeStore } from '../utils/Theme';

/** 正文与标题之间的留白（vp） */
const SECTION_GAP_VP: number = 16;
/** 小节之间的留白（vp） */
const PARAGRAPH_GAP_VP: number = 10;
/** 内容左右留白（vp）：官方 `padding_level8` */
const SIDE_PADDING_VP: number = 16;

/** 一段正文：标题 + 若干行文案（用数组而不是模板串 —— 每行独立排版，不会糊成一坨） */
class PolicySection {
  readonly title: string;
  readonly lines: string[];

  constructor(title: string, lines: string[]) {
    this.title = title;
    this.lines = lines;
  }
}

/**
 * 政策正文。
 *
 * 口径与实际实现严格对应（写错了就是虚假陈述）：
 *  · 本机字段来自 `Task` 模型；
 *  · 上传项来自 `SyncService` / `FeedbackService` / `PushRegistrar` 三条链路；
 *  · 权限来自 `module.json5` 的 `requestPermissions`。
 */
const SECTIONS: PolicySection[] = [
  new PolicySection('一、我们收集哪些信息，用来做什么', [
    '1. 只存在你的手机上、不会上传的信息：任务名称、备注、原文、步骤、截止时间与提醒时间、' +
      '分类与标签、重要程度、你填写的地点、以及添加任务时的草稿。',
    '2. 只有你主动开启「云端同步」并填写服务器地址后，才会发往你自己配置的服务器：',
    '· 设备标识与访问令牌：注册设备时生成，用于让服务器把结果推给正确的手机；',
    '· QQ 绑定关系与群订阅列表：决定把哪些群的消息整理成候选；',
    '· 采纳 / 忽略计数：用于减少你不需要的候选，不包含任何任务正文；',
    '· Push 令牌：用于服务端在到点时给你下发提醒；未开启推送则没有这一项。',
    '3. 群消息原文：由服务器在内存中临时保留不超过 30 分钟，不写入磁盘、不会回传，' +
      '仅用于生成你看到的候选与「原文对照」。',
    '4. 我们不做：不收集通讯录、位置、应用安装列表；不做用户画像，不做广告投放，不做跨应用跟踪。'
  ]),
  new PolicySection('二、设备权限与用途', [
    '· 网络（INTERNET）：与你自己配置的服务器通信（同步、解析、推送）。拒绝则云端相关功能不可用。',
    '· 麦克风（MICROPHONE）：仅在你按住说话时录音并转成文字。拒绝后仍可手动输入或粘贴文本。',
    '· 日历读取与写入（READ_CALENDAR / WRITE_CALENDAR）：把任务写成系统日程、并在到期前提醒。' +
      '拒绝后任务仍保存在本机，只是不写日程。',
    '· 通知与代理提醒（PUBLISH_AGENT_REMINDER）：到点提醒与同步状态提示。拒绝后不会有提醒，' +
      '任务本身不受影响。',
    '· 图片与文件：通过系统选择器让你挑截图或导入 JSON，只读取你选中的那一个文件。'
  ]),
  new PolicySection('三、信息的存储与保护', [
    '· 本机：保存在应用私有目录（首选项与文件），卸载应用即一并删除；导出的文件由你自己选择存放位置。',
    '· 服务器：仅限你自己填写的那台服务器；群消息原文只驻留内存不超过 30 分钟，不落盘。',
    '· 传输：全部走 HTTPS。',
    '· 我们不会出售你的信息，不会用于广告，也不会与第三方共享。'
  ]),
  new PolicySection('四、第三方共享、转让与公开披露', [
    '· 本应用没有接入任何第三方统计、广告或社交 SDK；AI 能力使用系统提供的能力，' +
      '范围仅限你当次输入的内容。',
    '· 除法律法规要求或你明确同意外，我们不共享、不转让、不公开披露你的信息。'
  ]),
  new PolicySection('五、你的权利', [
    '· 查阅与更正：任务详情页可直接查看和修改每一项内容。',
    '· 删除：单条任务可删除；设置 → 数据 →「清空全部任务」可一次清空本机全部任务；' +
      '设置 → 云端数据 →「删除服务端数据」可清除服务器上的记录。',
    '· 撤回授权：本页底部「撤回隐私授权」。撤回后 AI 与云相关能力（云端同步、服务端解析、' +
      '语音转文字、OCR、实体抽取、推送上报）全部停用，' +
      '本机基础功能仍然可用：手动增删改任务、本地提醒、通知、日历写入、导入导出。',
    '· 撤回随时可以在本页重新授权，恢复后相关能力即刻可用。'
  ]),
  new PolicySection('六、未成年人保护', [
    '· 本应用面向在校学生，不收集年龄、身份证号等身份信息，也不提供付费与社交功能。',
    '· 未满 14 周岁的用户请在监护人陪同下使用，并由监护人同意本政策。'
  ]),
  new PolicySection('七、本政策的更新', [
    '· 政策如有变更，会更新本页顶部的「更新日期」，并在应用内提示你。',
    '· 涉及收集范围扩大的重大变更，会重新征求你的同意；不同意可继续使用本机基础功能。'
  ]),
  new PolicySection('八、联系我们', [
    '· 本应用为校园实践项目，开发者联系方式见应用市场的应用详情页「开发者信息」。',
    '· 你也可以在应用的项目仓库中提交问题，我们会在 15 个工作日内答复。'
  ])
];

/** 二级页的实例化方法 —— 官方系统路由表要的就是它（`router_map.json` 的 `buildFunction`） */
@Builder
export function PrivacyPolicyPageBuilder(name: string, param: Object) {
  B_PrivacyPolicy();
}

@ComponentV2
export struct B_PrivacyPolicy {
  /** 视觉个性化：M3 色系（与设置页同一档 `surface`） */
  @Local themeStore: ThemeStore = ThemeStore.instance();
  /** 授权状态（单例的 `@Trace` 字段，撤回后本页立刻变文案） */
  @Local consent: PrivacyConsent = PrivacyConsent.instance();
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

  private toast(message: ResourceStr): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (error) {
      // toast 失败不影响主流程
    }
  }

  /** 撤回 / 重新授权：落盘并联动同步运行态 */
  private async applyConsent(granted: boolean): Promise<void> {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    await PrivacyConsent.setGranted(context, granted);
    if (!granted) {
      // 撤回后立刻停掉同步；SyncService 自己也有一层 consent 门禁，这里是双保险。
      SyncService.setEnabled(false);
      await SettingsRepository.setSyncEnabled(context, false);
      this.toast('已撤回授权：AI 与云端功能已停用，本机基础功能仍可用');
      return;
    }
    // 重新授权后 SyncService 会按 consent 恢复；设置页已没有「云端同步」开关。
    SyncService.setEnabled(true);
    this.toast('已重新授权，AI 解析与云端同步已恢复');
  }

  /** 撤回前二次确认（撤回是"立即生效 + 影响功能"的动作，必须确认） */
  private confirmWithdraw(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '撤回隐私授权',
      message: '撤回后，云端同步、服务端解析、语音转文字、OCR、实体抽取与推送上报都会停用；'
        + '手动增删改任务、本地提醒、通知、日历写入、导入导出不受影响。\n\n'
        + '随时可以在本页重新授权。',
      buttons: [
        { text: '取消', color: $r('sys.color.ohos_id_color_text_primary') },
        { text: '撤回', color: this.themeStore.scheme.error }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index === 1) {
        this.applyConsent(false);
      }
    }).catch(() => {
      // 弹窗失败：什么也不做（不能因为弹窗挂了就把授权撤掉）
    });
  }

  /** 授权状态条：一眼看出当前是否已同意，以及撤回会失去什么 */
  @Builder
  consentBanner() {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        SymbolGlyph(this.consent.granted
          ? $r('sys.symbol.checkmark_circle_fill')
          : $r('sys.symbol.exclamationmark_circle'))
          .fontSize(18)
          .fontColor([this.consent.granted ? this.themeStore.scheme.primary : this.themeStore.scheme.error])
        Text(this.consent.granted ? '当前状态：已同意本政策' : '当前状态：已撤回授权')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.consent.granted
            ? $r('sys.color.ohos_id_color_text_primary')
            : this.themeStore.scheme.error)
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.consent.granted
        ? '同意后，云端同步、服务端解析、语音转文字、OCR、实体抽取与推送上报才会工作。'
        : 'AI 与云端功能已停用；手动增删改任务、本地提醒、通知、日历写入、导入导出仍然可用。')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .width('100%')
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .padding(Theme.GAP_L)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
    .borderRadius(Theme.RADIUS_CARD)
  }

  /** 一节正文 */
  @Builder
  section(section: PolicySection) {
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
        // 只负责颜色的底色层：把手势条那一带也刷成 `surface`（与详情页/搜索页同一处修）
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
              // 抬头：生效/更新日期（合规要求可追溯到版本）
              Column({ space: 4 }) {
                Text('生效日期：2026 年 10 月 27 日')
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .width('100%')
                Text('更新日期：2026 年 10 月 27 日    版本：v1.0')
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .width('100%')
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)

              this.consentBanner()

              Text('知了（Distiller）是一款把群消息整理成待办的校园工具。'
                + '这份政策说明我们收集哪些信息、怎么使用与保存，以及你可以怎样撤回同意。'
                + '为了让你一眼看懂，全文按「只在本机」和「会上传到服务器」两类分开写。')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .lineHeight(`${Theme.LINE_BODY}vp`)
                .width('100%')
                .textAlign(TextAlign.Start)

              ForEach(SECTIONS, (section: PolicySection) => {
                this.section(section)
              }, (section: PolicySection) => section.title)

              // 撤回 / 重新授权（页面底部，与正文分开，避免误触）
              Column({ space: 8 }) {
                if (this.consent.granted) {
                  Button({ type: ButtonType.Capsule, stateEffect: true }) {
                    Text('撤回隐私授权')
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
                      .fontColor(this.themeStore.scheme.error)
                  }
                  .height(44)
                  .width('100%')
                  .backgroundColor(this.themeStore.scheme.errorContainer)
                  .onClick(() => {
                    this.confirmWithdraw();
                  })
                  .accessibilityText('撤回隐私授权')
                } else {
                  Button({ type: ButtonType.Capsule, stateEffect: true }) {
                    Text('重新同意本政策')
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
                      .fontColor(this.themeStore.scheme.onPrimary)
                  }
                  .height(44)
                  .width('100%')
                  .backgroundColor(this.themeStore.scheme.primary)
                  .onClick(() => {
                    this.applyConsent(true);
                  })
                  .accessibilityText('重新同意本政策')
                }

                Text('撤回与重新授权都只影响 AI 与云端能力，不影响你本机已有的任务。')
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .padding({ top: Theme.GAP_L, bottom: Theme.GAP_XL })
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
        title: { mainTitle: '隐私政策' }
      }
    })
    .hideBackButton(false)
  }
}
