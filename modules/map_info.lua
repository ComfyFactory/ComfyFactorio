local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Style = require 'utils.gui_style'
local Task = require 'utils.task_token'
local Public = {}

local module_name = Gui.uid_name()

local map_info =
{
    localised_category = false,
    main_caption = nil,
    main_caption_color = nil,
    sub_caption = nil,
    sub_caption_color = nil,
    text = nil,
    call_map_info_on_join = true
}

Global.register(
    map_info,
    function (tbl)
        map_info = tbl
    end
)

local function has_map_info()
    if map_info.main_caption and map_info.text and map_info.sub_caption then
        return true
    elseif map_info.localised_category then
        return true
    end
    return false
end

local open_map_info_token = Task.register(function (event)
    local player = game.get_player(event.player_index)
    if player and player.valid and player.connected and map_info.call_map_info_on_join and has_map_info() then
        Gui.call_existing_tab(player, 'Map Info')
    end
end)

local function readable_color(custom, fallback)
    if not custom then
        return fallback
    end
    local r, g, b = custom.r or custom[1] or 0, custom.g or custom[2] or 0, custom.b or custom[3] or 0
    local scale = math.max(r, g, b) > 1 and 255 or 1
    return { 0.5 + r / scale * 0.5, 0.5 + g / scale * 0.5, 0.5 + b / scale * 0.5 }
end

local function create_map_intro(data)
    if not has_map_info() then
        return
    end

    local frame = data.frame
    frame.clear()
    local panel_width = Style.content_width(data.player, frame)
    local panel = Style.surface(frame, 'map_information', panel_width)
    local width = math.max(1, panel_width - 2 * Style.spacing.md)

    if map_info.localised_category then
        map_info.main_caption = map_info.main_caption or { map_info.localised_category .. '.map_info_main_caption' }
        map_info.sub_caption = map_info.sub_caption or { map_info.localised_category .. '.map_info_sub_caption' }
        map_info.text = map_info.text or { map_info.localised_category .. '.map_info_text' }
    end

    local title = Style.text(panel, map_info.main_caption, width, readable_color(map_info.main_caption_color, Style.colors.heading))
    title.style.font = 'default-bold'
    local subtitle = Style.text(panel, map_info.sub_caption, width, readable_color(map_info.sub_caption_color, Style.colors.muted))
    subtitle.style.font = 'default-semibold'
    subtitle.style.bottom_margin = Style.spacing.sm
    local body = Style.text(panel, map_info.text, width)
    for _, label in ipairs({ title, subtitle, body }) do
        label.style.width = width
        label.style.horizontal_align = 'center'
    end
end

local create_map_intro_token = Task.register(create_map_intro)

local function on_player_joined_game(event)
    if not has_map_info() or not map_info.call_map_info_on_join then
        return
    end

    local player = game.get_player(event.player_index)
    if player and player.valid and player.online_time == 0 then
        Task.set_timeout_in_ticks(5, open_map_info_token, { player_index = player.index })
    end
end

function Public.call_map_info_on_join(state)
    map_info.call_map_info_on_join = state or false
end

function Public.get_map_information()
    return map_info
end

function Public.set_map_main_caption(caption)
    if not caption then
        return error('caption is required to set the map information')
    end
    map_info.main_caption = caption
end

function Public.set_map_sub_caption(caption)
    if not caption then
        return error('caption is required to set the map information')
    end
    map_info.sub_caption = caption
end

function Public.set_map_text(text)
    if not text then
        return error('text is required to set the map information')
    end

    map_info.text = text
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)

Gui.add_tab_to_gui({ name = module_name, caption = 'Map Info', id = create_map_intro_token, admin = false })

Gui.on_click(
    module_name,
    function (event)
        local player = event.player
        Gui.reload_active_tab(player, nil, 'Map Info')
    end
)

return Public
