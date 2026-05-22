local Utils = require 'maps.oarc.ms_utils'
local MT = require 'maps.oarc.table'
local Tabs = require 'utils.gui'

local Public = {}
--------------------------------------------------------------------------------
-- Rocket Launch Event Code
-- Controls the "win condition"
--------------------------------------------------------------------------------
function Public.RocketLaunchEvent(event)
    local force = event.rocket.force

    -- Notify players on force if rocket was launched without sat.
    if event.rocket.get_item_count('satellite') == 0 then
        for _, player in pairs(force.players) do
            player.print("You launched the rocket, but you didn't put a satellite inside.")
        end
        return
    end

    local this = MT.get()

    -- First ever sat launch
    if not this.satellite_sent then
        this.satellite_sent = {}
        Utils.SendBroadcastMsg('Team ' .. event.rocket.force.name .. ' was the first to launch a rocket!')

        for _, player in pairs(game.players) do
            Tabs.set_tab(player, 'Rockets', true)
        end
    end

    -- Track additional satellites launched by this force
    if this.satellite_sent[force.name] then
        -- First sat launch for this force.
        this.satellite_sent[force.name] = this.satellite_sent[force.name] + 1
        Utils.SendBroadcastMsg('Team ' .. event.rocket.force.name .. ' launched another rocket. Total ' .. this.satellite_sent[force.name])
    else
        -- game.set_game_state{game_finished=true, player_won=true, can_continue=true}
        this.satellite_sent[force.name] = 1
        Utils.SendBroadcastMsg('Team ' .. event.rocket.force.name .. ' launched their first rocket!')
    end
end

return Public
