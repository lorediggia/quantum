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
    opacity   = "0.80 override 0.80 override 1.0 override",
})

hl.window_rule({
    name      = "pulseaudio-popup",
    match     = { class = [[^(pavucontrol|org\.pulseaudio\.pavucontrol)$]] },
    float     = true,
    size      = { 700, 500 },
    center    = true,
    opacity   = "0.80 override 0.80 override 1.0 override",
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

hl.layer_rule({
    name    = "quickshell-frame-no-anim",
    match   = { namespace = "quickshell-frame" },
    no_anim = true,
})

hl.layer_rule({
    name    = "disable-picker-anim",
    match   = { namespace = [[^(hyprpicker)$]] },
    no_anim = true,
})

hl.layer_rule({
    name    = "disable-slurp-anim",
    match   = { namespace = "selection" },
    no_anim = true,
})
