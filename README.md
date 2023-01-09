Brave New OARC
is a merge of both OARC and Brave New World mods

OARC: https://mods.factorio.com/mod/oarc-mod
Brave New World: https://mods.factorio.com/mod/brave-new-world

Since Brave New World is ideally single player and OARC is the best multiplayer mod that enables single players to build their own bases but share with other players on the same team, I decided to combine the two mods.

I started with OARC 1.0.1 and BNW 4.11

This does not turn on any special features.

Known issues:
Reset player, done by moderator in the game will remove the players base, reset him to 0,0 spawn, but respawning to a new location is not done correctly. 
Bots will explode if too far from a charge for too long - well that's a feature, upto the point the 40 of them do it.

12/26/2022 4.1.2
Fixed issue with moving player on reset and second player not being moved to new location on start
Fixed issue where sometimes the base was not cleaned up when a player is reset of leaves

Adding - closer/further biters - based on Starting Area Size
Adding - a text message on ground to tell player to get power

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

1/8/2023 - 4.1.4
More work finding bots that explode, removed excessive logging