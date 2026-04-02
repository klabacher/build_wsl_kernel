#!/bin/bash
set -euo pipefail

KERNEL_REPO="https://github.com/microsoft/WSL2-Linux-Kernel.git"
ACTION="${1:-default}"

if [[ ! "$ACTION" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Invalid action format."
    exit 1
fi

cd /workspace

if [ ! -d ".git" ]; then
    echo "Cloning WSL kernel repository..."
    TMP_CLONE_DIR=$(mktemp -d)
    git clone --depth 1 "$KERNEL_REPO" "$TMP_CLONE_DIR"
    tar -cf - -C "$TMP_CLONE_DIR" . | tar -xf - -C /workspace
    rm -rf "$TMP_CLONE_DIR"
fi

mkdir -p /out/modules

case "$ACTION" in
    "default")
        echo "Building default configuration and modules..."
        make KCONFIG_CONFIG=Microsoft/config-wsl -j"$(nproc)"
        make KCONFIG_CONFIG=Microsoft/config-wsl modules_install INSTALL_MOD_PATH=/out/modules
        tar -czf /out/modules.tar.gz -C /out/modules .
        cp arch/x86/boot/bzImage /out/bzImage
        echo "Output saved to /out/bzImage and /out/modules.tar.gz"
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
    "inject-waydroid")
        echo "Injecting strict Waydroid configurations..."
        if [ ! -x "./scripts/config" ]; then
            echo "Error: Configuration script missing or not executable."
            exit 1
        fi
        cp Microsoft/config-wsl .config
        ./scripts/config --enable CONFIG_ANDROID
        ./scripts/config --enable CONFIG_ANDROID_BINDER_IPC
        ./scripts/config --enable CONFIG_ANDROID_BINDERFS
        ./scripts/config --enable CONFIG_BRIDGE
        ./scripts/config --enable CONFIG_NETFILTER
        ./scripts/config --enable CONFIG_IP_NF_IPTABLES
        ./scripts/config --enable CONFIG_IP_NF_NAT
        ./scripts/config --enable CONFIG_VETH
        ./scripts/config --enable CONFIG_PSI
        make olddefconfig
        cp .config /out/custom.config
        echo "Waydroid configuration injected and saved to /out/custom.config"
        ;;
    "custom")
        echo "Building from custom configuration and modules..."
        if [ ! -f "/out/custom.config" ]; then
            echo "Error: custom.config missing. Run menuconfig or inject-waydroid first."
            exit 1
        fi
        cp /out/custom.config .config
        make -j"$(nproc)"
        make modules_install INSTALL_MOD_PATH=/out/modules
        tar -czf /out/modules.tar.gz -C /out/modules .
        cp arch/x86/boot/bzImage /out/bzImage
        echo "Output saved to /out/bzImage and /out/modules.tar.gz"
        ;;
    *)
        echo "Error: Unrecognized action."
        exit 1
        ;;
esac