local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local Global = require 'utils.global'
local Server = require 'utils.server'
local Gui = require 'utils.gui'
local Style = require 'utils.gui_style'
local Task = require 'utils.task_token'
local SpamProtection = require 'utils.spam_protection'

local module_name = Gui.uid_name()
local score_dataset = 'seasons'
local score_key = 'mtn_v3'
local score_key_dev = 'mtn_v3_dev'
local set_data = Server.set_data
local try_get_data = Server.try_get_data

local insert = table.insert

local this =
{
    seasons = {},
    sort_by = {}
}

Global.register(
    this,
    function (t)
        this = t
    end
)

local function sort_list(method, column_name, score_list)
    table.sort(score_list, function (a, b)
        local first, second = a[column_name], b[column_name]
        if first == nil then
            return false
        end
        if second == nil then
            return true
        end
        if method == 'descending' then
            return first > second
        end
        return first < second
    end)
end

local function write_additional_stats(key)
    local current_date = Server.get_current_date(true)
    if current_date == nil then
        Server.output_script_data('Failed to get current date.')
        return
    end

    local season = Public.get_stateful('season')
    local rounds_survived = Public.get_stateful('rounds_survived')
    local best_streak = Public.get_stateful('best_streak')
    local previous_raw_date = Public.get_stateful('current_date')

    local previous_date = Server.get_current_date(true, false, previous_raw_date)
    if previous_date == nil then
        Server.output_script_data('Failed to get previous date.')
        return
    end

    if not season then
        Server.output_script_data('Missing season data, cannot write stats')
        return
    end

    if not rounds_survived then
        Server.output_script_data('Missing rounds survived data, cannot write stats')
        return
    end

    if #this.seasons < 2 then
        Server.output_script_data('Not enough seasons to write stats, minimum of 2 seasons is required')
        Server.output_script_data('Current season: ' .. season)
        Server.output_script_data('Backend data has not been updated yet')
        Server.output_script_data(serpent.block(this.seasons))
        return
    end

    this.seasons[#this.seasons + 1] =
    {
        season_index = season,
        rounds_survived = rounds_survived,
        best_streak = best_streak or 'N/A',
        buffs_granted = rounds_survived,
        started = previous_date,
        ended = current_date
    }

    if key then
        set_data(score_dataset, key, this.seasons)
        Server.output_script_data('Season stats written to server')
    else
        Server.output_script_data('No key provided for season stats, data not saved')
    end
end

local get_scores =
    Task.register(
        function (data)
            if data and data.value and type(data.value) == 'table' then
                this.seasons = data.value
                Server.output_script_data('Season scores loaded successfully')
            else
                Server.output_script_data('Invalid season data received from server')
                this.seasons = {}
            end
        end
    )

function Public.get_season_scores()
    local secs = Server.get_current_time()
    if not secs then
        return
    else
        local server_name_matches = Server.check_server_name(Public.discord_name)
        if server_name_matches then
            try_get_data(score_dataset, score_key, get_scores)
        else
            try_get_data(score_dataset, score_key_dev, get_scores)
        end
    end
end

-- local Core = require 'maps.mountain_fortress_v3.core' Core.set_season_scores()
function Public.set_season_scores()
    local secs = Server.get_current_time()
    if not secs then
        return
    else
        local server_name_matches = Server.check_server_name(Public.discord_name)
        if server_name_matches then
            write_additional_stats(score_key)
        else
            write_additional_stats(score_key_dev)
        end
    end
end

local sorting_symbol = { ascending = '▲', descending = '▼' }

local function season_date(value)
    if type(value) == 'string' and value ~= '' and value ~= 'N/A' then
        return value
    end
end

local function get_score_list()
    local seasons = this.seasons or {}
    local score_list = {}

    for _, data in pairs(seasons) do
        insert(
            score_list,
            {
                season_index = tonumber(data.season_index),
                rounds_survived = tonumber(data.rounds_survived),
                best_streak = tonumber(data.best_streak),
                buffs_granted = tonumber(data.buffs_granted),
                started = season_date(data.started),
                ended = season_date(data.ended)
            }
        )
    end
    return score_list
end

local function show_score(data)
    local player = data.player
    local frame = data.frame
    frame.clear()

    local t = frame.add { type = 'table', column_count = 6 }
    t.style.horizontal_spacing = Style.spacing.xs

    -- Score headers
    local headers =
    {
        { column = 'season_index', name = 'season_index', caption = { 'mtn_v3_highscore.season' }, tooltip = { 'mtn_v3_highscore.season_index' } },
        { column = 'rounds_survived', name = 'rounds_survived', caption = { 'mtn_v3_highscore.rounds_survived' }, tooltip = { 'mtn_v3_highscore.rounds_survived_in_the_season' } },
        { column = 'best_streak', name = 'best_streak', caption = { 'mtn_v3_highscore.best_streak' }, tooltip = { 'mtn_v3_highscore.best_streak_of_rounds_survived' } },
        { column = 'buffs_granted', name = 'buffs_granted', caption = { 'mtn_v3_highscore.buffs_granted' }, tooltip = { 'mtn_v3_highscore.buffs_granted_to_players_which_is_gained_each' } },
        { column = 'started', name = 'started', caption = { 'mtn_v3_highscore.start_date' }, tooltip = { 'mtn_v3_highscore.start_date_of_the_season' } },
        { column = 'ended', name = 'ended', caption = { 'mtn_v3_highscore.stop_date' }, tooltip = { 'mtn_v3_highscore.stop_date_of_the_season' } }
    }

    local width = math.max(480, Style.content_width(player, frame))
    local widths = Style.column_widths(width, { 70, 122, 94, 110, 110, 110 }, Style.spacing.xs)
    local sorting_pref = this.sort_by[player.index]
    for index, header in ipairs(headers) do
        local cap = header.caption

        -- Add sorting symbol if any
        if header.column and sorting_pref.column == header.column then
            local symbol = sorting_symbol[sorting_pref.method]
            cap = { '', symbol, ' ', cap }
        end

        -- Header
        local label =
            t.add
            {
                type = 'label',
                caption = cap,
                tooltip = header.tooltip or '',
                name = header.name
            }
        Style.table_heading(label)
        label.style.width = widths[index]
        label.style.horizontal_align = 'center'
    end

    -- Score list
    local score_list = get_score_list()
    sort_list(sorting_pref.method, sorting_pref.column, score_list)

    for _, score_data in ipairs(score_list) do
        for index, header in ipairs(headers) do
            local caption = score_data[header.column] or 'N/A'
            local label =
                t.add
                {
                    type = 'label',
                    caption = caption,
                    tooltip = tostring(caption)
                }
            label.style.font = 'default'
            label.style.font_color = Style.colors.text
            label.style.bottom_padding = Style.spacing.xs
            label.style.width = widths[index]
            label.style.single_line = true
            label.style.horizontal_align = 'center'
        end
    end
end

local show_score_token = Task.register(show_score)

local function on_gui_click(event)
    local element = event.element
    if not element or not element.valid then
        return
    end

    local player = game.get_player(event.element.player_index)
    if not player then
        return
    end

    local frame = Gui.get_player_active_frame(player)
    if not frame then
        return
    end
    if frame.name ~= 'Seasons' then
        return
    end

    local is_spamming = SpamProtection.is_spamming(player, nil, 'Season Gui Click')
    if is_spamming then
        return
    end

    local name = event.element.name

    -- Handles click on a score header
    local element_to_column =
    {
        ['season_index'] = 'season_index',
        ['rounds_survived'] = 'rounds_survived',
        ['best_streak'] = 'best_streak',
        ['buffs_granted'] = 'buffs_granted',
        ['started'] = 'started',
        ['ended'] = 'ended'
    }
    local column = element_to_column[name]
    if column then
        local sorting_pref = this.sort_by[player.index]
        if sorting_pref.column == column and sorting_pref.method == 'descending' then
            sorting_pref.method = 'ascending'
        else
            sorting_pref.method = 'descending'
            sorting_pref.column = column
        end
        show_score({ player = player, frame = frame })
        return
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if not this.sort_by[player.index] then
        this.sort_by[player.index] = { method = 'descending', column = 'season_index' }
    end
end

local function on_player_left_game(event)
    local player = game.players[event.player_index]
    if this.sort_by[player.index] then
        this.sort_by[player.index] = nil
    end
end

Server.on_data_set_changed(
    score_dataset,
    function (data)
        if data.value then
            this.seasons = data.value
        end
    end
)

Server.on_data_set_changed(
    score_key_dev,
    function (data)
        if data.value then
            this.seasons = data.value
        end
    end
)

Gui.add_tab_to_gui({ name = module_name, caption = 'Seasons', localised_caption = { 'mtn_v3_highscore.seasons' }, id = show_score_token, admin = false, only_server_sided = true })

Gui.on_click(
    module_name,
    function (event)
        local player = event.player
        Gui.reload_active_tab(player, nil, 'Seasons')
    end
)

Event.add(defines.events.on_player_left_game, on_player_left_game)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(ServerCommands.events.on_server_started, Public.get_season_scores)

return Public
