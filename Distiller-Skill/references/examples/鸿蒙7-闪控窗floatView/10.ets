// 来源：documentId = API参考/ArkUI_方舟UI框架/ArkTS_API/窗口管理/ohos_window_floatView_闪控窗_/js-apis-floatview
// 行范围：L654-L667
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

import { BusinessError } from '@kit.BasicServicesKit';
import { floatView } from '@kit.ArkUI';

try {
  // 启动闪控窗
  this.floatViewController?.start().then(() => {
    console.info('Succeeded in starting float view.');
  }).catch((err: BusinessError): void => {
    console.error(`Failed to start float view. Cause:${err.code}, message:${err.message}`);
  });
} catch (e) {
  console.error(`Failed to start float view. Cause:${e.code}, message:${e.message}`);
}
```
