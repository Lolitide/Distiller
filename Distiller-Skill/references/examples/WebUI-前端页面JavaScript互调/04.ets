// 来源：documentId = 开发指南/ArkWeb_方舟Web/在应用中使用前端页面JavaScript/前端页面调用应用侧函数/web-in-page-app-function-invoking
// 行范围：L252-L278
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

              }
            ]
          }
        ]
      }
    }
    ```
    
*   index1.html前端页面触发应用侧代码。
    
    ```
    <!-- index1.html -->
    <!DOCTYPE html>
    <html>
    <body>
    <button type="button" onclick="callArkTS()">Click Me!</button>
    <p id="demo"></p>
    <script>
        function callArkTS() {
            let str = testObjName.test();
            document.getElementById("demo").innerHTML = str;
            console.info('ArkTS Hello World! :' + str);
        }
    </script>
    </body>
    </html>
    ```
