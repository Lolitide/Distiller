// 来源：documentId = 开发指南/ArkWeb_方舟Web/在应用中使用前端页面JavaScript/前端页面调用应用侧函数/web-in-page-app-function-invoking
// 行范围：L523-L596
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

// xxx.ets
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';

class TestClass {
  constructor() {
  }

  test(param: ESObject): void {
    param.hello("call obj func");
  }

  toString(param: string): void {
    console.info('Web Component toString' + param);
  }
}

@Entry
@Component
struct Index {
  webviewController: webview.WebviewController = new webview.WebviewController();
  @State testObj: TestClass = new TestClass();

  build() {
    Column() {
      Button('refresh')
        .onClick(() => {
          try {
            this.webviewController.refresh();
          } catch (error) {
            console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
          }
        })
      Button('Register JavaScript To Window')
        .onClick(() => {
          try {
            this.webviewController.registerJavaScriptProxy(this.testObj, "testObjName", ["test", "toString"]);
          } catch (error) {
            console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
          }
        })
      Button('deleteJavaScriptRegister')
        .onClick(() => {
          try {
            this.webviewController.deleteJavaScriptRegister("testObjName");
          } catch (error) {
            console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
          }
        })
      Web({ src: $rawfile('index.html'), controller: this.webviewController })
    }
  }
}
```

```
<!-- index.html -->
<!DOCTYPE html>
<html>
<body>
<button type="button" onclick="callArkTS()">Click Me!</button>
<p id="demo"></p>
<script>
    // 写法1
    class Student {
        constructor(nameList) {
            this.methodNameListForJsProxy = nameList;
        }

        hello(param) {
            testObjName.toString(param)
        }
    }
    var st = new Student(["hello"])
