Brave New OARC
is a merge of both OARC and Brave New World mods

OARC: https://mods.factorio.com/mod/oarc-mod
Brave New World: https://mods.factorio.com/mod/brave-new-world

Since Brave New World is ideally single player and OARC is the best multiplayer mod that enables single players to build their own bases but share with other players on the same team, I decided to combine the two mods.

I started with OARC 1.0.1 and BNW 4.11

Brave New Oarc enables you to play Brave New World and OARC together, and best of all - with other players.  I've made alot of changes, 

1/19/2023 - 4.1.6
Modified starting area, upgraded starting power from 50Mj to 90Mj and power from 720kW to 1.4MW, Fully charged. Also placed a blue chest with requests for robots.
The bots will go into chests if you move the roboports.

No more special bots. The problem was that when you choose "fast bots" and you finally get to making bots, you're disappointed at how slow they are. They become a major negative
towards fun game play.

We now have a end game scenario - previously if one person's main roboport died, every one died.  The changes: Biters HATE your main roboport and if they get near it, 
they will aggressively attack it, but they are passive to all other roboports.
If the main one dies, you immediately get thrown back to 0,0 location and are able to restart, rejoin a force. No one else is impacted.

Fixed RESTART player so the menu comes up once they go back to 0,0.

Many settings added to the "Mod settings" screen:
	- number of Silo's' - 1..12
	- Bots energy use, normal, increase energy storage, increase range, increase movement, increase all
		Bots consume energy, Fast bots consume more energy. Energy is VERY important in this scenario.
		Increase storage, increases their max storage from 1.5MJ to 3MJ
		Increase range, decreases their consumption per tick
		Increase movement, decreases their consumption while moving
	- Number of starting bots added to your mod settings - you choices: 10/5, 50/25, 100/50, 200/100 for construction/logistic bots
	  The max bots in starter roboport are 350, so I think these are good options.  If you choose 10/5 I recommend also clicking on the resistance values to make them "nearly" indestructible.
	- Bot speed in km/h.  10-400.  Note that the default game starts at 12.9 km/h. So choose 13 if you want to go close to default. Increases in research will speed them up further.
	- Bridge moat - if you have a moat, do you want biters to access your players?
	- anti-grief. This basically turns off the ability for someone to delete anything in your base via map view.
	- TTL for ghost images - default is 30 minutes, options, 10, 30, 60, 120, 240, 360 or use config.lua to define
	- Item and Energy Sharing - chests and accumulators that enable you to share items and power with EVERYONE.
	- Base shape - Circle or Octagon
	- Resitances to make you bots near indestructible !

Verified - buddy spawn to kick all players associated with that base

1/15/2023 - 4.1.5
Welcome message disappears but player name remains
Oil patch slight move to enable roboport to fit between it.
Fixed reset player - but player has to be offline for it to work properly
Previously if one player lost their starting roboport it ended the game. Now it will display that
you lost but enables you to continue playing.  I may change this to immediately remove and clean up 
player that died and not hastle other players with the lose message.
Options settable by host:
	added moat bridge option in gui MOD interface
	added four different resistances in MOD interface for fire, spitter, explosion and physical damage to bots
	added support for turning anti-griefing on/off. This disables delete in map view and sets a time limit on ghost items.
	moved oil to make room for roboport between it
	offer chest sharing and energy share
	Number of silos

1/8/2023 - 4.1.4
More work finding bots that explode, removed excessive logging. Fixed exploding bots.

1/7/2023 - 4.1.3
12/27/2022
Modified the start state to be 1x multiplier for research. Most people will just play scenario from the mod, not start a server, use the technology_price_multiplier in map-settings.json if running from a server.
I may not have upgraded the github before posting to factorio mod site, so this is updated, in both location.

12/29/2022
Increased richness of three oil spots outside main, with randomness on how rich

1/05/2023
Modified bots so they are indestructible. This needs some work since I don't mind if they die,
I just don't want them randomly exploding because you are working them too hard. 
Slowing them down to a crawl and letting them die to biters if misused is fine,
but just exploding for some unknown cause is bull.

1/07/2023 - Anti-grief turned on by default (config.lua)

12/26/2022 4.1.2
Fixed issue with moving player on reset and second player not being moved to new location on start
Fixed issue where sometimes the base was not cleaned up when a player is reset of leaves

Adding - closer/further biters - based on Starting Area Size
Adding - a text message on ground to tell player to get power

