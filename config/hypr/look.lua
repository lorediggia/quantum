hl.config({
    general = {
        gaps_in          = 6,
        gaps_out         = 16,
        border_size      = 0,
        resize_on_border = true,
    },
    decoration = {
        rounding = 15,
        shadow   = { enabled = false },
        blur     = { size = 8, passes = 2, noise = 0.01, contrast = 1.1, brightness = 1.2, xray = true },
    },
    render    = { direct_scanout = 1 },
    misc      = { disable_hyprland_logo = true, disable_splash_rendering = true, force_default_wallpaper = 0 },
    ecosystem = { no_update_news = true },
})

local function bezier(name, a, b) hl.curve(name, { type = "bezier", points = { a, b } }) end
bezier("decel",  { 0.05, 0.9 }, { 0.1, 1.0 })
bezier("smooth", { 0.16, 1.0 }, { 0.3, 1.0 })
bezier("glide",  { 0.22, 1.0 }, { 0.36, 1.0 })

for _, a in ipairs({
    { "windows",          6, "glide",  "slide" },
    { "windowsOut",       5, "glide",  "slide" },
    { "fade",             5, "smooth" },
    { "workspaces",       7, "glide",  "slide" },
    { "specialWorkspace", 7, "glide",  "slidevert" },
    { "layers",           6, "decel",  "slide" },
    { "layersOut",        5, "smooth", "slide" },
}) do
    hl.animation({ leaf = a[1], enabled = true, speed = a[2], bezier = a[3], style = a[4] })
end
