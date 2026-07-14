# Claude Code 接入 DeepSeek V4：用最强工具链跑最划算的模型

> Claude Code 是目前最好的 AI 编程工具链之一，但官方模型价格不低。DeepSeek V4 原生兼容 Anthropic API，只需几行配置就能无缝接入。本文从原理到实操，手把手带你完成配置，并逐行解释每条命令的含义。

> **前置要求**：需要先安装好 Claude Code，见 [01-claude-code-install](./01-claude-code-install.md)。
>
> **相关文章**：如果你想在 VS Code 中用更轻量的方式（Cline 插件）接入 DeepSeek，见 [03-vscode-deepseek-cline](./03-vscode-deepseek-cline.md)。如果你用的是 OpenAI 的 Codex 而非 Claude Code，见 [05-codex-deepseek](./05-codex-deepseek.md)。
>
> **AI 编程工具系列文章：**
> | 编号 | 文章 | 一句话说明 |
> |------|------|-----------|
> | 01 | [安装 Claude Code](./01-claude-code-install.md) | 安装 Claude Code + 代理配置 |
> | **02** | **本文** | **用 DeepSeek 模型跑 Claude Code 工具链** |
> | 03 | [VS Code 中用 DeepSeek 处理文件](./03-vscode-deepseek-cline.md) | Claude Code 方案 vs Cline 插件方案 |
> | 04 | [Python 调用 AI API 入门](./04-python-ai-api-basics.md) | 用代码调用各家 AI 模型 |
> | 05 | [Codex 接入 DeepSeek](./05-codex-deepseek.md) | OpenAI Codex 接入 DeepSeek + 多模型切换 |
>
> **延伸阅读**：想了解这些配置方法是怎么找到的？如何在 GitHub 上高效搜索开源项目和配置？看 [GitHub 搜索技巧指南](../open-source/01-github-search-guide.md)。

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

## 模型切换：DeepSeek ↔ Claude 官方 ↔ 其他模型

接入 DeepSeek 后，你可能还想切回 Claude 官方模型（比如处理复杂架构问题），或者试用其他模型。Claude Code 的切换本质上就是**改环境变量**，有以下几种方式：

### 方法一：手动改环境变量（最直接）

Claude Code 的模型路由只由两个环境变量决定：`ANTHROPIC_BASE_URL` 和 `ANTHROPIC_AUTH_TOKEN`。切换模型就是改这两个值。

**切回 Claude 官方模型：**

```powershell
# 删除 DeepSeek 相关的环境变量，让 Claude Code 回到默认行为
Remove-Item Env:ANTHROPIC_BASE_URL
Remove-Item Env:ANTHROPIC_MODEL
Remove-Item Env:ANTHROPIC_AUTH_TOKEN
# 如果你有 Claude Pro 订阅，直接启动即可（用订阅登录）
claude
```

或者用 Anthropic API Key：

```powershell
$env:ANTHROPIC_API_KEY = "sk-ant-你的Anthropic Key"
# 不设 ANTHROPIC_BASE_URL，默认就走 Anthropic 官方
claude
```

**切到 DeepSeek：**

```powershell
$env:ANTHROPIC_BASE_URL = "https://api.deepseek.com/anthropic"
$env:ANTHROPIC_AUTH_TOKEN = "sk-你的DeepSeek Key"
$env:ANTHROPIC_MODEL = "deepseek-v4-pro[1m]"
claude
```

> ⚠️ 每次切换后需要**退出再重新启动** `claude`，环境变量在运行中途改不生效。

### 方法二：Shell 别名一键切换（推荐日常使用）

在 PowerShell 配置文件里定义函数，以后输入一个命令就完成切换：

```powershell
# 编辑 PowerShell 配置文件
notepad $PROFILE
```

添加以下内容：

```powershell
function Use-DeepSeek {
    $env:ANTHROPIC_BASE_URL = "https://api.deepseek.com/anthropic"
    $env:ANTHROPIC_AUTH_TOKEN = "sk-你的DeepSeek Key"
    $env:ANTHROPIC_MODEL = "deepseek-v4-pro[1m]"
    $env:ANTHROPIC_DEFAULT_OPUS_MODEL = "deepseek-v4-pro[1m]"
    $env:ANTHROPIC_DEFAULT_SONNET_MODEL = "deepseek-v4-pro[1m]"
    $env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "deepseek-v4-flash"
    $env:CLAUDE_CODE_SUBAGENT_MODEL = "deepseek-v4-flash"
    $env:CLAUDE_CODE_EFFORT_LEVEL = "max"
    Write-Host "已切换到 DeepSeek V4 Pro" -ForegroundColor Green
}

function Use-Claude {
    Remove-Item Env:ANTHROPIC_BASE_URL -ErrorAction SilentlyContinue
    Remove-Item Env:ANTHROPIC_MODEL -ErrorAction SilentlyContinue
    Remove-Item Env:ANTHROPIC_AUTH_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:ANTHROPIC_DEFAULT_OPUS_MODEL -ErrorAction SilentlyContinue
    Remove-Item Env:ANTHROPIC_DEFAULT_SONNET_MODEL -ErrorAction SilentlyContinue
    Remove-Item Env:ANTHROPIC_DEFAULT_HAIKU_MODEL -ErrorAction SilentlyContinue
    Remove-Item Env:CLAUDE_CODE_SUBAGENT_MODEL -ErrorAction SilentlyContinue
    Remove-Item Env:CLAUDE_CODE_EFFORT_LEVEL -ErrorAction SilentlyContinue
    Write-Host "已切换到 Claude 官方模型（需要 Pro 订阅或 API Key）" -ForegroundColor Cyan
}
```

保存后重新打开 PowerShell，使用方式：

```powershell
Use-DeepSeek    # 切到 DeepSeek
claude          # 启动

# 或者
Use-Claude      # 切回 Claude 官方
claude          # 启动
```

Mac / Linux 用户在 `~/.zshrc` 或 `~/.bashrc` 中用 `alias` 实现同样效果：

```bash
alias use-deepseek='export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic" && export ANTHROPIC_AUTH_TOKEN="sk-你的Key" && export ANTHROPIC_MODEL="deepseek-v4-pro[1m]" && echo "已切换到 DeepSeek"'
alias use-claude='unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL && echo "已切换到 Claude 官方"'
```

### 方法三：CC Switch 图形界面（不想碰命令行）

[CC Switch](https://github.com/farion1231/cc-switch) 是一个开源的桌面 GUI 工具，可以可视化管理多个 provider，点一下就切换。

**安装：**

- Windows：从 [GitHub Releases](https://github.com/farion1231/cc-switch/releases) 下载 `.msi` 安装包
- Mac：`brew install --cask cc-switch`
- Linux：下载 `.deb` / `.rpm` / `.AppImage`

**使用：**

1. 打开 CC Switch，点 **+ Add Provider**
2. 填入 Provider 名称（如 `DeepSeek`）、API Key、Request URL（`https://api.deepseek.com/anthropic`）
3. 再添加一个 `Claude Official`（不填 Request URL，使用默认）
4. 在列表中点击想用的 provider，点 **Use** 即可

CC Switch 会自动写入 `~/.claude/settings.json`，下次启动 `claude` 时生效，不需要手动改环境变量。

### 方法四：修改 .claude/settings.json（项目级配置）

如果你想**某个项目用 DeepSeek、另一个项目用 Claude 官方**，可以在项目根目录创建 `.claude/settings.json`：

DeepSeek 项目的 `.claude/settings.json`：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "sk-你的DeepSeek Key",
    "ANTHROPIC_MODEL": "deepseek-v4-pro[1m]"
  }
}
```

Claude 官方的项目不需要这个文件，或者留一个空配置：

```json
{
  "env": {}
}
```

这样在不同项目目录下启动 `claude`，会自动使用对应的模型。

### 切换速查表

| 我要... | 操作 |
|--------|------|
| DeepSeek → Claude 官方 | 删掉 `ANTHROPIC_BASE_URL` 等环境变量，重启 `claude` |
| Claude 官方 → DeepSeek | 设置 `ANTHROPIC_BASE_URL` 和 `ANTHROPIC_AUTH_TOKEN`，重启 `claude` |
| 频繁切换 | 用 Shell 别名（方法二）或 CC Switch（方法三） |
| 不同项目用不同模型 | 项目目录下放 `.claude/settings.json`（方法四） |
| 确认当前用的是哪个模型 | 进入 claude 后输入 `/status` |

### 什么时候该切回 Claude 官方

| 场景 | 推荐 |
|------|------|
| 日常编码、文件处理、简单重构 | DeepSeek V4 Pro（便宜 5 倍+） |
| 复杂多文件架构设计 | Claude Opus / Sonnet（推理更强） |
| 需要图片输入（截图分析 UI） | Claude 官方（DeepSeek 的 Anthropic 接口不支持图片） |
| 需要 extended thinking 深度推理 | Claude 官方（DeepSeek 不支持） |
| 对安全性要求高的代码审查 | Claude 官方（不能有漏报） |

---

## 已知限制

- **不支持图片输入**：当前 DeepSeek V4 的 Anthropic 兼容接口暂不支持传入图片，所以 Claude Code 中涉及截图分析的功能无法使用。
- **响应速度**：开启 max effort 思考模式后，复杂问题的首次响应可能需要较长时间（30 秒以上），这是模型在进行深度推理。
- **复杂推理场景**：在极端复杂的编码和前沿推理任务上，V4-Pro 与 Claude Opus 4.6 仍有差距，可能需要多次调教。

---

## 总结

整个配置过程不超过 5 分钟：安装 Claude Code → 获取 DeepSeek API Key → 设置环境变量 → 验证。核心原理就是一个 URL 重定向——把请求从 Anthropic 转发到 DeepSeek，后者提供了完全兼容的 API 接口，所以 Claude Code 的所有功能（工具调用、多步任务、代码执行）都能正常工作。

一次配置，长期受益。
