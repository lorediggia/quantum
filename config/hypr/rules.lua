local function rule(name, match, effects)
    effects.name, effects.match = name, match
    hl.window_rule(effects)
end
local function float(w, h, extra)
    local r = extra or {}
    r.float, r.center, r.size = true, true, { w, h }
    return r
end
local translucent = "0.80 override 0.80 override 1.0 override"

rule("dialogs", { class = [[.*(xdg-desktop-portal-gtk|zenity|kdialog).*]] },         float(800, 600))
rule("pickers", { title = [[^(Open|Apri|Save|Salva|Select|Seleziona).*$]] },          float(900, 600))
rule("blueman", { class = [[^blueman-manager$]] },                                   float(700, 500, { opacity = translucent }))
rule("pavu",    { class = [[^(pavucontrol|org\.pulseaudio\.pavucontrol)$]] },        float(700, 500, { opacity = translucent }))
rule("games",   { class = [[^(steam_app_.*|gamescope|.*\.exe)$]] },                  { no_blur = true, rounding = 0 })
rule("media",   { class = [[^(mpv|vlc|io\.mpv\.Mpv|org\.videolan\.VLC)$]] },         { no_blur = true })

for name, namespace in pairs({ shell = "^quickshell", picker = "^hyprpicker$", slurp = "^selection$" }) do
    hl.layer_rule({ name = name, match = { namespace = namespace }, no_anim = true })
end

