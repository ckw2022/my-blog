# VS Code 接入 DeepSeek V4 Pro 文件处理指南

> 目标：在 VS Code 里用 DeepSeek V4 Pro 读写文件、改代码、执行终端命令，效果与 Claude Code 一致。
> 提供两种方案，按需选择。

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

### 原理

把 Claude Code 的 API 请求重定向到 DeepSeek 服务器。工具链完全是 Claude Code 那套（文件读写、终端操作、多步任务），模型换成 DeepSeek V4 Pro。

### 前置条件

- Node.js 18+（`node --version` 验证）
- DeepSeek API Key（[platform.deepseek.com](https://platform.deepseek.com/api_keys)）

### 第一步：安装 Claude Code CLI

```powershell
npm install -g @anthropic-ai/claude-code
claude --version   # 看到版本号说明成功
```

### 第二步：安装 VS Code 插件

1. 按 `Ctrl+Shift+X` 打开扩展商店
2. 搜索 **Claude Code**，找到发布者是 **Anthropic** 的
3. 点 **Install**

### 第三步：配置 DeepSeek 环境变量

**每次使用前在 VS Code 终端运行（临时生效）：**

```powershell
$env:ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
$env:ANTHROPIC_AUTH_TOKEN="sk-你的DeepSeek API Key"
$env:ANTHROPIC_MODEL="deepseek-v4-pro[1m]"
$env:ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]"
$env:ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]"
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
$env:CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
$env:CLAUDE_CODE_EFFORT_LEVEL="max"
```

**永久生效（推荐）**：在项目根目录创建 `.claude/settings.json`：

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "sk-你的DeepSeek API Key",
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

### 第四步：启动

```powershell
claude
```

验证：输入 `/status`，显示 `deepseek-v4-pro[1m]` 则接入成功。

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
