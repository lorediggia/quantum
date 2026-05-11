--  ╭──────────────────────────────────────────╮
--            quantum ✦ hyprland.lua                 
-- ╰──────────────────────────────────────────╯
local home = os.getenv("HOME")

-- env + program variables
require("env")
require("variables")

-- appearance
require("general")
require("decoration")
require("animations")

-- input + rules
require("keybinds")
require("windowrules")

-- hw + startup
require("startup")

-- helper
local function load_if(p)
    local f = io.open(p)
    if f then f:close(); dofile(p) end
end

-- local hardware overrides
load_if(home .. "/dotfiles/local/hypr-local.lua")

-- user-managed keybinds (auto-generated)
load_if(home .. "/dotfiles/local/user-keybinds.lua")
