-- Bots explode for no good reason, in a mod that requires you to use ONLY bots to survive, them spontaneous exploding is bad
-- The thoughts are that adding resistance to explosion and potentially more important physical damage will keep them alive longer
-- see data.lua to other mods to extend their life
for _, bot in pairs(data.raw["construction-robot"]) do
	bot.resistances = bot.resistances or {}
	table.insert(bot.resistances, {type = "acid", percent = 100})
	table.insert(bot.resistances, {type = "explosion", percent = 100})
	table.insert(bot.resistances, {type = "fire", percent = 100})
	table.insert(bot.resistances, {type = "physical", percent = 100})

end
for _, bot in pairs(data.raw["logistic-robot"]) do
	bot.resistances = bot.resistances or {}
	table.insert(bot.resistances, {type = "acid", percent = 100})
	table.insert(bot.resistances, {type = "explosion", percent = 100})
	table.insert(bot.resistances, {type = "fire", percent = 100})
	table.insert(bot.resistances, {type = "physical", percent = 100})
end


