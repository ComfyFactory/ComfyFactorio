local Global = require 'utils.global'
local Event = require 'utils.event'
local Server = require 'utils.server'
local Token = require 'utils.token'
local shuffle = table.shuffle_table
local WD = require 'modules.wave_defense.table'
local format_number = require 'util'.format_number
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local ICWF = require 'maps.mountain_fortress_v3.icw.functions'
local ICWT = require 'maps.mountain_fortress_v3.icw.table'
local Core = require 'utils.core'
local Public = require 'maps.mountain_fortress_v3.table'
local Task = require 'utils.task'
local Alert = require 'utils.alert'
local IC = require 'maps.mountain_fortress_v3.ic.table'
local RPG = require 'modules.rpg.table'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local Beam = require 'modules.render_beam'

local this = {
    enabled = false,
    rounds_survived = 0,
    buffs = {},
    reset_after = 60
}

local random = math.random
local floor = math.floor
local dataset = 'scenario_settings'
local dataset_key = 'mtn_v3'

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local stateful_spawn_points = {
    {{x = -205, y = -37}, {x = 195, y = 37}},
    {{x = -205, y = -112}, {x = 195, y = 112}},
    {{x = -205, y = -146}, {x = 195, y = 146}},
    {{x = -205, y = -112}, {x = 195, y = 112}},
    {{x = -205, y = -72}, {x = 195, y = 72}},
    {{x = -205, y = -146}, {x = 195, y = 146}},
    {{x = -205, y = -37}, {x = 195, y = 37}},
    {{x = -205, y = -5}, {x = 195, y = 5}},
    {{x = -205, y = -23}, {x = 195, y = 23}},
    {{x = -205, y = -5}, {x = 195, y = 5}},
    {{x = -205, y = -72}, {x = 195, y = 72}},
    {{x = -205, y = -23}, {x = 195, y = 23}},
    {{x = -205, y = -54}, {x = 195, y = 54}},
    {{x = -205, y = -80}, {x = 195, y = 80}},
    {{x = -205, y = -54}, {x = 195, y = 54}},
    {{x = -205, y = -80}, {x = 195, y = 80}},
    {{x = -205, y = -103}, {x = 195, y = 103}},
    {{x = -205, y = -150}, {x = 195, y = 150}},
    {{x = -205, y = -103}, {x = 195, y = 103}},
    {{x = -205, y = -150}, {x = 195, y = 150}}
}

local buff_to_string = {
    ['starting_items'] = 'Starting items',
    ['character_running_speed_modifier'] = 'Movement',
    ['manual_mining_speed_modifier'] = 'Mining',
    ['character_resource_reach_distance_bonus'] = 'Resource reach',
    ['character_item_pickup_distance_bonus'] = 'Item pickup',
    ['character_loot_pickup_distance_bonus'] = 'Loot pickup',
    ['laboratory_speed_modifier'] = 'Laboratory speed',
    ['laboratory_productivity_bonus'] = 'Laboratory productivity',
    ['worker_robots_storage_bonus'] = 'Robot storage',
    ['worker_robots_battery_modifier'] = 'Robot battery',
    ['worker_robots_speed_modifier'] = 'Robot speed',
    ['mining_drill_productivity_bonus'] = 'Mining drill speed',
    ['character_health_bonus'] = 'Character health',
    ['character_reach_distance_bonus'] = 'Reach',
    ['manual_crafting_speed_modifier'] = 'Crafting',
    ['xp_bonus'] = 'XP Bonus',
    ['xp_level'] = 'XP Level'
}

local function get_random_buff()
    local buffs = {
        {
            name = 'character_running_speed_modifier',
            modifier = 'force',
            state = 0.05
        },
        {
            name = 'manual_mining_speed_modifier',
            modifier = 'force',
            state = 0.05
        },
        {
            name = 'character_resource_reach_distance_bonus',
            modifier = 'force',
            state = 0.05
        },
        {
            name = 'character_item_pickup_distance_bonus',
            modifier = 'force',
            state = 0.05
        },
        {
            name = 'character_loot_pickup_distance_bonus',
            modifier = 'force',
            state = 0.05
        },
        {
            name = 'laboratory_speed_modifier',
            modifier = 'force',
            state = 0.05
        },
        {
            name = 'laboratory_productivity_bonus',
            modifier = 'force',
            state = 0.05
        },
        {
            name = 'worker_robots_storage_bonus',
            modifier = 'force',
            state = 0.05
        },
        {
            name = 'worker_robots_battery_modifier',
            modifier = 'force',
            state = 0.05
        },
        {
            name = 'worker_robots_speed_modifier',
            modifier = 'force',
            state = 0.05
        },
        {
            name = 'mining_drill_productivity_bonus',
            modifier = 'force',
            state = 0.05
        },
        {
            name = 'character_health_bonus',
            modifier = 'force',
            state = 50
        },
        {
            name = 'character_reach_distance_bonus',
            modifier = 'force',
            state = 1
        },
        {
            name = 'manual_crafting_speed_modifier',
            modifier = 'force',
            state = 0.04
        },
        {
            name = 'xp_bonus',
            modifier = 'rpg',
            state = 0.02
        },
        {
            name = 'xp_level',
            modifier = 'rpg',
            state = 1
        },
        {
            name = 'starting_items',
            modifier = 'supplies',
            limit = nil,
            items = {
                {name = 'iron-plate', count = 100},
                {name = 'copper-plate', count = 100}
            }
        },
        {
            name = 'starting_items',
            modifier = 'defense',
            limit = nil,
            items = {
                {name = 'gun-turret', count = 2},
                {name = 'firearm-magazine', count = 100}
            }
        },
        {
            name = 'starting_items',
            modifier = 'armor',
            limit = 1,
            items = {
                {name = 'heavy-armor', count = 1}
            }
        },
        {
            name = 'starting_items',
            modifier = 'production',
            limit = nil,
            items = {
                {name = 'stone-furnace', count = 4},
                {name = 'coal', count = 100}
            }
        },
        {
            name = 'starting_items',
            modifier = 'fast-startup',
            limit = nil,
            items = {
                {name = 'assembling-machine', count = 1}
            }
        },
        {
            name = 'starting_items',
            modifier = 'heal-thy-buildings',
            limit = nil,
            items = {
                {name = 'repair-pack', count = 5}
            }
        }
    }

    shuffle(buffs)
    shuffle(buffs)
    shuffle(buffs)
    shuffle(buffs)
    shuffle(buffs)
    shuffle(buffs)

    return buffs[1]
end

local function get_item_produced_count(item_name)
    local force = game.forces.player

    local production = force.item_production_statistics.input_counts[item_name]
    if not production then
        return false
    end

    return production
end

local function get_entity_mined_count(item_name)
    local force = game.forces.player

    local count = 0
    for name, entity_count in pairs(force.entity_build_count_statistics.output_counts) do
        if name:find(item_name) then
            count = count + entity_count
        end
    end

    return count
end

local function get_killed_enemies_count(primary, secondary)
    local force = game.forces.player

    local count = 0
    for name, entity_count in pairs(force.kill_count_statistics.input_counts) do
        if name:find(primary) or name:find(secondary) then
            count = count + entity_count
        end
    end

    return count
end

local move_all_players_token =
    Token.register(
    function()
        Public.move_all_players()
    end
)

local search_corpse_token =
    Token.register(
    function(event)
        local player_index = event.player_index
        local player = game.get_player(player_index)

        if not player or not player.valid then
            return
        end

        local pos = player.position
        local entities =
            player.surface.find_entities_filtered {
            area = {{pos.x - 0.5, pos.y - 0.5}, {pos.x + 0.5, pos.y + 0.5}},
            name = 'character-corpse'
        }

        local entity
        for _, e in ipairs(entities) do
            if e.character_corpse_tick_of_death then
                entity = e
                break
            end
        end

        if not entity or not entity.valid then
            return
        end

        entity.destroy()

        local text = player.name .. "'s corpse was consumed by the biters."

        game.print(text)
    end
)

local function on_pre_player_died(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)

    if not player or not player.valid then
        return
    end

    local surface = player.surface

    local map_name = 'boss_room'

    local corpse_removal_disabled = Public.get('corpse_removal_disabled')
    if corpse_removal_disabled then
        return
    end

    if string.sub(surface.name, 0, #map_name) ~= map_name then
        return
    end

    -- player.ticks_to_respawn = 1800 * (this.rounds_survived + 1)

    Task.set_timeout_in_ticks(5, search_corpse_token, {player_index = player.index})
end

local locomotive_market_pickaxe_token =
    Token.register(
    function(count)
        local upgrades = Public.get('upgrades')
        if upgrades.pickaxe_tier >= count then
            return true, {'stateful.locomotive_market_pickaxe'}, {'stateful.done', count, count}, {'stateful.tooltip_completed'}
        end

        return false, {'stateful.locomotive_market_pickaxe'}, {'stateful.not_done', upgrades.pickaxe_tier, count}, {'stateful.tooltip_not_completed'}
    end
)

local locomotive_market_health_token =
    Token.register(
    function(count)
        local upgrades = Public.get('upgrades')
        if upgrades.health_upgrades >= count then
            return true, {'stateful.locomotive_market_health'}, {'stateful.done', count, count}, {'stateful.tooltip_completed'}
        end

        return false, {'stateful.locomotive_market_health'}, {'stateful.not_done', upgrades.health_upgrades, count}, {'stateful.tooltip_not_completed'}
    end
)

local locomotive_market_xp_points_token =
    Token.register(
    function(count)
        local upgrades = Public.get('upgrades')
        if upgrades.xp_points_upgrade >= count then
            return true, {'stateful.locomotive_market_xp_points'}, {'stateful.done', count, count}, {'stateful.tooltip_completed'}
        end

        return false, {'stateful.locomotive_market_xp_points'}, {'stateful.not_done', upgrades.xp_points_upgrade, count}, {'stateful.tooltip_not_completed'}
    end
)

local empty_token =
    Token.register(
    function()
        return false
    end
)

local killed_enemies_token =
    Token.register(
    function()
        local enemies_killed = Public.get_killed_enemies_count('biter', 'spitter')
        if enemies_killed >= this.objectives.killed_enemies then
            return true, {'stateful.enemies_killed'}, {'stateful.done', format_number(this.objectives.killed_enemies, true), format_number(this.objectives.killed_enemies)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_completed'}
        end

        return false, {'stateful.enemies_killed'}, {'stateful.not_done', format_number(enemies_killed, true), format_number(this.objectives.killed_enemies, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_not_completed'}
    end
)

local complete_mystical_chest_amount_token =
    Token.register(
    function()
        local mystical_chest_completed = Public.get('mystical_chest_completed')
        if mystical_chest_completed >= this.objectives.complete_mystical_chest_amount then
            return true, {'stateful.mystical_chest'}, {'stateful.done', this.objectives.complete_mystical_chest_amount, this.objectives.complete_mystical_chest_amount}, {'stateful.generic_tooltip'}, {'stateful.tooltip_completed'}
        end
        return false, {'stateful.mystical_chest'}, {'stateful.not_done', mystical_chest_completed, this.objectives.complete_mystical_chest_amount}, {'stateful.generic_tooltip'}, {'stateful.tooltip_not_completed'}
    end
)

local research_level_selection_token =
    Token.register(
    function()
        local actual = this.objectives.research_level_count
        local expected = this.objectives.research_level_selection.count
        if actual >= expected then
            return true, {'stateful.research', this.objectives.research_level_selection.name}, {'stateful.done', expected, expected}, {'stateful.generic_tooltip'}, {'stateful.tooltip_completed'}
        end
        return false, {'stateful.research', this.objectives.research_level_selection.name}, {'stateful.not_done', actual, expected}, {'stateful.generic_tooltip'}, {'stateful.tooltip_not_completed'}
    end
)

local trees_farmed_token =
    Token.register(
    function()
        local trees = get_entity_mined_count('tree')
        if trees >= this.objectives.trees_farmed then
            return true, {'stateful.trees_mined'}, {'stateful.done', format_number(this.objectives.trees_farmed, true), format_number(this.objectives.trees_farmed, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_completed'}
        end
        return false, {'stateful.trees_mined'}, {'stateful.not_done', format_number(trees, true), format_number(this.objectives.trees_farmed, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_not_completed'}
    end
)

local rocks_farmed_token =
    Token.register(
    function()
        local rocks = get_entity_mined_count('rock')
        if rocks >= this.objectives.rocks_farmed then
            return true, {'stateful.rocks_mined'}, {'stateful.done', format_number(this.objectives.rocks_farmed, true), format_number(this.objectives.rocks_farmed, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_completed'}
        end
        return false, {'stateful.rocks_mined'}, {'stateful.not_done', format_number(rocks, true), format_number(this.objectives.rocks_farmed, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_not_completed'}
    end
)

local rockets_launched_token =
    Token.register(
    function()
        local launched = game.forces.player.rockets_launched
        if launched >= this.objectives.rockets_launched then
            return true, {'stateful.launch_rockets'}, {'stateful.done', format_number(this.objectives.rockets_launched, true), format_number(this.objectives.rockets_launched, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_completed'}
        end
        return false, {'stateful.launch_rockets'}, {'stateful.not_done', format_number(launched, true), format_number(this.objectives.rockets_launched, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_not_completed'}
    end
)

local function scale(setting, limit, factor)
    factor = factor or 1.15
    local scale_value = floor(setting * (factor ^ this.rounds_survived))
    if limit and scale_value >= limit then
        return limit
    end
    return scale_value
end

local function get_random_items()
    local items = {
        {'iron-plate', random(5000000, 20000000)},
        {'steel-plate', random(400000, 1500000)},
        {'copper-plate', random(5000000, 20000000)},
        {'iron-gear-wheel', random(400000, 1000000)},
        {'iron-stick', random(100000, 300000)},
        {'copper-cable', random(20000000, 50000000)},
        {'electronic-circuit', random(5000000, 20000000)},
        {'advanced-circuit', random(1000000, 2000000)},
        {'processing-unit', random(100000, 400000)},
        {'engine-unit', random(100000, 300000)},
        {'electric-engine-unit', random(50000, 150000)},
        {'rocket-control-unit', random(100000, 200000)},
        {'explosives', random(1000000, 2000000)}
    }

    shuffle(items)
    shuffle(items)

    local container = {
        [1] = {name = items[1][1], count = items[1][2]},
        [2] = {name = items[2][1], count = items[2][2]},
        [3] = {name = items[3][1], count = items[3][2]}
    }

    if this.test_mode then
        container = {
            [1] = {name = items[1].products[1].name, count = 1},
            [2] = {name = items[2].products[1].name, count = 1},
            [3] = {name = items[3].products[1].name, count = 1}
        }
    end

    return container
end

local function get_random_item()
    local items = {
        {'effectivity-module', random(500, 4000)},
        {'effectivity-module-2', random(200, 1000)},
        {'productivity-module', random(50000, 100000)},
        {'productivity-module-2', random(5000, 20000)},
        {'speed-module', random(50000, 200000)},
        {'speed-module-2', random(5000, 25000)}
    }

    shuffle(items)
    shuffle(items)
    shuffle(items)
    shuffle(items)

    return {name = items[1][1], count = items[1][2]}
end

local function get_random_research_recipe()
    -- scale(10, 20)
    local research_level_list = {
        'energy-weapons-damage-7',
        'physical-projectile-damage-7',
        'refined-flammables-7',
        'stronger-explosives-7',
        'mining-productivity-4',
        'worker-robots-speed-6',
        'follower-robot-count-7'
    }

    shuffle(research_level_list)

    if this.test_mode then
        return {name = research_level_list[1], count = 1}
    end

    return {name = research_level_list[1], count = scale(2, 40)}
end

local function get_random_locomotive_tier()
    local tiers = {
        'pickaxe',
        'health',
        'xp_point'
    }

    shuffle(tiers)
    shuffle(tiers)
    shuffle(tiers)
    shuffle(tiers)

    local pickaxe_count = scale(5, 59)
    local health_count = scale(5, 100)
    local xp_points_count = scale(5, 100)

    if this.test_mode then
        pickaxe_count = 1
        health_count = 1
        xp_points_count = 1
    end

    if tiers[1] == 'pickaxe' then
        return {
            locomotive_market_pickaxe_token,
            pickaxe_count
        }
    end

    if tiers[1] == 'health' then
        return {
            locomotive_market_health_token,
            health_count
        }
    end

    if tiers[1] == 'xp_point' then
        return {
            locomotive_market_xp_points_token,
            xp_points_count
        }
    end
end

local function get_random_objectives()
    local items = {
        {
            name = 'supplies',
            token = empty_token
        },
        {
            name = 'single_item',
            token = empty_token
        },
        {
            name = 'killed_enemies',
            token = killed_enemies_token
        },
        {
            name = 'complete_mystical_chest_amount',
            token = complete_mystical_chest_amount_token
        },
        {
            name = 'research_level_selection',
            token = research_level_selection_token
        },
        {
            name = 'locomotive_market_selection',
            token = empty_token
        },
        {
            name = 'trees_farmed',
            token = trees_farmed_token
        },
        {
            name = 'rocks_farmed',
            token = rocks_farmed_token
        },
        {
            name = 'rockets_launched',
            token = rockets_launched_token
        }
    }

    shuffle(items)

    return {
        items[1],
        items[2],
        items[3]
    }
end

local function apply_buffs(starting_items)
    if this.buffs and next(this.buffs) then
        if not this.buffs_collected then
            this.buffs_collected = {}
        end

        local force = game.forces.player
        for _, buff in pairs(this.buffs) do
            if buff then
                if buff.modifier == 'force' then
                    force[buff.name] = force[buff.name] + buff.state

                    if not this.buffs_collected[buff.name] then
                        this.buffs_collected[buff.name] = buff.state
                    else
                        this.buffs_collected[buff.name] = this.buffs_collected[buff.name] + buff.state
                    end
                end
                if buff.modifier == 'rpg' then
                    local rpg_extra = RPG.get('rpg_extra')
                    if buff.name == 'xp_bonus' then
                        if not rpg_extra.difficulty then
                            rpg_extra.difficulty = buff.state
                        else
                            rpg_extra.difficulty = rpg_extra.difficulty + buff.state
                        end
                        if not this.buffs_collected['xp_bonus'] then
                            this.buffs_collected['xp_bonus'] = buff.state
                        else
                            this.buffs_collected['xp_bonus'] = this.buffs_collected['xp_bonus'] + buff.state
                        end
                    end
                    if buff.name == 'xp_level' then
                        if not rpg_extra.grant_xp_level then
                            rpg_extra.grant_xp_level = buff.state
                        else
                            rpg_extra.grant_xp_level = rpg_extra.grant_xp_level + buff.state
                        end
                        if not this.buffs_collected['xp_level'] then
                            this.buffs_collected['xp_level'] = buff.state
                        else
                            this.buffs_collected['xp_level'] = this.buffs_collected['xp_level'] + buff.state
                        end
                    end
                end
                if buff.modifier == 'starting_items' then
                    if not this.buffs_collected['starting_items'] then
                        this.buffs_collected['starting_items'] = {}
                    end
                    for _, item in pairs(buff.items) do
                        if item then
                            if starting_items[item.name] and item.limit and item.limit == 1 then
                                break -- break if the limit is 1
                            end

                            if starting_items[item.name] then
                                starting_items[item.name] = starting_items[item.name] + item.count
                            else
                                starting_items[item.name] = item.count
                            end
                            if not this.buffs_collected['starting_items'][item.name] then
                                this.buffs_collected['starting_items'][item.name] = item.count
                            else
                                this.buffs_collected['starting_items'][item.name] = starting_items[item.name] + item.count
                            end
                        end
                    end
                end
            end
        end
    end
end

local function apply_startup_settings(settings)
    local new_value = Server.get_current_date()
    if not new_value then
        return
    end
    settings = settings or {}
    local old_value = this.current_date
    if old_value then
        old_value = tonumber(old_value)
        local time_to_reset = (new_value - old_value)
        if time_to_reset then
            if time_to_reset > this.reset_after then
                settings.current_date = tonumber(new_value)
                settings.test_mode = false
                settings.rounds_survived = 0
                settings.buffs = {}
                this.buffs = {}
                this.buffs_collected = {}
                this.rounds_survived = 0
                this.current_date = tonumber(new_value)
                local message = ({'stateful.reset'})
                local message_discord = ({'stateful.reset_discord'})
                game.print(message)
                Server.to_discord_embed(message_discord, true)

                Server.set_data(dataset, dataset_key, settings)
            end
        end
    end

    local starting_items = Public.get_func('starting_items')

    apply_buffs(starting_items)
    return settings
end

local apply_settings_token =
    Token.register(
    function(data)
        local settings = data and data.value or nil
        local new_value = Server.get_current_date()
        if not new_value then
            return
        end

        if not settings then
            settings = {
                rounds_survived = 0,
                current_date = tonumber(new_value)
            }
            Server.set_data(dataset, dataset_key, settings)
            return
        end

        Public.reset_stateful()

        this.current_date = settings.current_date
        this.buffs = settings.buffs

        settings = apply_startup_settings(settings)

        this.rounds_survived = settings.rounds_survived

        Public.increase_enemy_damage_and_health()

        Server.set_data(dataset, dataset_key, settings)
    end
)

function Public.save_settings()
    this.buffs[#this.buffs + 1] = get_random_buff()

    local settings = {
        rounds_survived = this.rounds_survived,
        test_mode = this.test_mode,
        buffs = this.buffs
    }

    Server.set_data(dataset, dataset_key, settings)
end

function Public.reset_stateful(refresh_gui)
    this.test_mode = false
    this.objectives_completed = {}
    this.objectives_completed_count = 0
    this.final_battle = false
    this.buffs_collected = {}

    this.selected_objectives = get_random_objectives()
    if this.test_mode then
        this.objectives = {
            randomized_zone = 2,
            randomized_wave = 2,
            randomized_linked_chests = 2,
            supplies = get_random_items(),
            single_item = get_random_item(),
            killed_enemies = 10,
            complete_mystical_chest_amount = 1,
            research_level_selection = get_random_research_recipe(),
            research_level_count = 0,
            locomotive_market_selection = get_random_locomotive_tier(),
            trees_farmed = 10,
            rocks_farmed = 10,
            rockets_launched = 1
        }
    else
        this.objectives = {
            randomized_zone = scale(5, 30, 1.2),
            randomized_wave = scale(300, 2000),
            randomized_linked_chests = scale(2, 20),
            supplies = get_random_items(),
            single_item = get_random_item(),
            killed_enemies = scale(125000, 10000000),
            complete_mystical_chest_amount = scale(3, 20),
            research_level_selection = get_random_research_recipe(),
            research_level_count = 0,
            locomotive_market_selection = get_random_locomotive_tier(),
            trees_farmed = scale(10000, 400000),
            rocks_farmed = scale(50000, 4000000),
            rockets_launched = scale(40, 700)
        }
    end
    this.collection = {
        time_until_attack = nil,
        time_until_attack_timer = nil,
        survive_for = nil,
        survive_for_timer = nil,
        final_arena_disabled = true
    }
    this.stateful_locomotive_migrated = false
    this.force_chunk = true

    local t = {
        ['randomized_zone'] = this.objectives.randomized_zone,
        ['randomized_wave'] = this.objectives.randomized_wave,
        ['randomized_linked_chests'] = this.objectives.randomized_linked_chests,
        ['research_level_count'] = this.objectives.research_level_count
    }
    for index = 1, #this.selected_objectives do
        local objective = this.selected_objectives[index]
        if not t[objective.name] then
            t[objective.name] = this.objectives[objective.name]
        end
    end

    this.objectives = t

    if refresh_gui then
        Public.refresh_frames()
    end
end

function Public.migrate_and_create(locomotive)
    local carriages = Public.get('carriages')
    local surface = game.get_surface('boss_room')
    if not surface or not surface.valid then
        return
    end
    local position = locomotive.position
    local inc = 6
    local new_position = {x = position.x, y = position.y + inc}

    for index, entity in pairs(carriages) do
        if index ~= 1 then
            if entity and entity.valid and entity.unit_number ~= locomotive.unit_number then
                local new_wagon = surface.create_entity({name = entity.name, position = new_position, force = 'player', defines.direction.north})
                if new_wagon and new_wagon.valid then
                    inc = inc + 7
                    new_position = {x = position.x, y = position.y + inc}
                    ICW.migrate_wagon(entity, new_wagon)
                end
            end
        end
    end
end

function Public.move_all_players()
    local market = Public.get('market')
    if not market or not market.valid then
        return
    end

    local surface = market.surface
    if not surface or not surface.valid then
        return
    end

    local spawn_pos = surface.find_non_colliding_position('character', market.position, 3, 0, 5)

    if spawn_pos then
        game.forces.player.set_spawn_position(spawn_pos, surface)
    else
        game.forces.player.set_spawn_position(market.position, surface)
    end

    ICWF.disable_auto_minimap()

    local message = ({'stateful.final_boss_message_start'})
    Alert.alert_all_players(50, message, nil, nil, 1)
    Core.iter_connected_players(
        function(player)
            local pos = surface.find_non_colliding_position('character', market.position, 3, 0, 5)

            Public.stateful_gui.boss_frame(player, true)

            if pos then
                player.teleport(pos, surface)
            else
                pos = market.position
                player.teleport(pos, surface)
                Public.unstuck_player(player.index)
            end
        end
    )
end

function Public.set_final_battle()
    WD.set_es('final_battle', true)
    this.final_battle = true
    Public.set('final_battle', true)
end

function Public.allocate()
    local stateful_locomotive = Public.get_stateful('stateful_locomotive')
    local stateful_locomotive_migrated = Public.get_stateful('stateful_locomotive_migrated')
    if stateful_locomotive and not stateful_locomotive_migrated then
        Task.set_timeout_in_ticks(100, move_all_players_token, {})

        Beam.new_valid_targets({'wall', 'turret', 'furnace', 'gate'})

        Public.soft_reset.add_schedule_to_delete_surface()
        Public.set_stateful('stateful_locomotive_migrated', true)
        local locomotive = Public.get('locomotive')
        local icw_data = ICW.migrate_wagon(locomotive, stateful_locomotive)
        local surface = game.get_surface('boss_room')
        if not surface or not surface.valid then
            return
        end

        ICWT.set('speed', 0.3)
        ICWT.set('final_battle', true)

        IC.set('allowed_surface', 'boss_room')

        local collection = Public.get_stateful('collection')
        if not collection then
            return
        end

        Server.to_discord_embed('Final boss wave is occuring soon!')

        WD.set('final_battle', true)

        Core.iter_connected_players(
            function(player)
                local wd = player.gui.top['wave_defense']
                if wd and wd.valid then
                    wd.destroy()
                end
            end
        )

        collection.time_until_attack = 54000 + game.tick
        collection.time_until_attack_timer = 54000 + game.tick

        Public.set_target(stateful_locomotive, icw_data)
        game.forces.player.chart(surface, {{-358, -151}, {358, 151}})
        Public.migrate_and_create(stateful_locomotive)
    end
end

function Public.set_target(target, icw_data)
    Public.set('locomotive', target)
    local wave_defense_table = WD.get()
    wave_defense_table.surface_index = game.get_surface('boss_room').index
    wave_defense_table.target = target
    wave_defense_table.enable_side_target = false
    wave_defense_table.spawn_position = {x = -206, y = -80}
    Public.set('active_surface_index', game.get_surface('boss_room').index)
    BiterHealthBooster.set('active_surface', game.get_surface('boss_room').name)
    Public.set('icw_locomotive', icw_data)
    Public.render_train_hp()
end

function Public.increase_enemy_damage_and_health()
    if this.rounds_survived == 1 then
        Event.raise(WD.events.on_biters_evolved, {force = game.forces.aggressors})
        Event.raise(WD.events.on_biters_evolved, {force = game.forces.aggressors_frenzy})
    else
        for _ = 1, this.rounds_survived do
            Event.raise(WD.events.on_biters_evolved, {force = game.forces.aggressors})
            Event.raise(WD.events.on_biters_evolved, {force = game.forces.aggressors_frenzy})
        end
    end
end

function Public.get_stateful(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set_stateful(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

function Public.remove_stateful(key, sub_key)
    if key and sub_key then
        if this[key] and this[key][sub_key] then
            this[key][sub_key] = nil
        end
    elseif key then
        if this[key] then
            this[key] = nil
        end
    end
end

function Public.enable(state)
    this.enabled = state or false
end

Event.on_init(Public.reset_stateful)

Event.add(
    Server.events.on_server_started,
    function()
        if this.settings_applied then
            return
        end

        this.settings_applied = true

        Server.try_get_data(dataset, dataset_key, apply_settings_token)
    end
)

Public.buff_to_string = buff_to_string
Public.get_random_buff = get_random_buff
Public.get_item_produced_count = get_item_produced_count
Public.get_entity_mined_count = get_entity_mined_count
Public.get_killed_enemies_count = get_killed_enemies_count
Public.apply_startup_settings = apply_startup_settings
Public.scale = scale
Public.stateful_spawn_points = stateful_spawn_points
Public.sizeof_stateful_spawn_points = #stateful_spawn_points
Public.on_pre_player_died = on_pre_player_died

return Public
