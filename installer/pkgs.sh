[[ $EUID -eq 0 ]] && exit 1
sudo -v

if ! command -v yay &>/dev/null; then
    run "Installing yay" bash -c '
        sudo pacman -S --needed --noconfirm git base-devel
        tmp=$(mktemp -d)
        git clone --depth 1 https://aur.archlinux.org/yay.git "$tmp"
        cd "$tmp" && makepkg -si --noconfirm
        rm -rf "$tmp"
    '
fi

PKGS_REPO=(git base-devel)
PKGS_AUR=()

if on HYPR;  then PKGS_REPO+=(hyprland hyprpicker polkit-gnome networkmanager power-profiles-daemon xdg-desktop-portal-hyprland xdg-desktop-portal-gtk grim slurp wl-clipboard); PKGS_AUR+=(hyprshot); fi
if on QSH;   then PKGS_AUR+=(quickshell); fi
if on TERM;  then PKGS_REPO+=(kitty starship fish); fi
if on THEME; then PKGS_AUR+=(wallust awww); fi
if on ROFI;  then PKGS_REPO+=(rofi-wayland); fi
if on HOLO;  then PKGS_REPO+=(rustup pkgconf fontconfig freetype2 gcc make); fi
if on BT;    then PKGS_REPO+=(bluez bluez-utils blueman); fi
if on AUDIO; then PKGS_REPO+=(pipewire pipewire-pulse wireplumber pavucontrol pamixer playerctl); fi
if on BTOP;  then PKGS_REPO+=(btop); fi
if on FF;    then PKGS_REPO+=(fastfetch); fi
if on FF; then PKGS_REPO+=(fastfetch chafa); fi
if on FILES; then PKGS_REPO+=(nautilus); fi
if on CURSOR; then PKGS_AUR+=(bibata-cursor-theme); fi
if on GTK;   then PKGS_REPO+=(nwg-look papirus-icon-theme sassc); fi
if on FONT;  then PKGS_REPO+=(inter-font); fi

run "Updating databases" sudo pacman -Syu --noconfirm
if (( ${#PKGS_REPO[@]} > 2 )); then run "Installing Pacman packages" sudo pacman -S --needed --noconfirm "${PKGS_REPO[@]}"; fi
if (( ${#PKGS_AUR[@]} > 0 )); then run "Installing AUR packages" yay -S --needed --noconfirm --sudoloop "${PKGS_AUR[@]}"; fi
if on HOLO; then run "Configuring Rust toolchain" rustup default stable; fi