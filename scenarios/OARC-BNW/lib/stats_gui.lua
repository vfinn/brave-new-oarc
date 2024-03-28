-- Thanks to Bits-Orio for getting me started on Stats table!

function format_number_commas(num)
  return tostring(num):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

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

function create_dropdown(parent, items, index)
    local dropdown = parent.add{ name="stats_dropdown", type = "drop-down" }
    for indx,item in pairs(items) do
        dropdown.add_item(item.richTextItem)
    end
    dropdown.selected_index = index
    return dropdown
end

-- columnStatItems - contains sets of 7 items to put across the dialog of items and their rich text string
-- statItems is an array that populates the dropdown names of the groups of 7 items
-- stats_table is populated with the stats for each of the 7 items to display based on itemIndx
-- itemIndx is the index of the drop down that chooses the array of items to display
-- 
function create_gui(player, statItems, columnStatItems, stats_table, itemIndx)

    if player.gui.screen.stats_gui then
        player.gui.screen.stats_gui.destroy()
    end

    local dialog = player.gui.screen.add{
        type = "frame",
        name = "stats_gui",
        caption = "Production Statistics",
        direction = "vertical"
    }
    dialog.auto_center = true

    local scroll_pane = dialog.add{type = "scroll-pane", vertical_scroll_policy = "auto",horizontal_scroll_policy = "auto"}
    scroll_pane.style.maximal_height = 400
    local table = scroll_pane.add{ type = "table", column_count = 8 }

    -- header
    local label = table.add{type = "label", caption = "[img=entity/character-corpse] Force"}
    label.style.font = "default-bold"
    label.style.font_color = {r = 0, g = 1, b = 0}
    label.style.minimal_width = 120

    for i=1, 7 do
        local label = table.add{type = "label", caption = columnStatItems[itemIndx][i].richTextItem}
        label.style.font = "default-bold"
        label.style.font_color = {r = 0, g = 1, b = 0}
        label.style.minimal_width = 120
        label.style.horizontal_align = "right"
    end

    -- data
    for _, stat in ipairs(stats_table) do
        local count_label
        if stat.force then
            count_label = table.add{type = "label", caption = stat.force}
        else
            count_label = table.add{type = "label", caption = format_number_commas(stat.count)}
            count_label.style.horizontal_align = "right"
        end
        count_label.style.minimal_width = 120
    end

    -- buttons
    local buttons = dialog.add{type = "table", column_count = 8 }
    -- drop list
    for indx, items in pairs (statItems) do
        if items.item == item then 
            index = indx
            break
        end
    end
    create_dropdown(table, statItems, itemIndx)
    
    -- space 6
    for i=1, 6 do
        local spacer = table.add{type = "label", caption = ""}
        spacer.style.minimal_width = 120
    end
    
    -- close button
    local button = table.add{ type= "button", name="stats_close_stats_gui", caption = "Close"}
     button.style.minimal_width = 120
    dialog.force_auto_center()
end

-- itemIndx 1..2 index's into 2x7 array of items
function buildStatsTable(player, itemIndx)
    local statItems = {
        {item="Resources"                    ,richTextItem="[item=iron-plate] Resources"},
        {item="Science"                      ,richTextItem="[item=automation-science-pack] Science"},
    }

    local columnStatItems = {
        {
            {item="iron-plate"               ,richTextItem="[item=iron-plate] Iron Plates"},
            {item="copper-plate"             ,richTextItem="[item=copper-plate] Copper Plates"},
            {item="steel-plate"              ,richTextItem="[item=steel-plate] Steel Plates"},
            {item="landfill"                 ,richTextItem="[item=landfill] Landfill"},
            {item="rocket-fuel"              ,richTextItem="[item=rocket-fuel] Rocket Fuel"},
            {item="nuclear-fuel"             ,richTextItem="[item=nuclear-fuel] Nuclear Fuel"},
            {item="uranium-fuel-cell"        ,richTextItem="[item=uranium-fuel-cell] Uranium Fuel Cell"},
        },
        {
            {item="automation-science-pack"  ,richTextItem="[item=automation-science-pack] Automation"},
            {item="logistic-science-pack"    ,richTextItem="[item=logistic-science-pack] Logistics"},
            {item="military-science-pack"    ,richTextItem="[item=military-science-pack] Military"},
            {item="chemical-science-pack"    ,richTextItem="[item=chemical-science-pack] Chemical"},
            {item="production-science-pack"  ,richTextItem="[item=production-science-pack] Production"},
            {item="utility-science-pack"     ,richTextItem="[item=utility-science-pack] Utility"},
            {item="space-science-pack"       ,richTextItem="[item=space-science-pack] Space"},
        }
    }
    
    local stats_table = {}
    log("Stats selection by <" .. player.name .. "> : " .. itemIndx)

    for _, force in pairs(game.forces) do
        local ignoredalienmodulefactions = { enemy=true, neutral=true, _ABANDONED_=true, _DESTROYED_=true, player=true} 
        if not ignoredalienmodulefactions[force.name] then

--            table.insert(stats_table, { force = force.name})
            table.insert(stats_table, {force=force.name})
            local stats = force.item_production_statistics
            for i=1, 7 do
                local item = columnStatItems[itemIndx][i].item
                local all_time = stats.input_counts[item] or 0

                table.insert(stats_table, {count=all_time})
            end
        end
    end
--    table.sort(stats_table, function(a, b) return a.all_time > b.all_time end)
    create_gui(player, statItems, columnStatItems, stats_table, itemIndx)
end

function closeStatsGui(player)
    player.gui.screen.stats_gui.destroy()
end