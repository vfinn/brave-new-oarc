-- example-config.lua (Rename this file to config.lua to use it)
-- May 26 2020 (updated on)
-- Configuration Options
--
-- You should be safe to leave most of the settings here as defaults if you want.
-- The only thing you definitely want to change are the welcome messages.

--------------------------------------------------------------------------------
-- Messages
-- You will want to change some of these to be your own.
--------------------------------------------------------------------------------

-- This stuff is shown in the welcome GUI and Info panel. Make sure it's valid.
WELCOME_MSG_TITLE = "Welcome to Brave New Oarc"
WELCOME_MSG = "This game provides the OARC multiplayer capability, and the Brave New World" -- Printed to player on join as well.
SERVER_MSG = "Character Mode is same as normal factorio, but with fewer starting items than non char mode, and 1/5 the number of robots.\n" ..
--	         "Features:\n" .. 
--             "   Backspace key clears the area of biter corpses\n" ..
--             "   Server Info menu tab enables various in game options like: Hide your base from other players,\n" ..
--             "   Warn of biters attacks - the constant attack warnings can be stopped\n" ..
--             "   Enable offline attacks - useful in Alien Modules game or competition.\n" ..
--             "   Auto Deconstruction of miners (BETA!)\n" ..
--             "   RESTART is available in the menu choices, and will automatically occur if your main large roboport is destroyed.\n" ..
--             " Most Asked Questions: \n" ..
             "Q: Are there special feature?\n" ..
             "A: Backspace key clears biter corpses, in player menu click on a name to get a gps link to their location, use the Server Info tab in top left to see selections\n" ..
             "Q: Why can't I move outside the area that my main base is located?\n" ..
             "A: Fog of war that limits your movement, but is intended as an antigrief. Use a Radars to claim more area.\n" ..
             "Q: Why can't I make Artillery?\n" ..
             "A: These are available after you launch one rocket.\n" ..
             "Brave New Player Mode:\n" ..
             "Q: Why do I have no man?\n" ..
             "A: You did not select 'character' mode on spawn. In Brave New Player mode you start with more items, and have 5x more bots, but can not craft or hold many items in your inventory. Bots do all your work. For easier use selected Settings->Interface->Pick ghosts if no items are available.\n" ..
             "Q: What items can I hold in inventory, and pick up from chests/assemblers?\n" ..
             "A: 1) Red&Green wires, copper cable, 2) Any module, 3) Any vehicles and all the items that go into a vehicles, 4) fuel cells 5) Blueprints\n" ..
	         "Q: Can I drive a vehicle?\n" ..
             "A: Yes - hover cursor over vehicle and press <enter>, you can NOT fire weapons though. Use them to steam roll the enemy.\n" 

SCENARIO_INFO_MSG = "Latest updates in this scenario version:\n"..
"No attacks on your base while you are offline, configurable!\n"..
"This scenario offers the option of a buddy base with your friends if you start at the same time.\n"..
"Join - play, then use RESTART to buddy up with a friend and each have your own base next to each other\n" ..
"You can be on the main team or your own. All teams are friendly.\n"..
"If you leave in the first 15 minutes, your base and character will be deleted!"

CONTACT_MSG = "Contact: SteamID:JustGoFly | Discord:JustGoFly"
DISCORD_INV = "https://discord.gg/RjxsUfkJzj"

------------------------------------------------------------------------------------------------------------------------
-- Module Enables
-- Each of the following things enable special features. These can't be changed once the game starts.
------------------------------------------------------------------------------------------------------------------------
ENABLE_LARGE_ROBOPORT = true
-- This allows 2 players to spawn next to each other in the wilderness, each with their own starting point. It adds more
-- GUI selection options.
ENABLE_BUDDY_SPAWN = true

-- Frontier style rocket silo mode. This means you can't build silos, but some spawn out in the wild for you to use.
-- if ENABLE_MAGIC_FACTORIES=false, you will find a few special areas to launch rockets from.
-- If ENABLE_MAGIC_FACTORIES=true, you must buy a silo at one of the special chunks.
FRONTIER_ROCKET_SILO_MODE = false

-- Enable Undecorator. Removes decorative items to reduce save file size.
ENABLE_UNDECORATOR = true

-- Enable Tags (Players can add a name-tag to explain what type of role they are doing if they want.)
ENABLE_TAGS = true

-- Enable Long Reach
ENABLE_LONGREACH = false

-- Enable Autofill (My autofill is very simplistic, if you are using a similar mod disable this!)
ENABLE_AUTOFILL = false
-- Enable auto decon of miners (My miner decon is very simplistic, if you are using a similar mod disable this!)
ENABLE_MINER_AUTODECON = true

-- Enable Playerlist
ENABLE_PLAYER_LIST = true
PLAYER_LIST_OFFLINE_PLAYERS = true -- List offline players as well.

-- Enable shared vision between teams (all teams are COOP regardless)
ENABLE_SHARED_TEAM_VISION = true

-- Cleans up unused chunks periodically. Helps keep map size down.
ENABLE_REGROWTH = true
-- This removes player bases when they leave shortly after joining. Only works if you have regrowth enabled!
ENABLE_ABANDONED_BASE_REMOVAL = true

-- Enable the research queue by default for all forces.
ENABLE_RESEARCH_QUEUE = true

-- This enables coin drops from enemies and a shop (GUI) to buy stuff from.
ENABLE_COIN_SHOP = false

-- Enable item & energy sharing system. 
ENABLE_ITEM_AND_ENERGY_SHARING = false -- REQUIRES ENABLE_COIN_SHOP=true!

-- Enable magic chunks around the map that let you buy powerful factories that smelt/assemble/process very very quickly.
ENABLE_MAGIC_FACTORIES = false -- REQUIRES ENABLE_COIN_SHOP=true!

-- This inhibits enemy attacks on bases where all players are offline.
-- Not 100% guaranteed.
ENABLE_OFFLINE_PROTECTION = true

-- This allows you to set the tech price multiplier for the game, but 
-- have it only affect the main force. We just pad all non-main forces lab prod bonus.
-- This has no effect unless the tech multiplier is more than 1!
ENABLE_FORCE_LAB_PROD_BONUS = false


-- Lock various recipes and technologies behind a rocket launch.
-- Each team/force must launch their own rocket to unlock this!
LOCK_GOODIES_UNTIL_ROCKET_LAUNCH = true
LOCKED_TECHNOLOGIES = {
    {t="atomic-bomb"},{t="artillery"}
}
-- remove all of these for bno characters
SPACE_BLOCK_LOCKED_TECHNOLOGIES_BNO = {
    {t="military"},
    {t="car"},
    {t="automobilism"}
}

-- enable all of these for character mode
SPACE_BLOCK_UNLOCKED_TECHNOLOGIES_CHAR = {
    {t="military"},
    {t="car"},
    {t="automobilism"}
}

-- disable all of these for both char and BNO players
SPACE_BLOCK_LOCKED_TECHNOLOGIES_COMMON = {
    {t="gun-turret"},
    {t="explosives"},
    {t="repair-pack"},
    {t="laser"},
    {t="steel-axe"},
    {t="landfill"}
 }

 SPACE_BLOCK_RECIPES_REMOVE_ALL_PLAYERS = {
    {r="electric-mining-drill"},
    {r="burner-mining-drill"},
    {r="light-armor"}
 }

LOCKED_RECIPES = {
}

-- Give cheaty items on start.
ENABLE_POWER_ARMOR_QUICK_START = false
ENABLE_MODULAR_ARMOR_QUICK_START = false

------------------------------------------------------------------------------------------------------------------------
-- MAP CONFIGURATION OPTIONS
-- In past versions I had a way to config map settings here to be used for cmd
-- line launching, but now you should just be using --map-gen-settings and
-- --map-settings option since it works with --start-server-load-scenario
-- Read the README.md file for instructions.
------------------------------------------------------------------------------------------------------------------------

-- This scales resources so that even if you spawn "far away" from the center
-- of the map, resources near to your spawn point scale so you aren't
-- surrounded by 100M patches or something. This is useful depending on what
-- map gen settings you pick.
SCALE_RESOURCES_AROUND_SPAWNS = true

------------------------------------------------------------------------------------------------------------------------
-- Alien Options
------------------------------------------------------------------------------------------------------------------------

-- Adjust enemy spawning based on distance to spawns. All it does it make things
-- more balanced based on your distance and makes the game a little easier.
-- No behemoth worms everywhere just because you spawned far away.
-- If you're trying out the vanilla spawning, you might want to disable this.
OARC_MODIFIED_ENEMY_SPAWNING = true

------------------------------------------------------------------------------------------------------------------------
-- Starting Items
------------------------------------------------------------------------------------------------------------------------
-- Items provided to the player the first time they join
PLAYER_SPAWN_START_ITEMS = {["pistol"] = 1,
                            ["coal"] = 10,
                            ["stone-furnace"] = 4,
                            ["burner-mining-drill"] = 10
}

PLAYER_SPAWN_START_ITEMS_SPACE_BLOCK = {                            
                            ["coal"] = 10,
                            ["stone-furnace"] = 4                            
}

PLAYER_SPAWN_START_ITEMS_SEABLOCK = {
                            ["pistol"] = 1,
                            ["coal"] = 10,
                            ["stone-furnace"] = 4
}


-- Items provided after EVERY respawn (disabled by default)
PLAYER_RESPAWN_START_ITEMS = {
}

------------------------------------------------------------------------------------------------------------------------
-- Distance Options
------------------------------------------------------------------------------------------------------------------------

-- This is the radius, in chunks, that a spawn area is from any other generated
-- chunks. It ensures the spawn area isn't too near generated/explored/existing
-- area. The larger you make this, the further away players will spawn from
-- generated map area (even if it is not visible on the map!).
CHECK_SPAWN_UNGENERATED_CHUNKS_RADIUS = 20  -- 10 vf

-- How many chunks away from the center of the map should the silo be spawned
SILO_CHUNK_DISTANCE = 300

-- Near Distance in chunks
-- When a player selects "near" spawn, they will be in or as close to this range as possible.
NEAR_MIN_DIST = SILO_CHUNK_DISTANCE - 100     --this 200 previously  150
NEAR_MAX_DIST = SILO_CHUNK_DISTANCE - 50     -- this 250 previously 200

-- SILO_CHUNK_DISTANCE at 200
-- Far Distance in chunks
-- When a player selects "far" spawn, they will be at least this distance away.
FAR_MIN_DIST = SILO_CHUNK_DISTANCE + 50        -- 350
FAR_MAX_DIST = SILO_CHUNK_DISTANCE + 100        -- 400



------------------------------------------------------------------------------------------------------------------------
-- Resource & Spawn Circle Options
------------------------------------------------------------------------------------------------------------------------

-- This is where you can modify what resources spawn, how much, where, etc.
-- Once you have a config you like, it's a good idea to save it for later use
-- so you don't lost it if you update the scenario.
OARC_CFG = {

    -- Misc spawn related config.
    gen_settings = {

        -- THIS IS WHAT SETS THE SPAWN CIRCLE SIZE!
        -- Create a circle of land area for the spawn
        -- If you make this much bigger than a few chunks, good luck.
        land_area_tiles = CHUNK_SIZE*2.5,

        -- Allow players to choose to spawn with a moat
        moat_choice_enabled = true,
        -- If there is a moat, this attempts to connect to land to avoid "turtling"
        moat_bridging = true, 

        -- This only applies to non-circle shaped spawns
        moat_size = 7,
        -- If you change the spawn area size, you might have to adjust this as well
        moat_size_modifier = 1.5,     -- 1 is 8 spaces, spitters range is 15, this would need to be 2 to keep spitters from hitting pumps jgf

        -- Start resource shape. true = circle, false = square.
        resources_circle_shape = false,

        -- Force the land area circle at the spawn to be fully grass
        force_grass = true,

        -- Spawn a circle/octagon of trees around the base outline.
        -- tree_circle = true,
        -- tree_octagon = false,
        -- Spawn a square/circle/octagon/diamond of trees around the base outline.
        base_shape = "circle",

        crashed_ship_resources = {
                                 },
        crashed_ship_wreakage = {
                                },
    },

    -- Safe Spawn Area Options
    -- The default settings here are balanced for my recommended map gen settings (close to train world).
    -- These values get modified in on_init based on the players Starting Area Size setting.
    safe_area =
    {
        -- Safe area has no aliens
        -- This is the radius in tiles of safe area.
        safe_radius = CHUNK_SIZE*6,		 -- vf previously *6  (6*32=192). 

        -- Warning area has significantly reduced aliens
        -- This is the radius in tiles of warning area.
        warn_radius = CHUNK_SIZE*12,	-- vf previously *12	 

        -- 1 : X (spawners alive : spawners destroyed) in this area
        warn_reduction = 20,

        -- Danger area has slightly reduce aliens
        -- This is the radius in tiles of danger area.
        danger_radius = CHUNK_SIZE*24,		-- vf previously *32	(960 - previously was 1024)
        -- 1 : X (spawners alive : spawners destroyed) in this area
        danger_reduction = 5,
    },

    -- Location of water strip (horizontal)
    water = {
        x_offset = -60,  -- -31, -- previously 4
        y_offset =  22,	 -- -72 previously 60
        length = 8
    },

    -- Handle placement of starting resources
    resource_rand_pos_settings =
    {
        -- Autoplace resources (randomly in circle)
        -- This will ignore the fixed x_offset/y_offset values in resource_tiles.
        -- Only works for resource_tiles at the moment, not oil patches/water.
        enabled = false,	-- true vf
        -- Distance from center of spawn that resources are placed.
        radius = 45, -- 70,	
        -- At what angle (in radians) do resources start.
        -- 0 means starts directly east.
        -- Resources are placed clockwise from there.
        angle_offset = 2.32, -- 2.32 is approx SSW.
        -- At what andle do we place the last resource.
        -- angle_offset and angle_final determine spacing and placement.
        angle_final = 4.46 -- 4.46 is approx NNW.
    },

    -- Resource tiles
    -- If you are running with mods like bobs/angels, you'll want to customize this.
    resource_tiles =
    {
        ["stone"] =
        {
            amount = 1200,
            size = 16,
            x_offset = -44,	
            y_offset = -38	
        },
        ["copper-ore"] =
        {
            amount = 1200,
            size = 18,
            x_offset = -53,
            y_offset = -16
        },
        ["iron-ore"] =
        {
            amount = 1500,
            size = 18,
            x_offset =-53,	
            y_offset = 8	
        },
        ["coal"] =
        {
            amount = 1200,
            size = 16,
            x_offset = -44,
            y_offset = 30
        } --,

		
        -- ["uranium-ore"] =
        -- {
        --     amount = 0,
        --     size = 0,
        --     x_offset = 17,
        --     y_offset = -34
        -- }

        -- ####### Bobs + Angels #######
        -- DISABLE STARTING OIL PATCHES!
        -- Coal                = coal
        -- Saphirite           = angels-ore1
        -- Stiratite           = angels-ore3
        -- Rubyte              = angels-ore5
        -- Bobmonium           = angels-ore6

        -- ########## Bobs Ore ##########
        -- Iron                = iron-ore
        -- Copper              = copper-ore
        -- Coal                = coal
        -- Stone               = stone
        -- Tin                 = tin-ore
        -- Lead (Galena)       = lead-ore

        -- See https://github.com/Oarcinae/FactorioScenarioMultiplayerSpawn/issues/11#issuecomment-479724909
        -- for full examples.
    },

    -- Special resource patches like oil
    resource_patches =
    {
        ["crude-oil"] =
        {
            num_patches = 2,
            amount = 900000,		-- vf previously 900000
            x_offset_start = -4,
            y_offset_start = 48,
            x_offset_next = 6,
            y_offset_next = 0
        }
    },
}

---------------------------------------
-- Other Forces/Teams Options
---------------------------------------

-- Separate teams
-- This allows you to join your own force/team. Everyone is still COOP/PvE, all
-- teams are friendly and cease-fire.
ENABLE_SEPARATE_TEAMS = true

-- Main force is what default players join
MAIN_FORCE = "Main Force"

-- Enable if players can allow others to join their base.
-- And specify how many including the host are allowed.
ENABLE_SHARED_SPAWNS = true
MAX_PLAYERS_AT_SHARED_SPAWN = 3 -- 3 max - or update SpawnCtrlGuiClick
DISTANCE_BETWEEN_SPAWNS = 10    -- in chunks valid = 10..20

-- Share local team chat with all teams
-- This makes it so you don't have to use /s
-- But it also means you can't talk privately with your own team.
ENABLE_SHARED_TEAM_CHAT = true

---------------------------------------
-- Special Action Cooldowns
---------------------------------------
RESPAWN_COOLDOWN_IN_MINUTES = 15

-- Require playes to be online for at least X minutes
-- Else their character is removed and their spawn point is freed up for use
MIN_ONLINE_TIME_IN_MINUTES = 15

--------------------------------------------------------------------------------
-- Frontier Rocket Silo Options
--------------------------------------------------------------------------------

-- Number of silos found in the wild.
-- These will spawn in a circle at given distance from the center of the map
-- If you set this number too high, you'll have a lot of delay at the start of the game.
SILO_NUM_SPAWNS = 6

-- If this is enabled, you get silos at the positions specified below.
-- (The other settings above are ignored in this case.)
SILO_FIXED_POSITION = false

-- If you want to set fixed spawn locations for some silos.
SILO_POSITIONS = {{x = -1000, y = -1000},
                  {x = -1000, y = 1000},
                  {x = 1000,  y = -1000},
                  {x = 1000,  y = 1000}}

-- Set this to false so that you have to search for the silo's.
ENABLE_SILO_VISION = true

-- Add beacons around the silo (Philip's mod)
ENABLE_SILO_BEACONS = false
ENABLE_SILO_RADAR = false

-- Allow silos to be built by the player, but forces them to build in
-- the fixed locations. If this is false, silos are built and assigned
-- only to the main force. This can cause a problem for non main forces
-- when playing with LOCK_GOODIES_UNTIL_ROCKET_LAUNCH enabled.
ENABLE_SILO_PLAYER_BUILD = true


--------------------------------------------------------------------------------
-- Long Reach Options
--------------------------------------------------------------------------------
BUILD_DIST_BONUS = 64
REACH_DIST_BONUS = BUILD_DIST_BONUS
RESOURCE_DIST_BONUS = 2

--------------------------------------------------------------------------------
-- Autofill Options
--------------------------------------------------------------------------------
AUTOFILL_TURRET_AMMO_QUANTITY = 10

--------------------------------------------------------------------------------
-- ANTI-Griefing stuff ( I don't personally maintain this as I don't care for it.)
-- These things were added from other people's requests/changes and are disabled by default.
--------------------------------------------------------------------------------
-- Enable this to disable deconstructing from map view, and setting a time limit
-- on ghost placements.
ENABLE_ANTI_GRIEFING = true

-- Makes blueprint ghosts dissapear if they have been placed longer than this
-- ONLY has an effect if ENABLE_ANTI_GRIEFING is true!
GHOST_TIME_TO_LIVE = 30 * TICKS_PER_MINUTE

-- I like keeping this off... set to true if you want to shoot your own chests
-- and stuff.
ENABLE_FRIENDLY_FIRE = false


------------------------------------------------------------------------------------------------------------------------
-- EXPERIMENTAL FEATURES
-- The following things are not recommended unless you really know what you are doing and are okay with crashes and
-- editing lua code.
------------------------------------------------------------------------------------------------------------------------

-- This turns on writing chat and certain events to specific files so that I can use that for discord integration. I
-- suggest you leave this off unless you know what you are doing.
ENABLE_SERVER_WRITE_FILES = true

-- Enable this to have a vanilla style starting spawn. This changes the experience pretty drastically. If you enable
-- this, you will NOT get the option to spawn using the "pre-fab" fixed layout spawns. This is because the spawn types
-- just don't balance well with each other.
ENABLE_VANILLA_SPAWNS = false

-- Vanilla spawn point options (only applicable if ENABLE_VANILLA_SPAWNS is enabled.)

-- Num total spawns pre-assigned (minimum number)
-- Points are in an even grid layout.
VANILLA_SPAWN_COUNT = 60

-- Num tiles between each spawn. (I recommend at least 1000)
VANILLA_SPAWN_SPACING = 2000

-- Silo Islands
-- This options is only valid when used with ENABLE_VANILLA_SPAWNS and FRONTIER_ROCKET_SILO_MODE!
-- This spreads out rocket silos on every OTHER island/vanilla spawn
SILO_ISLANDS_MODE = false

-- This is part of regrowth, and if both are enabled, any chunks which aren't active and have no entities will
-- eventually be deleted over time. DO NOT USE THIS WITH MODS!
ENABLE_WORLD_EATER = false 