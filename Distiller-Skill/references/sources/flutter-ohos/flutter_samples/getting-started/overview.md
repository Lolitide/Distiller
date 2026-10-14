# 框架介绍

## Flutter 是什么

Flutter 是 Google 开源的高性能跨平台 UI 框架。开发者使用 **Dart** 与 **Widget** 描述界面与业务逻辑，一套代码可面向 iOS、Android、Windows、macOS、Linux 等多个目标平台构建应用，并支持与各平台 **原生代码混合开发**。Flutter 在世界各地被大量开发者与组织采用，协议与源码均开放。

更完整的通用说明见 [Flutter 中文开发文档](https://docs.flutter.cn/)。

## Flutter 与 OpenHarmony（Flutter OH）

除上述官方支持的平台外，**Flutter 已面向 OpenHarmony 完成工程化适配**（社区常称 **Flutter OH** 或 **OpenHarmony Flutter**）。在适配形态下，你可以：

- **沿用 Flutter 应用模型**：Dart、Widget、`pub` 依赖、热重载/调试等开发体验与常规 Flutter 项目一致（具体以当前工具链版本为准）。
- **面向 OpenHarmony 构建与运行**：通过扩展后的构建产物（如 HAR 等）与宿主集成方式，将 Flutter 模块部署到 OpenHarmony 设备或模拟器。
- **与原生协同**：在 OpenHarmony 应用（ArkUI / Stage 模型等）中嵌入 Flutter 页面或模块，通过 **Platform Channel**、**Platform View**、**多引擎** 等能力与原生互通，并按需接入三方插件。

换言之：**同一套 Flutter 技术栈**在适配层与工具链的支撑下，**扩展到了 OpenHarmony 生态**，便于在 OpenHarmony 设备上复用现有 Flutter 资产或从零构建混合应用。

> 说明：OpenHarmony 相关引擎、SDK 与构建流程由适配社区与本文档配套仓库维护；**上游 Flutter 仍以 Google 文档为准**，平台差异与排期见下文「延伸阅读」中的版本与分支说明。

## 在本套文档中的位置

- 整体能力与分层设计见：[Flutter OH 架构介绍](../getting-started/architecture.md)
- 环境、设备与编译准备见：[环境搭建](../getting-started/README.md) 与 [Flutter OH 开发环境搭建](../getting-started/flutter-oh-env-setup.md)
- 嵌入应用、Channel、性能与 FAQ 等见：[文档总索引](../README.md)

## 延伸阅读

- [Flutter 体系结构概览](https://flutter.cn/docs/resources/architectural-overview)（通用架构，与 OpenHarmony 适配层结合阅读）
- [Flutter OH 版本说明与分支策略](https://gitcode.com/CPF-Flutter/flutter_flutter/wiki/Flutter-OH%E7%89%88%E6%9C%AC%E6%BC%94%E8%BF%9B%E8%A7%84%E5%88%92%E5%92%8C%E5%88%86%E6%94%AF%E7%AD%96%E7%95%A5.md)（OpenHarmony 适配演进）
