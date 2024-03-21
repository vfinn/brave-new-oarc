-- admin_commands.lua
-- May 2019
-- 
-- Yay, admin commands!

require("lib/oarc_utils")

-- name :: string: Name of the command.
-- tick :: uint: Tick the command was used.
-- player_index :: uint (optional): The player who used the command. It will be missing if run from the server console.
-- parameter :: string (optional): The parameter passed after the command, separated from the command by 1 space.

-- Give yourself or another player, power armor
commands.add_command("give-power-armor-kit", "give a start kit", function(command)
    
    local player = game.players[command.player_index]
    local target = player
    
    if player ~= nil and player.admin then
        if (command.parameter ~= nil) then
        	if game.players[command.parameter] ~= nil then
        		target = game.players[command.parameter]
        	else
        		target.print("Invalid player target. Double check the player name?")
        		return
        	end
        end

        GiveQuickStartPowerArmor(target)
        player.print("Gave a powerstart kit to " .. target.name)
        target.print("You have been given a power armor starting kit!")
    end
end)


commands.add_command("give-test-kit", "give a start kit", function(command)
    
    local player = game.players[command.player_index]
    local target = player
    
    if player ~= nil and player.admin then
        if (command.parameter ~= nil) then
            if game.players[command.parameter] ~= nil then
                target = game.players[command.parameter]
            else
                target.print("Invalid player target. Double check the player name?")
                return
            end
        end

        GiveTestKit(target)
        player.print("Gave a test kit to " .. target.name)
        target.print("You have been given a test kit!")
    end
end)


commands.add_command("load-quickbar", "Pre-load quickbar shortcuts", function(command)

    local p = game.players[command.player_index]

    -- 1st Row
    p.set_quick_bar_slot(1, "transport-belt");
    p.set_quick_bar_slot(2, "small-electric-pole");
    p.set_quick_bar_slot(3, "inserter");
    p.set_quick_bar_slot(4, "underground-belt");
    p.set_quick_bar_slot(5, "splitter");

    p.set_quick_bar_slot(6, "coal");
    p.set_quick_bar_slot(7, "repair-pack");
    p.set_quick_bar_slot(8, "gun-turret");
    p.set_quick_bar_slot(9, "stone-wall");
    p.set_quick_bar_slot(10, "radar");

    -- 2nd Row
    p.set_quick_bar_slot(11, "stone-furnace");
    p.set_quick_bar_slot(12, "wooden-chest");
    p.set_quick_bar_slot(13, "steel-chest");
    p.set_quick_bar_slot(14, "assembling-machine-1");
    p.set_quick_bar_slot(15, "assembling-machine-2");

    p.set_quick_bar_slot(16, nil);
    p.set_quick_bar_slot(17, nil);
    p.set_quick_bar_slot(18, nil);
    p.set_quick_bar_slot(19, nil);
    p.set_quick_bar_slot(20, nil);

    -- 3rd Row
    p.set_quick_bar_slot(21, "electric-mining-drill");
    p.set_quick_bar_slot(22, "fast-inserter");
    p.set_quick_bar_slot(23, "long-handed-inserter");
    p.set_quick_bar_slot(24, "medium-electric-pole");
    p.set_quick_bar_slot(25, "big-electric-pole");

    p.set_quick_bar_slot(26, "stack-inserter");
    p.set_quick_bar_slot(27, nil);
    p.set_quick_bar_slot(28, nil);
    p.set_quick_bar_slot(29, nil);
    p.set_quick_bar_slot(30, nil);

    -- 4th Row
    p.set_quick_bar_slot(31, "fast-transport-belt");
    p.set_quick_bar_slot(32, "medium-electric-pole");
    p.set_quick_bar_slot(33, "fast-inserter");
    p.set_quick_bar_slot(34, "fast-underground-belt");
    p.set_quick_bar_slot(35, "fast-splitter");

    p.set_quick_bar_slot(36, "stone-wall");
    p.set_quick_bar_slot(37, "repair-pack");
    p.set_quick_bar_slot(38, "gun-turret");
    p.set_quick_bar_slot(39, "laser-turret");
    p.set_quick_bar_slot(40, "radar");

    -- 5th Row
    p.set_quick_bar_slot(41, "train-stop");
    p.set_quick_bar_slot(42, "rail-signal");
    p.set_quick_bar_slot(43, "rail-chain-signal");
    p.set_quick_bar_slot(44, "rail");
    p.set_quick_bar_slot(45, "big-electric-pole");

    p.set_quick_bar_slot(46, "locomotive");
    p.set_quick_bar_slot(47, "cargo-wagon");
    p.set_quick_bar_slot(48, "fluid-wagon");
    p.set_quick_bar_slot(49, "pump");
    p.set_quick_bar_slot(50, "storage-tank");

    -- 6th Row
    p.set_quick_bar_slot(51, "oil-refinery");
    p.set_quick_bar_slot(52, "chemical-plant");
    p.set_quick_bar_slot(53, "storage-tank");
    p.set_quick_bar_slot(54, "pump");
    p.set_quick_bar_slot(55, nil);

    p.set_quick_bar_slot(56, "pipe");
    p.set_quick_bar_slot(57, "pipe-to-ground");
    p.set_quick_bar_slot(58, "assembling-machine-2");
    p.set_quick_bar_slot(59, "pump");
    p.set_quick_bar_slot(60, nil);

    -- 7th Row
    p.set_quick_bar_slot(61, "roboport");
    p.set_quick_bar_slot(62, "logistic-chest-storage");
    p.set_quick_bar_slot(63, "logistic-chest-passive-provider");
    p.set_quick_bar_slot(64, "logistic-chest-requester");
    p.set_quick_bar_slot(65, "logistic-chest-buffer");

    p.set_quick_bar_slot(66, "logistic-chest-active-provider");
    p.set_quick_bar_slot(67, "logistic-robot");
    p.set_quick_bar_slot(68, "construction-robot");
    p.set_quick_bar_slot(69, nil);
    p.set_quick_bar_slot(70, nil);

end)


-- later move into oarc_utils.lua
local function format_number(num)
    num = math.ceil(num)
    if num >= 1000000 then
        return string.format("%dM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%dk", num / 1000)
    else
        return tostring(num)
    end
end

-- merge with oarc_gui_tabs.lua
local function create_gui(player, stats_table, item)
    if player.gui.screen.stats_gui then
        player.gui.screen.stats_gui.destroy()
    end

    local dialog = player.gui.screen.add{
        type = "frame",
        name = "stats_gui",
        caption = "Production statistics for: [img=item/" .. item .. "] " .. item,
        direction = "vertical"
    }
    dialog.auto_center = true

    local scroll_pane = dialog.add{
        type = "scroll-pane",
        vertical_scroll_policy = "auto",
        horizontal_scroll_policy = "auto"
    }
    scroll_pane.style.maximal_height = 400

    local table = scroll_pane.add{
        type = "table",
        column_count = 5
    }


    local headers = {"Force", "1min", "1hr", "1day", "All time"}
    for _, header in ipairs(headers) do
        local label = table.add{type = "label", caption = header}
        label.style.font = "default-bold"
        label.style.font_color = {r = 0, g = 1, b = 0}
        label.style.minimal_width = 120
    end


    for _, stat in ipairs(stats_table) do
        local force_label = table.add{type = "label", caption = stat.force}
        force_label.style.minimal_width = 120
        local minute_label = table.add{type = "label", caption = format_number(stat.last_minute)}
        minute_label.style.minimal_width = 120
        local hour_label = table.add{type = "label", caption = format_number(stat.last_hour)}
        hour_label.style.minimal_width = 120
        local day_label = table.add{type = "label", caption = format_number(stat.last_day)}
        day_label.style.minimal_width = 120
        local all_time_label = table.add{type = "label", caption = format_number(stat.all_time)}
        all_time_label.style.minimal_width = 120
    end

    local sciencePacks = {
        ["automation-science-pack"] = "[tool=automation-science-pack]",
        ["logistic-science-pack"] = "[tool=logistic-science-pack]",
        -- Add more science packs here...
    }
    

    local button = dialog.add{ type= "button", name="stats_close_stats_gui", caption = "Close"}
    for packName, iconPath in pairs(sciencePacks) do
        local button = dialog.add{
            type = "button",
            parent= "button_style",
            name = packName,
            caption = textName,
--            style = "icon_button",
            font_color = {r = 1, g = 0, b = 0},
            sprite = iconPath
        }
        button.style.width = 64
        button.style.height = 32
    end    
--    button.style.font_color = {r = 1, g = 0, b = 0}

    dialog.force_auto_center()
end

-- Function to handle the /stats command
-- author: bits-orio 
commands.add_command("stats", "Statistics for players", function(command)
    local player = game.players[command.player_index]

    local input = command.parameter
    local items = {}
    local itemPattern = '"[^"]+"|[^%s]+'  -- Matches items within quotes or separated by spaces

--    if input==nil then
--        player.print("use: /stat landfill.  For internal names see: https://wiki.factorio.com/Landfill")
--        return
--    end
    

    local search_term = "iron-plate"
    local player = game.player
    if player then
        local best_match = nil
        local shortest_distance = math.huge
        local escaped_search_term = search_term:gsub("([^%w])", "%%%1")
        for name, _ in pairs(game.item_prototypes) do
            if name:find(escaped_search_term) then
                local distance = math.abs(#name - #search_term)
                if not best_match or distance < shortest_distance then
                    best_match = name
                    shortest_distance = distance
                end
            end
        end

        if best_match then
            local item = best_match
            local stats_table = {}
            for _, force in pairs(game.forces) do
                local ignoredalienmodulefactions = { enemy=true, neutral=true, _ABANDONED_=true, _DESTROYED_=true, player=true} 
                if not ignoredalienmodulefactions[force.name] then
                    local stats = force.item_production_statistics
                    local last_minute = stats.get_flow_count{type="input", name=item, precision_index=defines.flow_precision_index.one_minute}
                    local last_hour = stats.get_flow_count{type="input", name=item, precision_index=defines.flow_precision_index.one_hour}
                    local last_day = stats.get_flow_count{type="input", name=item, precision_index=defines.flow_precision_index.one_hour} * 24
                    local all_time = stats.input_counts[item] or 0

                    table.insert(stats_table, {
                        force = force.name,
                        last_minute = last_minute,
                        last_hour = last_hour,
                        last_day = last_day,
                        all_time = all_time
                    })
                end
            end

            table.sort(stats_table, function(a, b) return a.all_time > b.all_time end)

            create_gui(player, stats_table, item)
        else
            player.print("No item found matching '" .. search_term .. "'")
        end
    end

end)

