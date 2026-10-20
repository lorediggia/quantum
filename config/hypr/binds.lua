local env = require("env")
local M, dsp = env.mod, hl.dsp

local function bind(keys, action, description, flags)
    local with = { description = description }
    for flag, value in pairs(flags or {}) do with[flag] = value end
    hl.bind(keys, action, with)
end
local function shell(target, call) return dsp.exec_cmd("quickshell ipc call " .. target .. " " .. call) end
local function toggle(surface) return shell("shell", "toggle " .. surface) end

bind(M .. " + RETURN", dsp.exec_cmd(env.terminal), "Terminal")
hl.bind("SUPER + E", hl.dsp.exec_cmd("nautilus --new-window"), { description = "Launch Nautilus in a new window" })
bind(M .. " + B",      dsp.exec_cmd(env.browser),  "Browser")
bind(M .. " + TAB",    toggle("launcher"),         "App launcher")
bind(M .. " + W",      toggle("wallpapers"),       "Wallpapers")
bind(M .. " + X",      toggle("sidebar"),          "Sidebar")
bind(M .. " + Z",      toggle("overview"),         "Window overview")
bind(M .. " + L",      dsp.exec_cmd("hyprlock"),   "Lock screen")
bind(M .. " + C",      shell("caffeine", "toggle"), "Keep awake (caffeine)")

local shots = "~/pictures/Screenshots"
bind(M .. " + S",         dsp.exec_cmd("pgrep -x slurp >/dev/null || grimblast --notify copy area"),   "Screenshot area")
bind(M .. " + SHIFT + S", dsp.exec_cmd("pgrep -x grim >/dev/null || grimblast --notify copy screen"),  "Screenshot screen")
bind(M .. " + G",         dsp.exec_cmd(("mkdir -p %s && grim %s/$(date +%%Y%%m%%d-%%H%%M%%S).png"):format(shots, shots)), "Screenshot to file")

bind(M .. " + Q",         dsp.window.close(),                         "Close window")
bind(M .. " + R",         dsp.window.float(),                         "Toggle floating")
bind(M .. " + F",         dsp.window.fullscreen(),                    "Fullscreen")
bind(M .. " + D",         dsp.window.fullscreen({ mode = "maximized" }), "Maximize")
bind(M .. " + M",         dsp.window.move({ workspace = "special:minimized", follow = false }), "Minimize window")
bind(M .. " + SHIFT + M", dsp.workspace.toggle_special("minimized"),  "Show minimized")
bind(M .. " + mouse:272", dsp.window.drag(),   "Drag window",   { mouse = true })
bind(M .. " + mouse:273", dsp.window.resize(), "Resize window", { mouse = true })

for _, dir in ipairs({ "left", "right", "up", "down" }) do
    bind(M .. " + " .. dir,         dsp.focus({ direction = dir }),       "Focus " .. dir)
    bind(M .. " + SHIFT + " .. dir, dsp.window.move({ direction = dir }), "Move window " .. dir)
end

local numpad = { "KP_End", "KP_Down", "KP_Next", "KP_Left", "KP_Begin", "KP_Right", "KP_Home", "KP_Up", "KP_Prior" }
for i = 1, 10 do
    bind(M .. " + " .. i % 10,         dsp.focus({ workspace = i }),       "Workspace " .. i)
    bind(M .. " + SHIFT + " .. i % 10, dsp.window.move({ workspace = i }), "Move to workspace " .. i)
    if numpad[i] then bind(M .. " + " .. numpad[i], dsp.focus({ workspace = i }), "Workspace " .. i) end
end
bind(M .. " + mouse_down", dsp.focus({ workspace = "e-1" }), "Previous workspace")
bind(M .. " + mouse_up",   dsp.focus({ workspace = "e+1" }), "Next workspace")

local locked, held = { locked = true }, { locked = true, repeating = true }
bind("XF86AudioRaiseVolume",  shell("volume", "up"),               "Volume up",       held)
bind("XF86AudioLowerVolume",  shell("volume", "down"),             "Volume down",     held)
bind("XF86AudioMute",         shell("volume", "mute"),             "Mute",            locked)
bind("XF86AudioMicMute",      shell("volume", "micmute"),          "Mute microphone", locked)
bind("XF86MonBrightnessUp",   shell("brightness", "up"),           "Brightness up",   held)
bind("XF86MonBrightnessDown", shell("brightness", "down"),         "Brightness down", held)
bind("XF86AudioPlay",         shell("media", "toggle"),            "Play / pause",    locked)
bind("XF86AudioNext",         shell("media", "next"),              "Next track",      locked)
bind("XF86AudioPrev",         shell("media", "prev"),              "Previous track",  locked)
