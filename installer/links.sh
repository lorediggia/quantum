CFG="$HOME/.config"
BIN="$HOME/.local/bin"
BKP="$HOME/.config-backup-$(date +%Y%m%d)"
mkdir -p "$CFG" "$BIN"

link_node() {
    if [[ -e "$2" && ! -L "$2" ]]; then
        mkdir -p "$BKP"
        mv "$2" "$BKP/$(basename "$2")"
    else
        rm -rf "$2"
    fi
    ln -sfnT "$1" "$2"
}

if on HYPR;  then link_node "$DOTFILES/config/hypr" "$CFG/hypr"; fi
if on QSH;   then link_node "$DOTFILES/config/quickshell" "$CFG/quickshell"; fi
if on TERM;  then
    link_node "$DOTFILES/config/kitty" "$CFG/kitty"
    link_node "$DOTFILES/config/fish" "$CFG/fish"
    link_node "$DOTFILES/config/starship.toml" "$CFG/starship.toml"
fi
if on THEME; then link_node "$DOTFILES/config/wallust" "$CFG/wallust"; fi
if on ROFI;  then link_node "$DOTFILES/config/rofi" "$CFG/rofi"; fi
if on FF;    then link_node "$DOTFILES/config/fastfetch" "$CFG/fastfetch"; fi

for f in "$DOTFILES/bin/"*; do
    [[ -f "$f" ]] || continue
    link_node "$f" "$BIN/$(basename "$f")"
    chmod +x "$f"
done

if [[ -f "$DOTFILES/bin/qs" ]]; then
    for tgt in sidebar topbar wall keybinds; do
        link_node "$DOTFILES/bin/qs" "$BIN/$tgt"
    done
fi

if on HOLO; then
    if [[ -d "$DOTFILES/holograph" ]]; then
        run "Compiling Holograph" bash -c "
            cd '$DOTFILES/holograph'
            cargo build --release
            install -Dm755 target/release/holograph '$BIN/holograph'
        "
    fi
fi

if on HYPR; then
    sudo systemctl enable --now NetworkManager.service || true
    sudo systemctl enable --now power-profiles-daemon.service || true
fi
if on BT; then sudo systemctl enable --now bluetooth.service || true; fi

finalize() {
    if on THEME; then
        WALLDIR="$HOME/Pictures/Wallpapers"
        mkdir -p "$WALLDIR"
        FIRST=$(find "$WALLDIR" -maxdepth 2 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | head -n1) || true
        if [[ -n "$FIRST" ]]; then
            "$BIN/theme-sync" "$FIRST" >/dev/null 2>&1 || true
        fi
    fi

    if on TERM; then
        CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
        if [[ "$CURRENT_SHELL" != "/usr/bin/fish" ]]; then
            sudo chsh -s /usr/bin/fish "$USER" || true
        fi
    fi
    clear
    echo "Execution finished successfully."
}
