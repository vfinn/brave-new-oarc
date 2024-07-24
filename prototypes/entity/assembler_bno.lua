-- based on: TheReturnOfUtraFastAssemblingMachine_0.0.1

-- set crafting speed
local BNO_Assembler_Crafting_Speed = settings.startup["bno-assembler-choice"].value
if BNO_Assembler_Crafting_Speed > 0 then
-- 1000 +(lvl/2) x (lvl x 40) 
if BNO_Assembler_Crafting_Speed > 50 then BNO_Assembler_Crafting_Speed = 10 end
local powerCost = 1000 + (BNO_Assembler_Crafting_Speed / 2) * (BNO_Assembler_Crafting_Speed * 40)

data:extend(
{
	{
		type = "explosion",
		name = "huge-explosion",
		localised_description = {"entity-description.assembling-machine-bno"},

		animation_speed = 5,
		animations =
		{
			{
				filename = "__base__/graphics/entity/big-explosion/big-explosion.png",
				priority = "extra-high",
				frame_width = 111,
				frame_height = 131,
				frame_count = 24,
				line_length = 5,
				height = 22,
				width = 26
			}
		},
		light = {intensity = 1, size = 50},
		smoke = "smoke",
		smoke_count = 20,
		smoke_slow_down_factor = 1,
		sound =
		{
			{
			filename = "__base__/sound/fight/old/huge-explosion.ogg",
			volume = 1.25
			}
		}
	},	
	-- TECHNOLOGY
	{
		type = "technology",
		name = "assembling-machine-bno",
		icon_size = 256,
		icon = "__brave-new-oarc__/graphics/entity/bno-assembling-machine/automation-bno-tech.png",
	--   icon = "__base__/graphics/technology/automation-3.png",
	--   tint = {r = 0.95, g = 0.25, b = 0.05, a = 1},
		effects =
		{
			{
			type = "unlock-recipe",
			recipe = "assembling-machine-bno"
			}
		},
		prerequisites = {"automation-3"},
		unit =
		{
			count = 500,
			ingredients =
			{
			{"automation-science-pack", 1},
			{"logistic-science-pack", 1},
			{"chemical-science-pack", 1},
			{"production-science-pack", 1}
			},
			time = 60
		},
		order = "a-b-c"
	},
    -- RECIPE
	{
		type = "recipe",
		name = "assembling-machine-bno",
		enabled = false,
		ingredients =
		{
			{"speed-module", 12},
			{"assembling-machine-3", 4}
		},
		result = "assembling-machine-bno"
	},
	-- ITEM
	{
		type = "item",
		name = "assembling-machine-bno",
		icon = "__brave-new-oarc__/graphics/entity/bno-assembling-machine/assembling-machine-bno-icon.png",
		icon_size = 64,
		-- flags = {"goes-to-quickbar"},
		subgroup = "production-machine",
		order = "c[assembling-machine-4]",
		place_result = "assembling-machine-bno",
		stack_size = 50,
		scale=.75
	},
    -- ASSEMBLING MACHINE
	{
		type = "assembling-machine",
		name = "assembling-machine-bno",
		icon = "__brave-new-oarc__/graphics/entity/bno-assembling-machine/assembling-machine-bno-icon.png",
		icon_size = 64,
		flags = {"placeable-neutral","placeable-player", "player-creation"},
		minable = {hardness = 0.2, mining_time = 0.5, result = "assembling-machine-bno"},
		max_health = 800,
		corpse = "big-remnants",
		dying_explosion = "medium-explosion",
		alert_icon_shift = util.by_pixel(-3, -12),
		resistances =
		{
			{
			type = "fire",
			percent = 70
			}
		},
--		fluid_boxes =
--		{
--			{
--				production_type = "input",
--				pipe_picture = assembler3pipepictures(),
--				pipe_covers = pipecoverspictures(),
--				base_area = 10,
--				base_level = -1,
--				pipe_connections = {{ type="input", position = {0, -2.5} }},
--				secondary_draw_orders = { north = -1 }
--			},
--			{
--				production_type = "output",
--				pipe_picture = assembler3pipepictures(),
--				pipe_covers = pipecoverspictures(),
--				base_area = 10,
--				base_level = 1,
--				pipe_connections = {{ type="output", position = {0, 2.5} }},
--				secondary_draw_orders = { north = -1 }
--			},
--			off_when_no_fluid_recipe = true
--		},
		open_sound = { filename = "__base__/sound/machine-open.ogg", volume = 0.85 },
		close_sound = { filename = "__base__/sound/machine-close.ogg", volume = 0.75 },
		vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
		working_sound =
		{
			sound = {
				{
					filename = "__base__/sound/assembling-machine-t3-1.ogg",
					volume = 0.8
				},
				{
					filename = "__base__/sound/assembling-machine-t3-2.ogg",
					volume = 0.8
				},
			},
			idle_sound = { filename = "__base__/sound/idle1.ogg", volume = 0.6 },
			apparent_volume = 1.5,
		},
		collision_box = {{-2, -2}, {2, 2}},
		selection_box = {{-2, -2}, {2, 2}},
		drawing_box = {{-1.5, -1.7}, {1.5, 1.5}},
		fast_replaceable_group = "assembling-machine",
		animation =
		{
			layers =
			{
				{
					filename = "__brave-new-oarc__/graphics/entity/bno-assembling-machine/assembling-machine-bno-entity.png",
					priority = "high",
					width = 108,
					height = 119,
					frame_count = 1,
					line_length = 1,
					shift = util.by_pixel(0, -0.5),
					hr_version = {
					filename = "__brave-new-oarc__/graphics/entity/bno-assembling-machine/hr-assembling-machine-bno-entity.png",
					priority = "high",
					width = 214,
					height = 237,
					frame_count = 1,
					line_length = 1,
					shift = util.by_pixel(0, -0.75),
					scale = .75
					}
				},
				{
					filename = "__base__/graphics/entity/assembling-machine-3/assembling-machine-3-shadow.png",
					priority = "high",
					width = 130,
					height = 82,
					frame_count = 1,
					line_length = 1,
					draw_as_shadow = true,
					shift = util.by_pixel(28, 4),
					hr_version = {
					filename = "__base__/graphics/entity/assembling-machine-3/hr-assembling-machine-3-shadow.png",
					priority = "high",
					width = 260,
					height = 162,
					frame_count = 1,
					line_length = 1,
					draw_as_shadow = true,
					shift = util.by_pixel(28, 4),
					scale = .75
					}
				},
			},
		},

		crafting_categories = {"crafting", "advanced-crafting", "crafting-with-fluid","chemistry"},
		crafting_speed = BNO_Assembler_Crafting_Speed,
		energy_source =
		{
			type = "electric",
			usage_priority = "secondary-input",
			emissions_per_minute = BNO_Assembler_Crafting_Speed / 2
		},
		energy_usage = string.format("%dkW", powerCost),
		ingredient_count = 10,
		module_specification =
		{
			module_slots = 5
		},
		allowed_effects = {"consumption", "speed", "productivity", "pollution"}
	},
}
)
end