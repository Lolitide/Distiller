/**
 * 权限状态变更的进程内广播。
 *
 * 首次引导是覆盖在主页上的组件，设置页在同一棵树上早已 `aboutToAppear`；用户在引导里
 * 授权日历/通知后，设置页不会重新走生命周期，于是仍显示「未授权」。
 * 这里只做一件事：引导授权完成后通知设置页重查权限。
 */
export class PermissionEvents {
  private static listener: (() => void) | undefined = undefined;

  static setListener(listener: () => void): void {
    PermissionEvents.listener = listener;
  }

  static clearListener(): void {
    PermissionEvents.listener = undefined;
  }

  static notifyChanged(): void {
    if (PermissionEvents.listener !== undefined) {
      PermissionEvents.listener();
    }
  }
}
