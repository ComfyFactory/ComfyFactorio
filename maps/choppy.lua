--choppy-- mewmew made this --

require "maps.modules.dynamic_landfill"
require "maps.modules.satellite_score"
require "maps.modules.spawners_contain_biters"
require "maps.choppy_map_intro"

local unearthing_worm = require "functions.unearthing_worm"
local unearthing_biters = require "functions.unearthing_biters"
local tick_tack_trap = require "functions.tick_tack_trap"
local create_entity_chain = require "functions.create_entity_chain"
local create_tile_chain = require "functions.create_tile_chain"

local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random
local map_functions = require "maps.tools.map_functions"

local disabled_for_deconstruction = {
		["fish"] = true,
		["rock-huge"] = true,
		["rock-big"] = true,
		["sand-rock-big"] = true,
		["mineable-wreckage"] = true
	}

local tile_replacements = {
	["dirt-1"] = "grass-1",
	["dirt-2"] = "grass-2",
	["dirt-3"] = "grass-3",
	["dirt-4"] = "grass-4",	
	["sand-1"] = "grass-1",
	["sand-2"] = "grass-2",
	["sand-3"] = "grass-3",
	["dry-dirt"] = "grass-2",	
	["red-desert-0"] = "grass-1",
	["red-desert-1"] = "grass-2",
	["red-desert-2"] = "grass-3",
	["red-desert-3"] = "grass-4",
}
	
local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000
	seed = seed + noise_seed_add
	if name == 1 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.006, pos.y * 0.006, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		noise[3] = simplex_noise(pos.x * 0.05, pos.y * 0.05, seed)
		seed = seed + noise_seed_add
		noise[4] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		local noise = noise[1] + noise[2] * 0.25 + noise[3] * 0.15 + noise[4] * 0.05		
		return noise
	end	
end

local function process_entity(e)
	if not e.valid then return end
	if e.name == "crude-oil" then return end
	if e.type == "tree" then
		e.destroy()
		return
	end
	if e.type == "resource" then
		e.surface.create_entity({name = "rock-big", position = e.position})
		e.destroy()
		return
	end
	if e.type == "unit-spawner" then			
		for _, entity in pairs (e.surface.find_entities_filtered({area = {{e.position.x - 4, e.position.y - 4},{e.position.x + 4, e.position.y + 4}}, force = "neutral"})) do
			if entity.valid then entity.destroy() end
		end
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
	
	for x = 0.5, 31.5, 1 do
		for y = 0.5, 31.5, 1 do
			local tile_to_insert = false
			local pos = {x = left_top.x + x, y = left_top.y + y}
											
			local tile = surface.get_tile(pos)
			if tile_replacements[tile.name] then
				table_insert(tiles, {name = tile_replacements[tile.name], position = pos})
			end
			
			if not tile.collides_with("player-layer") then
				if surface.can_place_entity({name = "tree-01", position = pos}) then
					local noise = get_noise(1, pos)
					if noise > 0.08 then
						if noise > 0.6 then
							if math_random(1,3) ~= 1 then surface.create_entity({name = "tree-08-brown", position = pos}) end
						else
							if math_random(1,3) ~= 1 then surface.create_entity({name = "tree-01", position = pos}) end
						end
					end
					
					if noise < -0.08 then				
						if noise < -0.6 then
							if math_random(1,3) ~= 1 then surface.create_entity({name = "tree-04", position = pos}) end
						else
							if math_random(1,3) ~= 1 then surface.create_entity({name = "tree-02-red", position = pos}) end
						end									
					end
				end
			end
			
		end
	end
	surface.set_tiles(tiles, true)	
	
	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
			decorative_names[#decorative_names+1] = k
		end
	end
	surface.regenerate_decorative(decorative_names, {position})
	
	if global.spawn_generated then return end
	if left_top.x < 96 then return end	 
	
	for _, e in pairs (surface.find_entities_filtered({area = {{-50, -50},{50, 50}}})) do
		local distance_to_center = math.sqrt(e.position.x^2 + e.position.y^2)
		if e.valid then
			if distance_to_center < 8 and e.type == "tree" and math_random(1,5) ~= 1 then e.destroy() end
		end		
	end
	global.spawn_generated = true		
end
	
local function on_marked_for_deconstruction(event)	
	if disabled_for_deconstruction[event.entity.name] then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
	if event.entity.type == "tree" then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]	
	if player.online_time == 0 then
		player.insert({name = "pistol", count = 1})
		player.insert({name = "firearm-magazine", count = 8})
	end	
	
	if global.map_init_done then return end
	
	game.map_settings.pollution.ageing = 0
	--game.map_settings.pollution.min_pollution_to_damage_trees = 1000000
	--game.map_settings.pollution.pollution_per_tree_damage = 0
	--game.map_settings.pollution.pollution_restored_per_tree_damage = 0

	game.surfaces["nauvis"].ticks_per_day = game.surfaces["nauvis"].ticks_per_day * 2
	
	global.map_init_done = true
end

local tree_yield = {
	["tree-01"] = "iron-ore",
	["tree-02-red"] = "copper-ore",
	["tree-04"] = "coal",
	["tree-08-brown"] = "stone",
	["rock-big"] = "uranium-ore"
}

local function get_amount(entity)
	local distance_to_center = math.sqrt(entity.position.x^2 + entity.position.y^2)
	local amount = 35 + (distance_to_center * 0.25)
	if amount > 500 then amount = 500 end
	amount = math.random(math.ceil(amount * 0.5), math.ceil(amount * 1.5))	
	return amount
end

local function trap(entity)							
	if math_random(1,1024) == 1 then tick_tack_trap(entity.surface, entity.position) return end
	if math_random(1,256) == 1 then unearthing_worm(entity.surface, entity.position) end
	if math_random(1,128) == 1 then unearthing_biters(entity.surface, entity.position, math_random(4,8)) end	
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	
	if entity.type == "tree" then 	
		trap(entity)
	end
		
	if tree_yield[entity.name] then		
		if event.buffer then event.buffer.clear() end			
		if not event.player_index then return end
		local amount = get_amount(entity)
		local second_item_amount = math_random(2,5)
		local second_item = "wood"
		
		if entity.type == "simple-entity" then
			amount = amount * 2
			second_item_amount = math_random(8,16)
			second_item = "stone"
		end
		
		entity.surface.create_entity({
			name = "flying-text",
			position = entity.position,
			text = "+" .. amount .. " [item=" .. tree_yield[entity.name] .. "] +" .. second_item_amount .. " [item=" .. second_item .. "]",
			color = {r=0.8,g=0.8,b=0.8}})	
		
		
		local player = game.players[event.player_index]
		
		local inserted_count = player.insert({name = tree_yield[entity.name], count = amount})				
		amount = amount - inserted_count
		if amount > 0 then
			entity.surface.spill_item_stack(entity.position,{name = tree_yield[entity.name], count = amount}, true)
		end
				
		local inserted_count = player.insert({name = second_item, count = second_item_amount})				
		second_item_amount = second_item_amount - inserted_count
		if second_item_amount > 0 then
			entity.surface.spill_item_stack(entity.position,{name = second_item, count = second_item_amount}, true)
		end
	end					
end

local function on_research_finished(event)
	event.research.force.character_inventory_slots_bonus = game.forces.player.mining_drill_productivity_bonus * 500
	if not event.research.force.technologies["steel-axe"].researched then return end
	event.research.force.manual_mining_speed_modifier = 1 + game.forces.player.mining_drill_productivity_bonus * 2
end

local function on_entity_died(event)
	on_player_mined_entity(event)
	
	if not event.entity.valid then return end
	if event.entity.type == "tree" then 
		for _, entity in pairs (event.entity.surface.find_entities_filtered({area = {{event.entity.position.x - 4, event.entity.position.y - 4},{event.entity.position.x + 4, event.entity.position.y + 4}}, name = "fire-flame-on-tree"})) do
			if entity.valid then entity.destroy() end
		end
	end		
end
	
event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_chunk_generated, on_chunk_generated)