--library to make working with unit commands easier

local Public = {}

local Global = require 'utils.global'
local Utils = require 'utils.utils'

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

---Command to attack natural obstacles
---@param surface LuaSurface
---@param position MapPosition
---@param distraction defines.distraction|nil
function Public.command_attack_obstacles(surface, position, distraction)
    local commands = {}
    local obstacles = surface.find_entities_filtered {position = position, radius = 25, type = {'simple-entity', 'tree', 'simple-entity-with-owner'}, limit = 100}
    if obstacles then
        --table.shuffle_table(obstacles)
        table.shuffle_by_distance(obstacles, position)
        for i = 1, #obstacles, 1 do
            if obstacles[i].valid then
                commands[#commands + 1] = {
                    type = defines.command.attack,
                    target = obstacles[i],
                    distraction = distraction
                }
            end
        end
    end
    commands[#commands + 1] = Public.command_move_to(position)
    local command = {
        type = defines.command.compound,
        structure_type = defines.compound_command.return_last,
        commands = commands
    }
    return command
end

---Give list of commands to unit or group
---@param unit LuaCommandable
---@param commands Command
function Public.multicommand(unit, commands)
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

---TODO: more advanced functions and direct LuaCommandable stuff

return Public