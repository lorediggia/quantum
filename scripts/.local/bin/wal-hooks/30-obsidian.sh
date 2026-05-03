#!/usr/bin/env bash

: "${DOTFILES:=$HOME/dotfiles}"
[[ -f $DOTFILES/local/post-wallpaper.env ]] && source "$DOTFILES/local/post-wallpaper.env"
[[ -z ${OBSIDIAN_VAULTS:-} ]] && exit 0

src="$HOME/.cache/wal/colors-obsidian.css"
[[ -f $src ]] || exit 0

for vault in $OBSIDIAN_VAULTS; do
    dir="$vault/.obsidian/snippets"
    [[ -d $dir ]] && install -m 644 "$src" "$dir/pywal.css"
done
