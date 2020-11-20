local Event = require 'utils.event'
local Global = require 'utils.global'
local Server = require 'utils.server'
local Token = require 'utils.token'
local Tabs = require 'comfy_panel.main'
local WPT = require 'maps.mountain_fortress_v3.table'

local score_dataset = 'highscores'
local set_data = Server.set_data
local try_get_data = Server.try_get_data

local Public = {}
local insert = table.insert
local random = math.random
local this = {
    score_table = {},
    sort_by = {}
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local biters = {
    'small-biter',
    'medium-biter',
    'big-biter',
    'behemoth-biter',
    'small-spitter',
    'medium-spitter',
    'big-spitter',
    'behemoth-spitter'
}
local function get_total_biter_killcount(force)
    local count = 0
    for _, biter in pairs(biters) do
        count = count + force.kill_count_statistics.get_input_count(biter)
    end
    return count
end

local function get_additional_stats(key)
    if not this.score_table['player'] then
        this.score_table['player'] = {}
    end

    local player = game.forces.player
    local breached_zone = WPT.get('breached_wall')
    local c = get_total_biter_killcount(player)
    local t = this.score_table['player']
    t.rockets_launched = player.rockets_launched
    t.biters_killed = c
    if breached_zone == 1 then
        t.breached_zone = breached_zone
    else
        t.breached_zone = breached_zone - 1
    end

    set_data(score_dataset, key, t)
end

local get_scores =
    Token.register(
    function(data)
        local value = data.value
        if not this.score_table['player'] then
            this.score_table['player'] = {}
        end

        this.score_table['player'] = value
    end
)

function Public.get_scores()
    local secs = Server.get_current_time()
    local key = 'mountain_fortress_v3_scores'
    if not secs then
        return
    else
        try_get_data(score_dataset, key, get_scores)
    end
end

function Public.set_scores(key)
    local secs = Server.get_current_time()
    key = tostring(key)
    if not secs then
        return
    else
        get_additional_stats(key)
    end
end

local sorting_symbol = {ascending = '▲', descending = '▼'}

local function get_score_list()
    local score_force = this.score_table['player']
    local score_list = {}
    if not score_force then
        score_list[#score_list + 1] = {
            name = 'Nothing here yet',
            killscore = 0,
            deaths = 0,
            built_entities = 0,
            mined_entities = 0
        }
        return score_list
    end
    for p, _ in pairs(score_force.players) do
        if score_force.players[p] then
            local score = score_force.players[p]
            insert(
                score_list,
                {
                    name = p,
                    killscore = score.killscore or 0,
                    deaths = score.deaths or 0,
                    built_entities = score.built_entities or 0,
                    mined_entities = score.mined_entities or 0
                }
            )
        end
    end
    return score_list
end

local function get_sorted_list(method, column_name, score_list)
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

local function add_global_stats(frame)
    local score = this.score_table['player']

    local t = frame.add {type = 'table', column_count = 6}

    local l = t.add {type = 'label', caption = 'Rockets launched: '}
    l.style.font = 'default-game'
    l.style.font_color = {r = 175, g = 75, b = 255}
    l.style.minimal_width = 140

    local l = t.add {type = 'label', caption = score.rockets_launched}
    l.style.font = 'default-listbox'
    l.style.font_color = {r = 0.9, g = 0.9, b = 0.9}
    l.style.minimal_width = 123

    local l = t.add {type = 'label', caption = 'Dead bugs: '}
    l.style.font = 'default-game'
    l.style.font_color = {r = 0.90, g = 0.3, b = 0.3}
    l.style.minimal_width = 100

    local l = t.add {type = 'label', caption = score.biters_killed}
    l.style.font = 'default-listbox'
    l.style.font_color = {r = 0.9, g = 0.9, b = 0.9}
    l.style.minimal_width = 145

    local l = t.add {type = 'label', caption = 'Breached zones: '}
    l.style.font = 'default-game'
    l.style.font_color = {r = 0, g = 128, b = 0}
    l.style.minimal_width = 100

    local l = t.add {type = 'label', caption = score.breached_zone - 1}
    l.style.font = 'default-listbox'
    l.style.font_color = {r = 0.9, g = 0.9, b = 0.9}
    l.style.minimal_width = 145
end

local show_score = (function(player, frame)
    frame.clear()

    local flow = frame.add {type = 'flow'}
    local sFlow = flow.style
    sFlow.horizontally_stretchable = true
    sFlow.horizontal_align = 'center'
    sFlow.vertical_align = 'center'

    local stats = flow.add {type = 'label', caption = 'Previous game statistics!'}
    local s_stats = stats.style
    s_stats.font = 'heading-1'
    s_stats.font_color = {r = 0.98, g = 0.66, b = 0.22}
    s_stats.horizontal_align = 'center'
    s_stats.vertical_align = 'center'

    -- Global stats : rockets, biters kills
    add_global_stats(frame)

    -- Separator
    local line = frame.add {type = 'line'}
    line.style.top_margin = 8
    line.style.bottom_margin = 8

    -- Score per player
    local t = frame.add {type = 'table', column_count = 5}

    -- Score headers
    local headers = {
        {name = 'score_player', caption = 'Player'},
        {column = 'killscore', name = 'score_killscore', caption = 'Killscore'},
        {column = 'deaths', name = 'score_deaths', caption = 'Deaths'},
        {column = 'built_entities', name = 'score_built_entities', caption = 'Built structures'},
        {column = 'mined_entities', name = 'score_mined_entities', caption = 'Mined entities'}
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
            name = header.name
        }
        label.style.font = 'default-listbox'
        label.style.font_color = {r = 0.98, g = 0.66, b = 0.22} -- yellow
        label.style.minimal_width = 150
        label.style.horizontal_align = 'right'
    end

    -- Score list
    local score_list = get_score_list()

    if #game.connected_players > 1 then
        score_list = get_sorted_list(sorting_pref.method, sorting_pref.column, score_list)
    end

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
    local t = scroll_pane.add {type = 'table', column_count = 5}

    -- Score entries
    for _, entry in pairs(score_list) do
        local p
        if not (entry and entry.name) then
            p = {color = {r = random(1, 255), g = random(1, 255), b = random(1, 255)}}
        else
            p = game.players[entry.name]
            if not p then
                p = {color = {r = random(1, 255), g = random(1, 255), b = random(1, 255)}}
            end
        end
        local special_color = {
            r = p.color.r * 0.6 + 0.4,
            g = p.color.g * 0.6 + 0.4,
            b = p.color.b * 0.6 + 0.4,
            a = 1
        }
        local line = {
            {caption = entry.name, color = special_color},
            {caption = tostring(entry.killscore)},
            {caption = tostring(entry.deaths)},
            {caption = tostring(entry.built_entities)},
            {caption = tostring(entry.mined_entities)}
        }
        local default_color = {r = 0.9, g = 0.9, b = 0.9}

        for _, column in ipairs(line) do
            local label =
                t.add {
                type = 'label',
                caption = column.caption,
                color = column.color or default_color
            }
            label.style.font = 'default'
            label.style.minimal_width = 150
            label.style.maximal_width = 150
            label.style.horizontal_align = 'right'
        end -- foreach column
    end -- foreach entry
end) -- show_score

comfy_panel_tabs['HighScore'] = {gui = show_score, admin = false}

local function on_gui_click(event)
    if not event then
        return
    end
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end

    local player = game.players[event.element.player_index]
    local frame = Tabs.comfy_panel_get_active_frame(player)
    if not frame then
        return
    end
    if frame.name ~= 'HighScore' then
        return
    end

    local name = event.element.name

    -- Handles click on the checkbox, for floating score
    if name == 'show_floating_killscore_texts' then
        global.show_floating_killscore[player.name] = event.element.state
        return
    end

    -- Handles click on a score header
    local element_to_column = {
        ['score_killscore'] = 'killscore',
        ['score_deaths'] = 'deaths',
        ['score_built_entities'] = 'built_entities',
        ['score_mined_entities'] = 'mined_entities'
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
        show_score(player, frame)
        return
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if not this.sort_by[player.index] then
        this.sort_by[player.index] = {method = 'descending', column = 'killscore'}
    end
end

local function on_player_left_game(event)
    local player = game.players[event.player_index]
    if this.sort_by[player.index] then
        this.sort_by[player.index] = nil
    end
end

Event.add(defines.events.on_player_left_game, on_player_left_game)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(Server.events.on_server_started, Public.get_scores)

return Public
