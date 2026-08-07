--luacheck: ignore
--spiral troopers-- mewmew wrote this -- inspired from kyte
-- modified by Gerkiz and Zuzulya

local Event = require 'utils.event'
local DeferredGenerate = require 'utils.deferred_generate'
local map_functions = require 'utils.tools.map_functions'
local SpawnersContainBiters = require 'modules.spawners_contain_biters'
local Poll = require 'utils.gui.poll'
local SoftReset = require 'utils.functions.soft_reset'
local Commands = require 'utils.commands'
local Color = require 'utils.color_presets'
require 'modules.dynamic_landfill'
require 'modules.satellite_score'

local ring_base_radius = 3
local ring_spacing = 2
local max_ring_level = 20
local loss_check_area =
{
    left_top = { x = -64, y = -64 },
    right_bottom = { x = 96, y = 96 }
}
local starting_items =
{
    ['iron-plate'] = 32,
    ['pistol'] = 1,
    ['firearm-magazine'] = 64
}
local chart_radius = 460
local reset_poll_duration = 120
local reset_poll_cooldown = 54000
local turret_reactivate_delay = 1800
local turret_enemy_check_radius = 32
local rock_raffle = { 'big-sand-rock', 'big-rock', 'big-rock', 'big-rock', 'huge-rock' }
local ore_rotation = { 'iron-ore', 'copper-ore', 'coal', 'stone', 'uranium-ore' }
local coal_free_spawn_radius = 96
local coal_base_amount = 50
local coal_distance_step = 1
local coal_floor_skip_tiles =
{
    ['out-of-map'] = true,
    ['water-green'] = true,
    ['water'] = true,
    ['deepwater'] = true,
    ['deepwater-green'] = true
}
local banned_entity_names =
{
    ['buffer-chest'] = true,
    ['requester-chest'] = true
}

local ore_build_allowed_types =
{
    ['mining-drill'] = true,
    ['transport-belt'] = true,
    ['underground-belt'] = true,
    ['splitter'] = true,
    ['pipe'] = true,
    ['pipe-to-ground'] = true,
    ['electric-pole'] = true,
    ['straight-rail'] = true,
    ['curved-rail-a'] = true,
    ['curved-rail-b'] = true,
    ['rail-signal'] = true,
    ['rail-chain-signal'] = true,
    ['train-stop'] = true,
    ['car'] = true,
    ['locomotive'] = true,
    ['cargo-wagon'] = true,
    ['fluid-wagon'] = true,
    ['artillery-wagon'] = true,
    ['loader'] = true,
    ['loader-1x1'] = true
}
local max_ore_richness = 5000000
local spiral_cords =
{
    { x = 0, y = -1 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 1, y = 0 }
}

local worm_raffle = {}
worm_raffle[1] = { 'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'small-worm-turret' }
worm_raffle[2] = { 'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'medium-worm-turret' }
worm_raffle[3] = { 'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'medium-worm-turret', 'medium-worm-turret' }
worm_raffle[4] = { 'small-worm-turret', 'small-worm-turret', 'small-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret' }
worm_raffle[5] = { 'small-worm-turret', 'small-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'big-worm-turret' }
worm_raffle[6] = { 'small-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'big-worm-turret' }
worm_raffle[7] = { 'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'big-worm-turret', 'big-worm-turret' }
worm_raffle[8] = { 'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'big-worm-turret', 'big-worm-turret' }
worm_raffle[9] = { 'medium-worm-turret', 'medium-worm-turret', 'medium-worm-turret', 'big-worm-turret', 'big-worm-turret', 'big-worm-turret' }
worm_raffle[10] = { 'medium-worm-turret', 'medium-worm-turret', 'big-worm-turret', 'big-worm-turret', 'big-worm-turret', 'big-worm-turret' }

local entity_drop_amount =
{
    ['small-biter'] = { low = 10, high = 20 },
    ['small-spitter'] = { low = 10, high = 20 },
    ['medium-spitter'] = { low = 15, high = 30 },
    ['big-spitter'] = { low = 20, high = 40 },
    ['behemoth-spitter'] = { low = 30, high = 50 },
    ['biter-spawner'] = { low = 50, high = 100 },
    ['spitter-spawner'] = { low = 50, high = 100 }
}
local ore_spill_raffle = { 'iron-ore', 'iron-ore', 'iron-ore', 'iron-ore', 'iron-ore', 'coal', 'coal', 'coal', 'copper-ore', 'copper-ore', 'stone', 'landfill' }

local kabooms = { 'big-artillery-explosion', 'big-explosion', 'explosion' }

local function get_surface_name()
    return storage.spiral_surface_name or 'spiral_troopers'
end

local function get_surface()
    return game.surfaces[get_surface_name()]
end

local function get_map_gen_settings()
    return
    {
        property_expression_names =
        {
            ['tile:water:probability'] = -1000,
            ['tile:deepwater:probability'] = -1000
        },
        cliff_settings = { cliff_elevation_interval = 50, cliff_elevation_0 = 50 },
        autoplace_controls =
        {
            ['coal'] = { frequency = 0, size = 0, richness = 0 },
            ['stone'] = { frequency = 0, size = 0, richness = 0 },
            ['copper-ore'] = { frequency = 0, size = 0, richness = 0 },
            ['iron-ore'] = { frequency = 0, size = 0, richness = 0 },
            ['uranium-ore'] = { frequency = 0, size = 0, richness = 0 },
            ['crude-oil'] =
            {
                frequency = 1000,
                size = 1
            },
            ['trees'] =
            {
                frequency = 4
            },
            ['enemy-base'] =
            {
                frequency = 0
            }
        }
    }
end

local function apply_force_settings(surface)
    game.map_settings.enemy_evolution.destroy_factor = 0.0
    game.map_settings.enemy_evolution.time_factor = 0.0001
    game.map_settings.enemy_evolution.pollution_factor = 0.0
    game.forces.player.set_spawn_position({ 0, 0 }, surface)
    game.forces.player.technologies['artillery-shell-range-1'].enabled = false
    game.forces.player.technologies['artillery-shell-speed-1'].enabled = false
    game.forces.player.technologies['artillery'].enabled = false
    game.forces.player.chart(surface, { { x = -chart_radius, y = -chart_radius }, { x = chart_radius, y = chart_radius } })
end

local mixed_ores =
{
    { name = 'iron-ore', weight = 25 },
    { name = 'copper-ore', weight = 25 },
    { name = 'stone', weight = 50 },
    { name = 'coal', weight = 75 }
}

local mixed_ore_ratios =
{
    ['iron-ore'] =
    {
        { name = 'iron-ore', weight = 75 },
        { name = 'copper-ore', weight = 15 },
        { name = 'stone', weight = 5 },
        { name = 'coal', weight = 5 }
    },
    ['copper-ore'] =
    {
        { name = 'copper-ore', weight = 75 },
        { name = 'iron-ore', weight = 15 },
        { name = 'stone', weight = 5 },
        { name = 'coal', weight = 5 }
    },
    ['coal'] =
    {
        { name = 'coal', weight = 75 },
        { name = 'iron-ore', weight = 15 },
        { name = 'copper-ore', weight = 5 },
        { name = 'stone', weight = 5 }
    },
    ['stone'] =
    {
        { name = 'stone', weight = 75 },
        { name = 'iron-ore', weight = 15 },
        { name = 'copper-ore', weight = 5 },
        { name = 'coal', weight = 5 }
    }
}

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = math.random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

local function ensure_chunk_generated(surface, chunk_x, chunk_y)
    if surface.is_chunk_generated({ chunk_x, chunk_y }) then
        return
    end
    local center = { x = chunk_x * 32 + 16, y = chunk_y * 32 + 16 }
    surface.request_to_generate_chunks(center, 0)
    surface.force_generate_chunk_requests()
end

local function treasure_chest(position, surface)
    local math_random = math.random
    local chest_raffle = {}
    local chest_loot =
    {
        { { name = 'submachine-gun', count = math_random(1, 3) }, weight = 3, evolution_min = 0.0, evolution_max = 0.1 },
        { { name = 'slowdown-capsule', count = math_random(16, 32) }, weight = 1, evolution_min = 0.0, evolution_max = 1 },
        { { name = 'poison-capsule', count = math_random(16, 32) }, weight = 3, evolution_min = 0.3, evolution_max = 1 },
        { { name = 'uranium-cannon-shell', count = math_random(16, 32) }, weight = 5, evolution_min = 0.6, evolution_max = 1 },
        { { name = 'cannon-shell', count = math_random(16, 32) }, weight = 5, evolution_min = 0.4, evolution_max = 0.7 },
        { { name = 'explosive-uranium-cannon-shell', count = math_random(16, 32) }, weight = 5, evolution_min = 0.6, evolution_max = 1 },
        { { name = 'explosive-cannon-shell', count = math_random(16, 32) }, weight = 5, evolution_min = 0.4, evolution_max = 0.8 },
        { { name = 'shotgun', count = 1 }, weight = 2, evolution_min = 0.0, evolution_max = 0.2 },
        { { name = 'shotgun-shell', count = math_random(16, 32) }, weight = 5, evolution_min = 0.0, evolution_max = 0.2 },
        { { name = 'combat-shotgun', count = 1 }, weight = 10, evolution_min = 0.3, evolution_max = 0.8 },
        { { name = 'piercing-shotgun-shell', count = math_random(16, 32) }, weight = 10, evolution_min = 0.2, evolution_max = 1 },
        { { name = 'flamethrower', count = 1 }, weight = 3, evolution_min = 0.3, evolution_max = 0.6 },
        { { name = 'flamethrower-ammo', count = math_random(16, 32) }, weight = 5, evolution_min = 0.3, evolution_max = 1 },
        { { name = 'rocket-launcher', count = 1 }, weight = 5, evolution_min = 0.2, evolution_max = 0.6 },
        { { name = 'rocket', count = math_random(16, 32) }, weight = 10, evolution_min = 0.2, evolution_max = 0.7 },
        { { name = 'explosive-rocket', count = math_random(16, 32) }, weight = 10, evolution_min = 0.3, evolution_max = 1 },
        { { name = 'land-mine', count = math_random(8, 16) }, weight = 10, evolution_min = 0.2, evolution_max = 0.7 },
        { { name = 'grenade', count = math_random(8, 16) }, weight = 10, evolution_min = 0.0, evolution_max = 0.5 },
        { { name = 'cluster-grenade', count = math_random(8, 16) }, weight = 5, evolution_min = 0.4, evolution_max = 1 },
        { { name = 'firearm-magazine', count = math_random(32, 128) }, weight = 10, evolution_min = 0, evolution_max = 0.3 },
        { { name = 'piercing-rounds-magazine', count = math_random(32, 128) }, weight = 10, evolution_min = 0.1, evolution_max = 0.8 },
        { { name = 'uranium-rounds-magazine', count = math_random(32, 128) }, weight = 10, evolution_min = 0.5, evolution_max = 1 },
        { { name = 'defender-capsule', count = math_random(8, 16) }, weight = 10, evolution_min = 0.0, evolution_max = 0.7 },
        { { name = 'distractor-capsule', count = math_random(8, 16) }, weight = 10, evolution_min = 0.2, evolution_max = 1 },
        { { name = 'destroyer-capsule', count = math_random(8, 16) }, weight = 10, evolution_min = 0.3, evolution_max = 1 },
        { { name = 'atomic-bomb', count = math_random(1, 2) }, weight = 1, evolution_min = 0.2, evolution_max = 1 },
        { { name = 'light-armor', count = 1 }, weight = 3, evolution_min = 0, evolution_max = 0.1 },
        { { name = 'heavy-armor', count = 1 }, weight = 3, evolution_min = 0.1, evolution_max = 0.3 },
        { { name = 'modular-armor', count = 1 }, weight = 2, evolution_min = 0.2, evolution_max = 0.6 },
        { { name = 'power-armor', count = 1 }, weight = 2, evolution_min = 0.4, evolution_max = 1 },
        { { name = 'power-armor-mk2', count = 1 }, weight = 1, evolution_min = 0.8, evolution_max = 1 },
        { { name = 'battery-equipment', count = 1 }, weight = 2, evolution_min = 0.3, evolution_max = 0.7 },
        { { name = 'battery-mk2-equipment', count = 1 }, weight = 2, evolution_min = 0.6, evolution_max = 1 },
        { { name = 'belt-immunity-equipment', count = 1 }, weight = 1, evolution_min = 0.3, evolution_max = 1 },
        { { name = 'solar-panel-equipment', count = math_random(1, 4) }, weight = 5, evolution_min = 0.3, evolution_max = 0.8 },
        { { name = 'discharge-defense-equipment', count = 1 }, weight = 1, evolution_min = 0.5, evolution_max = 0.8 },
        { { name = 'energy-shield-equipment', count = math_random(1, 2) }, weight = 2, evolution_min = 0.3, evolution_max = 0.8 },
        { { name = 'energy-shield-mk2-equipment', count = 1 }, weight = 2, evolution_min = 0.7, evolution_max = 1 },
        { { name = 'exoskeleton-equipment', count = 1 }, weight = 1, evolution_min = 0.3, evolution_max = 1 },
        { { name = 'fission-reactor-equipment', count = 1 }, weight = 1, evolution_min = 0.5, evolution_max = 1 },
        { { name = 'night-vision-equipment', count = 1 }, weight = 1, evolution_min = 0.3, evolution_max = 0.8 },
        { { name = 'personal-laser-defense-equipment', count = 1 }, weight = 2, evolution_min = 0.4, evolution_max = 1 },
        { { name = 'exoskeleton-equipment', count = 1 }, weight = 1, evolution_min = 0.3, evolution_max = 1 },
        { { name = 'iron-gear-wheel', count = math_random(80, 100) }, weight = 3, evolution_min = 0.0, evolution_max = 0.3 },
        { { name = 'copper-cable', count = math_random(100, 200) }, weight = 3, evolution_min = 0.0, evolution_max = 0.3 },
        { { name = 'engine-unit', count = math_random(16, 32) }, weight = 2, evolution_min = 0.1, evolution_max = 0.5 },
        { { name = 'electric-engine-unit', count = math_random(16, 32) }, weight = 2, evolution_min = 0.4, evolution_max = 0.8 },
        { { name = 'battery', count = math_random(100, 200) }, weight = 2, evolution_min = 0.3, evolution_max = 0.8 },
        { { name = 'advanced-circuit', count = math_random(100, 200) }, weight = 3, evolution_min = 0.4, evolution_max = 1 },
        { { name = 'electronic-circuit', count = math_random(100, 200) }, weight = 3, evolution_min = 0.0, evolution_max = 0.4 },
        { { name = 'processing-unit', count = math_random(100, 200) }, weight = 3, evolution_min = 0.7, evolution_max = 1 },
        { { name = 'explosives', count = math_random(25, 50) }, weight = 1, evolution_min = 0.2, evolution_max = 0.6 },
        { { name = 'lubricant-barrel', count = math_random(4, 10) }, weight = 1, evolution_min = 0.3, evolution_max = 0.5 },
        { { name = 'rocket-fuel', count = math_random(4, 10) }, weight = 2, evolution_min = 0.3, evolution_max = 0.7 },
        { { name = 'steel-plate', count = math_random(50, 100) }, weight = 2, evolution_min = 0.1, evolution_max = 0.3 },
        { { name = 'nuclear-fuel', count = 1 }, weight = 2, evolution_min = 0.7, evolution_max = 1 },
        { { name = 'burner-inserter', count = math_random(16, 32) }, weight = 3, evolution_min = 0.0, evolution_max = 0.1 },
        { { name = 'inserter', count = math_random(16, 32) }, weight = 3, evolution_min = 0.0, evolution_max = 0.4 },
        { { name = 'long-handed-inserter', count = math_random(16, 32) }, weight = 3, evolution_min = 0.0, evolution_max = 0.4 },
        { { name = 'fast-inserter', count = math_random(16, 32) }, weight = 3, evolution_min = 0.1, evolution_max = 1 },
        { { name = 'bulk-inserter', count = math_random(4, 8) }, weight = 1, evolution_min = 0.4, evolution_max = 1 },
        { { name = 'bulk-inserter', count = math_random(4, 8) }, weight = 3, evolution_min = 0.3, evolution_max = 1 },
        { { name = 'small-electric-pole', count = math_random(8, 16) }, weight = 3, evolution_min = 0.0, evolution_max = 0.3 },
        { { name = 'medium-electric-pole', count = math_random(8, 16) }, weight = 3, evolution_min = 0.2, evolution_max = 1 },
        { { name = 'big-electric-pole', count = math_random(8, 16) }, weight = 3, evolution_min = 0.3, evolution_max = 1 },
        { { name = 'substation', count = math_random(4, 8) }, weight = 3, evolution_min = 0.5, evolution_max = 1 },
        { { name = 'wooden-chest', count = math_random(8, 16) }, weight = 3, evolution_min = 0.0, evolution_max = 0.2 },
        { { name = 'iron-chest', count = math_random(8, 16) }, weight = 3, evolution_min = 0.1, evolution_max = 0.4 },
        { { name = 'steel-chest', count = math_random(8, 16) }, weight = 3, evolution_min = 0.3, evolution_max = 1 },
        { { name = 'small-lamp', count = math_random(8, 16) }, weight = 3, evolution_min = 0.1, evolution_max = 0.3 },
        { { name = 'rail', count = math_random(50, 100) }, weight = 3, evolution_min = 0.1, evolution_max = 0.6 },
        { { name = 'assembling-machine-1', count = math_random(2, 4) }, weight = 3, evolution_min = 0.0, evolution_max = 0.3 },
        { { name = 'assembling-machine-2', count = math_random(2, 4) }, weight = 3, evolution_min = 0.2, evolution_max = 0.8 },
        { { name = 'assembling-machine-3', count = math_random(2, 4) }, weight = 3, evolution_min = 0.5, evolution_max = 1 },
        { { name = 'accumulator', count = math_random(4, 8) }, weight = 3, evolution_min = 0.4, evolution_max = 1 },
        { { name = 'offshore-pump', count = math_random(2, 4) }, weight = 2, evolution_min = 0.0, evolution_max = 0.1 },
        { { name = 'beacon', count = math_random(2, 4) }, weight = 3, evolution_min = 0.7, evolution_max = 1 },
        { { name = 'boiler', count = math_random(4, 8) }, weight = 3, evolution_min = 0.0, evolution_max = 0.3 },
        { { name = 'steam-engine', count = math_random(4, 8) }, weight = 3, evolution_min = 0.0, evolution_max = 0.5 },
        { { name = 'steam-turbine', count = math_random(2, 4) }, weight = 2, evolution_min = 0.5, evolution_max = 1 },
        { { name = 'nuclear-reactor', count = 1 }, weight = 1, evolution_min = 0.5, evolution_max = 1 },
        { { name = 'centrifuge', count = math_random(1, 2) }, weight = 2, evolution_min = 0.5, evolution_max = 1 },
        { { name = 'heat-pipe', count = math_random(8, 16) }, weight = 2, evolution_min = 0.5, evolution_max = 1 },
        { { name = 'heat-exchanger', count = math_random(4, 8) }, weight = 2, evolution_min = 0.5, evolution_max = 1 },
        { { name = 'arithmetic-combinator', count = math_random(25, 50) }, weight = 1, evolution_min = 0.1, evolution_max = 1 },
        { { name = 'constant-combinator', count = math_random(25, 50) }, weight = 1, evolution_min = 0.1, evolution_max = 1 },
        { { name = 'decider-combinator', count = math_random(25, 50) }, weight = 1, evolution_min = 0.1, evolution_max = 1 },
        { { name = 'power-switch', count = math_random(8, 16) }, weight = 1, evolution_min = 0.1, evolution_max = 1 },
        { { name = 'programmable-speaker', count = math_random(8, 16) }, weight = 1, evolution_min = 0.1, evolution_max = 1 },
        { { name = 'chemical-plant', count = math_random(2, 4) }, weight = 3, evolution_min = 0.3, evolution_max = 1 },
        { { name = 'burner-mining-drill', count = math_random(8, 16) }, weight = 3, evolution_min = 0.0, evolution_max = 0.2 },
        { { name = 'electric-mining-drill', count = math_random(4, 8) }, weight = 3, evolution_min = 0.2, evolution_max = 0.6 },
        { { name = 'express-transport-belt', count = math_random(50, 100) }, weight = 3, evolution_min = 0.5, evolution_max = 1 },
        { { name = 'express-underground-belt', count = math_random(4, 16) }, weight = 3, evolution_min = 0.5, evolution_max = 1 },
        { { name = 'express-splitter', count = math_random(8, 16) }, weight = 3, evolution_min = 0.5, evolution_max = 1 },
        { { name = 'fast-transport-belt', count = math_random(50, 100) }, weight = 3, evolution_min = 0.2, evolution_max = 0.7 },
        { { name = 'fast-underground-belt', count = math_random(4, 16) }, weight = 3, evolution_min = 0.2, evolution_max = 0.7 },
        { { name = 'fast-splitter', count = math_random(8, 16) }, weight = 3, evolution_min = 0.2, evolution_max = 0.3 },
        { { name = 'transport-belt', count = math_random(50, 100) }, weight = 3, evolution_min = 0, evolution_max = 0.3 },
        { { name = 'underground-belt', count = math_random(4, 16) }, weight = 3, evolution_min = 0, evolution_max = 0.3 },
        { { name = 'splitter', count = math_random(8, 16) }, weight = 3, evolution_min = 0, evolution_max = 0.3 },
        { { name = 'oil-refinery', count = math_random(1, 2) }, weight = 2, evolution_min = 0.3, evolution_max = 1 },
        { { name = 'pipe', count = math_random(40, 50) }, weight = 3, evolution_min = 0.0, evolution_max = 0.3 },
        { { name = 'pipe-to-ground', count = math_random(25, 50) }, weight = 1, evolution_min = 0.2, evolution_max = 0.5 },
        { { name = 'pumpjack', count = math_random(2, 4) }, weight = 1, evolution_min = 0.3, evolution_max = 0.8 },
        { { name = 'pump', count = math_random(2, 4) }, weight = 1, evolution_min = 0.3, evolution_max = 0.8 },
        { { name = 'solar-panel', count = math_random(4, 8) }, weight = 3, evolution_min = 0.4, evolution_max = 0.9 },
        { { name = 'electric-furnace', count = math_random(2, 4) }, weight = 3, evolution_min = 0.5, evolution_max = 1 },
        { { name = 'steel-furnace', count = math_random(4, 8) }, weight = 3, evolution_min = 0.2, evolution_max = 0.7 },
        { { name = 'stone-furnace', count = math_random(8, 16) }, weight = 3, evolution_min = 0.0, evolution_max = 0.1 },
        { { name = 'radar', count = math_random(1, 2) }, weight = 1, evolution_min = 0.1, evolution_max = 0.3 },
        { { name = 'rail-signal', count = math_random(8, 16) }, weight = 2, evolution_min = 0.2, evolution_max = 0.8 },
        { { name = 'rail-chain-signal', count = math_random(8, 16) }, weight = 2, evolution_min = 0.2, evolution_max = 0.8 },
        { { name = 'stone-wall', count = math_random(50, 100) }, weight = 1, evolution_min = 0.1, evolution_max = 0.5 },
        { { name = 'gate', count = math_random(8, 16) }, weight = 1, evolution_min = 0.1, evolution_max = 0.5 },
        { { name = 'storage-tank', count = math_random(4, 8) }, weight = 3, evolution_min = 0.3, evolution_max = 0.6 },
        { { name = 'train-stop', count = math_random(2, 4) }, weight = 1, evolution_min = 0.2, evolution_max = 0.7 },
        { { name = 'express-loader', count = math_random(1, 2) }, weight = 1, evolution_min = 0.5, evolution_max = 1 },
        { { name = 'fast-loader', count = math_random(1, 2) }, weight = 1, evolution_min = 0.2, evolution_max = 0.7 },
        { { name = 'loader', count = math_random(1, 2) }, weight = 1, evolution_min = 0.0, evolution_max = 0.5 },
        { { name = 'lab', count = math_random(2, 4) }, weight = 2, evolution_min = 0.0, evolution_max = 0.1 }
    }

    local level = storage.spiral_troopers_level / 40
    if level > 1 then
        level = 1
    end
    for _, t in pairs(chest_loot) do
        if prototypes.item[t[1].name] then
            for _ = 1, t.weight, 1 do
                if t.evolution_min <= level and t.evolution_max >= level then
                    table.insert(chest_raffle, t[1])
                end
            end
        end
    end
    local chest_type_raffle = { 'steel-chest', 'iron-chest', 'wooden-chest' }
    local e = surface.create_entity { name = chest_type_raffle[math_random(1, #chest_type_raffle)], position = position, force = 'player' }
    e.destructible = false
    local i = e.get_inventory(defines.inventory.chest)
    for _ = 1, math_random(3, 4), 1 do
        local loot = chest_raffle[math_random(1, #chest_raffle)]
        i.insert(loot)
    end
end

local function level_finished()
    local surface = get_surface()
    if not storage.spiral_troopers_beaten_level then
        storage.spiral_troopers_beaten_level = 1
    else
        storage.spiral_troopers_beaten_level = storage.spiral_troopers_beaten_level + 1
    end

    local evolution = storage.spiral_troopers_beaten_level / 40
    if evolution > 1 then
        evolution = 1
    end
    game.forces.enemy.set_evolution_factor(evolution, surface.index)

    for _, player in pairs(game.connected_players) do
        player.play_sound { path = 'utility/new_objective', volume_modifier = 0.6 }
    end
    game.print('Level ' .. storage.spiral_troopers_beaten_level .. ' finished. Area Unlocked!')

    local radius = (storage.spiral_troopers_beaten_level / 2) * 32
    radius = radius + 160
    game.forces.player.chart(surface, { { x = -1 * radius, y = -1 * radius }, { x = radius, y = radius } })
end

local function pick_weighted_ore(ratio_table)
    local total = 0
    for _, r in pairs(ratio_table) do
        total = total + r.weight
    end
    local roll = math.random(1, total)
    local acc = 0
    for _, r in pairs(ratio_table) do
        acc = acc + r.weight
        if roll <= acc then
            return r.name
        end
    end
    return ratio_table[1].name
end

local function clear_resource_at(surface, pos)
    local existing = surface.find_entities_filtered({ position = pos, type = 'resource', limit = 1 })
    if existing[1] then
        existing[1].destroy()
    end
end

local function draw_mixed_ore_circle(center, main_ore, surface, radius, amount)
    local ratio_table = mixed_ore_ratios[main_ore]
    for dx = -radius, radius do
        for dy = -radius, radius do
            local dist = math.sqrt(dx * dx + dy * dy)
            local edge_wobble = radius - math.random(0, 2)
            if dist <= edge_wobble then
                local pos = { x = math.floor(center.x + dx) + 0.5, y = math.floor(center.y + dy) + 0.5 }
                local tile = surface.get_tile(pos.x, pos.y)
                if tile.valid and tile.name ~= 'out-of-map' then
                    clear_resource_at(surface, pos)
                    local ore_name = ratio_table and pick_weighted_ore(ratio_table) or main_ore
                    local falloff = 1 - (dist / (edge_wobble + 1)) * 0.6
                    local tile_amount = math.floor(amount * falloff * (0.85 + math.random() * 0.3))
                    if tile_amount < 1 then
                        tile_amount = 1
                    end
                    surface.create_entity({ name = ore_name, position = pos, amount = tile_amount })
                end
            end
        end
    end
end

local function place_oil_field(surface, center, amount)
    if amount <= 1000 then
        amount = math.random(500000, 1500000)
    end
    local pos = { x = math.floor(center.x) + 0.5, y = math.floor(center.y) + 0.5 }
    surface.create_entity({ name = 'crude-oil', position = pos, amount = amount })
end

local function enforce_banned_entities(entity, event)
    if not (entity and entity.valid) then
        return false
    end
    local is_ghost = entity.name == 'entity-ghost'
    local e_name = is_ghost and entity.ghost_name or entity.name
    if not banned_entity_names[e_name] then
        return false
    end
    if event.player_index then
        local player = game.players[event.player_index]
        if player and player.valid then
            player.print('Buffer chest and requester chest cannot be built.', { color = { r = 1, g = 0.3, b = 0 } })
        end
    end
    if is_ghost then
        entity.destroy()
        return true
    end
    local surface = entity.surface
    local position = entity.position
    local ok = pcall(function ()
        local items_to_place = entity.prototype.items_to_place_this
        local stack = items_to_place and items_to_place[1]
        if stack then
            local actor = event.robot or (event.player_index and game.players[event.player_index])
            if actor and actor.valid and actor.can_insert(stack) then
                actor.insert(stack)
            else
                surface.spill_item_stack({ position = position, stack = stack, enable_looted = true, allow_belts = true })
            end
        end
    end)
    if not ok then
        log('spiral_troopers enforce_banned_entities: refund failed for ' .. tostring(entity.name))
    end
    entity.destroy()
    return true
end


local function enforce_ore_build_restriction(entity, event)
    if not (entity and entity.valid) then
        return false
    end
    local is_ghost = entity.name == 'entity-ghost'
    local e_type = is_ghost and entity.ghost_type or entity.type
    if ore_build_allowed_types[e_type] then
        return false
    end
    local on_resource = entity.surface.count_entities_filtered({ area = entity.bounding_box, type = 'resource', limit = 1 }) > 0
    if not on_resource then
        return false
    end

    if event.player_index then
        local player = game.players[event.player_index]
        if player and player.valid then
            player.print('Cannot build this on ore/coal - only drills, belts, pipes, poles, rails and vehicles are allowed.', { color = { r = 1, g = 0.3, b = 0 } })
        end
    end

    if is_ghost then
        entity.destroy()
        return true
    end

    local surface = entity.surface
    local position = entity.position
    local ok = pcall(function ()
        local items_to_place = entity.prototype.items_to_place_this
        local stack = items_to_place and items_to_place[1]
        if stack then
            local actor = event.robot or (event.player_index and game.players[event.player_index])
            if actor and actor.valid and actor.can_insert(stack) then
                actor.insert(stack)
            else
                surface.spill_item_stack({ position = position, stack = stack, enable_looted = true, allow_belts = true })
            end
        end
    end)
    if not ok then
        log('spiral_troopers enforce_ore_build_restriction: refund failed for ' .. tostring(entity.name))
    end

    surface.create_entity({ name = 'explosion', position = position })
    entity.destroy()
    return true
end

local function get_furthest_chunk()
    local surface = get_surface()
    local x = 1
    while true do
        if not surface.is_chunk_generated({ 0 + x, 0 }) then
            break
        end
        x = x + 1
    end
    x = x - 1
    local y = 1
    while true do
        if not surface.is_chunk_generated({ 0, 0 + y }) then
            break
        end
        y = y + 1
    end
    y = y - 1
    return x, y
end

local function clear_chunk_of_enemies(chunk, surface)
    local a =
    {
        left_top = { x = chunk.x * 32, y = chunk.y * 32 },
        right_bottom = { x = (chunk.x * 32) + 31, y = (chunk.y * 32) + 31 }
    }
    local enemies = surface.find_entities_filtered({ force = 'enemy', area = a })
    if enemies[1] then
        for i = 1, #enemies, 1 do
            enemies[i].destroy()
        end
    end
end



local function ring_perimeter_chunks(radius)
    local chunks = {}
    for x = -radius, radius do
        table.insert(chunks, { x = x, y = -radius })
        table.insert(chunks, { x = x, y = radius })
    end
    for y = -radius + 1, radius - 1 do
        table.insert(chunks, { x = -radius, y = y })
        table.insert(chunks, { x = radius, y = y })
    end
    return chunks
end

local function ore_richness_for_level(level)
    local richness = 150000 * (5 ^ (level - 1))
    if richness > max_ore_richness then
        richness = max_ore_richness
    end
    return richness
end

local function grow_action_step(job)
    if job.map_id ~= storage.spiral_map_id then
        return false
    end
    local surface = get_surface()
    if not surface or not surface.valid then
        storage.spiral_growth_in_progress = false
        return false
    end

    local phase = job.phase
    local level = job.level
    local radius = job.radius
    local checkpoint_chunk = job.checkpoint_chunk
    local reward_chunk = job.reward_chunk
    local side_index = job.side_index

    if phase == 1 then
        ensure_chunk_generated(surface, checkpoint_chunk.x, checkpoint_chunk.y)
        ensure_chunk_generated(surface, reward_chunk.x, reward_chunk.y)
        clear_chunk_of_enemies(checkpoint_chunk, surface)
        clear_chunk_of_enemies(reward_chunk, surface)
        local tiles = {}
        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                local pos = { x = checkpoint_chunk.x * 32 + x, y = checkpoint_chunk.y * 32 + y }
                table.insert(tiles, { name = 'water-green', position = pos })
                if math.random(1, 2) == 1 then
                    table.insert(job.entities, { name = rock_raffle[math.random(1, #rock_raffle)], position = pos })
                end
            end
        end
        surface.set_tiles(tiles, true)
        local checkpoint_area =
        {
            left_top = { x = checkpoint_chunk.x * 32, y = checkpoint_chunk.y * 32 },
            right_bottom = { x = checkpoint_chunk.x * 32 + 32, y = checkpoint_chunk.y * 32 + 32 }
        }
        for _, res in pairs(surface.find_entities_filtered({ area = checkpoint_area, type = 'resource' })) do
            res.destroy()
        end
        job.phase = 2
        return true
    end

    if phase == 2 then
        local diagonal_dirs = { { x = 1, y = 1 }, { x = -1, y = 1 }, { x = 1, y = -1 }, { x = -1, y = -1 } }
        for _, d in pairs(diagonal_dirs) do
            local water_chunk = { x = d.x * (radius - 1), y = d.y * (radius - 1) }
            ensure_chunk_generated(surface, water_chunk.x, water_chunk.y)
            local water_pos = { x = water_chunk.x * 32 + 16, y = water_chunk.y * 32 + 16 }
            map_functions.draw_noise_tile_circle(water_pos, 'water', surface, 5)
            local water_area =
            {
                left_top = { x = water_pos.x - 7, y = water_pos.y - 7 },
                right_bottom = { x = water_pos.x + 7, y = water_pos.y + 7 }
            }
            for _, res in pairs(surface.find_entities_filtered({ area = water_area, type = 'resource' })) do
                res.destroy()
            end
            place_oil_field(surface, water_pos, ore_richness_for_level(level))
        end
        job.phase = 3
        job.next_tick = game.tick + 10
        return true
    end

    if phase == 3 then
        local ok_reward, err_reward = pcall(function ()
            local tiles = {}
            for x = 0, 31, 1 do
                for y = 0, 31, 1 do
                    local pos = { x = reward_chunk.x * 32 + x, y = reward_chunk.y * 32 + y }
                    if x == 16 and y == 16 then
                        local ore = ore_rotation[side_index]
                        if level % 3 == 0 then
                            ore = 'uranium-ore'
                        end
                        draw_mixed_ore_circle(pos, ore, surface, 14, ore_richness_for_level(level))
                        local unlocker = surface.create_entity({ name = 'burner-inserter', position = pos, force = 'player' })
                        unlocker.destructible = false
                        unlocker.minable_flag = false
                    end

                    if x >= 4 and x <= 5 and y >= 4 and y <= 5 then
                        if math.random(1, 3) ~= 1 then
                            treasure_chest(pos, surface)
                        end
                    end
                    if x >= 26 and x <= 27 and y >= 26 and y <= 27 then
                        if math.random(1, 3) ~= 1 then
                            treasure_chest(pos, surface)
                        end
                    end
                    if x >= 26 and x <= 27 and y >= 4 and y <= 5 then
                        if math.random(1, 3) ~= 1 then
                            treasure_chest(pos, surface)
                        end
                    end
                    if x >= 4 and x <= 5 and y >= 26 and y <= 27 then
                        if math.random(1, 3) ~= 1 then
                            treasure_chest(pos, surface)
                        end
                    end

                    if x >= 3 and x <= 6 and y >= 3 and y <= 6 then
                        table.insert(tiles, { name = 'concrete', position = pos })
                    end
                    if x >= 25 and x <= 28 and y >= 25 and y <= 28 then
                        table.insert(tiles, { name = 'concrete', position = pos })
                    end
                    if x >= 25 and x <= 28 and y >= 3 and y <= 6 then
                        table.insert(tiles, { name = 'concrete', position = pos })
                    end
                    if x >= 3 and x <= 6 and y >= 25 and y <= 28 then
                        table.insert(tiles, { name = 'concrete', position = pos })
                    end
                end
            end
            surface.set_tiles(tiles, true)
        end)
        if not ok_reward then
            log('spiral_troopers grow_level: reward room error at level ' .. tostring(level) .. ': ' .. tostring(err_reward))
        end
        local checkpoint_water_center = { x = checkpoint_chunk.x * 32 + 16, y = checkpoint_chunk.y * 32 + 16 }
        place_oil_field(surface, checkpoint_water_center, ore_richness_for_level(level))
        job.phase = 4
        job.next_tick = game.tick + 10
        return true
    end

    if phase == 4 then
        local ok_ore, err_ore = pcall(function ()
            for other_side = 1, 4 do
                if other_side ~= side_index then
                    local other_dir = spiral_cords[other_side]
                    local ore_chunk = { x = other_dir.x * (radius - 1), y = other_dir.y * (radius - 1) }
                    ensure_chunk_generated(surface, ore_chunk.x, ore_chunk.y)
                    local ore_pos = { x = ore_chunk.x * 32 + 16, y = ore_chunk.y * 32 + 16 }
                    draw_mixed_ore_circle(ore_pos, ore_rotation[other_side], surface, 14, ore_richness_for_level(level))
                end
            end
        end)
        if not ok_ore then
            log('spiral_troopers grow_level: side-ore error at level ' .. tostring(level) .. ': ' .. tostring(err_ore))
        end
        job.phase = 5
        job.index = 1
        job.next_tick = game.tick + 10
        return true
    end

    if phase == 5 then
        local chunk = job.wall_chunks[job.index]
        if not chunk then
            job.phase = 6
            return true
        end
        ensure_chunk_generated(surface, chunk.x, chunk.y)
        local wall_chunk_area =
        {
            left_top = { x = chunk.x * 32, y = chunk.y * 32 },
            right_bottom = { x = chunk.x * 32 + 32, y = chunk.y * 32 + 32 }
        }
        for _, res in pairs(surface.find_entities_filtered({ area = wall_chunk_area, type = 'resource' })) do
            res.destroy()
        end
        local wall_tiles = {}
        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                local pos = { x = chunk.x * 32 + x, y = chunk.y * 32 + y }
                table.insert(wall_tiles, { name = 'out-of-map', position = pos })
            end
        end
        surface.set_tiles(wall_tiles, true)
        job.index = job.index + 1
        job.next_tick = game.tick + 10
        return true
    end
    if phase == 6 then
        local r = 550
        game.forces.player.chart(surface, { { x = -r, y = -r }, { x = r, y = r } })
        job.index = job.index + 1
        job.next_tick = game.tick + 10
        job.phase = 7
        return true
    end

    if not storage.checkpoint_barriers then
        storage.checkpoint_barriers = {}
    end
    storage.checkpoint_barriers[level] = {}
    for _, e in pairs(job.entities) do
        local entity = surface.create_entity(e)
        entity.destructible = false
        entity.minable_flag = false
        table.insert(storage.checkpoint_barriers[level], entity)
    end
    storage.checkpoint_barriers[level] = shuffle(storage.checkpoint_barriers[level])
    storage.spiral_growth_in_progress = false
    return false
end

local function grow_action(job)
    local success, result = pcall(grow_action_step, job)
    if not success then
        storage.spiral_growth_in_progress = false
        log('spiral_troopers grow_action error: ' .. tostring(result))
        return false
    end
    return result
end

local grow_action_token = DeferredGenerate.register(grow_action)

local function start_grow_job()
    if not storage.spiral_troopers_level then
        storage.spiral_troopers_level = 1
    else
        storage.spiral_troopers_level = storage.spiral_troopers_level + 1
    end
    local level = storage.spiral_troopers_level
    local side_index = level % 4
    if side_index == 0 then
        side_index = 4
    end
    local side_dir = spiral_cords[side_index]
    local radius = ring_base_radius + (level - 1) * ring_spacing
    local checkpoint_chunk = { x = side_dir.x * radius, y = side_dir.y * radius }
    local reward_chunk = { x = side_dir.x * (radius - 1), y = side_dir.y * (radius - 1) }
    local wall_chunks = {}
    for _, chunk in pairs(ring_perimeter_chunks(radius)) do
        if not (chunk.x == checkpoint_chunk.x and chunk.y == checkpoint_chunk.y) then
            table.insert(wall_chunks, chunk)
        end
    end
    local job =
    {
        phase = 1,
        index = 1,
        level = level,
        radius = radius,
        side_index = side_index,
        checkpoint_chunk = checkpoint_chunk,
        reward_chunk = reward_chunk,
        wall_chunks = wall_chunks,
        entities = {},
        map_id = storage.spiral_map_id or 0
    }
    storage.spiral_growth_in_progress = true
    DeferredGenerate.queue(grow_action_token, job, #wall_chunks + 5)
end



local function try_grow_spiral()
    local surface = get_surface()
    if not surface or storage.spiral_growth_in_progress then
        return
    end
    if storage.spiral_troopers_level and storage.spiral_troopers_level >= max_ring_level then
        return
    end
    local fx, fy = get_furthest_chunk()
    local furthest = math.min(fx, fy)
    local current_radius = 0
    if storage.spiral_troopers_level then
        current_radius = ring_base_radius + (storage.spiral_troopers_level - 1) * ring_spacing
    end
    if furthest <= current_radius then
        return
    end
    start_grow_job()
end

local function on_chunk_generated(event)
    local surface = get_surface()
    if not surface or event.surface.name ~= surface.name then
        return
    end

    if not storage.spiral_troopers_spawn_ores then
        if get_furthest_chunk() > 7 then
            draw_mixed_ore_circle({ x = -16, y = 16 }, 'copper-ore', surface, 11, 9900)
            draw_mixed_ore_circle({ x = 6, y = 16 }, 'coal', surface, 11, 9900)
            draw_mixed_ore_circle({ x = 50, y = 16 }, 'iron-ore', surface, 11, 9900)
            draw_mixed_ore_circle({ x = 29, y = 16 }, 'stone', surface, 11, 9900)
            map_functions.draw_noise_tile_circle({ x = -20, y = -16 }, 'water', surface, 9)
            local radius = 256
            game.forces.player.chart(surface, { { x = -1 * radius, y = -1 * radius }, { x = radius, y = radius } })
            storage.spiral_troopers_spawn_ores = true
            place_oil_field(surface, { x = -20, y = -16 }, 30000)
        end
    end

    local spawner_density_modifier = 100
    local worm_density_modifier = 1000
    local worm_level = 5
    if storage.spiral_troopers_level then
        spawner_density_modifier = spawner_density_modifier - (storage.spiral_troopers_level * 10)
        worm_density_modifier = worm_density_modifier - (storage.spiral_troopers_level * 50)
        worm_level = storage.spiral_troopers_level / 40
    end
    if spawner_density_modifier < 10 then
        spawner_density_modifier = 10
    end
    if worm_density_modifier < 5 then
        worm_density_modifier = 5
    end
    local worm_index = math.ceil(worm_level * 10)
    if worm_index < 1 then
        worm_index = 1
    end
    if worm_index > 10 then
        worm_index = 10
    end
    local worm_names = worm_raffle[worm_index]
    local left_top = event.area.left_top
    local outer_chunk = left_top.x > 80 or left_top.x < -80 or left_top.y > 80 or left_top.y < -80
    local mixed_ores_paint = storage.mixed_ores_paint

    for x = 0, 31 do
        for y = 0, 31 do
            local pos = { x = left_top.x + x, y = left_top.y + y }
            if outer_chunk then
                if math.random(1, spawner_density_modifier) == 1 then
                    if surface.can_place_entity({ name = 'spitter-spawner', position = pos }) then
                        if math.random(1, 3) == 1 then
                            surface.create_entity({ name = 'spitter-spawner', position = pos })
                        else
                            surface.create_entity({ name = 'biter-spawner', position = pos })
                        end
                    end
                end
                if math.random(1, worm_density_modifier) == 1 then
                    local name = worm_names[math.random(1, #worm_names)]
                    if surface.can_place_entity({ name = name, position = pos }) then
                        surface.create_entity({ name = name, position = pos })
                    end
                end
            elseif math.random(1, 10) == 1 then
                if surface.can_place_entity({ name = 'tree-03', position = pos }) then
                    surface.create_entity({ name = 'tree-03', position = pos })
                end
            end

            local ore_pos = { x = math.floor(pos.x) + 0.5, y = math.floor(pos.y) + 0.5 }
            local distance_from_center = math.sqrt(ore_pos.x * ore_pos.x + ore_pos.y * ore_pos.y)
            if distance_from_center > coal_free_spawn_radius then
                local tile = surface.get_tile(ore_pos.x, ore_pos.y)
                if tile.valid and not coal_floor_skip_tiles[tile.name] then
                    if surface.count_entities_filtered({ position = ore_pos, type = 'resource', limit = 1 }) == 0 then
                        local amount = coal_base_amount + math.floor((distance_from_center - coal_free_spawn_radius) * coal_distance_step)
                        local ore_name = 'coal'
                        if mixed_ores_paint then
                            ore_name = pick_weighted_ore(mixed_ores)
                        end
                        surface.create_entity({ name = ore_name, position = ore_pos, amount = amount })
                    end
                end
            end
        end
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if not storage.map_init_done then
        local map_gen_settings = get_map_gen_settings()
        local surface = game.create_surface('spiral_troopers', map_gen_settings)
        storage.spiral_surface_name = surface.name
        storage.spiral_map_id = (storage.spiral_map_id or 0) + 1
        SpawnersContainBiters.add_surface(surface.name)
        apply_force_settings(surface)
        storage.map_init_done = true
    end
    local surface = get_surface()
    local surface_name = get_surface_name()
    if player.online_time < 5 and surface.is_chunk_generated({ 0, 0 }) then
        player.teleport(surface.find_non_colliding_position('character', { 0, 0 }, 2, 1), surface_name)
    else
        if player.online_time < 5 then
            player.teleport({ 0, 0 }, surface_name)
        end
    end
    if player.online_time < 10 then
        player.insert { name = 'iron-plate', count = 32 }
        player.insert { name = 'pistol', count = 1 }
        player.insert { name = 'firearm-magazine', count = 64 }
    end

    if player.physical_surface.name ~= surface.name then
        player.teleport(surface.find_non_colliding_position('character', { 0, 0 }, 2, 1), surface.name)
    end
end

local function on_player_rotated_entity(event)
    if event.entity.name == 'burner-inserter' and event.entity.destructible == false then
        get_surface().create_entity { name = 'big-explosion', position = event.entity.position }
        event.entity.destroy()
        level_finished()
    end
end

local disabled_entities =
{
    ['gun-turret'] = true,
    ['laser-turret'] = true,
    ['flamethrower-turret'] = true
}

local function turret_enemy_area(position)
    return
    {
        left_top = { x = position.x - turret_enemy_check_radius, y = position.y - turret_enemy_check_radius },
        right_bottom = { x = position.x + turret_enemy_check_radius, y = position.y + turret_enemy_check_radius }
    }
end

local function track_disabled_turret(entity)
    if not storage.spiral_disabled_turrets then
        storage.spiral_disabled_turrets = {}
    end
    storage.spiral_disabled_turrets[entity.unit_number] =
    {
        entity = entity,
        enemies_clear_tick = nil
    }
end

local function check_disabled_turrets()
    local turrets = storage.spiral_disabled_turrets
    if not turrets then
        return
    end
    for unit_number, data in pairs(turrets) do
        local entity = data.entity
        if not entity or not entity.valid then
            turrets[unit_number] = nil
        else
            local enemy_count = entity.surface.count_entities_filtered({ force = 'enemy', area = turret_enemy_area(entity.position), limit = 1 })
            if enemy_count > 0 then
                data.enemies_clear_tick = nil
            elseif not data.enemies_clear_tick then
                data.enemies_clear_tick = game.tick
            elseif game.tick - data.enemies_clear_tick >= turret_reactivate_delay then
                entity.disabled_by_script = false
                turrets[unit_number] = nil
            end
        end
    end
end

local function on_built_entity(event)
    if enforce_banned_entities(event.entity, event) then
        return
    end
    if enforce_ore_build_restriction(event.entity, event) then
        return
    end
    local entity = event.entity
    if not entity or not entity.valid or not disabled_entities[entity.name] then
        return
    end
    local enemy_count = entity.surface.count_entities_filtered({ force = 'enemy', area = turret_enemy_area(entity.position), limit = 1 })
    if enemy_count > 0 then
        entity.disabled_by_script = true
        track_disabled_turret(entity)
        if event.player_index then
            local player = game.players[event.player_index]
            if player and player.valid then
                player.print('The turret seems to be malfunctioning near those creatures. It will reactivate shortly after they leave.', { color = { r = 0.75, g = 0.0, b = 0.0 } })
            end
        end
    end
end

local function on_robot_built_entity(event)
    on_built_entity(event)
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end
    if entity.name == 'biter-spawner' or entity.name == 'spitter-spawner' then
        if math.random(1, 50) == 1 then
            local amount = 100000 * (1 + (game.forces.enemy.get_evolution_factor(entity.surface.index) * 20))
            entity.surface.create_entity({ name = 'crude-oil', position = entity.position, amount = amount })
        end
    end
    if entity_drop_amount[entity.name] then
        if game.forces.enemy.get_evolution_factor(entity.surface.index) < 0.5 then
            local amount =
                math.ceil(math.random(entity_drop_amount[entity.name].low, entity_drop_amount[entity.name].high) * (0.5 - game.forces.enemy.get_evolution_factor(entity.surface.index)) * 2)
            entity.surface.spill_item_stack({ position = entity.position, stack = { name = ore_spill_raffle[math.random(1, #ore_spill_raffle)], count = amount }, enable_looted = true })
        end
    end
end

local function on_player_built_tile(event)
    local placed_tiles = event.tiles
    for _, t in pairs(placed_tiles) do
        if t.old_tile.name == 'water-green' then
            local tiles = {}
            table.insert(tiles, { name = 'water-green', position = t.position })
            get_surface().set_tiles(tiles, true)
        end
    end
end

local function on_tick()
    if not storage.spiral_troopers_beaten_level then
        return
    end
    if not storage.checkpoint_barriers[storage.spiral_troopers_beaten_level] then
        return
    end
    if game.tick % 2 == 1 then
        if storage.checkpoint_barriers[storage.spiral_troopers_beaten_level][#storage.checkpoint_barriers[storage.spiral_troopers_beaten_level]].valid == true then
            local pos = storage.checkpoint_barriers[storage.spiral_troopers_beaten_level][#storage.checkpoint_barriers[storage.spiral_troopers_beaten_level]].position
            local surface = get_surface()
            surface.create_entity { name = kabooms[math.random(1, #kabooms)], position = pos }
            local a =
            {
                left_top = { x = pos.x - 10, y = pos.y - 10 },
                right_bottom = { x = pos.x + 10, y = pos.y + 10 }
            }
            local greenwater = surface.find_tiles_filtered({ name = 'water-green', area = a })
            if greenwater then
                if greenwater[1] then
                    local tiles = {}
                    for _, tile in pairs(greenwater) do
                        table.insert(tiles, { name = 'grass-1', position = tile.position })
                    end
                    surface.set_tiles(tiles, true)
                end
            end
            storage.checkpoint_barriers[storage.spiral_troopers_beaten_level][#storage.checkpoint_barriers[storage.spiral_troopers_beaten_level]].destroy()
        end
        storage.checkpoint_barriers[storage.spiral_troopers_beaten_level][#storage.checkpoint_barriers[storage.spiral_troopers_beaten_level]] = nil
        if #storage.checkpoint_barriers[storage.spiral_troopers_beaten_level] == 0 then
            storage.checkpoint_barriers[storage.spiral_troopers_beaten_level] = nil
        end
    end
end

local function area_has_player_buildings(surface)
    local entities = surface.find_entities_filtered({ area = loss_check_area, force = 'player' })
    for _, entity in pairs(entities) do
        if entity.valid and entity.type ~= 'character' and entity.type ~= 'simple-entity' and entity.destructible then
            return true
        end
    end
    return false
end

local function area_has_enemies(surface)
    return surface.count_entities_filtered({ area = loss_check_area, force = 'enemy', limit = 1 }) > 0
end

local function clear_spiral_storage()
    storage.spiral_troopers_level = nil
    storage.spiral_troopers_beaten_level = nil
    storage.checkpoint_barriers = nil
    storage.spiral_growth_in_progress = false
    storage.spiral_troopers_spawn_ores = nil
    storage.spiral_base_established = nil
    storage.spiral_reset_poll_id = nil
    storage.spiral_reset_poll_cooldown = nil
    storage.spiral_disabled_turrets = nil
    storage.map_init_done = nil

    local force = game.forces.player
    force.technologies['spidertron'].enabled = false
    force.technologies['spidertron'].researched = false
end

local function reset_map()
    local old_surface = get_surface()
    if not old_surface or not old_surface.valid then
        return
    end
    clear_spiral_storage()
    Poll.reset()
    storage.spiral_map_id = (storage.spiral_map_id or 0) + 1
    local new_surface = SoftReset.soft_reset_map(old_surface, get_map_gen_settings(), starting_items)
    storage.spiral_surface_name = new_surface.name
    SpawnersContainBiters.add_surface(new_surface.name)
    apply_force_settings(new_surface)
    storage.map_init_done = true
end

local function start_reset_poll()
    if storage.spiral_reset_poll_id then
        return false
    end
    if storage.spiral_reset_poll_cooldown and game.tick < storage.spiral_reset_poll_cooldown then
        return false
    end
    local ok, id = Poll.poll(
        {
            question = 'Soft-reset the map?',
            answers = { 'Yes, reset!', 'No, keep defending!' },
            duration = reset_poll_duration,
            custom_data = { spiral_reset_poll = true }
        }
    )
    if ok then
        storage.spiral_reset_poll_id = id
        return true
    end
    return false
end

local function check_loss_condition()
    local surface = get_surface()
    if not surface or not surface.valid then
        return
    end
    if not storage.map_init_done then
        return
    end
    if not storage.spiral_troopers_beaten_level or storage.spiral_troopers_beaten_level <= 0 then
        return
    end
    if storage.spiral_reset_poll_id then
        return
    end
    if storage.spiral_reset_poll_cooldown and game.tick < storage.spiral_reset_poll_cooldown then
        return
    end
    local has_buildings = area_has_player_buildings(surface)
    if has_buildings then
        storage.spiral_base_established = true
        return
    end
    if not storage.spiral_base_established then
        return
    end

    if not area_has_enemies(surface) then
        return
    end

    start_reset_poll()
end

local function command_vote_to_reset(player)
    local warn = Color.warning
    local ok_color = Color.success
    local surface = get_surface()
    local failed = false

    if not surface or not surface.valid then
        player.print('Surface is not valid. Please contact a moderator.', { color = warn })
        return false
    end

    if not storage.map_init_done then
        player.print('Map is not initialized yet. Please contact a moderator.', { color = warn })
        failed = true
    end

    local beaten = storage.spiral_troopers_beaten_level or 0
    if beaten <= 0 then
        player.print('Need at least one beaten checkpoint level (current: ' .. beaten .. ').', { color = warn })
        failed = true
    end

    if storage.spiral_reset_poll_id then
        player.print('A reset poll is already running.', { color = warn })
        failed = true
    end

    if storage.spiral_reset_poll_cooldown and game.tick < storage.spiral_reset_poll_cooldown then
        local remaining_minutes = math.ceil((storage.spiral_reset_poll_cooldown - game.tick) / 3600)
        player.print('Reset poll is on cooldown (' .. remaining_minutes .. ' minute(s) remaining).', { color = warn })
        failed = true
    end

    if failed then
        player.print('Reset poll conditions not met.', { color = warn })
        return false
    end

    if start_reset_poll() then
        player.print('Reset poll started.', { color = ok_color })
        return true
    end

    player.print('Failed to start reset poll.', { color = warn })
    return false
end

Commands.new('vote_to_reset', 'Check Spiral Troopers loss conditions and start a soft-reset poll if met.')
    :callback(
        function (player)
            return command_vote_to_reset(player)
        end
    )

local function on_poll_complete(event)
    if not event.custom_data or not event.custom_data.spiral_reset_poll then
        return
    end
    storage.spiral_reset_poll_id = nil
    local winning_answer = event.winning_answer
    if winning_answer and winning_answer.text == 'Yes, reset!' then
        game.print('Spiral Troopers: reset vote passed. Soft-resetting map...', { color = { r = 0.98, g = 0.66, b = 0.22 } })
        reset_map()
        return
    end
    storage.spiral_reset_poll_cooldown = game.tick + reset_poll_cooldown
    game.print('Spiral Troopers: reset vote failed. Keep defending whatever you have left!', { color = { r = 0.98, g = 0.66, b = 0.22 } })
    game.print('Next reset vote in ' .. math.floor(reset_poll_cooldown / 60 / 60) .. ' hours.', { r = 0.98, g = 0.66, b = 0.22 })
end

Event.on_init(
    function ()
        storage.mixed_ores_paint = true
        game.forces.player.lock_space_location('nauvis')
    end
)

Event.add(defines.events.on_tick, on_tick)
Event.on_nth_tick(30, try_grow_spiral)
Event.on_nth_tick(60, check_disabled_turrets)
Event.on_nth_tick(300, check_loss_condition)
Event.add(defines.events.on_player_built_tile, on_player_built_tile)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_rotated_entity, on_player_rotated_entity)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(ServerCommands.events.on_poll_complete, on_poll_complete)
