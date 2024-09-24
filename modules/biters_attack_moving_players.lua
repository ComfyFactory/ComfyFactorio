--moving players attract biters from far away

local Event = require 'utils.event'
local math_random = math.random

local function on_player_changed_position(event)
    if math_random(1, 128) ~= 1 then
        return
    end
    if game.tick - storage.biters_attack_moving_players_last_action_tick < 7200 then
        return
    end
    local player = game.players[event.player_index]
    if not player.character then
        return
    end
    local amount = math.floor(game.tick * 0.0005) + 1
    if amount > 32 then
        amount = 32
    end
    player.surface.set_multi_command(
        {
            command = {
                type = defines.command.attack_area,
                destination = player.position,
                radius = 16,
                distraction = defines.distraction.by_anything
            },
            unit_count = amount,
            force = 'enemy',
            unit_search_distance = 1024
        }
    )
    storage.biters_attack_moving_players_last_action_tick = game.tick
end

local function on_init()
    storage.biters_attack_moving_players_last_action_tick = 0
end

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.on_init(on_init)
