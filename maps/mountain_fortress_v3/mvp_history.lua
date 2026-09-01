local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local Global = require 'utils.global'
local Server = require 'utils.server'
local Task = require 'utils.task_token'
local Core = require 'utils.core'
local WD = require 'modules.wave_defense.table'

local mvp_dataset = 'scenario_settings'
local mvp_key = 'mtn_v3_mvps'
local mvp_key_dev = 'mtn_v3_mvps_dev'
local set_data = Server.set_data
local try_get_data = Server.try_get_data

local this =
{
    history = {}
}

Global.register(
    this,
    function (t)
        this = t
    end
)

local get_history =
    Task.register(
        function (data)
            if data and data.value and type(data.value) == 'table' then
                this.history = data.value
                Server.output_script_data('MVP history loaded successfully')
            else
                Server.output_script_data('No MVP history found, starting empty list')
                this.history = {}
            end
        end
    )

function Public.get_mvp_history()
    local secs = Server.get_current_time()
    if not secs then
        return
    end
    local server_name_matches = Server.check_server_name(Public.discord_name)
    if server_name_matches then
        try_get_data(mvp_dataset, mvp_key, get_history)
    else
        try_get_data(mvp_dataset, mvp_key_dev, get_history)
    end
end

function Public.save_mvp_round(mvp)
    if not mvp then
        return
    end

    local secs = Server.get_current_time()
    if not secs then
        return
    end

    local d = Server.convertFromEpoch(secs)
    local date = Server.get_current_date_with_time()
    if d then
        date = d.year .. '-' .. d.month .. '-' .. d.day .. ' ' .. d.hours .. ':' .. d.minutes .. ':' .. d.seconds
    end

    local stateful = Public.get_stateful()
    this.history[#this.history + 1] =
    {
        date = date,
        timestamp = secs,
        outcome = Public.get('game_won') and 'won' or 'lost',
        wave = WD.get_wave(),
        season = stateful and stateful.season or nil,
        rounds_survived = stateful and stateful.rounds_survived or nil,
        time_played = Core.format_time(game.ticks_played),
        players = #game.players,
        fighter = mvp.killscore,
        builder = mvp.built_entities,
        miner = mvp.mined_entities
    }

    local server_name_matches = Server.check_server_name(Public.discord_name)
    if server_name_matches then
        set_data(mvp_dataset, mvp_key, this.history)
        Server.output_script_data('MVP round written to dataset ' .. mvp_dataset .. ' / ' .. mvp_key)
    else
        set_data(mvp_dataset, mvp_key_dev, this.history)
        Server.output_script_data('MVP round written to dataset ' .. mvp_dataset .. ' / ' .. mvp_key_dev)
    end
end

Server.on_data_set_changed(
    mvp_dataset,
    function (data)
        if data.key ~= mvp_key and data.key ~= mvp_key_dev then
            return
        end
        if data.value and type(data.value) == 'table' then
            this.history = data.value
        end
    end
)

Event.add(ServerCommands.events.on_server_started, Public.get_mvp_history)

return Public
