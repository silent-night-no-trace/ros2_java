# ROS 2 Java client library

**English** | [中文](README.zh-CN.md)

> **Origin:** This is a maintained fork of the (now inactive) upstream
> [`ros2-java/ros2_java`](https://github.com/ros2-java/ros2_java), retargeted
> from ROS 2 Galactic to **ROS 2 Humble** and augmented with a self-contained
> Docker build system (desktop + Android AAR, with CN mirror acceleration).
> This repository: <https://github.com/silent-night-no-trace/ros2_java>.
> See [What changed](#what-changed-vs-upstream) below.

### Build status

[![CI](https://github.com/silent-night-no-trace/ros2_java/actions/workflows/build_and_test.yml/badge.svg?branch=main)](https://github.com/silent-night-no-trace/ros2_java/actions/workflows/build_and_test.yml)

| Target | Build platform |
|---|---|
| Desktop (jars + host `.so`) | **ROS 2 Humble** · Ubuntu 22.04 Jammy · OpenJDK 11 |
| Android AAR (`arm64-v8a`) | **ROS 2 Humble** · Ubuntu 22.04 Jammy (container) · NDK 25.2 / API 31 / Fast-DDS 2.6.x |

> The badge reflects this fork's own CI
> ([`.github/workflows/build_and_test.yml`](.github/workflows/build_and_test.yml)),
> which builds both the desktop jars/`.so` and the Android AAR via the validated
> Docker path (`./docker/build.sh desktop|android` against official sources).
> Build artifacts are uploaded per run. The Docker build is also the recommended
> path for local builds. Pushing a `v*` tag publishes the Android AAR and a
> desktop bundle to [GitHub Releases](https://github.com/silent-night-no-trace/ros2_java/releases)
> (see [`.github/workflows/release.yml`](.github/workflows/release.yml)).

## Introduction

This is a set of projects (bindings, code generator, examples and more) that enables developers to write ROS 2
applications for the JVM and Android.

Besides this repository itself, there's also:
- https://github.com/ros2-java/ament_java, which adds support for Gradle to Ament
- https://github.com/ros2-java/ament_gradle_plugin, a Gradle plugin that makes it easier to use ROS 2 in Java and Android project. The Gradle plugin can be installed from Gradle Central https://plugins.gradle.org/plugin/org.ros2.tools.gradle
- https://github.com/ros2-java/ros2_java_examples, examples for the Java Runtime Environment
- https://github.com/ros2-java/ros2_android_examples, examples for Android

### Is this Java only?

No, any language that targets the JVM can be used to write ROS 2 applications.

### Including Android?

Yep! Use Fast-DDS as your DDS vendor (pinned to 2.6.x on this Humble fork).

### Features

The current set of features include:
- Generation of all builtin and complex ROS types, including arrays, strings, nested types, constants, etc.
- Support for publishers and subscriptions
- Tunable Quality of Service (e.g. lossy networks, reliable delivery, etc.)
- Clients and services
- Timers
- Composition (i.e. more than one node per process)
- Time handling (system and steady, ROS time not yet supported https://github.com/ros2-java/ros2_java/issues/122)
- Support for Android
- Parameters services and clients (both asynchronous and synchronous)

## Quick start with Docker (recommended)

This repository ships a self-contained Docker build that produces ready-to-use
ros2_java artifacts for ROS 2 Humble, with pluggable CN mirror acceleration
(`apt`/`pip`/`rosdistro`/ros2 apt/Android SDK/Gradle). It is the fastest and
only fully validated path for both desktop and Android on this Humble fork.

| Target | Command | Artifacts (`output/<target>/`) |
|---|---|---|
| Desktop (host arch, amd64) | `./docker/build.sh desktop` | `jars/`, `lib/*.so`, `share/` |
| Android AAR (arm64-v8a, API 31) | `./docker/build.sh android` | `*.aar`, `jars/`, `jniLibs/`, `share/` |

```bash
# Desktop: rcljava.jar + message jars + host .so
./docker/build.sh desktop

# Android: arm64-v8a AAR (NDK 25.2, Fast-DDS patches applied)
./docker/build.sh android

# Disable CN mirrors (use official sources)
USE_CN_MIRROR=0 ./docker/build.sh desktop

# Customize the set of desktop message packages
./docker/build.sh desktop \
  --build-arg BUILD_PACKAGES_UP_TO="rcljava std_msgs sensor_msgs"

# Force a clean rebuild
./docker/build.sh android --no-cache
```

The build layers your local checkout (with the Humble changes) on top of the
Humble source tree pinned by `docker/ros2_java_*_humble.repos` — i.e. it builds
**your modified source**, not upstream `main`. See [`docker/README.md`](docker/README.md)
for the full mirror list, Android patches, and offline options.

## Manual build (without Docker)

Prefer the Docker path above — it is the fully validated, continuously
tested flow on this Humble fork. The manual steps below are Humble-correct
recipes for **both desktop and Android**, each verified end-to-end on bare
metal (desktop: 16 packages, `BUILD_TESTING=OFF`; Android: 112 packages,
~56 MB AAR / 334 `.so`). They are not re-run in CI; Docker remains the
recommended path.

### Install dependencies

> Note: While the following instructions use a Linux shell the same can be done on other platforms like Windows with slightly adjusted commands.

1. [Install ROS 2](https://index.ros.org/doc/ros2/Installation).

1. Install Java and a JDK.

    This Humble fork builds with OpenJDK 11 and targets Java 8 bytecode
    (`-source/-target 1.8`), so the resulting jars run on JDK 8+.

    On Ubuntu, you can install OpenJDK 11 with:

        sudo apt install openjdk-11-jdk

1. Install Gradle.
Make sure you have Gradle 3.2 (or later) installed. (The Android Docker
build uses Gradle 7.6; for desktop, each jar package brings its own Gradle
wrapper via colcon-gradle.)

    *Ubuntu Bionic or later*

        sudo apt install gradle

    *macOS*

        brew install gradle

    Note: if run into compatibily issues between gradle 3.x and Java 9, try using Java 8,

        brew tap caskroom/versions
        brew cask install java8
        export JAVA_HOME=/Library/Java/JavaVirtualMachines/1.8.0.jdk/Contents/Home

    *Windows*

        choco install gradle

1. Install build tools (`rsync` is used by the overlay step below):

        sudo apt install curl python3-colcon-common-extensions python3-pip python3-vcstool rsync

1. Install Gradle extensions for colcon:

        python3 -m pip install -U git+https://github.com/colcon/colcon-gradle
        python3 -m pip install --no-deps -U git+https://github.com/colcon/colcon-ros-gradle

### Download and Build ROS 2 Java for Desktop

These steps mirror `docker/Dockerfile.desktop` so the result matches the
Docker build. Run them from the repo root and export it as `REPO` first
(the Android section reuses the same variable):

1. Source your ROS 2 Humble installation:

        export REPO=$(pwd)
        source /opt/ros/humble/setup.bash

1. Create a workspace and fetch the Humble source tree (this pulls
   `ros2-java/ros2_java@main` as a placeholder, which we overwrite next):

        mkdir -p ~/ros2_java_ws/src && cd ~/ros2_java_ws
        vcs import src < "$REPO/docker/ros2_java_humble.repos"

1. Overlay your local (Humble-patched) checkout on top of the placeholder,
   so the build uses your modified source, not upstream `main`. Exclude
   `.git`, `output/`, and prior build dirs so they don't pollute the
   workspace (Docker gets the same effect via `.dockerignore`):

        rm -rf src/ros2-java/ros2_java
        rsync -a --exclude='.git' --exclude='output' \
          --exclude='build' --exclude='install' --exclude='log' \
          "$REPO"/ src/ros2-java/ros2_java/

1. Initialize rosdep (first time only on a fresh machine — the Docker build
   does this inside the image). Behind the CN mirrors, repoint rosdistro to
   USTC first to avoid `raw.githubusercontent.com` timeouts during
   `rosdep update`:

        sudo rosdep init
        sudo sed -i 's|https://raw.githubusercontent.com/ros/rosdistro/master|https://mirrors.ustc.edu.cn/rosdistro|g' \
          /etc/ros/rosdep/sources.list.d/20-default.list
        rosdep update

1. Install ROS dependencies. `rosdep install` runs `sudo apt-get install`
   under the hood, so (like `rosdep init` above) it needs interactive or
   passwordless sudo. The skip-keys match the Docker build, plus
   `test_interface_files` — its apt package `ros-humble-test-interface-files`
   is only a test fixture and is not needed under `BUILD_TESTING=OFF`
   (verified: the full desktop build succeeds without it):

        rosdep install --from-paths src --ignore-src --rosdistro humble -y -r \
          -t build -t buildtool -t build_export -t buildtool_export -t exec \
          --skip-keys "ament_tools cyclonedds rcl_logging_log4cxx rcl_logging_spdlog rmw_connextdds rmw_connextdds_common rti_connext_dds_cmake_module rmw_cyclonedds_cpp iceoryx_binding_c test_interface_files"

1. Build the desktop package set (same default list as the Docker build):

        colcon build --symlink-install --packages-up-to \
          rcljava std_msgs std_srvs geometry_msgs nav_msgs sensor_msgs \
          --cmake-args -DBUILD_TESTING=OFF

   Adjust the `--packages-up-to` list to build more/fewer message packages.
   On Windows use `--merge-install` instead of `--symlink-install`.

After building, jars land in `install/<pkg>/share/java/*.jar` and the JNI
`.so` in `install/<pkg>/lib/`.


### Download and Build ROS 2 Java for Android

> Prefer the Docker path (`./docker/build.sh android`) — it is the fully
> validated, continuously tested flow. The manual recipe below is a
> Humble-correct cross-compile (NDK 25.2, `arm64-v8a`, API 31, Fast-DDS 2.6.x)
> that has been **verified end-to-end on bare metal**: 112 packages, producing
> a ~56 MB `ros2_java_android_humble_arm64-v8a_release.aar` (334 `.so`,
> including `libfastrtps.so`) that matches the Docker output. It is not run in
> CI; Docker remains the recommended path. The recipe mirrors
> [`docker/Dockerfile.android`](docker/Dockerfile.android) with user-local
> paths (no sudo for the toolchain); see [`docker/README.md`](docker/README.md)
> for the full pinned version table. Run from the repo root with
> `export REPO=$(pwd)` (as set in the desktop section) — several steps below
> reference `$REPO/docker/...`.

Target: `arm64-v8a`, Android API 31, NDK 25.2.9519653, build-tools 33.0.2,
CMake 3.22.1, Gradle 7.6, Fast-DDS 2.6.x. JDK 11 builds the jars; JDK 17 is
only needed to run `sdkmanager` (its bytecode target).

1. Install build dependencies (sudo):

        sudo apt install -y --no-install-recommends \
          curl wget unzip zip git rsync build-essential cmake ninja-build \
          libasio-dev libtinyxml2-dev openjdk-11-jdk openjdk-17-jdk \
          python3 python3-pip python3-vcstool python3-colcon-common-extensions \
          python3-rosdep python3-lark

1. Set up the Android SDK/NDK in a user-writable location (no sudo).
   `sdkmanager` runs under JDK 17; the build itself uses JDK 11.

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

1. Prepare the third-party sources Fast-DDS needs (Android toolchain does not
   search host `/usr/include`; TinyXML2 is forced to source mode). Use
   `codeload.github.com` tarballs (plain HTTPS, reachable even when github
   git is throttled):

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
        # vendor tarballs (the patches below point the vendor packages at these)
        wget -O $TP/google-benchmark.tar.gz https://codeload.github.com/google/benchmark/tar.gz/c05843a9f622db08ad59804c190f98879b76beba
        wget -O $TP/foonathan-memory.tar.gz https://codeload.github.com/eProsima/memory/tar.gz/vendor-1.4.1
        rm -rf /tmp/tx.tar.gz /tmp/txsrc /tmp/asio.tar.gz /tmp/asiosrc

1. Install Gradle 7.6 (CN mirror with official fallback):

        export GR=$HOME/gradle
        wget -O /tmp/g.zip https://mirrors.cloud.tencent.com/gradle/gradle-7.6-bin.zip || \
          wget -O /tmp/g.zip https://services.gradle.org/distributions/gradle-7.6-bin.zip
        unzip -q /tmp/g.zip -d $GR && rm /tmp/g.zip
        export PATH=$GR/gradle-7.6/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$JAVA_HOME/bin:$PATH

1. Install the colcon Gradle extensions:

        python3 -m pip install -U git+https://github.com/colcon/colcon-gradle
        python3 -m pip install --no-deps -U git+https://github.com/colcon/colcon-ros-gradle

1. Fetch the Humble Android source tree. `docker/fetch_sources.py` pulls
   codeload tarballs (works where github git is throttled); `vcs import`
   against `docker/ros2_java_android_humble.repos` works where git is reachable:

        export WS=$HOME/ros2_android_ws
        mkdir -p $WS/src
        python3 "$REPO/docker/fetch_sources.py" --repos "$REPO/docker/ros2_java_android_humble.repos" --src $WS/src

1. Overlay your local (Humble-patched) checkout on the placeholder:

        rm -rf $WS/src/ros2-java/ros2_java
        rsync -a --exclude='.git' --exclude='output' \
          --exclude='build' --exclude='install' --exclude='log' \
          "$REPO"/ $WS/src/ros2-java/ros2_java/

1. Apply the two Android patches (these mirror `Dockerfile.android`; the
   quoted heredocs keep `${...}` in the regexes intact). Patch 1 makes the
   rosidl Java generator emit only the `rosidl_typesupport_c` JNI variant on
   Android and drops the cross-package `*_JNI_LIBRARIES` link (fixes
   duplicate-JNI-symbol / `NULL jclass` crashes). Patch 2 points the vendor
   packages at the local tarballs and adapts Fast-DDS to Android (force
   `SECURITY`/`NO_TLS` off, guard OpenSSL, fix `FileWatch` `duration_cast`):

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

1. Temporarily unregister the host's `rosidl_generator_py` so the cross-build
   does not try to generate Python interfaces for the aarch64 target (which
   fails on the missing `aarch64-linux-gnu/python3.10/pyconfig.h`). This edits
   the system ROS install, so back it up and **restore it after the build**
   (step 13). Requires sudo:

        sudo bash -c '
        B=/opt/ros/humble/share/ament_index/resource_index
        for d in rosidl_generate_idl_interfaces rosidl_generate_interfaces rosidl_generator_packages; do
          [ -f "$B/$d/rosidl_generator_py" ] && [ ! -f "$B/$d/rosidl_generator_py.bak" ] && \
            mv "$B/$d/rosidl_generator_py" "$B/$d/rosidl_generator_py.bak"
        done'

1. Install ROS dependencies. `rosdep install` runs `sudo apt-get install`
   internally (needs interactive/passwordless sudo like `rosdep init`). The
   extra skip-keys (`benchmark clang-tidy clang-format python3-mypy
   python3-nose python3-lttng python3-babeltrace`) cover lint/test/tracing
   packages that the Docker build installs as root but are **not** needed under
   `BUILD_TESTING=OFF` (verified — the cross-build succeeds without them):

        source /opt/ros/humble/setup.bash
        cd $WS
        rosdep install --from-paths src --ignore-src --rosdistro humble -y -r \
          -t build -t buildtool -t build_export -t buildtool_export -t exec \
          --skip-keys "ament_tools cyclonedds rcl_logging_log4cxx rcl_logging_spdlog rmw_connextdds rmw_connextdds_common rti_connext_dds_cmake_module rmw_cyclonedds_cpp iceoryx_binding_c test_interface_files benchmark clang-tidy clang-format python3-mypy python3-nose python3-lttng python3-babeltrace"

1. Cross-compile (`--merge-install` is required by the AAR packager):

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

1. Package the AAR (the packager reads env vars for all paths, so it needs no
   edits; `AAR_TEMPLATE_DIR` points at the repo's template):

        export ROS2_ANDROID_WS=$WS
        export AAR_TEMPLATE_DIR=$REPO/docker/aar_template
        export AAR_WORK_DIR=$WS/aar_work
        export AAR_OUT_DIR=$WS/output
        bash $REPO/docker/build_android12_aar.sh
        # -> $WS/output/ros2_java_android_humble_arm64-v8a_release.aar (+ jars/, jniLibs/, share/)

1. Restore the host's `rosidl_generator_py` (undo step 9):

        sudo bash -c '
        B=/opt/ros/humble/share/ament_index/resource_index
        for d in rosidl_generate_idl_interfaces rosidl_generate_interfaces rosidl_generator_packages; do
          [ -f "$B/$d/rosidl_generator_py.bak" ] && [ ! -f "$B/$d/rosidl_generator_py" ] && \
            mv "$B/$d/rosidl_generator_py.bak" "$B/$d/rosidl_generator_py"
        done'

You can find more information about the Android examples at https://github.com/ros2-java/ros2_android_examples

## What changed vs upstream

Source-level changes relative to [`ros2-java/ros2_java`](https://github.com/ros2-java/ros2_java) `main`:

- **ROS 2 Galactic → Humble**: CI workflow `ubuntu-20.04` → `ubuntu-22.04`,
  `required-ros-distributions`/`target-ros2-distro` `galactic` → `humble`;
  README install snippets `source /opt/ros/galactic` → `humble`.
- **Java bytecode target 1.6 → 1.8**: `rcljava/CMakeLists.txt` and
  `rcljava_common/CMakeLists.txt` set `CMAKE_JAVA_COMPILE_FLAGS` to
  `-source/-target 1.8`, so jars build on JDK 11/17 and run on JDK 8+.
  C++/CMake/rosidl templates are otherwise unchanged.
- **New Docker build system** (under `docker/`): one-command
  builds for desktop and Android AAR, pinned to Humble source via
  `docker/ros2_java_*_humble.repos`, with pluggable CN mirrors and the
  Android Fast-DDS patches inlined. See [`docker/README.md`](docker/README.md).

The `.dockerignore` and `docker/` tree are new; everything else above is a
modification of existing upstream files.

## Contributing

Contributions are more than welcome!
If you'd like to contribute to the project, please read [CONTRIBUTING](CONTRIBUTING.md) for contributing guidelines.
