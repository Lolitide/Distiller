import { Store } from '../common/Store';
import { safeReplace } from '../common/UiParts';

@Entry
@Component
struct Index {
  aboutToAppear(): void {
    // getContext(this) 已废弃：改用 getHostContext()（可能为空，需判空）
    const ctx: Context | undefined = this.getUIContext().getHostContext();
    if (ctx !== undefined) {
      Store.init(ctx);
    }
    AppStorage.setOrCreate<number>('msgVersion', 0);
    AppStorage.setOrCreate<boolean>('needOnboarding', false);
    AppStorage.setOrCreate<string>('newMsgBanner', '');
    if (Store.hasIdentity()) {
      safeReplace(this.getUIContext(), 'pages/HomePage');
    } else {
      safeReplace(this.getUIContext(), 'pages/OnboardingPage');
    }
  }

  build() {
    Column() {
      Text('知了')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
