#!/bin/bash
set -euo pipefail

trap 'echo -e "\nProcess interrupted. Exiting gracefully."; exit 130' SIGINT SIGTERM

IMAGE_NAME="wsl-kernel-builder"
WORKSPACE_DIR="$(pwd)/workspace"
OUT_DIR="$(pwd)/out"

if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed or not in PATH." >&2
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "Error: docker daemon is not running or accessible." >&2
    exit 1
fi

if ! mkdir -p "$WORKSPACE_DIR" "$OUT_DIR"; then
    echo "Error: Failed to create required directories." >&2
    exit 1
fi

build_image() {
    clear
    echo "Preparing build environment..."
    if [ ! -f "Dockerfile" ]; then
        echo "Error: Dockerfile not found in the current directory." >&2
        exit 1
    fi
    if ! docker build -q -t "$IMAGE_NAME" . > /dev/null; then
        echo "Error: Failed to build Docker image." >&2
        exit 1
    fi
}

run_container() {
    local cmd="$1"
    if ! docker run --rm -it \
        -v "$WORKSPACE_DIR:/workspace:rw" \
        -v "$OUT_DIR:/out:rw" \
        "$IMAGE_NAME" "$cmd"; then
        echo "Error: Container execution failed for command '$cmd'." >&2
        return 1
    fi
    return 0
}

show_menu() {
    clear
    echo "WSL Kernel Builder"
    echo "------------------"
    echo "1. Build default kernel"
    echo "2. Run menuconfig (Customize features)"
    echo "3. Build custom kernel (Requires step 2)"
    echo "4. Make clean (Remove build artifacts)"
    echo "5. Clean workspace (Delete all sources and outputs)"
    echo "6. Exit"
    echo "------------------"
    printf "Select an option (1-6): "
}

validate_input() {
    local input="$1"
    if [[ ! "$input" =~ ^[1-6]$ ]]; then
        echo "Error: Invalid input. Expected a single digit between 1 and 6." >&2
        sleep 2
        return 1
    fi
    return 0
}

clean_workspace() {
    echo "Cleaning directories..."
    if docker run --rm \
        -v "$WORKSPACE_DIR:/workspace:rw" \
        -v "$OUT_DIR:/out:rw" \
        alpine sh -c 'su -c "rm -rf /workspace/* /workspace/.[!.]* /out/* /out/.[!.]*" 2>/dev/null || true'; then
        echo "Clean complete."
    else
        echo "Error: Failed to clean directories." >&2
    fi
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
                run_container "default" || true
                read -r -p "Process finished. Press Enter to return to menu..."
                ;;
            2)
                run_container "menuconfig" || true
                ;;
            3)
                run_container "custom" || true
                read -r -p "Process finished. Press Enter to return to menu..."
                ;;
            4)
                run_container "make-clean" || true
                read -r -p "Process finished. Press Enter to return to menu..."
                ;;
            5)
                clean_workspace
                read -r -p "Press Enter to return to menu..."
                ;;
            6)
                echo "Exiting."
                exit 0
                ;;
        esac
    done
}

main