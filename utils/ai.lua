local Event = require 'utils.event'
local CommonFunctions = require 'utils.common'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Global = require 'utils.global'

local this = {
    timers = {}
}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local Public = {}
local remove = table.remove

Public.command = {
    --[[
      @param args nil
   --]]
    noop = 0,
    --[[
      @param args nil
   --]]
    seek_and_destroy_player = 1,
    --[[
      @param args = {
          agents, // All movable agents
          positions, // Table of positions to attack
      }
   --]]
    attack_objects = 2
}

local function _get_direction(src, dest)
    local src_x = CommonFunctions.get_axis(src, 'x')
    local src_y = CommonFunctions.get_axis(src, 'y')
    local dest_x = CommonFunctions.get_axis(dest, 'x')
    local dest_y = CommonFunctions.get_axis(dest, 'y')

    local step = {
        x = nil,
        y = nil
    }

    local precision = CommonFunctions.rand_range(1, 10)
    if dest_x - precision > src_x then
        step.x = 1
    elseif dest_x < src_x - precision then
        step.x = -1
    else
        step.x = 0
    end

    if dest_y - precision > src_y then
        step.y = 1
    elseif dest_y < src_y - precision then
        step.y = -1
    else
        step.y = 0
    end

    return CommonFunctions.direction_lookup[step.x][step.y]
end

local function _move_to(ent, trgt, min_distance)
    local state = {
        walking = false
    }

    local distance = CommonFunctions.get_distance(trgt.position, ent.position)
    if min_distance < distance then
        local dir = _get_direction(ent.position, trgt.position)
        if dir then
            state = {
                walking = true,
                direction = dir
            }
        end
    end

    ent.walking_state = state
    return state.walking
end

local function refill_ammo(ent)
    if not ent or not ent.valid then
        return
    end
    local weapon = ent.get_inventory(defines.inventory.character_guns)[ent.selected_gun_index]
    if weapon and weapon.valid_for_read then
        local selected_ammo = ent.get_inventory(defines.inventory.character_ammo)[ent.selected_gun_index]
        if selected_ammo then
            if not selected_ammo.valid_for_read then
                if weapon.name == 'shotgun' then
                    ent.insert({name = 'shotgun-shell', count = 5})
                end
                if weapon.name == 'pistol' then
                    ent.insert({name = 'firearm-magazine', count = 5})
                end
            end
        end
    end
end

local function _shoot_at(ent, trgt)
    ent.shooting_state = {
        state = defines.shooting.shooting_selected,
        position = trgt.position
    }
end

local function _shoot_stop(ent)
    ent.shooting_state = {
        state = defines.shooting.not_shooting,
        position = {0, 0}
    }
end

local function set_noise_hostile_hook(ent)
    if not ent or not ent.valid then
        return
    end
    local weapon = ent.get_inventory(defines.inventory.character_guns)[ent.selected_gun_index]
    if weapon and weapon.valid_for_read then
        return
    end

    if CommonFunctions.rand_range(1, 5) == 1 then
        ent.insert({name = 'shotgun', count = 1})
        ent.insert({name = 'shotgun-shell', count = 5})
    end
end

local function _do_job_seek_and_destroy_player(data)
    local surf = data.surface
    local force = data.force
    local players = game.connected_players

    if type(surf) == 'number' then
        surf = game.surfaces[surf]
        if not surf or not surf.valid then
            this.timers[game.tick] = nil
            return
        end
    end

    for _, player in pairs(players) do
        if player and player.valid and player.character then
            local position = data.position or player.character.position
            local search_info = {
                name = 'character',
                position = position,
                radius = 30,
                force = force or 'enemy'
            }

            local ents = surf.find_entities_filtered(search_info)
            if ents and #ents > 0 then
                for _, e in pairs(ents) do
                    if e and e.valid then
                        if e.player == nil then
                            set_noise_hostile_hook(e)
                            refill_ammo(e)
                            if not _move_to(e, player.character, CommonFunctions.rand_range(5, 10)) then
                                _shoot_at(e, player.character)
                            else
                                _shoot_stop(e)
                            end
                        end
                    else
                        if data.repeat_function then
                            this.timers[data.new] = nil
                        end
                    end
                end
            else
                if data.repeat_function then
                    this.timers[data.new] = nil
                end
            end
        end
    end
end

local function _do_job_attack_objects(data)
    local surf = data.surface
    local force = data.force
    local position = data.position

    if type(surf) == 'number' then
        surf = game.surfaces[surf]
        if not surf or not surf.valid then
            if data.repeat_function then
                this.timers[data.new] = nil
            end
            return
        end
    end

    local search_info = {
        name = 'character',
        position = position,
        radius = 30,
        force = force or 'enemy'
    }

    local ents = surf.find_entities_filtered(search_info)
    if ents and #ents > 0 then
        local target, closest, agent, query
        for i = #ents, 1, -1 do
            agent = ents[i]
            if not agent.valid then
                remove(ents, i)
                goto continue
            end

            if game.tick % i ~= 0 then
                goto continue
            end

            query = {
                position = agent.position,
                radius = 15,
                type = {
                    'projectile',
                    'beam'
                },
                force = {
                    'enemy',
                    'player',
                    'neutral'
                },
                invert = true
            }
            closest = surf.find_entities_filtered(query)
            if #closest ~= 0 then
                target = CommonFunctions.get_closest_neighbour(agent.position, closest)
            else
                goto continue
            end

            if target == nil or not target.valid then
                goto continue
            end

            if not _move_to(agent, target, CommonFunctions.rand_range(5, 15)) then
                _shoot_at(agent, target)
            else
                _shoot_stop(agent)
            end

            ::continue::
        end
    else
        if data.repeat_function then
            this.timers[data.new] = nil
        end
    end
end

local do_job_token

do_job_token =
    Token.register(
    function(data)
        local surf = data.surface
        local command = data.command

        if type(surf) == 'number' then
            surf = game.surfaces[surf]
            if not surf or not surf.valid then
                this.timers[game.tick] = nil
                return
            end
        end

        if command == Public.command.seek_and_destroy_player then
            _do_job_seek_and_destroy_player(data)
        elseif command == Public.command.attack_objects then
            _do_job_attack_objects(data)
        end
    end
)

function Public.add_job_to_task(data)
    if not type(data) == 'table' then
        return
    end

    if not data.tick then
        return
    end

    if not this.timers[game.tick + data.tick] then
        this.timers[game.tick + data.tick] = data
    end
end

--[[
do_job - Perform non-stateful operation on all chosen force "character" entities.
@param surf - LuaSurface, on which everything is happening.
@param command - Command to perform on all non-player controllable characters.
--]]
Public.do_job = function(surf, command, args, force)
    if args == nil then
        args = {}
    end

    if command == Public.command.seek_and_destroy_player then
        _do_job_seek_and_destroy_player(surf, force)
    elseif command == Public.command.attack_objects then
        _do_job_attack_objects(surf, args)
    end
end

Event.add(
    defines.events.on_tick,
    function()
        local tick = game.tick

        if not this.timers[tick] then
            return
        end
        local data = this.timers[tick]
        if not data then
            return
        end

        if data.repeat_function then
            this.timers[tick + data.tick] = data
            this.timers[tick + data.tick].previous = tick
            data.new = tick + data.tick
        end

        Task.set_timeout_in_ticks(data.tick, do_job_token, data)

        this.timers[tick] = nil
    end
)

return Public
