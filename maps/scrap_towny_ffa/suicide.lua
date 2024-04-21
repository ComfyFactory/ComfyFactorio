local Event = require 'utils.event'
local Scheduler = require 'utils.scheduler'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'

local yellow = {r = 200, g = 200, b = 0}

-- Must be at least 1 minute
local minutes_to_die = 5

local one_minute = 60 * 60

local function on_player_died(event)
    local this = ScenarioTable.get_table()
    local player = game.players[event.player_index]
    this.suicides[player.index] = nil
end

Event.add(defines.events.on_player_died, on_player_died)

local suicide_handler =
    Scheduler.set(
    function(event)
        local this = ScenarioTable.get_table()
        local player_index = event.player_index
        local player = game.get_player(player_index)
        if not player or not player.valid or not player.character then
            return
        end

        if not this.suicides[player.index] then
            -- the suicide was cancelled (the character died)
            return
        end

        local minutes_remaining = this.suicides[player.index].minutes_remaining

        if minutes_remaining <= 0 then
            player.character.die()
            this.suicides[player.index] = nil
        else
            if minutes_remaining == 1 then
                player.print(minutes_remaining .. ' minute remaining until death.', yellow)
            else
                player.print(minutes_remaining .. ' minutes remaining until death.', yellow)
            end
            this.suicides[player.index].minutes_remaining = this.suicides[player.index].minutes_remaining - 1
            Scheduler.timer(game.tick + one_minute, event.handler, {player_index = player.index, handler = event.handler, ttl = event.ttl + 1})
        end
    end
)

commands.add_command(
    'suicide',
    'Kills the player',
    function()
        local this = ScenarioTable.get_table()
        local player = game.player

        if not player or not player.valid then
            return
        end

        if this.suicides[player.index] then
            player.print('You are already dying!', yellow)
            return
        end

        this.suicides[player.index] = {minutes_remaining = minutes_to_die - 1}
        Scheduler.timer(game.tick + one_minute, suicide_handler, {player_index = player.index, handler = suicide_handler, ttl = 1})
        player.print('You ate a poison pill. You will die in ' .. minutes_to_die .. ' minutes.', yellow)
    end
)
