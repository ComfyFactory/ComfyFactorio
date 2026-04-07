local Global = require 'utils.global'
local Event = require 'utils.event'
local Utils = require 'utils.utils'
local Server = require 'utils.server'
local Gui = require 'utils.gui'
local Task = require 'utils.task_token'
local shuffle = table.shuffle_table
local WD = require 'modules.wave_defense.table'
local format_number = require 'util'.format_number
local ICWF = require 'maps.mountain_fortress_v3.icw.functions'
local ICWT = require 'maps.mountain_fortress_v3.icw.table'
local Core = require 'utils.core'
local Public = require 'maps.mountain_fortress_v3.table'
local Alert = require 'utils.alert'
local RPG = require 'modules.rpg.table'
local Beam = require 'modules.render_beam'
local Discord = require 'utils.discord'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local ICW = require 'maps.mountain_fortress_v3.icw.table'

local this =
{
    enabled = false,
    rounds_survived = 0,
    current_streak = 0,
    best_streak = 0,
    season = 1,
    buffs = {},
    permanent_buffs = {},
    reset_after = 60,
    time_to_reset = 60
}

local random = math.random
local round = math.round
local floor = math.floor
local deep_copy = table.deep_copy
local dataset = 'scenario_settings'
local dataset_key = 'mtn_v3'
local dataset_key_modded = 'mtn_v3_modded'
local dataset_key_dev = 'mtn_v3_dev'
local dataset_key_dev_modded = 'mtn_v3_dev_modded'
local dataset_key_previous = 'mtn_v3_previous'
local dataset_key_modded_previous = 'mtn_v3_modded_previous'
local dataset_key_previous_dev = 'mtn_v3_previous_dev'
local dataset_key_modded_previous_dev = 'mtn_v3_previous_dev'
local send_ping_to_channel = Discord.channel_names.mtn_channel
local minerals_lookup_table = {}
local enemies_lookup_table = {}
local apply_buffs
local apply_permanent_buffs

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

Global.register(
    minerals_lookup_table,
    function (tbl)
        minerals_lookup_table = tbl
    end
)

Global.register(
    enemies_lookup_table,
    function (tbl)
        enemies_lookup_table = tbl
    end
)

local damage_types = { 'physical', 'explosion', 'laser' }

local buff_to_string =
{
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

local shutdown_scenario_token =
    Task.register(
        function ()
            Server.stop_scenario()
        end
    )

local start_scenario_token =
    Task.register(
        function ()
            Server.start_scenario('Mountain_Fortress_v3')
        end
    )

local function upperCase(str)
    return (str:gsub('^%l', string.upper))
end

local function notify_season_over_to_discord(perm_buff)
    local server_name_matches = Server.check_server_name(Public.discord_name)

    local stateful = Public.get_stateful()

    if not stateful.buffs_collected then
        apply_buffs()
    end
    if not stateful.permanent_buffs_collected then
        apply_permanent_buffs()
    end
    local buffs = ''
    if stateful.buffs and next(stateful.buffs) then
        if stateful.buffs_collected and next(stateful.buffs_collected) then
            if stateful.buffs_collected.starting_items then
                buffs = buffs .. 'Starting items:\n'
                for item_name, item_data in pairs(stateful.buffs_collected.starting_items) do
                    buffs = buffs .. upperCase(item_name) .. ': ' .. item_data.count
                    buffs = buffs .. '\n'
                end
                buffs = buffs .. '\n'
            end

            buffs = buffs .. 'Force buffs:\n'
            for name, buff_data in pairs(stateful.buffs_collected) do
                if type(buff_data.amount) ~= 'table' and name ~= 'starting_items' then
                    if name == 'xp_level' or name == 'xp_bonus' or name == 'character_health_bonus' then
                        if buff_data.count and buff_to_string[name] then
                            buffs = buffs .. buff_to_string[name] .. ': ' .. buff_data.count
                        else
                            buffs = buffs .. upperCase(name) .. ': Active' .. '\n'
                        end
                    else
                        if buff_data.count and buff_to_string[name] then
                            buffs = buffs .. buff_to_string[name] .. ': ' .. (buff_data.count * 100) .. '%'
                        elseif type(buff_data) == 'table' then
                            for _, t_data in pairs(buff_data) do
                                if t_data and type(t_data) == 'table' then
                                    buffs = buffs .. upperCase(t_data.name) .. ': Active' .. '\n'
                                end
                            end
                        elseif buff_data.name then
                            buffs = buffs .. upperCase(buff_data.name) .. ': Active' .. '\n'
                        else
                            buffs = buffs .. upperCase(name) .. ': Active' .. '\n'
                        end
                    end
                    buffs = buffs .. '\n'
                end
            end
        end
    end

    local text =
    {
        title = 'Season: ' .. stateful.season .. ' is over!',
        description = 'Game statistics from the season is below',
        color = 'success',
        fields =
        {
            {
                title = 'Rounds survived:',
                description = stateful.rounds_survived,
                inline = 'false'
            },
            {
                title = 'Best win streak:',
                description = stateful.best_streak or 'None',
                inline = 'false'
            },
            {
                title = 'Buffs granted:',
                description = buffs,
                inline = 'false'
            },
            {
                title = 'Permanent buffs granted:',
                description = perm_buff.discord,
                inline = 'false'
            }
        }

    }
    if server_name_matches then
        Server.to_discord_named_parsed_embed(send_ping_to_channel, text)
    else
        Server.to_discord_embed_parsed(text)
    end

    stateful.buffs_collected = {}
    stateful.permanent_buffs_collected = {}
end

local function get_item_produced_count(item_name, quality)
    local force = game.forces.player
    local statistics = Public.get('statistics')

    if not Public.get('is_quality_from_production_enabled') then
        quality = 'normal'
    end

    if not statistics.surface_production then
        statistics.surface_production = {}
    end

    if not statistics.surface_production[item_name] then
        statistics.surface_production[item_name] = {}
    end

    local total_production = 0

    for surface_name, _ in pairs(statistics.surface_production[item_name]) do
        local surface_exists = game.get_surface(surface_name) and game.get_surface(surface_name).valid
        if not surface_exists then
            statistics.surface_production[item_name][surface_name] = nil
        end
    end

    for _, surface in pairs(game.surfaces) do
        if surface.valid then
            local surface_name = surface.name
            local current_production = force.get_item_production_statistics(surface_name).get_input_count({ name = item_name, quality = quality }) or 0

            if not statistics.surface_production[item_name][surface_name] then
                statistics.surface_production[item_name][surface_name] = current_production
            else
                local previous_production = statistics.surface_production[item_name][surface_name]
                local production_difference = current_production - previous_production
                if production_difference > 0 then
                    total_production = total_production + production_difference
                end
                statistics.surface_production[item_name][surface_name] = current_production
            end
        end
    end

    if not statistics.running_total then
        statistics.running_total = {}
    end

    if not statistics.running_total[item_name] then
        statistics.running_total[item_name] = 0
    end

    statistics.running_total[item_name] = statistics.running_total[item_name] + total_production

    return statistics.running_total[item_name]
end

local function get_entity_mined_count(_, item_name)
    local force = game.forces.player
    local starting_planet = Public.get_planet()

    local count = 0
    for name, entity_count in pairs(force.get_entity_build_count_statistics(starting_planet).output_counts) do
        if name:find(item_name) then
            count = count + entity_count
        end
    end

    return count
end

local function get_killed_enemies_count(primary, secondary)
    local force = game.forces.player
    local starting_planet = Public.get_planet()

    local count = 0
    for name, entity_count in pairs(force.get_kill_count_statistics(starting_planet).input_counts) do
        if name:find(primary) or name:find(secondary) then
            count = count + entity_count
        end
    end

    return count
end

local move_all_players_token =
    Task.register(
        function ()
            Public.move_all_players()
        end
    )

local search_corpse_token =
    Task.register(
        function (event)
            local player_index = event.player_index
            if not player_index then return end
            local player = game.get_player(player_index)

            if not player or not player.valid then
                return
            end

            local pos = player.physical_position
            local entities =
                player.surface.find_entities_filtered
                {
                    area = { { pos.x - 0.5, pos.y - 0.5 }, { pos.x + 0.5, pos.y + 0.5 } },
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

    local corpse_removal_disabled = Public.get('corpse_removal_disabled')
    if corpse_removal_disabled then
        return
    end

    local starting_planet = Public.get_planet()

    if string.sub(surface.name, 0, #starting_planet) ~= starting_planet then
        return
    end

    -- player.ticks_to_respawn = 1800 * (this.rounds_survived + 1)

    Task.set_timeout_in_ticks(5, search_corpse_token, { player_index = player.index })
end

local function get_random_quality()
    if not Public.is_modded_pt2 then
        return 'normal'
    end

    if not Public.get('is_quality_from_production_enabled') then
        return 'normal'
    end

    local rounds = this.rounds_survived
    local quality_per_level = Public.quality_per_level_objectives
    local best_key = 1

    for level, _ in pairs(quality_per_level) do
        if rounds >= level then
            if level > best_key then
                best_key = level
            end
        end
    end

    local quality_list = quality_per_level[best_key]
    return quality_list[random(1, #quality_list)]
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
        function ()
            return false
        end
    )

local killed_enemies_token =
    Task.register(
        function ()
            local force = game.forces.player
            local starting_planet = Public.get_planet()

            if not enemies_lookup_table or not next(enemies_lookup_table) then
                Public.create_enemies_lookup_table()
            end

            local actual = 0
            for name, entity_count in pairs(force.get_kill_count_statistics(starting_planet).input_counts) do
                if enemies_lookup_table[name] then
                    actual = actual + entity_count
                end
            end

            local expected = this.objectives.killed_enemies
            if actual >= expected then
                return true, { 'stateful.enemies_killed' }, { 'stateful.done', format_number(expected, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_completed' }
            end

            return false, { 'stateful.enemies_killed' }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_not_completed' }
        end
    )

local killed_enemies_type_token =
    Task.register(
        function ()
            local actual = this.objectives.killed_enemies_type.actual
            local expected = this.objectives.killed_enemies_type.expected
            if actual >= expected then
                return true, { 'stateful.enemies_killed_type', this.objectives.killed_enemies_type.damage_type }, { 'stateful.done', format_number(expected, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_completed' }
            end

            return false, { 'stateful.enemies_killed_type', this.objectives.killed_enemies_type.damage_type }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' },
                {
                    'stateful.tooltip_not_completed'
                }
        end
    )

local handcrafted_items_token =
    Task.register(
        function ()
            local actual = this.objectives.handcrafted_items.actual
            local expected = this.objectives.handcrafted_items.expected
            if actual >= expected then
                return true, { 'stateful.crafted_items', this.objectives.handcrafted_items.name }, { 'stateful.done', format_number(expected, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_completed' }
            end

            return false, { 'stateful.crafted_items', this.objectives.handcrafted_items.name }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' },
                {
                    'stateful.tooltip_not_completed'
                }
        end
    )

local handcrafted_items_any_token =
    Task.register(
        function ()
            local actual = this.objectives.handcrafted_items_any.actual
            local expected = this.objectives.handcrafted_items_any.expected
            if actual >= expected then
                return true, { 'stateful.crafted_items', this.objectives.handcrafted_items_any.name }, { 'stateful.done', format_number(expected, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_completed' }
            end

            return false, { 'stateful.crafted_items', this.objectives.handcrafted_items_any.name }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' },
                {
                    'stateful.tooltip_not_completed'
                }
        end
    )

local launch_item_token =
    Task.register(
        function ()
            local actual = this.objectives.launch_item.actual
            local expected = this.objectives.launch_item.expected
            if actual >= expected then
                return true, { 'stateful.launch_item', this.objectives.launch_item.name }, { 'stateful.done', format_number(expected, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_completed' }
            end

            return false, { 'stateful.launch_item', this.objectives.launch_item.name }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' },
                {
                    'stateful.tooltip_not_completed'
                }
        end
    )

local cast_spell_token =
    Task.register(
        function ()
            local actual = this.objectives.cast_spell.actual
            local expected = this.objectives.cast_spell.expected
            if actual >= expected then
                return true, { 'stateful.cast_spell', this.objectives.cast_spell.name }, { 'stateful.done', format_number(expected, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_completed' }
            end

            return false, { 'stateful.cast_spell', this.objectives.cast_spell.name }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' },
                {
                    'stateful.tooltip_not_completed'
                }
        end
    )

local cast_spell_any_token =
    Task.register(
        function ()
            local actual = this.objectives.cast_spell_any.actual
            local expected = this.objectives.cast_spell_any.expected
            if actual >= expected then
                return true, { 'stateful.cast_spell', this.objectives.cast_spell_any.name }, { 'stateful.done', format_number(expected, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_completed' }
            end

            return false, { 'stateful.cast_spell', this.objectives.cast_spell_any.name }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' },
                {
                    'stateful.tooltip_not_completed'
                }
        end
    )

local research_level_selection_token =
    Task.register(
        function ()
            local actual = this.objectives.research_level_selection.research_count
            local expected = this.objectives.research_level_selection.count
            if actual >= expected then
                return true, { 'stateful.research', this.objectives.research_level_selection.name }, { 'stateful.done', expected, expected }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_completed' }
            end
            return false, { 'stateful.research', this.objectives.research_level_selection.name }, { 'stateful.not_done', actual, expected }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_not_completed' }
        end
    )

local locomotive_market_coins_spent_token =
    Task.register(
        function ()
            local coins = this.objectives.locomotive_market_coins_spent
            local actual = coins.spent
            local expected = coins.required
            if actual >= expected then
                return true, { 'stateful.market_spent' }, { 'stateful.done', format_number(expected, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_completed' }
            end
            return false, { 'stateful.market_spent' }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_not_completed' }
        end
    )

local minerals_farmed_token =
    Task.register(
        function ()
            local force = game.forces.player
            local starting_planet = Public.get_planet()

            if not minerals_lookup_table or not next(minerals_lookup_table) then
                Public.create_minerals_lookup_table()
            end

            local count = 0
            for name, entity_count in pairs(force.get_entity_build_count_statistics(starting_planet).output_counts) do
                if minerals_lookup_table[name] then
                    count = count + entity_count
                end
            end

            local actual = count
            local expected = this.objectives.minerals_farmed
            if actual >= expected then
                return true, { 'stateful.minerals_mined' }, { 'stateful.done', format_number(expected, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_completed' }
            end
            return false, { 'stateful.minerals_mined' }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.mined_entities_tooltip' }, { 'stateful.tooltip_not_completed_entities' }
        end
    )

local rockets_launched_token =
    Task.register(
        function ()
            local actual = game.forces.player.rockets_launched
            local expected = this.objectives.rockets_launched
            if actual >= expected then
                return true, { 'stateful.launch_rockets' }, { 'stateful.done', format_number(expected, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_completed' }
            end
            return false, { 'stateful.launch_rockets' }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_not_completed' }
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

local function scale_lin(setting, limit, factor)
    factor = factor or 1.05
    local scale_value = math.floor(setting + (factor * this.rounds_survived))
    if limit and scale_value >= limit then
        return limit
    end
    return floor(scale_value)
end

local function make_entry(item)
    local quality_multiplier =
    {
        normal = 1.0,
        uncommon = 0.75,
        rare = 0.5,
        epic = 0.25,
        legendary = 0.1
    }

    local quality = get_random_quality()
    local multiplier = quality_multiplier[quality] or 1
    local count = math.floor(item[2] * multiplier)

    return
    {
        name = item[1],
        count = math.max(1, count),
        quality = quality
    }
end

local function get_random_items()
    local items =
    {
        { 'advanced-circuit', scale(225000, 9000000) },
        { 'copper-cable', scale(3000000, 120000000) },
        { 'copper-plate', scale(1500000, 60000000) },
        { 'electric-engine-unit', scale(10000, 400000) },
        { 'electronic-circuit', scale(1000000, 40000000) },
        { 'engine-unit', scale(20000, 800000) },
        { 'explosives', scale(150000, 6000000) },
        { 'iron-gear-wheel', scale(150000, 6000000) },
        { 'iron-plate', scale(2000000, 80000000) },
        { 'iron-stick', scale(75000, 3000000) },
        { 'processing-unit', scale(40000, 1600000) },
        { 'steel-plate', scale(200000, 8000000) },
        { 'rocket', scale(25000, 1000000) },
        { 'explosive-rocket', scale(25000, 1000000) },
        { 'slowdown-capsule', scale(10000, 400000) },
        { 'laser-turret', scale(3000, 120000) },
        { 'stone-wall', scale(20000, 800000) },
        { 'accumulator', scale(5000, 200000) },
        { 'refined-concrete', scale(15000, 600000) },
        { 'uranium-rounds-magazine', scale(4000, 160000) },
        { 'explosive-uranium-cannon-shell', scale(3000, 120000) },
        { 'distractor-capsule', scale(1500, 60000) },
        { 'cluster-grenade', scale(4000, 160000) },
        { 'small-lamp', scale(5000, 200000) },
        { 'uranium-fuel-cell', scale(2500, 100000) }
    }

    if Public.is_modded_pt2 then
        table.insert(items, { 'lithium', scale(5000, 80000000) })
        table.insert(items, { 'lithium-plate', scale(1000, 80000000) })
        table.insert(items, { 'carbon-fiber', scale(1000, 80000000) })

        table.insert(items, { 'tungsten-carbide', scale(100, 500000) })
        table.insert(items, { 'tungsten-plate', scale(100, 500000) })
        table.insert(items, { 'holmium-plate', scale(100, 500000) })
        table.insert(items, { 'supercapacitor', scale(50, 500000) })
        table.insert(items, { 'superconductor', scale(50, 500000) })
        table.insert(items, { 'carbon', scale(100, 500000) })
        table.insert(items, { 'turbo-splitter', scale(50, 500000) })
        table.insert(items, { 'turbo-transport-belt', scale(50, 500000) })
        table.insert(items, { 'turbo-underground-belt', scale(50, 500000) })
    end

    shuffle(items)
    shuffle(items)

    local container =
    {
        [1] = make_entry(items[1]),
        [2] = make_entry(items[2]),
        [3] = make_entry(items[3])
    }

    if this.test_mode then
        container =
        {
            [1] = { name = items[1][1], count = 1, quality = get_random_quality() },
            [2] = { name = items[2][1], count = 1, quality = get_random_quality() },
            [3] = { name = items[3][1], count = 1, quality = get_random_quality() }
        }
    end

    return container
end


local function get_random_item()
    local items =
    {
        { 'efficiency-module', scale(1000, 400000) },
        { 'productivity-module', scale(10000, 400000) },
        { 'speed-module', scale(10000, 400000) },
        { 'efficiency-module-2', scale(200, 100000) },
        { 'productivity-module-2', scale(1000, 100000) },
        { 'speed-module-2', scale(1000, 100000) },
        { 'efficiency-module-3', scale(50, 30000) },
        { 'productivity-module-3', scale(500, 30000) },
        { 'speed-module-3', scale(500, 30000) },
        { 'automation-science-pack', scale(1000, 400000) },
        { 'logistic-science-pack', scale(1000, 400000) },
        { 'military-science-pack', scale(1000, 400000) },
        { 'chemical-science-pack', scale(1000, 400000) },
        { 'production-science-pack', scale(1000, 400000) },
        { 'utility-science-pack', scale(1000, 400000) },
    }

    if Public.is_modded_pt2 then
        table.insert(items, { 'quality-module', scale(100, 30000) })
        table.insert(items, { 'quality-module-2', scale(100, 30000) })
        table.insert(items, { 'quality-module-3', scale(100, 30000) })
        table.insert(items, { 'space-science-pack', scale(1000, 400000) })
        table.insert(items, { 'metallurgic-science-pack', scale(1000, 400000) })
        table.insert(items, { 'agricultural-science-pack', scale(1000, 400000) })
        table.insert(items, { 'electromagnetic-science-pack', scale(1000, 400000) })
        table.insert(items, { 'cryogenic-science-pack', scale(500, 400000) })
    end

    if this.rounds_survived > 100 then
        table.insert(items, { 'promethium-science-pack', scale(50, 400000) })
    end

    shuffle(items)
    shuffle(items)
    shuffle(items)
    shuffle(items)

    return make_entry(items[1])
end

local function get_random_handcrafted_item()
    local items =
    {
        { 'advanced-circuit', scale(2000, 500000) },
        { 'copper-cable', scale(10000, 500000) },
        { 'electronic-circuit', scale(5000, 1000000) },
        { 'iron-gear-wheel', scale(50000, 1000000) },
        { 'iron-stick', scale(75000, 3000000) },
        { 'rocket', scale(5000, 1000000) },
        { 'explosive-rocket', scale(5000, 1000000) },
        { 'slowdown-capsule', scale(2500, 400000) },
        { 'laser-turret', scale(1500, 20000) },
        { 'stone-wall', scale(5000, 800000) },
        { 'accumulator', scale(1000, 200000) },
        { 'uranium-rounds-magazine', scale(1000, 60000) },
        { 'explosive-uranium-cannon-shell', scale(1000, 10000) },
        { 'distractor-capsule', scale(1500, 60000) },
        { 'grenade', scale(5000, 200000) },
        { 'cluster-grenade', scale(1000, 100000) },
        { 'small-lamp', scale(2500, 200000) },
        { 'rail', scale(5000, 100000) },
        { 'small-electric-pole', scale(5000, 100000) },
        { 'medium-electric-pole', scale(3500, 80000) },
        { 'big-electric-pole', scale(2000, 50000) },
        { 'transport-belt', scale(10000, 100000) },
        { 'fast-transport-belt', scale(3000, 50000) },
        { 'repair-pack', scale(10000, 100000) },
        { 'splitter', scale(10000, 100000) },
        { 'fast-splitter', scale(3000, 50000) },
        { 'inserter', scale(3000, 50000) },
        { 'firearm-magazine', scale(10000, 200000) },
        { 'piercing-rounds-magazine', scale(5000, 100000) },
        { 'pipe', scale(10000, 100000) },
        { 'pipe-to-ground', scale(3000, 50000) },
        { 'efficiency-module', scale(100, 50000) },
        { 'productivity-module', scale(100, 50000) },
        { 'speed-module', scale(100, 50000) },
    }

    if Public.is_modded_pt2 then
        table.insert(items, { 'quality-module', scale(100, 50000) })
    end

    shuffle(items)
    shuffle(items)
    shuffle(items)
    shuffle(items)

    return { name = items[1][1], count = items[1][2] }
end


local function get_random_spell()
    local items =
    {
        { 'small-biter', scale(100, 2500, 1.01) },
        { 'small-spitter', scale(100, 2500, 1.01) },
        { 'medium-biter', scale(100, 2500, 1.01) },
        { 'medium-spitter', scale(100, 2500, 1.01) },
        { 'shotgun-shell', scale(100, 2500, 1.01) },
        { 'grenade', scale(100, 2500, 1.01) },
        { 'cluster-grenade', scale(100, 2500, 1.01) },
        { 'cannon-shell', scale(100, 2500, 1.01) },
        { 'explosive-cannon-shell', scale(100, 2500, 1.01) },
        { 'uranium-cannon-shell', scale(100, 2500, 1.01) },
        { 'rocket', scale(100, 2500, 1.01) },
        { 'acid-stream-spitter-big', scale(100, 2500, 1.01) },
        { 'explosives', scale(100, 2500, 1.01) },
        { 'distractor-capsule', scale(100, 2500, 1.01) },
        { 'defender-capsule', scale(100, 2500, 1.01) },
        { 'destroyer-capsule', scale(100, 2500, 1.01) },
        { 'warp-gate', scale(100, 2500, 1.01) },
        { 'haste', scale(100, 2500, 1.01) }
    }

    shuffle(items)
    shuffle(items)
    shuffle(items)
    shuffle(items)

    return { name = items[1][1], count = items[1][2] }
end


local function get_random_research_recipe()
    -- scale(10, 20)
    local research_level_list =
    {
        'laser-weapons-damage-7',
        'stronger-explosives-7',
        'mining-productivity-4',
        'worker-robots-speed-6',
        'follower-robot-count-5'
    }

    if Public.get('space_age') then
        research_level_list =
        {
            'laser-weapons-damage-7',
            'stronger-explosives-7',
            'mining-productivity-3',
            'worker-robots-speed-7',
            'follower-robot-count-5'
        }
    end

    shuffle(research_level_list)

    if this.test_mode then
        return { name = research_level_list[1], count = 1, research_count = 0 }
    end

    return { name = research_level_list[1], count = scale(2, 9, 1.03), research_count = 0 }
end

local function get_random_objectives()
    local items =
    {
        {
            name = 'single_item',
            token = empty_token,
            discord = 'Produce item'
        },
        {
            name = 'killed_enemies',
            token = killed_enemies_token,
            discord = 'Kill enemies'
        },
        {
            name = 'killed_enemies_type',
            token = killed_enemies_type_token,
            discord = 'Kill enemies of a specific type'
        },
        {
            name = 'handcrafted_items',
            token = handcrafted_items_token,
            discord = 'Craft items'
        },
        {
            name = 'handcrafted_items_any',
            token = handcrafted_items_any_token,
            discord = 'Craft any items'
        },
        {
            name = 'cast_spell',
            token = cast_spell_token,
            discord = 'Cast a spell'
        },
        {
            name = 'launch_item',
            token = launch_item_token,
            discord = 'Launch an item'
        },
        {
            name = 'cast_spell_any',
            token = cast_spell_any_token,
            discord = 'Cast any spell'
        },
        {
            name = 'research_level_selection',
            token = research_level_selection_token,
            discord = 'Research a specific technology'
        },
        {
            name = 'locomotive_market_coins_spent',
            token = locomotive_market_coins_spent_token,
            discord = 'Spend coins at the market'
        },
        {
            name = 'minerals_farmed',
            token = minerals_farmed_token,
            discord = 'Mine minerals'
        },
        {
            name = 'rockets_launched',
            token = rockets_launched_token,
            discord = 'Launch rockets'
        }
    }

    shuffle(items)
    shuffle(items)
    shuffle(items)
    shuffle(items)

    if _DEBUG then
        items[#items + 1] =
        {
            name = 'supplies',
            token = empty_token
        }
        return items
    end

    return
    {
        {
            name = 'supplies',
            token = empty_token
        },
        items[2],
        items[3],
        items[4]
    }
end

local function clear_all_stats()
    this.buffs_collected = {}
    this.permanent_buffs_collected = {}
    this.extra_wagons = 0
    this.quality_trains = 'normal'
    this.quality_buildings = 'normal'
    local rpg_extra = RPG.get('rpg_extra')
    rpg_extra.difficulty = 0
    rpg_extra.grant_xp_level = 0
end

local function migrate_buffs_generic(saved_buffs)
    local static_buffs = Public.get_random_buff(true)

    local static_buffs_by_name = {}
    for _, static_buff in pairs(static_buffs) do
        static_buffs_by_name[static_buff.name] = static_buff
    end

    for index, saved_buff in pairs(saved_buffs) do
        if saved_buff.name:find('quality_cargo_wagon') then
            saved_buff.name = saved_buff.name:gsub('quality_cargo_wagon', 'quality_trains')
        end

        if saved_buffs[index].modifier == 'starting_items_1' then
            saved_buffs[index].modifier = 'starting_items'
        end


        local static_buff = static_buffs_by_name[saved_buff.name]

        if static_buff then
            if not Public.is_modded_pt2 and static_buff.dlc then
                saved_buffs[index] = nil
            else
                local collected_count = saved_buff.count or 0
                saved_buffs[index] = {}

                for key, value in pairs(static_buff) do
                    saved_buffs[index][key] = value
                end

                saved_buffs[index].count = collected_count

                saved_buffs[index].replaces = nil

                if saved_buffs[index].items == 0 then
                    saved_buffs[index] = nil
                end
            end
        else
            saved_buffs[index] = nil
        end
    end
end

local function migrate_buffs()
    migrate_buffs_generic(this.buffs)
end

local function migrate_permanent_buffs()
    migrate_buffs_generic(this.permanent_buffs)
end

local function update_collected_entry(collected_table, key, name, count, discord, force_flag)
    if not collected_table[key] then
        collected_table[key] =
        {
            name = name,
            count = count,
            discord = discord,
            force = force_flag
        }
    else
        collected_table[key].count = collected_table[key].count + count
    end
end

local function check_limit(limit_types, key, buff, increment)
    increment = increment or 1
    limit_types[key] = (limit_types[key] or 0) + increment
    return buff.limit and limit_types[key] > buff.limit
end

local function apply_force_buff(buff, collected_table, limit_types)
    if check_limit(limit_types, buff.name, buff) then
        return true -- signal to skip
    end

    local force = game.forces.player
    force[buff.name] = force[buff.name] + buff.state
    update_collected_entry(collected_table, buff.name, nil, buff.state, buff.discord, true)
end

local function apply_rpg_distance_buff(buff, collected_table, limit_types)
    if check_limit(limit_types, buff.modifier, buff) then
        return true -- signal to skip
    end

    local force = game.forces.player
    for _, buff_name in pairs(buff.modifiers) do
        if buff_name == 'character_reach_distance_bonus' then
            buff.state = 1
        end
        force[buff_name] = force[buff_name] + buff.state
        update_collected_entry(collected_table, buff_name, 'Extra Reach', buff.state, buff.discord, true)
    end
end

local function apply_locomotive_buff(buff, collected_table, limit_types)
    if check_limit(limit_types, buff.modifier, buff, buff.state) then
        return true -- signal to skip this buff
    end

    this.extra_wagons = (this.extra_wagons or 0) + buff.state

    update_collected_entry(collected_table, 'locomotive', 'Extra Wagons', buff.state, buff.discord)
    return false
end

local quality_rank =
{
    normal = 0,
    common = 1,
    uncommon = 2,
    rare = 3,
    epic = 4,
    legendary = 5
}

local function is_higher_quality(new, old)
    if not old then return true end
    return (quality_rank[new] or 0) > (quality_rank[old] or 0)
end

local function apply_quality_buff(buff, collected_table, limit_types)
    if check_limit(limit_types, buff.name, buff) then
        return true -- signal to skip
    end

    local function update_if_higher(current, new)
        if is_higher_quality(new, current) then
            return new
        else
            return current
        end
    end

    if buff.modifier == 'quality_trains' then
        this.quality_trains = update_if_higher(this.quality_trains, buff.quality)
        Server.output_script_data('Setting trains quality to ' .. this.quality_trains)
    elseif buff.name:find('quality_buildings') then
        this.quality_buildings = update_if_higher(this.quality_buildings, buff.quality)
        Server.output_script_data('Setting wild buildings quality to ' .. this.quality_buildings)
    end


    collected_table[buff.name] =
    {
        name = 'Quality trains' .. ' (' .. buff.quality .. ')',
        discord = buff.discord
    }
end


local function apply_fish_buff(buff, collected_table, limit_types)
    limit_types[buff.name] = true
    Public.set('all_the_fish', true)
    update_collected_entry(collected_table, 'fish', 'A thousand fishes', nil, buff.discord)
end

local function apply_tech_buff(buff, collected_table, limit_types)
    if check_limit(limit_types, buff.name, buff) then
        return true -- signal to skip
    end

    local techs = Public.get_func('techs')

    if not collected_table['techs'] then
        collected_table['techs'] = {}
    end

    if type(buff.techs) ~= 'table' then
        return true
    end

    for _, tech in pairs(buff.techs) do
        if tech and not techs[tech.name] then
            techs[tech.name] = { name = buff.name }

            collected_table['techs'][tech.name] =
            {
                name = tech.name,
                buff_type = buff.name,
                discord = buff.discord
            }

            this.delayed_tech = this.delayed_tech or {}
            this.delayed_tech[tech.name] = tech
        end
    end
    return false
end

local function apply_rpg_buff(buff, collected_table, limit_types)
    local rpg_extra = RPG.get('rpg_extra')

    if check_limit(limit_types, buff.name, buff) then
        return true -- signal to skip
    end

    if buff.name == 'xp_bonus' then
        rpg_extra.difficulty = (rpg_extra.difficulty or 0) + buff.state
        update_collected_entry(collected_table, 'xp_bonus', 'XP Bonus', buff.state, buff.discord)
    elseif buff.name == 'xp_level' then
        rpg_extra.grant_xp_level = (rpg_extra.grant_xp_level or 0) + buff.state
        update_collected_entry(collected_table, 'xp_level', 'XP Level Bonus', buff.state, buff.discord)
    end
    return false
end

local function apply_starting_items_buff(buff, collected_table, limit_types)
    if check_limit(limit_types, buff.name, buff) then
        return true -- signal to skip
    end

    local starting_items = Public.get_func('starting_items')

    if not collected_table['starting_items'] then
        collected_table['starting_items'] = {}
    end

    if type(buff.items) ~= 'table' then
        return true -- signal to skip
    end

    for _, item in pairs(buff.items) do
        if item then
            if starting_items[item.name] and buff.limit and
                starting_items[item.name].item_limit and
                starting_items[item.name].item_limit >= buff.limit then
                starting_items[item.name].limit_reached = true
                return true -- skip this buff
            end

            if starting_items[item.name] then
                starting_items[item.name].count = starting_items[item.name].count + item.count
                starting_items[item.name].item_limit = (starting_items[item.name].item_limit or 0) + (buff.add_per_buff or 0)
                starting_items[item.name].buff_type = buff.name
            else
                starting_items[item.name] =
                {
                    buff_type = buff.name,
                    count = item.count,
                    item_limit = buff.add_per_buff
                }
            end

            if collected_table['starting_items'][item.name] then
                collected_table['starting_items'][item.name].count =
                    collected_table['starting_items'][item.name].count + item.count
                collected_table['starting_items'][item.name].buff_type = buff.name
            else
                collected_table['starting_items'][item.name] =
                {
                    buff_type = buff.name,
                    count = item.count,
                    discord = buff.discord
                }
            end
        end
    end
    return false
end

local function apply_buffs_generic(buffs_table, collected_table, is_permanent)
    if not buffs_table or not next(buffs_table) then
        return
    end

    -- Run migration
    if is_permanent then
        migrate_permanent_buffs()
    else
        migrate_buffs()
    end

    local total_buffs = 0
    local limit_types = Public.get_func('limit_types')


    for _, buff in pairs(buffs_table) do
        if buff then
            local skip_buff = false

            if buff.name and buff.quality then
                skip_buff = apply_quality_buff(buff, collected_table, limit_types)
            elseif buff.modifier == 'rpg_distance' then
                skip_buff = apply_rpg_distance_buff(buff, collected_table, limit_types)
            elseif buff.modifier == 'locomotive' then
                skip_buff = apply_locomotive_buff(buff, collected_table, limit_types)
            elseif buff.modifier == 'force' then
                skip_buff = apply_force_buff(buff, collected_table, limit_types)
            elseif buff.modifier == 'fish' then
                skip_buff = apply_fish_buff(buff, collected_table, limit_types)
            elseif buff.modifier == 'tech' then
                skip_buff = apply_tech_buff(buff, collected_table, limit_types)
            elseif buff.modifier == 'rpg' then
                skip_buff = apply_rpg_buff(buff, collected_table, limit_types)
            elseif buff.modifier == 'starting_items' then
                skip_buff = apply_starting_items_buff(buff, collected_table, limit_types)
            end

            if skip_buff then
                goto continue
            end
            total_buffs = total_buffs + 1
        end
        ::continue::
    end

    this.total_buffs = total_buffs
    local log_message = is_permanent and 'Applied all permanent buffs. Total buffs: ' .. total_buffs
        or 'Applied all buffs. Total buffs: ' .. total_buffs
    Server.output_script_data(log_message)
    Server.output_script_data('Total wagons this round: ' .. (this.extra_wagons or 0))
end

apply_buffs = function ()
    this.buffs_collected = this.buffs_collected or {}
    apply_buffs_generic(this.buffs, this.buffs_collected, false)
end

apply_permanent_buffs = function ()
    this.permanent_buffs_collected = this.permanent_buffs_collected or {}
    apply_buffs_generic(this.permanent_buffs, this.permanent_buffs_collected, true)
end

-- Returns one or more buffs that have not hit their limit.
-- If count is nil or 1, behaves like before (single buff).
-- If count > 1, returns up to count unique buffs.
local function grant_non_limit_reached_buff(count)
    local all_buffs = Public.get_random_buff(true)
    local starting_items = Public.get_func('starting_items')
    local techs = Public.get_func('techs')
    local limit_types = Public.get_func('limit_types')

    local valid_buffs = {}

    for _, data in pairs(all_buffs) do
        if (not Public.is_modded_pt2 and data.dlc) then
            goto continue
        end

        local skip = false

        for _, item_data in pairs(starting_items) do
            if item_data.buff_type == data.name
                and item_data.item_limit
                and data.limit
                and item_data.item_limit >= data.limit then
                skip = true
                break
            end
        end

        if not skip then
            for _, tech_data in pairs(techs) do
                if tech_data.name == data.name then
                    skip = true
                    break
                end
            end
        end

        if not skip then
            for limit_name, limit_count in pairs(limit_types) do
                if limit_name == data.name then
                    if limit_count and type(limit_count) ~= "boolean" and data.limit then
                        if limit_count >= data.limit then
                            skip = true
                        end
                    else
                        skip = true
                    end
                    break
                end
            end
        end

        if not skip then
            table.insert(valid_buffs, data)
        end

        ::continue::
    end

    for _ = 1, 5 do
        shuffle(valid_buffs)
    end

    if #valid_buffs == 0 then
        return Public.get_random_buff(nil, true)
    end

    if not count or count == 1 then
        return valid_buffs[1]
    end

    local result = {}
    for i = 1, math.min(count, #valid_buffs) do
        table.insert(result, valid_buffs[i])
    end
    return result
end



local function grant_non_limit_reached_buff_permanent()
    local all_buffs = Public.get_random_buff(true)

    local permanent_buff_counts = {}
    if this.permanent_buffs then
        for _, permanent_buff in pairs(this.permanent_buffs) do
            if permanent_buff and permanent_buff.name then
                permanent_buff_counts[permanent_buff.name] = (permanent_buff_counts[permanent_buff.name] or 0) + 1
            end
        end
    end

    for index, data in pairs(all_buffs) do
        local should_remove = false

        if not Public.is_modded_pt2 and data.dlc then
            should_remove = true
        end

        if not should_remove and data.limit and permanent_buff_counts[data.name] then
            if permanent_buff_counts[data.name] >= data.limit then
                should_remove = true
            end
        end

        if not should_remove and data.modifier == 'tech' and data.techs then
            local techs = Public.get_func('techs')
            for _, tech in pairs(data.techs) do
                if tech and techs[tech.name] then
                    should_remove = true
                    break
                end
            end
        end

        if not should_remove and data.modifier == 'starting_items' and data.limit then
            local starting_items = Public.get_func('starting_items')
            for _, item in pairs(data.items or {}) do
                if item and starting_items[item.name] then
                    local current_limit = starting_items[item.name].item_limit or 0
                    if current_limit >= data.limit then
                        should_remove = true
                        break
                    end
                end
            end
        end

        if should_remove then
            all_buffs[index] = nil
        end
    end

    for _ = 1, 5 do
        shuffle(all_buffs)
    end

    if not all_buffs[1] then
        return Public.get_random_buff(nil, true)
    end

    return all_buffs[1]
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

    local server_name_matches = Server.check_server_name(Public.discord_name)

    settings = settings or {}
    local stored_date = this.current_date
    if not stored_date then
        return
    end
    local stored_date_raw = Server.get_current_date(false, true, stored_date)
    local converted_stored_date = round(Utils.convert_date(stored_date_raw.year, stored_date_raw.month, stored_date_raw.day))
    local time_to_reset = (current_date - converted_stored_date)
    this.time_to_reset = this.reset_after - time_to_reset
    if time_to_reset and time_to_reset >= this.reset_after then
        local perm_buff = grant_non_limit_reached_buff_permanent()
        this.permanent_buffs[#this.permanent_buffs + 1] = perm_buff
        Public.save_settings_before_reset()
        Public.set_season_scores()

        local s = this.season or 1
        game.server_save('Season_' .. s .. '_Mtn_v3_' .. tostring(current_time))
        notify_season_over_to_discord(perm_buff)
        settings.current_date = current_time
        settings.test_mode = false
        settings.rounds_survived = 0
        settings.buffs = {}
        this.buffs = {}
        this.buffs_collected = {}
        this.permanent_buffs_collected = {}
        this.rounds_survived = 0
        settings.permanent_buffs = this.permanent_buffs
        this.season = this.season + 1
        this.current_streak = 0
        this.best_streak = 0
        this.current_date = current_time
        settings.season = this.season
        this.time_to_reset = this.reset_after
        local message = ({ 'stateful.reset' })
        local message_discord = ({ 'stateful.reset_discord' })
        game.print(message)
        Server.to_discord_embed(message_discord, true)

        if server_name_matches then
            if Public.is_modded then
                Server.set_data(dataset, dataset_key_modded, deep_copy(settings))
            else
                Server.set_data(dataset, dataset_key, deep_copy(settings))
            end
        else
            if Public.is_modded then
                Server.set_data(dataset, dataset_key_dev_modded, deep_copy(settings))
            else
                Server.set_data(dataset, dataset_key_dev, deep_copy(settings))
            end
        end

        if not settings.disable_shutdown then
            game.print(({ 'entity.notify_shutdown' }), { color = { r = 0.22, g = 0.88, b = 0.22 } })
            local notify_shutdown = ({ 'entity.shutdown_game' })
            Server.to_discord_bold(notify_shutdown, true)
            Task.set_timeout_in_ticks(10, shutdown_scenario_token)
        end

        if settings.restart_scenario then
            game.print(({ 'entity.notify_restart' }), { color = { r = 0.22, g = 0.88, b = 0.22 } })
            local notify_restart = ({ 'entity.notify_restart' })
            Server.to_discord_bold(notify_restart, true)
            Task.set_timeout_in_ticks(10, start_scenario_token)
        end
    end
end

local apply_settings_token =
    Task.register(
        function (data)
            local server_name_matches = Server.check_server_name(Public.discord_name)
            local settings = data and data.value or nil
            local current_time = Server.get_current_time()
            if not current_time then
                return
            end

            if not settings then
                settings =
                {
                    rounds_survived = 0,
                    current_date = tonumber(current_time),
                    season = 1
                }
                if server_name_matches then
                    if Public.is_modded then
                        Server.set_data(dataset, dataset_key_modded, deep_copy(settings))
                    else
                        Server.set_data(dataset, dataset_key, deep_copy(settings))
                    end
                else
                    if Public.is_modded then
                        Server.set_data(dataset, dataset_key_dev_modded, deep_copy(settings))
                    else
                        Server.set_data(dataset, dataset_key_dev, deep_copy(settings))
                    end
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
            this.buffs = settings.buffs or {}
            this.permanent_buffs = settings.permanent_buffs or {}

            this.rounds_survived = settings.rounds_survived
            this.season = settings.season
            this.best_streak = settings.best_streak or 0
            this.current_streak = settings.current_streak or 0

            apply_startup_settings(settings)
            local current_season = Public.get('current_season')
            if current_season and current_season.valid then
                ---@diagnostic disable-next-line: param-type-mismatch
                current_season.text = 'Season: ' .. this.season
            end

            this.objectives = {}
        end
    )

-- Activates delayed techs
function Public.activate_delayed_techs(force)
    local techs = this.delayed_tech
    if not techs then
        return
    end
    if not next(techs) then
        return
    end
    for tech_name, tech_data in pairs(techs) do
        if tech_data then
            force.technologies[tech_name].researched = true
            this.delayed_tech[tech_name] = nil
        end
    end
end

-- local Alert = require 'utils.alert'
-- local Stateful = require 'maps.mountain_fortress_v3.stateful.table'
-- local buff = Stateful.save_settings()
-- Alert.alert_all_players(100, 'Buff granted from previous run: ' .. buff.discord)
-- Alert.alert_all_players(100, 'Buff granted from previous run: ' .. buff.discord)
-- Alert.alert_all_players(100, 'Buff granted from previous run: ' .. buff.discord)
function Public.save_settings(buff)
    local granted_buff = buff or grant_non_limit_reached_buff()
    this.buffs[#this.buffs + 1] = granted_buff

    local settings =
    {
        objectives_time_spent = this.objectives_time_spent,
        rounds_survived = this.rounds_survived,
        season = this.season,
        test_mode = this.test_mode,
        buffs = this.buffs,
        permanent_buffs = this.permanent_buffs,
        current_date = this.current_date
    }

    if this.current_streak > this.best_streak then
        this.best_streak = this.current_streak
        settings.best_streak = this.best_streak
        settings.current_streak = this.current_streak
        Server.output_script_data('New best win streak: ' .. this.best_streak)
    end

    local server_name_matches = Server.check_server_name(Public.discord_name)
    if server_name_matches then
        if Public.is_modded then
            Server.set_data(dataset, dataset_key_modded, deep_copy(settings))
        else
            Server.set_data(dataset, dataset_key, deep_copy(settings))
        end
    else
        if Public.is_modded then
            Server.set_data(dataset, dataset_key_dev_modded, deep_copy(settings))
        else
            Server.set_data(dataset, dataset_key_dev, deep_copy(settings))
        end
    end

    return granted_buff
end

function Public.save_settings_before_reset()
    local settings =
    {
        rounds_survived = this.rounds_survived,
        season = this.season,
        test_mode = this.test_mode,
        buffs = this.buffs,
        permanent_buffs = this.permanent_buffs,
    }
    if this.current_streak > this.best_streak then
        this.best_streak = this.current_streak
        settings.best_streak = this.best_streak
        settings.current_streak = this.current_streak
        Server.output_script_data('New best win streak: ' .. this.best_streak)
    end

    local server_name_matches = Server.check_server_name(Public.discord_name)
    if server_name_matches then
        if Public.is_modded then
            Server.set_data(dataset, dataset_key_modded_previous, deep_copy(settings))
        else
            Server.set_data(dataset, dataset_key_previous, deep_copy(settings))
        end
    else
        if Public.is_modded then
            Server.set_data(dataset, dataset_key_modded_previous_dev, deep_copy(settings))
        else
            Server.set_data(dataset, dataset_key_previous_dev, deep_copy(settings))
        end
    end
end

function Public.reset_stateful(refresh_gui, clear_buffs)
    this.test_mode = false

    this.final_battle = false
    this.extra_wagons = 0
    this.quality_trains = 'normal'
    this.quality_buildings = 'normal'
    if clear_buffs then
        this.buffs_collected = {}
        this.permanent_buffs_collected = {}
    end
    this.enemies_boosted = false
    this.tasks_required_to_win = 5

    if not this.previous_objectives_time_spent then
        this.previous_objectives_time_spent = {}
    end

    if this.test_mode then
        this.objectives =
        {
            randomized_zone = 2,
            supplies = get_random_items(),
            single_item = get_random_item(),
            killed_enemies = 10,
            killed_enemies_type =
            {
                actual = 0,
                expected = 10,
                damage_type = damage_types[random(1, #damage_types)]
            },
            handcrafted_items =
            {
                actual = 0,
                expected = 10,
                name = 'rail'
            },
            handcrafted_items_any =
            {
                actual = 0,
                expected = 10,
                name = 'Any'
            },
            cast_spell =
            {
                actual = 0,
                expected = 10,
                name = 'pipe'
            },
            cast_spell_any =
            {
                actual = 0,
                expected = 10,
                name = 'Any'
            },
            launch_item =
            {
                actual = 0,
                expected = 10,
                name = 'raw-fish'
            },
            research_level_selection = get_random_research_recipe(),
            locomotive_market_coins_spent = 0,
            locomotive_market_coins_spent_required = 1,
            trees_farmed = 10,
            minerals_farmed = 10,
            rockets_launched = 1
        }
    else
        if not this.objectives then
            this.objectives = {}
        end

        if not this.selected_objectives then
            this.selected_objectives = get_random_objectives()
        end

        if not this.objectives.randomized_zone or (this.objectives_completed ~= nil and this.objectives_completed.randomized_zone) then
            this.objectives.randomized_zone = scale(4, 15, 1.013)
        end
        if not this.objectives.supplies or (this.objectives_completed ~= nil and this.objectives_completed.supplies) then
            this.objectives.supplies = get_random_items()
        end
        if not this.objectives.single_item or (this.objectives_completed ~= nil and this.objectives_completed.single_item) then
            this.objectives.single_item = get_random_item()
        end
        if not this.objectives.killed_enemies or (this.objectives_completed ~= nil and this.objectives_completed.killed_enemies) then
            this.objectives.killed_enemies = scale(25000, 400000, 1.03)
        end
        if not this.objectives.killed_enemies_type or (this.objectives_completed ~= nil and this.objectives_completed.killed_enemies_type) then
            this.objectives.killed_enemies_type =
            {
                actual = 0,
                expected = scale(10000, 400000, 1.03),
                damage_type = damage_types[random(1, #damage_types)]
            }
        end
        if not this.objectives.handcrafted_items or (this.objectives_completed ~= nil and this.objectives_completed.handcrafted_items) then
            local item = get_random_handcrafted_item()
            this.objectives.handcrafted_items =
            {
                actual = 0,
                expected = item.count,
                name = item.name,
                quality = item.quality
            }
        end
        if not this.objectives.handcrafted_items_any or (this.objectives_completed ~= nil and this.objectives_completed.handcrafted_items_any) then
            this.objectives.handcrafted_items_any =
            {
                actual = 0,
                expected = scale(50000, 4000000, 1.04),
                name = 'Any',
                quality = 'normal'
            }
        end
        if not this.objectives.cast_spell or (this.objectives_completed ~= nil and this.objectives_completed.cast_spell) then
            local item = get_random_spell()
            this.objectives.cast_spell =
            {
                actual = 0,
                expected = item.count,
                name = item.name,
            }
        end
        if not this.objectives.cast_spell_any or (this.objectives_completed ~= nil and this.objectives_completed.cast_spell_any) then
            this.objectives.cast_spell_any =
            {
                actual = 0,
                expected = scale(100, 1000),
                name = 'Any'
            }
        end
        if not this.objectives.launch_item or (this.objectives_completed ~= nil and this.objectives_completed.launch_item) then
            this.objectives.launch_item =
            {
                actual = 0,
                expected = scale(1, 500),
                name = 'raw-fish'
            }
        end
        if not this.objectives.research_level_selection or (this.objectives_completed ~= nil and this.objectives_completed.research_level_selection) then
            this.objectives.research_level_selection = get_random_research_recipe()
        end
        if not this.objectives.locomotive_market_coins_spent or (this.objectives_completed ~= nil and this.objectives_completed.locomotive_market_coins_spent) then
            this.objectives.locomotive_market_coins_spent =
            {
                spent = 0,
                required = scale(50000, nil, 1.02)
            }
        end
        if not this.objectives.minerals_farmed or (this.objectives_completed ~= nil and this.objectives_completed.minerals_farmed) then
            this.objectives.minerals_farmed = scale(25000, 250000, 1.02)
        end
        if not this.objectives.rockets_launched or (this.objectives_completed ~= nil and this.objectives_completed.rockets_launched) then
            this.objectives.rockets_launched = scale(10, 700, 1.02)
        end
    end

    local supplies = this.objectives.supplies
    for _, supply in pairs(supplies) do
        if supply and supply.total then
            supply.count = supply.total
        end
    end

    if supplies.single_item and supplies.single_item.total then
        supplies.single_item.count = supplies.single_item.total
    end

    WD.set_es_unit_limit(scale_lin(100, 1000, 5.819))

    this.objectives.handcrafted_items.actual = 0
    this.objectives.handcrafted_items_any.actual = 0
    this.objectives.cast_spell.actual = 0
    this.objectives.cast_spell_any.actual = 0
    this.objectives.killed_enemies_type.actual = 0
    this.objectives.launch_item.actual = 0
    this.objectives.research_level_selection.research_count = 0
    this.objectives.locomotive_market_coins_spent.spent = 0

    this.objectives_completed = {}
    if this.objectives_time_spent and next(this.objectives_time_spent) then
        this.previous_objectives_time_spent[#this.previous_objectives_time_spent + 1] = this.objectives_time_spent
    end

    this.stateful_spawn_points =
    {
        { { x = -205, y = -37 }, { x = 195, y = 37 } },
        { { x = -205, y = -112 }, { x = 195, y = 112 } },
        { { x = -205, y = -146 }, { x = 195, y = 146 } },
        { { x = -205, y = -112 }, { x = 195, y = 112 } },
        { { x = -205, y = -72 }, { x = 195, y = 72 } },
        { { x = -205, y = -146 }, { x = 195, y = 146 } },
        { { x = -205, y = -37 }, { x = 195, y = 37 } },
        { { x = -205, y = -5 }, { x = 195, y = 5 } },
        { { x = -205, y = -23 }, { x = 195, y = 23 } },
        { { x = -205, y = -5 }, { x = 195, y = 5 } },
        { { x = -205, y = -72 }, { x = 195, y = 72 } },
        { { x = -205, y = -23 }, { x = 195, y = 23 } },
        { { x = -205, y = -54 }, { x = 195, y = 54 } },
        { { x = -205, y = -80 }, { x = 195, y = 80 } },
        { { x = -205, y = -54 }, { x = 195, y = 54 } },
        { { x = -205, y = -80 }, { x = 195, y = 80 } },
        { { x = -205, y = -103 }, { x = 195, y = 103 } },
        { { x = -205, y = -150 }, { x = 195, y = 150 } },
        { { x = -205, y = -103 }, { x = 195, y = 103 } },
        { { x = -205, y = -150 }, { x = 195, y = 150 } }
    }

    this.objectives_time_spent = {}
    this.objectives_completed_count = 0

    this.collection =
    {
        clear_rocks = nil,
        survive_for = nil,
        survive_for_timer = nil,
        final_arena_disabled = false
    }
    this.stateful_locomotive_migrated = false
    this.force_chunk = true

    local Diff = Difficulty.get()
    Diff.index = scale(1, 3, 1.009)

    if Diff.index == 3 then
        local message = ({ 'stateful.difficulty_step' })
        local delay = 25
        Alert.set_timeout_in_ticks_alert(delay, { text = message })
    end

    Public.set('coin_amount', Diff.index)

    local t =
    {
        ['randomized_zone'] = this.objectives.randomized_zone
    }
    for index = 1, #this.selected_objectives do
        local objective = this.selected_objectives[index]
        if not t[objective.name] then
            t[objective.name] = this.objectives[objective.name]
        end
    end

    this.objectives = t
    clear_all_stats()

    apply_permanent_buffs()
    apply_buffs()
    if refresh_gui then
        Public.refresh_frames()
    end

    local quality_size =
    {
        ['normal'] = 40,
        ['uncommon'] = 45,
        ['rare'] = 50,
        ['epic'] = 55,
        ['legendary'] = 70
    }

    local quality_train = this.quality_trains

    local forced_locomotive_size = Public.get('forced_locomotive_size')
    if forced_locomotive_size then
        quality_train = 'legendary'
    end

    ICW.set('wagon_areas',
        {
            ['cargo-wagon'] = { left_top = { x = -quality_size[quality_train], y = 0 }, right_bottom = { x = quality_size[quality_train], y = 100 } },
            ['fluid-wagon'] = { left_top = { x = -quality_size[quality_train], y = 0 }, right_bottom = { x = quality_size[quality_train], y = 100 } },
            ['locomotive'] = { left_top = { x = -quality_size[quality_train], y = 0 }, right_bottom = { x = quality_size[quality_train], y = 100 } }
        })
end

function Public.move_all_players()
    local active_surface_index = Public.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]
    if not (surface and surface.valid) then
        return
    end

    local locomotive = Public.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    ICWF.disable_auto_minimap()

    local message = ({ 'stateful.final_boss_message_start' })
    Alert.alert_all_players(50, message, nil, nil, 1)
    Core.iter_connected_players(
    ---@param player LuaPlayer
        function (player)
            local pos = surface.find_non_colliding_position('character', locomotive.position, 32, 1)

            Public.stateful_gui.boss_frame(player, true)

            if pos then
                player.teleport(pos, surface)
            else
                player.teleport(locomotive.position, surface)
                Public.unstuck_player(player.index)
            end
        end
    )
end

function Public.create_minerals_lookup_table()
    local entities = prototypes.entity
    for name, entity in pairs(entities) do
        if entity.type == 'tree' or entity.type == 'simple-entity' or entity.type == 'simple-entity-with-owner' then
            minerals_lookup_table[entity.name] = name
        end
    end
end

function Public.create_enemies_lookup_table()
    local entities = prototypes.entity
    for name, entity in pairs(entities) do
        if entity.type == 'unit' then
            enemies_lookup_table[entity.name] = name
        end
    end
end

function Public.set_final_battle()
    if this.final_battle then
        return
    end

    local es_settings = WD.get_es('settings')
    WD.set_es('final_battle', true)
    es_settings.final_battle = true
    es_settings.force_name = 'aggressors_frenzy'
    Public.set('final_battle', true)
end

function Public.allocate()
    local moved_all_players = Public.get_stateful('moved_all_players')
    if not moved_all_players then
        Task.set_timeout_in_ticks(10, move_all_players_token, {})

        Beam.new_valid_targets({ 'wall', 'turret', 'furnace', 'gate' })

        Public.set_stateful('moved_all_players', true)

        ICWT.set('speed', 0.3)
        ICWT.set('final_battle', true)

        local collection = Public.get_stateful('collection')
        if not collection then
            return
        end

        Server.to_discord_embed('Final boss wave is occuring soon!')

        WD.set('final_battle', true)

        if Gui.get_mod_gui_top_frame() then
            Core.iter_players(
                function (player)
                    local g = Gui.get_button_flow(player)['wave_defense']
                    if g and g.valid then
                        g.destroy()
                    end
                end
            )
        else
            Core.iter_connected_players(
                function (player)
                    local wd = player.gui.top['wave_defense']
                    if wd and wd.valid then
                        wd.destroy()
                    end
                end
            )
        end
    end
end

function Public.increase_enemy_damage_and_health()
    if this.enemies_boosted then
        return
    end
    this.enemies_boosted = true


    if this.rounds_survived > 1 then
        for _ = 1, this.rounds_survived do
            Event.raise(ServerCommands.events.on_biters_evolved, { force = game.forces.enemy, health_increase = true })
            Event.raise(ServerCommands.events.on_biters_evolved, { force = game.forces.aggressors })
            Event.raise(ServerCommands.events.on_biters_evolved, { force = game.forces.aggressors_frenzy })
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

function Public.stateful_on_server_started()
    if this.settings_applied then
        return
    end

    local server_name_matches = Server.check_server_name(Public.discord_name)

    this.settings_applied = true

    if server_name_matches then
        if Public.is_modded then
            Server.try_get_data(dataset, dataset_key_modded, apply_settings_token)
        else
            Server.try_get_data(dataset, dataset_key, apply_settings_token)
        end
    else
        if Public.is_modded then
            Server.try_get_data(dataset, dataset_key_dev_modded, apply_settings_token)
        else
            Server.try_get_data(dataset, dataset_key_dev, apply_settings_token)
        end
        this.test_mode = true
    end
end

Event.add(
    ServerCommands.events.on_server_started,
    function ()
        if this.settings_applied then
            return
        end

        local server_name_matches = Server.check_server_name(Public.discord_name)

        this.settings_applied = true

        if server_name_matches then
            if Public.is_modded then
                Server.try_get_data(dataset, dataset_key_modded, apply_settings_token)
            else
                Server.try_get_data(dataset, dataset_key, apply_settings_token)
            end
        else
            if Public.is_modded then
                Server.try_get_data(dataset, dataset_key_dev_modded, apply_settings_token)
            else
                Server.try_get_data(dataset, dataset_key_dev, apply_settings_token)
            end
            this.test_mode = true
        end
    end
)

Server.on_data_set_changed(
    dataset_key,
    function (data)
        if data.value then
            local settings = data.value
            if settings.rounds_survived ~= nil then
                this.rounds_survived = settings.rounds_survived
            end
            if settings.season ~= nil then
                this.season = settings.season
            end
            if settings.best_streak ~= nil then
                this.best_streak = settings.best_streak
            end
            if settings.test_mode ~= nil then
                this.test_mode = settings.test_mode
            end
            if settings.buffs ~= nil then
                this.buffs = settings.buffs
            end
            if settings.current_date ~= nil then
                this.current_date = settings.current_date
            end
        end
    end
)

Server.on_data_set_changed(
    dataset_key_modded,
    function (data)
        if data.value then
            local settings = data.value
            if settings.rounds_survived ~= nil then
                this.rounds_survived = settings.rounds_survived
            end
            if settings.season ~= nil then
                this.season = settings.season
            end
            if settings.best_streak ~= nil then
                this.best_streak = settings.best_streak
            end
            if settings.test_mode ~= nil then
                this.test_mode = settings.test_mode
            end
            if settings.buffs ~= nil then
                this.buffs = settings.buffs
            end
            if settings.permanent_buffs ~= nil then
                this.permanent_buffs = settings.permanent_buffs
            end
            if settings.current_date ~= nil then
                this.current_date = settings.current_date
            end
        end
    end
)

Server.on_data_set_changed(
    dataset_key_dev,
    function (data)
        if data.value then
            local settings = data.value
            if settings.rounds_survived ~= nil then
                this.rounds_survived = settings.rounds_survived
            end
            if settings.season ~= nil then
                this.season = settings.season
            end
            if settings.best_streak ~= nil then
                this.best_streak = settings.best_streak
            end
            if settings.test_mode ~= nil then
                this.test_mode = settings.test_mode
            end
            if settings.buffs ~= nil then
                this.buffs = settings.buffs
            end
            if settings.permanent_buffs ~= nil then
                this.permanent_buffs = settings.permanent_buffs
            end
            if settings.current_date ~= nil then
                this.current_date = settings.current_date
            end
        end
    end
)

Public.buff_to_string = buff_to_string
Public.get_item_produced_count = get_item_produced_count
Public.get_entity_mined_count = get_entity_mined_count
Public.get_killed_enemies_count = get_killed_enemies_count
Public.apply_startup_settings = apply_startup_settings
Public.scale = scale
Public.on_pre_player_died = on_pre_player_died
Public.on_market_item_purchased = on_market_item_purchased
Public.grant_non_limit_reached_buff = grant_non_limit_reached_buff
Public.apply_buffs = apply_buffs
Public.apply_permanent_buffs = apply_permanent_buffs

if _DEBUG then
    local settings = require 'maps.mountain_fortress_v3.stateful._stateful_debug'
    Event.on_init(
        function ()
            local cbl = Task.get(apply_settings_token)
            storage.tokens.utils_server.admins['Gerkiz'] = true
            storage.tokens.utils_server.server_time.secs = 1187954
            cbl(settings)
        end
    )
end


return Public
