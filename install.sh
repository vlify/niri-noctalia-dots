#!/usr/bin/env bash
set -euo pipefail

DOTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
MODE=check
YES=false

usage() {
    cat <<'EOF'
Usage: ./install.sh [--check | --dry-run | --apply [--yes]]

  --check    Report detected applications and deployment paths (default)
  --dry-run  Preview files and generated configuration without writing anything
  --apply    Back up conflicting files and deploy the configuration
  --yes      Skip confirmation; requires --apply
  --help     Show this help

No packages are installed and no system files or GUI preferences are modified.
EOF
}
while (($#)); do
    case "$1" in
        --check) MODE=check ;;
        --dry-run) MODE=dry-run ;;
        --apply) MODE=apply ;;
        --yes) YES=true ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done
if [[ "$YES" == true && "$MODE" != apply ]]; then
    echo '--yes requires --apply' >&2
    exit 2
fi
for base in "$TARGET_CONFIG_DIR" "$TARGET_DATA_DIR"; do
    [[ "$base" == /* ]] || { printf 'XDG paths must be absolute: %s\n' "$base" >&2; exit 2; }
done

command_path() {
    local candidate
    for candidate in "$@"; do
        if command -v "$candidate" >/dev/null 2>&1; then
            command -v "$candidate"
            return 0
        fi
    done
    return 1
}

# Respect the user's terminal when provided; Alacritty is the themed fallback.
terminal_source='installed fallback'
if [[ -n "${TERMINAL:-}" && "$TERMINAL" != *[[:space:]]* ]] && command -v "$TERMINAL" >/dev/null 2>&1; then
    terminal="$TERMINAL"
    terminal_source=TERMINAL
else
    terminal="$(command_path alacritty kitty foot ghostty wezterm konsole ptyxis || true)"
fi

font=sans-serif
if command -v fc-match >/dev/null 2>&1; then
    for family in 'JetBrainsMono Nerd Font Propo' 'JetBrainsMono Nerd Font' 'JetBrains Mono'; do
        resolved="$(fc-match -f '%{family}' "$family" 2>/dev/null || true)"
        if [[ ",$resolved," == *",$family,"* ]]; then
            font="$family"
            break
        fi
    done
fi

# xdg-user-dir understands localized user-dirs.dirs; never source that file as code.
pictures_dir="${XDG_PICTURES_DIR:-}"
if [[ "$pictures_dir" != /* ]] && command -v xdg-user-dir >/dev/null 2>&1; then
    pictures_dir="$(xdg-user-dir PICTURES 2>/dev/null || true)"
fi
if [[ "$pictures_dir" != /* || "$pictures_dir" == "$HOME" ]]; then
    pictures_dir="$HOME/Pictures"
fi
wallpaper_dir="${pictures_dir%/}/wallpaper"
wallpaper_target="$wallpaper_dir/niri-noctalia.png"
settings_target="$TARGET_DATA_DIR/applications/niri-noctalia-settings.desktop"
generated="$DOTS_DIR/.config/noctalia/zz-adaptive.generated.toml"

app_dirs=("$TARGET_DATA_DIR/applications")
IFS=: read -r -a xdg_data_dirs <<< "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
for base in "${xdg_data_dirs[@]}"; do
    [[ "$base" == /* ]] && app_dirs+=("$base/applications")
done
app_dirs+=("$TARGET_DATA_DIR/flatpak/exports/share/applications" /var/lib/flatpak/exports/share/applications)

desktop_value() {
    awk -v key="$2" '
        /^\[Desktop Entry\]\r?$/ { inside=1; next }
        /^\[/ { inside=0 }
        inside && index($0, key "=")==1 {
            sub(/^[^=]*=/, ""); sub(/\r$/, ""); print; exit
        }' "$1"
}
pick_desktop_entry() {
    local id dir file hidden try_exec
    for id in "$@"; do
        id="${id%.desktop}"
        [[ -n "$id" && "$id" != *[!a-zA-Z0-9._-]* ]] || continue
        for dir in "${app_dirs[@]}"; do
            file="$dir/$id.desktop"
            [[ -f "$file" ]] || continue
            hidden="$(desktop_value "$file" Hidden)"
            # A user Hidden=true entry masks a system entry with the same ID.
            [[ "${hidden,,}" != true ]] || break
            [[ "$(desktop_value "$file" Type)" == Application ]] || break
            [[ -n "$(desktop_value "$file" Exec)" ]] || break
            try_exec="$(desktop_value "$file" TryExec)"
            if [[ -n "$try_exec" ]] && ! command -v "$try_exec" >/dev/null 2>&1; then
                break
            fi
            printf '%s' "$id"
            return 0
        done
    done
    return 1
}

browser_default=''
if command -v xdg-settings >/dev/null 2>&1; then
    browser_default="$(xdg-settings get default-web-browser 2>/dev/null || true)"
fi
browser_mime=''
file_manager_default=''
if command -v xdg-mime >/dev/null 2>&1; then
    browser_mime="$(xdg-mime query default x-scheme-handler/https 2>/dev/null || true)"
    file_manager_default="$(xdg-mime query default inode/directory 2>/dev/null || true)"
fi
browser="$(pick_desktop_entry "$browser_default" "$browser_mime" org.mozilla.firefox firefox org.qutebrowser.qutebrowser com.brave.Browser brave-browser org.chromium.Chromium chromium google-chrome || true)"
file_manager="$(pick_desktop_entry "$file_manager_default" org.gnome.Nautilus nautilus org.kde.dolphin dolphin thunar org.gnome.Nemo nemo || true)"
case "${terminal##*/}" in
    alacritty) terminal_entries=(Alacritty alacritty) ;;
    kitty) terminal_entries=(kitty) ;;
    foot) terminal_entries=(foot org.codeberg.dnkl.foot) ;;
    ghostty) terminal_entries=(com.mitchellh.ghostty org.ghostty.Ghostty) ;;
    wezterm) terminal_entries=(org.wezfurlong.wezterm wezterm) ;;
    konsole) terminal_entries=(org.kde.konsole konsole) ;;
    ptyxis) terminal_entries=(org.gnome.Ptyxis ptyxis) ;;
    *) terminal_entries=("${terminal##*/}") ;;
esac
terminal_entry="$(pick_desktop_entry "${terminal_entries[@]}" || true)"
dock_apps=()
# Stable order: browser, terminal, file manager, settings. Do not pin personal extras.
for entry in "$browser" "$terminal_entry" "$file_manager"; do
    [[ -n "$entry" ]] && dock_apps+=("$entry")
done
dock_apps+=(niri-noctalia-settings)

toml_string() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/\\r}"
    value="${value//$'\t'/\\t}"
    printf '"%s"' "$value"
}
render_config() {
    printf '# Generated by install.sh; user GUI overrides remain authoritative.\n[shell]\nfont_family = '
    toml_string "$font"
    printf '\n\n[wallpaper]\ndirectory = '
    toml_string "$wallpaper_dir"
    printf '\n\n[wallpaper.default]\npath = '
    toml_string "$wallpaper_target"
    printf '\n\n[dock]\nenabled = true\nshow_running = true\npinned = ['
    local separator='' id
    for id in "${dock_apps[@]}"; do
        printf '%s' "$separator"
        toml_string "$id"
        separator=', '
    done
    printf ']\n'
}

modules=(niri noctalia alacritty)
for module in "${modules[@]}"; do
    [[ -d "$DOTS_DIR/.config/$module" ]] || { printf 'Missing module: %s\n' "$module" >&2; exit 1; }
done
for asset in wallpaper.png niri-noctalia-settings.desktop; do
    [[ -f "$DOTS_DIR/assets/$asset" ]] || { printf 'Missing asset: %s\n' "$asset" >&2; exit 1; }
done
for file in "$generated" "$settings_target" "$wallpaper_target"; do
    [[ ! -d "$file" ]] || { printf 'Expected file, found directory: %s\n' "$file" >&2; exit 1; }
done

printf 'Terminal: %s (%s)\n' "${terminal:-none detected}" "$terminal_source"
printf 'Dock browser: %s\nDock terminal: %s\nDock file manager: %s\n' "${browser:-none detected}" "${terminal_entry:-none detected}" "${file_manager:-none detected}"
printf 'Dock settings: niri-noctalia-settings\nNoctalia font: %s\n' "$font"
printf 'Wallpaper: %s\nSettings launcher: %s\n' "$wallpaper_target" "$settings_target"
printf 'Generated configuration: %s\nConfig target: %s\n' "$generated" "$TARGET_CONFIG_DIR"
for module in "${modules[@]}"; do
    src="$DOTS_DIR/.config/$module"
    dest="$TARGET_CONFIG_DIR/$module"
    if [[ "$(readlink -f -- "$dest" 2>/dev/null || true)" == "$(readlink -f -- "$src")" ]]; then
        printf 'Already using project configuration: %s\n' "$dest"
    elif [[ -e "$dest" || -L "$dest" ]]; then
        printf 'Will back up and replace: %s\n' "$dest"
    else
        printf 'Will link: %s -> %s\n' "$src" "$dest"
    fi
done
if [[ "$MODE" == check ]]; then
    echo 'Check only. Use --dry-run for the generated TOML, or --apply to deploy.'
    exit 0
fi
if [[ "$MODE" == dry-run ]]; then
    echo 'Would create missing wallpaper/application directories, deploy the two assets, and write:'
    render_config
    echo 'Dry run complete; no files or directories were changed.'
    exit 0
fi
if [[ "$YES" != true ]]; then
    read -r -p 'Apply this configuration and its wallpaper/settings launcher? [y/N] ' answer
    [[ "$answer" =~ ^[Yy]$ ]] || { echo 'Cancelled; no changes made.'; exit 0; }
fi

# Stage and validate before changing live paths. The dry-run path above creates nothing.
stage="$(mktemp -d)"
trap 'rm -rf -- "$stage"' EXIT
render_config > "$stage/generated.toml"
cp -- "$DOTS_DIR/assets/wallpaper.png" "$stage/wallpaper.png"
cp -- "$DOTS_DIR/assets/niri-noctalia-settings.desktop" "$stage/settings.desktop"
if command -v noctalia >/dev/null 2>&1; then
    noctalia config validate "$stage/generated.toml"
fi
stamp="$(date +%Y%m%d_%H%M%S_%N)"
install_file() {
    local source="$1" target="$2" temp
    if [[ -f "$target" && ! -L "$target" ]] && cmp -s -- "$source" "$target"; then
        printf 'Already current: %s\n' "$target"
        return
    fi
    mkdir -p -- "$(dirname -- "$target")"
    if [[ -e "$target" || -L "$target" ]]; then
        cp -a -- "$target" "${target}.bak.${stamp}"
        printf 'Backed up: %s.bak.%s\n' "$target" "$stamp"
    fi
    temp="$(mktemp "$(dirname -- "$target")/.niri-noctalia.XXXXXX")"
    cp -- "$source" "$temp"
    chmod 0644 "$temp"
    mv -fT -- "$temp" "$target"
    printf 'Installed: %s\n' "$target"
}
install_file "$stage/wallpaper.png" "$wallpaper_target"
install_file "$stage/settings.desktop" "$settings_target"
install_file "$stage/generated.toml" "$generated"
mkdir -p -- "$TARGET_CONFIG_DIR"
for module in "${modules[@]}"; do
    src="$DOTS_DIR/.config/$module"
    dest="$TARGET_CONFIG_DIR/$module"
    if [[ "$(readlink -f -- "$dest" 2>/dev/null || true)" == "$(readlink -f -- "$src")" ]]; then
        continue
    fi
    if [[ -e "$dest" || -L "$dest" ]]; then
        mv -- "$dest" "${dest}.bak.${stamp}"
        printf 'Backed up: %s.bak.%s\n' "$dest" "$stamp"
    fi
    ln -s -- "$src" "$dest"
done
echo 'Deployment complete. Generated settings are git-ignored; GUI preferences were preserved.'
