local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Task = require 'utils.task_token'

local module_name = Gui.uid_name()

local map_info = {
    localised_category = false,
    main_caption = nil,
    main_caption_color = {r = 0.6, g = 0.3, b = 0.99},
    sub_caption = nil,
    sub_caption_color = {r = 0.2, g = 0.9, b = 0.2},
    text = nil
}

Global.register(
    map_info,
    function(tbl)
        map_info = tbl
    end
)

local call_active_tab_token =
    Task.register(
    function(event)
        local player_index = event.player_index
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end
        Gui.call_existing_tab(player, 'Map Info')
    end
)

local Public = {}

function Public.Pop_info()
    return map_info
end

local function create_map_intro(data)
    local frame = data.frame
    frame.clear()
    frame.style.padding = 4
    frame.style.margin = 0

    local t = frame.add {type = 'table', column_count = 1}

    local line = t.add {type = 'line'}
    line.style.top_margin = 4
    line.style.bottom_margin = 4

    if not map_info.localised_category then
        return
    end

    local caption = map_info.main_caption or {map_info.localised_category .. '.map_info_main_caption'}
    local sub_caption = map_info.sub_caption or {map_info.localised_category .. '.map_info_sub_caption'}
    local text = map_info.text or {map_info.localised_category .. '.map_info_text'}

    if map_info.localised_category then
        map_info.main_caption = caption
        map_info.sub_caption = sub_caption
        map_info.text = text
    end
    local l = t.add {type = 'label', caption = map_info.main_caption}
    l.style.font = 'heading-1'
    l.style.font_color = map_info.main_caption_color
    l.style.minimal_width = 780
    l.style.horizontal_align = 'center'
    l.style.vertical_align = 'center'

    local l_2 = t.add {type = 'label', caption = map_info.sub_caption}
    l_2.style.font = 'heading-2'
    l_2.style.font_color = map_info.sub_caption_color
    l_2.style.minimal_width = 780
    l_2.style.horizontal_align = 'center'
    l_2.style.vertical_align = 'center'

    local line_2 = t.add {type = 'line'}
    line_2.style.top_margin = 4
    line_2.style.bottom_margin = 4

    local scroll_pane =
        frame.add {
        type = 'scroll-pane',
        name = 'scroll_pane',
        direction = 'vertical',
        horizontal_scroll_policy = 'never',
        vertical_scroll_policy = 'auto'
    }
    scroll_pane.style.maximal_height = 320
    scroll_pane.style.minimal_height = 320

    local l_3 = scroll_pane.add {type = 'label', caption = map_info.text}
    l_3.style.font = 'heading-2'
    l_3.style.single_line = false
    l_3.style.font_color = {r = 0.85, g = 0.85, b = 0.88}
    l_3.style.minimal_width = 780
    l_3.style.horizontal_align = 'center'
    l_3.style.vertical_align = 'center'
end

local create_map_intro_token = Task.register(create_map_intro)

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if player.online_time == 0 then
        Gui.call_existing_tab(player, 'Map Info')
        Task.set_timeout_in_ticks(5, call_active_tab_token, {player_index = player.index})
    end
end
Event.add(defines.events.on_player_joined_game, on_player_joined_game)

Gui.add_tab_to_gui({name = module_name, caption = 'Map Info', id = create_map_intro_token, admin = false})

Gui.on_click(
    module_name,
    function(event)
        local player = event.player
        Gui.reload_active_tab(player)
    end
)

return Public
