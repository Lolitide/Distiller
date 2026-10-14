// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式基本语法/自定义组件/自定义组件复用/全局复用_集中化的组件回收与复用/arkts-global-reuse-pool
// 行范围：L241-L354
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

@Entry
@ComponentV2
struct Parent {
  @Local show: boolean[] = [true, true, true];

  build() {
    Column({ space: 20 }) {
      Row({ space: 10 }) {
        Button('删除Comp1')
          .onClick(() => this.show[0] = false)
        Button('添加Comp1')
          .onClick(() => this.show[0] = true)
      }
      Row({ space: 10 }) {
        Button('删除Comp2')
          .onClick(() => this.show[1] = false)
        Button('添加Comp2')
          .onClick(() => this.show[1] = true)
      }
      Row({ space: 10 }) {
        Button('删除Comp3')
          .onClick(() => this.show[2] = false)
        Button('添加Comp3')
          .onClick(() => this.show[2] = true)
      }

      Column({ space: 10 }) {
        // 使用if切换触发复用。
        if (this.show[0]) {
          CompA({ label: 'A1' })
        }
        if (this.show[1]) {
          CompA({ label: 'A2' })
        }
        if (this.show[2]) {
          CompA({ label: 'A3' })
        }
      }
    }
    .width('100%')
  }
}

@ReusableV2
@ComponentV2
struct ReusableCompA {
  @Require @Param value: number;

  aboutToAppear() {
    console.info('ReusableCompA aboutToAppear');
  }
  aboutToReuse() {
    console.info('ReusableCompA aboutToReuse');
  }
  aboutToRecycle() {
    console.info('ReusableCompA aboutToRecycle');
  }
  aboutToDisappear() {
    console.info('ReusableCompA aboutToDisappear');
  }

  build() {
    Text(`ReusableCompA Item ${this.value}`)
      .fontSize(16)
      .fontColor(Color.Green)
  }
}

// 多个CompA组件实例共用一个ReusableCompA的全局复用池。
@ComponentV2({ reusePool: 'shared', poolAccepts: [ReusableCompA], freezeWhenInactive: false})
struct CompA {
  @Require @Param label: string;

  build() {
    Column({ space: 5 }) {
      Text(`CompA ${this.label}`)
        .fontSize(18)
        .fontColor(Color.Blue)
      ReusableCompA({ value: 1 })
      ReusableCompA({ value: 2 })
    }
    .border({ width: 1, color: Color.Gray })
    .padding(5)
  }
}
```

**启动** — 6个ReusableCompA子组件被创建：

```
ReusableCompA aboutToAppear (×6)
```

**删除Comp1** — 子组件被回收：

```
ReusableCompA aboutToRecycle (×2)
```

**添加Comp1** — 子组件从共享池中复用：

```
ReusableCompA aboutToReuse (×2)
```

**依次删除所有3个CompA** — 当最后一个CompA被销毁时，没有剩余的CompA实例，因此共享池也被销毁：

```
// 删除Comp1和Comp2：子组件被回收
ReusableCompA aboutToRecycle (×2, 每个被删除的CompA)

// 删除Comp3：最后一个实例 — 共享池被销毁
ReusableCompA aboutToDisappear (×6, 所有缓存实例被永久销毁)
```
