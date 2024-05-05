-- Define a function to add a custom title bar with a close button
function add_titlebar(gui, caption, close_button_name)
    local titlebar = gui.add{type = "flow"}
    titlebar.drag_target = gui
    titlebar.add{
        type = "label",
        style = "frame_title",
        caption = caption,
        ignored_by_interaction = true,
    }
    local filler = titlebar.add{
        type = "empty-widget",
        style = "draggable_space",
        ignored_by_interaction = true,
    }
    filler.style.height = 24
    filler.style.horizontally_stretchable = true
    titlebar.add{
        type = "sprite-button",
        name = close_button_name,
        style = "frame_action_button",
        sprite = "utility/close_white",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        tooltip = {"gui.close-instruction"},
    }
end

function create_popup_gui(player, title, msgArray)
    -- Create a GUI frame with a custom title bar
    if player.gui.screen.popup_gui then
        player.gui.screen.popup_gui.destroy()
    end

    local dialog = player.gui.screen.add{
        type = "frame",
        name = "popup_gui",
        direction = "vertical"
    }
    dialog.auto_center = true
    add_titlebar(dialog, title, "popup_close_gui_title")
    for index, msg in ipairs(msgArray) do
        dialog.add{
            type = "label",
            caption = msg
        }
    end

    -- close button
    local button = dialog.add{ type= "button", name="popup_close_gui", caption = "Close"}
     button.style.minimal_width = 120
     dialog.force_auto_center()

end


-- create_popup_gui(player,"Character option is not possible!", {"Each team must be of the same type - Character or Brave New Player.", "The player that started Main Force has already selected Brave New Player.","", "If you'd like to play as character - form your own team."})
