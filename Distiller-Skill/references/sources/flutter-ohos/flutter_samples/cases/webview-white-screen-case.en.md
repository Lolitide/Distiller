# Case Study: White Screen When a Webview Launches Payment

I. Solution to the ERR_UNKNOWN_URL_SCHEME error reported when a deeplink launches an app or loading continues

1. Open certain web pages through web; a white screen appears after the page opens.
2. Debug the link with the inspect method below, and find that the scheme of the link is not http or https.
How to use inspect: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/web-debugging-with-devtools

After loading, the protocol turns out to be bdnetdisk instead of http or https.
This is a custom scheme. HarmonyOS supports only three schemes by default: http, https, and file. Custom schemes must be configured on your own before they can be loaded and rendered correctly.

The following provides demo code that supports custom schemes. After a custom scheme is added, opening web loads the custom scheme and displays it correctly.
```
import { webview } from '@kit.ArkWeb';

@Entry
@Component
struct Index {
   @State url: string = 'https://lsj01.top/';
   private webController: WebviewController = new webview.WebviewController()
   schemeHandler: webview.WebSchemeHandler = new webview.WebSchemeHandler(); // schemeHandler must be declared to configure custom schemes
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
         // In onControllerAttached, set the schemes to support loading, such as bdnetdisk, bilibili, etc.
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

For a custom scheme, use interception to launch the corresponding app.
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
         // Web({ src: $rawfile('1.html'), controller: this.controller }) // Using this opens the 1.html link; clicking the URL here then navigates to Alipay
         Web({ src: 'https://u.alipay.cn/_6hzg1sryluB', controller: this.controller }) // Using this, opening the demo navigates directly to Alipay
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
