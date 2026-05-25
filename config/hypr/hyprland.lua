-- quantum ✦ hyprland.lua

local home = os.getenv("HOME")

require("env")
require("variables")
require("general")
require("decoration")
require("animations")
require("keybinds")
require("windowrules")
require("startup")

local function load_if(p) pcall(dofile, p) end

load_if(home .. "/dotfiles/local/hypr-local.lua")
load_if(home .. "/dotfiles/local/user-keybinds.lua")
