-- oarc_global_cfg.lua
-- April 2019
--
-- Here is where we store/init config values to the global table.
-- Allows runtime modification of game settings if we want it.
-- Also allows supporting both MOD and SCENARIO versions.

-- DON'T JUDGE ME


-- That's a LOT of settings.
function InitOarcConfig()

    global.ocfg = {}
	global.spawn = {}

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
    global.ocfg.frontier_rocket_silo = FRONTIER_ROCKET_SILO_MODE
    global.ocfg.silo_islands = SILO_ISLANDS_MODE
    global.ocfg.enable_undecorator = ENABLE_UNDECORATOR
    global.ocfg.enable_tags = ENABLE_TAGS
    global.ocfg.enable_long_reach = ENABLE_LONGREACH
    global.ocfg.enable_autofill = ENABLE_AUTOFILL
    global.ocfg.enable_miner_decon = ENABLE_MINER_AUTODECON
    global.ocfg.enable_player_list = ENABLE_PLAYER_LIST
    global.ocfg.list_offline_players = PLAYER_LIST_OFFLINE_PLAYERS
    global.ocfg.enable_shared_team_vision = ENABLE_SHARED_TEAM_VISION
    global.ocfg.enable_regrowth = ENABLE_REGROWTH
    global.ocfg.enable_abandoned_base_removal = ENABLE_ABANDONED_BASE_REMOVAL
    global.ocfg.enable_research_queue = ENABLE_RESEARCH_QUEUE
--    global.ocfg.enable_coin_shop =  setGlobalSetting("bno-coin-shop", ENABLE_COIN_SHOP)
    global.ocfg.enable_coin_shop = ENABLE_COIN_SHOP
    global.ocfg.enable_chest_sharing =  setGlobalSetting("bno-chest-sharing", ENABLE_ITEM_AND_ENERGY_SHARING, true)
--    global.ocfg.enable_chest_sharing = ENABLE_ITEM_AND_ENERGY_SHARING
    global.ocfg.enable_magic_factories = ENABLE_MAGIC_FACTORIES
    global.ocfg.enable_offline_protect = ENABLE_OFFLINE_PROTECTION
    global.ocfg.enable_power_armor_start = ENABLE_POWER_ARMOR_QUICK_START
    global.ocfg.enable_modular_armor_start = ENABLE_MODULAR_ARMOR_QUICK_START
    global.ocfg.lock_goodies_rocket_launch = LOCK_GOODIES_UNTIL_ROCKET_LAUNCH
    global.ocfg.scale_resources_around_spawns = SCALE_RESOURCES_AROUND_SPAWNS

    global.ocfg.modified_enemy_spawning = OARC_MODIFIED_ENEMY_SPAWNING
    global.ocfg.near_dist_start = NEAR_MIN_DIST
    global.ocfg.near_dist_end = NEAR_MAX_DIST
    global.ocfg.far_dist_start = FAR_MIN_DIST
    global.ocfg.far_dist_end = FAR_MAX_DIST
    global.ocfg.vanilla_spawn_count = VANILLA_SPAWN_COUNT
    global.ocfg.vanilla_spawn_spacing = VANILLA_SPAWN_SPACING

    global.ocfg.spawn_config = OARC_CFG

    global.ocfg.enable_separate_teams = ENABLE_SEPARATE_TEAMS
    global.ocfg.main_force = MAIN_FORCE
    global.ocfg.enable_shared_spawns = ENABLE_SHARED_SPAWNS
    global.ocfg.max_players_shared_spawn = MAX_PLAYERS_AT_SHARED_SPAWN
    global.ocfg.enable_shared_chat = ENABLE_SHARED_TEAM_CHAT
    global.ocfg.respawn_cooldown_min = RESPAWN_COOLDOWN_IN_MINUTES
    --global.ocfg.frontier_silo_count = SILO_NUM_SPAWNS    
    global.ocfg.frontier_silo_count = setGlobalSetting("bno-number-of-silos", SILO_NUM_SPAWNS)
    log("Silo count: " .. global.ocfg.frontier_silo_count)
    global.ocfg.frontier_silo_distance = SILO_CHUNK_DISTANCE
    global.ocfg.frontier_fixed_pos = SILO_FIXED_POSITION
    global.ocfg.frontier_pos_table = SILO_POSITIONS
    global.ocfg.frontier_silo_vision = ENABLE_SILO_VISION
    global.ocfg.frontier_allow_build = ENABLE_SILO_PLAYER_BUILD
    global.ocfg.circle_shape = (tree_circle == true)    -- otherwise it's an octagon
    global.ocfg.spawn_config.gen_settings.tree_circle = (setGlobalSetting("bno-spawn-base-shape-circle",  global.ocfg.spawn_config.gen_settings.tree_circle)=="circle")
    global.ocfg.spawn_config.gen_settings.tree_octagon = not global.ocfg.spawn_config.gen_settings.tree_circle
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
-- only use isBool true if field returns "yes" and needs conversion to boolean
function setGlobalSetting(settings_startup_name, default_val, isBool)
    isBool = isBool or false    -- set default to false
    local tmpVal = default_val
    local settingVal = settings.startup[settings_startup_name].value
    if ((settingVal ~= "use config.lua setting") and isBool) then
        tmpVal = settingVal=="yes"      -- convert Yes/No into boolean
    else
        tmpVal = settingVal
    end   
    log("setGlobalSetting: " .. settings_startup_name .. ", isBool? " .. tostring(isBool) .. ", input value: " .. tostring(default_val) .. ", output value: " .. tostring(tmpVal))
    return tmpVal
end

