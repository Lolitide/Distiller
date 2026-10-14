// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式基本语法/自定义组件/自定义组件复用/全局复用_集中化的组件回收与复用/arkts-global-reuse-pool
// 行范围：L52-L160
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

@Entry
@ComponentV2
struct Index {
  @Local componentSwitch: boolean = false;
  build() {
    Column() {
      Button('Switch components')
        .onClick(() => {
          this.componentSwitch = !this.componentSwitch;
        })
      if (this.componentSwitch) { // 切换不同子组件
        ChildComponentA()
      } else {
        ChildComponentB()
      }
    }
  }
}
@ComponentV2
struct ChildComponentA { // ReusableComponent复用组件的复用池默认在组件ChildComponentA上，在Index组件中if分支切换时销毁
  build() {
    Column() {
      Text('Component A')
      ReusableComponent() // 子组件ComponentA和ComponentB共用复用组件ReusableComponent
    }
  }
}
@ComponentV2
struct ChildComponentB {
  build() {
    Column() {
      Text('Component B')
      ReusableComponent() // 子组件ComponentA和ComponentB共用复用组件ReusableComponent
    }
  }
}
@ReusableV2
@ComponentV2
struct ReusableComponent { // 复用组件
  aboutToRecycle() {
    console.info('Reusable component is being recycled');
  }
  aboutToDisappear() {
    console.info('Reusable component is being destroyed'); // 在Index组件中if分支切换时，由于位于父组件ChildComponentA的默认复用池被销毁，该复用组件也会被销毁，无法被ChildComponentB复用。
  }
  build() {
    Text('ReusableComponent')
  }
}
```

适配全局复用能力的示例如下：

```
@ReusableV2
@ComponentV2
struct ReusableComponent { // 复用组件
  aboutToRecycle() {
    // 在Index组件中if分支切换时，该组件由上层组件Index声明的全局复用池接纳，并复用到ChildComponentB中的ReusableComponent创建过程中
    console.info('Reusable component is being recycled');
  }
  aboutToDisappear() {
    console.info('Reusable component is being destroyed');
  }
  build() {
    Text('ReusableComponent')
  }
}
@Entry
@ComponentV2({
  reusePool: 'shared', // 配置全局复用池模式，使能全局复用能力
  poolAccepts: [ReusableComponent], // 配置全局复用池接纳名称为ReusableComponent的自定义组件
  freezeWhenInactive: false // 组件冻结默认配置
})
struct Index {
  @Local componentSwitch: boolean = false;
  build() {
    Column() {
      Button('Switch components')
        .onClick(() => {
          this.componentSwitch = !this.componentSwitch;
        })
      if (this.componentSwitch) { // 切换不同子组件
        ChildComponentA()
      } else {
        ChildComponentB()
      }
    }
  }
}
@ComponentV2
struct ChildComponentA { // ReusableComponent复用组件的复用池使用上层组件Index的全局复用池，在ComponentA上的默认复用池会被跳过
  build() {
    Column() {
      Text('Component A')
      ReusableComponent() // 子组件ComponentA和ComponentB共用复用组件ReusableComponent
    }
  }
}
@ComponentV2
struct ChildComponentB {
  build() {
    Column() {
      Text('Component B')
      ReusableComponent() // 子组件ComponentA和ComponentB共用复用组件ReusableComponent
    }
  }
}
```
