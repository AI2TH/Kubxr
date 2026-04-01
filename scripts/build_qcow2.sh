#!/bin/bash
set -e

# This script builds the base.qcow2 image for the k8s node.
# It uses a temporary Docker container to perform the Alpine bootstrap.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ASSETS_DIR="${PROJECT_ROOT}/android/app/src/main/assets/vm"

mkdir -p "${ASSETS_DIR}"

echo "=== Building k8s Base Image (Alpine + k0s) ==="

# We use an x86_64 container but we will bootstrap an aarch64 rootfs
docker run --rm --privileged \
    -v "${PROJECT_ROOT}:/src" \
    -v "${ASSETS_DIR}:/out" \
    alpine:3.19 \
    sh -c "
apk add --no-cache qemu-img qemu-system-aarch64 bash e2fsprogs
bash /src/scripts/_build_rootfs.sh
"

echo "✅ VM Assets ready in: ${ASSETS_DIR}"
