-- core
hl.env("PATH",                                os.getenv("HOME") .. "/.local/bin:" .. (os.getenv("PATH") or ""))
hl.env("XDG_SESSION_TYPE",                    "wayland")
hl.env("XDG_CURRENT_DESKTOP",                 "Hyprland")
hl.env("XDG_SESSION_DESKTOP",                 "Hyprland")

-- wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT",        "wayland")
hl.env("MOZ_ENABLE_WAYLAND",                  "1")
hl.env("QT_QPA_PLATFORM",                     "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("SDL_VIDEODRIVER",                     "wayland")

-- scaling + cursors
hl.env("GDK_SCALE",        "1")
hl.env("QT_SCALE_FACTOR",  "1")
hl.env("XCURSOR_SIZE",     "24")
hl.env("HYPRCURSOR_SIZE",  "24")
hl.env("XCURSOR_THEME",    "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
