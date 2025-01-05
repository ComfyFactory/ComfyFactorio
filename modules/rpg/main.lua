--RPG Modules
local Public = require 'modules.rpg.core'
local Gui = require 'utils.gui'
local Event = require 'utils.event'
local AntiGrief = require 'utils.antigrief'
local SpamProtection = require 'utils.spam_protection'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local Explosives = require 'modules.explosives'
local StatData = require 'utils.datastore.statistics'
local WD = require 'modules.wave_defense.table'
local Math2D = require 'math2d'
local Color = require 'utils.color_presets'

StatData.add_normalize('spells', 'Spells casted')

--RPG Settings
local enemy_types = Public.enemy_types
local die_cause = Public.die_cause
local points_per_level = Public.points_per_level
local nth_tick = Public.nth_tick

--RPG Frames
local main_frame_name = Public.main_frame_name
local spell_gui_frame_name = Public.spell_gui_frame_name
local cooldown_indicator_name = Public.cooldown_indicator_name

local round = math.round
local floor = math.floor
local random = math.random
local sqrt = math.sqrt

local function on_gui_click(event)
    if not event then
        return
    end
    local player = game.get_player(event.player_index)
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

    if not Public.check_is_surface_valid(player) then
        return
    end

    if element.type ~= 'sprite-button' then
        return
    end

    local shift = event.shift

    if element.caption ~= '✚' then
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
        if event.button == defines.mouse_button_type.left then
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
            local left = rpg_t.points_left / 2
            if left > 2 then
                for _ = 2, left, 1 do -- for _ = 1 results in uneven distribution
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
            end
            Public.toggle(player, true)
        end
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
    ['character'] = function (cause)
        if not cause.player then
            return
        end
        return { cause.player }
    end,
    ['combat-robot'] = function (cause)
        if not cause.last_user then
            return
        end
        if not game.players[cause.last_user.index] then
            return
        end
        return { game.players[cause.last_user.index] }
    end,
    ['car'] = function (cause)
        local players = {}
        local driver = cause.get_driver()
        if driver and driver.valid and driver.is_player() then
            players[#players + 1] = driver
        else
            players[#players + 1] = driver.player
        end

        local passenger = cause.get_passenger()
        if passenger then
            if passenger.player then
                players[#players + 1] = passenger.player
            end
        end
        return players
    end,
    ['spider-vehicle'] = function (cause)
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
                    if entity.unit_number then
                        local mana_to_reward = random(1, 5)
                        if mana_to_reward > 1 then
                            Public.reward_mana(player, mana_to_reward)
                        end
                    end
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
        if entity.unit_number then
            local mana_to_reward = random(1, 5)
            if mana_to_reward > 1 then
                Public.reward_mana(player, mana_to_reward)
            end
        end
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
        if heal_per_tick and heal_per_tick <= 0 then
            goto continue
        end

        if not heal_per_tick then goto continue end
        heal_per_tick = round(heal_per_tick)
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
        local rpg_t = Public.get_value_from_player(player.index)
        if rpg_t then
            local mana_per_tick = Public.get_mana_modifier(player)
            local rpg_extra = Public.get('rpg_extra')
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
                    rpg_t.mana = (round(rpg_t.mana * 10) / 10)
                end
            end
        end

        ::continue::

        Public.update_mana(player)
    end
end

local function is_position_near(area, entity)
    local status = false

    local function inside(pos)
        local lt = area.left_top
        local rb = area.right_bottom

        return pos.x >= lt.x and pos.y >= lt.y and pos.x <= rb.x and pos.y <= rb.y
    end

    if inside(entity) then
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
    local original_damage_amount = event.original_damage_amount
    local final_damage_amount = event.final_damage_amount

    if cause.get_inventory(defines.inventory.character_ammo)[cause.selected_gun_index].valid_for_read or cause.get_inventory(defines.inventory.character_guns)[cause.selected_gun_index].valid_for_read then
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

    if not Public.check_is_surface_valid(p) then
        return
    end

    if entity.force.index == cause.force.index then
        return
    end

    local position = p.physical_position

    local area = {
        left_top = { x = position.x - 5, y = position.y - 5 },
        right_bottom = { x = position.x + 5, y = position.y + 5 }
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
    local damage = Public.get_final_damage(cause.player, entity, original_damage_amount)
    local enable_aoe_punch = Public.get('rpg_extra').enable_aoe_punch
    local rpg_t = Public.get_value_from_player(cause.player.index)

    --Floating messages and particle effects.
    if random(1, 7) == 1 then
        damage = damage * random(250, 350) * 0.01
        cause.surface.create_entity(
            {
                name = 'compi-speech-bubble',
                position = entity.position,
                text = '‼' .. floor(damage),
                source = entity,
                lifetime = 30
            }
        )
        cause.surface.create_entity({ name = 'blood-explosion-huge', position = entity.position })
    else
        damage = damage * random(100, 125) * 0.01
        cause.player.create_local_flying_text(
            {
                text = floor(damage),
                position = entity.position,
                color = { 150, 150, 150 },
                time_to_live = 90,
                speed = 2
            }
        )
    end

    local is_explosive_bullets_enabled = Public.get_explosive_bullets()
    if is_explosive_bullets_enabled then
        Public.explosive_bullets(event)
    end

    --Cause a one punch.
    if enable_aoe_punch then
        if rpg_t.aoe_punch then
            local chance = Public.get_aoe_punch_chance(cause.player) * 10
            local chance_to_hit = random(0, 999)
            local success = chance_to_hit < chance
            Public.log_aoe_punch(
                function ()
                    if success then
                        print('[OnePunch]: Chance: ' .. chance .. ' Chance to hit:  ' .. chance_to_hit .. ' Success: true' .. ' Damage: ' .. damage)
                    else
                        print('[OnePunch]: Chance: ' .. chance .. ' Chance to hit:  ' .. chance_to_hit .. ' Success: false' .. ' Damage: ' .. damage)
                    end
                end
            )
            if success then
                Public.aoe_punch(cause, entity, damage, final_damage_amount) -- only kill the biters if their health is below or equal to zero
                return
            end
        end
    end

    --Handle vanilla damage.
    Public.has_health_boost(entity, damage, final_damage_amount, cause)
end

local function on_player_repaired_entity(event)
    if random(1, 4) ~= 1 then
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

    local player = game.get_player(event.player_index)

    if not player or not player.valid or not player.character then
        return
    end

    local rpg_t = Public.get_value_from_player(player.index)
    if rpg_t.repaired_entity_delay > game.tick then
        return
    end

    Public.gain_xp(player, 0.05)
    Public.reward_mana(player, 0.2)

    local repair_speed = Public.get_magicka(player)
    if repair_speed <= 0 then
        return
    end

    rpg_t.repaired_entity_delay = game.tick + 20

    entity.health = entity.health + repair_speed
end

local function on_player_rotated_entity(event)
    local player = game.get_player(event.player_index)

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
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    if Public.get_last_spell_cast(player) then
        return
    end

    if random(1, 64) ~= 1 then
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
    ['item-entity'] = true,
    ['fish'] = true,
}

local function on_player_died(event)
    local player = game.get_player(event.player_index)

    if not player or not player.valid then
        return
    end

    Public.remove_frame(player)
end

local function on_pre_player_left_game(event)
    local player = game.get_player(event.player_index)

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
    local player = game.get_player(event.player_index)

    if not player or not player.valid then
        return
    end

    if not Public.check_is_surface_valid(player) then
        return
    end

    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_t then return end
    if rpg_t.last_mined_entity_position.x == entity.position.x and rpg_t.last_mined_entity_position.y == entity.position.y then
        return
    end

    rpg_t.last_mined_entity_position.x = entity.position.x
    rpg_t.last_mined_entity_position.y = entity.position.y

    local distance_multiplier = floor(sqrt(entity.position.x ^ 2 + entity.position.y ^ 2)) * 0.0005 + 1

    local xp_modifier_when_mining = Public.get('rpg_extra').xp_modifier_when_mining

    local xp_amount
    if entity.type == 'resource' then
        xp_amount = 0.9 * distance_multiplier
    else
        xp_amount = (1.5 + entity.max_health * xp_modifier_when_mining) * distance_multiplier
    end

    if player.gui.screen[main_frame_name] then
        local f = player.gui.screen[main_frame_name]
        local data = Gui.get_data(f)
        if data.exp_gui and data.exp_gui.valid then
            data.exp_gui.caption = floor(rpg_t.xp)
        end
    end

    Public.gain_xp(player, xp_amount)
    Public.reward_mana(player, 0.5 * distance_multiplier)
end

local function on_player_crafted_item(event)
    if not event.recipe.energy then
        return
    end
    local player = game.get_player(event.player_index)
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

    local amount = 0.40 * random(1, 2)
    local recipe = event.recipe

    if tweaked_crafting_items_enabled then
        if item and item.valid then
            if is_blacklisted[item.name] then
                return -- return if the item is blacklisted
            end
        end
    end

    local final_xp = recipe.energy * amount

    local get_dex_modifier = Public.get_dex_modifier(player)
    if not get_dex_modifier then return end

    if get_dex_modifier >= 10 then
        local chance = Public.get_crafting_bonus_chance(player) * 10
        local r = random(0, 1999)
        local success = r < chance
        if success then
            Public.set_crafting_boost(player, get_dex_modifier)
            local d = random(0, 2999)
            local item_dupe = d < chance
            if item_dupe and final_xp < 6 then
                local reward = {
                    name = item.name,
                    count = 1
                }
                Public.increment_duped_crafted_items(player)
                if player.can_insert(reward) then
                    player.insert(reward)
                end
            end
        end
    end

    Public.gain_xp(player, final_xp)
    Public.reward_mana(player, amount)
end

local function on_player_respawned(event)
    local player = game.get_player(event.player_index)
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
    local player = game.get_player(event.player_index)
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

local function get_near_coord_modifier(range)
    local coord = { x = (range * -1) + random(0, range * 2), y = (range * -1) + random(0, range * 2) }
    for _ = 1, 5, 1 do
        local new_coord = { x = (range * -1) + random(0, range * 2), y = (range * -1) + random(0, range * 2) }
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

    if not e.destructible then
        return
    end

    e.surface.create_entity({ name = 'ground-explosion', position = e.position })

    if e.type == 'entity-ghost' then
        e.destroy()
        return
    end

    e.health = e.health - random(30, 90)
    if e.health <= 0 then
        e.die('enemy')
    end
end

local function floaty_hearts(entity, c)
    local position = { x = entity.position.x - 0.75, y = entity.position.y - 1 }
    local b = 1.35
    for _ = 1, c, 1 do
        local p = {
            (position.x + 0.4) + (b * -1 + random(0, b * 20) * 0.1),
            position.y + (b * -1 + random(0, b * 20) * 0.1)
        }
        entity.surface.create_entity({ name = 'compi-speech-bubble', position = p, text = '♥', source = entity, lifetime = 30 })
    end
end

local function tame_unit_effects(player, entity)
    floaty_hearts(entity, 7)

    rendering.draw_text {
        text = '~' .. player.name .. "'s pet~",
        surface = player.surface,
        target = {
            entity = entity,
            offset = { 0, -2.6 },
        },
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

local function on_player_used_capsule_custom(event)
    local enable_mana = Public.get('rpg_extra').enable_mana
    if not enable_mana then
        return
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local
    is_spamming = SpamProtection.is_spamming(player, nil, 'RPG - on_player_used_capsule_custom')
    if is_spamming then
        return
    end
    local projectile_types = Public.get_projectiles

    if not player.character or not player.character.valid then
        return
    end

    if not Public.check_is_surface_valid(player) then
        return
    end

    local rpg_t = Public.get_value_from_player(player.index)

    if not rpg_t.enable_entity_spawn then
        player.print('[RPG] You must enable the button in the spell GUI to cast a spell.', { color = Color.warning })
        return
    end

    local mana = rpg_t.mana
    local surface = player.surface

    local spell = Public.get_spell_by_name(rpg_t, rpg_t.dropdown_select_name)
    if not spell then
        return
    end

    if spell.enforce_cooldown then
        if Public.is_cooldown_active_for_player(player) then
            Public.cast_spell(player, true)
            return
        end
    end

    local position = event.cursor_position
    if not position then
        return
    end

    local radius = 15
    local area = {
        left_top = { x = position.x - radius, y = position.y - radius },
        right_bottom = { x = position.x + radius, y = position.y + radius }
    }

    if not spell.enabled then
        return Public.cast_spell(player, true)
    end

    if rpg_t.level < spell.level then
        return Public.cast_spell(player, true)
    end

    if not Math2D.bounding_box.contains_point(area, player.physical_position) then
        Public.cast_spell(player, true)
        return
    end

    if mana < spell.mana_cost then
        return Public.cast_spell(player, true)
    end

    local target_pos
    if spell.target then
        target_pos = { position.x, position.y }
    elseif projectile_types[spell.entityName] then
        local coord_modifier = get_near_coord_modifier(projectile_types[spell.entityName].max_range)
        target_pos = { position.x + coord_modifier.x, position.y + coord_modifier.y }
    end

    local range
    if spell.range then
        range = spell.range
    else
        range = 0
    end

    local force
    if spell.force then
        force = spell.force
    else
        force = 'player'
    end

    local data = {
        self = spell,
        player = player,
        damage_entity = damage_entity,
        position = position,
        surface = surface,
        force = force,
        target_pos = target_pos,
        range = range,
        tame_unit_effects = tame_unit_effects,
        explosives = Explosives,
        rpg_t = rpg_t
    }

    local funcs = {
        remove_mana = Public.remove_mana,
        damage_player_over_time = Public.damage_player_over_time,
        cast_spell = Public.cast_spell
    }

    rpg_t.amount = 0

    local cast_spell = spell.callback(data, funcs)
    if not cast_spell then
        return
    end

    if rpg_t.amount == 0 then
        rpg_t.amount = 1
    end

    Event.raise(Public.events.on_spell_cast_success, { player_index = player.index, spell_name = spell.entityName, amount = rpg_t.amount })

    StatData.get_data(player):increase('spells')

    if spell.enforce_cooldown then
        if player.gui.screen[spell_gui_frame_name] then
            local f = player.gui.screen[spell_gui_frame_name]
            if f then
                if f[cooldown_indicator_name] then
                    Public.register_cooldown_for_player_progressbar(player, spell)
                end
            end
        else
            Public.register_cooldown_for_player(player, spell)
        end
    end

    Public.update_mana(player)

    local reward_xp = spell.mana_cost * 0.085
    if reward_xp < 1 then
        reward_xp = 1
    end

    Public.gain_xp(player, reward_xp)

    if spell.log_spell then
        local msg = player.name .. ' casted ' .. spell.entityName .. '. '
        AntiGrief.insert_into_capsule_history(player, position, msg)
    end
end

local function on_player_used_capsule(event)
    local enable_mana = Public.get('rpg_extra').enable_mana
    if not enable_mana then
        return
    end

    local projectile_types = Public.get_projectiles

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    if not player.character or not player.character.valid then
        return
    end

    if not Public.check_is_surface_valid(player) then
        return
    end

    local item = event.item

    if not item then
        return
    end

    local name = item.name

    local rpg_t = Public.get_value_from_player(player.index)
    if not rpg_t then return end

    if name == 'cooked-fish' or name == 'grilled-fish' then
        Public.get_mana_modifier_from_using_fish(player, name)
        return
    end

    if name ~= 'raw-fish' then
        return
    end

    Public.get_heal_modifier_from_using_fish(player)



    if not rpg_t.enable_entity_spawn then
        return
    end

    local mana = rpg_t.mana
    local surface = player.surface

    local spell = Public.get_spell_by_name(rpg_t, rpg_t.dropdown_select_name)
    if not spell then
        return
    end

    if spell.enforce_cooldown then
        if Public.is_cooldown_active_for_player(player) then
            Public.cast_spell(player, true)
            return
        end
    end

    local position = event.position
    if not position then
        return
    end

    local radius = 15
    local area = {
        left_top = { x = position.x - radius, y = position.y - radius },
        right_bottom = { x = position.x + radius, y = position.y + radius }
    }

    if not spell.enabled then
        return Public.cast_spell(player, true)
    end

    if rpg_t.level < spell.level then
        return Public.cast_spell(player, true)
    end

    if not Math2D.bounding_box.contains_point(area, player.physical_position) then
        Public.cast_spell(player, true)
        return
    end

    if mana < spell.mana_cost then
        return Public.cast_spell(player, true)
    end

    local target_pos
    if spell.target then
        target_pos = { position.x, position.y }
    elseif projectile_types[spell.entityName] then
        local coord_modifier = get_near_coord_modifier(projectile_types[spell.entityName].max_range)
        target_pos = { position.x + coord_modifier.x, position.y + coord_modifier.y }
    end

    local range
    if spell.range then
        range = spell.range
    else
        range = 0
    end

    local force
    if spell.force then
        force = spell.force
    else
        force = 'player'
    end

    local data = {
        self = spell,
        player = player,
        damage_entity = damage_entity,
        position = position,
        surface = surface,
        force = force,
        target_pos = target_pos,
        range = range,
        tame_unit_effects = tame_unit_effects,
        explosives = Explosives,
        rpg_t = rpg_t
    }

    local funcs = {
        remove_mana = Public.remove_mana,
        damage_player_over_time = Public.damage_player_over_time,
        cast_spell = Public.cast_spell
    }

    rpg_t.amount = 0

    local cast_spell = spell.callback(data, funcs)
    if not cast_spell then
        return
    end

    if rpg_t.amount == 0 then
        rpg_t.amount = 1
    end

    Event.raise(Public.events.on_spell_cast_success, { player_index = player.index, spell_name = spell.entityName, amount = rpg_t.amount })

    StatData.get_data(player):increase('spells')

    if spell.enforce_cooldown then
        if player.gui.screen[spell_gui_frame_name] then
            local f = player.gui.screen[spell_gui_frame_name]
            if f then
                if f[cooldown_indicator_name] then
                    Public.register_cooldown_for_player_progressbar(player, spell)
                end
            end
        else
            Public.register_cooldown_for_player(player, spell)
        end
    end

    Public.update_mana(player)

    local reward_xp = spell.mana_cost * 0.085
    if reward_xp < 1 then
        reward_xp = 1
    end

    Public.gain_xp(player, reward_xp)

    if spell.log_spell then
        local msg = player.name .. ' casted ' .. spell.entityName .. '. '
        AntiGrief.insert_into_capsule_history(player, position, msg)
    end
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
    local players = game.connected_players
    local count = #players
    local enable_mana = Public.get('rpg_extra').enable_mana

    if ticker % nth_tick == 0 then
        Public.global_pool(players, count)
    end

    if ticker % 30 == 0 then
        regen_health_player(players)
        if enable_mana then
            regen_mana_player(players)
        end
    end
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
if script.active_mods['MtnFortressAddons'] then
    Event.add(defines.events['mtn-shift-cast-spell'], on_player_used_capsule_custom)
end
Event.add(defines.events.on_player_used_capsule, on_player_used_capsule)
Event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
Event.add(defines.events.on_player_removed, on_player_removed)
Event.on_nth_tick(10, tick)
Event.on_nth_tick(2, Public.update_tidal_wave)

Event.add(
    defines.events.on_gui_closed,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        Public.clear_settings_frames(player)
    end
)

if _DEBUG then
    Public.disable_cooldowns_on_spells()

    Event.on_init(
        function ()
            Public.rpg_reset_all_players()
            Public.enable_health_and_mana_bars(true)
            Public.enable_wave_defense(true)
            Public.enable_mana(true)
            Public.personal_tax_rate(0.4)
            Public.enable_stone_path(true)
            Public.enable_aoe_punch(true)
            Public.enable_aoe_punch_globally(false)
            Public.enable_range_buffs(true)
            Public.enable_auto_allocate(true)
            Public.enable_explosive_bullets_globally(true)
            Public.enable_explosive_bullets(false)
        end
    )
end

return Public
