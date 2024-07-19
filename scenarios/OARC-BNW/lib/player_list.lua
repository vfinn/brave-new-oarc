-- oarc_player_list.lua
-- Mar 2019

--------------------------------------------------------------------------------
-- Player List GUI - My own version
--------------------------------------------------------------------------------
function CreatePlayerListGuiTab(tab_container, player)
    local scrollFrame = tab_container.add{type="scroll-pane",
                                    name="playerList-panel",
                                    direction = "vertical"}
    local charMode
    ApplyStyle(scrollFrame, my_player_list_fixed_width_style)
    scrollFrame.horizontal_scroll_policy = "never"

    AddLabel(scrollFrame, "online_title_msg", "Online Players:", my_label_header_style)
    for indx,player in pairs(game.connected_players) do
        if global.players[player.index].characterMode then 
            charMode = "Character" 
        else
            charMode = "Brave New Player"
        end
        local forceName = player.force.name
        if global.players[player.index].inSpawn then
            forceName = "In Spawn"
        end
        local caption_str = player.name.." ["..forceName.."]".." ("..formattime_hours_mins(player.online_time)..")    ".. charMode
        if (player.admin) then
            AddLabel(scrollFrame, "player:"..player.name, caption_str, my_player_list_admin_style)
        else
            AddLabel(scrollFrame, "player:"..player.name, caption_str, my_player_list_style)
        end
    end

    -- List offline players
    if (global.ocfg.list_offline_players) then
        AddSpacerLine(scrollFrame)
        AddLabel(scrollFrame, "offline_title_msg", "Offline Players:", my_label_header_grey_style)
        for indx,player in pairs(game.players) do
            if global.players[indx].characterMode then 
                charMode = "Character" 
            else
                charMode = "Brave New Player"
            end
            if (not player.connected) then
                local caption_str = player.name.." ["..player.force.name.."]".." ("..formattime_hours_mins(player.online_time)..")    ".. charMode
                local text = scrollFrame.add{type="label", caption=caption_str, name="player:"..player.name}
                ApplyStyle(text, my_player_list_offline_style)
            end
        end
    end
end
