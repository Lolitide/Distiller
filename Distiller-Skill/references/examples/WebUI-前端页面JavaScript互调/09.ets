// 来源：documentId = 开发指南/ArkWeb_方舟Web/在应用中使用前端页面JavaScript/前端页面调用应用侧函数/web-in-page-app-function-invoking
// 行范围：L599-L616
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

    //创建一个构造器，构造函数首字母大写
    function Obj1(){
        this.methodNameListForJsProxy=["hello"];
        this.hello=function(param){
            testObjName.toString(param)
        };
    }
    //利用构造器，通过new关键字生成对象
    var st1 = new Obj1();

    function callArkTS() {
        testObjName.test(st);
        testObjName.test(st1);
    }
</script>
</body>
</html>
```
