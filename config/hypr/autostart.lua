hl.on("hyprland.start", function()
    for _, cmd in ipairs({
        "killall -q xdg-desktop-portal; /usr/lib/xdg-desktop-portal",
        "gsettings set org.gnome.desktop.interface color-scheme prefer-dark",
        "gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'",
        "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
        "awww-daemon",
        "wallpaper",
        "quickshell",
        "hypridle",
    }) do hl.exec_cmd(cmd) end
end)
