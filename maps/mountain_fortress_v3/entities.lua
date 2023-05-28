require 'modules.rocks_broken_paint_tiles'

local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local Server = require 'utils.server'
local RPG = require 'modules.rpg.main'
local Collapse = require 'modules.collapse'
local Alert = require 'utils.alert'
local Task = require 'utils.task'
local Score = require 'utils.gui.score'
local Token = require 'utils.token'
local Discord = require 'utils.discord'
local Core = require 'utils.core'
local Diff = require 'modules.difficulty_vote_by_amount'
local format_number = require 'util'.format_number
local RPG_Progression = require 'utils.datastore.rpg_data'
local WD = require 'modules.wave_defense.table'

local zone_settings = Public.zone_settings
local random = math.random
local floor = math.floor
local abs = math.abs
local round = math.round

-- Use these settings for live
local send_ping_to_channel = Discord.channel_names.mtn_channel
-- Use these settings for testing
-- bot-lounge
-- local send_ping_to_channel = Discord.channel_names.bot_quarters
-- dev
-- local send_ping_to_channel = Discord.channel_names.bot_quarters
-- local role_to_mention = Discord.role_mentions.test_role

local chests = {
    'wooden-chest',
    'iron-chest',
    'steel-chest',
    'crash-site-chest-1',
    'crash-site-chest-2',
    'crash-site-spaceship-wreck-big-1',
    'crash-site-spaceship-wreck-big-2',
    'crash-site-spaceship-wreck-medium-1',
    'crash-site-spaceship-wreck-medium-2',
    'crash-site-spaceship-wreck-medium-3'
}

local size_chests = #chests

local treasure_chest_messages = {
    ({'entity.treasure_1'}),
    ({'entity.treasure_2'}),
    ({'entity.treasure_3'})
}

local rare_treasure_chest_messages = {
    ({'entity.treasure_rare_1'}),
    ({'entity.treasure_rare_2'}),
    ({'entity.treasure_rare_3'})
}

local disabled_threats = {
    ['entity-ghost'] = true,
    ['raw-fish'] = true
}

local defeated_messages = {
    ({'entity.defeated_1'}),
    ({'entity.defeated_2'}),
    ({'entity.defeated_3'}),
    ({'entity.defeated_4'})
}

local protect_types = {
    ['cargo-wagon'] = true,
    ['artillery-wagon'] = true,
    ['fluid-wagon'] = true,
    ['locomotive'] = true,
    ['reactor'] = true,
    ['spider-vehicle'] = true,
    ['car'] = true
}

local reset_game =
    Token.register(
    function(data)
        local this = data.this
        if this.soft_reset then
            Public.set_scores()
            this.game_reset_tick = nil
            Public.reset_map()
            return
        end
        if this.restart then
            Public.set_scores()
            local message = ({'entity.reset_game'})
            Server.to_discord_bold(message, true)
            Server.start_scenario('Mountain_Fortress_v3')
            return
        end
        if this.shutdown then
            Public.set_scores()
            local message = ({'entity.shutdown_game'})
            Server.to_discord_bold(message, true)
            Server.stop_scenario()
            return
        end
    end
)

local function get_random_weighted(weighted_table, item_index, weight_index)
    local total_weight = 0
    item_index = item_index or 1
    weight_index = weight_index or 2

    for _, w in pairs(weighted_table) do
        total_weight = total_weight + w[weight_index]
    end

    local index = random() * total_weight
    local weight_sum = 0
    for _, w in pairs(weighted_table) do
        weight_sum = weight_sum + w[weight_index]
        if weight_sum >= index then
            return w[item_index]
        end
    end
end

local function on_entity_removed(data)
    local entity = data.entity
    local upgrades = Public.get('upgrades')

    local built = {
        ['land-mine'] = upgrades.landmine.built,
        ['flamethrower-turret'] = upgrades.flame_turret.built
    }

    local validator = {
        ['land-mine'] = 'landmine',
        ['flamethrower-turret'] = 'flame_turret'
    }

    local name = validator[entity.name]

    if built[entity.name] and entity.force.index == 1 then
        upgrades[name].built = upgrades[name].built - 1
        if upgrades[name].built <= 0 then
            upgrades[name].built = 0
        end
    end
end

local function check_health()
    local locomotive_health = Public.get('locomotive_health')
    local locomotive_max_health = Public.get('locomotive_max_health')
    local carriages = Public.get('carriages')
    if locomotive_health <= 0 then
        Public.set('locomotive_health', 0)
    end
    local m = locomotive_health / locomotive_max_health
    if carriages then
        for i = 1, #carriages do
            local entity = carriages[i]
            if not (entity and entity.valid) then
                return
            end
            local cargo_health = 600
            if entity.type == 'locomotive' then
                entity.health = 1000 * m
            else
                entity.health = cargo_health * m
            end
        end
    end
end

local function check_health_final_damage(final_damage_amount)
    local carriages = Public.get('carriages')
    if carriages then
        for i = 1, #carriages do
            local entity = carriages[i]
            if not (entity and entity.valid) then
                return
            end
            entity.health = entity.health + final_damage_amount
        end
    end
end

local function set_train_final_health(final_damage_amount, repair)
    if final_damage_amount == 0 then
        return
    end

    local locomotive = Public.get('locomotive')
    if not (locomotive and locomotive.valid) then
        return
    end

    local locomotive_health = Public.get('locomotive_health')
    local locomotive_max_health = Public.get('locomotive_max_health')

    if not repair then
        local poison_deployed = Public.get('poison_deployed')
        local robotics_deployed = Public.get('robotics_deployed')

        local lower_high = locomotive_max_health * 0.4
        local higher_high = locomotive_max_health * 0.5
        local lower_low = locomotive_max_health * 0.2
        local higher_low = locomotive_max_health * 0.3

        if locomotive_health >= lower_high and locomotive_health <= higher_high then
            if not poison_deployed then
                local carriages = Public.get('carriages')

                if WD.get('wave_number') <= 800 then
                    if carriages then
                        for i = 1, #carriages do
                            local entity = carriages[i]
                            Public.enable_poison_defense(entity.position)
                        end
                    end
                end

                local p = {
                    position = locomotive.position
                }
                local msg = ({'entity.train_taking_damage'})
                Alert.alert_all_players_location(p, msg)
                Public.set().poison_deployed = true
            end
        elseif locomotive_health >= lower_low and locomotive_health <= higher_low then
            if not robotics_deployed then
                local carriages = Public.get('carriages')

                if carriages then
                    for i = 1, #carriages do
                        local entity = carriages[i]
                        Public.enable_robotic_defense(entity.position)
                    end
                end
                local p = {
                    position = locomotive.position
                }
                local msg = ({'entity.train_taking_damage'})
                Alert.alert_all_players_location(p, msg)
                Public.set().robotics_deployed = true
            end
        elseif locomotive_health >= locomotive_max_health then
            Public.set().poison_deployed = false
        end
    end

    if locomotive_health <= 0 or locomotive.health <= 5 then
        locomotive.destructible = false
        locomotive.health = 1
        Public.set('game_lost', true)
        Public.loco_died()
    end

    if locomotive_health <= 0 then
        check_health_final_damage(final_damage_amount)
        return
    end

    Public.set('locomotive_health', floor(locomotive_health - final_damage_amount))
    if locomotive_health > locomotive_max_health then
        Public.set('locomotive_health', locomotive_max_health)
    end
    locomotive_health = Public.get('locomotive_health')

    check_health()

    local health_text = Public.get('health_text')

    rendering.set_text(health_text, 'HP: ' .. round(locomotive_health) .. ' / ' .. round(locomotive_max_health))
end

local function protect_entities(data)
    local cause = data.cause
    local entity = data.entity
    local force = data.force
    local dmg = data.final_damage_amount

    if not dmg then
        return
    end

    local check_heavy_damage = Public.get('check_heavy_damage')

    if check_heavy_damage then
        if (entity.type == 'simple-entity' or entity.type == 'simple-entity-with-owner') and dmg >= 500 then
            entity.health = entity.health + dmg
        end
    end

    if entity.force.index ~= 1 then
        return
    end

    local function is_protected(e)
        local map_name = 'mtn_v3'

        if string.sub(e.surface.name, 0, #map_name) ~= map_name then
            return true
        end
        if protect_types[e.type] then
            return true
        end
        return false
    end

    local carriages_numbers = Public.get('carriages_numbers')
    if is_protected(entity) then
        if (cause and cause.valid) then
            if Public.valid_enemy_forces[cause.force.name] then
                if carriages_numbers and carriages_numbers[entity.unit_number] then
                    set_train_final_health(dmg, false)
                    return
                else
                    entity.health = entity.health - dmg
                    return
                end
            end
        elseif not (cause and cause.valid) then
            if force and Public.valid_enemy_forces[force.name] then
                if carriages_numbers and carriages_numbers[entity.unit_number] then
                    set_train_final_health(dmg, false)
                    return
                else
                    entity.health = entity.health - dmg
                    return
                end
            end
        end

        entity.health = entity.health + dmg
    end
end

local function hidden_treasure(player, entity)
    local rpg = RPG.get_value_from_player(player.index)
    if not rpg then
        return
    end

    local magic = rpg.magicka

    if magic >= 50 then
        local msg = rare_treasure_chest_messages[random(1, #rare_treasure_chest_messages)]
        Alert.alert_player(player, 5, msg)
        Public.add_loot_rare(entity.surface, entity.position, 'wooden-chest', magic)
        return
    end
    local msg = treasure_chest_messages[random(1, #treasure_chest_messages)]
    Alert.alert_player(player, 5, msg, nil, nil, 0.3)
    Public.add_loot(entity.surface, entity.position, chests[random(1, size_chests)])
end

local function biters_chew_rocks_faster(data)
    local cause = data.cause
    local entity = data.entity
    local final_damage_amount = data.final_damage_amount

    if entity.force.index ~= 3 then
        return
    end --Neutral Force
    if not cause then
        return
    end
    if not cause.valid then
        return
    end
    if cause.force.index ~= 2 then
        return
    end --Enemy Force

    entity.health = entity.health - final_damage_amount * 7
end

local projectiles = {'grenade', 'explosive-rocket', 'grenade', 'explosive-rocket', 'explosive-cannon-projectile'}

local function angry_tree(entity, cause, player)
    if entity.type ~= 'tree' then
        return
    end

    if abs(entity.position.y) < zone_settings.zone_depth then
        return
    end
    if random(1, 6) == 1 then
        Public.buried_biter(entity.surface, entity.position)
    end
    if random(1, 8) == 1 then
        Public.buried_worm(entity.surface, entity.position)
    end
    if random(1, 32) ~= 1 then
        return
    end
    local position = false
    if cause then
        if cause.valid then
            position = cause.position
        end
    end
    if not position then
        position = {entity.position.x + (-20 + random(0, 40)), entity.position.y + (-20 + random(0, 40))}
    end
    if player then
        local forest_zone = RPG.get_value_from_player(player.index, 'forest_zone')
        if forest_zone and random(1, 32) == 1 then
            local cbl = Public.refill_turret_callback
            local data = {callback_data = Public.piercing_rounds_magazine_ammo}
            local e =
                entity.surface.create_entity(
                {
                    name = 'gun-turret',
                    position = entity.position,
                    force = 'enemy'
                }
            )
            if e.can_insert(Public.piercing_rounds_magazine_ammo) then
                e.insert(Public.piercing_rounds_magazine_ammo)
            end
            local callback = Token.get(cbl)
            callback(e, data)
            return
        end
    end

    entity.surface.create_entity(
        {
            name = projectiles[random(1, 5)],
            position = entity.position,
            force = 'neutral',
            source = entity.position,
            target = position,
            max_range = 16,
            speed = 0.01
        }
    )
end

local function give_coin(player)
    local coin_amount = Public.get('coin_amount')
    local coin_override = Public.get('coin_override')
    local forest_zone = RPG.get_value_from_player(player.index, 'forest_zone')

    if forest_zone then
        if random(1, 3) ~= 1 then
            return
        end
    end

    if coin_amount >= 1 then
        if coin_override then
            player.insert({name = 'coin', count = coin_override})
        else
            player.insert({name = 'coin', count = random(1, coin_amount)})
        end
    end
end

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

local mining_events = {
    {
        function()
        end,
        300000,
        'Nothing'
    },
    {
        function()
        end,
        16384,
        'Nothing'
    },
    {
        function()
        end,
        4096,
        'Nothing'
    },
    {
        function(entity)
            if Public.is_around_train(entity) then
                entity.destroy()
                return
            end

            Public.buried_biter(entity.surface, entity.position)
            entity.destroy()
        end,
        4096,
        'Angry Biter #2'
    },
    {
        function(entity)
            if Public.is_around_train(entity) then
                entity.destroy()
                return
            end

            Public.buried_biter(entity.surface, entity.position)
            entity.destroy()
        end,
        512,
        'Angry Biter #2'
    },
    {
        function(entity)
            if Public.is_around_train(entity) then
                entity.destroy()
                return
            end

            Public.buried_worm(entity.surface, entity.position)
            entity.destroy()
        end,
        2048,
        'Angry Worm'
    },
    {
        function(entity)
            if Public.is_around_train(entity) then
                entity.destroy()
                return
            end

            Public.tick_tack_trap(entity.surface, entity.position)
            entity.destroy()
        end,
        2048,
        'Dangerous Trap'
    },
    {
        function(entity, index)
            if Public.is_around_train(entity) then
                entity.destroy()
                return
            end

            local player = game.get_player(index)

            if entity.type == 'tree' then
                angry_tree(entity, player.character, player)
                entity.destroy()
            end
        end,
        1024,
        'Angry Tree'
    },
    {
        function(entity, index)
            local player = game.get_player(index)
            hidden_treasure(player, entity)
        end,
        1024,
        'Treasure_Tier_1'
    },
    {
        function(entity, index)
            local player = game.get_player(index)
            hidden_treasure(player, entity)
        end,
        512,
        'Treasure_Tier_2'
    },
    {
        function(entity, index)
            local player = game.get_player(index)
            hidden_treasure(player, entity)
        end,
        256,
        'Treasure_Tier_3'
    },
    {
        function(entity, index)
            local player = game.get_player(index)
            hidden_treasure(player, entity)
        end,
        128,
        'Treasure_Tier_4'
    },
    {
        function(entity, index)
            local player = game.get_player(index)
            hidden_treasure(player, entity)
        end,
        64,
        'Treasure_Tier_5'
    },
    {
        function(entity, index)
            local player = game.get_player(index)
            hidden_treasure(player, entity)
        end,
        32,
        'Treasure_Tier_6'
    },
    {
        function(entity, index)
            local player = game.get_player(index)
            hidden_treasure(player, entity)
        end,
        16,
        'Treasure_Tier_7'
    },
    {
        function(entity, index)
            if Public.is_around_train(entity) then
                entity.destroy()
                return
            end

            local ent_to_create = {'biter-spawner', 'spitter-spawner'}

            local position = entity.position
            local surface = entity.surface
            local e = surface.create_entity({name = ent_to_create[random(1, #ent_to_create)], position = position, force = 'enemy'})

            e.destructible = false
            Task.set_timeout_in_ticks(300, immunity_spawner, {entity = e})
            Public.unstuck_player(index)
        end,
        512,
        'Nest'
    },
    {
        function(entity, index)
            if Public.is_around_train(entity) then
                entity.destroy()
                return
            end

            local ent_to_create = {'biter-spawner', 'spitter-spawner'}

            local position = entity.position
            local surface = entity.surface
            local e = surface.create_entity({name = ent_to_create[random(1, #ent_to_create)], position = position, force = 'enemy'})

            e.destructible = false
            Task.set_timeout_in_ticks(300, immunity_spawner, {entity = e})
            Public.unstuck_player(index)
        end,
        512,
        'Nest'
    },
    {
        function(entity)
            local position = entity.position
            local surface = entity.surface
            surface.create_entity({name = 'compilatron', position = position, force = 'player'})
        end,
        64,
        'Friendly Compilatron'
    },
    {
        function(entity)
            if Public.is_around_train(entity) then
                entity.destroy()
                return
            end

            local position = entity.position
            local surface = entity.surface
            surface.create_entity({name = 'compilatron', position = position, force = 'enemy'})
        end,
        128,
        'Enemy Compilatron'
    },
    {
        function(entity)
            local chest = 'crash-site-chest-' .. random(1, 2)
            local container = entity.surface.create_entity({name = chest, position = entity.position, force = 'neutral'})
            if container and container.health then
                container.insert({name = 'vehicle-machine-gun', count = 1})
                container.health = random(1, container.health)
            end
        end,
        64,
        'VSMG'
    },
    {
        function(entity, index)
            local position = entity.position
            local surface = entity.surface
            surface.create_entity({name = 'car', position = position, force = 'player'})
            Public.unstuck_player(index)
            local player = game.players[index]
            local msg = ({'entity.found_car', player.name})
            Alert.alert_player(player, 15, msg)
        end,
        32,
        'Car'
    }
}

local function on_player_mined_entity(event)
    local entity = event.entity
    local player = game.get_player(event.player_index)
    if not player.valid then
        return
    end
    if not entity.valid then
        return
    end
    local rpg_char = RPG.get_value_from_player(player.index)

    local map_name = 'mtn_v3'

    if string.sub(entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local d = {
        entity = entity
    }

    on_entity_removed(d)

    if disabled_threats[entity.name] then
        return
    end

    local mined_scrap = Public.get('mined_scrap')

    if entity.type == 'simple-entity' or entity.type == 'simple-entity-with-owner' or entity.type == 'tree' then
        Public.set().mined_scrap = mined_scrap + 1
        Public.on_player_mined_entity(event)
        if entity.type == 'tree' then
            if random(1, 3) == 1 then
                give_coin(player)
            end
        elseif entity.type == 'simple-entity-with-owner' then
            if random(1, 6) == 1 then
                give_coin(player)
            end
        else
            give_coin(player)
        end
        if rpg_char.stone_path then
            entity.surface.set_tiles({{name = 'stone-path', position = entity.position}}, true)
        end

        local func = get_random_weighted(mining_events)
        func(entity, player.index)
    end
end

local function on_robot_mined_entity(event)
    local entity = event.entity

    if not entity.valid then
        return
    end

    local map_name = 'mtn_v3'

    if string.sub(entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local d = {
        entity = entity
    }

    on_entity_removed(d)
end

local function get_damage(data)
    local entity = data.entity
    local original_damage_amount = data.original_damage_amount

    local damage = original_damage_amount + original_damage_amount * random(1, 100)
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

local function kaboom(entity, target, damage)
    local base_vector = {target.position.x - entity.position.x, target.position.y - entity.position.y}

    local vector = {base_vector[1], base_vector[2]}
    vector[1] = vector[1] * 512
    vector[2] = vector[2] * 256

    local msg = {'TASTY', 'MUNCH', 'SNACK_TIME', 'OVER 9000!'}

    entity.surface.create_entity(
        {
            name = 'flying-text',
            position = {entity.position.x + base_vector[1] * 0.5, entity.position.y + base_vector[2] * 0.5},
            text = msg[random(1, #msg)],
            color = {255, 0, 0}
        }
    )

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

    vector[1] = vector[1] * 1.6
    vector[2] = vector[2] * 1.6

    local a = 0.30

    for i = 1, 8, 1 do
        for x = i * -1 * a, i * a, 1 do
            for y = i * -1 * a, i * a, 1 do
                local p = {entity.position.x + x + vector[1] * i, entity.position.y + y + vector[2] * i}
                entity.surface.create_trivial_smoke({name = 'fire-smoke', position = p})
                for _, e in pairs(entity.surface.find_entities({{p[1] - a, p[2] - a}, {p[1] + a, p[2] + a}})) do
                    if e.valid then
                        if e.health then
                            if e.destructible and e.minable then
                                if e.force.index ~= entity.force.index then
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

local function boss_puncher(data)
    local cause = data.cause
    local entity = data.entity

    if not cause then
        return
    end
    if not cause.valid then
        return
    end

    if cause.force.index ~= 2 then
        return
    end

    if entity.force.index ~= 1 then
        return
    end
    if not entity then
        return
    end
    if not entity.valid then
        return
    end

    if random(1, 10) == 1 then
        kaboom(cause, entity, get_damage(data))
    end
end

local function on_entity_damaged(event)
    local entity = event.entity

    if not (entity and entity.valid) then
        return
    end

    local cause = event.cause
    local force = event.force
    local final_damage_amount = event.final_damage_amount
    local original_damage_amount = event.original_damage_amount

    local wave_number = WD.get_wave()
    local boss_wave_warning = WD.get_alert_boss_wave()
    local munch_time = Public.get('munch_time')

    local data = {
        cause = cause,
        entity = entity,
        final_damage_amount = final_damage_amount,
        original_damage_amount = original_damage_amount,
        force = force
    }

    protect_entities(data)
    biters_chew_rocks_faster(data)

    if munch_time then
        if boss_wave_warning or wave_number >= 1000 then
            if random(0, 512) == 1 then
                boss_puncher(data)
            end
        end
    end
end

local function on_player_repaired_entity(event)
    if not event.entity then
        return
    end
    if not event.entity.valid then
        return
    end
    if not event.entity.health then
        return
    end
    local entity = event.entity
    local carriages_numbers = Public.get('carriages_numbers')

    if carriages_numbers[entity.unit_number] then
        local player = game.get_player(event.player_index)
        local repair_speed = RPG.get_magicka(player)
        if repair_speed <= 1 then
            set_train_final_health(-1, true)
            return
        else
            set_train_final_health(-repair_speed, true)
            return
        end
    end
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity.valid then
        return
    end

    local cause = event.cause

    local map_name = 'mtn_v3'

    if string.sub(entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local d = {
        entity = entity
    }

    on_entity_removed(d)

    local player
    local valid_enemy_forces = Public.valid_enemy_forces

    if cause then
        if cause.valid then
            if (cause and cause.name == 'character' and cause.player) then
                player = cause.player
            end
            if valid_enemy_forces[cause.force.name] or cause.force.index == 3 then
                entity.destroy()
                return
            end
        end
    end

    if disabled_threats[entity.name] then
        return
    end

    local biters_killed = Public.get('biters_killed')
    local biters = Public.get('biters')

    if entity.type == 'unit' or entity.type == 'unit-spawner' then
        Public.set().biters_killed = biters_killed + 1
        biters.amount = biters.amount - 1
        if biters.amount <= 0 then
            biters.amount = 0
        end
        if Public.is_around_train(entity) then
            return
        end
        if random(1, 512) == 1 then
            Public.tick_tack_trap(entity.surface, entity.position)
            return
        end
    end

    if entity.type == 'tree' then
        for _, e in pairs(
            entity.surface.find_entities_filtered(
                {
                    area = {
                        {entity.position.x - 4, entity.position.y - 4},
                        {entity.position.x + 4, entity.position.y + 4}
                    },
                    name = 'fire-flame-on-tree'
                }
            )
        ) do
            if e.valid then
                e.destroy()
                return
            end
        end
        if Public.is_around_train(entity) then
            return
        end
        angry_tree(entity, cause, player)
        return
    end

    if entity.type == 'simple-entity' then
        if Public.is_around_train(entity) then
            entity.destroy()
            return
        end
        if random(1, 32) == 1 then
            Public.buried_biter(entity.surface, entity.position)
            entity.destroy()
            return
        end
        if random(1, 64) == 1 then
            Public.buried_worm(entity.surface, entity.position)
            entity.destroy()
            return
        end
        if random(1, 512) == 1 then
            Public.tick_tack_trap(entity.surface, entity.position)
            return
        end
        entity.destroy()
        return
    end
end

local function get_sorted_list(column_name, score_list)
    for _ = 1, #score_list, 1 do
        for y = 1, #score_list, 1 do
            if not score_list[y + 1] then
                break
            end
            if score_list[y][column_name] < score_list[y + 1][column_name] then
                local key = score_list[y]
                score_list[y] = score_list[y + 1]
                score_list[y + 1] = key
            end
        end
    end
    return score_list
end

local function get_mvps(force)
    local get_score = Score.get_table().score_table
    if not get_score[force] then
        return false
    end
    local score = get_score[force]
    local score_list = {}
    for _, p in pairs(game.players) do
        if score.players[p.name] then
            local killscore = 0
            if score.players[p.name].killscore then
                killscore = score.players[p.name].killscore
            end
            local built_entities = 0
            if score.players[p.name].built_entities then
                built_entities = score.players[p.name].built_entities
            end
            local mined_entities = 0
            if score.players[p.name].mined_entities then
                mined_entities = score.players[p.name].mined_entities
            end
            table.insert(score_list, {name = p.name, killscore = killscore, built_entities = built_entities, mined_entities = mined_entities})
        end
    end
    local mvp = {}
    score_list = get_sorted_list('killscore', score_list)
    mvp.killscore = {name = score_list[1].name, score = score_list[1].killscore}
    score_list = get_sorted_list('mined_entities', score_list)
    mvp.mined_entities = {name = score_list[1].name, score = score_list[1].mined_entities}
    score_list = get_sorted_list('built_entities', score_list)
    mvp.built_entities = {name = score_list[1].name, score = score_list[1].built_entities}
    return mvp
end

local function show_mvps(player)
    local get_score = Score.get_table().score_table
    local wave_defense_table = WD.get_table()
    if not get_score then
        return
    end
    if player.gui.left['mvps'] then
        return
    end
    local frame = player.gui.left.add({type = 'frame', name = 'mvps', direction = 'vertical'})
    local l = frame.add({type = 'label', caption = 'MVPs:'})
    l.style.font = 'default-listbox'
    l.style.font_color = {r = 0.55, g = 0.55, b = 0.99}

    local t = frame.add({type = 'table', column_count = 2})
    local mvp = get_mvps('player')
    if mvp then
        local wave_defense = t.add({type = 'label', caption = 'Highest Wave >> '})
        wave_defense.style.font = 'default-listbox'
        wave_defense.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
        local wave_defense_text = t.add({type = 'label', caption = 'This rounds highest wave was: ' .. wave_defense_table.wave_number})
        wave_defense_text.style.font = 'default-bold'
        wave_defense_text.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

        local fighter_label = t.add({type = 'label', caption = 'Fighter >> '})
        fighter_label.style.font = 'default-listbox'
        fighter_label.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
        local fighter_label_text = t.add({type = 'label', caption = mvp.killscore.name .. ' with a killing score of ' .. mvp.killscore.score .. ' kills!'})
        fighter_label_text.style.font = 'default-bold'
        fighter_label_text.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

        local builder_label = t.add({type = 'label', caption = 'Builder >> '})
        builder_label.style.font = 'default-listbox'
        builder_label.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
        local builder_label_text = t.add({type = 'label', caption = mvp.built_entities.name .. ' built ' .. mvp.built_entities.score .. ' things!'})
        builder_label_text.style.font = 'default-bold'
        builder_label_text.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

        local miners_label = t.add({type = 'label', caption = 'Miners >> '})
        miners_label.style.font = 'default-listbox'
        miners_label.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
        local miners_label_text = t.add({type = 'label', caption = mvp.mined_entities.name .. ' mined a total of  ' .. mvp.mined_entities.score .. ' entities!'})
        miners_label_text.style.font = 'default-bold'
        miners_label_text.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

        local sent_to_discord = Public.get('sent_to_discord')
        local server_name_matches = Server.check_server_name('Mtn Fortress')

        if not sent_to_discord and server_name_matches then
            local message = {
                title = 'Game over',
                description = 'Player statistics is below',
                color = 'failure',
                field1 = {
                    text1 = 'Highest Wave:',
                    text2 = wave_defense_table.wave_number,
                    inline = 'false'
                },
                field2 = {
                    text1 = 'MVP Fighter:',
                    text2 = mvp.killscore.name .. ' with a killing score of ' .. mvp.killscore.score .. ' kills!',
                    inline = 'false'
                },
                field3 = {
                    text1 = 'MVP Builder:',
                    text2 = mvp.built_entities.name .. ' built ' .. mvp.built_entities.score .. ' things!',
                    inline = 'false'
                },
                field4 = {
                    text1 = 'MVP Miners:',
                    text2 = mvp.mined_entities.name .. ' mined a total of ' .. mvp.mined_entities.score .. ' entities!',
                    inline = 'false'
                }
            }
            Server.to_discord_embed_parsed(message)
            local wave = WD.get_wave()
            local threat = WD.get('threat')
            local collapse_speed = Collapse.get_speed()
            local collapse_amount = Collapse.get_amount()

            local diff = Diff.get()
            if not diff then
                return
            end
            local time_played = Core.format_time(game.ticks_played)
            local total_players = #game.players
            local pickaxe_upgrades = Public.pickaxe_upgrades
            local upgrades = Public.get('upgrades')
            local pick_tier = pickaxe_upgrades[upgrades.pickaxe_tier]

            if Public.get('prestige_system_enabled') then
                RPG_Progression.save_all_players()
            end
            local date = Server.get_start_time()
            game.server_save('Final_Mtn_Fortress_v3_' .. tostring(date))
            local text = {
                title = 'Game over!',
                description = 'Game statistics from the game is below',
                color = 'failure',
                field1 = {
                    text1 = 'Time played:',
                    text2 = time_played,
                    inline = 'true'
                },
                field2 = {
                    text1 = 'Game Difficulty:',
                    text2 = diff.name,
                    inline = 'true',
                    emptyField = 'true',
                    emptyInline = 'true'
                },
                field3 = {
                    text1 = 'Highest wave:',
                    text2 = format_number(wave, true),
                    inline = 'true'
                },
                field4 = {
                    text1 = 'Total connected players:',
                    text2 = total_players,
                    inline = 'true',
                    emptyField = 'true',
                    emptyInline = 'true'
                },
                field5 = {
                    text1 = 'Threat:',
                    text2 = format_number(threat, true),
                    inline = 'true'
                },
                field6 = {
                    text1 = 'Pickaxe Upgrade:',
                    text2 = pick_tier .. ' (' .. upgrades.pickaxe_tier .. ')',
                    inline = 'true',
                    emptyField = 'true',
                    emptyInline = 'true'
                },
                field7 = {
                    text1 = 'Collapse Speed:',
                    text2 = collapse_speed,
                    inline = 'true'
                },
                field8 = {
                    text1 = 'Collapse Amount:',
                    text2 = collapse_amount,
                    inline = 'true',
                    emptyField = 'true',
                    emptyInline = 'true'
                }
            }
            if server_name_matches then
                if wave >= 1000 then
                    Server.to_discord_named_parsed_embed(send_ping_to_channel, text)
                end
            else
                Server.to_discord_embed_parsed(text)
            end

            Public.set('sent_to_discord', true)
        end
    end
end

function Public.unstuck_player(index)
    local player = game.get_player(index)
    local surface = player.surface
    local position = surface.find_non_colliding_position('character', player.position, 32, 0.5)
    if not position then
        return
    end
    player.teleport(position, surface)
end

function Public.loco_died(invalid_locomotive)
    local game_lost = Public.get('game_lost')
    if not game_lost then
        return
    end

    local announced_message = Public.get('announced_message')
    if announced_message then
        return
    end

    local active_surface_index = Public.get('active_surface_index')
    local locomotive = Public.get('locomotive')
    local surface = game.surfaces[active_surface_index]
    local wave_defense_table = WD.get_table()
    if wave_defense_table.game_lost and not invalid_locomotive then
        return
    end
    Collapse.start_now(false)

    for _, player in pairs(game.connected_players) do
        player.play_sound {path = 'utility/game_lost', volume_modifier = 0.75}
        show_mvps(player)
    end

    if not locomotive.valid then
        local this = Public.get()

        local data = {}
        if this.locomotive and this.locomotive.valid then
            data.position = this.locomotive.position
        else
            data.position = {x = 0, y = 0}
        end

        local msg = defeated_messages[random(1, #defeated_messages)]
        Alert.alert_all_players_location(data, msg, nil, 15)

        wave_defense_table.game_lost = true
        wave_defense_table.target = nil

        local params = {
            this = this
        }

        if this.soft_reset then
            this.game_reset_tick = nil
            Task.set_timeout_in_ticks(600, reset_game, params)
            this.announced_message = true
            return
        end
        if this.restart then
            game.print(({'entity.notify_restart'}), {r = 0.22, g = 0.88, b = 0.22})
            Task.set_timeout_in_ticks(600, reset_game, params)
            this.announced_message = true
            return
        end
        if this.shutdown then
            game.print(({'entity.notify_shutdown'}), {r = 0.22, g = 0.88, b = 0.22})
            Task.set_timeout_in_ticks(600, reset_game, params)
            this.announced_message = true
            return
        end

        return
    end

    local this = Public.get()

    this.locomotive_health = 0
    this.locomotive.color = {0.49, 0, 255, 1}
    rendering.set_text(this.health_text, 'HP: ' .. round(this.locomotive_health) .. ' / ' .. round(this.locomotive_max_health))
    wave_defense_table.game_lost = true
    wave_defense_table.target = nil
    local msg = defeated_messages[random(1, #defeated_messages)]

    local pos = {
        position = this.locomotive.position
    }
    Alert.alert_all_players_location(pos, msg)
    game.forces.enemy.set_friend('player', true)
    game.forces.player.set_friend('enemy', true)

    local fake_shooter = surface.create_entity({name = 'character', position = this.locomotive.position, force = 'enemy'})
    surface.create_entity(
        {
            name = 'atomic-rocket',
            position = this.locomotive.position,
            force = 'enemy',
            speed = 1,
            max_range = 1200,
            target = this.locomotive,
            source = fake_shooter
        }
    )

    surface.spill_item_stack(this.locomotive.position, {name = 'coin', count = 512}, false)
    this.game_reset_tick = 5400
    for _, player in pairs(game.connected_players) do
        player.play_sound {path = 'utility/game_lost', volume_modifier = 0.75}
        show_mvps(player)
    end
end

local function on_built_entity(event)
    local entity = event.created_entity
    if not entity.valid then
        return
    end

    local map_name = 'mtn_v3'

    if string.sub(entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local position = entity.position
    local player = game.get_player(event.player_index)

    if entity.name == 'radar' then
        if entity.surface.count_entities_filtered({type = 'radar', position = position, radius = 64}) > 1 then
            player.surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = ({'entity.radar_limit'}),
                    color = {255, 0, 0}
                }
            )

            player.surface.spill_item_stack(position, {name = entity.name, count = 1, true})
            entity.destroy()
            return
        end
    end

    local valid_drills = {
        ['burner-mining-drill'] = true,
        ['electric-mining-drill'] = true
    }

    if valid_drills[entity.name] then
        entity.force = 'bonus_drill'
        return
    end

    local upgrades = Public.get('upgrades')

    local upg = upgrades
    local surface = entity.surface

    local built = {
        ['land-mine'] = upg.landmine.built,
        ['flamethrower-turret'] = upg.flame_turret.built
    }

    local limit = {
        ['land-mine'] = upg.landmine.limit,
        ['flamethrower-turret'] = upg.flame_turret.limit
    }

    local validator = {
        ['land-mine'] = 'landmine',
        ['flamethrower-turret'] = 'flame_turret'
    }

    local name = validator[entity.name]

    if built[entity.name] and entity.force.index == 1 then
        if built[entity.name] < limit[entity.name] then
            upgrades[name].built = built[entity.name] + 1
            upgrades.unit_number[name][entity] = entity
            upgrades.showed_text = false

            surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = upgrades[name].built .. ' / ' .. limit[entity.name] .. ' ' .. entity.name,
                    color = {r = 0.82, g = 0.11, b = 0.11}
                }
            )
        else
            if not upgrades.showed_text then
                surface.create_entity(
                    {
                        name = 'flying-text',
                        position = entity.position,
                        text = ({'entity.entity_limit_reached', entity.name}),
                        color = {r = 0.82, g = 0.11, b = 0.11}
                    }
                )

                upgrades.showed_text = true
            end
            player.insert({name = entity.name, count = 1})
            entity.destroy()
        end
    end
end

local function on_robot_built_entity(event)
    local entity = event.created_entity
    if not entity.valid then
        return
    end

    local map_name = 'mtn_v3'

    if string.sub(entity.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local position = entity.position

    if entity.name == 'radar' then
        if entity.surface.count_entities_filtered({type = 'radar', position = position, radius = 64}) > 1 then
            entity.surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = ({'entity.radar_limit'}),
                    color = {255, 0, 0}
                }
            )

            entity.surface.spill_item_stack(position, {name = entity.name, count = 1, true})
            entity.destroy()
            return
        end
    end

    local valid_drills = {
        ['burner-mining-drill'] = true,
        ['electric-mining-drill'] = true
    }

    if valid_drills[entity.name] then
        entity.force = 'bonus_drill'
        return
    end

    local upgrades = Public.get('upgrades')

    local upg = upgrades
    local surface = entity.surface

    local built = {
        ['land-mine'] = upg.landmine.built,
        ['flamethrower-turret'] = upg.flame_turret.built
    }

    local limit = {
        ['land-mine'] = upg.landmine.limit,
        ['flamethrower-turret'] = upg.flame_turret.limit
    }

    local validator = {
        ['land-mine'] = 'landmine',
        ['flamethrower-turret'] = 'flame_turret'
    }

    local name = validator[entity.name]

    if built[entity.name] and entity.force.index == 1 then
        if built[entity.name] < limit[entity.name] then
            upgrades[name].built = built[entity.name] + 1
            upgrades.unit_number[name][entity] = entity
            upgrades.showed_text = false

            surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = upgrades[name].built .. ' / ' .. limit[entity.name] .. ' ' .. entity.name,
                    color = {r = 0.82, g = 0.11, b = 0.11}
                }
            )
        else
            if not upgrades.showed_text then
                surface.create_entity(
                    {
                        name = 'flying-text',
                        position = entity.position,
                        text = ({'entity.entity_limit_reached', entity.name}),
                        color = {r = 0.82, g = 0.11, b = 0.11}
                    }
                )

                upgrades.showed_text = true
            end
            local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
            inventory.insert({name = entity.name, count = 1})
            entity.destroy()
        end
    end
end

local on_player_or_robot_built_tile = function(event)
    local surface = game.surfaces[event.surface_index]

    local map_name = 'mtn_v3'

    if string.sub(surface.name, 0, #map_name) ~= map_name then
        return
    end

    local tiles = event.tiles
    if not tiles then
        return
    end
    for k, v in pairs(tiles) do
        local old_tile = v.old_tile
        if old_tile.name == 'black-refined-concrete' then
            surface.set_tiles({{name = 'black-refined-concrete', position = v.position}}, true)
        end
        if old_tile.name == 'blue-refined-concrete' then
            surface.set_tiles({{name = 'blue-refined-concrete', position = v.position}}, true)
        end
        if old_tile.name == 'cyan-refined-concrete' then
            surface.set_tiles({{name = 'cyan-refined-concrete', position = v.position}}, true)
        end
        if old_tile.name == 'hazard-concrete-right' then
            surface.set_tiles({{name = 'hazard-concrete-right', position = v.position}}, true)
        end
        if old_tile.name == 'lab-dark-2' then
            surface.set_tiles({{name = 'lab-dark-2', position = v.position}}, true)
        end
    end
end

Public.get_random_weighted = get_random_weighted

Event.add_event_filter(defines.events.on_entity_damaged, {filter = 'final-damage-amount', comparison = '>', value = 0})
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_robot_mined_entity, on_robot_mined_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_player_built_tile, on_player_or_robot_built_tile)
Event.add(defines.events.on_robot_built_tile, on_player_or_robot_built_tile)

return Public
