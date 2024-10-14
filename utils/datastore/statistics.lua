-- created by Gerkiz for ComfyFactorio
local Global = require 'utils.global'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Server = require 'utils.server'
local Event = require 'utils.event'

local set_timeout_in_ticks = Task.set_timeout_in_ticks
local statistics_dataset = 'statistics'

local set_data = Server.set_data
local try_get_data = Server.try_get_data
local e = defines.events
local floor = math.floor

local events = {
    map_tags_made = e.on_chart_tag_added,
    chat_messages = e.on_console_chat,
    commands_used = e.on_console_command,
    machines_built = e.on_built_entity,
    items_picked_up = e.on_picked_up_item,
    tiles_built = e.on_player_built_tile,
    join_count = e.on_player_joined_game,
    deaths = e.on_player_died,
    entities_repaired = e.on_player_repaired_entity,
    items_crafted = e.on_player_crafted_item,
    capsules_used = e.on_player_used_capsule,
    tiles_removed = e.on_player_mined_tile,
    deconstructer_planner_used = e.on_player_deconstructed_area
}

local settings = {
    required_only_time_to_save_time = 10 * 3600,
    afk_time = 5 * 3600,
    nth_tick = 5 * 3600
}

local Public = {
    events = {
        on_player_removed = Event.generate_event_name('on_player_removed')
    }
}

local normalized_names = {
    ['map_tags_made'] = { name = 'Map-tags created', tooltip = "Tags that you've created in minimap." },
    ['chat_messages'] = { name = 'Messages', tooltip = 'Messages sent in chat.' },
    ['commands_used'] = { name = 'Commands', tooltip = 'Commands used in console.' },
    ['machines_built'] = { name = 'Entities built', tooltip = 'Entities built by the player.' },
    ['items_picked_up'] = { name = 'Items picked-up', tooltip = 'Items picked-up by the player.' },
    ['tiles_built'] = { name = 'Tiles placed', tooltip = 'Tiles placed by the player.' },
    ['join_count'] = { name = 'Join count', tooltip = 'How many times the player has joined the game.' },
    ['deaths'] = { name = 'Deaths', tooltip = 'How many times the player has died.' },
    ['entities_repaired'] = { name = 'Entities repaired', tooltip = 'How many entities the player has repaired.' },
    ['items_crafted'] = { name = 'Items crafted', tooltip = 'How many items the player has crafted.' },
    ['capsules_used'] = { name = 'Capsules used', tooltip = 'How many capsules the player has used.' },
    ['tiles_removed'] = { name = 'Tiles removed', tooltip = 'How many tiles the player has removed.' },
    ['deconstructer_planner_used'] = { name = 'Decon planner used', tooltip = 'How many times the player has used the deconstruction planner.' },
    ['maps_played'] = { name = 'Maps played', tooltip = 'How many maps the player has played.' },
    ['afk_time'] = { name = 'Total AFK', tooltip = 'How long the player has been AFK.' },
    ['distance_moved'] = { name = 'Distance travelled', tooltip = 'How far the player has travelled.\nIncluding standing still in looped belts.' },
    ['damage_dealt'] = { name = 'Damage dealt', tooltip = 'How much damage the player has dealt.' },
    ['enemies_killed'] = { name = 'Enemies killed', tooltip = 'How many enemies the player has killed.' },
    ['friendly_killed'] = { name = 'Friendlies killed', tooltip = 'How many friendlies the player has killed.\n This includes entities such as buildings etc.' },
    ['rockets_launched'] = { name = 'Rockets launched', tooltip = 'How many rockets the player has launched.' },
    ['research_complete'] = { name = 'Research completed', tooltip = 'How many researches the player has completed.' },
    ['force_mined_machines'] = { name = 'Mined friendly entities', tooltip = 'How many friendly entities the player has mined.' },
    ['trees'] = { name = 'Trees chopped', tooltip = 'How many trees the player has chopped.' },
    ['rocks'] = { name = 'Rocks mined', tooltip = 'How many rocks the player has mined.' },
    ['resources'] = { name = 'Ores mined', tooltip = 'How many ores the player has mined.' },
    ['kicked'] = { name = 'Kicked', tooltip = 'How many times the player has been kicked.' }
}
local statistics = {}

-- Register the statistics table in the global table
Global.register(
    {
        statistics = statistics
    },
    function (tbl)
        statistics = tbl.statistics

        for _, stat in pairs(statistics) do
            setmetatable(stat, Public.metatable)
        end
    end
)

-- Metatable for the statistics table
Public.metatable = { __index = Public }

-- Add a normalization entry to the normalized_names table
function Public.add_normalize(name, normalize)
    if _LIFECYCLE == _STAGE.runtime then
        error('cannot call during runtime', 2)
    end

    local mt = setmetatable({ name = normalize }, Public.metatable)

    normalized_names[name] = mt

    return mt
end

-- Set the tooltip for a statistic
function Public:set_tooltip(tooltip)
    if _LIFECYCLE == _STAGE.runtime then
        error('cannot call during runtime', 2)
    end

    self.tooltip = tooltip
end

--- Returns the player table or false
---@param player LuaPlayer|number
---@return any
local function get_data(player)
    local player_index = player and type(player) == 'number' and player or player and player.valid and player.index or false
    if not player_index then
        log('Invalid player index at get_data')
        return false
    end

    local data = statistics[player_index]

    if not data then
        local p = game.get_player(player_index)
        local name = p and p.valid and p.name or nil
        local player_data = {
            name = name,
            tick = 0
        }

        for event, _ in pairs(events) do
            player_data[event] = 0
        end

        local mt = setmetatable(player_data, Public.metatable)

        statistics[player_index] = mt
    end

    return statistics[player_index]
end

local try_download_data_token =
    Token.register(
        function (data)
            local player_name = data.key
            local player = game.get_player(player_name)
            if not player or not player.valid then
                return
            end

            local stats = data.value
            if stats then
                local s = setmetatable(stats, Public.metatable)
                statistics[player.index] = s
            else
                get_data(player)
            end
        end
    )

local try_upload_data_token =
    Token.register(
        function (data)
            local player_name = data.key
            if not player_name then
                return
            end
            local stats = data.value
            local player = game.get_player(player_name)
            if not player or not player.valid then
                return
            end

            if stats then
                -- we don't want to clutter the database with players less than 10 minutes played.
                if player.online_time <= settings.required_only_time_to_save_time then
                    return
                end

                set_data(statistics_dataset, player_name, get_data(player))
            else
                local d = get_data(player)
                if player.online_time >= settings.required_only_time_to_save_time then
                    set_data(statistics_dataset, player_name, d)
                end
            end
        end
    )

-- Increase a statistic by a delta value
function Public:increase(name, delta)
    if not self[name] then
        self[name] = 0
    end

    self[name] = self[name] + (delta or 1)

    self.tick = self.tick + 1

    return self
end

-- Save the player's statistics
function Public:save()
    local player = game.get_player(self.name)
    if not player or not player.valid then
        return
    end

    if player.online_time <= settings.required_only_time_to_save_time then
        return
    end

    if self.tick < 10 then
        return
    end

    set_data(statistics_dataset, player.name, self)
    return self
end

-- Clear the player's statistics
function Public:clear(force_clear)
    if force_clear then
        statistics[self.name] = nil
    else
        local player = game.get_player(self.name)
        if not player or not player.valid then
            statistics[self.name] = nil
            return
        end
        local connected = player.connected

        if not connected then
            statistics[self.name] = nil
        end
    end
end

-- Try to get the player's data from the dataset
function Public:try_get_data()
    try_get_data(statistics_dataset, self.name, try_download_data_token)
    return self
end

-- Try to upload the player's data to the dataset
function Public:try_upload_data()
    try_get_data(statistics_dataset, self.name, try_upload_data_token)
    return self
end

local nth_tick_token =
    Token.register(
        function (event)
            local player_index = event.player_index
            local player = game.get_player(player_index)
            if not player or not player.valid then
                return
            end

            get_data(player):save()
        end
    )

--- Uploads each connected players play time to the dataset
local function upload_data()
    local players = game.connected_players
    local count = 0
    for i = 1, #players do
        count = count + 10
        local player = players[i]
        set_timeout_in_ticks(count, nth_tick_token, { player_index = player.index })
    end
end

--- Checks if a player exists within the table
---@param player_index string
---@return boolean
function Public.exists(player_index)
    return statistics[player_index] ~= nil
end

--- Returns the table of statistics
---@param player LuaPlayer
---@return table|boolean
function Public.get_player(player)
    return statistics and player and player.valid and statistics[player.index] or false
end

-- Event handlers

Event.add(
    e.on_player_joined_game,
    function (event)
        get_data(event.player_index):try_get_data()
    end
)

Event.add(
    e.on_player_left_game,
    function (event)
        get_data(event.player_index):try_upload_data()
    end
)

Event.add(
    Public.events.on_player_removed,
    function (event)
        local player_index = event.player_index
        statistics[player_index] = nil
    end
)

Event.add(
    e.on_player_removed,
    function (event)
        local player_index = event.player_index
        statistics[player_index] = nil
    end
)

Event.on_nth_tick(settings.nth_tick, upload_data)

Server.on_data_set_changed(
    statistics_dataset,
    function (data)
        local player = game.get_player(data.key)
        if player and player.valid then
            local stats = data.value
            if stats then
                local s = setmetatable(stats, Public.metatable)
                statistics[data.key] = s
            end
        end
    end
)

local function on_marked_for_deconstruction_on_player_mined_entity(event)
    if not event.player_index then
        return
    end

    local player = game.get_player(event.player_index)
    if not player.valid or not player.connected then
        return
    end
    local entity = event.entity
    if not entity.valid then
        return
    end

    local data = get_data(event.player_index)
    if entity.type == 'resource' then
        data:increase('resources')
    elseif entity.type == 'tree' then
        data:increase('trees')
    elseif entity.type == 'simple-entity' then
        data:increase('rocks')
    elseif entity.force == player.force then
        data:increase('force_mined_machines')
    end
end

for stat_name, event_name in pairs(events) do
    Event.add(
        event_name,
        function (event)
            if not event.player_index then
                return
            end
            local player = game.get_player(event.player_index)
            if not player or not player.valid or not player.connected then
                return
            end
            local data = get_data(event.player_index)
            data:increase(stat_name)
        end
    )
end

Event.add(
    e.on_research_finished,
    function (event)
        local research = event.research
        if event.by_script or not research or not research.valid then
            return
        end
        local force = research.force
        if not force or not force.valid then
            return
        end
        for _, player in pairs(force.connected_players) do
            local data = get_data(player)
            data:increase('research_complete')
        end
    end
)

Event.add(
    e.on_rocket_launched,
    function (event)
        local silo = event.rocket_silo
        if not silo or not silo.valid then
            return
        end
        local force = silo.force
        if not force or not force.valid then
            return
        end
        for _, player in pairs(force.connected_players) do
            local data = get_data(player)
            data:increase('rockets_launched')
        end
    end
)

Event.add(
    e.on_entity_died,
    function (event)
        local character = event.cause
        if not character or not character.valid or character.type ~= 'character' then
            return
        end
        local player = character.player
        if not player or not player.valid or not player.connected then
            return
        end
        local entity = event.entity
        if not entity.valid or entity.force.name == 'neutral' then
            return
        end
        local data = get_data(player)
        if entity.force == player.force then
            data:increase('friendly_killed')
            return
        end
        data:increase('enemies_killed')
    end
)

Event.add(
    e.on_entity_damaged,
    function (event)
        local character = event.cause
        if not character or not character.valid or character.type ~= 'character' then
            return
        end
        local player = character.player
        if not player or not player.valid or not player.connected then
            return
        end
        local entity = event.entity
        if not entity.valid or entity.force == player.force or entity.force.name == 'neutral' then
            return
        end

        local final_damage = event.final_damage_amount

        local data = get_data(player)
        data:increase('damage_dealt', floor(final_damage))
    end
)

Event.add(
    e.on_player_changed_position,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid or not player.connected or player.afk_time > settings.required_only_time_to_save_time then
            return
        end
        local data = get_data(event.player_index)
        data:increase('distance_moved')
    end
)

Event.on_nth_tick(
    3600,
    function ()
        if game.tick == 0 then
            return
        end
        for _, player in pairs(game.connected_players) do
            local data = get_data(player)
            if player.afk_time > settings.afk_time then
                data:increase('afk_time')
            end
        end
    end
)

Event.add(
    e.on_player_created,
    function (event)
        get_data(event.player_index):increase('maps_played')
    end
)

Event.add(
    e.on_player_kicked,
    function (event)
        get_data(event.player_index):increase('kicked')
    end
)

Event.add(e.on_marked_for_deconstruction, on_marked_for_deconstruction_on_player_mined_entity)
Event.add(e.on_player_mined_entity, on_marked_for_deconstruction_on_player_mined_entity)

Public.upload_data = upload_data
Public.get_data = get_data
Public.normalized_names = normalized_names

return Public
