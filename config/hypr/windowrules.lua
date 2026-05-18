-- global glass
hl.window_rule({
    name        = "global-glass",
    match       = { class = ".*" },
    --opacity     = "0.85 override 0.80 override 1.0 override",
    border_size = 0,
})

-- floating dialogs
hl.window_rule({
    name   = "system-dialogs",
    match  = { class = [[.*(xdg-desktop-portal-gtk|zenity|kdialog).*]] },
    float  = true,
    size   = { 800, 600 },
    center = true,
})

hl.window_rule({
    name   = "blueman-popup",
    match  = { class = [[^(blueman-manager)$]] },
    float  = true,
    size   = { 700, 500 },
    center = true,
})

hl.window_rule({
    name      = "pulseaudio-popup",
    match     = { class = [[^(pavucontrol|org\.pulseaudio\.pavucontrol)$]] },
    float     = true,
    size      = { 700, 500 },
    center    = true,
    animation = "popin",
})

hl.window_rule({
    name   = "file-picker",
    match  = { title = [[^(Open.*|Apri.*|Save.*|Salva.*|Select.*|Seleziona.*)$]] },
    float  = true,
    size   = { 900, 600 },
    center = true,
})

-- performance overrides
hl.window_rule({
    name     = "games-no-glass",
    match    = { class = [[^(steam_app_.*|gamescope|.*\.exe)$]] },
    opacity  = "1.0 override 1.0 override 1.0 override",
    no_blur  = true,
    rounding = 0,
})

hl.window_rule({
    name    = "media-no-glass",
    match   = { class = [[^(mpv|vlc|io\.mpv\.Mpv|org\.videolan\.VLC)$]] },
    opacity = "1.0 override 1.0 override 1.0 override",
    no_blur = true,
})

hl.window_rule({
    name    = "fullscreen-no-glass",
    match   = { fullscreen = true },
    opacity = "1.0 override 1.0 override 1.0 override",
    no_blur = true,
})

-- layer rules
hl.layer_rule({
    name         = "quickshell-glass",
    match        = { namespace = [[^quickshell.*]] },
    blur         = true,
    ignore_alpha = 0.1,
    xray         = true,
})

hl.layer_rule({
    name         = "rofi-glass",
    match        = { namespace = "rofi" },
    blur         = true,
    ignore_alpha = 0.2,
    xray         = true,
    animation    = "slide top",
})

hl.layer_rule({
    name         = "wallpicker-glass",
    match        = { namespace = "wallpicker" },
    blur         = true,
    xray         = true,
    ignore_alpha = 0.5,
    animation    = "slide bottom",
})

hl.layer_rule({
    name    = "disable-picker-anim",
    match   = { namespace = [[^(hyprpicker)$]] },
    no_anim = true,
})
