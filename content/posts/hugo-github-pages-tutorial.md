---
title: "从零搭建个人知识库博客：Hugo + GitHub Pages 完整教程"
date: 2026-06-15
draft: false
tags: ["Hugo", "GitHub Pages", "博客搭建", "教程"]
categories: ["软件"]
math: true
summary: "手把手教你用 Hugo + GitHub Pages 搭建支持 LaTeX 公式和思维导图的个人知识库博客，完全免费，30分钟上线。"
---

## 一、为什么选 Hugo + GitHub Pages

搭建个人知识库，我需要满足三个条件：支持 LaTeX 数学公式、支持思维导图/流程图、完全免费。对比了几个方案后，选择了 Hugo + GitHub Pages：

| 方案 | LaTeX | 思维导图 | 免费 | 速度 |
|------|-------|---------|------|------|
| Hugo + GitHub Pages | ✅ KaTeX | ✅ Mermaid | ✅ | 极快 |
| Hexo + GitHub Pages | ✅ | ✅ | ✅ | 较快 |
| WordPress | 需插件 | 需插件 | ❌ 需服务器 | 一般 |
| Notion | 部分支持 | ❌ | ✅ | 一般 |

Hugo 构建速度极快，几百篇文章也能秒级生成，配合 GitHub Pages 免费托管，是技术博客的最佳选择。

---

## 二、环境准备

### 操作系统

本教程基于 Windows 环境，使用 PowerShell 操作。macOS 和 Linux 用户命令基本相同。

### 安装 Scoop（Windows 包管理器）

打开 **PowerShell**（注意：不要用管理员模式，普通模式打开），依次运行：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

|部分|意思|
|----|----|
|Set-ExecutionPolicy|设置脚本执行策略|
|-ExecutionPolicy RemoteSigned|允许运行本地脚本，但从网上下载的脚本必须有签名|
|-Scope CurrentUser|只对当前用户生效，不影响其他用户|


输入 `Y` 确认，然后：

```powershell
irm get.scoop.sh | iex
```
|部分|全称|意思|
|----|----|----|
|irm|Invoke-RestMethod|从网上下载内容|
|get.scoop.sh|Scoop的安装脚本地址|下载安装脚本|
|`|`|管道符，把左边命令的输出传给右边命令当输入，像水管接水一样|
|iex|Invoke-Expression|执行收到的内容|

看到 `Scoop was installed successfully` 表示安装成功。

> ⚠️ 如果用管理员模式运行会报错 "Running the installer as administrator is disabled by default"，关掉窗口用普通模式重新打开即可。

### 安装 Hugo

```powershell
scoop install hugo-extended
```

> ⚠️ 一定要装 `hugo-extended` 版本，PaperMod 主题需要 extended 版本支持 SCSS。

验证安装：

```powershell
hugo version
# 输出类似：hugo v0.147.0+extended windows/amd64
```

### 安装 Git

```powershell
scoop install git
```

### 注册 GitHub 账号

如果还没有 GitHub 账号，去 [github.com](https://github.com) 注册一个。记住你的用户名，后面要用。

---

## 三、创建博客项目

### 初始化项目

选择一个目录存放博客，比如 `E:\repository\`：

```powershell
# 1. 进入你想放博客的目录（比如D盘）
cd E:\repository\
# 2. 创建博客项目
hugo new site my-blog
# 3. 进入项目文件夹
cd my-blog
# 4. 初始化Git
git init
```

### 安装 PaperMod 主题

```powershell
#  安装PaperMod主题
git submodule add https://github.com/adityatelange/hugo-PaperMod.git themes/PaperMod
```

|部分|意思|
|----|----|
|git submodule add|把别人的仓库嵌入到你的项目里|
|https://github.com/adityatelange/hugo-PaperMod.git|PaperMod主题的GitHub地址|
|themes/PaperMod|下载到你项目的 themes/PaperMod 文件夹里|

git submodule add能跟原作者同步更新，以后想更新主题，输入代码git submodule update --remote。

PaperMod 是一个简洁美观的 Hugo 主题，支持深色模式、目录导航、代码高亮等功能。

### 配置 hugo.toml

该文件整个博客的总控制台，决定网站长什么样、有什么功能。

用 VS Code 或记事本打开项目根目录下的 `hugo.toml`，也可以通过在powershell键入指令修改文件。
```powershell
# 在PowerShell里运行，用VS Code打开整个项目
code D:\my-blog
```


**全部替换**为以下内容：

```toml
baseURL = "https://你的GitHub用户名.github.io/"
languageCode = "zh-cn"
title = "我的知识库"
theme = "PaperMod"

[params]
  defaultTheme = "auto"         
  ShowReadingTime = true        
  ShowShareButtons = false      
  ShowPostNavLinks = true       
  ShowBreadCrumbs = true        
  ShowCodeCopyButtons = true    
  ShowToc = true                
  TocOpen = true                

  [params.homeInfoParams]
    Title = "欢迎来到我的知识库"
    Content = "记录学习笔记与技术心得"

[[menu.main]]
  name = "首页"
  url = "/"
  weight = 1

[[menu.main]]
  name = "分类"
  url = "/categories/"
  weight = 2

[[menu.main]]
  name = "标签"
  url = "/tags/"
  weight = 3

[[menu.main]]
  name = "搜索"
  url = "/search/"
  weight = 4

[outputs]
  home = ["HTML", "RSS", "JSON"]

[markup]
  [markup.goldmark]
    [markup.goldmark.renderer]
      unsafe = true
  [markup.highlight]
    codeFences = true
    lineNos = true
    style = "monokai"
```
|区块|解释|
|----|----|
|前4行|网站叫什么、地址是什么、用什么主题|
|[params]|PaperMod主题的GitHub地址|
|[params.homeInfoParams]|首页显示的大标题和副标题|
|[[menu.main]]|顶部导航栏有哪些按钮|
|[outputs]|输出哪些格式（搜索功能需要JSON）|
|[markup]|代码高亮和HTML支持|

```powershell
  defaultTheme = "auto"         # 主题跟随系统（自动深色/浅色）
  ShowReadingTime = true        # 显示阅读时间（如"3 min"）
  ShowShareButtons = false      # 不显示分享按钮
  ShowPostNavLinks = true       # 文章底部显示"上一篇/下一篇"
  ShowBreadCrumbs = true        # 显示面包屑导航（首页 > 分类 > 文章）
  ShowCodeCopyButtons = true    # 代码块右上角显示复制按钮
  ShowToc = true                # 显示文章目录（Table of Contents）
  TocOpen = true                # 目录默认展开
  ```
> 📝 记得把 `baseURL` 里的 `你的GitHub用户名` 换成你自己的。

---

## 四、给博客安装插件
现在博客本身只能显示文字和图片，想要**LaTeX公式**和**Mermaid思维导图**，就得通过修改 `extend_head.html` 文件把它们"装上去"。
### 创建模板文件

```powershell
mkdir layouts\partials
notepad layouts\partials\extend_head.html
```

粘贴以下内容并保存：

```html
<!-- KaTeX CSS -->
<link rel="stylesheet"
  href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css"/>

<!-- KaTeX JS -->
<script defer
  src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js">
</script>

<!-- KaTeX 自动渲染 -->
<script defer
  src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js"
  onload="renderMathInElement(document.body, {
    delimiters: [
      {left: '$$', right: '$$', display: true},
      {left: '$', right: '$', display: false}
    ]
  });">
</script>

<!-- Mermaid 思维导图/流程图 -->
<script
  src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js">
</script>
<script>
  document.addEventListener('DOMContentLoaded', function () {
    mermaid.initialize({ startOnLoad: true, theme: 'default' });
  });
</script>
```

这个文件同时集成了 KaTeX（LaTeX 公式渲染）和 Mermaid（思维导图/流程图）。


## 五、基础写作技能
### 5.1 LaTeX 使用方法

在 Markdown 文章中直接写 LaTeX 语法：

**行内公式**：用单个 `$` 包裹

```
质能方程 $E = mc^2$ 是物理学最著名的公式。
```

**独立公式**：用双 `$$` 包裹

```
$$
\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}
$$
```

**矩阵**：

```
$$
\begin{bmatrix} a & b \\ c & d \end{bmatrix}
$$
```

---

### 5.2 集成思维导图（Mermaid）

Mermaid 已经在上一步的 `extend_head.html` 中一起配置好了。在 Markdown 中使用 HTML 标签包裹：

 #### 思维导图

```html
<div class="mermaid">
mindmap
  root((知识库))
    编程
      Python
      C/C++
    硬件
      电路设计
      PCB
    算法
      FOC
      PID
</div>
```

 #### 流程图

```html
<div class="mermaid">
graph TD
    A[开始] --> B{判断条件}
    B -->|是| C[执行操作A]
    B -->|否| D[执行操作B]
    C --> E[结束]
    D --> E
</div>
```

 #### 时间线

```html
<div class="mermaid">
timeline
    title 项目进度
    2026-Q1 : 需求分析 : 方案设计
    2026-Q2 : 硬件开发 : 软件开发
    2026-Q3 : 联调测试
    2026-Q4 : 量产交付
</div>
```

> ⚠️ Mermaid 需要 `hugo.toml` 中 `unsafe = true` 开启，否则 HTML 标签会被过滤。

---

## 六、写第一篇文章

### 创建文章
进入刚刚创建的文件夹
```powreshell
cd E:\repository\my-blog
```
创建文件
```powershell
hugo new posts/my-first-post.md
```
Hugo 默认会把所有的源文件放在项目的 ``content`` 文件夹里。所以这条命令实际创建的完整路径是：`my-blog/content/posts/my-first-post.md`。
### 编辑文章

用vscode打开 `content/posts/my-first-post.md`，替换为：

```markdown
---
title: "我的第一篇博客"
date: 2026-06-15
draft: false
tags: ["入门", "测试"]
categories: ["教程"]
math: true
---

## Hello World

这是我的第一篇博客！

### 测试 LaTeX 公式

欧拉公式：$e^{i\pi} + 1 = 0$

### 测试流程图

<div class="mermaid">
graph LR
    A[写文章] --> B[本地预览]
    B --> C[git push]
    C --> D[自动上线]
</div>
```

### 文章头部说明

| 字段 | 作用 | 说明 |
|------|------|------|
| `title` | 文章标题 | 必填 |
| `date` | 发布日期 | 必填 |
| `draft` | 是否为草稿 | `true` 不会发布，改为 `false` 发布 |
| `tags` | 标签 | 用于分类检索 |
| `categories` | 分类 | 用于大类归档 |
| `math` | 启用 LaTeX | 需要公式的文章设为 `true` |

### 本地预览

```powershell
hugo server -D
```

打开浏览器访问 `http://localhost:1313` 查看效果。`Ctrl+C` 停止预览。

---

## 七、部署到 GitHub Pages

### 创建 GitHub 仓库

1. 打开 [github.com/new](https://github.com/new)
2. Repository name 填：`my-blog.github.io`
3. 选择 **Public**
4. 其他选项都不勾
5. 点 **Create repository**

⚠️如果文件夹重复，则要修改两个地方

第一个地方，修改GitHub里面的链接地址
1. 打开 [github.com/new](https://github.com/new)
2. Repository name 填：`my-blog`
3. 选择 **Public**
4. 其他选项都不勾
5. 点 **Create repository**

第二个地方，``hugo.toml`` 里的 baseURL改为
```powershell
baseURL = "https://ckw2022.github.io/my-blog/"
```
此时访问地址变成：https://用户名.github.io/my-blog/
### 创建自动部署配置

```powershell
mkdir .github\workflows
notepad .github\workflows\deploy.yml
```

粘贴以下内容并保存：

```yaml
name: Deploy Hugo site to Pages

on:
  push:
    branches: ["main"]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v3
        with:
          hugo-version: "latest"
          extended: true

      - name: Build
        run: hugo --minify

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./public

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

### 配置 Git 身份

```powershell
git config --global user.name "你的GitHub用户名"
git config --global user.email "你的GitHub注册邮箱"
```

### 推送上线

```powershell
cd E:\repository\my-blog
git add .
git commit -m "init blog"
git branch -M main
git remote add origin https://github.com/你的用户名/你的用户名.github.io.git
git push --set-upstream origin main
```

如果在`github`创建文件夹时出现文件夹命名重复，则链接地址改为你当时创建的地址
```powershell
cd E:\repository\my-blog
git add .
git commit -m "init blog"
git branch -M main
git remote add origin https://github.com/ckw2022/my-blog.git
git push --set-upstream origin main
```
|部分|意思|
|----|----|
|cd E:\repository\my-blog|进入博客项目文件夹|
|git add .|把所有文件标记为"准备提交"|
|git commit -m "init blog"|提交，备注"初始化博客"。m，message的缩写，后面跟提交说明|
|git branch -M main|把当前分支命名为main|
|git remote add origin https://...|告诉Git仓库地址在哪|
|git push --set-upstream origin main|推送到GitHub|
### 开启 GitHub Pages

1. 打开 `https://github.com/你的用户名/你的用户名.github.io/settings/pages`或者`https://github.com/ckw2022/my-blog/settings/pages`
2. **Source** 改为 **GitHub Actions**
3. 等待 1-2 分钟
4. 访问 `https://你的用户名.github.io`

若命名重复则进行以下操作
1. 打开 `https://github.com/ckw2022/my-blog/settings/pages`
2. **Source** 改为 **GitHub Actions**
3. 等待 1-2 分钟
4. 访问 `https://你的用户名.github.io/my-blog/`
看到你的博客页面就成功了！

---

## 日常写作流程

搭建完成后，以后发新文章只需要四步：

```powershell
# 1. 创建新文章
hugo new posts/文章名.md

# 2. 编辑内容（推荐用 VS Code）
code .

# 3. 本地预览
hugo server -D

# 4. 推送上线（1-2分钟自动部署）
git add .
git commit -m "add 文章名"
git push
```

---

## 推荐目录结构

按主题分文件夹管理文章：

```
content/posts/
├── hardware/          # 硬件相关
│   ├── motor-structure.md
│   └── driver-circuits.md
├── software/          # 软件相关
│   ├── stm32-basics.md
│   └── rtos.md
└── algorithms/        # 算法相关
    ├── foc.md
    └── pid-control.md
```

---

## 常见问题

**Q：LaTeX 公式不渲染？**

检查两点：`layouts/partials/extend_head.html` 是否存在且内容正确；文章头部是否有 `math: true`。

**Q：Mermaid 图不显示？**

确认 `hugo.toml` 中 `unsafe = true` 已开启，且用 `<div class="mermaid">` 包裹代码。

**Q：git push 报错 "no upstream branch"？**

运行 `git push --set-upstream origin main`。

**Q：GitHub Pages 显示 404？**

进入仓库 Settings → Pages → Source 改为 GitHub Actions。

**Q：文章修改后网站没更新？**

确认 `draft` 设为 `false`，然后 `git add . && git commit -m "update" && git push`，等 1-2 分钟。

---

## 总结

整个搭建流程只需要安装三个工具（Scoop、Hugo、Git），配置三个文件（`hugo.toml`、`extend_head.html`、`deploy.yml`），就能拥有一个支持 LaTeX 公式和思维导图的免费个人知识库。以后写文章就是 Markdown + git push，简单高效。
