local home = os.getenv("HOME")

local function repo()
    local link = io.popen('readlink -f "$HOME/.config/hypr"')
    local path = link:read("l")
    link:close()
    return path and path:match("^(.*)/config/hypr$")
end

local M = {
    dotfiles = os.getenv("DOTFILES") or repo() or home .. "/dotfiles",
    mod      = "SUPER",
    terminal = "kitty",
    files    = "nautilus",
    browser  = "helium-browser",
}
local cursor = "Bibata-Modern-Classic"

for name, value in pairs({
    DOTFILES                            = M.dotfiles,
    PATH                                = M.dotfiles .. "/bin:" .. home .. "/.local/bin:" .. os.getenv("PATH"),
    XDG_SESSION_DESKTOP                 = "Hyprland",
    ELECTRON_OZONE_PLATFORM_HINT        = "wayland",
    SDL_VIDEODRIVER                     = "wayland",
    QT_QPA_PLATFORM                     = "wayland;xcb",
    QT_QPA_PLATFORMTHEME                = "qt6ct",
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1",
    QS_ICON_THEME                       = "WhiteSur-dark",
    XCURSOR_THEME                       = cursor,
    HYPRCURSOR_THEME                    = cursor,
    XCURSOR_SIZE                        = "24",
    HYPRCURSOR_SIZE                     = "24",
}) do hl.env(name, value) end

return M
