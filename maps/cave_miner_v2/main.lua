local Constants = require 'maps.cave_miner_v2.constants'
local Event = require 'utils.event'
local Explosives = require "modules.explosives"
local Functions = require 'maps.cave_miner_v2.functions'
local Global = require 'utils.global'
local Market = require 'maps.cave_miner_v2.market'
local Server = require 'utils.server'
local Terrain = require 'maps.cave_miner_v2.terrain'

require 'modules.no_deconstruction_of_neutral_entities'
require "modules.rocks_broken_paint_tiles"
require "modules.rocks_heal_over_time"
require "modules.rocks_yield_ore_veins"

local math_floor = math.floor

local cave_miner = {}
Global.register(
    cave_miner,
    function(tbl)
        cave_miner = tbl
    end
)

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	
	Functions.create_top_gui(player)
	Functions.update_top_gui(cave_miner)
	
	local tick = game.ticks_played
	if tick == 0 then
		if player.character and player.character.valid then
			player.character.destroy()
			return
		end
	end
	
	for name, count in pairs(Constants.starting_items) do
		player.insert({name = name, count = count})
	end
end

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	if not player.character then return end
	if not player.character.valid then return end
	Terrain.reveal(game.surfaces.nauvis, game.surfaces.cave_miner_source, {x = math_floor(player.position.x), y = math_floor(player.position.y)}, 8)
end

local function on_chunk_generated(event)
	local surface = event.surface
	if surface.index == 1 then
		Terrain.out_of_map(event)
		return
	end
	if surface.name == "cave_miner_source" then
		Terrain.generate_cave(event)
		return
	end
end

local function on_market_item_purchased(event)
	Market.offer_bought(event, cave_miner)
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity then return end
	if not entity.valid then return end
	local surface = entity.surface
	local position = entity.position	
	if entity.type == "simple-entity" then
		cave_miner.rocks_broken = cave_miner.rocks_broken + 1
		if math.random(1, 16) == 1 then
			Functions.spawn_random_biter(surface, position, 1)
		end
	end
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity then return end
	if not entity.valid then return end
	local surface = entity.surface
	local position = entity.position	
	if entity.type == "simple-entity" then
		cave_miner.rocks_broken = cave_miner.rocks_broken + 1
		if math.random(1, 2) == 1 then
			Functions.spawn_random_biter(surface, position, 1)
		end
	end
end

local function on_entity_spawned(event)
	local spawner = event.spawner
	local unit = event.entity
	local surface = spawner.surface
	Functions.spawn_random_biter(surface, unit.position, 1)
	unit.destroy()
end

local function init(cave_miner)
	local tick = game.ticks_played
	if tick % 60 ~= 0 then return end
	Terrain.roll_source_surface()
	
	local surface = game.surfaces.nauvis
	surface.min_brightness = 0.01
	surface.brightness_visual_weights = {0.99, 0.99, 0.99}
	surface.daytime = 0.42
	surface.freeze_daytime = true
	surface.solar_power_multiplier = 999
	
	cave_miner.rocks_broken = 0
	cave_miner.pickaxe_tier = 1
	
	local force = game.forces.player
	Functions.set_mining_speed(cave_miner, force)	
	force.technologies["steel-axe"].enabled = false
	force.technologies["landfill"].enabled = false
	force.technologies["spidertron"].enabled = false
	force.technologies["artillery"].enabled = false
	
	cave_miner.gamestate = "spawn_players"
end

local function spawn_players(cave_miner)
	local tick = game.ticks_played
	if tick % 60 ~= 0 then return end
	Terrain.reveal(game.surfaces.nauvis, game.surfaces.cave_miner_source, {x = 0, y = 0}, 8)
	Market.spawn(cave_miner)
	for _, player in pairs(game.connected_players) do
		Functions.spawn_player(player)
	end
	cave_miner.gamestate = "game_in_progress"
end

local function game_in_progress(cave_miner)
	local tick = game.ticks_played
	if tick % 60 ~= 0 then return end
	Functions.update_top_gui(cave_miner)
end

local gamestates = {
	["init"] = init,
	["spawn_players"] = spawn_players,
	["game_in_progress"] = game_in_progress,
}

local function on_tick()
	gamestates[cave_miner.gamestate](cave_miner)	
end

local function on_init()
	cave_miner.reset_counter = 0
	cave_miner.gamestate = "init"
	cave_miner.mining_speed_bonus = 100
	cave_miner.pickaxe_tier = 1
	cave_miner.rocks_broken = 0
	
	global.rocks_yield_ore_maximum_amount = 256
	global.rocks_yield_ore_base_amount = 32
	global.rocks_yield_ore_distance_modifier = 0.01
	
	Explosives.set_destructible_tile("out-of-map", 1500)
	Explosives.set_destructible_tile("water", 1000)
	Explosives.set_destructible_tile("water-green", 1000)
	Explosives.set_destructible_tile("deepwater-green", 1000)
	Explosives.set_destructible_tile("deepwater", 1000)
	Explosives.set_destructible_tile("water-shallow", 1000)
	Explosives.set_destructible_tile("water-mud", 1000)
	
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.enemy_evolution.time_factor = 0
end

Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_entity_spawned, on_entity_spawned)
Event.add(defines.events.on_entity_died, on_entity_died)

require "modules.rocks_yield_ore" 