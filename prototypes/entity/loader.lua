--myLoader = data.raw.roboport["loader"]
local myLoader = util.table.deepcopy(data.raw["loader-1x1"]["loader-1x1"])
myLoader.name = "loader-1x1"
myLoaderq.type = "loader-1x1"
myLoader.icon_size = 64
--myLoader.collision_box = { { -0.4, -0.9 }, { 0.4, 0.9 } }
--myLoader.selection_box = { { -0.5, -1 }, { 0.5, 1 } }

--myLoader.collision_box = { { -0.4,  -1 }, { 0.4, 0.1 } }   -- this was good but flipped oddly
myLoader.collision_box = { { -0.4,  -0.4 }, { 0.4, 0.4 }}   -- this was good but flipped oddly
myLoader.selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } }
myLoader.icon = "__brave-new-oarc__/graphics/icons/loader.png"
--      speed = 0.5 / 32,
myLoader.max_distance = 1
myLoader.tile_width = 1
myLoader.tile_height = 1
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
            scale =0.5,
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