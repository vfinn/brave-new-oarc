local myConBotItem
local myConBot
local myLogiBotItem
local myLogiBot


myConBotItem = util.table.deepcopy(data.raw["item"]["construction-robot"])
myConBotItem.name = "bnw-homeworld-construction-robot"
myConBotItem.place_result = "bnw-homeworld-construction-robot"
--myConBotItem.max_energy = "1.5MJ"
--myConBotItem.speed_multiplier_when_out_of_energy = 0.2
--myConBotItem.energy_per_tick = "0kJ"
--myConBotItem.energy_per_move = "0kJ"
myConBotItem.min_to_charge = 0.2
myConBotItem.max_to_charge = 0.95
--myConBotItem.destructible = false
data:extend({myConBotItem})

myLogiBotItem = util.table.deepcopy(data.raw["item"]["logistic-robot"])
myLogiBotItem.name = "bnw-homeworld-logistic-robot"
myLogiBotItem.place_result = "bnw-homeworld-logistic-robot"
--myConBotItem.max_energy = "1.5MJ"
--myConBotItem.speed_multiplier_when_out_of_energy = 0.2
--myConBotItem.energy_per_tick = "0kJ"
--myConBotItem.energy_per_move = "0kJ"
--myConBotItem.min_to_charge = 0.2
--myConBotItem.max_to_charge = 0.95
--myConBotItem.destructible = false
data:extend({myLogiBotItem})

myConBot = util.table.deepcopy(data.raw["construction-robot"]["construction-robot"])
myConBot.name = "bnw-homeworld-construction-robot"
myConBot.speed = 0.5
myConBot.minable = {mining_time = 10, result = "bnw-homeworld-construction-robot"}
--myConBot.max_energy = "1.5MJ"
--myConBot.energy_per_tick = "0kJ"
--myConBot.energy_per_move = "0kJ"
--myConBot.destructible = false
data:extend({myConBot})

myLogiBot = util.table.deepcopy(data.raw["logistic-robot"]["logistic-robot"])
myLogiBot.name = "bnw-homeworld-logistic-robot"
myLogiBot.speed = 0.5
myLogiBot.minable = {mining_time = 10, result = "bnw-homeworld-logistic-robot"}
--myLogiBot.max_energy = "1.5MJ"
--myLogiBot.energy_per_tick = "0kJ"
--myLogiBot.energy_per_move = "0kJ"
--myLogiBot.destructible = false
data:extend({myLogiBot})
