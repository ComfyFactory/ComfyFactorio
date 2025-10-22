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

local this = {}

local Public = {}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local set_gamestate_token =
    Task.register(
        function ()
            this.gamestate = 1
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

    this.calculated_snake_length = 0
    this.snake_length = 200

    this.delayed_messages = {}

    this.level_vectors = {}
    this.alive_boss_enemy_entities = {}
    this.current_level = 0
    this.gamestate = 0
    Task.set_timeout_in_ticks(30, set_gamestate_token)

    game.forces.player.set_spawn_position({ 0, 2 }, surface)

    this.alive_enemies = 0
    this.alive_boss_enemy_count = 0

    this.current_level = this.current_level + 1
    this.current_stage = 1

    this.completed_levels = {}

    this.market_positions = {}

    this.notified_enemies_to_attack = {}

    this.rocket_silo = nil

    this.centered_points =
    {
        [1] = { position = { x = 0, y = 0 }, radius = 200, level = 1 }
    }

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

    this.seeds = nil

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

    Difficulty.reset_difficulty_poll({ closing_timeout = game.tick + 36000 })
    Difficulty.set_gui_width(20)
    Difficulty.set('button_height', 54)
    this.difficulty_vote_ended = false
    Server.to_discord_embed('** A fresh round of Infestation Islands has begun! **')
    Task.set_timeout_in_ticks(100, set_tech_limit_token)
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
