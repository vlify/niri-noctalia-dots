#!/usr/bin/env bash
set -euo pipefail

# niri-noctalia-dots install script
DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET_WALLPAPER_DIR="${HOME}/Pictures/Wallpapers"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
    esac
done

echo "==> Deploying niri-noctalia-dots..."
echo "    Source: ${DOTS_DIR}"
echo "    Target: ${TARGET_CONFIG_DIR}"

if [ "$DRY_RUN" = true ]; then
    echo "==> [DRY RUN] No files will be modified."
fi

# Ensure base directories exist
mkdir -p "${TARGET_CONFIG_DIR}" "${TARGET_WALLPAPER_DIR}"

# Deploy configuration directories
CONFIG_MODULES=("niri" "noctalia" "alacritty")

for module in "${CONFIG_MODULES[@]}"; do
    src="${DOTS_DIR}/.config/${module}"
    dest="${TARGET_CONFIG_DIR}/${module}"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "    [Dry-run] Would backup $dest to ${dest}.bak.${TIMESTAMP}"
        else
            echo "    Backing up existing $dest -> ${dest}.bak.${TIMESTAMP}"
            mv "$dest" "${dest}.bak.${TIMESTAMP}"
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "    [Dry-run] Would link $src -> $dest"
    else
        echo "    Linking $src -> $dest"
        ln -sfn "$src" "$dest"
    fi
done

# Deploy default wallpaper
if [ -f "${DOTS_DIR}/assets/wallpaper.png" ]; then
    wp_dest="${TARGET_WALLPAPER_DIR}/default.png"
    if [ ! -f "$wp_dest" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "    [Dry-run] Would copy default wallpaper to $wp_dest"
        else
            echo "    Installing default wallpaper -> $wp_dest"
            cp "${DOTS_DIR}/assets/wallpaper.png" "$wp_dest"
        fi
    fi
fi

echo ""
echo "==> Installation complete!"
echo "    Restart niri or run: niri msg action reload-config"
echo "    Start noctalia with: systemctl --user start noctalia (or launch via niri config)"
