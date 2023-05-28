local Public = require 'modules.wave_defense.core'
local Event = require 'utils.event'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Alert = require 'utils.alert'
local Server = require 'utils.server'

local random = math.random
local floor = math.floor
local sqrt = math.sqrt
local round = math.round
local raise = Event.raise

local function debug_print(msg)
    local debug = Public.get('debug')
    if not debug then
        return
    end
    print('WaveDefense: ' .. msg)
end

local function debug_print_health(msg)
    local debug = Public.get('debug_health')
    if not debug then
        return
    end
    print('[HEALTHBOOSTER]: ' .. msg)
end

local function valid(userdata)
    if not (userdata and userdata.valid) then
        return false
    end
    return true
end

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = math.random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

local function find_initial_spot(surface, position)
    local spot = Public.get('spot')
    if not spot then
        local pos = surface.find_non_colliding_position('rocket-silo', position, 128, 1)
        if not pos then
            pos = surface.find_non_colliding_position('rocket-silo', position, 148, 1)
        end
        if not pos then
            pos = surface.find_non_colliding_position('rocket-silo', position, 164, 1)
        end
        if not pos then
            pos = surface.find_non_colliding_position('rocket-silo', position, 200, 1)
        end
        if not pos then
            pos = position
        end

        if random(1, 2) == 1 then
            local random_pos = {
                {x = pos.x - 10, y = pos.y - 5},
                {x = pos.x + 10, y = pos.y - 5},
                {x = pos.x - 10, y = pos.y - 5},
                {x = pos.x + 10, y = pos.y - 5}
            }
            local actual_pos = shuffle(random_pos)
            pos = {x = actual_pos[1].x, y = actual_pos[1].y}
        end

        if not pos then
            pos = position
        end

        Public.set('spot', pos)
        return pos
    else
        spot = Public.get('spot')
        return spot
    end
end

local function is_closer(pos1, pos2, pos)
    return ((pos1.x - pos.x) ^ 2 + (pos1.y - pos.y) ^ 2) < ((pos2.x - pos.x) ^ 2 + (pos2.y - pos.y) ^ 2)
end

local function shuffle_distance(tbl, position)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = random(size)
        if is_closer(tbl[i].position, tbl[rand].position, position) and i > rand then
            tbl[i], tbl[rand] = tbl[rand], tbl[i]
        end
    end
    return tbl
end

local function is_position_near(pos_to_check, check_against)
    local function inside(pos)
        return pos.x >= pos_to_check.x and pos.y >= pos_to_check.y and pos.x <= pos_to_check.x and pos.y <= pos_to_check.y
    end

    if inside(check_against) then
        return true
    end

    return false
end

local function remove_trees(entity)
    if not valid(entity) then
        return
    end
    local surface = entity.surface
    local radius = 10
    local pos = entity.position
    local area = {{pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius}}
    local trees = surface.find_entities_filtered {area = area, type = 'tree'}
    if #trees > 0 then
        for _, tree in pairs(trees) do
            if tree and tree.valid then
                tree.destroy()
            end
        end
    end
end

local function remove_rocks(entity)
    if not valid(entity) then
        return
    end
    local surface = entity.surface
    local radius = 10
    local pos = entity.position
    local area = {{pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius}}
    local rocks = surface.find_entities_filtered {area = area, type = 'simple-entity'}
    if #rocks > 0 then
        for _, rock in pairs(rocks) do
            if rock and rock.valid then
                rock.destroy()
            end
        end
    end
end

local function fill_tiles(entity, size)
    if not valid(entity) then
        return
    end
    local surface = entity.surface
    local radius = size or 10
    local pos = entity.position
    local t = {
        'water',
        'water-green',
        'water-mud',
        'water-shallow',
        'deepwater',
        'deepwater-green'
    }
    local area = {{pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius}}
    local tiles = surface.find_tiles_filtered {area = area, name = t}
    if #tiles > 0 then
        for _, tile in pairs(tiles) do
            surface.set_tiles({{name = 'sand-1', position = tile.position}}, true)
        end
    end
    debug_print('fill_tiles - filled tiles cause we found non-placable tiles.')
end

local function get_spawn_pos()
    local surface_index = Public.get('surface_index')
    local surface = game.surfaces[surface_index]
    if not surface then
        return debug_print('get_spawn_pos - surface was not valid?')
    end

    local c = 0

    ::retry::

    local initial_position = Public.get('spawn_position')

    if random(1, 2) == 1 then
        initial_position = {x = initial_position.x, y = initial_position.y - 30}
    else
        initial_position = {x = initial_position.x, y = initial_position.y - 20}
    end

    local located_position = find_initial_spot(surface, initial_position)
    local valid_position = surface.find_non_colliding_position('stone-furnace', located_position, 32, 1)
    local debug = Public.get('debug')
    if debug then
        if valid_position then
            local x = valid_position.x
            local y = valid_position.y
            game.print('[gps=' .. x .. ',' .. y .. ',' .. surface.name .. ']')
        end
    end

    if not valid_position then
        local remove_entities = Public.get('remove_entities')
        if remove_entities then
            c = c + 1
            valid_position = Public.get('spawn_position')
            debug_print(serpent.block('valid_position - x:' .. valid_position.x .. ' y:' .. valid_position.y))
            remove_trees({surface = surface, position = valid_position, valid = true})
            remove_rocks({surface = surface, position = valid_position, valid = true})
            fill_tiles({surface = surface, position = valid_position, valid = true})
            Public.set('spot', 'nil')
            if c == 5 then
                return debug_print('get_spawn_pos - we could not find a spawning pos?')
            end
            goto retry
        else
            return debug_print('get_spawn_pos - we could not find a spawning pos?')
        end
    end

    debug_print(serpent.block('valid_position - x:' .. valid_position.x .. ' y:' .. valid_position.y))

    return valid_position
end

local function is_unit_valid(biter)
    local max_biter_age = Public.get('max_biter_age')
    if not biter.entity then
        debug_print('is_unit_valid - unit destroyed - does no longer exist')
        return false
    end
    if not biter.entity.valid then
        debug_print('is_unit_valid - unit destroyed - invalid')
        return false
    end
    if biter.spawn_tick + max_biter_age < game.tick then
        debug_print('is_unit_valid - unit destroyed - timed out')
        return false
    end
    return true
end

local function refresh_active_unit_threat()
    local active_biter_threat = Public.get('active_biter_threat')
    local generated_units = Public.get('generated_units')
    debug_print('refresh_active_unit_threat - current value ' .. active_biter_threat)
    local biter_threat = 0
    for k, biter in pairs(generated_units.active_biters) do
        if valid(biter.entity) then
            biter_threat = biter_threat + Public.threat_values[biter.entity.name]
        else
            generated_units.active_biters[k] = nil
        end
    end
    local biter_health_boost = BiterHealthBooster.get('biter_health_boost')
    Public.set('active_biter_threat', round(biter_threat * biter_health_boost, 2))
    debug_print('refresh_active_unit_threat - new value ' .. active_biter_threat)
    if generated_units.unit_group_pos.index > 500 then
        generated_units.unit_group_pos.positions = {}
        generated_units.unit_group_pos.index = 0
    end
end

local function time_out_biters()
    local generated_units = Public.get('generated_units')
    local active_biter_count = Public.get('active_biter_count')
    local active_biter_threat = Public.get('active_biter_threat')
    local valid_enemy_forces = Public.get('valid_enemy_forces')

    if active_biter_count >= 100 and #generated_units.active_biters <= 10 then
        Public.set('active_biter_count', 50)
    end

    local biter_health_boost = BiterHealthBooster.get('biter_health_boost')

    for k, biter in pairs(generated_units.active_biters) do
        if not is_unit_valid(biter) then
            Public.set('active_biter_count', active_biter_count - 1)
            local entity = biter.entity
            if entity and entity.valid then
                Public.set('active_biter_threat', active_biter_threat - round(Public.threat_values[entity.name] * biter_health_boost, 2))
                if valid_enemy_forces[entity.force.name] then
                    entity.destroy()
                end
            end
            debug_print('time_out_biters: ' .. k .. ' got deleted.')
            generated_units.active_biters[k] = nil
        end
    end
end

local function get_random_close_spawner()
    local generated_units = Public.get('generated_units')
    local target = Public.get('target')
    local get_random_close_spawner_attempts = Public.get('get_random_close_spawner_attempts')
    local center = target.position
    local spawner
    local retries = 0
    for _ = 1, get_random_close_spawner_attempts, 1 do
        ::retry::
        if #generated_units.nests < 1 then
            return false
        end
        local k = random(1, #generated_units.nests)
        local spawner_2 = generated_units.nests[k]
        if not spawner_2 or not spawner_2.valid then
            generated_units.nests[k] = nil
            retries = retries + 1
            if retries == 5 then
                break
            end
            goto retry
        end
        if not spawner or (center.x - spawner_2.position.x) ^ 2 + (center.y - spawner_2.position.y) ^ 2 < (center.x - spawner.position.x) ^ 2 + (center.y - spawner.position.y) ^ 2 then
            spawner = spawner_2
            if spawner and spawner.position then
                debug_print('get_random_close_spawner - Found at x' .. spawner.position.x .. ' y' .. spawner.position.y)
            end
        end
    end
    return spawner
end

local function get_random_character()
    local characters = {}
    local surface_index = Public.get('surface_index')
    local p = game.connected_players
    for _, player in pairs(p) do
        if player.character then
            if player.character.valid then
                if player.character.surface.index == surface_index then
                    characters[#characters + 1] = player.character
                end
            end
        end
    end
    if not characters[1] then
        return
    end
    return characters[random(1, #characters)]
end

local function set_main_target()
    local target = Public.get('target')
    if target then
        if target.valid then
            raise(Public.events.on_target_aquired, {target = target})
            return
        end
    end

    local unit_groups_size = Public.get('unit_groups_size')
    if unit_groups_size < 0 then
        unit_groups_size = 0
    end
    Public.set('unit_groups_size', unit_groups_size)

    local sec_target = Public.get_side_target()
    if not sec_target then
        sec_target = get_random_character()
    end
    if not sec_target then
        raise(Public.events.on_target_aquired, {target = target})
        return
    end

    Public.set('target', sec_target)
    raise(Public.events.on_target_aquired, {target = target})
    debug_print('set_main_target -- New main target ' .. sec_target.name .. ' at position x' .. sec_target.position.x .. ' y' .. sec_target.position.y .. ' selected.')
end

local function set_group_spawn_position(surface)
    local spawner = get_random_close_spawner()
    if not spawner then
        return
    end
    local position = surface.find_non_colliding_position('behemoth-biter', spawner.position, 128, 1)
    if not position then
        return
    end
    Public.set('spawn_position', {x = position.x, y = position.y})
    local spawn_position = get_spawn_pos()
    if spawn_position then
        debug_print('set_group_spawn_position -- Changed position to x' .. spawn_position.x .. ' y' .. spawn_position.y .. '.')
    end
end

local function set_enemy_evolution()
    local wave_number = Public.get('wave_number')
    local generated_units = Public.get('generated_units')
    local threat = Public.get('threat')
    local evolution_factor = wave_number * 0.001
    local enemy = game.forces.enemy
    local biter_health_boost = 1

    if evolution_factor > 1 then
        evolution_factor = 1
    end

    if not next(generated_units.active_biters) then
        Public.set('active_biter_count', 0)
    end

    if threat > 50000 then
        biter_health_boost = round(biter_health_boost + (threat - 50000) * 0.000033, 3)
    end

    BiterHealthBooster.set('biter_health_boost', biter_health_boost)

    if enemy.evolution_factor == 1 and evolution_factor == 1 then
        return
    end

    enemy.evolution_factor = evolution_factor
    raise(Public.events.on_evolution_factor_changed, {evolution_factor = evolution_factor})
end

local function can_units_spawn()
    local threat = Public.get('threat')

    if threat <= 0 then
        debug_print('can_units_spawn - threat too low')
        time_out_biters()
        return false
    end

    local active_biter_count = Public.get('active_biter_count')
    local max_active_biters = Public.get('max_active_biters')
    if active_biter_count >= max_active_biters then
        debug_print('can_units_spawn - active biter count too high')
        time_out_biters()
        return false
    end

    local active_biter_threat = Public.get('active_biter_threat')
    if active_biter_threat >= threat then
        debug_print('can_units_spawn - active biter threat too high (' .. active_biter_threat .. ')')
        time_out_biters()
        return false
    end
    return true
end

local function get_active_unit_groups_count()
    local generated_units = Public.get('generated_units')
    local count = 0

    for k, g in pairs(generated_units.unit_groups) do
        if g.valid then
            if #g.members > 0 then
                count = count + 1
            else
                g.destroy()
                generated_units.unit_groups[k] = nil
                local unit_groups_size = Public.get('unit_groups_size')
                Public.set('unit_groups_size', unit_groups_size - 1)
            end
        else
            generated_units.unit_groups[k] = nil
            generated_units.unit_group_pos.positions[k] = nil
            local unit_groups_size = Public.get('unit_groups_size')
            Public.set('unit_groups_size', unit_groups_size - 1)
            if generated_units.unit_group_last_command[k] then
                generated_units.unit_group_last_command[k] = nil
            end
        end
    end
    debug_print('Active unit group count: ' .. count)
    return count
end

local function spawn_biter(surface, position, forceSpawn, is_boss_biter, unit_settings)
    if not forceSpawn then
        if not is_boss_biter then
            if not can_units_spawn() then
                return
            end
        end
    end

    local boosted_health = BiterHealthBooster.get('biter_health_boost')

    local name
    if random(1, 100) > 73 then
        name = Public.wave_defense_roll_spitter_name()
    else
        name = Public.wave_defense_roll_biter_name()
    end

    local old_position = position

    local enable_random_spawn_positions = Public.get('enable_random_spawn_positions')

    if enable_random_spawn_positions then
        if random(1, 3) == 1 then
            position = {x = (-1 * (position.x + random(1, 10))), y = (position.y + random(1, 10))}
        else
            position = {x = (position.x + random(1, 10)), y = (position.y + random(1, 10))}
        end
    end

    position = surface.find_non_colliding_position('steel-chest', position, 3, 1)
    if not position then
        position = old_position
    end

    local biter = surface.create_entity({name = name, position = position, force = 'enemy'})
    biter.ai_settings.allow_destroy_when_commands_fail = true
    biter.ai_settings.allow_try_return_to_spawner = false
    biter.ai_settings.do_separation = true

    local increase_health_per_wave = Public.get('increase_health_per_wave')
    local boost_units_when_wave_is_above = Public.get('boost_units_when_wave_is_above')
    local boost_bosses_when_wave_is_above = Public.get('boost_bosses_when_wave_is_above')
    local wave_number = Public.get('wave_number')

    if (increase_health_per_wave and (wave_number >= boost_units_when_wave_is_above)) and not is_boss_biter then
        local modified_unit_health = Public.get('modified_unit_health')
        local final_health = round(modified_unit_health.current_value * unit_settings.scale_units_by_health[biter.name], 3)
        if final_health < 1 then
            final_health = 1
        end
        debug_print_health('final_health - unit: ' .. biter.name .. ' with h-m: ' .. final_health)
        BiterHealthBooster.add_unit(biter, final_health)
    end

    if is_boss_biter then
        if (wave_number >= boost_bosses_when_wave_is_above) then
            local increase_boss_health_per_wave = Public.get('increase_boss_health_per_wave')
            if increase_boss_health_per_wave then
                local modified_boss_unit_health = Public.get('modified_boss_unit_health')
                BiterHealthBooster.add_boss_unit(biter, modified_boss_unit_health.current_value, 0.55)
            else
                local sum = boosted_health * 5
                BiterHealthBooster.add_boss_unit(biter, sum, 0.55)
            end
        else
            local sum = boosted_health * 5
            BiterHealthBooster.add_boss_unit(biter, sum, 0.55)
        end
    end

    local generated_units = Public.get('generated_units')

    generated_units.active_biters[biter.unit_number] = {entity = biter, spawn_tick = game.tick}
    local active_biter_count = Public.get('active_biter_count')
    Public.set('active_biter_count', active_biter_count + 1)
    local active_biter_threat = Public.get('active_biter_threat')
    Public.set('active_biter_threat', active_biter_threat + round(Public.threat_values[name] * boosted_health, 2))
    return biter
end

local function increase_biter_damage()
    local increase_damage_per_wave = Public.get('increase_damage_per_wave')
    if not increase_damage_per_wave then
        return
    end

    local e = game.forces.enemy
    local new = Difficulty.get('value') * 0.04
    local melee = new
    local bio = new - 0.02
    local e_old_melee = e.get_ammo_damage_modifier('melee')
    local e_old_biological = e.get_ammo_damage_modifier('biological')

    debug_print('Melee: ' .. melee + e_old_melee)
    debug_print('Biological: ' .. bio + e_old_biological)

    e.set_ammo_damage_modifier('melee', melee + e_old_melee)
    e.set_ammo_damage_modifier('biological', bio + e_old_biological)
end

local function increase_biters_health()
    local increase_health_per_wave = Public.get('increase_health_per_wave')
    if not increase_health_per_wave then
        return
    end

    -- this sets normal units health
    local modified_unit_health = Public.get('modified_unit_health')
    if modified_unit_health.current_value > modified_unit_health.limit_value then
        modified_unit_health.current_value = modified_unit_health.limit_value
    end
    debug_print_health('modified_unit_health.current_value: ' .. modified_unit_health.current_value)
    Public.set('modified_unit_health').current_value = modified_unit_health.current_value + modified_unit_health.health_increase_per_boss_wave

    -- this sets boss units health
    local modified_boss_unit_health = Public.get('modified_boss_unit_health')
    if modified_boss_unit_health.current_value > modified_boss_unit_health.limit_value then
        modified_boss_unit_health.current_value = modified_boss_unit_health.limit_value
    end
    debug_print_health('modified_boss_unit_health.current_value: ' .. modified_boss_unit_health.current_value)
    Public.set('modified_boss_unit_health').current_value = modified_boss_unit_health.current_value + modified_boss_unit_health.health_increase_per_boss_wave
end

local function increase_unit_group_size()
    local increase_average_unit_group_size = Public.get('increase_average_unit_group_size')
    if not increase_average_unit_group_size then
        return
    end

    local boost_spawner_sizes_wave_is_above = Public.get('boost_spawner_sizes_wave_is_above')
    local wave_number = Public.get('wave_number')

    if (wave_number >= boost_spawner_sizes_wave_is_above) then
        local average_unit_group_size = Public.get('average_unit_group_size')
        local new_average_unit_group_size = average_unit_group_size + 1

        if new_average_unit_group_size > 128 then
            new_average_unit_group_size = 128
        end

        Public.set('average_unit_group_size', new_average_unit_group_size)
        debug_print_health('average_unit_group_size - ' .. new_average_unit_group_size)
    end
end

local function increase_max_active_unit_groups()
    local _increase_max_active_unit_groups = Public.get('increase_max_active_unit_groups')
    if not _increase_max_active_unit_groups then
        return
    end

    local boost_spawner_sizes_wave_is_above = Public.get('boost_spawner_sizes_wave_is_above')
    local wave_number = Public.get('wave_number')

    if (wave_number >= boost_spawner_sizes_wave_is_above) then
        local max_active_unit_groups = Public.get('max_active_unit_groups')
        local new_max_active_unit_groups = max_active_unit_groups + 1

        if new_max_active_unit_groups > 64 then
            new_max_active_unit_groups = 64
        end

        Public.set('max_active_unit_groups', new_max_active_unit_groups)
        debug_print_health('max_active_unit_groups - ' .. new_max_active_unit_groups)
    end
end

local function set_next_wave()
    local wave_number = Public.get('wave_number')
    Public.set('wave_number', wave_number + 1)
    wave_number = Public.get('wave_number')

    local event_data = {}

    local threat_gain_multiplier = Public.get('threat_gain_multiplier')
    local threat_gain = wave_number * threat_gain_multiplier

    if wave_number > 1000 then
        threat_gain = threat_gain * (wave_number * 0.001)
    end
    if wave_number % 50 == 0 then
        increase_unit_group_size()
    end
    if wave_number % 200 == 0 then
        increase_max_active_unit_groups()
    end

    event_data.wave_number = wave_number

    if wave_number % 50 == 0 then
        increase_biter_damage()
        increase_biters_health()
        Public.set('boss_wave', true)
        event_data.boss_wave = true
        Public.set('boss_wave_warning', true)
        local alert_boss_wave = Public.get('alert_boss_wave')
        local spawn_position = get_spawn_pos()
        if alert_boss_wave then
            local msg = 'Boss Wave: ' .. wave_number
            local pos = {
                position = spawn_position
            }
            Alert.alert_all_players_location(pos, msg, {r = 0.8, g = 0.1, b = 0.1})
        end
        threat_gain = threat_gain * 2
    else
        local boss_wave_warning = Public.get('boss_wave_warning')
        if boss_wave_warning then
            Public.set('boss_wave_warning', false)
        end
    end

    local log_wave_to_discord = Public.get('log_wave_to_discord')

    if wave_number % 100 == 0 and log_wave_to_discord then
        Server.to_discord_embed('Current wave: ' .. wave_number)
    end

    local threat = Public.get('threat')
    Public.set('threat', threat + floor(threat_gain))

    local wave_enforced = Public.get('wave_enforced')
    local next_wave = Public.get('next_wave')
    local wave_interval = Public.get('wave_interval')
    event_data.next_wave = next_wave
    event_data.wave_interval = wave_interval
    event_data.threat_gain = threat_gain
    if not wave_enforced then
        Public.set('last_wave', next_wave)
        Public.set('next_wave', game.tick + wave_interval)
    end

    raise(Public.events.on_wave_created, event_data)
end

local function reform_group(group)
    local unit_group_command_step_length = Public.get('unit_group_command_step_length')
    local group_position = {x = group.position.x, y = group.position.y}
    local step_length = unit_group_command_step_length
    local generated_units = Public.get('generated_units')
    local position = group.surface.find_non_colliding_position('biter-spawner', group_position, step_length, 4)
    if position then
        local new_group = group.surface.create_unit_group {position = position, force = group.force}
        for _, biter in pairs(group.members) do
            new_group.add_member(biter)
        end
        debug_print('Creating new unit group, because old one was stuck.')
        generated_units.unit_groups[new_group.group_number] = new_group
        local unit_groups_size = Public.get('unit_groups_size')
        Public.set('unit_groups_size', unit_groups_size + 1)

        return new_group
    else
        debug_print('Destroying stuck group.')
        if generated_units.unit_groups[group.group_number] then
            if generated_units.unit_group_last_command[group.group_number] then
                generated_units.unit_group_last_command[group.group_number] = nil
            end
            local positions = generated_units.unit_group_pos.positions
            if positions[group.group_number] then
                positions[group.group_number] = nil
            end
            table.remove(generated_units.unit_groups, group.group_number)
            local unit_groups_size = Public.get('unit_groups_size')
            Public.set('unit_groups_size', unit_groups_size - 1)
        end
        group.destroy()
    end
    return nil
end

local function get_side_targets(group)
    local unit_group_command_step_length = Public.get('unit_group_command_step_length')
    local search_side_targets = Public.get('search_side_targets')

    local commands = {}
    local group_position = {x = group.position.x, y = group.position.y}
    local step_length = unit_group_command_step_length

    local side_target = Public.get_side_target()
    if not side_target then
        return
    end
    local target_position = side_target.position
    local distance_to_target = floor(sqrt((target_position.x - group_position.x) ^ 2 + (target_position.y - group_position.y) ^ 2))
    local steps = floor(distance_to_target / step_length) + 1

    for _ = 1, steps, 1 do
        local old_position = group_position
        local obstacles =
            group.surface.find_entities_filtered {
            position = old_position,
            radius = step_length * 2,
            type = search_side_targets,
            limit = 100
        }
        if obstacles then
            for v = 1, #obstacles, 1 do
                if obstacles[v].valid then
                    commands[#commands + 1] = {
                        type = defines.command.attack,
                        destination = obstacles[v].position,
                        distraction = defines.distraction.by_anything
                    }
                end
            end
        end

        commands[#commands + 1] = {
            type = defines.command.attack,
            target = side_target,
            distraction = defines.distraction.by_anything
        }
    end

    return commands
end

local function get_main_command(group)
    local unit_group_command_step_length = Public.get('unit_group_command_step_length')
    local commands = {}
    local group_position = {x = group.position.x, y = group.position.y}
    local step_length = unit_group_command_step_length

    local target = Public.get('target')
    if not valid(target) then
        return
    end

    debug_print('get_main_command - starting')

    local target_position = target.position
    local distance_to_target = floor(sqrt((target_position.x - group_position.x) ^ 2 + (target_position.y - group_position.y) ^ 2))
    local steps = floor(distance_to_target / step_length) + 1
    local vector = {
        round((target_position.x - group_position.x) / steps, 3),
        round((target_position.y - group_position.y) / steps, 3)
    }

    debug_print('get_commmands - to main target x' .. target_position.x .. ' y' .. target_position.y)
    debug_print('get_commmands - distance_to_target:' .. distance_to_target .. ' steps:' .. steps)
    debug_print('get_commmands - vector ' .. vector[1] .. '_' .. vector[2])

    for _ = 1, steps, 1 do
        local old_position = group_position
        group_position.x = group_position.x + vector[1]
        group_position.y = group_position.y + vector[2]
        local obstacles =
            group.surface.find_entities_filtered {
            position = old_position,
            radius = step_length / 2,
            type = {'simple-entity', 'tree'},
            limit = 50
        }
        if obstacles then
            shuffle_distance(obstacles, old_position)
            for ii = 1, #obstacles, 1 do
                if obstacles[ii].valid then
                    commands[#commands + 1] = {
                        type = defines.command.attack,
                        target = obstacles[ii],
                        distraction = defines.distraction.by_anything
                    }
                end
            end
        end
        local position = group.surface.find_non_colliding_position('behemoth-biter', group_position, step_length, 1)
        if position then
            commands[#commands + 1] = {
                type = defines.command.attack_area,
                destination = {x = position.x, y = position.y},
                radius = 16,
                distraction = defines.distraction.by_anything
            }
        end
    end

    commands[#commands + 1] = {
        type = defines.command.attack_area,
        destination = {x = target_position.x, y = target_position.y},
        radius = 8,
        distraction = defines.distraction.by_anything
    }

    commands[#commands + 1] = {
        type = defines.command.attack,
        target = target,
        distraction = defines.distraction.by_anything
    }

    return commands
end

local function command_to_main_target(group, bypass)
    if not valid(group) then
        return
    end
    local generated_units = Public.get('generated_units')
    local unit_group_command_delay = Public.get('unit_group_command_delay')
    if not bypass then
        if not generated_units.unit_group_last_command[group.group_number] then
            generated_units.unit_group_last_command[group.group_number] = game.tick - (unit_group_command_delay + 1)
        end

        if generated_units.unit_group_last_command[group.group_number] then
            if generated_units.unit_group_last_command[group.group_number] + unit_group_command_delay > game.tick then
                return
            end
        end
    end

    local fill_tiles_so_biter_can_path = Public.get('fill_tiles_so_biter_can_path')
    if fill_tiles_so_biter_can_path then
        fill_tiles(group, 10)
    end

    local tile = group.surface.get_tile(group.position)
    if tile.valid and tile.collides_with('player-layer') then
        group = reform_group(group)
    end
    if not valid(group) then
        return
    end

    local commands = get_main_command(group)

    debug_print('get_main_command - got commands')

    local surface_index = Public.get('surface_index')

    if group.surface.index ~= surface_index then
        return
    end

    group.set_command(
        {
            type = defines.command.compound,
            structure_type = defines.compound_command.return_last,
            commands = commands
        }
    )
    debug_print('get_main_command - sent commands')
    if valid(group) then
        generated_units.unit_group_last_command[group.group_number] = game.tick
    end
end

local function command_to_side_target(group)
    local generated_units = Public.get('generated_units')
    local unit_group_command_delay = Public.get('unit_group_command_delay')
    if not generated_units.unit_group_last_command[group.group_number] then
        generated_units.unit_group_last_command[group.group_number] = game.tick - (unit_group_command_delay + 1)
    end

    if generated_units.unit_group_last_command[group.group_number] then
        if generated_units.unit_group_last_command[group.group_number] + unit_group_command_delay > game.tick then
            return
        end
    end

    local tile = group.surface.get_tile(group.position)
    if tile.valid and tile.collides_with('player-layer') then
        group = reform_group(group)
    end

    local commands = get_side_targets(group)
    if not commands then
        return
    end

    group.set_command(
        {
            type = defines.command.compound,
            structure_type = defines.compound_command.return_last,
            commands = commands
        }
    )

    generated_units.unit_group_last_command[group.group_number] = game.tick
end

local function give_side_commands_to_group()
    local enable_side_target = Public.get('enable_side_target')
    if not enable_side_target then
        return
    end

    local target = Public.get('target')
    if not valid(target) then
        return
    end

    local generated_units = Public.get('generated_units')
    for _, group in pairs(generated_units.unit_groups) do
        if type(group) ~= 'number' then
            if group.valid then
                command_to_side_target(group)
            else
                get_active_unit_groups_count()
            end
        end
    end
end

local function give_main_command_to_group()
    local target = Public.get('target')
    if not valid(target) then
        return
    end

    local generated_units = Public.get('generated_units')
    for _, group in pairs(generated_units.unit_groups) do
        if type(group) ~= 'number' then
            if group.valid then
                if group.surface.index == target.surface.index then
                    command_to_main_target(group)
                end
            else
                get_active_unit_groups_count()
            end
        end
    end
end

local function spawn_unit_group(fs, only_bosses)
    if fs then
        debug_print('spawn_unit_group - forcing new biters')
    else
        if not can_units_spawn() then
            debug_print('spawn_unit_group - Cant spawn units?')
            return
        end
    end
    local target = Public.get('target')
    if not valid(target) then
        debug_print('spawn_unit_group - Target was not valid?')
        return
    end

    local max_active_unit_groups = Public.get('max_active_unit_groups')
    if fs then
        debug_print('spawn_unit_group - forcing new biters')
    else
        if get_active_unit_groups_count() >= max_active_unit_groups then
            debug_print('spawn_unit_group - unit_groups at max')
            return
        end
    end
    local surface_index = Public.get('surface_index')
    local remove_entities = Public.get('remove_entities')

    local surface = game.surfaces[surface_index]
    set_group_spawn_position(surface)

    local spawn_position = get_spawn_pos()
    if not spawn_position then
        return
    end

    local radius = 10
    local area = {
        left_top = {spawn_position.x - radius, spawn_position.y - radius},
        right_bottom = {spawn_position.x + radius, spawn_position.y + radius}
    }
    for _, v in pairs(surface.find_entities_filtered {area = area, name = 'land-mine'}) do
        if v and v.valid then
            debug_print('spawn_unit_group - found land-mines')
            v.die()
        end
    end

    if remove_entities then
        remove_trees({surface = surface, position = spawn_position, valid = true})
        remove_rocks({surface = surface, position = spawn_position, valid = true})
        fill_tiles({surface = surface, position = spawn_position, valid = true})
    end

    local wave_number = Public.get('wave_number')
    Public.wave_defense_set_unit_raffle(wave_number)

    debug_print('Spawning unit group at x' .. spawn_position.x .. ' y' .. spawn_position.y)

    local event_data = {}

    local generated_units = Public.get('generated_units')
    local unit_group = surface.create_unit_group({position = spawn_position, force = 'enemy'})

    event_data.unit_group = unit_group

    generated_units.unit_group_pos.index = generated_units.unit_group_pos.index + 1
    generated_units.unit_group_pos.positions[unit_group.group_number] = {position = unit_group.position, index = 0}
    local average_unit_group_size = Public.get('average_unit_group_size')
    local unit_settings = Public.get('unit_settings')
    event_data.unit_settings = unit_settings

    local group_size = floor(average_unit_group_size * Public.group_size_modifier_raffle[random(1, Public.group_size_modifier_raffle_size)])

    event_data.group_size = group_size
    event_data.boss_wave = false

    local boss_wave = Public.get('boss_wave')
    if not boss_wave and not only_bosses then
        for _ = 1, group_size, 1 do
            local biter = spawn_biter(surface, spawn_position, fs, false, unit_settings)
            if not biter then
                debug_print('spawn_unit_group - No biters were found?')
                break
            end
            unit_group.add_member(biter)

            raise(Public.events.on_entity_created, {entity = biter, boss_unit = false, target = target})
            -- command_to_side_target(unit_group)
        end
    end

    if boss_wave or only_bosses then
        event_data.boss_wave = true
        local count = random(1, floor(wave_number * 0.01) + 2)
        if count > 16 then
            count = 16
        end
        if count <= 4 then
            count = 4
        end
        event_data.spawn_count = count
        for _ = 1, count, 1 do
            local biter = spawn_biter(surface, spawn_position, fs, true, unit_settings)
            if not biter then
                debug_print('spawn_unit_group - No biter was found?')
                break
            end
            unit_group.add_member(biter)
            raise(Public.events.on_entity_created, {entity = biter, boss_unit = true, target = target})
        end
        Public.set('boss_wave', false)
    end

    generated_units.unit_groups[unit_group.group_number] = unit_group
    local unit_groups_size = Public.get('unit_groups_size')
    Public.set('unit_groups_size', unit_groups_size + 1)
    if random(1, 2) == 1 then
        Public.set('random_group', unit_group)
    end
    Public.set('spot', 'nil')
    raise(Public.events.on_unit_group_created, event_data)
    return true
end

local function check_group_positions()
    local resolve_pathing = Public.get('resolve_pathing')
    if not resolve_pathing then
        return
    end

    local generated_units = Public.get('generated_units')
    local target = Public.get('target')
    if not valid(target) then
        return
    end

    for _, group in pairs(generated_units.unit_groups) do
        if group.valid then
            local ugp = generated_units.unit_group_pos.positions
            if group.state == defines.group_state.finished then
                return command_to_main_target(group, true)
            end
            if ugp[group.group_number] then
                local success = is_position_near(group.position, ugp[group.group_number].position)
                if success then
                    ugp[group.group_number].index = ugp[group.group_number].index + 1
                    if ugp[group.group_number].index >= 2 then
                        command_to_main_target(group, true)
                        fill_tiles(group, 30)
                        remove_rocks(group)
                        remove_trees(group)
                        if valid(group) and ugp[group.group_number].index >= 4 then
                            generated_units.unit_group_pos.positions[group.group_number] = nil
                            reform_group(group)
                        end
                    end
                end
            end
        end
    end
end

local function log_threat()
    local enable_threat_log = Public.get('enable_threat_log')
    if not enable_threat_log then
        return
    end

    local threat_log_index = Public.get('threat_log_index')
    Public.set('threat_log_index', threat_log_index + 1)
    local threat_log = Public.get('threat_log')
    local threat = Public.get('threat')
    threat_log_index = Public.get('threat_log_index')
    threat_log[threat_log_index] = threat
    if threat_log_index > 900 then
        threat_log[threat_log_index - 901] = nil
    end
end

local tick_tasks = {
    [30] = set_main_target,
    [60] = set_enemy_evolution,
    [90] = check_group_positions,
    [120] = give_main_command_to_group,
    [150] = log_threat,
    [180] = Public.build_nest,
    [210] = Public.build_worm
}

local tick_tasks_t2 = {
    [1200] = give_side_commands_to_group,
    [3600] = time_out_biters,
    [7200] = refresh_active_unit_threat
}

Public.spawn_unit_group = spawn_unit_group

Event.on_nth_tick(
    30,
    function()
        local tick = game.tick
        local game_lost = Public.get('game_lost')
        if game_lost then
            return
        end

        local paused = Public.get('paused')
        if paused then
            local players = game.connected_players
            for _, player in pairs(players) do
                Public.update_gui(player)
            end
            return
        end

        local enable_grace_time = Public.get('enable_grace_time')
        if enable_grace_time and (not enable_grace_time.enabled) then
            if not enable_grace_time.set then
                Public.set('next_wave', game.tick + 100)
                enable_grace_time.set = true
            end
        end

        local next_wave = Public.get('next_wave')
        if tick > next_wave then
            set_next_wave()
        end

        local t = tick % 300
        local t2 = tick % 18000

        if tick_tasks[t] then
            tick_tasks[t]()
        end

        if tick_tasks_t2[t2] then
            tick_tasks_t2[t2]()
        end

        local players = game.connected_players
        for _, player in pairs(players) do
            Public.update_gui(player)
        end
    end
)

Event.on_nth_tick(
    50,
    function()
        local tick_to_spawn_unit_groups = Public.get('tick_to_spawn_unit_groups')
        local tick = game.tick
        local will_not_spawn = tick % tick_to_spawn_unit_groups ~= 0
        if will_not_spawn then
            return
        end

        local game_lost = Public.get('game_lost')
        if game_lost then
            return
        end

        local paused = Public.get('paused')
        if paused then
            return
        end

        spawn_unit_group()
    end
)

Public.set_next_wave = set_next_wave

return Public
