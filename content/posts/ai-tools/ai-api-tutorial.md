---
title: "VS Code 中调用 AI 模型 API 完整教程"
date: 2026-06-17
draft: false
tags: ["Python", "API", "AI", "DeepSeek", "OpenAI", "VS Code"]
categories: ["软件"]
math: false
summary: "手把手教你用 Python 在 VS Code 中调用 DeepSeek、OpenAI、通义千问等 AI 模型 API，从注册到跑通第一个请求。"
---

## 什么是 API

API（Application Programming Interface）就是**程序之间对话的接口**。

用人话说：你写一段 Python 代码，把问题发给 AI 的服务器，服务器返回 AI 的回答。

<div class="mermaid">
graph LR
    A[你的Python代码] -->|发送问题| B[AI服务器]
    B -->|返回回答| A
</div>

跟你在网页上跟 ChatGPT 聊天本质一样，只不过把"打字发送"变成了"代码发送"。

**为什么要用 API 而不是直接用网页聊天：**

| 网页聊天 | API 调用 |
|---------|---------|
| 手动一个个问 | 代码自动批量问 |
| 只能自己用 | 可以做成应用给别人用 |
| 功能固定 | 灵活定制，想怎么用就怎么用 |

用途：Python 调 API 就是把 AI 能力嵌进你自己的程序里。你的程序发请求给 AI 服务器，AI 返回结果，用户使用你的程序时就自动有了 AI 功能，用户甚至不知道背后用的是 DeepSeek 还是 ChatGPT。

---

## 环境准备

### 安装 Python

确认 Python 已安装：

```powershell
python --version
```

看到 `Python 3.x.x` 就行。没装的话去 [python.org](https://www.python.org/downloads/) 下载，安装时**勾选 Add to PATH**。

### 创建项目和虚拟环境

```powershell
# 创建项目文件夹
mkdir E:\projects\ai-api-demo
cd E:\projects\ai-api-demo

# 创建虚拟环境
python -m venv .venv

# 激活虚拟环境
.venv\Scripts\Activate.ps1

# 安装依赖（一个库调所有模型）
pip install openai
```

为什么只装 `openai` 一个库？因为大部分 AI 公司都兼容 OpenAI 的接口格式，**一个库就能调用所有模型**。

### 用 VS Code 打开项目

```powershell
code .
```

---

## 调用 DeepSeek（推荐入门）

DeepSeek 是国内的 AI 公司，注册简单，价格便宜，中文能力强。

### 第一步：注册拿 API Key

1. 打开 [platform.deepseek.com](https://platform.deepseek.com)
2. 用手机号注册并登录
3. 左侧菜单点 **API Keys**
4. 点 **创建 API Key**
5. 复制保存（只显示一次）

新用户有免费额度，足够测试。

### 第二步：写代码

新建 `deepseek_demo.py`：

```python
from openai import OpenAI

# 创建客户端
client = OpenAI(
    api_key="你的DeepSeek API Key",       # 换成你的Key
    base_url="https://api.deepseek.com"    # DeepSeek的地址
)

# 发送问题
response = client.chat.completions.create(
    model="deepseek-chat",                  # 模型名称
    messages=[
        {"role": "user", "content": "用简单的语言解释什么是PID控制"}
    ]
)

# 打印回答
print(response.choices[0].message.content)
```

### 第三步：运行

```powershell
python deepseek_demo.py
```

等几秒，终端里就会打印出 AI 的回答。

### 代码逐行解释

```python
from openai import OpenAI
# 导入 openai 库里的 OpenAI 类

client = OpenAI(
    api_key="你的Key",           # API Key，相当于你的身份证
    base_url="https://..."       # 服务器地址，告诉代码去哪找AI
)

response = client.chat.completions.create(
    model="deepseek-chat",       # 用哪个模型
    messages=[                   # 发送的消息列表
        {
            "role": "user",      # 角色：用户
            "content": "问题"     # 问题内容
        }
    ]
)

print(response.choices[0].message.content)
# response.choices[0] = 第一个回答
# .message.content    = 回答的文字内容
```

---

## 调用其他模型

学会 DeepSeek 后，调用其他模型只需要**换三个参数**：

| 参数 | 说明 |
|------|------|
| `api_key` | 换成对应平台的 Key |
| `base_url` | 换成对应平台的地址 |
| `model` | 换成对应的模型名 |

### OpenAI（GPT-4o）

注册地址：[platform.openai.com](https://platform.openai.com)

```python
client = OpenAI(
    api_key="sk-你的OpenAI Key"
    # 不用填base_url，默认就是OpenAI的地址
)

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "user", "content": "你好"}
    ]
)
```

> ⚠️ OpenAI 需要海外手机号注册，且需要付费充值才能用。国内访问需要代理。

### 通义千问（阿里）

注册地址：[dashscope.aliyun.com](https://dashscope.aliyun.com)

```python
client = OpenAI(
    api_key="你的阿里Key",
    base_url="https://dashscope.aliyuncs.com/compatible-mode/v1"
)

response = client.chat.completions.create(
    model="qwen-plus",
    messages=[
        {"role": "user", "content": "你好"}
    ]
)
```

> 有免费额度，注册用支付宝就行。

### 硅基流动（聚合平台）

注册地址：[siliconflow.cn](https://siliconflow.cn)

一个平台调用几十种模型，包括 Qwen、Llama、DeepSeek 等。

```python
client = OpenAI(
    api_key="你的硅基Key",
    base_url="https://api.siliconflow.cn/v1"
)

response = client.chat.completions.create(
    model="Qwen/Qwen2.5-7B-Instruct",
    messages=[
        {"role": "user", "content": "你好"}
    ]
)
```

> 有免费额度，注册简单，推荐用来尝试不同模型。

### Claude（Anthropic）

注册地址：[console.anthropic.com](https://console.anthropic.com)

Claude 有自己的 SDK，不用 openai 库：

```powershell
pip install anthropic
```

```python
import anthropic

client = anthropic.Anthropic(api_key="你的Claude Key")

response = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "你好"}
    ]
)

print(response.content[0].text)
```

---

## 各平台对比速查表

| 平台 | 注册方式 | 免费额度 | 国内直连 | 推荐程度 |
|------|---------|---------|---------|---------|
| DeepSeek | 手机号 | ✅ 有 | ✅ 能 | ⭐⭐⭐ 入门首选 |
| 通义千问 | 支付宝 | ✅ 有 | ✅ 能 | ⭐⭐⭐ |
| 硅基流动 | 手机号 | ✅ 有 | ✅ 能 | ⭐⭐⭐ 模型多 |
| OpenAI | 海外手机号 | ❌ 无 | ❌ 要代理 | ⭐⭐ 注册麻烦 |
| Claude API | 邮箱 | ❌ 无 | ❌ 要代理 | ⭐⭐ |

---

## 进阶用法

### 多轮对话

AI 不记得之前说了什么，需要你把历史消息都传过去：

```python
messages = [
    {"role": "user", "content": "我叫小明"},
    {"role": "assistant", "content": "你好小明！有什么可以帮你的？"},
    {"role": "user", "content": "我叫什么名字？"}
]

response = client.chat.completions.create(
    model="deepseek-chat",
    messages=messages
)

# AI会回答"你叫小明"，因为历史消息里有这个信息
```

| role | 意思 |
|------|------|
| `user` | 你说的话 |
| `assistant` | AI说的话 |
| `system` | 给AI的背景设定 |

### 设定 AI 的角色

用 `system` 消息给 AI 一个身份：

```python
response = client.chat.completions.create(
    model="deepseek-chat",
    messages=[
        {"role": "system", "content": "你是一个电机控制领域的专家，用简单易懂的语言回答问题"},
        {"role": "user", "content": "解释一下SVPWM算法"}
    ]
)
```

### 控制回答长度和随机性

```python
response = client.chat.completions.create(
    model="deepseek-chat",
    messages=[
        {"role": "user", "content": "写一首诗"}
    ],
    max_tokens=200,       # 最多回答200个token（约100个汉字）
    temperature=0.7       # 0=固定回答，1=随机创意，默认1
)
```

| 参数 | 作用 | 建议值 |
|------|------|--------|
| `max_tokens` | 限制回答长度 | 看需要，1000够大部分场景 |
| `temperature` | 控制随机性 | 写代码用0.2，写作用0.8 |

### 流式输出（打字机效果）

让 AI 的回答一个字一个字出现，不用等全部生成完：

```python
stream = client.chat.completions.create(
    model="deepseek-chat",
    messages=[
        {"role": "user", "content": "讲一个故事"}
    ],
    stream=True    # 开启流式输出
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
```

---

## API Key 安全管理

**千万不要**把 API Key 直接写在代码里然后上传到 GitHub，别人拿到你的 Key 会盗刷你的余额。

### 方法一：环境变量（推荐）

```python
import os
from openai import OpenAI

client = OpenAI(
    api_key=os.environ.get("DEEPSEEK_API_KEY"),
    base_url="https://api.deepseek.com"
)
```

运行前在终端设置环境变量：

```powershell
$env:DEEPSEEK_API_KEY = "你的Key"
python deepseek_demo.py
```

### 方法二：.env 文件

安装 python-dotenv：

```powershell
pip install python-dotenv
```

创建 `.env` 文件（注意有个点）：

```
DEEPSEEK_API_KEY=你的Key
```

代码里读取：

```python
from dotenv import load_dotenv
import os
from openai import OpenAI

load_dotenv()    # 读取.env文件

client = OpenAI(
    api_key=os.getenv("DEEPSEEK_API_KEY"),
    base_url="https://api.deepseek.com"
)
```

最后在 `.gitignore` 里加上 `.env`，防止上传：

```
.env
.venv/
__pycache__/
```

---

## 完整项目结构

```
E:\projects\ai-api-demo\
├── .venv\                 ← 虚拟环境（不上传）
├── .env                   ← API Key（不上传）
├── .gitignore             ← 忽略文件列表
├── deepseek_demo.py       ← DeepSeek 示例
├── openai_demo.py         ← OpenAI 示例
├── qwen_demo.py           ← 通义千问示例
└── requirements.txt       ← 依赖列表
```

---

## 常见问题

**Q：运行报错 `ModuleNotFoundError: No module named 'openai'`？**

虚拟环境没激活，先运行 `.venv\Scripts\Activate.ps1`，再 `pip install openai`。

**Q：报错 `AuthenticationError` 或 `401`？**

API Key 填错了或过期了，去平台重新生成一个。

**Q：报错 `Connection Error`？**

网络问题。用国内平台（DeepSeek、通义千问）不需要代理，用 OpenAI 需要代理：

```powershell
$env:HTTP_PROXY = "http://127.0.0.1:你的代理端口"
$env:HTTPS_PROXY = "http://127.0.0.1:你的代理端口"
```

**Q：一个 `openai` 库怎么调所有模型？**

因为大部分 AI 公司都兼容了 OpenAI 的接口标准，就像所有手机都用 Type-C 充电口一样。只要换 `base_url` 和 `api_key` 就能切换不同模型。

**Q：API 调用怎么收费？**

按 token 计费，token 是 AI 处理文字的最小单位。大约 1 个汉字 = 2 个 token，1000 个 token 约 500 个汉字。DeepSeek 每百万 token 约 1-2 元，非常便宜。
