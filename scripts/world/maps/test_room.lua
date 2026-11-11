-- Functional, asset-independent test chamber with a bounded floor and spawn.
return {
    version = "1.10", luaversion = "5.1", tiledversion = "1.10.2",
    class = "", orientation = "orthogonal", renderorder = "right-down",
    width = 16, height = 12, tilewidth = 40, tileheight = 40,
    infinite = false, backgroundcolor = {23, 27, 43, 255},
    nextlayerid = 5, nextobjectid = 7,
    properties = {name = "Ten Shadows Test Chamber"},
    tilesets = {},
    layers = {
        {
            type = "tilelayer", id = 1, name = "floor", class = "", encoding = "lua",
            width = 16, height = 12, x = 0, y = 0,
            opacity = 1, visible = true, offsetx = 0, offsety = 0,
            parallaxx = 1, parallaxy = 1, properties = {},
            data = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
        },
        {
            type = "objectgroup", id = 2, name = "collision", class = "collision",
            draworder = "topdown", visible = true, opacity = 1,
            offsetx = 0, offsety = 0, parallaxx = 1, parallaxy = 1,
            properties = {},
            objects = {
                {id=1, name="north_wall", class="", x=0, y=0, width=640, height=40, rotation=0, visible=true, properties={}},
                {id=2, name="south_wall", class="", x=0, y=440, width=640, height=40, rotation=0, visible=true, properties={}},
                {id=3, name="west_wall", class="", x=0, y=0, width=40, height=480, rotation=0, visible=true, properties={}},
                {id=4, name="east_wall", class="", x=600, y=0, width=40, height=480, rotation=0, visible=true, properties={}}
            }
        },
        {
            type = "objectgroup", id = 3, name = "markers", class = "markers",
            draworder = "topdown", visible = true, opacity = 1,
            offsetx = 0, offsety = 0, parallaxx = 1, parallaxy = 1,
            properties = {},
            objects = {
                {id=5, name="spawn", class="", shape="point", x=320, y=360, width=0, height=0, rotation=0, visible=true, properties={}}
            }
        }        ,
        {
            type = "objectgroup", id = 4, name = "objects", class = "objects",
            draworder = "topdown", visible = true, opacity = 1,
            offsetx = 0, offsety = 0, parallaxx = 1, parallaxy = 1,
            properties = {},
            objects = {
                {id=6, name="savepoint", class="", shape="rectangle", x=300, y=260, width=40, height=40, rotation=0, visible=true, properties={marker="spawn", heals=true, text1_1="* The shadows gather quietly around you.", text1_2="* Your party is restored. The power of the Ten Shadows shines within you."}}
            }
        }
    }
}