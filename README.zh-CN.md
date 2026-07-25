# ROS 2 Java 客户端库

[English](README.md) | **中文**

> **来源：** 本仓库是（已停更的）上游
> [`ros2-java/ros2_java`](https://github.com/ros2-java/ros2_java) 的维护性 fork，
> 从 ROS 2 Galactic 改造为 **ROS 2 Humble**，并增加了自包含的 Docker 构建系统
> （桌面 + Android AAR，可插拔国产加速镜像）。
> 本仓库地址：<https://github.com/silent-night-no-trace/ros2_java>。
> 与上游的差异见 [与上游的差异](#与上游的差异)。

### 构建状态

| 目标 | 状态 |
|---|---|
| **ROS Humble - Ubuntu Jammy（OpenJDK）** | ![Build Status](https://github.com/ros2-java/ros2_java/workflows/CI/badge.svg?branch=main) |

> 该徽章反映的是上游 `ros2-java/ros2_java` 的 CI；本 fork 未配置 CI。
> Docker 构建是本仓库的已验证路径。

## 简介

这是一组项目（绑定、代码生成器、示例等），让开发者可以用 Java/JVM 以及 Android 编写 ROS 2 应用。

除本仓库外，还有：
- https://github.com/ros2-java/ament_java —— 为 Ament 增加 Gradle 支持
- https://github.com/ros2-java/ament_gradle_plugin —— 一个 Gradle 插件，便于在 Java/Android 项目中使用 ROS 2。可从 Gradle Central 安装：https://plugins.gradle.org/plugin/org.ros2.tools.gradle
- https://github.com/ros2-java/ros2_java_examples —— Java 运行时示例
- https://github.com/ros2-java/ros2_android_examples —— Android 示例

### 只能用 Java 吗？

不是，任何以 JVM 为目标的语言都可以用来写 ROS 2 应用。

### 包含 Android 吗？

是的！请使用 Fast-DDS 作为 DDS 供应商（Humble 上 pin 为 2.6.x）。

### 功能特性

当前功能集包括：
- 生成所有内建与复杂 ROS 类型（数组、字符串、嵌套类型、常量等）
- 发布者 / 订阅者
- 可调 QoS（丢包网络、可靠传输等）
- 客户端 / 服务
- 定时器
- 组合（单进程多节点）
- 时间处理（system 与 steady；ROS 时间暂不支持 https://github.com/ros2-java/ros2_java/issues/122）
- Android 支持
- 参数服务与客户端（同步与异步）

## Docker 快速开始（推荐）

本仓库自带一个自包含的 Docker 构建，产出 ROS 2 Humble 下即用的 ros2_java 产物，
带可插拔的国产加速镜像（`apt`/`pip`/`rosdistro`/ros2 apt/Android SDK/Gradle）。
这是本 Humble fork 上桌面与 Android 两端最快、也是唯一完全验证过的路径。

| 目标 | 命令 | 产物（`output/<target>/`） |
|---|---|---|
| 桌面（宿主架构 amd64） | `./docker/build.sh desktop` | `jars/`、`lib/*.so`、`share/` |
| Android AAR（arm64-v8a，API 31） | `./docker/build.sh android` | `*.aar`、`jars/`、`jniLibs/`、`share/` |

```bash
# 桌面：rcljava.jar + 各消息包 jar + 本机 .so
./docker/build.sh desktop

# Android：arm64-v8a AAR（NDK 25.2，已应用 Fast-DDS 补丁）
./docker/build.sh android

# 关闭国产镜像（用官方源）
USE_CN_MIRROR=0 ./docker/build.sh desktop

# 自定义要构建的桌面消息包
./docker/build.sh desktop \
  --build-arg BUILD_PACKAGES_UP_TO="rcljava std_msgs sensor_msgs"

# 强制全量重建
./docker/build.sh android --no-cache
```

构建会把本地 checkout（含 Humble 改动）覆盖在 `docker/ros2_java_*_humble.repos`
固定的 Humble 源码树之上——即**构建你修改过的源码**，而非上游 `main`。
完整的镜像列表、Android 补丁与离线方案见 [`docker/README.md`](docker/README.md)。

## 手动构建（无 Docker）

推荐上面的 Docker 路径——它是本 Humble fork 上唯一完全验证过的流程。
下面的手动步骤是与之等价、对 Humble 正确的桌面**参考流程**（可复现，但本仓库未持续测试）。
Android 的上游手动流程已过时，见该段末尾说明。

### 安装依赖

> 注：下列命令以 Linux shell 为例，Windows 上略作调整即可。

1. [安装 ROS 2](https://index.ros.org/doc/ros2/Installation)。

1. 安装 Java / JDK。

    本 Humble fork 用 OpenJDK 11 构建，字节码 target 为 Java 8
    （`-source/-target 1.8`），故产物 jar 可在 JDK 8+ 运行。

    Ubuntu 上安装 OpenJDK 11：

        sudo apt install openjdk-11-jdk

1. 安装 Gradle。
    需要 Gradle 3.2（或更高）。Android Docker 构建用 Gradle 7.6；
    桌面端各 jar 包通过 colcon-gradle 自带 Gradle wrapper。

    *Ubuntu Bionic 或更高*

        sudo apt install gradle

    *macOS*

        brew install gradle

    *Windows*

        choco install gradle

1. 安装构建工具：

        sudo apt install curl python3-colcon-common-extensions python3-pip python3-vcstool

1. 安装 colcon 的 Gradle 扩展：

        python3 -m pip install -U git+https://github.com/colcon/colcon-gradle
        python3 -m pip install --no-deps -U git+https://github.com/colcon/colcon-ros-gradle

### 下载并构建桌面版 ROS 2 Java

下列步骤镜像 `docker/Dockerfile.desktop`，结果与 Docker 构建一致。
`$REPO` 为本 fork 的本地 checkout 路径。

1. source ROS 2 Humble 安装：

        source /opt/ros/humble/setup.bash

1. 建工作区并拉取 Humble 源码树（其中 `ros2-java/ros2_java@main` 是占位，下一步覆盖）：

        mkdir -p ~/ros2_java_ws/src && cd ~/ros2_java_ws
        vcs import src < "$REPO/docker/ros2_java_humble.repos"

1. 用本地（Humble 改造过的）checkout 覆盖占位，使构建用你的源码而非上游 `main`：

        rm -rf src/ros2-java/ros2_java
        cp -r "$REPO" src/ros2-java/ros2_java

1. 安装 ROS 依赖（skip-keys 与 Docker 一致——不发布或在此构建不了的包）：

        rosdep install --from-paths src --ignore-src --rosdistro humble -y -r \
          -t build -t buildtool -t build_export -t buildtool_export -t exec \
          --skip-keys "ament_tools cyclonedds rcl_logging_log4cxx rcl_logging_spdlog rmw_connextdds rmw_connextdds_common rti_connext_dds_cmake_module rmw_cyclonedds_cpp iceoryx_binding_c"

1. 构建桌面包集合（与 Docker 默认包列表一致）：

        colcon build --symlink-install --packages-up-to \
          rcljava std_msgs std_srvs geometry_msgs nav_msgs sensor_msgs \
          --cmake-args -DBUILD_TESTING=OFF

    调整 `--packages-up-to` 列表可构建更多/更少消息包。
    Windows 上用 `--merge-install` 代替 `--symlink-install`。

构建完成后，jar 在 `install/<pkg>/share/java/*.jar`，JNI `.so` 在 `install/<pkg>/lib/`。

### 下载并构建 Android 版 ROS 2 Java

> **注：** 下面手动步骤是上游遗留参考（NDK 16b、`armeabi-v7a`、API 21、
> 旧的 `ros2_java_android.repos`）。Docker 路径（`./docker/build.sh android`）
> 才是已验证的现代流程：NDK 25.2、`arm64-v8a`、API 31，已应用 Fast-DDS Android 补丁。
> 除非需要自定义手动配置，否则请用 Docker。如需对 Humble 正确的手动 Android 构建，
> toolchain 参数、repos pin 与 Fast-DDS 补丁都在
> [`docker/Dockerfile.android`](docker/Dockerfile.android) 内联，可据其复刻。

Android 配置略复杂，需要安装 SDK 与 NDK，以及一台可运行示例的 Android 设备。

至少下载 Android Lollipop（或更高）的 SDK，示例至少要求 API level 21、NDK 14。

从[官方](https://developer.android.com/ndk/downloads/index.html)下载 Android NDK，假设下载 16b（2018-04-28 时最新稳定版）并解压到 `~/android_ndk`。

还需安装 [Android SDK](https://developer.android.com/studio/#downloads)，例如放在 `~/android_sdk`，并设 `ANDROID_HOME` 指向它。

`ros2_java_android.repos` 虽包含 Android 绑定编译所需的全部仓库，但需禁用其中某些包（`python_cmake_module`、`rosidl_generator_py`、`test_msgs`）——要么不需要、要么无法交叉编译（如 Python 生成器）。

1. 下载 [Android NDK](https://developer.android.com/ndk/downloads/index.html)，设 `ANDROID_NDK` 为其解压路径。

1. 下载 [Android SDK](https://developer.android.com/studio/#downloads)，设 `ANDROID_HOME` 为其解压路径。

1. 克隆 ROS 2 与 ROS 2 Java 源码：

        mkdir -p $HOME/ros2_android_ws/src
        cd $HOME/ros2_android_ws
        curl https://raw.githubusercontent.com/ros2-java/ros2_java/main/ros2_java_android.repos | vcs import src

1. 设置 Android 构建配置：

        export PYTHON3_EXEC="$( which python3 )"
        export PYTHON3_LIBRARY="$( ${PYTHON3_EXEC} -c 'import os.path; from distutils import sysconfig; print(os.path.realpath(os.path.join(sysconfig.get_config_var("LIBPL"), sysconfig.get_config_var("LDLIBRARY"))))' )"
        export PYTHON3_INCLUDE_DIR="$( ${PYTHON3_EXEC} -c 'from distutils import sysconfig; print(sysconfig.get_config_var("INCLUDEPY"))' )"
        export ANDROID_ABI=armeabi-v7a
        export ANDROID_NATIVE_API_LEVEL=android-21
        export ANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-clang

1. 构建（跳过不需要或无法交叉编译的包）：

        colcon build \
          --packages-ignore cyclonedds rcl_logging_log4cxx rosidl_generator_py \
          --packages-up-to rcljava \
          --cmake-args \
          -DPYTHON_EXECUTABLE=${PYTHON3_EXEC} \
          -DPYTHON_LIBRARY=${PYTHON3_LIBRARY} \
          -DPYTHON_INCLUDE_DIR=${PYTHON3_INCLUDE_DIR} \
          -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake \
          -DANDROID_FUNCTION_LEVEL_LINKING=OFF \
          -DANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL} \
          -DANDROID_TOOLCHAIN_NAME=${ANDROID_TOOLCHAIN_NAME} \
          -DANDROID_STL=c++_shared \
          -DANDROID_ABI=${ANDROID_ABI} \
          -DANDROID_NDK=${ANDROID_NDK} \
          -DTHIRDPARTY=ON \
          -DCOMPILE_EXAMPLES=OFF \
          -DCMAKE_FIND_ROOT_PATH="${PWD}/install"

更多 Android 示例信息见 https://github.com/ros2-java/ros2_android_examples

## 与上游的差异

相对 [`ros2-java/ros2_java`](https://github.com/ros2-java/ros2_java) `main` 的源码层改动：

- **ROS 2 Galactic → Humble**：CI 工作流 `ubuntu-20.04` → `ubuntu-22.04`，
  `required-ros-distributions`/`target-ros2-distro` `galactic` → `humble`；
  README 安装片段 `source /opt/ros/galactic` → `humble`。
- **Java 字节码 target 1.6 → 1.8**：`rcljava/CMakeLists.txt` 与
  `rcljava_common/CMakeLists.txt` 的 `CMAKE_JAVA_COMPILE_FLAGS` 改为
  `-source/-target 1.8`，使 jar 可用 JDK 11/17 构建、JDK 8+ 运行。
  C++/CMake/rosidl 模板未改动。
- **新增 Docker 构建系统**（`docker/` 下）：桌面与 Android AAR 一键构建，
  通过 `docker/ros2_java_*_humble.repos` 固定到 Humble 源码，带可插拔国产镜像
  与内联的 Android Fast-DDS 补丁。见 [`docker/README.md`](docker/README.md)。

`.dockerignore` 与 `docker/` 目录树是新增；其余均为对既有上游文件的修改。

## 贡献

欢迎贡献！如需参与，请阅读 [CONTRIBUTING](CONTRIBUTING.md) 了解贡献指南。
