-- control.lua
-- Mar 2019
-- Dec 30, 2021 Mod by JustGoFly to merge OARC and Brave New World

-- Oarc's Separated Spawn Scenario
--
-- I wanted to create a scenario that allows you to spawn in separate locations
-- From there, I ended up adding a bunch of other minor/major features
--
-- Credit:
--  Tags - Taken from WOGs scenario
--  Rocket Silo - Taken from Frontier as an idea
--
-- Feel free to re-use anything you want. It would be nice to give me credit
-- if you can.



-- To keep the scenario more manageable (for myself) I have done the following:
--      1. Keep all event calls in control.lua (here)
--      2. Put all config options in config.lua and provided an example-config.lua file too.
--      3. Put other stuff into their own files where possible.
--      4. Put all other files into lib folder
--      5. Provided an examples folder for example/recommended map gen settings

-- Generic Utility Includes
require("lib/oarc_utils")

-- Other soft-mod type features.
require("lib/frontier_silo")
require("lib/tag")
require("lib/game_opts")
require("lib/player_list")
require("lib/rocket_launch")
require("lib/admin_commands")
require("lib/regrowth_map")
require("lib/shared_chests")
require("lib/notepad")
require("lib/map_features")
require("lib/oarc_buy")
require("lib/auto_decon_miners")

-- For Philip. I currently do not use this and need to add proper support for
-- commands like this in the future.
-- require("lib/rgcommand")
-- require("lib/helper_commands")

-- Main Configuration File
require("config")

-- Save all config settings to global table.
require("lib/oarc_global_cfg.lua")

-- Scenario Specific Includes
require("lib/separate_spawns")
require("lib/separate_spawns_guis")
require("lib/oarc_enemies")
require("lib/oarc_gui_tabs")

-- compatibility with mods
require("compat/factoriomaps")

-- Create a new surface so we can modify map settings at the start.
GAME_SURFACE_NAME="oarc"
default_qb_slots = {
        [1]  = "transport-belt",
        [2]  = "underground-belt",
        [3]  = "splitter",
        [4]  = "inserter",
        [5]  = "long-handed-inserter",
        [6]  = "medium-electric-pole",
        [7]  = "small-electric-pole",
        [8]  = "assembling-machine-1",
        [9]  = "stone-furnace",
        [10] = "electric-mining-drill",
        [11] = "roboport",
        [12] = "logistic-chest-storage",
        [13] = "logistic-chest-requester",
        [14] = "logistic-chest-passive-provider",
        [15] = "logistic-chest-buffer",
		[16] = "logistic-chest-active-provider",
        [17] = "gun-turret",
        [18] = "stone-wall",
        [19]  = "small-lamp",
        [20] = "radar",
        [21] = "pipe-to-ground",
        [22] = "pipe",
        [23] = "offshore-pump",
        [24] = "boiler",
        [25] = "steam-engine",
        [26] = "burner-inserter",
        [27] = "lab"
}
commands.add_command("trigger-map-cleanup",
    "Force immediate removal of all expired chunks (unused chunk removal mod)",
    RegrowthForceRemoveChunksCmd)


--------------------------------------------------------------------------------
-- ALL EVENT HANLDERS ARE HERE IN ONE PLACE!
--------------------------------------------------------------------------------

----------------------------------------
-- On Init - only runs once the first
--   time the game starts
----------------------------------------
script.on_init(function(event)

    -- FIRST
    InitOarcConfig()

    -- Regrowth (always init so we can enable during play.)
    RegrowthInit()

    -- Create new game surface
    CreateGameSurface()

    -- MUST be before other stuff, but after surface creation.
    InitSpawnGlobalsAndForces()

    -- Frontier Silo Area Generation
    if (global.ocfg.frontier_rocket_silo and not global.ocfg.enable_magic_factories) then
        SpawnSilosAndGenerateSiloAreas()
    end

    -- Everyone do the shuffle. Helps avoid always starting at the same location.
    -- Needs to be done after the silo spawning.
    if (global.ocfg.enable_vanilla_spawns) then
        global.vanillaSpawns = FYShuffle(global.vanillaSpawns)
        log("Vanilla spawns:")
        log(serpent.block(global.vanillaSpawns))
    end
    
    Compat.handle_factoriomaps()

    if (global.ocfg.enable_coin_shop and global.ocfg.enable_chest_sharing) then
        SharedChestInitItems()
    elseif (global.ocfg.enable_chest_sharing) then
    -- vf enable item and power sharing without coins
        log("sharing chests and power !")
        SharedChestInitItems()
    end

    if (global.ocfg.enable_coin_shop and global.ocfg.enable_magic_factories) then
        MagicFactoriesInit()
    end

    OarcMapFeatureInitGlobalCounters()
    OarcAutoDeconOnInit()

    -- Display starting point text as a display of dominance.
    RenderPermanentGroundText(game.surfaces[GAME_SURFACE_NAME], {x=-34,y=-25}, 12, "Brave New OARC", {0.9, 0.7, 0.3, 0.8})
    BNOSwarmGroupInit()
end)


----------------------------------------
script.on_load(function()
	Compat.handle_factoriomaps()
end)


----------------------------------------
-- Rocket launch event
-- Used for end game win conditions / unlocking late game stuff
----------------------------------------
script.on_event(defines.events.on_rocket_launched, function(event)
    RocketLaunchEvent(event)
end)


----------------------------------------
-- Chunk Generation
----------------------------------------
script.on_event(defines.events.on_chunk_generated, function(event)

    if (event.surface.name ~= GAME_SURFACE_NAME) then 
        return 
    end

    if global.ocfg.enable_regrowth then
        RegrowthChunkGenerate(event)
    end

    if global.ocfg.enable_undecorator then
        UndecorateOnChunkGenerate(event)
    end

    SeparateSpawnsGenerateChunk(event)

    CreateHoldingPen(event.surface, event.area)
end)


----------------------------------------
-- Gui Click
----------------------------------------
script.on_event(defines.events.on_gui_click, function(event)

    -- Don't interfere with other mod related stuff.
    if (event.element.get_mod() ~= nil) then return end

    if global.ocfg.enable_tags then
        TagGuiClick(event)
    end

    WelcomeTextGuiClick(event)
    SpawnOptsGuiClick(event)
    SpawnCtrlGuiClick(event)
    SharedSpwnOptsGuiClick(event)
    BuddySpawnOptsGuiClick(event)
    BuddySpawnWaitMenuClick(event)
    BuddySpawnRequestMenuClick(event)
    SharedSpawnJoinWaitMenuClick(event)

    ClickOarcGuiButton(event)

    if global.ocfg.enable_coin_shop then
        ClickOarcStoreButton(event)
    end

    GameOptionsGuiClick(event)

end)

script.on_event(defines.events.on_gui_checked_state_changed, function (event)
    SpawnOptsRadioSelect(event)
    SpawnCtrlGuiOptionsSelect(event)
end)

script.on_event(defines.events.on_gui_selected_tab_changed, function (event)
    TabChangeOarcGui(event)

    if global.ocfg.enable_coin_shop then
        TabChangeOarcStore(event)
    end
end)


----------------------------------------
-- Player Events
----------------------------------------
script.on_event(defines.events.on_player_joined_game, function(event)
log("on_event::On Player Joined Game " .. game.players[event.player_index].name)
    PlayerJoinedMessages(event)
    ServerWriteFile("player_events", game.players[event.player_index].name .. " joined the game." .. "\n")
end)

----------------------------------------
script.on_event(defines.events.on_player_created, function(event)
local player = game.players[event.player_index]

log("on_event::On Player created: " .. player.name)

-- Additions from BraveNewWork OnEvent_on_player_created(event) vf
    if not global.players then
        global.players = {}

    end
    global.players[event.player_index] = {
        crafted = {},
        inventory_items = {},
        previous_position = player.position,
    }
    -- Move the player to the game surface immediately.
    --    player.teleport({x=0,y=0},  game.surfaces[GAME_SURFACE_NAME]) -- could cause crash - SafeTeleport bypasses safeguards
    SafeTeleport(player, game.surfaces[GAME_SURFACE_NAME], {x=0,y=0})
    player.set_controller{type=defines.controllers.character,character=player.surface.create_entity{name='character',force=player.force,position=player.position}}

log("Player teleported to 0:0");
    if global.ocfg.enable_long_reach then
        GivePlayerLongReach(player)
    end

    SeparateSpawnsPlayerCreated(event.player_index, true)

    InitOarcGuiTabs(player)

    if global.ocfg.enable_coin_shop then
        InitOarcStoreGuiTabs(player)
    end

    -- disable light
    player.disable_flashlight()
    -- enable cheat mode
    player.cheat_mode = true

    -- Set-up a sane default for the quickbar
    for i = 1, 100 do
        if not player.get_quick_bar_slot(i) then
            if default_qb_slots[i] then
                player.set_quick_bar_slot(i, default_qb_slots[i])
            end
        end
    end

    global.bnw_scenario_version = game.active_mods["brave-new-oarc"]
    -- setup force   vf TODO do this in on_gui_click using new location that comes back from SpawnOptsGuiClick
    -- setupForce(player.force, player.surface, 0, 0, game.active_mods["SeaBlock"])
    preventMining(player)

end)


script.on_event(defines.events.on_player_respawned, function(event)
-- log("on_event::on_player_respawned: " .. game.players[event.player_index].name)
    SeparateSpawnsPlayerRespawned(event)

    PlayerRespawnItems(event)

    if global.ocfg.enable_long_reach then
        GivePlayerLongReach(game.players[event.player_index])
    end
end)

script.on_event(defines.events.on_player_left_game, function(event)
log("on_event::on_player_left_game - " .. game.players[event.player_index].name)
    ServerWriteFile("player_events", game.players[event.player_index].name .. " left the game." .. "\n")
    local player = game.players[event.player_index]

    -- If players leave early, say goodbye.
    if (player and (player.online_time < (global.ocfg.minimum_online_time * TICKS_PER_MINUTE))) then
        log("Player left early - removing: " .. player.name)
        SendBroadcastMsg(player.name .. "'s base was marked for immediate clean up because they left within "..global.ocfg.minimum_online_time.." minutes of joining.")
        RemoveOrResetPlayer(player, true, true, true, true)
    end
end)

-- script.on_event(defines.events.on_player_removed, function(event)
    -- Player is already deleted when this is called.
-- end)

----------------------------------------
-- On tick events. Stuff that needs to happen at regular intervals.
-- Delayed events, delayed spawns, ...
----------------------------------------
script.on_event(defines.events.on_tick, function(event)
   if global.ocfg.enable_regrowth then
        RegrowthOnTick()
        RegrowthForceRemovalOnTick()
    end

    DelayedSpawnOnTick()

    if global.ocfg.enable_chest_sharing then
        SharedChestsOnTick()
    end

    if (global.ocfg.enable_chest_sharing and global.ocfg.enable_magic_factories) then
        MagicFactoriesOnTick()
    end

    TimeoutSpeechBubblesOnTick()
    FadeoutRenderOnTick()

    if global.ocfg.enable_miner_decon then
        OarcAutoDeconOnTick()
    end

    if global.ocfg.warn_biter_attack then
        global.swarmCheckTick = global.swarmCheckTick or game.tick
        if (game.tick >= global.swarmCheckTick) then
            BNOCleanGPSStack()
            global.swarmCheckTick = game.tick + TICKS_PER_SECOND    -- check again in 1 second
        end
    end
end)



script.on_event(defines.events.on_sector_scanned, function (event)   
    if global.disableRegrowthWhileWaitingToRemoveAllChunks then
        -- this regrowth can cause a player's space that just quit, and marked for deletion, to not be deleted
        log("Ah hah !  Regrowth event while waiting to remove chunks - ignore!")
    else
	    if global.ocfg.enable_regrowth  then
            -- log("on_event::on_sector_scanned - enable_regrowth")    
            RegrowthSectorScan(event)
        end
    end
end)


----------------------------------------
-- Various on "built" events
----------------------------------------
script.on_event(defines.events.on_built_entity, function(event)
 	if global.ocfg.enable_autofill then
        Autofill(event)
    end

    if global.ocfg.enable_regrowth then
        if (event.created_entity.surface.name ~= GAME_SURFACE_NAME) then return end
        RegrowthMarkAreaSafeGivenTilePos(event.created_entity.position, 2, false)
    end

    if global.ocfg.enable_anti_grief then
        SetItemBlueprintTimeToLive(event)
    end

    if global.ocfg.frontier_rocket_silo then
        BuildSiloAttempt(event)
    end

end)

script.on_event(defines.events.on_robot_built_entity, function (event)
    if global.ocfg.enable_regrowth then
        if (event.created_entity.surface.name ~= GAME_SURFACE_NAME) then return end
        RegrowthMarkAreaSafeGivenTilePos(event.created_entity.position, 2, false)
    end
    if global.ocfg.frontier_rocket_silo then
        BuildSiloAttempt(event)
    end
end)

script.on_event(defines.events.on_player_built_tile, function (event)
    if global.ocfg.enable_regrowth then
        if (game.surfaces[event.surface_index].name ~= GAME_SURFACE_NAME) then return end

        for k,v in pairs(event.tiles) do
            RegrowthMarkAreaSafeGivenTilePos(v.position, 2, false)
        end
    end
end)

----------------------------------------
-- On script_raised_built. This should help catch mods that
-- place items that don't count as player_built and robot_built.
-- Specifically FARL.
----------------------------------------
script.on_event(defines.events.script_raised_built, function(event)
    if global.ocfg.enable_regrowth then
        if (event.entity.surface.name ~= GAME_SURFACE_NAME) then return end
        RegrowthMarkAreaSafeGivenTilePos(event.entity.position, 2, false)
    end
end)

----------------------------------------
-- Shared chat, so you don't have to type /s
-- But you do lose your player colors across forces.
----------------------------------------
script.on_event(defines.events.on_console_chat, function(event)
    if (event.player_index) then
        ServerWriteFile("server_chat", game.players[event.player_index].name .. ": " .. event.message .. "\n")
    end
    if (global.ocfg.enable_shared_chat) then
        if (event.player_index ~= nil) then
            ShareChatBetweenForces(game.players[event.player_index], event.message)
        end
    end
end)

----------------------------------------
-- On Research Finished
-- This is where you can permanently remove researched techs
----------------------------------------
script.on_event(defines.events.on_research_finished, function(event)

    -- Never allows players to build rocket-silos in "frontier" mode.
    if global.ocfg.frontier_rocket_silo and not global.ocfg.frontier_allow_build then
        RemoveRecipe(event.research.force, "rocket-silo")
    end

    if global.ocfg.lock_goodies_rocket_launch and
        (not global.ocore.satellite_sent or not global.ocore.satellite_sent[event.research.force.name]) then
        for _,v in ipairs(LOCKED_RECIPES) do
            RemoveRecipe(event.research.force, v.r)
        end
    end
end)

----------------------------------------
-- On Entity Spawned and On Biter Base Built
-- This is where I modify biter spawning based on location and other factors.
----------------------------------------
script.on_event(defines.events.on_entity_spawned, function(event)
    if (global.ocfg.modified_enemy_spawning) then
        ModifyEnemySpawnsNearPlayerStartingAreas(event)
    end
end)
script.on_event(defines.events.on_biter_base_built, function(event)
    if (global.ocfg.modified_enemy_spawning) then
        ModifyEnemySpawnsNearPlayerStartingAreas(event)
    end
end)

----------------------------------------
-- On unit group finished gathering
-- This is where I remove biter waves on offline players
----------------------------------------
script.on_event(defines.events.on_unit_group_finished_gathering, function(event)
    if (global.ocfg.enable_offline_protect) then
        OarcModifyEnemyGroup(event.group)
    end
end)

----------------------------------------
-- On player clicked on gps tag
-- Save player's stuff so they don't lose it if they can't get to the corpse fast enough.
----------------------------------------

script.on_event(defines.events.on_player_clicked_gps_tag, function(event)
    local biter, swarmGroup
    if (#global.swarmGroup > 0) then
        for k,swarm in pairs(global.swarmGroup ) do
            if ((swarm.startPosition.x == event.position.x) and  (swarm.startPosition.y == event.position.y)) then
                swarmGroup = swarm.group
                break
            end
        end
    end
    if (swarmGroup ~= nil and swarmGroup.valid) then
        for _,member in pairs(swarmGroup.members) do
            if (member.active) then
                biter=member
                break
            end
        end
        if (biter ~=nil) then
            if (biter.valid) then   -- follow the biter swarm with text and camera
                game.players[event.player_index].zoom_to_world(event.position,  0.5, biter) -- follow a live biter
                local rid1=rendering.draw_text{text=string.format("Swarm coming to kill you, %s.", game.players[event.player_index].name),
                        surface=game.surfaces[GAME_SURFACE_NAME],
                        target=biter,
                        color={1,0.1,0.1,1},
                        scale=3,
                        font="compi",
                        time_to_live=TICKS_PER_SECOND*9,
                        draw_on_ground=false}
                local rid2=rendering.draw_text{text="Press ESC to exit this view.",
                        surface=game.surfaces[GAME_SURFACE_NAME],
                        target=biter,
                        target_offset={0,2},
                        color={1,0.1,0.1,1},
                        scale=2,
                        font="compi",
                        time_to_live=TICKS_PER_SECOND*12,
                        draw_on_ground=false}
                        table.insert(global.oarc_renders_fadeout, rid1)            
                        table.insert(global.oarc_renders_fadeout, rid2)            
            else    -- show where they were when they formed
                game.players[event.player_index].zoom_to_world(event.position)                
--                local rid1=rendering.draw_text{text=string.format("Swarm dead, they formed here, %s.", game.players[event.player_index].name),                        surface=game.surfaces[GAME_SURFACE_NAME],                        target={event.position.x, event.position.y},                        color={1,0.1,0.1,0.7},                        scale=3,                        font="compi",                        time_to_live=TICKS_PER_SECOND*9,                        draw_on_ground=false}
--                local rid2=rendering.draw_text{text="Press ESC to exit this view.",                        surface=game.surfaces[GAME_SURFACE_NAME],                        target=biter,{event.position.x, event.position.y+2},                        color={1,0.1,0.1,0.7},                        scale=2,                        font="compi",                        time_to_live=TICKS_PER_SECOND*12,                        draw_on_ground=false}
--                table.insert(global.oarc_renders_fadeout, rid1)            
--                table.insert(global.oarc_renders_fadeout, rid2)            
            end
        end
    else    -- show where they were when they formed
        game.players[event.player_index].zoom_to_world(event.position)
--        local rid1=rendering.draw_text{text=string.format("Swarm dead, they formed here, %s.", game.players[event.player_index].name),                    surface=game.surfaces[GAME_SURFACE_NAME],                    target=event.position,                    color={1,0.1,0.1,0.7},                    scale=3,                    font="compi",                    time_to_live=TICKS_PER_SECOND*9,                    draw_on_ground=false}
--        local rid2=rendering.draw_text{text=string.format("Press ESC to exit this view.", game.players[event.player_index].name),                    surface=game.surfaces[GAME_SURFACE_NAME],                    target={event.position.x, event.position.y+2},                    color={1,0.1,0.1,0.7},                    scale=2,                    font="compi",                    time_to_live=TICKS_PER_SECOND*12,                    draw_on_ground=false}
--         table.insert(global.oarc_renders_fadeout, rid1)            
--         table.insert(global.oarc_renders_fadeout, rid2)            
    end
end)

----------------------------------------
-- On Corpse Timed Out
-- Save player's stuff so they don't lose it if they can't get to the corpse fast enough.
----------------------------------------
script.on_event(defines.events.on_character_corpse_expired, function(event)
--    game.print("Character corpse expired")
    DropGravestoneChestFromCorpse(event.corpse)
end)


----------------------------------------
-- On Gui Text Change
-- For capturing text entry.
----------------------------------------
script.on_event(defines.events.on_gui_text_changed, function(event)
    NotepadOnGuiTextChange(event)
end)


----------------------------------------
-- On Gui Closed
-- For capturing player escaping custom GUI so we can close it using ESC key.
----------------------------------------
script.on_event(defines.events.on_gui_closed, function(event)
    OarcGuiOnGuiClosedEvent(event)
    if global.ocfg.enable_coin_shop then
        OarcStoreOnGuiClosedEvent(event)
    end
end)

----------------------------------------
-- On enemies killed
-- For coin generation and stuff
----------------------------------------
script.on_event(defines.events.on_post_entity_died, function(event)
    if (game.surfaces[event.surface_index].name ~= GAME_SURFACE_NAME) then return end
    if global.ocfg.enable_coin_shop then
        CoinsFromEnemiesOnPostEntityDied(event)
    end
end,
{{filter="type", type = "unit"}, {filter="type", type = "unit-spawner"}, {filter="type", type = "turret"}})


----------------------------------------
-- Scripted auto decon for miners...
----------------------------------------
script.on_event(defines.events.on_resource_depleted, function(event)
    if global.ocfg.enable_miner_decon then
        OarcAutoDeconOnResourceDepleted(event)
    end
end)

-- Addition of functions to track bots dying vf
-- Called when a worker (construction or logistic) robot expires through a lack of energy.
-- https://lua-api.factorio.com/latest/events.html#on_worker_robot_expired
function robotdied(event)
    log("Event: Logistics Robot died: " .. event.name .. ", Robot Name:".. event.robot.name)
end

script.on_event(defines.events.on_worker_robot_expired, robotdied)


-----------------------------------------------------------------------------------------------------------
-- Start of Brave New World functions
-----------------------------------------------------------------------------------------------------------

function inventoryChanged(event)
    if global.creative then
        return
    end
    local player = game.players[event.player_index]
    if not global.seablocked then
        -- tiny hack to work around that SeaBlock sets up stuff after BNW on load
        global.seablocked = true
        -- move everything from the Home rock to the other chest
        local home_rock = player.surface.find_entity("rock-chest", {0.5, 0.5})
        if home_rock then
            for name, count in pairs(home_rock.get_inventory(defines.inventory.chest).get_contents()) do
                global.seablock_chest.insert{name = name, count = count}
            end
        end
        home_rock.destroy()
        global.seablock_chest = nil

        -- and clear the starting items from player inventory
        player.clear_items_inside()
    end
    -- remove any crafted items (and possibly make ghost cursor of item)
    for _, item in pairs(global.players[event.player_index].crafted) do
        if itemCountAllowed(item.name, item.count, player) == 0 then
            if player.clean_cursor() then
                player.cursor_stack.clear()
            end
        end
        player.cursor_ghost = game.item_prototypes[item.name]
        player.remove_item(item)
    end
    global.players[event.player_index].crafted = {}

    -- player is only allowed to carry whitelisted items
    -- everything else goes into entity opened or entity beneath mouse cursor
	-- log("Clearing inventory")
    local inventory_main = player.get_inventory(defines.inventory.god_main)
    local items = {}
	if (inventory_main ~= nil) then	-- vf
		for i = 1, #inventory_main do
			local item_stack = inventory_main[i]
			if item_stack and item_stack.valid_for_read and not item_stack.is_blueprint then
				local name = item_stack.name
				if items[name] then
					items[name].count = items[name].count + item_stack.count
				else
					items[name] = {
						count = item_stack.count,
						slot = item_stack
					}
				end
			end
		end
	end
    global.players[event.player_index].inventory_items = items

    local entity = player.selected or player.opened
    for name, item in pairs(items) do
        local allowed = itemCountAllowed(name, item.count, player)
        local to_remove = item.count - allowed
        if to_remove > 0 then
            dropItems(entity, player, name, to_remove)
            player.remove_item{name = name, count = to_remove}
        end
    end
end

function dropItems(entity, player, name, count)
--    local entity = player.opened or player.selected
    local inserted = 0
    if (global.enable_oe_debug) then
        log("dropItems- player: ".. player.name .. ", name: " .. name .. " count: " .. count)
    end
    if entity and entity.insert then
        -- in case picking up items from a limited chest, unset limit, insert, then set limit again
        for _, inventory_id in pairs(defines.inventory) do
            local inventory = entity.get_inventory(inventory_id)
            if inventory then
                local barpos = inventory.supports_bar() and inventory.get_bar() or nil
                if inventory.supports_bar() then
                    inventory.set_bar() -- clear bar (the chest size limiter)
                end
                inserted = inserted + inventory.insert{name = name, count = count}
                count = count - inserted
                if inventory.supports_bar() then
                    inventory.set_bar(barpos) -- reset bar
                end
                if count <= 0 then
                    break
                end
            end
        end
        if count > 0 then
            -- try a generic insert (although code above should make this redundant)
            count = count - entity.insert({name = name, count = count})
        end
    end
    if count > 0 then
        -- now we're forced to spill items
        entity = entity or global.forces[player.force.name].roboport
        if entity then
            if entity.valid then  
                -- This was causing crashes in dropItems if a ghost entity forced a drop, a thank running over stone, or dropping a ghost on stone could do this                  
                if (entity.name ~= "entity-ghost") then
                    if (global.enable_oe_debug) then
                        log("dropItems: Spilling items for: ".. entity.name .. ", type: " .. entity.type .. ", at " .. GetGPStext(entity.position) .. ", entity force: ".. entity.force.name)
                    end
                    if (entity.surface == nil) then
                        game.prints[player.name]("Send this log to JustGoFly - it shows something that WOULD have crashed, and provides good info to debug what caused it")
                        log("dropItems: would have crashed accessing entity.surface - on entity name: " .. entity.name .. " for item: " .. name .. " count: " .. count .. " for player: " .. player.name)
                    else
                        entity.surface.spill_item_stack(entity.position, {name = name, count = count}, false, entity.force, false)
                    end
                end
            end
        end
    end
end

function itemCountAllowed(name, count, player)
    local item = game.item_prototypes[name]
    local place_type = item.place_result and item.place_result.type
    if name == "red-wire" or name == "green-wire" then
        -- need these for circuitry, one stack is enough
        return math.min(200, count)
    elseif name == "copper-cable" then
        -- need this for manually connecting poles, but don't want player to manually move stuff around so we'll limit it
        return math.min(20, count)
    elseif item.type == "blueprint" or item.type == "deconstruction-item" or item.type == "blueprint-book" or item.type == "selection-tool" or name == "artillery-targeting-remote" or name == "spidertron-remote" or item.type == "upgrade-item" or item.type == "copy-paste-tool" or item.type == "cut-paste-tool" or name == "tl-adjust-capsule" or name == "tl-draw-capsule" or name == "tl-edit-capsule" then
        -- these only place ghosts or are utility items
        return count
    elseif place_type == "car" or place_type == "spider-vehicle" then
        -- let users put down cars & tanks
        return count
    elseif item.place_as_equipment_result then
        -- let user carry equipment
        return count
    elseif string.match(name, ".*module.*") then
        -- allow modules
        return count
    elseif name == "BlueprintAlignment-blueprint-holder" then
        -- temporary holding location for original blueprint, should only ever be one of these.
        return count
    end
    return 0
end


function preventMining(player)
    -- prevent mining (this appeared to be reset when loading a 0.16.26 save in 0.16.27)
    player.force.manual_mining_speed_modifier = -0.99999999 -- allows removing ghosts with right-click
end

script.on_configuration_changed(function(chgdata)
log("on_configuration_changed")
    local new = game.active_mods["brave-new-oarc"]
    if new ~= nil then
        local old = global.bnw_scenario_version
        if old ~= new then
            game.reload_script()
            global.bnw_scenario_version = new
        end
    end
end)

script.on_event(defines.events.on_player_pipette, function(event)
    if global.creative then
        return
    end
    game.players[event.player_index].cursor_stack.clear()
    game.players[event.player_index].cursor_ghost = event.item
end)

script.on_event(defines.events.on_player_crafted_item, function(event)
    if global.creative then
        return
    end
    game.players[event.player_index].cursor_ghost = event.item_stack.prototype
    event.item_stack.count = 0
end)

script.on_event(defines.events.on_player_main_inventory_changed, inventoryChanged)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    if global.creative then
        return
    end
    local player = game.players[event.player_index]
    local cursor = player.cursor_stack
    if cursor and cursor.valid_for_read then
        local allowed = itemCountAllowed(cursor.name, cursor.count, player)
        local to_remove = cursor.count - allowed
        if to_remove > 0 then
            local entity = player.opened or player.selected
            dropItems(entity, player, cursor.name, to_remove)
            if allowed > 0 then
                cursor.count = allowed
            else
                player.cursor_ghost = cursor.prototype
                player.cursor_stack.clear()
            end
        end
    end
    -- check if user is in trouble due to insufficient storage
    local alerts = player.get_alerts{type = defines.alert_type.no_storage}
    local out_of_storage = false
    for _, surface in pairs(alerts) do
        for _, alert_type in pairs(surface) do
            for _, alert in pairs(alert_type) do
                local entity = alert.target
                if (entity.name == "construction-robot") then
                    out_of_storage = true
                    local inventory = entity.get_inventory(defines.inventory.robot_cargo)
                    if inventory then
                        for name, count in pairs(inventory.get_contents()) do
                            entity.surface.spill_item_stack(entity.position, {name = name, count = count})
                        end
                    end
                    entity.clear_items_inside()
                end
            end
        end
    end
    if out_of_storage then
        player.print({"out-of-storage"})
    end
end)

script.on_event(defines.events.on_entity_died, function(event)
    if global.creative then
        return
    end
    local entity = event.entity
    -- check if roboport was destroyed
    if entity.name=="roboport-main" then
        log("Force DIED: " .. entity.force.name)
        SendBroadcastMsg("Our buddy on force: '" .. entity.force.name ..  "'' Gone like a fart in the wind")        
        for name,player in pairs(game.connected_players) do
            log ("player: " .. player.name .. " at " ..GetGPStext(global.spawn[player.index]) .. " Died due to the starting roboport being destroyed.")
            log ("and entity at " .. GetGPStext(entity.position))
            if (GetGPStext(global.spawn[player.index]) == GetGPStext(entity.position)) then
                SendMsg(player.name, "Sorry '" .. player.name .. "' you LOSE! Rejoin if you like")
    		    log("Kicking Player: " .. player.name .. " force: " .. player.force.name .. " position: " .. GetGPStext(global.spawn[player.index]))
                RemoveOrResetPlayer(player, false, true, true, true)
            end

--            if (player.force.name == entity.force.name) then
--                
--                SendMsg(player.name, "Sorry " .. player.name .. " you lose - rejoin if you like")
--    		    log("Kicking Player: " .. player.name .. " force: " .. player.force.name)
--                RemoveOrResetPlayer(player, false, true, true, true)
--            end
        end
        SendBroadcastMsg("Our buddy on force: '" .. entity.force.name .. "' Died due to the starting roboport being destroyed.")        
--        game.set_game_state{game_finished = false, player_won = false, can_continue = true, }
    end
end)

script.on_event(defines.events.on_player_changed_position, function(event)
    if global.creative then
        return
    end
	-- We might be waiting for base to render vf
    if not global.forces then
		return
	end
    -- enable moving around at 0,0
    if (event.player_index > #global.players) then
        return
    end
    local player = game.players[event.player_index]
    -- TODO: really shouldn't have to do this so often (can we do it in migrate function?)
    preventMining(player)

    local config = global.forces[player.force.name]
    local x_chunk = math.floor(player.position.x / CHUNK_SIZE)      -- 32
    local y_chunk = math.floor(player.position.y / CHUNK_SIZE)      -- 32
    -- prevent player from exploring, unless in a vehicle
    if global.spawning then
        log("Player spawning - override the safeguard - allow spawning here")
        global.spawning = false
    else
        if not player.vehicle then
            local charted = function(x, y)
               return player.force.is_chunk_charted(player.surface, {x, y}) and
                  (player.force.is_chunk_charted(player.surface, {x - 2, y - 2}) or not player.surface.is_chunk_generated({x - 2, y - 2})) and
                  (player.force.is_chunk_charted(player.surface, {x - 2, y + 2}) or not player.surface.is_chunk_generated({x - 2, y + 2})) and
                  (player.force.is_chunk_charted(player.surface, {x + 2, y - 2}) or not player.surface.is_chunk_generated({x + 2, y - 2})) and
                  (player.force.is_chunk_charted(player.surface, {x + 2, y + 2}) or not player.surface.is_chunk_generated({x + 2, y + 2}))
            end
            if not charted(math.floor(player.position.x / CHUNK_SIZE), math.floor(player.position.y / CHUNK_SIZE)) then -- 32  32
                -- can't move here, chunk not charted
                local prev_pos = global.players[event.player_index].previous_position
                if charted(math.floor(player.position.x / CHUNK_SIZE), math.floor(prev_pos.y / CHUNK_SIZE)) then    -- 32 32
                    -- we can move here, though
                    prev_pos.x = player.position.x
                elseif charted(math.floor(prev_pos.x / CHUNK_SIZE), math.floor(player.position.y / CHUNK_SIZE)) then    -- 32 32
                    -- or here
                    prev_pos.y = player.position.y
                end
                -- teleport player to (possibly modified) prev_pos
                player.teleport(prev_pos)
            end
        end
    end
    -- save new player position
    global.players[event.player_index].previous_position = player.position
end)

--script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
--    log("events.on_runtime_mod_setting_changed: setting " .. event.setting .. " for: " .. game.players[event.player_index].name .. "type: " .. event.setting_type)
    -- log("Physical setting changed to: " .. settings.get_player_settings(event.player_index)["bno-bots-resistance-physical"])
--end)

function change_bots()
local myConBot
local myLogiBot
	-- body
    myConBot = util.table.deepcopy(data.raw["construction-robot"]["construction-robot"])
    myConBot.speed = 0.5
    myConBot.minable = {mining_time = 10, result = "construction-robot"}
    myConBot.max_energy = "4MJ"
    myConBot.energy_per_tick = "0.0005kJ"
    myConBot.energy_per_move = "0.2kJ"
    myConBot.destructible = false
    data:extend({myConBot})

    myLogiBot = util.table.deepcopy(data.raw["logistic-robot"]["logistic-robot"])
    myLogiBot.minable = {mining_time = 10, result = "logistic-robot"}
    myLogiBot.max_energy = "4MJ"
    myLogiBot.energy_per_tick = "0.0005kJ"
    myLogiBot.energy_per_move = "0.2kJ"
    myLogiBot.speed = 0.5
    myLogiBot.destructible = false
    data:extend({myLogiBot})
end