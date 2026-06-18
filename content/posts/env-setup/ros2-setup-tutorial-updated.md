---
title: "Windows 下搭建 ROS2 开发环境完整教程"
date: 2026-06-18
draft: false
tags: ["ROS2", "Ubuntu", "虚拟机", "机器人"]
categories: ["软件"]
math: false
summary: "从安装虚拟机到配置 ROS2 开发环境，包括 Ubuntu 安装、ROS2 安装、VS Code 远程开发配置，一站式搞定。"
---

## 方案选择

Windows 上跑 ROS2 有三种方式：

| 方案 | 优点 | 缺点 | 推荐 |
|------|------|------|------|
| **VMware 虚拟机** | 完整 Linux，GUI 稳定，Gazebo/rviz2 正常 | 占资源多，性能有损耗 | ⭐⭐⭐ 最稳 |
| **WSL2** | 轻量，启动快 | GUI 支持不完美，Gazebo 可能有问题 | ⭐⭐ |
| **双系统** | 性能最好 | 切换麻烦，有风险 | ⭐ |

**推荐用 VMware 虚拟机**，ROS2 的可视化工具（rviz2、Gazebo）在虚拟机里最稳定。

---

## 第一步：下载所需文件

### 1.1 下载 VMware Workstation Pro

VMware 现在对个人用户免费了。

**官网下载（推荐）：**

1. 打开 [Broadcom 支持门户](https://support.broadcom.com)
2. 注册 Broadcom 账号（免费）
3. 搜索 VMware Workstation Pro，下载 Windows 版
4. 安装时选择 **个人免费许可证**

> 官网注册流程比较繁琐。如果打不开或太慢，可以在 Gitee 上搜索"VMware Workstation"找到第三方分享的安装包，下载后用杀毒软件扫一遍再安装。

**安装注意事项：**

- 安装过程中如果提示需要安装 **Microsoft VC Redistributable** 并重启，点"是"重启，重启后重新运行安装程序
- 安装完成后可能弹出"侧通道缓解"安全提示，关掉即可，不影响使用

### 1.2 下载 Ubuntu 22.04 镜像

ROS2 Humble（目前最稳定的长期支持版）需要 Ubuntu 22.04：

1. 打开 [ubuntu.com/download/desktop](https://mirrors.tuna.tsinghua.edu.cn/ubuntu-releases/22.04.5/)
2. 点 22.04.5/（22.04的最新版本），进去后找到文件名包含 desktop-amd64.iso 的文件下载，大约4.5GB。
> ⚠️ 一定要选 22.04，不要选 24.04。ROS2 Humble 只支持 22.04。

---

## 第二步：创建虚拟机

### 2.1 新建虚拟机

1. 打开 VMware Workstation
2. 点 **创建新的虚拟机**
3. 选 **典型（推荐）**，下一步
4. 选 **安装程序光盘映像文件(iso)** → 浏览选择下载好的 `ubuntu-22.04.5-desktop-amd64.iso`
5. 下一步，操作系统会自动识别为 **Ubuntu 64 位**
6. 虚拟机名称填 `ROS2-Ubuntu`
7. 选择存放位置（建议放在空间大的盘，如 `E:\VMs\ROS2-Ubuntu`）

### 2.2 配置硬件（逐步设置）

创建向导中会依次配置以下项目：

**处理器配置：**

| 设置项 | 填写值 |
|--------|--------|
| 处理器数量 | 2 |
| 每个处理器内核数量 | 2 |
| 总核数 | 4 |

> 📝 不要把所有核心都给虚拟机，留一半给 Windows。例如 i5-12400F（6核12线程）给虚拟机4核，Windows留2核。

**内存配置：**

| 设置项 | 推荐值 | 说明 |
|--------|--------|------|
| 内存 | 8192 MB (8GB) | ROS2 + Gazebo 需要较大内存 |

> 如果你的电脑总内存是16GB，给虚拟机8GB，Windows留8GB。总内存只有8GB的话给4GB。

**网络配置：**

选 **使用网络地址转换（NAT）**。NAT 模式下虚拟机自动共用 Windows 的网络，不需要额外配置。

**I/O 控制器和磁盘类型：**

| 设置项 | 选择 |
|--------|------|
| I/O 控制器 | LSI Logic（推荐） |
| 磁盘类型 | SCSI（推荐） |
| 磁盘 | 创建新虚拟磁盘 |

这三步都选默认推荐值，直接下一步。

**磁盘容量：**

| 设置项 | 填写值 |
|--------|--------|
| 最大磁盘大小 | **60 GB**（默认20GB太小，装完ROS2就满了） |
| 存储方式 | **将虚拟磁盘存储为单个文件**（性能更好） |

> 📝 不用勾"立即分配所有磁盘空间"，虚拟硬盘会按实际使用量慢慢增大，不会一下子占掉60GB。

**完成前检查：**

创建完成前会显示配置摘要，点 **自定义硬件** 再检查两项：

1. **CD/DVD** → 确认已选择 Ubuntu 22.04 的 ISO 文件
2. **显示器** → 勾选 **加速3D图形**（Gazebo 仿真器必须开启）

确认无误后点 **完成**，虚拟机创建成功。

### 2.3 安装 Ubuntu

点 **开启此虚拟机**，进入 Ubuntu 安装界面：

**第一步：选择语言**

左侧列表选 **English**（建议用英文系统，ROS2 文档和报错信息都是英文，方便排查问题），点 **Install Ubuntu**。

> 也可以选中文，不影响 ROS2 使用，但遇到报错搜索英文更容易找到解决方案。

**第二步：键盘布局**

选 **English (US)**，直接 Continue。

**第三步：更新和软件**

- 选 **Normal installation**（正常安装）
- 勾选 **Download updates while installing Ubuntu**（安装时下载更新）
- 点 Continue

**第四步：安装类型**

选 **Erase disk and install Ubuntu**（清除磁盘并安装），点 **Install Now**。

弹出确认对话框 "Write the changes to disks?"，点 **Continue**。

> ⚠️ 这里说的"清除磁盘"是虚拟机的60GB虚拟硬盘，不会影响你 Windows 的 C盘/D盘/E盘。

**第五步：选择时区**

选 **Shanghai**，点 Continue。

**第六步：设置用户信息**

| 字段 | 填什么 |
|------|--------|
| Your name | 你的名字（如 ckw） |
| Your computer's name | 自动生成即可 |
| Pick a username | 登录用户名（如 ckw） |
| Choose a password | 设一个密码 |
| Confirm your password | 再输一遍 |

建议选 **Log in automatically**（自动登录），省得每次开虚拟机都输密码。

> ⚠️ 密码一定要记住！后面装 ROS2 用 `sudo` 命令时需要输入密码。

点 Continue，等待安装完成（约10-20分钟），安装完后重启。

**第七步：进入系统**

重启后会弹出 Welcome 向导和 Software Updater：

- **Software Updater**：点 **Install Now** 更新系统
- **Welcome 向导**：一路点 Next/Skip 跳过即可

### 2.4 安装 VMware Tools

重启后在虚拟机里打开终端（`Ctrl+Alt+T`）：

```bash
sudo apt update
sudo apt install -y open-vm-tools open-vm-tools-desktop
```

安装后重启虚拟机，就能：
- 自适应分辨率
- Windows 和虚拟机之间复制粘贴
- 拖拽文件

装了 vs 没装：
| 功能 | 没装 VMware Tools | 装了 VMware Tools |
| --- | --- | --- |
| 分辨率 | 固定800x600，很小 | 自动适应窗口大小 |
| 复制粘贴 | Windows和虚拟机之间不能复制 | 可以互相复制粘贴文字 |
| 拖拽文件 | 不能 | 直接从Windows拖文件进虚拟机 |
| 鼠标 | 进出虚拟机要按Ctrl+Alt | 鼠标自由移动，无缝切换 |
| 性能 | 卡顿 | 更流畅 |

---

## 第三步：安装 ROS2 Humble

在 Ubuntu 虚拟机的终端里（`Ctrl+Alt+T` 打开终端），**逐步**运行以下命令：

### 3.0 检查网络和换源

先确认虚拟机能上网：

```bash
ping baidu.com
```

看到有回复就说明网络正常，`Ctrl+C` 停止。

> 如果 ping 不通，检查 VMware 网络设置是否选了 NAT 模式。

换清华源加速下载（国内必须，否则下载极慢）：

```bash
sudo sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
sudo sed -i 's/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
sudo apt update
```

### 3.1 设置编码

```bash
sudo apt update && sudo apt install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
```

### 3.2 添加 ROS2 软件源

```bash
sudo apt install -y software-properties-common
sudo add-apt-repository universe

sudo apt update && sudo apt install -y curl
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
```

### 3.3 安装 ROS2

```bash
sudo apt update
sudo apt upgrade -y

# 安装桌面完整版（包含 rviz2、Gazebo 等可视化工具）
sudo apt install -y ros-humble-desktop
```

这一步下载量较大（约 2GB），耐心等待。

### 3.4 安装开发工具

```bash
# 编译工具
sudo apt install -y python3-colcon-common-extensions

# rosdep（依赖管理）
sudo apt install -y python3-rosdep2
sudo rosdep init
rosdep update
```

### 3.5 配置环境变量

```bash
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

这行命令让你每次打开终端都自动加载 ROS2 环境。

### 3.6 验证安装

打开两个终端窗口：

**终端1（发布者）：**
```bash
ros2 run demo_nodes_cpp talker
```

**终端2（订阅者）：**
```bash
ros2 run demo_nodes_cpp listener
```

如果终端1不断打印 `Publishing: 'Hello World: x'`，终端2不断打印 `I heard: [Hello World: x]`，说明 ROS2 安装成功。

---

## 第四步：安装 Gazebo 仿真器

```bash
sudo apt install -y ros-humble-gazebo-ros-pkgs
```

测试 Gazebo：

```bash
gazebo
```

弹出 3D 仿真界面就成功了。

---

## 第五步：VS Code 远程开发（在 Windows 上写代码）

你可以在 Windows 的 VS Code 里直接编辑虚拟机里的代码，不用在虚拟机里装 VS Code。

### 5.1 虚拟机里安装 SSH

在 Ubuntu 终端运行：

```bash
sudo apt install -y openssh-server
```

查看虚拟机的 IP 地址：

```bash
ip addr show | grep inet
```

找到类似 `192.168.xxx.xxx` 的地址，记下来。

### 5.2 Windows VS Code 安装远程插件

1. 打开 Windows 上的 VS Code
2. `Ctrl+Shift+X` 搜索安装 **Remote - SSH**
3. 按 `Ctrl+Shift+P`，输入 `Remote-SSH: Connect to Host`
4. 输入 `你的Ubuntu用户名@192.168.xxx.xxx`
5. 输入你的 Ubuntu 密码
6. 连接成功后左下角显示绿色的 SSH 标识

现在你就可以在 Windows 的 VS Code 里直接编辑虚拟机里的文件了。

### 5.3 安装 ROS 插件

连接到虚拟机后，在 VS Code 里安装：

- **ROS**（Microsoft出品）
- **C/C++**
- **Python**
- **CMake Tools**

---

## 第六步：创建第一个 ROS2 工作空间

### 6.1 创建工作空间

```bash
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws
```

### 6.2 创建功能包

```bash
cd ~/ros2_ws/src

# 创建Python功能包
ros2 pkg create --build-type ament_python my_first_pkg --dependencies rclpy

# 或者创建C++功能包
ros2 pkg create --build-type ament_cmake my_cpp_pkg --dependencies rclcpp
```

### 6.3 编译

```bash
cd ~/ros2_ws
colcon build
source install/setup.bash
```

### 6.4 写一个简单的发布者节点

编辑 `~/ros2_ws/src/my_first_pkg/my_first_pkg/publisher.py`：

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String

class MinimalPublisher(Node):
    def __init__(self):
        super().__init__('minimal_publisher')
        self.publisher_ = self.create_publisher(String, 'topic', 10)
        timer_period = 0.5  # 每0.5秒发布一次
        self.timer = self.create_timer(timer_period, self.timer_callback)
        self.i = 0

    def timer_callback(self):
        msg = String()
        msg.data = f'Hello ROS2: {self.i}'
        self.publisher_.publish(msg)
        self.get_logger().info(f'Publishing: "{msg.data}"')
        self.i += 1

def main(args=None):
    rclpy.init(args=args)
    node = MinimalPublisher()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
```

### 6.5 配置 setup.py

编辑 `~/ros2_ws/src/my_first_pkg/setup.py`，在 `entry_points` 里添加：

```python
entry_points={
    'console_scripts': [
        'publisher = my_first_pkg.publisher:main',
    ],
},
```

### 6.6 编译运行

```bash
cd ~/ros2_ws
colcon build
source install/setup.bash
ros2 run my_first_pkg publisher
```

看到不断打印 `Publishing: "Hello ROS2: x"` 就成功了。

---

## ROS2 常用命令速查

| 命令 | 作用 |
|------|------|
| `ros2 topic list` | 查看所有话题 |
| `ros2 topic echo /topic` | 监听某个话题 |
| `ros2 node list` | 查看运行中的节点 |
| `ros2 run 包名 节点名` | 运行节点 |
| `ros2 launch 包名 launch文件` | 启动launch文件 |
| `colcon build` | 编译工作空间 |
| `source install/setup.bash` | 加载编译结果 |

---

## 常见问题

**Q：虚拟机很卡怎么办？**

1. 给虚拟机多分配内存（8GB以上）
2. 确认开了 3D 加速
3. 关掉 Windows 上不用的程序释放资源

**Q：Gazebo 打开黑屏？**

3D 加速没开好。在虚拟机设置 → 显示器 → 勾选**加速 3D 图形**，然后重启虚拟机。

**Q：`ros2 command not found`？**

环境变量没加载，运行：

```bash
source /opt/ros/humble/setup.bash
```

如果每次都要手动输，检查 `~/.bashrc` 最后一行有没有这句。

**Q：`colcon build` 报错？**

先安装依赖：

```bash
cd ~/ros2_ws
rosdep install --from-paths src --ignore-src -r -y
```

**Q：网络太慢下载不了？**

换清华源：

```bash
sudo sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
sudo apt update
```

ROS2 源也可以换中科大镜像：

```bash
sudo sed -i 's/packages.ros.org/mirrors.ustc.edu.cn\/ros2/g' /etc/apt/sources.list.d/ros2.list
sudo apt update
```
