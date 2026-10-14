// 来源：documentId = 开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式基本语法/自定义组件/自定义组件复用/全局复用_集中化的组件回收与复用/arkts-global-reuse-pool
// 行范围：L164-L169
// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改
// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译

@Component/@ComponentV2配置参数：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| reusePool | ReusePoolOwnership | 否 | 如果使用全局复用功能，该参数的值必须为"shared"或"perInstance"。决定此组件类的所有实例是共享单个复用池还是每个实例拥有自己的池。 |
| poolAccepts | Function[] | 否 | 全局复用池接纳的可复用组件的数组，可以同时包含@Reusable和@ReusableV2装饰的自定义组件。 |
