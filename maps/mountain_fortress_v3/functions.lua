local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local Server = require 'utils.server'
local Task = require 'utils.task_token'
local Color = require 'utils.color_presets'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local Global = require 'utils.global'
local Alert = require 'utils.alert'
local WD = require 'modules.wave_defense.table'
local RPG = require 'modules.rpg.main'
local Collapse = require 'modules.collapse'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local ICW_Func = require 'maps.mountain_fortress_v3.icw.functions'
local math2d = require 'math2d'
local Misc = require 'utils.commands.misc'
local Core = require 'utils.core'
local Beams = require 'modules.render_beam'
local BottomFrame = require 'utils.gui.bottom_frame'
local Modifiers = require 'utils.player_modifiers'
local Session = require 'utils.datastore.session_data'

local zone_settings = Public.zone_settings
local remove_boost_movement_speed_on_respawn
local de = defines.events

local this = {
    power_sources = {index = 1},
    refill_turrets = {index = 1},
    magic_crafters = {index = 1},
    magic_fluid_crafters = {index = 1},
    art_table = {index = 1},
    starting_items = {
        ['pistol'] = {
            count = 1
        },
        ['firearm-magazine'] = {
            count = 16
        },
        ['rail'] = {
            count = 16
        },
        ['wood'] = {
            count = 16
        },
        ['explosives'] = {
            count = 32
        }
    }
}

local random_respawn_messages = {
    'The doctors stitched you up as best they could.',
    'Ow! Your right leg hurts.',
    'Ow! Your left leg hurts.',
    'You can feel your whole body aching.',
    "You still have some bullet wounds that aren't patched up.",
    'You feel dizzy but adrenalin is granting you speed.',
    'Adrenalin is kicking in, but your body is damaged.'
}

local health_values = {
    '0.35',
    '0.40',
    '0.45',
    '0.50',
    '0.55',
    '0.60',
    '0.65',
    '0.70',
    '0.75',
    '0.80',
    '0.85',
    '0.90',
    '0.95',
    '1'
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local random = math.random
local floor = math.floor
local round = math.round
local sqrt = math.sqrt
local remove = table.remove
local magic_crafters_per_tick = 3
local magic_fluid_crafters_per_tick = 8
local tile_damage = 50

local artillery_target_entities = {
    'character',
    'tank',
    'car',
    'radar',
    'lab',
    'furnace',
    'locomotive',
    'cargo-wagon',
    'fluid-wagon',
    'artillery-wagon',
    'artillery-turret',
    'laser-turret',
    'gun-turret',
    'flamethrower-turret',
    'silo',
    'spidertron'
}

local function debug_str(msg)
    local debug = Public.get('debug')
    if not debug then
        return
    end
    print('Mtn: ' .. msg)
end

local function show_text(msg, pos, color, surface)
    if color == nil then
        surface.create_entity({name = 'flying-text', position = pos, text = msg})
    else
        surface.create_entity({name = 'flying-text', position = pos, text = msg, color = color})
    end
end

local function fast_remove(tbl, index)
    local count = #tbl
    if index > count then
        return
    elseif index < count then
        tbl[index] = tbl[count]
    end

    tbl[count] = nil
end

local pause_waves_custom_callback_token =
    Task.register(
    function(status)
        Collapse.disable_collapse(status)
        local status_str = status and 'has stopped!' or 'is active once again!'
        Alert.alert_all_players(30, 'Collapse ' .. status_str, nil, 'achievement/tech-maniac', 0.6)
    end
)

local function do_refill_turrets()
    local refill_turrets = this.refill_turrets
    local index = refill_turrets.index

    if index > #refill_turrets then
        refill_turrets.index = 1
        return
    end

    local turret_data = refill_turrets[index]
    local turret = turret_data.turret

    if not turret.valid then
        fast_remove(refill_turrets, index)
        return
    end

    refill_turrets.index = index + 1

    local data = turret_data.data
    if data.liquid then
        turret.fluidbox[1] = data
    elseif data then
        turret.insert(data)
    end
end

local function do_magic_crafters()
    local magic_crafters = this.magic_crafters
    local limit = #magic_crafters
    if limit == 0 then
        return
    end

    local index = magic_crafters.index

    for _ = 1, magic_crafters_per_tick do
        if index > limit then
            index = 1
        end

        local data = magic_crafters[index]

        local entity = data.entity
        if not entity.valid then
            fast_remove(magic_crafters, index)
            limit = limit - 1
            if limit == 0 then
                return
            end
        else
            index = index + 1

            local tick = game.tick
            local last_tick = data.last_tick
            local rate = data.rate

            local count = (tick - last_tick) * rate

            local fcount = floor(count)

            if fcount > 1 then
                fcount = 1
            end

            if fcount > 0 then
                if entity.get_output_inventory().can_insert({name = data.item, count = fcount}) then
                    entity.get_output_inventory().insert {name = data.item, count = fcount}
                    entity.products_finished = entity.products_finished + fcount
                    data.last_tick = round(tick - (count - fcount) / rate)
                end
            end
        end
    end

    magic_crafters.index = index
end

local function do_magic_fluid_crafters()
    local magic_fluid_crafters = this.magic_fluid_crafters
    local limit = #magic_fluid_crafters

    if limit == 0 then
        return
    end

    local index = magic_fluid_crafters.index

    for _ = 1, magic_fluid_crafters_per_tick do
        if index > limit then
            index = 1
        end

        local data = magic_fluid_crafters[index]

        local entity = data.entity
        if not entity.valid then
            fast_remove(magic_fluid_crafters, index)
            limit = limit - 1
            if limit == 0 then
                return
            end
        else
            index = index + 1

            local tick = game.tick
            local last_tick = data.last_tick
            local rate = data.rate

            local count = (tick - last_tick) * rate

            local fcount = floor(count)

            if fcount > 0 then
                local fluidbox_index = data.fluidbox_index
                local fb = entity.fluidbox

                local fb_data = fb[fluidbox_index] or {name = data.item, amount = 0}
                fb_data.amount = fb_data.amount + fcount
                fb[fluidbox_index] = fb_data

                entity.products_finished = entity.products_finished + fcount

                data.last_tick = tick - (count - fcount) / rate
            end
        end
    end

    magic_fluid_crafters.index = index
end

local artillery_target_callback =
    Task.register(
    function(data)
        local position = data.position
        local entity = data.entity
        local index = data.index

        local art_table = this.art_table
        local outpost = art_table[index]

        if not entity.valid then
            outpost.last_fire_tick = 0
            return
        end

        local tx, ty = position.x, position.y
        local fired_at_target = false

        local pos = entity.position
        local x, y = pos.x, pos.y
        local dx, dy = tx - x, ty - y
        local d = dx * dx + dy * dy
        if d >= 1024 and d <= 441398 then -- 704 in depth~
            if entity.name == 'character' then
                entity.surface.create_entity {
                    name = 'artillery-projectile',
                    position = position,
                    target = entity,
                    force = 'enemy',
                    speed = 1.5
                }
                fired_at_target = true
            elseif entity.name ~= 'character' then
                entity.surface.create_entity {
                    name = 'rocket',
                    position = position,
                    target = entity,
                    force = 'enemy',
                    speed = 1.5
                }
                fired_at_target = true
            end
        end

        if not fired_at_target then
            outpost.last_fire_tick = 0
        end
    end
)

local function do_beams_away()
    local wave_number = WD.get_wave()
    local orbital_strikes = Public.get('orbital_strikes')
    if not orbital_strikes.enabled then
        return
    end

    if wave_number > 1000 then
        local difficulty_index = Difficulty.get('index')
        local wave_nth = 9999
        if difficulty_index == 1 then
            wave_nth = 500
        elseif difficulty_index == 2 then
            wave_nth = 250
        elseif difficulty_index == 3 then
            wave_nth = 100
        end

        if wave_number % wave_nth == 0 then
            local active_surface_index = Public.get('active_surface_index')
            local surface = game.get_surface(active_surface_index)

            if not orbital_strikes[wave_number] then
                orbital_strikes[wave_number] = true
                Beams.new_beam_delayed(surface, random(500, 3000))
            end
        end
    end
end

local function do_clear_enemy_spawners()
    local tick = game.tick
    if tick % 1000 ~= 0 then
        return
    end

    local enemy_spawners = Public.get('enemy_spawners')
    if not enemy_spawners.enabled then
        return
    end

    for unit_number, spawner in pairs(enemy_spawners.spawners) do
        if not spawner.entity or not spawner.entity.valid then
            enemy_spawners.spawners[unit_number] = nil
        end
    end
end

local function do_season_fix()
    local active_surface_index = Public.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]
    if not (surface and surface.valid) then
        return
    end

    local current_season = Public.get('current_season')

    if current_season then
        rendering.destroy(current_season)
    end

    Public.set(
        'current_season',
        rendering.draw_text {
            text = 'Season: ' .. Public.stateful.get_stateful('season'),
            surface = surface,
            target = {-0, 12},
            color = {r = 0.98, g = 0.77, b = 0.22},
            scale = 3,
            font = 'heading-1',
            alignment = 'center',
            scale_with_zoom = false
        }
    )
end

local do_season_fix_token = Task.register(do_season_fix)

local function do_artillery_turrets_targets()
    local art_table = this.art_table
    local index = art_table.index

    local difficulty_index = Difficulty.get('index')
    if difficulty_index == 3 then
        return
    end

    if index > #art_table then
        art_table.index = 1
        return
    end

    art_table.index = index + 1

    local outpost = art_table[index]

    local now = game.tick
    if now - outpost.last_fire_tick < 480 then
        return
    end

    local turrets = outpost.artillery_turrets
    for i = #turrets, 1, -1 do
        local turret = turrets[i]
        if not turret.valid then
            fast_remove(turrets, i)
        end
    end

    local count = #turrets
    if count == 0 then
        fast_remove(art_table, index)
        return
    end

    local turret = turrets[1]
    local area = outpost.artillery_area
    local surface = turret.surface

    local entities = surface.find_entities_filtered {area = area, name = artillery_target_entities, force = 'player'}

    if #entities == 0 then
        return
    end

    local position = turret.position

    outpost.last_fire_tick = now

    for i = 1, count do
        local entity = entities[random(#entities)]
        if entity and entity.valid then
            local data = {position = position, entity = entity, index = index}
            Task.set_timeout_in_ticks(i * 60, artillery_target_callback, data)
        end
    end
end

local function add_magic_crafter_output(entity, output, distance)
    local magic_fluid_crafters = this.magic_fluid_crafters
    local magic_crafters = this.magic_crafters
    local rate = output.min_rate + output.distance_factor * distance

    local fluidbox_index = output.fluidbox_index
    local data = {
        entity = entity,
        last_tick = game.tick,
        base_rate = round(rate, 8),
        rate = round(rate, 8),
        item = output.item,
        fluidbox_index = fluidbox_index
    }

    if fluidbox_index then
        magic_fluid_crafters[#magic_fluid_crafters + 1] = data
    else
        magic_crafters[#magic_crafters + 1] = data
    end
end

local function tick()
    do_refill_turrets()
    do_magic_crafters()
    do_magic_fluid_crafters()
    do_artillery_turrets_targets()
    do_beams_away()
    do_clear_enemy_spawners()
end

Public.deactivate_callback =
    Task.register(
    function(entity)
        if entity and entity.valid then
            entity.active = false
            entity.operable = false
            entity.destructible = false
        end
    end
)

Public.neutral_force =
    Task.register(
    function(entity)
        if entity and entity.valid then
            entity.force = 'neutral'
        end
    end
)

Public.enemy_force =
    Task.register(
    function(entity)
        if entity and entity.valid then
            entity.force = 'enemy'
        end
    end
)

Public.active_not_destructible_callback =
    Task.register(
    function(entity)
        if entity and entity.valid then
            entity.active = true
            entity.operable = false
            entity.destructible = false
        end
    end
)

Public.disable_minable_callback =
    Task.register(
    function(entity)
        if entity and entity.valid then
            entity.minable = false
        end
    end
)

Public.disable_minable_and_ICW_callback =
    Task.register(
    function(entity)
        if entity and entity.valid then
            local wagons_in_the_wild = Public.get('wagons_in_the_wild')
            entity.minable = false
            entity.destructible = false
            ICW.register_wagon(entity)

            wagons_in_the_wild[entity.unit_number] = entity
        end
    end
)

Public.disable_destructible_callback =
    Task.register(
    function(entity)
        if entity and entity.valid then
            entity.destructible = false
            entity.minable = false
        end
    end
)
Public.disable_active_callback =
    Task.register(
    function(entity)
        if entity and entity.valid then
            entity.active = false
        end
    end
)

local disable_active_callback = Public.disable_active_callback

Public.refill_turret_callback =
    Task.register(
    function(turret, data)
        local refill_turrets = this.refill_turrets
        local callback_data = data.callback_data
        turret.direction = 3

        refill_turrets[#refill_turrets + 1] = {turret = turret, data = callback_data}
    end
)

Public.refill_artillery_turret_callback =
    Task.register(
    function(turret, data)
        local refill_turrets = this.refill_turrets
        local art_table = this.art_table
        local index = art_table.index

        turret.active = false
        turret.direction = 3

        refill_turrets[#refill_turrets + 1] = {turret = turret, data = data.callback_data}

        local artillery_data = art_table[index]
        if not artillery_data then
            artillery_data = {}
        end

        local artillery_turrets = artillery_data.artillery_turrets
        if not artillery_turrets then
            artillery_turrets = {}
            artillery_data.artillery_turrets = artillery_turrets

            local pos = turret.position
            local x, y = pos.x, pos.y
            artillery_data.artillery_area = {{x - 112, y}, {x + 112, y + 212}}
            artillery_data.last_fire_tick = 0

            art_table[#art_table + 1] = artillery_data
        end

        artillery_turrets[#artillery_turrets + 1] = turret
    end
)

Public.refill_liquid_turret_callback =
    Task.register(
    function(turret, data)
        local refill_turrets = this.refill_turrets
        local callback_data = data.callback_data
        callback_data.liquid = true

        refill_turrets[#refill_turrets + 1] = {turret = turret, data = callback_data}
    end
)

Public.power_source_callback =
    Task.register(
    function(turret)
        local power_sources = this.power_sources
        power_sources[#power_sources + 1] = turret
    end
)

Public.magic_item_crafting_callback =
    Task.register(
    function(entity, data)
        local callback_data = data.callback_data
        if not (entity and entity.valid) then
            return
        end

        entity.minable = false
        entity.destructible = false
        entity.operable = false

        local force = game.forces.player

        local tech = callback_data.tech
        if not callback_data.testing then
            if tech then
                if not force.technologies[tech].researched then
                    entity.destroy()
                    return
                end
            end
        end

        local recipe = callback_data.recipe
        if recipe then
            entity.set_recipe(recipe)
        else
            local furance_item = callback_data.furance_item
            if furance_item then
                local inv = entity.get_inventory(defines.inventory.furnace_result)
                inv.insert(furance_item)
            end
        end

        local p = entity.position
        local x, y = p.x, p.y
        local distance = sqrt(x * x + y * y)

        local output = callback_data.output
        if #output == 0 then
            add_magic_crafter_output(entity, output, distance)
        else
            for i = 1, #output do
                local o = output[i]
                add_magic_crafter_output(entity, o, distance)
            end
        end

        if not callback_data.keep_active then
            Task.set_timeout_in_ticks(2, disable_active_callback, entity) -- causes problems with refineries.
        end
    end
)

Public.magic_item_crafting_callback_weighted =
    Task.register(
    function(entity, data)
        local callback_data = data.callback_data
        if not (entity and entity.valid) then
            return
        end

        local weights = callback_data.weights
        local loot = callback_data.loot
        local destructible = callback_data.destructible

        if not destructible then
            entity.destructible = false
        end

        entity.minable = false
        entity.operable = false

        local p = entity.position

        local i = random() * weights.total

        local index = table.binary_search(weights, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end

        local stack = loot[index].stack
        if not stack then
            return
        end

        local force = game.forces.player

        local tech = stack.tech
        if not callback_data.testing then
            if tech then
                if force.technologies[tech] then
                    if not force.technologies[tech].researched then
                        entity.destroy()
                        return
                    end
                end
            end
        end

        local recipe = stack.recipe
        if recipe then
            entity.set_recipe(recipe)
        else
            local furance_item = stack.furance_item
            if furance_item then
                local inv = entity.get_inventory(defines.inventory.furnace_result)
                inv.insert(furance_item)
            end
        end

        local x, y = p.x, p.y
        local distance = sqrt(x * x + y * y)

        local output = stack.output
        if #output == 0 then
            add_magic_crafter_output(entity, output, distance)
        else
            for o_i = 1, #output do
                local o = output[o_i]
                add_magic_crafter_output(entity, o, distance)
            end
        end

        if not callback_data.keep_active then
            Task.set_timeout_in_ticks(2, disable_active_callback, entity) -- causes problems with refineries.
        end
    end
)

function Public.prepare_weighted_loot(loot)
    local total = 0
    local weights = {}

    for i = 1, #loot do
        local v = loot[i]
        total = total + v.weight
        weights[#weights + 1] = total
    end

    weights.total = total

    return weights
end

function Public.do_random_loot(entity, weights, loot)
    if not entity.valid then
        return
    end

    entity.operable = false
    --entity.destructible = false

    local i = random() * weights.total

    local index = table.binary_search(weights, i)
    if (index < 0) then
        index = bit32.bnot(index)
    end

    local stack = loot[index].stack
    if not stack then
        return
    end

    local df = stack.distance_factor
    local count
    if df then
        local p = entity.position
        local x, y = p.x, p.y
        local d = sqrt(x * x + y * y)

        count = stack.count + d * df
    else
        count = stack.count
    end

    entity.insert {name = stack.name, count = count}
end

local function calc_players()
    local players = game.connected_players
    local check_afk_players = Public.get('check_afk_players')
    if not check_afk_players then
        return #players
    end
    local total = 0
    Core.iter_connected_players(
        function(player)
            if player.afk_time < 36000 then
                total = total + 1
            end
        end
    )
    if total <= 0 then
        total = #players
    end
    return total
end

remove_boost_movement_speed_on_respawn =
    Task.register(
    function(data)
        local player = data.player
        if not player or not player.valid then
            return
        end
        if not data.tries then
            data.tries = 0
        end

        if not player.character or not player.character.valid then
            data.tries = data.tries + 1
            if data.tries > 10 then
                return
            end

            Task.set_timeout_in_ticks(10, remove_boost_movement_speed_on_respawn, {player = player, tries = data.tries})
            return
        end

        Modifiers.update_single_modifier(player, 'character_running_speed_modifier', 'v3_move_boost')
        Modifiers.update_player_modifiers(player)

        player.print('Movement speed bonus removed!', Color.info)
        local rpg_t = RPG.get_value_from_player(player.index)
        rpg_t.has_custom_spell_active = nil
    end
)

local boost_movement_speed_on_respawn =
    Task.register(
    function(data)
        local player = data.player
        if not player or not player.valid then
            return
        end
        if not player.character or not player.character.valid then
            return
        end

        local rpg_t = RPG.get_value_from_player(player.index)
        rpg_t.has_custom_spell_active = true

        Modifiers.update_single_modifier(player, 'character_running_speed_modifier', 'v3_move_boost', 1)
        Modifiers.update_player_modifiers(player)

        Task.set_timeout_in_ticks(800, remove_boost_movement_speed_on_respawn, {player = player})
        player.print('Movement speed bonus applied! Be quick and fetch your corpse!', Color.info)
    end
)

local function on_wave_created(event)
    if not event or not event.wave_number then
        return
    end

    local wave_number = event.wave_number

    if wave_number % 50 == 0 then
        if wave_number >= 1500 then
            WD.set_pause_wave_in_ticks(random(36000, 54000))
        else
            WD.set_pause_wave_in_ticks(random(18000, 54000))
        end
    end
end

function Public.set_difficulty()
    local game_lost = Public.get('game_lost')
    if game_lost then
        return
    end
    local Diff = Difficulty.get()
    if not Diff then
        return
    end
    local wave_defense_table = WD.get_table()
    local check_if_threat_below_zero = Public.get('check_if_threat_below_zero')
    local collapse_amount = Public.get('collapse_amount')
    local collapse_speed = Public.get('collapse_speed')
    local difficulty = Public.get('difficulty')
    local mining_bonus_till_wave = Public.get('mining_bonus_till_wave')
    local mining_bonus = Public.get('mining_bonus')
    local disable_mining_boost = Public.get('disable_mining_boost')
    local wave_number = WD.get_wave()
    local player_count = calc_players()

    if not Diff.value then
        Diff.value = 0.1
    end

    if not wave_defense_table.enforce_max_active_biters then
        if Diff.index == 1 then
            wave_defense_table.max_active_biters = 768 + player_count * (90 * Diff.value)
        elseif Diff.index == 2 then
            wave_defense_table.max_active_biters = 845 + player_count * (90 * Diff.value)
        elseif Diff.index == 3 then
            wave_defense_table.max_active_biters = 1000 + player_count * (90 * Diff.value)
        end

        if wave_defense_table.max_active_biters >= 4000 then
            wave_defense_table.max_active_biters = 4000
        end
    end

    -- threat gain / wave
    if Diff.index == 1 then
        wave_defense_table.threat_gain_multiplier = 1.2 + player_count * Diff.value * 0.1
    elseif Diff.index == 2 then
        wave_defense_table.threat_gain_multiplier = 2 + player_count * Diff.value * 0.1
    elseif Diff.index == 3 then
        wave_defense_table.threat_gain_multiplier = 4 + player_count * Diff.value * 0.1
    end

    -- local amount = player_count * 0.40 + 2 -- too high?
    local amount = player_count * difficulty.multiply + 2
    amount = floor(amount)
    if amount < difficulty.lowest then
        amount = difficulty.lowest
    elseif amount > difficulty.highest then
        amount = difficulty.highest -- lowered from 20 to 10
    end

    local wave = WD.get('wave_number')

    local threat_check = nil

    if check_if_threat_below_zero then
        threat_check = wave_defense_table.threat <= 0
    end

    if Diff.index == 1 then
        if wave < 100 then
            wave_defense_table.wave_interval = 4500
        else
            wave_defense_table.wave_interval = 3600 - player_count * 60
        end

        if wave_defense_table.wave_interval < 2000 or threat_check then
            wave_defense_table.wave_interval = 2000
        end
    elseif Diff.index == 2 then
        if wave < 100 then
            wave_defense_table.wave_interval = 3000
        else
            wave_defense_table.wave_interval = 2600 - player_count * 60
        end
        if wave_defense_table.wave_interval < 1800 or threat_check then
            wave_defense_table.wave_interval = 1800
        end
    elseif Diff.index == 3 then
        if wave < 100 then
            wave_defense_table.wave_interval = 3000
        else
            wave_defense_table.wave_interval = 1600 - player_count * 60
        end
        wave_defense_table.wave_interval = 1600 - player_count * 60
        if wave_defense_table.wave_interval < 1600 or threat_check then
            wave_defense_table.wave_interval = 1600
        end
    end

    if collapse_amount then
        Collapse.set_amount(collapse_amount)
    else
        Collapse.set_amount(amount)
    end
    if collapse_speed then
        Collapse.set_speed(collapse_speed)
    else
        if player_count >= 1 and player_count <= 8 then
            Collapse.set_speed(8)
        elseif player_count > 8 and player_count <= 20 then
            Collapse.set_speed(7)
        elseif player_count > 20 and player_count <= 35 then
            Collapse.set_speed(6)
        elseif player_count > 35 then
            Collapse.set_speed(5)
        end
    end

    if player_count >= 1 and not disable_mining_boost then
        local force = game.forces.player
        if wave_number < mining_bonus_till_wave then
            -- the mining speed of the players will increase drastically since RPG is also loaded.
            -- additional mining speed comes from steel axe research: 100%, and difficulty settings: too young to die 50%, hurt me plenty 25%
            force.manual_mining_speed_modifier = force.manual_mining_speed_modifier - mining_bonus
            if player_count <= 5 then
                mining_bonus = 3 -- set a static 300% bonus if there are <= 5 players.
            elseif player_count >= 6 and player_count <= 10 then
                mining_bonus = 1 -- set a static 100% bonus if there are <= 10 players.
            elseif player_count >= 11 then
                mining_bonus = 0 -- back to 0% with more than 11 players
            end
            force.manual_mining_speed_modifier = force.manual_mining_speed_modifier + mining_bonus
            Public.set('mining_bonus', mining_bonus) -- Setting mining_bonus globally so it remembers how much to reduce
        else
            force.manual_mining_speed_modifier = force.manual_mining_speed_modifier - mining_bonus
            Public.set('disable_mining_boost', true)
        end
    end
end

function Public.render_direction(surface)
    local counter = Public.get('soft_reset_counter')
    local winter_mode = Public.get('winter_mode')
    local text = 'Welcome to Mountain Fortress v3!'
    if winter_mode then
        text = 'Welcome to Wintery Mountain Fortress v3!'
    end

    Public.set(
        'current_season',
        rendering.draw_text {
            text = 'Season: ' .. Public.stateful.get_stateful('season'),
            surface = surface,
            target = {-0, 12},
            color = {r = 0.98, g = 0.77, b = 0.22},
            scale = 3,
            font = 'heading-1',
            alignment = 'center',
            scale_with_zoom = false
        }
    )

    Task.set_timeout_in_ticks(25, do_season_fix_token, {})
    Task.set_timeout_in_ticks(50, do_season_fix_token, {})

    if counter then
        rendering.draw_text {
            text = text .. '\nRun: ' .. counter,
            surface = surface,
            target = {-0, 10},
            color = {r = 0.98, g = 0.66, b = 0.22},
            scale = 3,
            font = 'heading-1',
            alignment = 'center',
            scale_with_zoom = false
        }
    else
        rendering.draw_text {
            text = text,
            surface = surface,
            target = {-0, 10},
            color = {r = 0.98, g = 0.66, b = 0.22},
            scale = 3,
            font = 'heading-1',
            alignment = 'center',
            scale_with_zoom = false
        }
    end

    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 20},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }

    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 30},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 40},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 50},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 60},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = 'Biters will attack this area.',
        surface = surface,
        target = {-0, 70},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }

    local x_min = -zone_settings.zone_width / 2
    local x_max = zone_settings.zone_width / 2

    surface.create_entity({name = 'electric-beam', position = {x_min, 74}, source = {x_min, 74}, target = {x_max, 74}})
    surface.create_entity({name = 'electric-beam', position = {x_min, 74}, source = {x_min, 74}, target = {x_max, 74}})
end

function Public.boost_difficulty()
    local difficulty_set = Public.get('difficulty_set')
    if difficulty_set then
        return
    end

    local force = game.forces.player

    force.manual_mining_speed_modifier = force.manual_mining_speed_modifier + 0.5
    force.character_running_speed_modifier = 0.15
    force.manual_crafting_speed_modifier = 0.15
    Public.set('coin_amount', 1)
    Public.set('upgrades').flame_turret.limit = 12
    Public.set('upgrades').landmine.limit = 50
    Public.set('locomotive_health', 10000)
    Public.set('locomotive_max_health', 10000)
    Public.set('bonus_xp_on_join', 500)
    WD.set('next_wave', game.tick + 3600 * 15)
    Public.set('spidertron_unlocked_at_zone', 10)
    WD.set_normal_unit_current_health(1.2)
    WD.set_unit_health_increment_per_wave(0.30)
    WD.set_boss_unit_current_health(2)
    WD.set_boss_health_increment_per_wave(1.5)
    WD.set('death_mode', false)
    Public.set('difficulty_set', true)
end

function Public.set_spawn_position()
    local collapse_pos = Collapse.get_position()
    local locomotive = Public.get('locomotive')
    local final_battle = Public.get('final_battle')
    if final_battle then
        return
    end
    if not locomotive or not locomotive.valid then
        return
    end
    --TODO check if final battle
    local l = locomotive.position

    local retries = 0

    local function check_tile(surface, tile, tbl, inc)
        if not (surface and surface.valid) then
            return false
        end
        if not tile then
            return false
        end
        local get_tile = surface.get_tile(tile)
        if get_tile.valid and get_tile.name == 'out-of-map' then
            remove(tbl, inc - inc + 1)
            return true
        else
            return false
        end
    end

    ::retry::

    local y_value_position = Public.get('y_value_position')
    local locomotive_positions = Public.get('locomotive_pos')
    local total_pos = #locomotive_positions.tbl

    local active_surface_index = Public.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]
    if not (surface and surface.valid) then
        return
    end

    local spawn_near_collapse = Public.get('spawn_near_collapse')

    if spawn_near_collapse.active then
        local collapse_position = surface.find_non_colliding_position('rocket-silo', collapse_pos, 64, 2)
        if not collapse_position then
            collapse_position = surface.find_non_colliding_position('solar-panel', collapse_pos, 32, 2)
        end
        if not collapse_position then
            collapse_position = surface.find_non_colliding_position('steel-chest', collapse_pos, 32, 2)
        end
        local sizeof = locomotive_positions.tbl[total_pos - total_pos + 1]
        if not sizeof then
            goto continue
        end

        if check_tile(surface, sizeof, locomotive_positions.tbl, total_pos) then
            retries = retries + 1
            if retries == 2 then
                goto continue
            end
            goto retry
        end

        local locomotive_position = surface.find_non_colliding_position('steel-chest', sizeof, 128, 1)
        local distance_from = floor(math2d.position.distance(locomotive_position, locomotive.position))
        local l_y = l.y
        local t_y = locomotive_position.y
        local c_y = collapse_pos.y
        if total_pos > spawn_near_collapse.total_pos then
            if l_y - t_y <= spawn_near_collapse.compare then
                if locomotive_position then
                    if check_tile(surface, sizeof, locomotive_positions.tbl, total_pos) then
                        debug_str('total_pos was higher - found oom')
                        retries = retries + 1
                        if retries == 2 then
                            goto continue
                        end
                        goto retry
                    end
                    debug_str('total_pos was higher - spawning at locomotive_position')
                    WD.set_spawn_position(locomotive_position)
                end
            elseif c_y - t_y <= spawn_near_collapse.compare_next then
                if distance_from >= spawn_near_collapse.distance_from then
                    local success = check_tile(surface, locomotive_position, locomotive_positions.tbl, total_pos)
                    if success then
                        debug_str('distance_from was higher - found oom')
                        return
                    end
                    debug_str('distance_from was higher - spawning at locomotive_position')
                    WD.set_spawn_position({x = locomotive_position.x, y = collapse_pos.y - y_value_position})
                else
                    debug_str('distance_from was lower - spawning at locomotive_position')
                    WD.set_spawn_position({x = locomotive_position.x, y = collapse_pos.y - y_value_position})
                end
            else
                if collapse_position then
                    debug_str('total_pos was higher - spawning at collapse_position')
                    collapse_position = {x = collapse_position.x, y = collapse_position.y - y_value_position}
                    WD.set_spawn_position(collapse_position)
                end
            end
        else
            if collapse_position then
                debug_str('total_pos was lower - spawning at collapse_position')
                collapse_position = {x = collapse_position.x, y = collapse_position.y - y_value_position}
                WD.set_spawn_position(collapse_position)
            end
        end
    end

    ::continue::
end

function Public.on_player_joined_game(event)
    local active_surface_index = Public.get('active_surface_index')
    local players = Public.get('players')
    local player = game.players[event.player_index]
    local surface = game.surfaces[active_surface_index]

    Public.set_difficulty()

    ICW_Func.is_minimap_valid(player, surface)

    if player.online_time < 1 then
        if not players[player.index] then
            players[player.index] = {}
        end
        local message = ({'main.greeting', player.name})
        Alert.alert_player(player, 15, message)
        if Public.get('death_mode') then
            local death_message = ({'main.death_mode_warning'})
            Alert.alert_player(player, 15, death_message)
        end
        for item, data in pairs(this.starting_items) do
            player.insert({name = item, count = data.count})
        end
    end

    -- local top = player.gui.top
    -- if top['mod_gui_top_frame'] then
    --     top['mod_gui_top_frame'].destroy()
    -- end

    local final_battle = Public.get('final_battle')
    local collection = Public.get_stateful('collection')
    if final_battle and not collection.final_arena_disabled then
        local boss_room = game.get_surface('boss_room')
        if not boss_room or not boss_room.valid then
            return
        end
        if player.surface.index ~= boss_room.index then
            local pos = boss_room.find_non_colliding_position('character', game.forces.player.get_spawn_position(boss_room), 3, 0, 5)
            if pos then
                player.teleport(pos, boss_room)
            else
                pos = game.forces.player.get_spawn_position(boss_room)
                player.teleport(pos, boss_room)
            end
        end
        return
    end

    if player.surface.index ~= active_surface_index then
        local pos = surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5)
        if pos then
            player.teleport(pos, surface)
        else
            pos = game.forces.player.get_spawn_position(surface)
            player.teleport(pos, surface)
        end
    else
        local p = {x = player.position.x, y = player.position.y}
        local get_tile = surface.get_tile(p)
        if get_tile.valid and get_tile.name == 'out-of-map' then
            local pos = surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5)
            if pos then
                player.teleport(pos, surface)
            else
                pos = game.forces.player.get_spawn_position(surface)
                player.teleport(pos, surface)
            end
        end
    end

    local locomotive = Public.get('locomotive')

    if not locomotive or not locomotive.valid then
        return
    end
    if player.position.y > locomotive.position.y then
        local pos = surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5)
        if pos then
            player.teleport(pos, surface)
        else
            pos = game.forces.player.get_spawn_position(surface)
            player.teleport(pos, surface)
        end
    end
end

function Public.on_player_left_game()
    Public.set_difficulty()
end

function Public.is_creativity_mode_on()
    local creative_enabled = Misc.get('creative_enabled')
    if creative_enabled then
        WD.set('next_wave', 1000)
        Collapse.start_now(true)
        Public.set_difficulty()
    end
end

function Public.disable_creative()
    local creative_enabled = Misc.get('creative_enabled')
    if creative_enabled then
        Misc.set('creative_enabled', false)
    end
end

function Public.on_player_respawned(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end
    if player.character and player.character.valid then
        Task.set_timeout_in_ticks(15, boost_movement_speed_on_respawn, {player = player})
        player.character.health = round(player.character.health * health_values[random(1, #health_values)])
        player.print(random_respawn_messages[random(1, #random_respawn_messages)])
    end
end

function Public.on_player_driving_changed_state(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local unit_number = entity.unit_number

    local wagons_in_the_wild = Public.get('wagons_in_the_wild')
    if not wagons_in_the_wild or not next(wagons_in_the_wild) then
        return
    end

    local wagon = wagons_in_the_wild[unit_number]
    if not wagon or not wagon.valid then
        wagons_in_the_wild[unit_number] = nil
        return
    end

    wagon.destructible = true

    wagons_in_the_wild[unit_number] = nil
end

function Public.on_player_changed_position(event)
    local active_surface_index = Public.get('active_surface_index')
    if not active_surface_index then
        return
    end
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    if player.controller_type == defines.controllers.spectator then
        return
    end

    local map_name = 'mtn_v3'

    if string.sub(player.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local position = player.position
    local surface = game.surfaces[active_surface_index]

    local p = {x = player.position.x, y = player.position.y}
    local config_tile = Public.get('void_or_tile')
    if config_tile == 'lab-dark-2' then
        local get_tile = surface.get_tile(p)
        if get_tile.valid and get_tile.name == 'lab-dark-2' then
            if random(1, 2) == 1 then
                if random(1, 2) == 1 then
                    show_text('This path is not for players!', p, {r = 0.98, g = 0.66, b = 0.22}, surface)
                end
                player.surface.create_entity({name = 'fire-flame', position = player.position})
                player.character.health = player.character.health - tile_damage
                if player.character.health == 0 then
                    player.character.die()
                    local message = ({'main.death_message_' .. random(1, 7), player.name})
                    game.print(message, {r = 0.98, g = 0.66, b = 0.22})
                end
            end
        end
    end

    if position.y >= 74 then
        player.teleport({position.x, position.y - 1}, surface)
        player.print(({'main.forcefield'}), {r = 0.98, g = 0.66, b = 0.22})
        if player.character then
            player.character.health = player.character.health - 5
            player.character.surface.create_entity({name = 'water-splash', position = position})
            if player.character.health <= 0 then
                player.character.die('enemy')
            end
        end
    end
end

local disable_recipes = function(force)
    force.recipes['cargo-wagon'].enabled = false
    force.recipes['fluid-wagon'].enabled = false
    force.recipes['car'].enabled = false
    force.recipes['tank'].enabled = false
    force.recipes['artillery-wagon'].enabled = false
    force.recipes['artillery-turret'].enabled = false
    force.recipes['artillery-shell'].enabled = false
    force.recipes['artillery-targeting-remote'].enabled = false
    force.recipes['locomotive'].enabled = false
    force.recipes['pistol'].enabled = false
    force.recipes['spidertron-remote'].enabled = false
    force.recipes['discharge-defense-equipment'].enabled = false
    force.recipes['discharge-defense-remote'].enabled = false
end

function Public.disable_tech()
    local force = game.forces.player
    force.technologies['landfill'].enabled = false
    force.technologies['spidertron'].enabled = false
    force.technologies['spidertron'].researched = false
    force.technologies['atomic-bomb'].enabled = false
    force.technologies['atomic-bomb'].researched = false
    force.technologies['artillery-shell-range-1'].enabled = false
    force.technologies['artillery-shell-range-1'].researched = false
    force.technologies['artillery-shell-speed-1'].enabled = false
    force.technologies['artillery-shell-speed-1'].researched = false
    force.technologies['optics'].researched = true
    force.technologies['railway'].researched = true
    force.technologies['land-mine'].enabled = false
    force.technologies['fluid-wagon'].enabled = false
    force.technologies['cliff-explosives'].enabled = false

    disable_recipes(force)
end

local disable_tech = Public.disable_tech

function Public.on_research_finished(event)
    disable_tech()

    local research = event.research
    local bonus_drill = game.forces.bonus_drill
    local player = game.forces.player

    local research_name = research.name
    local force = research.force

    if Public.get('print_tech_to_discord') and force.name == 'player' then
        Server.to_discord_embed_raw('<a:Modded:835932131036364810> ' .. research_name:gsub('^%l', string.upper) .. ' has been researched!')
    end

    research.force.character_inventory_slots_bonus = player.mining_drill_productivity_bonus * 50 -- +5 Slots /
    bonus_drill.mining_drill_productivity_bonus = bonus_drill.mining_drill_productivity_bonus + 0.03
    if bonus_drill.mining_drill_productivity_bonus >= 3 then
        bonus_drill.mining_drill_productivity_bonus = 3
    end

    local players = game.connected_players
    for i = 1, #players do
        local p = players[i]
        Modifiers.update_player_modifiers(p)
    end

    if research.name == 'steel-axe' then
        local msg = 'Steel-axe technology has been researched, 100% has been applied.\nBuy Pickaxe-upgrades in the market to boost it even more!'
        Alert.alert_all_players(30, msg, nil, 'achievement/tech-maniac', 0.6)
    end

    local force_name = research.force.name
    if not force_name then
        return
    end
    local flamethrower_damage = Public.get('flamethrower_damage')
    flamethrower_damage[force_name] = -0.85
    if research.name == 'military' then
        game.forces[force_name].set_turret_attack_modifier('flamethrower-turret', flamethrower_damage[force_name])
        game.forces[force_name].set_ammo_damage_modifier('flamethrower', flamethrower_damage[force_name])
    end

    if string.sub(research.name, 0, 18) == 'refined-flammables' then
        flamethrower_damage[force_name] = flamethrower_damage[force_name] + 0.10
        game.forces[force_name].set_turret_attack_modifier('flamethrower-turret', flamethrower_damage[force_name])
        game.forces[force_name].set_ammo_damage_modifier('flamethrower', flamethrower_damage[force_name])
    end
end

function Public.set_player_to_god(player)
    if player.character and player.character.valid then
        return false
    end

    if not player.character and player.controller_type ~= defines.controllers.spectator then
        player.print('[color=blue][Spectate][/color] It seems that you are not in the realm of the living.', Color.warning)
        return false
    end

    local spectate = Public.get('spectate')

    if spectate[player.index] and spectate[player.index].delay and spectate[player.index].delay > game.tick then
        local cooldown = floor((spectate[player.index].delay - game.tick) / 60) + 1 .. ' seconds!'
        player.print('[color=blue][Spectate][/color] Retry again in ' .. cooldown, Color.warning)
        return false
    end

    spectate[player.index] = nil

    player.set_controller({type = defines.controllers.god})
    player.create_character()
    local active_surface_index = Public.get('active_surface_index')
    local surface = game.get_surface(active_surface_index)
    if not surface or not surface.valid then
        return false
    end

    if string.sub(player.surface.name, 0, #surface.name) == surface.name then
        local pos = surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5)
        if pos then
            player.teleport(pos, surface)
        else
            pos = game.forces.player.get_spawn_position(surface)
            player.teleport(pos, surface)
        end
    else
        local pos = player.surface.find_non_colliding_position('character', {0, 0}, 3, 0, 5)
        if pos then
            player.teleport(pos, player.surface)
        else
            player.teleport({pos}, player.surface)
        end
    end

    Event.raise(
        BottomFrame.events.bottom_quickbar_respawn_raise,
        {
            player_index = player.index
        }
    )

    player.tag = ''

    game.print('[color=blue][Spectate][/color] ' .. player.name .. ' is no longer spectating!')
    Server.to_discord_bold(table.concat {'*** ', '[Spectate] ' .. player.name .. ' is no longer spectating!', ' ***'})
    return true
end

function Public.set_player_to_spectator(player)
    if player.in_combat then
        player.print('[color=blue][Spectate][/color] You are in combat. Try again soon.', Color.warning)
        return false
    end

    if player.driving then
        return player.print('[color=blue][Spectate][/color] Please exit the vehicle before continuing', Color.warning)
    end

    local spectate = Public.get('spectate')

    if not spectate[player.index] then
        spectate[player.index] = {
            verify = false
        }
        player.print('[color=blue][Spectate][/color] Please click the spectate button again if you really want to this.', Color.warning)
        return false
    end

    if player.character and player.character.valid then
        player.character.die()
    end

    player.character = nil
    player.spectator = true
    player.tag = '[img=utility/ghost_time_to_live_modifier_icon]'
    player.set_controller({type = defines.controllers.spectator})
    game.print('[color=blue][Spectate][/color] ' .. player.name .. ' is now spectating.')
    Server.to_discord_bold(table.concat {'*** ', '[Spectate] ' .. player.name .. ' is now spectating.', ' ***'})

    if spectate[player.index] and not spectate[player.index].delay then
        spectate[player.index].verify = true
        spectate[player.index].delay = game.tick + 3600
    end
    return true
end

Public.firearm_magazine_ammo = {name = 'firearm-magazine', count = 200}
Public.piercing_rounds_magazine_ammo = {name = 'piercing-rounds-magazine', count = 200}
Public.uranium_rounds_magazine_ammo = {name = 'uranium-rounds-magazine', count = 200}
Public.light_oil_ammo = {name = 'light-oil', amount = 100}
Public.artillery_shell_ammo = {name = 'artillery-shell', count = 15}
Public.laser_turrent_power_source = {buffer_size = 2400000, power_production = 40000}
Public.pause_waves_custom_callback_token = pause_waves_custom_callback_token

function Public.get_func(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.show_all_gui(player)
    for _, child in pairs(player.gui.top.children) do
        child.visible = true
    end
end

function Public.clear_spec_tag(player)
    if player.tag == '[Spectator]' then
        player.tag = ''
    end
end

function Public.equip_players(starting_items, recreate)
    local players = Public.get('players')

    for _, player in pairs(game.players) do
        if player.character and player.character.valid then
            player.character.destroy()
        end
        if player.connected then
            if not player.character then
                player.set_controller({type = defines.controllers.god})
                player.create_character()
            end
            player.clear_items_inside()
            Modifiers.update_player_modifiers(player)
            if not recreate then
                starting_items = starting_items or this.starting_items
                for item, item_data in pairs(this.starting_items) do
                    player.insert({name = item, count = item_data.count})
                end
            end
            Public.show_all_gui(player)
            Public.clear_spec_tag(player)
        else
            players[player.index] = nil
            Session.clear_player(player)
            game.remove_offline_players({player.index})
        end
    end
end

function Public.reset_func_table()
    this.power_sources = {index = 1}
    this.refill_turrets = {index = 1}
    this.magic_crafters = {index = 1}
    this.magic_fluid_crafters = {index = 1}
    this.starting_items = {
        ['pistol'] = {
            count = 1
        },
        ['firearm-magazine'] = {
            count = 16
        },
        ['rail'] = {
            count = 16
        },
        ['wood'] = {
            count = 16
        },
        ['explosives'] = {
            count = 32
        }
    }
end

local on_player_joined_game = Public.on_player_joined_game
local on_player_left_game = Public.on_player_left_game
local on_research_finished = Public.on_research_finished
local on_player_changed_position = Public.on_player_changed_position
local on_player_respawned = Public.on_player_respawned
local on_player_driving_changed_state = Public.on_player_driving_changed_state

Event.add(de.on_player_joined_game, on_player_joined_game)
Event.add(de.on_player_left_game, on_player_left_game)
Event.add(de.on_research_finished, on_research_finished)
Event.add(de.on_player_changed_position, on_player_changed_position)
Event.add(de.on_player_respawned, on_player_respawned)
Event.add(de.on_player_driving_changed_state, on_player_driving_changed_state)
Event.on_nth_tick(10, tick)
Event.add(WD.events.on_wave_created, on_wave_created)

return Public
