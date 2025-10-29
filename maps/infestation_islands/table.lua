-- one table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'
local Autostash = require 'modules.autostash'
local BottomFrame = require 'utils.gui.bottom_frame'
local Misc = require 'utils.commands.misc'
local Map = require 'modules.map_info'
local Task = require 'utils.task_token'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Server = require 'utils.server'
local MGS = require 'maps.infestation_islands.island_settings'
local AntiGrief = require 'utils.antigrief'
local Poll = require 'utils.gui.poll'

local this = {}

local Public = { max_island_radius_param = 256 }

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

Public.island_keeper = '[color=blue]Island Keeper: [/color]'

Public.command_color = { r = 0.98, g = 0.66, b = 0.22 }

Public.island_radius_param = 6

Public.base_cooldowns =
{
    [1] = 60 * 60 * 6,
    [2] = 60 * 60 * 4,
    [3] = 60 * 60 * 2.5,
}

Public.base_spider_count =
{
    [1] = { min = 1, max = 2 },
    [2] = { min = 2, max = 3 },
    [3] = { min = 3, max = 4 },
}
Public.decoratives =
{
    'red-croton',
    'brown-hairy-grass',
    'muddy-stump',
    'green-bush-mini',
    'nuclear-ground-patch',
}

Public.spooky_lines =
{
    "The market does not feel as safe as before...",
    "Something feels… off around the market.",
    "The guards whisper of strange noises beneath the ground.",
    "The calm around the market feels forced — too quiet.",
    "The soil near the market seems to move when no one is looking."
}

Public.overrun_messages =
{
    "[color=red]The ground trembles where the market once stood.[/color]",
    "[color=red]Something vast is crawling out from beneath the ruins.[/color]",
    "[color=red]The earth splits open — a tide of biters surges forth.[/color]",
    "[color=red]The market’s ashes stir… the hive awakens.[/color]",
    "[color=red]A dark roar echoes from the crater — they’re not done yet.[/color]",
    "[color=red]The air thickens with the sound of chittering and claws.[/color]",
    "[color=red]The soil itself seems alive where the market once stood.[/color]",
    "[color=red]Smoke rises… and with it, the swarm.[/color]",
    "[color=red]The silence breaks — and the ground moves.[/color]",
    "[color=red]Biters are pouring out of the ruins![/color]",
    "[color=red]The island is being overrun — the swarm is spreading fast![/color]",
    "[color=red]A massive horde erupts from the fallen market![/color]",
    "[color=red]The market’s collapse has unleashed the swarm![/color]",
    "[color=red]The ground bursts open — enemies everywhere![/color]",
    "[color=red]The swarm is reclaiming the island![/color]",
    "[color=red]The defenders are gone — the biters take everything.[/color]",
    "[color=red]They’re coming from below! The island is lost![/color]",
    "[color=red]The market is gone… and the swarm claims what’s left.[/color]",
    "[color=red]Only ruin remains — the swarm feasts in silence.[/color]",
    "[color=red]The island falls quiet, except for the sound of wings and claws.[/color]",
    "[color=red]The market’s fall has awakened something unstoppable.[/color]",
}

Public.quality_per_level = {}
for i = 0, 50 do
    local n = i / 50
    local w_normal, w_uncommon, w_rare, w_epic, w_legendary = 100, 0, 0, 0, 0

    if n > 0.2 then
        w_normal, w_uncommon = 70, 30
    end
    if n > 0.4 then
        w_normal, w_uncommon, w_rare = 65, 25, 10
    end
    if n > 0.6 then
        w_normal, w_uncommon, w_rare, w_epic = 50, 30, 15, 5
    end
    if n > 0.8 then
        w_normal, w_uncommon, w_rare, w_epic, w_legendary = 40, 30, 20, 8, 2
    end

    local total = w_normal + w_uncommon + w_rare + w_epic + w_legendary
    Public.quality_per_level[i] =
    {
        thresholds =
        {
            w_normal / total,
            (w_normal + w_uncommon) / total,
            (w_normal + w_uncommon + w_rare) / total,
            (w_normal + w_uncommon + w_rare + w_epic) / total,
        }
    }
end

Public.valid_enemy_types =
{
    ['unit'] = true,
    ['turret'] = true,
    ['unit-spawner'] = true
}

Public.rock_raffle =
{
    'big-sand-rock',
    'big-sand-rock',
    'big-rock',
    'big-rock',
    'big-rock',
    'big-rock',
    'big-rock',
    'huge-rock',
    'huge-rock'
}

Public.plantable_soil =
{
    'natural-jellynut-soil',
    'artificial-jellynut-soil',
    'natural-yumako-soil',
    'artificial-yumako-soil',
    'wetland-yumako',
    'wetland-jellynut',
}

Public.qualities =
{
    'normal',
    'uncommon',
    'rare',
    'epic',
    'legendary'
}

Public.mining_chances_ores =
{
    { name = 'coal', chance = 26 },
    { name = 'copper-ore', chance = 21 },
    { name = 'iron-ore', chance = 20 },
    { name = 'stone', chance = 15 },
    { name = 'uranium-ore', chance = 10 },
    { name = 'spoilage', chance = 10 },
    { name = 'tungsten-ore', chance = 5 },
    { name = 'holmium-ore', chance = 5 },
    { name = 'calcite', chance = 10 },
    { name = 'lithium', chance = 5 },
    { name = 'jellynut', chance = 5 },
    { name = 'yumako', chance = 5 },
    { name = 'carbon', chance = 5 },
    { name = 'scrap', chance = 5 },
    { name = 'ice', chance = 5 },
}

Public.harvest_raffle_ores = {}
for _, data in pairs(Public.mining_chances_ores) do
    for _ = 1, data.chance, 1 do
        Public.harvest_raffle_ores[#Public.harvest_raffle_ores + 1] = data.name
    end
end
Public.size_of_ore_raffle = #Public.harvest_raffle_ores

Public.raw_ores =
{
    'copper-ore',
    'iron-ore',
    'coal',
    'stone',
    'uranium-ore',
    'calcite',
    'tungsten-ore',
    'scrap',
}

Public.raw_ores_dict =
{
    ['copper-ore'] = { min = 75000, max = 75000 },
    ['iron-ore'] = { min = 75000, max = 75000 },
    ['coal'] = { min = 75000, max = 75000 },
    ['stone'] = { min = 75000, max = 75000 },
    ['uranium-ore'] = { min = 75000, max = 75000 },
    ['calcite'] = { min = 15000, max = 30000 },
    ['tungsten-ore'] = { min = 20000, max = 40000 },
    ['scrap'] = { min = 15000, max = 50000 },
}

Public.oil_raffle =
{
    'sulfuric-acid-geyser',
    'lithium-brine',
    'crude-oil',
}

Public.draw_path_tile_whitelist =
{
    ['water'] = true,
    ['deepwater'] = true,
    ['brash-ice'] = true,
    ['lava-hot'] = true,
}

Public.path_tile_names =
{
    'highland-yellow-rock',
    'highland-yellow-rock',
    'highland-dark-rock-2',
    'highland-dark-rock-2',
    'highland-dark-rock',
    'highland-dark-rock',
    'midland-cracked-lichen-dull',
    'midland-cracked-lichen-dull',
    'midland-cracked-lichen-dark',
    'midland-cracked-lichen-dark',
    'midland-turquoise-bark-2',
    'midland-turquoise-bark-2',
    'midland-turquoise-bark',
    'midland-turquoise-bark',
    'lowland-dead-skin',
    'lowland-dead-skin',
    'lowland-dead-skin-2',
    'lowland-dead-skin-2',
    'lowland-red-vein-dead',
    'lowland-red-vein-dead',
}

Public.path_tile_names_dict =
{
    ['highland-yellow-rock'] = true,
    ['highland-dark-rock-2'] = true,
    ['highland-dark-rock'] = true,
    ['midland-cracked-lichen-dull'] = true,
    ['midland-cracked-lichen-dark'] = true,
    ['midland-turquoise-bark-2'] = true,
    ['midland-turquoise-bark'] = true,
    ['lowland-dead-skin'] = true,
    ['lowland-dead-skin-2'] = true,
    ['lowland-red-vein-dead'] = true,
}

Public.messages =
{
    "The infestation spreads its reach...",
    "Extending the corruption — please stand by...",
    "Creeping tendrils are forming new islands...",
    "Nature’s wrath forges a new connection...",
    "The island keeper senses movement beneath the waters...",
    "Roots dig deep — a new island awakens...",
    "The corruption coils ever closer...",
    "Spawning path tiles... and probably a few regrets...",
    "The ground trembles as the next path takes shape...",
    "Building a new route for our doom — hang tight...",
    "The infestation hums... something new emerges...",
    "Path formation in progress — please don’t fall in...",
    "The snake slithers onward... destination unknown...",
    "Twisting and turning — the way forward is being formed...",
    "Stretching the tendrils of chaos to new lands...",
    "Bridging the gap between survival and regret..."
}

Public.gleba_trees =
{
    'jellystem',
    'yumako-tree'
}

Public.enemy_units =
{
    biter_types =
    {
        { name = 'small-biter', unlock_level = 1 },
        { name = 'small-wriggler-pentapod', unlock_level = 1 },
        { name = 'medium-biter', unlock_level = 3 },
        { name = 'big-biter', unlock_level = 5 },
        { name = 'behemoth-biter', unlock_level = 10 },
        { name = 'medium-wriggler-pentapod', unlock_level = 4 },
        { name = 'big-wriggler-pentapod', unlock_level = 8 },

    },
    spitter_types =
    {
        { name = 'small-spitter', unlock_level = 1 },
        { name = 'medium-spitter', unlock_level = 3 },
        { name = 'big-spitter', unlock_level = 5 },
        { name = 'behemoth-spitter', unlock_level = 10 },
    },
    spider_types =
    {
        { name = 'small-strafer-pentapod', unlock_level = 3 },
        { name = 'medium-strafer-pentapod', unlock_level = 5 },
        { name = 'big-strafer-pentapod', unlock_level = 10 },
        { name = 'small-stomper-pentapod', unlock_level = 8 },
        { name = 'medium-stomper-pentapod', unlock_level = 12 },
        { name = 'big-stomper-pentapod', unlock_level = 15 }
    },
    worm_types =
    {
        { name = 'small-worm-turret', unlock_level = 1 },
        { name = 'medium-worm-turret', unlock_level = 3 },
        { name = 'big-worm-turret', unlock_level = 5 },
        { name = 'behemoth-worm-turret', unlock_level = 10 }
    },
    spawner_types =
    {
        { name = 'biter-spawner', unlock_level = 1 },
        { name = 'spitter-spawner', unlock_level = 1 },
        { name = 'gleba-spawner-small', unlock_level = 1 },
        { name = 'gleba-spawner', unlock_level = 5 }
    },
    spawn_qualities =
    {
        { name = 'normal', unlock_level = 1 },
        { name = 'uncommon', unlock_level = 3 },
        { name = 'rare', unlock_level = 6 },
        { name = 'epic', unlock_level = 10 },
        { name = 'legendary', unlock_level = 15 }
    }
}

Public.voting_messages =
{
    'wants to advance to island %d. Do you agree?',
    'proposes moving on to island %d.',
    'asks if everyone\'s ready for island %d.',
    'suggests we continue our journey to island %d.',
    'is tempted to explore island %d. Shall we follow?',
    'asks: "Should we travel to island %d next?"'
}

local set_tech_limit_token = Task.register(
    function ()
        Public.functions.disable_tech()
    end
)

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

    for _, player in pairs(game.connected_players) do
        if player and player.valid then
            player.character = nil
            player.teleport({ x = 0, y = 0 }, game.surfaces[1])
        end
    end


    local T = Map.Pop_info()
    T.localised_category = 'infestation_islands'
    T.main_caption_color = { r = 150, g = 150, b = 0 }
    T.sub_caption_color = { r = 0, g = 150, b = 0 }

    this.game_lost = false
    this.top_label_caption_override = nil

    local surface = game.surfaces[1]
    surface.ignore_surface_conditions = true
    surface.request_to_generate_chunks({ x = 0, y = 0 }, 6)

    Misc.bottom_button(true)
    BottomFrame.reset()
    BottomFrame.activate_custom_buttons(true)
    Autostash.bottom_button(true)
    Autostash.insert_into_furnace(true)
    AntiGrief.reset_tables()
    Poll.reset()

    this.soft_reset = true

    this.check_afk_players_enabled = true

    this.game_over_if_market_dies = false

    this.bridge_position = { x = 0, y = 0 }

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

    this.megabonk = true

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

    this.auto_create_islands = false

    this.vector = {}

    this.delayed_messages = {}

    this.level_vectors = {}
    this.alive_boss_enemy_entities = {}
    this.current_level = 0

    game.forces.player.set_spawn_position({ 0, 2 }, surface)

    this.alive_enemies = 0

    this.current_level = this.current_level + 1

    this.market_positions = {}

    this.notified_enemies_to_attack = {}

    this.rocket_silo = nil

    this.islands_data =
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

    this.fallen_market = nil
    this.printed_location_for_fallen_market = nil

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

    this.game_over_tasks_done = false

    this.drift_corpses_toward_beach_enabled = true

    this.clear_items_on_ground_state = true
    this.clear_items_on_ground = nil

    this.infinite_ammo_tick = 50

    this.market_rerolls = {}

    this.initial_rocket_silo_created = false

    this.evolution_factor = 0

    this.check_surface_daytime_for_attacks = false

    this.disable_multi_command_attack = false

    this.market_target = nil

    this.cooldown_complete_level = game.tick + 100
    this.voting_to_progress_enabled = true

    this.reverse_start_position = true

    this.checked_island = {}

    this.time_until_next_island_is_created = nil -- 60 * 60 * 60 -- 1 hour
    this.time_until_next_island_is_created_static = nil
    this.auto_generate_upon_idle = true

    game.forces.enemy.set_friend('player', false)
    game.forces.player.set_friend('enemy', false)
    game.forces.enemy.set_cease_fire('player', false)
    game.forces.player.set_cease_fire('enemy', false)

    Public.draw_main_island({ x = 0, y = 0 }, 200)

    Difficulty.reset_difficulty_poll({ closing_timeout = game.tick + 36000 })
    Difficulty.set_gui_width(20)
    Difficulty.set('button_height', 54)

    Difficulty.set_difficulties(
        {
            [1] =
            {
                name = "I'm too young to die",
                index = 1,
                value = 1,
                color = { r = 0.00, g = 0.25, b = 0.00 },
                print_color = { r = 0.00, g = 0.4, b = 0.00 },
                count = 0,
                strength_modifier = 1.00,
                boss_modifier = 6.0
            },
            [2] =
            {
                name = 'Hurt me plenty',
                index = 2,
                value = 4,
                color = { r = 0.00, g = 0.00, b = 0.25 },
                print_color = { r = 0.0, g = 0.0, b = 0.5 },
                count = 0,
                strength_modifier = 5,
                boss_modifier = 7.0
            },
            [3] =
            {
                name = 'Ultra-violence',
                index = 3,
                value = 10,
                color = { r = 255, g = 128, b = 0.00 },
                print_color = { r = 255, g = 128, b = 0.00 },
                count = 0,
                strength_modifier = 12,
                boss_modifier = 8.0
            }
        })
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
