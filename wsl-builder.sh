#!/bin/bash
set -euo pipefail

IMAGE_NAME="wsl-kernel-builder"
WORKSPACE_DIR="$(pwd)/workspace"
OUT_DIR="$(pwd)/out"

mkdir -p "$WORKSPACE_DIR" "$OUT_DIR"

build_image() {
    clear
    echo "Preparing build environment..."
    docker build -q -t "$IMAGE_NAME" . > /dev/null
}

run_container() {
    local cmd="$1"
    docker run --rm -it \
        -v "$WORKSPACE_DIR:/workspace" \
        -v "$OUT_DIR:/out" \
        "$IMAGE_NAME" "$cmd"
}

show_menu() {
    clear
    echo "WSL Kernel Builder"
    echo "------------------"
    echo "1. Build default kernel"
    echo "2. Run menuconfig (Customize features)"
    echo "3. Build custom kernel (Requires step 2)"
    echo "4. Clean workspace"
    echo "5. Exit"
    echo "------------------"
    echo "Select an option (1-5): "
}

validate_input() {
    local input="$1"
    if [[ ! "$input" =~ ^[1-5]$ ]]; then
        echo "Error: Invalid input. Expected digit between 1 and 5."
        sleep 2
        return 1
    fi
    return 0
}

main() {
    build_image
    while true; do
        show_menu
        read -r choice
        
        if ! validate_input "$choice"; then
            continue
        fi

        case "$choice" in
            1)
                run_container "default"
                read -p "Process finished. Press Enter to return to menu..."
                ;;
            2)
                run_container "menuconfig"
                ;;
            3)
                run_container "custom"
                read -p "Process finished. Press Enter to return to menu..."
                ;;
            4)
                echo "Cleaning directories..."
                rm -rf "${WORKSPACE_DIR:?}"/* "${OUT_DIR:?}"/*
                echo "Clean complete."
                read -p "Press Enter to return to menu..."
                ;;
            5)
                echo "Exiting."
                exit 0
                ;;
        esac
    done
}

main