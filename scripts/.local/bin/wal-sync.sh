#!/usr/bin/env bash

: "${DOTFILES:=$HOME/dotfiles}"
: "${HOOKS_DIR:=$DOTFILES/scripts/.local/bin/wal-hooks}"

wp_path="${1:-$(cat "$HOME/.cache/wal-sync.last" 2>/dev/null)}"
[[ -z $wp_path ]] && exit 1

state="$HOME/.cache/wal-sync.last"
[[ -f $state && $(< "$state") == "$wp_path" ]] && exit 0
printf '%s' "$wp_path" > "$state"

wal -i "$wp_path" -qste

[[ -L "$HOME/.config/wal/templates/colors-hyprland.lua" ]] \
    || (cd "$DOTFILES" && stow -R pywal) 2>/dev/null

if [[ -d $HOOKS_DIR ]]; then
    for hook in "$HOOKS_DIR"/*; do
        [[ -x $hook ]] && "$hook" "$wp_path" &
    done
    wait
fi
