// 来源：documentId = API参考/ArkUI_方舟UI框架/ArkTS_API/窗口管理/ohos_window_floatView_闪控窗_/js-apis-floatview
// 行范围：L242-L269
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

// Entry.ets
import { BusinessError } from '@kit.BasicServicesKit';
import { floatingBall, floatView } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  private floatingBallController: floatingBall.FloatingBallController | undefined = undefined;
  private floatViewController: floatView.FloatViewController | undefined = undefined;
  // 创建控制器
  // ...
  public unbindController(): void {
    try {
      // 使用绑定时传入的闪控窗和闪控球控制器
      if (this.floatViewController && this.floatingBallController) {
        // 解绑闪控窗和闪控球
        floatView.unbind(this.floatViewController!, this.floatingBallController!).then(() => {
          console.info('Succeeded in unbinding float view and floating ball.');
        }).catch((err: BusinessError): void => {
          console.error(`Failed to unbind float view and floating ball. Cause:${err.code}, message:${err.message}`);
        });
      }
    } catch (e) {
      console.error(`Failed to unbind float view and floating ball. Cause:${e.code}, message:${e.message}`);
    }
  }
}
```
