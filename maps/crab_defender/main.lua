require 'maps.crab_defender.terrain'
require 'maps.crab_defender.market'
require 'maps.crab_defender.commands'
require 'maps.crab_defender.shotgun_buff'
require 'maps.crab_defender.on_entity_damaged'
require 'modules.rocket_launch_always_yields_science'
require 'modules.biters_yield_coins'
require 'modules.dangerous_goods'
require 'modules.custom_death_messages'

local FishToWin = require 'maps.crab_defender.launch_fish_to_win'
local Unit_health_booster = require 'modules.biter_health_booster'
local Session = require 'utils.datastore.session_data'
local Difficulty = require 'modules.difficulty_vote'
local Map = require 'modules.map_info'
local Event = require 'utils.event'
local Reset = require 'utils.functions.soft_reset'
local Server = require 'utils.server'
local Poll = require 'utils.gui.poll'
local boss_biter = require 'maps.crab_defender.boss_biters'
local FDT = require 'maps.crab_defender.table'
local Score = require 'utils.gui.score'
local Task = require 'utils.task_token'
local Color = require 'utils.color_presets'
local insert = table.insert
local enable_start_grace_period = true

local random = math.random
local floor = math.floor
local spawn_biters_token

local Public = {}

local starting_items = {
    ['pistol'] = 1,
    ['firearm-magazine'] = 16,
    ['raw-fish'] = 3,
    ['iron-plate'] = 32,
    ['stone'] = 12
}

local disable_tech = function()
    game.forces.player.technologies['spidertron'].enabled = false
    game.forces.player.technologies['spidertron'].researched = false
    game.forces.player.technologies['optics'].researched = true
    game.forces.player.technologies['artillery'].researched = false
    game.forces.player.technologies['atomic-bomb'].enabled = false
end

function Public.reset_game()
    FishToWin.reset()
    FDT.reset_table()
    Poll.reset()
    local this = FDT.get()

    Difficulty.reset_difficulty_poll()
    Difficulty.set_poll_closing_timeout = game.tick + 36000

    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        Score.init_player_table(player)
        if player.gui.left['crab_defender_game_lost'] then
            player.gui.left['crab_defender_game_lost'].destroy()
        end
    end

    local offline_players = game.players
    for i = 1, #offline_players do
        local player = offline_players[i]
        Session.clear_player(player)
    end

    disable_tech()

    local map_gen_settings = {}
    map_gen_settings.seed = random(10000, 99999)
    map_gen_settings.height = 2048
    map_gen_settings.water = 0.10
    map_gen_settings.terrain_segmentation = 3
    map_gen_settings.cliff_settings = {cliff_elevation_interval = 32, cliff_elevation_0 = 32}
    map_gen_settings.autoplace_controls = {
        ['coal'] = {frequency = 4, size = 1.5, richness = 2},
        ['stone'] = {frequency = 4, size = 1.5, richness = 2},
        ['copper-ore'] = {frequency = 4, size = 1.5, richness = 2},
        ['iron-ore'] = {frequency = 4, size = 1.5, richness = 2},
        ['uranium-ore'] = {frequency = 0, size = 0, richness = 0},
        ['crude-oil'] = {frequency = 5, size = 1.25, richness = 2},
        ['trees'] = {frequency = 2, size = 1, richness = 1},
        ['enemy-base'] = {frequency = 'none', size = 'none', richness = 'none'}
    }
    map_gen_settings.autoplace_settings = {
        ['tile'] = {
            settings = {
                ['deepwater'] = {frequency = 1, size = 0, richness = 1},
                ['deepwater-green'] = {frequency = 1, size = 0, richness = 1},
                ['water'] = {frequency = 1, size = 0, richness = 1},
                ['water-green'] = {frequency = 1, size = 0, richness = 1},
                ['water-mud'] = {frequency = 1, size = 0, richness = 1},
                ['water-shallow'] = {frequency = 1, size = 0, richness = 1}
            },
            treat_missing_as_default = true
        }
    }

    if not this.active_surface_index then
        this.active_surface_index = game.create_surface('crab_defender', map_gen_settings).index
    else
        this.active_surface_index = Reset.soft_reset_map(game.surfaces[this.active_surface_index], map_gen_settings, starting_items).index
    end

    local surface = game.surfaces[this.active_surface_index]
    if not surface or not surface.valid then
        return
    end

    surface.peaceful_mode = false

    local r = 320
    local p = {x = -131, y = 5}
    game.forces.player.chart(
        surface,
        {
            {p.x - r - 200, p.y - r - 200},
            {p.x + r + 600, p.y + r}
        }
    )

    game.map_settings.enemy_expansion.enabled = false
    game.map_settings.enemy_evolution.destroy_factor = 0
    game.map_settings.enemy_evolution.time_factor = 0
    game.map_settings.enemy_evolution.pollution_factor = 0
    game.map_settings.pollution.enabled = false

    if not game.forces.decoratives then
        game.create_force('decoratives')
    end

    game.forces['decoratives'].set_cease_fire('enemy', true)
    game.forces['enemy'].set_cease_fire('decoratives', true)
    game.forces['player'].set_cease_fire('decoratives', true)
    game.remove_offline_players()

    game.map_settings.enemy_expansion.enabled = false

    game.reset_time_played()

    this.market_health = 1000
    this.market_max_health = 1000
    this.spawn_area_generated = false
end

local biter_count_limit = 1024

local create_wave_gui = function(player)
    if player.gui.top['crab_defender_waves'] then
        player.gui.top['crab_defender_waves'].destroy()
    end
    local this = FDT.get()
    local frame = player.gui.top.add({type = 'frame', name = 'crab_defender_waves'})
    frame.style.maximal_height = 38

    if not this.wave_grace_period then
        local label = frame.add({type = 'label', caption = 'Wave: ' .. (this.wave_count or 0)})
        label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
        label.style.font = 'default-listbox'
        label.style.left_padding = 4
        label.style.right_padding = 4
        label.style.minimal_width = 68
        label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

        local next_level_progress = game.tick % this.wave_interval / this.wave_interval

        local progressbar = frame.add({type = 'progressbar', name = 'progressbar', value = next_level_progress})
        progressbar.style = 'achievement_progressbar'
        progressbar.style.minimal_width = 96
        progressbar.style.maximal_width = 96
        progressbar.style.padding = -1
        progressbar.style.top_padding = 1
    else
        local time_remaining = floor(((this.wave_grace_period - (game.tick % this.wave_grace_period)) / 60) / 60)
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

local show_fd_stats = function(player)
    local gui_id = 'fd-stats'
    local table_id = gui_id .. 'table'
    local this = FDT.get()

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
    for _, v in pairs(table_header) do
        local h = table.add {type = 'label', caption = v}
        h.style.font = 'heading-2'
    end

    for _, v in pairs(this.entity_limits) do
        local name = v.str
        local placed = v.placed
        local limit = v.limit
        local entry = {name, placed .. '/' .. limit}
        for _, value_entry in pairs(entry) do
            table.add {
                type = 'label',
                caption = value_entry
            }
        end
    end
end

local update_fd_stats = function()
    for _, player in pairs(game.connected_players) do
        if player.gui.left['fd-stats'] then
            show_fd_stats(player)
        end
    end
end

local add_fd_stats_button = function(player)
    local button_id = 'fd-stats-button'
    if player.gui.top[button_id] then
        player.gui.top[button_id].destroy()
    end

    player.gui.top.add {
        type = 'sprite-button',
        name = button_id,
        sprite = 'item/submachine-gun'
    }
end

local on_gui_click = function(event)
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

local on_market_item_purchased = function()
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

local get_biter_initial_pool = function()
    local this = FDT.get()
    local biter_pool
    if this.wave_count > 1750 then
        biter_pool = {
            {name = 'behemoth-biter', threat = threat_values.behemoth_biter, weight = 2},
            {name = 'behemoth-spitter', threat = threat_values.behemoth_spitter, weight = 1}
        }
        return biter_pool
    end
    if this.wave_count > 1500 then
        biter_pool = {
            {name = 'big-biter', threat = threat_values.big_biter, weight = 1},
            {name = 'behemoth-biter', threat = threat_values.behemoth_biter, weight = 2},
            {name = 'behemoth-spitter', threat = threat_values.behemoth_spitter, weight = 1}
        }
        return biter_pool
    end
    if this.wave_count > 1250 then
        biter_pool = {
            {name = 'big-biter', threat = threat_values.big_biter, weight = 2},
            {name = 'behemoth-biter', threat = threat_values.behemoth_biter, weight = 2},
            {name = 'behemoth-spitter', threat = threat_values.behemoth_spitter, weight = 1}
        }
        return biter_pool
    end
    if this.wave_count > 1000 then
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

local get_biter_pool = function()
    local biter_pool = get_biter_initial_pool()
    local biter_raffle = {}
    for _, biter_type in pairs(biter_pool) do
        for _ = 1, biter_type.weight, 1 do
            insert(biter_raffle, {name = biter_type.name, threat = biter_type.threat})
        end
    end
    return biter_raffle
end

local spawn_biter = function(surface, pos, biter_pool)
    local attack_wave_threat = FDT.get('attack_wave_threat')
    if attack_wave_threat < 1 then
        return false
    end

    local spawned_biters = FDT.get('spawned_biters')
    spawned_biters = spawned_biters or 9999
    if spawned_biters > biter_count_limit then
        return false
    end

    biter_pool = biter_pool[random(1, #biter_pool)]
    FDT.set('attack_wave_threat', attack_wave_threat - biter_pool.threat)
    attack_wave_threat = FDT.get('attack_wave_threat')
    local valid_pos = surface.find_non_colliding_position(biter_pool.name, pos, 8, 2)
    local biter = surface.create_entity({name = biter_pool.name, position = valid_pos})
    if biter and biter.valid then
        spawned_biters = FDT.get('spawned_biters')
        FDT.set('spawned_biters', spawned_biters + 1)
        return biter, attack_wave_threat
    end
end

local get_y_coord_raffle_table = function()
    local t = {}

    t[#t + 1] = -65
    t[#t + 1] = -282
    t[#t + 1] = -65
    t[#t + 1] = -282
    t[#t + 1] = -65
    t[#t + 1] = -282
    t[#t + 1] = -65
    t[#t + 1] = -282
    t[#t + 1] = -65
    t[#t + 1] = -282
    table.shuffle_table(t)
    return t
end

local get_x_coord_raffle_table = function()
    local t = {}

    t[#t + 1] = 671
    t[#t + 1] = -535
    t[#t + 1] = 671
    t[#t + 1] = -535
    t[#t + 1] = 671
    t[#t + 1] = -535
    t[#t + 1] = 671
    t[#t + 1] = -535
    t[#t + 1] = 671
    t[#t + 1] = -535
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

local get_number_of_attack_groups = function()
    local n = 1
    local wave_count = FDT.get('wave_count')
    for _, entry in pairs(attack_group_count_thresholds) do
        if wave_count >= entry[1] then
            n = entry[2]
        end
    end
    return n
end

local send_unit_group = function(unit_group)
    local commands = {}
    local market = FDT.get('market')
    if not market or not market.valid then
        return
    end

    commands[#commands + 1] = {
        type = defines.command.attack_area,
        destination = {x = market.position.x, y = market.position.y},
        radius = 256,
        distraction = defines.distraction.by_anything
    }
    commands[#commands + 1] = {
        type = defines.command.attack,
        target = market,
        distraction = defines.distraction.by_anything
    }

    unit_group.set_command(
        {
            type = defines.command.compound,
            structure_type = defines.compound_command.return_last,
            commands = commands
        }
    )
end

local spawn_boss_units = function(surface)
    local Diff = Difficulty.get()
    local this = FDT.get()
    if this.wave_count <= 2000 then
        game.print({'crab_defender.boss_message', this.wave_count, {'crab_defender.' .. this.wave_count}}, {r = 0.8, g = 0.1, b = 0.1})
    else
        game.print({'crab_defender.boss_message', this.wave_count}, {r = 0.8, g = 0.1, b = 0.1})
    end

    if not this.boss_waves[this.wave_count] then
        local amount = this.wave_count
        if amount > 1000 then
            amount = 1000
        end
        this.boss_waves[this.wave_count] = {
            {name = 'behemoth-biter', count = floor(amount / 20)},
            {name = 'behemoth-spitter', count = floor(amount / 40)}
        }
    end

    local health_factor = this.difficulties_votes[Diff.difficulty_vote_index].boss_modifier
    if this.wave_count == 100 then
        health_factor = health_factor * 2
    end

    local position = {x = 216, y = 0}
    local biter_group = surface.create_unit_group({position = position})
    for _, entry in pairs(this.boss_waves[this.wave_count]) do
        for _ = 1, entry.count, 1 do
            local pos = surface.find_non_colliding_position(entry.name, position, 64, 3)
            if pos then
                local biter = surface.create_entity({name = entry.name, position = pos})
                this.boss_biters[biter.unit_number] = biter
                Unit_health_booster.add_boss_unit(biter, this.biter_health_boost * health_factor, 0.55)
                biter_group.add_member(biter)
            end
        end
    end

    send_unit_group(biter_group)
end

local wake_up_the_biters = function(surface)
    local market = FDT.get('market')
    if not market or not market.valid then
        return
    end

    local actual_biters = surface.count_entities_filtered({type = 'unit'})
    if actual_biters < biter_count_limit then
        FDT.set('spawned_biters', actual_biters)
    end

    surface.set_multi_command(
        {
            command = {
                type = defines.command.attack,
                target = market,
                distraction = defines.distraction.none
            },
            unit_count = 1024,
            force = 'enemy',
            unit_search_distance = 1024
        }
    )
end

spawn_biters_token =
    Task.register(
    function(event)
        local attack_wave_threat = event.attack_wave_threat
        if not attack_wave_threat then
            return
        end
        if attack_wave_threat < 1 then
            return
        end

        local unit_group = event.unit_group
        if not unit_group or not unit_group.valid then
            return
        end

        local surface = event.surface
        local biter_pool = event.biter_pool
        if not biter_pool then
            return
        end

        local biter
        biter, attack_wave_threat = spawn_biter(surface, unit_group.position, biter_pool)
        if biter then
            unit_group.add_member(biter)
        end

        Task.set_timeout_in_ticks(3, spawn_biters_token, {attack_wave_threat = attack_wave_threat, unit_group = unit_group, surface = surface, biter_pool = biter_pool})
    end,
    9999
)

local biter_attack_wave = function()
    local Diff = Difficulty.get()
    local this = FDT.get()

    if not this.market or not this.market.valid then
        return
    end
    if this.wave_grace_period then
        return
    end
    local surface = game.surfaces[this.active_surface_index]
    if not surface or not surface.valid then
        return
    end

    this.spawned_biters = this.spawned_biters or 9999

    if this.spawned_biters > biter_count_limit then
        wake_up_the_biters(surface)
        game.print('Max biter count reached, waking up idle biters!', Color.warning)
        game.print('Wave number will not increase.', Color.warning)
        return
    end

    if not this.wave_count then
        this.wave_count = 1
    else
        this.wave_count = this.wave_count + 1
    end

    local m = 0.0015
    if Diff.difficulty_vote_index then
        m = m * this.difficulties_votes[Diff.difficulty_vote_index].strength_modifier
    end
    game.forces.enemy.set_ammo_damage_modifier('melee', this.wave_count * m)
    game.forces.enemy.set_ammo_damage_modifier('biological', this.wave_count * m)
    this.biter_health_boost = 1 + (this.wave_count * (m * 2))

    m = 4
    if Diff.difficulty_vote_index then
        m = m * this.difficulties_votes[Diff.difficulty_vote_index].amount_modifier
    end

    if this.wave_count % 50 == 0 then
        this.attack_wave_threat = floor(this.wave_count * (m * 1.5))
        spawn_boss_units(surface)
        if this.attack_wave_threat > 10000 then
            this.attack_wave_threat = 10000
        end
    else
        this.attack_wave_threat = floor(this.wave_count * m)
        if this.attack_wave_threat > 10000 then
            this.attack_wave_threat = 10000
        end
    end

    local evolution = this.wave_count * 0.00125
    if evolution > 1 then
        evolution = 1
    end
    game.forces.enemy.evolution_factor = evolution

    local y_raffle = get_y_coord_raffle_table()
    local x_raffle = get_x_coord_raffle_table()

    local unit_groups = {}
    this.unit_groups = this.unit_groups or {}
    local biter_pool = get_biter_pool()

    if this.wave_count > 50 and random(1, 8) == 1 then
        for i = 1, 10, 1 do
            unit_groups[i] = surface.create_unit_group({position = {x = x_raffle[i], y = y_raffle[i]}})
            local unit_group = unit_groups[i]
            if unit_group and unit_group.valid then
                if not this.unit_groups[unit_group.group_number] then
                    this.unit_groups[unit_group.group_number] = unit_group
                end
                Task.set_timeout_in_ticks(i, spawn_biters_token, {attack_wave_threat = this.attack_wave_threat, unit_group = unit_group, surface = surface, biter_pool = biter_pool})
            end
        end
    else
        for i = 1, get_number_of_attack_groups(), 1 do
            unit_groups[i] = surface.create_unit_group({position = {x = x_raffle[i], y = y_raffle[i]}})
            local unit_group = unit_groups[i]
            if unit_group and unit_group.valid then
                if not this.unit_groups[unit_group.group_number] then
                    this.unit_groups[unit_group.group_number] = unit_group
                end
                Task.set_timeout_in_ticks(i, spawn_biters_token, {attack_wave_threat = this.attack_wave_threat, unit_group = unit_group, surface = surface, biter_pool = biter_pool})
            end
        end
    end
end

local get_sorted_list = function(column_name, score_list)
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

local get_mvps = function()
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

local is_game_lost = function()
    local this = FDT.get()

    if not this.game_has_ended then
        return
    end

    for _, player in pairs(game.connected_players) do
        if player.gui.left['crab_defender_game_lost'] then
            return
        end
        local f =
            player.gui.left.add(
            {
                type = 'frame',
                name = 'crab_defender_game_lost',
                caption = 'The crab market was overrun! The biters are having a feast :3',
                direction = 'vertical'
            }
        )
        f.style.font_color = {r = 0.65, g = 0.1, b = 0.99}

        local t = f.add({type = 'table', column_count = 2})

        local survival_time_label = t.add({type = 'label', caption = 'Survival Time >> '})
        survival_time_label.style.font = 'default-listbox'
        survival_time_label.style.font_color = {r = 0.22, g = 0.77, b = 0.44}

        local market_age_label

        if this.market_age then
            if this.market_age >= 216000 then
                market_age_label =
                    t.add(
                    {
                        type = 'label',
                        caption = floor(((this.market_age / 60) / 60) / 60) .. ' hours ' .. math.ceil((this.market_age % 216000 / 60) / 60) .. ' minutes'
                    }
                )
                market_age_label.style.font = 'default-bold'
                market_age_label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}
            else
                market_age_label = t.add({type = 'label', caption = math.ceil((this.market_age % 216000 / 60) / 60) .. ' minutes'})
                market_age_label.style.font = 'default-bold'
                market_age_label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}
            end
        end

        local mvp = get_mvps()
        if mvp then
            local mvp_defender_label = t.add({type = 'label', caption = 'MVP Defender >> '})
            mvp_defender_label.style.font = 'default-listbox'
            mvp_defender_label.style.font_color = {r = 0.22, g = 0.77, b = 0.44}

            local mvp_killscore_label = t.add({type = 'label', caption = mvp.killscore.name .. ' with a score of ' .. mvp.killscore.score})
            mvp_killscore_label.style.font = 'default-bold'
            mvp_killscore_label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

            local mvp_builder_label = t.add({type = 'label', caption = 'MVP Builder >> '})
            mvp_builder_label.style.font = 'default-listbox'
            mvp_builder_label.style.font_color = {r = 0.22, g = 0.77, b = 0.44}

            local mvp_built_ent_label =
                t.add(
                {
                    type = 'label',
                    caption = mvp.built_entities.name .. ' built ' .. mvp.built_entities.score .. ' things'
                }
            )
            mvp_built_ent_label.style.font = 'default-bold'
            mvp_built_ent_label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

            local mvp_deaths_label = t.add({type = 'label', caption = 'MVP Deaths >> '})
            mvp_deaths_label.style.font = 'default-listbox'
            mvp_deaths_label.style.font_color = {r = 0.22, g = 0.77, b = 0.44}

            local mvp_deaths_name_label = t.add({type = 'label', caption = mvp.deaths.name .. ' died ' .. mvp.deaths.score .. ' times'})
            mvp_deaths_name_label.style.font = 'default-bold'
            mvp_deaths_name_label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

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

        player.play_sound {path = 'utility/game_lost', volume_modifier = 0.75}
    end

    game.map_settings.enemy_expansion.enabled = true
    game.map_settings.enemy_expansion.max_expansion_distance = 15
    game.map_settings.enemy_expansion.settler_group_min_size = 15
    game.map_settings.enemy_expansion.settler_group_max_size = 30
    game.map_settings.enemy_expansion.min_expansion_cooldown = 600
    game.map_settings.enemy_expansion.max_expansion_cooldown = 600
end

local damage_entities_in_radius = function(surface, position, radius, damage)
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

local market_kill_visuals = function()
    local this = FDT.get()
    local surface = game.surfaces[this.active_surface_index]
    if not surface or not surface.valid then
        return
    end

    if not surface or not surface.valid then
        return
    end

    if not this.market or not this.market.valid then
        return
    end

    for x = -5, 5, 0.5 do
        for y = -5, 5, 0.5 do
            if random(1, 2) == 1 then
                surface.create_trivial_smoke(
                    {
                        name = 'smoke-fast',
                        position = {this.market.position.x + (x * 0.35), this.market.position.y + (y * 0.35)}
                    }
                )
            end
            if random(1, 3) == 1 then
                surface.create_trivial_smoke(
                    {
                        name = 'train-smoke',
                        position = {this.market.position.x + (x * 0.35), this.market.position.y + (y * 0.35)}
                    }
                )
            end
        end
    end
    surface.spill_item_stack(this.market.position, {name = 'raw-fish', count = 1024}, true)
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

local on_entity_died = function(event)
    if not event.entity.valid then
        return
    end

    local this = FDT.get()

    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    if entity.type == 'unit' and entity.force.name == 'enemy' then
        this.spawned_biters = this.spawned_biters - 1
        if this.spawned_biters < 0 then
            this.spawned_biters = 0
        end
    end

    if entity.force.name == 'enemy' then
        local surface = entity.surface

        if this.boss_biters[entity.unit_number] then
            boss_biter.died(event)
        end

        local splash = biter_splash_damage[entity.name]
        if splash then
            if random(1, splash.chance) == 1 then
                for _, visual in pairs(splash.visuals) do
                    surface.create_entity({name = visual, position = entity.position})
                end
                damage_entities_in_radius(surface, entity.position, splash.radius, random(splash.damage_min, splash.damage_max))
                return
            end
        end

        if entity.name == 'behemoth-biter' then
            if random(1, 16) == 1 then
                local p = surface.find_non_colliding_position('big-biter', entity.position, 3, 0.5)
                if p then
                    surface.create_entity {name = 'big-biter', position = p}
                end
            end
            for _ = 1, random(1, 2), 1 do
                local p = surface.find_non_colliding_position('medium-biter', entity.position, 3, 0.5)
                if p then
                    surface.create_entity {name = 'medium-biter', position = p}
                end
            end
        end
        return
    end

    if entity == this.market then
        market_kill_visuals()
        this.market.die()
        this.market = nil
        this.market_age = game.tick - this.last_reset
        this.game_has_ended = true
        is_game_lost()
        return
    end

    if this.entity_limits[entity.name] then
        this.entity_limits[entity.name].placed = this.entity_limits[entity.name].placed - 1
        update_fd_stats()
    end
end

local on_player_joined_game = function(event)
    local player = game.players[event.player_index]
    local this = FDT.get()
    local surface = game.surfaces[this.active_surface_index]
    if not surface or not surface.valid then
        return
    end

    if player.online_time == 0 then
        for item, amount in pairs(starting_items) do
            player.insert({name = item, count = amount})
        end
    end

    local spawn = player.force.get_spawn_position(surface)
    local pos = surface.find_non_colliding_position('character', spawn, 3, 0.5)

    if not pos and player.online_time < 2 then
        player.teleport(spawn, surface)
    elseif player.online_time < 2 or player.surface.index ~= this.active_surface_index then
        player.teleport(pos, surface)
    end

    create_wave_gui(player)
    add_fd_stats_button(player)

    if game.tick > 900 then
        is_game_lost()
    end
end

local deny_buildings_tbl = {
    ['radar'] = true,
    ['roboport'] = true
}

local function deny_building(event)
    local entity = event.created_entity
    if not entity.valid then
        return
    end

    if entity.position.x >= 655 or entity.position.x < -522 then
        if deny_buildings_tbl[entity.name] then
            if not string.match(entity.name, 'rail') then
                if event.player_index then
                    game.get_player(event.player_index).insert({name = entity.name, count = 1})
                else
                    local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
                    inventory.insert({name = entity.name, count = 1})
                end
            end
            event.created_entity.surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = 'To save map performance, you can only build within the crab claws',
                    color = {r = 0.98, g = 0.66, b = 0.22}
                }
            )

            entity.destroy()
            return true
        end
    end
    return false
end

local on_built_entity = function(event)
    local get_score = Score.get_table().score_table
    local this = FDT.get()
    local entity = event.created_entity
    local surface = entity.surface

    if not surface or not surface.valid then
        return
    end

    if not entity.valid then
        return
    end

    if deny_building(event) then
        return
    end

    local e = {x = entity.position.x, y = entity.position.y}
    local get_tile = surface.get_tile(e)

    if this.entity_limits[entity.name] then
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

    if get_tile.valid and get_tile.name == 'tutorial-grid' then
        entity.destroy()
        return
    end
end

local on_robot_built_entity = function(event)
    local entity = event.created_entity
    local surface = entity.surface

    if not surface or not surface.valid then
        return
    end

    if not entity.valid then
        return
    end

    if deny_building(event) then
        return
    end

    local e = {x = entity.position.x, y = entity.position.y}
    local get_tile = surface.get_tile(e)
    local this = FDT.get()
    if this.entity_limits[entity.name] then
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
            local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
            inventory.insert({name = entity.name, count = 1})
            entity.destroy()
        end
    end

    if get_tile.valid and get_tile.name == 'tutorial-grid' then
        entity.destroy()
        return
    end
end

local on_player_changed_position = function(event)
    local player = game.players[event.player_index]
    local this = FDT.get()
    local surface = game.surfaces[this.active_surface_index]
    if not surface or not surface.valid then
        return
    end

    local p = {x = player.position.x, y = player.position.y}
    local get_tile = surface.get_tile(p.x, p.y)
    if get_tile.valid and get_tile.name == 'tutorial-grid' then
        if player.character and player.character.valid then
            player.character.health = player.character.health - random(20, 40)
            player.character.surface.create_entity({name = 'water-splash', position = player.position})

            if player.character.health <= 0 then
                player.character.die('enemy')
                return
            end
        end
    end
end

local is_position_near = function(area, position)
    local function inside(pos)
        local lt = area.left_top
        local rb = area.right_bottom

        return pos.x >= lt.x and pos.y >= lt.y and pos.x <= rb.x and pos.y <= rb.y
    end

    if inside(position) then
        return true
    end

    return false
end

local on_player_or_robot_built_tile = function(event)
    local surface = game.surfaces[event.surface_index]

    local tiles = event.tiles
    if not tiles then
        return
    end
    local area = {
        left_top = {x = -944, y = -800},
        right_bottom = {x = 944, y = 90}
    }

    for _, v in pairs(tiles) do
        local old_tile = v.old_tile
        if is_position_near(area, v.position) then
            if old_tile.name == 'tutorial-grid' then
                surface.set_tiles({{name = 'tutorial-grid', position = v.position}}, true)
            end
            if old_tile.name == 'water' then
                surface.set_tiles({{name = 'water', position = v.position}}, true)
            end
            if old_tile.name == 'water-green' then
                surface.set_tiles({{name = 'water-green', position = v.position}}, true)
            end
        else
            if v.position.x > 1197 or v.position.x < -1063 then
                surface.set_tiles({{name = old_tile.name, position = v.position}}, true)
            end
        end
    end
end

local on_player_mined_entity = function(event)
    local this = FDT.get()
    if this.entity_limits[event.entity.name] then
        this.entity_limits[event.entity.name].placed = this.entity_limits[event.entity.name].placed - 1
        update_fd_stats()
    end
end

local on_robot_mined_entity = function(event)
    local this = FDT.get()
    if this.entity_limits[event.entity.name] then
        this.entity_limits[event.entity.name].placed = this.entity_limits[event.entity.name].placed - 1
        update_fd_stats()
    end
end

local on_research_finished = function(event)
    disable_tech()
    local research = event.research.name
    if research ~= 'tank' then
        return
    end
    game.forces['player'].technologies['artillery'].researched = true
    game.forces.player.recipes['artillery-wagon'].enabled = false
end

local on_player_respawned = function(event)
    local this = FDT.get()
    if not this.market_age then
        return
    end
    local player = game.players[event.player_index]
    player.character.destructible = false
end

local has_the_game_ended = function()
    local this = FDT.get()
    if this.market_age then
        if not this.game_restart_timer then
            this.game_restart_timer = 5400
        else
            if this.game_restart_timer < 0 then
                return
            end

            this.game_restart_timer = this.game_restart_timer - 30
        end
        local cause_msg
        if this.restart then
            cause_msg = 'restart'
        elseif this.shutdown then
            cause_msg = 'shutdown'
        elseif this.soft_reset then
            cause_msg = 'soft-reset'
        end

        if this.game_restart_timer % 1800 == 0 then
            if this.game_restart_timer > 0 then
                this.game_reset = true
                game.print('Game will ' .. cause_msg .. ' in ' .. this.game_restart_timer / 60 .. ' seconds!', {r = 0.22, g = 0.88, b = 0.22})
            end
            if this.soft_reset and this.game_restart_timer == 0 then
                this.game_reset_tick = nil
                Public.reset_game()
                return
            end
            if this.restart and this.game_restart_timer == 0 then
                if not this.announced_message then
                    game.print('Soft-reset is disabled. Server will restart!', {r = 0.22, g = 0.88, b = 0.22})
                    local message = 'Soft-reset is disabled. Server will restart!'
                    Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
                    Server.start_scenario('Crab_Defender')
                    this.announced_message = true
                    return
                end
            end
            if this.shutdown and this.game_restart_timer == 0 then
                if not this.announced_message then
                    game.print('Soft-reset is disabled. Server is shutting down!', {r = 0.22, g = 0.88, b = 0.22})
                    local message = 'Soft-reset is disabled. Server is shutting down!'
                    Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
                    Server.stop_scenario()
                    this.announced_message = true
                    return
                end
            end
        end
    end
end

local on_init = function()
    Public.reset_game()

    local T = Map.Pop_info()
    T.localised_category = 'crab_defender'
    T.main_caption_color = {r = 0.11, g = 0.8, b = 0.44}
    T.sub_caption_color = {r = 0.33, g = 0.66, b = 0.9}
end

local on_tick = function()
    local Diff = Difficulty.get()
    local this = FDT.get()
    local surface = game.surfaces[this.active_surface_index]
    if not surface or not surface.valid then
        return
    end
    if game.tick % 30 == 0 then
        has_the_game_ended()
        if this.market and this.market.valid then
            for _, player in pairs(game.connected_players) do
                if surface.peaceful_mode == false then
                    create_wave_gui(player)
                end
            end
        end
        if this.wave_count >= (this.wave_limit or 2000) then
            if this.market and this.market.valid then
                this.market.die()
                game.print('Game won!', {r = 0.22, g = 0.88, b = 0.22})
                game.print('Game wave limit reached! Game will soft-reset shortly.', {r = 0.22, g = 0.88, b = 0.22})
                return
            end
        end
        if game.tick % 180 == 0 then
            if surface then
                game.forces.player.chart(surface, {{-428, -24}, {-675, -326}})
                game.forces.player.chart(surface, {{577, -24}, {824, -326}})
                game.forces.player.chart(surface, {{248, 0}, {-248, 200}})
                if Diff.difficulty_vote_index then
                    this.wave_interval = this.difficulties_votes[Diff.difficulty_vote_index].wave_interval
                -- this.wave_interval = 1800
                end
            end
        end
    end

    if game.tick % 600 == 0 then
        local unit_groups = this.unit_groups
        if unit_groups and next(unit_groups) then
            for index, unit_group in pairs(unit_groups) do
                if unit_group.valid then
                    send_unit_group(unit_group)
                else
                    this.unit_groups[index] = nil
                end
            end
        end
    end

    if game.tick % this.wave_interval == this.wave_interval - 1 then
        if surface.peaceful_mode == true then
            return
        end
        biter_attack_wave()
    end
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
Event.add(defines.events.on_player_built_tile, on_player_or_robot_built_tile)
Event.add(defines.events.on_robot_built_tile, on_player_or_robot_built_tile)
Event.add(defines.events.on_tick, on_tick)
Event.on_init(on_init)

return Public
