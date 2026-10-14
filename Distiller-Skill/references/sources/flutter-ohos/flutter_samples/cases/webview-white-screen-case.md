# webview拉起支付白屏场景案例

一、deeplink拉起应用或者继续进行加载，报错ERR_UNKNOWN_URL_SCHEME的解决方案

1. 通过web打开某些网页，打开后出现白屏。
2. 通过如下的inspect方式对链接进行调试，发现链接的scheme不是http或者https。
inspect使用方法：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/web-debugging-with-devtools

加载后，发现协议变成了bdnetdisk，而不是http或者https。
这种就是自定义scheme，而鸿蒙默认只支持http/https/file这3种协议，自定义协议，需要自行配置，才能正常加载实现。

如下提供支持自定义scheme的demo代码写法。增加自定义scheme后，打开web，就可以加载自定义的scheme，并正常显示出来。
```
import { webview } from '@kit.ArkWeb';

@Entry
@Component
struct Index {
   @State url: string = 'https://lsj01.top/';
   private webController: WebviewController = new webview.WebviewController()
   schemeHandler: webview.WebSchemeHandler = new webview.WebSchemeHandler(); // 需要声明schemeHandler,用于配置自定义scheme
   aboutToAppear(): void {
      webview.WebviewController.setWebDebuggingAccess(true)
   }

   build() {
      Column() {
         Web(
            {
               src: "https://pan.baidu.com/s/1t1b1sQYoic1qj3WD0uezgw?pwd=kick#list/path=%2F",
               controller: this.webController,
            }
         )
         // 在onControllerAttached中，对scheme设置所需要支持加载的协议，如bdnetdisk,bilibili等
         .onControllerAttached(
            ()=> {
               this.schemeHandler.onRequestStart((request: webview.WebSchemeHandlerRequest,
                  resourceHandler: webview.WebResourceHandler) => {
                     return true;
                  })
               this.webController.setWebSchemeHandler("bdnetdisk", this.schemeHandler)
            }
         )
         .fileAccess(true)
         .domStorageAccess(true)
      }
      .height('100%')
      .width('100%')
   }
}
```

自定义scheme，通过拦截的方式，拉起对应的应用。
```
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { common, OpenLinkOptions } from '@kit.AbilityKit';

@Entry
@Component
struct WebComponent {
   controller: webview.WebviewController = new webview.WebviewController();
   controllerT: TextInputController = new TextInputController();
   private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
   build() {
      Column() {
         // Web({ src: $rawfile('1.html'), controller: this.controller }) //使用这个会打开1.html这个链接，然后点击这里的URL,就会跳转到支付宝
         Web({ src: 'https://u.alipay.cn/_6hzg1sryluB', controller: this.controller }) //使用这个，打开demo后，会直接跳转到支付宝
            .geolocationAccess(false)
            .domStorageAccess(true)
            .databaseAccess(true)
            .fileAccess(true)
            .imageAccess(true)
            .javaScriptAccess(true)
            .onlineImageAccess(true)
            .allowWindowOpenMethod(true)
            .enableWebAVSession(false)
            .onLoadIntercept((event) => {
               const url: string = event.data.getRequestUrl();
               console.warn('url '+url)
               if (!url.startsWith('http')&&!url.startsWith('https')&&!url.startsWith('resource')) {
                  const link: string = url;
                  console.warn('link '+link)
                  const openLinkOptions: OpenLinkOptions = {
                     appLinkingOnly: false,
                     parameters: {
                        name: 'test'
                     }
                  };
                  this.context.openLink(link, openLinkOptions).then(() => {
                     console.info('open link success.');
                  }).catch((err: BusinessError) => {
                     console.error('open link failed. Code is ${err.code}, message is ${err.message}');
                  })
               }
               return false;
            })
      }
   }
}
```

html
```
<!-- call.html -->
<!DOCTYPE html>
<html>
<body>
<div>
   <br>
   <a href="https://u.alipay.cn/_6hzg1sryluB">这里</a>
   <br>
</div>
</body>
</html>
```
