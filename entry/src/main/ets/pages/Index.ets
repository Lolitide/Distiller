import { Store } from '../common/Store';

@Entry
@Component
struct Index {
  aboutToAppear(): void {
    Store.init(getContext(this));
    AppStorage.setOrCreate<number>('msgVersion', 0);
    AppStorage.setOrCreate<boolean>('needOnboarding', false);
    AppStorage.setOrCreate<string>('newMsgBanner', '');
    if (Store.hasIdentity()) {
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/HomePage' });
    } else {
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/OnboardingPage' });
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
