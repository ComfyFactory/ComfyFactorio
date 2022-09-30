local Public = {}
local math_random = math.random
local math_floor = math.floor
local math_sqrt = math.sqrt
local math_round = math.round
local table_size = table.size
local table_insert = table.insert
local table_remove = table.remove
local table_shuffle = table.shuffle_table

local Event = require 'utils.event'
local Global = require 'utils.global'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'

local tick_schedule = {}
Global.register(
    tick_schedule,
    function(t)
        tick_schedule = t
    end
)

local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Evolution = require 'maps.scrap_towny_ffa.evolution'

local function get_commmands(target, group)
    local commands = {}
    local group_position = {x = group.position.x, y = group.position.y}
    local step_length = 128

    local target_position = target.position
    local distance_to_target = math_floor(math_sqrt((target_position.x - group_position.x) ^ 2 + (target_position.y - group_position.y) ^ 2))
    local steps = math_floor((distance_to_target - 27) / step_length) + 1
    local vector = {math_round((target_position.x - group_position.x) / steps, 3), math_round((target_position.y - group_position.y) / steps, 3)}

    for _ = 1, steps, 1 do
        group_position.x = group_position.x + vector[1]
        group_position.y = group_position.y + vector[2]
        local position = group.surface.find_non_colliding_position('small-biter', group_position, step_length, 2)
        if position then
            commands[#commands + 1] = {
                type = defines.command.go_to_location,
                destination = {x = position.x, y = position.y},
                radius = 16,
                distraction = defines.distraction.by_damage
            }
        end
    end

    commands[#commands + 1] = {
        type = defines.command.attack,
        target = target,
        distraction = defines.distraction.by_damage
    }
    commands[#commands + 1] = {
        type = defines.command.attack_area,
        destination = target.position,
        radius = 27,
        distraction = defines.distraction.by_anything
    }
    commands[#commands + 1] = {
        type = defines.command.build_base,
        destination = target.position,
        distraction = defines.distraction.by_damage
    }

    return commands
end

local function roll_market()
    local this = ScenarioTable.get_table()
    local town_centers = this.town_centers
    if town_centers == nil or table_size(town_centers) == 0 then
        return
    end
    local keyset = {}
    for town_name, town_center in pairs(town_centers) do
        local evolution = Evolution.get_biter_evolution(town_center.market.position)
        local tries = math_floor(evolution * 20)
        -- 1 try for each 5% of evolution
        for _ = 1, tries, 1 do
            table_insert(keyset, town_name)
        end
    end
    local tc = math_random(1, #keyset)
    return town_centers[keyset[tc]]
end

local function get_random_close_spawner(surface, market, radius)
    local units = surface.find_enemy_units(market.position, radius, market.force)
    if units ~= nil and #units > 0 then
        -- found units, shuffle the list
        table_shuffle(units)
        while units[1] do
            local unit = units[1]
            if unit.spawner then
                return unit.spawner
            end
            table_remove(units, 1)
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
    local this = ScenarioTable.get_table()
    if this.testing_mode then
        return
    end
    for k, swarm in pairs(this.swarms) do
        if not is_swarm_valid(swarm) then
            table_remove(this.swarms, k)
        end
    end
end

function Public.unit_groups_start_moving()
    local this = ScenarioTable.get_table()
    if this.testing_mode then
        return
    end
    for _, swarm in pairs(this.swarms) do
        if swarm.group then
            if swarm.group.valid then
                swarm.group.start_moving()
            end
        end
    end
end

local function new_town(town_center)
    -- cooldown for swarms on new towns is 15 minutes
    local cooldown_ticks = 15 * 3600
    local elapsed_ticks = game.tick - town_center.creation_tick
    -- skip if within first 30 minutes and town evolution < 0.25
    if elapsed_ticks < cooldown_ticks and town_center.evolution.biters < 0.15 then
        return true
    end
    return false
end

function Public.swarm(town_center, radius)
    if town_center == nil then
        return
    end
    local this = ScenarioTable.get_table()
    if this.testing_mode then
        return
    end
    local r = radius or 32
    local tc = town_center or roll_market()
    if not tc or r > 512 then
        return
    end
    -- cancel if relatively new town
    if new_town(tc) then
        return
    end
    -- skip if we have to many swarms already
    local count = table_size(this.swarms)
    local towns = table_size(this.town_centers)
    if count > 3 * towns then
        return
    end

    local market = tc.market
    local surface = market.surface

    -- find a spawner
    local spawner = get_random_close_spawner(surface, market, r)
    if not spawner then
        r = r + 16
        local future = game.tick + 1
        -- schedule to run this method again with a higher radius on next tick
        if not tick_schedule[future] then
            tick_schedule[future] = {}
        end
        tick_schedule[future][#tick_schedule[future] + 1] = {
            callback = 'swarm',
            params = {tc, r}
        }
        return
    end

    -- get our evolution at the spawner location
    local evolution
    if spawner.name == 'spitter-spawner' then
        evolution = Evolution.get_biter_evolution(spawner)
    else
        evolution = Evolution.get_spitter_evolution(spawner)
    end

    -- get the evolution at the market location
    local market_evolution = Evolution.get_evolution(market.position)

    -- get our target amount of enemies based on relative evolution
    local count2 = (evolution * 124) + 4

    local units = spawner.surface.find_enemy_units(spawner.position, 16, market.force)
    if #units < count2 then
        units = spawner.surface.find_enemy_units(spawner.position, 32, market.force)
    end
    if #units < count2 then
        units = spawner.surface.find_enemy_units(spawner.position, 64, market.force)
    end
    if #units < count2 then
        units = spawner.surface.find_enemy_units(spawner.position, 128, market.force)
    end
    if not units[1] then
        return
    end

    -- try up to 10 times to throw in a boss based on market evolution
    -- evolution = 0%, chances 0 in 10
    -- evoution = 10%, chances 1 in 10
    -- evolution = 20%, chances 2 in 10
    -- evolution = 100%, chances 10 in 10
    local health_multiplier = 40 * market_evolution + 10
    for _ = 1, math_floor(market_evolution * 10), 1 do
        if math_random(1, 2) == 1 then
            BiterHealthBooster.add_boss_unit(units[1], health_multiplier)
        end
    end

    local unit_group_position = surface.find_non_colliding_position('biter-spawner', units[1].position, 256, 1)
    if not unit_group_position then
        return
    end
    local unit_group = surface.create_unit_group({position = unit_group_position, force = units[1].force})

    for key, unit in pairs(units) do
        if key > count2 then
            break
        end
        unit_group.add_member(unit)
    end

    unit_group.set_command(
        {
            type = defines.command.compound,
            structure_type = defines.compound_command.return_last,
            commands = get_commmands(market, unit_group)
        }
    )
    table_insert(this.swarms, {group = unit_group, timeout = game.tick + 36000})
end

local function on_unit_group_finished_gathering(event)
    local unit_group = event.group
    local position = unit_group.position
    local entities = unit_group.surface.find_entities_filtered({position = position, radius = 256, name = 'market'})
    local target = entities[1]
    if target ~= nil then
        local force = target.force
        local this = ScenarioTable.get_table()
        local town_centers = this.town_centers
        local town_center = town_centers[force.name]
        -- cancel if relatively new town
        if new_town(town_center) then
            return
        end
        unit_group.set_command(
            {
                type = defines.command.compound,
                structure_type = defines.compound_command.return_last,
                commands = get_commmands(target, unit_group)
            }
        )
    end
end

local function on_tick()
    if not tick_schedule[game.tick] then
        return
    end
    for _, token in pairs(tick_schedule[game.tick]) do
        local callback = token.callback
        local params = token.params
        if callback == 'swarm' then
            Public.swarm(params[1], params[2])
        end
    end
    tick_schedule[game.tick] = nil
end

local on_init = function()
    BiterHealthBooster.acid_nova(true)
    BiterHealthBooster.check_on_entity_died(true)
end

Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_unit_group_finished_gathering, on_unit_group_finished_gathering)

return Public
