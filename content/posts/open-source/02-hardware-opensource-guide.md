---
title: "在 GitHub 上找硬件/PCB 开源项目：以 STM32G4 电机驱动板为例"
date: 2026-07-02
draft: false
tags: ["GitHub", "开源硬件", "STM32", "FOC", "电机驱动", "KiCad", "PCB"]
categories: ["工具"]
math: false
summary: "如何在 GitHub 上找到可以复现的硬件开源项目？以 STM32G4 电机驱动板为实战案例，讲解搜索策略、项目评估和复现要点。"
---

> **本文定位**：专门针对硬件/PCB 类开源项目的搜索和评估方法。以 STM32G4 FOC 电机驱动板为例，从搜索到判断能否复现，全流程实战演示。
>
> **开源项目探索系列：**
> | 编号 | 文章 | 一句话说明 |
> |------|------|-----------|
> | 01 | [GitHub 搜索技巧指南](./01-github-search-guide.md) | GitHub 搜索技巧 + 项目质量判断 |
> | **02** | **本文** | **硬件/PCB 开源项目搜索实战** |
>
> 通用的 GitHub 搜索语法（`stars:`、`language:`、`topic:` 等）请看 [01](./01-github-search-guide.md)，本文不重复。

---

## 硬件项目和软件项目搜索的区别

软件项目 clone 下来就能跑，硬件项目不一样——你需要原理图、PCB 文件、BOM 表、固件代码，缺一个都没法复现。所以搜索硬件项目时，关注点不仅是"找到"，更是"能不能打板做出来"。

| 维度 | 软件项目 | 硬件项目 |
|------|---------|---------|
| 复现成本 | clone + install | 打板 + 采购元器件 + 焊接 + 调试 |
| 必须的文件 | 源码 | 原理图 + PCB + BOM + 固件 |
| EDA 工具 | 不需要 | KiCad / Altium Designer / 立创 EDA |
| 验证方式 | 运行测试 | 实物调试 |
| 版本兼容 | 依赖管理 | EDA 版本、元器件停产问题 |

---

## 搜索策略：怎么找硬件项目

### 策略一：用 Topics 浏览

硬件类项目常用的 Topics：

| Topic | 地址 | 内容 |
|-------|------|------|
| `bldc-driver` | [github.com/topics/bldc-driver](https://github.com/topics/bldc-driver) | BLDC 电机驱动 |
| `bldc-motor-controller` | [github.com/topics/bldc-motor-controller](https://github.com/topics/bldc-motor-controller) | BLDC 电机控制器 |
| `foc` | [github.com/topics/foc](https://github.com/topics/foc) | 磁场定向控制 |
| `motor-controller` | [github.com/topics/motor-controller](https://github.com/topics/motor-controller) | 电机控制器（通用） |
| `kicad-pcb` | [github.com/topics/kicad-pcb](https://github.com/topics/kicad-pcb) | KiCad PCB 设计 |
| `pcb-design` | [github.com/topics/pcb-design](https://github.com/topics/pcb-design) | PCB 设计（通用） |
| `open-source-hardware` | [github.com/topics/open-source-hardware](https://github.com/topics/open-source-hardware) | 开源硬件 |
| `stm32` | [github.com/topics/stm32](https://github.com/topics/stm32) | STM32 相关 |

### 策略二：精准搜索

```
# 找 STM32G4 电机驱动的硬件项目
stm32g4 motor driver stars:>5

# 找包含 KiCad 文件的项目（有 PCB 设计 = 硬件可复现）
stm32g4 motor path:*.kicad_pcb

# 找 FOC 控制器
stm32g4 foc bldc

# 限定有 BOM 文件
motor driver path:BOM

# 组合搜索：STM32 + FOC + 活跃项目
stm32 foc stars:>20 pushed:>2025-01-01

# 中文搜索
stm32g4 电机 驱动 开源
```

### 策略三：看 Awesome List 和聚合页

硬件项目有几个重要的聚合资源：

| 资源 | 地址 | 说明 |
|------|------|------|
| 机器人电子清单 | [cajt/list_of_robot_electronics](https://github.com/cajt/list_of_robot_electronics) | 开源机器人电子硬件汇总，含大量电机驱动板 |
| KiCad Made with KiCad | [kicad.org/made-with-kicad](https://www.kicad.org/made-with-kicad/) | KiCad 官网的项目展示，按类别浏览 |
| KiCad Motor Controller | [kicad.org/.../Motor-Controller](https://www.kicad.org/made-with-kicad/categories/Motor-Controller/) | KiCad 电机控制器分类 |
| OSHWA 认证项目 | [certification.oshwa.org](https://certification.oshwa.org/list.html) | 开源硬件协会认证的项目 |

### 策略四：从成熟项目的生态出发

有些大项目形成了生态，围绕它有很多衍生设计：

| 生态核心项目 | 说明 | 衍生搜索 |
|------------|------|---------|
| [SimpleFOC](https://github.com/simplefoc/Arduino-FOC) | 通用 FOC 库，社区大 | 搜 `simplefoc board` 找配套硬件 |
| [moteus](https://github.com/mjbots/moteus) | 成熟 STM32G4 驱动板 | 看 Fork 和 Discussions 找衍生设计 |
| [ODrive](https://github.com/odrivetechnic/ODrive) | 高性能双轴驱动 | 搜 `odrive compatible` |
| [VESC](https://github.com/vedderb/bldc) | 电动车/滑板车驱动 | 搜 `vesc hardware` |

---

## 实战案例：找 STM32G4 电机驱动板

### 搜索过程

1. 先搜 `stm32g4 motor driver`，按 Star 排序
2. 再搜 `stm32g4 foc bldc`，扩大范围
3. 看 Topics 页面 [bldc-driver](https://github.com/topics/bldc-driver)
4. 查 [list_of_robot_electronics](https://github.com/cajt/list_of_robot_electronics) 聚合列表
5. 搜中文 `stm32g4 电机 foc`

### 找到的项目

| 项目 | MCU | 特点 | EDA | 链接 |
|------|-----|------|-----|------|
| **RoboMotor** | STM32G4 | 全开源 FOC 控制器，17kHz 电流环 + 4kHz 速度环 + 1kHz 位置环 | KiCad 8 | [GitHub](https://github.com/baoqi-zhong/RoboMotor) |
| **flatmcu** | STM32G473CB | BLDC/FOC 控制器，TI DRV8353RS 驱动芯片 | KiCad | [GitHub](https://github.com/GyrocopterLLC/flatmcu) |
| **moteus** | STM32G4 | 50mm 方板，集成磁编码器，CAN-FD 通信，社区最大 | KiCad | [GitHub](https://github.com/mjbots/moteus) |
| **G431-ESC-MotorDriver** | STM32G431 | 基于 ST ESC 开发板的电机控制 | — | [GitHub](https://github.com/mindThomas/G431-ESC-MotorDriver) |
| **MESC_Firmware** | STM32 全系列 | 通用 FOC 固件库，支持 FPU 的 STM32 | — | [GitHub](https://github.com/davidmolony/MESC_Firmware) |
| **DengFOC_on_STM32** | STM32G4 | 灯哥 FOC 教程实现，学习向 | — | [GitHub](https://github.com/haotianh9/DengFOC_on_STM32) |

### 如何选择

- **想直接打板复现** → RoboMotor（KiCad 8 全开源，中国作者）或 moteus（最成熟）
- **想学 FOC 算法** → DengFOC_on_STM32（有教程配套）或 MESC_Firmware（代码注释好）
- **想参考驱动芯片选型** → flatmcu（用了 TI DRV8353RS，文档清楚）

---

## 判断硬件项目能否复现

找到项目后，在决定投入时间和金钱之前，按下面的清单检查：

### 必须检查的文件

| 文件类型 | 常见路径/文件名 | 没有会怎样 |
|---------|---------------|-----------|
| **原理图** | `*.kicad_sch`、`*.SchDoc`、`schematic/` | 不知道电路怎么连的 |
| **PCB 文件** | `*.kicad_pcb`、`*.PcbDoc`、`pcb/` | 没法打板 |
| **BOM 表** | `BOM.csv`、`BOM.xlsx`、`bom/` | 不知道买什么元器件 |
| **Gerber 文件** | `gerber/`、`fabrication/` | 有了可以直接发给 PCB 厂（但有 PCB 文件也能自己导出） |
| **固件代码** | `firmware/`、`src/`、`*.c/*.h` | 板子做了也跑不起来 |

### 质量评估清单

| 检查项 | 看什么 | 红线 |
|--------|--------|------|
| **EDA 版本** | README 或项目文件头 | KiCad 7/8 最好，太老的版本可能打不开 |
| **BOM 可采购性** | 元器件型号是否能买到 | 用了停产/冷门器件 = 采购困难 |
| **文档完整度** | 有没有焊接说明、调试步骤 | 零文档的硬件项目复现难度极高 |
| **最近更新** | 最后 commit 时间 | 超过 2 年没更新要谨慎 |
| **Issue 反馈** | 有没有人成功复现并反馈 | 有人说"成功打板运行"= 可靠 |
| **3D 模型/图片** | README 里有没有实物照片 | 有实物照片说明作者自己做过 |
| **License** | 硬件许可类型 | CERN OHL / CC BY-SA 最常见，无 License 的谨慎 |

### EDA 工具对照

你需要对应的 EDA 工具才能打开设计文件：

| 文件后缀 | EDA 工具 | 是否免费 |
|---------|---------|---------|
| `.kicad_pcb` / `.kicad_sch` | KiCad | 免费开源 |
| `.PcbDoc` / `.SchDoc` | Altium Designer | 付费（学生免费） |
| `.json`（立创格式） | 立创 EDA | 免费 |
| `.brd` / `.sch`（Eagle） | Autodesk Eagle / KiCad（可导入） | Eagle 已停售 |

**建议**：优先选 KiCad 设计的项目，KiCad 免费开源，跨平台，社区活跃。

---

## 从搜索到复现的完整流程

```
1. 明确需求
   └─ 我要什么？（电压范围、电流、电机类型、通信接口）

2. 搜索项目
   ├─ GitHub Topics 浏览
   ├─ 关键词搜索 + 排序筛选
   ├─ Awesome List / 聚合列表
   └─ 成熟项目生态

3. 初步筛选（5 分钟/项目）
   ├─ Star 数和活跃度
   ├─ README 文档质量
   └─ 是否有完整的硬件文件

4. 深入评估（30 分钟/项目）
   ├─ 下载并用 KiCad 打开原理图
   ├─ 检查 BOM 元器件可采购性
   ├─ 看 Issues 里有没有复现反馈
   └─ 评估是否需要修改适配

5. 开始复现
   ├─ 导出 Gerber → 发给 PCB 厂（嘉立创等）
   ├─ 按 BOM 采购元器件
   ├─ 焊接（先焊电源部分，测试通过再焊其他）
   └─ 烧录固件 → 调试
```

---

## 硬件项目的 License 说明

硬件开源项目用的许可证和软件不同：

| License | 全称 | 说明 |
|---------|------|------|
| **CERN OHL-S** | CERN Open Hardware Licence – Strongly Reciprocal | 类似 GPL，修改后必须开源 |
| **CERN OHL-W** | CERN Open Hardware Licence – Weakly Reciprocal | 类似 LGPL，核心修改需开源 |
| **CERN OHL-P** | CERN Open Hardware Licence – Permissive | 类似 MIT，随便用 |
| **CC BY-SA** | Creative Commons Attribution-ShareAlike | 需署名 + 相同方式共享 |
| **CC BY** | Creative Commons Attribution | 只需署名 |

商用的话优先选 CERN OHL-P 或 CC BY 的项目。个人学习用不必太纠结。

---

*参考来源：[GitHub Topics - kicad-pcb](https://github.com/topics/kicad-pcb) · [GitHub Topics - bldc-driver](https://github.com/topics/bldc-driver) · [cajt/list_of_robot_electronics](https://github.com/cajt/list_of_robot_electronics) · [KiCad Made with KiCad](https://www.kicad.org/made-with-kicad/) · [RoboMotor](https://github.com/baoqi-zhong/RoboMotor) · [moteus](https://github.com/mjbots/moteus) · [flatmcu](https://github.com/GyrocopterLLC/flatmcu)*
