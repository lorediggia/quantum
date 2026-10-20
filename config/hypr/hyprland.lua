local env = require("env")
require("look")
require("rules")
require("binds")
require("autostart")

local overrides = io.open(env.dotfiles .. "/local/hypr-local.lua")
if overrides then
    overrides:close()
    dofile(env.dotfiles .. "/local/hypr-local.lua")
end
