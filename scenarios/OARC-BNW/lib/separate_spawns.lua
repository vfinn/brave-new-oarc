-- separate_spawns.lua
-- Nov 2016
--
-- Code that handles everything regarding giving each player a separate spawn
-- Includes the GUI stuff

require("lib/oarc_utils")
require("config")
local crash_site = require("crash-site")

--[[
  ___  _  _  ___  _____ 
 |_ _|| \| ||_ _||_   _|
  | | | .` | | |   | |  
 |___||_|\_||___|  |_|  
                        
--]]

-- Initializes the globals used to track the special spawn and player
-- status information
function InitSpawnGlobalsAndForces()

    -- Core global to help me organize shit.
    if (global.ocore == nil) then
        global.ocore = {}
    end

    -- This contains each player's spawn point. Literally where they will respawn.
    -- There is a way in game to change this under one of the little menu features I added.
    if (global.ocore.playerSpawns == nil) then
        global.ocore.playerSpawns = {}
    end

    -- This is the most important table. It is a list of all the unique spawn points.
    -- This is what chunk generation checks against.
    -- Each entry looks like this: {pos={x,y},moat=bool,vanilla=bool}
    if (global.ocore.uniqueSpawns == nil) then
        global.ocore.uniqueSpawns = {}
    end

    -- List of available vanilla spawns
    if (global.vanillaSpawns == nil) then
        global.vanillaSpawns = {}
    end

    -- This keeps a list of any player that has shared their base.
    -- Each entry contains information about if it's open, spawn pos, and players in the group.
    if (global.ocore.sharedSpawns == nil) then
        global.ocore.sharedSpawns = {}
    end

    -- Each player has an option to change their respawn which has a cooldown when used.
    -- Other similar abilities/functions that require cooldowns could be added here.
    if (global.ocore.playerCooldowns == nil) then
        global.ocore.playerCooldowns = {}
    end

    -- List of players in the "waiting room" for a buddy spawn.
    -- They show up in the list to select when doing a buddy spawn.
    if (global.ocore.waitingBuddies == nil) then
        global.ocore.waitingBuddies = {}
    end

    -- Players who have made a spawn choice get put into this list while waiting.
    -- An on_tick event checks when it expires and then places down the base resources, and teleports the player.
    -- Go look at DelayedSpawnOnTick() for more info.
    if (global.ocore.delayedSpawns == nil) then
        global.ocore.delayedSpawns = {}
    end

    -- This is what I use to communicate a buddy spawn request between the buddies.
    -- This contains information of who is asking, and what options were selected.
    if (global.ocore.buddySpawnOpts == nil) then
        global.ocore.buddySpawnOpts = {}
    end

    -- Silo info
    if (global.siloPosition == nil) then
        global.siloPosition = {}
    end

    -- Buddy info: The only real use is to check if one of a buddy pair is online to see if we should allow enemy
    -- attacks on the base.
    if (global.ocore.buddyPairs == nil) then
        global.ocore.buddyPairs = {}
    end

    -- Rendering fancy fadeouts.
    if (global.oarc_renders_fadeout == nil) then
        global.oarc_renders_fadeout = {}
    end

    -- Name a new force to be the default force.
    -- This is what any new player is assigned to when they join, even before they spawn.
    local main_force = CreateForce(global.ocfg.main_force)
    main_force.set_spawn_position({x=0,y=0}, GAME_SURFACE_NAME)

    -- Special forces for when players with their own force want a reset.
    global.ocore.abandoned_force = "_ABANDONED_"
    global.ocore.destroyed_force = "_DESTROYED_"
    game.create_force(global.ocore.abandoned_force)
    game.create_force(global.ocore.destroyed_force)
end



--[[
  ___  _       _ __   __ ___  ___     ___  ___  ___  ___  ___  ___  ___  ___ 
 | _ \| |     /_\\ \ / /| __|| _ \   / __|| _ \| __|/ __||_ _|| __||_ _|/ __|
 |  _/| |__  / _ \\ V / | _| |   /   \__ \|  _/| _|| (__  | | | _|  | || (__ 
 |_|  |____|/_/ \_\|_|  |___||_|_\   |___/|_|  |___|\___||___||_|  |___|\___|
                                                                             
--]]

-- When a new player is created, present the spawn options
-- Assign them to the main force so they can communicate with the team
-- without shouting.
function SeparateSpawnsPlayerCreated(player_index, clear_inv)
    local player = game.players[player_index]

log("SeparateSpawnsPlayerCreated: " .. player.force.name)
    -- Make sure spawn control tab is disabled
    SetOarcGuiTabEnabled(player, OARC_SPAWN_CTRL_GUI_NAME, false)
    SwitchOarcGuiTab(player, OARC_GAME_OPTS_GUI_TAB_NAME)

    -- If they are a new player, put them on the main force.
    if (player.force.name == "player") then
        player.force = global.ocfg.main_force
    end

    -- Reset counts for map feature usage for this player.
    OarcMapFeaturePlayerCreatedEvent(player)

    -- Ensure cleared inventory!
    if (clear_inv) then
		log("SeparateSpawnsPlayerCreated - Clear Inventory")
		if (defines.inventory.character_main == nil) then
			log("SeparateSpawnsPlayerCreated - character_main is nil")
			return
		end
        local inv = player.get_inventory(defines.inventory.character_main)
		if (inv == nil) then
			log("SeparateSpawnsPlayerCreated - character_main inventory is nil")
			return
		end

        player.get_inventory(defines.inventory.character_main ).clear()
        player.get_inventory(defines.inventory.character_guns).clear()
        player.get_inventory(defines.inventory.character_ammo).clear()
        player.get_inventory(defines.inventory.character_armor).clear()
        player.get_inventory(defines.inventory.character_trash).clear()
    end

    HideOarcGui(player)
    HideOarcStore(player)
    DisplayWelcomeTextGui(player)
end


-- Check if the player has a different spawn point than the default one
-- Make sure to give the default starting items
function SeparateSpawnsPlayerRespawned(event)
    local player = game.players[event.player_index]
    SendPlayerToSpawn(player)
end


--[[
  ___  ___   _ __      __ _  _     ___  ___  _____  _   _  ___ 
 / __|| _ \ /_\\ \    / /| \| |   / __|| __||_   _|| | | || _ \
 \__ \|  _// _ \\ \/\/ / | .` |   \__ \| _|   | |  | |_| ||  _/
 |___/|_| /_/ \_\\_/\_/  |_|\_|   |___/|___|  |_|   \___/ |_|  
                                                               
--]]

-- Add a spawn to the shared spawn global
-- Used for tracking which players are assigned to it, where it is and if
-- it is open for new players to join
function CreateNewSharedSpawn(player)
    global.ocore.sharedSpawns[player.name] = {openAccess=true,
                                    position=global.ocore.playerSpawns[player.name],
                                    players={}}
end

-- Generate the basic starter resource around a given location.
function GenerateStartingResources(surface, pos)

    local rand_settings = global.ocfg.spawn_config.resource_rand_pos_settings

    -- Generate all resource tile patches
    if (not rand_settings.enabled) then
        for t_name,t_data in pairs (global.ocfg.spawn_config.resource_tiles) do
            local pos = {x=pos.x+t_data.x_offset, y=pos.y+t_data.y_offset}
            GenerateResourcePatch(surface, t_name, t_data.size, pos, t_data.amount)
        end
    else

        -- Create list of resource tiles
        local r_list = {}
        for k,_ in pairs(global.ocfg.spawn_config.resource_tiles) do
            if (k ~= "") then
                table.insert(r_list, k)
            end
        end
        local shuffled_list = FYShuffle(r_list)

        -- This places resources in a semi-circle
        -- Tweak in config.lua
        local angle_offset = rand_settings.angle_offset
        local num_resources = TableLength(global.ocfg.spawn_config.resource_tiles)
        local theta = ((rand_settings.angle_final - rand_settings.angle_offset) / num_resources);
        local count = 0

        for _,k_name in pairs (shuffled_list) do
            local angle = (theta * count) + angle_offset;

            local tx = (rand_settings.radius * math.cos(angle)) + pos.x
            local ty = (rand_settings.radius * math.sin(angle)) + pos.y

            local pos = {x=math.floor(tx), y=math.floor(ty)}
            GenerateResourcePatch(surface, k_name, global.ocfg.spawn_config.resource_tiles[k_name].size, pos, global.ocfg.spawn_config.resource_tiles[k_name].amount)
            count = count+1
        end
    end

    -- Generate special resource patches (oil)
    for p_name,p_data in pairs (global.ocfg.spawn_config.resource_patches) do
        local oil_patch_x=pos.x+p_data.x_offset_start
        local oil_patch_y=pos.y+p_data.y_offset_start
        for i=1,p_data.num_patches do
            surface.create_entity({name=p_name, amount=p_data.amount,
                        position={oil_patch_x, oil_patch_y}})
            oil_patch_x=oil_patch_x+p_data.x_offset_next
            oil_patch_y=oil_patch_y+p_data.y_offset_next
        end
    end
end

function SendPlayerToNewSpawnAndCreateIt(delayedSpawn)
    -- DOUBLE CHECK and make sure the area is super safe.
    local player = game.players[delayedSpawn.playerName]
log("SendPlayerToNewSpawnAndCreateIt: " .. player.name)
    ClearNearbyEnemies(delayedSpawn.pos, global.ocfg.spawn_config.safe_area.safe_radius, game.surfaces[GAME_SURFACE_NAME])

    if (not delayedSpawn.vanilla) then

        -- Generate water strip only if we don't have a moat.
        if (not delayedSpawn.moat) then
            local water_data = global.ocfg.spawn_config.water
            CreateWaterStrip(game.surfaces[GAME_SURFACE_NAME],
                            {x=delayedSpawn.pos.x+water_data.x_offset, y=delayedSpawn.pos.y+water_data.y_offset},
                            water_data.length)
            CreateWaterStrip(game.surfaces[GAME_SURFACE_NAME],
                            {x=delayedSpawn.pos.x+water_data.x_offset, y=delayedSpawn.pos.y+water_data.y_offset+1},
                            water_data.length)
        end

        -- Create the spawn resources here
        GenerateStartingResources(game.surfaces[GAME_SURFACE_NAME], delayedSpawn.pos)

    end

    -- Render some welcoming text...
    DisplayWelcomeGroundTextAtSpawn(player, delayedSpawn.pos)	

	-- Render Brave New World Items - vf
    global.spawn[player.index] = delayedSpawn.pos  -- save the starting position, this is how we determine who died when a starting roboport is killed
	setupBNWForce(player.force, player.surface, delayedSpawn.pos.x, delayedSpawn.pos.y, game.active_mods["SeaBlock"])
    GivePlayerStarterItems(player)

    -- Chart the area.
    ChartArea(player.force, delayedSpawn.pos, math.ceil(global.ocfg.spawn_config.gen_settings.land_area_tiles/CHUNK_SIZE), player.surface)

    if (player.gui.screen.wait_for_spawn_dialog ~= nil) then
        player.gui.screen.wait_for_spawn_dialog.destroy()
    end

    if (global.ocfg.enable_chest_sharing and not delayedSpawn.vanilla) then
        
        local x_dist = global.ocfg.spawn_config.resource_rand_pos_settings.radius +10        -- moved slightly further out

        -- Shared electricity IO pair of scripted electric-energy-interfaces
        SharedEnergySpawnInput(player, {x=delayedSpawn.pos.x+x_dist, y=delayedSpawn.pos.y-11})
        SharedEnergySpawnOutput(player, {x=delayedSpawn.pos.x+x_dist, y=delayedSpawn.pos.y+10})

        -- Input Chests
        SharedChestsSpawnInput(player, {x=delayedSpawn.pos.x+x_dist, y=delayedSpawn.pos.y-7})
        SharedChestsSpawnInput(player, {x=delayedSpawn.pos.x+x_dist, y=delayedSpawn.pos.y-6})

        -- Tile arrows to help indicate
        CreateTileArrow(game.surfaces[GAME_SURFACE_NAME], {x=delayedSpawn.pos.x+x_dist-4, y=delayedSpawn.pos.y-7}, "RIGHT")
        CreateTileArrow(game.surfaces[GAME_SURFACE_NAME], {x=delayedSpawn.pos.x+x_dist+1, y=delayedSpawn.pos.y-7}, "LEFT")

        -- Combinators for monitoring items in the network.
        SharedChestsSpawnCombinators(player,
                {x=delayedSpawn.pos.x+x_dist-1, y=delayedSpawn.pos.y-2}, -- Ctrl
                {x=delayedSpawn.pos.x+x_dist-1, y=delayedSpawn.pos.y}) -- Status


        SharedChestsSpawnOutput(player, {x=delayedSpawn.pos.x+x_dist, y=delayedSpawn.pos.y+4}, true)
        SharedChestsSpawnOutput(player, {x=delayedSpawn.pos.x+x_dist, y=delayedSpawn.pos.y+5}, true)

        -- Tile arrows to help indicate
        CreateTileArrow(game.surfaces[GAME_SURFACE_NAME], {x=delayedSpawn.pos.x+x_dist-4, y=delayedSpawn.pos.y+4}, "LEFT")
        CreateTileArrow(game.surfaces[GAME_SURFACE_NAME], {x=delayedSpawn.pos.x+x_dist+1, y=delayedSpawn.pos.y+4}, "RIGHT")

        -- Cutscene to force the player to witness my brilliance
        -- player.set_controller{type=defines.controllers.cutscene,waypoints={{position={x=delayedSpawn.pos.x+x_dist,
        -- y=delayedSpawn.pos.y},transition_time=150,time_to_wait=150,zoom=0.8},{target=player.character,transition_time=60,time_to_wait=30,zoom=0.8}},
        -- final_transition_time=45}
    end

    if (global.ocfg.spawn_config.gen_settings.crashed_ship) then
        crash_site.create_crash_site(game.surfaces[GAME_SURFACE_NAME],
                                    {x=delayedSpawn.pos.x+15, y=delayedSpawn.pos.y-25},
                                    global.ocfg.spawn_config.gen_settings.crashed_ship_resources,
                                    global.ocfg.spawn_config.gen_settings.crashed_ship_wreakage)
    end
    -- Send the player to that position
    SafeTeleport(player, game.surfaces[GAME_SURFACE_NAME], delayedSpawn.pos)
    if player.character then
log("on_event::On Player created: destroy character")
       player.character.destroy()
       player.character = nil
    end

end

-- likely not needed - all chunks within the spawn area are deleted in OarcRegrowthRemoveAllChunks
function removeBNWForce(x, y)
    log("deleting roboport at " .. x .. ", " .. y)    
    game.surfaces[GAME_SURFACE_NAME].delete_chunk({x = x, y = y})
end

--[[FUNCTION DEFINITION]]
--Capture your blueprint with a roboport in it - easier to debug if captured ABSOLUTE on and X,Y at 0,0
local function build_blueprint_from_string(bp_string, surface, position, force)
    local bp_entity = surface.create_entity{name='item-on-ground',position=position,stack='blueprint'}
    local offset= {x=0, y=0}
    bp_entity.stack.import_stack(bp_string)
    local bp_entities = bp_entity.stack.get_blueprint_entities()
    bp_entity.destroy()
    for _,entity in pairs(util.table.deepcopy(bp_entities)) do
        if entity.name == "roboport" then 
            offset= entity.position
            break;
        end
    end

    for _,entity in pairs(util.table.deepcopy(bp_entities)) do
        if entity.name == "roboport" then 
--            log("Roboport - NOT BUILDING at " .. entity.position.x .. ", " .. entity.position.y)
        else
--            log("building: '" .. entity.name .. "' at " .. entity.position.x - offset.x + position.x .. " , " .. entity.position.y -offset.y + position.y)
            entity.position = {entity.position.x - offset.x + position.x, entity.position.y -offset.y + position.y}
            entity.force = force
            entity.raise_built = true
            newEntity = surface.create_entity(entity)
            if entity.name == "accumulator" then 
                newEntity.energy = 5000000 
--                log("modified accumulator to have " .. entity.energy)
            end
        end
    end
end

function setupBNWForce(force, surface, x, y, seablock_enabled)
log("setupBNWForce: x=" .. x .. ", y=" .. y)
    if not global.forces then
        global.forces = {}
    end

--    if global.forces[force.name] then
        -- force already existss
--log("force already exists, exiting")		
--        return
--    end
    global.forces[force.name] = {}

    -- setup event listeners for creative mode
    if remote.interfaces["creative-mode"] then
        script.on_event(remote.call("creative-mode", "on_enabled"), function(event)
            global.creative = true
        end)
        script.on_event(remote.call("creative-mode", "on_disabled"), function(event)
            global.creative = false
        end)
    end

    -- give player the possibility to build robots & logistic chests from the start
    force.technologies["construction-robotics"].researched = true
    force.technologies["logistic-robotics"].researched = true
    force.technologies["logistic-system"].researched = true

    -- research some techs that require manual labour
    if seablock_enabled then
        force.technologies["sb-startup1"].researched = true
        force.technologies["sb-startup2"].researched = true
        force.technologies["bio-paper-1"].researched = true
        force.technologies["bio-wood-processing"].researched = true
        force.technologies["sb-startup3"].researched = true
        force.technologies["sb-startup4"].researched = true
        force.technologies["sct-lab-t1"].researched = true
        force.technologies["sct-automation-science-pack"].researched = true
    end

    -- setup starting location
    local water_replace_tile = "sand-1"
    force.chart(surface, {{x - 192, y - 192}, {x + 192, y + 192}})
    if not seablock_enabled and not BRAVE_NEW_OARC_MASHUP then	-- this is what Brave new world does to add oil - done differently in OARC
        water_replace_tile = "dirt-3"
        -- oil is rare, but mandatory to continue research. add some oil patches near spawn point
        local xx = x + math.random(16, 32) * (math.random(1, 2) == 1 and 1 or -1)
        local yy = y + math.random(16, 32) * (math.random(1, 2) == 1 and 1 or -1)
        local tiles = {}
        surface.create_entity{name = "crude-oil", amount = math.random(900000, 2500000), position = {xx, yy}, force=force, raise_built = true}
        for xxx = xx - 2, xx + 2 do
            for yyy = yy - 2, yy + 2 do
                local tile = surface.get_tile(xxx, yyy)
                local name = tile.name
                if tile.prototype.layer <= 4 then
                    name = water_replace_tile
                end
                tiles[#tiles + 1] = {name = name, position = {xxx, yyy}}
            end
        end
		
        xxx = xx + math.random(-8, 8)
        yyy = yy - math.random(4, 8)
        for xxxx = xxx - 2, xxx + 2 do
            for yyyy = yyy - 2, yyy + 2 do
                local tile = surface.get_tile(xxxx, yyyy)
                local name = tile.name
                if tile.prototype.layer <= 4 then
                    name = water_replace_tile
                end
                tiles[#tiles + 1] = {name = name, position = {xxxx, yyyy}}
            end
        end
        surface.create_entity{name = "crude-oil", amount = math.random(900000, 2500000), position = {xxx, yyy}, force=force, raise_built = true}
        xxx = xx + math.random(-8, 8)
        yyy = yy + math.random(4, 8)
        for xxxx = xxx - 2, xxx + 2 do
            for yyyy = yyy - 2, yyy + 2 do
                local tile = surface.get_tile(xxxx, yyyy)
                local name = tile.name
                if tile.prototype.layer <= 4 then
                    name = water_replace_tile
                end
                tiles[#tiles + 1] = {name = name, position = {xxxx, yyyy}}
            end
        end
        surface.create_entity{name = "crude-oil", amount = math.random(900000, 2500000), position = {xxx, yyy}, force=force, raise_built = true}
        surface.set_tiles(tiles)
    end
	-- vf - We always need oil within reach on every map or you can't get outside main, so let's drop a few a small distance away randomly
	-- put it outside of main, to the left
	if BRAVE_NEW_OARC_MASHUP then
        local xx = x + math.random(CHUNK_SIZE*4, CHUNK_SIZE*5) * (math.random(1, 2) == 1 and 1 or -1)
		
        local yy = y + math.random(CHUNK_SIZE*4, CHUNK_SIZE*5) * (math.random(1, 2) == 1 and 1 or -1)
        local tiles = {}
        surface.create_entity{name = "crude-oil", amount = math.random(2500000, 2900000), position = {xx, yy}, force=force, raise_built = true}
log("Random oil - " .. xx .. " : " .. yy);		
        for xxx = xx - 2, xx + 2 do
            for yyy = yy - 2, yy + 2 do
                local tile = surface.get_tile(xxx, yyy)
                local name = tile.name
                if tile.prototype.layer <= 4 then
                    name = water_replace_tile
                end
                tiles[#tiles + 1] = {name = name, position = {xxx, yyy}}
            end
        end
		
        xxx = xx + math.random(-8, 8)
        yyy = yy - math.random(4, 8)
        for xxxx = xxx - 2, xxx + 2 do
            for yyyy = yyy - 2, yyy + 2 do
                local tile = surface.get_tile(xxxx, yyyy)
                local name = tile.name
                if tile.prototype.layer <= 4 then
                    name = water_replace_tile
                end
                tiles[#tiles + 1] = {name = name, position = {xxxx, yyyy}}
            end
        end
        surface.create_entity{name = "crude-oil", amount = math.random(2500000, 2900000), position = {xxx, yyy}, force=force, raise_built = true}
        xxx = xx + math.random(-16, 9)
        yyy = yy + math.random(4, 8)
log("Random oil - " .. xxx .. " : " .. yyy);		
        for xxxx = xxx - 2, xxx + 2 do
            for yyyy = yyy - 2, yyy + 2 do
                local tile = surface.get_tile(xxxx, yyyy)
                local name = tile.name
                if tile.prototype.layer <= 4 then
                    name = water_replace_tile
                end
                tiles[#tiles + 1] = {name = name, position = {xxxx, yyyy}}
            end
        end
        surface.create_entity{name = "crude-oil", amount = math.random(2500000, 2900000), position = {xxx, yyy}, force=force, raise_built = true}
log("Random oil - " .. xxx .. " : " .. yyy);		
        surface.set_tiles(tiles)
	end
    -- remove trees/stones/resources
    local entities = surface.find_entities_filtered{area = {{x - 16, y - 7}, {x + 15, y + 9}}, force = "neutral"}
    for _, entity in pairs(entities) do
        entity.destroy()
    end
    -- place dirt beneath structures
    tiles = {}
    for xx = x - 14, x + 13 do
        for yy = y - 5, y + 7 do
            local tile = surface.get_tile(xx, yy)
            local name = tile.name
            if tile.prototype.layer <= 4 then
                name = water_replace_tile
            end
            tiles[#tiles + 1] = {name = name, position = {xx, yy}}
        end
    end
    surface.set_tiles(tiles)

    -- make sure a roboport is captured at center - make sure there is a Roboport!
    local blueprint = "0eNqdmu+OmzoUxN+Fz0llG/8jr1KtKpKlWyQCKZB772q1734h2zap1hOfzIfVKhH8Ambm+NjMW7Hvzs1pbPu52L0V7WHop2L39a2Y2pe+7tbv5tdTU+yKdm6Oxabo6+P6aRq6etye6r7pivdN0fbPzX/FTr8/bYqmn9u5bT4wlw+v3/rzcd+MywFXwDz0zfbfuusW6GmYllOGfv25BbPVztgvblO8Fjtjgvvi3t83n1hGzCqzrFLMMlmWFbN0luXELJVleSlLV1lWELNilhXFrJBlVWKWz7K0EsNcHiZWvs4rX4ulr/Ny1WLt67yPtFj8Oi9YLVa/zjtJi+Wv8pLVYv2rvJe02ABKIFqxA1TeTUbsACUo12IHqLydjNgBKi9aI3aAytvJiB2g8qI1YgeovJ2M1AG2yovWBDEsbycTxTCBaCsxLG+nUolhedGWVPfjAcwwsABgZbKxyzVAiGbFtNtWA9GcnObzNC+nlXna1QVj/VyP2ZkOcW4McFye47arj6fs5ISUcTVAN7y009wetocfzTRvx+bnefnfjFn0ep2b4tfx37633XLSR0P/u9P//BvjsB/mhXwYzutiwqn12n4dfhXrusCYx/Nh/e3EKU+phlqJn5nKK8BqOS2vAGvktLwOrNiHf1VCRLNM8QKqso6BoSvzTPGKABYYWAVgkamEUQHa1Yr14XA+nrt6HkawgPvDSi4ElZi09pP3SFpO8vdJhqmlaKzcVftrWTgN4wzK6W+QTmKuom/7qRkl1Q4Iyzmm7sD78+JxV/b+uAc5ydwnRTkpo8+KqVxorDzVdoHH6DUDA/XBM20XvM2SgWkAs0StMUnSje7P+2muL2ffLzVmaRf6pn35sR/Ol07Bx9RU7j1RfNIXGQg7pUlRertXN32+XZe83YrwV/IiA+MIpLvAOALpLlCOMABGOaIEMEvN5YjmCH/ZJMkTc3maFAg7pUmRmsvRWFWySfhmaXRBbYrndmwOHwfZ1F6xEoL1o2D9cNsgBBshuHoUXFLdCXhi0RLlNKmk6IjuJE3yRPVMkwLVnaCxikz5BBUvVgwMXFmlmPJpAYzZroroxYyhajFYjFYls8MEaZbZYYI0R1VSRPPSnaHbkoceQiC2mSAsUvUH3WfF7MogmlaK2ZbBOE3VD4gzjOctopUMDb70tIzr4Z06hhYQ7YHGSf+BpVEPLB+qDIqaDuCIUfMBGjFNTQgR0TQRk8A0JsCBaSURlcA0JsSBaY6IS2AaE+TAtEBEJjCNCXNgWkUkMCBN/jZbC7wgf52tBeo1TKID00oihYFplohhYJojchiY5okgBqYFIomBaZGIYmBaRWQxIK1URBgD0zQRoMA0JtuBaSURocA0Jt2BaY4IUWAak+/AtEDEKDCNSXhgGtUjXWhPm48g6+4m97op/mnG6XKeidqGygTvlj+99Hv/A9bDeDQ="
    build_blueprint_from_string(blueprint,surface,{x=x, y=y},force)
    local config = global.forces[force.name]
    config.roboport = surface.create_entity{name = "roboport-main", position = {x, y}, force = force, raise_built = true}
    config.roboport.minable = false
    config.roboport.energy = 100000000    
    local roboport_inventory = config.roboport.get_inventory(defines.inventory.roboport_robot)
    -- start with 100/50 construction/logistic bots

    -- {"10/5", "50/25", "100/50", "200/100", "500/250"}
    local numLogisticBots
    if (global.ocfg.starting_bot_count == "10/5") then
        numLogisticBots=5
    elseif (global.ocfg.starting_bot_count == "50/25") then
        numLogisticBots=25
    elseif (global.ocfg.starting_bot_count == "100/50") then
        numLogisticBots=50
    elseif (global.ocfg.starting_bot_count == "200/100") then
        numLogisticBots=100
    end
    roboport_inventory.insert{name = "construction-robot", count = numLogisticBots*2}
    roboport_inventory.insert{name = "logistic-robot", count = numLogisticBots}

    roboport_inventory = config.roboport.get_inventory(defines.inventory.roboport_material)
    roboport_inventory.insert{name = "repair-pack", count = 10}
    
    
--    -- electric pole
--    local electric_pole = surface.create_entity{name = "medium-electric-pole", position = {x + 1, y + 2}, force = force, raise_built = true}
--    -- radar
--    surface.create_entity{name = "radar", position = {x - 1, y + 3}, force = force, raise_built = true}
    -- storage chest
    surface.create_entity{name = "logistic-chest-storage", position = {x - 1, y + 3}, force = force, raise_built = true}
    surface.create_entity{name = "logistic-chest-storage", position = {x - 2, y + 3}, force = force, raise_built = true}
    local seablock_chest = surface.create_entity{name = "logistic-chest-storage", position = {x + 0, y + 3}, force = force, raise_built = true}
    -- storage chest, contains the items the force starts with
    local chest = surface.create_entity{name = "logistic-chest-storage", position = {x + 1, y + 3}, force = force, raise_built = true}
    local chest_inventory = chest.get_inventory(defines.inventory.chest)
    chest_inventory.insert{name = "transport-belt", count = 400}
    chest_inventory.insert{name = "underground-belt", count = 20}
    chest_inventory.insert{name = "splitter", count = 10}
    chest_inventory.insert{name = "pipe", count = 20}
    chest_inventory.insert{name = "pipe-to-ground", count = 10}
    chest_inventory.insert{name = "burner-inserter", count = 4}
    chest_inventory.insert{name = "inserter", count = 20}
    chest_inventory.insert{name = "medium-electric-pole", count = 50}
    chest_inventory.insert{name = "small-lamp", count = 10}
    chest_inventory.insert{name = "stone-furnace", count = 4}
    chest_inventory.insert{name = "offshore-pump", count = 1}
    chest_inventory.insert{name = "boiler", count = 1}
    chest_inventory.insert{name = "steam-engine", count = 2}
    chest_inventory.insert{name = "assembling-machine-1", count = 4}
    chest_inventory.insert{name = "roboport", count = 4}
    --chest_inventory.insert{name = "logistic-chest-storage", count = 2}
    chest_inventory.insert{name = "logistic-chest-passive-provider", count = 4}
    chest_inventory.insert{name = "logistic-chest-requester", count = 3}
    chest_inventory.insert{name = "logistic-chest-buffer", count = 4}
    chest_inventory.insert{name = "logistic-chest-active-provider", count = 4}
    chest_inventory.insert{name = "lab", count = 2}
    chest_inventory.insert{name = "gun-turret", count = 2}
    chest_inventory.insert{name = "firearm-magazine", count = 20}
    if seablock_enabled then
        -- need some stuff for SeaBlock so we won't get stuck (also slightly accelerate gameplay)
        chest_inventory.insert{name = "ore-crusher", count = 4}
        chest_inventory.insert{name = "angels-electrolyser", count = 1}
        chest_inventory.insert{name = "liquifier", count = 2}
        chest_inventory.insert{name = "algae-farm", count = 2}
        chest_inventory.insert{name = "hydro-plant", count = 1}
        chest_inventory.insert{name = "crystallizer", count = 1}
        chest_inventory.insert{name = "angels-flare-stack", count = 2}
        chest_inventory.insert{name = "clarifier", count = 1}
        chest_inventory.insert{name = "wood-pellets", count = 50}
        global.seablock_chest = seablock_chest
    else
        -- prevent error when looking for "rock-chest" later
        global.seablocked = true
        -- only give player this when we're not seablocking
        chest_inventory.insert{name = "electric-mining-drill", count = 4}
    end
    -- solar panels and accumulators (left side)
--    surface.create_entity{name = "solar-panel", position = {x - 11, y - 2}, force = force, raise_built = true}
--    surface.create_entity{name = "solar-panel", position = {x - 11, y + 1}, force = force, raise_built = true}
--    surface.create_entity{name = "solar-panel", position = {x - 11, y + 4}, force = force, raise_built = true}
--    surface.create_entity{name = "solar-panel", position = {x - 8, y + 4}, force = force, raise_built = true}
--    surface.create_entity{name = "solar-panel", position = {x - 5, y - 2}, force = force, raise_built = true}
--    surface.create_entity{name = "solar-panel", position = {x - 5, y + 4}, force = force, raise_built = true}
--    surface.create_entity{name = "medium-electric-pole", position = {x - 7, y}, force = force, raise_built = true}
--    surface.create_entity{name = "small-lamp", position = {x - 6, y}, force = force, raise_built = true}
--    local accumulator = surface.create_entity{name = "accumulator", position = {x - 8, y - 2}, force = force, raise_built = true}
--    accumulator.energy = 5000000
--    accumulator = surface.create_entity{name = "accumulator", position = {x - 8, y}, force = force, raise_built = true}
--    accumulator.energy = 0eNq12c2O2jAQAOB38Tms4n+HV6lQFcBiI4UEOUlbhHj3BmgX1HoyY0sc9sBq/WVwZibO7IVt28mfQtONbH1hza7vBrb+dmFDc+jq9va78XzybM2a0R9Zwbr6ePs09G0dVqe68y27Fqzp9v4XW/Nrga6sd7vpOLX12IeXleK6KZjvxmZs/COA+4fz9246bn2Y6eilC3bqh3lN392uNzsrrirzoQt2Zmut1Ye+3kL6xxJ0S2KWpFslZqmnNfadX/2s2zjl3Bcl4pQmh+UsFpYhh2WwsCyZshjlyJTCqIpMaYzi5ZcV6n0dsIiALeecHJJAQxJkS6KWJFsctejpXqJWQr6jZcjJCW8rNDBLDsyihcgdHcNTrKJjHO2oZU57tgDGow+LKKb+UlFI0CGxCEk6VC5CKqcvQ/v0TPrQb/tTH0ag3fxxXFQxOaUDhWTJG2Xd4kY5OmQWoYoOLSaTLHPqBdgnmXOcMSWAifR6qaLQS3eftsNY3xcvlks1H+E63xw+t/0Ubgc36TYxWaUXUDzEl0Z/nNvyqq2PJ6x+KmDfDNkqUSsj8eNf0FHvwVfe/38PZPQeZFRCNESVUwlQ8qr0Zm94FEpv9gCU3uwBiJ70zi1Cz6RvusGH0QfkeHrf7YLtm+B3j79RMdcQXZXoPouh7Q/NMDa71e7TD+NqPk+F+uCxq3AgV1yWq1G3ek+8unxPvJoT75tMu29aEF2R6MqsfZDoPqgsV6CuflO85k3x0h8+brFjaZf8FAOgKvn4FodMmfzQAqCsE5cEJiI5EyQQyxkhgVjGM0dGIZ2eU3HIZLwBg1/PZrwBg5jLOcdAWJU+vDPA27Qt0yduoMXTR26gJdIHZaAl0+d3oKXSJ1ygpdMnb6Bl0qdloGXTp2Wg5dIHXA9rUzym+euXfxsU7IcPw32ZcLclwho9//D5Nfo3Gke7BA==
--    accumulator = surface.create_entity{name = "accumulator", position = {x - 8, y + 2}, force = force, raise_built = true}
--    accumulator.energy = 5000000
--    accumulator = surface.create_entity{name = "accumulator", position = {x - 6, y + 2}, force = force, raise_built = true}
--    accumulator.energy = 5000000
--    accumulator = surface.create_entity{name = "accumulator", position = {x - 4, y + 2}, force = force, raise_built = true}
--    accumulator.energy = 5000000
--    -- solar panels and accumulators (right side)
--    surface.create_entity{name = "solar-panel", position = {x + 4, y - 2}, force = force, raise_built = true}
--    surface.create_entity{name = "solar-panel", position = {x + 4, y + 4}, force = force, raise_built = true}
--    surface.create_entity{name = "solar-panel", position = {x + 7, y + 4}, force = force, raise_built = true}
--    surface.create_entity{name = "solar-panel", position = {x + 10, y - 2}, force = force, raise_built = true}
--    surface.create_entity{name = "solar-panel", position = {x + 10, y + 1}, force = force, raise_built = true}
--    surface.create_entity{name = "solar-panel", position = {x + 10, y + 4}, force = force, raise_built = true}
--    surface.create_entity{name = "medium-electric-pole", position = {x + 6, y}, force = force, raise_built = true}
--    surface.create_entity{name = "small-lamp", position = {x + 5, y}, force = force, raise_built = true}
--    accumulator = surface.create_entity{name = "accumulator", position = {x + 4, y + 2}, force = force, raise_built = true}
--    accumulator.energy = 5000000
--    accumulator = surface.create_entity{name = "accumulator", position = {x + 6, y + 2}, force = force, raise_built = true}
--    accumulator.energy = 5000000
--    accumulator = surface.create_entity{name = "accumulator", position = {x + 8, y - 2}, force = force, raise_built = true}
--    accumulator.energy = 5000000
--    accumulator = surface.create_entity{name = "accumulator", position = {x + 8, y}, force = force, raise_built = true}
--    accumulator.energy = 5000000
end



function DisplayWelcomeGroundTextAtSpawn(player, pos)

    -- Render some welcoming text...
    local tcolor = {0.9, 0.7, 0.3, 0.8}
    local ttl = 2000
    local rid1 = rendering.draw_text{text="Welcome",
                        surface=game.surfaces[GAME_SURFACE_NAME],
                        target={x=pos.x-21, y=pos.y-25},
                        color=tcolor,
                        scale=20,
                        font="compi",
                        time_to_live=ttl,
                        -- players={player},
                        draw_on_ground=true,
                        orientation=0,
                        -- alignment=center,
                        scale_with_zoom=false,
                        only_in_alt_mode=false}
    local rid2 = rendering.draw_text{text=player.name,
                        surface=game.surfaces[GAME_SURFACE_NAME],
                        target={x=pos.x-21, y=pos.y+5},
                        color=tcolor,
                        scale=20,
                        font="compi",
                        time_to_live=ttl,
                        -- players={player},
                        draw_on_ground=true,
                        orientation=0,
                        -- alignment=center,
                        scale_with_zoom=false,
                        only_in_alt_mode=false}

    table.insert(global.oarc_renders_fadeout, rid1)
--    table.insert(global.oarc_renders_fadeout, rid2)
end

--[[
   ___  _  _  _   _  _  _  _  __     ___  ___  _  _  ___  ___    _  _____  ___  ___   _  _ 
  / __|| || || | | || \| || |/ /    / __|| __|| \| || __|| _ \  /_\|_   _||_ _|/ _ \ | \| |
 | (__ | __ || |_| || .` || ' <    | (_ || _| | .` || _| |   / / _ \ | |   | || (_) || .` |
  \___||_||_| \___/ |_|\_||_|\_\    \___||___||_|\_||___||_|_\/_/ \_\|_|  |___|\___/ |_|\_|
                                                                                           
--]]

-- Clear the spawn areas.
-- This should be run inside the chunk generate event and be given a list of all
-- unique spawn points.
-- This clears enemies in the immediate area, creates a slightly safe area around it,
-- It no LONGER generates the resources though as that is now handled in a delayed event!
function SetupAndClearSpawnAreas(surface, chunkArea)
    for name,spawn in pairs(global.ocore.uniqueSpawns) do

        -- Create a bunch of useful area and position variables
        local landArea = GetAreaAroundPos(spawn.pos, global.ocfg.spawn_config.gen_settings.land_area_tiles+CHUNK_SIZE)
        -- local safeArea = GetAreaAroundPos(spawn.pos, global.ocfg.spawn_config.safe_area.safe_radius)
        -- local warningArea = GetAreaAroundPos(spawn.pos, global.ocfg.spawn_config.safe_area.warn_radius)
        -- local reducedArea = GetAreaAroundPos(spawn.pos, global.ocfg.spawn_config.safe_area.danger_radius)
        local chunkAreaCenter = {x=chunkArea.left_top.x+(CHUNK_SIZE/2),
                                         y=chunkArea.left_top.y+(CHUNK_SIZE/2)}
        local spawnPosOffset = {x=spawn.pos.x+global.ocfg.spawn_config.gen_settings.land_area_tiles,
                                         y=spawn.pos.y+global.ocfg.spawn_config.gen_settings.land_area_tiles}



        -- Make chunks near a spawn safe by removing enemies
        if (getDistance(spawn.pos, chunkAreaCenter) < global.ocfg.spawn_config.safe_area.safe_radius) then
            RemoveAliensInArea(surface, chunkArea)

        -- Create a warning area with heavily reduced enemies
        elseif (getDistance(spawn.pos, chunkAreaCenter) < global.ocfg.spawn_config.safe_area.warn_radius) then
            ReduceAliensInArea(surface, chunkArea, global.ocfg.spawn_config.safe_area.warn_reduction)
            -- DowngradeWormsInArea(surface, chunkArea, 100, 100, 100)
            RemoveWormsInArea(surface, chunkArea, false, true, true, true) -- remove all non-small worms.

        -- Create a third area with moderatly reduced enemies
        elseif (getDistance(spawn.pos, chunkAreaCenter) < global.ocfg.spawn_config.safe_area.danger_radius) then
            ReduceAliensInArea(surface, chunkArea, global.ocfg.spawn_config.safe_area.danger_reduction)
            -- DowngradeWormsInArea(surface, chunkArea, 50, 100, 100)
            RemoveWormsInArea(surface, chunkArea, false, false, true, true) -- remove all huge/behemoth worms.
        end

        if (not spawn.vanilla) then
            -- If the chunk is within the main land area, then clear trees/resources
            -- and create the land spawn areas (guaranteed land with a circle of trees)
            if CheckIfInArea(chunkAreaCenter,landArea) then

                -- Remove trees/resources inside the spawn area
                RemoveInCircle(surface, chunkArea, "tree", spawn.pos, global.ocfg.spawn_config.gen_settings.land_area_tiles)
                RemoveInCircle(surface, chunkArea, "resource", spawn.pos, global.ocfg.spawn_config.gen_settings.land_area_tiles+5)
                RemoveInCircle(surface, chunkArea, "cliff", spawn.pos, global.ocfg.spawn_config.gen_settings.land_area_tiles+5)

                local fill_tile = "landfill"
                if (game.active_mods["oarc-restricted-build"]) then
                    fill_tile = global.ocfg.locked_build_area_tile
                end

                if (global.ocfg.spawn_config.gen_settings.tree_circle) then
                    CreateCropCircle(surface, spawn.pos, chunkArea, global.ocfg.spawn_config.gen_settings.land_area_tiles, fill_tile)
                elseif (global.ocfg.spawn_config.gen_settings.tree_octagon) then
                    CreateCropOctagon(surface, spawn.pos, chunkArea, global.ocfg.spawn_config.gen_settings.land_area_tiles, fill_tile)
                end
                if (global.ocfg.spawn_config.gen_settings.moat_choice_enabled) then
                    if (spawn.moat) then
                        -- allowed_values = {"yes", "no", "use config.lua setting"}
                        local moat_bridge_enabled=global.ocfg.spawn_config.gen_settings.moat_bridging
                        if (settings.startup["bno-moat-bridge"].value ~= "use config.lua setting") then
                            moat_bridge_enabled = settings.startup["bno-moat-bridge"].value == "yes"
                        end
                        CreateMoat(surface,
                            spawn.pos,
                            chunkArea,
                            global.ocfg.spawn_config.gen_settings.land_area_tiles,
                            "water",
                            moat_bridge_enabled)
                    end
                end
            end
        end
    end
end

-- This is the main function that creates the spawn area
-- Provides resources, land and a safe zone
function SeparateSpawnsGenerateChunk(event)
    local surface = event.surface
    local chunkArea = event.area

    -- Modify enemies first.
    if global.ocfg.modified_enemy_spawning then
        DowngradeWormsDistanceBasedOnChunkGenerate(event)
    end

    -- Downgrade resources near to spawns
    if global.ocfg.scale_resources_around_spawns then
        DowngradeResourcesDistanceBasedOnChunkGenerate(surface, chunkArea)
    end

    -- This handles chunk generation near player spawns
    -- If it is near a player spawn, it does a few things like make the area
    -- safe and provide a guaranteed area of land and water tiles.
    SetupAndClearSpawnAreas(surface, chunkArea)
end

-- Based on the danger distance, you get full resources, and it is exponential from the spawn point to that distance.
function DowngradeResourcesDistanceBasedOnChunkGenerate(surface, chunkArea)

    local closestSpawn = GetClosestUniqueSpawn(chunkArea.left_top)

    if (closestSpawn == nil) then return end

    local distance = getDistance(chunkArea.left_top, closestSpawn.pos)
    -- Adjust multiplier to bring it in or out
    local modifier = (distance / (global.ocfg.spawn_config.safe_area.danger_radius*1))^3
    if modifier < 0.1 then modifier = 0.1 end
    if modifier > 1 then return end

    local ore_per_tile_cap = math.floor(100000 * modifier)

    for key, entity in pairs(surface.find_entities_filtered{area=chunkArea, type="resource"}) do
        if entity.valid and entity and entity.position and entity.amount then
            local new_amount = math.ceil(entity.amount * modifier)
            if (new_amount < 1) then
                entity.destroy()
            else
                if (entity.name ~= "crude-oil") then
                    entity.amount = math.min(new_amount, ore_per_tile_cap)
                else
                    entity.amount = new_amount
                end
            end            
        end
    end
end

-- I wrote this to ensure everyone gets safer spawns regardless of evolution level.
-- This is intended to downgrade any biters/spitters spawning near player bases.
-- I'm not sure the performance impact of this but I'm hoping it's not bad.
function ModifyEnemySpawnsNearPlayerStartingAreas(event)

    if (not event.entity or not (event.entity.force.name == "enemy") or not event.entity.position) then
        log("ModifyBiterSpawns - Unexpected use.")
        return
    end

    local enemy_pos = event.entity.position
    local surface = event.entity.surface
    local enemy_name = event.entity.name

    local closest_spawn = GetClosestUniqueSpawn(enemy_pos)

    if (closest_spawn == nil) then
        -- log("GetClosestUniqueSpawn ERROR - None found?")
        return
    end

    -- No enemies inside safe radius!
    if (getDistance(enemy_pos, closest_spawn.pos) < global.ocfg.spawn_config.safe_area.safe_radius) then
        event.entity.destroy()

    -- Warn distance is all SMALL only.
    elseif (getDistance(enemy_pos, closest_spawn.pos) < global.ocfg.spawn_config.safe_area.warn_radius) then
        if ((enemy_name == "big-biter") or (enemy_name == "behemoth-biter") or (enemy_name == "medium-biter")) then
            event.entity.destroy()
            surface.create_entity{name = "small-biter", position = enemy_pos, force = game.forces.enemy}
            -- log("Downgraded biter close to spawn.")
        elseif ((enemy_name == "big-spitter") or (enemy_name == "behemoth-spitter") or (enemy_name == "medium-spitter")) then
            event.entity.destroy()
            surface.create_entity{name = "small-spitter", position = enemy_pos, force = game.forces.enemy}
            -- log("Downgraded spitter close to spawn.")
        elseif ((enemy_name == "big-worm-turret") or (enemy_name == "behemoth-worm-turret") or (enemy_name == "medium-worm-turret")) then
            event.entity.destroy()
            surface.create_entity{name = "small-worm-turret", position = enemy_pos, force = game.forces.enemy}
            -- log("Downgraded worm close to spawn.")
        end

    -- Danger distance is MEDIUM max.
    elseif (getDistance(enemy_pos, closest_spawn.pos) < global.ocfg.spawn_config.safe_area.danger_radius) then
        if ((enemy_name == "big-biter") or (enemy_name == "behemoth-biter")) then
            event.entity.destroy()
            surface.create_entity{name = "medium-biter", position = enemy_pos, force = game.forces.enemy}
            -- log("Downgraded biter further from spawn.")
        elseif ((enemy_name == "big-spitter") or (enemy_name == "behemoth-spitter")) then
            event.entity.destroy()
            surface.create_entity{name = "medium-spitter", position = enemy_pos, force = game.forces.enemy}
            -- log("Downgraded spitter further from spawn
        elseif ((enemy_name == "big-worm-turret") or (enemy_name == "behemoth-worm-turret")) then
            event.entity.destroy()
            surface.create_entity{name = "medium-worm-turret", position = enemy_pos, force = game.forces.enemy}
            -- log("Downgraded worm further from spawn.")
        end
    end
end



--[[
   ___  _     ___    _    _  _  _   _  ___ 
  / __|| |   | __|  /_\  | \| || | | || _ \
 | (__ | |__ | _|  / _ \ | .` || |_| ||  _/
  \___||____||___|/_/ \_\|_|\_| \___/ |_|  
                                           
--]]


function ResetPlayerAndDestroyForce(player)
    local player_old_force = player.force

    player.force = global.ocfg.main_force

    if ((#player_old_force.players == 0) and (player_old_force.name ~= global.ocfg.main_force)) then
        SendBroadcastMsg("Team " .. player_old_force.name .. " has been destroyed! All buildings will slowly be destroyed now.")
        log("DestroyForce - FORCE DESTROYED: " .. player_old_force.name)
        game.merge_forces(player_old_force, global.ocore.destroyed_force)           
    end

    RemoveOrResetPlayer(player, false, false, true, true)
    SeparateSpawnsPlayerCreated(player.index, false)
end

function ResetPlayerAndAbandonForce(player)
    local player_old_force = player.force

    player.force = global.ocfg.main_force

    if ((#player_old_force.players == 0) and (player_old_force.name ~= global.ocfg.main_force)) then
        SendBroadcastMsg("Team " .. player_old_force.name .. " has been abandoned!")
        log("AbandonForce - FORCE ABANDONED: " .. player_old_force.name)
        game.merge_forces(player_old_force, global.ocore.abandoned_force)           
    end

    RemoveOrResetPlayer(player, false, false, false, false)
    SeparateSpawnsPlayerCreated(player.index, false)
end

function ResetPlayerAndMergeForceToNeutral(player)
    RemoveOrResetPlayer(player, false, true, true, true)
    SeparateSpawnsPlayerCreated(player.index, true)
end

function KickAndMarkPlayerForRemoval(player)
    game.kick_player(player, "KickAndMarkPlayerForRemoval")
    if (not global.ocore.player_removal_list) then
        global.ocore.player_removal_list = {}
    end
    table.insert(global.ocore.player_removal_list, player)
end

-- Call this if a player leaves the game early (or a player wants an early game reset)
function RemoveOrResetPlayer(player, remove_player, remove_force, remove_base, immediate)
    if (not player) then
        log("ERROR - CleanupPlayer on NIL Player!")
        return
    end

    -- If this player is staying in the game, lets make sure we don't delete them along with the map chunks being
    -- cleared.
    log("RemoveOrResetPlayer:: teleport to 0,0")
    -- this causing crash
    --if player.character == nil then
    --    log("RemoveOrResetPlayer::Character created")
    --    player.create_character()
    --end
    player.teleport({x=0,y=0}, GAME_SURFACE_NAME)
    local player_old_force = player.force
    player.force = global.ocfg.main_force

    -- Clear globals
    CleanupPlayerGlobals(player.name) -- Except global.ocore.uniqueSpawns

    -- Clear their unique spawn (if they have one)
    UniqueSpawnCleanupRemove(player.name, remove_base, immediate) -- Specifically global.ocore.uniqueSpawns

    -- Remove a force if this player created it and they are the only one on it
    if (remove_force) then
        if ((#player_old_force.players == 0) and (player_old_force.name ~= global.ocfg.main_force)) then
            log("RemoveOrResetPlayer - FORCE REMOVED: " .. player_old_force.name)
            game.merge_forces(player_old_force, "neutral")           
        end
    end

    -- Remove the character completely
    if (remove_player) then
        game.remove_offline_players({player})        
    end
    -- this happens if player loses - reset them and show menu
    if (remove_base and not remove_player) then
        DisplaySpawnOptions(player)
    end
end

function UniqueSpawnCleanupRemove(playerName, cleanup, immediate)
    if (global.ocore.uniqueSpawns[playerName] == nil) then return end -- Safety
    log("UniqueSpawnCleanupRemove - " .. playerName .. ", cleanup: " .. tostring(cleanup) .. ", immediate: " .. tostring(immediate))

    local spawnPos = global.ocore.uniqueSpawns[playerName].pos

    -- Check if it was near someone else's base. (Really just buddy base is possible I think.)
    nearOtherSpawn = false
    for spawnPlayerName,otherSpawnPos in pairs(global.ocore.uniqueSpawns) do
        if ((spawnPlayerName ~= playerName) and (getDistance(spawnPos, otherSpawnPos.pos) < (global.ocfg.spawn_config.gen_settings.land_area_tiles*3))) then
            log("Won't remove base as it's close to another spawn: " .. spawnPlayerName)
            nearOtherSpawn = true
        end
    end

    -- Unused Chunk Removal mod (aka regrowth)
    if (cleanup and global.ocfg.enable_abandoned_base_removal and (not nearOtherSpawn) and global.ocfg.enable_regrowth) then
log("UniqueSpawnCleanupRemove: yes remove chunks")
        if (global.ocore.uniqueSpawns[playerName].vanilla) then
            log("Returning a vanilla spawn back to available.")
            table.insert(global.vanillaSpawns, {x=spawnPos.x,y=spawnPos.y})
        end

        if (immediate) then
            log("IMMEDIATE Removing base: " .. spawnPos.x .. "," .. spawnPos.y)
--            removeBNWForce(spawnPos.x, spawnPos.y)
            RegrowthMarkAreaForRemoval(spawnPos, math.ceil(global.ocfg.spawn_config.gen_settings.land_area_tiles/CHUNK_SIZE +3))  -- vf previous divided by /CHUNK_SIZE - need bigger for roboport
            TriggerCleanup()
        else
            log("Removing permanent flags on base: " .. spawnPos.x .. "," .. spawnPos.y)
            RegrowthMarkAreaNotPermanentOVERWRITE(spawnPos, math.ceil(global.ocfg.spawn_config.gen_settings.land_area_tiles/CHUNK_SIZE + 3)) -- previous divided by /CHUNK_SIZE
        end
	else
log("UniqueSpawnCleanupRemove: NO don't remove chunks. cleanup: " .. tostring(cleanup) .. ", global.ocfg.enable_abandoned_base_removal: " .. tostring(global.ocfg.enable_abandoned_base_removal) .. ", nearOtherSpawn: " .. tostring(nearOtherSpawn) .. ", global.ocfg.enable_regrowth: " .. tostring(global.ocfg.enable_regrowth))
    end

    global.ocore.uniqueSpawns[playerName] = nil
end

function CleanupPlayerGlobals(playerName)

    -- Clear the buddy pair IF one exists
    if (global.ocore.buddyPairs[playerName] ~= nil) then
        local buddyName = global.ocore.buddyPairs[playerName]
        global.ocore.buddyPairs[playerName] = nil
        global.ocore.buddyPairs[buddyName] = nil
    end

    -- Remove them from the buddy waiting list
    for idx,name in pairs(global.ocore.waitingBuddies) do
        if (name == playerName) then
            table.remove(global.ocore.waitingBuddies, idx)
            break
        end
    end

    -- Clear buddy spawn options (should already be cleared, but just in case it isn't)
    if (global.ocore.buddySpawnOpts[playerName] ~= nil) then
        global.ocore.buddySpawnOpts[playerName] = nil
    end

    -- Transfer or remove a shared spawn if player is owner
    if (global.ocore.sharedSpawns[playerName] ~= nil) then

        local teamMates = global.ocore.sharedSpawns[playerName].players

        if (#teamMates >= 1) then
            local newOwnerName = table.remove(teamMates) -- Remove 1 to use as new owner.
            TransferOwnershipOfSharedSpawn(playerName, newOwnerName)
            SendBroadcastMsg(playerName .. "has left so " .. newOwnerName .. " now owns their base.")
        else
            global.ocore.sharedSpawns[playerName] = nil
        end
    end

    -- Remove from other shared spawns (need to search all)
    for _,sharedSpawn in pairs(global.ocore.sharedSpawns) do
        for key,name in pairs(sharedSpawn.players) do
            if (playerName == name) then
                sharedSpawn.players[key] = nil;
                goto LOOP_BREAK -- Nest loop break.
            end
        end
    end
    ::LOOP_BREAK::

    -- Clear their personal spawn point info
    if (global.ocore.playerSpawns[playerName] ~= nil) then
        global.ocore.playerSpawns[playerName] = nil
    end

    -- Remove them from the delayed spawn queue if they are in it
    for idx,delayedSpawn in pairs(global.ocore.delayedSpawns) do
        if (playerName == delayedSpawn.playerName) then
            if (delayedSpawn.vanilla) then
                log("Returning a vanilla spawn back to available.")
                table.insert(global.vanillaSpawns, {x=delayedSpawn.pos.x,y=delayedSpawn.pos.y})
            end

            table.remove(global.ocore.delayedSpawns, idx)
            log("Removing player from delayed spawn queue: " .. playerName)
            break
        end
    end

    if (global.ocore.playerCooldowns[playerName] ~= nil) then
        global.ocore.playerCooldowns[playerName] = nil
    end

    global.oarc_store.pmf_counts[playerName] = {}
end

function TransferOwnershipOfSharedSpawn(prevOwnerName, newOwnerName)
    -- Transfer the shared spawn global
    global.ocore.sharedSpawns[newOwnerName] = global.ocore.sharedSpawns[prevOwnerName]
    global.ocore.sharedSpawns[newOwnerName].openAccess = false
    global.ocore.sharedSpawns[prevOwnerName] = nil

    -- Transfer the unique spawn global
    global.ocore.uniqueSpawns[newOwnerName] = global.ocore.uniqueSpawns[prevOwnerName]
    global.ocore.uniqueSpawns[prevOwnerName] = nil

    game.players[newOwnerName].print("You have been given ownership of this base!")
end

--[[
  _  _  ___  _     ___  ___  ___     ___  _____  _   _  ___  ___ 
 | || || __|| |   | _ \| __|| _ \   / __||_   _|| | | || __|| __|
 | __ || _| | |__ |  _/| _| |   /   \__ \  | |  | |_| || _| | _| 
 |_||_||___||____||_|  |___||_|_\   |___/  |_|   \___/ |_|  |_|  
                                                              
--]]

-- Same as GetClosestPosFromTable but specific to global.ocore.uniqueSpawns
function GetClosestUniqueSpawn(pos)

    local closest_dist = nil
    local closest_key = nil

    for k,s in pairs(global.ocore.uniqueSpawns) do
        local new_dist = getDistance(pos, s.pos)
        if (closest_dist == nil) then
            closest_dist = new_dist
            closest_key = k
        elseif (closest_dist > new_dist) then
            closest_dist = new_dist
            closest_key = k
        end
    end

    if (closest_key == nil) then
        -- log("GetClosestUniqueSpawn ERROR - None found?")
        return nil
    end

    return global.ocore.uniqueSpawns[closest_key]
end

-- Return the owner of the shared spawn for this player.
-- May return nil if player has not spawned yet.
function FindPlayerSharedSpawn(playerName)

    -- If the player IS an owner, he can't be in any other shared base.
    if (global.ocore.sharedSpawns[playerName] ~= nil) then
        return playerName
    end

    -- Otherwise, search all shared spawns for this player and return the owner.
    for ownerName,sharedSpawn in pairs(global.ocore.sharedSpawns) do
        for _,sharingPlayerName in pairs(sharedSpawn.players) do
            if (playerName == sharingPlayerName) then
                return ownerName
            end
        end
    end

    -- Lastly, return nil if not found. Means player hasn't been assigned a base yet.
    return nil
end

-- Returns the number of players currently online at the shared spawn
function GetOnlinePlayersAtSharedSpawn(ownerName)
    if (global.ocore.sharedSpawns[ownerName] ~= nil) then

        -- Does not count base owner
        local count = 0

        -- For each player in the shared spawn, check if online and add to count.
        for _,player in pairs(game.connected_players) do
            if (ownerName == player.name) then
                count = count + 1
            end

            for _,playerName in pairs(global.ocore.sharedSpawns[ownerName].players) do

                if (playerName == player.name) then
                    count = count + 1
                end
            end
        end

        return count
    else
        return 0
    end
end

-- Get the number of currently available shared spawns
-- This means the base owner has enabled access AND the number of online players
-- is below the threshold.
function GetNumberOfAvailableSharedSpawns()
    local count = 0

    for ownerName,sharedSpawn in pairs(global.ocore.sharedSpawns) do
        if (sharedSpawn.openAccess and
            (game.players[ownerName] ~= nil) and
            game.players[ownerName].connected) then
            if ((global.ocfg.max_players_shared_spawn == 0) or
                (#global.ocore.sharedSpawns[ownerName].players < global.ocfg.max_players_shared_spawn)) then
                count = count+1
            end
        end
    end

    return count
end

function DoesPlayerHaveCustomSpawn(player)
    for name,spawnPos in pairs(global.ocore.playerSpawns) do
        if (player.name == name) then
            return true
        end
    end
    return false
end

function ChangePlayerSpawn(player, pos)
    global.ocore.playerSpawns[player.name] = pos
    global.ocore.playerCooldowns[player.name] = {setRespawn=game.tick}
end


function QueuePlayerForDelayedSpawn(playerName, spawn, moatEnabled, vanillaSpawn)

    -- If we get a valid spawn point, setup the area
    if ((spawn.x ~= 0) or (spawn.y ~= 0)) then
        global.ocore.uniqueSpawns[playerName] = {pos=spawn,moat=moatEnabled,vanilla=vanillaSpawn}

        --vf local delay_spawn_seconds = 5*(math.ceil(global.ocfg.spawn_config.gen_settings.land_area_tiles/CHUNK_SIZE))
		local delay_spawn_seconds = 5
        game.players[playerName].print("Generating your spawn now, please wait for at least " .. delay_spawn_seconds .. " seconds...")
        game.players[playerName].surface.request_to_generate_chunks(spawn, 4)
        delayedTick = game.tick + delay_spawn_seconds*TICKS_PER_SECOND
        table.insert(global.ocore.delayedSpawns, {playerName=playerName, pos=spawn, moat=moatEnabled, vanilla=vanillaSpawn, delayedTick=delayedTick})

        HideOarcGui(game.players[playerName])
        HideOarcStore(game.players[playerName])
        DisplayPleaseWaitForSpawnDialog(game.players[playerName], delay_spawn_seconds)

        RegrowthMarkAreaSafeGivenTilePos(spawn, math.ceil(global.ocfg.spawn_config.gen_settings.land_area_tiles/CHUNK_SIZE), true)

    else
        log("THIS SHOULD NOT EVER HAPPEN! Spawn failed!")
        SendBroadcastMsg("ERROR!! Failed to create spawn point for: " .. playerName)
    end
end


-- Check a table to see if there are any players waiting to spawn
-- Check if we are past the delayed tick count
-- Spawn the players and remove them from the table.
function DelayedSpawnOnTick()
    if ((game.tick % (30)) == 1) then
        if ((global.ocore.delayedSpawns ~= nil) and (#global.ocore.delayedSpawns > 0)) then
            for i=#global.ocore.delayedSpawns,1,-1 do
                delayedSpawn = global.ocore.delayedSpawns[i]

                if (delayedSpawn.delayedTick < game.tick) then
                    -- TODO, add check here for if chunks around spawn are generated surface.is_chunk_generated(chunkPos)
                    if (game.players[delayedSpawn.playerName] ~= nil) then
                        log("Delayed spawn for: " .. game.players[delayedSpawn.playerName].name)
                        SendPlayerToNewSpawnAndCreateIt(delayedSpawn)
                    end
                    table.remove(global.ocore.delayedSpawns, i)
                end
            end
        end
    end
end

function SendPlayerToSpawn(player)
    if (DoesPlayerHaveCustomSpawn(player)) then
        SafeTeleport(player,
                        game.surfaces[GAME_SURFACE_NAME],
                        global.ocore.playerSpawns[player.name])
    else
        SafeTeleport(player,
                        game.surfaces[GAME_SURFACE_NAME],
                        game.forces[global.ocfg.main_force].get_spawn_position(GAME_SURFACE_NAME))
    end
end

function SendPlayerToRandomSpawn(player)
    local numSpawns = TableLength(global.ocore.uniqueSpawns)
    local rndSpawn = math.random(0,numSpawns)
    local counter = 0

    if (rndSpawn == 0) then
        player.teleport(game.forces[global.ocfg.main_force].get_spawn_position(GAME_SURFACE_NAME), GAME_SURFACE_NAME)
        log("Player teleport to " .. game.forces[global.ocfg.main_force].get_spawn_position(GAME_SURFACE_NAME));
    else
        counter = counter + 1
        for name,spawn in pairs(global.ocore.uniqueSpawns) do
            if (counter == rndSpawn) then
                player.teleport(spawn.pos)
                break
            end
            counter = counter + 1
        end
    end
end

--[[
  ___  ___   ___   ___  ___     ___  ___  ___  ___  ___  ___  ___  ___ 
 | __|/ _ \ | _ \ / __|| __|   / __|| _ \| __|/ __||_ _|| __||_ _|/ __|
 | _|| (_) ||   /| (__ | _|    \__ \|  _/| _|| (__  | | | _|  | || (__ 
 |_|  \___/ |_|_\ \___||___|   |___/|_|  |___|\___||___||_|  |___|\___|
                                                                       
--]]

function CreateForce(force_name)
    local newForce = nil

    -- Check if force already exists
    if (game.forces[force_name] ~= nil) then
        log("Force doesn't exist - create it! Force name: " .. force_name);
        return CreateForce(force_name .. "_") -- Append a character to make the force name unique.

    -- Create a new force
    elseif (TableLength(game.forces) < MAX_FORCES) then
        newForce = game.create_force(force_name)
        if global.ocfg.enable_shared_team_vision then
            newForce.share_chart = true
        end
        if global.ocfg.enable_research_queue then
            newForce.research_queue_enabled = true
        end
        -- Chart silo areas if necessary
        if global.ocfg.frontier_rocket_silo and global.ocfg.frontier_silo_vision then
            ChartRocketSiloAreas(game.surfaces[GAME_SURFACE_NAME], newForce)
        end
        SetCeaseFireBetweenAllForces()
        SetFriendlyBetweenAllForces()
        newForce.friendly_fire = global.ocfg.enable_friendly_fire
        if (global.ocfg.enable_anti_grief) then
            log("Turning ON anti-grief settings")
            AntiGriefing(newForce)
        end

        if global.ocfg.lock_goodies_rocket_launch and not global.ocore.satellite_sent then
            for _,v in ipairs(LOCKED_TECHNOLOGIES) do
                DisableTech(newForce, v.t)
            end
        end
    else
        log("TOO MANY FORCES!!! - CreateForce()")
        return game.forces[global.ocfg.main_force]
    end

    -- Add productivity bonus for solo teams.
    if (ENABLE_FORCE_LAB_PROD_BONUS) then
        local tech_mult = game.difficulty_settings.technology_price_multiplier
        if (tech_mult > 1) and (force_name ~= global.ocfg.main_force) then
            newForce.laboratory_productivity_bonus = (tech_mult-1)
        end
    end
    log("Difficulty multiplier: ".. game.difficulty_settings.technology_price_multiplier)
    -- Loot distance buff
    newForce.character_loot_pickup_distance_bonus = 16

    return newForce
end

function CreatePlayerCustomForce(player)

    local newForce = CreateForce(player.name)
    player.force = newForce

    if (newForce.name == player.name) then
        SendBroadcastMsg(player.name.." has started their own team!")
    else
        player.print("Sorry, no new teams can be created. You were assigned to the default team instead.")
    end

    return newForce
end

--[[
 __   __ _    _  _  ___  _     _       _     ___  ___   _ __      __ _  _  ___ 
 \ \ / //_\  | \| ||_ _|| |   | |     /_\   / __|| _ \ /_\\ \    / /| \| |/ __|
  \ V // _ \ | .` | | | | |__ | |__  / _ \  \__ \|  _// _ \\ \/\/ / | .` |\__ \
   \_//_/ \_\|_|\_||___||____||____|/_/ \_\ |___/|_| /_/ \_\\_/\_/  |_|\_||___/
                                                                               
--]]

-- Function to generate some map_gen_settings.starting_points
-- You should only use this at the start of the game really.
function CreateVanillaSpawns(count, spacing)

    local points = {}

    -- Get an ODD number from the square of the input count.
    -- Always rounding up so we don't end up with less points that requested.
    local sqrt_count = math.ceil(math.sqrt(count))
    if (sqrt_count % 2 == 0) then
        sqrt_count = sqrt_count + 1
    end

    -- Need to know how much to offset the grid.
    local sqrt_half = math.floor((sqrt_count-1)/2)

    if (sqrt_count < 1) then
        log("CreateVanillaSpawns less than 1!!")
        return
    end

    if (global.vanillaSpawns == nil) then
        global.vanillaSpawns = {}
    end

    -- This should give me points centered around 0,0 I think.
    for i=-sqrt_half,sqrt_half,1 do
        for j=-sqrt_half,sqrt_half,1 do
            if (i~=0 or j~=0) then -- EXCEPT don't put 0,0

                local x_pos = (i*spacing)
                x_pos = x_pos - (x_pos % CHUNK_SIZE) + (CHUNK_SIZE/2)
                local y_pos = (j*spacing)
                y_pos = y_pos - (y_pos % CHUNK_SIZE) + (CHUNK_SIZE/2)

                table.insert(points, {x=x_pos,y=y_pos})
                table.insert(global.vanillaSpawns, {x=x_pos,y=y_pos})
            end
        end
    end

    -- Do something with the return value.
    return points
end

-- Useful when combined with something like CreateVanillaSpawns
-- Where it helps ensure ALL chunks generated use new map_gen_settings.
function DeleteAllChunksExceptCenter(surface)
    -- Delete the starting chunks that make it into the game before settings are changed.
    for chunk in surface.get_chunks() do
        -- Don't delete the chunk that might contain players lol.
        -- This is really only a problem for launching AS the host. Not headless
        if ((chunk.x ~= 0) and (chunk.y ~= 0)) then
log("delete chunk: x: " .. chunk.x .. ", y: " .. chunk.y)
            surface.delete_chunk({chunk.x, chunk.y})
        end
    end
end

-- Find a vanilla spawn as close as possible to the given target_distance
function FindUnusedVanillaSpawn(surface, target_distance)
    local best_key = nil
    local best_distance = nil

    for k,v in pairs(global.vanillaSpawns) do

        -- Check if chunks nearby are not generated.
        local chunk_pos = GetChunkPosFromTilePos(v)
        if IsChunkAreaUngenerated(chunk_pos, CHECK_SPAWN_UNGENERATED_CHUNKS_RADIUS, surface) then

            -- Is this our first valid find?
            if ((best_key == nil) or (best_distance == nil)) then
                best_key = k
                best_distance = math.abs(math.sqrt((v.x^2) + (v.y^2)) - target_distance)

            -- Check if it is closer to target_distance than previous option.
            else
                local new_distance = math.abs(math.sqrt((v.x^2) + (v.y^2)) - target_distance)
                if (new_distance < best_distance) then
                    best_key = k
                    best_distance = new_distance
                end
            end

        -- If it's not a valid spawn anymore, let's remove it.
        else
            log("Removing vanilla spawn due to chunks generated: x=" .. v.x .. ",y=" .. v.y)
            table.remove(global.vanillaSpawns, k)
        end
    end

    local spawn_pos = {x=0,y=0}
    if ((best_key ~= nil) and (global.vanillaSpawns[best_key] ~= nil)) then
        spawn_pos.x = global.vanillaSpawns[best_key].x
        spawn_pos.y = global.vanillaSpawns[best_key].y
        table.remove(global.vanillaSpawns, best_key)
    end
    log("Found unused vanilla spawn: x=" .. spawn_pos.x .. ",y=" .. spawn_pos.y)
    return spawn_pos
end


function ValidateVanillaSpawns(surface)
    for k,v in pairs(global.vanillaSpawns) do

        -- Check if chunks nearby are not generated.
        local chunk_pos = GetChunkPosFromTilePos(v)
        if not IsChunkAreaUngenerated(chunk_pos, CHECK_SPAWN_UNGENERATED_CHUNKS_RADIUS+15, surface) then
            log("Removing vanilla spawn due to chunks generated: x=" .. v.x .. ",y=" .. v.y)
            table.remove(global.vanillaSpawns, k)
        end
    end
end

