-- pywal-generated palette
local home = os.getenv("HOME")
local ok, palette = pcall(dofile, home .. "/.cache/wal/colors-hyprland.lua")
if not ok or type(palette) ~= "table" then palette = {} end

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 10,
        border_size = 2,

        col = {
            active_border = {
                colors = {
                    palette.color4 or "rgb(7aa2f7)",
                    palette.color2 or "rgb(9ece6a)",
                },
                angle = 45,
            },
            inactive_border = "rgba(00000000)",
        },

        layout                  = "dwindle",
        resize_on_border        = true,
        extend_border_grab_area = 15,
        hover_icon_on_border    = true,
        allow_tearing           = false,
    },
})
