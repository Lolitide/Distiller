/*
 * 《隐私政策》正文（可复用）。
 *
 * 2026-10-29：首次启动引导里点「《隐私政策》」原来走路由 push，会被全屏引导覆盖层盖住；
 * 现在引导页用 `bindContentCover` 就地弹出政策正文，所以把正文抽成组件，两处共用同一份文案：
 *  · `B_PrivacyPolicy`（设置 → 关于 → 隐私说明，带撤回/重新授权按钮）；
 *  · `A_Onboarding`（首次启动，只读，不提供撤回）。
 *
 * 口径与实际实现严格对应（写错了就是虚假陈述）：
 *  · 本机字段来自 `Task` 模型；
 *  · 上传项来自 `SyncService` / `FeedbackService` / `PushRegistrar` 三条链路；
 *  · 权限来自 `module.json5` 的 `requestPermissions`。
 */
import { Theme, ThemeStore } from '../utils/Theme';

/** 小节之间的留白（vp） */
const SECTION_GAP_VP: number = 16;
/** 段落之间的留白（vp） */
const PARAGRAPH_GAP_VP: number = 10;
/** 每个小节标题上方额外留一行空行（2026-10-29 需求方） */
const SECTION_BLANK_VP: number = 10;

/** 一段正文：标题 + 若干行文案（每行独立排版，不会糊成一坨） */
export class PolicySection {
  readonly title: string;
  readonly lines: string[];

  constructor(title: string, lines: string[]) {
    this.title = title;
    this.lines = lines;
  }
}

/** 政策正文（与实现一一对应） */
export const PRIVACY_SECTIONS: PolicySection[] = [
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
    '· 本应用没有接入任何第三方统计、广告或社交 SDK。',
    '· 文字识别（OCR）与语音识别使用系统提供的能力，仅处理你当次输入的图片/音频，不保存原文件、不上传。',
    '· 待办的自动整理（标题、时间、地点、类型、标签、步骤等）由你自己配置的服务器调用大模型完成；' +
      '其中聊天原文与图片音频不会上传，只有生成待办所必需的白名单字段会离开手机。',
    '· 除法律法规要求或你明确同意外，我们不共享、不转让、不公开披露你的信息。'
  ]),
  new PolicySection('五、关于人工智能生成内容', [
    '· 本应用会对群消息文本做自动整理，生成待办标题、时间、地点、类型、标签、步骤等内容，' +
      '这些内容由人工智能生成。',
    '· 生成结果仅供参考，可能存在偏差，请在保存前核对；应用内所有 AI 生成内容均标注「AI 生成」。',
    '· 你导出的 CSV / JSON 文件同样带有「AI生成」标识与生成说明，便于识别内容来源。'
  ]),
  new PolicySection('六、你的权利', [
    '· 查阅与更正：任务详情页可直接查看和修改每一项内容。',
    '· 删除：单条任务可删除；设置 → 数据 →「清空全部任务」可一次清空本机全部任务；' +
      '设置 → 云端数据 →「删除服务端数据」可清除服务器上的记录。',
    '· 撤回授权：本页底部「撤回隐私授权」。撤回后 AI 与云相关能力（云端同步、服务端解析、' +
      '语音转文字、OCR、实体抽取、推送上报）全部停用，' +
      '本机基础功能仍然可用：手动增删改任务、本地提醒、通知、日历写入、导入导出。',
    '· 撤回随时可以在本页重新授权，恢复后相关能力即刻可用。'
  ]),
  new PolicySection('七、未成年人保护', [
    '· 本应用面向在校学生，不收集年龄、身份证号等身份信息，也不提供付费与社交功能。',
    '· 未满 14 周岁的用户请在监护人陪同下使用，并由监护人同意本政策。'
  ]),
  new PolicySection('八、本政策的更新', [
    '· 政策如有变更，会更新本页顶部的「更新日期」，并在应用内提示你。',
    '· 涉及收集范围扩大的重大变更，会重新征求你的同意；不同意可继续使用本机基础功能。'
  ]),
  new PolicySection('九、联系我们', [
    '· 本应用为校园实践项目，开发者联系方式见应用市场的应用详情页「开发者信息」。',
    '· 你也可以在应用的项目仓库中提交问题，我们会在 15 个工作日内答复。'
  ])
];

@ComponentV2
export struct PrivacyPolicyText {
  @Param showIntro: boolean = true;
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 一节正文 */
  @Builder
  section(section: PolicySection) {
    Column({ space: PARAGRAPH_GAP_VP }) {
      // 小标题上方空一行
      Row()
        .width('100%')
        .height(SECTION_BLANK_VP)

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
    Column({ space: SECTION_GAP_VP }) {
      if (this.showIntro) {
        Text('知了（Distiller）是一款把群消息整理成待办的校园工具。'
          + '这份政策说明我们收集哪些信息、怎么使用与保存，以及你可以怎样撤回同意。'
          + '为了让你一眼看懂，全文按「只在本机」和「会上传到服务器」两类分开写。')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .lineHeight(`${Theme.LINE_BODY}vp`)
          .width('100%')
          .textAlign(TextAlign.Start)
      }

      ForEach(PRIVACY_SECTIONS, (section: PolicySection) => {
        this.section(section)
      }, (section: PolicySection) => section.title)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
