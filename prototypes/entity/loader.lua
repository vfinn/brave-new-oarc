--myLoader = data.raw.roboport["loader"]
local myLoader = util.table.deepcopy(data.raw["loader"]["loader"])
myLoader.name = "loader"
myLoader.type = "loader"
myLoader.icon_size = 64
--myLoader.collision_box = { { -0.4, -0.9 }, { 0.4, 0.9 } }
--myLoader.selection_box = { { -0.5, -1 }, { 0.5, 1 } }
myLoader.collision_box = { { -0.4, -0.9 }, { 0.4, 0.9 } }
myLoader.selection_box = { { -0.5, -1 }, { 0.5, 1 } }
--      speed = 0.5 / 32,
myLoader.max_distance = 1  -- 3
myLoader.tile_width = 1
myLoader.tile_height = 2
container_distance = 1
myLoader.structure = 
{
    direction_in = 
    {
        sheet = 
        {
            filename = "__brave-new-oarc__/graphics/entity/loader/loader-structure.png",
            width = 64,
            height = 64,
            scale = 0.5,
            priority = "extra-high"
        },
    },
    direction_out = 
    {
        sheet = 
        {
            filename = "__brave-new-oarc__/graphics/entity/loader/loader-structure.png",
            width = 64,
            height = 64,
            scale = 0.5,
            priority = "extra-high",
            y = 64
        },
    },
 }
 data:extend({myLoader})