# ros2_java + ROS 2 Humble Docker 构建

在服务器上用 Docker 一键构建改造成 Humble 的 ros2_java，全程国产加速镜像。
支持两种产物：

| 目标 | 命令 | 产物（`output/<target>/`） |
|---|---|---|
| Desktop（服务器本机架构 amd64） | `./build.sh desktop` | `jars/`、`lib/*.so`、`share/` |
| Android AAR（arm64-v8a） | `./build.sh android` | `*.aar`、`jars/`、`jniLibs/`、`share/` |

## 前置

- 服务器装有 Docker（建议 20.10+，默认 BuildKit）。
- 能访问外网；首次构建需联网拉取 ROS2 humble 源码、Android SDK/NDK、Gradle、第三方库。
- 服务器为 x86_64 Linux（`ros:humble-ros-base-jammy` 基础镜像要求）。

## 软件版本一览

构建里实际 pin 的版本（Humble）：

| 组件 | 版本 | 来源 |
|---|---|---|
| ROS 2 | Humble | 基础镜像 `ros:humble-ros-base-jammy` + `.repos` pin `humble` 分支 |
| 基础镜像 / Ubuntu | 22.04 Jammy | `ros:humble-ros-base-jammy` |
| Java（构建） | OpenJDK 11 | `openjdk-11-jdk`，`JAVA_HOME=java-11-openjdk-amd64` |
| Java 字节码 target | `-source/-target 1.8` | `rcljava` / `rcljava_common` 的 `CMAKE_JAVA_COMPILE_FLAGS` |
| colcon-gradle | `main`（最新） | codeload `colcon/colcon-gradle@main` |
| colcon-ros-gradle | `main`（最新） | codeload `colcon/colcon-ros-gradle@main` |
| Android NDK | 25.2.9519653 | `ARG ANDROID_NDK_VERSION` |
| Android API | 31 | `ARG ANDROID_API` |
| Android ABI | arm64-v8a | `ARG ANDROID_ABI` |
| cmdline-tools | 11076708 | `ARG CMDLINE_TOOLS_VERSION` |
| build-tools | 33.0.2 | sdkmanager |
| Android cmake | 3.22.1 | sdkmanager |
| Gradle（AAR 打包） | 7.6 | `ARG GRADLE_VERSION` |
| Fast-DDS | 2.6.x | `ros2_java_android_humble.repos` pin `2.6.x` |
| JDK（sdkmanager 运行时） | 17 | `openjdk-17-jdk`（仅 android 镜像，供 sdkmanager 用） |

> 桌面端 Java 字节码 target 为 1.8，故产物 jar 可在 JDK 8 及以上运行；
> 构建期用 JDK 11。Android AAR 的 `jniLibs` 仅含 `arm64-v8a` 一套 ABI，
> 如需 `armeabi-v7a` 等其它 ABI，改 `ANDROID_ABI` 并视情况调整 NDK/补丁。

## 用法

```bash
cd /path/to/ros2_java

# Desktop：产出 rcljava.jar + 各消息包 jar + 本机 .so
./docker/build.sh desktop

# Android：产出 arm64-v8a AAR
./docker/build.sh android

# 关闭国产镜像（用官方源）
USE_CN_MIRROR=0 ./docker/build.sh desktop

# 自定义要构建的桌面消息包
./docker/build.sh desktop \
  --build-arg BUILD_PACKAGES_UP_TO="rcljava std_msgs sensor_msgs"

# Android 自定义 ABI / API
ANDROID_ABI=arm64-v8a ANDROID_API=31 ./docker/build.sh android

# 强制全量重建
./docker/build.sh android --no-cache
```

产物默认输出到仓库下的 `output/<target>/`。

## 构建结果参考（Humble，已验证）

| 目标 | colcon 包数 | 产物 | 典型耗时 |
|---|---|---|---|
| Desktop | 16 | `jars/` 14、`lib/` 56 个 .so、`share/` 18 个包目录 | 缓存命中时仅重跑 colcon/收集层 |
| Android | 112 | `ros2_java_android_humble_arm64-v8a_release.aar`（约 56MB）、`jniLibs/arm64-v8a/`（约 334 个 .so，含 libfastrtps.so）、`share/` 117 个包目录 | 约 6 分钟 colcon + 1 分钟 Gradle |

Desktop 默认包列表：`rcljava std_msgs std_srvs geometry_msgs nav_msgs sensor_msgs`
（可通过 `--build-arg BUILD_PACKAGES_UP_TO=...` 增减）。
Android 交叉编译包含 Fast-DDS（fastrtps）、`rmw_fastrtps_*`、`rcl`、`rcljava` 全套。

## 缓存友好

`.dockerignore` 排除了 `output/`、`build.log`、`.git/`、`.github/`、`*.md`
以及频繁改动的 `docker/Dockerfile.*` 与 `docker/build.sh`，使得
`COPY . ${ROS2_WS}/src/ros2-java/ros2_java` 在你迭代 Dockerfile 时保持缓存稳定
——改动 build 脚本不会作废前面的 apt-deps/rosdep 层。
桌面 `BUILD_PACKAGES_UP_TO` 这个 `ARG` 也特意声明在 colcon RUN 紧邻处，
改包列表只作废 colcon/收集层，不影响前置依赖层。

> 注意：`docker/fetch_sources.py` 和 `docker/*.repos` 必须留在构建上下文里
> （被显式 `COPY docker/...` 引用），故 `.dockerignore` 只逐文件排除易变项，
> 不整体排除 `docker/` 目录。

## 国产镜像一览

| 资源 | 镜像 |
|---|---|
| apt (ubuntu) | `mirrors.tuna.tsinghua.edu.cn` |
| apt (ros2) | `mirrors.ustc.edu.cn/ros2/ubuntu` |
| pip | `pypi.tuna.tsinghua.edu.cn` |
| rosdistro | `mirrors.ustc.edu.cn/rosdistro` |
| Android SDK/NDK 仓库 | `mirrors.tuna.tsinghua.edu.cn/android/repository` |
| Gradle 分发 | `mirrors.cloud.tencent.com/gradle` |
| Gradle/Maven 依赖（AAR） | `maven.aliyun.com` |

源码与第三方（GitHub codeload）仍走 github.com；若服务器无法直连 GitHub，
建议挂代理（`HTTPS_PROXY`）或预先准备离线包（见下）。

## 构建的是哪个 ros2_java？

`COPY .` 会把仓库当前 checkout（含你对 Humble 的改动）覆盖到工作区 `src/ros2-java/ros2_java`，
即**构建你本地改过的源码**，而非上游 main。其余 ROS2 包按 `ros2_java_*_humble.repos`
固定到 humble 分支。

## Android 补丁说明

`Dockerfile.android` 内联了已在产线 AAR 验证的补丁（与 `rcl_android_build` 一致）：

1. `rosidl_generator_java` Android 仅生成 `rosidl_typesupport_c` 一套 message JNI，
   并取消对依赖包 `*_JNI_LIBRARIES` 的 link —— 修复 Android 上同名 JNI 符号 +
   DT_NEEDED 预加载导致的 `NULL jclass` 崩溃。
2. Fast-DDS：Android 关闭 OpenSSL/TLS/Security、`FileWatch.hpp` `duration_cast` 修复。
3. `google_benchmark_vendor` / `foonathan_memory_vendor` 改为本地 tar 包，避免构建期 git clone。

## 离线包（可选）

若服务器不能联网，可把预先下载的压缩包挂载进容器，替换网络拉取步骤。
基础镜像 `ros:humble-ros-base-jammy` 仍需能 pull 到（或本地导入）。

## 与上游 ros2_java 的差异（源码层）

见仓库根目录改动：CI 切到 humble/22.04、README 安装源切到 humble、
`rcljava` 与 `rcljava_common` 的 Java 字节码 `-source/-target` 从 1.6 升到 1.8
（兼容 JDK 11/17）。C++/Java/rosidl 模板零改动。
