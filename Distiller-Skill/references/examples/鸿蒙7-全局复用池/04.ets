// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式基本语法/自定义组件/自定义组件复用/全局复用_集中化的组件回收与复用/arkts-global-reuse-pool
// 行范围：L361-L471
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

@ReusableV2
@ComponentV2
struct ReusableChild {
  @Consumer() provide: number = 10;

  aboutToAppear() {
    console.info('ReusableChild aboutToAppear');
  }
  aboutToReuse() {
    console.info('ReusableChild aboutToReuse');
    // 组件被复用时修改@Consumer状态变量，能同步该数据到Parent组件的@Provider状态变量中。
    this.provide = 150;
  }
  aboutToRecycle() {
    console.info('ReusableChild aboutToRecycle');
  }
  aboutToDisappear() {
    console.info('ReusableChild aboutToDisappear');
  }

  build() {
    Column({ space: 20 }) {
      Text(`ReusableChild @Consumer: ${this.provide}`)
        .fontSize(20)
      SubChild()
    }
  }
}

@Entry
// 声明全局复用池，接纳ReusableChild复用组件。
@ComponentV2({ reusePool: 'perInstance', poolAccepts: [ReusableChild], freezeWhenInactive: false })
struct Parent {
  @Provider() provide: number = 100;
  @Local boolVal: boolean = false;

  build() {
    Column({ space: 10 }) {
      Button('切换组件')
        .onClick(() => {
          this.boolVal = !this.boolVal;
        })

      Text(`父组件 Provider: ${this.provide}`)
        .fontSize(20)
      Button('增加 +10')
        .onClick(() => {
          this.provide += 10;
        })

      // 切换到可复用组件时，ReusableChild会进入当前组件的全局复用池中。
      if (this.boolVal) {
        Text('非可复用组件')
          .fontSize(24)
        Child()
      } else {
        Text('可复用组件')
          .fontSize(24)
        ReusableChild()
      }
    }
    .width('100%')
  }
}

@ComponentV2
struct SubChild {
  @Consumer() provide: number = 10;

  aboutToAppear() {
    console.info('SubChild aboutToAppear');
  }
  aboutToReuse() {
    console.info('SubChild aboutToReuse');
  }
  aboutToRecycle() {
    console.info('SubChild aboutToRecycle');
  }
  aboutToDisappear() {
    console.info('SubChild aboutToDisappear');
  }

  build() {
    Text(`SubChild @Consumer: ${this.provide}`)
  }
}

@ComponentV2
struct Child {
  @Consumer() provide: number = 10;

  aboutToAppear() {
    console.info('Child aboutToAppear');
  }
  aboutToDisappear() {
    console.info('Child aboutToDisappear');
  }

  build() {
    Column({ space: 20 }) {
      Text(`Child @Consumer: ${this.provide}`)
        .fontSize(20)
      SubChild()
    }
  }
}
```

**从ReusableChild切换到Child**：

```
