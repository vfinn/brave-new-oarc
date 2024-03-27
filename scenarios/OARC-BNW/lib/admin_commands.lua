-- admin_commands.lua
-- May 2019
-- 
-- Yay, admin commands!

require("lib/oarc_utils")
require("lib/stats_gui")

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

        buildStatsTable(player, best_match)
    end

end)

-- Thanks to Bits-Orio for getting me started on Stats table!
function buildStatsTable(player, item)
    if item then
        local stats_table = {}
        log("Stats selection by <" .. player.name .. "> : " .. item)

        for _, force in pairs(game.forces) do
            local ignoredalienmodulefactions = { enemy=true, neutral=true, _ABANDONED_=true, _DESTROYED_=true, player=true} 
            if not ignoredalienmodulefactions[force.name] then
                local stats = force.item_production_statistics
                local last_minute = stats.get_flow_count{type="input", name=item, precision_index=defines.flow_precision_index.one_minute}
                local last_hour = stats.get_flow_count{type="input", name=item, precision_index=defines.flow_precision_index.one_hour}
                local all_time = stats.input_counts[item] or 0

                table.insert(stats_table, {
                    force = force.name,
                    last_minute = last_minute,
                    last_hour = last_hour,
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


