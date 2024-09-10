-- separate_spawns_guis.lua
-- Nov 2016

-- I made a separate file for all the GUI related functions

require("lib/separate_spawns")
require("lib/gui_popup")

local INFO_GUI_MAX_WIDTH  = 800

local SPAWN_GUI_MAX_WIDTH = 500
local SPAWN_GUI_MAX_HEIGHT = 1400

-- Use this for testing shared spawns...
-- local sharedSpawnExample1 = {openAccess=true,
--                             position={x=50,y=50},
--                             players={"ABC", "DEF"}}
-- local sharedSpawnExample2 = {openAccess=false,
--                             position={x=200,y=200},
--                             players={"ABC", "DEF"}}
-- local sharedSpawnExample3 = {openAccess=true,
--                             position={x=400,y=400},
--                             players={"A", "B", "C", "D"}}
-- global.ocore.sharedSpawns = {testName1=sharedSpawnExample1,
--                        testName2=sharedSpawnExample2,
--                        Oarc=sharedSpawnExample3}

-- A display gui message
-- Meant to be display the first time a player joins.
function DisplayWelcomeTextGui(player)
    if ((player.gui.screen["welcome_msg"] ~= nil) or
        (player.gui.screen["spawn_opts"] ~= nil) or
        (player.gui.screen["shared_spawn_opts"] ~= nil) or
        (player.gui.screen["join_shared_spawn_wait_menu"] ~= nil) or
        (player.gui.screen["buddy_spawn_opts"] ~= nil) or
        (player.gui.screen["buddy_wait_menu"] ~= nil) or
        (player.gui.screen["buddy_request_menu"] ~= nil) or
        (player.gui.screen["wait_for_spawn_dialog"] ~= nil)) then
        log("DisplayWelcomeTextGui called while some other dialog is already displayed!")
        return false
    end

    local wGui = player.gui.screen.add{name = "welcome_msg",
                            type = "frame",
                            direction = "vertical",
                            caption=global.ocfg.welcome_title}
    wGui.auto_center=true

    wGui.style.maximal_width = INFO_GUI_MAX_WIDTH
    wGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT

    -- Start with server message.
    AddLabel(wGui, "server_msg_lbl1", global.ocfg.server_rules, my_label_style)
    
     
    AddLabel(wGui, "contact_info_msg_lbl1", global.ocfg.server_contact, my_label_style)
    AddSpacer(wGui)

    -- Informational message about the scenario
    AddLabel(wGui, "scenario_info_msg_lbl1", SCENARIO_INFO_MSG, my_label_style)
    AddSpacer(wGui)

    -- Not enough room on the screen for this
    -- Warning about spawn creation time
    AddLabel(wGui, "spawn_time_msg_lbl1", {"oarc-spawn-time-warning-msg"}, my_warning_style)

    -- Confirm button
    AddSpacerLine(wGui)
    local button_flow = wGui.add{type = "flow"}
    button_flow.style.horizontal_align = "right"
    button_flow.style.horizontally_stretchable = true
    button_flow.add{name = "welcome_okay_btn",
                    type = "button",
                    caption={"oarc-i-understand"},
                    style = "confirm_button"}

    return true
end


-- Handle the gui click of the welcome msg
function WelcomeTextGuiClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local buttonClicked = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    if (buttonClicked == "welcome_okay_btn") then
        if (player.gui.screen.welcome_msg ~= nil) then
            player.gui.screen.welcome_msg.destroy()
        end
        DisplaySpawnOptions(player)
    end
end

function getBuddy(player)
    local buddy = nil
    for i=1, #global.ocore.waitingBuddies,1 do
        if (global.ocore.waitingBuddies[i] ~= nil and global.ocore.waitingBuddies[i] ~= player.name) then
            buddy = game.players[global.ocore.waitingBuddies[i]]
        end
    end
    if (buddy) then
        log ("Buddy is " .. buddy.name)
    end
    return buddy
end

-- Display the spawn options and explanation
function DisplaySpawnOptions(player)
    if (player == nil) then
        log("DisplaySpawnOptions with no valid player...")
        return
    end

    if (player.gui.screen.spawn_opts ~= nil) then
        log("Tried to display spawn options when it was already displayed!")
        return
    end
    global.players[player.index].inSpawn=true
    player.gui.screen.add{name = "spawn_opts",
                            type = "frame",
                            direction = "vertical",
                            caption={"oarc-spawn-options"}}
    local sGui = player.gui.screen.spawn_opts
    sGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    sGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT
    sGui.auto_center=true

    -- Warnings and explanations...
    local warn_msg = {"oarc-click-info-btn-help"}
    AddLabel(sGui, "warning_lbl1", warn_msg, my_warning_style)
    AddLabel(sGui, "spawn_msg_lbl1", SPAWN_MSG1, my_label_style)

    -- The main spawning options. Solo near and solo far.
    -- If enable, you can also choose to be on your own team.
    local soloSpawnFlow = sGui.add{name = "spawn_solo_flow",
                                    type = "frame",
                                    direction="vertical",
                                    style = "bordered_frame"}

    -- Radio buttons to pick your team.
    if (global.ocfg.enable_separate_teams) then
        soloSpawnFlow.add{name = "isolated_spawn_main_team_radio",
                        type = "radiobutton",
                        caption={"oarc-join-main-team-radio"},
                        state=global.ocfg.main_team}
        soloSpawnFlow.add{name = "isolated_spawn_new_team_radio",
                        type = "radiobutton",
                        caption={"oarc-create-own-team-radio"},
                        state=not global.ocfg.main_team}
    end

    -- OPTIONS frame
    -- AddLabel(soloSpawnFlow, "options_spawn_lbl1",
    --     "Additional spawn options can be selected here. Not all are compatible with each other.", my_label_style)

-- Allow players to spawn with a moat around their area.
    if (global.ocfg.space_block) then
            soloSpawnFlow.add{name = "easy_start_option_checkbox",
                            type = "checkbox",
                            caption={"oarc-easy-start-option"},
                            state=global.ocfg.easyStart}
    else
        if global.ocfg.seablock then
            global.ocfg.spawn_config.gen_settings.moat_choice_enabled=false
        else
            local moat_bridge_enabled=global.ocfg.spawn_config.gen_settings.moat_bridging
            if (settings.startup["bno-moat-choice"].value == "Player choice w Bridge") then
                global.ocfg.spawn_config.gen_settings.moat_choice_enabled = true
                moat_bridge_enabled = true
            elseif (settings.startup["bno-moat-choice"].value == "Player choice w/o Bridge") then
                global.ocfg.spawn_config.gen_settings.moat_choice_enabled = true
                moat_bridge_enabled = false
            else
                global.ocfg.spawn_config.gen_settings.moat_choice_enabled = false
                moat_bridge_enabled = false
            end
        end
        if global.ocfg.spawn_config.gen_settings.moat_choice_enabled then
            if (global.ocfg.spawn_config.gen_settings.moat_choice_enabled and not global.ocfg.enable_vanilla_spawns) then
                soloSpawnFlow.add{name = "isolated_spawn_moat_option_checkbox",
                                type = "checkbox",
                                caption={"oarc-moat-option"},
                                state=global.players[player.index].moatChoice}
            end
        end
    end    
    soloSpawnFlow.add{name = "character_mode_option_checkbox",
                type = "checkbox",
                caption={"bno-mode-option"},
                state=global.players[player.index].characterMode}


    -- if (global.ocfg.enable_vanilla_spawns and (#global.vanillaSpawns > 0)) then
    --     soloSpawnFlow.add{name = "isolated_spawn_vanilla_option_checkbox",
    --                     type = "checkbox",
    --                     caption="Use a pre-set vanilla spawn point. " .. #global.vanillaSpawns .. " available.",
    --                     state=false}
    -- end

    -- Isolated spawn options. The core gameplay of this scenario.
    local soloSpawnbuttons = soloSpawnFlow.add{name = "spawn_solo_flow",
                                                type = "flow",
                                                direction="horizontal"}
    soloSpawnbuttons.style.horizontal_align = "center"
    soloSpawnbuttons.style.horizontally_stretchable = true
    soloSpawnbuttons.add{name = "isolated_spawn_near",
                    type = "button",
                    caption={"oarc-solo-spawn-near"},
                    style = "confirm_button"}
    soloSpawnbuttons.add{name = "isolated_spawn_far",
                    type = "button",
                    caption={"oarc-solo-spawn-far"},
                    style = "confirm_button"}

    if (global.ocfg.enable_vanilla_spawns) then
        AddLabel(soloSpawnFlow, "isolated_spawn_lbl1",
            {"oarc-starting-area-vanilla"}, my_label_style)
        AddLabel(soloSpawnFlow, "vanilla_spawn_lbl2",
            {"oarc-vanilla-spawns-available", #global.vanillaSpawns}, my_label_style)
    else
        AddLabel(soloSpawnFlow, "isolated_spawn_lbl1",
            {"oarc-starting-area-normal"}, my_label_style)
    end

    -- Spawn options to join another player's base.
    local sharedSpawnFrame = sGui.add{name = "spawn_shared_flow",
                                    type = "frame",
                                    direction="vertical",
                                    style = "bordered_frame"}
    if global.ocfg.enable_shared_spawns then
        local numAvailSpawns = GetNumberOfAvailableSharedSpawns()
        if (numAvailSpawns > 0) then
            sharedSpawnFrame.add{name = "join_other_spawn",
                            type = "button",
                            caption={"oarc-join-someone-avail", numAvailSpawns}}
            local join_spawn_text = {"oarc-join-someone-info"}
            AddLabel(sharedSpawnFrame, "join_other_spawn_lbl1", join_spawn_text, my_label_style)
        else
            AddLabel(sharedSpawnFrame, "join_other_spawn_lbl1", {"oarc-no-shared-avail"}, my_label_style)
            sharedSpawnFrame.add{name = "join_other_spawn_check",
                            type = "button",
                            caption={"oarc-join-check-again"}}
        end
    else
        AddLabel(sharedSpawnFrame, "join_other_spawn_lbl1",
            {"oarc-shared-spawn-disabled"}, my_warning_style)
    end

    -- Awesome buddy spawning system
    if (not global.ocfg.enable_vanilla_spawns) then
        if global.ocfg.enable_shared_spawns and global.ocfg.enable_buddy_spawn then
            local buddySpawnFrame = sGui.add{name = "spawn_buddy_flow",
                                            type = "frame",
                                            direction="vertical",
                                            style = "bordered_frame"}

            -- AddSpacerLine(buddySpawnFrame, "buddy_spawn_msg_spacer")
            buddySpawnFrame.add{name = "buddy_spawn",
                            type = "button",
                            caption={"oarc-buddy-spawn"}}
            AddLabel(buddySpawnFrame, "buddy_spawn_lbl1",
                {"oarc-buddy-spawn-info"} , my_label_style)
        end
    end

    -- Some final notes
    if (global.ocfg.max_players_shared_spawn > 0) then
        AddLabel(sGui, "max_players_lbl2",
                {"oarc-max-players-shared-spawn", global.ocfg.max_players_shared_spawn-1},
                my_note_style)
    end
    local spawn_distance_notes={"oarc-spawn-dist-notes", global.ocfg.near_dist_start, global.ocfg.near_dist_end, global.ocfg.far_dist_start, global.ocfg.far_dist_end}
    AddLabel(sGui, "note_lbl1", spawn_distance_notes, my_note_style)
end

-- This just updates the radio buttons/checkboxes when players click them.
function SpawnOptsRadioSelect(event)
    
    local player=game.players[event.player_index]
    local gPlayer=global.players[event.player_index]

    if not (event and event.element and event.element.valid) then return end
    local elemName = event.element.name

    if (elemName == "isolated_spawn_main_team_radio") then
        event.element.parent.isolated_spawn_new_team_radio.state=false
        
    elseif (elemName == "isolated_spawn_new_team_radio") then
        event.element.parent.isolated_spawn_main_team_radio.state=false
    end
    if (elemName == "character_mode_option_checkbox") then
        -- to see the sync code for forces and character mode diff with 4.2.62
        gPlayer.characterMode = event.element.state
    end

    local buddy = getBuddy(player)
    if (elemName == "buddy_spawn_main_team_radio") then
        event.element.parent.buddy_spawn_new_team_radio.state=false
        event.element.parent.buddy_spawn_buddy_team_radio.state=false
        if buddy then            
            -- buddy.gui.screen.buddy_spawn_opts.buddy_spawn_main_team_radio.state=true
            buddy.gui.screen.buddy_spawn_opts.spawn_buddy_flow.buddy_spawn_new_team_radio.state=false
            buddy.gui.screen.buddy_spawn_opts.spawn_buddy_flow.buddy_spawn_buddy_team_radio.state=false
        end
    elseif (elemName == "buddy_spawn_new_team_radio") then
        -- event.element.parent.buddy_spawn_main_team_radio.state=false
        event.element.parent.buddy_spawn_new_team_radio.state=true
        event.element.parent.buddy_spawn_buddy_team_radio.state=false
        if buddy then
            -- buddy.gui.screen.buddy_spawn_opts.buddy_spawn_main_team_radio.state=false
            buddy.gui.screen.buddy_spawn_opts.spawn_buddy_flow.buddy_spawn_new_team_radio.state=true
            buddy.gui.screen.buddy_spawn_opts.spawn_buddy_flow.buddy_spawn_buddy_team_radio.state=false
        end
    elseif (elemName == "buddy_spawn_buddy_team_radio") then
        -- event.element.parent.buddy_spawn_main_team_radio.state=false
        event.element.parent.buddy_spawn_new_team_radio.state=false
        event.element.parent.buddy_spawn_buddy_team_radio.state=true
        if buddy then
            -- buddy.gui.screen.buddy_spawn_opts.buddy_spawn_main_team_radio.state=false
            buddy.gui.screen.buddy_spawn_opts.spawn_buddy_flow.buddy_spawn_new_team_radio.state=false
            buddy.gui.screen.buddy_spawn_opts.spawn_buddy_flow.buddy_spawn_buddy_team_radio.state=true
        end
    end
end


-- Handle the gui click of the spawn options
function SpawnOptsGuiClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local elemName = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.screen.spawn_opts == nil) then
        return -- Gui event unrelated to this gui.
    end

    local pgcs = player.gui.screen.spawn_opts

    local joinMainTeamRadio, joinOwnTeamRadio, moatChoice, vanillaChoice = false
    if (elemName == "isolated_spawn_moat_option_checkbox") then
        global.players[player.index].moatChoice=pgcs.spawn_solo_flow.isolated_spawn_moat_option_checkbox.state
        return
    end

--    log("SpawnOptsGuiClick: ".. tostring(elemNam))
    -- Check if a valid button on the gui was pressed
    -- and delete the GUI
    if ((elemName == "default_spawn_btn") or
        (elemName == "isolated_spawn_near") or
        (elemName == "isolated_spawn_far") or
        (elemName == "join_other_spawn") or
        (elemName == "buddy_spawn") or
        (elemName == "join_other_spawn_check")) then

        if (global.ocfg.enable_separate_teams) then
            joinMainTeamRadio = pgcs.spawn_solo_flow.isolated_spawn_main_team_radio.state
            joinOwnTeamRadio  = pgcs.spawn_solo_flow.isolated_spawn_new_team_radio.state
        else
            joinMainTeamRadio = true
            joinOwnTeamRadio  = false
        end
        global.ocfg.main_team = joinMainTeamRadio       -- remember so on a restart we keep the setting
        
        -- modify above based on choice to remove main team for this. Code left in case we ever put it back
--        joinMainTeamRadio = false
--        joinOwnTeamRadio  = true
--        global.ocfg.main_team = false

        if global.ocfg.seablock then
            global.ocfg.spawn_config.gen_settings.moat_choice_enabled=false
        end
        if (global.ocfg.space_block) then
            global.ocfg.easyStart = pgcs.spawn_solo_flow.easy_start_option_checkbox.state
        end
        if (global.ocfg.spawn_config.gen_settings.moat_choice_enabled and not global.ocfg.enable_vanilla_spawns and
           (pgcs.spawn_solo_flow.isolated_spawn_moat_option_checkbox ~= nil)) then
                moatChoice = pgcs.spawn_solo_flow.isolated_spawn_moat_option_checkbox.state
                global.players[player.index].moatChoice=moatChoice
        end
        
        -- if (global.ocfg.enable_vanilla_spawns and
        --     (pgcs.spawn_solo_flow.isolated_spawn_vanilla_option_checkbox ~= nil)) then
        --     vanillaChoice = pgcs.spawn_solo_flow.isolated_spawn_vanilla_option_checkbox.state
        -- end
        pgcs.destroy()
    else
        return -- Do nothing, no valid element item was clicked.
    end

    if (elemName == "default_spawn_btn") then
        GivePlayerStarterItems(player)
        ChangePlayerSpawn(player, player.force.get_spawn_position(GAME_SURFACE_NAME))
        SendBroadcastMsg({"oarc-player-is-joining-main-force", player.name})
        ChartArea(player.force, player.position, math.ceil(global.ocfg.spawn_config.gen_settings.land_area_tiles/CHUNK_SIZE), player.surface)
        -- Unlock spawn control gui tab
        SetOarcGuiTabEnabled(player, OARC_SPAWN_CTRL_GUI_NAME, true)

    elseif ((elemName == "isolated_spawn_near") or (elemName == "isolated_spawn_far")) then

        -- Create a new spawn point
        local newSpawn = {x=0,y=0}

        -- Create a new force for player if they choose that radio button
        if global.ocfg.enable_separate_teams and joinOwnTeamRadio then
            local newForce = CreatePlayerCustomForce(player)
        end

        -- Find an unused vanilla spawn
        -- if (vanillaChoice) then
        if (global.ocfg.enable_vanilla_spawns) then
            if (elemName == "isolated_spawn_far") then
                newSpawn = FindUnusedVanillaSpawn(game.surfaces[GAME_SURFACE_NAME],
                                                            global.ocfg.far_dist_end*CHUNK_SIZE)
            elseif (elemName == "isolated_spawn_near") then
                newSpawn = FindUnusedVanillaSpawn(game.surfaces[GAME_SURFACE_NAME],
                                                            global.ocfg.near_dist_start*CHUNK_SIZE)
            end

        -- Default OARC-type pre-set layout spawn.
        else
            -- Find coordinates of a good place to spawn
            if (elemName == "isolated_spawn_far") then
                newSpawn = FindUngeneratedCoordinates(global.ocfg.far_dist_start,global.ocfg.far_dist_end, player.surface)
            elseif (elemName == "isolated_spawn_near") then
                newSpawn = FindUngeneratedCoordinates(global.ocfg.near_dist_start,global.ocfg.near_dist_end, player.surface)
            end
        end

        -- If that fails, find a random map edge in a rand direction.
        if ((newSpawn.x == 0) and (newSpawn.y == 0)) then
            newSpawn = FindMapEdge(GetRandomVector(), player.surface)
            log("Resorting to find map edge! x=" .. newSpawn.x .. ",y=" .. newSpawn.y)
        end

        -- Create that player's spawn in the global vars
        ChangePlayerSpawn(player, newSpawn)

        -- Send the player there
        QueuePlayerForDelayedSpawn(player.name, newSpawn, global.players[player.index].moatChoice, global.ocfg.enable_vanilla_spawns)
        if (elemName == "isolated_spawn_near") then
            SendBroadcastMsg({"oarc-player-is-joining-near", player.name})
        elseif (elemName == "isolated_spawn_far") then
            SendBroadcastMsg({"oarc-player-is-joining-far", player.name})
        end

        -- Unlock spawn control gui tab
        SetOarcGuiTabEnabled(player, OARC_SPAWN_CTRL_GUI_NAME, true)
        player.print({"", {"oarc-please-wait"}, "!"})

    elseif (elemName == "join_other_spawn") then
        DisplaySharedSpawnOptions(player)

    -- Provide a way to refresh the gui to check if people have shared their
    -- bases.
    elseif (elemName == "join_other_spawn_check") then
        DisplaySpawnOptions(player)

    -- Hacky buddy spawn system
    elseif (elemName == "buddy_spawn") then
        if #global.ocore.waitingBuddies>1 then
            game.print(player.name .. " attempting to form a buddy team, but we're busy forming another team. Get moving in there!")
            create_popup_gui(player,"Sorry busy forming a team - please wait, and try again", {"Two players are already in the process of forming a buddy team", "You will be able to join this screen when they are done","", "Please wait and try again ...", ""})        
            return
        end
        table.insert(global.ocore.waitingBuddies, player.name)
        SendBroadcastMsg({"oarc-looking-for-buddy", player.name})
        
        DisplayBuddySpawnOptions(player)
    end
end


-- Display the spawn options and explanation
function DisplaySharedSpawnOptions(player)
    player.gui.screen.add{name = "shared_spawn_opts",
                            type = "frame",
                            direction = "vertical",
                            caption={"oarc-avail-bases-join"}}

    local shGuiFrame = player.gui.screen.shared_spawn_opts
    shGuiFrame.auto_center = true
    local shGui = shGuiFrame.add{type="scroll-pane", name="spawns_scroll_pane", caption=""}
    ApplyStyle(shGui, my_fixed_width_style)
    shGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    shGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT
    shGui.horizontal_scroll_policy = "never"


    for spawnName,sharedSpawn in pairs(global.ocore.sharedSpawns) do
        if (sharedSpawn.openAccess and
            (game.players[spawnName] ~= nil) and
            game.players[spawnName].connected) then
            local spotsRemaining = global.ocfg.max_players_shared_spawn - #global.ocore.sharedSpawns[spawnName].players
            if (global.ocfg.max_players_shared_spawn == 0) then
                shGui.add{type="button", caption=spawnName, name=spawnName}
            elseif (spotsRemaining > 0) then
                shGui.add{type="button", caption={"oarc-spawn-spots-remaining", spawnName, spotsRemaining}, name=spawnName}
            end
            if (shGui.spawnName ~= nil) then
                -- AddSpacer(buddyGui, spawnName .. "spacer_lbl")
                ApplyStyle(shGui[spawnName], my_small_button_style)
            end
        end
    end


    shGui.add{name = "shared_spawn_cancel",
                    type = "button",
                    caption={"oarc-cancel-return-to-previous"},
                    style = "back_button"}
end

-- Handle the gui click of the shared spawn options
function SharedSpwnOptsGuiClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local buttonClicked = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    if (event.element.parent) then
        if (event.element.parent.name ~= "spawns_scroll_pane") then
            return
        end
    end

    -- Check for cancel button, return to spawn options
    if (buttonClicked == "shared_spawn_cancel") then
        DisplaySpawnOptions(player)
        if (player.gui.screen.shared_spawn_opts ~= nil) then
            player.gui.screen.shared_spawn_opts.destroy()
        end

    -- Else check for which spawn was selected
    -- If a spawn is removed during this time, the button will not do anything
    else
        for spawnName,sharedSpawn in pairs(global.ocore.sharedSpawns) do
            if ((buttonClicked == spawnName) and
                (game.players[spawnName] ~= nil) and
                (game.players[spawnName].connected)) then

                -- Add the player to that shared spawns join queue.
                if (global.ocore.sharedSpawns[spawnName].joinQueue == nil) then
                    global.ocore.sharedSpawns[spawnName].joinQueue = {}
                end
                table.insert(global.ocore.sharedSpawns[spawnName].joinQueue, player.name)

                -- Clear the shared spawn options gui.
                if (player.gui.screen.shared_spawn_opts ~= nil) then
                    player.gui.screen.shared_spawn_opts.destroy()
                end

                -- Display wait menu with cancel button.
                DisplaySharedSpawnJoinWaitMenu(player)

                -- Tell other player they are requesting a response.
                game.players[spawnName].print({"oarc-player-requesting-join-you", player.name})
                break
            end
        end
    end
end

function DisplaySharedSpawnJoinWaitMenu(player)

    local sGui = player.gui.screen.add{name = "join_shared_spawn_wait_menu",
                            type = "frame",
                            direction = "vertical",
                            caption={"oarc-waiting-for-spawn-owner"}}
    sGui.auto_center = true
    sGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    sGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    AddLabel(sGui, "warning_lbl1", {"oarc-you-will-spawn-once-host"}, my_warning_style)
    sGui.add{name = "cancel_shared_spawn_wait_menu",
                    type = "button",
                    caption={"oarc-cancel-return-to-previous"},
                    style = "back_button"}
end

-- Handle the gui click of the buddy wait menu
function SharedSpawnJoinWaitMenuClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local elemName = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.screen.join_shared_spawn_wait_menu == nil) then
        return -- Gui event unrelated to this gui.
    end

    -- Check if player is cancelling the request.
    if (elemName == "cancel_shared_spawn_wait_menu") then
        player.gui.screen.join_shared_spawn_wait_menu.destroy()
        DisplaySpawnOptions(player)

        -- Find and remove the player from the joinQueue they were in.
        for spawnName,sharedSpawn in pairs(global.ocore.sharedSpawns) do
            if (sharedSpawn.joinQueue ~= nil) then
                for index,requestingPlayer in pairs(sharedSpawn.joinQueue) do
                    if (requestingPlayer == player.name) then
                        global.ocore.sharedSpawns[spawnName].joinQueue[index] = nil
                        game.players[spawnName].print({"oarc-player-cancel-join-request", player.name})
                        return
                    end
                end
            end
        end

        log("ERROR! Failed to remove player from joinQueue!")
    end
end

local function IsSharedSpawnActive(player)
    if ((global.ocore.sharedSpawns[player.name] == nil) or
        (global.ocore.sharedSpawns[player.name].openAccess == false)) then
        return false
    else
        return true
    end
end


-- Get a random warp point to go to
function GetRandomSpawnPoint()
    local numSpawnPoints = TableLength(global.ocore.sharedSpawns)
    if (numSpawnPoints > 0) then
        local randSpawnNum = math.random(1,numSpawnPoints)
        local counter = 1
        for _,sharedSpawn in pairs(global.ocore.sharedSpawns) do
            if (randSpawnNum == counter) then
                return sharedSpawn.position
            end
            counter = counter + 1
        end
    end

    return {x=0,y=0}
end

-- This is a toggle function, it either shows or hides the spawn controls
function CreateSpawnCtrlGuiTab(tab_container, player)
    local spwnCtrls = tab_container.add{
        type="scroll-pane",
        name="spwn_ctrl_panel",
        caption=""}
    ApplyStyle(spwnCtrls, my_fixed_width_style)
    spwnCtrls.style.maximal_height = SPAWN_GUI_MAX_HEIGHT
    spwnCtrls.horizontal_scroll_policy = "never"

    if global.ocfg.enable_shared_spawns then
        if (global.ocore.uniqueSpawns[player.name] ~= nil) then
            -- This checkbox allows people to join your team when they first
            -- start the game.
            spwnCtrls.add{type="checkbox", name="accessToggle",
                            caption={"oarc-spawn-allow-joiners"},
                            state=IsSharedSpawnActive(player)}
            ApplyStyle(spwnCtrls["accessToggle"], my_fixed_width_style)
        end
    end

    -- @todo Figure out why this case could be hit... Fix for error report in github.
    if (global.ocore.playerCooldowns[player.name] == nil) then
        global.ocore.playerCooldowns[player.name] = {setRespawn=game.tick}
    end

    -- Sets the player's custom spawn point to their current location
    if ((game.tick - global.ocore.playerCooldowns[player.name].setRespawn) >
            (global.ocfg.respawn_cooldown_min * TICKS_PER_MINUTE)) then
        spwnCtrls.add{type="button", name="setRespawnLocation", caption={"oarc-set-respawn-loc"}}
        spwnCtrls["setRespawnLocation"].style.font = "default-small-semibold"

    else
        AddLabel(spwnCtrls,"respawn_cooldown_note1",
            {"oarc-set-respawn-loc-cooldown", formattime((global.ocfg.respawn_cooldown_min * TICKS_PER_MINUTE)-(game.tick - global.ocore.playerCooldowns[player.name].setRespawn))}, my_note_style)
    end
    AddLabel(spwnCtrls, "respawn_cooldown_note2", {"oarc-set-respawn-note"}, my_note_style)

    -- Display a list of people in the join queue for your base.
    if (global.ocfg.enable_shared_spawns and IsSharedSpawnActive(player)) then
        if ((global.ocore.sharedSpawns[player.name].joinQueue ~= nil) and
            (#global.ocore.sharedSpawns[player.name].joinQueue > 0)) then


            AddLabel(spwnCtrls, "drop_down_msg_lbl1", {"oarc-select-player-join-queue"}, my_label_style)
            spwnCtrls.add{name = "join_queue_dropdown",
                            type = "drop-down",
                            items = global.ocore.sharedSpawns[player.name].joinQueue}
            spwnCtrls.add{name = "accept_player_request",
                            type = "button",
                            caption={"oarc-accept"}}
            spwnCtrls.add{name = "reject_player_request",
                            type = "button",
                            caption={"oarc-reject"}}
        else
            AddLabel(spwnCtrls, "empty_join_queue_note1", {"oarc-no-player-join-reqs"}, my_note_style)
        end
        spwnCtrls.add{name = "join_queue_spacer", type = "label",
                        caption=" "}
    end
end

function SpawnCtrlGuiOptionsSelect(event)
    if not (event and event.element and event.element.valid) then return end

    local player = game.players[event.player_index]
    local name = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    -- Handle changes to spawn sharing.
    if (name == "accessToggle") then
        if event.element.state then
            if DoesPlayerHaveCustomSpawn(player) then
                if (global.ocore.sharedSpawns[player.name] == nil) then
                    CreateNewSharedSpawn(player)
                else
                    global.ocore.sharedSpawns[player.name].openAccess = true
                end

                SendBroadcastMsg({"oarc-start-shared-base", player.name})
            end
        else
            if (global.ocore.sharedSpawns[player.name] ~= nil) then
                global.ocore.sharedSpawns[player.name].openAccess = false
                SendBroadcastMsg({"oarc-stop-shared-base", player.name})
            end
        end
        FakeTabChangeEventOarcGui(player)
    end
end

function SpawnCtrlGuiClick(event)
    if not (event and event.element and event.element.valid) then return end

    local player = game.players[event.player_index]
    local elemName = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    if (event.element.parent) then
        if (event.element.parent.name ~= "spwn_ctrl_panel") then
            return
        end
    end

    -- Sets a new respawn point and resets the cooldown.
    if (elemName == "setRespawnLocation") then
        if DoesPlayerHaveCustomSpawn(player) then
            ChangePlayerSpawn(player, player.position)
            FakeTabChangeEventOarcGui(player)
            player.print({"oarc-spawn-point-updated"})
        end
    end

    -- Accept or reject pending player join requests to a shared base
    if ((elemName == "accept_player_request") or (elemName == "reject_player_request")) then

        if ((event.element.parent.join_queue_dropdown == nil) or
            (event.element.parent.join_queue_dropdown.selected_index == 0)) then
            player.print({"oarc-selected-player-not-wait"})
            FakeTabChangeEventOarcGui(player)
            return
        end

        local joinQueueIndex = event.element.parent.join_queue_dropdown.selected_index
        local joinQueuePlayerChoice = event.element.parent.join_queue_dropdown.get_item(joinQueueIndex)

        if ((game.players[joinQueuePlayerChoice] == nil) or
            (not game.players[joinQueuePlayerChoice].connected)) then
            player.print({"oarc-selected-player-not-wait"})
            FakeTabChangeEventOarcGui(player)
            return
        end

        if (elemName == "reject_player_request") then
            player.print({"oarc-reject-joiner", joinQueuePlayerChoice})
            SendMsg(joinQueuePlayerChoice, {"oarc-your-request-rejected"})
            FakeTabChangeEventOarcGui(player)

            -- Close the waiting players menu
            if (game.players[joinQueuePlayerChoice].gui.screen.join_shared_spawn_wait_menu) then
                game.players[joinQueuePlayerChoice].gui.screen.join_shared_spawn_wait_menu.destroy()
                DisplaySpawnOptions(game.players[joinQueuePlayerChoice])
            end

            -- Find and remove the player from the joinQueue they were in.
            for index,requestingPlayer in pairs(global.ocore.sharedSpawns[player.name].joinQueue) do
                if (requestingPlayer == joinQueuePlayerChoice) then
                    global.ocore.sharedSpawns[player.name].joinQueue[index] = nil
                    return
                end
            end

        elseif (elemName == "accept_player_request") then

            -- Find and remove the player from the joinQueue they were in.
            for index,requestingPlayer in pairs(global.ocore.sharedSpawns[player.name].joinQueue) do
                if (requestingPlayer == joinQueuePlayerChoice) then
                    global.ocore.sharedSpawns[player.name].joinQueue[index] = nil
                end
            end
 
            -- If player exists, then do stuff.
            if (game.players[joinQueuePlayerChoice]) then
                -- Send an announcement
                SendBroadcastMsg({"oarc-player-joining-base", joinQueuePlayerChoice, player.name})

                -- Close the waiting players menu
                if (game.players[joinQueuePlayerChoice].gui.screen.join_shared_spawn_wait_menu) then
                    game.players[joinQueuePlayerChoice].gui.screen.join_shared_spawn_wait_menu.destroy()
                end


                -- Spawn the player
                local joiningPlayer = game.players[joinQueuePlayerChoice]

                local baseOwnerPlayer = game.players[player.name]
                -- auto generate location of spawn - UPTO 4 additional players (E, SE, S) for buddies
                local landTileArea = global.ocfg.spawn_config.gen_settings.land_area_tiles               
                local spawnPosOffset={0,0}

                local numBuddiesJoined = #global.ocore.sharedSpawns[baseOwnerPlayer.name].players
                local distanceBetweenSpawns = DISTANCE_BETWEEN_SPAWNS
                log("Spawn Buddy: " .. ({[0]='East', 'South-East', 'South'})[numBuddiesJoined])
                if distanceBetweenSpawns<10 then distanceBetweenSpawns=5 end
                if distanceBetweenSpawns>20 then distanceBetweenSpawns=20 end
                if  numBuddiesJoined== 0 then
                    spawnPosOffset={x=landTileArea * distanceBetweenSpawns, y=0}    -- east
                elseif numBuddiesJoined == 1 then
--                    spawnPosOffset={x=landTileArea * -distanceBetweenSpawns, y=0} -- west
                    spawnPosOffset={x=landTileArea * distanceBetweenSpawns, y=landTileArea * distanceBetweenSpawns} -- south-east
                elseif numBuddiesJoined == 2 then
                    spawnPosOffset={x=0, y=landTileArea * distanceBetweenSpawns}    -- south
--                    spawnPosOffset={x=0, y=landTileArea * -distanceBetweenSpawns} -- north
                else
                    player.print({"oarc-reject-joiner", joinQueuePlayerChoice})
                    SendMsg(joinQueuePlayerChoice, {"oarc-your-request-rejected"})
                    return
                end

                SpawnBuddyIntoAdjoiningBase(joiningPlayer, baseOwnerPlayer, false, spawnPosOffset)
                
--                ChangePlayerSpawn(joiningPlayer, global.ocore.sharedSpawns[player.name].position)
                if global.players[joiningPlayer.index].characterMode then
--                    joiningPlayer.insert{name="power-armor", count = 1}
                    joiningPlayer.insert{name = "firearm-magazine", count = 20}
                end
--                SendPlayerToSpawn(joiningPlayer)
                GivePlayerStarterItems(joiningPlayer)
--                table.insert(global.ocore.sharedSpawns[player.name].players, joiningPlayer.name)  -- done in SpawnBuddyIntoAdjoiningBase
--                joiningPlayer.force = game.players[player.name].force
                global.spawn[joiningPlayer.index] = global.spawn[game.players[player.name].index]       -- vf update the global.spawn table, so when one dies, both die

                -- Unlock spawn control gui tab
                SetOarcGuiTabEnabled(joiningPlayer, OARC_SPAWN_CTRL_GUI_NAME, true)
                HideOarcGui(baseOwnerPlayer)
            else
                SendBroadcastMsg({"oarc-player-left-while-joining", joinQueuePlayerChoice})
            end
        end
    end
end

-- Refresh buddy list
function refreshBuddyList(player)
    local waiting_buddies_dropdown = player.gui.screen.buddy_spawn_opts.spawn_buddy_flow.waiting_buddies_dropdown
    local index=0
    waiting_buddies_dropdown.clear_items()
    log ("Refresh buddy list - refreshed by: " .. player.name)
    for _,buddyName in pairs(global.ocore.waitingBuddies) do
        if (player.name == buddyName) then
            log ("buddy list refreshed by " .. player.name)
        else
            log ("Adding " .. buddyName .. " to my waiting_buddies_dropdown, index of " .. game.players[buddyName].index)
            waiting_buddies_dropdown.add_item(buddyName)
            index=game.players[buddyName].index
        end
    end
--    log ("buddy index: " .. index)
--    log("contents of waitingBuddies list")
--    for _,buddyName in pairs(global.ocore.waitingBuddies) do
--        log("    " .. buddyName)
--    end
    if #waiting_buddies_dropdown.items >0 then
        waiting_buddies_dropdown.selected_index = 1
    end
end


-- Display the buddy spawn menu
function DisplayBuddySpawnOptions(player)
    local buddyGui = player.gui.screen.add{name = "buddy_spawn_opts",
                            type = "frame",
                            direction = "vertical",
                            caption={"oarc-buddy-spawn-options"}}
    buddyGui.auto_center = true
    buddyGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    buddyGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    AddLabel(buddyGui, "buddy_info_msg", {"oarc-buddy-spawn-instructions"}, my_label_style)
    AddSpacer(buddyGui)

    -- The buddy spawning options.
    local buddySpawnFlow = buddyGui.add{name = "spawn_buddy_flow",
                                    type = "frame",
                                    direction="vertical",
                                    style = "bordered_frame"}

    buddyList = {}
    for _,buddyName in pairs(global.ocore.waitingBuddies) do
        if (buddyName ~= player.name) then
            table.insert(buddyList, buddyName)
        end
    end
    AddLabel(buddySpawnFlow, "drop_down_msg_lbl1", {"oarc-buddy-select-info"}, my_label_style)
    buddySpawnFlow.add{name = "waiting_buddies_dropdown",
                    type = "drop-down",     -- "list-box"
                    items = buddyList}

-- removed since this is now automatic
--    buddySpawnFlow.add{name = "refresh_buddy_list",
--                    type = "button",
--                    caption={"oarc-buddy-refresh"}}
    -- AddSpacerLine(buddySpawnFlow)

    -- Allow picking of teams
    if (global.ocfg.enable_separate_teams) then
-- removed because 1) causes mismatch of characterMode 2) Players didn't like it being here
--        buddySpawnFlow.add{name = "buddy_spawn_main_team_radio",
--                        type = "radiobutton",
--                        caption={"oarc-join-main-team-radio"},
--                        state=true}
        local buddy = getBuddy(player)
        ntState=false
        btState=true
        if buddy then
            ntState=buddy.gui.screen.buddy_spawn_opts.spawn_buddy_flow.buddy_spawn_new_team_radio.state
            btState=buddy.gui.screen.buddy_spawn_opts.spawn_buddy_flow.buddy_spawn_buddy_team_radio.state
        end
        buddySpawnFlow.add{name = "buddy_spawn_new_team_radio",
                        type = "radiobutton",
                        caption={"oarc-create-own-team-radio"},
                        state=ntState}
        buddySpawnFlow.add{name = "buddy_spawn_buddy_team_radio",
                        type = "radiobutton",
                        caption={"oarc-create-buddy-team"},
                        state=btState}
    end
    if (global.ocfg.spawn_config.gen_settings.moat_choice_enabled) then
        buddySpawnFlow.add{name = "buddy_spawn_moat_option_checkbox",
                        type = "checkbox",
                        caption={"oarc-moat-option"},
                        state=global.players[player.index].moatChoice}
    end

    buddySpawnFlow.add{name = "character_mode_option_checkbox",
                type = "checkbox",
                caption={"bno-mode-option"},
                state=global.players[player.index].characterMode}

    -- AddSpacerLine(buddySpawnFlow)
    buddySpawnFlow.add{name = "buddy_spawn_request_near",
                    type = "button",
                    caption={"oarc-buddy-spawn-near"},
                    style = "confirm_button"}
    buddySpawnFlow.add{name = "buddy_spawn_request_far",
                    type = "button",
                    caption={"oarc-buddy-spawn-far"},
                    style = "confirm_button"}

    AddSpacer(buddyGui)
    buddyGui.add{name = "buddy_spawn_cancel",
                    type = "button",
                    caption={"oarc-cancel-return-to-previous"},
                    style = "back_button"}

    -- Some final notes
    AddSpacerLine(buddyGui)
    if (global.ocfg.max_players_shared_spawn > 0) then
        AddLabel(buddyGui, "buddy_max_players_lbl1",
                {"oarc-max-players-shared-spawn", global.ocfg.max_players_shared_spawn-1},
                my_note_style)
    end
    local spawn_distance_notes={"oarc-spawn-dist-notes", global.ocfg.near_dist_start, global.ocfg.near_dist_end, global.ocfg.far_dist_start, global.ocfg.far_dist_end}
    AddLabel(buddyGui, "note_lbl1", spawn_distance_notes, my_note_style)
    refreshBuddyList(player)
    if (#global.ocore.waitingBuddies)>0 then
        refreshBuddyList(game.players[global.ocore.waitingBuddies[1]])   -- only one other player in the menu when you join, it has to be [1]
    end
end

-- Handle the gui click of the spawn options
function BuddySpawnOptsGuiClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local elemName = event.element.name
log("BuddySpawnOptsGuiClick element name: " .. elemName .. ", player: ".. player.name)    

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.screen.buddy_spawn_opts == nil) then
        return -- Gui event unrelated to this gui.
    end

    -- Just refresh the buddy list dropdown values only.
    if (elemName == "refresh_buddy_list") then
        refreshBuddyList(player)
        return
    end

    -- Handle the cancel button to exit this menu
    if (elemName == "buddy_spawn_cancel") then
        log(player.name .. " left buddy spawn")
        game.print({"oarc-buddy-cancel-request", player.name})
        player.gui.screen.buddy_spawn_opts.spawn_buddy_flow.waiting_buddies_dropdown.clear_items()
        -- now clear the list for the other player in buddy spawn
        player.gui.screen.buddy_spawn_opts.destroy()

        DisplaySpawnOptions(player)

        -- Remove them from the buddy list when they cancel
        for i=#global.ocore.waitingBuddies,1,-1 do
            if (global.ocore.waitingBuddies[i] == player.name) then
                table.remove(global.ocore.waitingBuddies, i)
            end
        end                    
        local buddy = getBuddy(player)
        if (buddy ~= nil) then
            buddy.gui.screen.buddy_spawn_opts.spawn_buddy_flow.waiting_buddies_dropdown.clear_items()
        end
    end

    if elemName == "buddy_spawn_moat_option_checkbox" then
        global.players[player.index].moatChoice=player.gui.screen.buddy_spawn_opts.spawn_buddy_flow.buddy_spawn_moat_option_checkbox.state
    end


    local joinMainTeamRadio, joinOwnTeamRadio, joinBuddyTeamRadio, moatChoice = false
    local buddyChoice = nil

    -- Handle the spawn request button clicks
    if ((elemName == "buddy_spawn_request_near") or
        (elemName == "buddy_spawn_request_far")) then

        local buddySpawnGui = player.gui.screen.buddy_spawn_opts.spawn_buddy_flow

        local dropDownIndex = buddySpawnGui.waiting_buddies_dropdown.selected_index
        if ((dropDownIndex > 0) and (dropDownIndex <= #buddySpawnGui.waiting_buddies_dropdown.items)) then
            buddyChoice = buddySpawnGui.waiting_buddies_dropdown.get_item(dropDownIndex)
        else
            player.print({"oarc-invalid-buddy"})
            return
        end

        local buddyIsStillWaiting = false
        for _,buddyName in pairs(global.ocore.waitingBuddies) do
            if (buddyChoice == buddyName) then
                if (game.players[buddyChoice]) then
                    buddyIsStillWaiting = true
                end
                break
            end
        end
        if (not buddyIsStillWaiting) then
            player.print({"oarc-buddy-not-avail"})
            player.gui.screen.buddy_spawn_opts.destroy()
            DisplayBuddySpawnOptions(player)
            return
        end

        if (global.ocfg.enable_separate_teams) then
            -- joinMainTeamRadio = buddySpawnGui.buddy_spawn_main_team_radio.state
            joinMainTeamRadio = false
            joinOwnTeamRadio = buddySpawnGui.buddy_spawn_new_team_radio.state
            joinBuddyTeamRadio = buddySpawnGui.buddy_spawn_buddy_team_radio.state
        else
            joinMainTeamRadio = false
            joinOwnTeamRadio = false
            joinBuddyTeamRadio = true
        end
        if (global.ocfg.spawn_config.gen_settings.moat_choice_enabled) then
            moatChoice =  buddySpawnGui.buddy_spawn_moat_option_checkbox.state
            global.players[player.index].moatChoice = moatChoice
        end

        -- Save the chosen spawn options somewhere for later use.
        global.ocore.buddySpawnOpts[player.name] = {joinMainTeamRadio=joinMainTeamRadio,
                                                    joinOwnTeamRadio=joinOwnTeamRadio,
                                                    joinBuddyTeamRadio=joinBuddyTeamRadio,
                                                    buddyChoice=buddyChoice,
                                                    distChoice=elemName}
        player.gui.screen.buddy_spawn_opts.destroy()

        -- Display prompts to the players
        DisplayBuddySpawnWaitMenu(player)
        DisplayBuddySpawnRequestMenu(game.players[buddyChoice], player.name)
        if (game.players[buddyChoice].gui.screen.buddy_spawn_opts ~= nil) then
            game.players[buddyChoice].gui.screen.buddy_spawn_opts.destroy()
        end

        -- Remove them from the buddy list while they make up their minds.
        for i=#global.ocore.waitingBuddies,1,-1 do
            name = global.ocore.waitingBuddies[i]
            if ((name == player.name) or (name == buddyChoice)) then
                table.remove(global.ocore.waitingBuddies, i)
            end
        end

    else
        return -- Do nothing, no valid element item was clicked.
    end
end


function DisplayBuddySpawnWaitMenu(player)

    local sGui = player.gui.screen.add{name = "buddy_wait_menu",
                            type = "frame",
                            direction = "vertical",
                            caption={"oarc-waiting-for-buddy"}}
    sGui.auto_center = true
    sGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    sGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    AddLabel(sGui, "warning_lbl1", {"oarc-wait-buddy-select-yes"}, my_warning_style)
    AddSpacer(sGui)
    sGui.add{name = "cancel_buddy_wait_menu",
                    type = "button",
                    caption={"oarc-cancel-return-to-previous"}}
end

-- Handle the gui click of the buddy wait menu
function BuddySpawnWaitMenuClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local elemName = event.element.name

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    if (player.gui.screen.buddy_wait_menu == nil) then
        return -- Gui event unrelated to this gui.
    end

    -- Check if player is cancelling the request.
    if (elemName == "cancel_buddy_wait_menu") then
        player.gui.screen.buddy_wait_menu.destroy()
        DisplaySpawnOptions(player)

        local buddy = nil
        if #global.ocore.waitingBuddies >0 then  -- Any buddies in buddy spawn menu ?
            buddy = game.players[global.ocore.buddySpawnOpts[player.name].buddyChoice]
        end

        -- Catch a case where the buddy has left the game early and no longer exists.
        if (buddy == nil) then
            return
        end

        if (buddy.gui.screen.buddy_request_menu ~= nil) then
            buddy.gui.screen.buddy_request_menu.destroy()
        end
        if (buddy.gui.screen.buddy_spawn ~= nil) then
            buddy.gui.screen.buddy_spawn_opts.spawn_buddy_flow.waiting_buddies_dropdown.clear_items()
            buddy.gui.screen.buddy_spawn_opts.destroy()
        end
        DisplaySpawnOptions(buddy)

        buddy.print({"oarc-buddy-cancel-request", player.name})
    end
end

function DisplayBuddySpawnRequestMenu(player, requestingBuddyName)

    if not player then
        log("Another gui click happened with no valid player...")
        return
    end

    local sGui = player.gui.screen.add{name = "buddy_request_menu",
                            type = "frame",
                            direction = "vertical",
                            caption="Buddy Request!"}
    sGui.auto_center = true
    sGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    sGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    AddLabel(sGui, "warning_lbl1", {"oarc-buddy-requesting-from-you", requestingBuddyName}, my_warning_style)

    local teamText = "error!"
    if (global.ocore.buddySpawnOpts[requestingBuddyName].joinMainTeamRadio) then
        teamText = {"oarc-buddy-txt-main-team"}
    elseif (global.ocore.buddySpawnOpts[requestingBuddyName].joinOwnTeamRadio) then
        teamText = {"oarc-buddy-txt-new-teams"}
    elseif (global.ocore.buddySpawnOpts[requestingBuddyName].joinBuddyTeamRadio) then
        teamText = {"oarc-buddy-txt-buddy-team"}
    end

    local moatText = " "
    if (global.players[player.index].moatChoice) then
        moatText = {"oarc-buddy-txt-moat"}
    end

    local distText = "error!"
    if (global.ocore.buddySpawnOpts[requestingBuddyName].distChoice == "buddy_spawn_request_near") then
        distText = {"oarc-buddy-txt-near"}
    elseif (global.ocore.buddySpawnOpts[requestingBuddyName].distChoice == "buddy_spawn_request_far") then
        distText = {"oarc-buddy-txt-far"}
    end


    local requestText = {"", requestingBuddyName, {"oarc-buddy-txt-would-like"}, teamText, {"oarc-buddy-txt-next-to-you"}, moatText, distText}
    AddLabel(sGui, "note_lbl1", requestText, my_warning_style)
    AddSpacer(sGui)


    sGui.add{name = "accept_buddy_request",
                    type = "button",
                    caption={"oarc-accept"}}
    sGui.add{name = "decline_buddy_request",
                    type = "button",
                    caption={"oarc-reject"}}
end

-- Spawn a buddy into a buddy base next to yours
function SpawnBuddyIntoAdjoiningBase(joiningPlayer, baseOwnerPlayer, joinOwnTeam, offsetPosParam)
    local baseOwnerSpawnPos=global.ocore.playerSpawns[baseOwnerPlayer.name]

    if offsetPosParam==nil then 
        offsetPos = {x=global.ocfg.spawn_config.gen_settings.land_area_tiles*DISTANCE_BETWEEN_SPAWNS, y=0} 
    else
        offsetPos = offsetPosParam
    end
    -- Create a new force for each player if they chose that option
    if joinOwnTeam then
        -- Create a new force for the combined players if they chose that option
        local newForce = CreatePlayerCustomForce(joiningPlayer)            
    else
--        joiningPlayer.force = CreatePlayerCustomForce(baseOwnerPlayer)
        joiningPlayer.force = game.players[baseOwnerPlayer.name].force
    end
    log("SpawnBuddyIntoAdjoiningBase - joining own team: " .. tostring(joinOwnTeam) .. ", base owner: " .. baseOwnerPlayer.name .. ", Force: " .. joiningPlayer.force.name .. ", baseOwnerSpawnPos = " .. GetGPStext(baseOwnerSpawnPos))
    -- Create that spawn in the global vars
    -- buddy spawns 6 * land_area_tiles (2.5 chunks)
    local buddySpawnPos = {x=(baseOwnerSpawnPos.x + offsetPos.x), y=(baseOwnerSpawnPos.y + offsetPos.y)} 
    ChangePlayerSpawn(joiningPlayer, buddySpawnPos)
    -- Send the joiningPlayer there - each have their potentially different moat choices
    QueuePlayerForDelayedSpawn(joiningPlayer.name, buddySpawnPos, global.players[joiningPlayer.index].moatChoice, false)
    -- Unlock spawn control gui tab
    global.ocore.buddyPairs[joiningPlayer.name] = baseOwnerPlayer.name
    if (not global.ocore.sharedSpawns[baseOwnerPlayer.name]) then
        CreateNewSharedSpawn(baseOwnerPlayer)
    end
    table.insert(global.ocore.sharedSpawns[baseOwnerPlayer.name].players, joiningPlayer.name)   -- keep track of all players on a team
    SetOarcGuiTabEnabled(joiningPlayer, OARC_SPAWN_CTRL_GUI_NAME, true)
    joiningPlayer.print({"oarc-please-wait"})
    joiningPlayer.print({"", {"oarc-please-wait"}, "!"})
    joiningPlayer.print({"", {"oarc-please-wait"}, "!!"})
    global.players[joiningPlayer.index].inSpawn=false
end


-- Handle the gui click of the buddy request menu
function BuddySpawnRequestMenuClick(event)
    if not (event and event.element and event.element.valid) then return end
    local joiningPlayer = game.players[event.player_index]
    local elemName = event.element.name
    local requesterName = nil
    local requesterOptions = {}

    if not joiningPlayer then
        log("Another gui click happened with no valid player...")
        return
    end

    if (joiningPlayer.gui.screen.buddy_request_menu == nil) then
        return -- Gui event unrelated to this gui.
    end


    -- Check if it's a button press and lookup the matching buddy info
    if ((elemName == "accept_buddy_request") or (elemName == "decline_buddy_request")) then
        for name,opts in pairs(global.ocore.buddySpawnOpts) do
            if (opts.buddyChoice == joiningPlayer.name) then
                requesterName = name
                requesterOptions = opts
            end
        end

        -- Not sure about this error condition...
        if (requesterName == nil) then
            SendBroadcastMsg("Error! Invalid buddy info???")
            log("Error! Invalid buddy info...")

            joiningPlayer.gui.screen.buddy_request_menu.destroy()
            DisplaySpawnOptions(joiningPlayer)
            return
        end
    else
        return -- Not a button click
    end

    -- Handle player accepted
    if (elemName == "accept_buddy_request") then

        if (game.players[requesterName].gui.screen.buddy_wait_menu ~= nil) then
            game.players[requesterName].gui.screen.buddy_wait_menu.destroy()
        end
        if (joiningPlayer.gui.screen.buddy_request_menu ~= nil) then
            joiningPlayer.gui.screen.buddy_request_menu.destroy()
        end
        local baseOwnerPlayer = game.players[requesterName]
        local joinOwnTeam = requesterOptions.joinOwnTeamRadio
        local farSpawn=requesterOptions.distChoice == "buddy_spawn_request_far"

        -- make base for primary player
        -- Create a new force for each player if they chose that option
        if joinOwnTeam then
            -- Create a new force for the combined players if they chose that option
            local buddyForce = CreatePlayerCustomForce(baseOwnerPlayer)
        end
        -- Create a new spawn point
        local newSpawn = {x=0,y=0}

        -- Create a new force for each player if they chose that option
        if requesterOptions.joinOwnTeamRadio then
            local newForce = CreatePlayerCustomForce(player)
            local buddyForce = CreatePlayerCustomForce(game.players[requesterName])

        -- Create a new force for the combined players if they chose that option
        elseif requesterOptions.joinBuddyTeamRadio then
            local buddyForce = CreatePlayerCustomForce(game.players[requesterName])
            joiningPlayer.force = buddyForce
        end

        -- Find coordinates of a good place to spawn
        if (farSpawn) then
            newSpawn = FindUngeneratedCoordinates(global.ocfg.far_dist_start,global.ocfg.far_dist_end, joiningPlayer.surface)
        else    -- near spawn
            newSpawn = FindUngeneratedCoordinates(global.ocfg.near_dist_start,global.ocfg.near_dist_end, joiningPlayer.surface)
        end
        -- If that fails, find a random map edge in a rand direction.
        if ((newSpawn.x == 0) and (newSpawn.x == 0)) then
            newSpawn = FindMapEdge(GetRandomVector(), joiningPlayer.surface)
            log("Resorting to find map edge! x=" .. newSpawn.x .. ",y=" .. newSpawn.y)
        end
        ChangePlayerSpawn(baseOwnerPlayer, newSpawn)
        -- Send the joiningPlayer there - each have their potentially different moat choices
        QueuePlayerForDelayedSpawn(requesterName, newSpawn, global.players[baseOwnerPlayer.index].moatChoice, false)
        log ("SpawnBuddyIntoAdjoiningBase: joiningPlayer " .. joiningPlayer.name .. ", baseOwner : " .. baseOwnerPlayer.name .. ", joinOwnTeam: " .. tostring(joinOwnTeam))
        SpawnBuddyIntoAdjoiningBase(joiningPlayer, baseOwnerPlayer, joinOwnTeam)
        SendBroadcastMsg(requesterName .. " and " .. joiningPlayer.name .. " are joining the game together!")

        -- Unlock spawn control gui tab
        SetOarcGuiTabEnabled(baseOwnerPlayer, OARC_SPAWN_CTRL_GUI_NAME, true)

        baseOwnerPlayer.print({"oarc-please-wait"})
        baseOwnerPlayer.print({"", {"oarc-please-wait"}, "!"})
        baseOwnerPlayer.print({"", {"oarc-please-wait"}, "!!"})
        global.ocore.buddyPairs[joiningPlayer.name] = requesterName
        global.players[baseOwnerPlayer.index].inSpawn=false


    -- Check if player is cancelling the request.
    elseif (elemName == "decline_buddy_request") then
        joiningPlayer.gui.screen.buddy_request_menu.destroy()
        DisplaySpawnOptions(joiningPlayer)

        local requesterBuddy = game.players[requesterName]

        if (requesterBuddy.gui.screen.buddy_wait_menu ~= nil) then
            requesterBuddy.gui.screen.buddy_wait_menu.destroy()
        end
        if (requesterBuddy.gui.screen.buddy_spawn ~= nil) then
            requesterBuddy.gui.screen.buddy_spawn_opts.destroy()
        end
        DisplaySpawnOptions(requesterBuddy)

        requesterBuddy.print({"oarc-buddy-declined", joiningPlayer.name})
    end

    global.ocore.buddySpawnOpts[requesterName] = nil
end


function DisplayPleaseWaitForSpawnDialog(player, delay_seconds)

    local pleaseWaitGui = player.gui.screen.add{name = "wait_for_spawn_dialog",
                            type = "frame",
                            direction = "vertical",
                            caption={"oarc-spawn-wait"}}
    pleaseWaitGui.auto_center = true
    pleaseWaitGui.style.maximal_width = SPAWN_GUI_MAX_WIDTH
    pleaseWaitGui.style.maximal_height = SPAWN_GUI_MAX_HEIGHT


    -- Warnings and explanations...
    local wait_warning_text = {"oarc-wait-text", delay_seconds}

    AddLabel(pleaseWaitGui, "warning_lbl1", wait_warning_text, my_warning_style)
end
