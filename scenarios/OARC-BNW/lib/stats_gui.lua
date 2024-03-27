-- 2x7 array in vector format
global.statItems = {
    {item="iron-plate"               ,richTextItem="[item=iron-plate] Iron Plates"},
    {item="copper-plate"             ,richTextItem="[item=copper-plate] Copper Plates"},
    {item="steel-plate"              ,richTextItem="[item=steel-plate] Steel Plates"},
    {item="landfill"                 ,richTextItem="[item=landfill] Landfill"},
    {item="rocket-fuel"              ,richTextItem="[item=rocket-fuel] Rocket Fuel"},
    {item="nuclear-fuel"             ,richTextItem="[item=nuclear-fuel] Nuclear Fuel"},
    {item="uranium-fuel-cell"        ,richTextItem="[item=uranium-fuel-cell] Uranium Fuel Cell"},
    {item="automation-science-pack"  ,richTextItem="[item=automation-science-pack] Automation"},
    {item="logistic-science-pack"    ,richTextItem="[item=logistic-science-pack] Logistics"},
    {item="military-science-pack"    ,richTextItem="[item=military-science-pack] Military"},
    {item="chemical-science-pack"    ,richTextItem="[item=chemical-science-pack] Chemical"},
    {item="production-science-pack"  ,richTextItem="[item=production-science-pack] Production"},
    {item="utility-science-pack"     ,richTextItem="[item=utility-science-pack] Utility"},
    {item="space-science-pack"       ,richTextItem="[item=space-science-pack] Space"},
}

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

function create_dropdown(parent, items, index)
    local dropdown = parent.add{ type = "drop-down" }
    for indx,item in pairs(items) do
        dropdown.add_item(item.richTextItem)
    end
    dropdown.selected_index = index
    return dropdown
end

-- merge with oarc_gui_tabs.lua
function create_gui(player, stats_table, item)
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

    local scroll_pane = dialog.add{
        type = "scroll-pane",
        vertical_scroll_policy = "auto",
        horizontal_scroll_policy = "auto"
    }
    scroll_pane.style.maximal_height = 400

    local table = scroll_pane.add{
        type = "table",
        column_count = 4
    }

    -- header
    local headers = {"Force", "1min", "1hr", "All time"}
    for _, header in ipairs(headers) do
        local label = table.add{type = "label", caption = header}
        label.style.font = "default-bold"
        label.style.font_color = {r = 0, g = 1, b = 0}
        label.style.minimal_width = 120
    end

    -- data
    for _, stat in ipairs(stats_table) do
        local force_label = table.add{type = "label", caption = stat.force}
        force_label.style.minimal_width = 120
        local minute_label = table.add{type = "label", caption = format_number(stat.last_minute)}
        minute_label.style.minimal_width = 120
        local hour_label = table.add{type = "label", caption = format_number(stat.last_hour)}
        hour_label.style.minimal_width = 120
        local all_time_label = table.add{type = "label", caption = format_number(stat.all_time)}
        all_time_label.style.minimal_width = 120
    end

    -- buttons
    local buttons = dialog.add{
        type = "table",
        column_count = 4
    }


    -- drop list
    local index=1
    for indx, items in pairs (global.statItems) do
        if items.item == item then 
            index = indx
            break
        end
    end
    create_dropdown(table, global.statItems, index)
    
    -- space
    local spacer = table.add{type = "label", caption = ""}
    spacer.style.minimal_width = 120

    -- space
    local spacer = table.add{type = "label", caption = ""}
    spacer.style.minimal_width = 120
    
    -- close button
    local button = table.add{ type= "button", name="stats_close_stats_gui", caption = "Close"}
--    local button = dialog.add{ type= "button", name="stats_close_stats_gui", caption = "Close"}
    dialog.force_auto_center()
end
