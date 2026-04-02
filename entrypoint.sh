#!/bin/bash
set -euo pipefail

KERNEL_REPO="https://github.com/microsoft/WSL2-Linux-Kernel.git"
ACTION="${1:-default}"

if [[ ! "$ACTION" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Invalid action format."
    exit 1
fi

if [ ! -d "/workspace/.git" ]; then
    echo "Cloning WSL kernel repository..."
    git clone --depth 1 "$KERNEL_REPO" .
fi

mkdir -p /out/modules

case "$ACTION" in
    "default")
        echo "Building default configuration and modules..."
        make KCONFIG_CONFIG=Microsoft/config-wsl -j"$(nproc)"
        make KCONFIG_CONFIG=Microsoft/config-wsl modules_install INSTALL_MOD_PATH=/out/modules
        cp arch/x86/boot/bzImage /out/bzImage
        echo "Output saved to /out/bzImage and /out/modules"
        ;;
    "make-clean")
        echo "Cleaning build artifacts..."
        make clean
        rm -rf /out/modules
        mkdir -p /out/modules
        echo "Build artifacts cleaned."
        ;;
    "menuconfig")
        echo "Launching menuconfig..."
        if [ -f "/out/custom.config" ]; then
            cp /out/custom.config .config
        else
            cp Microsoft/config-wsl .config
        fi
        make menuconfig
        cp .config /out/custom.config
        echo "Configuration saved to /out/custom.config"
        ;;
    "custom")
        echo "Building from custom configuration and modules..."
        if [ ! -f "/out/custom.config" ]; then
            echo "Error: custom.config missing. Run menuconfig first."
            exit 1
        fi
        cp /out/custom.config .config
        make -j"$(nproc)"
        make modules_install INSTALL_MOD_PATH=/out/modules
        cp arch/x86/boot/bzImage /out/bzImage
        echo "Output saved to /out/bzImage and /out/modules"
        ;;
    *)
        echo "Error: Unrecognized action."
        exit 1
        ;;
esac