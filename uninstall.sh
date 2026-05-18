#!/usr/bin/env bash
set -euo pipefail

export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
INSTALLER="$DOTFILES/installer"

source "$INSTALLER/env.sh"
menu

CFG="$HOME/.config"
BIN="$HOME/.local/bin"

unlink_node() {
    if [[ -L "$1" ]]; then
        rm -f "$1"
    fi
}

if on HYPR;  then unlink_node "$CFG/hypr"; fi
if on QSH;   then unlink_node "$CFG/quickshell"; fi
if on TERM;  then
    unlink_node "$CFG/kitty"
    unlink_node "$CFG/fish"
    unlink_node "$CFG/starship.toml"
    if [[ "$(getent passwd "$USER" | cut -d: -f7)" == "/usr/bin/fish" ]]; then
        sudo chsh -s /bin/bash "$USER" || true
    fi
fi
if on THEME; then unlink_node "$CFG/wallust"; fi
if on ROFI;  then unlink_node "$CFG/rofi"; fi
if on FF;    then unlink_node "$CFG/fastfetch"; fi

for f in "$DOTFILES/bin/"*; do
    if [[ -f "$f" ]]; then
        unlink_node "$BIN/$(basename "$f")"
    fi
done

if on HOLO; then unlink_node "$BIN/holograph"; fi

clear
echo "Uninstallation finished successfully."