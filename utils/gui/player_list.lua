-- Created for ComfyFactorio
-- by gerkiz, mewmew and redlabel

local Event = require 'utils.event'
local Where = require 'utils.commands.where'
local Session = require 'utils.datastore.session_data'
local Gui = require 'utils.gui'
local Global = require 'utils.global'
local SpamProtection = require 'utils.spam_protection'
local Token = require 'utils.token'
local Vars = require 'utils.player_list_vars'
local Utils = require 'utils.utils'
local Core = require 'utils.core'
local Inventory = require 'modules.show_inventory'
local Color = require 'utils.color_presets'
local Config = require 'utils.gui.config'

local Public =
{
    settings =
    {
        disable_camera_for_non_admins = false,
    },

}

local module_name = Gui.uid_name()
local locate_player_frame_name = Gui.uid_name()
local poke_player_frame_name = Gui.uid_name()
local header_label_name = Gui.uid_name()
local ranks = Vars.ranks
local pokemessages = Vars.pokemessages
local get_formatted_playtime = Utils.get_formatted_playtime
local get_comparator = Vars.get_comparator
local tag = 'Players'

local this =
{
    player_list =
    {
        last_poke_tick = {},
        pokes = {},
        sorting_method = {}
    },
    rpg_enabled = false,
    show_roles_in_list = false,
    player_settings = {}
}

Global.register(
    this,
    function (t)
        this = t
    end
)

Config.register_scenario_module(
    {
        id = "player_list",
        admin_only = true,
        gui_rows = Config.register_token(
            function (player, frame)
                local label = frame.add({ type = 'label', caption = 'Player List Settings' })
                label.style.font = 'default-bold'
                label.style.padding = 0
                label.style.left_padding = 10
                label.style.top_padding = 10
                label.style.horizontal_align = 'left'
                label.style.vertical_align = 'bottom'
                label.style.font_color = Color.green

                local switch_state = 'right'
                if this.player_settings[player.index] and this.player_settings[player.index].show_all_players then
                    switch_state = 'left'
                end
                Config.add_switch(frame, switch_state, 'show_all_players', 'Show All Players', 'On = Shows all players.\nOff = Shows only connected players.')

                frame.add({ type = 'line' })
            end),
        handlers =
        {
            ['show_all_players'] = Config.register_token(
                function (player, event)
                    if event.element.switch_state == 'left' then
                        this.player_settings[player.index] = { show_all_players = true }
                        player.print('Now showing all players.', { color = Color.green })
                    else
                        this.player_settings[player.index] = { show_all_players = false }
                        player.print('Now showing only connected players.', { color = Color.green })
                    end
                end),
        }
    })

local symbol_asc = '⬆️'
local symbol_desc = '⬇️'

local function get_header(tbl, name)
    for _, setting in pairs(tbl) do
        if setting.header and setting.header == name then
            return setting
        end
    end
end

local header_modifier =
{
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

local function get_sorted_list(sort_by, show_all_players)
    local session_table = Session.get_session_table()
    local player_list = {}

    local func = Core.iter_connected_players
    if show_all_players then
        func = Core.iter_players
    end

    func(
        function (player, index)
            local player_data = player_list[index] or {}
            player_data.rank = get_rank(player)
            player_data.name = player.name

            local t = 0
            if session_table[player.name] then
                t = session_table[player.name]
            end

            if this.rpg_enabled then
                local rpg_callback = this.rpg_callback_token and Token.get(this.rpg_callback_token)
                local char
                if rpg_callback then
                    char = rpg_callback({ player_index = player.index, key = 'level' })
                end
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

    local merged = {}
    for _, player_data in pairs(player_list) do
        merged[#merged + 1] = player_data
    end
    if _DEBUG then
        local fake_players =
        {
            { name = 'Belt Enjoyer', color = { r = 0.2, g = 0.75, b = 0.3 }, rank = 'item/transport-belt', admin = false, coins = 128, total = 216000 * 6 + 3600 * 12, online = 3600 * 42, rpg = 14, pokes = 3 },
            { name = 'Smelter', color = { r = 0.9, g = 0.45, b = 0.1 }, rank = 'item/stone-furnace', admin = false, coins = 54, total = 216000 * 23 + 3600 * 40, online = 3600 * 8, rpg = 7, pokes = 1 },
            { name = 'Admin Faker', color = { r = 0.85, g = 0.15, b = 0.15 }, rank = 'item/power-armor', admin = true, coins = 900, total = 5184000 * 2 + 216000 * 3, online = 216000 * 2, rpg = 42, pokes = 11 },
            { name = 'Trainman', color = { r = 0.3, g = 0.55, b = 0.95 }, rank = 'item/locomotive', admin = false, coins = 17, total = 3600 * 4, online = 3600 * 4, rpg = 4, pokes = 0 },
            { name = 'Oil King', color = { r = 0.15, g = 0.15, b = 0.15 }, rank = 'item/pumpjack', admin = false, coins = 320, total = 216000 * 12, online = 3600 * 95, rpg = 21, pokes = 6 },
            { name = 'Very Long Faker Like So Long', color = { r = 0.7, g = 0.4, b = 0.9 }, rank = 'item/repair-pack', admin = false, coins = 2, total = 3600 * 90, online = 3600 * 15, rpg = 2, pokes = 8 }
        }
        for i = 1, #fake_players do
            local fake = fake_players[i]
            merged[#merged + 1] =
            {
                rank = fake.rank,
                name = fake.name,
                rpg_level = fake.rpg,
                total_played_time = get_formatted_playtime(fake.total),
                total_played_ticks = fake.total,
                admin = fake.admin,
                color = fake.color,
                index = -i,
                coins = fake.coins,
                played_time = get_formatted_playtime(fake.online),
                played_ticks = fake.online,
                pokes = fake.pokes
            }
        end
    end

    local comparator = get_comparator(sort_by)
    table.sort(merged, comparator)

    return merged
end

local function player_list_show(data)
    local frame = data.frame
    local sort_by = data.sort_by
    -- Frame management
    frame.clear()
    frame.style.padding = 4

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

    local content_width = 0
    for _, setting in pairs(gui_data) do
        content_width = content_width + setting.header_width
    end

    local player_tbl = frame.add { type = 'table', column_count = #gui_data }

    for _, setting in pairs(gui_data) do
        setting.sorter(setting, player_tbl)
    end

    local header_line = frame.add({ type = 'line', direction = 'horizontal' })
    header_line.style.minimal_width = content_width
    header_line.style.horizontally_stretchable = true
    header_line.style.top_margin = 2
    header_line.style.bottom_margin = 2

    -- List management
    local scroll_pane =
        frame.add
        {
            type = 'scroll-pane',
            name = 'scroll_pane',
            direction = 'vertical',
            horizontal_scroll_policy = 'never',
            vertical_scroll_policy = 'auto'
        }
    scroll_pane.style.maximal_height = 360

    local player_list_panel_table = scroll_pane.add { type = 'flow', name = 'player_list_panel_table', direction = 'vertical' }
    player_list_panel_table.style.minimal_width = content_width
    player_list_panel_table.style.horizontally_stretchable = true

    local show_all_players = this.player_settings[data.player.index] and this.player_settings[data.player.index].show_all_players or false

    local player_list = get_sorted_list(sort_by, show_all_players)
    for i = 1, #player_list, 1 do
        local player = player_list[i]
        local row = player_list_panel_table.add { type = 'table', column_count = #gui_data }
        for _, setting in pairs(gui_data) do
            setting.func(row, player, i)
        end
        local line = player_list_panel_table.add({ type = 'line', direction = 'horizontal' })
        line.style.minimal_width = content_width
        line.style.horizontally_stretchable = true
        line.style.top_margin = 2
        line.style.bottom_margin = 2
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
            if Public.settings.disable_camera_for_non_admins and not player.admin then
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
            if target.controller_type == defines.controllers.remote then
                player.print('[Inventory] This player is currently in remote-view and has no character association. Please try again later.', { color = Color.warning })
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
        if not target or not target.valid then
            return
        end

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

local function on_rpg_callback_added(event)
    if event.token then
        this.rpg_callback_token = event.token
    end
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
        Gui.reload_active_tab(player, nil, tag)
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
Event.add(ServerCommands.events.on_rpg_callback_added, on_rpg_callback_added)

return Public
