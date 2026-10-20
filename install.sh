#!/usr/bin/env bash
set -euo pipefail
((EUID)) || { echo "run as your user, not root" >&2; exit 1; }

root=$(cd "$(dirname "$0")" && pwd)
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
wal=$HOME/pictures/wal
work=${XDG_CACHE_HOME:-$HOME/.cache}/quantum
failed=()

list() {
    local f
    for f; do grep -v '^[[:space:]]*$' "$root/pkgs/$f.txt"; done
}

need() {
    local f
    for f; do
        [[ -s $root/pkgs/$f.txt ]] || { echo "missing pkgs/$f.txt: extract the whole repository again" >&2; return 1; }
    done
    compgen -G "$root/pkgs/*/PKGBUILD" >/dev/null || { echo "missing pkgs/*/PKGBUILD: extract the whole repository again" >&2; return 1; }
}

has() { command -v "$1" >/dev/null || { echo "$1 is missing: run the packages stage first" >&2; return 1; }; }

bootstrap_yay() {
    local tmp
    tmp=$(mktemp -d)
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp"
    (cd "$tmp" && makepkg -si --noconfirm)
    rm -rf "$tmp"
}

build_local() {
    local f dir name ver tmp
    tmp=$(mktemp -d)
    mkdir -p "$tmp/build" "$tmp/src"
    for f in "$root"/pkgs/*/PKGBUILD; do
        dir=${f%/*}
        read -r name ver < <(bash -c '. "$0" && echo "$pkgname ${epoch:+$epoch:}$pkgver-$pkgrel"' "$f")
        [[ $(pacman -Q "$name" 2>/dev/null) == "$name $ver" ]] && continue
        (cd "$dir" \
            && BUILDDIR=$tmp/build PKGDEST=$tmp SRCDEST=$tmp/src makepkg -s --noconfirm \
            && sudo pacman -U --noconfirm --ask 4 "$tmp/$name-$ver-"*.pkg.tar.*) \
            || { echo "$name: makepkg failed, trying the fallback" >&2; [[ -f $dir/fallback.sh ]] && bash "$dir/fallback.sh" "${ver%-*}"; } \
            || failed+=("$name")
    done
    rm -rf "$tmp"
}

packages() {
    local repo aur p
    need build desktop aur apps
    mkdir -p "$work"
    export TMPDIR=$work
    mapfile -t repo < <(list build desktop)
    mapfile -t aur < <(list aur apps)
    sudo pacman -Syu --needed --noconfirm "${repo[@]}"
    command -v yay >/dev/null || bootstrap_yay
    build_local
    for p in "${aur[@]}"; do
        yay -S --needed --noconfirm --sudoloop "$p" || failed+=("$p")
    done
    ((${#failed[@]} == 0)) || { echo "not installed: ${failed[*]}" >&2; return 1; }
}

link() {
    local src dst
    mkdir -p "$cfg" "$root/local/stickers"
    for src in "$root"/config/*; do
        dst=$cfg/${src##*/}
        [[ $(readlink -f "$dst") == "$src" ]] && continue
        [[ -e $dst || -L $dst ]] && mv "$dst" "$dst.bak.$(date +%s)"
        ln -s "$src" "$dst" && echo "linked ${dst/#$HOME/"~"}"
    done
}

seed() {
    has magick
    mkdir -p "$wal"
    [[ -n $(ls -A "$wal") ]] || magick -size 2560x1440 radial-gradient:'#2b2b4d-#0b0b12' "$wal/quantum.png"
}

theme() {
    local key val name
    has gsettings
    [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} || -S ${XDG_RUNTIME_DIR:-/nonexistent}/bus ]] || exec dbus-run-session -- bash "$0" theme
    while IFS='=' read -r key val; do
        case $key in
            gtk-theme-name) name=gtk-theme ;;
            gtk-icon-theme-name) name=icon-theme ;;
            gtk-cursor-theme-name) name=cursor-theme ;;
            gtk-cursor-theme-size) name=cursor-size ;;
            gtk-font-name) name=font-name ;;
            *) continue ;;
        esac
        gsettings set org.gnome.desktop.interface "$name" "$val"
    done < "$root/config/gtk-3.0/settings.ini"
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
}

services() {
    local s rc=0
    need services
    mapfile -t s < <(list services)
    sudo systemctl enable "${s[@]}" || rc=1
    sudo systemctl start "${s[@]}" || echo "some services did not start now, they start at the next boot" >&2
    return $rc
}

if (($# != 1)); then
    (($#)) || set -- link packages seed theme services
    for stage; do
        echo "==> $stage"
        bash "$0" "$stage" || failed+=("$stage")
    done
    ((${#failed[@]} == 0)) || { echo "failed: ${failed[*]}" >&2; exit 1; }
    echo "done: log in on a TTY and run start-hyprland"
    exit 0
fi

case $1 in
    link|packages|seed|theme|services) "$1" ;;
    *) echo "usage: install.sh [link|packages|seed|theme|services]..." >&2; exit 1 ;;
esac
