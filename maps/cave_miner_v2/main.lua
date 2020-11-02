local Constants = require 'maps.cave_miner_v2.constants'
local Event = require 'utils.event'
local Explosives = require "modules.explosives_2"
local Autostash = require "modules.autostash"
local Functions = require 'maps.cave_miner_v2.functions'
local Global = require 'utils.global'
local Market = require 'maps.cave_miner_v2.market'
local Server = require 'utils.server'
local Terrain = require 'maps.cave_miner_v2.terrain'
local Map_info = require "modules.map_info"

require "modules.satellite_score"
require "modules.hunger"
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
	--print mining chances
	--for k, v in pairs(table.get_random_weighted_chances(Functions.mining_events)) do game.print(Functions.mining_events[k][3] .. " | " .. math.round(v, 4) .. " | 1 in " .. math_floor(1 / v)) end

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
	
	if player.online_time > 0 then return end
	for name, count in pairs(Constants.starting_items) do
		player.insert({name = name, count = count})
	end
end

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	if not player.character then return end
	if not player.character.valid then return end
	Functions.reveal(cave_miner, game.surfaces.nauvis, game.surfaces.cave_miner_source, {x = math_floor(player.position.x), y = math_floor(player.position.y)}, 11)
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
		local f = table.get_random_weighted(Functions.mining_events)
		f(cave_miner, entity, event.player_index)
	end
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity then return end
	if not entity.valid then return end
	if Functions.on_entity_died[entity.type] then
		Functions.on_entity_died[entity.type](cave_miner, entity)
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
	surface.min_brightness = 0.08
	surface.brightness_visual_weights = {0.92, 0.92, 0.92}
	surface.daytime = 0.43
	surface.freeze_daytime = true
	surface.solar_power_multiplier = 5

	cave_miner.last_reroll_player_name = ""
	cave_miner.reveal_queue = {}
	cave_miner.darkness = {}
	cave_miner.rocks_broken = 0
	cave_miner.pickaxe_tier = 1
	
	local force = game.forces.player
	Functions.set_mining_speed(cave_miner, force)	
	force.technologies["steel-axe"].enabled = false
	force.technologies["landfill"].enabled = false
	force.technologies["spidertron"].enabled = false
	force.technologies["artillery"].enabled = false
	force.technologies["artillery-shell-range-1"].enabled = false
	force.technologies["artillery-shell-speed-1"].enabled = false
	force.character_inventory_slots_bonus = 0
	
	cave_miner.gamestate = "spawn_players"
end

local function spawn_players(cave_miner)
	local tick = game.ticks_played
	if tick % 60 ~= 0 then return end
	Functions.reveal(cave_miner, game.surfaces.nauvis, game.surfaces.cave_miner_source, {x = 0, y = 0}, 8)
	Market.spawn(cave_miner)
	for _, player in pairs(game.connected_players) do
		Functions.spawn_player(player)
	end
	cave_miner.gamestate = "game_in_progress"
end

local game_tasks = {
	[15] = Functions.update_top_gui,
	[30] = function()
		local reveal = cave_miner.reveal_queue[1]
		if not reveal then return end
		local brush_size = 3
		if Constants.reveal_chain_brush_sizes[reveal[1]] then brush_size = Constants.reveal_chain_brush_sizes[reveal[1]] end
		Functions.reveal(
			cave_miner,
			game.surfaces.nauvis,
			game.surfaces.cave_miner_source,
			{x = reveal[2], y = reveal[3]},
			brush_size
		)	
		table.remove(cave_miner.reveal_queue, 1)
	end,
	[45] = Functions.darkness,
}

local function game_in_progress(cave_miner)
	local tick = game.ticks_played % 60		
	if not game_tasks[tick] then return end
	game_tasks[tick](cave_miner)
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
	cave_miner.reveal_queue = {}
	
	global.rocks_yield_ore_maximum_amount = 256
	global.rocks_yield_ore_base_amount = 16
	global.rocks_yield_ore_distance_modifier = 0.0128
	
	Explosives.set_destructible_tile("out-of-map", 5000)
	Explosives.set_destructible_tile("water", 2000)
	Explosives.set_destructible_tile("water-green", 2000)
	Explosives.set_destructible_tile("deepwater-green", 2500)
	Explosives.set_destructible_tile("deepwater", 2500)
	Explosives.set_destructible_tile("water-shallow", 1500)
	Explosives.set_destructible_tile("water-mud", 1500)
	
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.enemy_evolution.time_factor = 0
	
	global.rocks_yield_ore_veins.amount_modifier = 0.20
	global.rocks_yield_ore_veins.chance = 1024
	
	local T = Map_info.Pop_info()
	T.localised_category = "cave_miner"
	T.main_caption_color = {r = 200, g = 100, b = 0}
	T.sub_caption_color = {r = 0, g = 175, b = 175}
	
	Autostash.insert_into_furnace(true)
	Autostash.insert_into_wagon(true)
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

require "maps.cave_miner_v2.rocks_yield_ore" 