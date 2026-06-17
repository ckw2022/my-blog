---
title: "VS Code 安装 Claude Code 完整教程（含代理配置）"
date: 2026-06-16
draft: false
tags: ["Claude Code", "VS Code", "AI编程", "教程"]
categories: ["软件"]
math: false
summary: "手把手教你在 VS Code 中安装和配置 Claude Code AI编程助手，包括 Node.js 安装、代理设置、登录验证全流程。"
---

## Claude Code 是什么

Claude Code 是 Anthropic 公司开发的 AI 编程助手，安装到 VS Code 后可以直接在编辑器里跟 AI 对话，让它帮你写代码、解释代码、找Bug。

**它能做什么：**

| 场景 | 没有 Claude Code | 有 Claude Code |
|------|-----------------|---------------|
| 代码报错 | 复制错误去浏览器搜 | 直接问，秒回答 |
| 不会写某个功能 | 查文档找教程 | 告诉它你要什么，直接生成 |
| 看别人的代码 | 一行行啃 | 让它解释整个文件 |
| Debug | 加 print 排查 | 帮你分析定位问题 |

---

## 前提条件

| 条件 | 说明 |
|------|------|
| VS Code | 版本 1.98.0 以上 |
| Claude 账号 | 需要 Pro 订阅（$20/月） |
| 代理工具 | 国内网络需要（V2RayN、Clash 等） |

> ⚠️ 免费版 Claude 账号无法使用 Claude Code，必须订阅 Pro 或更高级别。

---

## 第一步：安装 Node.js

Claude Code 是基于 Node.js 的工具，需要先安装 Node.js 18 以上版本。

如果已经安装了 Scoop（包管理器），直接运行：

```powershell
scoop install nodejs
```

验证安装：

```powershell
node --version
```

看到 `v18.x.x` 或更高就没问题。

> 没有 Scoop 的话，也可以去 [nodejs.org](https://nodejs.org) 下载安装包手动安装。

---

## 第二步：安装 Claude Code CLI

CLI 是 Claude Code 的核心引擎，VS Code 插件依赖它运行。

```powershell
npm install -g @anthropic-ai/claude-code
```

`npm install -g` 的意思是全局安装一个 npm 包，`@anthropic-ai/claude-code` 是包名。

验证安装：

```powershell
claude --version
```

看到版本号就说明安装成功。

---

## 第三步：安装 VS Code 插件

1. 打开 VS Code
2. 按 `Ctrl+Shift+X` 打开扩展商店
3. 搜索 **Claude Code**
4. 找到发布者是 **Anthropic** 的那个（有 2M+ 安装量）
5. 点 **Install**

安装完后侧边栏会出现一个 ✨ 图标。

---

## 第四步：配置代理（国内必须）

国内直接连 Claude 服务器会被墙，需要配置代理。

### 4.1 确认代理端口

打开你的代理软件（V2RayN、Clash 等），找到本地监听端口：

| 软件 | 常见端口 |
|------|---------|
| V2RayN | 10808 |
| Clash | 7890 |
| Shadowsocks | 1080 |

以 V2RayN 为例，在软件左下角可以看到 `本地:[mixed:10808]`，端口就是 `10808`。

### 4.2 在 VS Code 设置里配置

1. 按 `Ctrl+,` 打开设置
2. 搜索 `proxy`
3. 在 **Http: Proxy** 输入框里填入：

```
http://127.0.0.1:10808
```

端口号换成你自己的。

### 4.3 在终端设置环境变量

每次打开 VS Code 终端时运行：

```powershell
$env:HTTP_PROXY = "http://127.0.0.1:10808"
$env:HTTPS_PROXY = "http://127.0.0.1:10808"
```

这一步是告诉终端里的程序也走代理。

> 📝 `127.0.0.1` 是本机地址，意思是"代理服务就在我自己电脑上"。端口号是代理软件的监听端口。

---

## 第五步：登录 Claude 账号

### 5.1 启动 Claude Code

在 VS Code 终端里运行：

```powershell
claude
```

首次运行会出现主题选择界面，选 **Dark mode** 或你喜欢的主题，按 Enter。

### 5.2 登录方式

出现登录选项后，选择 **Claude.ai Subscription**（用 Claude 订阅账号登录）。

### 5.3 浏览器验证

正常情况下会自动打开浏览器进行登录验证。

如果浏览器没有自动打开，终端会显示一个很长的链接和提示：

```
Browser didn't open? Use the url below to sign in (c to copy)
https://claude.com/cai/oauth/authorize?...
Paste code here if prompted >
```

操作步骤：

1. 按 **c** 复制链接
2. 手动打开浏览器，粘贴链接并访问
3. 在网页上登录你的 Claude 账号
4. 登录成功后网页会显示一个验证码
5. 复制验证码，回到终端粘贴，按 Enter

### 5.4 终端设置

登录后会提示是否使用推荐的终端设置：

```
Use Claude Code's terminal setup?
1. Yes, use recommended settings
2. No, maybe later with /terminal-setup
```

选 **1. Yes, use recommended settings**，按 Enter。

### 5.5 登录成功

看到以下信息就说明登录成功了：

```
claude
Sonnet 4.6 · Claude Pro · 你的邮箱
E:\你的项目路径
```

`>` 提示符出现后就可以开始使用了。

---

## 日常使用

### 启动 Claude Code

每次打开 VS Code，在终端里运行：

```powershell
# 设置代理（国内必须）
$env:HTTP_PROXY = "http://127.0.0.1:10808"
$env:HTTPS_PROXY = "http://127.0.0.1:10808"

# 启动
claude
```

### 使用示例

在 `>` 后面直接输入你的问题：

```
> 帮我写一个Python脚本，读取CSV文件并画柱状图
```

```
> 解释一下这段代码是什么意思
```

```
> 这个报错怎么解决：ModuleNotFoundError: No module named 'numpy'
```

Claude 会直接在终端里回复，还能帮你创建和修改文件。

### 常用快捷键

| 快捷键 | 作用 |
|--------|------|
| `?` | 查看所有快捷键 |
| `Esc` | 取消当前操作 |
| `Shift+Enter` | 输入多行内容 |

---

## 常见问题

**Q：登录时报 403 错误？**

两个可能原因：
1. 代理没开或端口配错了，检查 V2RayN 是否在运行，端口是否正确
2. 你的 Claude 账号是免费版，需要升级到 Pro（$20/月）

**Q：每次都要手动设代理，能不能自动？**

可以。在 PowerShell 配置文件里添加自动设置：

```powershell
notepad $PROFILE
```

在打开的文件里添加：

```powershell
$env:HTTP_PROXY = "http://127.0.0.1:10808"
$env:HTTPS_PROXY = "http://127.0.0.1:10808"
```

保存后每次打开终端会自动设置代理。

**Q：Claude Code 和 claude.ai 网页有什么区别？**

本质上是同一个 AI，区别在于使用方式：

| | claude.ai 网页 | Claude Code |
|---|---|---|
| 在哪用 | 浏览器 | VS Code 终端 |
| 能读代码文件 | 需要手动粘贴 | 自动读取项目文件 |
| 能改代码 | 不能，只能给建议 | 能直接修改你的文件 |
| 适合 | 问问题、写文章 | 写代码、改代码、Debug |

**Q：VS Code 弹出防火墙警告？**

点 **允许访问**，两个复选框（专用网络、公用网络）都勾上。Claude Code 需要联网才能工作。
