// 来源：documentId = API参考/ArkUI_方舟UI框架/ArkTS_API/窗口管理/ohos_window_floatView_闪控窗_/js-apis-floatview
// 行范围：L92-L121
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { floatView } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  private floatViewController: floatView.FloatViewController | undefined = undefined;
  aboutToAppear(): void {
    // 请在组件内获取context，确保this.getUIContext().getHostContext()返回的结果为UIAbilityContext
    let ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    // 创建闪控窗配置对象
    let config: floatView.FloatViewConfiguration = {
      context: ctx,
      templateType: floatView.FloatViewTemplateType.ROUNDED_RECTANGLE
    };
    try {
      // 创建闪控窗控制器
      floatView.create(config).then((data: floatView.FloatViewController) => {
        this.floatViewController = data;
        console.info(`Succeeded in creating float view controller. Data: ${data}`);
      }).catch((err: BusinessError): void => {
        console.error(`Failed to create float view controller. Cause:${err.code}, message:${err.message}`);
      });
    } catch (e) {
      console.error(`Failed to create float view controller. Cause:${e.code}, message:${e.message}`);
    }
  }
}
```
