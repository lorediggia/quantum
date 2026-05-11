hl.on("hyprland.start", function()
    -- core
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- awww 
    hl.exec_cmd("awww-daemon")

    -- shell
    hl.exec_cmd("/usr/bin/quickshell")

    -- cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
end)
