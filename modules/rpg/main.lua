--RPG Modules
local Public = require 'modules.rpg.core'
local Gui = require 'utils.gui'
local Event = require 'utils.event'
local AntiGrief = require 'antigrief'
local Color = require 'utils.color_presets'
local SpamProtection = require 'utils.spam_protection'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local Explosives = require 'modules.explosives'

local WD = require 'modules.wave_defense.table'
local Math2D = require 'math2d'

--RPG Settings
local enemy_types = Public.enemy_types
local die_cause = Public.die_cause
local points_per_level = Public.points_per_level
local nth_tick = Public.nth_tick

--RPG Frames
local main_frame_name = Public.main_frame_name

local sub = string.sub

local function on_gui_click(event)
    if not event then
        return
    end
    local player = game.players[event.player_index]
    if not (player and player.valid) then
        return
    end

    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    local element = event.element
    if player.gui.screen[main_frame_name] then
        local is_spamming = SpamProtection.is_spamming(player, nil, 'RPG Gui Click')
        if is_spamming then
            return
        end
    end

    local surface_name = Public.get('rpg_extra').surface_name
    if sub(player.surface.name, 0, #surface_name) ~= surface_name then
        return
    end

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

    local rpg_t = Public.get_value_from_player(player.index)

    local index = element.name
    if not rpg_t[index] then
        return
    end
    if not player.character then
        return
    end

    if shift then
        local count = rpg_t.points_left
        if not count then
            return
        end
        rpg_t.points_left = 0
        rpg_t[index] = rpg_t[index] + count
        if not rpg_t.reset then
            rpg_t.total = rpg_t.total + count
        end
        Public.toggle(player, true)
        Public.update_player_stats(player)
    elseif event.button == defines.mouse_button_type.right then
        for _ = 1, points_per_level, 1 do
            if rpg_t.points_left <= 0 then
                Public.toggle(player, true)
                return
            end
            rpg_t.points_left = rpg_t.points_left - 1
            rpg_t[index] = rpg_t[index] + 1
            if not rpg_t.reset then
                rpg_t.total = rpg_t.total + 1
            end
            Public.update_player_stats(player)
        end
        Public.toggle(player, true)
        return
    end

    if rpg_t.points_left <= 0 then
        Public.toggle(player, true)
        return
    end
    rpg_t.points_left = rpg_t.points_left - 1
    rpg_t[index] = rpg_t[index] + 1
    if not rpg_t.reset then
        rpg_t.total = rpg_t.total + 1
    end
    Public.update_player_stats(player)
    Public.toggle(player, true)
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
    ['spider-vehicle'] = function(cause)
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
    if not event.entity or not event.entity.valid then
        return
    end

    local entity = event.entity

    --Grant XP for hand placed land mines
    if entity.last_user then
        if entity.type == 'land-mine' then
            if event.cause then
                if event.cause.valid then
                    if event.cause.force.index == entity.force.index then
                        return
                    end
                end
            end
            Public.gain_xp(entity.last_user, 1)
            Public.reward_mana(entity.last_user, 1)
            return
        end
    end

    local rpg_extra = Public.get('rpg_extra')

    if rpg_extra.enable_wave_defense then
        if rpg_extra.rpg_xp_yield['big-biter'] <= 16 then
            local wave_number = WD.get_wave()
            if wave_number >= 1000 then
                rpg_extra.rpg_xp_yield['big-biter'] = 16
                rpg_extra.rpg_xp_yield['behemoth-biter'] = 64
            end
        end
    end

    local biter_health_boost = BiterHealthBooster.get('biter_health_boost')
    local biter_health_boost_units = BiterHealthBooster.get('biter_health_boost_units')

    if not event.cause or not event.cause.valid then
        return
    end

    local cause = event.cause
    local type = cause.type
    if not type then
        goto continue
    end

    if cause.force.index == 1 then
        if die_cause[type] then
            if rpg_extra.rpg_xp_yield[entity.name] then
                local amount = rpg_extra.rpg_xp_yield[entity.name]
                amount = amount / 5
                if biter_health_boost then
                    local health_pool = biter_health_boost_units[entity.unit_number]
                    if health_pool then
                        amount = amount * (1 / health_pool[2])
                    end
                end

                if rpg_extra.turret_kills_to_global_pool then
                    Public.add_to_global_pool(amount, false)
                end
            else
                Public.add_to_global_pool(0.5, false)
            end
            return
        end
    end

    ::continue::

    if cause.force.index == entity.force.index then
        return
    end

    if not get_cause_player[cause.type] then
        return
    end

    local players = get_cause_player[cause.type](cause)
    if not players then
        return
    end
    if not players[1] then
        return
    end

    --Grant modified XP for health boosted units
    if biter_health_boost then
        if enemy_types[entity.type] then
            local health_pool = biter_health_boost_units[entity.unit_number]
            if health_pool then
                for _, player in pairs(players) do
                    if rpg_extra.rpg_xp_yield[entity.name] then
                        local amount = rpg_extra.rpg_xp_yield[entity.name] * (1 / health_pool[2])
                        if amount < rpg_extra.rpg_xp_yield[entity.name] then
                            amount = rpg_extra.rpg_xp_yield[entity.name]
                        end
                        if rpg_extra.turret_kills_to_global_pool then
                            local inserted = Public.add_to_global_pool(amount, true)
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
        if rpg_extra.rpg_xp_yield[entity.name] then
            local amount = rpg_extra.rpg_xp_yield[entity.name]
            if rpg_extra.turret_kills_to_global_pool then
                local inserted = Public.add_to_global_pool(amount, true)
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
        local heal_per_tick = Public.get_heal_modifier(player)
        if heal_per_tick <= 0 then
            goto continue
        end
        heal_per_tick = math.round(heal_per_tick)
        if player and player.valid and not player.in_combat then
            if player.character and player.character.valid then
                player.character.health = player.character.health + heal_per_tick
            end
        end

        ::continue::

        Public.update_health(player)
    end
end

local function regen_mana_player(players)
    for i = 1, #players do
        local player = players[i]
        local mana_per_tick = Public.get_mana_modifier(player)
        local rpg_extra = Public.get('rpg_extra')
        local rpg_t = Public.get_value_from_player(player.index)
        if mana_per_tick <= 0.1 then
            mana_per_tick = rpg_extra.mana_per_tick
        end

        if rpg_extra.force_mana_per_tick then
            mana_per_tick = 1
        end

        if player and player.valid and not player.in_combat then
            if player.character and player.character.valid then
                if rpg_t.mana < 0 then
                    rpg_t.mana = 0
                end
                if rpg_t.mana >= rpg_t.mana_max then
                    goto continue
                end
                rpg_t.mana = rpg_t.mana + mana_per_tick
                if rpg_t.mana >= rpg_t.mana_max then
                    rpg_t.mana = rpg_t.mana_max
                end
                rpg_t.mana = (math.round(rpg_t.mana * 10) / 10)
            end
        end

        ::continue::

        Public.update_mana(player)
    end
end

local function give_player_flameboots(player)
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_t then
        return
    end

    if not rpg_t.flame_boots then
        return
    end

    if not player.character then
        return
    end
    if player.character.driving then
        return
    end

    if not rpg_t.mana then
        return
    end

    if rpg_t.mana <= 0 then
        player.print(({'rpg_main.flame_boots_worn_out'}), {r = 0.22, g = 0.77, b = 0.44})
        rpg_t.flame_boots = false
        return
    end

    if rpg_t.mana % 500 == 0 then
        player.print(({'rpg_main.flame_mana_remaining', rpg_t.mana}), {r = 0.22, g = 0.77, b = 0.44})
    end

    local p = player.position

    player.surface.create_entity({name = 'fire-flame', position = p})

    rpg_t.mana = rpg_t.mana - 5
    if rpg_t.mana <= 0 then
        rpg_t.mana = 0
    end
    if player.gui.screen[main_frame_name] then
        local f = player.gui.screen[main_frame_name]
        local data = Gui.get_data(f)
        if data.mana and data.mana.valid then
            data.mana.caption = rpg_t.mana
        end
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
            text = ({'rpg_main.one_punch_text'}),
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

local function is_position_near(area, entity)
    local status = false

    local function inside(pos)
        local lt = area.left_top
        local rb = area.right_bottom

        return pos.x >= lt.x and pos.y >= lt.y and pos.x <= rb.x and pos.y <= rb.y
    end

    if inside(entity, area) then
        status = true
    end

    return status
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

    local entity = event.entity
    local cause = event.cause

    if
        cause.get_inventory(defines.inventory.character_ammo)[cause.selected_gun_index].valid_for_read or
            cause.get_inventory(defines.inventory.character_guns)[cause.selected_gun_index].valid_for_read
     then
        local is_explosive_bullets_enabled = Public.get_explosive_bullets()
        if is_explosive_bullets_enabled then
            Public.explosive_bullets(event)
        end
        return
    end
    if not cause.player then
        return
    end

    local p = cause.player

    local surface_name = Public.get('rpg_extra').surface_name
    if sub(p.surface.name, 0, #surface_name) ~= surface_name then
        return
    end

    if entity.force.index == cause.force.index then
        return
    end

    local position = p.position

    local area = {
        left_top = {x = position.x - 5, y = position.y - 5},
        right_bottom = {x = position.x + 5, y = position.y + 5}
    }

    if not is_position_near(area, entity.position) then
        return
    end

    local item = p.cursor_stack

    if item and item.valid_for_read then
        if item.name == 'discharge-defense-remote' then
            return
        end
    end

    Public.reward_mana(cause.player, 2)

    --Grant the player life-on-hit.
    cause.health = cause.health + Public.get_life_on_hit(cause.player)

    --Calculate modified damage.
    local damage = event.original_damage_amount + event.original_damage_amount * Public.get_melee_modifier(cause.player)
    if entity.prototype.resistances then
        if entity.prototype.resistances.physical then
            damage = damage - entity.prototype.resistances.physical.decrease
            damage = damage - damage * entity.prototype.resistances.physical.percent
        end
    end
    damage = math.round(damage, 3)
    if damage < 1 then
        damage = 1
    end

    local enable_one_punch = Public.get('rpg_extra').enable_one_punch
    local rpg_t = Public.get_value_from_player(cause.player.index)

    --Cause a one punch.
    if enable_one_punch then
        if rpg_t.one_punch then
            if math.random(0, 999) < Public.get_one_punch_chance(cause.player) * 10 then
                one_punch(cause, entity, damage)
                if entity.valid then
                    entity.die(entity.force.name, cause)
                end
                return
            end
        end
    end

    --Floating messages and particle effects.
    if math.random(1, 7) == 1 then
        damage = damage * math.random(250, 350) * 0.01
        cause.surface.create_entity(
            {
                name = 'flying-text',
                position = entity.position,
                text = '‼' .. math.floor(damage),
                color = {255, 0, 0}
            }
        )
        cause.surface.create_entity({name = 'blood-explosion-huge', position = entity.position})
    else
        damage = damage * math.random(100, 125) * 0.01
        cause.player.create_local_flying_text(
            {
                text = math.floor(damage),
                position = entity.position,
                color = {150, 150, 150},
                time_to_live = 90,
                speed = 2
            }
        )
    end

    local biter_health_boost = BiterHealthBooster.get('biter_health_boost')
    local biter_health_boost_units = BiterHealthBooster.get('biter_health_boost_units')

    --Handle the custom health pool of the biter health booster, if it is used in the map.
    if biter_health_boost then
        local health_pool = biter_health_boost_units[entity.unit_number]
        if health_pool then
            health_pool[1] = health_pool[1] + event.final_damage_amount
            health_pool[1] = health_pool[1] - damage

            --Set entity health relative to health pool
            entity.health = health_pool[1] * health_pool[2]

            if health_pool[1] <= 0 then
                local entity_number = entity.unit_number
                entity.die(entity.force.name, cause)

                if biter_health_boost_units[entity_number] then
                    biter_health_boost_units[entity_number] = nil
                end
            end
            return
        end
    end

    --Handle vanilla damage.
    entity.health = entity.health + event.final_damage_amount
    entity.health = entity.health - damage
    if entity.health <= 0 then
        entity.die(cause.force.name, cause)
    end

    local is_explosive_bullets_enabled = Public.get_explosive_bullets()
    if is_explosive_bullets_enabled then
        Public.explosive_bullets(event)
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

    if not player or not player.valid or not player.character then
        return
    end

    Public.gain_xp(player, 0.05)
    Public.reward_mana(player, 0.2)

    local repair_speed = Public.get_magicka(player)
    if repair_speed <= 0 then
        return
    end
    entity.health = entity.health + repair_speed
end

local function on_player_rotated_entity(event)
    local player = game.players[event.player_index]

    if not player or not player.valid then
        return
    end
    if not player.character then
        return
    end

    local rpg_t = Public.get_value_from_player(player.index)
    if rpg_t.rotated_entity_delay > game.tick then
        return
    end
    rpg_t.rotated_entity_delay = game.tick + 20
    Public.gain_xp(player, 0.20)
end

local function on_player_changed_position(event)
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    local enable_flame_boots = Public.get('rpg_extra').enable_flame_boots

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

local function on_player_died(event)
    local player = game.players[event.player_index]

    if not player or not player.valid then
        return
    end

    Public.remove_frame(player)
end

local function on_pre_player_left_game(event)
    local player = game.players[event.player_index]

    if not player or not player.valid then
        return
    end

    Public.remove_frame(player)
end

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

    if not player or not player.valid then
        return
    end

    local surface_name = Public.get('rpg_extra').surface_name
    if sub(player.surface.name, 0, #surface_name) ~= surface_name then
        return
    end

    local rpg_t = Public.get_value_from_player(player.index)
    if rpg_t.last_mined_entity_position.x == event.entity.position.x and rpg_t.last_mined_entity_position.y == event.entity.position.y then
        return
    end
    rpg_t.last_mined_entity_position.x = entity.position.x
    rpg_t.last_mined_entity_position.y = entity.position.y

    local distance_multiplier = math.floor(math.sqrt(entity.position.x ^ 2 + entity.position.y ^ 2)) * 0.0005 + 1

    local xp_amount
    if entity.type == 'resource' then
        xp_amount = 0.5 * distance_multiplier
    else
        xp_amount = (1.5 + event.entity.prototype.max_health * 0.0035) * distance_multiplier
    end

    if player.gui.screen[main_frame_name] then
        local f = player.gui.screen[main_frame_name]
        local data = Gui.get_data(f)
        if data.exp_gui and data.exp_gui.valid then
            data.exp_gui.caption = math.floor(rpg_t.xp)
        end
    end

    Public.gain_xp(player, xp_amount)
    Public.reward_mana(player, 0.5 * distance_multiplier)
end

local function on_player_crafted_item(event)
    if not event.recipe.energy then
        return
    end
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    if player.cheat_mode then
        return
    end

    local rpg_extra = Public.get('rpg_extra')
    local is_blacklisted = rpg_extra.tweaked_crafting_items
    local tweaked_crafting_items_enabled = rpg_extra.tweaked_crafting_items_enabled

    local item = event.item_stack

    local amount = 0.30 * math.random(1, 2)

    if tweaked_crafting_items_enabled then
        if item and item.valid then
            if is_blacklisted[item.name] then
                amount = 0.2
            end
        end
    end

    Public.gain_xp(player, event.recipe.energy * amount)
    Public.reward_mana(player, amount)
end

local function on_player_respawned(event)
    local player = game.players[event.player_index]
    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_t then
        Public.rpg_reset_player(player)
        return
    end
    Public.update_player_stats(player)
    Public.draw_level_text(player)
    Public.update_health(player)
    Public.update_mana(player)
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    local rpg_t = Public.get_value_from_player(player.index)
    local rpg_extra = Public.get('rpg_extra')
    if not rpg_t then
        Public.rpg_reset_player(player)
        if rpg_extra.reward_new_players > 10 then
            Public.gain_xp(player, rpg_extra.reward_new_players)
        end
    end
    for _, p in pairs(game.connected_players) do
        Public.draw_level_text(p)
    end
    Public.draw_gui_char_button(player)
    if not player.character then
        return
    end
    Public.update_player_stats(player)
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
    if not e or not e.valid then
        return
    end

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
        entity.surface.create_entity({name = 'flying-text', position = p, text = '♥', color = {math.random(150, 255), 0, 255}})
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
    local enable_mana = Public.get('rpg_extra').enable_mana
    local surface_name = Public.get('rpg_extra').surface_name
    if not enable_mana then
        return
    end

    local conjure_items = Public.get_spells()
    local projectile_types = Public.get_projectiles

    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    if not player.character or not player.character.valid then
        return
    end

    if sub(player.surface.name, 0, #surface_name) ~= surface_name then
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

    local rpg_t = Public.get_value_from_player(player.index)

    if not rpg_t.enable_entity_spawn then
        return
    end

    local p = player.print

    if rpg_t.last_spawned >= game.tick then
        return p(({'rpg_main.mana_casting_too_fast', player.name}), Color.warning)
    end

    local mana = rpg_t.mana
    local surface = player.surface

    local object = conjure_items[rpg_t.dropdown_select_index]
    if not object then
        return
    end

    local position = event.position
    if not position then
        return
    end

    local radius = 15
    local area = {
        left_top = {x = position.x - radius, y = position.y - radius},
        right_bottom = {x = position.x + radius, y = position.y + radius}
    }

    if rpg_t.level < object.level then
        return p(({'rpg_main.low_level'}), Color.fail)
    end

    if not object.enabled then
        return
    end

    local obj_name = object.obj_to_create

    if not Math2D.bounding_box.contains_point(area, player.position) then
        player.print(({'rpg_main.not_inside_pos'}), Color.fail)
        return
    end

    if mana < object.mana_cost then
        return p(({'rpg_main.no_mana'}), Color.fail)
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
    if obj_name == 'suicidal_comfylatron' then
        Public.suicidal_comfylatron(position, surface)
        p(({'rpg_main.suicidal_comfylatron', 'Suicidal Comfylatron'}), Color.success)
        rpg_t.mana = rpg_t.mana - object.mana_cost
    elseif obj_name == 'repair_aoe' then
        local ents = Public.repair_aoe(player, position)
        p(({'rpg_main.repair_aoe', ents}), Color.success)
        rpg_t.mana = rpg_t.mana - object.mana_cost
    elseif obj_name == 'pointy_explosives' then
        local entities =
            player.surface.find_entities_filtered {force = player.force, type = 'container', area = {{position.x - 1, position.y - 1}, {position.x + 1, position.y + 1}}}

        local detonate_chest
        for i = 1, #entities do
            local e = entities[i]
            detonate_chest = e
        end
        if detonate_chest and detonate_chest.valid then
            local success = Explosives.detonate_chest(detonate_chest)
            if success then
                player.print(({'rpg_main.detonate_chest'}), Color.success)
                rpg_t.mana = rpg_t.mana - object.mana_cost
            else
                player.print(({'rpg_main.detonate_chest_failed'}), Color.fail)
            end
        end
    elseif obj_name == 'warp-gate' then
        player.teleport(surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5), surface)
        rpg_t.mana = 0
        Public.damage_player_over_time(player, math.random(8, 16))
        player.play_sound {path = 'utility/armor_insert', volume_modifier = 1}
        p(({'rpg_main.warped_ok'}), Color.info)
        rpg_t.mana = rpg_t.mana - object.mana_cost
    elseif obj_name == 'fish' then -- spawn in some fish
        player.insert({name = 'raw-fish', count = object.amount})
        p(({'rpg_main.object_spawned', 'raw-fish'}), Color.success)
        rpg_t.mana = rpg_t.mana - object.mana_cost
    elseif projectile_types[obj_name] then -- projectiles
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
        p(({'rpg_main.object_spawned', obj_name}), Color.success)
        rpg_t.mana = rpg_t.mana - object.mana_cost
    else
        if object.target then -- rockets and such
            surface.create_entity({name = obj_name, position = position, force = force, target = target_pos, speed = 1})
            p(({'rpg_main.object_spawned', obj_name}), Color.success)
            rpg_t.mana = rpg_t.mana - object.mana_cost
        elseif surface.can_place_entity {name = obj_name, position = position} then
            if object.biter then
                local e = surface.create_entity({name = obj_name, position = position, force = force})
                tame_unit_effects(player, e)
            elseif object.aoe then
                for x = 1, -1, -1 do
                    for y = 1, -1, -1 do
                        local pos = {x = position.x + x, y = position.y + y}
                        if surface.can_place_entity {name = obj_name, position = pos} then
                            if object.mana_cost > rpg_t.mana then
                                break
                            end
                            local e = surface.create_entity({name = obj_name, position = pos, force = force})
                            e.direction = player.character.direction
                            rpg_t.mana = rpg_t.mana - object.mana_cost
                        end
                    end
                end
            else
                local e = surface.create_entity({name = obj_name, position = position, force = force})
                e.direction = player.character.direction
            end
            p(({'rpg_main.object_spawned', obj_name}), Color.success)
            rpg_t.mana = rpg_t.mana - object.mana_cost
        else
            p(({'rpg_main.out_of_reach'}), Color.fail)
            return
        end
    end

    local msg = player.name .. ' casted ' .. obj_name .. '. '

    rpg_t.last_spawned = game.tick + object.tick
    Public.update_mana(player)

    local reward_xp = object.mana_cost * 0.085
    if reward_xp < 1 then
        reward_xp = 1
    end

    Public.gain_xp(player, reward_xp)

    AntiGrief.insert_into_capsule_history(player, position, msg)

    return
end

local function on_player_changed_surface(event)
    local player = game.get_player(event.player_index)
    Public.draw_level_text(player)
end

local function on_player_removed(event)
    Public.remove_player(event.player_index)
end

local function tick()
    local ticker = game.tick
    local count = #game.connected_players
    local players = game.connected_players
    local enable_flameboots = Public.get('rpg_extra').enable_flameboots
    local enable_mana = Public.get('rpg_extra').enable_mana

    if ticker % nth_tick == 0 then
        Public.global_pool(players, count)
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

Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)
Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_player_crafted_item, on_player_crafted_item)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_created, on_player_joined_game)
Event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_rotated_entity, on_player_rotated_entity)
Event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)
Event.add(defines.events.on_player_used_capsule, on_player_used_capsule)
Event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
Event.add(defines.events.on_player_removed, on_player_removed)
Event.on_nth_tick(10, tick)

return Public
