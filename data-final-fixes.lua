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