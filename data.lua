local myConBotItem
local myConBot
local myLogiBotItem
local myLogiBot


local speedBotsDbl=settings.startup["bno-starting-bots_speed"].value / 216
log("Bot speed: " .. speedBotsDbl .. " k/hr")
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

log ("Energy settings: Storage(" .. energyBotsStorage .. "), Range(" .. energyBotsRange .. ", Movement(" .. energyBotsMovement .. ")" )
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

mySpecialRoboport = util.table.deepcopy(data.raw["roboport"]["roboport"])
mySpecialRoboport.name = "roboport-main"
mySpecialRoboport.is_military_target=true
data:extend({mySpecialRoboport})

myLogiRoboportItem = util.table.deepcopy(data.raw["item"]["roboport"])
myLogiRoboportItem.name="roboport-main"
myLogiRoboportItem.place_result = "roboport"
data:extend({myLogiRoboportItem})

