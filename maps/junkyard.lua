--junkyard-- mewmew made this --

require "maps.modules.dynamic_landfill"
require "maps.modules.satellite_score"
require "maps.modules.spawners_contain_biters"
require "maps.modules.splice_double"
require "maps.modules.biter_player_count_difficulty"
require "maps.modules.mineable_wreckage_yields_scrap"

local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random
local map_functions = require "maps.tools.map_functions"

local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000
	seed = seed + noise_seed_add
	if name == 1 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.005, pos.y * 0.005, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		noise[3] = simplex_noise(pos.x * 0.05, pos.y * 0.05, seed)
		seed = seed + noise_seed_add
		noise[4] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		local noise = noise[1] + noise[2] * 0.3 + noise[3] * 0.2 + noise[4] * 0.1
		--noise = noise * 0.5
		return noise
	end	
end

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	
	if not global.map_init_done then
		game.surfaces["nauvis"].ticks_per_day = game.surfaces["nauvis"].ticks_per_day * 2		
		game.surfaces["nauvis"].freeze_daytime = true
		global.map_init_done = true						
	end	
	
	if player.online_time == 0 then				
		--player.insert{name = 'iron-plate', count = 32}
		--player.insert{name = 'iron-gear-wheel', count = 16}
	end	
end

local tile_replacements = {
	["grass-1"] = "dirt-7",
	["grass-2"] = "dirt-6",
	["grass-3"] = "dirt-5",
	["grass-4"] = "dirt-4"	,
	["water"] = "water-green",
	["deepwater"] = "deepwater-green",	
	["sand-1"] = "dirt-7",
	["sand-2"] = "dirt-6",
	["sand-3"] = "dirt-5"	
}

local entity_replacements = {
	["tree-01"] = "dead-dry-hairy-tree",
	["tree-02"] = "tree-06-brown",
	["tree-03"] = "dead-grey-trunk",
	["tree-04"] = "dry-hairy-tree",	
	["tree-05"] = "dry-tree",	
	["tree-06"] = "tree-06-brown",	
	["tree-07"] = "dry-tree",	
	["tree-08"] = "tree-08-brown",	
	["tree-09"] = "tree-06-brown",
	["tree-02-red"] = "dry-tree",	
	--["tree-06-brown"] = "dirt",	
	--["tree-08-brown"] = "dirt",	
	["tree-09-brown"] = "tree-06-brown",	
	["tree-09-red"] = "tree-06-brown",
	["iron-ore"] = "mineable-wreckage",
	["copper-ore"] = "mineable-wreckage",
	["coal"] = "mineable-wreckage",
	["stone"] = "mineable-wreckage"
}

local wrecks = {"big-ship-wreck-1", "big-ship-wreck-2", "big-ship-wreck-3"}
local function create_shipwreck(surface, position)
	local raffle = {}
	local loot = {						
		
		{{name = "iron-gear-wheel", count = math_random(80,100)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "copper-cable", count = math_random(100,200)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "engine-unit", count = math_random(16,32)}, weight = 2, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "electric-engine-unit", count = math_random(16,32)}, weight = 2, evolution_min = 0.4, evolution_max = 0.8},
		{{name = "battery", count = math_random(100,200)}, weight = 2, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "advanced-circuit", count = math_random(100,200)}, weight = 3, evolution_min = 0.4, evolution_max = 1},
		{{name = "electronic-circuit", count = math_random(100,200)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},
		{{name = "processing-unit", count = math_random(100,200)}, weight = 3, evolution_min = 0.7, evolution_max = 1},
		{{name = "explosives", count = math_random(25,50)}, weight = 1, evolution_min = 0.2, evolution_max = 0.6},
		{{name = "lubricant-barrel", count = math_random(4,10)}, weight = 1, evolution_min = 0.3, evolution_max = 0.5},
		{{name = "rocket-fuel", count = math_random(4,10)}, weight = 2, evolution_min = 0.3, evolution_max = 0.7},
		{{name = "computer", count = 1}, weight = 1, evolution_min = 0.2, evolution_max = 1},
		{{name = "steel-plate", count = math_random(50,100)}, weight = 2, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "nuclear-fuel", count = 1}, weight = 2, evolution_min = 0.7, evolution_max = 1},
				
		{{name = "burner-inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.1},
		{{name = "inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},
		{{name = "long-handed-inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},		
		{{name = "fast-inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.1, evolution_max = 1},
		{{name = "filter-inserter", count = math_random(8,16)}, weight = 1, evolution_min = 0.2, evolution_max = 1},		
		{{name = "stack-filter-inserter", count = math_random(4,8)}, weight = 1, evolution_min = 0.4, evolution_max = 1},
		{{name = "stack-inserter", count = math_random(4,8)}, weight = 3, evolution_min = 0.3, evolution_max = 1},				
		{{name = "small-electric-pole", count = math_random(16,32)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "medium-electric-pole", count = math_random(8,16)}, weight = 3, evolution_min = 0.2, evolution_max = 1},		
		{{name = "wooden-chest", count = math_random(25,50)}, weight = 3, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "iron-chest", count = math_random(4,8)}, weight = 3, evolution_min = 0.1, evolution_max = 0.4},
		{{name = "steel-chest", count = math_random(4,8)}, weight = 3, evolution_min = 0.3, evolution_max = 1},		
		{{name = "small-lamp", count = math_random(8,16)}, weight = 3, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "rail", count = math_random(50,75)}, weight = 3, evolution_min = 0.1, evolution_max = 0.6},
		{{name = "assembling-machine-1", count = math_random(1,2)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "assembling-machine-2", count = math_random(1,2)}, weight = 3, evolution_min = 0.2, evolution_max = 0.8},
		{{name = "offshore-pump", count = 1}, weight = 2, evolution_min = 0.0, evolution_max = 0.1},
		{{name = "beacon", count = 1}, weight = 3, evolution_min = 0.7, evolution_max = 1},
		{{name = "boiler", count = math_random(2,4)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "steam-engine", count = math_random(2,4)}, weight = 3, evolution_min = 0.0, evolution_max = 0.5},
		{{name = "steam-turbine", count = math_random(1,2)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		--{{name = "nuclear-reactor", count = 1}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "centrifuge", count = math_random(1,2)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "heat-pipe", count = math_random(8,12)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "heat-exchanger", count = math_random(2,4)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "arithmetic-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "constant-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "decider-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "power-switch", count = math_random(2,4)}, weight = 1, evolution_min = 0.1, evolution_max = 1},		
		{{name = "programmable-speaker", count = math_random(2,4)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "green-wire", count = math_random(50,100)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "red-wire", count = math_random(50,100)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "chemical-plant", count = math_random(2,4)}, weight = 3, evolution_min = 0.3, evolution_max = 1},
		{{name = "burner-mining-drill", count = math_random(4,8)}, weight = 3, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "electric-mining-drill", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 0.6},		
		{{name = "express-transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "express-underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0.5, evolution_max = 1},		
		{{name = "express-splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "fast-transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "fast-underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "fast-splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0.2, evolution_max = 0.3},
		{{name = "transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0, evolution_max = 0.3},
		{{name = "underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0, evolution_max = 0.3},
		{{name = "splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0, evolution_max = 0.3},		
		{{name = "pipe", count = math_random(40,50)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "pipe-to-ground", count = math_random(8,16)}, weight = 1, evolution_min = 0.2, evolution_max = 0.5},
		{{name = "pumpjack", count = math_random(1,2)}, weight = 1, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "pump", count = math_random(1,4)}, weight = 1, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "steel-furnace", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "stone-furnace", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.1},		
		{{name = "radar", count = math_random(1,2)}, weight = 1, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "rail-signal", count = math_random(8,16)}, weight = 2, evolution_min = 0.2, evolution_max = 0.8},
		{{name = "rail-chain-signal", count = math_random(8,16)}, weight = 2, evolution_min = 0.2, evolution_max = 0.8},		
		{{name = "stone-wall", count = math_random(25,75)}, weight = 1, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "gate", count = math_random(4,8)}, weight = 1, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "storage-tank", count = math_random(2,4)}, weight = 3, evolution_min = 0.3, evolution_max = 0.6},
		{{name = "train-stop", count = math_random(1,2)}, weight = 1, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "express-loader", count = math_random(1,2)}, weight = 1, evolution_min = 0.5, evolution_max = 1},
		{{name = "fast-loader", count = math_random(1,2)}, weight = 1, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "loader", count = math_random(1,2)}, weight = 1, evolution_min = 0.0, evolution_max = 0.5},
		{{name = "lab", count = math_random(2,4)}, weight = 2, evolution_min = 0.0, evolution_max = 0.1}	
	}

	local distance_to_center = math.sqrt(position.x^2 + position.y^2)
	if distance_to_center < 1 then
		distance_to_center = 0.1
	else
		distance_to_center = distance_to_center / 5000
	end
	if distance_to_center > 1 then distance_to_center = 1 end
	
	for _, t in pairs (loot) do
		for x = 1, t.weight, 1 do
			if t.evolution_min <= distance_to_center and t.evolution_max >= distance_to_center then
				table.insert(raffle, t[1])
			end
		end			
	end
	local e = surface.create_entity{name = wrecks[math_random(1,#wrecks)], position = position, force = "player"}	
	for x = 1, math_random(2,3), 1 do
		local loot = raffle[math_random(1,#raffle)]
		e.insert(loot)
	end	
end

local function process_entity(e)	
	if entity_replacements[e.name] then
		e.surface.create_entity({name = entity_replacements[e.name], position = e.position})
		e.destroy()
		return
	end
	
	if e.force.name == "enemy" then			
		e.destroy()
		return
	end
end

local function on_chunk_generated(event)
	local surface = event.surface
	local left_top = event.area.left_top
	local tiles = {}
	local entities = {}	
	
	for _, e in pairs(surface.find_entities_filtered({area = event.area})) do
		process_entity(e)		
	end
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local tile_to_insert = false
			local pos = {x = left_top.x + x, y = left_top.y + y}
											
			local tile = surface.get_tile(pos)
			if tile_replacements[tile.name] then
				table_insert(tiles, {name = tile_replacements[tile.name], position = pos})
			end
			
			if not tile.collides_with("player-layer") then
				local noise = get_noise(1, pos)	
				if noise > 0.5 or noise < -0.5 then				
					if math_random(1,3) ~= 1 then
						surface.create_entity({name = "mineable-wreckage", position = pos})
					else
						if math_random(1,1024) == 1 then
							create_shipwreck(surface, pos)
						else
							if math_random(1,50000) == 1 then
								local e = surface.create_entity({name = "nuclear-reactor", position = pos, force = "enemy"})								
							end							
						end
					end							
				end	
			end
			
		end
	end
	surface.set_tiles(tiles, true)
	
	--for _, entity in pairs(entities) do
		--if surface.can_place_entity(entity) then
			--surface.create_entity(entity)
		--end
	--end
	
	--if not global.spawn_generated and left_top.x <= -64 then
		--map_functions.draw_noise_tile_circle({x = 0, y = 0}, "concrete", surface, 5)
		--map_functions.draw_smoothed_out_ore_circle({x = -32, y = -32}, "copper-ore", surface, 15, 2500)
		--map_functions.draw_smoothed_out_ore_circle({x = -32, y = 32}, "iron-ore", surface, 15, 2500)
		--map_functions.draw_smoothed_out_ore_circle({x = 32, y = 32}, "coal", surface, 15, 2500)
		--map_functions.draw_smoothed_out_ore_circle({x = 32, y = -32}, "stone", surface, 15, 2500)							
		--map_functions.draw_oil_circle({x = 0, y = 0}, "crude-oil", surface, 5, 200000)
		--global.spawn_generated = true
	--end
end

event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_chunk_generated, on_chunk_generated)