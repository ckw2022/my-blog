# Codex 接入 DeepSeek V4 Pro 指南

> Codex 是 OpenAI 的编程 Agent，工具链强大但官方模型价格高。本文手把手教你接入 DeepSeek V4 Pro，成本降低 90%+，上下文窗口扩展到 1M token。

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
