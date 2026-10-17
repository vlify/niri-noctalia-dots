# niri-noctalia-dots

Modern scrollable tiling desktop environment powered by [Niri](https://github.com/YaLTeR/niri) and [Noctalia](https://noctalia.dev) shell, featuring frosted glass panels, harmonized corner radii, and cohesive dark aesthetics.

---

## Features

- **Window Management**: Smooth horizontal scrolling via `niri`.
- **Top Bar & Panels**: `noctalia` with flush top edge, island clock, system tray, and media controller with audio spectrum.
- **Visual Harmony**: 16px window corners aligned with Noctalia panel border radius (`corner_radius_scale = 1.5`).
- **Terminal Integration**: `alacritty` with Noctalia-matching color scheme and subtle blur.
- **Safe Installation**: Idempotent installation script with automatic backup of existing configurations.

---

## Directory Structure

```text
niri-noctalia-dots/
├── .config/
│   ├── alacritty/
│   │   ├── alacritty.toml
│   │   └── themes/noctalia.toml
│   ├── niri/
│   │   ├── config.kdl
│   │   ├── noctalia.kdl
│   │   └── dms/
│   └── noctalia/
│       └── config.toml
├── assets/
│   └── wallpaper.png
├── install.sh
└── README.md
```

---

## Dependencies

### Core
- `niri`
- `noctalia`
- `alacritty`
- `swaybg`
- `polkit-mate-authentication-agent-1`

### Fonts & Themes
- `JetBrainsMono Nerd Font Propo`
- `Sarasa Mono SC Nerd Font` (fallback CJK font for terminal)

---

## Installation

### 1. Dry Run (Inspect Changes)

```bash
./install.sh --dry-run
```

### 2. Apply Configuration

```bash
./install.sh
```

Existing configurations in `~/.config/niri`, `~/.config/noctalia`, and `~/.config/alacritty` will be backed up with timestamp suffixes (`*.bak.<TIMESTAMP>`).

---

## Keybindings (Cheat Sheet)

| Shortcut | Action |
| :--- | :--- |
| `Alt + Space` | Noctalia Application Launcher |
| `Mod + Y` | Noctalia Clipboard History |
| `Super + Alt + L` | Lock Screen |
| `Mod + Return` | Open Alacritty Terminal |
| `Mod + Q` | Close Window |
| `XF86Audio*` | Volume & Media Controls via Noctalia |
| `XF86MonBrightness*` | Display Backlight Control |

---

## License

MIT
