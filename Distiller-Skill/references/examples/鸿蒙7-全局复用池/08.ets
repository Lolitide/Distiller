// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式基本语法/自定义组件/自定义组件复用/全局复用_集中化的组件回收与复用/arkts-global-reuse-pool
// 行范围：L975-L1080
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

import { UIUtils, IReusableInfo } from '@kit.ArkUI';

@ReusableV2
@ComponentV2
struct ReusableComponent {
  @Param param: number = 8;

  aboutToAppear() {
    console.info('ReusableComponent aboutToAppear');
  }
  aboutToReuse() {
    console.info('ReusableComponent aboutToReuse');
  }

  build() {
    Column() {
      Text(`ReusableComponent ${this.param}`)
    }
  }
}

@Builder
function preRenderBuilder() {
  ReusableComponent()
}

@Entry
@ComponentV2({ reusePool: 'shared', poolAccepts: [ReusableComponent], freezeWhenInactive: false })
struct Index {
  @Local onUIFullyLoaded: boolean = false;

  aboutToAppear() {
    // 获取池并调度预渲染。
    const pool = UIUtils.getCustomComponentContext(this).getReusePool();
    pool!.preRender(new WrappedBuilder<[]>(preRenderBuilder), 1)
      .then(() => {
        console.info('ReusableComponent preRender completes');
      });
  }

  checkPool() {
    // 获取全局复用池内组件数量
    const reusePool = UIUtils.getCustomComponentContext(this).getReusePool();
    const reusableInfo: IReusableInfo = reusePool!.getReusableInfo(ReusableComponent) as IReusableInfo;
    console.info(`ReusableComponent reuse pool count=${reusableInfo.count}`);
  }

  build() {
    Column({ space: 5 }) {
      Button('Switch')
        .onClick(() => {
          // 切换触发组件复用
          this.onUIFullyLoaded = !this.onUIFullyLoaded;
        })
        .width(100)
      Button('Check pool')
        .onClick(() => {
          // 检查复用池大小
          this.checkPool();
        })
        .width(100)
      CompA({ showFullUI: this.onUIFullyLoaded })
    }
    .width('100%')
  }
}

@ComponentV2
struct CompA {
  @Require @Param showFullUI: boolean;

  build() {
    if (this.showFullUI) {
      ReusableComponent()
    }
  }
}
```

执行序列：

1.  启动时，Index.aboutToAppear()通过UIUtils.getCustomComponentContext(this).getReusePool()获取池并调用preRender。preRender作为空闲任务异步执行：它调用@Builder函数，创建ReusableComponent实例。
2.  预渲染的ReusableComponent被回收到Index的复用池中。预渲染完成打印日志。
    
    ```
    ReusableComponent preRender completes
    ```
    
3.  点击Check pool按钮检查全局复用池大小，打印日志，当前复用池大小为1。
    
    ```
    ReusableComponent reuse pool count=1
    ```
    
4.  点击Switch按钮设置onUIFullyLoaded = true，这会触发CompA的重新渲染。
5.  CompA的if条件变为true。框架创建ReusableComponent时，能找到Index上的全局复用池，并取出预渲染的实例。aboutToAppear触发，组件被复用，无需重新创建，然后执行build展开。
    
    ```
    ReusableComponent aboutToAppear
    ```
    
6.  再次点击Check pool按钮检查全局复用池大小，打印日志，当前复用池大小减少到0，表示预渲染的组件被使用并取出复用池。
    
    ```
    ReusableComponent reuse pool count=0
    ```
