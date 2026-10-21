/*
 * 删除确认弹窗 —— **全工程唯一实现**。
 *
 * 为什么收在一个函数里（需求方 2026-10-17：「把任务列表里面的删除弹窗和任务详情里面的步骤删除弹窗样式
 * 全部改成和任务详情里面右上角删除的弹窗一样」）：
 * 三处删除（列表多选删除 / 详情页步骤删除 / 详情页删除任务）原来各写一份 `showAlertDialog`，
 * 参数一漂移样式就不一样了 —— 最明显的是列表与步骤那两处给删除按钮加了
 * `style: DialogButtonStyle.HIGHLIGHT` + `defaultFocus: true`，删除按钮被画成高亮实心；
 * 而详情页那份是**红色警示文字**（`sys.color.warning`）+ 不抢默认焦点。现在统一按详情页那份来。
 *
 * 采用官方 `UIContext.showAlertDialog`（`AlertDialog.show` 从 API 18 起已废弃，官方原文：
 * 「建议使用 showAlertDialog 替代…需先获取 UIContext 实例后再进行调用」）。
 *
 * ⚠️ 两个按钮之间那条灰色竖线是系统弹窗**固定样式**的一部分，`AlertDialogParam` 里没有任何开关
 * 能去掉它（详见 `MainTabBar` 里那段查证记录）；要真去掉只能自绘弹窗内容，代价是不再走官方样式。
 *
 * 调用方只需给「标题 + 正文 + 确认后干什么」，按钮文案与配色不许各写一份。
 */
import { UIContext } from '@kit.ArkUI';

export function showDeleteConfirmDialog(ctx: UIContext, title: ResourceStr, message: ResourceStr,
  onConfirm: () => void): void {
  ctx.showAlertDialog({
    title: title,
    message: message,
    // 左：取消（默认样式，不抢焦点，避免误触回车就删）
    primaryButton: {
      value: $r('app.string.action_cancel'),
      action: () => {
        // 取消：什么都不做
      }
    },
    // 右：删除 —— **红色警示文字**，与「危险操作」的语义一致
    secondaryButton: {
      value: $r('app.string.action_delete'),
      enabled: true,
      fontColor: $r('sys.color.warning'),
      action: () => {
        onConfirm();
      }
    }
  });
}
