local Public = require 'modules.wave_defense.table'
local Event = require 'utils.event'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local math_random = math.random
local round = math.round
local Token = require 'utils.token'
local Task = require 'utils.task'

local immunity_spawner =
    Token.register(
    function(data)
        local entity = data.entity
        if not entity or not entity.valid then
            return
        end
        entity.destructible = true
    end
)

local function is_boss(entity)
    local unit_number = entity.unit_number
    local biter_health_boost_units = BiterHealthBooster.get('biter_health_boost_units')
    if not biter_health_boost_units then
        return
    end
    local unit = biter_health_boost_units[unit_number]
    if unit and unit[3] and unit[3].healthbar_id then
        return true
    else
        return false
    end
end

local function remove_unit(entity)
    local generated_units = Public.get('generated_units')
    local unit_number = entity.unit_number
    if not generated_units.active_biters[unit_number] then
        return
    end
    local m = 1
    local biter_health_boost_units = BiterHealthBooster.get('biter_health_boost_units')
    if not biter_health_boost_units then
        return
    end

    if biter_health_boost_units[unit_number] then
        m = 1 / biter_health_boost_units[unit_number][2]
    end
    local active_threat_loss = math.round(Public.threat_values[entity.name] * m, 2)
    local active_biter_threat = Public.get('active_biter_threat')
    Public.set('active_biter_threat', active_biter_threat - active_threat_loss)
    local active_biter_count = Public.get('active_biter_count')
    Public.set('active_biter_count', active_biter_count - 1)
    generated_units.active_biters[unit_number] = nil

    if active_biter_count <= 0 then
        Public.set('active_biter_count', 0)
    end
    if active_biter_threat <= 0 then
        Public.set('active_biter_threat', 0)
    end
end

local function place_nest_near_unit_group()
    local random_group = Public.get('random_group')
    if not (random_group and random_group.valid) then
        return
    end

    local generated_units = Public.get('generated_units')
    local group = generated_units.unit_groups[random_group.group_number]
    if not group then
        return
    end
    if not group.valid then
        return
    end
    if not group.members then
        return
    end
    if not group.members[1] then
        return
    end
    local unit = group.members[math_random(1, #group.members)]
    if not unit.valid then
        return
    end
    local name = 'biter-spawner'
    if math_random(1, 3) == 1 then
        name = 'spitter-spawner'
    end
    local position = unit.surface.find_non_colliding_position(name, unit.position, 12, 1)
    if not position then
        return
    end
    local r = Public.get('nest_building_density')
    if
        unit.surface.count_entities_filtered(
            {
                type = 'unit-spawner',
                force = unit.force,
                area = {{position.x - r, position.y - r}, {position.x + r, position.y + r}}
            }
        ) > 0
     then
        return
    end

    local boss = is_boss(unit)

    local modified_unit_health = Public.get('modified_unit_health')
    local modified_boss_unit_health = Public.get('modified_boss_unit_health')

    local spawner = unit.surface.create_entity({name = name, position = position, force = unit.force})
    spawner.destructible = false
    Task.set_timeout_in_ticks(200, immunity_spawner, {entity = spawner})

    if boss then
        BiterHealthBooster.add_boss_unit(spawner, modified_boss_unit_health.current_value, 0.5)
    else
        BiterHealthBooster.add_unit(spawner, modified_unit_health.current_value)
    end
    generated_units.nests[#generated_units.nests + 1] = spawner
    unit.surface.create_entity({name = 'blood-explosion-huge', position = position})
    unit.surface.create_entity({name = 'blood-explosion-huge', position = unit.position})
    remove_unit(unit)
    unit.destroy()
    local threat = Public.get('threat')
    Public.set('threat', threat - Public.threat_values[name])
    return true
end

function Public.build_nest()
    local threat = Public.get('threat')
    if threat < 1024 then
        return
    end
    local unit_groups_size = Public.get('unit_groups_size')
    if unit_groups_size == 0 then
        return
    end
    for _ = 1, 2, 1 do
        if place_nest_near_unit_group() then
            return
        end
    end
end

function Public.build_worm()
    local threat = Public.get('threat')
    if threat < 512 then
        return
    end
    local worm_building_chance = Public.get('worm_building_chance') --[[@as integer]]

    if math_random(1, worm_building_chance) ~= 1 then
        return
    end

    local unit_groups_size = Public.get('unit_groups_size')
    if unit_groups_size == 0 then
        return
    end

    local random_group = Public.get('random_group')
    if not (random_group and random_group.valid) then
        return
    end
    local generated_units = Public.get('generated_units')
    local group = generated_units.unit_groups[random_group.group_number]
    if not group then
        return
    end
    if not group.valid then
        return
    end
    if not group.members then
        return
    end
    if not group.members[1] then
        return
    end
    local unit = group.members[math_random(1, #group.members)]
    if not unit.valid then
        return
    end

    local boss = is_boss(unit)

    local wave_number = Public.get('wave_number')
    local position = unit.surface.find_non_colliding_position('assembling-machine-1', unit.position, 8, 1)
    Public.wave_defense_set_worm_raffle(wave_number)
    local worm = Public.wave_defense_roll_worm_name()
    if not position then
        return
    end

    local worm_building_density = Public.get('worm_building_density')
    local r = worm_building_density
    if
        unit.surface.count_entities_filtered(
            {
                type = 'turret',
                force = unit.force,
                area = {{position.x - r, position.y - r}, {position.x + r, position.y + r}}
            }
        ) > 0
     then
        return
    end
    local u = unit.surface.create_entity({name = worm, position = position, force = unit.force})
    local worm_unit_settings = Public.get('worm_unit_settings')
    local modified_unit_health = Public.get('modified_unit_health')
    local modified_boss_unit_health = Public.get('modified_boss_unit_health')

    if boss then
        BiterHealthBooster.add_boss_unit(u, modified_boss_unit_health.current_value, 0.5)
    else
        local final_health = round(modified_unit_health.current_value * worm_unit_settings.scale_units_by_health[worm], 3)
        if final_health < 1 then
            final_health = 1
        end
        BiterHealthBooster.add_unit(u, final_health)
    end

    unit.surface.create_entity({name = 'blood-explosion-huge', position = position})
    unit.surface.create_entity({name = 'blood-explosion-huge', position = unit.position})
    remove_unit(unit)
    unit.destroy()
    Public.set('threat', threat - Public.threat_values[worm])
end

local function shred_simple_entities(entity)
    local threat = Public.get('threat')
    if threat < 25000 then
        return
    end
    local simple_entities =
        entity.surface.find_entities_filtered(
        {
            type = 'simple-entity',
            area = {{entity.position.x - 3, entity.position.y - 3}, {entity.position.x + 3, entity.position.y + 3}}
        }
    )
    if #simple_entities == 0 then
        return
    end
    if #simple_entities > 1 then
        table.shuffle_table(simple_entities)
    end
    local r = math.floor(threat * 0.00004)
    if r < 1 then
        r = 1
    end
    local count = math.random(1, r)
    --local count = 1
    local damage_dealt = 0
    for i = 1, count, 1 do
        if not simple_entities[i] then
            break
        end
        if simple_entities[i].valid then
            if simple_entities[i].health then
                damage_dealt = damage_dealt + simple_entities[i].health
                simple_entities[i].die('neutral', simple_entities[i])
            end
        end
    end
    if damage_dealt == 0 then
        return
    end
    local simple_entity_shredding_cost_modifier = Public.get('simple_entity_shredding_cost_modifier')
    local threat_cost = math.floor(damage_dealt * simple_entity_shredding_cost_modifier)
    if threat_cost < 1 then
        threat_cost = 1
    end
    Public.set('threat', threat - threat_cost)
end

local function spawn_unit_spawner_inhabitants(entity)
    if entity.type ~= 'unit-spawner' then
        return
    end
    local wave_number = Public.get('wave_number')
    local count = 8 + math.floor(wave_number * 0.02)
    if count > 128 then
        count = 128
    end
    Public.wave_defense_set_unit_raffle(wave_number)
    for _ = 1, count, 1 do
        local position = {entity.position.x + (-4 + math.random(0, 8)), entity.position.y + (-4 + math.random(0, 8))}
        if math.random(1, 4) == 1 then
            entity.surface.create_entity({name = Public.wave_defense_roll_spitter_name(), position = position, force = 'enemy'})
        else
            entity.surface.create_entity({name = Public.wave_defense_roll_biter_name(), position = position, force = 'enemy'})
        end
    end
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity.valid then
        return
    end

    local disable_threat_below_zero = Public.get('disable_threat_below_zero')
    local valid_enemy_forces = Public.get('valid_enemy_forces')
    if not valid_enemy_forces then
        return
    end

    local modified_unit_health = Public.get('modified_unit_health')
    if not modified_unit_health then
        return
    end
    local modified_boss_unit_health = Public.get('modified_boss_unit_health')
    if not modified_boss_unit_health then
        return
    end

    local boss = is_boss(entity)

    local boost_value = modified_unit_health.current_value
    if boss then
        boost_value = modified_boss_unit_health.current_value / 2
    end

    if entity.type == 'unit' then
        if not Public.threat_values[entity.name] then
            return
        end
        if disable_threat_below_zero then
            local threat = Public.get('threat')
            if threat <= 0 then
                Public.set('threat', 0)
                remove_unit(entity)
                return
            end
            Public.set('threat', math.round(threat - Public.threat_values[entity.name] * boost_value, 2))
            remove_unit(entity)
        else
            local threat = Public.get('threat')
            Public.set('threat', math.round(threat - Public.threat_values[entity.name] * boost_value, 2))
            remove_unit(entity)
        end
    else
        if valid_enemy_forces[entity.force.name] then
            if entity.health then
                if Public.threat_values[entity.name] then
                    local threat = Public.get('threat')
                    Public.set('threat', math.round(threat - Public.threat_values[entity.name] * boost_value, 2))
                end
                spawn_unit_spawner_inhabitants(entity)
            end
        end
    end

    if entity.force.index == 3 then
        if event.cause then
            if event.cause.valid then
                if event.cause.force.index == 2 then
                    shred_simple_entities(entity)
                end
            end
        end
    end
end

Event.add(defines.events.on_entity_died, on_entity_died)

return Public
