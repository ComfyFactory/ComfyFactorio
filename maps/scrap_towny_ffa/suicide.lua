local ScenarioTable = require 'maps.scrap_towny_ffa.table'

local yellow = { r = 200, g = 200, b = 0 }
local minutes_to_die = 10
local one_minute = 60 * 60

commands.add_command(
        'suicide',
        'Kills the player',
        function(cmd)
            local this = ScenarioTable.get_table()
            local player = game.player

            if not player or not player.valid then
                return
            end

            if this.suicides[player.name] then
                player.print("You are already dying!", yellow)
                return
            end

            -- Schedule death for 30 seconds less than the average. Death is checked every minute, so this keeps
            -- the average correct.
            this.suicides[player.name] = game.tick + (one_minute * minutes_to_die - (one_minute * 0.5))
            player.print("You ate a poison pill. You will die in approximately " .. minutes_to_die .. " minutes.", yellow)
        end
)

local Public = {}

function Public.check()
    local this = ScenarioTable.get_table()
    for name, death_time in pairs(this.suicides) do
        local remaining_time = death_time - game.tick
        local player = game.get_player(name)
        if not player or not player.valid then
            return
        end
        if not player.character then
            return
        end

        if remaining_time <= 0 then
            player.character.die(player.force, player.character)
            this.suicides[player.name] = nil
        else
            local remaining_minutes = math.ceil(remaining_time / 3600)
            if remaining_minutes ~= minutes_to_die then
                if remaining_minutes == 1 then
                    player.print(remaining_minutes .. " minute remaining until death.", yellow)
                else
                    player.print(remaining_minutes .. " minutes remaining until death.", yellow)
                end
            end
        end
    end
end

return Public
