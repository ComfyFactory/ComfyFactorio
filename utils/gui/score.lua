--scoreboard by mewmew
-- modified by Gerkiz

local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Style = require 'utils.gui_style'
local SpamProtection = require 'utils.spam_protection'
local Token = require 'utils.token'
local format_number = require 'util'.format_number

local Public = {}
local this =
{
    score_table = {},
    sort_by = {}
}

local module_name = Gui.uid_name()

Global.register(
    this,
    function (t)
        this = t
    end
)

local sorting_symbol = { ascending = '▲', descending = '▼' }
local building_and_mining_blacklist =
{
    ['tile-ghost'] = true,
    ['entity-ghost'] = true,
    ['item-entity'] = true
}

function Public.get_table()
    return this
end

function Public.reset_tbl()
    this.score_table['player'] =
    {
        players = {}
    }
end

function Public.init_player_table(player, reset)
    if not player then
        return
    end
    if not this.score_table then return end
    if not this.score_table[player.force.name] then this.score_table[player.force.name] = { players = {} } end

    local tbl_force = this.score_table[player.force.name]

    if reset then
        tbl_force.players[player.name] =
        {
            built_entities = 0,
            deaths = 0,
            killscore = 0,
            mined_entities = 0,
            crafted_items = 0
        }
    end

    if not tbl_force then
        tbl_force = {}
    end

    if not tbl_force.players then
        tbl_force.players = {}
    end

    if not player.name then return end

    if not tbl_force.players[player.name] then
        tbl_force.players[player.name] =
        {
            built_entities = 0,
            deaths = 0,
            killscore = 0,
            mined_entities = 0,
            crafted_items = 0
        }
    end
end

local function get_score_list(force)
    local score_force = this.score_table[force]
    local score_list = {}
    for _, p in pairs(game.connected_players) do
        if score_force.players[p.name] then
            local score = score_force.players[p.name]
            table.insert(
                score_list,
                {
                    name = p.name,
                    color = p.color,
                    killscore = score.killscore or 0,
                    deaths = score.deaths or 0,
                    built_entities = score.built_entities or 0,
                    mined_entities = score.mined_entities or 0,
                    crafted_items = score.crafted_items or 0
                }
            )
        end
    end
    if _DEBUG then
        local fake_players =
        {
            { name = 'Belt Enjoyer', color = { r = 0.2, g = 0.75, b = 0.3 }, killscore = 1280, deaths = 3, built_entities = 420, mined_entities = 8600, crafted_items = 1500 },
            { name = 'Smelter', color = { r = 0.9, g = 0.45, b = 0.1 }, killscore = 90, deaths = 1, built_entities = 2100, mined_entities = 540, crafted_items = 9800 },
            { name = 'Admin Faker', color = { r = 0.85, g = 0.15, b = 0.15 }, killscore = 9000, deaths = 11, built_entities = 640, mined_entities = 120, crafted_items = 300 },
            { name = 'Trainman', color = { r = 0.3, g = 0.55, b = 0.95 }, killscore = 15, deaths = 0, built_entities = 80, mined_entities = 40, crafted_items = 25 },
            { name = 'Oil King', color = { r = 0.15, g = 0.15, b = 0.15 }, killscore = 320, deaths = 6, built_entities = 1100, mined_entities = 24000, crafted_items = 760 },
            { name = 'Very Long Faker Like So Long', color = { r = 0.7, g = 0.4, b = 0.9 }, killscore = 2, deaths = 8, built_entities = 12, mined_entities = 3, crafted_items = 1 }
        }
        for i = 1, #fake_players do
            score_list[#score_list + 1] = fake_players[i]
        end
    end
    return score_list
end

local function get_sorted_list(method, column_name, score_list)
    local comparators =
    {
        ['ascending'] = function (a, b)
            return a[column_name] < b[column_name]
        end,
        ['descending'] = function (a, b)
            return a[column_name] > b[column_name]
        end
    }
    table.sort(score_list, comparators[method])
    return score_list
end

local biters =
{
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
        for _, surface in pairs(game.surfaces) do
            count = count + force.get_kill_count_statistics(surface).get_input_count(biter)
        end
    end
    return count
end

local function add_global_stats(frame, player)
    local flow = Style.toolbar(frame)
    Style.metric(flow, 'Rockets launched', format_number(player.force.rockets_launched, true))
    Style.metric(flow, 'Enemies killed', format_number(get_total_biter_killcount(player.force), true))
end

local function show_score(data)
    local player = data.player
    local frame = data.frame
    frame.clear()

    Public.init_player_table(player)

    -- Global stats : rockets, biters kills
    add_global_stats(frame, player)

    -- Separator
    local line = frame.add { type = 'line' }
    line.style.top_margin = 2
    line.style.bottom_margin = 2

    -- Score headers
    local content_width = math.max(480, Style.content_width(player, frame))
    local player_width = content_width >= 730 and 214 or 128
    local headers =
    {
        { name = 'score_player', caption = 'Player', width = player_width, align = 'left' },
        { column = 'killscore', name = 'score_killscore', caption = 'Killscore', width = 84, align = 'center' },
        { column = 'deaths', name = 'score_deaths', caption = 'Deaths', width = 56, align = 'center' },
        { column = 'built_entities', name = 'score_built_entities', caption = 'Built structures', width = 118, align = 'center' },
        { column = 'mined_entities', name = 'score_mined_entities', caption = 'Mined entities', width = 108, align = 'center' },
        { column = 'crafted_items', name = 'score_crafted_items', caption = 'Crafted items', width = 104, align = 'center' }
    }

    local preferred_widths = {}
    for i, header in ipairs(headers) do
        preferred_widths[i] = header.width
    end
    local widths = Style.column_widths(content_width, preferred_widths)
    for i, header in ipairs(headers) do
        header.width = widths[i]
    end

    local sorting_pref = this.sort_by[player.name]
    if not sorting_pref then
        sorting_pref = { method = 'descending', column = 'killscore' }
        this.sort_by[player.name] = sorting_pref
    end

    local header_table = frame.add { type = 'table', column_count = #headers }
    header_table.style.minimal_width = content_width
    header_table.style.horizontal_spacing = 0
    header_table.style.vertical_spacing = 0
    header_table.style.top_cell_padding = 0
    header_table.style.bottom_cell_padding = 0
    for _, header in ipairs(headers) do
        local cap = header.caption

        -- Add sorting symbol if any
        if header.column and sorting_pref.column == header.column then
            local symbol = sorting_symbol[sorting_pref.method]
            cap = '[color=yellow]' .. symbol .. '[/color] ' .. cap
        end

        -- Header
        local label =
            header_table.add
            {
                type = 'label',
                caption = cap,
                tooltip = header.caption,
                name = header.name
            }
        Style.table_heading(label)
        label.style.width = header.width
        label.style.single_line = true
        label.style.horizontal_align = header.align
        label.style.top_padding = 0
        label.style.bottom_padding = 0
    end

    local header_line = frame.add({ type = 'line', direction = 'horizontal' })
    header_line.style.minimal_width = content_width
    header_line.style.horizontally_stretchable = true
    header_line.style.top_margin = 0
    header_line.style.bottom_margin = 0

    -- Score list
    local score_list = get_score_list(player.force.name)

    if #score_list > 1 then
        score_list = get_sorted_list(sorting_pref.method, sorting_pref.column, score_list)
    end

    local score_flow = frame.add { type = 'flow', direction = 'vertical' }
    score_flow.style.minimal_width = content_width
    score_flow.style.vertical_spacing = 0

    -- Score entries
    for i = 1, #score_list do
        local entry = score_list[i]
        local base = entry.color or { r = 0.6, g = 0.6, b = 0.6 }
        local special_color =
        {
            r = base.r * 0.6 + 0.4,
            g = base.g * 0.6 + 0.4,
            b = base.b * 0.6 + 0.4,
            a = 1
        }
        local lines =
        {
            { caption = entry.name, color = special_color },
            { caption = format_number(tonumber(entry.killscore), true) },
            { caption = format_number(tonumber(entry.deaths), true) },
            { caption = format_number(tonumber(entry.built_entities), true) },
            { caption = format_number(tonumber(entry.mined_entities), true) },
            { caption = format_number(tonumber(entry.crafted_items), true) }
        }

        local row = score_flow.add { type = 'table', column_count = #headers }
        row.style.horizontal_spacing = 0
        row.style.vertical_spacing = 0
        row.style.top_cell_padding = 0
        row.style.bottom_cell_padding = 1
        for column_index, column in ipairs(lines) do
            local header = headers[column_index]
            local label =
                row.add
                {
                    type = 'label',
                    caption = column.caption,
                    tooltip = column.caption
                }
            label.style.font_color = column.color or Style.colors.text
            label.style.width = header.width
            label.style.single_line = true
            label.style.horizontal_align = header.align
            label.style.top_padding = 3
            label.style.bottom_padding = 3
        end
    end
end

local show_score_token = Token.register(show_score)

local function refresh_score_full()
    for _, player in pairs(game.connected_players) do
        local frame = Gui.get_player_active_frame(player)
        if frame then
            if frame.name ~= 'Scoreboard' then
                return
            end
            show_score({ player = player, frame = frame })
        end
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    Public.init_player_table(player)
    if not this.sort_by[player.name] then
        this.sort_by[player.name] = { method = 'descending', column = 'killscore' }
    end
end

local function on_gui_click(event)
    local element = event.element
    if not element or not element.valid then
        return
    end
    local player = game.get_player(event.player_index)
    local name = event.element.name

    local frame = Gui.get_player_active_frame(player)
    if not frame then
        return
    end
    if frame.name ~= 'Scoreboard' then
        return
    end

    -- Handles click on a score header
    local element_to_column =
    {
        ['score_killscore'] = 'killscore',
        ['score_deaths'] = 'deaths',
        ['score_built_entities'] = 'built_entities',
        ['score_mined_entities'] = 'mined_entities',
        ['score_crafted_items'] = 'crafted_items'
    }
    local column = element_to_column[name]
    if column then
        local is_spamming = SpamProtection.is_spamming(player, nil, 'Score Gui Column Click')
        if is_spamming then
            return
        end
        local sorting_pref = this.sort_by[player.name]
        if sorting_pref.column == column and sorting_pref.method == 'descending' then
            sorting_pref.method = 'ascending'
        else
            sorting_pref.method = 'descending'
            sorting_pref.column = column
        end
        show_score({ player = player, frame = frame })
        return
    end

    -- No more to handle
end

local function on_rocket_launched()
    refresh_score_full()
end

local entity_score_values =
{
    ['behemoth-biter'] = 100,
    ['behemoth-spitter'] = 100,
    ['behemoth-worm-turret'] = 300,
    ['big-biter'] = 30,
    ['big-spitter'] = 30,
    ['big-worm-turret'] = 300,
    ['biter-spawner'] = 200,
    ['medium-biter'] = 15,
    ['medium-spitter'] = 15,
    ['medium-worm-turret'] = 150,
    ['character'] = 1000,
    ['small-biter'] = 5,
    ['small-spitter'] = 5,
    ['small-worm-turret'] = 50,
    ['spitter-spawner'] = 200,
    ['gun-turret'] = 50,
    ['laser-turret'] = 150,
    ['flamethrower-turret'] = 300
}

local function train_type_cause(event)
    local players = {}
    if event.cause.train.passengers then
        for _, player in pairs(event.cause.train.passengers) do
            players[#players + 1] = player
        end
    end
    return players
end

local kill_causes =
{
    ['character'] = function (event)
        if not event.cause.player then
            return
        end
        return { event.cause.player }
    end,
    ['combat-robot'] = function (event)
        if not event.cause.last_user then
            return
        end
        if not game.players[event.cause.last_user.index] then
            return
        end
        return { game.players[event.cause.last_user.index] }
    end,
    ['car'] = function (event)
        local players = {}
        local driver = event.cause.get_driver()
        if driver then
            if driver.player then
                players[#players + 1] = driver.player
            end
        end
        local passenger = event.cause.get_passenger()
        if passenger then
            if passenger.player then
                players[#players + 1] = passenger.player
            end
        end
        return players
    end,
    ['spider-vehicle'] = function (event)
        local players = {}
        local driver = event.cause.get_driver()
        if driver then
            if driver.player then
                players[#players + 1] = driver.player
            end
        end
        local passenger = event.cause.get_passenger()
        if passenger then
            if passenger.player then
                players[#players + 1] = passenger.player
            end
        end
        return players
    end,
    ['locomotive'] = train_type_cause,
    ['cargo-wagon'] = train_type_cause,
    ['artillery-wagon'] = train_type_cause,
    ['fluid-wagon'] = train_type_cause
}

local function on_entity_died(event)
    if not event.entity.valid then
        return
    end
    if not event.cause then
        return
    end
    if not event.cause.valid then
        return
    end
    if event.entity.force.index == event.cause.force.index then
        return
    end
    if not entity_score_values[event.entity.name] then
        return
    end
    if not kill_causes[event.cause.type] then
        return
    end
    local players_to_reward = kill_causes[event.cause.type](event)
    if not players_to_reward then
        return
    end
    if #players_to_reward == 0 then
        return
    end
    for _, player in pairs(players_to_reward) do
        Public.init_player_table(player)
        local score = this.score_table[player.force.name].players[player.name]
        score.killscore = score.killscore + entity_score_values[event.entity.name]
    end
end

local function on_player_died(event)
    local player = game.players[event.player_index]
    Public.init_player_table(player)
    local score = this.score_table[player.force.name].players[player.name]
    score.deaths = 1 + (score.deaths or 0)
end

local function on_player_crafted_item(event)
    local player = game.players[event.player_index]
    Public.init_player_table(player)
    local score = this.score_table[player.force.name].players[player.name]
    score.crafted_items = 1 + (score.crafted_items or 0)
end

local function on_player_mined_entity(event)
    if not event.entity.valid then
        return
    end
    if building_and_mining_blacklist[event.entity.type] then
        return
    end

    local player = game.players[event.player_index]
    Public.init_player_table(player)
    local score = this.score_table[player.force.name].players[player.name]
    score.mined_entities = 1 + (score.mined_entities or 0)
end

local function on_built_entity(event)
    if not event.entity.valid then
        return
    end
    if building_and_mining_blacklist[event.entity.type] then
        return
    end
    local player = game.players[event.player_index]
    Public.init_player_table(player)
    local score = this.score_table[player.force.name].players[player.name]
    score.built_entities = 1 + (score.built_entities or 0)
end

Gui.add_tab_to_gui({ name = module_name, caption = 'Scoreboard', id = show_score_token, admin = false })

Gui.on_click(
    module_name,
    function (event)
        local player = event.player
        Gui.reload_active_tab(player, nil, 'Scoreboard')
    end
)

Event.on_init(function ()
    Public.reset_tbl()
end)

Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_player_crafted_item, on_player_crafted_item)
Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_rocket_launched, on_rocket_launched)

return Public
