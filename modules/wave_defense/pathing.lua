-- by Gerkiz for Comfy
local Public = require 'modules.wave_defense.table'
local Event = require 'utils.event'

local floor = math.floor
local sqrt = math.sqrt
local random = math.random

local max_outstanding = 2
local path_cooldown = 600
local unreachable_ttl = 3600
local goal_grid = 8
local stuck_dist_sq = 16
local lateral_offset = 32
local attack_radius = 20

local blocked_tiles =
{
    ['out-of-map'] = true,
    ['void-tile'] = true
}

local request_path_flags =
{
    allow_destroy_friendly_entities = true,
    allow_paths_through_own_entities = true,
    cache = true,
    prefer_straight_paths = false,
    low_priority = true,
    no_break = false
}

local command_path_flags =
{
    allow_destroy_friendly_entities = true,
    allow_paths_through_own_entities = true,
    cache = true,
    prefer_straight_paths = false,
    low_priority = false,
    no_break = false
}

local stage_primary = 1
local stage_lateral = 2
local stage_alt = 3

local function get_biter_path_params()
    local proto = prototypes.entity['small-biter'] or prototypes.entity['medium-biter']
    if proto then
        return proto.collision_box, proto.collision_mask
    end
    return { left_top = { x = -0.2, y = -0.2 }, right_bottom = { x = 0.2, y = 0.2 } }, { layers = { player = true, train = true, is_object = true, is_lower_object = true } }
end

local function goal_key(pos)
    return floor(pos.x / goal_grid) .. '_' .. floor(pos.y / goal_grid)
end

local function is_goal_unreachable(generated_units, pos, tick)
    local goals = generated_units.unreachable_goals
    if not goals then
        return false
    end
    local key = goal_key(pos)
    local stamped = goals[key]
    if not stamped then
        return false
    end
    if stamped + unreachable_ttl < tick then
        goals[key] = nil
        return false
    end
    return true
end

local function mark_goal_unreachable(generated_units, pos, tick)
    if not generated_units.unreachable_goals then
        generated_units.unreachable_goals = {}
    end
    generated_units.unreachable_goals[goal_key(pos)] = tick
end

local function get_random_character()
    local surface_index = Public.get('surface_index')
    local characters = {}
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        if player.character and player.character.valid and player.character.surface.index == surface_index then
            characters[#characters + 1] = player.character
        end
    end
    if not characters[1] then
        return
    end
    return characters[random(1, #characters)]
end

local function get_lateral_positions(start, goal)
    local dx = goal.x - start.x
    local dy = goal.y - start.y
    local len = sqrt(dx * dx + dy * dy)
    if len < 1 then
        len = 1
    end
    local nx = -dy / len
    local ny = dx / len
    return
    {
        { x = goal.x + nx * lateral_offset, y = goal.y + ny * lateral_offset },
        { x = goal.x - nx * lateral_offset, y = goal.y - ny * lateral_offset }
    }
end

local function set_group_attack_command(group, destination, target, waypoint)
    if not (group and group.valid) then
        return
    end
    if not destination then
        return
    end

    local commands = {}
    if waypoint then
        commands[#commands + 1] =
        {
            type = defines.command.go_to_location,
            destination = waypoint,
            radius = 8,
            distraction = defines.distraction.by_anything,
            pathfind_flags = command_path_flags
        }
    end

    commands[#commands + 1] =
    {
        type = defines.command.attack_area,
        destination = { x = destination.x, y = destination.y },
        radius = attack_radius,
        distraction = defines.distraction.by_anything
    }

    if target and target.valid then
        commands[#commands + 1] =
        {
            type = defines.command.attack,
            target = target,
            distraction = defines.distraction.by_anything
        }
    end

    group.set_command(
        {
            type = defines.command.compound,
            structure_type = defines.compound_command.return_last,
            commands = commands
        }
    )

    local generated_units = Public.get('generated_units')
    if generated_units and generated_units.unit_group_last_command then
        generated_units.unit_group_last_command[group.unique_id] = game.tick
    end
end

local function release_request(generated_units, id)
    local request = generated_units.path_requests[id]
    if not request then
        return
    end
    generated_units.path_requests[id] = nil
    generated_units.path_request_count = (generated_units.path_request_count or 1) - 1
    if generated_units.path_request_count < 0 then
        generated_units.path_request_count = 0
    end
    return request
end

local function request_path(group, generated_units, goal, stage, target, waypoint, attack_destination, lateral_index)
    if generated_units.path_request_count >= max_outstanding then
        Public.debug_print('pathing - request skipped, outstanding cap')
        return false
    end

    local bounding_box, collision_mask = get_biter_path_params()
    local surface = group.surface
    local ok, id_or_err = pcall(
        function ()
            return surface.request_path(
                {
                    bounding_box = bounding_box,
                    collision_mask = collision_mask,
                    start = group.position,
                    goal = goal,
                    force = group.force,
                    radius = 16,
                    pathfind_flags = request_path_flags,
                    path_resolution_modifier = -2
                }
            )
        end
    )

    if not ok or not id_or_err then
        Public.debug_print('pathing - request_path error: ' .. tostring(id_or_err))
        return false
    end

    generated_units.path_requests[id_or_err] =
    {
        group_id = group.unique_id,
        stage = stage,
        goal = goal,
        attack_destination = attack_destination or goal,
        target = target,
        waypoint = waypoint,
        lateral_index = lateral_index
    }
    generated_units.path_request_count = generated_units.path_request_count + 1
    generated_units.group_path_cooldown[group.unique_id] = game.tick
    Public.debug_print('pathing - requested id ' .. id_or_err .. ' stage ' .. stage .. ' x' .. goal.x .. ' y' .. goal.y)
    return true
end

local function begin_stage(group, stage, generated_units, lateral_index)
    if not (group and group.valid) then
        return
    end

    local tick = game.tick
    local target = Public.get('target')
    if not (target and target.valid) then
        return
    end

    if stage == stage_primary then
        local dest = Public.get_attack_destination(group.surface, target.position)
        if is_goal_unreachable(generated_units, dest, tick) then
            Public.debug_print('pathing - primary goal cached unreachable, skipping to lateral')
            return begin_stage(group, stage_lateral, generated_units)
        end
        if not request_path(group, generated_units, dest, stage_primary, target, nil, dest) then
            set_group_attack_command(group, dest, target)
        end
        return
    end

    if stage == stage_lateral then
        local dest = Public.get_attack_destination(group.surface, target.position)
        local laterals = get_lateral_positions(group.position, dest)
        local start_index = lateral_index or 1
        for i = start_index, #laterals do
            local walkable = Public.get_attack_destination(group.surface, laterals[i])
            if not is_goal_unreachable(generated_units, walkable, tick) then
                Public.debug_print('pathing - lateral offset x' .. walkable.x .. ' y' .. walkable.y)
                if request_path(group, generated_units, walkable, stage_lateral, target, walkable, dest, i) then
                    return
                end
                set_group_attack_command(group, dest, target, walkable)
                return
            end
        end
        return begin_stage(group, stage_alt, generated_units)
    end

    local character = get_random_character()
    if character and character.valid and (not target.valid or character.unit_number ~= target.unit_number) then
        local dest = Public.get_attack_destination(character.surface, character.position)
        Public.debug_print('pathing - alt target character at x' .. dest.x .. ' y' .. dest.y)
        if not request_path(group, generated_units, dest, stage_alt, character, nil, dest) then
            set_group_attack_command(group, dest, character)
        end
        return
    end

    Public.debug_print('pathing - no alt target, waiting for reform')
end

function Public.get_attack_destination(surface, position)
    if not surface or not surface.valid or not position then
        return position
    end

    local tile = surface.get_tile(position)
    local blocked = false
    if tile.valid then
        if blocked_tiles[tile.name] then
            blocked = true
        elseif tile.collides_with('player') then
            blocked = true
        end
    end

    local radius = 8
    local precision = 1
    if blocked then
        radius = 32
        precision = 2
    end

    local dest = surface.find_non_colliding_position('behemoth-biter', position, radius, precision)
    if dest then
        return dest
    end

    if blocked then
        dest = surface.find_non_colliding_position('behemoth-biter', position, 64, 2)
        if dest then
            return dest
        end
        Public.debug_print('get_attack_destination - no walkable tile near x' .. position.x .. ' y' .. position.y)
    end

    return { x = position.x, y = position.y }
end

function Public.add_approach_waypoints(commands, group, destination)
    if not (group and group.valid and destination) then
        return commands
    end

    local gx = group.position.x
    local gy = group.position.y
    local fractions = { 0.33, 0.66 }
    for i = 1, #fractions do
        local t = fractions[i]
        local probe = { x = gx + (destination.x - gx) * t, y = gy + (destination.y - gy) * t }
        local pos = group.surface.find_non_colliding_position('behemoth-biter', probe, 16, 1)
        if pos then
            commands[#commands + 1] =
            {
                type = defines.command.attack_area,
                destination = { x = pos.x, y = pos.y },
                radius = 16,
                distraction = defines.distraction.by_anything
            }
        end
    end
    return commands
end

function Public.is_group_stalled(last_position, current_position)
    if not last_position or not current_position then
        return false
    end
    local dx = current_position.x - last_position.x
    local dy = current_position.y - last_position.y
    return (dx * dx + dy * dy) < stuck_dist_sq
end

function Public.begin_path_recovery(group)
    if not (group and group.valid) then
        return
    end

    local generated_units = Public.get('generated_units')
    if not generated_units.path_requests then
        generated_units.path_requests = {}
    end
    if not generated_units.path_request_count then
        generated_units.path_request_count = 0
    end
    if not generated_units.group_path_cooldown then
        generated_units.group_path_cooldown = {}
    end
    if not generated_units.unreachable_goals then
        generated_units.unreachable_goals = {}
    end

    local tick = game.tick
    local cooldown = generated_units.group_path_cooldown[group.unique_id]
    if cooldown and cooldown + path_cooldown > tick then
        Public.debug_print('pathing - recovery cooldown for group ' .. group.unique_id)
        return
    end

    for _, request in pairs(generated_units.path_requests) do
        if request.group_id == group.unique_id then
            Public.debug_print('pathing - recovery already in flight for group ' .. group.unique_id)
            return
        end
    end

    Public.debug_print('pathing - begin recovery for group ' .. group.unique_id)
    begin_stage(group, stage_primary, generated_units)
end

local function on_script_path_request_finished(event)
    local generated_units = Public.get('generated_units')
    if not generated_units or not generated_units.path_requests then
        return
    end

    local request = release_request(generated_units, event.id)
    if not request then
        return
    end

    local group = generated_units.unit_groups[request.group_id]
    if not (group and group.valid) then
        Public.debug_print('pathing - finished id ' .. event.id .. ' but group is gone')
        return
    end

    if event.try_again_later then
        generated_units.group_path_cooldown[request.group_id] = nil
        Public.debug_print('pathing - try_again_later id ' .. event.id)
        return
    end

    if event.path then
        Public.debug_print('pathing - path ok id ' .. event.id .. ' stage ' .. request.stage)
        set_group_attack_command(group, request.attack_destination or request.goal, request.target, request.waypoint)
        return
    end

    Public.debug_print('pathing - path fail id ' .. event.id .. ' stage ' .. request.stage)
    mark_goal_unreachable(generated_units, request.goal, game.tick)

    if request.stage == stage_primary then
        begin_stage(group, stage_lateral, generated_units)
    elseif request.stage == stage_lateral then
        begin_stage(group, stage_lateral, generated_units, (request.lateral_index or 1) + 1)
    else
        Public.debug_print('pathing - all stages failed for group ' .. request.group_id)
    end
end

local function on_ai_command_completed(event)
    if event.was_distracted then
        return
    end
    if event.result ~= defines.behavior_result.fail then
        return
    end

    local generated_units = Public.get('generated_units')
    if not generated_units or not generated_units.unit_groups then
        return
    end

    local group = generated_units.unit_groups[event.unit_number]
    if not (group and group.valid) then
        return
    end

    Public.debug_print('pathing - group command fail ' .. event.unit_number)
    Public.begin_path_recovery(group)
end

Event.add(defines.events.on_script_path_request_finished, on_script_path_request_finished)
Event.add(defines.events.on_ai_command_completed, on_ai_command_completed)

return Public
