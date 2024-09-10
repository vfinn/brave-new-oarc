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
    log("SeparateSpawnsPlayerCreated: Player: " .. player.name .. ", Force: " .. player.force.name)
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
    local kOffset=0
    if not global.ocfg.dangOreus then
        if global.ocfg.bzlead then
            GenerateResourcePatch(surface, "lead-ore", 15, {x=pos.x-94, y=pos.y+29}, 20000)
        end
        if global.ocfg.bztitanium then
            GenerateResourcePatch(surface, "titanium-ore", 8, {x=pos.x-61, y=pos.y-34}, 10000)
        end
        if global.ocfg.krastorio2 then
            kOffset=32
            if game.active_mods["scrap-resource"] then
                GenerateResourcePatch(surface, "scrap", 12, {x=pos.x-42-kOffset, y=pos.y-57}, 3000)
            end
            GenerateResourcePatch(surface, "rare-metals", 16, {x=pos.x-62-kOffset, y=pos.y-38}, 10000)
            if not global.ocfg.krastorio2_resources_increased then
                for k,item in pairs(global.ocfg.spawn_config.resource_tiles) do
                    if (item ~= "") then
                        item.amount = item.amount*4
                    end
                end
            end
            global.ocfg.krastorio2_resources_increased=true
        end
        if game.active_mods["scrap-resource"] then
            GenerateResourcePatch(surface, "scrap", 12, {x=pos.x-42-kOffset, y=pos.y-57}, 3000)
        end
    end
    -- generate normal ore patch's in main
    if not global.ocfg.seablock and not global.ocfg.dangOreus then
        -- Generate all resource tile patches
        if (not rand_settings.enabled) then
            for t_name,t_data in pairs (global.ocfg.spawn_config.resource_tiles) do
                local pos = {x=pos.x+t_data.x_offset - kOffset, y=pos.y+t_data.y_offset}
                GenerateResourcePatch(surface, t_name, t_data.size, pos, t_data.amount * game.surfaces.oarc.map_gen_settings.autoplace_controls[t_name].richness) 
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
    end
    if global.ocfg.dangOreus then   -- clear oil area
        -- clear under oil patches
        local p_data = global.ocfg.spawn_config.resource_patches["crude-oil"]
        local oil_patch_x=pos.x+p_data.x_offset_start
        local oil_patch_y=pos.y+p_data.y_offset_start
        for i=1,p_data.num_patches do
            local entities = surface.find_entities_filtered{area = {{oil_patch_x-9, oil_patch_y-8}, {oil_patch_x+10, oil_patch_y+8}}, force = "neutral"}
            for _, entity in pairs(entities) do
                entity.destroy()
            end
            oil_patch_x=oil_patch_x+p_data.x_offset_next
            oil_patch_y=oil_patch_y+p_data.y_offset_next
        end
    end
    -- Generate special resource patches (oil)
    if not global.ocfg.seablock then
        for p_name,p_data in pairs (global.ocfg.spawn_config.resource_patches) do
            local oil_patch_x=pos.x+p_data.x_offset_start
            local oil_patch_y=pos.y+p_data.y_offset_start
            for i=1,p_data.num_patches do
                surface.create_entity({name=p_name, amount=p_data.amount,position={oil_patch_x, oil_patch_y}})
                oil_patch_x=oil_patch_x+p_data.x_offset_next
                oil_patch_y=oil_patch_y+p_data.y_offset_next
            end
        end
    end
end

function SendPlayerToNewSpawnAndCreateIt(delayedSpawn)
    -- DOUBLE CHECK and make sure the area is super safe.
    local player = game.players[delayedSpawn.playerName]
    log("SendPlayerToNewSpawnAndCreateIt: " .. player.name .. ", force: " .. player.force.name)
    if global.ocfg.space_block then
        if (global.ocfg.frontier_rocket_silo and not global.ocfg.enable_magic_factories) then
            if not global.make_silos then
                GenerateRocketSiloAreas(game.surfaces[GAME_SURFACE_NAME])
                global.make_silos=true
            end
        end

        for _,v in ipairs(SPACE_BLOCK_RECIPES_REMOVE_ALL_PLAYERS) do
            RemoveRecipe(player.force, v.r)
        end           

        -- remove more items from research if you are Space Block and BNO Player
        if global.players[player.index].characterMode then
            for _,v in ipairs(SPACE_BLOCK_UNLOCKED_TECHNOLOGIES_CHAR) do
                EnableTech(player.force, v.t)
            end
        else
            for _,v in ipairs(SPACE_BLOCK_LOCKED_TECHNOLOGIES_BNO) do
                DisableTech(player.force, v.t)
            end
        end
    else
        if global.ocfg.dangOreus then -- Silo
            -- dangOreus writes on top of the silo's, so generate on_init, then regenerate clearing ore after dangOreus finishing on_chunk_generated
            if global.ocfg.forceRegenerationOfSilos and (global.ocfg.frontier_rocket_silo and not global.ocfg.enable_magic_factories) then
                GenerateRocketSiloAreas(game.surfaces[GAME_SURFACE_NAME])
                global.ocfg.forceRegenerationOfSilos=false
            end
        end
        ClearNearbyEnemies(delayedSpawn.pos, global.ocfg.spawn_config.safe_area.safe_radius, game.surfaces[GAME_SURFACE_NAME])
        if not global.ocfg.seablock then
            if (not delayedSpawn.vanilla) then

                -- Generate water strip only if we don't have a moat.
                if (not delayedSpawn.moat) then
                    local water_data = global.ocfg.spawn_config.water
                    -- top left
                    CreateWaterStrip(game.surfaces[GAME_SURFACE_NAME],
                                    {x=delayedSpawn.pos.x+water_data.x_offset, y=delayedSpawn.pos.y+water_data.y_offset},
                                    water_data.length)
                    CreateWaterStrip(game.surfaces[GAME_SURFACE_NAME],
                                    {x=delayedSpawn.pos.x+water_data.x_offset+1, y=delayedSpawn.pos.y+water_data.y_offset},
                                    water_data.length)
                end
            end
            -- Create the spawn resources here
            GenerateStartingResources(game.surfaces[GAME_SURFACE_NAME], delayedSpawn.pos)
        end
    end
    -- Render some welcoming text...
    DisplayWelcomeGroundTextAtSpawn(player, delayedSpawn.pos)	

    -- Render Brave New World Items - vf
    global.spawn[player.index] = delayedSpawn.pos  -- save the starting position, this is how we determine who died when a starting roboport is killed
    setupBNWForce(player, delayedSpawn.pos.x, delayedSpawn.pos.y)
    if global.players[player.index]. characterMode then
        GivePlayerStarterItems(player)
    end
    -- Chart the area.
    ChartArea(player.force, delayedSpawn.pos, math.ceil(global.ocfg.spawn_config.gen_settings.land_area_tiles/CHUNK_SIZE), player.surface)

    if (player.gui.screen.wait_for_spawn_dialog ~= nil) then
        player.gui.screen.wait_for_spawn_dialog.destroy()
    end

    local x_dist = global.ocfg.spawn_config.resource_rand_pos_settings.radius +10        -- moved slightly further out
    if (global.ocfg.krastorio2) then x_dist = x_dist + 32 end  -- not quite a full tile - but exactly to the end of the robot network
    if (global.ocfg.enable_energy_sharing) then
        -- Shared electricity IO pair of scripted electric-energy-interfaces
        SharedEnergySpawnInput(player, {x=delayedSpawn.pos.x+x_dist, y=delayedSpawn.pos.y-11})
        SharedEnergySpawnOutput(player, {x=delayedSpawn.pos.x+x_dist, y=delayedSpawn.pos.y+10})
    end
    if (global.ocfg.enable_chest_sharing and not delayedSpawn.vanilla) then
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
    local SP=delayedSpawn.pos
    SP.y=SP.y+10        -- move them down 10 tiles, otherwise they spawn inside the walls, next to large roboport
    tiles = {}
    for x = SP.x-1,SP.x+1 do
        for y = SP.y-1,SP.y+1 do
            table.insert(tiles, {name = "landfill", position = {x=x, y=y}})
        end
    end
    game.surfaces[GAME_SURFACE_NAME].set_tiles(tiles)

    SafeTeleport(player, game.surfaces[GAME_SURFACE_NAME], SP)
    SetupCharacterOrBNOPlayer(player)
end

function SetupCharacterOrBNOPlayer(player)
    local gPlayer = global.players[player.index]
    preventMining(player)   -- enables or prevents based on character mode
    player.cheat_mode=not gPlayer.characterMode
    if gPlayer.characterMode then 
        if player.character == nil then 
            player.create_character() 
        end
    else
        if player.character then
            log("on_event::On Player created: destroy character")
            player.character.destroy()
            player.character = nil
        end
    end
end

-- Convert player char to bno or vice versa
-- BUT this does not add/remove bots !
-- Also take items from inventory and put into chest
function convertPlayer(player, toBNO)
	global.players[player.index].characterMode= not toBNO
	player.cheat_mode=toBNO
	preventMining(player)
    if toBNO then
		player.character.destroy()
        player.character = nil
	else
        if player.character == nil then 
            player.create_character()
        end
	end
end


-- likely not needed - all chunks within the spawn area are deleted in OarcRegrowthRemoveAllChunks
function removeBNWForce(x, y)
    log("deleting roboport at " .. x .. ", " .. y)    
    game.surfaces[GAME_SURFACE_NAME].delete_chunk({x = x, y = y})
end

--[[FUNCTION DEFINITION]]
--Capture your blueprint with a roboport in it - easier to debug if captured ABSOLUTE on and X,Y at 0,0
-- https://forums.factorio.com/viewtopic.php?t=60584
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
        -- common mistake is to leave the 4 yellow chests in the blueprint, this causes serious problems, if they are there - ignore them
        if ((entity.name == "roboport") or (entity.name == "logistic-chest-storage")) then 
--            log(entity.name .. " - NOT BUILDING at " .. entity.position.x .. ", " .. entity.position.y)
        else
--          log("building: '" .. entity.name .. "' at " .. entity.position.x - offset.x + position.x .. " , " .. entity.position.y -offset.y + position.y)
            entity.position = {entity.position.x - offset.x + position.x, entity.position.y -offset.y + position.y}
            entity.force = force
            entity.raise_built = true
            newEntity = surface.create_entity(entity)
            if entity.name == "accumulator" then 
                newEntity.energy = 5000000 
--              log("modified accumulator to have " .. entity.energy)
            end
        end
    end
end

function setupBNWForce(player, x, y)
log("setupBNWForce: x=" .. x .. ", y=" .. y)
    if not global.forces then
        global.forces = {}
    end
    local force = player.force
    local surface = player.surface
    local characterMode = global.players[player.index].characterMode

    global.forces[force.name] = {characterMode = characterMode} -- track per team - eventually remove from player and index from here

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
    if global.ocfg.seablock then
        local gx = x-math.random(32,90)
        local gy = y+math.random(32,90)
        log("Placing temperate garden at " .. GetGPStext({x=gx, y=gy}))
        local tiles = {}
        local width=5
        local height=5
        local tileRadSqr = width^2
        -- make it roune
        for xx = gx - width, gx + width do
            for yy = gy - height, gy + height do
                local distVar = math.floor((gx - xx)^2 + (gy - yy)^2)

                if (distVar < tileRadSqr) then
                    local tile = surface.get_tile(xx, yy)
                    local name = tile.name
                    if tile.prototype.layer <= 4 then
                        name = "sand-2"
                    end
                    tiles[#tiles + 1] = {name = name, position = {xx, yy}}
                end
            end
        end
        surface.set_tiles(tiles)
        surface.create_entity({name="temperate-garden",amount=50,position = {x=gx, y=gy}, force=game.forces.neutral})
        surface.create_entity({name="desert-garden",   amount=50,position = {x=gx+2, y=gy+2}, force=game.forces.neutral})
        surface.create_entity({name="temperate-tree",  amount=50,position = {x=gx-2, y=gy+2}, force=game.forces.neutral})
        surface.create_entity({name="temperate-tree",  amount=50,position = {x=gx-2, y=gy-2}, force=game.forces.neutral})
        surface.create_entity({name="temperate-tree",  amount=50,position = {x=gx+3, y=gy-2}, force=game.forces.neutral})
        surface.create_entity({name="temperate-tree",  amount=50,position = {x=gx-3, y=gy-3}, force=game.forces.neutral})
    else
        -- setup starting location
        local water_replace_tile = "sand-1"
        force.chart(surface, {{x - 192, y - 192}, {x + 192, y + 192}})
	    -- vf - We always need oil within reach on every map or you can't get outside main, so let's drop a few a small distance away randomly
	    -- put it outside of main, to the left
	    if not global.ocfg.space_block and not global.ocfg.freight_forwarding then
            local xx = x + math.random(CHUNK_SIZE*5, CHUNK_SIZE*6) * (math.random(1, 2) == 1 and 1 or -1)
		
            local yy = y + math.random(CHUNK_SIZE*5, CHUNK_SIZE*6) * (math.random(1, 2) == 1 and 1 or -1)
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
    end

    -- place dirt beneath structures
    local dirtTiles = {}
    local startX=14 
    local extentX=13
    local startY=5
    local extentY=7

    if global.ocfg.space_block then
        startX=16
        extentX=19
        startY=8
        extentY=9
    elseif global.ocfg.dangOreus then
        startX=30
        extentX=30
        startY=30
        extentY=30
    end
    -- remove trees/stones/resources
    local entities = surface.find_entities_filtered{area = {{x - startX, y - startY}, {x + extentX, y + extentY}}, force = "neutral"}
    for _, entity in pairs(entities) do
        entity.destroy()
    end

    for xx = x - startX, x + extentX do
        for yy = y - startY, y + extentY do
            local tile = surface.get_tile(xx, yy)
            local name = tile.name
            if tile.prototype.layer <= 4 then
                name = water_replace_tile
            end
            dirtTiles[#dirtTiles + 1] = {name = "landfill", position = {xx, yy}}
        end
    end
    surface.set_tiles(dirtTiles)

    -- Blueprint rules:
    --      make sure a roboport is captured at center !
    --      make sure there are NO yellow chests in this blueprint
    local blueprint=""
    -- 1.1 MW, 120 MJ storage - large roboport
    -- to make blueprint - be sure there is a roboport in it, and you should remove the 4 yellow chests or mod how they are handled
    -- global.spawn[player.index]
    if (global.ocfg.space_block) then
        if global.ocfg.easyStart then
            log("Space Block: EasyStart for " .. player.name)
            TemporaryHelperText("Check chests for resources", {global.spawn[player.index].x-6, global.spawn[player.index].y+11},  TICKS_PER_MINUTE*4, 2,{0,1,.7,1})
            TemporaryHelperText("Use Space Matter furnaces", {global.spawn[player.index].x-25, global.spawn[player.index].y+2}, TICKS_PER_MINUTE*4, 1,{1,1,1,1})
            TemporaryHelperText("to copy raw iron,copper,stone", {global.spawn[player.index].x-25, global.spawn[player.index].y+3}, TICKS_PER_MINUTE*4, 1,{1,1,1,1})
            blueprint = "0eNqtmt1yszYQQN+Fa/MN+oe8SieTASw7TAFRftpmMn73ynZqsL0y6/V3lcQRZyUhHZaVv6OinmzXV+0YvX1HVenaIXr74zsaqn2b18fPxq/ORm9RNdom2kRt3hz/Glyd93GXt7aODpuoarf23+iNHd43kW3HaqzsGXP64+ujnZrC9r7BBbDLhzGu2sH2o//HJurc4K9y7TGiJ8VCqfSX2kRfp99l8kv5MNuqt+W5lT5s7uj8Qq/dvhrGqozLT+vj9Pavyf8MBcruAv1c8LGran/VeSj/j3Geg9G11hNLNx1njx179NNo7knpus72sesDLcWlZdW7NtxOLoj+vizavC+627vmo5h2u1Ofx36ywCwtIj6cfv1o+jkAnrs49nk7dK4f48LWI4w3j/ASwKsLPh8G2xR11e7jJi8/q9bGDA4i5yAi+7mzZXVaz0OXl7aoXflnvJ06G5+mFQirwTUPRZO30QCawdPYOi1F00S6TsvwNLVOYwkexxE4hsbxDIHjeJxG4Aib6nhL1p3GyLvqng/tKqbI/AzF12S+RvENYeYNRmcsJffcoHqevSg0HRLaR+HcOPhOd5DQ+Lwx+3ybw9Ml1U0gCMRoMgvhFluyyes6rvOmg2niZq4hmqAlA1dsjU8GLkF6V7hxfj6rJJAWtP4GTaflAVzyDo1I0mwfmm5F030Ip2m6D+EMTfchXErTfQi3eFTOaUSTj359xLupb/1nIFwnF7SEwCIhJshCYh4mghFkKTGyFJwsS4mRpRBkvkLx5YsyFjQZi3kXHi1wHFbAx3MkcOFo3J290puCV7d4IklNbqYAws17Ly/LqZnqfHR9wFsr2yPDo/RjlEzwKLmCYngUX0FxPGpFJVKgUXxl2qXEo9amXb1uTg6CNdWcHGNOOe+JcxrwRABxJ9BN9DCXuLyK3qUN55IDmB5IerrKMYaUGZkvUK/3i/fFqRjG/NQUZPPFUvAX2Wr/WbjpNJtKQHOjGEVB4DpTnKIgGCWwI14Y6H7ECThiSXES3E1FcRKM0hQnwShDcRKMSl93UgKCM7o02O+TxqIECZpDk5NOVFVWM7I4UHVBzQlJLcMktZqedDJUz19NOhNa0qkVLcFL4ARPa4pdwR2jDcWuMCqlJHgwKqPIFESZhCJTGMUoMoVRnCJTGCXIzuPZ73Pe5TAFNJ6Rzxhv4Q2eYrxhyDVVjqrZGnJNlaNqtsY88hJf9RI3tKMWk5IKijxQAjQZqWAWwqUJqWAWxDFSwSyI46SCWRAnSAWzII684TQmxUhVqNh7Pgxd3xdPVHr/cW67OH9NQgXe5SntVRVYhE6Qr1rJBwfDVw3Vw7Pmq6azNybvjWpqHrSdHVD209bGrqrjIu97uzx8hivV6VPv4gaxfObOFD4fX32oLJIWjiqMpinxqwPsLhJqDd2sjqfP8NNZbYW/MaFiXxaeBei5lS0MN9q8iW27r1q7ekCEpNOOi05wCMdpdg/hBM3uIZyk2T2EUzS7h3CaZvcQbt6e3fGJD6/FBYcHOPMudLvd8OnlFHdT6BBwCQRet/yWOn1l6W3xDadN9LffVecVmjJpMm6Mlszw9HD4D3k8wQI=";
        else
            log("Space Block: Normal Start for " .. player.name)
            if (settings.startup["bno-main-area-design-boiler-n-steam-engines"].value == "solar only") then
                blueprint = "0eNqlmeFymzAMx9/Fn8MOg40hr7Lr9QxxWt8AMwPber28+yBZC0vkoKifcsk5PxlZf1kS76ysR9N52w5s/85s5dqe7b+/s96+tLqefxveOsP2zA6mYTvW6mb+1rta+6jTranZacdsezB/2J6fnnbMtIMdrLlgzl/entuxKY2fFnwCBq/bvnN+iEpTDxO4c/30N9fOJieUKOLkm9yxN7aPkqSIv8nJzMF6U10WidPuhp580m3bGz9Mv0HcdMXl19wE4KbUXXPMrsUnXfe9acrati9Ro6tX25qIgzbkjWcmC/Z8TH2nK1PWrvrxXDo39NOOOwZYleBRAsb4tTEAlqFh+TZMYWEJ34blaJjYhhVomNqG8RhLS2MEjaNpKYL2uJLyHKMkTpXSLR6SEhdUfIHCyy9JNVc0qfJFXl4fNHgUXFzZgTiKItMgbSWtRtd1VOumA2HZ1TFCsIIi+tDWkpii+iCNU2QfpCUU2QdpKUX2QRpZPhnqepZUvELhM1TS+i8cs4AjFqXU7sX2g62i6tX0Q+TNz3H6RKA/xH5e/3y09fSnS030USzd2vCudLM3KjfO9ZiM5739W77EzVyjDX48uwL4yxP0QDnV9QLl+uLx+0KiKq+Yum+J2XfKv5bQBS2hp8tZzsc3PxRceS2GoChN0eLnxdWmIdqqDq2qsRlrPTjwGOcU9uFlkCTRJLFBytCkbIOk0KR8g5RjSXPw3iUVaNKGx0WMJm14XPDHlZxglCwSqpITVBNFLixTFP5rTVrOaYlCrLq0sewHfbYAGVuCNp0Mtca+vJZuPF84ooBuBJGRkgeHk4dQhOSRgqSckDxgUoF03ip33DpPQs6TMSGbgJuUnJBNYFJCyCYwKSVkE5hELihR8x5JLihRgxmZEYKag35QhKCGSTnhRoRJBSGGQVIWE2IYJnFCDMOkhBDDMGlRw1FPHcDda3EVYyrQ6mZUTSjUjCK7O6NItm4qldNuqow0Agz6iDQDDNJIQ8AgjTQFDNEUaQoYpJGmgEFaEuqCy/F4RCjggRb4t3OHpYvlcajz1XWgPV71QoNrTWDVoj3rp+bZ+dBCubLZdcbfWbpE/jjp2Y7NnbVLXFd+PJjI2ToqtfemXj882MKrR/JQenMKG+W5EpT3AUoGIkeSskGIlpGyQYimSNkgRMtJ2SBEK0jZIEDLY1I2ONOedpcXfvvV+8Ed+zXp9xJCORdqeiSVCa6S/HT6C7+g/kg="
            else        
                blueprint = "0eNqlmW1vozAMx78Lr8tEgPDQr3KapkDTLjogXAh3N0397hfoNrjWKa73qmoVfg6O/47tvgdVM8reqM4G+/dA1bobgv2P92BQp04002/2rZfBPlBWtsEu6EQ7fRt0I0zYi042wXkXqO4g/wZ7dn7eBbKzyip5wcxf3l66sa2kcQu+ANaIbui1sWElG+vAvR7cY7qbTDpUWkbxE98Fb8E+jJM4feLOzEEZWV8WpefdDT3+oqtukMa63yBusuLya24McBPqrjlm1+kXXQyDbKtGdaewFfWr6mTIQBv8xjPOgpqPaehFLatG1z9fKq3t4HbcB4BVDh4lYIxdGwNgGRpWbMNyLCxm27ACDUu3YSUalm/DWISlJRGCxtC0BEEjKCnGKImRpRRjpMRSKj5B4fn3pMpoUmWLvIw4CPAoWHplB+KslNWKpgkb0fYgLLtyPAQrSJr3ba0kid5DiyOS6n00RpK9jxaTZO+jJSTZ+2hk+USo65lT8QyFz1BJ67/gjjyOWJTS6JMarKrD+lUONjTy1+g+EehPsc/rX46qcQ9daqLPYunWhtGVnrxR63Gqx3g07e1j+RI3U41mzTi7AnjkGXqhguj6SbwI15cP3xesRFVeEXXfJWbfCftWQv9wzsMJPVnOcjq+6aXgymsxBEVpghb/5I3/Ng3RVnVoXY/t2AirwWOcUtinl0ESR5PSDVKGJmUbpBxNKjZIBZY0Be9dUokmbXg8jdCkDY+n7HElZxglpzFVyRmqiaIWlixH4b/XpDFOSxTpqksbq8GK2QJkbAna3BnqpDq9VnqcL5y0hG6ENCMlDw4njzQnJI8cJBWE5AGTSqTzVrnj1nkcch6PCNkE3CRnhGwCk2JCNoFJCSGbwCRqQclQ8x5OLSgZajDDM0JQg/LgOSGoYVJBuBFhUkmIYXj6ExFiGCYxQgzDpJgQwzBpUcNRuA7g7rW4jjFP45yRNYGaUWR3ZxTx5k0V026qjDQC9PqINAP00khDQC+NNAX00XLSFNBLI00BvbTY1wVX4/GIUMADLfAfrQ9LF8siX+crGk97vOqFrO6kZ9WiPWVc86yNbyFf2ex7ae4sXSJ/dHpWY3tn7RLXtRkPMtSqCSthjGzWLw+28PkjeSi5OYWN8jxfPFO5TXnmG+wTGqG693xVvlop2lB2JzWfzd35JRJOyjgzG6KRMo6XRso4Xhop4/hoBSnjeGmkjOOlLVKvRtM52d2N8vJezGQQPyHN9aLixhAqqV2lq+nP0a/njG5fLmnUPWzNKKHtLqLUx+Pw6vJK2I+emf36sFAtc7Gos58u+y3o1ChPrzD/Ebxf/W+8C367t7gItWBp7sIwz1KWx8X5/A9KAql6"
            end
        end
    elseif global.ocfg.seablock then
--                if (settings.startup["bno-main-area-design-boiler-n-steam-engines"].value == "solar only") then
        blueprint = "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"
    elseif global.ocfg.dangOreus then   -- blueprint
        blueprint = "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"
    elseif characterMode then
        -- Normal Oarc game - with a character
        blueprint = "0eNqVmt1uo0AMhd+F67Ri7GF+8iqrakVa1EVKICJkd6sq774kVdtoNcY+d00lvniG44OZk/dqtz93x6kf5mr7XvXP43Cqtj/eq1P/OrT76//mt2NXbat+7g7Vphraw/XTady308OxHbp9ddlU/fDS/a227rJRr2yfn8+H876dx+nuSro8bapumPu57z4KuH14+zmcD7tuWtDfXz2PQ/fwp93vF+hxPC2XjMP16xbMg0+PzaZ6W/5q/GNzudbzH4hgUFMGcXEzCqTwReIyyRtLClpJjREUNVCwro21tUVjSV4rKRlBjQbKRhBpIFcbSaySnHW/a22/nVXftVoUG0lOJXnj8jiqyzNKnNX2dcFIyirJqHFW+9cZRc5qA7tvlU/tSzuVIF7bbDIKnNXmJaN9s9q9dKfvwwJ52LeHY4lE6oPAqG9WjYCMBs6qEVBj7RTVCMiqb9UIyKpv1QgoGZdHqhGQ0cZJf44bVU6qEbBR5aQaARtdnFQjYOuYQqodsFHmpNoBG12cVDtg66RCTl2eUeak+gEbbZxUP2CrytUm9laVq03sjSp3WXNgTzBJqonhqZ4EkodJ0lTfwKuTagowSaopwqurBVKCSU4g5eK7Yem15RNUfPeprZhmFeOsGF7FkBXjVjFW92b1hjXfwp7G3Xgcp7k4yn1SigzreHL3rJTKCcYNovW7Hq2Y9buerJj1u26VMq3e9VDD/S7scsC9WujSAJ+bXP8qkmCv9lkgedA5fC5i7lR93p3m9napbBwLZbmg619/7cbzdD2tivVTiRtAKxHKi6CVCJgEW8n1nKiIyrANSKhY2/aeorT3oSntfXSgL5Q3LRLoCwKGQV8QMB7tZqkHIzybSD0YA9zNQSDBs4koqoT6QixiMjhRlDGpRm2gjHGoDZQxBD53BQyj/VXGeLS/ypgG7a8yBp6zJS2nCJMELSd4zvbC21bKMEk6Qa/h6EMqKjs4aRBRBB+iiyiGD6xFlFXh/AUqYqwKZ17FBPh8UVxYhM/yRFSCz6hEVIbPgySUq+ExXEbBc7gXQyd8ECcJhU/iUixTwxmmXBWcYsqogKaPMiqi+aOMSmgCKaMyGkGKKHOaWesohyaHMorQvE9GMRr4ySiPJn4yqkEjPxkV0LhORkU0r5NRCY3ZZFRGczYRZY42dbWbs01d7URoqCWjGE21ZJRHYy0Z1aC5lowKaBoloyIaR8mohIZIMiqjKZKIMkecutrNGaeudobjHxnFMOo2yTxtPn6dtr37Gdym+t1Np9tFlJyPmWKiHOuUL5d/RoFoZA=="
    else
        if (settings.startup["bno-main-area-design-boiler-n-steam-engines"].value == "solar only") then
--          solar only
            blueprint = "0eNqdmuuOm0gQRt+F33ZEVV/xq6xGEXbIBAmDF/DujkZ+9wVPJrYSqqu6fo08MsdcvlN0d/V7ceyuzWVs+7k4vBftaein4vDXezG1r33drf+b3y5NcSjauTkXu6Kvz+unaejqcX+p+6Yrbrui7b81/xUHuO3YI+vT6Xq+dvU8jE9H4u1lVzT93M5t83EC9w9vX/vr+diMC/rx0/PQN/t/665boJdhWg4Z+vXnFszeRotf3K54W44wFXxxt/WUfmOhmFWyLCNmAcuyUpaJLMuJWRXL8mKWZ1lBzAosK4pZlmVVYpZjWVCKYXxYQZx8Y3iYOPqGjz6Is2/47IM4/MiHH8TpRz79II4/8vEHcf6Rzz+IBUBeABAbgLwBKDYABeVabADyBqDYAOQNQLEByBuAYgOANwDFBgBvAIoNAN4AFBsAvAEoNgB4A1BsAPAGGLEBwIfWqEY/SMBQAzMEzGwOCbnBFEWzYtrz8ICiOTnN8jQvpwFPe1gw1t/qkX3TUZwnAc7Lc9x39fnCvpyoZDwE6IbXdprb0/70o5nm/dj8fV3+NiOLXs9zV/z8/tfvbbcc9DGg/5wj/Pkb43Ac5oV8Gq7rNMSV67l9Tgx+fX2dmszj9bT+9sYhL1sD6lL8zJBPgAU5jU+ARTEN+BxYuYfPxYuiWU3xIlJlnQZGnZnXFC9LwIIG5ghY3Jzibk8FP1l+k1SJSauxCZIr5aSQJoGc5NIkee6fZ0eemOY+cr+WhMswzkQp/QSFTcwj8G0/NaOk0hGhcvK3zvNwlbo+L77vmE6VC2ISMKmSJx2YVMmTDulUedVwi3iEHjQwoi541XCLiIM3GlggYFZRseImySkq1jbJKyrWNumpuF+P01zfj04XrLgMXfqmff1xHK73UYuPW8MKH6VoBBodNtGVwtLN6w+lwtJtEigs3SahRizChWA0MMKFYDViRQLmNLCKgPlsS21ZbpJCtqUUKWZbSpGq7HEFQYqlalxB3PUIqrc4RcPstzh1lSa7PlAkm10fKJLLrg8UyWuUJiyMQQOjnmDMV3q5SAJWaWBU46JUrMDYkpisVaBYgaFpqFiBoWlGsQJD06xibYCmOcXaAE3zirUBmhYUawM0LeZrRZpQVRoY2XYrNV4hRQMNzVC0jFfAr8JttlHydwAGBmU195+8Y05DI++Y19x/S9FCftM/QYv5bf8Ercpv/NO0jO5zJaBBfvM/QcP89n+CZvI3ACRoNn8LQILm8vcAJGg+fxNAghbydwEkaDF/G0CCVuXvA6BpGX1ogQsZjWiBCxmdaIELGa1ogQvyXjQKXJA3o1HggrwbjQIX5O1oFLgg70ejwIWMhrTAhYyOtMAFeUsaBC7Ie9IgcMGY/F0BCZrN3xaQoKnGSHfay+5jK+Xhac/mrvinGaf7cbhcTagwBG8hYLzd/gdAgBor"
        else
--      adding the boiler to existing ssolar - water pump over land - not water
            blueprint = "0eNqdmutum0AQhd+F36Zihr2AX6WKKuxsEiQMFEPbKPK7F+ymRu2OZ5hfkSP243bO7OwePpJDM4V+qNsx2X8k9bFrz8n+60dyrl/bqln+N773Idkn9RhOyS5pq9Py69w11ZD2VRua5LJL6vY5/Er2cNmxI6vjcTpNTTV2w2okXp52SWjHeqzD7QKuP96/tdPpEIYZfT/12LUh/Vk1zQztu/M8pGuX082Y1BQGv9hd8j6PMFh+sZflkv5hoZgFLCsXszKWZaSsvGRZVswqWJYTszzL8mKWY1mFmGVZVilmGZYFmRiW8zCx8nNe+SCWfs5LH8Taz3ntg1j8yIsfxOpHXv0glj/y8gex/pHXP4gNgLwBQOwA5B2AYgcg7wAUOwAFtV/sAOQdgGIHIO8AFDsAeAeg2AHAOwDFDgDeASh2APAOQLEDgHcAih0AvANysQOAd0Cu6X6WohuFoQYGBCyPtoRMA0TSjJi2ajVImpXTDE9zchrwtLsLhuq5GrjJieSsDHCa32PaVKeem09IZdwN0HSv9Xmsj+nxLZzHdAjfp/lvGFj0cp275M/x317qZh50a+g/1wj/n2PoDt04k4/dtCxDbLZc2+fC4O/hy9JkHKbjcu7IkKdYQ52J3xnyCjAgp/EKMCimAa8DI/fhqhKSNKMoXpSqjNXAqCtzmuKFBMxrYDkBK6JL3Piy8pNloqRSTFoc+4BkMznJPyaBnGQfk+S6Xy1olgIdpd11v5SEvhtGopR+guKYu+Dr9hwGSaUjRGXls86q9yXvz4mfOz5WlfViEjCqkisdGFXJlQ6PVeU07Rb1Ch1oYERdcKp2i5CDyzUwS8CMomK5KMkqKlac5BQVK05aFffpcB6r6+jHBcvNrUsb6te3QzdduxZXxNoKV0jRCDTaR9GlwqXR+/eZwqVxEihcGiehxliEF3yugRFe8EZjLEfArAbmCZhTuLSIkrzCpXFSoXBpnFQq+oooqchUfQXx1AtQzeIUDRWzePwuc0V9iJOMoj7ESVZRH+Ikp7E04cLCa2DUGyw0li4IWKmBUcFFptmBMcRirQTNDgxJQ80ODEnLNTswJM1o9gZImtXsDZA0p9kbIGleszdA0gqNrQgnlKUGRsZumcJX1H1Cptl0NUDRNkwB5V9YHCWfA9AzKM1GD/3ENDs99BPTbPUYpGheEfrTtEIR+9O0UhH8k7QN6XMhoIEi/KdpqIj/aVquCO1pmlF8TkDTrCK2p2lO8UUBTfOK4J6mFYpvCmhaqYjuSdqGHFrgrA1BtEC9G5JogbM2RNEC9cqzaBQ4Sx5Go8AL8jQaBV6Qx9Eo8II8j0aBFzYE0gIvbEikBV6QR9Ig8II8kwaBF/JcEeTTNKP4xoCmqXokknb3wmEa2jCkD+OLdTNir0Htcz2E4+0gFz2B10XC6ybKyiPhY1c1bBD8s+ue7wfNXX80+4VVNH7o6iYwO13/PxCMUteeDNUpDe1r3Qa2T5DR14E1S8820+8Punt5Ob91Q0j7ifheYK0VL9LKKtHu6z6wDex1q+Vpd/s+eL/6EHmX/JgVcruP2aK+RO+dAY/F5fIb+V3+cQ=="                            
        end
    end
    build_blueprint_from_string(blueprint,surface,{x=x, y=y},force)
        
    local config = global.forces[force.name]
    config.roboport = surface.create_entity{name = "roboport-bno", position = {x, y}, force = force, raise_built = true}
    config.roboport.backer_name = player.name
    config.roboport.minable = false
    config.roboport.energy = 400000000    
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
    elseif (global.ocfg.starting_bot_count == "500/250") then
        numLogisticBots=250
    else 
        numLogisticBots=100 -- someone messing with code - default to 100
    end
    if characterMode then   numLogisticBots = numLogisticBots / 5 end     -- 1/5 the number of bots if you are in character moed
    -- setup robots in main roboport
    roboport_inventory.insert{name = "construction-robot", count = numLogisticBots*2}
    roboport_inventory.insert{name = "logistic-robot", count = numLogisticBots}
    roboport_inventory = config.roboport.get_inventory(defines.inventory.roboport_material)
    roboport_inventory.insert{name = "repair-pack", count = 10}

    -- setup main logistic chests
    surface.create_entity{name = "logistic-chest-storage", position = {x - 1, y + 4}, force = force, raise_built = true}
    surface.create_entity{name = "logistic-chest-storage", position = {x - 2, y + 4}, force = force, raise_built = true}
    local seablock_chest = surface.create_entity{name = "logistic-chest-storage", position = {x + 0, y + 4}, force = force, raise_built = true}
    -- storage chest, contains the items the force starts with
    local chest = surface.create_entity{name = "logistic-chest-storage", position = {x + 1, y + 4}, force = force, raise_built = true}
    -- storage chest
    local chest_inventory = chest.get_inventory(defines.inventory.chest)

    -- K R A S T O R I O 2
    -- add chests for Krastorio unless if they are playing in character mode - the character is their crafting/requestor/storage device
    if global.ocfg.krastorio2 then
        chest_inventory.insert{name = "logistic-chest-requester", count = 2}        -- blue chests
        chest_inventory.insert{name = "logistic-chest-passive-provider", count = 2} -- red chests 
    end
    local destination_for_inventory = chest_inventory

    if characterMode then
--        if global.ocfg.space_block then 
--            player.insert{name="power-armor", count = 1}
--        end
        destination_for_inventory = player
    end
    -- everyone always gets 4 red circuits
    destination_for_inventory.insert{name="advanced-circuit", count=4}
    if (settings.startup["bno-assembler-choice"].value >0) then -- large assemblers ?  Give them one !
        local numAssemblers= settings.startup["bno-assembler-at-start"].value
        destination_for_inventory.insert{name = "assembling-machine-4", count = numAssemblers}
    end

    -- S P A C E   B L O C K
    if global.ocfg.space_block then      
        if characterMode then
            destination_for_inventory.insert{name="iron-ore", count=10}
            destination_for_inventory.insert{name="copper-ore", count=10}
            destination_for_inventory.insert{name="stone", count=10}
            destination_for_inventory.insert{name="coal", count=10}
            -- Character gets half the logistic chests
            destination_for_inventory.insert{name = "logistic-chest-passive-provider", count = 2} -- red chests 
            destination_for_inventory.insert{name = "logistic-chest-buffer", count = 1}           -- add to green chests based on blueprint
            destination_for_inventory.insert{name = "logistic-chest-active-provider", count = 2}  -- purple chests
        else
            destination_for_inventory.insert{name = "inserter", count = 10}
            destination_for_inventory.insert{name = "fast-inserter", count = 2}
            destination_for_inventory.insert{name="iron-ore", count=50}
            destination_for_inventory.insert{name="copper-ore", count=50}
            destination_for_inventory.insert{name="stone", count=50}
            destination_for_inventory.insert{name="coal", count=50}
            destination_for_inventory.insert{name = "logistic-chest-requester", count = 1}        -- blue chests
            destination_for_inventory.insert{name = "logistic-chest-passive-provider", count = 4} -- red chests 
            destination_for_inventory.insert{name = "logistic-chest-buffer", count = 3}           -- add to green chests based on blueprint
            destination_for_inventory.insert{name = "logistic-chest-active-provider", count = 4}  -- purple chests
        end

        destination_for_inventory.insert{name = "transport-belt", count = 10}
        destination_for_inventory.insert{name = "small-lamp", count = 10}
        destination_for_inventory.insert{name = "filter-inserter", count = 1}
        destination_for_inventory.insert{name = "burner-inserter", count = 2}
        destination_for_inventory.insert{name = "copper-cable", count = 20}
        
        -- now normal items from space block
--	    destination_for_inventory.insert{name="assembling-machine-2",count=1}
--	    destination_for_inventory.insert{name="assembling-machine-1",count=4}
--	    destination_for_inventory.insert{name="solar-panel",count=20}
--	    destination_for_inventory.insert{name="accumulator",count=10}
--	    destination_for_inventory.insert{name="small-electric-pole",count=5}
--	    destination_for_inventory.insert{name="offshore-pump",count=1}
	    destination_for_inventory.insert{name="spaceblock-water",count=50}
  	    destination_for_inventory.insert{name="landfill",count=800}
    	destination_for_inventory.insert{name="crude-oil-barrel",count=5}
        destination_for_inventory.insert{name="small-lamp", count = 10}
        destination_for_inventory.insert{name ="lab", count=2}
        if not global.ocfg.easyStart then
            -- these 5 are extra items in the easyStart bp, so give to normal 
            if not characterMode then
                destination_for_inventory.insert{name = "logistic-chest-requester", count = 1}    -- blue chests
            end
            destination_for_inventory.insert{name = "inserter", count = 1}
            destination_for_inventory.insert{name = "fast-inserter", count = 5}   
            destination_for_inventory.insert{name = "filter-inserter", count = 3} 
            destination_for_inventory.insert{name="spaceblock-matter-furnace", count = 3}
        end
    else
        if global.ocfg.LootChestPlus then
            destination_for_inventory.insert{name="artifact-loot-chest", count = 1}
        end
        if not characterMode then   -- character does NOT get all of this stuff - make it within your character
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
            chest_inventory.insert{name = "lab", count = 2}
        end
        destination_for_inventory.insert{name = "gun-turret", count = 2}
        if (global.ocfg.lex_aircraft) then
            destination_for_inventory.insert{name = "spidertron-remote", count = 2}
        end
        if global.ocfg.krastorio2 then
            destination_for_inventory.insert{name = "rifle-magazine", count = 20}         -- rifle ammo
            if characterMode then
                destination_for_inventory.insert{name="submachine-gun", count = 1}
                destination_for_inventory.insert{name="kr-wind-turbine", count=10}
            end
            -- if not characterMode then   -- character doesn't get labs
            --     destination_for_inventory.insert{name = "kr-bio-lab", count = 2}              -- bio labs
            -- end
        else
            destination_for_inventory.insert{name = "firearm-magazine", count = 20}
        end
        -- S E A   B L O C K
        local seablock_items = {}
        if global.ocfg.seablock then
            -- research some techs that require manual labour
            --force.technologies["sb-startup1"].researched = true
            --force.technologies["sb-startup2"].researched = true
            --force.technologies["bio-paper-1"].researched = true
            --force.technologies["bio-wood-processing"].researched = true
            --force.technologies["sb-startup3"].researched = true
            --force.technologies["sb-startup4"].researched = true
            --force.technologies["sct-lab-t1"].researched = true
            --force.technologies["sct-automation-science-pack"].researched = true

            if global.ocfg.seablock and remote.interfaces["SeaBlock"] then
                log("Getting starting items from remote.call to seablock")
                seablock_items = remote.call("SeaBlock", "get_starting_items")
                -- remote.call("SeaBlock", "set_starting_items", nil)

                local unlocks = remote.call("SeaBlock", "get_unlocks")
                for _,techs in pairs(unlocks) do
                    for _,tech in pairs(techs) do
                        if force.technologies[tech] then
                            force.technologies[tech].researched = true
                        end
                    end
                end
            end

            local ignored_items = {
                ["copper-pipe"] = true
--                ["iron-gear-wheel"] = true,
--                ["iron-stick"] = true,
--                ["pipe"] = true,
--                ["pipe-to-ground"] = true,
            }
            log("moving " .. #seablock_items .. " items to player or chest")
            if seablock_items then
                for item_name, item_count in pairs(seablock_items) do
                    if not ignored_items[item_name] then
                        seablock_chest.insert{name = item_name, count = item_count}
                    end
                end
            end
            if not characterMode then
                chest_inventory.insert{name = "logistic-chest-requester", count = 2}     -- blue chests
                chest_inventory.insert{name = "logistic-chest-buffer", count = 1}        -- green chests
                chest_inventory.insert{name = "wood-pellets", count = 300}               -- extra fuel for BNO player - they can't make wood
                chest_inventory.insert{name = "assembling-machine-1", count = 2}
            end     
            destination_for_inventory.insert{name = "angels-electrolyser", count = 10}     -- this to make copper and iron
            destination_for_inventory.insert{name = "angels-flare-stack", count = 2}       -- helps make iron early
            destination_for_inventory.insert{name = "offshore-pump", count = 1}
            destination_for_inventory.insert{name = "wood-pellets", count = 100}
            destination_for_inventory.insert{name = "burner-ore-crusher", count = 3}
            destination_for_inventory.insert{name = "liquifier", count = 1}
            destination_for_inventory.insert{name = "crystallizer", count = 1}
            destination_for_inventory.insert{name = "algae-farm", count = 2}            
            destination_for_inventory.insert{name = "filter-inserter", count = 4}            
            destination_for_inventory.insert{name = "fast-inserter", count = 4}            
        else
            -- prevent error when looking for "rock-chest" later
            global.seablocked = true
            -- only give player this when we're not seablocking
            if not characterMode then   -- character does not get electric drills or extra chests
                chest_inventory.insert{name = "electric-mining-drill", count = 4}
                chest_inventory.insert{name = "logistic-chest-buffer", count = 1}   -- no green in this bp, so add 1
            end
        end
        if not characterMode then
            if (settings.startup["bno-main-area-design-boiler-n-steam-engines"].value == "solar only") then
                chest_inventory.insert{name = "logistic-chest-requester", count = 3}    -- blue chests
            else
                chest_inventory.insert{name = "logistic-chest-requester", count = 2}    -- blue chests
            end
            chest_inventory.insert{name = "logistic-chest-passive-provider", count = 4} -- red chests 
            chest_inventory.insert{name = "logistic-chest-buffer", count = 3}           -- add to green chests based on blueprint
            chest_inventory.insert{name = "logistic-chest-active-provider", count = 4}  -- purple chests
            local numRedChests = settings.startup["bno-num-red-boxes"].value
            local numBlueChests = settings.startup["bno-num-blue-boxes"].value
            if (numRedChests ~= 4) then 
                chest_inventory.insert{name = "logistic-chest-passive-provider", count = numRedChests-4} 
            end
            if (numBlueChests ~= 4) then 
                chest_inventory.insert{name = "logistic-chest-requester", count = numBlueChests-4} 
            end
        end
    end
end



function DisplayWelcomeGroundTextAtSpawn(player, pos)

    -- Render some welcoming text...
    local tcolor = {0.9, 0.7, 0.3, 0.8}
    local ttl = 2000
    local rid1 = rendering.draw_text{text="Welcome",
                        surface=game.surfaces[GAME_SURFACE_NAME],
                        target={x=pos.x, y=pos.y-25},
                        color=tcolor,
                        scale=20,
                        font="compi",
                        time_to_live=ttl,
                        -- players={player},
                        draw_on_ground=true,
                        orientation=0,
                        -- alignment=center,
                        scale_with_zoom=false,
                        only_in_alt_mode=false,
                        alignment= "center"}
    local rid2 = rendering.draw_text{text=player.name,
                        surface=game.surfaces[GAME_SURFACE_NAME],
                        target={x=pos.x, y=pos.y+5},
                        color=tcolor,
                        scale=20,
                        font="compi",
                        time_to_live=ttl+720,
                        -- players={player},
                        draw_on_ground=true,
                        orientation=0,
                        -- alignment=center,
                        scale_with_zoom=false,
                        only_in_alt_mode=false,
                        alignment= "center"}
    local rid3 = rendering.draw_text{text="Top left - Click !",
                        surface=game.surfaces[GAME_SURFACE_NAME],
                        target={x=pos.x, y=pos.y+20},
                        color={0, 1, 1, 0.8},
                        scale=9,
                        font="compi",
                        time_to_live=ttl+600,
                        -- players={player},
                        draw_on_ground=true,
                        orientation=0,
                        -- alignment=center,
                        scale_with_zoom=false,
                        only_in_alt_mode=false,
                        alignment= "center"}

    table.insert(global.oarc_renders_fadeout, rid1)
    table.insert(global.oarc_renders_fadeout, rid2)
    table.insert(global.oarc_renders_fadeout, rid3)
end

function DisplayWelcomeBackGroundTextAtSpawn(player, pos)
    -- Render some welcoming text...
    local tcolor = {0.9, 0.7, 0.3, 0.8}
    local rid1 = rendering.draw_text{text="Welcome Back!",
                        surface=game.surfaces[GAME_SURFACE_NAME],
                        target={x=pos.x-35, y=pos.y-25},
                        color=tcolor,
                        scale=20,
                        font="compi",
                        time_to_live=600,
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
                        time_to_live=600,
                        -- players={player},
                        draw_on_ground=true,
                        orientation=0,
                        -- alignment=center,
                        scale_with_zoom=false,
                        only_in_alt_mode=false}
   -- remove player name, not one from above, one drawn when player quit, above one is temporary. 
    table.insert(global.oarc_renders_fadeout, rid1)
    table.insert(global.oarc_renders_fadeout, rid2)

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
        local areaAroundPos = GetAreaAroundPos(spawn.pos, global.ocfg.spawn_config.gen_settings.land_area_tiles)
        local landArea = GetAreaAroundPos(spawn.pos, global.ocfg.spawn_config.gen_settings.land_area_tiles+CHUNK_SIZE)

        -- 1.414 is Sqrt(2) to increase land area to include corners  
        local offsetForSquare=1

        if global.ocfg.spawn_config.gen_settings.base_shape == "square" then    
            offsetForSquare=1.414
        end
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
            if CheckIfInArea(chunkAreaCenter,areaAroundPos) then -- previously used landArea vf

                -- Remove trees/resources inside the spawn area
                RemoveInCircle(surface, chunkArea, "tree", spawn.pos, global.ocfg.spawn_config.gen_settings.land_area_tiles)
                RemoveInCircle(surface, chunkArea, "resource", spawn.pos, global.ocfg.spawn_config.gen_settings.land_area_tiles*offsetForSquare+5)
                RemoveInCircle(surface, chunkArea, "cliff", spawn.pos, global.ocfg.spawn_config.gen_settings.land_area_tiles*offsetForSquare+5)
                
                local fill_tile = "landfill"
                if (game.active_mods["oarc-restricted-build"]) then
                    fill_tile = global.ocfg.locked_build_area_tile
                end

                if global.ocfg.spawn_config.gen_settings.base_shape ~= nil then
                    if (global.ocfg.spawn_config.gen_settings.base_shape == "circle") then
                        CreateCropCircle(surface, spawn.pos, chunkArea, global.ocfg.spawn_config.gen_settings.land_area_tiles, fill_tile)
                    else
                        CreateCropOctagon(surface, spawn.pos, chunkArea, global.ocfg.spawn_config.gen_settings.land_area_tiles, fill_tile, global.ocfg.spawn_config.gen_settings.base_shape)
                    end
                end
            end
            if CheckIfInArea(chunkAreaCenter,landArea) then -- previously used landArea vf
                if (spawn.moat) then
                    -- allowed_values = {"yes", "no", "use config.lua setting"}
                    moat_bridge_enabled = settings.startup["bno-moat-choice"].value == "Player choice w Bridge"

                    CreateMoat(surface,
                        spawn.pos,
                        chunkArea,
                        global.ocfg.spawn_config.gen_settings.land_area_tiles,
                        "water",
                        moat_bridge_enabled,
                        global.ocfg.spawn_config.gen_settings.base_shape)
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
--    log("Closest Spawn : " .. chunkArea.left_top.x .. "," .. chunkArea.left_top.y .. ", Closest Spawn : " .. closestSpawn.pos.x .. "," .. closestSpawn.pos.y)
    local distance = getDistance(chunkArea.left_top, closestSpawn.pos)
    -- Adjust multiplier to bring it in or out
    local modifier = (distance / (global.ocfg.spawn_config.safe_area.danger_radius*1))^3
    if modifier < 0.1 then modifier = 0.1 end
    if modifier > 1 then return end

    local ore_per_tile_cap = math.floor(100000 * modifier)
    if global.ocfg.dangOreus then
        ore_per_tile_cap = math.floor(500 * modifier)
    end
 
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
    log("RemoveOrResetPlayer:: " .. player.name .. " teleport to 0,0. Remove_player: " .. tostring(remove_player) .. ", remove_force: " .. tostring(remove_force) .. ", remove_base: " .. tostring(remove_base) .. ", immediate: " .. tostring(immediate))

    if (not remove_player) then
        SafeTeleport(player, game.surfaces[GAME_SURFACE_NAME], {x=0,y=0})    -- tell SafeTeleport NOT to remove the character or crash city
    end
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
            if (player_old_force.name ~= "neutral") then 
                game.merge_forces(player_old_force, "neutral")           
            end
        end
    end

    -- Remove the character completely
    if (remove_player) then
        game.remove_offline_players({player})
    end

    -- this happens if player loses or they choose to reset themselves - reset them and show menu
    if (remove_base and not remove_player) then
        DisplaySpawnOptions(player)
    end

    -- clear main inventory
--    log("player valid: " .. tostring(player.valid))
--    log("player index: " .. tostring(player.index))
--    log("player global.player[player.index]: " .. tostring(global.player[player.index]))
--    log("global.players[player.index].characterMode: " .. tostring(global.players[player.index].characterMode))

    
    if  player.valid then       -- this can occur when joining a game where you previous quit and timed out after 15 minutes
        if player.index and global.players[player.index] and global.players[player.index].characterMode then
            empty_players_inventory(player)
        end
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
            SendBroadcastMsg(playerName .. " has left so " .. newOwnerName .. " now owns their base.")
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
        global.players[game.players[playerName].index].inSpawn=false
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
    SetupCharacterOrBNOPlayer(player)
    if (DoesPlayerHaveCustomSpawn(player)) then
        SafeTeleport(player, game.surfaces[GAME_SURFACE_NAME], global.ocore.playerSpawns[player.name])
    else
        SafeTeleport(player, game.surfaces[GAME_SURFACE_NAME], game.forces[global.ocfg.main_force].get_spawn_position(GAME_SURFACE_NAME))
    end
end

function SendPlayerToRandomSpawn(player)
    local numSpawns = TableLength(global.ocore.uniqueSpawns)
    local rndSpawn = math.random(0,numSpawns)
    local counter = 0

    SetupCharacterOrBNOPlayer(player)
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
        if global.ocfg.space_block then
            for _,v in ipairs(SPACE_BLOCK_LOCKED_TECHNOLOGIES_COMMON) do
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