#!/usr/bin/env bash
set -euo pipefail

BUILDER_ROOT="${HOME}/.ailang/builders/qemu"

IMAGE_NAME="ubuntu-24.04-server-cloudimg-arm64.img"
IMAGE_URL="https://cloud-images.ubuntu.com/releases/24.04/release/${IMAGE_NAME}"

BASE_IMAGE="${BUILDER_ROOT}/${IMAGE_NAME}"
DISK_IMAGE="${BUILDER_ROOT}/builder.qcow2"

mkdir -p "${BUILDER_ROOT}"

#
# Verify tools
#

require() {
    command -v "$1" >/dev/null 2>&1 || {
        echo
        echo "Missing dependency: $1"
        echo

        case "$1" in
            qemu-system-aarch64|qemu-img)
                echo "Install with:"
                echo
                echo "    brew install qemu"
                ;;
        esac

        exit 1
    }
}

require qemu-system-aarch64
require qemu-img

#
# Download Ubuntu image
#

if [[ ! -f "${BASE_IMAGE}" ]]; then
    echo "Downloading Ubuntu ARM64 cloud image..."
    curl -L "${IMAGE_URL}" -o "${BASE_IMAGE}"
fi

#
# Create writable VM disk
#

if [[ ! -f "${DISK_IMAGE}" ]]; then
    echo "Creating builder disk..."
    qemu-img create \
        -f qcow2 \
        -F qcow2 \
        -b "${BASE_IMAGE}" \
        "${DISK_IMAGE}" \
        40G
fi

#
# Boot VM
#

echo
echo "Starting AiLang Builder..."
echo

exec qemu-system-aarch64 \
    -machine virt,highmem=on \
    -accel hvf \
    -cpu host \
    -smp 4 \
    -m 8192 \
    -bios edk2-aarch64-code.fd \
    -drive if=virtio,file="${DISK_IMAGE}",format=qcow2 \
    -device virtio-net-pci \
    -netdev user,id=net0 \
    -device virtio-rng-pci \
    -serial mon:stdio