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

local this = {
    enabled = false,
    rounds_survived = 0,
    season = 1,
    buffs = {},
    reset_after = 60,
    time_to_reset = 60
}

local random = math.random
local round = math.round
local floor = math.floor
local dataset = 'scenario_settings'
local dataset_key = 'mtn_v3'
local dataset_key_dev = 'mtn_v3_dev'
local dataset_key_previous = 'mtn_v3_previous'
local dataset_key_previous_dev = 'mtn_v3_previous_dev'
local send_ping_to_channel = Discord.channel_names.mtn_channel
local scenario_name = Public.scenario_name

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local damage_types = { 'physical', 'explosion', 'laser' }

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
    local server_name_matches = Server.check_server_name(scenario_name)

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
                        if buff_data.count and buff_to_string[name] then
                            buffs = buffs .. buff_to_string[name] .. ': ' .. buff_data.count
                        else
                            buffs = buffs .. name .. ': Active'
                        end
                    else
                        if buff_data.count and buff_to_string[name] then
                            buffs = buffs .. buff_to_string[name] .. ': ' .. (buff_data.count * 100) .. '%'
                        else
                            buffs = buffs .. name .. ': Active'
                        end
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

local function get_random_buff(fetch_all, only_force)
    local buffs = {
        {
            name = 'character_running_speed_modifier',
            discord = 'Running speed modifier - run faster!',
            modifier = 'force',
            per_force = true,
            state = 0.05
        },
        {
            name = 'manual_mining_speed_modifier',
            discord = 'Mining speed modifier - mine faster!',
            modifier = 'force',
            per_force = true,
            state = 0.15
        },
        {
            name = 'laboratory_speed_modifier',
            discord = 'Laboratory speed modifier - labs work faster!',
            modifier = 'force',
            per_force = true,
            state = 0.15
        },
        {
            name = 'laboratory_productivity_bonus',
            discord = 'Laboratory productivity bonus - labs dupe things!',
            modifier = 'force',
            per_force = true,
            state = 0.15
        },
        {
            name = 'worker_robots_storage_bonus',
            discord = 'Robot storage bonus - robots carry more!',
            modifier = 'force',
            per_force = true,
            state = 1
        },
        {
            name = 'worker_robots_battery_modifier',
            discord = 'Robot battery bonus - robots work longer!',
            modifier = 'force',
            per_force = true,
            state = 1
        },
        {
            name = 'worker_robots_speed_modifier',
            discord = 'Robot speed modifier - robots move faster!',
            modifier = 'force',
            per_force = true,
            state = 0.5
        },
        {
            name = 'mining_drill_productivity_bonus',
            discord = 'Drill productivity bonus - drills work faster!',
            modifier = 'force',
            per_force = true,
            state = 0.5
        },
        {
            name = 'character_health_bonus',
            discord = 'Character health bonus - more health!',
            modifier = 'force',
            per_force = true,
            state = 250
        },
        {
            name = 'distance',
            discord = 'RPG reach distance bonus - reach further!',
            modifier = 'rpg_distance',
            per_force = true,
            modifiers = { 'character_resource_reach_distance_bonus', 'character_item_pickup_distance_bonus', 'character_loot_pickup_distance_bonus', 'character_reach_distance_bonus' },
            state = 0.05
        },
        {
            name = 'manual_crafting_speed_modifier',
            discord = 'Crafting speed modifier - craft faster!',
            modifier = 'force',
            per_force = true,
            state = 0.12
        },
        {
            name = 'xp_bonus',
            discord = 'RPG XP point bonus - more XP points from kills etc.',
            modifier = 'rpg',
            per_force = true,
            state = 0.12
        },
        {
            name = 'xp_level',
            discord = 'RPG XP level bonus - start with more XP levels',
            modifier = 'rpg',
            per_force = true,
            state = 20
        },
        {
            name = 'chemicals_s',
            discord = 'Starting items supplies - start with some sulfur',
            modifier = 'starting_items',
            limit = 200,
            add_per_buff = 50,
            items = {
                { name = 'sulfur', count = 50 }
            }
        },
        {
            name = 'chemicals_p',
            discord = 'Starting items supplies - start with some plastic bar',
            modifier = 'starting_items',
            limit = 200,
            add_per_buff = 50,
            items = {
                { name = 'plastic-bar', count = 100 }
            }
        },
        {
            name = 'supplies',
            discord = 'Starting items supplies - start with some copper and iron plates',
            modifier = 'starting_items',
            limit = 1000,
            add_per_buff = 100,
            items = {
                { name = 'iron-plate',   count = 100 },
                { name = 'copper-plate', count = 100 }
            }
        },
        {
            name = 'supplies_1',
            discord = 'Starting items supplies - start with more copper and iron plates',
            modifier = 'starting_items',
            limit = 1000,
            add_per_buff = 200,
            items = {
                { name = 'iron-plate',   count = 200 },
                { name = 'copper-plate', count = 200 }
            }
        },
        {
            name = 'supplies_2',
            discord = 'Starting items supplies - start with even more copper and iron plates',
            modifier = 'starting_items',
            limit = 1000,
            add_per_buff = 400,
            items = {
                { name = 'iron-plate',   count = 400 },
                { name = 'copper-plate', count = 400 }
            }
        },
        {
            name = 'defense_3',
            discord = 'Defense starting supplies - start with more turrets and ammo',
            modifier = 'starting_items',
            limit = 1,
            add_per_buff = 1,
            items = {
                { name = 'rocket-launcher', count = 1 },
                { name = 'rocket',          count = 100 }
            }
        },
        {
            name = 'armor',
            discord = 'Armor starting supplies - start with some armor and solar panels',
            modifier = 'starting_items',
            limit = 1,
            add_per_buff = 1,
            items = {
                { name = 'modular-armor',         count = 1 },
                { name = 'solar-panel-equipment', count = 2 }
            }
        },
        {
            name = 'production_1',
            discord = 'Production starting supplies - start with some steel furnaces and solid fuel',
            modifier = 'starting_items',
            limit = 2,
            add_per_buff = 1,
            items = {
                { name = 'steel-furnace', count = 4 },
                { name = 'solid-fuel',    count = 100 }
            }
        },
        {
            name = 'fast_startup_1',
            discord = 'Assembling starting supplies - start with some assembling machines T2',
            modifier = 'starting_items',
            limit = 25,
            add_per_buff = 2,
            items = {
                { name = 'assembling-machine-2', count = 2 }
            }
        },
        {
            name = 'fast_startup_2',
            discord = 'Assembling starting supplies - start with some assembling machines T3',
            modifier = 'starting_items',
            limit = 25,
            add_per_buff = 2,
            items = {
                { name = 'assembling-machine-3', count = 2 }
            }
        },
        {
            name = 'heal-thy-buildings',
            discord = 'Repair starting supplies - start with some repair packs',
            modifier = 'starting_items',
            limit = 20,
            add_per_buff = 2,
            items = {
                { name = 'repair-pack', count = 5 }
            }
        },
        {
            name = 'extra_wagons',
            discord = 'Extra wagon at start',
            modifier = 'locomotive',
            state = 1
        },
        {
            name = 'american_oil',
            discord = 'Oil tech - start with some crude oil barrels',
            modifier = 'starting_items',
            limit = 40,
            add_per_buff = 20,
            items = {
                { name = 'crude-oil-barrel', count = 20 }
            }
        },
        {
            name = 'steel_plates',
            discord = 'Steel tech - start with some steel plates',
            modifier = 'starting_items',
            limit = 200,
            add_per_buff = 100,
            items = {
                { name = 'steel-plate', count = 100 }
            }
        },
        {
            name = 'red_science',
            discord = 'Science tech - start with some red science packs',
            modifier = 'starting_items',
            limit = 200,
            add_per_buff = 10,
            items = {
                { name = 'automation-science-pack', count = 10 }
            }
        },
        {
            name = 'roboport_equipement',
            discord = 'Equipement tech - start with a personal roboport',
            modifier = 'starting_items',
            limit = 4,
            add_per_buff = 1,
            items = {
                { name = 'personal-roboport-equipment', count = 1 }
            }
        },
        {
            name = 'mk1_tech_unlocked',
            discord = 'Equipement tech - start with power armor tech unlocked.',
            modifier = 'tech',
            limit = 1,
            add_per_buff = 1,
            techs = {
                { name = 'power-armor', count = 1 }
            }
        },
        {
            name = 'steel_axe_unlocked',
            discord = 'Equipement tech - start with steel axe tech unlocked.',
            modifier = 'tech',
            limit = 1,
            add_per_buff = 1,
            techs = {
                { name = 'steel-axe', count = 1 }
            }
        },
        {
            name = 'military_2_unlocked',
            discord = 'Equipement tech - start with military 2 tech unlocked.',
            modifier = 'tech',
            limit = 1,
            add_per_buff = 1,
            techs = {
                { name = 'military-2', count = 1 }
            }
        },
        {
            name = 'all_the_fish',
            discord = 'Wagon is full of fish!',
            modifier = 'fish',
            limit = 1,
            add_per_buff = 1
        }
    }

    if only_force then
        local force_buffs = {}
        for _, buff in pairs(buffs) do
            if buff.per_force then
                force_buffs[#force_buffs + 1] = buff
            end
        end

        shuffle(force_buffs)
        shuffle(force_buffs)
        shuffle(force_buffs)
        shuffle(force_buffs)
        shuffle(force_buffs)
        shuffle(force_buffs)

        return force_buffs[1]
    end

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

local function get_item_produced_count(player, item_name)
    local force = game.forces.player

    local production = force.get_item_production_statistics(player.surface).input_counts[item_name]
    if not production then
        return false
    end

    return production
end

local function get_entity_mined_count(event, item_name)
    local force = game.forces.player

    local count = 0
    for name, entity_count in pairs(force.get_entity_build_count_statistics(event.surface).output_counts) do
        if name:find(item_name) then
            count = count + entity_count
        end
    end


    return count
end

local function get_killed_enemies_count(primary, secondary)
    local force = game.forces.player

    local count = 0
    for _, surface in pairs(game.surfaces) do
        for name, entity_count in pairs(force.get_kill_count_statistics(surface).input_counts) do
            if name:find(primary) or name:find(secondary) then
                count = count + entity_count
            end
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
            local player = game.get_player(player_index)

            if not player or not player.valid then
                return
            end

            local pos = player.position
            local entities =
                player.surface.find_entities_filtered {
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

    if string.sub(surface.name, 0, #scenario_name) ~= scenario_name then
        return
    end

    -- player.ticks_to_respawn = 1800 * (this.rounds_survived + 1)

    Task.set_timeout_in_ticks(5, search_corpse_token, { player_index = player.index })
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
            local actual = Public.get_killed_enemies_count('biter', 'spitter')
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

            return false, { 'stateful.enemies_killed_type', this.objectives.killed_enemies_type.damage_type }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, {
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

            return false, { 'stateful.crafted_items', this.objectives.handcrafted_items.name }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, {
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

            return false, { 'stateful.crafted_items', this.objectives.handcrafted_items_any.name }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, {
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

            return false, { 'stateful.launch_item', this.objectives.launch_item.name }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, {
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

            return false, { 'stateful.cast_spell', this.objectives.cast_spell.name }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, {
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

            return false, { 'stateful.cast_spell', this.objectives.cast_spell_any.name }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, {
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
        function (event)
            local actual = get_entity_mined_count(event, 'rock') + get_entity_mined_count(event, 'tree')
            local expected = this.objectives.minerals_farmed
            if actual >= expected then
                return true, { 'stateful.minerals_mined' }, { 'stateful.done', format_number(expected, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_completed' }
            end
            return false, { 'stateful.minerals_mined' }, { 'stateful.not_done', format_number(actual, true), format_number(expected, true) }, { 'stateful.generic_tooltip' }, { 'stateful.tooltip_not_completed' }
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

local function get_random_items()
    local items = {
        { 'advanced-circuit',               scale(225000, 9000000) },
        { 'copper-cable',                   scale(3000000, 120000000) },
        { 'copper-plate',                   scale(1500000, 60000000) },
        { 'electric-engine-unit',           scale(10000, 400000) },
        { 'electronic-circuit',             scale(1000000, 40000000) },
        { 'engine-unit',                    scale(20000, 800000) },
        { 'explosives',                     scale(150000, 6000000) },
        { 'iron-gear-wheel',                scale(150000, 6000000) },
        { 'iron-plate',                     scale(2000000, 80000000) },
        { 'iron-stick',                     scale(75000, 3000000) },
        { 'processing-unit',                scale(40000, 1600000) },
        { 'steel-plate',                    scale(200000, 8000000) },
        { 'rocket',                         scale(25000, 1000000) },
        { 'explosive-rocket',               scale(25000, 1000000) },
        { 'slowdown-capsule',               scale(10000, 400000) },
        { 'laser-turret',                   scale(3000, 120000) },
        { 'stone-wall',                     scale(20000, 800000) },
        { 'accumulator',                    scale(5000, 200000) },
        { 'refined-concrete',               scale(15000, 600000) },
        { 'uranium-rounds-magazine',        scale(4000, 160000) },
        { 'explosive-uranium-cannon-shell', scale(3000, 120000) },
        { 'distractor-capsule',             scale(1500, 60000) },
        { 'cluster-grenade',                scale(4000, 160000) },
        { 'small-lamp',                     scale(5000, 200000) },
        { 'uranium-fuel-cell',              scale(2500, 100000) }
    }

    shuffle(items)
    shuffle(items)

    local container = {
        [1] = { name = items[1][1], count = items[1][2] },
        [2] = { name = items[2][1], count = items[2][2] },
        [3] = { name = items[3][1], count = items[3][2] }
    }

    if this.test_mode then
        container = {
            [1] = { name = items[1].products[1].name, count = 1 },
            [2] = { name = items[2].products[1].name, count = 1 },
            [3] = { name = items[3].products[1].name, count = 1 }
        }
    end

    return container
end

local function get_random_item()
    local items = {
        { 'efficiency-module',     scale(1000, 400000) },
        { 'productivity-module',   scale(10000, 400000) },
        { 'speed-module',          scale(10000, 400000) },
        { 'efficiency-module-2',   scale(200, 100000) },
        { 'productivity-module-2', scale(1000, 100000) },
        { 'speed-module-2',        scale(1000, 100000) },
        { 'efficiency-module-3',   scale(50, 30000) },
        { 'productivity-module-3', scale(500, 30000) },
        { 'speed-module-3',        scale(500, 30000) }
    }

    shuffle(items)
    shuffle(items)
    shuffle(items)
    shuffle(items)

    return { name = items[1][1], count = items[1][2] }
end

local function get_random_handcrafted_item()
    local items = {
        { 'advanced-circuit',               scale(2000, 500000) },
        { 'copper-cable',                   scale(10000, 500000) },
        { 'electronic-circuit',             scale(5000, 1000000) },
        { 'iron-gear-wheel',                scale(50000, 1000000) },
        { 'iron-stick',                     scale(75000, 3000000) },
        { 'rocket',                         scale(5000, 1000000) },
        { 'explosive-rocket',               scale(5000, 1000000) },
        { 'slowdown-capsule',               scale(2500, 400000) },
        { 'laser-turret',                   scale(1500, 20000) },
        { 'stone-wall',                     scale(5000, 800000) },
        { 'accumulator',                    scale(1000, 200000) },
        { 'uranium-rounds-magazine',        scale(1000, 60000) },
        { 'explosive-uranium-cannon-shell', scale(1000, 10000) },
        { 'distractor-capsule',             scale(1500, 60000) },
        { 'grenade',                        scale(5000, 200000) },
        { 'cluster-grenade',                scale(1000, 100000) },
        { 'small-lamp',                     scale(2500, 200000) },
        { 'rail',                           scale(5000, 100000) },
        { 'small-electric-pole',            scale(5000, 100000) },
        { 'medium-electric-pole',           scale(3500, 80000) },
        { 'big-electric-pole',              scale(2000, 50000) },
        { 'transport-belt',                 scale(10000, 100000) },
        { 'fast-transport-belt',            scale(3000, 50000) },
        { 'repair-pack',                    scale(10000, 100000) },
        { 'splitter',                       scale(10000, 100000) },
        { 'fast-splitter',                  scale(3000, 50000) },
        { 'inserter',                       scale(3000, 50000) },
        { 'firearm-magazine',               scale(10000, 200000) },
        { 'piercing-rounds-magazine',       scale(5000, 100000) },
        { 'pipe',                           scale(10000, 100000) },
        { 'pipe-to-ground',                 scale(3000, 50000) },
        { 'efficiency-module',              scale(100, 50000) },
        { 'productivity-module',            scale(100, 50000) },
        { 'speed-module',                   scale(100, 50000) }
    }

    shuffle(items)
    shuffle(items)
    shuffle(items)
    shuffle(items)

    return { name = items[1][1], count = items[1][2] }
end

local function get_random_spell()
    local items = {
        { 'small-biter',             scale(100, 2500) },
        { 'small-spitter',           scale(100, 2500) },
        { 'medium-biter',            scale(100, 2500) },
        { 'medium-spitter',          scale(100, 2500) },
        { 'shotgun-shell',           scale(100, 2500) },
        { 'grenade',                 scale(100, 2500) },
        { 'cluster-grenade',         scale(100, 2500) },
        { 'cannon-shell',            scale(100, 2500) },
        { 'explosive-cannon-shell',  scale(100, 2500) },
        { 'uranium-cannon-shell',    scale(100, 2500) },
        { 'rocket',                  scale(100, 2500) },
        { 'acid-stream-spitter-big', scale(100, 2500) },
        { 'explosives',              scale(100, 2500) },
        { 'distractor-capsule',      scale(100, 2500) },
        { 'defender-capsule',        scale(100, 2500) },
        { 'destroyer-capsule',       scale(100, 2500) },
        { 'warp-gate',               scale(100, 2500) },
        { 'haste',                   scale(100, 2500) }
    }

    shuffle(items)
    shuffle(items)
    shuffle(items)
    shuffle(items)

    return { name = items[1][1], count = items[1][2] }
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
        return { name = research_level_list[1], count = 1, research_count = 0 }
    end

    return { name = research_level_list[1], count = scale(2, 9, 1.03), research_count = 0 }
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
            name = 'killed_enemies_type',
            token = killed_enemies_type_token
        },
        {
            name = 'handcrafted_items',
            token = handcrafted_items_token
        },
        {
            name = 'handcrafted_items_any',
            token = handcrafted_items_any_token
        },
        {
            name = 'cast_spell',
            token = cast_spell_token
        },
        {
            name = 'launch_item',
            token = launch_item_token
        },
        {
            name = 'cast_spell_any',
            token = cast_spell_any_token
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
            name = 'minerals_farmed',
            token = minerals_farmed_token
        },
        {
            name = 'rockets_launched',
            token = rockets_launched_token
        }
    }

    shuffle(items)
    shuffle(items)
    shuffle(items)
    shuffle(items)

    if _DEBUG then
        items[#items + 1] = {
            name = 'supplies',
            token = empty_token
        }
        return items
    end

    return {
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
    this.extra_wagons = 0
    local rpg_extra = RPG.get('rpg_extra')
    rpg_extra.difficulty = 0
    rpg_extra.grant_xp_level = 0
end

local function migrate_buffs()
    local state_buffs = get_random_buff(true)

    for _, data in pairs(state_buffs) do
        for index, buff in pairs(this.buffs) do
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

                if buff.items == 0 then
                    this.buffs[index] = nil
                end
            end
        end
    end
end

local function apply_buffs()
    local starting_items = Public.get_func('starting_items')
    local techs = Public.get_func('techs')
    local limit_types = Public.get_func('limit_types')

    if this.buffs and next(this.buffs) then
        local total_buffs = 0
        if not this.buffs_collected then
            this.buffs_collected = {}
        end

        migrate_buffs()

        local force = game.forces.player
        for _, buff in pairs(this.buffs) do
            if buff then
                total_buffs = total_buffs + 1
                if buff.modifier == 'rpg_distance' then
                    for _, buff_name in pairs(buff.modifiers) do
                        if buff_name == 'character_reach_distance_bonus' then
                            buff.state = 1
                        end

                        force[buff_name] = force[buff_name] + buff.state

                        if not this.buffs_collected[buff_name] then
                            this.buffs_collected[buff_name] = {
                                name = 'Extra Reach',
                                count = buff.state,
                                discord = buff.discord,
                                force = true
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
                            count = buff.state,
                            discord = buff.discord,
                            force = true
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

                    if not this.buffs_collected['locomotive'] then
                        this.buffs_collected['locomotive'] = {
                            name = 'Extra Wagons',
                            count = buff.state,
                            discord = buff.discord
                        }
                    else
                        if this.extra_wagons > 4 then
                            this.buffs_collected['locomotive'].count = this.extra_wagons
                        else
                            this.buffs_collected['locomotive'].count = this.extra_wagons + buff.state
                        end
                    end

                    if this.extra_wagons > 4 then
                        this.extra_wagons = 4
                    end
                end
                if buff.modifier == 'fish' then
                    limit_types[buff.name] = true
                    Public.set('all_the_fish', true)
                    if not this.buffs_collected['fish'] then
                        this.buffs_collected['fish'] = {
                            name = 'A thousand fishes',
                            discord = buff.discord
                        }
                    end
                end
                if buff.modifier == 'tech' then
                    if not this.buffs_collected['techs'] then
                        this.buffs_collected['techs'] = {}
                    end
                    if type(buff.techs) ~= 'table' then
                        goto cont
                    end

                    for _, tech in pairs(buff.techs) do
                        if tech then
                            if techs[tech.name] then
                                goto cont
                            end

                            if not techs[tech.name] then
                                techs[tech.name] = {
                                    name = buff.name
                                }
                            end

                            if not this.buffs_collected['techs'][tech.name] then
                                this.buffs_collected['techs'][tech.name] = {
                                    name = tech.name,
                                    buff_type = buff.name,
                                    discord = buff.discord
                                }
                            end
                            force.technologies[tech.name].researched = true
                        end
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
                                name = 'XP Bonus',
                                count = buff.state,
                                discord = buff.discord
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
                                name = 'XP Level Bonus',
                                count = buff.state,
                                discord = buff.discord
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
                    if type(buff.items) ~= 'table' then
                        goto cont
                    end

                    for _, item in pairs(buff.items) do
                        if item then
                            if starting_items[item.name] and buff.limit and starting_items[item.name].item_limit and starting_items[item.name].item_limit >= buff.limit then
                                starting_items[item.name].limit_reached = true
                                goto cont -- break if there is a limit set
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
                                    count = item.count,
                                    discord = buff.discord
                                }
                            end
                        end
                    end
                end
            end
            ::cont::
        end
        this.total_buffs = total_buffs
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

    local server_name_matches = Server.check_server_name(scenario_name)

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
        Public.save_settings_before_reset()
        Public.set_season_scores()

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
        local message = ({ 'stateful.reset' })
        local message_discord = ({ 'stateful.reset_discord' })
        game.print(message)
        Server.to_discord_embed(message_discord, true)

        -- game.print(({ 'entity.notify_shutdown' }), { r = 0.22, g = 0.88, b = 0.22 })
        -- local notify_shutdown = ({ 'entity.shutdown_game' })
        -- Server.to_discord_bold(notify_shutdown, true)

        -- Server.stop_scenario()

        if server_name_matches then
            Server.set_data(dataset, dataset_key, settings)
        else
            Server.set_data(dataset, dataset_key_dev, settings)
        end
    end
end

local apply_settings_token =
    Task.register(
        function (data)
            local server_name_matches = Server.check_server_name(scenario_name)
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


            this.rounds_survived = settings.rounds_survived
            this.season = settings.season

            apply_startup_settings(settings)
            local current_season = Public.get('current_season')
            if current_season and current_season.valid then
                ---@diagnostic disable-next-line: param-type-mismatch
                current_season.text = 'Season: ' .. this.season
            end

            this.objectives = {}

            Public.reset_stateful()
            Public.increase_enemy_damage_and_health()
            Public.init_mtn()
        end
    )

local function grant_non_limit_reached_buff()
    local all_buffs = get_random_buff(true)
    local starting_items = Public.get_func('starting_items')
    local techs = Public.get_func('techs')
    local limit_types = Public.get_func('limit_types')

    for index, data in pairs(all_buffs) do
        for _, item_data in pairs(starting_items) do
            if item_data.buff_type == data.name and item_data.item_limit and data.limit and item_data.item_limit >= data.limit then
                all_buffs[index] = nil
            end
        end

        for _, tech_data in pairs(techs) do
            if tech_data.name == data.name then
                all_buffs[index] = nil
            end
        end

        for limit_name, _ in pairs(limit_types) do
            if limit_name == data.name then
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
        return get_random_buff(nil, true)
    end

    return all_buffs[1]
end

function Public.save_settings()
    local granted_buff = grant_non_limit_reached_buff()
    this.buffs[#this.buffs + 1] = granted_buff

    local settings = {
        objectives_time_spent = this.objectives_time_spent,
        rounds_survived = this.rounds_survived,
        season = this.season,
        test_mode = this.test_mode,
        buffs = this.buffs,
        current_date = this.current_date
    }

    local server_name_matches = Server.check_server_name(scenario_name)
    if server_name_matches then
        Server.set_data(dataset, dataset_key, settings)
    else
        Server.set_data(dataset, dataset_key_dev, settings)
    end

    return granted_buff
end

function Public.save_settings_before_reset()
    local settings = {
        rounds_survived = this.rounds_survived,
        season = this.season,
        test_mode = this.test_mode,
        buffs = this.buffs,
        current_date = this.current_date
    }

    local server_name_matches = Server.check_server_name(scenario_name)
    if server_name_matches then
        Server.set_data(dataset, dataset_key_previous, settings)
    else
        Server.set_data(dataset, dataset_key_previous_dev, settings)
    end
end

function Public.reset_stateful(refresh_gui, clear_buffs)
    this.test_mode = false

    this.final_battle = false
    this.extra_wagons = 0
    if clear_buffs then
        this.buffs_collected = {}
    end
    this.enemies_boosted = false
    this.tasks_required_to_win = 6

    if not this.previous_objectives_time_spent then
        this.previous_objectives_time_spent = {}
    end

    if this.test_mode then
        this.objectives = {
            randomized_zone = 2,
            randomized_wave = 2,
            supplies = get_random_items(),
            single_item = get_random_item(),
            killed_enemies = 10,
            killed_enemies_type = {
                actual = 0,
                expected = 10,
                damage_type = damage_types[random(1, #damage_types)]
            },
            handcrafted_items = {
                actual = 0,
                expected = 10,
                name = 'rail'
            },
            handcrafted_items_any = {
                actual = 0,
                expected = 10,
                name = 'Any'
            },
            cast_spell = {
                actual = 0,
                expected = 10,
                name = 'pipe'
            },
            cast_spell_any = {
                actual = 0,
                expected = 10,
                name = 'Any'
            },
            launch_item = {
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
        if not this.objectives.randomized_wave or (this.objectives_completed ~= nil and this.objectives_completed.randomized_wave) then
            this.objectives.randomized_wave = scale(200, 1000)
        end
        if not this.objectives.supplies or (this.objectives_completed ~= nil and this.objectives_completed.supplies) then
            this.objectives.supplies = get_random_items()
        end
        if not this.objectives.single_item or (this.objectives_completed ~= nil and this.objectives_completed.single_item) then
            this.objectives.single_item = get_random_item()
        end
        if not this.objectives.killed_enemies or (this.objectives_completed ~= nil and this.objectives_completed.killed_enemies) then
            this.objectives.killed_enemies = scale(25000, 400000, 1.035)
        end
        if not this.objectives.killed_enemies_type or (this.objectives_completed ~= nil and this.objectives_completed.killed_enemies_type) then
            this.objectives.killed_enemies_type = {
                actual = 0,
                expected = scale(10000, 400000, 1.035),
                damage_type = damage_types[random(1, #damage_types)]
            }
        end
        if not this.objectives.handcrafted_items or (this.objectives_completed ~= nil and this.objectives_completed.handcrafted_items) then
            local item = get_random_handcrafted_item()
            this.objectives.handcrafted_items = {
                actual = 0,
                expected = item.count,
                name = item.name
            }
        end
        if not this.objectives.handcrafted_items_any or (this.objectives_completed ~= nil and this.objectives_completed.handcrafted_items_any) then
            this.objectives.handcrafted_items_any = {
                actual = 0,
                expected = scale(50000, 4000000),
                name = 'Any'
            }
        end
        if not this.objectives.cast_spell or (this.objectives_completed ~= nil and this.objectives_completed.cast_spell) then
            local item = get_random_spell()
            this.objectives.cast_spell = {
                actual = 0,
                expected = item.count,
                name = item.name
            }
        end
        if not this.objectives.cast_spell_any or (this.objectives_completed ~= nil and this.objectives_completed.cast_spell_any) then
            this.objectives.cast_spell_any = {
                actual = 0,
                expected = scale(100, 1000),
                name = 'Any'
            }
        end
        if not this.objectives.launch_item or (this.objectives_completed ~= nil and this.objectives_completed.launch_item) then
            local item = get_random_handcrafted_item()
            this.objectives.launch_item = {
                actual = 0,
                expected = scale(1, 50),
                name = item.name
            }
        end
        if not this.objectives.research_level_selection or (this.objectives_completed ~= nil and this.objectives_completed.research_level_selection) then
            this.objectives.research_level_selection = get_random_research_recipe()
        end
        if not this.objectives.locomotive_market_coins_spent or (this.objectives_completed ~= nil and this.objectives_completed.locomotive_market_coins_spent) then
            this.objectives.locomotive_market_coins_spent = {
                spent = 0,
                required = scale(50000)
            }
        end
        if not this.objectives.minerals_farmed or (this.objectives_completed ~= nil and this.objectives_completed.minerals_farmed) then
            this.objectives.minerals_farmed = scale(25000, 250000)
        end
        if not this.objectives.rockets_launched or (this.objectives_completed ~= nil and this.objectives_completed.rockets_launched) then
            this.objectives.rockets_launched = scale(10, 700)
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

    this.stateful_spawn_points = {
        { { x = -205, y = -37 },  { x = 195, y = 37 } },
        { { x = -205, y = -112 }, { x = 195, y = 112 } },
        { { x = -205, y = -146 }, { x = 195, y = 146 } },
        { { x = -205, y = -112 }, { x = 195, y = 112 } },
        { { x = -205, y = -72 },  { x = 195, y = 72 } },
        { { x = -205, y = -146 }, { x = 195, y = 146 } },
        { { x = -205, y = -37 },  { x = 195, y = 37 } },
        { { x = -205, y = -5 },   { x = 195, y = 5 } },
        { { x = -205, y = -23 },  { x = 195, y = 23 } },
        { { x = -205, y = -5 },   { x = 195, y = 5 } },
        { { x = -205, y = -72 },  { x = 195, y = 72 } },
        { { x = -205, y = -23 },  { x = 195, y = 23 } },
        { { x = -205, y = -54 },  { x = 195, y = 54 } },
        { { x = -205, y = -80 },  { x = 195, y = 80 } },
        { { x = -205, y = -54 },  { x = 195, y = 54 } },
        { { x = -205, y = -80 },  { x = 195, y = 80 } },
        { { x = -205, y = -103 }, { x = 195, y = 103 } },
        { { x = -205, y = -150 }, { x = 195, y = 150 } },
        { { x = -205, y = -103 }, { x = 195, y = 103 } },
        { { x = -205, y = -150 }, { x = 195, y = 150 } }
    }

    this.objectives_time_spent = {}
    this.objectives_completed_count = 0

    this.collection = {
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

    Public.reset_main_table()

    clear_all_stats()

    apply_buffs()
    if refresh_gui then
        Public.refresh_frames()
    end
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

    if _DEBUG then
        Core.iter_fake_connected_players(
            storage.characters,
            function (player)
                local pos = surface.find_non_colliding_position('character', locomotive.position, 32, 1)

                if pos then
                    player.teleport(pos, surface)
                else
                    player.teleport(locomotive.position, surface)
                    Public.unstuck_player(player.index)
                end
            end
        )
    end
end

function Public.set_final_battle()
    if this.final_battle then
        return
    end

    local es_settings = WD.get_es('settings')
    WD.set_es('final_battle', true)
    es_settings.final_battle = true
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

    if this.rounds_survived == 1 then
        Event.raise(WD.events.on_biters_evolved, { force = game.forces.enemy, health_increase = true })
        Event.raise(WD.events.on_biters_evolved, { force = game.forces.aggressors })
        Event.raise(WD.events.on_biters_evolved, { force = game.forces.aggressors_frenzy })
    else
        for _ = 1, this.rounds_survived do
            Event.raise(WD.events.on_biters_evolved, { force = game.forces.enemy, health_increase = true })
            Event.raise(WD.events.on_biters_evolved, { force = game.forces.aggressors })
            Event.raise(WD.events.on_biters_evolved, { force = game.forces.aggressors_frenzy })
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

    local server_name_matches = Server.check_server_name(scenario_name)

    this.settings_applied = true

    if server_name_matches then
        Server.try_get_data(dataset, dataset_key, apply_settings_token)
    else
        Server.try_get_data(dataset, dataset_key_dev, apply_settings_token)
        this.test_mode = true
    end
end

Event.add(
    Server.events.on_server_started,
    function ()
        if this.settings_applied then
            return
        end

        local server_name_matches = Server.check_server_name(scenario_name)

        this.settings_applied = true

        if server_name_matches then
            Server.try_get_data(dataset, dataset_key, apply_settings_token)
        else
            Server.try_get_data(dataset, dataset_key_dev, apply_settings_token)
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

Public.buff_to_string = buff_to_string
Public.get_random_buff = get_random_buff
Public.get_item_produced_count = get_item_produced_count
Public.get_entity_mined_count = get_entity_mined_count
Public.get_killed_enemies_count = get_killed_enemies_count
Public.apply_startup_settings = apply_startup_settings
Public.scale = scale
Public.on_pre_player_died = on_pre_player_died
Public.on_market_item_purchased = on_market_item_purchased

return Public
