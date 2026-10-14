// 来源：documentId = API参考/ArkUI_方舟UI框架/ArkTS_API/窗口管理/ohos_window_floatView_闪控窗_/js-apis-floatview
// 行范围：L398-L412
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

import { BusinessError } from '@kit.BasicServicesKit';
import { floatView } from '@kit.ArkUI';

try {
  // floatViewController需通过floatView.create()获取，详见floatView.create()示例
  // 设置闪控窗的页面内容路径
  this.floatViewController?.setUIContext('pages/Index').then(() => {
    console.info('Succeeded in setting UI context.');
  }).catch((err: BusinessError): void => {
    console.error(`Failed to set UI context. Cause:${err.code}, message:${err.message}`);
  });
} catch (e) {
  console.error(`Failed to set UI context. Cause:${e.code}, message:${e.message}`);
}
```
