#!/bin/bash
set -euo pipefail

KERNEL_REPO="https://github.com/microsoft/WSL2-Linux-Kernel.git"
ACTION="${1:-default}"

if [ ! -d "/workspace/.git" ]; then
    echo "Cloning WSL kernel repository..."
    git clone --depth 1 "$KERNEL_REPO" .
fi

case "$ACTION" in
    "default")
        echo "Building default configuration..."
        make KCONFIG_CONFIG=Microsoft/config-wsl -j$(nproc)
        cp arch/x86/boot/bzImage /out/bzImage
        echo "Output saved to out/bzImage"
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
        echo "Configuration saved to out/custom.config"
        ;;
    "custom")
        echo "Building from custom configuration..."
        if [ ! -f "/out/custom.config" ]; then
            echo "Error: custom.config missing. Run menuconfig first."
            exit 1
        fi
        cp /out/custom.config .config
        make -j$(nproc)
        cp arch/x86/boot/bzImage /out/bzImage
        echo "Output saved to out/bzImage"
        ;;
    *)
        echo "Error: Unrecognized action."
        exit 1
        ;;
esac