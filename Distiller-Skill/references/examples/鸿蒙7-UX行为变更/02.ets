// 来源：documentId = 版本说明/26_0_0/OS平台能力/OS平台行为变更说明/26_0_0_Beta1引入的行为变更/UX样式或效果的变更/changelogs-ux-7001
// 行范围：L187-L215
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

    {
      "module": {
        // ...
        "type": "entry",
        // ...
        "metadata": [{
          "name": "ohos.arkui.UIMaterial.state",
          "value": "disable"
        }]
        // ...
      }
    }
    ```
    
    更多配置说明参见MaterialState。
    
3.  如果开发者仅想关闭部分组件的沉浸式系统材质，可通过组件提供的组件级接口关闭指定组件的沉浸式系统材质功能。
    
    为需要关闭材质的组件设置systemMaterial为uiMaterial.Material.empty。
    
    ```
    import { uiMaterial } from '@kit.ArkUI';
    
    this.getUIContext().getPromptAction().showToast({
      message: 'Toast Content',
      // 关闭指定组件的沉浸式系统材质
      systemMaterial: uiMaterial.Material.empty
    });
    ```
