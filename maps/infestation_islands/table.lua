-- one table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'
local Autostash = require 'modules.autostash'
local BottomFrame = require 'utils.gui.bottom_frame'
local Misc = require 'utils.commands.misc'
local Map = require 'modules.map_info'
local Scheduler = require 'utils.scheduler'
local Task = require 'utils.task_token'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Server = require 'utils.server'
local MGS = require 'maps.infestation_islands.island_settings'

local this = {}

local Public = { max_island_radius_param = 256 }

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local set_tech_limit_token = Task.register(
    function ()
        Public.func.disable_tech()
    end
)

Public.qualities =
{
    'normal',
    'uncommon',
    'rare',
    'epic',
    'legendary'
}

local function init_mirror_surface()
    if game.surfaces['island'] then
        return
    end

    local map_gen_settings = MGS
    map_gen_settings.seed = math.random(1, 999999999)

    if not game.surfaces['island'] then
        game.create_surface('island', map_gen_settings)
        local surface = game.surfaces['island']
        surface.ignore_surface_conditions = true
        ---@diagnostic disable-next-line: param-type-mismatch
        surface.request_to_generate_chunks({ 0, 0 }, math.ceil(Public.max_island_radius_param / 32))
    end
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.is_game_lost()
    return this.game_lost or false
end

function Public.on_init()
    for index, _ in pairs(this) do
        this[index] = nil
    end

    init_mirror_surface()

    for _, player in pairs(game.players) do
        if player and player.valid then
            player.character = nil
            player.teleport({ x = 0, y = 0 }, game.surfaces[1])
        end
    end


    local T = Map.Pop_info()
    T.localised_category = 'infestation_islands'
    T.main_caption_color = { r = 150, g = 150, b = 0 }
    T.sub_caption_color = { r = 0, g = 150, b = 0 }

    Scheduler.can_run_scheduler(true)

    this.game_lost = false

    local surface = game.surfaces[1]
    surface.ignore_surface_conditions = true
    surface.request_to_generate_chunks({ x = 0, y = 0 }, 6)

    Misc.bottom_button(true)
    BottomFrame.reset()
    BottomFrame.activate_custom_buttons(true)
    Autostash.bottom_button(true)
    Autostash.insert_into_furnace(true)

    this.soft_reset = true

    this.bridge_position = { x = 0, y = 0 }

    this.notified_market_safe = false

    local mgs = surface.map_gen_settings
    mgs.water = 9.9
    mgs.property_expression_names =
    {
        ['control-setting:aux:bias'] = '0.500000',
        ['control-setting:aux:frequency:multiplier'] = '6.000000',
        ['control-setting:moisture:bias'] = '-0.050000',
        ['control-setting:moisture:frequency:multiplier'] = '6.000000',
    }
    surface.map_gen_settings = mgs

    local blacklist =
    {
        ['dark-mud-decal'] = true,
        ['sand-dune-decal'] = true,
        ['light-mud-decal'] = true,
        ['puberty-decal'] = true,
        ['sand-decal'] = true,
        ['red-desert-decal'] = true
    }
    this.decorative_names = {}
    for k, v in pairs(prototypes.decorative) do
        if not blacklist[k] then
            if v.autoplace_specification then
                this.decorative_names[#this.decorative_names + 1] = k
            end
        end
    end

    local tree_raffle = {}
    for _, e in pairs(prototypes.entity) do
        if e.type == 'tree' then
            table.insert(tree_raffle, e.name)
        end
    end

    this.tree_raffle = tree_raffle

    local corpses_raffle = {}
    for _, e in pairs(prototypes.entity) do
        if e.type == 'corpse' then
            table.insert(corpses_raffle, e.name)
        end
    end

    this.corpses_raffle = corpses_raffle

    this.stages = {}
    this.last_level = 25
    local island_level = 12
    for _ = 1, this.last_level + 1 do
        this.stages[#this.stages + 1] =
        {
            size = 16 + (32 + (island_level * 2)) * 1.5
        }
        island_level = island_level + 5
    end

    this.stages[#this.stages].final = true

    this.final_battle = false

    this.player_options = {}

    this.autogenerate_islands = false

    this.vector = {}

    this.delayed_messages = {}

    this.level_vectors = {}
    this.alive_boss_enemy_entities = {}
    this.current_level = 0

    game.forces.player.set_spawn_position({ 0, 2 }, surface)

    this.alive_enemies = 0
    this.alive_boss_enemy_count = 0

    this.current_level = this.current_level + 1
    this.current_stage = 1

    this.completed_levels = {}

    this.market_positions = {}

    this.notified_enemies_to_attack = {}

    this.rocket_silo = nil

    this.connected_islands = {}

    this.centered_points =
    {
        [1] = { position = { x = 0, y = 0 }, radius = 200, level = 1 }
    }

    -- Determine island path direction (chosen once at init)
    -- Only cardinal directions - perpendicular movement will be added randomly per island
    local directions =
    {
        { name = "right", dx = 1, dy = 0 },
        { name = "left", dx = -1, dy = 0 },
        { name = "up", dx = 0, dy = -1 },
        { name = "down", dx = 0, dy = 1 }
    }
    this.island_direction = directions[math.random(1, #directions)]

    this.quality_list =
    {
        'normal',
        'uncommon',
        'rare',
        'epic',
        'legendary'
    }

    this.tiles = {}

    this.spawned_markets = {}

    this.path_tiles = nil

    this.max_biters_per_island = 150

    if not this.seeds then
        this.seeds =
        {
            seed_1 = math.random(1, 9999999),
            seed_2 = math.random(1, 9999999),
            seed_3 = math.random(1, 9999999),
            seed_m1 = (math.random(8, 16) * 0.1) / 300,
            seed_m2 = (math.random(12, 24) * 0.1) / 300,
            seed_m3 = (math.random(50, 100) * 0.1) / 300
        }
    end

    this.nomed_marked = nil

    this.loot_stats =
    {
        rare = 48,
        normal = 48
    }

    this.infinite_ammo_grants = 1

    this.piercing_ammo_grants = false
    this.uranium_ammo_grants = false
    this.piercing_ammo_grants_added = false
    this.uranium_ammo_grants_added = false

    this.last_attack_tick = game.tick

    this.buried_biters = {}

    surface.freeze_daytime = false
    surface.ticks_per_day = 25200

    this.market_prices = {}

    this.drift_corpses_toward_beach_enabled = true

    this.clear_items_on_ground_state = true
    this.clear_items_on_ground = nil

    this.infinite_ammo_tick = 50

    this.market_rerolls = {}

    this.initial_rocket_silo_created = false

    this.evolution_factor = 0

    this.islands_voting = {}

    this.check_surface_daytime_for_attacks = false

    this.disable_multi_command_attack = false

    this.market_target = nil

    this.cooldown_complete_level = game.tick + 100
    this.voting_to_progress_enabled = true

    this.checked_island = {}

    game.forces.enemy.set_friend('player', false)
    game.forces.player.set_friend('enemy', false)

    Public.draw_main_island({ x = 0, y = 0 }, 200)

    Difficulty.reset_difficulty_poll({ closing_timeout = game.tick + 36000 })
    Difficulty.set_gui_width(20)
    Difficulty.set('button_height', 54)
    this.difficulty_vote_ended = false
    Server.to_discord_embed('** A fresh round of Infestation Islands has begun! **')
    Task.set_timeout_in_ticks(100, set_tech_limit_token)

    if _DEBUG then
        Difficulty.set_poll_closing_timeout(game.tick)
        this.voting_to_progress_enabled = false
        game.speed = 4
        Misc.set('creative_enabled', true)
        game.print('Debug mode enabled, skipping difficulty vote and voting to progress!')
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

Event.on_init(Public.on_init)

return Public
