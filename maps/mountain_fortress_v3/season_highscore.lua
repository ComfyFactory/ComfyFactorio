local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local Global = require 'utils.global'
local Server = require 'utils.server'
local Gui = require 'utils.gui'
local Task = require 'utils.task_token'
local SpamProtection = require 'utils.spam_protection'

local module_name = Gui.uid_name()
local score_dataset = 'seasons'
local score_key = 'mtn_v3'
local score_key_dev = 'mtn_v3_dev'
local set_data = Server.set_data
local try_get_data = Server.try_get_data

local insert = table.insert

local this = {
    seasons = {},
    sort_by = {}
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local function sort_list(method, column_name, score_list)
    local comparators = {
        ['ascending'] = function(a, b)
            return a[column_name] < b[column_name]
        end,
        ['descending'] = function(a, b)
            return a[column_name] > b[column_name]
        end
    }

    table.sort(score_list, comparators[method])
    return score_list
end

local function write_additional_stats(key)
    local current_date = Server.get_current_date(true)
    if not current_date then
        return
    end

    local season = Public.get_stateful('season')
    local rounds_survived = Public.get_stateful('rounds_survived')
    local total_buffs = Public.get_stateful('total_buffs')
    local previous_raw_date = Public.get_stateful('current_date')

    local previous_date = Server.get_current_date(true, false, previous_raw_date)
    if not previous_date then
        return
    end

    this.seasons[#this.seasons] = {
        season_index = season,
        rounds_survived = rounds_survived,
        buffs_granted = total_buffs,
        started = previous_date,
        ended = current_date
    }

    if key then
        set_data(score_dataset, key, this.seasons)
    end
end

local get_scores =
    Task.register(
    function(data)
        local value = data.value
        this.seasons = value
    end
)

function Public.get_season_scores()
    local secs = Server.get_current_time()
    if not secs then
        return
    else
        local server_name_matches = Server.check_server_name('Mtn Fortress')
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
        local server_name_matches = Server.check_server_name('Mtn Fortress')
        if server_name_matches then
            write_additional_stats(score_key)
        else
            write_additional_stats(score_key_dev)
        end
    end
end

local function on_init()
    local secs = Server.get_current_time()
    if not secs then
        write_additional_stats()
        return
    end
end

local sorting_symbol = {ascending = '▲', descending = '▼'}

local function get_score_list()
    local seasons = this.seasons
    local score_list = {}
    if not seasons then
        score_list[#score_list + 1] = {
            season_index = 'N/A',
            rounds_survived = 'N/A',
            buffs_granted = 'N/A',
            started = 'N/A',
            ended = 'N/A'
        }
        return score_list
    end

    for _, data in pairs(seasons) do
        insert(
            score_list,
            {
                season_index = data.season_index,
                rounds_survived = data.rounds_survived,
                buffs_granted = data.buffs_granted,
                started = data.started,
                ended = data.ended
            }
        )
    end
    return score_list
end

local function show_score(data)
    local player = data.player
    local frame = data.frame
    frame.clear()

    local flow = frame.add {type = 'flow'}
    local sFlow = flow.style
    sFlow.horizontally_stretchable = true
    sFlow.horizontal_align = 'center'
    sFlow.vertical_align = 'center'

    -- Score per player
    local t = frame.add {type = 'table', column_count = 5}

    -- Score headers
    local headers = {
        {column = 'season_index', name = 'season_index', caption = 'Season', tooltip = 'Season index.'},
        {column = 'rounds_survived', name = 'rounds_survived', caption = 'Rounds survived', tooltip = 'Rounds survived in the season.'},
        {column = 'buffs_granted', name = 'buffs_granted', caption = 'Buffs granted', tooltip = 'Buffs granted to players which is gained each round won.'},
        {column = 'started', name = 'started', caption = 'Start date', tooltip = 'Start date of the season.'},
        {column = 'ended', name = 'ended', caption = 'Stop date', tooltip = 'Stop date of the season.'}
    }

    local sorting_pref = this.sort_by[player.index]
    for _, header in ipairs(headers) do
        local cap = header.caption

        -- Add sorting symbol if any
        if header.column and sorting_pref.column == header.column then
            local symbol = sorting_symbol[sorting_pref.method]
            cap = symbol .. cap
        end

        -- Header
        local label =
            t.add {
            type = 'label',
            caption = cap,
            tooltip = header.tooltip or '',
            name = header.name
        }
        label.style.font = 'default-listbox'
        label.style.font_color = {r = 0.98, g = 0.66, b = 0.22} -- yellow
        label.style.minimal_width = 125
        label.style.horizontal_align = 'center'
    end

    -- Score list
    local score_list = get_score_list()

    score_list = sort_list(sorting_pref.method, sorting_pref.column, score_list)

    -- New pane for scores (while keeping headers at same position)
    local scroll_pane =
        frame.add(
        {
            type = 'scroll-pane',
            name = 'score_scroll_pane',
            direction = 'vertical',
            horizontal_scroll_policy = 'never',
            vertical_scroll_policy = 'auto'
        }
    )
    scroll_pane.style.maximal_height = 400
    scroll_pane.style.minimal_width = 700

    t = scroll_pane.add {type = 'table', column_count = 5}

    -- Score entries
    local i = 0
    for _, score_data in pairs(score_list) do
        i = i + 1

        local lines = {
            {caption = score_data.season_index},
            {caption = score_data.rounds_survived},
            {caption = score_data.buffs_granted},
            {caption = score_data.started},
            {caption = score_data.ended}
        }
        local default_color = {r = 0.9, g = 0.9, b = 0.9}

        for _, column in ipairs(lines) do
            local label =
                t.add {
                type = 'label',
                caption = column.caption,
                color = column.color or default_color
            }
            label.style.font = 'default'
            label.style.minimal_width = 125
            label.style.maximal_width = 150
            label.style.horizontal_align = 'center'
        end -- foreach column
    end -- foreach entry
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
    local element_to_column = {
        ['season_index'] = 'season_index',
        ['rounds_survived'] = 'rounds_survived',
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
        show_score({player = player, frame = frame})
        return
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if not this.sort_by[player.index] then
        this.sort_by[player.index] = {method = 'descending', column = 'season_index'}
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
    function(data)
        if data.value then
            this.seasons = data.value
        end
    end
)

Server.on_data_set_changed(
    score_key_dev,
    function(data)
        if data.value then
            this.seasons = data.value
        end
    end
)

Gui.add_tab_to_gui({name = module_name, caption = 'Seasons', id = show_score_token, admin = false, only_server_sided = true})

Gui.on_click(
    module_name,
    function(event)
        local player = event.player
        Gui.reload_active_tab(player)
    end
)

Event.on_init(on_init)
Event.add(defines.events.on_player_left_game, on_player_left_game)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(Server.events.on_server_started, Public.get_season_scores)

return Public
