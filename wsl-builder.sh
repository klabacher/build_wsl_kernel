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

mkdir -p "$WORKSPACE_DIR" "$OUT_DIR"

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
    
    if ! docker volume create ccache_vol &> /dev/null; then
        echo "Error: Failed to ensure ccache volume exists." >&2
        return 1
    fi

    if ! docker run --rm -it \
        -v "$WORKSPACE_DIR:/workspace:rw" \
        -v "$OUT_DIR:/out:rw" \
        -v ccache_vol:/root/.cache/ccache:rw \
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
    echo "3. Inject strict Waydroid configuration (Auto)"
    echo "4. Build custom kernel (Requires step 2 or 3)"
    echo "5. Make clean (Remove build artifacts)"
    echo "6. Clean workspace (Delete all sources and outputs)"
    echo "7. Exit"
    echo "------------------"
    printf "Select an option (1-7): "
}

validate_input() {
    local input="$1"
    if [[ ! "$input" =~ ^[1-7]$ ]]; then
        echo "Error: Invalid input. Expected a single digit between 1 and 7." >&2
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
        alpine sh -c 'rm -rf /workspace/* /workspace/.[!.]* /out/* /out/.[!.]* 2>/dev/null || true'; then
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
                run_container "inject-waydroid" || true
                read -r -p "Process finished. Press Enter to return to menu..."
                ;;
            4)
                run_container "custom" || true
                read -r -p "Process finished. Press Enter to return to menu..."
                ;;
            5)
                run_container "make-clean" || true
                read -r -p "Process finished. Press Enter to return to menu..."
                ;;
            6)
                clean_workspace
                read -r -p "Press Enter to return to menu..."
                ;;
            7)
                echo "Exiting."
                exit 0
                ;;
        esac
    done
}

main