# 字体依赖与回退

本仓库通过依赖说明和 Fontconfig 回退提供字体支持，字体二进制由发行版或字体上游提供。

参考实现：

- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland/blob/main/sdata/deps-info.md) 在字体/主题依赖中列出 Fontconfig、JetBrains Mono Nerd Font 及图标字体，并说明各字体的使用位置。
- [Caelestia](https://github.com/caelestia-dots/caelestia/blob/main/manifest.toml) 在 Hyprland 和 Foot 组件的包列表中声明 `ttf-jetbrains-mono-nerd`。

本仓库的选择：

- Noctalia 安装时优先查找 `JetBrainsMono Nerd Font Propo`、`JetBrainsMono Nerd Font`、`JetBrains Mono`；仅在 Fontconfig 返回的实际 family 匹配时采用，否则使用 `sans-serif`。
- Alacritty 默认使用 `monospace`，由系统 Fontconfig 选取可用字体。终端缺少某些语言或 Nerd Font 图形时，安装相应的 CJK 字体或 Nerd Font。
- 推荐的可选终端字体：JetBrains Mono Nerd Font；已有 Sarasa Mono SC Nerd Font 的用户也可以继续使用它。安装脚本不自动下载字体或安装系统软件包。

查看本机实际回退结果：

```bash
fc-match -f '%{family}\n' monospace
fc-match -f '%{family}\n' 'JetBrainsMono Nerd Font'
fc-list : family
```

想让 Alacritty 使用指定字体时，修改 `.config/alacritty/alacritty.toml` 中 `[font]` 的三个 family 值，例如：

```toml
[font]
normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
bold = { family = "JetBrainsMono Nerd Font", style = "Bold" }
italic = { family = "JetBrainsMono Nerd Font", style = "Italic" }
```

字体名称以 `fc-list` 的实际输出为准，安装推荐字体后可重新运行 `./install.sh --dry-run` 检查 Noctalia 的选择。
