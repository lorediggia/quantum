local vars = require("variables")
local m    = vars.mainMod

-- apps
hl.bind(m .. " + RETURN",            hl.dsp.exec_cmd(vars.terminal))
hl.bind(m .. " + Q",                 hl.dsp.window.close())
hl.bind(m .. " + E",                 hl.dsp.exec_cmd(vars.fileManager))
hl.bind(m .. " + B",                 hl.dsp.exec_cmd(vars.browser))
hl.bind(m .. " + TAB",               hl.dsp.exec_cmd(vars.menu))
hl.bind(m .. " + W",                 hl.dsp.exec_cmd("quickshell ipc call wall_e toggle '[]'"))
hl.bind(m .. " + X",                 hl.dsp.exec_cmd("sidebar"))
hl.bind(m .. " + S",                 hl.dsp.exec_cmd([[sh -c 'GEOM=$(slurp -b 00000044 -c ffffff -w 2) && grim -t png -g "$GEOM" - | wl-copy']]))
hl.bind(m .. " + F",                 hl.dsp.exec_cmd("sh -c 'grim - | wl-copy'"))
hl.bind(m .. " + Z",                 hl.dsp.exec_cmd("topbar"))
hl.bind(m .. " + K",                 hl.dsp.exec_cmd("keybinds"))
hl.bind(m .. " + G",                 hl.dsp.exec_cmd([[sh -c 'grim "$HOME/Pictures/$(date +%Y%m%d-%H%M%S).png"']]))
hl.bind(m .. " + L",                 hl.dsp.exec_cmd("hyprlock"))

-- window
hl.bind(m .. " + R",         hl.dsp.window.float())

-- mouse
hl.bind(m .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(m .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- focus
hl.bind(m .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(m .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(m .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(m .. " + down",  hl.dsp.focus({ direction = "d" }))

-- move window
hl.bind(m .. " + SHIFT + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(m .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(m .. " + SHIFT + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(m .. " + SHIFT + down",  hl.dsp.window.move({ direction = "d" }))

-- workspaces 1..10
for i = 1, 10 do
    local k = (i == 10) and "0" or tostring(i)
    hl.bind(m .. " + " .. k,         hl.dsp.focus({ workspace = i }))
    hl.bind(m .. " + SHIFT + " .. k, hl.dsp.window.move({ workspace = i }))
end

-- numpad workspaces
local numpad = {
    KP_End = 1, KP_Down = 2, KP_Next = 3, KP_Left = 4, KP_Begin = 5,
    KP_Right = 6, KP_Home = 7, KP_Up = 8, KP_Prior = 9,
}
for key, ws in pairs(numpad) do
    hl.bind(m .. " + " .. key, hl.dsp.focus({ workspace = ws }))
end

hl.bind(m .. " + mouse_down", hl.dsp.focus({ workspace = "+1" }))
hl.bind(m .. " + mouse_up",   hl.dsp.focus({ workspace = "-1" }))
