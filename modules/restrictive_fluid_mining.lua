-- restricts mining of fluid filled entities -- by mewmew

local Event = require 'utils.event'
local Compat = require 'utils.functions.factorio_compat'
local math_random = math.random

local message_color = {r = 255, g = 150, b = 0}

local max_fill_percentages = {
    ['storage-tank'] = 0.1,
    ['pipe'] = 0.25,
    ['pipe-to-ground'] = 0.25
}

local function restrict_fluid_mining(event)
    if not max_fill_percentages[event.entity.type] then
        return
    end

    local entity = event.entity
    local fluidbox_count = Compat.fluidbox_count(entity)
    if fluidbox_count == 0 then
        return
    end

    local total_capacity = 0
    local total_current_fluid_amount = 0

    for i = 1, fluidbox_count, 1 do
        local fluid = Compat.get_fluid(entity, i)
        if fluid then
            total_capacity = total_capacity + Compat.get_fluid_capacity(entity, i)
            total_current_fluid_amount = total_current_fluid_amount + fluid.amount
        end
    end

    if total_capacity == 0 or total_current_fluid_amount == 0 then
        return
    end

    local fill_percentage = total_current_fluid_amount / total_capacity

    if fill_percentage < max_fill_percentages[event.entity.type] then
        return
    end

    event.buffer.clear()

    local replacement_entity =
        event.entity.surface.create_entity(
        {
            name = event.entity.name,
            force = event.entity.force,
            position = event.entity.position,
            direction = event.entity.direction
        }
    )
    replacement_entity.health = event.entity.health

    local fluid_name = 'fluid'
    local container_name = event.entity.name

    for i = 1, fluidbox_count, 1 do
        local fluid = Compat.get_fluid(entity, i)
        if fluid then
            Compat.set_fluid(replacement_entity, i, { name = fluid.name, amount = fluid.amount, temperature = fluid.temperature })
            fluid_name = fluid.name
        end
    end

    if not event.player_index then
        return
    end

    local messages = {
        'Mining this ' .. container_name .. ' would cause a terrible mess.',
        'You don´t want to spill all the ' .. fluid_name .. '.',
        'There is too much ' .. fluid_name .. ' in the ' .. container_name .. ' to dismantle it safely.'
    }
    local player = game.players[event.player_index]
    player.print(messages[math_random(1, #messages)], message_color)
end

local function on_player_mined_entity(event)
    restrict_fluid_mining(event)
end

local function on_robot_mined_entity(event)
    restrict_fluid_mining(event)
end

Event.add(defines.events.on_robot_mined_entity, on_robot_mined_entity)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
