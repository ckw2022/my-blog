# Codex 接入 DeepSeek V4 Pro 指南

> Codex 是 OpenAI 的编程 Agent，工具链强大但官方模型价格高。本文手把手教你接入 DeepSeek V4 Pro，成本降低 90%+，上下文窗口扩展到 1M token。

> **本文定位**：针对 OpenAI Codex 的完整配置指南，包括 CLI / IDE 扩展 / 桌面应用三种方式，以及通过 OpenRouter 接入 Claude、Gemini 等其他模型。如果你用的是 Anthropic 的 Claude Code（不是 Codex），见 [02-claude-code-deepseek](./02-claude-code-deepseek.md)。
>
> **Codex vs Claude Code**：两者都是 AI 编程 Agent，但来自不同公司（OpenAI vs Anthropic），使用不同的 API 协议。Codex 接入 DeepSeek 需要 Moon Bridge 做协议转换，而 Claude Code 只需改环境变量。
>
> **AI 编程工具系列文章：**
> | 编号 | 文章 | 一句话说明 |
> |------|------|-----------|
> | 01 | [安装 Claude Code](./01-claude-code-install.md) | 安装 Claude Code + 代理配置 |
> | 02 | [Claude Code 接入 DeepSeek](./02-claude-code-deepseek.md) | 用 DeepSeek 模型跑 Claude Code 工具链 |
> | 03 | [VS Code 中用 DeepSeek 处理文件](./03-vscode-deepseek-cline.md) | Claude Code 方案 vs Cline 插件方案 |
> | 04 | [Python 调用 AI API 入门](./04-python-ai-api-basics.md) | 用代码调用各家 AI 模型 |
> | **05** | **本文** | **OpenAI Codex 接入 DeepSeek + 多模型切换** |
>
> **延伸阅读**：想在 GitHub 上找更多配置方案和开源项目？看 [GitHub 搜索技巧指南](../open-source/01-github-search-guide.md)。

### Codex 的三种使用方式

Codex 不只能在终端里用，目前有三种入口：

| 方式 | 说明 | 适合场景 |
|------|------|---------|
| **CLI（命令行）** | 终端 TUI 界面，本文主要讲的方式 | 自动化、脚本化、轻量使用 |
| **IDE 扩展** | VS Code / Cursor / JetBrains 内直接使用 | 日常开发，边写代码边用 |
| **桌面应用（Codex App）** | 独立 GUI 客户端，Microsoft Store 可下载 | 多项目并行、可视化审查 |

三种方式**都可以接入 DeepSeek**，核心都是通过 Moon Bridge 做协议转换。本文先讲 CLI 方式（第一步到第六步），然后在后面补充 IDE 扩展和桌面应用的配置方法。

---

## 为什么需要中间层？

Claude Code 接入 DeepSeek 只需改一个环境变量，因为 DeepSeek 原生兼容 Anthropic API 协议。

但 **Codex 不同**：Codex 使用 OpenAI 的 **Responses API**，而 DeepSeek 只提供 **Chat Completions API**，两者协议不兼容，需要一个中间转换层。

```
Codex → Responses API → Moon Bridge（转换层）→ Chat Completions API → DeepSeek V4 Pro
```

中间层使用 **Moon Bridge**（DeepSeek 官方推荐）。

---

## 前置条件

| 条件 | 要求 | 检查命令 |
|------|------|---------|
| Node.js | 18+ | `node --version` |
| Go | 1.25+ | `go version` |
| DeepSeek API Key | 需充值余额 | — |
| Git | 任意版本 | `git --version` |

**安装 Node.js**：前往 [nodejs.org](https://nodejs.org) 下载 LTS 版本，安装时勾选 **Add to PATH**。

**安装 Go**：

1. 打开 [go.dev/dl](https://go.dev/dl/)
2. 下载 **`go1.26.4.windows-amd64.msi`**（Installer，Windows x86-64，59MB，页面 Stable versions 中加粗显示的那行）
3. 双击安装，默认路径为 `C:\Program Files\Go`，无需修改，一路 Next 即可
4. 安装完成后，**必须关闭当前 PowerShell，重新打开一个新窗口**，否则 PATH 不生效

验证 Go 安装（新窗口中运行）：

```powershell
go version
# 正确输出：go version go1.26.4 windows/amd64
```

> ⚠️ 常见问题：安装 Go 后在原终端运行 `go version` 报错 `无法将"go"项识别为 cmdlet、函数、脚本文件或可运行程序的名称`，这不是安装失败，而是终端没有加载新的 PATH。**关掉重开 PowerShell 即可解决**。

---

## 第一步：安装 Codex CLI

打开一个新 PowerShell 窗口，运行：

```powershell
npm install -g @openai/codex
```

说明：`npm install` 是 Node.js 的包管理器安装命令，`-g` 表示全局安装（安装后在任意目录都能使用 `codex` 命令），`@openai/codex` 是 OpenAI 官方发布的包名。

验证安装：

```powershell
codex --version
go version
```

`codex --version` 显示 `codex-cli 0.x.x`，`go version` 显示 `go version go1.26.4 windows/amd64`，两个都有版本号则说明环境就绪。

---

## 第二步：获取 DeepSeek API Key

1. 打开 [platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys)
2. 注册并登录（手机号）
3. 点击 **创建 API Key**，复制保存
4. 充值少量余额（几块钱够测试）

---

## 第三步：安装并配置 Moon Bridge

### 3.1 克隆 Moon Bridge

`git clone` 会把仓库下载到**当前终端所在目录**。建议先切换到你想存放的位置，例如 `E:\git download`：

```powershell
cd "E:\git download"
git clone https://github.com/ZhiYi-R/moon-bridge.git
cd moon-bridge
```

说明：`cd` 切换当前工作目录（路径有空格必须加引号）；`git clone` 从 GitHub 下载整个仓库，完成后在当前目录创建 `moon-bridge` 文件夹；最后 `cd moon-bridge` 进入该文件夹，**后续第四、五步的命令都必须在这个目录里运行**。

### 3.2 创建配置文件

在 `moon-bridge` 目录下新建 `config.yml`，填入你的 DeepSeek API Key：

```yaml
mode: "Transform"

server:
  addr: "127.0.0.1:38440"

providers:
  deepseek:
    base_url: "https://api.deepseek.com/anthropic"
    api_key: "sk-你的DeepSeek API Key"   # ← 换成你的 Key

routes:
  moonbridge:
    to: "deepseek/deepseek-v4-pro"
```

**配置说明：**

| 字段 | 含义 |
|------|------|
| `server.addr` | Moon Bridge 本地监听地址，默认 38440 端口 |
| `base_url` | DeepSeek 兼容 Anthropic 协议的端点 |
| `api_key` | 你的 DeepSeek API Key |

> ⚠️ 注意：顶层字段必须是 `providers`（不是 `provider`），且不支持 `models`、`default_model` 等子字段，否则启动报错：`field provider not found` / `field models not found`。

---

## 第四步：启动 Moon Bridge

**继续使用第三步的终端**（当前目录应在 `moon-bridge` 文件夹内）。

首次运行前，先设置国内代理，否则下载依赖会因被墙而失败：

```powershell
go env -w GOPROXY=https://goproxy.cn,direct
```

说明：`go env -w` 写入 Go 的全局配置（永久生效）；`GOPROXY` 是 Go 下载依赖时走的代理地址；`goproxy.cn` 是国内镜像，替代被墙的 `proxy.golang.org`；`direct` 表示镜像找不到时直接连原始地址。

然后启动 Moon Bridge，**保持这个终端开着，不要关闭**：

```powershell
go run ./cmd/moonbridge --config config.yml
```

说明：`go run` 编译并运行 Go 程序；`./cmd/moonbridge` 是当前目录下的程序入口文件夹；`--config config.yml` 指定刚才创建的配置文件。

然后重新运行启动命令，等待依赖下载完成。启动成功后终端显示：

```
Moon Bridge 监听于 127.0.0.1:38440
HTTP 服务器监听中 addr=127.0.0.1:38440
```

说明 Moon Bridge 已正常运行，**保持此终端不要关闭**。

---

## 第五步：生成 Codex 配置

**新开一个 PowerShell 窗口**，`cd` 到 `moon-bridge` 目录（第四步的终端保持开着不动），运行以下命令：

```powershell
$CODEX_HOME_DIR = "$env:USERPROFILE\.codex"
New-Item -ItemType Directory -Force -Path $CODEX_HOME_DIR
$MODEL = go run ./cmd/moonbridge --config config.yml --print-codex-model
go run ./cmd/moonbridge --config config.yml --print-codex-config $MODEL --codex-base-url "http://127.0.0.1:38440/v1" --codex-home $CODEX_HOME_DIR | Out-File -Encoding utf8 "$CODEX_HOME_DIR\config.toml"
```

各行说明：

- `$CODEX_HOME_DIR = "$env:USERPROFILE\.codex"`：定义变量，值为 `C:\Users\你的用户名\.codex`（配置文件存放位置）
- `New-Item -ItemType Directory -Force`：创建 `.codex` 文件夹，`-Force` 表示已存在则跳过不报错
- `--print-codex-model`：让 Moon Bridge 输出当前配置的模型名，存入 `$MODEL` 变量
- `--print-codex-config $MODEL`：根据模型名生成 Codex 配置内容
- `--codex-base-url`：告诉 Codex 把请求发到本机的 Moon Bridge（`127.0.0.1:38440`）
- `| Out-File -Encoding utf8`：把输出写入文件，**必须加 `-Encoding utf8`**，否则文件编码有误，启动 Codex 时报错 `invalid utf-8 sequence`

这一步自动生成两个文件：
- `C:\Users\你的用户名\.codex\config.toml`：Codex 的 provider 配置
- `C:\Users\你的用户名\.codex\models_catalog.json`：模型能力描述

---

## 第六步：启动 Codex

**继续使用第五步的终端**（已在 `moon-bridge` 目录），运行：

```powershell
$env:CODEX_HOME = "$env:USERPROFILE\.codex"
codex
```

说明：`$env:CODEX_HOME` 告诉 Codex 去哪里找配置文件（第五步生成的 `config.toml`）；不设置这个变量，Codex 找不到 Moon Bridge 配置，会尝试连接 OpenAI 官方服务器。

> ⚠️ 不需要 `cd C:\你的项目路径`，那只是示例。Codex 会在当前目录下工作，想操作哪个文件夹就先 `cd` 过去再启动。

启动后出现选择沙箱的界面，选 **2（Use non-admin sandbox）** 回车，不需要管理员权限。

看到以下界面说明启动成功：

```
Sandbox ready
Codex can now safely edit files and execute commands in your computer
moonbridge default · 当前目录路径
```

在输入框直接用中文描述任务即可，Codex 会通过 Moon Bridge 调用 DeepSeek V4 Pro 来执行。

**每次使用的固定流程：**

1. 终端 A：`cd` 到 `moon-bridge` 目录 → 运行 `go run ./cmd/moonbridge --config config.yml`（保持开着）
2. 终端 B：`cd` 到你的工作目录 → 运行 `$env:CODEX_HOME = "$env:USERPROFILE\.codex"` → 运行 `codex`

---

## 一键启动脚本（推荐）

配置好之后，每次使用都需要手动开两个终端、分别执行命令。可以用脚本把这些步骤合并，双击即启动。

### 脚本文件

已生成脚本 `启动Codex.ps1`，保存在 `C:\Users\Y\Desktop\文献\启动Codex.ps1`。

**使用前先修改脚本里的两个路径**，用记事本或 VS Code 打开 `启动Codex.ps1`，找到开头两行改成你自己的实际路径：

```powershell
$MOONBRIDGE_DIR = "E:\git download\moon-bridge"   # moon-bridge 文件夹的位置
$WORK_DIR       = "C:\Users\Y\Desktop\文献"        # 你想让 Codex 操作的目录
```

### 如何运行

直接双击 `启动Codex.ps1` 可能被系统拦截（执行策略限制）。推荐方式：

1. 在文件上**右键 → 用 PowerShell 运行**
2. 或在 PowerShell 里执行：

```powershell
& "C:\Users\Y\Desktop\文献\启动Codex.ps1"
```

### 脚本做了什么

1. 自动开一个新窗口，`cd` 到 `moon-bridge` 目录并启动 Moon Bridge（保持运行）
2. 等待 5 秒让 Moon Bridge 初始化完成
3. 再开一个新窗口，`cd` 到你的工作目录并启动 Codex

两个窗口都弹出后，在 Codex 窗口里操作即可。

---

## 方式二：IDE 扩展（VS Code / JetBrains）

如果你更习惯在编辑器里工作，可以用 Codex 的 IDE 扩展，在编辑器侧边栏直接和 Codex 对话，同时看代码、改代码。

### 安装扩展

**VS Code / Cursor / Windsurf：**

在扩展商店搜索 `Codex`（发布者为 OpenAI），或直接访问 [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=openai.chatgpt) 安装。安装后重启编辑器，Codex 会出现在右侧边栏。

**JetBrains（IntelliJ / PyCharm / WebStorm / Rider 等）：**

前往 [JetBrains 官方 Codex 集成页面](https://blog.jetbrains.com/ai/2026/01/codex-in-jetbrains-ides/) 安装插件。支持 ChatGPT 账号、API Key 或 JetBrains AI 订阅登录。

### 接入 DeepSeek

IDE 扩展默认走 OpenAI 官方 API。要接入 DeepSeek，**仍然需要 Moon Bridge**（本文第三、四步），因为协议不兼容的问题在 IDE 扩展中同样存在。

配置流程：

1. 按照本文第三、四步安装并启动 Moon Bridge（保持终端开着）
2. 按照第五步生成 Codex 配置文件（`config.toml` 和 `models_catalog.json`）
3. 打开 IDE，在 Codex 扩展的设置中将 API 端点指向 Moon Bridge 的本地地址 `http://127.0.0.1:38440/v1`

### 三种模式

IDE 扩展内可以切换使用模式：

| 模式 | 说明 |
|------|------|
| **Chat** | 纯聊天，不会自动改文件，适合先讨论方案再动手 |
| **Agent** | 自动读写当前项目文件，执行命令需要你确认 |
| **Agent (Full Access)** | 完全自主，读写文件、执行命令都不需要确认 |

### 优势

相比 CLI，IDE 扩展的优势在于：可以直接看到当前打开的文件作为上下文，用 `@file` 引用项目中的其他文件，改动直接在编辑器里预览，不需要在终端和编辑器之间来回切换。

---

## 方式三：Codex 桌面应用

Codex 桌面应用是独立的 GUI 客户端，2026 年 3 月发布了 Windows 版，功能比 CLI 更丰富。

### 安装

**方法一：Microsoft Store**

在 Microsoft Store 搜索 `Codex` 下载，免费安装。

**方法二：命令行安装**

```powershell
winget install Codex -s msstore
```

### 登录

安装后用 ChatGPT 账号登录。ChatGPT Plus、Pro、Business、Edu、Enterprise 计划均包含 Codex 使用额度。

### 接入 DeepSeek

与 CLI 和 IDE 扩展一样，桌面应用默认走 OpenAI 官方 API，接入 DeepSeek **同样需要 Moon Bridge**。

配置流程与 CLI 相同：

1. 按照本文第三、四步安装并启动 Moon Bridge
2. 按照第五步生成 Codex 配置文件
3. 桌面应用会自动读取 `C:\Users\你的用户名\.codex\config.toml`，如果第五步已经正确生成，直接打开应用即可

> ⚠️ 确保启动桌面应用前 Moon Bridge 已经在运行，否则 Codex 无法连接到 DeepSeek。

### 桌面应用独有功能

| 功能 | 说明 |
|------|------|
| **并行工作区（Worktrees）** | 同时开多个项目，每个项目独立运行 Agent |
| **可视化代码审查（Review）** | 像 PR 审查一样查看 Agent 的改动 |
| **内置浏览器** | 不用切出去就能预览网页效果 |
| **Computer Use** | 让 Agent 看到屏幕并操作 GUI |
| **自动化（Automations）** | 设定触发条件，自动执行任务 |

### 沙箱设置

桌面应用支持原生 Windows 沙箱（PowerShell 环境）和 WSL2 Linux 沙箱。启动时选择 **Default permissions** 可以限制 Agent 只在项目目录内操作，防止误删文件。

### 集成终端

桌面应用内置终端，支持 PowerShell、命令提示符、Git Bash、WSL，在设置中切换即可。

---

## 三种方式对比

| 对比项 | CLI | IDE 扩展 | 桌面应用 |
|--------|-----|---------|---------|
| 安装方式 | `npm install -g @openai/codex` | 编辑器扩展商店 | Microsoft Store |
| 界面 | 终端 TUI | 编辑器侧边栏 | 独立 GUI 窗口 |
| 接入 DeepSeek | 需要 Moon Bridge | 需要 Moon Bridge | 需要 Moon Bridge |
| 多项目并行 | 需开多个终端 | 每个编辑器窗口一个 | 原生支持 Worktrees |
| 代码审查 | 无 | 编辑器内 diff | 内置 Review 面板 |
| 适合人群 | 习惯终端的开发者 | 日常写代码的开发者 | 需要管理多项目的开发者 |

---

## 验证是否接入成功

在任意新开的 PowerShell 窗口运行（Moon Bridge 那个终端需保持开着）。

**检查可用模型：**

```powershell
curl http://127.0.0.1:38440/v1/models
```

返回 `StatusCode: 200` 且内容包含 `deepseek-v4-pro` 说明 Moon Bridge 正常运行。

**发送测试请求：**

PowerShell 内置的 `curl` 不支持 `-H` 参数，需改用 `Invoke-RestMethod`：

```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:38440/v1/responses" `
  -Method Post `
  -ContentType "application/json" `
  -Body '{"model":"moonbridge","input":"用一句话介绍 DeepSeek V4 Pro","max_output_tokens":100}'
```

收到 AI 回复内容，说明整个链路（Codex → Moon Bridge → DeepSeek）接入成功。

> 验证步骤为可选，Codex 界面能正常对话即说明接入成功，不需要每次都做。

---

## 接入其他模型

除了 DeepSeek，Codex 还可以接入 GPT、Claude、Gemini 等模型。根据模型不同，接入难度也不同。

### 一、接入 GPT（原生支持，最简单）

Codex 是 OpenAI 的产品，原生支持 GPT，**不需要 Moon Bridge**，直接设置 OpenAI API Key 即可。

**前置条件：**

- OpenAI 账号（需海外手机号注册：[platform.openai.com](https://platform.openai.com)）
- 账户有余额（无免费额度，需充值）
- 国内访问需要代理

**CLI 配置：**

临时生效（当前终端有效）：

```powershell
$env:OPENAI_API_KEY = "sk-你的OpenAI API Key"
codex
```

永久生效（写入系统环境变量，之后每次直接运行 `codex` 即可）：

```powershell
[System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "sk-你的Key", "User")
```

说明：`SetEnvironmentVariable` 的第三个参数 `"User"` 表示只对当前用户生效，不影响其他用户。设置后**重新打开 PowerShell** 才能生效。

启动时不需要开 Moon Bridge，直接运行：

```powershell
codex
```

**IDE 扩展配置：**

安装 Codex 扩展后，用 ChatGPT 账号或 OpenAI API Key 登录即可，默认就走 GPT，无需额外配置。

**桌面应用配置：**

同上，登录 ChatGPT 账号即可直接使用 GPT 模型。

### 二、通过 OpenRouter 接入任意模型（推荐）

[OpenRouter](https://openrouter.ai/) 是一个模型聚合平台，**一个 API Key 可以调用 Claude、Gemini、Llama、GPT 等几百个模型**，按用量计费。对于想在 Codex 中试用不同模型的人来说，这是最方便的方式。

**注册和获取 Key：**

1. 打开 [openrouter.ai](https://openrouter.ai/)，注册账号
2. 进入 [openrouter.ai/keys](https://openrouter.ai/keys) 创建 API Key
3. 充值余额（支持多种支付方式）

**配置 config.toml：**

打开或新建 `C:\Users\你的用户名\.codex\config.toml`，写入以下内容：

```toml
model = "anthropic/claude-sonnet-4"    # 想用哪个模型就改这里
model_provider = "openrouter"

[model_providers.openrouter]
name = "OpenRouter"
base_url = "https://openrouter.ai/api/v1"
env_key = "OPENROUTER_API_KEY"
```

**设置环境变量：**

```powershell
$env:OPENROUTER_API_KEY = "sk-or-你的OpenRouter Key"
codex
```

永久生效：

```powershell
[System.Environment]::SetEnvironmentVariable("OPENROUTER_API_KEY", "sk-or-你的Key", "User")
```

**常用模型 ID：**

| 模型 | OpenRouter 模型 ID | 说明 |
|------|-------------------|------|
| Claude Sonnet 4 | `anthropic/claude-sonnet-4` | Anthropic 的编程强模型 |
| Claude Haiku 4.5 | `anthropic/claude-haiku-4.5` | 便宜快速 |
| Gemini 2.5 Flash | `google/gemini-2.5-flash` | Google 的快速模型 |
| Gemini 2.5 Pro | `google/gemini-2.5-pro` | Google 的旗舰模型 |
| GPT-4o | `openai/gpt-4o` | OpenAI 旗舰 |
| Llama 4 Maverick | `meta-llama/llama-4-maverick` | Meta 开源模型 |

完整模型列表见 [openrouter.ai/models](https://openrouter.ai/models)。切换模型只需改 `config.toml` 里的 `model` 值。

> ⚠️ **重要**：OpenRouter 不需要 Moon Bridge。OpenRouter 自身支持 Responses API，Codex 可以直接对接。

### 三、通过 config.toml 自定义 Provider

如果你有其他 API 服务（比如 Azure OpenAI、公司内部网关、本地模型等），也可以手动配置 provider。

**基本格式：**

```toml
model = "你的模型名"
model_provider = "自定义名称"

[model_providers.自定义名称]
name = "显示名称"
base_url = "https://你的API地址/v1"
env_key = "你的环境变量名"
```

**配置说明：**

| 字段 | 含义 |
|------|------|
| `model` | 模型 ID，由 API 提供方决定 |
| `model_provider` | 对应下方 `[model_providers.xxx]` 的名称 |
| `base_url` | API 端点地址 |
| `env_key` | 存放 API Key 的环境变量名 |

> ⚠️ **协议要求**：Codex 目前只支持 **Responses API** 协议（`wire_api = "responses"`，这是默认值可以不写）。2025 年之前的旧教程可能写 `wire_api = "chat"`，这个已经不支持了。如果你的 API 提供方只支持 Chat Completions API，就需要 Moon Bridge 或 LiteLLM 等中间层做协议转换（和接入 DeepSeek 一样的原理）。

### 模型价格对比

| 模型 | 价格（每百万 token 输出）| 上下文 | 国内直连 | 需要中间层 |
|------|------------------------|--------|---------|-----------|
| GPT-4o | ~$15 | 128K | ❌ 需代理 | 不需要 |
| GPT-4o mini | ~$0.6 | 128K | ❌ 需代理 | 不需要 |
| Claude Sonnet 4 | ~$15 | 200K | ❌ 需代理 | 通过 OpenRouter 不需要 |
| Gemini 2.5 Flash | 免费额度 / ~$0.6 | 1M | ❌ 需代理 | 通过 OpenRouter 不需要 |
| DeepSeek V4 Pro | ~$3.48 | 1M | ✅ 能 | 需要 Moon Bridge |
| DeepSeek V4 Flash | ~$0.28 | 1M | ✅ 能 | 需要 Moon Bridge |

---

## 模型切换

### 方法一：改 config.toml（通用，推荐）

`config.toml` 是 Codex 的核心配置文件，位于 `C:\Users\你的用户名\.codex\config.toml`。**三种使用方式（CLI、IDE 扩展、桌面应用）都会读取这个文件。**

切换模型只需改两个值：

```toml
model = "想用的模型ID"
model_provider = "对应的provider名称"
```

改完后**重启 Codex**（退出再打开）即可生效。

**示例：从 DeepSeek 切到 OpenRouter 上的 Claude**

把 `config.toml` 从：

```toml
# Moon Bridge + DeepSeek 的配置
model = "moonbridge"
model_provider = "moonbridge"

[model_providers.moonbridge]
name = "Moon Bridge"
base_url = "http://127.0.0.1:38440/v1"
env_key = "MOONBRIDGE_API_KEY"
```

改为：

```toml
# OpenRouter + Claude 的配置
model = "anthropic/claude-sonnet-4"
model_provider = "openrouter"

[model_providers.openrouter]
name = "OpenRouter"
base_url = "https://openrouter.ai/api/v1"
env_key = "OPENROUTER_API_KEY"
```

> 💡 可以在 config.toml 里同时保留多个 `[model_providers.xxx]` 段，切换时只需改顶部的 `model` 和 `model_provider` 即可，不用反复写 provider 配置。

**同时保留多个 provider 的完整示例：**

```toml
# ===== 当前使用的模型（改这两行即可切换）=====
model = "anthropic/claude-sonnet-4"
model_provider = "openrouter"

# ===== Provider 定义（可以全部保留）=====

# OpenRouter：一个 Key 用所有模型
[model_providers.openrouter]
name = "OpenRouter"
base_url = "https://openrouter.ai/api/v1"
env_key = "OPENROUTER_API_KEY"

# Moon Bridge：用于 DeepSeek
[model_providers.moonbridge]
name = "Moon Bridge"
base_url = "http://127.0.0.1:38440/v1"
env_key = "MOONBRIDGE_API_KEY"
```

切换到 DeepSeek 时，只需把前两行改为：

```toml
model = "moonbridge"
model_provider = "moonbridge"
```

切换到 GPT 时，删除或注释掉 `model` 和 `model_provider` 行，Codex 默认走 OpenAI 官方（需设置 `OPENAI_API_KEY` 环境变量）。

### 方法二：CLI 内用 /model 命令

在 CLI 中输入：

```
/model
```

会弹出当前可用的模型列表，用方向键选择，回车确认。这种方式只在当前会话生效，退出后恢复为 config.toml 的配置。

### 方法三：IDE 扩展内切换

在 VS Code 的 Codex 侧边栏中，点击模型名称或使用模型选择器，可以在可用模型间切换。如果配置了自定义 provider，自定义模型也会出现在列表中。

### 方法四：桌面应用内切换

在桌面应用的设置中可以选择模型。和 IDE 扩展一样，config.toml 中定义的自定义 provider 模型也会出现。

### 切换时 Moon Bridge 的处理

| 切换方向 | Moon Bridge | 操作 |
|---------|-------------|------|
| 任意 → DeepSeek | 需要运行 | 先启动 Moon Bridge，再启动 Codex |
| DeepSeek → GPT / OpenRouter / 其他 | 不需要 | 可以关掉 Moon Bridge 那个终端 |
| DeepSeek → GPT（直连） | 不需要 | 删掉 config.toml 的 model/model_provider，设好 OPENAI_API_KEY |

### 各模型适用场景

| 场景 | 推荐 | 理由 |
|------|------|------|
| 日常代码编写、文件处理 | DeepSeek V4 Pro | 便宜、1M 上下文、国内直连 |
| 需要 OpenAI 生态插件支持 | GPT-4o | Codex 原生支持，兼容性最好 |
| 成本敏感的简单任务 | DeepSeek V4 Flash | 最便宜 |
| 想试用多个模型对比效果 | OpenRouter | 一个 Key 切换所有模型 |
| 复杂推理和代码审查 | Claude Sonnet 4 | 编程能力强 |

---

## 与 Claude Code 接入方式对比

| 对比项 | Claude Code + DeepSeek | Codex + DeepSeek |
|--------|----------------------|-----------------|
| 接入难度 | 简单（改环境变量）| 中等（需要 Moon Bridge）|
| 原因 | DeepSeek 原生兼容 Anthropic API | Codex 用 Responses API，需转换 |
| 中间层 | 不需要 | 需要 Moon Bridge（Go 实现）|
| 配置步骤 | ~5 分钟 | ~15 分钟 |
| 上下文窗口 | 1M token | 1M token |

---

## 常见错误

| 错误 | 原因 | 解决方法 |
|------|------|---------|
| `go : 无法将"go"项识别...` | Go 安装后未重启终端，PATH 未生效 | 关闭当前 PowerShell，重新打开新窗口 |
| `dial tcp ... connection failed` | Go 下载依赖被墙 | 运行 `go env -w GOPROXY=https://goproxy.cn,direct` 后重试 |
| `field provider not found` | config.yml 顶层写成了 `provider` | 改为 `providers`（去掉外层嵌套） |
| `field models not found` | config.yml 包含不支持的 `models` 字段 | 删除 `models` 及其子字段，使用简化配置 |
| `invalid utf-8 sequence` | config.toml 编码错误 | 第五步加 `-Encoding utf8` 重新生成 |
| `connection refused` | Moon Bridge 没启动或端口不对 | 确认第四步终端仍在运行 |
| Codex 看不到模型 | `models_catalog.json` 未生成 | 重新执行第五步 |
| `401` 认证失败 | API Key 填错 | 检查 `config.yml` 中的 `api_key` |
| `402` 余额不足 | DeepSeek 账户没钱 | 去平台充值 |
| 图片输入失败 | V4 Pro 不支持图片 | 移除 `visual.enabled: true` 配置 |

---

## 总结

整体流程：安装环境 → 配置 Moon Bridge → 启动代理 → 生成 Codex 配置 → 启动 Codex。

核心原理：Moon Bridge 把 Codex 发出的 OpenAI Responses API 请求，实时转换为 DeepSeek 能理解的 Chat Completions API 格式，实现无缝对接。

---

*参考来源：[DeepSeek 官方 awesome-deepseek-agent](https://github.com/deepseek-ai/awesome-deepseek-agent/blob/main/docs/codex.md)*
