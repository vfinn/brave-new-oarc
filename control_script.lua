-- control.lua

-- Dec 30, 2021 Mod by JustGoFly to merge OARC and Brave New World
-- First issues that had to be dealt with were bugs in 1) Each of the mods, 2) in my merge of the mods
-- BNW had some checks as if it were a single player game and crashes, all documented in the changelog.
-- The biggest issue was exploding bots, this took many months of digging.
-- I added the larger roboport, which had to look different since it will show up in the list of items, 
-- even if it's not placeable. It also doubles the logistics space and increases charging of bots from 
-- 4 to 16 bots.  Eventually I'll make this researchable.
-- After watching players get overrun with no warning, I added notification of swarms coming and tracking 
-- of them by clicking on the notification.Also moved alot of the config settings into the mods settable
-- UI.
-- Update: 1/10/2024 - Many releases, much testing, I believe this to be the most stable version of Oarc.
-- I just 4.2.21 added support for Character (legacy Factorio) mode, along with what I call Brave New player
-- mode.  I've added many features, most are just enabling access to features provided by Oarcinea in 
-- config.lua through the UI, which simplifies access to those many features.  I've added the warning for 
-- each attack by biters, after watching players ignore defenses and being attacked before they really get 
-- started. This supports a tracking mode, and monitoring of which location that group came from after that
-- group died. This helps me to know where to engage even in late game.
-- Speed of bots is displayed in an understandable mode of KPH.  JVMGuy helped by adding the support for 
-- a square and diamond shaped base. Some players reported that they wanted the WHOLE base to be covered by
-- the logistics network.

-- Comments below are from Oarcinae. 

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

-- 
    
--local console = {
--    name = 'Console',
--    admin = true,
----    print = function(...) rcon.print(...) end,
--    print = function (...)
--      for i,v in ipairs(arg) do
--        printResult = printResult .. tostring(v) .. "\t"
--      end
--      printResult = printResult .. "\n"
--      rcon.print(printResult, {sound=defines.print_sound.never})
--    end,
--    color = {1, 1, 1, 1}
--}

local console = {
    name = 'Console',
    admin = true,
    print = function(...) rcon.print(...) end,
    color = {0, 1, 1, 1}    -- cyan
}
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
require("lib/stats_gui")

local string = require('__stdlib__/stdlib/utils/string')

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
        [18] = "assembling-machine-2",
        [19] = "small-lamp",
        [20] = "stone-wall",
        [21] = "pipe-to-ground",
        [22] = "pipe",
        [23] = "offshore-pump",
        [24] = "boiler",
        [25] = "steam-engine",
        [26] = "burner-inserter",
        [27] = "fast-inserter",
        [28] = "filter-inserter",
        [29] = "lab",
        [30] = "radar"
}

commands.add_command("trigger-map-cleanup",
    "Force immediate removal of all expired chunks (unused chunk removal mod)",
    RegrowthForceRemoveChunksCmd)


local function update_loaders()
    for _, force in pairs(game.forces) do
        force.recipes["loader"].enabled = force.technologies["logistics"].researched
        force.recipes["fast-loader"].enabled = force.technologies["logistics-2"].researched
        force.recipes["express-loader"].enabled = force.technologies["logistics-3"].researched
    end
end

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
    RenderPermanentGroundText(game.surfaces[GAME_SURFACE_NAME], {x=-27,y=-25}, 12,    "Brave New OARC", {0.9, 0.7, 0.3, 0.8})
    if global.ocfg.space_block then -- Space block
        RenderPermanentGroundText(game.surfaces[GAME_SURFACE_NAME], {x=-13,y=-17}, 8, "Space Block", {0.9, 0.7, 0.3, 0.8})  
    elseif global.ocfg.seablock then -- Sea Block
        RenderPermanentGroundText(game.surfaces[GAME_SURFACE_NAME], {x=-10,y=-17}, 8, "Sea Block", {0.9, 0.7, 0.3, 0.8})  
    elseif global.ocfg.krastorio2 then -- Krastorio2
        RenderPermanentGroundText(game.surfaces[GAME_SURFACE_NAME], {x=-11,y=-17}, 8, "Krastorio2", {0.9, 0.7, 0.3, 0.8}) 
    elseif global.ocfg.alien_module then -- Alien ore
        RenderPermanentGroundText(game.surfaces[GAME_SURFACE_NAME], {x=-15,y=-17}, 8, "Alien Modules", {0.9, 0.7, 0.3, 0.8}) 
    end
    BNOSwarmGroupInit()
    log("Applying new values for Starting Area: " .. game.surfaces.oarc.map_gen_settings.starting_area *100 .. "%")
    -- Apply the value set in game UI of Starting Area Size to the starting area radius's
    local starting_area = game.surfaces.oarc.map_gen_settings.starting_area
    if (starting_area<.5) then
        OARC_CFG.safe_area.safe_radius = OARC_CFG.safe_area.safe_radius * 0.5
    else
        OARC_CFG.safe_area.safe_radius = OARC_CFG.safe_area.safe_radius * starting_area
    end
    OARC_CFG.safe_area.warn_radius = OARC_CFG.safe_area.warn_radius * starting_area
    OARC_CFG.safe_area.danger_radius = OARC_CFG.safe_area.danger_radius * starting_area

    update_loaders()   -- loaders

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
    if not global.ocfg.seablock then
        SeparateSpawnsGenerateChunk(event)
    end

    CreateHoldingPen(event.surface, event.area)
end)


----------------------------------------
-- Gui Click
----------------------------------------
script.on_event(defines.events.on_gui_click, function(event)
--    log(game.players[event.player_index].name .. " generated a gui click event: " .. tostring(event.element.name))
    -- Don't interfere with other mod related stuff.
    if (event.element.get_mod() ~= nil) then return end

    if event.element and event.element.valid then
        if event.element.name == "stats_close_stats_gui" then
            closeStatsGui(game.players[event.player_index])
        elseif event.element.name == "stats_dialog" then
            buildStatsTable(game.players[event.player_index], 1)
            HideOarcGui(game.players[event.player_index])
        elseif event.element.name == "stats_close_stats_gui" then
            event.element.parent.parent.destroy()
        end
    end

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

script.on_event(defines.events.on_gui_selection_state_changed, function (event)
    if (event.element.name == "stats_dropdown") then
        buildStatsTable(game.players[event.player_index], event.element.selected_index)
    end
end)

----------------------------------------
-- Player Events
----------------------------------------
script.on_event(defines.events.on_player_joined_game, function(event)
    local joiningPlayer=game.players[event.player_index]
    if global.ocfg.krastorio2 and not global.ocfg.creep_initialized then
        remote.call("kr-creep", "set_creep_on_surface", game.surfaces["oarc"].index, true)      -- oarc
        remote.call("kr-creep", "set_creep_on_surface", game.surfaces["nauvis"].index, false)     -- nauvis
        global.ocfg.creep_initialized=true
    end

    if global.ocfg.dangOreus and not global.ocfg.danOreus_initialized then
        remote.call("dangOreus", "toggle", game.surfaces["nauvis"], false)      -- turn off ore on nauvis to save cpu
        global.ocfg.danOreus_initialized=true
    end

    log("on_event::On Player Joined Game " .. joiningPlayer.name)
    PlayerJoinedMessages(event)
    ServerWriteFile("player_events", joiningPlayer.name .. " joined the game." .. "\n")
    -- Remove player name from map while they are online_time
    -- Render some welcoming text...

    if (global.players[event.player_index].drawOnExit ~=nil) then
        log("Destroying drawOnExit: " .. tostring(global.players[event.player_index].drawOnExit) .. " for player: " .. game.players[event.player_index].name)
        rendering.destroy(global.players[event.player_index].drawOnExit)
        global.players[event.player_index].drawOnExit=nil
    end
    if (global.spawn[event.player_index]) then
        DisplayWelcomeBackGroundTextAtSpawn (joiningPlayer, global.spawn[event.player_index])
    end
    if (global.players[event.player_index].emptyInventory)  then    -- this has to be done here since Space Block on_created
        empty_players_inventory(joiningPlayer) -- Space Block and potentially other mods add inventory
        global.players[event.player_index].emptyInventory=nil
    end

end)
    
----------------------------------------
script.on_event(defines.events.on_player_created, function(event)
local player = game.players[event.player_index]

log("on_event::On Player created: " .. player.name)

-- Additions from BraveNewWork OnEvent_on_player_created(event) vf
    if not global.players then  
        global.players = {}
    end
    if (#global.players < event.player_index) then
        log("Zeroing out index :" .. event.player_index .. " drawOnExit to nil for " .. game.players[event.player_index].name)
        local moatChoice=true
        if global.ocfg.spawn_config.gen_settings.moat_choice_enabled then
            moatChoice =  global.ocfg.spawn_config.gen_settings.moat_choice_enabled
        end

        global.players[event.player_index] = {
            crafted = {},
            inventory_items = {},   
            previous_position = player.position,
            drawOnExit = nil,
            characterMode = false,
            inSpawn = true,
            moatChoice=moatChoice
        }
    end
    -- Move the player to the game surface immediately.  First time spawning - character has to be deleted
    global.players[event.player_index].emptyInventory = true    -- postpone until on_player_joined, since space block fills inventory in their on_player_created, which is done AFTER ours.
    if player.character then 
        player.character.destroy()
    end
    player.teleport({x=0,y=0},  game.surfaces[GAME_SURFACE_NAME])   -- don't use SafeTeleport or double characters show up
    player.set_controller{type=defines.controllers.character,character=player.surface.create_entity{name='character',force=player.force,position=player.position}}

    log("Player teleported to 0:0")
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
    -- enable cheat mode - Allows for infinite free crafting which we don't want in normal mode, and done via code when enabled in BNO mode.
    
    -- Set-up a sane default for the quickbar
    if global.ocfg.space_block then 
        default_qb_slots[6]="fast-inserter"    
        default_qb_slots[7]="burner-inserter"    
    
        default_qb_slots[10]="landfill"    
        default_qb_slots[17]="iron-chest"  
        default_qb_slots[19]="spaceblock-matter-furnace"  
        
        default_qb_slots[20]="spaceblock-water" 
        default_qb_slots[26]="medium-electric-pole"
        default_qb_slots[27]="small-electric-pole"        
        default_qb_slots[29]="small-lamp"
    end
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
    if (global.ocfg.space_block) then
        TemporaryHelperText("Assemblers produce coal,wood, iron,copper,stone and random items at a slower rate than space matter furnaces", {-22, -10}, TICKS_PER_MINUTE*5, 1.5,{0,.7,1,1})
    end
    TemporaryHelperText("Check Top left - System Info for more information",                                             {-22, 10}, TICKS_PER_MINUTE*5, 1.5,{0,.7,1,1})


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
    else
        if global.spawn[player.index]~=nil then
            global.players[player.index].drawOnExit = rendering.draw_text{text=player.name,
                            surface=game.surfaces[GAME_SURFACE_NAME],
                            target={x=global.spawn[player.index].x-21, y=global.spawn[player.index].y+5},
                            color={0.9, 0.7, 0.3, 0.8},
                            scale=20,
                            font="compi",
                            draw_on_ground=true,
                            orientation=0,
                            scale_with_zoom=false,
                            only_in_alt_mode=false}
            log("Player player.name - drawOnExit created = " .. global.players[player.index].drawOnExit)
        end
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

    if #global.oarc_decon_miners>0 and ((game.tick % (TICKS_PER_SECOND)) == 2) then
        OarcAutoDeconOnTick()
    end

    if global.ocfg.warn_biter_attack then
        global.swarmCheckTick = global.swarmCheckTick or game.tick
        if (game.tick >= global.swarmCheckTick) then
            BNOCleanGPSStack()
            global.swarmCheckTick = game.tick + TICKS_PER_SECOND*2    -- check again in 2 seconds
        end
    end
    -- check to see if a bno assembler is in the game and needs to be damaged and then exploded
    if  (game.tick % (TICKS_PER_SECOND) == 59) 
    and (settings.startup["bno-assembler-choice"].value >0) 
    and global.ocfg.bno_assembler_explodes then         -- (settings.startup["bno-assembler-explode"].value==true) then
        checkKillBnoAssembler()
    end
end)

----------------------------------------
--  Checks to see if a new bno assembler needs to be damaged due to low power, exploded and ghost removed
--  Only notify a player once every 2 minutes, and only if damaged assembler is in a shared map
----------------------------------------
function checkKillBnoAssembler()
    local entityPos={}
    local surface = game.surfaces[GAME_SURFACE_NAME]
	local entities = surface.find_entities_filtered{name="assembling-machine-bno"}
	for _, entity in pairs(entities) do
	    if entity and entity.valid and entity.health and ((entity.energy / entity.electric_buffer_size)<.20) then
            if entity.last_user.connected then  -- is player online - then damage bno assembler
                entityPos=entity.position
	            entity.damage(40, "neutral", "explosion")   -- entity becomes invalid when health == 0
                -- if the bots have repair packs they will typically keep the assembler above 700 in health
                if (entity.valid and entity.health <= 600) then
                    if global.ocfg.share_chart[entity.last_user.index] then
                        for _,player in pairs(game.connected_players) do
                            if global.ocfg.notify_assembler_explode_notification[player.name] == nil then
                                global.ocfg.notify_assembler_explode_notification[player.name] = true
                            end
                            if global.ocfg.notify_assembler_explode_notification[player.name] then
                                local notify = false
                                -- only notify once every 2 minutes
                                if  global.ocfg.notify_assembler_explode_notification[player.name .. " tick"] == nil then
                                    notify = true
                                elseif global.ocfg.notify_assembler_explode_notification[player.name .. " tick"] < game.tick then
                                    notify = true
                                end
                                if notify then
                                    global.ocfg.notify_assembler_explode_notification[player.name .. " tick"] = game.tick  + (2 * TICKS_PER_MINUTE)
                                    player.print("Large assembler owned by " .. entity.last_user.name .. " is about to explode! " .. GetGPStext(entityPos))
                                end
                            end
                        end
                    end
                end
                if not entity.valid then
                    local tile = surface.get_tile(entityPos.x,entityPos.y)
                    local ghost = surface.find_entities_filtered{ghost_name="assembling-machine-bno",position=entityPos}
                    if ghost then
                        ghost[1].destroy()
                    end
                end
            end
	    end
	end
end


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

--script.on_event(defines.events.on_console_command, function(event)
--    if (event.player_index and event.message) then
--        ServerWriteFile("server_console_command", game.players[event.player_index].name .. ": " .. event.message .. "\n")
--    end
--end)


----------------------------------------
-- On Research Finished
-- This is where you can permanently remove researched techs
----------------------------------------
script.on_event(defines.events.on_research_finished, function(event)
    local force = event.research.force

    -- Never allows players to build rocket-silos in "frontier" mode.
    if global.ocfg.frontier_rocket_silo and not global.ocfg.frontier_allow_build then
        RemoveRecipe(force, "rocket-silo")
    end

    if global.ocfg.lock_goodies_rocket_launch and
        (not global.ocore.satellite_sent or not global.ocore.satellite_sent[force.name]) then
        for _,v in ipairs(LOCKED_RECIPES) do
            RemoveRecipe(force, v.r)
        end
    end

    for indx,player in pairs(game.connected_players) do
        if (player.force.name == force.name) then
            player.print("Your team completed researching [technology=" .. event.research.name .. "]", {r=0, g=102/255, b=0, a=1}) -- green
            log("Team " .. force.name .. " completed researching [technology=" .. event.research.name .. "]")
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
    OarcAutoDeconOnResourceDepleted(event)
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
    if global.creative or global.players[event.player_index].characterMode then
        return
    end
    local player = game.players[event.player_index]
    if global.seablocked ==nil then
    else
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

    checkForStealing(player, entity)
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
        if global.ocfg.alien_module and name=="artifact-ore" and entity==nil then
            -- the ore it will just disappear - no one gets it
        else
            entity = entity or global.forces[player.force.name].roboport    -- dump unknown item to main roboport
        end
        if entity and entity.valid then
            -- This was causing crashes in dropItems if a ghost entity forced a drop, a tank running over stone, or dropping a ghost on stone could do this                  
            if (global.enable_oe_debug) then
                log("dropItems: Spilling items for: ".. entity.name .. ", type: " .. entity.type .. ", at " .. GetGPStext(entity.position) .. ", entity force: ".. entity.force.name)
            end
            if (entity.name == "oarc-gui") then
                game.players[player.name].print("Close your menu when stealing ore from someone ;)")                    
            elseif (entity.surface == nil) then
                game.players[player.name].print("Send this log to JustGoFly - it shows something that WOULD have crashed, and provides good info to debug what caused it")
                log("dropItems: would have crashed accessing entity.surface - on entity name: " .. entity.name .. " for item: " .. name .. " count: " .. count .. " for player: " .. player.name)
            else
                entity.surface.spill_item_stack(entity.position, {name = name, count = count}, false, entity.force, false)
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
    elseif string.match(name, "dt%-cell") then
        -- allow Krastorio 2 special cells
        return count
    elseif string.match(name, ".*fuel%-cell") then
        -- allow Krastorio 2 fuel cells
        return count
    elseif string.match(name, ".*%-fuel") then
        -- allow lexi-aircraft to load fuel cells into aircraft by hand
        return count
    elseif name == "BlueprintAlignment-blueprint-holder" then
        -- temporary holding location for original blueprint, should only ever be one of these.
        return count
        -- allow poles and combinators for circuitissimo
    elseif global.ocfg.circuitissimo and (string.match(name, ".*combinator*") or string.match(name, ".*pole")) then
        return math.min(20, count)
    end
    return 0
end


function preventMining(player)
    if global.players[player.index].characterMode then 
        player.force.manual_mining_speed_modifier = 0  -- allow mining
        EnableTech(player.force, "steel-axe")
        return
    else
    -- prevent mining (this appeared to be reset when loading a 0.16.26 save in 0.16.27)
        player.force.manual_mining_speed_modifier = -0.99999999 -- allows removing ghosts with right-click
        if global.ocfg.krastorio2 then
            if global.players[player.index].characterPlayer then
                EnableTech(player.force, "kr-iron-pickaxe")
                EnableTech(player.force, "kr-advanced-pickaxe")
            else
                DisableTech(player.force, "kr-iron-pickaxe")
                DisableTech(player.force, "kr-advanced-pickaxe")
            end
        end
        DisableTech(player.force, "steel-axe") -- researching this upgrades the above manual_mining_speed_modifier by 1 - not good !
    end
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

 -- if player hits q over an item, check their inventory to see if they have that item,
 -- if they do - load their hand, otherwise put a ghost in their hand
script.on_event(defines.events.on_player_pipette, function(event)
    if global.creative or global.players[event.player_index].characterMode then
        return
    end
    local player = game.players[event.player_index]
    local inv = global.players[event.player_index].inventory_items
    local allowed = 0
    if inv[event.item.name] then
        allowed = itemCountAllowed(event.item.name, inv[event.item.name].count, player)
    end
    if allowed == 0 then
        player.cursor_stack.clear()
        player.cursor_ghost = event.item
    end
end)

script.on_event(defines.events.on_player_crafted_item, function(event)
    if global.creative or global.players[event.player_index].characterMode then
        return
    end
    pcall(function()    -- mostly safeguard seablock from crashing when a player tries to craft a liquid
        game.players[event.player_index].cursor_ghost = event.item_stack.prototype
        event.item_stack.count = 0
    end)
end)

script.on_event(defines.events.on_player_main_inventory_changed, inventoryChanged)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    if global.creative or global.players[event.player_index].characterMode  then
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

    checkForStealing(player, player.opened)

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
        player.print({"out-of-storage", player.name})
        log("Sending out of storage message to: " .. player.name)
    end
end)

script.on_event(defines.events.on_player_fast_transferred, function(event)
    local player = game.players[event.player_index]
    local entity = event.entity
    local itemsStolen
    local items=""

    if (player.force.name ~= entity.force.name) then   -- taking something 
        if player.selected then
            itemsStolen = player.selected.get_output_inventory().get_contents()
            for  name, count in pairs(itemsStolen) do
                items = items ..  name .. " of qty : " ..  count .. " | "
            end
        end

        for idx,p in pairs(game.connected_players) do
            if (p.force.name ~= player.force.name) then
                screamViolationToPlayers(player, entity, items)
            end
        end
        log("WTF (on_player_fast_transferred)" .. player.name .. "just took from " .. entity.last_user.name .. " type: [" .. entity.type .. "] " .. entity.name .. " " .. items ..  GetGPStext(entity.position))
    end
end)

function screamViolationToPlayers(player, entity, items, logOnly)            
    logOnly = logOnly or false

    if not logOnly then
        for idx,p in pairs(game.connected_players) do
            if (p.force.name ~= player.force.name) then
                p.print("WTF " .. player.name .. "just took from " .. entity.last_user.name .. " " .. entity.name .. " " .. items ..  GetGPStext(entity.position))
                p.play_sound { path = 'wtf' }
            end
        end
    end
    log("WTF " .. player.name .. "just took from " .. entity.last_user.name .. " " .. entity.name .. " " .. items ..  GetGPStext(entity.position))
end

-- called when players stack changes
function checkForStealing(player, entity)
    -- warn players that someone is touching a chest - unless it's a /o player (admin) accessing a chest
        if (entity) then
        if (not string.contains(entity.type, "frame")) then     -- menu open
            if (entity.is_player()) then    -- admin accessing another players inventory
                log("WTF (admin function)" .. player.name .. " just took something from inventory of " .. entity.name .. " body! " ..  GetGPStext(entity.position))
            else
                -- if the player and we're not processing a menu of ANY MOD 
                if (player.opened and (pcall(function () return player.opened.gui == nil end))) then
                    -- fast transfer only of accessing a box/entity of another players
                    if (pcall(function() return (not player.opened_self and (player.opened.force.name ~= player.force.name)) end)) then   -- taking something from someone else
                        log("Debug info: " .. player.name .. " player.opened.name - " .. player.opened.name .. "player force: " .. player.force.name .. ", opened force: " .. player.opened.force.name)
                        local illegalTypes = {"container", "linked-container", "logistic-container", "furnace", "item", "boiler", "assembling-machine-1", "assembling-machine-2", "assembling-machine-3", "car"}
                        local reported=false
                        for index, value in ipairs(illegalTypes) do
                            if value == entity.type then
                                reportViolationToPlayers(player, entity)
                                reported=true
                            end
                        end
                        if not reported then
                            reportViolationToPlayers(player, entity, true)
                        end
                    end
                end
            end
        end
    end
end

function reportViolationToPlayers(player, entity, logOnly)
    local items = ""
    if entity.is_entity_with_owner then
        logOnly = logOnly or false
        local stolenInv = entity.get_output_inventory()
        itemsStolen = {}
        for i=1,#stolenInv do
            if stolenInv[i] and stolenInv[i].valid and stolenInv[i].valid_for_read then
                if itemsStolen[stolenInv[i].name] == nil then
                    itemsStolen[stolenInv[i].name] = stolenInv[i].count
                else
                    itemsStolen[stolenInv[i].name] = itemsStolen[stolenInv[i].name] + stolenInv[i].count
                end
            end
        end
        for  name, count in pairs(itemsStolen) do
            items = items ..  name .. " qty remaining : " ..  count .. " | "
        end
        if not logOnly then
            for idx,p in pairs(game.connected_players) do
                if (p.force.name ~= player.force.name) then
                    p.print("WTF " .. player.name .. "just accessed " .. entity.last_user.name .. " " .. entity.name .. " " .. items ..  GetGPStext(entity.position))
                    p.play_sound { path = 'wtf' }
                end
            end
        end
        log("WTF (checkForStealing)" .. player.name .. "just accessed " .. entity.last_user.name .. " type: " .. entity.type .. " <" .. entity.name .. "> " .. items ..  GetGPStext(entity.position))
    end
end


script.on_event(defines.events.on_entity_died, function(event)
    local playerThatDied=nil
    if global.creative then
        return
    end
    local entity = event.entity
    -- check if roboport was destroyed - the backer_name is the friendly name given to each roboport - the main one is named after to player
    log("BNO Roboport died for " .. entity.force.name .. " at " .. GetGPStext(entity.position))
    if (entity.name=="roboport-bno") then
        for name,player in pairs(game.players) do
            local SP=entity.position
            SP.y=SP.y+10        -- global.spawn is player spawn position - not roboport, and that is 10 tiles down from roboport. 
            -- it has to be at this location - could also compare (entity.backer_name == player.name) 
            if (GetGPStext(global.spawn[player.index]) == GetGPStext(SP)) then 
                playerThatDied=global.spawn[player.index]   -- capture the player that died
                SendBroadcastMsg("Oh No " .. playerThatDied.name .. " on '" .. entity.force.name ..  "'' Gone like a fart in the wind")
                log("Force DIED: " .. entity.force.name .. ", player: " .. playerThatDied.name )
                global.spawn[player.index]=nil  -- solves a race condition - player dies, then roboport dies, on respawn - crash without this in SafeTeleport
                log ("player: " .. player.name .. " at " ..GetGPStext(global.spawn[player.index]) .. " Died due to the starting roboport being destroyed.")
                log ("and entity at " .. GetGPStext(SP))
                SendBroadcastMsg("Our buddy " .. player.name .. " on force: '" .. entity.force.name .. "' Died due to the starting roboport being destroyed.")        
                SendMsg(player.name, "Sorry '" .. player.name .. "' you LOSE! Rejoin if you like, and give it another try")
                RemoveOrResetPlayer(player, false, true, true, true)
            end
        end
        -- other bno roboports will die - no need to kill off the player unless it's the main one.
        if playerThatDied ~= nil then    -- this crashed once when it was nil - so fix here
            for name, player in pairs(game.connected_players) do
                if (player.index == playerThatDied.index) then
                    player.play_sound { path = 'you-lost' }  -- if the player that died is still online - play random sound
                else
                    player.play_sound { path = 'player-lost' }
                end
            end
        end
    end
    if entity.name=="character" then
        game.set_game_state{game_finished = false, player_won = false, can_continue = true, }
    end
end)


script.on_event(defines.events.on_player_driving_changed_state, function(event)
    local player=game.players[event.player_index]
    log("Changed driver state: " .. event.entity.name)
    -- distance between two points √((x2 – x1)² + (y2 – y1)²)
    local distance = getDistance(event.entity.position, global.players[event.player_index].previous_position)
    if (distance > 1500) then
        log(string.format("msg: %s, sent to %d players", msg, #game.connected_players-1))
        for idx,p in pairs(game.connected_players) do
            if (p.index ~= player.index) then
                p.print("WTF is this guy (" .. player.name .. ") doing teleporting " .. distance .. " tiles " ..  GetGPStext(event.entity.position))
                p.play_sound { path = 'wtf' }
            end
        end        
        log("WTF Player : " .. player.name .. " teleported " .. distance .. " tiles and entered a vehicle far from his main base to x: " .. event.entity.position.x .. ", y: " .. event.entity.position.y)
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
    -- some mods teleport a player to a new surface, new position, allow this to happen
    if (game.players[event.player_index].surface.name ~= GAME_SURFACE_NAME) then
        return
    end
    -- enable moving around at 0,0
    if (event.player_index > #global.players) then
        return
    end
    local player = game.players[event.player_index]
    -- TODO: really shouldn't have to do this so often (can we do it in migrate function?)
    -- preventMining(player)

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
                player.print("Fog of War limit! Drop a radar to extend your reach", {sound=defines.print_sound.never})
                player.play_sound { path = 'Nu-uhh' }
            end
        end
    end
    -- save new player position
    global.players[event.player_index].previous_position = player.position
end)


script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	if event.setting == "bno-exploding-assemblers" then
        if not game.players[event.player_index].admin then
            player.print("Sorry but this is an admin only function - request that it be changed")
            return
        end
        global.ocfg.bno_assembler_explodes = settings.global["bno-exploding-assemblers"].value
        local onOff = " OFF"
        if global.ocfg.bno_assembler_explodes then 
            onOff = " ON" 
        end
        game.print("The admin turned " .. onOff .. " exploding large assemblers", {color={r=0, g=1, b=1, a=1}})
	end
end)

--script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
--    log("events.on_runtime_mod_setting_changed: setting " .. event.setting .. " for: " .. game.players[event.player_index].name .. "type: " .. event.setting_type)
--    log("Physical setting changed to: " .. settings.get_player_settings(event.player_index)["bno-share-chart"])
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

  
--=================================================================================================

-- @ tableIn: Table
-- @ element: any
local function tableContains(tableIn, element)
  for ___, value in pairs(tableIn) do
    if value == element then
      return true
    end
  end
  return false
end

--=================================================================================================
-- @ event: CustomInputEvent
-- Docs: https://lua-api.factorio.com/latest/events.html#CustomInputEvent
-- Taken directly from remove-biter-corpses from RedRafe mod
local function removeCorpses(event)
  local blacklist = {
      'character-corpse',
      'transport-caution-corpse'  -- Transport Drones
      }
      local player = game.players[event.player_index]
      if not player then return end
      local radius = 32
      -- settings.get_player_settings(event.player_index)['rbc-radius'].value
  
      local bodyCount = 0
      for ___, entity in pairs(player.surface.find_entities_filtered{
        position = player.position,
        radius = radius,
        type = 'corpse'}
      ) do 
     if not tableContains(blacklist, entity.name) then 
         entity.destroy()
         bodyCount = bodyCount + 1
     end
  end
  if bodyCount > 0 then 
    player.print('Removed ' .. tostring(bodyCount) .. ' corpses', {r=254/255, g=255/255, b=10/255, a=1})
  else 
    player.print('Already Clear', {r=49/255, g=190/255, b=48/255, a=1})
  end
end
  
--=================================================================================================
script.on_event("remove-corpses", removeCorpses)

--=================================================================================================
-- patch globals for 50 to 51 migration
-- add characterMode to global.forces and use in UI
commands.add_command("migrate-51", "4.2.51 migration" , function(command)
    if (game.players[command.player_index].admin) then
        for i, player in pairs(game.players) do
            if player.force.name == nil then
                log("Player: ".. player.name .. " is not on a force yet!")
            else
                if not global.forces then
                    log("initializing global.forces with " .. #game.players .. " players")
                    global.forces = {}
                end
                if global.forces[player.force.name].characterMode == nil then
                    global.forces[player.force.name].characterMode = global.players[i].characterMode
                else
                    if global.forces[player.force.name].characterMode == global.players[i].characterMode then
                        log("characterMode verification for player: " .. player.name .. " good !")
                    else
                        log("!!!!!  Major problem - " .. player.name .. " is characterMode : " .. tostring(global.players[i].characterMode) .. " and team is " .. tostring(global.forces[player.force.name].characterMode))
                    end
                end
            end
        end
    end
end)