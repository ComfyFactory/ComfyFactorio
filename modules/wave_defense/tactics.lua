local WD = require 'modules.wave_defense.table'

local Public = {}
local priorities = { character = 1, turret = 2, ['ammo-turret'] = 2, ['electric-turret'] = 2, ['fluid-turret'] = 2, wall = 3 }
local types = { 'character', 'turret', 'ammo-turret', 'electric-turret', 'fluid-turret', 'wall' }

local function distance_squared(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return dx * dx + dy * dy
end

local function eligible(group, entity)
    if not (entity and entity.valid and entity.surface == group.surface and entity.destructible and entity.health and entity.health > 0) then
        return false
    end
    local own, other = group.force, entity.force
    return own ~= other and own.index ~= other.index
        and not own.get_friend(other) and not other.get_friend(own)
        and not own.get_cease_fire(other) and not other.get_cease_fire(own)
end

local function reset_progress(state, group, tick)
    state.position = { x = group.position.x, y = group.position.y }
    state.progress_tick = tick
end

local function get_state(generated, group, tick)
    generated.group_tactics = generated.group_tactics or {}
    local state = generated.group_tactics[group.unique_id]
    if not state then
        state = { next_scan = tick, cooldown_until = tick }
        reset_progress(state, group, tick)
        generated.group_tactics[group.unique_id] = state
    end
    return state
end

local function reset_thought(state, group, tick)
    state.target = nil
    state.cooldown_until = tick + 600
    reset_progress(state, group, tick)
    group.set_distraction_command({ type = defines.command.stop, distraction = defines.distraction.none })
    return group.valid
end

function Public.update_group_tactics(group, target, tick)
    if not (group and group.valid) then
        return false
    end
    local group_id = group.unique_id
    local generated = WD.get('generated_units')
    if WD.get('enable_group_tactics') == false
        or not (target and target.valid and target.surface == group.surface) then
        local state = generated and generated.group_tactics and generated.group_tactics[group.unique_id]
        if state and state.target and not reset_thought(state, group, tick) then
            generated.group_tactics[group_id] = nil
        end
        return false
    end
    if not generated then
        return false
    end
    local state = get_state(generated, group, tick)

    if state.target then
        if tick >= state.hold_until or not eligible(group, state.target)
            or distance_squared(group.position, state.target.position) > 32 * 32 then
            if not reset_thought(state, group, tick) then
                generated.group_tactics[group_id] = nil
                return false
            end
        else
            reset_progress(state, group, tick)
            return false
        end
    end

    local moving = defines.group_state and defines.group_state.moving
    if not moving or group.state ~= moving or distance_squared(state.position, group.position) >= 9 then
        reset_progress(state, group, tick)
    end
    local stalled = moving and group.state == moving and tick - state.progress_tick >= 900
    if (group.has_command == false or not group.command or stalled) and (not state.retry_tick or tick - state.retry_tick >= 600) then
        state.retry_tick = tick
        reset_progress(state, group, tick)
        return true
    end

    if tick < state.next_scan or tick < state.cooldown_until then
        return false
    end
    state.next_scan = tick + 180
    local entities = group.surface.find_entities_filtered({ position = group.position, radius = 24, limit = 16, type = types })
    local best, best_priority, best_distance
    for i = 1, math.min(#entities, 16) do
        local entity = entities[i]
        if eligible(group, entity) then
            local priority = priorities[entity.type]
            local distance = distance_squared(group.position, entity.position)
            if priority and distance <= 24 * 24 and (not best or priority < best_priority or (priority == best_priority and distance < best_distance)) then
                best, best_priority, best_distance = entity, priority, distance
            end
        end
    end
    if best then
        state.target = best
        state.hold_until = tick + 300
        reset_progress(state, group, tick)
        group.set_distraction_command({ type = defines.command.attack, target = best, distraction = defines.distraction.none })
        if not group.valid then generated.group_tactics[group_id] = nil end
    end
    return false
end

function Public.add_tactical_waypoint(commands, group, destination)
    if WD.get('enable_group_tactics') == false
        or not (group and group.valid and destination and type(destination.x) == 'number' and type(destination.y) == 'number') then
        return commands
    end
    local distance = math.sqrt(distance_squared(group.position, destination))
    if distance < 64 then
        return commands
    end
    local generated = WD.get('generated_units')
    if not generated then
        return commands
    end
    local state = get_state(generated, group, game and game.tick or 0)
    if state.flank_side == nil then
        local choice = math.random(1, 8)
        state.flank_side = choice == 1 and -1 or (choice == 2 and 1 or 0)
    end
    if state.flank_side == 0 or state.flank_planned then
        return commands
    end
    local dx, dy = destination.x - group.position.x, destination.y - group.position.y
    local offset = 16 * state.flank_side
    local probe =
    {
        x = group.position.x + dx * 0.5 - dy / distance * offset,
        y = group.position.y + dy * 0.5 + dx / distance * offset
    }
    local point = group.surface.find_non_colliding_position('behemoth-biter', probe, 8, 1)
    if point then
        commands[#commands + 1] =
        {
            type = defines.command.go_to_location,
            destination = { x = point.x, y = point.y },
            distraction = defines.distraction.by_enemy
        }
        state.flank_planned = true
    end
    return commands
end

return Public
