local Public = require 'modules.rpg.table'
local Task = require 'utils.task'
local Gui = require 'utils.gui'
local Color = require 'utils.color_presets'
local Token = require 'utils.token'
local Alert = require 'utils.alert'

local level_up_floating_text_color = {0, 205, 0}
local visuals_delay = Public.visuals_delay
local xp_floating_text_color = Public.xp_floating_text_color
local experience_levels = Public.experience_levels
local points_per_level = Public.points_per_level
local settings_level = Public.gui_settings_levels
local floor = math.floor
local random = math.random

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
        for i = 1, 3 do
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

    -- automatically enable one_punch and stone_path,
    -- but do so only once.
    if rpg_t.level >= settings_level['one_punch_label'] then
        if not rpg_t.auto_toggle_features.one_punch then
            rpg_t.auto_toggle_features.one_punch = true
            rpg_t.one_punch = true
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

    rpg_extra.global_pool = rpg_extra.global_pool + fee
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
        if data.mana and data.mana.valid then
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
        if data.mana and data.mana.valid then
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
        if data.health and data.health.valid then
            data.health.caption = (math.round(player.character.health * 10) / 10)
        end
        local shield_gui = player.character.get_inventory(defines.inventory.character_armor)
        if not shield_gui.is_empty() then
            if shield_gui[1].grid then
                local shield = math.floor(shield_gui[1].grid.shield)
                local shield_max = math.floor(shield_gui[1].grid.max_shield)
                if data.shield and data.shield.valid then
                    data.shield.caption = shield
                end
                if data.shield_max and data.shield_max.valid then
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
    player.play_sound {path = 'utility/achievement_unlocked', volume_modifier = 0.40}
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
    player.play_sound {path = 'utility/achievement_unlocked', volume_modifier = 0.40}
end

function Public.get_melee_modifier(player)
    local rpg_t = Public.get_value_from_player(player.index)
    return (rpg_t.strength - 10) * 0.10
end

function Public.get_heal_modifier(player)
    local rpg_t = Public.get_value_from_player(player.index)
    return (rpg_t.vitality - 10) * 0.06
end

function Public.get_heal_modifier_from_using_fish(player)
    local rpg_extra = Public.get('rpg_extra')
    if rpg_extra.disable_get_heal_modifier_from_using_fish then
        return
    end

    local base_amount = 80
    local rng = random(base_amount, base_amount * 4)
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

function Public.get_one_punch_chance(player)
    local rpg_t = Public.get_value_from_player(player.index)
    if rpg_t.strength < 100 then
        return 0
    end
    local chance = math.round(rpg_t.strength * 0.01, 1)
    if chance > 100 then
        chance = 100
    end
    return chance
end

function Public.get_extra_following_robots(player)
    local rpg_t = Public.get_value_from_player(player.index)
    local strength = rpg_t.strength
    local count = math.round(strength / 2 * 0.03, 3)
    return count
end

function Public.get_magicka(player)
    local rpg_t = Public.get_value_from_player(player.index)
    return (rpg_t.magicka - 10) * 0.10
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
                dropdown_select_index1 = 1,
                dropdown_select_index2 = 1,
                dropdown_select_index3 = 1,
                allocate_index = 1,
                flame_boots = false,
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
                show_bars = false,
                stone_path = false,
                one_punch = false,
                auto_toggle_features = {
                    stone_path = false,
                    one_punch = false
                }
            }
        )
        rpg_t.points_left = old_points_left + total
        rpg_t.xp = old_xp
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
                dropdown_select_index1 = 1,
                dropdown_select_index2 = 1,
                dropdown_select_index3 = 1,
                allocate_index = 1,
                flame_boots = false,
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
                show_bars = false,
                stone_path = false,
                one_punch = false,
                auto_toggle_features = {
                    stone_path = false,
                    one_punch = false
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
        amount = math.round(amount, 3) - fee
        if rpg_extra.difficulty then
            amount = amount + rpg_extra.difficulty
        end
        Public.debug_log('RPG - ' .. player.name .. ' got after fee: ' .. amount)
    else
        Public.debug_log('RPG - ' .. player.name .. ' got org xp: ' .. amount)
    end

    rpg_t.xp = math.round(rpg_t.xp + amount, 3)
    rpg_t.xp_since_last_floaty_text = rpg_t.xp_since_last_floaty_text + amount

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

    return
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

Public.add_to_global_pool = add_to_global_pool
