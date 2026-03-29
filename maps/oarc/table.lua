local Event = require 'utils.event'
local Global = require 'utils.global'

local Public = {}

local this = {}

Global.register(
    this,
    function (t)
        this = t
    end
)

function Public.reset_table()
    this.check_players = {}
    this.chunk_size = 32
    this.max_forces = 64
    this.ticks_per_second = 60
    this.ticks_per_minute = 3600
    this.ticks_per_hour = 216000
    this.welcome_msg_title = 'ComfyFactorio!'
    this.welcome_msg = ''
    this.server_msg = '[color=orange]Rules:[/color] Be polite. Ask before changing other players stuff.\n[color=orange]Discord:[/color] https://getcomfy.eu/discord'
    this.scenario_info_msg =
    [[
This scenario gives you and/or your friends your own starting area.
You can play in the main team or your own. All teams are friendly.
If you leave in the first 15 minutes, your base and character will be deleted!


[color=yellow]Repeated joining and leaving will result in a temporary ban.[/color]

[color=yellow]Unoptimized huge builds will be deleted without any notice.[/color]
[color=yellow]Don't reveal new chunks too much since it makes the server lag.[/color]

[color=red]Be aware - joining main force will be difficult for you to survive![/color]

But most importantly - have fun!
        ]]
    this.enable_vanilla_spawns = false
    this.enable_default_spawn = true
    this.enable_buddy_spawn = false

    this.silo_island_mode = false -- keep disabled for random pos
    this.silo_fixed_pos = false -- keep disabled for random pos
    this.frontier_rocket_silo_mode = false
    this.ms_silos_generated = false
    this.silo_spawns = 5
    this.silo_distance = 200
    this.silo_pos =
    {
        { x = -1000, y = -1000 },
        { x = -1000, y = 1000 },
        { x = 1000, y = -1000 },
        { x = 1000, y = 1000 }
    }
    this.enable_silo_vision = true
    this.enable_silo_beacon = true
    this.enable_silo_radar = true
    this.enable_silo_player_build = true

    this.enable_regrowth = true

    this.enable_undecorator = true
    this.clear_old_bases_enabled = true
    this.enable_scramble = false
    this.enable_longreach = false
    this.enable_autofill = false
    this.enable_loaders = true
    this.disable_nukes = true
    this.enable_shared_team_vision = true
    this.enable_base_removal = true
    this.enable_r_queue = true
    this.enable_power_armor = true
    this.modded_enemy = false -- disabled cause OE
    this.enable_market = true
    this.player_spawn_start_items =
    {
        { name = 'pistol', count = 1 },
        { name = 'firearm-magazine', count = 16 },
        { name = 'burner-mining-drill', count = 8 },
        { name = 'stone-furnace', count = 8 },
        { name = 'raw-fish', count = 24 },
        { name = 'iron-plate', count = 48 },
        { name = 'coal', count = 50 },
        { name = 'coal', count = 50 },
        { name = 'stone', count = 50 }
    }

    this.player_respawn_start_items =
    {
        { name = 'pistol', count = 1 },
        { name = 'firearm-magazine', count = 8 }
    }

    this.check_spawn_ungenerated_chunk_radius = 20

    this.near_min_dist = 30
    this.near_max_dist = 50
    this.far_min_dist = 100
    this.far_max_dist = 150

    this.vanilla_spawn_count = 60

    this.vanilla_spawn_distance = 1000

    this.buddy_spawn_distance = (this.chunk_size * 2.5) * 2.8

    this.scenario_config =
    {
        gen_settings =
        {
            -- land_area_tiles = this.chunk_size * 2.5,
            land_area_tiles = this.chunk_size * 2.5,
            moat_choice_enabled = false,
            resources_circle_shape = false,
            force_grass = true,
            tree_circle = false,
            tree_octagon = false,
            tree_square = true,
            trees_enabled = true
        },
        safe_area =
        {
            safe_radius = this.chunk_size * 8,
            warn_radius = this.chunk_size * 16,
            warn_reduction = 20,
            danger_radius = this.chunk_size * 32,
            danger_reduction = 5
        },
        water_new =
        {
            x_offset = -90,
            y_offset = -55,
            length = 10
        },
        water_classic =
        {
            x_offset = -4,
            y_offset = -65,
            length = 8
        },
        resource_rand_pos_settings =
        {
            enabled = true,
            radius = 60,
            angle_offset = 2.32, -- 2.32 is approx SSW.
            angle_final = 4.46 -- 4.46 is approx NNW.
        },
        pos =
        {
            { x = -5, y = -45 },
            { x = 20, y = -45 },
            { x = -30, y = -45 },
            { x = -56, y = -45 }
        },
        resource_tiles_new =
        {
            [1] =
            {
                amount = 2500,
                size = 18
            },
            [2] =
            {
                amount = 2500,
                size = 18
            },
            [3] =
            {
                amount = 2500,
                size = 18
            },
            [4] =
            {
                amount = 2500,
                size = 18
            }
        },
        resource_tiles_classic =
        {
            ['iron-ore'] =
            {
                amount = 1200,
                size = 18,
                x_offset = -29,
                y_offset = 16
            },
            ['copper-ore'] =
            {
                amount = 1200,
                size = 18,
                x_offset = -28,
                y_offset = -3
            },
            ['stone'] =
            {
                amount = 900,
                size = 18,
                x_offset = -27,
                y_offset = -34
            },
            ['coal'] =
            {
                amount = 800,
                size = 18,
                x_offset = -27,
                y_offset = -20
            }
        },
        resource_tiles_town =
        {
            ['iron-ore'] = 1200,
            ['copper-ore'] = 1200,
            ['stone'] = 900,
            ['coal'] = 800
        },
        -- Special resource patches like oil
        resource_patches_new =
        {
            ['crude-oil'] =
            {
                num_patches = 3,
                amount = 1000000,
                x_offset_start = 60,
                y_offset_start = -50,
                x_offset_next = 6,
                y_offset_next = 0
            },
            enabled = false
        },
        resource_patches_classic =
        {
            ['crude-oil'] =
            {
                num_patches = 3,
                amount = 1000000,
                x_offset_start = -3,
                y_offset_start = 60,
                x_offset_next = 6,
                y_offset_next = 0
            },
            enabled = false
        }
    }
    this.enable_separate_teams = true
    this.main_force_name = 'main_force'
    this.enable_shared_spawns = true
    this.max_players = 10
    this.team_chat = true
    this.respawn_cooldown = 15
    this.min_online = 15
    this.last_online = 1440

    this.hidden_dimension_enabled = false

    this.build_dist_bonus = 64
    this.reach_dist_bonus = this.build_dist_bonus
    this.resource_dist_bonus = 2
    this.enable_antigrief = false
    this.ghost_ttl = 10 * this.ticks_per_minute

    this.playerSpawns = {}
    this.uniqueSpawns = {}
    this.vanillaSpawns = {}
    this.sharedSpawns = {}
    this.playerCooldowns = {}
    this.waitingBuddies = {}
    this.delayedSpawns = {}
    this.buddySpawnOptions = {}
    this.siloPosition = {}
    this.force_silo_positions = {}
    this.watery_world = false
    this.town_only_layout = false
    this.layout_square_enabled = true
    this.towns = {}
    this.swarms = {}
    this.evolution_settings =
    {
        radius = 1500,
        log = false,
        night_time_only = false,
        on_tick_check = true,
        towns_grace = 3600 -- 1 minutes
    }
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

function Public.remove(key, sub_key)
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

local reset_table = Public.reset_table

Event.on_init(reset_table)
return Public
