# niri-noctalia-dots

A ready-to-apply desktop configuration built on [Niri](https://github.com/YaLTeR/niri) (scrollable tiling compositor) and [Noctalia](https://noctalia.dev) (Quickshell desktop shell) — frosted glass panels, harmonized corner radii, and one consistent dark palette across the whole session.

Everything is tuned at the seam between the two: margins, radii and font sizes line up, so it looks like the screenshot out of the box.

![Desktop](assets/screenshot.png)

## Features

- **Window Management** — Smooth horizontal scrolling via `niri`; windows slide in and out like a film strip.
- **Top Bar & Panels** — `noctalia` with a flush top edge, island clock, system tray, and a media controller with an audio spectrum.
- **Visual Harmony** — 16px window corners aligned with the Noctalia panel border radius (`corner_radius_scale = 1.5`).
- **Terminal Integration** — `alacritty` with the same palette as Noctalia plus subtle blur.
- **Safe Installation** — Idempotent install script; running it twice won't stack configs, and anything it overwrites is backed up with a timestamp first.

## Screenshots

| Desktop | Wallpaper |
| :---: | :---: |
| ![Desktop](assets/screenshot.png) | ![Wallpaper](assets/wallpaper.png) |

## Installation

### 1. Dry run (prints the planned changes, writes nothing)

```bash
./install.sh --dry-run
```

### 2. Apply

```bash
./install.sh
```

Existing `~/.config/niri`, `~/.config/noctalia` and `~/.config/alacritty` are backed up as `*.bak.<TIMESTAMP>` — nothing is deleted.

### 3. Reload the session

```bash
niri msg action quit --skip-confirmation   # or just log out and back in
```

## Dependencies

### Core

| Package | Purpose |
| :--- | :--- |
| `niri` | Window management |
| `noctalia` | Top bar, panels, lock screen |
| `alacritty` | Terminal |
| `swaybg` | Wallpaper |
| `polkit-mate-authentication-agent-1` | Polkit authentication agent |

### Fonts

- `JetBrainsMono Nerd Font Propo` — primary UI and terminal font
- `Sarasa Mono SC Nerd Font` — CJK fallback for the terminal, so Chinese text doesn't turn into tofu boxes

Missing Nerd Font glyphs show up as squares in the bar, so install the fonts before judging the look.

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
│   ├── screenshot.png
│   └── wallpaper.png
├── install.sh
└── README.md
```

## Keybindings

| Shortcut | Action |
| :--- | :--- |
| `Alt + Space` | Application launcher |
| `Mod + Y` | Clipboard history |
| `Mod + Return` | Open alacritty |
| `Mod + Q` | Close window |
| `Super + Alt + L` | Lock screen |
| `XF86Audio*` | Volume & media controls |
| `XF86MonBrightness*` | Display backlight |

## Notes

- Written against niri 0.1.x and the current Noctalia release; if you're several versions off, read the `--dry-run` output first.
- Only hand-written configs are tracked — no system-level dotfiles.
- The wallpapers in `assets/` are for preview; swap them for your own.

## License

MIT
