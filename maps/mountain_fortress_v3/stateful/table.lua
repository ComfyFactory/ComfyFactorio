local Global = require 'utils.global'
local Event = require 'utils.event'
local Utils = require 'utils.utils'
local Server = require 'utils.server'
local Task = require 'utils.task_token'
local shuffle = table.shuffle_table
local WD = require 'modules.wave_defense.table'
local format_number = require 'util'.format_number
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local ICWF = require 'maps.mountain_fortress_v3.icw.functions'
local ICWT = require 'maps.mountain_fortress_v3.icw.table'
local Core = require 'utils.core'
local Public = require 'maps.mountain_fortress_v3.table'
local Alert = require 'utils.alert'
local IC = require 'maps.mountain_fortress_v3.ic.table'
local RPG = require 'modules.rpg.table'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local Beam = require 'modules.render_beam'
local Discord = require 'utils.discord'

local this = {
    enabled = false,
    rounds_survived = 0,
    season = 1,
    buffs = {},
    reset_after = 60,
    time_to_reset = 60
}

local round = math.round
local floor = math.floor
local dataset = 'scenario_settings'
local dataset_key = 'mtn_v3'
local dataset_key_dev = 'mtn_v3_dev'
local dataset_key_previous = 'mtn_v3_previous'
local send_ping_to_channel = Discord.channel_names.mtn_channel

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
    ['distance'] = 'All distance modifiers',
    ['manual_crafting_speed_modifier'] = 'Crafting',
    ['xp_bonus'] = 'XP Points',
    ['xp_level'] = 'XP Level'
}

local function notify_season_over_to_discord()
    local server_name_matches = Server.check_server_name('Mtn Fortress')

    local stateful = Public.get_stateful()

    local buffs = ''
    if stateful.buffs and next(stateful.buffs) then
        if stateful.buffs_collected and next(stateful.buffs_collected) then
            if stateful.buffs_collected.starting_items then
                buffs = buffs .. 'Starting items:\n'
                for item_name, item_data in pairs(stateful.buffs_collected.starting_items) do
                    buffs = buffs .. item_name .. ': ' .. item_data.count
                    buffs = buffs .. '\n'
                end
                buffs = buffs .. '\n'
            end

            buffs = buffs .. 'Force buffs:\n'
            for name, buff_data in pairs(stateful.buffs_collected) do
                if type(buff_data.amount) ~= 'table' and name ~= 'starting_items' then
                    if name == 'xp_level' or name == 'xp_bonus' or name == 'character_health_bonus' then
                        buffs = buffs .. buff_to_string[name] .. ': ' .. buff_data.count
                    else
                        buffs = buffs .. buff_to_string[name] .. ': ' .. (buff_data.count * 100) .. '%'
                    end
                    buffs = buffs .. '\n'
                end
            end
        end
    end

    local text = {
        title = 'Season: ' .. stateful.season .. ' is over!',
        description = 'Game statistics from the season is below',
        color = 'success',
        field1 = {
            text1 = 'Rounds survived:',
            text2 = stateful.rounds_survived,
            inline = 'false'
        },
        field2 = {
            text1 = 'Buffs granted:',
            text2 = buffs,
            inline = 'false'
        }
    }
    if server_name_matches then
        Server.to_discord_named_parsed_embed(send_ping_to_channel, text)
    else
        Server.to_discord_embed_parsed(text)
    end
end

local function get_random_force_buff(fetch_all)
    local buffs = {
        {
            name = 'character_running_speed_modifier',
            discord = 'Running speed modifier',
            modifier = 'force',
            state = 0.05
        },
        {
            name = 'manual_mining_speed_modifier',
            discord = 'Mining speed modifier',
            modifier = 'force',
            state = 0.15
        },
        {
            name = 'laboratory_speed_modifier',
            discord = 'Laboratory speed modifier',
            modifier = 'force',
            state = 0.15
        },
        {
            name = 'laboratory_productivity_bonus',
            discord = 'Productivity bonus',
            modifier = 'force',
            state = 0.15
        },
        {
            name = 'worker_robots_storage_bonus',
            discord = 'Robot storage bonus',
            modifier = 'force',
            state = 1
        },
        {
            name = 'worker_robots_battery_modifier',
            discord = 'Robot battery bonus',
            modifier = 'force',
            state = 1
        },
        {
            name = 'worker_robots_speed_modifier',
            discord = 'Robot speed modifier',
            modifier = 'force',
            state = 0.5
        },
        {
            name = 'mining_drill_productivity_bonus',
            discord = 'Drill productivity bonus',
            modifier = 'force',
            state = 0.5
        },
        {
            name = 'character_health_bonus',
            discord = 'Character health bonus',
            modifier = 'force',
            state = 250
        },
        {
            name = 'distance',
            discord = 'RPG reach distance bonus',
            modifier = 'rpg_distance',
            modifiers = {'character_resource_reach_distance_bonus', 'character_item_pickup_distance_bonus', 'character_loot_pickup_distance_bonus', 'character_reach_distance_bonus'},
            state = 0.05
        },
        {
            name = 'manual_crafting_speed_modifier',
            discord = 'Crafting speed modifier',
            modifier = 'force',
            state = 0.12
        },
        {
            name = 'xp_bonus',
            discord = 'RPG XP point bonus',
            modifier = 'rpg',
            state = 0.12
        },
        {
            name = 'xp_level',
            discord = 'RPG XP level bonus',
            modifier = 'rpg',
            state = 20
        }
    }

    if fetch_all then
        return buffs
    end

    shuffle(buffs)
    shuffle(buffs)
    shuffle(buffs)
    shuffle(buffs)
    shuffle(buffs)
    shuffle(buffs)

    return buffs[1]
end

local function get_random_buff(fetch_all)
    local buffs = {
        {
            name = 'character_running_speed_modifier',
            discord = 'Running speed modifier',
            modifier = 'force',
            state = 0.05
        },
        {
            name = 'manual_mining_speed_modifier',
            discord = 'Mining speed modifier',
            modifier = 'force',
            state = 0.15
        },
        {
            name = 'laboratory_speed_modifier',
            discord = 'Laboratory speed modifier',
            modifier = 'force',
            state = 0.15
        },
        {
            name = 'laboratory_productivity_bonus',
            discord = 'Productivity bonus',
            modifier = 'force',
            state = 0.15
        },
        {
            name = 'worker_robots_storage_bonus',
            discord = 'Robot storage bonus',
            modifier = 'force',
            state = 1
        },
        {
            name = 'worker_robots_battery_modifier',
            discord = 'Robot battery bonus',
            modifier = 'force',
            state = 1
        },
        {
            name = 'worker_robots_speed_modifier',
            discord = 'Robot speed modifier',
            modifier = 'force',
            state = 0.5
        },
        {
            name = 'mining_drill_productivity_bonus',
            discord = 'Drill productivity bonus',
            modifier = 'force',
            state = 0.5
        },
        {
            name = 'character_health_bonus',
            discord = 'Character health bonus',
            modifier = 'force',
            state = 250
        },
        {
            name = 'distance',
            discord = 'RPG reach distance bonus',
            modifier = 'rpg_distance',
            modifiers = {'character_resource_reach_distance_bonus', 'character_item_pickup_distance_bonus', 'character_loot_pickup_distance_bonus', 'character_reach_distance_bonus'},
            state = 0.05
        },
        {
            name = 'manual_crafting_speed_modifier',
            discord = 'Crafting speed modifier',
            modifier = 'force',
            state = 0.12
        },
        {
            name = 'xp_bonus',
            discord = 'RPG XP point bonus',
            modifier = 'rpg',
            state = 0.12
        },
        {
            name = 'xp_level',
            discord = 'RPG XP level bonus',
            modifier = 'rpg',
            state = 20
        },
        {
            name = 'supplies',
            discord = 'Starting items supplies',
            modifier = 'starting_items',
            limit = 1000,
            add_per_buff = 100,
            items = {
                {name = 'iron-plate', count = 100},
                {name = 'copper-plate', count = 100}
            }
        },
        {
            name = 'supplies_1',
            discord = 'Starting items supplies',
            modifier = 'starting_items',
            limit = 1000,
            add_per_buff = 200,
            items = {
                {name = 'iron-plate', count = 200},
                {name = 'copper-plate', count = 200}
            }
        },
        {
            name = 'supplies_2',
            discord = 'Starting items supplies',
            modifier = 'starting_items',
            limit = 1000,
            add_per_buff = 400,
            items = {
                {name = 'iron-plate', count = 400},
                {name = 'copper-plate', count = 400}
            }
        },
        {
            name = 'defense',
            discord = 'Defense starting supplies',
            modifier = 'starting_items',
            limit = 10,
            add_per_buff = 1,
            items = {
                {name = 'gun-turret', count = 2},
                {name = 'firearm-magazine', count = 25}
            }
        },
        {
            name = 'defense_2',
            discord = 'Defense starting supplies',
            modifier = 'starting_items',
            limit = 10,
            add_per_buff = 1,
            items = {
                {name = 'grenade', count = 25},
                {name = 'poison-capsule', count = 15}
            }
        },
        {
            name = 'defense_3',
            discord = 'Defense starting supplies',
            modifier = 'starting_items',
            limit = 1,
            add_per_buff = 1,
            items = {
                {name = 'rocket-launcher', count = 1},
                {name = 'rocket', count = 100}
            }
        },
        {
            name = 'armor',
            discord = 'Armor starting supplies',
            modifier = 'starting_items',
            limit = 1,
            add_per_buff = 1,
            items = {
                {name = 'modular-armor', count = 1},
                {name = 'solar-panel-equipment', count = 2}
            }
        },
        {
            name = 'production',
            discord = 'Production starting supplies',
            modifier = 'starting_items',
            limit = 2,
            add_per_buff = 1,
            items = {
                {name = 'stone-furnace', count = 4},
                {name = 'coal', count = 100}
            }
        },
        {
            name = 'production_1',
            discord = 'Production starting supplies',
            modifier = 'starting_items',
            limit = 2,
            add_per_buff = 1,
            items = {
                {name = 'steel-furnace', count = 4},
                {name = 'solid-fuel', count = 100}
            }
        },
        {
            name = 'fast_startup',
            discord = 'Assembling starting supplies',
            modifier = 'starting_items',
            limit = 25,
            add_per_buff = 2,
            items = {
                {name = 'assembling-machine-1', count = 2}
            }
        },
        {
            name = 'fast_startup_1',
            discord = 'Assembling starting supplies',
            modifier = 'starting_items',
            limit = 25,
            add_per_buff = 2,
            items = {
                {name = 'assembling-machine-2', count = 2}
            }
        },
        {
            name = 'fast_startup_2',
            discord = 'Assembling starting supplies',
            modifier = 'starting_items',
            limit = 25,
            add_per_buff = 2,
            items = {
                {name = 'assembling-machine-3', count = 2}
            }
        },
        {
            name = 'heal-thy-buildings',
            discord = 'Repair starting supplies',
            modifier = 'starting_items',
            limit = 20,
            add_per_buff = 2,
            items = {
                {name = 'repair-pack', count = 5}
            }
        },
        {
            name = 'extra_wagons',
            discord = 'Extra wagon at start',
            modifier = 'locomotive',
            state = 1
        }
    }

    if fetch_all then
        return buffs
    end

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
    Task.register(
    function()
        Public.move_all_players()
    end
)

local search_corpse_token =
    Task.register(
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

local function on_market_item_purchased(event)
    if not event.cost then
        return
    end

    local coins = this.objectives.locomotive_market_coins_spent
    if not coins then
        return
    end

    coins.spent = coins.spent + event.cost
end

local empty_token =
    Task.register(
    function()
        return false
    end
)

local killed_enemies_token =
    Task.register(
    function()
        local actual = Public.get_killed_enemies_count('biter', 'spitter')
        local expected = this.objectives.killed_enemies
        if actual >= expected then
            return true, {'stateful.enemies_killed'}, {'stateful.done', format_number(expected, true), format_number(expected, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_completed'}
        end

        return false, {'stateful.enemies_killed'}, {'stateful.not_done', format_number(actual, true), format_number(expected, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_not_completed'}
    end
)

local research_level_selection_token =
    Task.register(
    function()
        local actual = this.objectives.research_level_selection.research_count
        local expected = this.objectives.research_level_selection.count
        if actual >= expected then
            return true, {'stateful.research', this.objectives.research_level_selection.name}, {'stateful.done', expected, expected}, {'stateful.generic_tooltip'}, {'stateful.tooltip_completed'}
        end
        return false, {'stateful.research', this.objectives.research_level_selection.name}, {'stateful.not_done', actual, expected}, {'stateful.generic_tooltip'}, {'stateful.tooltip_not_completed'}
    end
)

local locomotive_market_coins_spent_token =
    Task.register(
    function()
        local coins = this.objectives.locomotive_market_coins_spent
        local actual = coins.spent
        local expected = coins.required
        if actual >= expected then
            return true, {'stateful.market_spent'}, {'stateful.done', format_number(expected, true), format_number(expected, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_completed'}
        end
        return false, {'stateful.market_spent'}, {'stateful.not_done', format_number(actual, true), format_number(expected, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_not_completed'}
    end
)

local trees_farmed_token =
    Task.register(
    function()
        local actual = get_entity_mined_count('tree')
        local expected = this.objectives.trees_farmed
        if actual >= expected then
            return true, {'stateful.trees_mined'}, {'stateful.done', format_number(expected, true), format_number(expected, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_completed'}
        end
        return false, {'stateful.trees_mined'}, {'stateful.not_done', format_number(actual, true), format_number(expected, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_not_completed'}
    end
)

local rocks_farmed_token =
    Task.register(
    function()
        local actual = get_entity_mined_count('rock')
        local expected = this.objectives.rocks_farmed
        if actual >= expected then
            return true, {'stateful.rocks_mined'}, {'stateful.done', format_number(expected, true), format_number(expected, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_completed'}
        end
        return false, {'stateful.rocks_mined'}, {'stateful.not_done', format_number(actual, true), format_number(expected, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_not_completed'}
    end
)

local rockets_launched_token =
    Task.register(
    function()
        local actual = game.forces.player.rockets_launched
        local expected = this.objectives.rockets_launched
        if actual >= expected then
            return true, {'stateful.launch_rockets'}, {'stateful.done', format_number(expected, true), format_number(expected, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_completed'}
        end
        return false, {'stateful.launch_rockets'}, {'stateful.not_done', format_number(actual, true), format_number(expected, true)}, {'stateful.generic_tooltip'}, {'stateful.tooltip_not_completed'}
    end
)

local function scale(setting, limit, factor)
    factor = factor or 1.05
    local scale_value = floor(setting * (factor ^ this.rounds_survived))
    if limit and scale_value >= limit then
        return limit
    end
    return floor(scale_value)
end

local function get_random_items()
    local items = {
        {'advanced-circuit', scale(225000, 9000000)},
        {'copper-cable', scale(3000000, 120000000)},
        {'copper-plate', scale(1500000, 60000000)},
        {'electric-engine-unit', scale(10000, 400000)},
        {'electronic-circuit', scale(1000000, 40000000)},
        {'engine-unit', scale(20000, 800000)},
        {'explosives', scale(150000, 6000000)},
        {'iron-gear-wheel', scale(150000, 6000000)},
        {'iron-plate', scale(2000000, 80000000)},
        {'iron-stick', scale(75000, 3000000)},
        {'processing-unit', scale(40000, 1600000)},
        {'rocket-control-unit', scale(8000, 320000)},
        {'steel-plate', scale(200000, 8000000)},
        {'rocket', scale(25000, 1000000)},
        {'explosive-rocket', scale(25000, 1000000)},
        {'slowdown-capsule', scale(10000, 400000)},
        {'laser-turret', scale(3000, 120000)},
        {'stone-wall', scale(20000, 800000)},
        {'accumulator', scale(5000, 200000)},
        {'refined-concrete', scale(15000, 600000)},
        {'uranium-rounds-magazine', scale(4000, 160000)},
        {'explosive-uranium-cannon-shell', scale(3000, 120000)},
        {'distractor-capsule', scale(1500, 60000)},
        {'cluster-grenade', scale(4000, 160000)},
        {'small-lamp', scale(5000, 200000)},
        {'uranium-fuel-cell', scale(2500, 100000)}
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
        {'effectivity-module', scale(1000, 400000)},
        {'productivity-module', scale(10000, 400000)},
        {'speed-module', scale(10000, 400000)},
        {'effectivity-module-2', scale(200, 100000)},
        {'productivity-module-2', scale(1000, 100000)},
        {'speed-module-2', scale(1000, 100000)},
        {'effectivity-module-3', scale(50, 30000)},
        {'productivity-module-3', scale(500, 30000)},
        {'speed-module-3', scale(500, 30000)}
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
        'stronger-explosives-7',
        'mining-productivity-4',
        'worker-robots-speed-6',
        'follower-robot-count-7'
    }

    shuffle(research_level_list)

    if this.test_mode then
        return {name = research_level_list[1], count = 1, research_count = 0}
    end

    return {name = research_level_list[1], count = scale(2, 40, 1.03), research_count = 0}
end

local function get_random_objectives()
    local items = {
        {
            name = 'single_item',
            token = empty_token
        },
        {
            name = 'killed_enemies',
            token = killed_enemies_token
        },
        {
            name = 'research_level_selection',
            token = research_level_selection_token
        },
        {
            name = 'locomotive_market_coins_spent',
            token = locomotive_market_coins_spent_token
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
        {
            name = 'supplies',
            token = empty_token
        },
        items[2],
        items[3]
    }
end

local function clear_all_stats()
    this.buffs_collected = {}
    this.extra_wagons = 0
    local rpg_extra = RPG.get('rpg_extra')
    rpg_extra.difficulty = 0
    rpg_extra.grant_xp_level = 0
end

local function migrate_buffs()
    local state_buffs = get_random_buff(true)

    for _, data in pairs(state_buffs) do
        for _, buff in pairs(this.buffs) do
            if data.name == buff.name then
                if data.add_per_buff then
                    buff.add_per_buff = data.add_per_buff
                end
                if buff.replaces then
                    buff.replaces = nil
                end

                if buff.modifier == 'starting_items_1' then
                    buff.modifier = 'starting_items'
                end

                if data.items and type(data.items) == 'table' then
                    buff.items = data.items
                end

                if data.limit and not buff.limit then
                    buff.limit = data.limit
                    buff.name = data.name
                end
            end
        end
    end
end

local function apply_buffs()
    local starting_items = Public.get_func('starting_items')

    if this.buffs and next(this.buffs) then
        if not this.buffs_collected then
            this.buffs_collected = {}
        end

        migrate_buffs()

        local force = game.forces.player
        for _, buff in pairs(this.buffs) do
            if buff then
                if buff.modifier == 'rpg_distance' then
                    for _, buff_name in pairs(buff.modifiers) do
                        if buff_name == 'character_reach_distance_bonus' then
                            buff.state = 1
                        end

                        force[buff_name] = force[buff_name] + buff.state

                        if not this.buffs_collected[buff_name] then
                            this.buffs_collected[buff_name] = {
                                count = buff.state
                            }
                        else
                            this.buffs_collected[buff_name].count = this.buffs_collected[buff_name].count + buff.state
                        end
                    end
                end
                if buff.modifier == 'force' then
                    force[buff.name] = force[buff.name] + buff.state

                    if not this.buffs_collected[buff.name] then
                        this.buffs_collected[buff.name] = {
                            count = buff.state
                        }
                    else
                        this.buffs_collected[buff.name].count = this.buffs_collected[buff.name].count + buff.state
                    end
                end
                if buff.modifier == 'locomotive' then
                    local extra_wagons = Public.get('extra_wagons')
                    if not extra_wagons then
                        this.extra_wagons = buff.state
                    else
                        this.extra_wagons = this.extra_wagons + buff.state
                    end

                    if this.extra_wagons > 4 then
                        this.extra_wagons = 4
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
                            this.buffs_collected['xp_bonus'] = {
                                count = buff.state
                            }
                        else
                            this.buffs_collected['xp_bonus'].count = this.buffs_collected['xp_bonus'].count + buff.state
                        end
                    end
                    if buff.name == 'xp_level' then
                        if not rpg_extra.grant_xp_level then
                            rpg_extra.grant_xp_level = buff.state
                        else
                            rpg_extra.grant_xp_level = rpg_extra.grant_xp_level + buff.state
                        end
                        if not this.buffs_collected['xp_level'] then
                            this.buffs_collected['xp_level'] = {
                                count = buff.state
                            }
                        else
                            this.buffs_collected['xp_level'].count = this.buffs_collected['xp_level'].count + buff.state
                        end
                    end
                end
                if buff.modifier == 'starting_items' then
                    if not this.buffs_collected['starting_items'] then
                        this.buffs_collected['starting_items'] = {}
                    end
                    for _, item in pairs(buff.items) do
                        if item then
                            if starting_items[item.name] and buff.limit and starting_items[item.name].item_limit and starting_items[item.name].item_limit >= buff.limit then
                                starting_items[item.name].limit_reached = true
                                break -- break if there is a limit set
                            end

                            if starting_items[item.name] then
                                starting_items[item.name].count = starting_items[item.name].count + item.count
                                starting_items[item.name].item_limit = starting_items[item.name].item_limit and starting_items[item.name].item_limit + buff.add_per_buff or buff.add_per_buff
                                starting_items[item.name].buff_type = buff.name
                            else
                                starting_items[item.name] = {
                                    buff_type = buff.name,
                                    count = item.count,
                                    item_limit = buff.add_per_buff
                                }
                            end
                            if this.buffs_collected['starting_items'][item.name] then
                                this.buffs_collected['starting_items'][item.name].count = this.buffs_collected['starting_items'][item.name].count + item.count
                                this.buffs_collected['starting_items'][item.name].buff_type = buff.name
                            else
                                this.buffs_collected['starting_items'][item.name] = {
                                    buff_type = buff.name,
                                    count = item.count
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    Public.equip_players(starting_items)
end

local function apply_startup_settings(settings)
    local current_date = Server.get_current_date(false, true)
    if not current_date then
        return
    end

    local current_time = Server.get_current_time()
    if not current_time then
        return
    end

    current_date = round(Utils.convert_date(current_date.year, current_date.month, current_date.day))

    local server_name_matches = Server.check_server_name('Mtn Fortress')

    settings = settings or {}
    local stored_date = this.current_date
    if not stored_date then
        return
    end
    local stored_date_raw = Server.get_current_date(false, true, stored_date)
    local converted_stored_date = round(Utils.convert_date(stored_date_raw.year, stored_date_raw.month, stored_date_raw.day))

    local time_to_reset = (current_date - converted_stored_date)
    this.time_to_reset = this.reset_after - time_to_reset

    if time_to_reset and time_to_reset > this.reset_after then
        if server_name_matches then
            Server.set_data(dataset, dataset_key_previous, settings)
        end

        local s = this.season or 1
        game.server_save('Season_' .. s .. '_Mtn_v3_' .. tostring(current_time))
        notify_season_over_to_discord()
        settings.current_date = current_time
        settings.test_mode = false
        settings.rounds_survived = 0
        settings.buffs = {}
        this.buffs = {}
        this.buffs_collected = {}
        this.rounds_survived = 0
        this.season = this.season + 1
        this.current_date = current_time
        settings.season = this.season
        this.time_to_reset = this.reset_after
        local message = ({'stateful.reset'})
        local message_discord = ({'stateful.reset_discord'})
        game.print(message)
        Server.to_discord_embed(message_discord, true)

        game.print(({'entity.notify_shutdown'}), {r = 0.22, g = 0.88, b = 0.22})
        local notify_shutdown = ({'entity.shutdown_game'})
        Server.to_discord_bold(notify_shutdown, true)

        Server.stop_scenario()

        if server_name_matches then
            Server.set_data(dataset, dataset_key, settings)
        else
            Server.set_data(dataset, dataset_key_dev, settings)
        end
    end
end

local apply_settings_token =
    Task.register(
    function(data)
        local server_name_matches = Server.check_server_name('Mtn Fortress')
        local settings = data and data.value or nil
        local current_time = Server.get_current_time()
        if not current_time then
            return
        end

        if not settings then
            settings = {
                rounds_survived = 0,
                current_date = tonumber(current_time),
                season = 1
            }
            if server_name_matches then
                Server.set_data(dataset, dataset_key, settings)
            else
                Server.set_data(dataset, dataset_key_dev, settings)
            end
            return
        end

        if not settings.current_date then
            settings.current_date = tonumber(current_time)
        end

        if not settings.season then
            settings.season = 1
        end

        this.current_date = settings.current_date
        this.buffs = settings.buffs

        apply_startup_settings(settings)

        this.rounds_survived = settings.rounds_survived
        this.season = settings.season

        local current_season = Public.get('current_season')
        rendering.set_text(current_season, 'Season: ' .. this.season)

        Public.reset_stateful()
        Public.increase_enemy_damage_and_health()
    end
)

local function apply_startup_dev_settings(settings)
    local current_date = {
        year = 2023,
        month = 10,
        day = 30
    }
    if not current_date then
        return
    end

    local current_time = 1600509719
    if not current_time then
        return
    end

    current_date = round(Utils.convert_date(current_date.year, current_date.month, current_date.day))

    local server_name_matches = true

    settings = settings or {}
    local stored_date = this.current_date
    if not stored_date then
        return
    end
    local stored_date_raw = Server.get_current_date(false, true, stored_date)
    local converted_stored_date = round(Utils.convert_date(stored_date_raw.year, stored_date_raw.month, stored_date_raw.day))

    local time_to_reset = (current_date - converted_stored_date)
    this.time_to_reset = this.reset_after - time_to_reset
    if time_to_reset and time_to_reset > this.reset_after then
        settings.current_date = current_time
        settings.test_mode = false
        settings.rounds_survived = 0
        settings.buffs = {}
        this.buffs = {}
        this.buffs_collected = {}
        this.rounds_survived = 0
        this.season = this.season + 1
        this.current_date = current_time
        settings.season = this.season
        this.time_to_reset = this.reset_after
        local message = ({'stateful.reset'})
        local message_discord = ({'stateful.reset_discord'})
        Task.set_timeout_in_ticks_text(60, {text = message})
        Server.to_discord_embed(message_discord, true)

        if server_name_matches then
            Server.set_data(dataset, dataset_key, settings)
        else
            Server.set_data(dataset, dataset_key_dev, settings)
        end
    end
end

---@diagnostic disable-next-line: unused-local
local apply_settings_dev_token =
    Task.register(
    function(data)
        local settings = data and data.value or nil
        local current_time = 1700509719
        if not current_time then
            return
        end

        this.current_date = settings.current_date
        this.buffs = settings.buffs

        apply_startup_dev_settings(settings)

        this.rounds_survived = settings.rounds_survived

        Public.reset_stateful()
        Public.increase_enemy_damage_and_health()
    end
)

local function grant_non_limit_reached_buff()
    local all_buffs = get_random_buff(true)
    local starting_items = Public.get_func('starting_items')

    for index, data in pairs(all_buffs) do
        for _, item_data in pairs(starting_items) do
            if item_data.buff_type == data.name and item_data.item_limit and data.limit and item_data.item_limit >= data.limit then
                all_buffs[index] = nil
            end
        end
    end

    shuffle(all_buffs)
    shuffle(all_buffs)
    shuffle(all_buffs)
    shuffle(all_buffs)
    shuffle(all_buffs)
    shuffle(all_buffs)

    if not all_buffs[1] then
        return get_random_force_buff()
    end

    return all_buffs[1]
end

function Public.save_settings()
    local granted_buff = grant_non_limit_reached_buff()
    this.buffs[#this.buffs + 1] = granted_buff

    local settings = {
        rounds_survived = this.rounds_survived,
        season = this.season,
        test_mode = this.test_mode,
        buffs = this.buffs,
        current_date = this.current_date
    }

    local server_name_matches = Server.check_server_name('Mtn Fortress')
    if server_name_matches then
        Server.set_data(dataset, dataset_key, settings)
    else
        Server.set_data(dataset, dataset_key_dev, settings)
    end

    return granted_buff
end

function Public.reset_stateful(refresh_gui, clear_buffs)
    this.test_mode = false
    this.objectives_completed = {}
    this.objectives_completed_count = 0
    this.final_battle = false
    this.extra_wagons = 0
    if clear_buffs then
        this.buffs_collected = {}
    end
    this.enemies_boosted = false
    this.tasks_required_to_win = 5

    this.selected_objectives = get_random_objectives()
    if this.test_mode then
        this.objectives = {
            randomized_zone = 2,
            randomized_wave = 2,
            supplies = get_random_items(),
            single_item = get_random_item(),
            killed_enemies = 10,
            research_level_selection = get_random_research_recipe(),
            locomotive_market_coins_spent = 0,
            locomotive_market_coins_spent_required = 1,
            trees_farmed = 10,
            rocks_farmed = 10,
            rockets_launched = 1
        }
    else
        this.objectives = {
            randomized_zone = scale(4, 15, 1.013),
            randomized_wave = scale(200, 1000),
            supplies = get_random_items(),
            single_item = get_random_item(),
            killed_enemies = scale(25000, 400000),
            research_level_selection = get_random_research_recipe(),
            locomotive_market_coins_spent = {
                spent = 0,
                required = scale(50000)
            },
            trees_farmed = scale(10000, 200000),
            rocks_farmed = scale(20000, 250000),
            rockets_launched = scale(10, 700)
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
        ['randomized_wave'] = this.objectives.randomized_wave
    }
    for index = 1, #this.selected_objectives do
        local objective = this.selected_objectives[index]
        if not t[objective.name] then
            t[objective.name] = this.objectives[objective.name]
        end
    end

    this.objectives = t

    clear_all_stats()

    apply_buffs()

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
    if this.enemies_boosted then
        return
    end

    this.enemies_boosted = true

    if this.rounds_survived == 1 then
        Event.raise(WD.events.on_biters_evolved, {force = game.forces.enemy, health_increase = true})
        Event.raise(WD.events.on_biters_evolved, {force = game.forces.aggressors})
        Event.raise(WD.events.on_biters_evolved, {force = game.forces.aggressors_frenzy})
    else
        for _ = 1, this.rounds_survived do
            Event.raise(WD.events.on_biters_evolved, {force = game.forces.enemy, health_increase = true})
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

        local server_name_matches = Server.check_server_name('Mtn Fortress')

        this.settings_applied = true

        if server_name_matches then
            Server.try_get_data(dataset, dataset_key, apply_settings_token)
        else
            Server.try_get_data(dataset, dataset_key_dev, apply_settings_token)
            this.test_mode = true
        end
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
Public.on_market_item_purchased = on_market_item_purchased

if _DEBUG then
    Event.on_init(
        function()
            local cbl = Task.get(apply_settings_dev_token)
            local data = {
                rounds_survived = 19,
                season = 2,
                test_mode = false,
                buffs = {
                    {name = 'defense', discord = 'Defense starting supplies', modifier = 'starting_items', items = {{name = 'gun-turret', count = 2}, {name = 'firearm-magazine', count = 100}}},
                    {name = 'fast_startup_2', discord = 'Assembling starting supplies', modifier = 'starting_items', replaces = 'fast_startup_2', items = {{name = 'assembling-machine-3', count = 2}}},
                    {name = 'character_health_bonus', discord = 'Character health bonus', modifier = 'force', state = 250},
                    {name = 'fast_startup_2', discord = 'Assembling starting supplies', modifier = 'starting_items', replaces = 'fast_startup_2', items = {{name = 'assembling-machine-3', count = 2}}},
                    {name = 'supplies_2', discord = 'Starting items supplies', modifier = 'starting_items_1', replaces = 'supplies', items = {{name = 'iron-plate', count = 400}, {name = 'copper-plate', count = 400}}},
                    {name = 'character_health_bonus', discord = 'Character health bonus', modifier = 'force', state = 250},
                    {name = 'defense_3', discord = 'Defense starting supplies', modifier = 'starting_items', replaces = 'defense_2', items = {{name = 'rocket-launcher', count = 1}, {name = 'rocket', count = 100}}},
                    {name = 'supplies_1', discord = 'Starting items supplies', modifier = 'starting_items', replaces = 'supplies', items = {{name = 'iron-plate', count = 200}, {name = 'copper-plate', count = 200}}},
                    {name = 'character_health_bonus', discord = 'Character health bonus', modifier = 'force', state = 250},
                    {name = 'worker_robots_storage_bonus', discord = 'Robot storage bonus', modifier = 'force', state = 0.05},
                    {name = 'supplies', discord = 'Starting items supplies', modifier = 'starting_items', items = {{name = 'iron-plate', count = 100}, {name = 'copper-plate', count = 100}}},
                    {name = 'xp_bonus', discord = 'RPG XP point bonus', modifier = 'rpg', state = 0.12},
                    {name = 'manual_mining_speed_modifier', discord = 'Mining speed modifier', modifier = 'force', state = 0.15},
                    {name = 'fast_startup_2', discord = 'Assembling starting supplies', modifier = 'starting_items', replaces = 'fast_startup_2', items = {{name = 'assembling-machine-3', count = 2}}},
                    {name = 'armor', discord = 'Armor starting supplies', modifier = 'starting_items', limit = 1, items = {{name = 'modular-armor', count = 1}, {name = 'solar-panel-equipment', count = 2}}},
                    {name = 'laboratory_productivity_bonus', discord = 'Productivity bonus', modifier = 'force', state = 0.15},
                    {name = 'laboratory_speed_modifier', discord = 'Laboratory speed modifier', modifier = 'force', state = 0.15},
                    {name = 'laboratory_productivity_bonus', discord = 'Productivity bonus', modifier = 'force', state = 0.15},
                    {name = 'supplies_1', discord = 'Starting items supplies', modifier = 'starting_items', replaces = 'supplies', items = {{name = 'iron-plate', count = 200}, {name = 'copper-plate', count = 200}}},
                    {name = 'worker_robots_storage_bonus', discord = 'Robot storage bonus', modifier = 'force', state = 0.05},
                    {name = 'fast_startup_1', discord = 'Assembling starting supplies', modifier = 'starting_items', replaces = 'fast_startup', items = {{name = 'assembling-machine-2', count = 2}}},
                    {name = 'character_running_speed_modifier', discord = 'Running speed modifier', modifier = 'force', state = 0.05},
                    {name = 'manual_mining_speed_modifier', discord = 'Mining speed modifier', modifier = 'force', state = 0.15},
                    {name = 'character_running_speed_modifier', discord = 'Running speed modifier', modifier = 'force', state = 0.05},
                    {name = 'manual_crafting_speed_modifier', discord = 'Crafting speed modifier', modifier = 'force', state = 0.12},
                    {name = 'defense_2', discord = 'Defense starting supplies', modifier = 'starting_items', replaces = 'defense', items = {{name = 'grenade', count = 50}, {name = 'poison-capsule', count = 30}}},
                    {name = 'heal-thy-buildings', discord = 'Repair starting supplies', modifier = 'starting_items', items = {{name = 'repair-pack', count = 5}}},
                    {name = 'defense', discord = 'Defense starting supplies', modifier = 'starting_items', items = {{name = 'gun-turret', count = 2}, {name = 'firearm-magazine', count = 100}}}
                },
                current_date = 1700529374
            }
            local settings = {
                value = data
            }
            cbl(settings)
        end
    )
end

return Public
