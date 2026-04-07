local Global = require 'utils.global'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local Utils = require 'maps.oarc.ms_utils'
local Event = require 'utils.event'
local MT = require 'maps.oarc.table'
local Evolution = require 'maps.oarc.evolution'

local this = {}

Global.register(
    this,
    function (t)
        this = t
    end
)

local Public = {}
local math_random = math.random
local math_floor = math.floor
local table_size = table.size
local table_insert = table.insert
local table_remove = table.remove
local table_shuffle = table.shuffle_table

local function get_commmands(target, tc)
    local commands = {}

    commands[#commands + 1] =
    {
        type = defines.command.attack_area,
        destination = target.position,
        radius = 16,
        distraction = defines.distraction.by_anything
    }
    commands[#commands + 1] =
    {
        type = defines.command.attack_area,
        destination = target.position,
        radius = 20,
        distraction = defines.distraction.by_anything
    }

    local main_force_name = MT.get('main_force_name')

    if tc.force ~= main_force_name then
        commands[#commands + 1] =
        {
            type = defines.command.build_base,
            destination = target.position,
            distraction = defines.distraction.by_anything
        }
    end

    return commands
end

local function roll_town()
    local towns = MT.get('towns')
    if towns == nil or table_size(towns) == 0 then
        return
    end
    local keyset = {}
    for town_name, town in pairs(towns) do
        if town and town.position then
            local evolution = Evolution.get_evolution(town.position)
            local tries = math_floor(evolution * 20)
            -- 1 try for each 5% of evolution
            for _ = 1, tries, 1 do
                table_insert(keyset, town_name)
            end
        end
    end
    if #keyset > 0 then
        local tc = math_random(1, #keyset)
        return towns[keyset[tc]]
    end
end

local function get_random_close_spawner(surface, position, force, radius)
    if not game.forces[force] then
        return
    end

    local units = surface.find_enemy_units(position, radius, force)
    if units ~= nil and #units > 0 then
        table_shuffle(units)
        for _, unit in pairs(units) do
            if unit.spawner then
                return unit.spawner
            end
        end
    end
end

local function is_swarm_valid(swarm)
    local group = swarm.group
    if not group then
        return
    end
    if not group.valid then
        return
    end
    if game.tick >= swarm.timeout then
        group.destroy()
        return
    end
    return true
end

function Public.validate_swarms()
    local swarms = MT.get('swarms')
    for k, swarm in pairs(swarms) do
        if not is_swarm_valid(swarm) then
            table_remove(swarms, k)
        end
    end
end

function Public.unit_groups_start_moving()
    local swarms = MT.get('swarms')
    for _, swarm in pairs(swarms) do
        if swarm.group then
            if swarm.group.valid then
                swarm.group.start_moving()
            end
        end
    end
end

local function new_town(town)
    -- cooldown for swarms on new towns is 15 minutes
    local cooldown_ticks = 15 * 3600
    local elapsed_ticks = game.tick - town.creation_tick
    -- skip if within first 30 minutes and town evolution < 0.25
    if elapsed_ticks < cooldown_ticks and town.evolution.biters < 0.15 then
        return true
    end
    return false
end

local function search_for_town_entities(surface, position, force)
    local entities = surface.find_entities_filtered({ position = position, radius = 512, force = force })
    if entities and #entities > 1 then
        table_shuffle(entities)
        if entities[1] and entities[1].valid and entities[1].health then
            return entities[1]
        end
    end
end

function Public.swarm(town, radius)
    local towns = MT.get('towns')
    local swarms = MT.get('swarms')
    local r = radius or 32
    local tc = town or roll_town()
    if not tc or r > 512 then
        return
    end
    -- cancel if relatively new town
    if new_town(tc) then
        return
    end

    -- skip if we have to many swarms already
    local count = table_size(swarms)
    local size_of_towns = table_size(towns)
    if count > 3 * size_of_towns then
        return
    end

    local surface_index = tc.surface
    local surface = game.get_surface(surface_index)
    if not surface or not surface.valid then
        return
    end

    -- find a spawner
    local spawner = get_random_close_spawner(surface, tc.position, tc.force, r)
    if not spawner then
        r = r + 16
        local tick = game.tick + 5
        -- schedule to run this method again with a higher radius on next tick
        if not this[tick] then
            this[tick] = { town = tc, radius = r }
        end
        return
    end

    -- get our evolution at the spawner location
    local evolution
    if spawner.name == 'spitter-spawner' then
        evolution = Evolution.get_biter_evolution(spawner)
    else
        evolution = Evolution.get_spitter_evolution(spawner)
    end

    -- get the evolution at the location
    local town_evo = Evolution.get_evolution(tc.position)

    -- get our target amount of enemies based on relative evolution
    local count2 = (evolution * 124) + 4

    local units = spawner.surface.find_enemy_units(spawner.position, 16, tc.force)
    if #units < count2 then
        units = spawner.surface.find_enemy_units(spawner.position, 32, tc.force)
    end
    if #units < count2 then
        units = spawner.surface.find_enemy_units(spawner.position, 64, tc.force)
    end
    if #units < count2 then
        units = spawner.surface.find_enemy_units(spawner.position, 128, tc.force)
    end
    if not units[1] then
        return
    end

    -- try up to 10 times to throw in a boss based on evolution
    -- evolution = 0%, chances 0 in 10
    -- evoution = 10%, chances 1 in 10
    -- evolution = 20%, chances 2 in 10
    -- evolution = 100%, chances 10 in 10
    local health_multiplier = 40 * town_evo + 10
    for _ = 1, math_floor(town_evo * 10), 1 do
        if math_random(1, 2) == 1 then
            BiterHealthBooster.add_boss_unit(units[1], health_multiplier)
        end
    end

    local random_target = search_for_town_entities(surface, tc.position, tc.force)

    local unit_group_position = surface.find_non_colliding_position('biter-spawner', units[1].position, 256, 1)
    if not unit_group_position then
        return
    end
    local unit_group = surface.create_unit_group({ position = unit_group_position, force = units[1].force })

    for key, unit in pairs(units) do
        if key > count2 then
            break
        end
        unit_group.add_member(unit)
    end

    if random_target then
        unit_group.set_command(
            {
                type = defines.command.compound,
                structure_type = defines.compound_command.return_last,
                commands = get_commmands(random_target, tc)
            }
        )
    end

    swarms[#swarms + 1] = { group = unit_group, timeout = game.tick + 36000 }
end

local function on_unit_group_finished_gathering(event)
    local unit_group = event.group
    local position = unit_group.position
    local entities = unit_group.surface.find_entities_filtered({ position = position, radius = 256, name = 'market' })
    local target = entities[1]
    if target ~= nil then
        local force = target.force
        Utils.get_owner_of_town(
            force.name,
            function (town)
                -- cancel if relatively new town
                if new_town(town) then
                    return
                end
                Public.swarm(town)
            end
        )
    end
end

local function on_tick()
    local tick = game.tick

    if not this[tick] then
        return
    end

    local params = this[tick]
    local town = params.town
    local radius = params.radius

    Public.swarm(town, radius)
    this[tick] = nil
end

local on_init = function ()
    BiterHealthBooster.acid_nova(true)
    BiterHealthBooster.check_on_entity_died(true)
end

Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_unit_group_finished_gathering, on_unit_group_finished_gathering)

return Public
