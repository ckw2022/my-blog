---
title: "VS Code 配置 Python 开发环境 + 虚拟环境"
date: 2026-06-16
draft: false
tags: ["Python", "VS Code", "虚拟环境", "开发环境"]
categories: ["软件"]
math: false
summary: "从零配置 VS Code 的 Python 开发环境，包括安装、插件、虚拟环境创建与管理，解决包冲突问题。"
---

## 为什么需要配置这些

很多人装完 Python 直接开始写代码，遇到的第一个坑往往是：项目A需要 `numpy 1.24`，项目B需要 `numpy 2.0`，装了一个另一个就崩了。

**虚拟环境**就是为了解决这个问题——给每个项目一个独立的 Python 环境，互不干扰。

<div class="mermaid">
graph TD
    A[电脑上的 Python] --> B[项目A的虚拟环境]
    A --> C[项目B的虚拟环境]
    A --> D[项目C的虚拟环境]
    B --> E["numpy 1.24<br>pandas 1.5"]
    C --> F["numpy 2.0<br>pandas 2.2"]
    D --> G["torch 2.0<br>opencv 4.9"]
</div>

每个项目装自己需要的包，互不影响。

---

## 第一步：安装 Python

### 下载

打开 [python.org/downloads](https://www.python.org/downloads/)，下载最新版本，双击安装。

### 安装时注意

安装界面**一定要勾选** `Add python.exe to PATH`，这是最重要的一步。不勾的话，命令行里找不到 Python。

### 验证安装

打开 PowerShell 或终端，运行：

```powershell
python --version
```

看到类似 `Python 3.12.x` 就说明安装成功。

同时验证 pip（Python 的包管理器）：

```powershell
pip --version
```

---

## 第二步：安装 VS Code 插件

打开 VS Code，按 `Ctrl+Shift+X` 进入扩展商店，搜索并安装以下插件：

| 插件名 | 作用 | 必装 |
|--------|------|------|
| **Python** (Microsoft) | Python 语言支持、调试、运行 | ✅ |
| **Pylance** (Microsoft) | 智能补全、类型检查 | ✅ |
| **Python Debugger** | 断点调试 | ✅ |
| **autopep8** 或 **Black Formatter** | 代码自动格式化 | 推荐 |

装完后重启 VS Code。

---

## 第三步：创建项目文件夹

假设要做一个数据分析项目：

```powershell
mkdir E:\projects\data-analysis
cd E:\projects\data-analysis
```

用 VS Code 打开这个文件夹：

```powershell
code .
```

---

## 第四步：创建虚拟环境

### 什么是虚拟环境

| | 不用虚拟环境 | 用虚拟环境 |
|---|---|---|
| 包装在哪 | 全局，所有项目共用 | 每个项目独立 |
| 会不会冲突 | ❌ 经常冲突 | ✅ 不会 |
| 删项目时 | 包还留在电脑上 | 删文件夹就干净了 |

### 创建虚拟环境

在 VS Code 的终端里（按 `` Ctrl+` `` 打开终端）运行：

```powershell
python -m venv .venv
```

这会在项目文件夹里创建一个 `.venv` 文件夹，里面就是这个项目专属的 Python 环境。

各部分含义：

| 部分 | 意思 |
|------|------|
| `python -m venv` | 用 Python 内置的 venv 模块创建虚拟环境 |
| `.venv` | 虚拟环境的文件夹名（`.` 开头表示隐藏文件夹，是约定俗成的命名） |

### 激活虚拟环境

```powershell
# Windows PowerShell
.venv\Scripts\Activate.ps1
```

激活后，终端前面会出现 `(.venv)` 标记：

```
(.venv) PS E:\projects\data-analysis>
```

看到 `(.venv)` 就说明你现在在虚拟环境里了。

> ⚠️ 如果报错 "无法加载文件...因为在此系统上禁止运行脚本"，先运行：
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```
> 输入 `Y` 确认，然后重新激活。

### 退出虚拟环境

```powershell
deactivate
```

---

## 第五步：让 VS Code 识别虚拟环境

### 自动识别

VS Code 通常会自动检测到 `.venv` 文件夹。右下角会提示"选择 Python 解释器"，点击选择 `.venv` 里的那个。

### 手动选择

如果没自动识别：

1. 按 `Ctrl+Shift+P` 打开命令面板
2. 输入 `Python: Select Interpreter`
3. 选择带 `.venv` 路径的那个，类似：

```
Python 3.12.x ('.venv': venv)  .\.venv\Scripts\python.exe
```

### 验证

在 VS Code 终端里运行：

```powershell
python -c "import sys; print(sys.executable)"
```

输出路径里包含 `.venv` 就说明配置正确：

```
E:\projects\data-analysis\.venv\Scripts\python.exe
```

---

## 第六步：安装项目依赖

虚拟环境激活后，用 pip 安装包，这些包只装在当前项目的 `.venv` 里：

```powershell
# 安装单个包
pip install numpy
pip install pandas
pip install matplotlib

# 一次装多个
pip install numpy pandas matplotlib
```

### 导出依赖列表

```powershell
pip freeze > requirements.txt
```

会生成一个 `requirements.txt` 文件，记录所有安装的包和版本号：

```
matplotlib==3.9.0
numpy==2.0.0
pandas==2.2.2
```

### 从依赖列表安装

别人拿到你的项目，一条命令就能装好所有依赖：

```powershell
pip install -r requirements.txt
```

---

## 第七步：配置 VS Code 设置

在项目根目录创建 `.vscode/settings.json`，统一项目配置：

```json
{
    "python.defaultInterpreterPath": ".venv/Scripts/python.exe",
    "python.terminal.activateEnvironment": true,
    "editor.formatOnSave": true,
    "python.analysis.typeCheckingMode": "basic"
}
```

| 配置项 | 作用 |
|--------|------|
| `defaultInterpreterPath` | 指定用哪个 Python |
| `activateEnvironment` | 打开终端自动激活虚拟环境 |
| `formatOnSave` | 保存时自动格式化代码 |
| `typeCheckingMode` | 开启基本的类型检查 |

---

## 完整项目结构

```
E:\projects\data-analysis\
├── .venv\                  ← 虚拟环境（不要上传到Git）
├── .vscode\
│   └── settings.json       ← VS Code 项目配置
├── main.py                 ← 你的代码
├── requirements.txt        ← 依赖列表
└── .gitignore              ← Git忽略文件
```

### .gitignore 文件

创建 `.gitignore` 文件，避免把虚拟环境上传到 GitHub：

```
.venv/
__pycache__/
*.pyc
.vscode/
```

---

## 日常工作流程

<div class="mermaid">
graph TD
    A[打开 VS Code] --> B[打开项目文件夹]
    B --> C{终端显示 .venv 吗?}
    C -->|是| D[直接写代码]
    C -->|否| E[手动激活: .venv\Scripts\Activate.ps1]
    E --> D
    D --> F[运行: python main.py]
    F --> G{需要新的包?}
    G -->|是| H[pip install 包名]
    H --> I[pip freeze > requirements.txt]
    I --> D
    G -->|否| D
</div>

### 每天开始写代码

```powershell
# 1. 打开项目
code E:\projects\data-analysis

# 2. VS Code 自动激活虚拟环境（如果配置了settings.json）

# 3. 写代码，按 F5 或右上角运行按钮运行
```

### 新建一个项目

```powershell
# 1. 创建文件夹
mkdir E:\projects\new-project
cd E:\projects\new-project

# 2. 创建虚拟环境
python -m venv .venv

# 3. 激活
.venv\Scripts\Activate.ps1

# 4. 装包
pip install 你需要的包

# 5. 用 VS Code 打开
code .
```

---

## 常见问题

**Q：每个项目都要创建虚拟环境吗？**

推荐是的。虽然小脚本可以不用，但养成习惯能避免很多包冲突的问题。创建虚拟环境就一条命令的事。

**Q：`.venv` 文件夹很大，能删吗？**

可以。删了以后重新 `python -m venv .venv`，再 `pip install -r requirements.txt` 就恢复了。这就是 `requirements.txt` 的意义——记录依赖，随时重建。

**Q：激活虚拟环境报错"禁止运行脚本"？**

运行 `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`，这个在搭建博客时已经设置过了，一般不会再遇到。

**Q：VS Code 终端没有自动激活虚拟环境？**

检查 `.vscode/settings.json` 里 `activateEnvironment` 是否为 `true`，以及解释器路径是否正确。

**Q：pip install 很慢？**

换国内镜像源：

```powershell
pip install numpy -i https://pypi.tuna.tsinghua.edu.cn/simple
```

或者永久设置清华源：

```powershell
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```
