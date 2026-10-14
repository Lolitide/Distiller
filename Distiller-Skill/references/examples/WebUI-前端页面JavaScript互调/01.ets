// 来源：documentId = 开发指南/ArkWeb_方舟Web/在应用中使用前端页面JavaScript/前端页面调用应用侧函数/web-in-page-app-function-invoking
// 行范围：L14-L207
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';

class TestClass {
  constructor() {
  }

  test(): string {
    return 'ArkTS Hello World!';
  }
}

@Entry
@Component
struct WebComponent {
  webviewController: webview.WebviewController = new webview.WebviewController();
  // 声明需要注册的对象
  @State testObj: TestClass = new TestClass();

  build() {
    Column() {
      Button('deleteJavaScriptRegister')
        .onClick(() => {
          try {
            this.webviewController.deleteJavaScriptRegister('testObjName');
            this.webviewController.refresh();
          } catch (error) {
            console.error(
              `ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
          }
        })
      // Web组件加载本地index.html页面
      Web({ src: $rawfile('index1.html'), controller: this.webviewController})
        // 将对象注入到web端
        .javaScriptProxy({
          object: this.testObj,
          name: 'testObjName',
          methodList: ['test'],
          controller: this.webviewController,
          // 可选参数
          asyncMethodList: [],
          permission: '{"javascriptProxyPermission":{"urlPermissionList":' +
            '[{"scheme":"resource","host":"rawfile","port":"","path":""},' +
            '{"scheme":"e","host":"f","port":"g","path":"h"}],"methodList":' +
            '[{"methodName":"test","urlPermissionList":' +
            '[{"scheme":"https","host":"xxx.com","port":"","path":""},' +
            '{"scheme":"resource","host":"rawfile","port":"","path":""}]},' +
            '{"methodName":"test11","urlPermissionList":' +
            '[{"scheme":"q","host":"r","port":"","path":"t"},' +
            '{"scheme":"u","host":"v","port":"","path":""}]}]}}'
        })
    }
  }
}
```

应用侧使用registerJavaScriptProxy()接口注册。

*   使用registerJavaScriptProxy()方法注册后，在下次加载或者重新加载后生效。

*   示例1：
    
    ```
    // xxx.ets
    import { webview } from '@kit.ArkWeb';
    import { BusinessError } from '@kit.BasicServicesKit';
    
    class TestClass {
      constructor() {
      }
    
      test(): string {
        return 'ArkUI Web Component';
      }
    
      toString(): void {
        console.info('Web Component toString');
      }
    }
    
    @Entry
    @Component
    struct Index {
      webviewController: webview.WebviewController = new webview.WebviewController();
      @State testObj: TestClass = new TestClass();
    
      build() {
        Column() {
          // jsb对象不再使用后，需解除注册，防止内存泄漏
          Button('deleteJavaScriptRegister')
            .onClick(() => {
              try {
                this.webviewController.deleteJavaScriptRegister('testObjName');
                this.webviewController.refresh();
              } catch (error) {
                console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
              }
            })
          Web({ src: $rawfile('index1.html'), controller: this.webviewController })
          // 在页面加载前注册，页面加载完成后生效
            .onControllerAttached(()=>{
              try {
                this.webviewController.registerJavaScriptProxy(this.testObj, 'testObjName', ['test', 'toString'],
                        // 可选参数, asyncMethodList
                        [],
                        // 可选参数, permission
                        '{"javascriptProxyPermission":{"urlPermissionList":[{"scheme":"resource","host":"rawfile","port":"","path":""},' +
                        '{"scheme":"e","host":"f","port":"g","path":"h"}],"methodList":[{"methodName":"test","urlPermissionList":' +
                        '[{"scheme":"https","host":"xxx.com","port":"","path":""},{"scheme":"resource","host":"rawfile","port":"","path":""}]},' +
                        '{"methodName":"test11","urlPermissionList":[{"scheme":"q","host":"r","port":"","path":"t"},' +
                        '{"scheme":"u","host":"v","port":"","path":""}]}]}}'
                );
              } catch (error) {
                console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
              }
            })
        }
      }
    }
    ```
    
*   示例2：
    
    ```
    // xxx.ets
    import { webview } from '@kit.ArkWeb';
    import { BusinessError } from '@kit.BasicServicesKit';
    
    class TestClass {
      constructor() {
      }
    
      test(): string {
        return 'ArkUI Web Component';
      }
    
      toString(): void {
        console.info('Web Component toString');
      }
    }
    
    @Entry
    @Component
    struct Index {
      webviewController: webview.WebviewController = new webview.WebviewController();
      @State testObj: TestClass = new TestClass();
      @State isRegistered: boolean = false;
    
      build() {
        Column() {
          // jsb对象不再使用后，需解除注册，防止内存泄漏
          Button('deleteJavaScriptRegister')
            .onClick(() => {
              try {
                this.webviewController.deleteJavaScriptRegister('testObjName');
                this.webviewController.refresh();
              } catch (error) {
                console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
              }
            })
          Web({ src: $rawfile('index1.html'), controller: this.webviewController })
            .onPageEnd(()=>{
              try {
                if(!this.isRegistered){
                this.webviewController.registerJavaScriptProxy(this.testObj, 'testObjName', ['test', 'toString'],
                        // 可选参数, asyncMethodList
                        [],
                        // 可选参数, permission
                        '{"javascriptProxyPermission":{"urlPermissionList":[{"scheme":"resource","host":"rawfile","port":"","path":""},' +
                        '{"scheme":"e","host":"f","port":"g","path":"h"}],"methodList":[{"methodName":"test","urlPermissionList":' +
                        '[{"scheme":"https","host":"xxx.com","port":"","path":""},{"scheme":"resource","host":"rawfile","port":"","path":""}]},' +
                        '{"methodName":"test11","urlPermissionList":[{"scheme":"q","host":"r","port":"","path":"t"},' +
                        '{"scheme":"u","host":"v","port":"","path":""}]}]}}'
                  );
                  this.isRegistered = true;
                  // onPageEnd中注册方法后，需重新加载后生效
                  this.webviewController.refresh();
                }
              } catch (error) {
                console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
              }
            })
        }
      }
    }
    ```
    
*   可选参数permission是一个JSON字符串，示例如下：
    
    ```
    {
      "javascriptProxyPermission": {
        "urlPermissionList": [       // Object级权限，如果匹配，所有Method都授权
          {
