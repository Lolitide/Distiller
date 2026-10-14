// 来源：documentId = API参考/ArkUI_方舟UI框架/ArkTS_API/窗口管理/ohos_window_floatView_闪控窗_/js-apis-floatview
// 行范围：L592-L615
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

import { BusinessError } from '@kit.BasicServicesKit';
import { floatView, window } from '@kit.ArkUI';

// 设置新窗口大小
let newSize: window.Size = {
  width: 800,
  height: 100
};
// 设置模板属性
let templateProperty: floatView.TemplateProperty = {
  templateType: floatView.FloatViewTemplateType.HORIZONTAL_BAR,
  size: newSize
};
try {
  // 切换闪控窗模板并改变窗口尺寸
  this.floatViewController?.switchTemplate(templateProperty).then(() => {
    console.info('Succeeded in switching window type and size.');
  }).catch((err: BusinessError): void => {
    console.error(`Failed to switch window type and size. Cause:${err.code}, message:${err.message}`);
  });
} catch (e) {
  console.error(`Failed to switch window type and size. Cause:${e.code}, message:${e.message}`);
}
```
