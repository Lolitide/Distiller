// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式基本语法/自定义组件/自定义组件复用/全局复用_集中化的组件回收与复用/arkts-global-reuse-pool
// 行范围：L724-L835
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

import { UIUtils, IReusableInfo } from '@kit.ArkUI';

@ReusableV2
@ComponentV2
struct TestChild {
  @Param label: string = '';
  aboutToAppear() {
    console.info(`TestChild [${this.label}] aboutToAppear`);
  }
  aboutToReuse() {
    console.info(`TestChild [${this.label}] aboutToReuse`);
  }
  aboutToRecycle() {
    console.info(`TestChild [${this.label}] aboutToRecycle`);
  }
  aboutToDisappear() {
    console.info(`TestChild [${this.label}] aboutToDisappear`);
  }
  build() {
    Text(`子组件: ${this.label}`)
  }
}

@Entry
// 配置全局复用池，使用perInstance所有权模式，接纳TestChild复用组件
@ComponentV2({ reusePool: 'perInstance', poolAccepts: [TestChild], freezeWhenInactive: false })
struct PoolOwner {
  @Local showA: boolean = true;
  @Local showB: boolean = true;
  @Local showC: boolean = true;

  // 清空指定reuseId的复用池
  purgeReuseId(id: string) {
    const pool = UIUtils.getCustomComponentContext(this).getReusePool();
    const info = pool?.getReusableInfo(TestChild, id) as IReusableInfo;
    if (info) {
      info.maxCount = 0;  // 仅释放全局复用池中此reuseId对应的复用组件
    }
  }

  // 打印当前组件复用池信息
  printReusePool() {
    const pool = UIUtils.getCustomComponentContext(this).getReusePool();
    const info = pool?.getReusableInfo(TestChild) as IReusableInfo[];
    if (info) {
      info.forEach((item) => {
        console.info(`{ count: ${item.count}, maxCount: ${item.maxCount}, reuseId: ${item.reuseId} }`);
      })
    }
  }

  build() {
    Column({ space: 3 }) {
      Button('切换A')
        .onClick(() => {
          this.showA = !this.showA;
        })
        .width(150)
      Button('切换B')
        .onClick(() => {
          this.showB = !this.showB;
        })
        .width(150)
      Button('切换C')
        .onClick(() => {
          this.showC = !this.showC;
        })
        .width(150)
      Button('仅清除B')
        // 清除reuseId为B的复用池大小
        .onClick(() => this.purgeReuseId('B'))
        .width(150)
      Button('打印复用池信息')
        .onClick(() => this.printReusePool())
        .width(150)

      if (this.showA) {
        TestChild({ label: 'A' })
          .reuse({ reuseId: () => 'A' })
      }
      if (this.showB) {
        // TestChild B 使用reuseId B
        TestChild({ label: 'B' })
          .reuse({ reuseId: () => 'B' })
      }
      if (this.showC) {
        TestChild({ label: 'C' })
          .reuse({ reuseId: () => 'C' })
      }
    }
    .width('100%')
  }
}
```

当所有3个都被关闭时，getReusableInfo(TestChild)（不带reuseId）返回一个数组：

```
  { count: 0, maxCount: 100, reuseId: undefined }  // 始终包含
  { count: 1, maxCount: 100, reuseId: 'A' }
  { count: 1, maxCount: 100, reuseId: 'B' }
  { count: 1, maxCount: 100, reuseId: 'C' }
```

点击"仅清除B"（设置B的maxCount = 0）后，只有B的实例被释放。数组变为：

```
  { count: 0, maxCount: 100, reuseId: undefined }
  { count: 1, maxCount: 100, reuseId: 'A' }
  { count: 0, maxCount: 0, reuseId: 'B' } // maxCount非默认时也会显示
  { count: 1, maxCount: 100, reuseId: 'C' }
```
