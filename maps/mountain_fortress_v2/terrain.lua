local math_random = math.random
local simplex_noise = require "utils.simplex_noise".d2
local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local spawner_raffle = {"biter-spawner", "biter-spawner", "biter-spawner", "spitter-spawner"}
local noises = {
	["no_rocks"] = {{modifier = 0.0033, weight = 1}, {modifier = 0.01, weight = 0.22}, {modifier = 0.05, weight = 0.05}, {modifier = 0.1, weight = 0.04}},
	["no_rocks_2"] = {{modifier = 0.013, weight = 1}, {modifier = 0.1, weight = 0.1}},
	["large_caves"] = {{modifier = 0.0033, weight = 1}, {modifier = 0.01, weight = 0.22}, {modifier = 0.05, weight = 0.05}, {modifier = 0.1, weight = 0.04}},	
	["small_caves"] = {{modifier = 0.008, weight = 1}, {modifier = 0.03, weight = 0.15}, {modifier = 0.25, weight = 0.05}},	
	["cave_ponds"] = {{modifier = 0.01, weight = 1}, {modifier = 0.1, weight = 0.06}},
	["cave_rivers"] = {{modifier = 0.005, weight = 1}, {modifier = 0.01, weight = 0.25}, {modifier = 0.05, weight = 0.01}},
}
local level_depth = 1024
local worm_level_modifier = 0.25

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

local function get_replacement_tile(surface, position)
	for i = 1, 128, 1 do
		local vectors = {{0, i}, {0, i * -1}, {i, 0}, {i * -1, 0}}
		table.shuffle_table(vectors)
		for k, v in pairs(vectors) do
			local tile = surface.get_tile(position.x + v[1], position.y + v[2])
			if not tile.collides_with("resource-layer") then return tile.name end
		end
	end
	return "grass-1"
end

--if left_top.y < -4096 then rock_chunk_level_5(surface, left_top) return end
	--if left_top.y < -3072 then rock_chunk_level_4(surface, left_top) return end
	--if left_top.y < -2048 then rock_chunk_level_3(surface, left_top) return end
	--if left_top.y < -1024 then rock_chunk_level_2(surface, left_top) return end
local function process_level_5_position(p, seed, tiles, entities, markets, treasure)
	local large_caves = get_noise("large_caves", p, seed)
	if large_caves > -0.03 and large_caves < 0.03 then
		tiles[#tiles + 1] = {name = "water-green", position = p}
		if math_random(1,128) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end

	local cave_rivers = get_noise("cave_rivers", p, seed)
	if cave_rivers > -0.05 and cave_rivers < 0.05 then		
		if math_random(1,48) == 1 then entities[#entities + 1] = {name = "tree-0" .. math_random(1, 9), position=p} end
		if math_random(1,768) == 1 then
			wave_defense_set_worm_raffle(math.abs(p.y) * worm_level_modifier)
			entities[#entities + 1] = {name = wave_defense_roll_worm_name(), position = p, force = "enemy"} 
		end
	else
		tiles[#tiles + 1] = {name = "dirt-7", position = p}	
		if math_random(1,8) > 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, #rock_raffle)], position = p} end
		if math_random(1,320) == 1 then treasure[#treasure + 1] = p end
		if math_random(1,1536) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = math.abs(p.y) * 1000} end
		if math_random(1,4096) == 1 then markets[#markets + 1] = p end
	end
end
	
local function process_level_4_position(p, seed, tiles, entities, markets, treasure)
	local small_caves = get_noise("small_caves", p, seed)
	if small_caves > -0.07 and small_caves < 0.07 then
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
		if math_random(1,2) > 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, #rock_raffle)], position = p} end
		return
	end
	if small_caves < -0.45 or small_caves > 0.45 then
		tiles[#tiles + 1] = {name = "deepwater-green", position = p}
		if math_random(1,128) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		if math_random(1,128) == 1 then
			wave_defense_set_worm_raffle(math.abs(p.y) * worm_level_modifier)
			entities[#entities + 1] = {name = wave_defense_roll_worm_name(), position = p, force = "enemy"} 
		end
		return
	end	
	tiles[#tiles + 1] = {name = "out-of-map", position = p}
end

local function process_rock_chunk_position(p, seed, tiles, entities, markets, treasure)	
	if p.y < level_depth * -5 then process_level_5_position(p, seed, tiles, entities, markets, treasure) return end
	if p.y < level_depth * -4 then process_level_4_position(p, seed, tiles, entities, markets, treasure) return end
	
	local m = 1
	if p.y < level_depth * -1 then m = 0.35 end
	if p.y < level_depth * -2 then m = 0.2 end
	if p.y < level_depth * -3 then m = 0.1 end
	
	local small_caves = get_noise("small_caves", p, seed)	
	local noise_large_caves = get_noise("large_caves", p, seed)
	
	if noise_large_caves > m * -1 and noise_large_caves < m then	
		
		local noise_cave_ponds = get_noise("cave_ponds", p, seed)
		--Green Water Ponds
		if noise_cave_ponds > 0.80 then
			tiles[#tiles + 1] = {name = "deepwater-green", position = p}
			if math_random(1,16) == 1 then entities[#entities + 1] = {name="fish", position=p} end
			return
		else
			if noise_cave_ponds > 0.785 then
				tiles[#tiles + 1] = {name = "dirt-7", position = p}
				return 
			end
		end
		
		--Chasms
		if noise_cave_ponds < 0.12 and noise_cave_ponds > -0.12 then
			if small_caves > 0.55 then
				tiles[#tiles + 1] = {name = "out-of-map", position = p}
				return
			end
			if small_caves < -0.55 then
				tiles[#tiles + 1] = {name = "out-of-map", position = p}
				return
			end
		end	
		
		--Rivers
		local cave_rivers = get_noise("cave_rivers", p, seed + 100000)
		if cave_rivers < 0.024 and cave_rivers > -0.024 then
			if noise_cave_ponds > 0 then
				tiles[#tiles + 1] = {name = "water-shallow", position = p}
				if math_random(1,64) == 1 then entities[#entities + 1] = {name="fish", position=p} end
				return				
			end
		end
		
		--Market Spots 
		if noise_cave_ponds < -0.80 then
			tiles[#tiles + 1] = {name = "grass-" .. math.floor(noise_cave_ponds * 32) % 3 + 1, position = p}
			if math_random(1,32) == 1 then markets[#markets + 1] = p end
			if math_random(1,16) == 1 then entities[#entities + 1] = {name = "tree-0" .. math_random(1, 9), position=p} end
			return
		end
		
		local no_rocks = get_noise("no_rocks", p, seed + 25000)
		--Worm oil Zones
		if p.y < -64 + noise_cave_ponds * 10 then
			if no_rocks < 0.08 and no_rocks > -0.08 then
				if small_caves > 0.35 then
					tiles[#tiles + 1] = {name = "dirt-" .. math.floor(noise_cave_ponds * 32) % 7 + 1, position = p}
					if math_random(1,500) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = math.abs(p.y) * 500} end
					if math_random(1,96) == 1 then
						wave_defense_set_worm_raffle(math.abs(p.y) * worm_level_modifier)
						entities[#entities + 1] = {name = wave_defense_roll_worm_name(), position = p, force = "enemy"} 
					end
					if math_random(1,1024) == 1 then treasure[#treasure + 1] = p end
					return
				end
			end
		end
		
		--Main Rock Terrain
		local no_rocks_2 = get_noise("no_rocks_2", p, seed + 75000)
		if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
			tiles[#tiles + 1] = {name = "dirt-" .. math.floor(no_rocks_2 * 8) % 2 + 5, position = p}
			if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
			return 
		end
		
		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,100) > 30 then entities[#entities + 1] = {name = rock_raffle[math_random(1, #rock_raffle)], position = p} end		
		return
	end
	
	if math.abs(noise_large_caves) > m * 7 then
		tiles[#tiles + 1] = {name = "water", position = p}
		if math_random(1,16) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end	
	if math.abs(noise_large_caves) > m * 6.5 then
		if math_random(1,16) == 1 then entities[#entities + 1] = {name="tree-02", position=p} end
		if math_random(1,64) == 1 then markets[#markets + 1] = p end
	end	
	if math.abs(noise_large_caves) > m * 5 then
		tiles[#tiles + 1] = {name = "grass-2", position = p}
		if math_random(1,512) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = math.abs(p.y) * 1000} end
		if math_random(1,512) == 1 then markets[#markets + 1] = p end
		if math_random(1,384) == 1 then
			wave_defense_set_worm_raffle(math.abs(p.y) * worm_level_modifier)
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
			local market = mountain_market(surface, position, math.abs(position.y) * 0.004)
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
	for i = 1, 2, 1 do
		local position = surface.find_non_colliding_position("biter-spawner", tile_positions[math_random(1, #tile_positions)], 16, 2)
		if position then
			local e = surface.create_entity({name = spawner_raffle[math_random(1, #spawner_raffle)], position = position})
			e.destructible = false
			e.active = false
		end		
	end
	for _, e in pairs(surface.find_entities_filtered({area = {{left_top.x, left_top.y},{left_top.x + 32, left_top.y + 32}}, type = "cliff"})) do	e.destroy() end
end

local function replace_water(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			if surface.get_tile(p).collides_with("resource-layer") then
				surface.set_tiles({{name = get_replacement_tile(surface, p), position = p}}, true)
			end		
		end
	end	
end

local function out_of_map(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x = left_top.x + x, y = left_top.y + y}}})				
		end
	end
end

local function wall(surface, left_top, seed)
	local entities = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			local small_caves = get_noise("small_caves", p, seed)	
			local cave_ponds = get_noise("cave_rivers", p, seed + 100000)
			if y > 9 + cave_ponds * 6 and y < 23 + small_caves * 6 then
				if small_caves > 0.10 or cave_ponds > 0.10 then
					--surface.set_tiles({{name = "water-shallow", position = p}})
					surface.set_tiles({{name = "deepwater", position = p}})
					if math_random(1,48) == 1 then surface.create_entity({name = "fish", position = p}) end
				else
					surface.set_tiles({{name = "dirt-7", position = p}})
					if math_random(1, 5) ~= 1 then
						surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = p})
					end
				end
			else
				surface.set_tiles({{name = "dirt-7", position = p}})
				
				if surface.can_place_entity({name = "stone-wall", position = p, force = "enemy"}) then
					if math_random(1,512) == 1 and y > 3 and y < 28 then
						treasure_chest(surface, p)
					else
						
						if y < 7 or y > 23 then
							if y <= 15 then
								if math_random(1, y + 1) == 1 then
									local e = surface.create_entity({name = "stone-wall", position = p, force = "neutral"})
									e.minable = false
								end
							else
								if math_random(1, 32 - y)  == 1 then
									local e = surface.create_entity({name = "stone-wall", position = p, force = "neutral"})
									e.minable = false
								end
							end
						end
						
					end				
				end		
				
				if math_random(1, 16) == 1 then
					if surface.can_place_entity({name = "small-worm-turret", position = p, force = "enemy"}) then
						wave_defense_set_worm_raffle(math.abs(p.y) * worm_level_modifier)
						surface.create_entity({name = wave_defense_roll_worm_name(), position = p, force = "enemy"})
					end
				end			
			end
		end
	end
end

local function process_chunk(surface, left_top)
	if not surface then return end
	if not surface.valid then return end
	if left_top.x >= 768 then return end
	if left_top.x < -768 then return end
	
	if left_top.y % level_depth == 0 and left_top.y < 0 and left_top.y > level_depth * -6 then wall(surface, left_top, surface.map_gen_settings.seed) return end
	
	if left_top.y >= 0 then replace_water(surface, left_top) end
	if left_top.y > 32 then game.forces.player.chart(surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}}) end	
	if left_top.y == -128 and left_top.x == -128 then
		local p = global.locomotive.position
		for _, entity in pairs(surface.find_entities_filtered({area = {{p.x - 3, p.y - 4},{p.x + 3, p.y + 10}}, type = "simple-entity"})) do	entity.destroy() end
	end
	if left_top.y < 0 then rock_chunk(surface, left_top) return end
	if left_top.y > 96 then out_of_map(surface, left_top) return end
	if left_top.y > 64 then biter_chunk(surface, left_top) return end
	if left_top.y >= 0 then border_chunk(surface, left_top) return end
end

--[[
local function process_chunk_queue()
	for k, chunk in pairs(global.chunk_queue) do		
		process_chunk(game.surfaces[chunk.surface_index], chunk.left_top)		
		global.chunk_queue[k] = nil
		return
	end
end


local function process_chunk_queue()
	local chunk = global.chunk_queue[#global.chunk_queue]
	if not chunk then return end
	process_chunk(game.surfaces[chunk.surface_index], chunk.left_top)		
	global.chunk_queue[#global.chunk_queue] = nil
end
]]

local function on_chunk_generated(event)
	if event.surface.index == 1 then return end
	process_chunk(event.surface, event.area.left_top)
	--global.chunk_queue[#global.chunk_queue + 1] = {left_top = {x = event.area.left_top.x, y = event.area.left_top.y}, surface_index = event.surface.index}
end

local event = require 'utils.event'
event.on_nth_tick(4, process_chunk_queue)
event.add(defines.events.on_chunk_generated, on_chunk_generated)