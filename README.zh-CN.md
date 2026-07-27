# ROS 2 Java 客户端库

[English](README.md) | **中文**

> **来源：** 本仓库是（已停更的）上游
> [`ros2-java/ros2_java`](https://github.com/ros2-java/ros2_java) 的维护性 fork，
> 从 ROS 2 Galactic 改造为 **ROS 2 Humble**，并增加了自包含的 Docker 构建系统
> （桌面 + Android AAR，可插拔国产加速镜像）。
> 本仓库地址：<https://github.com/silent-night-no-trace/ros2_java>。
> 与上游的差异见 [与上游的差异](#与上游的差异)。

### 构建状态

[![CI](https://github.com/silent-night-no-trace/ros2_java/actions/workflows/build_and_test.yml/badge.svg?branch=main)](https://github.com/silent-night-no-trace/ros2_java/actions/workflows/build_and_test.yml)

| 目标 | 构建平台 |
|---|---|
| 桌面（jar + 本机 `.so`） | **ROS 2 Humble** · Ubuntu 22.04 Jammy · OpenJDK 11 |
| Android AAR（`arm64-v8a`） | **ROS 2 Humble** · Ubuntu 22.04 Jammy（容器内） · NDK 25.2 / API 31 / Fast-DDS 2.6.x |

> 该徽章反映本 fork 自己的 CI
>（[`.github/workflows/build_and_test.yml`](.github/workflows/build_and_test.yml)），
> 经已验证的 Docker 路径（`./docker/build.sh desktop|android`，走官方源）构建
> 桌面 jar/`.so` 与 Android AAR。每次运行都会上传构建产物。本地构建同样推荐
> Docker 路径。

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

推荐上面的 Docker 路径——它是本 Humble fork 上完全验证、持续测试的流程。
下面的手动步骤是对 Humble 正确的**桌面与 Android** 配方，均在裸机端到端验证通过
（桌面：16 个包，`BUILD_TESTING=OFF`；Android：112 个包、约 56MB AAR / 334 个 `.so`）。
它们不在 CI 中复跑；Docker 仍是推荐路径。

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

1. 安装构建工具（`rsync` 用于下面的源码覆盖步骤）：

        sudo apt install curl python3-colcon-common-extensions python3-pip python3-vcstool rsync

1. 安装 colcon 的 Gradle 扩展：

        python3 -m pip install -U git+https://github.com/colcon/colcon-gradle
        python3 -m pip install --no-deps -U git+https://github.com/colcon/colcon-ros-gradle

### 下载并构建桌面版 ROS 2 Java

下列步骤镜像 `docker/Dockerfile.desktop`，结果与 Docker 构建一致。
请在仓库根目录执行，并先 `export REPO=$(pwd)`（下面的 Android 段复用该变量）：

1. source ROS 2 Humble 安装：

        export REPO=$(pwd)
        source /opt/ros/humble/setup.bash

1. 建工作区并拉取 Humble 源码树（其中 `ros2-java/ros2_java@main` 是占位，下一步覆盖）：

        mkdir -p ~/ros2_java_ws/src && cd ~/ros2_java_ws
        vcs import src < "$REPO/docker/ros2_java_humble.repos"

1. 用本地（Humble 改造过的）checkout 覆盖占位，使构建用你的源码而非上游 `main`。
   排除 `.git`、`output/` 及已有的 build 目录，避免污染工作区（Docker 靠
   `.dockerignore` 达到同样效果）：

        rm -rf src/ros2-java/ros2_java
        rsync -a --exclude='.git' --exclude='output' \
          --exclude='build' --exclude='install' --exclude='log' \
          "$REPO"/ src/ros2-java/ros2_java/

1. 初始化 rosdep（全新机器首次才需要——Docker 构建在镜像内已做）。
   国内镜像环境下，先把 rosdistro 指向 USTC，避免 `rosdep update` 拉
   `raw.githubusercontent.com` 超时：

        sudo rosdep init
        sudo sed -i 's|https://raw.githubusercontent.com/ros/rosdistro/master|https://mirrors.ustc.edu.cn/rosdistro|g' \
          /etc/ros/rosdep/sources.list.d/20-default.list
        rosdep update

1. 安装 ROS 依赖。`rosdep install` 内部会执行 `sudo apt-get install`，
   故与上面的 `rosdep init` 一样需要交互式或免密 sudo。skip-keys 与 Docker
   一致，另加 `test_interface_files`——其 apt 包
   `ros-humble-test-interface-files` 只是测试夹具，`BUILD_TESTING=OFF` 下用不到
   （已验证：跳过它桌面完整构建照常成功）：

        rosdep install --from-paths src --ignore-src --rosdistro humble -y -r \
          -t build -t buildtool -t build_export -t buildtool_export -t exec \
          --skip-keys "ament_tools cyclonedds rcl_logging_log4cxx rcl_logging_spdlog rmw_connextdds rmw_connextdds_common rti_connext_dds_cmake_module rmw_cyclonedds_cpp iceoryx_binding_c test_interface_files"

1. 构建桌面包集合（与 Docker 默认包列表一致）：

        colcon build --symlink-install --packages-up-to \
          rcljava std_msgs std_srvs geometry_msgs nav_msgs sensor_msgs \
          --cmake-args -DBUILD_TESTING=OFF

    调整 `--packages-up-to` 列表可构建更多/更少消息包。
    Windows 上用 `--merge-install` 代替 `--symlink-install`。

构建完成后，jar 在 `install/<pkg>/share/java/*.jar`，JNI `.so` 在 `install/<pkg>/lib/`。

### 下载并构建 Android 版 ROS 2 Java

> 推荐用 Docker 路径（`./docker/build.sh android`）——它是完全验证、持续
> 测试的流程。下面的手动配方是对 Humble 正确的交叉编译（NDK 25.2、
> `arm64-v8a`、API 31、Fast-DDS 2.6.x），**已在裸机端到端验证**：112 个包，
> 产出约 56MB 的 `ros2_java_android_humble_arm64-v8a_release.aar`（334 个
> `.so`，含 `libfastrtps.so`），与 Docker 产物一致。它不在 CI 中复跑；Docker
> 仍是推荐路径。配方镜像
> [`docker/Dockerfile.android`](docker/Dockerfile.android)，用用户级路径
> （工具链无需 sudo）；完整 pin 版本表见 [`docker/README.md`](docker/README.md)。
> 请在仓库根目录执行并 `export REPO=$(pwd)`（同桌面段）——下面多处引用
> `$REPO/docker/...`。

目标：`arm64-v8a`、Android API 31、NDK 25.2.9519653、build-tools 33.0.2、
CMake 3.22.1、Gradle 7.6、Fast-DDS 2.6.x。JDK 11 构建 jar；JDK 17 仅用于跑
`sdkmanager`（其字节码 target）。

1. 安装构建依赖（sudo）：

        sudo apt install -y --no-install-recommends \
          curl wget unzip zip git rsync build-essential cmake ninja-build \
          libasio-dev libtinyxml2-dev openjdk-11-jdk openjdk-17-jdk \
          python3 python3-pip python3-vcstool python3-colcon-common-extensions \
          python3-rosdep python3-lark

1. 在用户可写位置安装 Android SDK/NDK（无需 sudo）。`sdkmanager` 用 JDK 17
   跑；构建本身用 JDK 11。

        export ANDROID_SDK_ROOT=$HOME/android-sdk
        export ANDROID_HOME=$ANDROID_SDK_ROOT
        export ANDROID_NDK=$ANDROID_SDK_ROOT/ndk/25.2.9519653
        export JDK17=/usr/lib/jvm/java-17-openjdk-amd64
        export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
        mkdir -p $ANDROID_SDK_ROOT
        CT=https://mirrors.tuna.tsinghua.edu.cn/android/repository/commandlinetools-linux-11076708_latest.zip
        wget -O /tmp/ct.zip "$CT" || wget -O /tmp/ct.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
        mkdir -p $ANDROID_SDK_ROOT/cmdline-tools
        unzip -q /tmp/ct.zip -d $ANDROID_SDK_ROOT/cmdline-tools && rm /tmp/ct.zip
        [ -d $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools ] && \
          mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest
        yes | env JAVA_HOME=$JDK17 sdkmanager --sdk_root=$ANDROID_SDK_ROOT --licenses
        env JAVA_HOME=$JDK17 sdkmanager --sdk_root=$ANDROID_SDK_ROOT \
          "platform-tools" "platforms;android-31" "build-tools;33.0.2" "cmake;3.22.1" "ndk;25.2.9519653"

1. 准备 Fast-DDS 所需第三方源码（Android 工具链不搜宿主 `/usr/include`；
   TinyXML2 强制 source 模式）。用 `codeload.github.com` 的 tar 包（纯 HTTPS，
   即便 github git 被限速也能通）：

        export TP=$HOME/thirdparty
        mkdir -p $TP/tinyxml2 $TP/asio
        wget -O /tmp/tx.tar.gz https://codeload.github.com/leethomason/tinyxml2/tar.gz/8c8293ba8969a46947606a93ff0cb5a083aab47a
        mkdir -p /tmp/txsrc && tar -xzf /tmp/tx.tar.gz -C /tmp/txsrc
        TX=$(find /tmp/txsrc -name tinyxml2.cpp | head -1)
        cp "$(dirname "$TX")/tinyxml2.cpp" "$TP/tinyxml2/"; cp "$(dirname "$TX")/tinyxml2.h" "$TP/tinyxml2/"
        wget -O /tmp/asio.tar.gz https://codeload.github.com/chriskohlhoff/asio/tar.gz/refs/tags/asio-1-22-1
        mkdir -p /tmp/asiosrc && tar -xzf /tmp/asio.tar.gz -C /tmp/asiosrc
        AH=$(find /tmp/asiosrc -name asio.hpp | head -1)
        cp -a "$(dirname "$AH")/." "$TP/asio/"
        # vendor tar 包（下面的补丁把 vendor 包指向这些）
        wget -O $TP/google-benchmark.tar.gz https://codeload.github.com/google/benchmark/tar.gz/c05843a9f622db08ad59804c190f98879b76beba
        wget -O $TP/foonathan-memory.tar.gz https://codeload.github.com/eProsima/memory/tar.gz/vendor-1.4.1
        rm -rf /tmp/tx.tar.gz /tmp/txsrc /tmp/asio.tar.gz /tmp/asiosrc

1. 安装 Gradle 7.6（国产镜像 + 官方兜底）：

        export GR=$HOME/gradle
        wget -O /tmp/g.zip https://mirrors.cloud.tencent.com/gradle/gradle-7.6-bin.zip || \
          wget -O /tmp/g.zip https://services.gradle.org/distributions/gradle-7.6-bin.zip
        unzip -q /tmp/g.zip -d $GR && rm /tmp/g.zip
        export PATH=$GR/gradle-7.6/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$JAVA_HOME/bin:$PATH

1. 安装 colcon 的 Gradle 扩展：

        python3 -m pip install -U git+https://github.com/colcon/colcon-gradle
        python3 -m pip install --no-deps -U git+https://github.com/colcon/colcon-ros-gradle

1. 拉 Humble Android 源码树。`docker/fetch_sources.py` 走 codeload tar 包
   （github git 被限速时也能用）；git 可达时可用
   `vcs import` 配 `docker/ros2_java_android_humble.repos`：

        export WS=$HOME/ros2_android_ws
        mkdir -p $WS/src
        python3 "$REPO/docker/fetch_sources.py" --repos "$REPO/docker/ros2_java_android_humble.repos" --src $WS/src

1. 用本地（Humble 改造过的）checkout 覆盖占位：

        rm -rf $WS/src/ros2-java/ros2_java
        rsync -a --exclude='.git' --exclude='output' \
          --exclude='build' --exclude='install' --exclude='log' \
          "$REPO"/ $WS/src/ros2-java/ros2_java/

1. 应用两个 Android 补丁（镜像 `Dockerfile.android`；引号 heredoc 保证正则里的
   `${...}` 不被 shell 展开）。补丁 1：让 rosidl Java 生成器在 Android 上只生成
   `rosidl_typesupport_c` 一套 JNI 变体，并去掉跨包 `*_JNI_LIBRARIES` 的 link
   （修复同名 JNI 符号 / `NULL jclass` 崩溃）。补丁 2：把 vendor 包指向本地
   tar 包，并让 Fast-DDS 适配 Android（强制 `SECURITY`/`NO_TLS` 关、守 OpenSSL、
   修 `FileWatch` 的 `duration_cast`）：

        WS="$WS" TP="$TP" python3 - <<'PY'
        from pathlib import Path
        import re, os
        ws = Path(os.environ['WS']) / 'src'
        get_ts = ws / 'ros2-java/ros2_java/rosidl_generator_java/cmake/rosidl_generator_java_get_typesupports.cmake'
        t = get_ts.read_text(encoding='utf-8')
        if 'if(ANDROID)' not in t:
            t = t.replace(
                'list(APPEND ${TYPESUPPORT_IMPLS} "rosidl_typesupport_c")\n',
                'list(APPEND ${TYPESUPPORT_IMPLS} "rosidl_typesupport_c")\n\n  if(ANDROID)\n    set(${TYPESUPPORT_IMPLS} "rosidl_typesupport_c")\n  endif()\n', 1)
        get_ts.write_text(t, encoding='utf-8')
        gen = ws / 'ros2-java/ros2_java/rosidl_generator_java/cmake/rosidl_generator_java_generate_interfaces.cmake'
        t = gen.read_text(encoding='utf-8')
        t = re.sub(r'\n\s*target_link_libraries\(\$\{_library_name\} \$\{\$\{_pkg_name\}_JNI_LIBRARIES\}\)\s*\n', '\n', t)
        gen.write_text(t, encoding='utf-8')

        ws = Path(os.environ['WS']) / 'src'; tp = Path(os.environ['TP'])
        gb = ws / 'ament/google_benchmark_vendor/CMakeLists.txt'
        t = gb.read_text(encoding='utf-8')
        t = t.replace('GIT_REPOSITORY https://github.com/google/benchmark.git', f'URL file://{tp}/google-benchmark.tar.gz')
        t = t.replace('GIT_TAG c05843a9f622db08ad59804c190f98879b76beba  # v${GOOGLE_BENCHMARK_TARGET_VERSION}\n', '')
        t = t.replace('GIT_CONFIG advice.detachedHead=false\n', '')
        gb.write_text(t, encoding='utf-8')
        fm = ws / 'eProsima/foonathan_memory_vendor/CMakeLists.txt'
        t = fm.read_text(encoding='utf-8')
        t = t.replace('GIT_REPOSITORY https://github.com/eProsima/memory.git', f'URL file://{tp}/foonathan-memory.tar.gz')
        t = t.replace('GIT_TAG vendor-1.4.1\n', '')
        fm.write_text(t, encoding='utf-8')
        fastdds = ws / 'eProsima/Fast-DDS/CMakeLists.txt'
        t = fastdds.read_text(encoding='utf-8')
        t = re.sub(r'if\(SECURITY\)\n\s*find_package\(OpenSSL REQUIRED\)\nelse\(\)\n\s*find_package\(OpenSSL\)\nendif\(\)\n',
            'if(NOT ANDROID)\n    if(SECURITY)\n        find_package(OpenSSL REQUIRED)\n    else()\n        find_package(OpenSSL QUIET)\n    endif()\nelse()\n    set(OPENSSL_FOUND FALSE)\nendif()\n', t, count=1)
        t = re.sub(r'if\(SECURITY\)\n\s*find_package\(OpenSSL REQUIRED\)\nelseif\(NOT ANDROID\)\n\s*find_package\(OpenSSL QUIET\)\nendif\(\)\n',
            'if(NOT ANDROID)\n    if(SECURITY)\n        find_package(OpenSSL REQUIRED)\n    else()\n        find_package(OpenSSL QUIET)\n    endif()\nelse()\n    set(OPENSSL_FOUND FALSE)\nendif()\n', t, count=1)
        t = t.replace('option(NO_TLS "Disables TLS Support" OFF)\n',
            'option(NO_TLS "Disables TLS Support" OFF)\nif(ANDROID)\n    set(SECURITY OFF CACHE BOOL "Activate security" FORCE)\n    set(NO_TLS ON CACHE BOOL "Disables TLS Support" FORCE)\nendif()\n', 1)
        fastdds.write_text(t, encoding='utf-8')
        fw = ws / 'eProsima/Fast-DDS/thirdparty/filewatch/FileWatch.hpp'
        t = fw.read_text(encoding='utf-8')
        t = t.replace('                current_time += std::chrono::nanoseconds(result.st_mtim.tv_nsec);\n',
            '                current_time += std::chrono::duration_cast<std::chrono::system_clock::duration>(\n'
            '                    std::chrono::nanoseconds(result.st_mtim.tv_nsec));\n', 1)
        t = t.replace('            last_write_time_ += std::chrono::nanoseconds(result.st_mtim.tv_nsec);\n',
            '            last_write_time_ += std::chrono::duration_cast<std::chrono::system_clock::duration>(\n'
            '                std::chrono::nanoseconds(result.st_mtim.tv_nsec));\n', 1)
        fw.write_text(t, encoding='utf-8')
        PY

1. 临时注销宿主的 `rosidl_generator_py`，使交叉构建不为 aarch64 目标生成
   Python 接口（否则会因缺 `aarch64-linux-gnu/python3.10/pyconfig.h` 失败）。
   这会改系统 ROS 安装，故先备份，**构建后还原**（步骤 13）。需 sudo：

        sudo bash -c '
        B=/opt/ros/humble/share/ament_index/resource_index
        for d in rosidl_generate_idl_interfaces rosidl_generate_interfaces rosidl_generator_packages; do
          [ -f "$B/$d/rosidl_generator_py" ] && [ ! -f "$B/$d/rosidl_generator_py.bak" ] && \
            mv "$B/$d/rosidl_generator_py" "$B/$d/rosidl_generator_py.bak"
        done'

1. 安装 ROS 依赖。`rosdep install` 内部会执行 `sudo apt-get install`
   （与 `rosdep init` 一样需交互/免密 sudo）。额外的 skip-keys
   （`benchmark clang-tidy clang-format python3-mypy python3-nose python3-lttng
   python3-babeltrace`）覆盖 Docker 以 root 装的 lint/test/tracing 包，但
   `BUILD_TESTING=OFF` 下用不到（已验证——跳过它们交叉构建照常成功）：

        source /opt/ros/humble/setup.bash
        cd $WS
        rosdep install --from-paths src --ignore-src --rosdistro humble -y -r \
          -t build -t buildtool -t build_export -t buildtool_export -t exec \
          --skip-keys "ament_tools cyclonedds rcl_logging_log4cxx rcl_logging_spdlog rmw_connextdds rmw_connextdds_common rti_connext_dds_cmake_module rmw_cyclonedds_cpp iceoryx_binding_c test_interface_files benchmark clang-tidy clang-format python3-mypy python3-nose python3-lttng python3-babeltrace"

1. 交叉编译（AAR 打包器要求 `--merge-install`）：

        export PYTHON3_EXEC="$(which python3)"
        export PYTHON3_LIBRARY="$(python3 -c 'import os.path,sysconfig; print(os.path.realpath(os.path.join(sysconfig.get_config_var("LIBPL"), sysconfig.get_config_var("LDLIBRARY"))))')"
        export PYTHON3_INCLUDE_DIR="$(python3 -c 'import sysconfig; print(sysconfig.get_config_var("INCLUDEPY"))')"
        colcon build --merge-install \
          --packages-up-to rcljava std_msgs std_srvs geometry_msgs nav_msgs sensor_msgs \
          --packages-skip cyclonedds rcl_logging_log4cxx rcl_logging_spdlog rosidl_generator_py \
            rclandroid ros2_talker_android ros2_listener_android rcljava_examples ros2_java_examples \
          --cmake-args \
            -DPYTHON_EXECUTABLE=$PYTHON3_EXEC -DPYTHON_LIBRARY=$PYTHON3_LIBRARY -DPYTHON_INCLUDE_DIR=$PYTHON3_INCLUDE_DIR \
            -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
            -DANDROID=ON -DANDROID_FUNCTION_LEVEL_LINKING=OFF \
            -DANDROID_NATIVE_API_LEVEL=android-31 -DANDROID_STL=c++_shared \
            -DANDROID_ABI=arm64-v8a -DANDROID_NDK=$ANDROID_NDK \
            -DSECURITY=OFF -DNO_TLS=ON -DSQLITE3_SUPPORT=OFF -DSHM_TRANSPORT_DEFAULT=OFF \
            -DCOMPILE_TOOLS=OFF -DFOONATHAN_MEMORY_FORCE_VENDORED_BUILD=ON \
            -DTHIRDPARTY=ON -DTHIRDPARTY_UPDATE=OFF \
            -DAsio_INCLUDE_DIR=$TP/asio -DTINYXML2_SOURCE_DIR=$TP/tinyxml2 -DTINYXML2_INCLUDE_DIR=$TP/tinyxml2 \
            -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
            -DCOMPILE_EXAMPLES=OFF -DBUILD_TESTING=OFF \
            -DRCL_LOGGING_IMPLEMENTATION=rcl_logging_noop \
            -DCMAKE_FIND_ROOT_PATH="$WS/install"

1. 打包 AAR（打包器全部路径走环境变量，无需改脚本；`AAR_TEMPLATE_DIR`
   指向仓库模板）：

        export ROS2_ANDROID_WS=$WS
        export AAR_TEMPLATE_DIR=$REPO/docker/aar_template
        export AAR_WORK_DIR=$WS/aar_work
        export AAR_OUT_DIR=$WS/output
        bash $REPO/docker/build_android12_aar.sh
        # -> $WS/output/ros2_java_android_humble_arm64-v8a_release.aar (+ jars/, jniLibs/, share/)

1. 还原宿主的 `rosidl_generator_py`（撤销步骤 9）：

        sudo bash -c '
        B=/opt/ros/humble/share/ament_index/resource_index
        for d in rosidl_generate_idl_interfaces rosidl_generate_interfaces rosidl_generator_packages; do
          [ -f "$B/$d/rosidl_generator_py.bak" ] && [ ! -f "$B/$d/rosidl_generator_py" ] && \
            mv "$B/$d/rosidl_generator_py.bak" "$B/$d/rosidl_generator_py"
        done'

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
