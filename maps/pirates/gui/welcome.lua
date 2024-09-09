-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Public = {}

function Public.show_welcome_window(player)
    if player.gui.center['welcome_window'] then player.gui.center['welcome_window'].destroy() end

    local frame = player.gui.center.add{
        type = 'frame',
        name = 'welcome_window',
        direction = 'vertical'
    }
    frame.style.width = 240
    -- frame.style.color = {r = 0.5, g = 0, b = 0, a = 0.5}

    local title_flow = frame.add{type = 'flow', direction = 'horizontal'}
    title_flow.style.horizontal_align = 'center'
    title_flow.style.top_margin = 10
    title_flow.style.width = 220

    local colors = {
        {r=1, g=0.5, b=0.5},
        {r=1, g=0.7, b=0.5},
        {r=1, g=1, b=0.5},
        {r=0.7, g=1, b=0.5},
        {r=0.5, g=0.7, b=1},
        {r=0.7, g=0.5, b=1}
    }

    -- Todo: Localize
    local welcome = {'W', 'E', 'L', 'C', 'O', 'M', 'E', '!'}

    for i, letter in ipairs(welcome) do
        local label = title_flow.add{type = 'label', caption = letter}
        label.style.font = 'default-large-bold'
        label.style.font_color = colors[(i-1) % #colors + 1]
    end

    local message1 = frame.add{type = 'label', caption = {'pirates.welcome_main_1'}}
    message1.style.font = 'scenario-message-dialog'
    message1.style.horizontal_align = 'center'
    message1.style.single_line = false
    message1.style.top_margin = 12
    message1.style.width = 220
    message1.style.rich_text_setting = defines.rich_text_setting.enabled

    local message2 = frame.add{type = 'label', caption = {'pirates.welcome_main_2'}}
    message2.style.font = 'scenario-message-dialog'
    message2.style.horizontal_align = 'center'
    message2.style.single_line = false
    message2.style.top_margin = 10
    message2.style.width = 220
    message2.style.rich_text_setting = defines.rich_text_setting.enabled

    local close_instruction = frame.add{type = 'label', caption = {'pirates.welcome_end'}}
    close_instruction.style.font = 'default-small'
    close_instruction.style.horizontal_align = 'center'
    close_instruction.style.top_margin = 20
    close_instruction.style.width = 220
end

function Public.handle_click(event)
    if event.element and event.element.valid then
        local player = game.players[event.player_index]
        if player.gui.center['welcome_window'] then
            if event.element.name == 'welcome_window' or event.element.parent.name == 'welcome_window' then
                Public.close_welcome_window(player)
                return true
            end
        end
    end
    return false
end

function Public.close_welcome_window(player)
    if player.gui.center['welcome_window'] then
        player.gui.center['welcome_window'].destroy()
    end
end

return Public