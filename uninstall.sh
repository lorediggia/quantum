#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
LOG_FILE="$HOME/.cache/dotfiles-uninstall.log"
mkdir -p "$(dirname "$LOG_FILE")"
: > "$LOG_FILE"

C_ACC='\e[38;5;183m' C_OK='\e[38;5;114m' C_ERR='\e[38;5;167m' C_DIM='\e[38;5;240m' C_DEF='\e[0m'
BOLD='\e[1m' REV='\e[7m'

step() { echo -e "\n${BOLD}${C_ERR}::${C_DEF} ${BOLD}$1${C_DEF}"; }
ok()   { echo -e "   ${C_OK}✔${C_DEF} $1"; }
warn() { echo -e "   ${C_WARN}⚠${C_DEF} $1"; }
info() { echo -e "   ${C_DIM}→${C_DEF} $1"; }
die()  { echo -e "\n${BOLD}${C_ERR}FATAL ERROR:${C_DEF} $1" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "Do not run as root."

OPTIONS=(
    "Unstow Dotfiles (Remove Symlinks)"
    "Remove Holograph Binaries"
    "Clean Pywal Cache & Wallpapers"
    "Remove Obsidian Integration"
    "Uninstall WhiteSur GTK Theme"
    "Restore Configuration Backups"
    "Uninstall System Packages"
    "Remove Rustup Toolchain"
    "Clean Local Configuration (local/)"
)
SELECTED=(1 1 1 1 1 1 0 0 0)
CURRENT=0

set +e
tput civis
while true; do
    clear
    echo -e "${C_ERR}${BOLD} 
           ╭──────────────────────────────────────────────────╮"
    echo " │               quantum uninstaller                │"
    echo " ╰──────────────────────────────────────────────────╯${C_DEF}"
    echo -e " Use ${BOLD}UP/DOWN${C_DEF} to navigate, ${BOLD}SPACE${C_DEF} to toggle, ${BOLD}ENTER${C_DEF} to confirm.\n"

    for i in "${!OPTIONS[@]}"; do
        [[ $i -eq $CURRENT ]] && echo -ne "  ${C_ERR}❯${C_DEF} " || echo -ne "    "
        [[ ${SELECTED[$i]} -eq 1 ]] && echo -ne "${C_ERR}[✗]${C_DEF} " || echo -ne "${C_DIM}[ ]${C_DEF} "
        [[ $i -eq $CURRENT ]] && echo -e "${REV}${OPTIONS[$i]}${C_DEF}" || echo -e "${OPTIONS[$i]}"
    done

    IFS= read -rsn1 key < /dev/tty || true
    case "$key" in
        $'\x1b')
            read -rsn2 -t 0.1 seq < /dev/tty || true
            [[ "$seq" == "[A" || "$seq" == "OA" ]] && ((CURRENT--))
            [[ $CURRENT -lt 0 ]] && CURRENT=$((${#OPTIONS[@]} - 1))
            [[ "$seq" == "[B" || "$seq" == "OB" ]] && ((CURRENT++))
            [[ $CURRENT -ge ${#OPTIONS[@]} ]] && CURRENT=0
            ;;
        " ") SELECTED[$CURRENT]=$((1 - SELECTED[$CURRENT])) ;;
        ""|$'\n') break ;;
    esac
done
tput cnorm
set -e

OPT_UNSTOW=${SELECTED[0]}
OPT_HOLO=${SELECTED[1]}
OPT_PYWAL=${SELECTED[2]}
OPT_OBS=${SELECTED[3]}
OPT_GTK=${SELECTED[4]}
OPT_RESTORE=${SELECTED[5]}
OPT_PKGS=${SELECTED[6]}
OPT_RUST=${SELECTED[7]}
OPT_LOCAL=${SELECTED[8]}

clear
step "Requesting sudo privileges"
sudo -v
( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

if (( OPT_UNSTOW )); then
    step "Unstowing configurations"
    STOW_PKGS=(hyprland kitty rofi quickshell fastfetch starship pywal scripts)
    if [[ -d "$DOTFILES" ]]; then
        cd "$DOTFILES"
        for p in "${STOW_PKGS[@]}"; do
            [[ -d "$p" ]] && stow -D --target="$HOME" "$p" 2>>"$LOG_FILE" || true
        done
        ok "Symlinks removed."
    fi
fi

if (( OPT_HOLO )); then
    step "Removing Holograph"
    sudo rm -f /usr/local/bin/holograph
    rm -f "$HOME/.local/bin/holograph"
    ok "Binaries removed."
fi

if (( OPT_GTK )); then
    step "Uninstalling WhiteSur GTK Theme"
    if [[ -d "/tmp/WhiteSur-gtk-theme" ]]; then
        ( cd "/tmp/WhiteSur-gtk-theme" && ./uninstall.sh ) >>"$LOG_FILE" 2>&1 || true
    fi
    sudo rm -rf /usr/share/themes/WhiteSur* 2>/dev/null || true
    rm -rf "$HOME/.themes/WhiteSur*" 2>/dev/null || true
    ok "GTK themes removed."
fi

if (( OPT_PYWAL )); then
    step "Cleaning Pywal and cache"
    rm -rf "$HOME/.cache/wal" "$HOME/.cache/wal-sync.last"
    rm -f "$HOME/.icons/default/index.theme"
    ok "Cache cleaned."
fi

if (( OPT_OBS )); then
    step "Removing Obsidian Integration"
    if [[ -f "$DOTFILES/local/post-wallpaper.env" ]]; then
        source "$DOTFILES/local/post-wallpaper.env" 2>/dev/null || true
        for vault in ${OBSIDIAN_VAULTS:-}; do
            rm -f "$vault/.obsidian/snippets/pywal.css" 2>/dev/null || true
            rm -f "$vault/.obsidian/snippets/layout-obsidian.css" 2>/dev/null || true
        done
        ok "Snippets removed from vaults."
    fi
fi

if (( OPT_RESTORE )); then
    step "Restoring backups"
    LATEST_BACKUP=$(find "$HOME" -maxdepth 1 -type d -name ".config-backup-*" | sort -r | head -n 1 || true)
    if [[ -n "$LATEST_BACKUP" ]]; then
        cp -r "$LATEST_BACKUP"/* "$HOME/.config/" 2>>"$LOG_FILE" || true
        ok "Backups restored from $LATEST_BACKUP"
    fi
fi

if (( OPT_PKGS )); then
    step "Uninstalling packages"
    PKGS=(
        hyprland hyprpicker polkit-gnome xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        kitty rofi-wayland quickshell fastfetch starship python-pywal python awww grim slurp wl-clipboard
        nwg-look papirus-icon-theme btop obsidian hyprshot
    )
    if command -v yay &>/dev/null; then
        yay -Rns --noconfirm "${PKGS[@]}" 2>>"$LOG_FILE" || true
    else
        sudo pacman -Rns --noconfirm "${PKGS[@]}" 2>>"$LOG_FILE" || true
    fi
    ok "Packages removed."
fi

if (( OPT_RUST )); then
    step "Uninstalling Rustup"
    if command -v rustup &>/dev/null; then
        rustup self uninstall -y >>"$LOG_FILE" 2>&1 || true
        ok "Rust removed."
    fi
fi

if (( OPT_LOCAL )); then
    step "Cleaning local configurations"
    rm -rf "$DOTFILES/local"
    ok "Folder local/ removed."
fi

echo -e "\n${BOLD}${C_OK} uninstallation complete!${C_DEF}\n"
kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
exit 0