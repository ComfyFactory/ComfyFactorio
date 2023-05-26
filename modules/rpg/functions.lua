local Public = require 'modules.rpg.table'
local Task = require 'utils.task'
local Gui = require 'utils.gui'
local Color = require 'utils.color_presets'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local P = require 'utils.player_modifiers'
local Token = require 'utils.token'
local Alert = require 'utils.alert'
local Math2D = require 'math2d'

local level_up_floating_text_color = {0, 205, 0}
local visuals_delay = Public.visuals_delay
local xp_floating_text_color = Public.xp_floating_text_color
local experience_levels = Public.experience_levels
local points_per_level = Public.points_per_level
local settings_level = Public.gui_settings_levels

local round = math.round
local floor = math.floor
local random = math.random
local abs = math.abs
local sub = string.sub
local angle_multipler = 2 * math.pi
local start_angle = -angle_multipler / 4
local update_rate = 4
local time_to_live = update_rate + 1

local draw_arc = rendering.draw_arc

--RPG Frames
local main_frame_name = Public.main_frame_name
local spell_gui_frame_name = Public.spell_gui_frame_name

local travelings = {
    'bzzZZrrt',
    'WEEEeeeeeee',
    'out of my way son',
    'on my way',
    'i need to leave',
    'comfylatron seeking target',
    'gotta go fast',
    'gas gas gas',
    'comfylatron coming through'
}

local desync =
    Token.register(
    function(data)
        local entity = data.entity
        if not entity or not entity.valid then
            return
        end
        local surface = data.surface
        local fake_shooter = surface.create_entity({name = 'character', position = entity.position, force = 'enemy'})
        for _ = 1, 3 do
            surface.create_entity(
                {
                    name = 'explosive-rocket',
                    position = entity.position,
                    force = 'enemy',
                    speed = 1,
                    max_range = 1,
                    target = entity,
                    source = fake_shooter
                }
            )
        end
        if fake_shooter and fake_shooter.valid then
            fake_shooter.destroy()
        end
    end
)

local function create_healthbar(player, size)
    return rendering.draw_sprite(
        {
            sprite = 'virtual-signal/signal-white',
            tint = Color.green,
            x_scale = size * 8,
            y_scale = size - 0.2,
            render_layer = 'light-effect',
            target = player.character,
            target_offset = {0, -2.5},
            surface = player.surface
        }
    )
end

local function create_manabar(player, size)
    return rendering.draw_sprite(
        {
            sprite = 'virtual-signal/signal-white',
            tint = Color.blue,
            x_scale = size * 8,
            y_scale = size - 0.2,
            render_layer = 'light-effect',
            target = player.character,
            target_offset = {0, -2.0},
            surface = player.surface
        }
    )
end

local function set_bar(min, max, id, mana)
    local m = min / max
    if not rendering.is_valid(id) then
        return
    end
    local x_scale = rendering.get_y_scale(id) * 8
    rendering.set_x_scale(id, x_scale * m)
    if not mana then
        rendering.set_color(id, {math.floor(255 - 255 * m), math.floor(200 * m), 0})
    end
end

local function level_up(player)
    local rpg_t = Public.get_value_from_player(player.index)
    local names = Public.auto_allocate_nodes_func

    local distribute_points_gain = 0
    for i = rpg_t.level + 1, #experience_levels, 1 do
        if rpg_t.xp > experience_levels[i] then
            rpg_t.level = i
            distribute_points_gain = distribute_points_gain + points_per_level
        else
            break
        end
    end
    if distribute_points_gain == 0 then
        return
    end

    -- automatically enable aoe_punch and stone_path,
    -- but do so only once.
    if rpg_t.level >= settings_level['aoe_punch_label'] then
        if not rpg_t.auto_toggle_features.aoe_punch then
            rpg_t.auto_toggle_features.aoe_punch = true
            rpg_t.aoe_punch = true
        end
    end
    if rpg_t.level >= settings_level['stone_path_label'] then
        if not rpg_t.auto_toggle_features.stone_path then
            rpg_t.auto_toggle_features.stone_path = true
            rpg_t.stone_path = true
        end
    end

    Public.draw_level_text(player)
    rpg_t.points_left = rpg_t.points_left + distribute_points_gain
    if rpg_t.allocate_index ~= 1 then
        local node = rpg_t.allocate_index
        local index = names[node]:lower()
        rpg_t[index] = rpg_t[index] + distribute_points_gain
        rpg_t.points_left = rpg_t.points_left - distribute_points_gain
        if not rpg_t.reset then
            rpg_t.total = rpg_t.total + distribute_points_gain
        end
        Public.update_player_stats(player)
    else
        Public.update_char_button(player)
    end
    if player.gui.screen[main_frame_name] then
        Public.toggle(player, true)
    end

    Public.level_up_effects(player)
end

local function has_health_boost(entity, damage, final_damage_amount, cause, callback_func)
    local biter_health_boost = BiterHealthBooster.get('biter_health_boost')
    local biter_health_boost_units = BiterHealthBooster.get('biter_health_boost_units')

    local get_health_pool

    if not entity.valid then
        return
    end

    --Handle the custom health pool of the biter health booster, if it is used in the map.
    if biter_health_boost then
        local health_pool = biter_health_boost_units[entity.unit_number]
        if health_pool then
            get_health_pool = health_pool[1]
            --Set entity health relative to health pool
            local max_health = health_pool[3].max_health
            local m = health_pool[1] / max_health
            local final_health = round(entity.prototype.max_health * m)

            health_pool[1] = round(health_pool[1] + final_damage_amount)
            health_pool[1] = round(health_pool[1] - damage)

            --Set entity health relative to health pool
            entity.health = final_health

            if health_pool[1] <= 0 then
                local entity_number = entity.unit_number
                if not callback_func then
                    entity.die(entity.force.name, cause)
                end

                if biter_health_boost_units[entity_number] then
                    biter_health_boost_units[entity_number] = nil
                end
            end
        else
            entity.health = entity.health + final_damage_amount
            entity.health = entity.health - damage
            if entity.health <= 0 then
                if not callback_func then
                    entity.die(cause.force.name, cause)
                end
            end
        end
    else
        --Handle vanilla damage.
        entity.health = entity.health + final_damage_amount
        entity.health = entity.health - damage
        if entity.health <= 0 then
            if not callback_func then
                entity.die(cause.force.name, cause)
            end
        end
    end

    return get_health_pool
end

local function set_health_boost(entity, damage, cause)
    local biter_health_boost = BiterHealthBooster.get('biter_health_boost')
    local biter_health_boost_units = BiterHealthBooster.get('biter_health_boost_units')

    local get_health_pool

    if not entity.valid then
        return
    end

    --Handle the custom health pool of the biter health booster, if it is used in the map.
    if biter_health_boost then
        local health_pool = biter_health_boost_units[entity.unit_number]
        if health_pool then
            get_health_pool = health_pool[1]
            --Set entity health relative to health pool
            local max_health = health_pool[3].max_health
            local m = health_pool[1] / max_health
            local final_health = round(entity.prototype.max_health * m)

            health_pool[1] = round(health_pool[1] - damage)

            --Set entity health relative to health pool
            entity.health = final_health

            if health_pool[1] <= 0 then
                local entity_number = entity.unit_number
                entity.die(entity.force.name, cause)

                if biter_health_boost_units[entity_number] then
                    biter_health_boost_units[entity_number] = nil
                end
            end
        end
    end

    return get_health_pool
end

local function add_to_global_pool(amount, personal_tax)
    local rpg_extra = Public.get('rpg_extra')

    if not rpg_extra.global_pool then
        return
    end
    local fee
    if personal_tax then
        fee = amount * rpg_extra.personal_tax_rate
    else
        fee = amount * 0.3
    end

    rpg_extra.global_pool = round(rpg_extra.global_pool + fee, 8)
    return amount - fee
end

local repair_buildings =
    Token.register(
    function(data)
        local entity = data.entity
        if entity and entity.valid then
            local rng = 0.1
            if math.random(1, 5) == 1 then
                rng = 0.2
            elseif math.random(1, 8) == 1 then
                rng = 0.4
            end
            local to_heal = entity.prototype.max_health * rng
            if entity.health and to_heal then
                entity.health = entity.health + to_heal
            end
        end
    end
)

function Public.repair_aoe(player, position)
    local entities = player.surface.find_entities_filtered {force = player.force, area = {{position.x - 8, position.y - 8}, {position.x + 8, position.y + 8}}}
    local count = 0
    for i = 1, #entities do
        local e = entities[i]
        if e.prototype.max_health ~= e.health then
            count = count + 1
            Task.set_timeout_in_ticks(10, repair_buildings, {entity = e})
        end
    end
    return count
end

function Public.suicidal_comfylatron(pos, surface)
    local str = travelings[math.random(1, #travelings)]
    local symbols = {'', '!', '!', '!!', '..'}
    str = str .. symbols[math.random(1, #symbols)]
    local text = str
    local e =
        surface.create_entity(
        {
            name = 'compilatron',
            position = {x = pos.x, y = pos.y + 2},
            force = 'neutral'
        }
    )
    surface.create_entity(
        {
            name = 'compi-speech-bubble',
            position = e.position,
            source = e,
            text = text
        }
    )
    local nearest_player_unit = surface.find_nearest_enemy({position = e.position, max_distance = 512, force = 'player'})

    if nearest_player_unit and nearest_player_unit.active and nearest_player_unit.force.name ~= 'player' then
        e.set_command(
            {
                type = defines.command.attack,
                target = nearest_player_unit,
                distraction = defines.distraction.none
            }
        )
        local data = {
            entity = e,
            surface = surface
        }
        Task.set_timeout_in_ticks(600, desync, data)
    else
        e.surface.create_entity({name = 'medium-explosion', position = e.position})
        e.surface.create_entity(
            {
                name = 'flying-text',
                position = e.position,
                text = 'DeSyyNC - no target found!',
                color = {r = 150, g = 0, b = 0}
            }
        )
        e.die()
    end
end

function Public.validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if not player.character then
        return false
    end
    if not player.connected then
        return false
    end
    if not game.players[player.index] then
        return false
    end
    return true
end

function Public.set_last_spell_cast(player, position)
    if not player or not player.valid then
        return false
    end
    if not position then
        return false
    end

    if not type(position) == 'table' then
        return false
    end

    local rpg_t = Public.get_value_from_player(player.index)

    rpg_t.last_spell_cast = position

    return true
end

function Public.get_last_spell_cast(player)
    if not player or not player.valid then
        return false
    end

    local rpg_t = Public.get_value_from_player(player.index)

    if not rpg_t then
        return
    end

    if not rpg_t.last_spell_cast then
        return false
    end

    local position = player.position
    local cast_radius = 1
    local cast_area = {
        left_top = {x = rpg_t.last_spell_cast.x - cast_radius, y = rpg_t.last_spell_cast.y - cast_radius},
        right_bottom = {x = rpg_t.last_spell_cast.x + cast_radius, y = rpg_t.last_spell_cast.y + cast_radius}
    }

    if rpg_t.last_spell_cast then
        if Math2D.bounding_box.contains_point(cast_area, position) then
            return true
        else
            return false
        end
    end
end

function Public.remove_mana(player, mana_to_remove)
    local rpg_extra = Public.get('rpg_extra')
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_extra.enable_mana then
        return
    end

    if not mana_to_remove then
        return
    end

    mana_to_remove = floor(mana_to_remove)

    if not rpg_t then
        return
    end

    if rpg_t.debug_mode then
        rpg_t.mana = 9999
        return
    end

    if player.gui.screen[main_frame_name] then
        local f = player.gui.screen[main_frame_name]
        local data = Gui.get_data(f)
        if data and data.mana and data.mana.valid then
            data.mana.caption = rpg_t.mana
        end
    end

    rpg_t.mana = rpg_t.mana - mana_to_remove

    if rpg_t.mana < 0 then
        rpg_t.mana = 0
        return
    end

    if player.gui.screen[spell_gui_frame_name] then
        local f = player.gui.screen[spell_gui_frame_name]
        if f['spell_table'] then
            if f['spell_table']['mana'] then
                f['spell_table']['mana'].caption = math.floor(rpg_t.mana)
            end
            if f['spell_table']['maxmana'] then
                f['spell_table']['maxmana'].caption = math.floor(rpg_t.mana_max)
            end
        end
    end
end

function Public.update_mana(player)
    local rpg_extra = Public.get('rpg_extra')
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_extra.enable_mana then
        return
    end

    if not rpg_t then
        return
    end

    if player.gui.screen[main_frame_name] then
        local f = player.gui.screen[main_frame_name]
        local data = Gui.get_data(f)
        if data and data.mana and data.mana.valid then
            data.mana.caption = rpg_t.mana
        end
    end
    if player.gui.screen[spell_gui_frame_name] then
        local f = player.gui.screen[spell_gui_frame_name]
        if f['spell_table'] then
            if f['spell_table']['mana'] then
                f['spell_table']['mana'].caption = math.floor(rpg_t.mana)
            end
            if f['spell_table']['maxmana'] then
                f['spell_table']['maxmana'].caption = math.floor(rpg_t.mana_max)
            end
        end
    end

    if rpg_t.mana < 1 then
        return
    end
    if rpg_extra.enable_health_and_mana_bars then
        if rpg_t.show_bars then
            if player.character and player.character.valid then
                if not rpg_t.mana_bar then
                    rpg_t.mana_bar = create_manabar(player, 0.5)
                elseif not rendering.is_valid(rpg_t.mana_bar) then
                    rpg_t.mana_bar = create_manabar(player, 0.5)
                end
                set_bar(rpg_t.mana, rpg_t.mana_max, rpg_t.mana_bar, true)
            end
        else
            if rpg_t.mana_bar then
                if rendering.is_valid(rpg_t.mana_bar) then
                    rendering.destroy(rpg_t.mana_bar)
                end
            end
        end
    end
end

function Public.reward_mana(player, mana_to_add)
    local rpg_extra = Public.get('rpg_extra')
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_extra.enable_mana then
        return
    end

    if not mana_to_add then
        return
    end

    mana_to_add = floor(mana_to_add)

    if not rpg_t then
        return
    end

    if player.gui.screen[main_frame_name] then
        local f = player.gui.screen[main_frame_name]
        local data = Gui.get_data(f)
        if data and data.mana and data.mana.valid then
            data.mana.caption = rpg_t.mana
        end
    end
    if player.gui.screen[spell_gui_frame_name] then
        local f = player.gui.screen[spell_gui_frame_name]
        if f['spell_table'] then
            if f['spell_table']['mana'] then
                f['spell_table']['mana'].caption = math.floor(rpg_t.mana)
            end
            if f['spell_table']['maxmana'] then
                f['spell_table']['maxmana'].caption = math.floor(rpg_t.mana_max)
            end
        end
    end

    if rpg_t.mana_max < 1 then
        return
    end

    if rpg_t.mana >= rpg_t.mana_max then
        rpg_t.mana = rpg_t.mana_max
        return
    end

    rpg_t.mana = rpg_t.mana + mana_to_add
end

function Public.update_health(player)
    local rpg_extra = Public.get('rpg_extra')
    local rpg_t = Public.get_value_from_player(player.index)

    if not player or not player.valid then
        return
    end

    if not player.character or not player.character.valid then
        return
    end

    if not rpg_t then
        return
    end

    if player.gui.screen[main_frame_name] then
        local f = player.gui.screen[main_frame_name]
        local data = Gui.get_data(f)
        if data and data.health and data.health.valid then
            data.health.caption = (round(player.character.health * 10) / 10)
        end
        local shield_gui = player.character.get_inventory(defines.inventory.character_armor)
        if not shield_gui.is_empty() then
            if shield_gui[1].grid then
                local shield = math.floor(shield_gui[1].grid.shield)
                local shield_max = math.floor(shield_gui[1].grid.max_shield)
                if data and data.shield and data.shield.valid then
                    data.shield.caption = shield
                end
                if data and data.shield_max and data.shield_max.valid then
                    data.shield_max.caption = shield_max
                end
            end
        end
    end

    if rpg_extra.enable_health_and_mana_bars then
        if rpg_t.show_bars then
            local max_life = math.floor(player.character.prototype.max_health + player.character_health_bonus + player.force.character_health_bonus)
            if not rpg_t.health_bar then
                rpg_t.health_bar = create_healthbar(player, 0.5)
            elseif not rendering.is_valid(rpg_t.health_bar) then
                rpg_t.health_bar = create_healthbar(player, 0.5)
            end
            set_bar(player.character.health, max_life, rpg_t.health_bar)
        else
            if rpg_t.health_bar then
                if rendering.is_valid(rpg_t.health_bar) then
                    rendering.destroy(rpg_t.health_bar)
                end
            end
        end
    end
end

function Public.log_aoe_punch(callback)
    local debug = Public.get('rpg_extra').debug_aoe_punch
    if not debug then
        return
    end
    callback()
end

--Melee damage modifier
function Public.aoe_punch(entity, target, damage, get_health_pool)
    if not (target and target.valid) then
        return
    end

    local base_vector = {target.position.x - entity.position.x, target.position.y - entity.position.y}

    local vector = {base_vector[1], base_vector[2]}
    vector[1] = vector[1] * 1000
    vector[2] = vector[2] * 1000

    entity.surface.create_entity({name = 'blood-explosion-huge', position = target.position})

    if abs(vector[1]) > abs(vector[2]) then
        local d = abs(vector[1])
        if abs(vector[1]) > 0 then
            vector[1] = vector[1] / d
        end
        if abs(vector[2]) > 0 then
            vector[2] = vector[2] / d
        end
    else
        local d = abs(vector[2])
        if abs(vector[2]) > 0 then
            vector[2] = vector[2] / d
        end
        if abs(vector[1]) > 0 and d > 0 then
            vector[1] = vector[1] / d
        end
    end

    vector[1] = vector[1] * 1.5
    vector[2] = vector[2] * 1.5

    local a = 0.20

    local cs = entity.surface
    local cp = entity.position

    for i = 1, 16, 1 do
        for x = i * -1 * a, i * a, 1 do
            for y = i * -1 * a, i * a, 1 do
                local p = {cp.x + x + vector[1] * i, cp.y + y + vector[2] * i}
                cs.create_trivial_smoke({name = 'train-smoke', position = p})
                for _, e in pairs(cs.find_entities({{p[1] - a, p[2] - a}, {p[1] + a, p[2] + a}})) do
                    if e.valid then
                        if e.health then
                            if e.destructible and e.minable and e.force.index ~= 3 then
                                if e.force.index ~= entity.force.index then
                                    if get_health_pool then
                                        local max_unit_health = floor(get_health_pool * 0.00015)
                                        if max_unit_health <= 0 then
                                            max_unit_health = 4
                                        end
                                        if max_unit_health >= 10 then
                                            max_unit_health = 10
                                        end
                                        local final = floor(damage * max_unit_health)
                                        set_health_boost(e, final, entity)
                                        if e.valid and e.health <= 0 and get_health_pool <= 0 then
                                            e.die(e.force.name, entity)
                                        end
                                    else
                                        if e.valid then
                                            e.health = e.health - damage * 0.05
                                            if e.health <= 0 then
                                                e.die(e.force.name, entity)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function Public.level_limit_exceeded(player, value)
    local rpg_extra = Public.get('rpg_extra')
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_extra.level_limit_enabled then
        return false
    end

    local limits = {
        [1] = 30,
        [2] = 50,
        [3] = 70,
        [4] = 90,
        [5] = 110,
        [6] = 130,
        [7] = 150,
        [8] = 170,
        [9] = 190,
        [10] = 210
    }

    local level = rpg_t.level
    local zone = rpg_extra.breached_walls
    if zone >= 11 then
        zone = 10
    end
    if value then
        return limits[zone]
    end

    if level >= limits[zone] then
        return true
    end
    return false
end

function Public.update_player_stats(player)
    local rpg_extra = Public.get('rpg_extra')
    local rpg_t = Public.get_value_from_player(player.index)
    local strength = rpg_t.strength - 10
    P.update_single_modifier(player, 'character_inventory_slots_bonus', 'rpg', round(strength * 0.2, 3))
    P.update_single_modifier(player, 'character_mining_speed_modifier', 'rpg', round(strength * 0.006, 3))
    P.update_single_modifier(player, 'character_maximum_following_robot_count_bonus', 'rpg', round(strength / 2 * 0.03, 3))

    local magic = rpg_t.magicka - 10
    local v = magic * 0.22
    P.update_single_modifier(player, 'character_build_distance_bonus', 'rpg', math.min(60, round(v * 0.12, 3)))
    P.update_single_modifier(player, 'character_item_drop_distance_bonus', 'rpg', math.min(60, round(v * 0.05, 3)))
    P.update_single_modifier(player, 'character_reach_distance_bonus', 'rpg', math.min(60, round(v * 0.12, 3)))
    P.update_single_modifier(player, 'character_loot_pickup_distance_bonus', 'rpg', math.min(20, round(v * 0.12, 3)))
    P.update_single_modifier(player, 'character_item_pickup_distance_bonus', 'rpg', math.min(20, round(v * 0.12, 3)))
    P.update_single_modifier(player, 'character_resource_reach_distance_bonus', 'rpg', math.min(20, round(v * 0.05, 3)))
    if rpg_t.mana_max >= rpg_extra.mana_limit then
        rpg_t.mana_max = rpg_extra.mana_limit
    else
        rpg_t.mana_max = round((magic) * 2, 3)
    end

    local dexterity = rpg_t.dexterity - 10
    P.update_single_modifier(player, 'character_running_speed_modifier', 'rpg', round(dexterity * 0.0010, 3)) -- reduced since too high speed kills UPS.
    P.update_single_modifier(player, 'character_crafting_speed_modifier', 'rpg', round(dexterity * 0.015, 3))
    P.update_single_modifier(player, 'character_health_bonus', 'rpg', round((rpg_t.vitality - 10) * 6, 3))
    P.update_player_modifiers(player)
end

function Public.level_up_effects(player)
    local position = {x = player.position.x - 0.75, y = player.position.y - 1}
    player.surface.create_entity({name = 'flying-text', position = position, text = '+LVL ', color = level_up_floating_text_color})
    local b = 0.75
    for _ = 1, 5, 1 do
        local p = {
            (position.x + 0.4) + (b * -1 + math.random(0, b * 20) * 0.1),
            position.y + (b * -1 + math.random(0, b * 20) * 0.1)
        }
        player.surface.create_entity({name = 'flying-text', position = p, text = '✚', color = {255, math.random(0, 100), 0}})
    end
    player.play_sound {path = 'utility/achievement_unlocked', volume_modifier = 0.50}
end

function Public.cast_spell(player, failed)
    local position = {x = player.position.x - 0.75, y = player.position.y - 1}
    local b = 0.75
    if not failed then
        for _ = 1, 3, 1 do
            local p = {
                (position.x + 0.4) + (b * -1 + math.random(0, b * 20) * 0.1),
                position.y + (b * -1 + math.random(0, b * 20) * 0.1)
            }
            player.surface.create_entity({name = 'flying-text', position = p, text = '✔️', color = {255, math.random(0, 100), 0}})
        end
        player.play_sound {path = 'utility/scenario_message', volume_modifier = 1}
    else
        for _ = 1, 3, 1 do
            local p = {
                (position.x + 0.4) + (b * -1 + math.random(0, b * 20) * 0.1),
                position.y + (b * -1 + math.random(0, b * 20) * 0.1)
            }
            player.surface.create_entity({name = 'flying-text', position = p, text = '✖', color = {255, math.random(0, 100), 0}})
        end
        player.play_sound {path = 'utility/cannot_build', volume_modifier = 1}
    end
end

function Public.xp_effects(player)
    local position = {x = player.position.x - 0.75, y = player.position.y - 1}
    player.surface.create_entity({name = 'flying-text', position = position, text = '+XP', color = level_up_floating_text_color})
    local b = 0.75
    for _ = 1, 5, 1 do
        local p = {
            (position.x + 0.4) + (b * -1 + math.random(0, b * 20) * 0.1),
            position.y + (b * -1 + math.random(0, b * 20) * 0.1)
        }
        player.surface.create_entity({name = 'flying-text', position = p, text = '✚', color = {255, math.random(0, 100), 0}})
    end
    player.play_sound {path = 'utility/achievement_unlocked', volume_modifier = 0.50}
end

function Public.get_range_modifier(player)
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_t then
        return false
    end
    local total = (rpg_t.strength - 10) * 0.010
    if total > 5 then -- limit it to 5 for now, until we've tested it enough
        total = 5
    end
    return round(total, 3)
end

function Public.get_melee_modifier(player)
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_t then
        return false
    end
    local total = (rpg_t.strength - 10) * 0.10
    return total
end

function Public.get_player_level(player)
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_t then
        return false
    end
    return rpg_t.level
end

function Public.get_area_of_effect_range(player)
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_t then
        return false
    end
    local total = (rpg_t.level - 10) * 0.05

    if rpg_t.level < 10 then
        total = 1
    end
    return total
end

function Public.get_final_damage_modifier(player)
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_t then
        return false
    end
    local rng = random(10, 35) * 0.01
    return (rpg_t.strength - 10) * rng
end

function Public.get_final_damage(player, entity, original_damage_amount)
    local modifier = Public.get_final_damage_modifier(player)
    if not modifier then
        return false
    end
    local damage = original_damage_amount + original_damage_amount * modifier
    if entity.prototype.resistances then
        if entity.prototype.resistances.physical then
            damage = damage - entity.prototype.resistances.physical.decrease
            damage = damage - damage * entity.prototype.resistances.physical.percent
        end
    end
    damage = round(damage, 3)
    if damage < 1 then
        damage = 1
    end
    return damage
end

function Public.get_heal_modifier(player)
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_t then
        return false
    end
    return (rpg_t.vitality - 10) * 0.06
end

function Public.get_heal_modifier_from_using_fish(player)
    local rpg_extra = Public.get('rpg_extra')
    if rpg_extra.disable_get_heal_modifier_from_using_fish then
        return
    end

    local base_amount = 80
    local rng = random(base_amount, base_amount * rpg_extra.heal_modifier)
    local char = player.character
    local position = player.position
    if char and char.valid then
        local health = player.character_health_bonus + 250
        local color
        if char.health > (health * 0.50) then
            color = {b = 0.2, r = 0.1, g = 1, a = 0.8}
        elseif char.health > (health * 0.25) then
            color = {r = 1, g = 1, b = 0}
        else
            color = {b = 0.1, r = 1, g = 0, a = 0.8}
        end
        player.surface.create_entity(
            {
                name = 'flying-text',
                position = {position.x, position.y + 0.6},
                text = '+' .. rng,
                color = color
            }
        )
        char.health = char.health + rng
    end
end

function Public.get_mana_modifier(player)
    local rpg_t = Public.get_value_from_player(player.index)
    if rpg_t.level <= 40 then
        return (rpg_t.magicka - 10) * 0.02000
    elseif rpg_t.level <= 80 then
        return (rpg_t.magicka - 10) * 0.01800
    else
        return (rpg_t.magicka - 10) * 0.01400
    end
end

function Public.get_life_on_hit(player)
    local rpg_t = Public.get_value_from_player(player.index)
    return (rpg_t.vitality - 10) * 0.4
end

function Public.get_aoe_punch_chance(player)
    local rpg_t = Public.get_value_from_player(player.index)
    if rpg_t.strength < 100 then
        return 0
    end
    local chance = round(rpg_t.strength * 0.007, 1)
    if chance > 100 then
        chance = 100
    end
    return chance
end

function Public.get_extra_following_robots(player)
    local rpg_t = Public.get_value_from_player(player.index)
    local strength = rpg_t.strength
    local count = round(strength / 2 * 0.03, 3)
    return count
end

function Public.get_magicka(player)
    local rpg_t = Public.get_value_from_player(player.index)
    return (rpg_t.magicka - 10) * 0.10
end

local show_cooldown
show_cooldown =
    Token.register(
    function(event)
        local player_index = event.player_index
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end

        local tick = event.tick
        local now = game.tick
        if now >= tick then
            return
        end

        local fade = ((now - tick) / event.delay) + 1

        if not player.character then
            return
        end

        draw_arc(
            {
                color = {1 - fade, fade, 0},
                max_radius = 0.5,
                min_radius = 0.4,
                start_angle = start_angle,
                angle = fade * angle_multipler,
                target = player.character,
                target_offset = {x = 0, y = -2},
                surface = player.surface,
                time_to_live = time_to_live
            }
        )

        Task.set_timeout_in_ticks(update_rate, show_cooldown, event)
    end
)
Public.show_cooldown = show_cooldown

function Public.register_cooldown_for_player(player, spell)
    Task.set_timeout_in_ticks(update_rate, show_cooldown, {player_index = player.index, tick = game.tick + spell.cooldown, delay = spell.cooldown})
end

--- Gives connected player some bonus xp if the map was preemptively shut down.
-- amount (integer) -- 10 levels
-- local Public = require 'modules.rpg.table' Public.give_xp(512)
function Public.give_xp(amount)
    for _, player in pairs(game.connected_players) do
        if not Public.validate_player(player) then
            return
        end
        Public.gain_xp(player, amount)
    end
end

-- Checks if the player is on the correct surface.
function Public.check_is_surface_valid(player)
    if is_game_modded() then
        return true
    end

    local is_surface_valid = false

    local surface_name = Public.get('rpg_extra').surface_name
    if type(surface_name) == 'table' then
        for _, tbl_surface in pairs(surface_name) do
            if sub(player.surface.name, 0, #surface_name) == tbl_surface then
                is_surface_valid = true
            end
        end
    else
        if sub(player.surface.name, 0, #surface_name) ~= surface_name then
            return false
        else
            return true
        end
    end

    if not is_surface_valid then
        return false
    end

    return true
end

function Public.rpg_reset_player(player, one_time_reset)
    if not player.character then
        player.set_controller({type = defines.controllers.god})
        player.create_character()
    end
    local rpg_t = Public.get_value_from_player(player.index)
    local rpg_extra = Public.get('rpg_extra')
    if one_time_reset then
        local total = rpg_t.total
        if not total then
            total = 0
        end
        if rpg_t.text then
            rendering.destroy(rpg_t.text)
            rpg_t.text = nil
        end
        local old_level = rpg_t.level
        local old_points_left = rpg_t.points_left
        local old_xp = rpg_t.xp
        rpg_t =
            Public.set_new_player_tbl(
            player.index,
            {
                level = 1,
                xp = 0,
                strength = 10,
                magicka = 10,
                dexterity = 10,
                vitality = 10,
                mana = 0,
                mana_max = 0,
                last_spawned = 0,
                dropdown_select_index = 1,
                dropdown_select_name = Public.all_spells[1].name[1],
                dropdown_select_index_1 = 1,
                dropdown_select_name_1 = Public.all_spells[1].name[1],
                dropdown_select_index_2 = 1,
                dropdown_select_name_2 = Public.all_spells[1].name[1],
                dropdown_select_index_3 = 1,
                dropdown_select_name_3 = Public.all_spells[1].name[1],
                allocate_index = 1,
                explosive_bullets = false,
                enable_entity_spawn = false,
                health_bar = rpg_t.health_bar,
                mana_bar = rpg_t.mana_bar,
                points_left = 0,
                last_floaty_text = visuals_delay,
                xp_since_last_floaty_text = 0,
                reset = true,
                capped = false,
                bonus = rpg_extra.breached_walls or 1,
                rotated_entity_delay = 0,
                last_mined_entity_position = {x = 0, y = 0},
                last_spell_cast = {x = 0, y = 0},
                show_bars = false,
                stone_path = false,
                aoe_punch = false,
                auto_toggle_features = {
                    stone_path = false,
                    aoe_punch = false
                }
            }
        )
        rpg_t.points_left = old_points_left + total
        rpg_t.xp = round(old_xp)
        rpg_t.level = old_level
    else
        Public.set_new_player_tbl(
            player.index,
            {
                level = 1,
                xp = 0,
                strength = 10,
                magicka = 10,
                dexterity = 10,
                vitality = 10,
                mana = 0,
                mana_max = 0,
                last_spawned = 0,
                dropdown_select_index = 1,
                dropdown_select_name = Public.all_spells[1].name[1],
                dropdown_select_index_1 = 1,
                dropdown_select_name_1 = Public.all_spells[1].name[1],
                dropdown_select_index_2 = 1,
                dropdown_select_name_2 = Public.all_spells[1].name[1],
                dropdown_select_index_3 = 1,
                dropdown_select_name_3 = Public.all_spells[1].name[1],
                allocate_index = 1,
                explosive_bullets = false,
                enable_entity_spawn = false,
                points_left = 0,
                last_floaty_text = visuals_delay,
                xp_since_last_floaty_text = 0,
                reset = false,
                capped = false,
                total = 0,
                bonus = 1,
                rotated_entity_delay = 0,
                last_mined_entity_position = {x = 0, y = 0},
                last_spell_cast = {x = 0, y = 0},
                show_bars = false,
                stone_path = false,
                aoe_punch = false,
                auto_toggle_features = {
                    stone_path = false,
                    aoe_punch = false
                }
            }
        )
    end
    Public.draw_gui_char_button(player)
    Public.draw_level_text(player)
    Public.update_char_button(player)
    Public.update_player_stats(player)
end

function Public.rpg_reset_all_players()
    local rpg_t = Public.get('rpg_t')
    local rpg_extra = Public.get('rpg_extra')
    for k, _ in pairs(rpg_t) do
        rpg_t[k] = nil
    end
    for _, p in pairs(game.connected_players) do
        Public.rpg_reset_player(p)
    end
    rpg_extra.breached_walls = 1
    rpg_extra.reward_new_players = 0
    rpg_extra.global_pool = 0
end

-- local Public = require 'modules.rpg.table' Public.gain_xp(game.players['Gerkiz'], 5012, true)
function Public.gain_xp(player, amount, added_to_pool, text)
    if not Public.validate_player(player) then
        return
    end
    local rpg_extra = Public.get('rpg_extra')
    local rpg_t = Public.get_value_from_player(player.index)

    if Public.level_limit_exceeded(player) then
        add_to_global_pool(amount, false)
        if not rpg_t.capped then
            rpg_t.capped = true
            local message = ({'rpg_functions.max_level'})
            Alert.alert_player_warning(player, 10, message)
        end
        return
    end

    local text_to_draw

    if rpg_t.capped then
        rpg_t.capped = false
    end

    if not added_to_pool then
        Public.debug_log('RPG - ' .. player.name .. ' got org xp: ' .. amount)
        local fee = amount - add_to_global_pool(amount, true)
        Public.debug_log('RPG - ' .. player.name .. ' got fee: ' .. fee)
        amount = round(amount, 3) - fee
        if rpg_extra.difficulty then
            amount = amount + rpg_extra.difficulty
        end
        Public.debug_log('RPG - ' .. player.name .. ' got after fee: ' .. amount)
    else
        Public.debug_log('RPG - ' .. player.name .. ' got org xp: ' .. amount)
    end

    rpg_t.xp = round(rpg_t.xp + amount, 3)
    rpg_t.xp_since_last_floaty_text = round(rpg_t.xp_since_last_floaty_text + amount)

    if not experience_levels[rpg_t.level + 1] then
        return
    end

    local f = player.gui.screen[main_frame_name]
    if f and f.valid then
        local d = Gui.get_data(f)
        if d.exp_gui and d.exp_gui.valid then
            d.exp_gui.caption = math.floor(rpg_t.xp)
        end
    end

    if rpg_t.xp >= experience_levels[rpg_t.level + 1] then
        level_up(player)
    end

    if rpg_t.last_floaty_text > game.tick then
        if not text then
            return
        end
    end

    if text then
        text_to_draw = '+' .. math.floor(amount) .. ' xp'
    else
        text_to_draw = '+' .. math.floor(rpg_t.xp_since_last_floaty_text) .. ' xp'
    end

    player.create_local_flying_text {
        text = text_to_draw,
        position = player.position,
        color = xp_floating_text_color,
        time_to_live = 340,
        speed = 2
    }

    rpg_t.xp_since_last_floaty_text = 0
    rpg_t.last_floaty_text = game.tick + visuals_delay
end

function Public.global_pool(players, count)
    local rpg_extra = Public.get('rpg_extra')

    if not rpg_extra.global_pool then
        return
    end

    local pool = math.floor(rpg_extra.global_pool)

    local random_amount = math.random(5000, 10000)

    if pool <= random_amount then
        return
    end

    if pool >= 20000 then
        pool = 20000
    end

    local share = pool / count

    Public.debug_log('RPG - Share per player:' .. share)

    for i = 1, #players do
        local p = players[i]
        if p.afk_time < 5000 then
            if not Public.level_limit_exceeded(p) then
                Public.gain_xp(p, share, false, true)
                Public.xp_effects(p)
            else
                share = share / 10
                rpg_extra.leftover_pool = rpg_extra.leftover_pool + share
                Public.debug_log('RPG - player capped: ' .. p.name .. '. Amount to pool:' .. share)
            end
        else
            local message = ({'rpg_functions.pool_reward', p.name})
            Alert.alert_player_warning(p, 10, message)
            share = share / 10
            rpg_extra.leftover_pool = rpg_extra.leftover_pool + share
            Public.debug_log('RPG - player AFK: ' .. p.name .. '. Amount to pool:' .. share)
        end
    end

    rpg_extra.global_pool = rpg_extra.leftover_pool or 0
end

local damage_player_over_time_token =
    Token.register(
    function(data)
        local player = data.player
        if not player.character or not player.character.valid then
            return
        end
        player.character.health = player.character.health - (player.character.health * 0.05)
        player.character.surface.create_entity({name = 'water-splash', position = player.position})
    end
)

--- Damages a player over time.
function Public.damage_player_over_time(player, amount)
    if not player or not player.valid then
        return
    end

    amount = amount or 10
    local tick = 20
    for _ = 1, amount, 1 do
        Task.set_timeout_in_ticks(tick, damage_player_over_time_token, {player = player})
        tick = tick + 15
    end
end

--- Distributes the global xp pool to every connected player.
function Public.distribute_pool()
    local count = #game.connected_players
    local players = game.connected_players
    Public.global_pool(players, count)
    print('Distributed the global XP pool')
end

Public.has_health_boost = has_health_boost
Public.set_health_boost = set_health_boost

Public.add_to_global_pool = add_to_global_pool
