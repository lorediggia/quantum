hl.config({
    decoration = {
        rounding         = 15,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_inactive     = false,

        blur = {
            enabled        = true,
            size           = 8,
            passes         = 2,
            ignore_opacity = true,
            xray           = true,
            noise          = 0.01,
            contrast       = 1.1,
            brightness     = 1.2,
            vibrancy       = 0.17,
        },

        shadow = {
            enabled = false,
        },
    },
})
