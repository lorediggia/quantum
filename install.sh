#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
LOG_FILE="$HOME/.cache/dotfiles-install.log"
mkdir -p "$(dirname "$LOG_FILE")"
: > "$LOG_FILE"

C_ACC='\e[38;5;183m'
C_OK='\e[38;5;114m'
C_ERR='\e[38;5;167m'
C_WARN='\e[38;5;215m'
C_DIM='\e[38;5;240m'
C_DEF='\e[0m'
BOLD='\e[1m'
REV='\e[7m'

step() { echo -e "\n${BOLD}${C_ACC}::${C_DEF} ${BOLD}$1${C_DEF}"; }
ok()   { echo -e "   ${C_OK}✔${C_DEF} $1"; }
warn() { echo -e "   ${C_WARN}⚠${C_DEF} $1"; }
info() { echo -e "   ${C_DIM}→${C_DEF} $1"; }
die()  { echo -e "\n${BOLD}${C_ERR}FATAL ERROR:${C_DEF} $1" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "Do not run as root."
command -v pacman &>/dev/null || die "Arch Linux required."
[[ -d "$DOTFILES" ]] || die "Dotfiles directory not found: $DOTFILES"

OPTIONS=(
    "Hyprland Core & Base System"
    "Terminal (Kitty & Starship)"
    "Rofi (App Launcher)"
    "Quickshell (Sidebar/UI)"
    "Theming Engine (Pywal & Awww)"
    "Holograph (Rust Theme Picker)"
    "Obsidian Integration"
    "Zen Browser"
    "Nautilus (File Manager)"
    "Bluetooth Stack"
    "Audio Stack (PipeWire)"
    "System Monitor (Btop)"
    "Bibata Cursor Theme"
    "Fastfetch"
    "GTK Themes (WhiteSur, nwg-look)"
)
SELECTED=(1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
CURRENT=0

set +e
tput civis
while true; do
    clear
    echo -e "
${C_ACC}${BOLD} ╭──────────────────────────────────────────────────╮"
         echo " │              quantum installer                   │"
         echo " ╰──────────────────────────────────────────────────╯${C_DEF}"
    echo -e " Use ${BOLD}UP/DOWN${C_DEF} to navigate, ${BOLD}SPACE${C_DEF} to toggle, ${BOLD}ENTER${C_DEF} to confirm.\n"

    for i in "${!OPTIONS[@]}"; do
        if [[ $i -eq $CURRENT ]]; then
            echo -ne "  ${C_ACC}❯${C_DEF} "
        else
            echo -ne "    "
        fi

        if [[ ${SELECTED[$i]} -eq 1 ]]; then
            echo -ne "${C_OK}[✓]${C_DEF} "
        else
            echo -ne "${C_DIM}[ ]${C_DEF} "
        fi

        if [[ $i -eq $CURRENT ]]; then
            echo -e "${REV}${OPTIONS[$i]}${C_DEF}"
        else
            echo -e "${OPTIONS[$i]}"
        fi
    done

    IFS= read -rsn1 key < /dev/tty || true
    case "$key" in
        $'\x1b')
            read -rsn2 -t 0.1 seq < /dev/tty || true
            if [[ "$seq" == "[A" || "$seq" == "OA" ]]; then
                ((CURRENT--))
                [[ $CURRENT -lt 0 ]] && CURRENT=$((${#OPTIONS[@]} - 1))
            elif [[ "$seq" == "[B" || "$seq" == "OB" ]]; then
                ((CURRENT++))
                [[ $CURRENT -ge ${#OPTIONS[@]} ]] && CURRENT=0
            fi
            ;;
        " ")
            SELECTED[$CURRENT]=$((1 - SELECTED[$CURRENT]))
            ;;
        ""|$'\n')
            break
            ;;
    esac
done
tput cnorm
set -e

OPT_HYPR=${SELECTED[0]}
OPT_TERM=${SELECTED[1]}
OPT_ROFI=${SELECTED[2]}
OPT_QUICKSHELL=${SELECTED[3]}
OPT_THEME=${SELECTED[4]}
OPT_HOLO=${SELECTED[5]}
OPT_OBS=${SELECTED[6]}
OPT_BROWSER=${SELECTED[7]}
OPT_NAUTILUS=${SELECTED[8]}
OPT_BT=${SELECTED[9]}
OPT_AUDIO=${SELECTED[10]}
OPT_BTOP=${SELECTED[11]}
OPT_CURSOR=${SELECTED[12]}
OPT_FASTFETCH=${SELECTED[13]}
OPT_GTK=${SELECTED[14]}

clear
if (( ! OPT_BROWSER )); then
    echo -ne " ➜ Alternative browser command (empty to skip): "
    read -r ALT_BROWSER < /dev/tty
fi

if (( OPT_OBS )); then
    AUTO_VAULT=$(find "$HOME" -maxdepth 4 -type d -name ".obsidian" -exec dirname {} \; 2>/dev/null | head -n 1 || true)
    [[ -z "$AUTO_VAULT" ]] && AUTO_VAULT="$HOME/Documents/Obsidian"
    echo -ne " ➜ Obsidian Vault path [${AUTO_VAULT}]: "
    read -r USER_VAULT < /dev/tty
    OBS_VAULT="${USER_VAULT:-$AUTO_VAULT}"
    OBS_VAULT="${OBS_VAULT/#\~/$HOME}"
fi
echo

step "Requesting sudo privileges"
sudo -v
( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
ok "Sudo session active."

if ! command -v yay &>/dev/null; then
    sudo pacman -S --needed --noconfirm git base-devel
    tmpdir=$(mktemp -d)
    git clone --depth 1 https://aur.archlinux.org/yay.git "$tmpdir/yay"
    ( cd "$tmpdir/yay" && makepkg -si --noconfirm )
    rm -rf "$tmpdir"
fi

step "Building package lists"
PKGS_REPO=(stow base-devel git)
PKGS_AUR=()

(( OPT_HYPR )) && PKGS_REPO+=(hyprland hyprpicker polkit-gnome xdg-desktop-portal-hyprland xdg-desktop-portal-gtk grim slurp wl-clipboard networkmanager power-profiles-daemon pacman-contrib qt6-base qt6-declarative qt6-svg qt6-wayland qt6-5compat ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono noto-fonts noto-fonts-emoji) && PKGS_AUR+=(hyprshot)
(( OPT_TERM )) && PKGS_REPO+=(kitty starship fish)
(( OPT_ROFI )) && PKGS_REPO+=(rofi-wayland)
(( OPT_QUICKSHELL )) && PKGS_REPO+=(quickshell)
(( OPT_THEME )) && PKGS_REPO+=(python-pywal python awww)
(( OPT_HOLO )) && PKGS_REPO+=(rustup pkgconf fontconfig freetype2 gcc make chafa)
(( OPT_OBS )) && PKGS_REPO+=(obsidian)
(( OPT_BROWSER )) && PKGS_AUR+=(zen-browser-bin)
(( OPT_NAUTILUS )) && PKGS_REPO+=(nautilus)
(( OPT_BT )) && PKGS_REPO+=(bluez bluez-utils blueman)
(( OPT_AUDIO )) && PKGS_REPO+=(pipewire pipewire-pulse wireplumber pavucontrol pamixer playerctl)
(( OPT_BTOP )) && PKGS_REPO+=(btop)
(( OPT_CURSOR )) && PKGS_AUR+=(bibata-cursor-theme)
(( OPT_FASTFETCH )) && PKGS_REPO+=(fastfetch)
(( OPT_GTK )) && PKGS_REPO+=(nwg-look papirus-icon-theme sassc)

step "Installing packages (Output is visible)"
sudo pacman -Syu --noconfirm || die "pacman -Syu failed."
sudo pacman -S --needed --noconfirm "${PKGS_REPO[@]}" || die "Repo install failed."
if (( ${#PKGS_AUR[@]} > 0 )); then
    yay -S --needed --noconfirm "${PKGS_AUR[@]}" || die "AUR install failed."
fi

if (( OPT_HOLO )); then
    rustup default stable || true
fi
ok "Packages installed."

if (( OPT_GTK )); then
    step "Installing WhiteSur GTK Theme (GitHub)"
    tmp_theme=$(mktemp -d)
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$tmp_theme" >>"$LOG_FILE" 2>&1
    ( cd "$tmp_theme" && ./install.sh ) >>"$LOG_FILE" 2>&1 || warn "WhiteSur installation failed. Check log."
    rm -rf "$tmp_theme"
    ok "WhiteSur GTK Theme installed."
fi

step "Enabling services"
if (( OPT_HYPR )); then
    systemctl list-unit-files | grep -q "^NetworkManager.service" && sudo systemctl enable --now NetworkManager.service >>"$LOG_FILE" 2>&1 || true
    systemctl list-unit-files | grep -q "^power-profiles-daemon.service" && sudo systemctl enable --now power-profiles-daemon.service >>"$LOG_FILE" 2>&1 || true
fi
(( OPT_BT )) && systemctl list-unit-files | grep -q "^bluetooth.service" && sudo systemctl enable --now bluetooth.service >>"$LOG_FILE" 2>&1 || true
ok "Services configured."

if (( OPT_OBS )) && [[ -n "${OBS_VAULT:-}" ]]; then
    step "Configuring Obsidian"
    mkdir -p "$DOTFILES/local"
    echo "OBSIDIAN_VAULTS=\"$OBS_VAULT\"" > "$DOTFILES/local/post-wallpaper.env"
    mkdir -p "$OBS_VAULT/.obsidian/snippets" 2>/dev/null || true
    if [[ -d "$DOTFILES/snippets" ]]; then
        cp -r "$DOTFILES/snippets/"*.css "$OBS_VAULT/.obsidian/snippets/" 2>/dev/null || true
    fi
    ok "Obsidian configured."
fi

if (( OPT_HOLO )); then
    step "Compiling Holograph"
    HOLO_SRC="$DOTFILES/holograph"
    if [[ -d "$HOLO_SRC" && -f "$HOLO_SRC/Cargo.toml" ]]; then
        cd "$HOLO_SRC"
        cargo build --release || die "Holograph build failed."
        sudo install -Dm755 "target/release/holograph" /usr/local/bin/holograph
        install -Dm755 "target/release/holograph" "$HOME/.local/bin/holograph"
        mkdir -p "$DOTFILES/logo/holograph" "$DOTFILES/logo/img"
        ok "Holograph installed."
        cd "$DOTFILES"
    fi
fi

if (( ! OPT_BROWSER )) && [[ -n "${ALT_BROWSER:-}" ]]; then
    sed -i "s|^\$browser.*=.*|\$browser    = $ALT_BROWSER|" "$DOTFILES/hyprland/.config/hypr/variables.conf" 2>/dev/null || true
fi

if [[ ! -f "$DOTFILES/local/hypr-local.conf" ]]; then
    mkdir -p "$DOTFILES/local"
    echo "monitor = ,preferred,auto,1" > "$DOTFILES/local/hypr-local.conf"
fi

step "Deploying configurations"
mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.cache/wal"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
NEEDS_BACKUP=0
TARGETS=("$HOME/.config/hypr" "$HOME/.config/kitty" "$HOME/.config/rofi" "$HOME/.config/quickshell" "$HOME/.config/fastfetch" "$HOME/.config/starship.toml" "$HOME/.config/wal")
for f in "$DOTFILES/scripts/.local/bin/"*; do TARGETS+=("$HOME/.local/bin/$(basename "$f")"); done
for target in "${TARGETS[@]}"; do
    if [[ -L "$target" ]]; then rm -f "$target"
    elif [[ -e "$target" ]]; then NEEDS_BACKUP=1 && mkdir -p "$BACKUP_DIR" && mv "$target" "$BACKUP_DIR/" 2>/dev/null || true; fi
done

STOW_PKGS=(scripts)
(( OPT_HYPR )) && STOW_PKGS+=(hyprland)
(( OPT_TERM )) && STOW_PKGS+=(kitty starship fish)
(( OPT_ROFI )) && STOW_PKGS+=(rofi)
(( OPT_QUICKSHELL )) && STOW_PKGS+=(quickshell)
(( OPT_THEME )) && STOW_PKGS+=(pywal)
(( OPT_FASTFETCH )) && STOW_PKGS+=(fastfetch)

cd "$DOTFILES"
for p in "${STOW_PKGS[@]}"; do
    [[ -d "$p" ]] && stow -R --target="$HOME" "$p" 2>>"$LOG_FILE" || true
done
find "$HOME/.local/bin" -type f -exec chmod +x {} \; 2>/dev/null || true
ok "Symlinks created."

if (( OPT_THEME )); then
    step "Initializing Theme"
    WALLDIR="$HOME/Pictures/Wallpapers"
    mkdir -p "$WALLDIR" "$HOME/.cache/wal"
    FIRST_WP=$(find "$WALLDIR" -maxdepth 2 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | head -n1)
    if [[ -n "$FIRST_WP" ]]; then
        "$HOME/.local/bin/wal-sync.sh" "$FIRST_WP" >>"$LOG_FILE" 2>&1 || true
    else
        wal --theme base16-monokai -qe >>"$LOG_FILE" 2>&1 || touch "$HOME/.cache/wal/colors-hyprland.conf"
    fi
    ok "Theme initialized."
fi

if (( OPT_CURSOR )); then
    mkdir -p "$HOME/.icons/default"
    echo -e "[Icon Theme]\nInherits=Bibata-Modern-Classic" > "$HOME/.icons/default/index.theme"
fi

if (( OPT_TERM )); then
    step "Setting Fish as default shell"
    sudo chsh -s /usr/bin/fish "$USER" >>"$LOG_FILE" 2>&1 || true
    ok "Default shell updated."
fi

echo -e "\n${BOLD}${C_OK} Installation complete, enjoy ;)${C_DEF}\n"
kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
exit 0