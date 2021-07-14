local Global = require 'utils.global'
local Game = require 'utils.game'
local Core = require 'utils.core'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Server = require 'utils.server'
local Event = require 'utils.event'
local table = require 'utils.table'
local RPG = require 'modules.rpg.table'
local Color = require 'utils.color_presets'

local Public = {}

local set_timeout_in_ticks = Task.set_timeout_in_ticks

local this = {
    settings = {
        enabled = false,
        reset_after = 7, -- 7 days
        required_level_to_progress = 99, -- higher than 99 to be able to save
        limit = 39600, -- level 100
        dataset = 'rpg_v2_dataset',
        reset_key = 'reset_by_this_date'
    },
    data = {}
}

local set_data = Server.set_data
local try_get_data = Server.try_get_data
local try_get_all_data = Server.try_get_all_data
local concat = table.concat
local round = math.round

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local function eligible(player)
    if not player or not player.valid then
        return
    end

    local player_level = RPG.get_value_from_player(player.index, 'level')
    if player_level then
        if player_level <= this.settings.required_level_to_progress then
            return false
        else
            player.print('[RPG] Prestige system resets after 7 days.', Color.warning)
            return true
        end
    end
end

local function get_progression(player)
    if not player or not player.valid then
        return
    end

    local player_xp = RPG.get_value_from_player(player.index, 'xp')
    if player_xp then
        return round(player_xp * 0.003)
    end
end

local clear_all_data_token =
    Token.register(
    function(data)
        local entries = data.entries
        if not entries then
            return
        end

        for key, _ in pairs(entries) do
            if key ~= this.settings.reset_key then
                this.data[key] = nil
                set_data(this.settings.dataset, key, nil)
            end
        end
    end
)

local try_download_amount_of_resets_token =
    Token.register(
    function(data)
        local old_value = data.value
        if old_value then
            old_value = tonumber(old_value)
            local new_value = Core.get_current_date()
            local time_to_reset = (new_value - old_value)
            if not time_to_reset then
                return
            end

            if time_to_reset < this.settings.reset_after then
                this.data[this.settings.reset_key] = new_value
            else
                this.data[this.settings.reset_key] = 0
                set_data(this.settings.dataset, this.settings.reset_key, tonumber(new_value))
                try_get_all_data(this.settings.dataset, clear_all_data_token)
            end
        else
            local new_value = Core.get_current_date()

            if new_value then
                set_data(this.settings.dataset, this.settings.reset_key, tonumber(new_value))
            else
                set_data(this.settings.dataset, this.settings.reset_key, 0)
            end
        end
    end
)

local try_download_data_token =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value
        local player = game.get_player(key)
        if not player or not player.valid then
            return
        end

        if value then
            if value < this.settings.limit then
                this.data[player.name] = value
                RPG.set_value_to_player(player.index, 'xp', value)
            else
                set_data(this.settings.dataset, key, nil)
            end
        end
    end
)

local try_upload_data_token =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value
        local player = game.get_player(key)

        if value then
            if not eligible(player) then
                return
            end
            local old_xp = value

            local new_xp = old_xp + get_progression(player)
            if new_xp <= 0 then
                return
            end

            new_xp = round(new_xp, 0)

            set_data(this.settings.dataset, key, new_xp)
            this.data[key] = new_xp
        else
            if eligible(player) then
                set_data(this.settings.dataset, key, get_progression(player))
            end
        end
    end
)

--- Tries to update amount of resets, if the threshold is reached nil the bonuses.
function Public.try_dl_resets()
    if not this.settings.enabled then
        return
    end

    local secs = Server.get_current_time()
    if secs == nil then
        return
    else
        try_get_data(this.settings.dataset, this.settings.reset_key, try_download_amount_of_resets_token)
    end
end

--- Tries to get data from the web-panel and updates the local table with values.
-- @param data_set player token
function Public.try_dl_data(key)
    if not this.settings.enabled then
        return
    end

    key = tostring(key)
    local secs = Server.get_current_time()
    if secs == nil then
        return
    else
        try_get_data(this.settings.dataset, key, try_download_data_token)
    end
end

--- Tries to get data from the web-panel and updates the local table with values.
-- @param data_set player token
function Public.try_ul_data(key)
    if not this.settings.enabled then
        return
    end

    key = tostring(key)
    local secs = Server.get_current_time()
    if secs == nil then
        return
    else
        try_get_data(this.settings.dataset, key, try_upload_data_token)
    end
end

--- Checks if a player exists within the table
-- @param player_name <string>
-- @return <boolean>
function Public.exists(player_name)
    return this.data[player_name] ~= nil
end

--- Prints a list of all players in the player_session table.
function Public.print_rpg_data()
    local result = {}

    for k, _ in pairs(this.data) do
        result[#result + 1] = k
    end

    result = concat(result, ', ')
    Game.player_print(result)
end

--- Returns the table of session
-- @return <table>
function Public.get_session_table()
    return this.data
end

--- Returns the table of settings
-- @return <table>
function Public.get_settings_table()
    return this.settings
end

--- Clears a given player from the session tables.
-- @param LuaPlayer
function Public.clear_player(player)
    if player and player.valid then
        local name = player.name
        local connected = player.connected

        if not connected then
            if this.data[name] then
                this.data[name] = nil
            end
        end
    end
end

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        if not this.settings.enabled then
            return
        end

        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        Public.try_dl_data(player.name)
    end
)

Event.add(
    defines.events.on_player_left_game,
    function(event)
        if not this.settings.enabled then
            return
        end

        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        Public.try_ul_data(player.name)
    end
)

local nth_tick_token =
    Token.register(
    function(data)
        local index = data.index
        local player = game.get_player(index)
        if player and player.valid then
            Public.try_ul_data(player.name)
        end
    end
)

--- Saves all eligible players to the web-panel
function Public.save_all_players()
    if not this.settings.enabled then
        return
    end

    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        if player and player.valid then
            if eligible(player) then
                local count = 0
                count = count + 10
                set_timeout_in_ticks(count, nth_tick_token, {index = player.index})
            end
        end
    end
end

--- Restores XP to players that have values in the web-panel
function Public.restore_xp_on_reset()
    if not this.settings.enabled then
        return
    end

    local stash = this.data
    for key, value in pairs(stash) do
        local player = game.get_player(key)
        if player and player.valid then
            RPG.set_value_to_player(player.index, 'xp', value)
            player.print('[RPG] Prestige system has been applied.', Color.success)
        end
    end
end

--- Sets a new dataset or use the default one
function Public.set_dataset(dataset)
    if dataset then
        this.settings.dataset = dataset
    end
end

--- Toggles the module
function Public.toggle_module(state)
    this.settings.enabled = state or false
end

Event.add(
    Server.events.on_server_started,
    function()
        Public.try_dl_resets()
    end
)

return Public
