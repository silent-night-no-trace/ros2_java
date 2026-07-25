#!/usr/bin/env bash
# Build ros2_java for ROS 2 Humble in Docker, with CN mirrors.
#
# Usage:
#   ./docker/build.sh desktop   # -> output/desktop/ : jars + lib/*.so + share
#   ./docker/build.sh android   # -> output/android/ : *.aar + jars + jniLibs + share
#   ./docker/build.sh desktop --no-cache
#   ./docker/build.sh desktop --build-arg BUILD_PACKAGES_UP_TO="rcljava std_msgs"
#
# Env overrides (optional):
#   USE_CN_MIRROR=0        disable CN mirrors (use official sources)
#   ANDROID_ABI=arm64-v8a  android target ABI
#   ANDROID_API=31         android API level
set -euo pipefail

TARGET="${1:-}"
shift || true

if [ "${TARGET}" != "desktop" ] && [ "${TARGET}" != "android" ]; then
  echo "Usage: $0 <desktop|android> [extra docker build args]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCKERFILE="${SCRIPT_DIR}/Dockerfile.${TARGET}"
OUT_DIR="${REPO_ROOT}/output/${TARGET}"

[ -f "${DOCKERFILE}" ] || { echo "Dockerfile not found: ${DOCKERFILE}" >&2; exit 1; }

export DOCKER_BUILDKIT=1
IMAGE_TAG="ros2_java-humble-${TARGET}:local"
BUILD_ARGS=(
  --build-arg "USE_CN_MIRROR=${USE_CN_MIRROR:-1}"
  --build-arg "ANDROID_ABI=${ANDROID_ABI:-arm64-v8a}"
  --build-arg "ANDROID_API=${ANDROID_API:-31}"
)

echo "==> Building ${IMAGE_TAG}"
echo "==> Context: ${REPO_ROOT}"
echo "==> Output : ${OUT_DIR}"
echo

docker build \
  -f "${DOCKERFILE}" \
  -t "${IMAGE_TAG}" \
  "${BUILD_ARGS[@]}" "$@" \
  "${REPO_ROOT}"

# Extract /output from the (scratch) final stage into the host OUT_DIR.
# scratch 镜像无 CMD/ENTRYPOINT，`docker create` 不带命令会报 "no command specified"，
# 故显式给一个占位命令 /bin/sh（create 不会执行它，cp 也不需要它存在）。
rm -rf "${OUT_DIR}"; mkdir -p "${OUT_DIR}"
CID="$(docker create "${IMAGE_TAG}" /bin/sh)"
trap 'docker rm "${CID}" >/dev/null 2>&1 || true' EXIT
docker cp "${CID}:/output/." "${OUT_DIR}/"

echo
echo "==> Done. Artifacts in: ${OUT_DIR}"
ls -lhR "${OUT_DIR}" | head -60 || true
