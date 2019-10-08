local math_random = math.random
local simplex_noise = require "utils.simplex_noise".d2
local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local spawner_raffle = {"biter-spawner", "biter-spawner", "biter-spawner", "spitter-spawner"}
local noises = {
	["no_rocks"] = {{modifier = 0.0033, weight = 1}, {modifier = 0.01, weight = 0.22}, {modifier = 0.05, weight = 0.05}, {modifier = 0.1, weight = 0.04}},
	["large_caves"] = {{modifier = 0.0033, weight = 1}, {modifier = 0.01, weight = 0.22}, {modifier = 0.05, weight = 0.05}, {modifier = 0.1, weight = 0.04}},	
	["small_caves"] = {{modifier = 0.008, weight = 1}, {modifier = 0.03, weight = 0.15}, {modifier = 0.25, weight = 0.05}},	
	["cave_ponds"] = {{modifier = 0.01, weight = 1}, {modifier = 0.1, weight = 0.06}},
}
local caves_start = -360

local function get_noise(name, pos, seed)
	local noise = 0
	local d = 0
	for _, n in pairs(noises[name]) do
		noise = noise + simplex_noise(pos.x * n.modifier, pos.y * n.modifier, seed) * n.weight
		d = d + n.weight
		seed = seed + 10000
	end
	noise = noise / d
	return noise
end

function get_cave_density_modifer(y)
	if y < caves_start then y = y - 2048 end
	local m = 1 + ((y) * 0.000175)
	if m < 0.10 then m = 0.10 end
	return m
end

local function process_rock_chunk_position(p, seed, tiles, entities, markets, treasure)
	local m = get_cave_density_modifer(p.y)
	
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)
	local small_caves = get_noise("small_caves", p, seed)
	
	if noise_cave_ponds < 0.08 and noise_cave_ponds > -0.08 then
		if small_caves > 0.55 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if small_caves < -0.55 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
	end	
	
	local no_rocks = get_noise("no_rocks", p, seed + 25000)
	local noise_large_caves = get_noise("large_caves", p, seed)
	
	if noise_large_caves > m * -1 and noise_large_caves < m then	
	
		--Green Water Ponds
		if noise_cave_ponds > 0.80 then
			tiles[#tiles + 1] = {name = "deepwater-green", position = p}
			if math_random(1,16) == 1 then entities[#entities + 1] = {name="fish", position=p} end
			return
		end
		
		--Market Spots 
		if noise_cave_ponds < -0.80 then
			tiles[#tiles + 1] = {name = "grass-" .. math_random(1, 3), position = p}
			if math_random(1,64) == 1 then markets[#markets + 1] = p end
			if math_random(1,32) == 1 then entities[#entities + 1] = {name = "tree-0" .. math_random(1, 9), position=p} end
			return
		end
				
		--Rock Free Zones
		if p.y < -64 + noise_cave_ponds * 10 then
			if no_rocks < 0.08 and no_rocks > -0.08 then
				if small_caves > 0.25 then
					tiles[#tiles + 1] = {name = "dirt-" .. math.floor(noise_cave_ponds * 32) % 7 + 1, position = p}
					if math_random(1,320) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = math.abs(p.y) * 500} end
					if math_random(1,128) == 1 then
						wave_defense_set_worm_raffle(math.abs(p.y) * 0.5)
						entities[#entities + 1] = {name = wave_defense_roll_worm_name(), position = p, force = "enemy"} 
					end
					if math_random(1,1024) == 1 then treasure[#treasure + 1] = p end
					return
				end
			end
		end
		
		--Main Rock Terrain
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,3) > 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, #rock_raffle)], position = p} end
		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
		return
	end
	
	if math.abs(noise_large_caves) > m * 7 then
		tiles[#tiles + 1] = {name = "water", position = p}
		if math_random(1,16) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end	
	if math.abs(noise_large_caves) > m * 6.5 then
		if math_random(1,16) == 1 then entities[#entities + 1] = {name="tree-02", position=p} end
		if math_random(1,128) == 1 then markets[#markets + 1] = p end
	end	
	if math.abs(noise_large_caves) > m * 5 then
		tiles[#tiles + 1] = {name = "grass-2", position = p}
		if math_random(1,384) == 1 then
			wave_defense_set_worm_raffle(math.abs(p.y) * 0.5)
			entities[#entities + 1] = {name = wave_defense_roll_worm_name(), position = p, force = "enemy"} 
		end
		return
	end
	if math.abs(noise_large_caves) > m * 4.75 then
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,3) > 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, #rock_raffle)], position = p} end
		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
		return
	end
	
	if small_caves > (m + 0.05) * -1 and small_caves < m - 0.05 then
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,5) > 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, #rock_raffle)], position = p} end
		if math_random(1, 512) == 1 then treasure[#treasure + 1] = p end
		return
	end			
		
	tiles[#tiles + 1] = {name = "out-of-map", position = p}
end

local function rock_chunk(surface, left_top)
	local tiles = {}
	local entities = {}
	local markets = {}
	local treasure = {}
	local seed = surface.map_gen_settings.seed
	for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_rock_chunk_position(p, seed, tiles, entities, markets, treasure)
		end
	end
	surface.set_tiles(tiles, true)

	if #markets > 0 then
		local position = markets[math_random(1, #markets)]
		if surface.count_entities_filtered{area = {{position.x - 96, position.y - 96}, {position.x + 96, position.y + 96}}, name = "market", limit = 1} == 0 then
			local market = random_type_market(surface, position, math.abs(position.y) * 0.004)
			market.destructible = false
		end
	end
	
	for _, p in pairs(treasure) do	treasure_chest(surface, p) end
	
	for _, e in pairs(entities) do
		if game.entity_prototypes[e.name].type == "simple-entity" or game.entity_prototypes[e.name].type == "turret" then
			surface.create_entity(e)
		else
			if surface.can_place_entity(e) then
				surface.create_entity(e)
			end
		end
	end
end

local function border_chunk(surface, left_top)
	local trees = {"dead-grey-trunk", "dead-grey-trunk", "dry-tree"}
	for x = 0, 31, 1 do
		for y = 5, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if math_random(1, math.ceil(pos.y + pos.y) + 64) == 1 then
				surface.create_entity({name = trees[math_random(1, #trees)], position = pos})			
			end
		end
	end		
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if math_random(1, pos.y + 2) == 1 then
				surface.create_decoratives{
				check_collision=false,
				decoratives={
						{name = "rock-medium", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))}
					}
				}
			end
			if math_random(1, pos.y + 2) == 1 then
				surface.create_decoratives{
				check_collision=false,
				decoratives={
						{name = "rock-small", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))}
					}
				}
			end
			if math_random(1, pos.y + 2) == 1 then
				surface.create_decoratives{
				check_collision=false,
				decoratives={
						{name = "rock-tiny", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))}
					}
				}
			end									
			if math_random(1, math.ceil(pos.y + pos.y) + 2) == 1 then
				surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = pos})			
			end
		end
	end
	
	for _, e in pairs(surface.find_entities_filtered({area = {{left_top.x, left_top.y},{left_top.x + 32, left_top.y + 32}}, type = "cliff"})) do	e.destroy() end
end

local function biter_chunk(surface, left_top)
	local tile_positions = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			tile_positions[#tile_positions + 1] = p
		end
	end
	for i = 1, 4, 1 do
		local position = surface.find_non_colliding_position("biter-spawner", tile_positions[math_random(1, #tile_positions)], 16, 2)
		if position then
			surface.create_entity({name = spawner_raffle[math_random(1, #spawner_raffle)], position = position})
		end		
	end
	for _, e in pairs(surface.find_entities_filtered({area = {{left_top.x, left_top.y},{left_top.x + 32, left_top.y + 32}}, type = "cliff"})) do	e.destroy() end
end

local function out_of_map(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x = left_top.x + x, y = left_top.y + y}}})				
		end
	end
end

local function process_chunk(surface, left_top)
	--game.forces.player.chart(surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}})
	if left_top.y == 64 and left_top.x == 64 then
		local p = global.locomotive.position
		for _, entity in pairs(surface.find_entities_filtered({area = {{p.x - 3, p.y - 4},{p.x + 3, p.y + 8}}, force = "neutral"})) do	entity.destroy() end
	end
	if left_top.y < 0 then rock_chunk(surface, left_top) return end
	if left_top.y > 128 then out_of_map(surface, left_top) return end
	if left_top.y > 64 or left_top.x > 480 or left_top.x < -512 then biter_chunk(surface, left_top) return end
	if left_top.y >= 0 then border_chunk(surface, left_top) return end
end

local function process_chunk_queue()
	for k, chunk in pairs(global.chunk_queue) do
		if chunk.surface then
			if chunk.surface.valid then
				process_chunk(chunk.surface, chunk.left_top)
			end
		end
		global.chunk_queue[k] = nil
		return
	end
end

local function on_chunk_generated(event)
	if event.surface.index == 1 then return end
	global.chunk_queue[#global.chunk_queue + 1] = {left_top = event.area.left_top, surface = event.surface}
end

local event = require 'utils.event'
event.on_nth_tick(8, process_chunk_queue)
event.add(defines.events.on_chunk_generated, on_chunk_generated)