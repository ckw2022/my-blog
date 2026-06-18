# Claude Code 接入 DeepSeek V4：用最强工具链跑最划算的模型

> Claude Code 是目前最好的 AI 编程工具链之一，但官方模型价格不低。DeepSeek V4 原生兼容 Anthropic API，只需几行配置就能无缝接入。本文从原理到实操，手把手带你完成配置，并逐行解释每条命令的含义。

---

## 为什么要这么做？

Claude Code 的核心价值在于它的**工具链和执行力**——文件读写、终端操作、多步任务拆解、自动修复——这些能力跟底层用哪个模型无关。而 DeepSeek V4 提供了一个关键特性：**原生兼容 Anthropic API 协议**，这意味着 Claude Code 可以直接对接 DeepSeek，不需要任何中间适配层。

性价比对比：

| 模型 | 输出价格（每百万 token） | 上下文窗口 |
|------|--------------------------|------------|
| Claude Opus 4.6 | ~$25 | 200K |
| Claude Sonnet 4.6 | ~$15 | 200K |
| DeepSeek V4-Pro | ~$3.48 | 1M |
| DeepSeek V4-Flash | ~$0.28 | 1M |

同样的工具链，成本降低 70% 以上，上下文窗口还从 200K 扩展到了 1M。

---

## 前置条件

开始之前，确保你的环境满足以下三个条件：

**1. 安装 Node.js 18+**

Claude Code 基于 Node.js 运行。Windows 用户还需要额外安装 Git for Windows。

```bash
# 检查 Node.js 版本
node --version
# 需要 v18.0.0 或更高
```

**2. 安装 Claude Code**

```bash
npm install -g @anthropic-ai/claude-code
```

这条命令的含义：`npm install` 是 Node.js 的包管理器安装命令，`-g` 表示全局安装（这样在任何目录都能使用 `claude` 命令），`@anthropic-ai/claude-code` 是 Anthropic 官方发布的 Claude Code 包名。

安装完成后验证：

```bash
claude --version
```

如果显示版本号，说明安装成功。

**3. 获取 DeepSeek API Key**

前往 DeepSeek 开放平台注册并创建 API Key：

```
https://platform.deepseek.com/api_keys
```

注册后充值一点余额（几块钱就够测试了），然后创建一个 API Key，复制保存好。

---

## 核心配置：环境变量方案

接入的核心原理很简单：通过环境变量，告诉 Claude Code "别把请求发给 Anthropic 的服务器了，发给 DeepSeek 的服务器"。

### Mac / Linux 配置

在终端中执行以下命令：

```bash
export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
export ANTHROPIC_AUTH_TOKEN=<你的DeepSeek API Key>
export ANTHROPIC_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
export CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
export CLAUDE_CODE_EFFORT_LEVEL=max
```

### Windows PowerShell 配置

```powershell
$env:ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
$env:ANTHROPIC_AUTH_TOKEN="<你的DeepSeek API Key>"
$env:ANTHROPIC_MODEL="deepseek-v4-pro[1m]"
$env:ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]"
$env:ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]"
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
$env:CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
$env:CLAUDE_CODE_EFFORT_LEVEL="max"
```

---

## 逐行解释每条配置

### ANTHROPIC_BASE_URL

```bash
export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
```

这是最关键的一行。Claude Code 默认把 API 请求发给 `https://api.anthropic.com`，设置这个变量后，所有请求会被重定向到 DeepSeek 的服务器。之所以能这样做，是因为 DeepSeek 专门提供了一个兼容 Anthropic API 格式的端点（`/anthropic`），接收的请求格式和返回的响应格式都跟 Anthropic 官方一致。

### ANTHROPIC_AUTH_TOKEN

```bash
export ANTHROPIC_AUTH_TOKEN=<你的DeepSeek API Key>
```

原本这里填的是 Anthropic 的 API Key，现在换成 DeepSeek 的。DeepSeek 的服务器会用这个 Key 来验证你的身份和扣费。格式类似 `sk-xxxxxxxxxxxxxxxx`。

### ANTHROPIC_MODEL

```bash
export ANTHROPIC_MODEL=deepseek-v4-pro[1m]
```

指定默认使用的模型。`deepseek-v4-pro` 是 DeepSeek V4 的旗舰版本，后面的 `[1m]` 表示启用 **1M（一百万 token）上下文窗口**。如果不加 `[1m]`，默认上下文窗口是 128K。对于大型项目的代码分析，1M 上下文是巨大的优势。

### ANTHROPIC_DEFAULT_OPUS_MODEL / SONNET_MODEL

```bash
export ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
```

Claude Code 内部在不同场景会调用不同级别的模型。Opus 用于最复杂的推理，Sonnet 用于常规任务。这里把它们都映射到 `deepseek-v4-pro[1m]`，确保所有场景都使用 V4-Pro。

### ANTHROPIC_DEFAULT_HAIKU_MODEL

```bash
export ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
```

Haiku 是轻量级模型，用于简单的子任务（比如判断文件类型、简短回复）。这里映射到 `deepseek-v4-flash`，它的价格只有 V4-Pro 的 1/12，用于简单任务绰绰有余，能大幅节省成本。

### CLAUDE_CODE_SUBAGENT_MODEL

```bash
export CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
```

Claude Code 在执行复杂任务时会拆分子任务，交给"子代理"处理。这个变量指定子代理使用的模型。同样用 Flash 来控制成本——子任务通常不需要最强的推理能力。

### CLAUDE_CODE_EFFORT_LEVEL

```bash
export CLAUDE_CODE_EFFORT_LEVEL=max
```

设置思考强度为最高级别。DeepSeek V4-Pro 支持"深度思考"模式，`max` 会让模型在回答前进行更充分的推理。这是 V4-Pro 的满血配置——开启思考模式 + 最大推理强度 + 1M 上下文。

---

## 验证是否接入成功

配置完成后，在终端输入：

```bash
claude
```

进入 Claude Code 界面后，输入：

```
/status
```

如果显示的 model 为 `deepseek-v4-pro[1m]`，说明接入成功。

---

## 持久化配置（推荐）

上面的 `export` 命令只在当前终端会话有效，关掉终端就没了。要让配置永久生效，有两种方式：

### 方式一：写入 Shell 配置文件

Mac/Linux 用户把上面那些 `export` 命令追加到 `~/.bashrc` 或 `~/.zshrc`：

```bash
echo 'export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic' >> ~/.zshrc
echo 'export ANTHROPIC_AUTH_TOKEN=你的Key' >> ~/.zshrc
# ... 其余几行同理
source ~/.zshrc
```

### 方式二：使用 Claude Code 的 settings.json

在项目根目录创建 `.claude/settings.json`：

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "你的DeepSeek API Key",
    "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
    "ANTHROPIC_MODEL": "deepseek-v4-pro[1m]",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "deepseek-v4-pro[1m]",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "deepseek-v4-pro[1m]",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "deepseek-v4-flash",
    "CLAUDE_CODE_SUBAGENT_MODEL": "deepseek-v4-flash",
    "CLAUDE_CODE_EFFORT_LEVEL": "max",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
```

这里多了两个可选配置：

- `API_TIMEOUT_MS`：设为 3000000（50 分钟）。DeepSeek 在开启深度思考时响应可能较慢，加大超时时间避免中途断开。
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`：设为 1，禁止 Claude Code 向 Anthropic 发送非必要的遥测请求，因为我们用的不是 Anthropic 的服务。

---

## Claude Desktop 接入方案

除了命令行的 Claude Code，Claude Desktop（桌面客户端）同样支持接入第三方模型。

**第一步**：前往 https://claude.ai/downloads 下载安装 Claude Desktop。

**第二步**：启动后，在登录界面开启**开发者模式**（无需注册 Claude 账号）。

**第三步**：在设置中添加自定义模型，填入 DeepSeek 的 Base URL 和 API Key。

Claude Desktop 的优势是同时拥有 Cowork（文档处理）和 Code（编程开发）两种模式，左上角一键切换，覆盖更多工作场景。

---

## 模型选择建议

| 场景 | 推荐模型 | 理由 |
|------|----------|------|
| 复杂架构设计、跨文件重构 | V4-Pro [1m] | 需要强推理 + 长上下文 |
| 日常编码、bug 修复 | V4-Pro | 标准上下文即可 |
| 简单生成、格式转换 | V4-Flash | 极致性价比 |
| 子任务、文件分类 | V4-Flash | 不需要强推理 |

---

## 已知限制

- **不支持图片输入**：当前 DeepSeek V4 的 Anthropic 兼容接口暂不支持传入图片，所以 Claude Code 中涉及截图分析的功能无法使用。
- **响应速度**：开启 max effort 思考模式后，复杂问题的首次响应可能需要较长时间（30 秒以上），这是模型在进行深度推理。
- **复杂推理场景**：在极端复杂的编码和前沿推理任务上，V4-Pro 与 Claude Opus 4.6 仍有差距，可能需要多次调教。

---

## 总结

整个配置过程不超过 5 分钟：安装 Claude Code → 获取 DeepSeek API Key → 设置环境变量 → 验证。核心原理就是一个 URL 重定向——把请求从 Anthropic 转发到 DeepSeek，后者提供了完全兼容的 API 接口，所以 Claude Code 的所有功能（工具调用、多步任务、代码执行）都能正常工作。

一次配置，长期受益。
