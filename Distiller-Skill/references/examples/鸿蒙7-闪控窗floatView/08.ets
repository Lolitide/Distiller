// 来源：documentId = API参考/ArkUI_方舟UI框架/ArkTS_API/窗口管理/ohos_window_floatView_闪控窗_/js-apis-floatview
// 行范围：L535-L553
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

import { BusinessError } from '@kit.BasicServicesKit';
import { floatView, window } from '@kit.ArkUI';

// 设置窗口大小
let size: window.Size = {
  width: 400,
  height: 600
};
try {
  // 设置闪控窗窗口大小
  this.floatViewController?.setWindowSize(size).then(() => {
    console.info('Succeeded in setting window size.');
  }).catch((err: BusinessError): void => {
    console.error(`Failed to set window size. Cause:${err.code}, message:${err.message}`);
  });
} catch (e) {
  console.error(`Failed to set window size. Cause:${e.code}, message:${e.message}`);
}
```
