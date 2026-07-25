#!/bin/bash
# Pack the cross-compiled ros2_java install tree into an Android AAR.
# Reused verbatim from the proven rcl_android_build pipeline.
set -euo pipefail

ROS2_ANDROID_WS="${ROS2_ANDROID_WS:-/opt/ros2_android_ws}"
AAR_TEMPLATE_DIR="${AAR_TEMPLATE_DIR:-/opt/aar_template}"
AAR_WORK_DIR="${AAR_WORK_DIR:-/opt/aar_work}"
AAR_OUT_DIR="${AAR_OUT_DIR:-/opt/output}"
ANDROID_ABI="${ANDROID_ABI:-arm64-v8a}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/android/sdk}"
ANDROID_NDK="${ANDROID_NDK:-/opt/android/sdk/ndk/25.2.9519653}"

echo "[AAR] preparing workspace"
rm -rf "${AAR_WORK_DIR}"
mkdir -p "${AAR_WORK_DIR}" "${AAR_OUT_DIR}"
cp -a "${AAR_TEMPLATE_DIR}/." "${AAR_WORK_DIR}/"

MODULE_DIR="${AAR_WORK_DIR}/ros2_android_aar"
mkdir -p "${MODULE_DIR}/libs"
mkdir -p "${MODULE_DIR}/src/main/jniLibs/${ANDROID_ABI}"
mkdir -p "${MODULE_DIR}/src/main/assets/ros2"

echo "[AAR] collecting jars"
find "${ROS2_ANDROID_WS}/install" -type f -path "*/share/*/java/*.jar" -exec cp -f {} "${MODULE_DIR}/libs/" \;

echo "[AAR] collecting shared libraries"
find "${ROS2_ANDROID_WS}/install" -type f -name "*.so" -exec cp -f {} "${MODULE_DIR}/src/main/jniLibs/${ANDROID_ABI}/" \;

if [ -f "${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" ]; then
  cp -f "${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" "${MODULE_DIR}/src/main/jniLibs/${ANDROID_ABI}/"
elif [ -f "${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ABI}/libc++_shared.so" ]; then
  cp -f "${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ABI}/libc++_shared.so" "${MODULE_DIR}/src/main/jniLibs/${ANDROID_ABI}/"
fi

echo "[AAR] collecting share resources"
if [ -d "${ROS2_ANDROID_WS}/install/share" ]; then
  cp -a "${ROS2_ANDROID_WS}/install/share" "${MODULE_DIR}/src/main/assets/ros2/"
fi

ROS_ACTIVITY_SRC="${ROS2_ANDROID_WS}/src/ros2-java/ros2_android/rclandroid/src/main/java/org/ros2/android/activity/ROSActivity.java"
if [ -f "${ROS_ACTIVITY_SRC}" ]; then
  mkdir -p "${MODULE_DIR}/src/main/java/org/ros2/android/activity"
  cp -f "${ROS_ACTIVITY_SRC}" "${MODULE_DIR}/src/main/java/org/ros2/android/activity/ROSActivity.java"
fi

cat > "${AAR_WORK_DIR}/local.properties" <<EOF
sdk.dir=${ANDROID_SDK_ROOT}
EOF

echo "[AAR] building"
cd "${AAR_WORK_DIR}"
gradle --no-daemon :ros2_android_aar:clean :ros2_android_aar:assembleRelease

AAR_SRC="${MODULE_DIR}/build/outputs/aar/ros2_android_aar-release.aar"
if [ ! -f "${AAR_SRC}" ]; then
  echo "[AAR] build failed: ${AAR_SRC} not found"
  exit 1
fi

cp -f "${AAR_SRC}" "${AAR_OUT_DIR}/ros2_java_android_humble_${ANDROID_ABI}_release.aar"

mkdir -p "${AAR_OUT_DIR}/jars" "${AAR_OUT_DIR}/jniLibs/${ANDROID_ABI}" "${AAR_OUT_DIR}/share"
cp -f "${MODULE_DIR}/libs/"*.jar "${AAR_OUT_DIR}/jars/" 2>/dev/null || true
cp -f "${MODULE_DIR}/src/main/jniLibs/${ANDROID_ABI}/"*.so "${AAR_OUT_DIR}/jniLibs/${ANDROID_ABI}/" 2>/dev/null || true
if [ -d "${MODULE_DIR}/src/main/assets/ros2/share" ]; then
  cp -a "${MODULE_DIR}/src/main/assets/ros2/share/." "${AAR_OUT_DIR}/share/"
fi

echo "[AAR] done: ${AAR_OUT_DIR}/ros2_java_android_humble_${ANDROID_ABI}_release.aar"
