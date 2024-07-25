-- Some of this taken from Robot_and_Radar_MK2  module !
-- This is settings for new roboport called roboport-bno
---------------------------------
-- Roboport changes
---------------------------------
roboport = data.raw.roboport["roboport"]
-- roboport.fast_replaceable_group = "roboport"
-- roboport.next_upgrade = "roboport-bno"
roboport.icon = "__brave-new-oarc__/graphics/icons/roboport-bno.png"
roboport.place_result = "roboport-bno"

---------------------------------
-- Roboport BNO
---------------------------------
roboportmain = table.deepcopy(roboport)
roboportmain.name = "roboport-bno"
--roboportmain.flags = { "hidden" }
roboportmain.localised_name = { "", "Brave New ", {"entity-name.roboport"}, ":"}
roboportmain.localised_description = { "entity-description.roboport-bno" }
roboportmain.minable.result = "roboport-bno"
-- roboportmain.fast_replaceable_group = "roboport"
roboportmain.corpse = "roboport-bno-remnants"
-- double radius

roboportmain.logistics_radius = roboportmain.logistics_radius * 2	
roboportmain.construction_radius = roboportmain.construction_radius * 2 + 3		-- slightly larger to enable access to the tree line, and water
local zoneIncrease = settings.startup["bno-increase-logistics"].value
roboportmain.logistics_radius = roboportmain.logistics_radius + zoneIncrease
roboportmain.construction_radius = roboportmain.construction_radius + zoneIncrease*2	-- to reach the large roboport-bno

-- quadruple charging capacities
roboportmain.energy_source.input_flow_limit = tostring(util.parse_energy(roboportmain.energy_source.input_flow_limit)*60*4) .. "W"
roboportmain.energy_source.buffer_capacity = tostring(util.parse_energy(roboportmain.energy_source.buffer_capacity)*4) .. "J"
roboportmain.energy_usage = tostring(util.parse_energy(roboportmain.energy_usage)*60*4) .. "W"
roboportmain.charging_energy = "1MW"

roboportmain.robot_slots_count = 20
roboportmain.material_slots_count = 8
roboportmain.charging_offsets = {
	{-1.5, 1.5}, {-0.5, 1.5}, { 0.5, 1.5}, { 1.5, 1.5},
	{-1.5, 0.5}, {-0.5, 0.5}, { 0.5, 0.5}, { 1.5, 0.5},
	{-1.5,-0.5}, {-0.5,-0.5}, { 0.5,-0.5}, { 1.5,-0.5},
	{-1.5,-1.5}, {-0.5,-1.5}, { 0.5,-1.5}, { 1.5,-1.5},
}


-- new textures
roboportmain.base.layers[1].filename =						"__brave-new-oarc__/graphics/entity/roboport-bno/roboport-bno-base.png"
roboportmain.base.layers[1].hr_version.filename =			"__brave-new-oarc__/graphics/entity/roboport-bno/hr-roboport-bno-base.png"
log ("Using large roboport with 16 charging ports")
roboportmain.collision_box = {{-2.85, -1.9}, {2.75, 3.65}}
roboportmain.selection_box = {{-2.85, -1.9}, {2.75, 3.65}}
roboportmain.base.layers[1].shift = util.by_pixel(30, 40)	-- -8
roboportmain.base.layers[1].scale = 1.80
roboportmain.base.layers[1].hr_version.shift = util.by_pixel(-8, 40)		-- this is main base
roboportmain.base.layers[1].hr_version.scale = .9

roboportmain.base.layers[2].filename = "__base__/graphics/entity/roboport/roboport-shadow.png"
roboportmain.base.layers[2].shift = util.by_pixel(36, 76)
roboportmain.base.layers[2].scale = 1.80
roboportmain.base.layers[2].hr_version.shift = util.by_pixel(36, 76)
roboportmain.base.layers[2].hr_version.scale = .9


roboportmain.base_patch.filename =							"__brave-new-oarc__/graphics/entity/roboport-bno/roboport-bno-base-patch.png"
roboportmain.base_patch.scale = 1.8
roboportmain.base_patch.shift = util.by_pixel(3,32)
roboportmain.base_patch.hr_version.filename =				"__brave-new-oarc__/graphics/entity/roboport-bno/hr-roboport-bno-base-patch.png"
roboportmain.base_patch.hr_version.scale = .9
roboportmain.base_patch.hr_version.shift= util.by_pixel(-9,36)

roboportmain.door_animation_down.filename =					"__brave-new-oarc__/graphics/entity/roboport-bno/roboport-bno-door-down.png"
roboportmain.door_animation_down.scale = 1.8
roboportmain.door_animation_down.shift = util.by_pixel(1,8)
roboportmain.door_animation_down.hr_version.filename =		"__brave-new-oarc__/graphics/entity/roboport-bno/hr-roboport-bno-door-down.png"
roboportmain.door_animation_down.hr_version.scale = .9
roboportmain.door_animation_down.hr_version.shift = util.by_pixel(-11.5,5)

roboportmain.door_animation_up.filename =					"__brave-new-oarc__/graphics/entity/roboport-bno/roboport-bno-door-up.png"
roboportmain.door_animation_up.scale = 1.8
roboportmain.door_animation_up.hr_version.filename =		"__brave-new-oarc__/graphics/entity/roboport-bno/hr-roboport-bno-door-up.png"
roboportmain.door_animation_up.hr_version.scale = .9
roboportmain.door_animation_up.hr_version.shift = util.by_pixel(-11.5,-30.5)

roboportmain.is_military_target=true
data:extend({ roboportmain })

data:extend({
-- TECHNOLOGY
{
	type = "technology",
	name = "roboport-bno",
	icon_size = 64,
	icon = "__brave-new-oarc__/graphics/icons/roboport-bno.png",
	effects =
	{
		{
			type = "unlock-recipe",
			recipe = "roboport-bno"
		}
	},
	prerequisites = {"robotics"},
	unit =
	{
		count = 500,
		ingredients =
		{
			{"automation-science-pack", 1},
			{"logistic-science-pack", 1},
			{"chemical-science-pack", 1},
		},
		time = 60
	},
	order = "a-b-c"
},
-- RECIPE
{
	type = "recipe",
	name = "roboport-bno",
	enabled = false,
	energy_required = 10,
	ingredients =
	{
		{ "steel-plate", 10 },
		{ "roboport", 4 },
		{ "processing-unit", 10 }
	},
	result = "roboport-bno"
},
	-- ITEM
	{
		type = "item",
		name = "roboport-bno",
		icon = "__brave-new-oarc__/graphics/icons/roboport-bno.png",
		icon_size = 64,
		localised_name = { "Brave New ", {"entity-name.roboport"}},
		localised_description = { "entity-description.roboport" },
		subgroup = "logistic-network",
		order = "c[signal]-a[roboport-bno]",
		place_result = "roboport-bno",
		stack_size = 10,
		scale=.9
	},
})

---------------------------------
-- Roboport BNO remnants
---------------------------------s
roboportmain_remnants = table.deepcopy(data.raw.corpse["roboport-remnants"])
roboportmain_remnants.name = "roboport-bno-remnants"

-- new textures
for _,anim in pairs(roboportmain_remnants.animation) do
	anim.filename =				"__brave-new-oarc__/graphics/entity/roboport-bno/remnants/roboport-bno-remnants.png"
	anim.hr_version.filename =	"__brave-new-oarc__/graphics/entity/roboport-bno/remnants/hr-roboport-bno-remnants.png"
end

data:extend({ roboportmain_remnants })