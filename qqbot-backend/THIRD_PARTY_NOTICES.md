# 第三方组件与许可证

本项目（知了 · 后端）使用了以下第三方组件。分发时请保留本文件与各许可证原文。

## 模型

| 组件 | 用途 | 许可证 | 出处 |
| --- | --- | --- | --- |
| Qwen 系列（默认 `qwen3.5:9b`，经 Ollama 运行） | 消息语义解析、候选摘要、画像归纳 | **Apache License 2.0** | 本机 `ollama show qwen3.5:9b --license` 实测输出 Apache 2.0 |

> 说明：本项目**不随代码分发模型权重**，只在自有服务器上调用推理接口。
> 模型输出（摘要/标题等）由我们的规则层再做约束与校验。
> App 侧在「设置 → 关于」中标注来源：**摘要与分类由本机 Qwen 模型（Apache-2.0）生成**。

## Python 依赖

| 组件 | 用途 | 许可证 |
| --- | --- | --- |
| `qq-botpy-v2` | QQ 机器人 SDK | 见 PyPI 项目页 |
| `qqbot-agent-sdk` | 备用机器人 SDK 入口 | 见 PyPI 项目页 |
| `aiosqlite` | 控制台 SQLite（异步） | MIT |
| `python-dotenv` | 读取 `.env` | BSD-3-Clause |
| `httpx` | HTTP 客户端 | BSD-3-Clause |
| `aiohttp` | 附件过路 | Apache-2.0 |
| `cn2an` | 中文数字 → 阿拉伯数字（缺失时回退内置实现） | MIT |
| `pypdf` | PDF 文本抽取（软依赖，缺失时该分支 501） | MIT |
| `cryptography` | Push Kit JWT（PS256）签名 | Apache-2.0 OR BSD-3-Clause |

各依赖的完整许可证文本可在其发行包或 PyPI 项目页获取。
