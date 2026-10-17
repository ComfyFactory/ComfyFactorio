--library to make working with unit commands easier

local Raffle = require 'utils.math.raffle'

local Public = {}

local random = math.random
local floor = math.floor

---Default worm list for AI.pick_worm, ordered from weakest to strongest
Public.worm_raffle = {
    'small-worm-turret',
    'small-worm-turret',
    'medium-worm-turret',
    'small-worm-turret',
    'medium-worm-turret',
    'medium-worm-turret',
    'big-worm-turret',
    'medium-worm-turret',
    'big-worm-turret',
    'big-worm-turret',
    'behemoth-worm-turret',
    'big-worm-turret',
    'behemoth-worm-turret',
    'behemoth-worm-turret',
    'behemoth-worm-turret',
    'big-worm-turret',
    'behemoth-worm-turret'
}

---Picks worm name scaled by evolution, higher evolution picks from the stronger part of the list
---@param evo number #evolution factor 0..1
---@param worm_names string[]|nil #ordered from weakest to strongest, defaults to AI.worm_raffle
---@return string
function Public.pick_worm(evo, worm_names)
    worm_names = worm_names or Public.worm_raffle
    local range = #worm_names - 1
    return worm_names[random(1 + floor(evo * range / 2), 1 + floor(evo * range))]
end

---Command to move
---@param position MapPosition
---@param distraction defines.distraction|nil
function Public.command_move_to(position, distraction)
    local command = {
        type = defines.command.go_to_location,
        destination = position,
        distraction = distraction or defines.distraction.by_enemy,
        no_break = true
    }
    return command
end

---Command to attack entity
---@param target LuaEntity
---@param distraction defines.distraction|nil
function Public.command_attack_target(target, distraction)
    local command = {
        type = defines.command.attack,
        target = target,
        distraction = distraction or defines.distraction.by_enemy
    }
    return command
end

---Command to attack things in area
---@param position MapPosition
---@param radius integer
---@param distraction defines.distraction|nil
function Public.command_attack_area(position, radius, distraction)
    local command = {
        type = defines.command.attack_area,
        destination = position,
        radius = radius or 25,
        distraction = distraction or defines.distraction.by_enemy
    }
    return command
end

---Command to attack natural obstacles, closest ones first (max 100), then move to position
---@param surface LuaSurface
---@param position MapPosition
---@param distraction defines.distraction|nil
---@param from MapPosition|nil #obstacles closer to this position get attacked first, defaults to position
function Public.command_attack_obstacles(surface, position, distraction, from)
    local commands = {}
    local obstacles = surface.find_entities_filtered { position = position, radius = 25, type = { 'simple-entity', 'tree', 'simple-entity-with-owner' } }
    local origin = from or position
    local ox, oy = origin.x or origin[1], origin.y or origin[2]
    local sorted = {}
    for i = 1, #obstacles, 1 do
        local p = obstacles[i].position
        local dx, dy = p.x - ox, p.y - oy
        sorted[i] = { entity = obstacles[i], distance = dx * dx + dy * dy }
    end
    table.sort(
        sorted,
        function (a, b)
            return a.distance < b.distance
        end
    )
    for i = 1, math.min(#sorted, 100), 1 do
        commands[#commands + 1] = {
            type = defines.command.attack,
            target = sorted[i].entity,
            distraction = distraction
        }
    end
    commands[#commands + 1] = Public.command_move_to(position)
    local command = {
        type = defines.command.compound,
        structure_type = defines.compound_command.return_last,
        commands = commands
    }
    return command
end

---Command to stop and stand still
---@param distraction defines.distraction|nil
function Public.command_stop(distraction)
    local command = {
        type = defines.command.stop,
        distraction = distraction or defines.distraction.by_enemy
    }
    return command
end

---Command to wander individually around the group/unit position
---@param ticks_to_wait integer|nil
---@param distraction defines.distraction|nil
function Public.command_wander(ticks_to_wait, distraction)
    local command = {
        type = defines.command.wander,
        ticks_to_wait = ticks_to_wait,
        distraction = distraction or defines.distraction.by_enemy
    }
    return command
end

---Give list of commands to unit or group
---@param unit LuaCommandable
---@param commands Command[]
function Public.multicommand(unit, commands)
    if not (unit and unit.valid) then
        return
    end
    if #commands > 0 then
        local command = {
            type = defines.command.compound,
            structure_type = defines.compound_command.return_last,
            commands = commands
        }
        unit.set_command(command)
    end
end

---Give list of commands to unit or group
---@param surface LuaSurface
---@param target LuaEntity
---@param force LuaForce
---@param size_multiplier number|nil #defaults to 1 if nil or less than 0
function Public.multi_attack(surface, target, force, size_multiplier)
    surface.set_multi_command(
        {
            command = Public.command_attack_target(target),
            unit_count = 16 + math.random(1, math.floor(1 + force.get_evolution_factor(surface) * 100)) * ((size_multiplier or 1) > 0 and size_multiplier or 1),
            force = force,
            unit_search_distance = 512
        }
    )
end

---Picks random entity from the list, closer entities to position being more likely. Shuffles the list in place.
---@param entities LuaEntity[]
---@param position MapPosition
---@return LuaEntity|nil
function Public.raffle_closest(entities, position)
    if not entities or #entities < 1 then
        return nil
    end
    table.shuffle_table(entities)
    table.shuffle_by_distance(entities, position)
    local weights = {}
    for index, _ in pairs(entities) do
        weights[#weights + 1] = 1 + floor((#entities - index) / 2)
    end
    return Raffle.raffle(entities, weights)
end

---Creates unit group and adds the units into it
---@param surface LuaSurface
---@param position MapPosition
---@param force ForceID
---@param units LuaEntity[]
---@return LuaCommandable
function Public.create_group(surface, position, force, units)
    local unit_group = surface.create_unit_group({ position = position, force = force })
    for _, unit in pairs(units) do
        unit_group.add_member(unit)
    end
    return unit_group
end

---Recreates the group with all its members plus new units, so it starts gathering again and everyone walks to the group first.
---There is no API to switch existing group back to gathering. Keeps the current command, so the group continues after gathering.
---Returns the same group if there are no new units. The new group has a different unique_id!
---@param group LuaCommandable
---@param units LuaEntity[]|nil #units to add on top of current members (same force as the group)
---@return LuaCommandable
function Public.regroup(group, units)
    local members = group.members
    local known = {}
    for _, member in pairs(members) do
        known[member.unit_number] = true
    end
    local added = false
    for _, unit in pairs(units or {}) do
        if unit.valid and not known[unit.unit_number] then
            known[unit.unit_number] = true
            members[#members + 1] = unit
            added = true
        end
    end
    if not added then
        return group
    end
    local command = group.command
    local new_group = Public.create_group(group.surface, group.position, group.force, members)
    if command then
        new_group.set_command(command)
    end
    if group.valid then
        group.destroy()
    end
    return new_group
end

---@class AI.tracked_unit
---@field entity LuaEntity
---@field active_since uint #tick when the unit started to be script-controlled

---Checks if script-controlled unit is dead or no longer commandable. Units older than max_age get destroyed.
---@param tracked AI.tracked_unit
---@param max_age uint #ticks
---@return boolean
function Public.is_unit_inactive(tracked, max_age)
    local entity = tracked.entity
    if not (entity and entity.valid) then
        return true
    end
    if not (entity.commandable and entity.commandable.valid) then
        return true
    end
    if game.tick - tracked.active_since > max_age then
        entity.destroy()
        return true
    end
    return false
end

---Removes inactive units from table of tracked units (keyed by unit_number)
---@param tracked_units table<uint, AI.tracked_unit>
---@param max_age uint #ticks
---@return integer #count of removed units
function Public.remove_inactive_units(tracked_units, max_age)
    local removed = 0
    for unit_number, tracked in pairs(tracked_units) do
        if Public.is_unit_inactive(tracked, max_age) then
            tracked_units[unit_number] = nil
            removed = removed + 1
        end
    end
    return removed
end

---Counts valid tracked units, removing the invalid ones from the table
---@param tracked_units table<uint, AI.tracked_unit>
---@return integer
function Public.count_valid_units(tracked_units)
    local count = 0
    for unit_number, tracked in pairs(tracked_units) do
        if tracked.entity and tracked.entity.valid then
            count = count + 1
        else
            tracked_units[unit_number] = nil
        end
    end
    return count
end

---Group settles down: its units are turned into nests (every 10 units = 1 nest, chance for worm instead), scaled by evolution.
---If no place for nest is found, the group attacks obstacles around. Groups with less than 10 units are destroyed.
---@param group LuaCommandable
---@param unit_names string[] #names of units that count towards the nests
---@param spawner_names string[]
---@param worm_names string[]|nil #ordered from weakest to strongest, defaults to AI.worm_raffle
---@return boolean #true if any nest was built
function Public.colonize(group, unit_names, spawner_names, worm_names)
    local surface = group.surface
    local evo = group.force.get_evolution_factor(surface)
    local nests = random(1 + floor(evo * 20), 2 + floor(evo * 20) * 2)
    local commands = {}
    local biters = surface.find_entities_filtered { position = group.position, radius = 30, name = unit_names, force = group.force }
    local goodbiters = {}
    if #biters > 1 then
        for i = 1, #biters, 1 do
            if biters[i].commandable == group then
                goodbiters[#goodbiters + 1] = biters[i]
            end
        end
    end
    if #goodbiters < 10 then
        if #group.members < 10 then
            group.destroy()
        end
        return false
    end
    local eligible_spawns = 1 + floor(#goodbiters / 10)
    local success = false

    for i = 1, nests, 1 do
        if eligible_spawns < i then
            break
        end
        local pos = surface.find_non_colliding_position('biter-spawner', group.position, 20, 1, true)
        if pos then
            success = true
            if random(1, 5) == 1 then
                surface.create_entity({ name = Public.pick_worm(evo, worm_names), position = pos, force = group.force })
            else
                surface.create_entity({ name = spawner_names[random(1, #spawner_names)], position = pos, force = group.force })
            end
        else
            commands = {
                Public.command_attack_obstacles(surface, group.position)
            }
        end
    end
    if success then
        for i = 1, #goodbiters, 1 do
            if goodbiters[i].valid then
                goodbiters[i].destroy()
            end
        end
        return true
    end
    Public.multicommand(group, commands)
    return false
end

---TODO: more advanced functions and direct LuaCommandable stuff

return Public
