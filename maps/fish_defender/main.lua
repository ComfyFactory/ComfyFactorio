--luacheck: ignore
-- fish defender -- by mewmew --

--require "modules.rpg"

require 'maps.fish_defender.market'
require 'maps.fish_defender.commands'
require 'maps.fish_defender.on_entity_damaged'
require 'modules.rocket_launch_always_yields_science'
require 'modules.biters_yield_coins'
require 'modules.dangerous_goods'
require 'modules.custom_death_messages'
require 'modules.launch_fish_to_win'

local AntiGrief = require 'utils.antigrief'
local Terrain = require 'maps.fish_defender.terrain'
local Unit_health_booster = require 'modules.biter_health_booster'
local Session = require 'utils.datastore.session_data'
local Difficulty = require 'modules.difficulty_vote'
local Map = require 'modules.map_info'
local Event = require 'utils.event'
local Reset = require 'utils.functions.soft_reset'
local Server = require 'utils.server'
local Poll = require 'utils.gui.poll'
local boss_biter = require 'maps.fish_defender.boss_biters'
local FDT = require 'maps.fish_defender.table'
local Score = require 'utils.gui.score'
local math_random = math.random
local insert = table.insert
local enable_start_grace_period = true

local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16, ['raw-fish'] = 3, ['iron-plate'] = 32}

local biter_count_limit = 1024 --maximum biters on the east side of the map, next wave will be delayed if the maximum has been reached
local boss_waves = {
    [50] = {{name = 'big-biter', count = 3}},
    [100] = {{name = 'behemoth-biter', count = 1}},
    [150] = {{name = 'behemoth-spitter', count = 4}, {name = 'big-spitter', count = 16}},
    [200] = {
        {name = 'behemoth-biter', count = 4},
        {name = 'behemoth-spitter', count = 2},
        {name = 'big-biter', count = 32}
    },
    [250] = {
        {name = 'behemoth-biter', count = 8},
        {name = 'behemoth-spitter', count = 4},
        {name = 'big-spitter', count = 32}
    },
    [300] = {{name = 'behemoth-biter', count = 16}, {name = 'behemoth-spitter', count = 8}}
}

local difficulties_votes = {
    [1] = {wave_interval = 4500, amount_modifier = 0.52, strength_modifier = 0.40, boss_modifier = 3.0},
    [2] = {wave_interval = 4100, amount_modifier = 0.76, strength_modifier = 0.65, boss_modifier = 4.0},
    [3] = {wave_interval = 3800, amount_modifier = 0.92, strength_modifier = 0.85, boss_modifier = 5.0},
    [4] = {wave_interval = 3600, amount_modifier = 1.00, strength_modifier = 1.00, boss_modifier = 6.0},
    [5] = {wave_interval = 3400, amount_modifier = 1.08, strength_modifier = 1.25, boss_modifier = 7.0},
    [6] = {wave_interval = 3100, amount_modifier = 1.24, strength_modifier = 1.75, boss_modifier = 8.0},
    [7] = {wave_interval = 2700, amount_modifier = 1.48, strength_modifier = 2.50, boss_modifier = 9.0}
}

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = math.random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

local function create_wave_gui(player)
    if player.gui.top['fish_defense_waves'] then
        player.gui.top['fish_defense_waves'].destroy()
    end
    local this = FDT.get()
    local frame = player.gui.top.add({type = 'frame', name = 'fish_defense_waves', tooltip = 'Click to show map info'})
    frame.style.maximal_height = 38

    local wave_count = 0
    if this.wave_count then
        wave_count = this.wave_count
    end

    if not this.wave_grace_period then
        local label = frame.add({type = 'label', caption = 'Wave: ' .. wave_count})
        label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
        label.style.font = 'default-listbox'
        label.style.left_padding = 4
        label.style.right_padding = 4
        label.style.minimal_width = 68
        label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

        local next_level_progress = game.tick % this.wave_interval / this.wave_interval

        local progressbar = frame.add({type = 'progressbar', value = next_level_progress})
        progressbar.style.minimal_width = 120
        progressbar.style.maximal_width = 120
        progressbar.style.top_padding = 10
    else
        local time_remaining = math.floor(((this.wave_grace_period - (game.tick % this.wave_grace_period)) / 60) / 60)
        if time_remaining <= 0 then
            this.wave_grace_period = nil
            return
        end

        local label = frame.add({type = 'label', caption = 'Waves will start in ' .. time_remaining .. ' minutes.'})
        label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
        label.style.font = 'default-listbox'
        label.style.left_padding = 4
        label.style.right_padding = 4
        label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

        if not enable_start_grace_period then
            this.wave_grace_period = nil
            return
        end
    end
end

local function show_fd_stats(player)
    local gui_id = 'fd-stats'
    local table_id = gui_id .. 'table'
    local entity_limits = FDT.get('entity_limits')

    if player.gui.left[gui_id] then
        player.gui.left[gui_id].destroy()
    end

    local frame =
        player.gui.left.add {
        type = 'frame',
        name = gui_id
    }
    local table =
        frame.add {
        type = 'table',
        name = table_id,
        column_count = 2
    }

    local table_header = {'Building', 'Placed' .. '/' .. 'Limit'}
    for k, v in pairs(table_header) do
        local h = table.add {type = 'label', caption = v}
        h.style.font = 'heading-2'
    end

    for k, v in pairs(entity_limits) do
        local name = v.str
        local placed = v.placed
        local limit = v.limit
        local entry = {name, placed .. '/' .. limit}
        for k, v in pairs(entry) do
            table.add {
                type = 'label',
                caption = v
            }
        end
    end
end

local function update_fd_stats()
    for _, player in pairs(game.connected_players) do
        if player.gui.left['fd-stats'] then
            show_fd_stats(player)
        end
    end
end

local function add_fd_stats_button(player)
    local button_id = 'fd-stats-button'
    if player.gui.top[button_id] then
        player.gui.top[button_id].destroy()
    end
    local button =
        player.gui.top.add {
        type = 'sprite-button',
        name = button_id,
        sprite = 'item/submachine-gun'
    }
end

local function on_gui_click(event)
    if not event.element.valid then
        return
    end
    if event.element.name ~= 'fd-stats-button' then
        return
    end
    local player = game.players[event.player_index]
    local frame = player.gui.left['fd-stats']
    if frame == nil then
        show_fd_stats(player)
    else
        frame.destroy()
    end
end

local function on_market_item_purchased(event)
    update_fd_stats()
end

local threat_values = {
    ['small_biter'] = 1,
    ['medium_biter'] = 3,
    ['big_biter'] = 5,
    ['behemoth_biter'] = 10,
    ['small_spitter'] = 1,
    ['medium_spitter'] = 3,
    ['big_spitter'] = 5,
    ['behemoth_spitter'] = 10
}

local function get_biter_initial_pool()
    local wave_count = FDT.get('wave_count')
    local biter_pool
    if wave_count > 1750 then
        biter_pool = {
            {name = 'behemoth-biter', threat = threat_values.behemoth_biter, weight = 2},
            {name = 'behemoth-spitter', threat = threat_values.behemoth_spitter, weight = 1}
        }
        return biter_pool
    end
    if wave_count > 1500 then
        biter_pool = {
            {name = 'big-biter', threat = threat_values.big_biter, weight = 1},
            {name = 'behemoth-biter', threat = threat_values.behemoth_biter, weight = 2},
            {name = 'behemoth-spitter', threat = threat_values.behemoth_spitter, weight = 1}
        }
        return biter_pool
    end
    if wave_count > 1250 then
        biter_pool = {
            {name = 'big-biter', threat = threat_values.big_biter, weight = 2},
            {name = 'behemoth-biter', threat = threat_values.behemoth_biter, weight = 2},
            {name = 'behemoth-spitter', threat = threat_values.behemoth_spitter, weight = 1}
        }
        return biter_pool
    end
    if wave_count > 1000 then
        biter_pool = {
            {name = 'big-biter', threat = threat_values.big_biter, weight = 3},
            {name = 'behemoth-biter', threat = threat_values.behemoth_biter, weight = 2},
            {name = 'behemoth-spitter', threat = threat_values.behemoth_spitter, weight = 1}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.1 then
        biter_pool = {
            {name = 'small-biter', threat = threat_values.small_biter, weight = 3},
            {name = 'small-spitter', threat = threat_values.small_spitter, weight = 1}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.2 then
        biter_pool = {
            {name = 'small-biter', threat = threat_values.small_biter, weight = 10},
            {name = 'medium-biter', threat = threat_values.medium_biter, weight = 2},
            {name = 'small-spitter', threat = threat_values.small_spitter, weight = 5},
            {name = 'medium-spitter', threat = threat_values.medium_spitter, weight = 1}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.3 then
        biter_pool = {
            {name = 'small-biter', threat = threat_values.small_biter, weight = 18},
            {name = 'medium-biter', threat = threat_values.medium_biter, weight = 6},
            {name = 'small-spitter', threat = threat_values.small_spitter, weight = 8},
            {name = 'medium-spitter', threat = threat_values.medium_spitter, weight = 3},
            {name = 'big-biter', threat = threat_values.big_biter, weight = 1}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.4 then
        biter_pool = {
            {name = 'small-biter', threat = threat_values.small_biter, weight = 2},
            {name = 'medium-biter', threat = threat_values.medium_biter, weight = 8},
            {name = 'big-biter', threat = threat_values.big_biter, weight = 2},
            {name = 'small-spitter', threat = threat_values.small_spitter, weight = 1},
            {name = 'medium-spitter', threat = threat_values.medium_spitter, weight = 4},
            {name = 'big-spitter', threat = threat_values.big_spitter, weight = 1}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.5 then
        biter_pool = {
            {name = 'small-biter', threat = threat_values.small_biter, weight = 2},
            {name = 'medium-biter', threat = threat_values.medium_biter, weight = 4},
            {name = 'big-biter', threat = threat_values.big_biter, weight = 8},
            {name = 'small-spitter', threat = threat_values.small_spitter, weight = 1},
            {name = 'medium-spitter', threat = threat_values.medium_spitter, weight = 2},
            {name = 'big-spitter', threat = threat_values.big_spitter, weight = 4}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.6 then
        biter_pool = {
            {name = 'medium-biter', threat = threat_values.medium_biter, weight = 4},
            {name = 'big-biter', threat = threat_values.big_biter, weight = 8},
            {name = 'medium-spitter', threat = threat_values.medium_spitter, weight = 2},
            {name = 'big-spitter', threat = threat_values.big_spitter, weight = 4}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.7 then
        biter_pool = {
            {name = 'behemoth-biter', threat = threat_values.small_biter, weight = 2},
            {name = 'medium-biter', threat = threat_values.medium_biter, weight = 12},
            {name = 'big-biter', threat = threat_values.big_biter, weight = 20},
            {name = 'behemoth-spitter', threat = threat_values.small_spitter, weight = 1},
            {name = 'medium-spitter', threat = threat_values.medium_spitter, weight = 6},
            {name = 'big-spitter', threat = threat_values.big_spitter, weight = 10}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.8 then
        biter_pool = {
            {name = 'behemoth-biter', threat = threat_values.small_biter, weight = 2},
            {name = 'medium-biter', threat = threat_values.medium_biter, weight = 4},
            {name = 'big-biter', threat = threat_values.big_biter, weight = 10},
            {name = 'behemoth-spitter', threat = threat_values.small_spitter, weight = 1},
            {name = 'medium-spitter', threat = threat_values.medium_spitter, weight = 2},
            {name = 'big-spitter', threat = threat_values.big_spitter, weight = 5}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor <= 0.9 then
        biter_pool = {
            {name = 'big-biter', threat = threat_values.big_biter, weight = 12},
            {name = 'behemoth-biter', threat = threat_values.behemoth_biter, weight = 2},
            {name = 'big-spitter', threat = threat_values.big_spitter, weight = 6},
            {name = 'behemoth-spitter', threat = threat_values.behemoth_spitter, weight = 1}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor <= 1 then
        biter_pool = {
            {name = 'big-biter', threat = threat_values.big_biter, weight = 4},
            {name = 'behemoth-biter', threat = threat_values.behemoth_biter, weight = 2},
            {name = 'big-spitter', threat = threat_values.big_spitter, weight = 2},
            {name = 'behemoth-spitter', threat = threat_values.behemoth_spitter, weight = 1}
        }
        return biter_pool
    end
end

local function get_biter_pool()
    local biter_pool = get_biter_initial_pool()
    local biter_raffle = {}
    for _, biter_type in pairs(biter_pool) do
        for x = 1, biter_type.weight, 1 do
            insert(biter_raffle, {name = biter_type.name, threat = biter_type.threat})
        end
    end
    return biter_raffle
end

local function spawn_biter(pos, biter_pool)
    local this = FDT.get()
    if this.attack_wave_threat < 1 then
        return false
    end

    local surface = game.surfaces[this.active_surface_index]
    biter_pool = shuffle(biter_pool)
    this.attack_wave_threat = this.attack_wave_threat - biter_pool[1].threat
    local valid_pos = surface.find_non_colliding_position(biter_pool[1].name, pos, 100, 2)
    local biter = surface.create_entity({name = biter_pool[1].name, position = valid_pos})
    biter.ai_settings.allow_destroy_when_commands_fail = false
    biter.ai_settings.allow_try_return_to_spawner = false
    return biter
end

local function get_y_coord_raffle_table()
    local t = {}
    for y = -96, 96, 8 do
        t[#t + 1] = y
    end
    table.shuffle_table(t)
    return t
end

local attack_group_count_thresholds = {
    {0, 1},
    {50, 2},
    {100, 3},
    {150, 4},
    {200, 5},
    {1000, 6},
    {2000, 7},
    {3000, 8}
}

local function get_number_of_attack_groups()
    local n = 1
    local this = FDT.get()
    for _, entry in pairs(attack_group_count_thresholds) do
        if this.wave_count >= entry[1] then
            n = entry[2]
        end
    end
    return n
end

local function clear_corpses(surface)
    local wave_count = FDT.get('wave_count')

    if not wave_count then
        return
    end
    local chance = 4
    if wave_count > 250 then
        chance = 3
    end
    if wave_count > 500 then
        chance = 2
    end
    for _, entity in pairs(surface.find_entities_filtered {type = 'corpse'}) do
        if math_random(1, chance) == 1 then
            entity.destroy()
        end
    end
end

local function send_unit_group(unit_group)
    local commands = {}
    local market = FDT.get('market')
    for x = unit_group.position.x, market.position.x, -48 do
        local destination = unit_group.surface.find_non_colliding_position('stone-wall', {x = x, y = unit_group.position.y}, 32, 4)
        if destination then
            commands[#commands + 1] = {
                type = defines.command.attack_area,
                destination = destination,
                radius = 16,
                distraction = defines.distraction.by_enemy
            }
        end
    end
    commands[#commands + 1] = {
        type = defines.command.attack_area,
        destination = {x = market.position.x, y = unit_group.position.y},
        radius = 16,
        distraction = defines.distraction.by_enemy
    }
    commands[#commands + 1] = {
        type = defines.command.attack,
        target = market,
        distraction = defines.distraction.by_enemy
    }

    unit_group.set_command(
        {
            type = defines.command.compound,
            structure_type = defines.compound_command.logical_and,
            commands = commands
        }
    )
end

local function spawn_boss_units(surface)
    local Diff = Difficulty.get()
    local this = FDT.get()
    if this.wave_count <= 2000 then
        game.print({'fish_defender.boss_message', this.wave_count, {'fish_defender.' .. this.wave_count}}, {r = 0.8, g = 0.1, b = 0.1})
    else
        game.print({'fish_defender.boss_message', this.wave_count}, {r = 0.8, g = 0.1, b = 0.1})
    end

    if not boss_waves[this.wave_count] then
        local amount = this.wave_count
        if amount > 1000 then
            amount = 1000
        end
        boss_waves[this.wave_count] = {
            {name = 'behemoth-biter', count = math.floor(amount / 20)},
            {name = 'behemoth-spitter', count = math.floor(amount / 40)}
        }
    end

    local health_factor = difficulties_votes[Diff.difficulty_vote_index].boss_modifier
    if this.wave_count == 100 then
        health_factor = health_factor * 2
    end

    local position = {x = 216, y = 0}
    local biter_group = surface.create_unit_group({position = position})
    for _, entry in pairs(boss_waves[this.wave_count]) do
        for x = 1, entry.count, 1 do
            local pos = surface.find_non_colliding_position(entry.name, position, 64, 3)
            if pos then
                local biter = surface.create_entity({name = entry.name, position = pos})
                biter.ai_settings.allow_destroy_when_commands_fail = false
                biter.ai_settings.allow_try_return_to_spawner = false
                this.boss_biters[biter.unit_number] = biter
                Unit_health_booster.add_boss_unit(biter, this.biter_health_boost * health_factor, 0.55)
                biter_group.add_member(biter)
            end
        end
    end

    send_unit_group(biter_group)
end

local function wake_up_the_biters(surface)
    local market = FDT.get('market')
    if not market then
        return
    end

    local units = surface.find_entities_filtered({type = 'unit'})
    units = shuffle(units)
    local unit_groups = {}
    local y_raffle = get_y_coord_raffle_table()
    for i = 1, 2, 1 do
        if not units[i] then
            break
        end
        if not units[i].valid then
            break
        end
        local x = units[i].position.x
        if x > 256 then
            x = 256
        end
        local y = units[i].position.y
        if y > 96 or y < -96 then
            y = y_raffle[i]
        end

        unit_groups[i] = surface.create_unit_group({position = {x = x, y = y}})
        local biters = surface.find_enemy_units(units[i].position, 24, 'player')
        for _, biter in pairs(biters) do
            unit_groups[i].add_member(biter)
        end
    end

    for i = 1, #unit_groups, 1 do
        if unit_groups[i].valid then
            if #unit_groups[i].members > 0 then
                send_unit_group(unit_groups[i])
            else
                unit_groups[i].destroy()
            end
        end
    end

    surface.set_multi_command(
        {
            command = {
                type = defines.command.attack,
                target = market,
                distraction = defines.distraction.none
            },
            unit_count = 16,
            force = 'enemy',
            unit_search_distance = 24
        }
    )
end

local function damage_entity_outside_of_fence(e)
    if not e.health then
        return
    end
    if e.force.name == 'neutral' then
        return
    end
    if e.type == 'unit' or e.type == 'unit-spawner' then
        return
    end

    e.surface.create_entity({name = 'water-splash', position = e.position})

    if e.type == 'entity-ghost' then
        e.destroy()
        return
    end

    e.health = e.health - math_random(math.floor(e.prototype.max_health * 0.05), math.floor(e.prototype.max_health * 0.1))
    if e.health <= 0 then
        e.die('enemy')
    end
end

local function biter_attack_wave()
    local Diff = Difficulty.get()
    local this = FDT.get()

    if not this.market then
        return
    end
    if this.wave_grace_period then
        return
    end
    local surface = game.surfaces[this.active_surface_index]

    clear_corpses(surface)
    wake_up_the_biters(surface)

    if surface.count_entities_filtered({type = 'unit'}) > biter_count_limit then
        --game.print("Biter limit reached, wave delayed.", {r = 0.7, g = 0.1, b = 0.1})
        return
    end

    if not this.wave_count then
        this.wave_count = 1
    else
        this.wave_count = this.wave_count + 1
    end

    local m = 0.0015
    if Diff.difficulty_vote_index then
        m = m * difficulties_votes[Diff.difficulty_vote_index].strength_modifier
    end
    game.forces.enemy.set_ammo_damage_modifier('melee', this.wave_count * m)
    game.forces.enemy.set_ammo_damage_modifier('biological', this.wave_count * m)
    this.biter_health_boost = 1 + (this.wave_count * (m * 2))

    local m = 4
    if Diff.difficulty_vote_index then
        m = m * difficulties_votes[Diff.difficulty_vote_index].amount_modifier
    end

    if this.wave_count % 50 == 0 then
        this.attack_wave_threat = math.floor(this.wave_count * (m * 1.5))
        spawn_boss_units(surface)
        if this.attack_wave_threat > 10000 then
            this.attack_wave_threat = 10000
        end
    else
        this.attack_wave_threat = math.floor(this.wave_count * m)
        if this.attack_wave_threat > 10000 then
            this.attack_wave_threat = 10000
        end
    end

    local evolution = this.wave_count * 0.00125
    if evolution > 1 then
        evolution = 1
    end
    game.forces.enemy.evolution_factor = evolution

    --if game.forces.enemy.evolution_factor == 1 then
    --	if not this.endgame_modifier then
    --		this.endgame_modifier = 1
    --		game.print("Endgame enemy evolution reached.", {r = 0.7, g = 0.1, b = 0.1})
    --	else
    --		this.endgame_modifier = this.endgame_modifier + 1
    --	end
    --end

    for _, e in pairs(surface.find_entities_filtered({area = {{160, -256}, {360, 256}}})) do
        damage_entity_outside_of_fence(e)
    end

    local y_raffle = get_y_coord_raffle_table()

    local unit_groups = {}
    if this.wave_count > 50 and math_random(1, 8) == 1 then
        for i = 1, 10, 1 do
            unit_groups[i] = surface.create_unit_group({position = {x = 256, y = y_raffle[i]}})
        end
    else
        for i = 1, get_number_of_attack_groups(), 1 do
            unit_groups[i] = surface.create_unit_group({position = {x = 256, y = y_raffle[i]}})
        end
    end

    local biter_pool = get_biter_pool()
    --local spawners = surface.find_entities_filtered({type = "unit-spawner", area = {{160, -196},{512, 196}}})
    --table.shuffle_table(spawners)

    while this.attack_wave_threat > 0 do
        for i = 1, #unit_groups, 1 do
            --local biter
            --if spawners[i] then
            --biter = spawn_biter(spawners[i].position, biter_pool)
            --else
            --biter = spawn_biter(unit_groups[i].position, biter_pool)
            --end

            local biter = spawn_biter(unit_groups[i].position, biter_pool)
            if biter then
                unit_groups[i].add_member(biter)
            else
                break
            end
        end
    end

    for i = 1, #unit_groups, 1 do
        send_unit_group(unit_groups[i])
    end
end

local function get_sorted_list(column_name, score_list)
    for x = 1, #score_list, 1 do
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

local function get_mvps()
    local get_score = Score.get_table().score_table
    if not get_score['player'] then
        return false
    end
    local score = get_score['player']
    local score_list = {}
    for _, p in pairs(game.players) do
        local killscore = 0
        if score.players[p.name].killscore then
            killscore = score.players[p.name].killscore
        end
        local deaths = 0
        if score.players[p.name].deaths then
            deaths = score.players[p.name].deaths
        end
        local built_entities = 0
        if score.players[p.name].built_entities then
            built_entities = score.players[p.name].built_entities
        end
        local mined_entities = 0
        if score.players[p.name].mined_entities then
            mined_entities = score.players[p.name].mined_entities
        end
        table.insert(
            score_list,
            {
                name = p.name,
                killscore = killscore,
                deaths = deaths,
                built_entities = built_entities,
                mined_entities = mined_entities
            }
        )
    end
    local mvp = {}
    score_list = get_sorted_list('killscore', score_list)
    mvp.killscore = {name = score_list[1].name, score = score_list[1].killscore}
    score_list = get_sorted_list('deaths', score_list)
    mvp.deaths = {name = score_list[1].name, score = score_list[1].deaths}
    score_list = get_sorted_list('built_entities', score_list)
    mvp.built_entities = {name = score_list[1].name, score = score_list[1].built_entities}
    return mvp
end

local function is_game_lost()
    local market = FDT.get('market')
    if market and market.valid then
        return
    end

    local this = FDT.get()

    for _, player in pairs(game.connected_players) do
        if player.gui.left['fish_defense_game_lost'] then
            return
        end
        local f =
            player.gui.left.add(
            {
                type = 'frame',
                name = 'fish_defense_game_lost',
                caption = 'The fish market was overrun! The biters are having a feast :3',
                direction = 'vertical'
            }
        )
        f.style.font_color = {r = 0.65, g = 0.1, b = 0.99}

        local t = f.add({type = 'table', column_count = 2})
        local l = t.add({type = 'label', caption = 'Survival Time >> '})
        l.style.font = 'default-listbox'
        l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}

        if this.market_age >= 216000 then
            local l =
                t.add(
                {
                    type = 'label',
                    caption = math.floor(((this.market_age / 60) / 60) / 60) .. ' hours ' .. math.ceil((this.market_age % 216000 / 60) / 60) .. ' minutes'
                }
            )
            l.style.font = 'default-bold'
            l.style.font_color = {r = 0.33, g = 0.66, b = 0.9}
        else
            local l = t.add({type = 'label', caption = math.ceil((this.market_age % 216000 / 60) / 60) .. ' minutes'})
            l.style.font = 'default-bold'
            l.style.font_color = {r = 0.33, g = 0.66, b = 0.9}
        end

        local mvp = get_mvps()
        if mvp then
            local l = t.add({type = 'label', caption = 'MVP Defender >> '})
            l.style.font = 'default-listbox'
            l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
            local l = t.add({type = 'label', caption = mvp.killscore.name .. ' with a score of ' .. mvp.killscore.score})
            l.style.font = 'default-bold'
            l.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

            local l = t.add({type = 'label', caption = 'MVP Builder >> '})
            l.style.font = 'default-listbox'
            l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
            local l =
                t.add(
                {
                    type = 'label',
                    caption = mvp.built_entities.name .. ' built ' .. mvp.built_entities.score .. ' things'
                }
            )
            l.style.font = 'default-bold'
            l.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

            local l = t.add({type = 'label', caption = 'MVP Deaths >> '})
            l.style.font = 'default-listbox'
            l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
            local l = t.add({type = 'label', caption = mvp.deaths.name .. ' died ' .. mvp.deaths.score .. ' times'})
            l.style.font = 'default-bold'
            l.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

            if not this.results_sent then
                local result = {}
                insert(result, 'MVP Defender: \\n')
                insert(result, mvp.killscore.name .. ' with a score of ' .. mvp.killscore.score .. '\\n')
                insert(result, '\\n')
                insert(result, 'MVP Builder: \\n')
                insert(result, mvp.built_entities.name .. ' built ' .. mvp.built_entities.score .. ' things\\n')
                insert(result, '\\n')
                insert(result, 'MVP Deaths: \\n')
                insert(result, mvp.deaths.name .. ' died ' .. mvp.deaths.score .. ' times')
                local message = table.concat(result)
                Server.to_discord_embed(message)
                this.results_sent = true
            end
        end

        for _, player in pairs(game.connected_players) do
            player.play_sound {path = 'utility/game_lost', volume_modifier = 0.75}
        end
    end

    game.map_settings.enemy_expansion.enabled = true
    game.map_settings.enemy_expansion.max_expansion_distance = 15
    game.map_settings.enemy_expansion.settler_group_min_size = 15
    game.map_settings.enemy_expansion.settler_group_max_size = 30
    game.map_settings.enemy_expansion.min_expansion_cooldown = 600
    game.map_settings.enemy_expansion.max_expansion_cooldown = 600
end

local function damage_entities_in_radius(surface, position, radius, damage)
    local entities_to_damage = surface.find_entities_filtered({area = {{position.x - radius, position.y - radius}, {position.x + radius, position.y + radius}}})
    for _, entity in pairs(entities_to_damage) do
        if entity.valid then
            if entity.health and entity.name ~= 'land-mine' then
                if entity.force.name ~= 'enemy' then
                    if entity.name == 'character' then
                        entity.damage(damage, 'enemy')
                    else
                        entity.health = entity.health - damage
                        if entity.health <= 0 then
                            entity.die('enemy')
                        end
                    end
                end
            end
        end
    end
end

local function market_kill_visuals()
    local market = FDT.get('market')
    local m = 32
    local m2 = m * 0.005
    for i = 1, 1024, 1 do
        market.surface.create_particle(
            {
                name = 'branch-particle',
                position = market.position,
                frame_speed = 0.1,
                vertical_speed = 0.1,
                height = 0.1,
                movement = {m2 - (math.random(0, m) * 0.01), m2 - (math.random(0, m) * 0.01)}
            }
        )
    end
    for x = -5, 5, 0.5 do
        for y = -5, 5, 0.5 do
            if math_random(1, 2) == 1 then
                market.surface.create_trivial_smoke(
                    {
                        name = 'smoke-fast',
                        position = {market.position.x + (x * 0.35), market.position.y + (y * 0.35)}
                    }
                )
            end
            if math_random(1, 3) == 1 then
                market.surface.create_trivial_smoke(
                    {
                        name = 'train-smoke',
                        position = {market.position.x + (x * 0.35), market.position.y + (y * 0.35)}
                    }
                )
            end
        end
    end
    market.surface.spill_item_stack(market.position, {name = 'raw-fish', count = 1024}, true)
end

local biter_splash_damage = {
    ['medium-biter'] = {
        visuals = {'blood-explosion-big', 'big-explosion'},
        radius = 1.5,
        damage_min = 50,
        damage_max = 100,
        chance = 32
    },
    ['big-biter'] = {
        visuals = {'blood-explosion-huge', 'ground-explosion'},
        radius = 2,
        damage_min = 75,
        damage_max = 150,
        chance = 48
    },
    ['behemoth-biter'] = {
        visuals = {'blood-explosion-huge', 'big-artillery-explosion'},
        radius = 2.5,
        damage_min = 100,
        damage_max = 200,
        chance = 64
    }
}

local function on_entity_died(event)
    if not event.entity.valid then
        return
    end

    local this = FDT.get()

    if event.entity.force.name == 'enemy' then
        local surface = event.entity.surface

        if this.boss_biters[event.entity.unit_number] then
            boss_biter.died(event)
        end

        local splash = biter_splash_damage[event.entity.name]
        if splash then
            if math_random(1, splash.chance) == 1 then
                for _, visual in pairs(splash.visuals) do
                    surface.create_entity({name = visual, position = event.entity.position})
                end
                damage_entities_in_radius(surface, event.entity.position, splash.radius, math_random(splash.damage_min, splash.damage_max))
                return
            end
        end

        if event.entity.name == 'behemoth-biter' then
            if math_random(1, 16) == 1 then
                local p = surface.find_non_colliding_position('big-biter', event.entity.position, 3, 0.5)
                if p then
                    surface.create_entity {name = 'big-biter', position = p}
                end
            end
            for i = 1, math_random(1, 2), 1 do
                local p = surface.find_non_colliding_position('medium-biter', event.entity.position, 3, 0.5)
                if p then
                    surface.create_entity {name = 'medium-biter', position = p}
                end
            end
        end
        return
    end

    if event.entity == this.market then
        market_kill_visuals()
        this.market = nil
        this.market_age = game.tick - this.last_reset
        is_game_lost()
    end

    if this.entity_limits[event.entity.name] then
        this.entity_limits[event.entity.name].placed = this.entity_limits[event.entity.name].placed - 1
        update_fd_stats()
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    local active_surface_index = FDT.get('active_surface_index')

    if player.online_time == 0 then
        player.insert({name = 'pistol', count = 1})
        --player.insert({name = "iron-axe", count = 1})
        player.insert({name = 'raw-fish', count = 3})
        player.insert({name = 'firearm-magazine', count = 16})
        player.insert({name = 'iron-plate', count = 32})
    end

    local surface = game.surfaces[active_surface_index]
    if not surface or not surface.valid then
        return
    end

    if player.surface.index ~= active_surface_index and surface.is_chunk_generated({0, 0}) then
        player.teleport(surface.find_non_colliding_position('character', game.forces['player'].get_spawn_position(surface), 50, 1), active_surface_index)
    else
        if player.surface.index ~= active_surface_index then
            player.teleport(game.forces['player'].get_spawn_position(surface), active_surface_index)
        end
    end

    create_wave_gui(player)
    add_fd_stats_button(player)

    if game.tick > 900 then
        is_game_lost()
    end

    --if this.charting_done then return end
    --game.forces.player.chart(game.surfaces["fish_defender"], {{-256, -512},{768, 512}})
    --this.charting_done = true
end

local function on_built_entity(event)
    local get_score = Score.get_table().score_table
    local this = FDT.get()
    local entity = event.created_entity
    if not entity.valid then
        return
    end
    if this.entity_limits[entity.name] then
        local surface = entity.surface

        if this.entity_limits[entity.name].placed < this.entity_limits[entity.name].limit then
            this.entity_limits[entity.name].placed = this.entity_limits[entity.name].placed + 1
            surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = this.entity_limits[entity.name].placed .. ' / ' .. this.entity_limits[entity.name].limit .. ' ' .. this.entity_limits[entity.name].str .. 's',
                    color = {r = 0.98, g = 0.66, b = 0.22}
                }
            )
            update_fd_stats()
        else
            surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = this.entity_limits[entity.name].str .. ' limit reached.',
                    color = {r = 0.82, g = 0.11, b = 0.11}
                }
            )
            local player = game.players[event.player_index]
            player.insert({name = entity.name, count = 1})
            if get_score then
                if get_score[player.force.name] then
                    if get_score[player.force.name].players[player.name] then
                        get_score[player.force.name].players[player.name].built_entities = get_score[player.force.name].players[player.name].built_entities - 1
                    end
                end
            end
            entity.destroy()
        end
    end
end

local function on_robot_built_entity(event)
    local entity = event.created_entity
    local entity_limits = FDT.get('entity_limits')
    if entity_limits[entity.name] then
        local surface = entity.surface
        if entity_limits[entity.name].placed < entity_limits[entity.name].limit then
            entity_limits[entity.name].placed = entity_limits[entity.name].placed + 1
            surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = entity_limits[entity.name].placed .. ' / ' .. entity_limits[entity.name].limit .. ' ' .. entity_limits[entity.name].str .. 's',
                    color = {r = 0.98, g = 0.66, b = 0.22}
                }
            )
            update_fd_stats()
        else
            surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = entity_limits[entity.name].str .. ' limit reached.',
                    color = {r = 0.82, g = 0.11, b = 0.11}
                }
            )
            local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
            inventory.insert({name = entity.name, count = 1})
            entity.destroy()
        end
    end
end

local function on_init(reset)
    local Diff = Difficulty.get()
    local get_score = Score.get_table()

    local this = FDT.get()

    AntiGrief.reset_tables()
    FDT.reset_table()
    Poll.reset()
    global.fish_in_space = 0

    local difficulties = {
        [1] = {
            name = 'Normal',
            value = 1,
            color = {r = 0.00, g = 0.00, b = 0.25},
            print_color = {r = 0.0, g = 0.0, b = 0.5}
        },
        [2] = {
            name = 'Hard',
            value = 1.5,
            color = {r = 0.25, g = 0.00, b = 0.00},
            print_color = {r = 0.4, g = 0.0, b = 0.00}
        },
        [3] = {
            name = 'Nightmare',
            value = 3,
            color = {r = 0.35, g = 0.00, b = 0.00},
            print_color = {r = 0.6, g = 0.0, b = 0.00}
        },
        [4] = {
            name = 'Impossible',
            value = 5,
            color = {r = 0.45, g = 0.00, b = 0.00},
            print_color = {r = 0.8, g = 0.0, b = 0.00}
        }
    }
    Difficulty.set_difficulties(difficulties)

    Diff.difficulty_poll_closing_timeout = this.wave_grace_period
    get_score.score_table = {}

    local players = game.players
    for i = 1, #players do
        local player = players[i]
        Session.clear_player(player)
    end

    game.remove_offline_players()

    local map_gen_settings = {}
    map_gen_settings.height = 2048
    map_gen_settings.water = 0.10
    map_gen_settings.seed = math_random(10000, 99999)
    map_gen_settings.terrain_segmentation = 3
    map_gen_settings.cliff_settings = {cliff_elevation_interval = 32, cliff_elevation_0 = 32}
    map_gen_settings.autoplace_controls = {
        ['coal'] = {frequency = 3, size = 1.5, richness = 1},
        ['stone'] = {frequency = 3, size = 1.5, richness = 1},
        ['copper-ore'] = {frequency = 3, size = 1.5, richness = 1},
        ['iron-ore'] = {frequency = 3, size = 1.5, richness = 1},
        ['uranium-ore'] = {frequency = 0, size = 0, richness = 0},
        ['crude-oil'] = {frequency = 5, size = 1.25, richness = 2},
        ['trees'] = {frequency = 2, size = 1, richness = 1},
        ['enemy-base'] = {frequency = 'none', size = 'none', richness = 'none'}
    }

    if not this.active_surface_index then
        this.active_surface_index = game.create_surface('fish_defender', map_gen_settings).index
    elseif reset then
        this.active_surface_index = Reset.soft_reset_map(game.surfaces[this.active_surface_index], map_gen_settings, starting_items).index
    end

    local surface = game.surfaces[this.active_surface_index]

    surface.peaceful_mode = false

    game.map_settings.enemy_expansion.enabled = false
    game.map_settings.enemy_evolution.destroy_factor = 0
    game.map_settings.enemy_evolution.time_factor = 0
    game.map_settings.enemy_evolution.pollution_factor = 0
    game.map_settings.pollution.enabled = false

    Difficulty.reset_difficulty_poll()
    Difficulty.set_poll_closing_timeout(game.tick + 35 * 60 * 60)

    game.forces.player.technologies['atomic-bomb'].enabled = false
    --game.forces["player"].technologies["landfill"].enabled = false

    if not game.forces.decoratives then
        game.create_force('decoratives')
    end
    game.forces['decoratives'].set_cease_fire('enemy', true)
    game.forces['enemy'].set_cease_fire('decoratives', true)
    game.forces.player.set_cease_fire('decoratives', true)

    Terrain.fish_eye(surface, {x = -2150, y = -300})

    game.map_settings.enemy_expansion.enabled = false
    game.forces.player.technologies['artillery'].researched = false
    game.forces.player.technologies['spidertron'].enabled = false
    game.forces.player.technologies['spidertron'].researched = false
    game.reset_time_played()

    local T = Map.Pop_info()
    T.localised_category = 'fish_defender'
    T.main_caption_color = {r = 0.11, g = 0.8, b = 0.44}
    T.sub_caption_color = {r = 0.33, g = 0.66, b = 0.9}

    for _, player in pairs(game.connected_players) do
        if player.gui.left['fish_defense_game_lost'] then
            player.gui.left['fish_defense_game_lost'].destroy()
        end
    end

    local mgs = game.surfaces['nauvis'].map_gen_settings
    mgs.width = 16
    mgs.height = 16
    game.surfaces['nauvis'].map_gen_settings = mgs
    game.surfaces['nauvis'].clear()
end

local function on_tick()
    local Diff = Difficulty.get()
    local this = FDT.get()
    local surface = game.surfaces[this.active_surface_index]
    if not surface or not surface.valid then
        return
    end
    if game.tick % 30 == 0 then
        if this.market and this.market.valid then
            for _, player in pairs(game.connected_players) do
                if surface.peaceful_mode == false then
                    create_wave_gui(player)
                end
            end
        end
        if game.tick % 180 == 0 then
            if surface then
                game.forces.player.chart(surface, {{-160, -128}, {192, 128}})
                if Diff.difficulty_vote_index then
                    this.wave_interval = difficulties_votes[Diff.difficulty_vote_index].wave_interval
                end
            end
        end

        if this.market_age then
            if not this.game_restart_timer then
                this.game_restart_timer = 10800
            else
                if this.game_restart_timer < 0 then
                    return
                end
                this.game_restart_timer = this.game_restart_timer - 30
            end
            if this.game_restart_timer % 1800 == 0 then
                if this.game_restart_timer > 0 then
                    this.game_reset = true
                    this.game_has_ended = true
                    game.print('Map will restart in ' .. this.game_restart_timer / 60 .. ' seconds!', {r = 0.22, g = 0.88, b = 0.22})
                end
                if this.game_restart_timer == 0 then
                    on_init(true)
                end
            end
        end
    end

    if this.wave_count >= this.wave_limit then
        if this.market and this.market.valid then
            this.market.die()
            game.print('Game wave limit reached! Game will soft-reset shortly.', {r = 0.22, g = 0.88, b = 0.22})
        end
    end

    if game.tick % this.wave_interval == this.wave_interval - 1 then
        if surface.peaceful_mode == true then
            return
        end
        biter_attack_wave()
    end
end

local function on_player_changed_position(event)
    local player = game.players[event.player_index]
    local active_surface_index = FDT.get('active_surface_index')
    local map_height = FDT.get('map_height')
    local surface = game.surfaces[active_surface_index]
    if not surface or not surface.valid then
        return
    end

    if player.position.x + player.position.y < 0 then
        return
    end
    if player.position.x < player.position.y then
        return
    end
    if player.position.x >= 160 then
        player.teleport({player.position.x - 1, player.position.y}, surface)
        if player.position.y > map_height or player.position.y < map_height * -1 then
            player.teleport({player.position.x, 0}, surface)
        end
        if player.character then
            player.character.health = player.character.health - 25
            player.character.surface.create_entity({name = 'water-splash', position = player.position})
            if player.character.health <= 0 then
                player.character.die('enemy')
            end
        end
    end
end

local function on_player_mined_entity(event)
    local this = FDT.get()
    if this.entity_limits[event.entity.name] then
        this.entity_limits[event.entity.name].placed = this.entity_limits[event.entity.name].placed - 1
        update_fd_stats()
    end
end

local function on_robot_mined_entity(event)
    local this = FDT.get()
    if this.entity_limits[event.entity.name] then
        this.entity_limits[event.entity.name].placed = this.entity_limits[event.entity.name].placed - 1
        update_fd_stats()
    end
end

local function on_research_finished(event)
    local research = event.research.name
    if research ~= 'tank' then
        return
    end
    game.forces['player'].technologies['artillery'].researched = true
    game.forces.player.recipes['artillery-wagon'].enabled = false
end

local function on_player_respawned(event)
    local market_age = FDT.get('market_age')
    if not market_age then
        return
    end
    local player = game.players[event.player_index]
    player.character.destructible = false
end

Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_robot_mined_entity, on_robot_mined_entity)
Event.add(defines.events.on_tick, on_tick)
Event.on_init(on_init)

return on_init
