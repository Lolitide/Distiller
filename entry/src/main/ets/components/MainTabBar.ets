import { SymbolGlyphModifier } from '@kit.ArkUI';

export class MainTabBar {
  static readonly TASK_LIST: BottomTabBarStyle = new BottomTabBarStyle(
    { normal: new SymbolGlyphModifier($r('sys.symbol.list_checkmark')) },
    $r('app.string.tab_task_list')
  );

  static readonly SETTINGS: BottomTabBarStyle = new BottomTabBarStyle(
    { normal: new SymbolGlyphModifier($r('sys.symbol.gearshape')) },
    $r('app.string.tab_settings')
  );
}
