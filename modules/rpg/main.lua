local Gui = require 'utils.gui'
local Event = require 'utils.event'
local Color = require 'utils.color_presets'
local Alert = require 'utils.alert'

local WD = require 'modules.wave_defense.table'
local Math2D = require 'math2d'

--RPG Modules
local RPG = require 'modules.rpg.table'
local Settings = require 'modules.rpg.settings'
local Functions = require 'modules.rpg.functions'
local RPG_GUI = require 'modules.rpg.gui'

--RPG Settings
local enemy_types = RPG.enemy_types
local die_cause = RPG.die_cause
local rpg_frame_icons = RPG.rpg_frame_icons
local conjure_items = RPG.conjure_items
local projectile_types = RPG.projectile_types
local points_per_level = RPG.points_per_level
local nth_tick = RPG.nth_tick
local visuals_delay = RPG.visuals_delay
local xp_floating_text_color = RPG.xp_floating_text_color
local teller_global_pool = RPG.teller_global_pool
local teller_level_limit = RPG.teller_level_limit
local experience_levels = RPG.experience_levels

--RPG Frames
local draw_main_frame_name = RPG.draw_main_frame_name
local main_frame_name = RPG.main_frame_name

local Public = {}

local function level_up(player)
    local rpg_t = RPG.get('rpg_t')

    local distribute_points_gain = 0
    for i = rpg_t[player.index].level + 1, #experience_levels, 1 do
        if rpg_t[player.index].xp > experience_levels[i] then
            rpg_t[player.index].level = i
            distribute_points_gain = distribute_points_gain + points_per_level
        else
            break
        end
    end
    if distribute_points_gain == 0 then
        return
    end
    RPG_GUI.draw_level_text(player)
    rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute + distribute_points_gain
    RPG_GUI.update_char_button(player)
    table.shuffle_table(rpg_frame_icons)
    if player.gui.left[main_frame_name] then
        RPG_GUI.toggle(player, true)
    end
    Functions.level_up_effects(player)
end

local function add_to_global_pool(amount, personal_tax)
    local rpg_extra = RPG.get('rpg_extra')

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

local function global_pool(players, count)
    local rpg_extra = RPG.get('rpg_extra')

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

    RPG.debug_log('RPG - Share per player:' .. share)

    for i = 1, #players do
        local p = players[i]
        if p.afk_time < 5000 then
            if not Functions.level_limit_exceeded(p) then
                Public.gain_xp(p, share, false, true)
                Functions.xp_effects(p)
            else
                share = share / 10
                rpg_extra.leftover_pool = rpg_extra.leftover_pool + share
                RPG.debug_log('RPG - player capped: ' .. p.name .. '. Amount to pool:' .. share)
            end
        else
            local message = teller_global_pool .. p.name .. ' received nothing. Reason: AFK'
            Alert.alert_player_warning(p, 10, message)
            share = share / 10
            rpg_extra.leftover_pool = rpg_extra.leftover_pool + share
            RPG.debug_log('RPG - player AFK: ' .. p.name .. '. Amount to pool:' .. share)
        end
    end

    rpg_extra.global_pool = rpg_extra.leftover_pool or 0

    return
end

local function on_gui_click(event)
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    local element = event.element
    local player = game.players[event.player_index]

    if element.type ~= 'sprite-button' then
        return
    end

    local shift = event.shift

    if element.caption ~= '✚' then
        return
    end
    if element.sprite ~= 'virtual-signal/signal-red' then
        return
    end

    local rpg_t = RPG.get('rpg_t')

    local index = element.name
    if not rpg_t[player.index][index] then
        return
    end
    if not player.character then
        return
    end

    if shift then
        local count = rpg_t[player.index].points_to_distribute
        if not count then
            return
        end
        rpg_t[player.index].points_to_distribute = 0
        rpg_t[player.index][index] = rpg_t[player.index][index] + count
        if not rpg_t[player.index].reset then
            rpg_t[player.index].total = rpg_t[player.index].total + count
        end
        RPG_GUI.toggle(player, true)
        RPG_GUI.update_player_stats(player)
    elseif event.button == defines.mouse_button_type.right then
        for _ = 1, points_per_level, 1 do
            if rpg_t[player.index].points_to_distribute <= 0 then
                RPG_GUI.toggle(player, true)
                return
            end
            rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute - 1
            rpg_t[player.index][index] = rpg_t[player.index][index] + 1
            if not rpg_t[player.index].reset then
                rpg_t[player.index].total = rpg_t[player.index].total + 1
            end
            RPG_GUI.update_player_stats(player)
        end
        RPG_GUI.toggle(player, true)
        return
    end

    if rpg_t[player.index].points_to_distribute <= 0 then
        RPG_GUI.toggle(player, true)
        return
    end
    rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute - 1
    rpg_t[player.index][index] = rpg_t[player.index][index] + 1
    if not rpg_t[player.index].reset then
        rpg_t[player.index].total = rpg_t[player.index].total + 1
    end
    RPG_GUI.update_player_stats(player)
    RPG_GUI.toggle(player, true)
end

local function train_type_cause(cause)
    local players = {}
    if cause.train.passengers then
        for _, player in pairs(cause.train.passengers) do
            players[#players + 1] = player
        end
    end
    return players
end

local get_cause_player = {
    ['character'] = function(cause)
        if not cause.player then
            return
        end
        return {cause.player}
    end,
    ['combat-robot'] = function(cause)
        if not cause.last_user then
            return
        end
        if not game.players[cause.last_user.index] then
            return
        end
        return {game.players[cause.last_user.index]}
    end,
    ['car'] = function(cause)
        local players = {}
        local driver = cause.get_driver()
        if driver then
            if driver.player then
                players[#players + 1] = driver.player
            end
        end
        local passenger = cause.get_passenger()
        if passenger then
            if passenger.player then
                players[#players + 1] = passenger.player
            end
        end
        return players
    end,
    ['locomotive'] = train_type_cause,
    ['cargo-wagon'] = train_type_cause,
    ['artillery-wagon'] = train_type_cause,
    ['fluid-wagon'] = train_type_cause
}

local function on_entity_died(event)
    if not event.entity.valid then
        return
    end

    --Grant XP for hand placed land mines
    if event.entity.last_user then
        if event.entity.type == 'land-mine' then
            if event.cause then
                if event.cause.valid then
                    if event.cause.force.index == event.entity.force.index then
                        return
                    end
                end
            end
            Public.gain_xp(event.entity.last_user, 1)
            return
        end
    end

    local rpg_extra = RPG.get('rpg_extra')

    if rpg_extra.enable_wave_defense then
        if rpg_extra.rpg_xp_yield['big-biter'] <= 16 then
            local wave_number = WD.get_wave()
            if wave_number >= 1000 then
                rpg_extra.rpg_xp_yield['big-biter'] = 16
                rpg_extra.rpg_xp_yield['behemoth-biter'] = 64
            end
        end
    end

    if not event.cause then
        return
    end

    if not event.cause.valid then
        return
    end

    local type = event.cause.type
    if not type then
        goto continue
    end

    if event.cause.force.index == 1 then
        if die_cause[type] then
            if rpg_extra.rpg_xp_yield[event.entity.name] then
                local amount = rpg_extra.rpg_xp_yield[event.entity.name]
                amount = amount / 5
                if global.biter_health_boost then
                    local health_pool = global.biter_health_boost_units[event.entity.unit_number]
                    if health_pool then
                        amount = amount * (1 / health_pool[2])
                    end
                end

                if rpg_extra.turret_kills_to_global_pool then
                    add_to_global_pool(amount, false)
                end
            else
                add_to_global_pool(0.5, false)
            end
            return
        end
    end

    ::continue::

    if event.cause.force.index == event.entity.force.index then
        return
    end

    if not get_cause_player[event.cause.type] then
        return
    end

    local players = get_cause_player[event.cause.type](event.cause)
    if not players then
        return
    end
    if not players[1] then
        return
    end

    --Grant modified XP for health boosted units
    if global.biter_health_boost then
        if enemy_types[event.entity.type] then
            local health_pool = global.biter_health_boost_units[event.entity.unit_number]
            if health_pool then
                for _, player in pairs(players) do
                    if rpg_extra.rpg_xp_yield[event.entity.name] then
                        local amount = rpg_extra.rpg_xp_yield[event.entity.name] * (1 / health_pool[2])
                        if rpg_extra.turret_kills_to_global_pool then
                            local inserted = add_to_global_pool(amount, true)
                            Public.gain_xp(player, inserted, true)
                        else
                            Public.gain_xp(player, amount)
                        end
                    else
                        Public.gain_xp(player, 0.5 * (1 / health_pool[2]))
                    end
                end
                return
            end
        end
    end

    --Grant normal XP
    for _, player in pairs(players) do
        if rpg_extra.rpg_xp_yield[event.entity.name] then
            local amount = rpg_extra.rpg_xp_yield[event.entity.name]
            if rpg_extra.turret_kills_to_global_pool then
                local inserted = add_to_global_pool(amount, true)
                Public.gain_xp(player, inserted, true)
            else
                Public.gain_xp(player, amount)
            end
        else
            Public.gain_xp(player, 0.5)
        end
    end
end

local function regen_health_player(players)
    for i = 1, #players do
        local player = players[i]
        local heal_per_tick = Functions.get_heal_modifier(player)
        if heal_per_tick <= 0 then
            goto continue
        end
        heal_per_tick = math.round(heal_per_tick)
        if player and player.valid and not player.in_combat then
            if player.character and player.character.valid then
                player.character.health = player.character.health + heal_per_tick
            end
        end
        Functions.update_health(player)

        ::continue::
    end
end

local function regen_mana_player(players)
    for i = 1, #players do
        local player = players[i]
        local mana_per_tick = Functions.get_mana_modifier(player)
        local rpg_extra = RPG.get('rpg_extra')
        local rpg_t = RPG.get('rpg_t')
        if mana_per_tick <= 0.1 then
            mana_per_tick = rpg_extra.mana_per_tick
        end

        if rpg_extra.force_mana_per_tick then
            mana_per_tick = 1
        end

        if player and player.valid and not player.in_combat then
            if player.character and player.character.valid then
                if rpg_t[player.index].mana >= rpg_t[player.index].mana_max then
                    goto continue
                end
                rpg_t[player.index].mana = rpg_t[player.index].mana + mana_per_tick

                if rpg_t[player.index].mana >= rpg_t[player.index].mana_max then
                    rpg_t[player.index].mana = rpg_t[player.index].mana_max
                end
                rpg_t[player.index].mana = (math.round(rpg_t[player.index].mana * 10) / 10)
            end
        end

        Functions.update_mana(player)

        ::continue::
    end
end

local function give_player_flameboots(player)
    if not player.character then
        return
    end
    if player.character.driving then
        return
    end

    local rpg_t = RPG.get('rpg_t')

    if not rpg_t[player.index].mana then
        return
    end

    if not rpg_t[player.index].flame_boots then
        return
    end

    if rpg_t[player.index].mana <= 0 then
        player.print('Your flame boots have worn out.', {r = 0.22, g = 0.77, b = 0.44})
        rpg_t[player.index].flame_boots = false
        return
    end

    if rpg_t[player.index].mana % 500 == 0 then
        player.print('Mana remaining: ' .. rpg_t[player.index].mana, {r = 0.22, g = 0.77, b = 0.44})
    end

    local p = player.position

    player.surface.create_entity({name = 'fire-flame', position = p})

    rpg_t[player.index].mana = rpg_t[player.index].mana - 5
    if rpg_t[player.index].mana <= 0 then
        rpg_t[player.index].mana = 0
    end
    if player.gui.left[main_frame_name] then
        local f = player.gui.left[main_frame_name]
        local data = Gui.get_data(f)
        data.mana.caption = rpg_t[player.index].mana
    end
end

--Melee damage modifier
local function one_punch(character, target, damage)
    local base_vector = {target.position.x - character.position.x, target.position.y - character.position.y}

    local vector = {base_vector[1], base_vector[2]}
    vector[1] = vector[1] * 1000
    vector[2] = vector[2] * 1000

    character.surface.create_entity(
        {
            name = 'flying-text',
            position = {character.position.x + base_vector[1] * 0.5, character.position.y + base_vector[2] * 0.5},
            text = 'ONE PUNCH',
            color = {255, 0, 0}
        }
    )
    character.surface.create_entity({name = 'blood-explosion-huge', position = target.position})
    character.surface.create_entity(
        {
            name = 'big-artillery-explosion',
            position = {target.position.x + vector[1] * 0.5, target.position.y + vector[2] * 0.5}
        }
    )

    if math.abs(vector[1]) > math.abs(vector[2]) then
        local d = math.abs(vector[1])
        if math.abs(vector[1]) > 0 then
            vector[1] = vector[1] / d
        end
        if math.abs(vector[2]) > 0 then
            vector[2] = vector[2] / d
        end
    else
        local d = math.abs(vector[2])
        if math.abs(vector[2]) > 0 then
            vector[2] = vector[2] / d
        end
        if math.abs(vector[1]) > 0 and d > 0 then
            vector[1] = vector[1] / d
        end
    end

    vector[1] = vector[1] * 1.5
    vector[2] = vector[2] * 1.5

    local a = 0.25

    for i = 1, 16, 1 do
        for x = i * -1 * a, i * a, 1 do
            for y = i * -1 * a, i * a, 1 do
                local p = {character.position.x + x + vector[1] * i, character.position.y + y + vector[2] * i}
                character.surface.create_trivial_smoke({name = 'train-smoke', position = p})
                for _, e in pairs(character.surface.find_entities({{p[1] - a, p[2] - a}, {p[1] + a, p[2] + a}})) do
                    if e.valid then
                        if e.health then
                            if e.destructible and e.minable and e.force.index ~= 3 then
                                if e.force.index ~= character.force.index then
                                    e.health = e.health - damage * 0.05
                                    if e.health <= 0 then
                                        e.die(e.force.name, character)
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

local function on_entity_damaged(event)
    if not event.cause then
        return
    end
    if not event.cause.valid then
        return
    end
    if event.cause.force.index == 2 then
        return
    end
    if event.cause.name ~= 'character' then
        return
    end
    if event.damage_type.name ~= 'physical' then
        return
    end
    if not event.entity.valid then
        return
    end
    if
        event.cause.get_inventory(defines.inventory.character_ammo)[event.cause.selected_gun_index].valid_for_read and
            event.cause.get_inventory(defines.inventory.character_guns)[event.cause.selected_gun_index].valid_for_read
     then
        return
    end
    if not event.cause.player then
        return
    end

    --Grant the player life-on-hit.
    event.cause.health = event.cause.health + Functions.get_life_on_hit(event.cause.player)

    --Calculate modified damage.
    local damage =
        event.original_damage_amount + event.original_damage_amount * Functions.get_melee_modifier(event.cause.player)
    if event.entity.prototype.resistances then
        if event.entity.prototype.resistances.physical then
            damage = damage - event.entity.prototype.resistances.physical.decrease
            damage = damage - damage * event.entity.prototype.resistances.physical.percent
        end
    end
    damage = math.round(damage, 3)
    if damage < 1 then
        damage = 1
    end

    local enable_one_punch = RPG.get('rpg_extra').enable_one_punch
    local rpg_t = RPG.get('rpg_t')

    --Cause a one punch.
    if enable_one_punch then
        if rpg_t[event.cause.player.index].one_punch then
            if math.random(0, 999) < Functions.get_one_punch_chance(event.cause.player) * 10 then
                one_punch(event.cause, event.entity, damage)
                if event.entity.valid then
                    event.entity.die(event.entity.force.name, event.cause)
                end
                return
            end
        end
    end

    --Floating messages and particle effects.
    if math.random(1, 7) == 1 then
        damage = damage * math.random(250, 350) * 0.01
        event.cause.surface.create_entity(
            {
                name = 'flying-text',
                position = event.entity.position,
                text = '‼' .. math.floor(damage),
                color = {255, 0, 0}
            }
        )
        event.cause.surface.create_entity({name = 'blood-explosion-huge', position = event.entity.position})
    else
        damage = damage * math.random(100, 125) * 0.01
        event.cause.player.create_local_flying_text(
            {
                text = math.floor(damage),
                position = event.entity.position,
                color = {150, 150, 150},
                time_to_live = 90,
                speed = 2
            }
        )
    end

    --Handle the custom health pool of the biter health booster, if it is used in the map.
    if global.biter_health_boost then
        local health_pool = global.biter_health_boost_units[event.entity.unit_number]
        if health_pool then
            health_pool[1] = health_pool[1] + event.final_damage_amount
            health_pool[1] = health_pool[1] - damage

            --Set entity health relative to health pool
            event.entity.health = health_pool[1] * health_pool[2]

            if health_pool[1] <= 0 then
                local entity_number = event.entity.unit_number
                event.entity.die(event.entity.force.name, event.cause)
                global.biter_health_boost_units[entity_number] = nil
            end
            return
        end
    end

    --Handle vanilla damage.
    event.entity.health = event.entity.health + event.final_damage_amount
    event.entity.health = event.entity.health - damage
    if event.entity.health <= 0 then
        event.entity.die(event.entity.force.name, event.cause)
    end
end

local function on_player_repaired_entity(event)
    if math.random(1, 4) ~= 1 then
        return
    end

    local entity = event.entity

    if not entity then
        return
    end

    if not entity.valid then
        return
    end

    if not entity.health then
        return
    end

    local player = game.players[event.player_index]

    if not player.character then
        return
    end
    Public.gain_xp(player, 0.05)

    local repair_speed = Public.get_magicka(player)
    if repair_speed <= 0 then
        return
    end
    entity.health = entity.health + repair_speed
end

local function on_player_rotated_entity(event)
    local player = game.players[event.player_index]
    if not player.character then
        return
    end
    local rpg_t = RPG.get('rpg_t')
    if rpg_t[player.index].rotated_entity_delay > game.tick then
        return
    end
    rpg_t[player.index].rotated_entity_delay = game.tick + 20
    Public.gain_xp(player, 0.20)
end

local function on_player_changed_position(event)
    local player = game.players[event.player_index]
    local surface_name = RPG.get('rpg_extra').surface_name
    if string.sub(player.surface.name, 0, #surface_name) ~= surface_name then
        return
    end

    local enable_flame_boots = RPG.get('rpg_extra').enable_flame_boots

    if enable_flame_boots then
        give_player_flameboots(player)
    end

    if math.random(1, 64) ~= 1 then
        return
    end
    if not player.character then
        return
    end
    if player.character.driving then
        return
    end
    Public.gain_xp(player, 1.0)
end

local building_and_mining_blacklist = {
    ['tile-ghost'] = true,
    ['entity-ghost'] = true,
    ['item-entity'] = true
}

local function on_pre_player_mined_item(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    if building_and_mining_blacklist[entity.type] then
        return
    end
    if entity.force.index ~= 3 then
        return
    end
    local player = game.players[event.player_index]
    local rpg_t = RPG.get('rpg_t')
    if
        rpg_t[player.index].last_mined_entity_position.x == event.entity.position.x and
            rpg_t[player.index].last_mined_entity_position.y == event.entity.position.y
     then
        return
    end
    rpg_t[player.index].last_mined_entity_position.x = entity.position.x
    rpg_t[player.index].last_mined_entity_position.y = entity.position.y

    local distance_multiplier = math.floor(math.sqrt(entity.position.x ^ 2 + entity.position.y ^ 2)) * 0.0005 + 1

    local xp_amount
    if entity.type == 'resource' then
        xp_amount = 0.5 * distance_multiplier
    else
        xp_amount = (1.5 + event.entity.prototype.max_health * 0.0035) * distance_multiplier
    end

    Public.gain_xp(player, xp_amount)
end

local function on_player_crafted_item(event)
    if not event.recipe.energy then
        return
    end
    local player = game.players[event.player_index]
    if not player.valid then
        return
    end

    if player.cheat_mode then
        return
    end

    local amount = 0.30 * math.random(1, 2)

    Public.gain_xp(player, event.recipe.energy * amount)
end

local function on_player_respawned(event)
    local player = game.players[event.player_index]
    local rpg_t = RPG.get('rpg_t')
    if not rpg_t[player.index] then
        Public.rpg_reset_player(player)
        return
    end
    RPG_GUI.update_player_stats(player)
    RPG_GUI.draw_level_text(player)
    Functions.update_health(player)
    Functions.update_mana(player)
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    local rpg_t = RPG.get('rpg_t')
    local rpg_extra = RPG.get('rpg_extra')
    if not rpg_t[player.index] then
        Public.rpg_reset_player(player)
        if rpg_extra.reward_new_players > 10 then
            Public.gain_xp(player, rpg_extra.reward_new_players)
        end
    end
    for _, p in pairs(game.connected_players) do
        RPG_GUI.draw_level_text(p)
    end
    RPG_GUI.draw_gui_char_button(player)
    if not player.character then
        return
    end
    RPG_GUI.update_player_stats(player)
end

local function create_projectile(surface, name, position, force, target, max_range)
    if max_range then
        surface.create_entity(
            {
                name = name,
                position = position,
                force = force,
                source = position,
                target = target,
                max_range = max_range,
                speed = 0.4
            }
        )
    else
        surface.create_entity(
            {
                name = name,
                position = position,
                force = force,
                source = position,
                target = target,
                speed = 0.4
            }
        )
    end
end

local function get_near_coord_modifier(range)
    local coord = {x = (range * -1) + math.random(0, range * 2), y = (range * -1) + math.random(0, range * 2)}
    for i = 1, 5, 1 do
        local new_coord = {x = (range * -1) + math.random(0, range * 2), y = (range * -1) + math.random(0, range * 2)}
        if new_coord.x ^ 2 + new_coord.y ^ 2 < coord.x ^ 2 + coord.y ^ 2 then
            coord = new_coord
        end
    end
    return coord
end

local function damage_entity(e)
    if not e.health then
        return
    end

    if e.force.name == 'player' then
        return
    end

    e.surface.create_entity({name = 'water-splash', position = e.position})

    if e.type == 'entity-ghost' then
        e.destroy()
        return
    end

    e.health = e.health - math.random(30, 90)
    if e.health <= 0 then
        e.die('enemy')
    end
end

local function floaty_hearts(entity, c)
    local position = {x = entity.position.x - 0.75, y = entity.position.y - 1}
    local b = 1.35
    for _ = 1, c, 1 do
        local p = {
            (position.x + 0.4) + (b * -1 + math.random(0, b * 20) * 0.1),
            position.y + (b * -1 + math.random(0, b * 20) * 0.1)
        }
        entity.surface.create_entity(
            {name = 'flying-text', position = p, text = '♥', color = {math.random(150, 255), 0, 255}}
        )
    end
end

local function tame_unit_effects(player, entity)
    floaty_hearts(entity, 7)

    rendering.draw_text {
        text = '~' .. player.name .. "'s pet~",
        surface = player.surface,
        target = entity,
        target_offset = {0, -2.6},
        color = {
            r = player.color.r * 0.6 + 0.25,
            g = player.color.g * 0.6 + 0.25,
            b = player.color.b * 0.6 + 0.25,
            a = 1
        },
        scale = 1.05,
        font = 'default-large-semibold',
        alignment = 'center',
        scale_with_zoom = false
    }
end

local function on_player_used_capsule(event)
    local enable_mana = RPG.get('rpg_extra').enable_mana
    local surface_name = RPG.get('rpg_extra').surface_name
    if not enable_mana then
        return
    end

    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    if string.sub(player.surface.name, 0, #surface_name) ~= surface_name then
        return
    end

    local item = event.item

    if not item then
        return
    end

    local name = item.name

    if name ~= 'raw-fish' then
        return
    end

    local rpg_t = RPG.get('rpg_t')

    if not rpg_t[player.index].enable_entity_spawn then
        return
    end

    local p = player.print

    if rpg_t[player.index].last_spawned >= game.tick then
        return p(
            'There was a lot more to magic, as ' ..
                player.name .. ' quickly found out, than waving their wand and saying a few funny words.',
            Color.warning
        )
    end

    local mana = rpg_t[player.index].mana
    local surface = player.surface

    local object = conjure_items[rpg_t[player.index].dropdown_select_index]
    if not object then
        return
    end

    if rpg_t[player.index].level <= object.level then
        return p('You lack the level to cast this spell.', Color.fail)
    end

    local object_name = object.name
    local obj_name = object.obj_to_create

    local position = event.position
    if not position then
        return
    end

    local radius = 15
    local area = {
        left_top = {x = position.x - radius, y = position.y - radius},
        right_bottom = {x = position.x + radius, y = position.y + radius}
    }

    if not Math2D.bounding_box.contains_point(area, player.position) then
        player.print('You wave your wand but realize that it´s out of reach.', Color.fail)
        return
    end

    if mana <= object.mana_cost then
        return p('You don´t have enough mana to cast this spell.', Color.fail)
    else
        rpg_t[player.index].mana = rpg_t[player.index].mana - object.mana_cost
    end

    local target_pos
    if object.target then
        target_pos = {position.x, position.y}
    elseif projectile_types[obj_name] then
        local coord_modifier = get_near_coord_modifier(projectile_types[obj_name].max_range)
        local proj_pos = {position.x + coord_modifier.x, position.y + coord_modifier.y}
        target_pos = proj_pos
    end

    local range
    if object.range then
        range = object.range
    else
        range = 0
    end

    local force
    if object.force then
        force = object.force
    else
        force = 'player'
    end
    if object.obj_to_create == 'suicidal_comfylatron' then
        Functions.suicidal_comfylatron(position, surface)
    elseif projectile_types[obj_name] then
        for i = 1, object.amount do
            local damage_area = {
                left_top = {x = position.x - 2, y = position.y - 2},
                right_bottom = {x = position.x + 2, y = position.y + 2}
            }
            create_projectile(surface, obj_name, position, force, target_pos, range)
            if object.damage then
                for _, e in pairs(surface.find_entities_filtered({area = damage_area})) do
                    damage_entity(e)
                end
            end
        end
    else
        if object.target then
            surface.create_entity({name = obj_name, position = position, force = force, target = target_pos, speed = 1})
        elseif object.obj_to_create == 'fish' then
            player.insert({name = 'raw-fish', count = object.amount})
        elseif surface.can_place_entity {name = obj_name, position = position} then
            if object.biter then
                local e = surface.create_entity({name = obj_name, position = position, force = force})
                tame_unit_effects(player, e)
            else
                surface.create_entity({name = obj_name, position = position, force = force})
            end
        else
            p('Can´t create entity at given location.', Color.fail)
            return
        end
    end

    rpg_t[player.index].last_spawned = game.tick + object.tick
    Functions.update_mana(player)

    return p('You wave your wand and ' .. object_name .. ' appears.', Color.success)
end

local function tick()
    local ticker = game.tick
    local count = #game.connected_players
    local players = game.connected_players
    local enable_flameboots = RPG.get('rpg_extra').enable_flameboots
    local enable_mana = RPG.get('rpg_extra').enable_mana

    if ticker % nth_tick == 0 then
        global_pool(players, count)
    end

    if ticker % 30 == 0 then
        regen_health_player(players)
        if enable_mana then
            regen_mana_player(players)
        end
        if enable_flameboots then
            give_player_flameboots(players)
        end
    end
end

--- Gives connected player some bonus xp if the map was preemptively shut down.
-- amount (integer) -- 10 levels
-- local Public = require 'modules.rpg_v2' Public.give_xp(512)
function Public.give_xp(amount)
    for _, player in pairs(game.connected_players) do
        if not Functions.validate_player(player) then
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
    local rpg_t = RPG.get('rpg_t')
    local rpg_extra = RPG.get('rpg_extra')
    if one_time_reset then
        local total = rpg_t[player.index].total
        if not total then
            total = 0
        end
        local old_level = rpg_t[player.index].level
        local old_points_to_distribute = rpg_t[player.index].points_to_distribute
        local old_xp = rpg_t[player.index].xp
        rpg_t[player.index] = {
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
            flame_boots = false,
            enable_entity_spawn = false,
            health_bar = rpg_t[player.index].health_bar,
            mana_bar = rpg_t[player.index].mana_bar,
            points_to_distribute = 0,
            last_floaty_text = visuals_delay,
            xp_since_last_floaty_text = 0,
            reset = true,
            capped = false,
            bonus = rpg_extra.breached_walls or 1,
            rotated_entity_delay = 0,
            last_mined_entity_position = {x = 0, y = 0},
            show_bars = false,
            stone_path = false,
            one_punch = false
        }
        rpg_t[player.index].points_to_distribute = old_points_to_distribute + total
        rpg_t[player.index].xp = old_xp
        rpg_t[player.index].level = old_level
    else
        rpg_t[player.index] = {
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
            flame_boots = false,
            enable_entity_spawn = false,
            points_to_distribute = 0,
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
            one_punch = false
        }
    end
    RPG_GUI.draw_gui_char_button(player)
    RPG_GUI.draw_level_text(player)
    RPG_GUI.update_char_button(player)
    RPG_GUI.update_player_stats(player)
end

function Public.rpg_reset_all_players()
    local rpg_t = RPG.get('rpg_t')
    local rpg_extra = RPG.get('rpg_extra')
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
    if not Functions.validate_player(player) then
        return
    end
    local rpg_extra = RPG.get('rpg_extra')
    local rpg_t = RPG.get('rpg_t')

    if Functions.level_limit_exceeded(player) then
        add_to_global_pool(amount, false)
        if not rpg_t[player.index].capped then
            rpg_t[player.index].capped = true
            local message = teller_level_limit .. 'You have hit the max level for the current zone.'
            Alert.alert_player_warning(player, 10, message)
        end
        return
    end

    local text_to_draw

    if rpg_t[player.index].capped then
        rpg_t[player.index].capped = false
    end

    if not added_to_pool then
        RPG.debug_log('RPG - ' .. player.name .. ' got org xp: ' .. amount)
        local fee = amount - add_to_global_pool(amount, true)
        RPG.debug_log('RPG - ' .. player.name .. ' got fee: ' .. fee)
        amount = math.round(amount, 3) - fee
        if rpg_extra.difficulty then
            amount = amount + rpg_extra.difficulty
        end
        RPG.debug_log('RPG - ' .. player.name .. ' got after fee: ' .. amount)
    else
        RPG.debug_log('RPG - ' .. player.name .. ' got org xp: ' .. amount)
    end

    rpg_t[player.index].xp = rpg_t[player.index].xp + amount
    rpg_t[player.index].xp_since_last_floaty_text = rpg_t[player.index].xp_since_last_floaty_text + amount

    if player.gui.left[main_frame_name] then
        local f = player.gui.left[main_frame_name]
        local data = Gui.get_data(f)
        Gui.set_data(f, data)
    end

    if not experience_levels[rpg_t[player.index].level + 1] then
        return
    end

    if rpg_t[player.index].xp >= experience_levels[rpg_t[player.index].level + 1] then
        level_up(player)
    end

    if rpg_t[player.index].last_floaty_text > game.tick then
        if not text then
            return
        end
    end

    if text then
        text_to_draw = '+' .. math.floor(amount) .. ' xp'
    else
        text_to_draw = '+' .. math.floor(rpg_t[player.index].xp_since_last_floaty_text) .. ' xp'
    end

    player.create_local_flying_text {
        text = text_to_draw,
        position = player.position,
        color = xp_floating_text_color,
        time_to_live = 340,
        speed = 2
    }

    rpg_t[player.index].xp_since_last_floaty_text = 0
    rpg_t[player.index].last_floaty_text = game.tick + visuals_delay
end

--- Distributes the global xp pool to every connected player.
function Public.distribute_pool()
    local count = #game.connected_players
    local players = game.connected_players
    global_pool(players, count)
    print('Distributed the global XP pool')
end

--- Pass along the main_button and main_frame
Public.main_frame_name = main_frame_name
Public.draw_main_frame_name = draw_main_frame_name
Public.settings_frame_name = Settings.settings_frame_name

if _DEBUG then
    commands.add_command(
        'give_xp',
        'DEBUG ONLY - if you are seeing this then this map is running on debug-mode.',
        function(cmd)
            local p
            local player = game.player
            local param = tonumber(cmd.parameter)

            if player then
                if player ~= nil then
                    p = player.print
                    if not player.admin then
                        p("[ERROR] You're not admin!", Color.fail)
                        return
                    end
                    if not param then
                        return
                    end
                    p('Distributed ' .. param .. ' of xp.')
                    Public.give_xp(param)
                end
            end
        end
    )
end

Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_player_crafted_item, on_player_crafted_item)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_rotated_entity, on_player_rotated_entity)
Event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)
Event.add(defines.events.on_player_used_capsule, on_player_used_capsule)
Event.on_nth_tick(10, tick)

return Public
