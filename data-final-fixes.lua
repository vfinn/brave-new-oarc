-- 12/3/2023 VF moved from Data.lua since Krastorio overrides alot of these settings - taking them back.

-- entities
require("prototypes.entity.roboport-main")
-- require("prototypes.entity.loader")

-- items
require("prototypes.item")

local myConBotItem
local myConBot
local myLogiBotItem
local myLogiBot


local speedBotsDbl=settings.startup["bno-starting-bots_speed"].value / 216	-- multiply by 0.621371 to get to mph
log("Bot speed: " .. speedBotsDbl .. " which is " .. speedBotsDbl*216 .. " km/hr")
-- energy usage: {"normal", "increase storage", "increase range", "increase movement", "increase storage, range & movement"}
local energyBotStr=settings.startup["bno-bots_energy"].value
local energyBotsStorage  = "1.5MJ"
local energyBotsRange    = "5.0kJ"	-- max consumption
local energyBotsMovement = "0.05kJ"	-- moving consumption
if     (energyBotStr == "increase storage")						then energyBotsStorage  = "3MJ"	 
elseif (energyBotStr == "increase range")						then energyBotsRange	= "2.5kJ"
elseif (energyBotStr == "increase movement")					then energyBotsMovement = "0.025kJ"
elseif (energyBotStr == "increase all")   then 
	energyBotsStorage	= "3MJ"	 
	energyBotsRange		= "2.5kJ"		
	energyBotsMovement	= "0.025kJ"
end

log ("Energy settings: Storage(" .. energyBotsStorage .. "), Range(" .. energyBotsRange .. "), Movement(" .. energyBotsMovement .. ")" )
myConBot = util.table.deepcopy(data.raw["construction-robot"]["construction-robot"])
myConBot.speed = speedBotsDbl
myConBot.minable = {mining_time = 10, result = "construction-robot"}
myConBot.max_energy		 = energyBotsStorage
myConBot.energy_per_tick = energyBotsMovement
myConBot.energy_per_move = energyBotsRange
data:extend({myConBot})

myLogiBot = util.table.deepcopy(data.raw["logistic-robot"]["logistic-robot"])
myLogiBot.speed = speedBotsDbl
myLogiBot.minable = {mining_time = 10, result = "logistic-robot"}
myLogiBot.max_energy		= energyBotsStorage
myLogiBot.energy_per_tick	= energyBotsMovement
myLogiBot.energy_per_move	= energyBotsRange
data:extend({myLogiBot})

myLogiRoboportItem = util.table.deepcopy(data.raw["item"]["roboport"])
myLogiRoboportItem.name="roboport-main"
myLogiRoboportItem.place_result = "roboport-main"
myLogiRoboportItem.icon = "__brave-new-oarc__/graphics/icons/roboport-main.png"
data:extend({myLogiRoboportItem})



-- Bots explode for no good reason(update Jan 2023 JGF - found it we were killing them if they had no owner - FIXED), in a mod that requires you to use ONLY bots to survive, them spontaneous exploding is bad
-- The thoughts are that adding resistance to explosion and potentially more important physical damage will keep them alive longer, (Update: I like this feature even though bots no longer explode - making it configurable)
-- see data.lua to other mods to extend their life
	if (settings.startup["bno-bots-resistance-acid"].value) then
		log("Bots resistant to acid")
	end
	if (settings.startup["bno-bots-resistance-explosion"].value) then
		log("Bots resistant to explosion")
	end
	if (settings.startup["bno-bots-resistance-fire"].value) then
		log("Bots resistant to fire")
	end
	if (settings.startup["bno-bots-resistance-physical"].value) then
		log("Bots resistant to physical damage")
	end
	for _, bot in pairs(data.raw["construction-robot"]) do
		bot.resistances = bot.resistances or {}
		if (settings.startup["bno-bots-resistance-acid"].value) then
			table.insert(bot.resistances, {type = "acid", percent = 100})
		end
		if (settings.startup["bno-bots-resistance-explosion"].value) then
			table.insert(bot.resistances, {type = "explosion", percent = 100})
		end
		if (settings.startup["bno-bots-resistance-fire"].value) then
			table.insert(bot.resistances, {type = "fire", percent = 100})
		end
		if (settings.startup["bno-bots-resistance-physical"].value) then
			table.insert(bot.resistances, {type = "physical", percent = 100})
		end
	end
	for _, bot in pairs(data.raw["logistic-robot"]) do
		bot.resistances = bot.resistances or {}
		if (settings.startup["bno-bots-resistance-acid"].value) then
			table.insert(bot.resistances, {type = "acid", percent = 100})
		end
		if (settings.startup["bno-bots-resistance-explosion"].value) then
			table.insert(bot.resistances, {type = "explosion", percent = 100})
		end
		if (settings.startup["bno-bots-resistance-fire"].value) then
			table.insert(bot.resistances, {type = "fire", percent = 100})
		end
		if (settings.startup["bno-bots-resistance-physical"].value) then
			table.insert(bot.resistances, {type = "physical", percent = 100})
		end
	end
