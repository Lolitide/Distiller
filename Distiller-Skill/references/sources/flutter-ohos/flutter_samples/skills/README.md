# AI Skills

本目录存放 Flutter OHOS 文档配套的 AI 技能（Skills），用于辅助性能分析与崩溃排查。

## 技能列表

| 技能 | 说明 |
|------|------|
| [flutter-ohos-insight](./flutter-ohos-insight/SKILL.md) | 分析 DevEco Studio Profiler 生成的 `.insight` trace 包，诊断 Flutter OHOS 性能问题（卡顿、首帧延迟、UI 线程阻塞、GPU 瓶颈等） |
| [ohos-flutter-crash-analyzer](./ohos-flutter-crash-analyzer/SKILL.md) | 分析 Flutter OHOS 应用崩溃问题，解析 native 栈、定位根因并生成修复建议报告 |

## 目录结构

```
skills/
├── README.md                          # 本文件
├── flutter-ohos-insight/               # .insight trace 分析技能
│   ├── SKILL.md
│   └── scripts/
│       └── insight_analyzer.py
└── ohos-flutter-crash-analyzer/        # 崩溃分析技能
    ├── SKILL.md
    ├── README.md
    ├── metadata.json
    ├── examples/                       # 崩溃分析示例
    └── references/                     # 参考文档（栈解析、引擎架构等）
```
