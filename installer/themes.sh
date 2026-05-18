if on GTK; then
    run "Installing WhiteSur GTK Theme" bash -c '
        tmp=$(mktemp -d)
        git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$tmp"
        cd "$tmp" && ./install.sh -t default
        rm -rf "$tmp"
    '
    run "Installing WhiteSur Icon Theme" bash -c '
        tmp=$(mktemp -d)
        git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$tmp"
        cd "$tmp" && ./install.sh
        rm -rf "$tmp"
    '
    gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Dark" || true
    gsettings set org.gnome.desktop.interface icon-theme "WhiteSur" || true
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" || true
fi

if on CURSOR; then
    mkdir -p "$HOME/.icons/default"
    printf '[Icon Theme]\nInherits=Bibata-Modern-Classic\n' > "$HOME/.icons/default/index.theme"
fi

if on FONT; then run "Refreshing font cache" fc-cache -f; fi