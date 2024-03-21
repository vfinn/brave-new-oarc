-- game_opts.lua
-- Jan 2018
-- Display current game options, maybe have some admin controls here
-- April 2023 - vf made reset playe chooseable for each player, for themselves, and added individual player options: warn of swarm attack

-- Main Configuration File
require("config")
require("lib/oarc_utils")
require("lib/separate_spawns")

function GameOptionsGuiClick(event)
    if not (event and event.element and event.element.valid) then return end
    local player = game.players[event.player_index]
    local name = event.element.name

    if (name == "ban_player") then
        local pIndex = event.element.parent.ban_players_dropdown.selected_index

        if (pIndex ~= 0) then
            local banPlayer = event.element.parent.ban_players_dropdown.get_item(pIndex)
            if (game.players[banPlayer]) then
                game.ban_player(banPlayer, "Banned from admin panel.")
                log("Banning " .. banPlayer)
            end
        end
    end

    if (name == "restart_player") then
        local pIndex = event.element.parent.ban_players_dropdown.selected_index

        if (pIndex ~= 0) then
            local resetPlayerName = event.element.parent.ban_players_dropdown.get_item(pIndex)
            local idx = game.players[resetPlayerName].index
            if (game.players[resetPlayerName]) then
                RemoveOrResetPlayer(game.players[resetPlayerName], false, true, true, true)
                SeparateSpawnsPlayerCreated(resetPlayerName, true)
                if (global.players[idx].drawOnExit) then
                    log("Restarting player - destroy of drawOnExit and all entries for " .. game.players[idx].name .. " value of ".. tostring(global.players[idx].drawOnExit))                  
                    rendering.destroy(global.players[idx].drawOnExit)
                end
                global.players[idx] = {
                                    crafted = {},
                                    inventory_items = {},
                                    previous_position = {x=0, y=0},
                                    drawOnExit = nil,   -- do NOT reset this - the player name rendered is still needed
                                    characterMode = false
                                }
                log("Resetting " .. resetPlayerName)
            end
        end
    end
    if (name == "warn_biter_attack_option_checkbox") then
        if (global.ocfg.warn_biter_setting[event.player_index] == nil) then
            global.ocfg.warn_biter_setting[event.player_index] = true
        else
            global.ocfg.warn_biter_setting[event.player_index] = not global.ocfg.warn_biter_setting[event.player_index]
        end
        local onOff = " OFF"
        if global.ocfg.warn_biter_setting[event.player_index] then onOff = " ON" end
        player.print(player.name .. " changed the 'Warn of biter attacking' option to " .. onOff)
    end
    if (name == "offline_protect") then
        if (global.ocfg.offline_protect[event.player_index] == nil) then 
            global.ocfg.offline_protect[event.player_index] = ENABLE_OFFLINE_PROTECTION 
        end
        global.ocfg.offline_protect [event.player_index] = not global.ocfg.offline_protect [event.player_index];
        local onOff = " OFF"
        if global.ocfg.offline_protect[event.player_index] then onOff = " ON" end
        player.print(player.name .. " changed the 'Protect base from biter attacks while offline' option to " .. onOff)
   end  
   if (name == "decon_miners") then

        local hostSettingForDeconMiners = settings.startup["bno-auto-deconstruct-miners-allowed"].value

        if global.ocfg.enable_miner_decon[player.force.name] ==nil then
            global.ocfg.enable_miner_decon[player.force.name] = ENABLE_MINER_AUTODECON
        end 
        -- Slight change pace here using force.name as index instead of event.player_index - I recommend prosecution and persecution
        global.ocfg.enable_miner_decon [player.force.name] = not  global.ocfg.enable_miner_decon [player.force.name]
        local onOff = " OFF"
        if global.ocfg.enable_miner_decon [player.force.name] then onOff = " ON" end
        player.print(player.name .. " changed the 'Auto Miner Deconstruct' option to " .. onOff)
   end  
  
   
   if (name == "share_chart_checkbox") then
        if (global.ocfg.share_chart[event.player_index] == nil) then
            global.ocfg.share_chart[event.player_index] = true
        end
        global.ocfg.share_chart[event.player_index] = not global.ocfg.share_chart[event.player_index]
        local onOff = " OFF"
        if global.ocfg.share_chart[event.player_index] then 
            onOff = " ON" 
            player.force.share_chart=true    
        else
            player.force.share_chart=false    
        end
        player.print(player.name .. " changed the 'Sharing of Chart' option to " .. onOff)
    end

end

-- Used by AddOarcGuiTab
function CreateGameOptionsTab(tab_container, player)

    if global.oarc_announcements ~= nil then
        AddLabel(tab_container, "announcement_info_label", "Server announcements:", my_label_header_style)
        AddLabel(tab_container, "announcement_info_txt", global.oarc_announcements, my_longer_label_style)
        AddSpacerLine(tab_container)
    end

    -- General Server Info:
    AddLabel(tab_container, "info_1", global.ocfg.welcome_msg, my_longer_label_style)
    AddLabel(tab_container, "info_2", global.ocfg.server_rules, my_longer_label_style)
    AddLabel(tab_container, "info_3", global.ocfg.server_contact, my_longer_label_style)
    tab_container.add{type="textfield",
                      tooltip="Come join the discord (copy this invite)!",
                      text=DISCORD_INV}
    AddSpacerLine(tab_container)

    -- Enemy Settings:
    local enemy_expansion_txt = "disabled"
    if game.map_settings.enemy_expansion.enabled then enemy_expansion_txt = "enabled" end

-- NO ROOM FOR THIS !
--    local enemy_text="Server Run Time: " .. formattime_hours_mins(game.tick) .. "\n" ..
--    "Current Evolution: " .. string.format("%.4f", game.forces["enemy"].evolution_factor) .. "\n" ..
--    "Enemy evolution time/pollution/destroy factors: " .. game.map_settings.enemy_evolution.time_factor .. "/" ..
--    game.map_settings.enemy_evolution.pollution_factor .. "/" ..
--    game.map_settings.enemy_evolution.destroy_factor .. "\n" ..
--    "Enemy expansion is " .. enemy_expansion_txt
--
--    AddLabel(tab_container, "enemy_info", enemy_text, my_longer_label_style)
--    AddSpacerLine(tab_container)

    -- Soft Mods:
    local soft_mods_string = "Oarc Core"
    if (global.ocfg.enable_undecorator) then
        soft_mods_string = soft_mods_string .. ", Undecorator"
    end
    if (global.ocfg.enable_tags) then
        soft_mods_string = soft_mods_string .. ", Tags"
    end
    if (global.ocfg.enable_long_reach) then
        soft_mods_string = soft_mods_string .. ", Long Reach"
    end
    if (global.ocfg.enable_autofill) then
        soft_mods_string = soft_mods_string .. ", Auto Fill"
    end
    if (global.ocfg.enable_player_list) then
        soft_mods_string = soft_mods_string .. ", Player List"
    end
    if (global.ocfg.enable_regrowth) then
        soft_mods_string = soft_mods_string .. ", Regrowth"
    end
    if (global.ocfg.enable_chest_sharing) then
        soft_mods_string = soft_mods_string .. ", Item & Energy Sharing"
    end
    if (global.ocfg.enable_magic_factories) then
        soft_mods_string = soft_mods_string .. ", Special Map Chunks"
    end
    if (global.ocfg.offline_protect[player.index]) then
        soft_mods_string = soft_mods_string .. ", Offline Attack Inhibitor"
    end

    local game_info_str = "Soft Mods: " .. soft_mods_string

    -- Spawn options:
    if (global.ocfg.enable_separate_teams) then
        game_info_str = game_info_str.."\n".."You are allowed to spawn on your own team (have your own research tree). All teams are friendly!"
    end
    if (global.ocfg.enable_vanilla_spawns) then
        game_info_str = game_info_str.."\n".."You are spawned in a default style starting area."
    else
        game_info_str = game_info_str.."\n".."You are spawned with a fix set of starting resources."
        if (global.ocfg.enable_buddy_spawn) then
            game_info_str = game_info_str.."\n".."You can chose to spawn alongside a buddy if you spawn together at the same time."
        end
    end
    if (global.ocfg.enable_shared_spawns) then
        game_info_str = game_info_str.."\n".."Spawn hosts may choose to share their spawn and allow other players to join them."
    end
    if (global.ocfg.enable_separate_teams and global.ocfg.enable_shared_team_vision) then
        game_info_str = game_info_str.."\n".."Everyone (all teams) have shared vision."
    end
    if (global.ocfg.frontier_rocket_silo) then
        game_info_str = game_info_str.."\n".."Silos are only placeable in certain areas on the map!"
    end
    if (global.ocfg.enable_regrowth) then
        game_info_str = game_info_str.."\n".."Old parts of the map will slowly be deleted over time (chunks without any player buildings)."
    end
    if (global.ocfg.enable_power_armor_start or global.ocfg.enable_modular_armor_start) then
        game_info_str = game_info_str.."\n".."Quicker start enabled."
    end
    if (global.ocfg.lock_goodies_rocket_launch) then
        game_info_str = game_info_str.."\n".."Some technologies and recipes are locked until you launch a rocket!"
    end

    if (global.ocfg.enable_abandoned_base_removal) then
        AddLabel(tab_container, "leave_warning_msg", "If you leave within " .. global.ocfg.minimum_online_time .. " minutes of joining, your base and character will be deleted.", my_longer_label_style)
        tab_container.leave_warning_msg.style.font_color=my_color_red
    end

    -- Ending Spacer
    AddSpacerLine(tab_container)

    -- ADMIN CONTROLS
    if (player.admin) then
        local si=1
        player_list = {}
        for k,p in pairs(game.players) do  -- game.connected_players   <-- previously only connected players
            table.insert(player_list, p.name)
            if p.name == player.name then si = k end
        end
        -- If we have more than ME in the game - enable RESTART button
        if #game.players>1 or not (player.position.x==0 and player.position.y==0) then 
            tab_container.add{name="restart_player", type="button", caption="Restart Player"}
        end
        tab_container.add{name="ban_player", type="button", caption="Ban Player"}
        tab_container.add{name="ban_players_dropdown",type = "drop-down",items = player_list, selected_index = si}
    else
        if not (player.position.x==0 and player.position.y==0) then 
            tab_container.add{name="restart_player", type="button", caption="Restart Player"}
        end
        player_list = {}
        table.insert(player_list, player.name)
        tab_container.add{name = "ban_players_dropdown",type = "drop-down",items = player_list, selected_index = 1}
--        tab_container.selected_index(1)
    end
    -- Ending Spacer
    if (player.index) then
        AddSpacerLine(tab_container)
        AddLabel(tab_container, "individual_user_settings2", "Individual User Settings:", my_label_header_style)
        if (global.ocfg.warn_biter_setting[player.index] == nil) then
            global.ocfg.warn_biter_setting[player.index] = true;
        end
        tab_container.add{name = "warn_biter_attack_option_checkbox",
                        type = "checkbox",
                        caption={"warn-biter-attack-option"},
                        state=(global.ocfg.warn_biter_setting[player.index])}
        if (global.ocfg.offline_protect[player.index] == nil) then
            global.ocfg.offline_protect [player.index] = ENABLE_OFFLINE_PROTECTION
        end
        tab_container.add{name = "offline_protect",
                        type = "checkbox",
                        caption={"offline-biter-attack-protect"},
                        state=(global.ocfg.offline_protect[player.index])}
        if (global.ocfg.share_chart[player.index] == nil) then
            global.ocfg.share_chart[player.index] = true;
        end
        tab_container.add{name = "share_chart_checkbox",
                        type = "checkbox",
                        caption={"bno-share-chart"},
                        state=(global.ocfg.share_chart[player.index])}

        if global.ocfg.enable_miner_decon[player.force.name] == nil then
            global.ocfg.enable_miner_decon[player.force.name] = ENABLE_MINER_AUTODECON
        end
        if (settings.startup["bno-auto-deconstruct-miners-allowed"].value) then
            tab_container.add{name = "decon_miners",
                            type = "checkbox",
                            caption={"decon-empty-miners"},
                            state=(global.ocfg.enable_miner_decon[player.force.name])}
        end
    end
end