# VS Code 接入 DeepSeek V4 Pro 文件处理指南

> 目标：在 VS Code 里用 DeepSeek V4 Pro 读写文件、改代码、执行终端命令，效果与 Claude Code 一致。
> 提供两种方案，按需选择。

> **本文定位**：聚焦"在 VS Code 中用 DeepSeek 处理文件"这个具体需求，提供两种方案的快速对比和配置。方案 A（Claude Code）的详细原理和逐行解释见 [02-claude-code-deepseek](./02-claude-code-deepseek.md)，方案 B（Cline 插件）在本文完整展开。
>
> **与其他文章的区别**：
> - [01](./01-claude-code-install.md) 讲安装，本文讲接入 DeepSeek
> - [02](./02-claude-code-deepseek.md) 深入讲原理，本文侧重快速上手 + Cline 方案
> - [05](./05-codex-deepseek.md) 讲的是 OpenAI 的 Codex，不是 Claude Code
>
> **AI 编程工具系列文章：**
> | 编号 | 文章 | 一句话说明 |
> |------|------|-----------|
> | 01 | [安装 Claude Code](./01-claude-code-install.md) | 安装 Claude Code + 代理配置 |
> | 02 | [Claude Code 接入 DeepSeek](./02-claude-code-deepseek.md) | 用 DeepSeek 模型跑 Claude Code 工具链 |
> | **03** | **本文** | **Claude Code 方案 vs Cline 插件方案** |
> | 04 | [Python 调用 AI API 入门](./04-python-ai-api-basics.md) | 用代码调用各家 AI 模型 |
> | 05 | [Codex 接入 DeepSeek](./05-codex-deepseek.md) | OpenAI Codex 接入 DeepSeek + 多模型切换 |

---

## 两种方案对比

| 方案 | 工具 | 文件操作 | 配置难度 | 是否需要 Claude 订阅 |
|------|------|---------|---------|-------------------|
| **方案 A** | Claude Code + DeepSeek | ✅ 完全一致 | ⭐⭐（合并两份已有指南）| ❌ 不需要 |
| **方案 B** | Cline 插件 + DeepSeek | ✅ 读写文件、终端命令 | ⭐（纯插件，最简单）| ❌ 不需要 |

**推荐**：
- 想要和 Claude Code **完全一样**的体验 → 方案 A
- 只想装个插件、快速上手 → 方案 B

---

## 方案 A：Claude Code + DeepSeek V4 Pro

把 Claude Code 的 API 请求重定向到 DeepSeek 服务器。工具链完全是 Claude Code 那套（文件读写、终端操作、多步任务），模型换成 DeepSeek V4 Pro。

**完整配置步骤请看 [02-claude-code-deepseek](./02-claude-code-deepseek.md)**，那篇文章包含安装、环境变量配置、逐行解释和持久化方案。这里只列快速检查清单：

1. 安装 Claude Code CLI：`npm install -g @anthropic-ai/claude-code`
2. 安装 VS Code 扩展：扩展商店搜 `Claude Code`（Anthropic 发布）
3. 配置环境变量或 `.claude/settings.json`（详见 [02](./02-claude-code-deepseek.md#核心配置环境变量方案)）
4. 终端运行 `claude`，输入 `/status` 确认模型为 `deepseek-v4-pro[1m]`

### 能做什么

和 Claude Code 官方版本完全一致：

```
> 读取 src/ 目录下所有 Python 文件，找出潜在的 bug
> 帮我重构 main.py，把所有函数拆成单独的模块
> 运行 python test.py，看看有什么报错，帮我修复
```

---

## 方案 B：Cline 插件 + DeepSeek V4 Pro

### 原理

Cline 是 VS Code 插件，支持 OpenAI 兼容 API，DeepSeek 直接对接，无需中间层。可以读写文件、执行终端命令、多步骤自动完成任务。

### 第一步：安装 Cline 插件

1. 按 `Ctrl+Shift+X` 打开扩展商店
2. 搜索 **Cline**
3. 点 **Install**

安装后左侧边栏出现 Cline 图标。

### 第二步：配置 DeepSeek

1. 点击左侧边栏的 Cline 图标
2. 点击右上角 **设置（齿轮图标）**
3. 找到 **API Provider**，选择 **OpenAI Compatible**
4. 填入以下信息：

| 字段 | 填入值 |
|------|--------|
| Base URL | `https://api.deepseek.com` |
| API Key | 你的 DeepSeek API Key |
| Model | `deepseek-v4-pro` |

5. 点击 **Save**

### 第三步：开始使用

在 Cline 面板输入任务，直接描述你要做什么：

```
读取当前项目的所有 .py 文件，整理成一个模块列表
```

```
帮我在 utils.py 里添加一个日志函数，同时在 main.py 里调用它
```

Cline 会自动读取文件、修改代码、在终端执行命令，每步操作都需要你确认（可设置为自动批准）。

### 注意事项

- 如遇到响应异常，在设置里**关闭 Thinking Mode**（deepseek-v4-pro 的思考模式目前与 Cline 有兼容性问题）
- 关闭思考模式后推理能力略降，但日常文件操作不受影响

---

## 两种方案的文件操作能力对比

| 操作 | 方案 A（Claude Code） | 方案 B（Cline）|
|------|----------------------|--------------|
| 读取文件 | ✅ | ✅ |
| 修改文件 | ✅ | ✅ |
| 创建文件 | ✅ | ✅ |
| 执行终端命令 | ✅ | ✅ |
| 多文件重构 | ✅ 强 | ✅ 强 |
| 跨文件依赖分析 | ✅ 1M 上下文 | ✅（受限于上下文） |
| 任务拆解为子步骤 | ✅ 原生支持 | ✅ 支持 |
| 启动方式 | 终端命令 `claude` | 侧边栏图标 |

---

## 推荐选择

**日常写代码、改代码**：方案 B（Cline）更简单，装完即用，界面友好。

**复杂多步骤任务、大型代码库重构**：方案 A（Claude Code）更稳定，工具链更成熟，1M 上下文处理大型项目有优势。

---

*参考来源：[Cline + DeepSeek V4 Pro 配置](https://knightli.com/en/2026/05/01/use-deepseek-v4-pro-in-cline/) · [DeepSeek VS Code 指南](https://deepseekai.guide/tutorials/deepseek-with-vscode/)*
