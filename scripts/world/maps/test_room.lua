-- Minimal Tiled-compatible room used as the post-battle destination.
-- It intentionally has no external tileset or art dependency.
return {
    version = "1.10",
    luaversion = "5.1",
    tiledversion = "1.10.2",
    class = "",
    orientation = "orthogonal",
    renderorder = "right-down",
    width = 20,
    height = 15,
    tilewidth = 40,
    tileheight = 40,
    nextlayerid = 2,
    nextobjectid = 2,
    properties = {name = "Ten Shadows Test Room"},
    tilesets = {},
    layers = {
        {
            type = "objectgroup",
            draworder = "topdown",
            id = 1,
            name = "markers",
            class = "",
            visible = true,
            opacity = 1,
            offsetx = 0,
            offsety = 0,
            parallaxx = 1,
            parallaxy = 1,
            properties = {},
            objects = {
                {
                    id = 1,
                    name = "spawn",
                    type = "",
                    shape = "point",
                    x = 400,
                    y = 300,
                    width = 0,
                    height = 0,
                    rotation = 0,
                    opacity = 1,
                    visible = true,
                    properties = {}
                }
            }
        }
    }
}
