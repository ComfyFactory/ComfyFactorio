-- Created for ComfyFactorio
-- by gerkiz, mewmew and redlabel

local Event = require 'utils.event'
local Where = require 'utils.commands.where'
local Session = require 'utils.datastore.session_data'
local Gui = require 'utils.gui'
local Global = require 'utils.global'
local SpamProtection = require 'utils.spam_protection'
local RPG = require 'modules.rpg.table'
local Token = require 'utils.token'
local Vars = require 'utils.player_list_vars'
local Utils = require 'utils.utils'
local Core = require 'utils.core'
local Inventory = require 'modules.show_inventory'

local Public = {}

local module_name = Gui.uid_name()
local locate_player_frame_name = Gui.uid_name()
local poke_player_frame_name = Gui.uid_name()
local header_label_name = Gui.uid_name()
local ranks = Vars.ranks
local pokemessages = Vars.pokemessages
local get_formatted_playtime = Utils.get_formatted_playtime
local get_comparator = Vars.get_comparator
local tag = 'Players'

local this = {
    player_list = {
        last_poke_tick = {},
        pokes = {},
        sorting_method = {}
    },
    rpg_enabled = false,
    show_roles_in_list = false
}

Global.register(
    this,
    function (t)
        this = t
    end
)

local symbol_asc = '⬆️'
local symbol_desc = '⬇️'

local function get_header(tbl, name)
    for _, setting in pairs(tbl) do
        if setting.header and setting.header == name then
            return setting
        end
    end
end

local header_modifier = {
    ['username_asc'] = function (tbl)
        local setting = get_header(tbl, 'username')
        setting.name = setting.name .. '[color=yellow]' .. symbol_asc .. '[/color]'
    end,
    ['username_desc'] = function (tbl)
        local setting = get_header(tbl, 'username')
        setting.name = setting.name .. '[color=yellow]' .. symbol_desc .. '[/color]'
    end,
    ['rpg_asc'] = function (tbl)
        local setting = get_header(tbl, 'rpg')
        setting.name = setting.name .. '[color=yellow]' .. symbol_asc .. '[/color]'
    end,
    ['rpg_desc'] = function (tbl)
        local setting = get_header(tbl, 'rpg')
        setting.name = setting.name .. '[color=yellow]' .. symbol_desc .. '[/color]'
    end,
    ['coins_asc'] = function (tbl)
        local setting = get_header(tbl, 'coins')
        setting.name = setting.name .. '[color=yellow]' .. symbol_asc .. '[/color]'
    end,
    ['coins_desc'] = function (tbl)
        local setting = get_header(tbl, 'coins')
        setting.name = setting.name .. '[color=yellow]' .. symbol_desc .. '[/color]'
    end,
    ['total_time_asc'] = function (tbl)
        local setting = get_header(tbl, 'total_time')
        setting.name = setting.name .. '[color=yellow]' .. symbol_asc .. '[/color]'
    end,
    ['total_time_desc'] = function (tbl)
        local setting = get_header(tbl, 'total_time')
        setting.name = setting.name .. '[color=yellow]' .. symbol_desc .. '[/color]'
    end,
    ['current_time_asc'] = function (tbl)
        local setting = get_header(tbl, 'current_time')
        setting.name = setting.name .. '[color=yellow]' .. symbol_asc .. '[/color]'
    end,
    ['current_time_desc'] = function (tbl)
        local setting = get_header(tbl, 'current_time')
        setting.name = setting.name .. '[color=yellow]' .. symbol_desc .. '[/color]'
    end,
    ['poke_asc'] = function (tbl)
        local setting = get_header(tbl, 'poke')
        setting.name = setting.name .. '[color=yellow]' .. symbol_asc .. '[/color]'
    end,
    ['poke_desc'] = function (tbl)
        local setting = get_header(tbl, 'poke')
        setting.name = setting.name .. '[color=yellow]' .. symbol_desc .. '[/color]'
    end
}

local function get_rank(player)
    local sessions_table = Session.get_session_table()
    local t = 0
    if sessions_table then
        if sessions_table[player.name] then
            t = sessions_table[player.name]
        end
    end

    local m = t / 3600

    local time_needed = 1000 -- in minutes between rank upgrades
    m = m / time_needed
    m = math.floor(m)
    m = m + 1

    if m > #ranks then
        m = #ranks
    end

    return ranks[m]
end

local function get_sorted_list(sort_by)
    local session_table = Session.get_session_table()
    local player_list = {}
    Core.iter_connected_players(
        function (player, index)
            local player_data = player_list[index] or {}
            player_data.rank = get_rank(player)
            player_data.name = player.name

            local t = 0
            if session_table[player.name] then
                t = session_table[player.name]
            end

            if this.rpg_enabled then
                local char = RPG.get_value_from_player(player.index, 'level')
                if not char then
                    char = 1
                end

                player_data.rpg_level = char
            end

            player_data.total_played_time = get_formatted_playtime(t)
            player_data.total_played_ticks = t

            player_data.admin = player.admin
            player_data.color = player.color
            player_data.index = player.index
            local inventory = player.get_main_inventory()
            if inventory and inventory.valid then
                local player_item_count = inventory.get_item_count('coin')
                player_data.coins = player_item_count
            else
                player_data.coins = 0
            end

            player_data.played_time = get_formatted_playtime(player.online_time)
            player_data.played_ticks = player.online_time
            player_data.pokes = this.player_list.pokes[player.index]

            player_list[index] = player_data
        end
    )
    local comparator = get_comparator(sort_by)
    table.sort(player_list, comparator)

    return player_list
end

local function player_list_show(data)
    local frame = data.frame
    local sort_by = data.sort_by
    -- Frame management
    frame.clear()
    frame.style.padding = 8

    local gui_data =
        Vars.gui_data(
            {
                header_label_name = header_label_name,
                show_roles_in_list = this.show_roles_in_list,
                locate_player_frame_name = locate_player_frame_name,
                rpg_enabled = this.rpg_enabled,
                poke_player_frame_name = poke_player_frame_name
            }
        )



    if sort_by then
        this.player_list.sorting_method[data.player.index] = sort_by
    else
        sort_by = this.player_list.sorting_method[data.player.index]
    end

    if this.player_list.sorting_method[data.player.index] == '_desc' or this.player_list.sorting_method[data.player.index] == '_asc' then
        this.player_list.sorting_method[data.player.index] = 'total_time_desc'
    end

    if not sort_by then
        sort_by = 'total_time_desc'
    end

    header_modifier[sort_by](gui_data)

    local player_tbl = frame.add { type = 'table', column_count = #gui_data }

    for _, setting in pairs(gui_data) do
        local label = player_tbl.add { type = 'label', caption = '' }
        label.style.minimal_width = setting.header_width
        label.style.maximal_width = setting.header_width
    end

    for _, setting in pairs(gui_data) do
        setting.sorter(setting, player_tbl)
    end

    -- List management
    local player_list_panel_table =
        frame.add {
            type = 'scroll-pane',
            name = 'scroll_pane',
            direction = 'vertical',
            horizontal_scroll_policy = 'never',
            vertical_scroll_policy = 'auto'
        }
    player_list_panel_table.style.maximal_height = 400

    player_list_panel_table = player_list_panel_table.add { type = 'table', name = 'player_list_panel_table', column_count = #gui_data }

    local player_list = get_sorted_list(sort_by)
    for i = 1, #player_list, 1 do
        local player = player_list[i]
        for _, setting in pairs(gui_data) do
            setting.func(player_list_panel_table, player, i)
        end
    end
end

local player_list_show_token = Token.register(player_list_show)

Gui.on_click(
    locate_player_frame_name,
    function (event)
        local player = event.player
        local element = event.element

        local button = event.button
        local data = Gui.get_data(element)
        if not data then
            return
        end

        if button == defines.mouse_button_type.left then
            local is_spamming = SpamProtection.is_spamming(player, nil, 'PlayerList Locate Player')
            if is_spamming then
                return
            end

            local target = game.get_player(data)
            if not target or not target.valid then
                return
            end
            Where.create_mini_camera_gui(player, target)
        elseif defines.mouse_button_type.right then
            local is_spamming = SpamProtection.is_spamming(player, nil, 'PlayerList Show Inventory')
            if is_spamming then
                return
            end

            local target = game.get_player(data)
            if not target or not target.valid then
                return
            end
            Inventory.show_inventory(player, target)
        end
    end
)

Gui.on_click(
    poke_player_frame_name,
    function (event)
        local player = event.player
        local element = event.element

        local data = Gui.get_data(element)
        if not data then
            return
        end
        local target = game.get_player(data)

        if player.index == target.index then
            return
        end

        if this.player_list.last_poke_tick[player.index] + 300 < game.tick then
            local str = '>> '
            str = str .. player.name
            str = str .. ' has poked '
            str = str .. target.name
            str = str .. ' with '
            local z = math.random(1, #pokemessages)
            str = str .. pokemessages[z]
            str = str .. ' <<'
            game.print(str)
            this.player_list.last_poke_tick[player.index] = game.tick
            this.player_list.pokes[target.index] = this.player_list.pokes[target.index] + 1
        end
    end
)

local function refresh()
    for _, player in pairs(game.connected_players) do
        local frame = Gui.get_player_active_frame(player)
        if frame then
            if frame.name ~= tag then
                return
            end
            local data = { player = player, frame = frame, sort_by = this.player_list.sorting_method[player.index] }
            player_list_show(data)
        end
    end
end

local function on_player_joined_game(event)
    if not this.player_list.last_poke_tick[event.player_index] then
        this.player_list.pokes[event.player_index] = 0
        this.player_list.last_poke_tick[event.player_index] = 0
        this.player_list.sorting_method[event.player_index] = 'total_time_desc'
    end
    refresh()
end

local function on_player_left_game()
    refresh()
end

--- If the different roles should be shown in the player_list.
---@param value boolean
function Public.show_roles_in_list(value)
    this.show_roles_in_list = value or false
    return this.show_roles_in_list
end

--- Notifies player_list if RPG is enabled or not.
---@param value boolean
function Public.rpg_enabled(value)
    this.rpg_enabled = value or false
    return this.rpg_enabled
end

Gui.add_tab_to_gui({ name = module_name, caption = tag, id = player_list_show_token, admin = false })

Gui.on_click(
    module_name,
    function (event)
        local player = event.player
        Gui.reload_active_tab(player)
    end
)

Gui.on_click(
    header_label_name,
    function (event)
        local player = event.player
        local element = event.element
        if not element or not element.valid then
            return
        end

        local parent = element.parent
        if not parent or not parent.valid then
            return
        end

        local frame = Gui.get_player_active_frame(player)
        if not frame then
            return
        end
        if frame.name ~= tag then
            return
        end

        if string.find(element.caption, symbol_desc) then
            local data = { player = player, frame = frame, sort_by = parent.name and parent.name:len() > 0 and parent.name .. '_asc' or nil }
            player_list_show(data)
        else
            local data = { player = player, frame = frame, sort_by = parent.name and parent.name:len() > 0 and parent.name .. '_desc' or nil }
            player_list_show(data)
        end
        local is_spamming = SpamProtection.is_spamming(player, nil, 'PlayerList Gui Click')
        if is_spamming then
            return
        end
    end
)

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_left_game, on_player_left_game)

return Public
