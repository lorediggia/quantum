hl.config({ animations = { enabled = true } })

-- curves
hl.curve("decel",     { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.0} } })
hl.curve("smoothOut", { type = "bezier", points = { {0.16, 1.0}, {0.3, 1.0} } })
hl.curve("wsSmooth",  { type = "bezier", points = { {0.22, 1.0}, {0.36, 1.0} } })
hl.curve("linear",    { type = "bezier", points = { {0, 0},      {1, 1}      } })

-- windows
hl.animation({ leaf = "windows",     enabled = true, speed = 6, bezier = "wsSmooth", style = "slide" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 6, bezier = "wsSmooth", style = "slide" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 5, bezier = "wsSmooth", style = "slide" })
hl.animation({ leaf = "fade",        enabled = true, speed = 5, bezier = "smoothOut" })
hl.animation({ leaf = "border",      enabled = true, speed = 8, bezier = "smoothOut" })

-- workspaces
hl.animation({ leaf = "workspaces",       enabled = true, speed = 7, bezier = "wsSmooth", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 7, bezier = "wsSmooth", style = "slidevert" })

-- layers
hl.animation({ leaf = "layers",    enabled = true, speed = 6, bezier = "decel" })
hl.animation({ leaf = "layersIn",  enabled = true, speed = 6, bezier = "decel",     style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 5, bezier = "smoothOut", style = "slide" })
