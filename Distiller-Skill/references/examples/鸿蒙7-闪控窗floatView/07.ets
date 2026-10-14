// 来源：documentId = API参考/ArkUI_方舟UI框架/ArkTS_API/窗口管理/ohos_window_floatView_闪控窗_/js-apis-floatview
// 行范围：L453-L496
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

// Index.ets
import { BusinessError } from '@kit.BasicServicesKit';
import { entryName } from './Hello'; // 导入命名路由页面
import { floatView } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  private floatViewController: floatView.FloatViewController | undefined = undefined;
  // 创建控制器
  // ...
  public setUIContextByName(): void {
    try {
      // 根据命名路由名称设置闪控窗的页面内容
      this.floatViewController?.setUIContextByName(entryName).then(() => {
        console.info('Succeeded in loading the content.');
      }).catch((err: BusinessError): void => {
        console.error(`Failed to load the content. Cause code: ${err.code}, message: ${err.message}`);
      });
    } catch (e) {
      console.error(`Failed to load the content. Cause code: ${e.code}, message: ${e.message}`);
    }
  }
}
```

```
// Hello.ets
export const entryName : string = 'Hello';
@Entry({routeName: entryName, useSharedStorage: true})
@Component
export struct Hello {
  @State message: string = 'Hello World'
  build() {
    Row() {
      Column() {
        Text(this.message)
      }
      .width('100%')
    }
    .height('100%')
  }
}
```
