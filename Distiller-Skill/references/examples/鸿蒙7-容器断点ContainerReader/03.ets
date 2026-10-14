// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/组件布局/构建布局/容器断点_ContainerReader/arkts-layout-development-container-reader
// 行范围：L222-L262
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

    // 示例1：数组超过最大长度[320, 600, 840, 1440, 2000, 3000]
    // 超过部分被忽略，使用系统默认：[320, 600, 840, 1440]
    .breakpointConfig({ width: [320, 600, 840, 1440, 2000, 3000] })
    
    // 示例2：数组非递增[100, 50, 300, 400]
    // 取递增结束的子数组：[100]
    .breakpointConfig({ width: [100, 50, 300, 400] })
    
    // 示例3：数组包含异常值[100, undefined, 300, 400]
    // 跳过异常值undefined，处理有效值：[100, 300, 400]
    .breakpointConfig({ width: [100, undefined, 300, 400] })
    ```
    

下面介绍容器断点的简单开发步骤。

1.  声明状态变量。
    
    首先需要声明用于存储容器尺寸和断点信息的状态变量并初始化，防止在未获取ContainerReader的大小和断点时使用造成异常。
    
    ```
    @State containerSize: Size = { width: 0, height: 0 };
    @State widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;
    ```
    
2.  配置ContainerReader。
    
    将状态变量绑定到ContainerReader组件，使用!!后缀触发双向绑定更新。
    
    ```
    ContainerReader({
      size: this.containerSize!!,
      widthBreakpoint: this.widthBp!!
    }) {
      Column() {
        Text('Adaptive Content')
      }
      .width('100%')
      .height('100%')
    }
    ```
