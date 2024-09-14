-- based on: TheReturnOfUtraFastAssemblingMachine_0.0.1
local BNO_Assembler_Crafting_Speed = settings.startup["bno-assembler-choice"].value
if BNO_Assembler_Crafting_Speed > 0 then
if BNO_Assembler_Crafting_Speed > 10 then BNO_Assembler_Crafting_Speed = 10 end

local assembling_machine = function(name, level, BNO_Assembler_Crafting_Speed, powerCost, color, ingredients, next_upgrade)
return {
	{
		type = "explosion",
		name = "huge-explosion",
		localised_description = {"entity-description." .. name},

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
		name = "automation-"..tostring(level), 
		icon_size = 256,
		icon = "__brave-new-oarc__/graphics/entity/bno-assembling-machine/automation-bno-tech"..color..".png",
		effects =
		{
			{
			type = "unlock-recipe",
			recipe = name		-- "assembling-machine-4", 5, 6
			}
		},
		prerequisites = {"automation-"..tostring(level-1)},	-- automation-3, 4 ,5
		unit =
		{
			count = (level-1)*100,
			ingredients = ingredients,
			time = 60
		},
		order = "a-b-c"
	},
    -- RECIPE
	{
		type = "recipe",
		name = name,
		enabled = false,
		ingredients =
		{
			{"speed-module", BNO_Assembler_Crafting_Speed * (level-2)},
			{"assembling-machine-"..tostring(level-1), 4}
		},
		result = name
	},
	-- ITEM
	{
		type = "item",
		name = name,
		icon = "__brave-new-oarc__/graphics/entity/bno-assembling-machine/assembling-machine-bno-icon"..color..".png",
		icon_size = 64,
		-- flags = {"goes-to-quickbar"},
		subgroup = "production-machine",
		order = "c[assembling-machine-4]",
		place_result = name,
		stack_size = 50,
		scale=.75
	},
    -- ASSEMBLING MACHINE
	{
		type = "assembling-machine",
		name = name,
		icon = "__brave-new-oarc__/graphics/entity/bno-assembling-machine/assembling-machine-bno-icon"..color..".png",
		icon_size = 64,
		flags = {"placeable-neutral","placeable-player", "player-creation"},
		minable = {hardness = 0.2, mining_time = 0.5, result = name},
		max_health = level*200,		-- 		previously 800 - 40 damage every second = 20 seconds, now 800, 1000, 1200
		next_upgrade=next_upgrade[level-3],
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
		fluid_boxes =
		{
			{
				production_type = "input",
				pipe_picture = assembler3pipepictures(),
				pipe_covers = pipecoverspictures(),
				base_area = 10,
				base_level = 0,
				pipe_connections = {{ type="input-output", position = {0.5, -2.5} }},
				secondary_draw_orders = { north = -1 }
			},
			{
				production_type = "input",
				pipe_picture = assembler3pipepictures(),
				pipe_covers = pipecoverspictures(),
				base_area = 10,
				base_level = 0,
				pipe_connections = {{ type="input-output", position = {-0.5, -2.5} }},
				secondary_draw_orders = { north = -1 }
			},
			{
				production_type = "input",
				pipe_picture = assembler3pipepictures(),
				pipe_covers = pipecoverspictures(),
				base_area = 10,
				base_level = 0,
				pipe_connections = {{ type="input-output", position = {0.5, 2.5} }},
				secondary_draw_orders = { north = -1 }
			},
			{
				production_type = "input",
				pipe_picture = assembler3pipepictures(),
				pipe_covers = pipecoverspictures(),
				base_area = 10,
				base_level = 0,
				pipe_connections = {{ type="input-output", position = {-0.5, 2.5} }},
				secondary_draw_orders = { north = -1 }
			},
			{
				production_type = "output",
				pipe_picture = assembler3pipepictures(),
				pipe_covers = pipecoverspictures(),
				base_area = 10,
				base_level = 1,
				pipe_connections = {{ type="input-output", position = {2.5, 0.5} }},
				secondary_draw_orders = { north = -1 }
			},
			{
				production_type = "output",
				pipe_picture = assembler3pipepictures(),
				pipe_covers = pipecoverspictures(),
				base_area = 10,
				base_level = 1,
				pipe_connections = {{ type="input-output", position = {2.5, -0.5} }},
				secondary_draw_orders = { north = -1 }
			},
			{
				production_type = "output",
				pipe_picture = assembler3pipepictures(),
				pipe_covers = pipecoverspictures(),
				base_area = 10,
				base_level = 1,
				pipe_connections = {{ type="input-output", position = {-2.5, 0.5} }},
				secondary_draw_orders = { north = -1 }
			},
			{
				production_type = "output",
				pipe_picture = assembler3pipepictures(),
				pipe_covers = pipecoverspictures(),
				base_area = 10,
				base_level = 1,
				pipe_connections = {{ type="input-output", position = {-2.5, -0.5} }},
				secondary_draw_orders = { north = -1 }
			},
			off_when_no_fluid_recipe = true
		},
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
					filename = "__brave-new-oarc__/graphics/entity/bno-assembling-machine/assembling-machine-bno-entity"..color..".png",
					priority = "high",
					width = 108,
					height = 119,
					scale = 1.5,
					frame_count = 1,
					line_length = 1,
					shift = util.by_pixel(0, -0.5),
					hr_version = {
						filename = "__brave-new-oarc__/graphics/entity/bno-assembling-machine/hr-assembling-machine-bno-entity"..color..".png",
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
					scale = 1.50,
					draw_as_shadow = true,
					shift = util.by_pixel(48, 4),
					hr_version = {
						filename = "__base__/graphics/entity/assembling-machine-3/hr-assembling-machine-3-shadow.png",
						priority = "high",
						width = 260,
						height = 162,
						frame_count = 1,
						line_length = 1,
						draw_as_shadow = true,
						shift = util.by_pixel(48, 4),
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
end


math.log5 = function (x)
	return math.log(x) / math.log(5)
end

local color = {"-red", "-cyan", "-green"}
local speeds = {.7, 1, 1.25}
local next_upgrade = {"assembling-machine-5", "assembling-machine-6", nil}

local ingredients=nil
for i=1,3 do
	if i==1 then
		ingredients =
		{
			{"automation-science-pack", 1},
			{"logistic-science-pack", 1},
			{"chemical-science-pack", 1},
			{"production-science-pack", 1}		}
	elseif i==2 then
		ingredients =
		{
			{"automation-science-pack", 1},
			{"logistic-science-pack", 1},
			{"chemical-science-pack", 1},
			{"production-science-pack", 1}		}
	elseif i==3 then
		ingredients =
		{
			{"automation-science-pack", 1},
			{"logistic-science-pack", 1},
			{"chemical-science-pack", 1},
			{"production-science-pack", 1},
			{"utility-science-pack", 1}
		}
	end
	-- set crafting speed

	-- more costly powerwise based on crafting speed - range 5..10 is 1172 to 5272
--	local speed = BNO_Assembler_Crafting_Speed * (i/2)
	local speed = BNO_Assembler_Crafting_Speed * speeds[i]
	local powerCost = 1000 + speed ^ (2.2 + math.log5(speed))
	-- old formula 
	--local powerCost = 1000 + (BNO_Assembler_Crafting_Speed / 2) * (BNO_Assembler_Crafting_Speed * 40)

	data:extend(assembling_machine("assembling-machine-"..tostring(i+3), i+3, speed, powerCost, color[i], ingredients, next_upgrade))
end

end 