/*
 * 系统栏避让区查询（px）。
 *
 * 背景（2026-10-21 需求方选定的方案 A）：窗口改回**全屏**，状态栏/导航条那片底色改由
 * **页面自己画**（`A_Main` 根节点 `.backgroundColor(surface) + expandSafeArea(TOP, BOTTOM)`）——
 * 这样它和页面同生同灭、也会跟着半模态蒙层一起变暗，不再是"窗口级色块"。
 *
 * 代价：页面坐标系跟着铺到屏幕物理边缘，**内容必须自己把系统栏那两截补回来**，
 * 于是需要这里两个数：
 *  · `topPx`    —— 状态栏高度（`TYPE_SYSTEM.topRect`）；
 *  · `bottomPx` —— 手势条/导航栏高度。⚠️ 必须先读 `TYPE_NAVIGATION_INDICATOR`
 *    （手势导航机型上 `TYPE_SYSTEM.bottomRect` 实测是 **0**，踩过）。
 *
 * 单位是 **px**（`Rect` 文档写明「in px」），调用方用 `UIContext.px2vp()` 换算。
 * 本文件只用 @kit 的公共能力，不碰任何 UI。
 */
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'WindowInsets';

export class WindowInsets {
  /**
   * 上一次查到的状态栏高度（px）——**同步缓存**。
   *
   * 为什么要缓存：`getWindowAvoidArea` 是异步的，而页面里"内容顶部让开多少"要在**首帧**就是对的。
   * 二级页（`B_TaskDetail` / `B_Search`）是导航 push 进来的，等 async 回来再补 39vp，
   * 会看到内容"先压着标题、再往下跳一下"。
   * 根页面 `A_TaskList` 启动时已经查过一次并写进这里，所以二级页能直接同步读到。
   */
  private static cachedTopPx: number = 0;

  /** 状态栏高度（px）；取不到返回 0（同时会刷新同步缓存） */
  static async topPx(context: common.Context): Promise<number> {
    try {
      const win: window.Window = await window.getLastWindow(context);
      const height: number = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height;
      WindowInsets.cachedTopPx = height;
      return height;
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'topPx failed: %{public}s', err.message);
      return 0;
    }
  }

  /**
   * 已缓存的状态栏高度（px）；还没查过就是 0。
   * 给"首帧就要落在正确位置"的页面用（见 `B_TaskDetail` / `B_Search` 的 `statusBarVp`）。
   */
  static topPxCached(): number {
    return WindowInsets.cachedTopPx;
  }

  /** 底部手势条（三键导航时是导航栏）高度（px）；取不到返回 0 */
  static async bottomPx(context: common.Context): Promise<number> {
    try {
      const win: window.Window = await window.getLastWindow(context);
      let height: number = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height;
      if (height <= 0) {
        // 三键导航机型：手势条那条是 0，导航栏高度在 TYPE_SYSTEM.bottomRect 里
        height = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).bottomRect.height;
      }
      return height;
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'bottomPx failed: %{public}s', err.message);
      return 0;
    }
  }
}
