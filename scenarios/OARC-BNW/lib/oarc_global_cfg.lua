-- oarc_global_cfg.lua
-- April 2019
--
-- Here is where we store/init config values to the global table.
-- Allows runtime modification of game settings if we want it.
-- Also allows supporting both MOD and SCENARIO versions.

-- DON'T JUDGE ME

local table = require('__stdlib__/stdlib/utils/string')

-- That's a LOT of settings.
function InitOarcConfig()

    global.ocfg = {}
	global.spawn = {}
    global.players = {}
    if (game.active_mods["clean-tutorial-grid"]) then
        global.ocfg.locked_build_area_tile = "clean-tutorial-grid"
    else
        global.ocfg.locked_build_area_tile = "tutorial-grid"
    end

     -- SCENARIO VERSION (ONLY - no more mod version.)
    global.ocfg.welcome_title = WELCOME_MSG_TITLE
    global.ocfg.welcome_msg = WELCOME_MSG
    global.ocfg.server_rules = SERVER_MSG
    global.ocfg.minimum_online_time = MIN_ONLINE_TIME_IN_MINUTES
    global.ocfg.server_contact = CONTACT_MSG
    global.ocfg.enable_vanilla_spawns = ENABLE_VANILLA_SPAWNS
    global.ocfg.enable_buddy_spawn = ENABLE_BUDDY_SPAWN
    global.ocfg.silo_islands = SILO_ISLANDS_MODE
    global.ocfg.enable_undecorator = ENABLE_UNDECORATOR
    global.ocfg.enable_tags = ENABLE_TAGS
    global.ocfg.enable_long_reach = ENABLE_LONGREACH
    global.ocfg.enable_autofill = ENABLE_AUTOFILL

    global.ocfg.enable_player_list = ENABLE_PLAYER_LIST
    global.ocfg.list_offline_players = PLAYER_LIST_OFFLINE_PLAYERS
    global.ocfg.enable_shared_team_vision = ENABLE_SHARED_TEAM_VISION
    global.ocfg.enable_regrowth = ENABLE_REGROWTH
    global.ocfg.enable_abandoned_base_removal = ENABLE_ABANDONED_BASE_REMOVAL
    global.ocfg.enable_research_queue = ENABLE_RESEARCH_QUEUE
--    global.ocfg.enable_coin_shop =  setGlobalSetting("bno-coin-shop", ENABLE_COIN_SHOP)
    global.ocfg.enable_coin_shop = ENABLE_COIN_SHOP
    global.ocfg.enable_chest_sharing =  setGlobalSetting("bno-chest-sharing", ENABLE_ITEM_AND_ENERGY_SHARING, true)
    -- for now let's make these same - but split chest and energy sharing up
    global.ocfg.enable_energy_sharing = global.ocfg.enable_chest_sharing
    global.ocfg.enable_magic_factories = ENABLE_MAGIC_FACTORIES
    -- We support a global option to turn on/off protection - host may choose always off, always on, or option based on player choice
    global.ocfg.enable_offline_protect = ENABLE_OFFLINE_PROTECTION  
    global.ocfg.offline_protect = {}
    global.ocfg.enable_miner_decon = {} -- forces
    global.ocfg.enable_miner_decon_notification = {} -- forces
    global.oarc_decon_miners = {}       -- table of miners to decon on_nth_tick
    global.ocfg.enable_power_armor_start = ENABLE_POWER_ARMOR_QUICK_START
    global.ocfg.enable_modular_armor_start = ENABLE_MODULAR_ARMOR_QUICK_START
    global.ocfg.lock_goodies_rocket_launch = LOCK_GOODIES_UNTIL_ROCKET_LAUNCH
    global.ocfg.scale_resources_around_spawns = SCALE_RESOURCES_AROUND_SPAWNS

    global.ocfg.modified_enemy_spawning = OARC_MODIFIED_ENEMY_SPAWNING
    global.ocfg.vanilla_spawn_count = VANILLA_SPAWN_COUNT
    global.ocfg.vanilla_spawn_spacing = VANILLA_SPAWN_SPACING

    global.ocfg.spawn_config = OARC_CFG

    global.ocfg.enable_separate_teams = ENABLE_SEPARATE_TEAMS
    global.ocfg.main_force = MAIN_FORCE
    global.ocfg.enable_shared_spawns = ENABLE_SHARED_SPAWNS
    global.ocfg.max_players_shared_spawn = MAX_PLAYERS_AT_SHARED_SPAWN
    global.ocfg.enable_shared_chat = ENABLE_SHARED_TEAM_CHAT
    global.ocfg.respawn_cooldown_min = RESPAWN_COOLDOWN_IN_MINUTES
    
    -- extract number from string
    -- "0: place anywhere", "6: small", "12: normal", "24: large"
    global.ocfg.frontier_silo_count=tonumber(string.match(settings.startup["bno-number-of-silos"].value, '%d[%d.,]*'))
    log("Silo count: " .. global.ocfg.frontier_silo_count)
    global.ocfg.frontier_rocket_silo = global.ocfg.frontier_silo_count~=0   -- 0 silo = build your own silo's

    global.ocfg.map_size = setGlobalSetting("bno-map-size", "normal") 
    global.ocfg.near_dist_start = NEAR_MIN_DIST
    global.ocfg.near_dist_end = NEAR_MAX_DIST
    global.ocfg.far_dist_start = FAR_MIN_DIST
    global.ocfg.far_dist_end = FAR_MAX_DIST
    global.ocfg.frontier_silo_distance =  SILO_CHUNK_DISTANCE
    if (global.ocfg.map_size == "tiny") then
        global.ocfg.frontier_silo_distance =  SILO_CHUNK_DISTANCE / 4
        global.ocfg.near_dist_start = NEAR_MIN_DIST / 4
        global.ocfg.near_dist_end = NEAR_MAX_DIST / 4
        global.ocfg.far_dist_start = FAR_MIN_DIST / 4
        global.ocfg.far_dist_end = FAR_MAX_DIST / 4
    elseif (global.ocfg.map_size == "small") then
        global.ocfg.frontier_silo_distance =  SILO_CHUNK_DISTANCE / 2
        global.ocfg.near_dist_start = NEAR_MIN_DIST / 2
        global.ocfg.near_dist_end = NEAR_MAX_DIST / 2
        global.ocfg.far_dist_start = FAR_MIN_DIST / 2
        global.ocfg.far_dist_end = FAR_MAX_DIST / 2
    elseif (global.ocfg.map_size == "large") then
        global.ocfg.frontier_silo_distance =  SILO_CHUNK_DISTANCE * 2
        global.ocfg.near_dist_start = NEAR_MIN_DIST * 2
        global.ocfg.near_dist_end = NEAR_MAX_DIST * 2
        global.ocfg.far_dist_start = FAR_MIN_DIST * 2
        global.ocfg.far_dist_end = FAR_MAX_DIST * 2
    end

    global.ocfg.frontier_fixed_pos = SILO_FIXED_POSITION
    global.ocfg.frontier_pos_table = SILO_POSITIONS
    global.ocfg.frontier_silo_vision = ENABLE_SILO_VISION
    global.ocfg.frontier_allow_build = ENABLE_SILO_PLAYER_BUILD
    -- global.ocfg.circle_shape = (tree_circle == true)    -- otherwise it's an octagon
    -- global.ocfg.spawn_config.gen_settings.tree_circle = (setGlobalSetting("bno-spawn-base-shape",  global.ocfg.spawn_config.gen_settings.tree_circle)=="circle")
    -- global.ocfg.spawn_config.gen_settings.tree_octagon = not global.ocfg.spawn_config.gen_settings.tree_circle
    global.ocfg.spawn_config.gen_settings.base_shape = setGlobalSetting("bno-spawn-base-shape", "circle")
    global.ocfg.enable_anti_grief =  setGlobalSetting("bno-anti-grief", ENABLE_ANTI_GRIEFING, true)
    global.ocfg.starting_bot_count = setGlobalSetting("bno-num-starting-bots", "100/50") 
    -- ghost ttl is special due to a string array of numbers and multiplying by TICKS_PER_MINUTE
    local ghost_ttl = GHOST_TIME_TO_LIVE
    if (settings.startup["bno-anti-grief-ghost-TTL"].value ~= "use config.lua setting") then
        ghost_ttl = tonumber(settings.startup["bno-anti-grief-ghost-TTL"].value)  * TICKS_PER_MINUTE
    end   
    log("Setting anti-grief ghost ttl settings to: " .. ghost_ttl/TICKS_PER_MINUTE .. " minutes")
    global.ocfg.ghost_ttl = ghost_ttl
    global.ocfg.enable_friendly_fire = ENABLE_FRIENDLY_FIRE

    global.ocfg.enable_server_write_files = ENABLE_SERVER_WRITE_FILES
    global.ocfg.warn_biter_attack = setGlobalSetting("bno-biter-swarm-attack", true, false)
    
    global.ocfg.warn_biter_setting = {}
    global.ocfg.share_chart = {}


    global.ocfg.space_block = game.active_mods["spaceblock"]
    if (global.ocfg.space_block) then    -- in data stage use:  mods["spaceblock"]
        log("Space Block mod installed !")
    end
    global.ocfg.easyStart=false

    global.ocfg.main_team=false
    -- The results of each of these can be treated as a boolean, but also contain the version number of the mod
    global.ocfg.freight_forwarding  = game.active_mods["FreightForwarding"]
    global.ocfg.bzlead              = game.active_mods["bzlead"]
    global.ocfg.bztitanium          = game.active_mods["bztitanium"]
    global.ocfg.krastorio2          = game.active_mods["Krastorio2"]
    global.ocfg.seablock            = game.active_mods["SeaBlock"]
    global.ocfg.lex_aircraft        = game.active_mods["lex-aircraft"]
    global.ocfg.alien_module        = game.active_mods["alien-module"]
    global.ocfg.LootChestPlus       = game.active_mods["LootChestPlus"]
    global.ocfg.dangOreus           = game.active_mods["dangOreus"]
    global.ocfg.claustorephobic     = game.active_mods["zzz-claustorephobic"]
    global.ocfg.circuitissimo       = game.active_mods["circuitissimo"]
    global.ocfg.brave_new_assembling_machines       = game.active_mods["brave-new-assembling-machines"]
    global.ocfg.forceRegenerationOfSilos = global.ocfg.dangOreus

    if (global.ocfg.krastorio2) then 
        global.ocfg.spawn_config.gen_settings.land_area_tiles = global.ocfg.spawn_config.gen_settings.land_area_tiles + 32 
        global.ocfg.creep_initialized=false
    end

    if global.ocfg.brave_new_assembling_machines then
        global.ocfg.surface_index_set=false
    end

    if global.ocfg.seablock then
        global.ocfg.spawn_config.gen_settings.moat_choice_enabled = false  -- moat makes no sense for seablock
    end
    if global.ocfg.freight_forwarding then global.ocfg.frontier_rocket_silo=false end
    global.ocfg.krastorio2_resources_increased = false

    if global.ocfg.dangOreus then
        global.ocfg.danOreus_initialized=false
    end

    -----------------------
    -- VALIDATION CHECKS --
    -----------------------

    if (not global.ocfg.frontier_rocket_silo or not global.ocfg.enable_vanilla_spawns) then
        global.ocfg.silo_islands = false
    end

    if (global.ocfg.enable_vanilla_spawns) then
        global.ocfg.enable_buddy_spawn = false
    end
-- vf enable item and power sharing without coins
--    if (not global.ocfg.enable_coin_shop) then
--        global.ocfg.enable_chest_sharing = false
--    end

    if (not global.ocfg.enable_chest_sharing) then
        global.ocfg.enable_magic_factories = false
    end
end

-- Set a value either based on MOD settings or config.lua
-- only use isYesNo true if field returns "yes" and needs conversion to boolean
function setGlobalSetting(settings_startup_name, default_val, isYesNo)
    isYesNo = isYesNo or false    -- set default to false
    local tmpVal = default_val
    local settingVal = settings.startup[settings_startup_name].value
    if ((settingVal ~= "use config.lua setting")) then
        if (isYesNo) then
            tmpVal = settingVal=="yes"      -- convert Yes/No into boolean
        else
            tmpVal = settingVal
        end
    end   
    log("setGlobalSetting: " .. settings_startup_name .. ", isYesNo? " .. tostring(isYesNo) .. ", input value: " .. tostring(default_val) .. ", output value: " .. tostring(tmpVal))
    return tmpVal
end
