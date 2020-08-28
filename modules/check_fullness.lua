local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {
    fullness_enabled = true
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local Public = {}
local random = math.random

local function compute_fullness(player)
    local free_slots = player.get_main_inventory().count_empty_stacks()
    if free_slots == 0 then
        if player.character then
            player.character.health = player.character.health - random(50, 100)
            player.character.surface.create_entity({name = 'water-splash', position = player.position})
            local messages = {
                'Ouch.. That hurt! Better be careful now.',
                'Just a fleshwound.',
                'Better keep those hands to yourself or you might loose them.'
            }
            player.print(messages[random(1, #messages)], {r = 0.75, g = 0.0, b = 0.0})
            if player.character.health <= 0 then
                player.character.die('enemy')
                game.print(player.name .. ' should have emptied their pockets.', {r = 0.75, g = 0.0, b = 0.0})
                return free_slots
            end
        end
    end
    return free_slots
end

function Public.check_fullness(player)
    if this.fullness_enabled then
        local fullness = compute_fullness(player)
        if fullness == 0 then
            return
        end
    end
end

function Public.enable_fullness(value)
    if value then
        this.fullness_enabled = value
    else
        this.fullness_enabled = false
    end
    return this.fullness_enabled
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

local check_fullness = Public.check_fullness

Event.add(
    defines.events.on_player_mined_entity,
    function(event)
        local entity = event.entity
        if not entity or not entity.valid then
            return
        end

        local player = game.players[event.player_index]
        if not player or not player.valid then
            return
        end

        if not this.fullness_enabled then
            return
        end

        check_fullness(player)
    end
)

return Public
