local Event = require 'utils.event'
local Market = require 'maps.scrapyard.market'
local create_entity_chain = require "functions.create_entity_chain"
local create_tile_chain = require "functions.create_tile_chain"
local simplex_noise = require 'utils.simplex_noise'.d2
local map_functions = require "tools.map_functions"
local shapes = require "tools.shapes"
local Loot = require 'maps.scrapyard.loot'
local insert = table.insert
local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs
local uncover_radius = 10

local rock_raffle = {"sand-rock-big","sand-rock-big", "rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local enemies = {"small-biter", "medium-biter", "small-spitter", "small-worm-turret", "medium-spitter", "medium-worm-turret", "big-biter", "big-spitter", "big-worm-turret", "behemoth-biter", "behemoth-spitter"}
local scrap_buildings = {"nuclear-reactor", "centrifuge", "beacon", "chemical-plant", "assembling-machine-1", "assembling-machine-2", "assembling-machine-3",  "oil-refinery", "arithmetic-combinator", "constant-combinator", "decider-combinator", "programmable-speaker", "steam-turbine", "steam-engine", "chemical-plant", "assembling-machine-1", "assembling-machine-2", "assembling-machine-3",  "oil-refinery", "arithmetic-combinator", "constant-combinator", "decider-combinator", "programmable-speaker", "steam-turbine", "steam-engine"}

local Public = {}

local function get_noise(name, pos)
	local seed = game.surfaces[global.active_surface_index].map_gen_settings.seed
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
		local sum = noise[1] + noise[2] * 0.35 + noise[3] * 0.23 + noise[4] * 0.11
		return sum
	elseif name == 2 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		local sum = noise[1]
		return sum
	elseif name == 3 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.05, pos.y * 0.05, seed)
		local sum = noise[1]
		return sum
	elseif name == 4 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		local sum = noise[1]
		return sum
	elseif name == 5 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.045, pos.y * 0.045, seed)
		local sum = noise[1]
		return sum
	elseif name == 6 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.02, pos.y * 0.02, seed)
		local sum = noise[1]
		return sum
	elseif name == 7 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.005, pos.y * 0.005, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		noise[3] = simplex_noise(pos.x * 0.05, pos.y * 0.05, seed)
		local sum = noise[1] + noise[2] + noise[3]
		return sum
	end
end

local function place_random_scrap_entity(surface, position)
	local r = math_random(1, 100)
	if r < 15 then
		local e = surface.create_entity({name = scrap_buildings[math_random(1, #scrap_buildings)], position = position, force = "scrap"})
		if e.name == "nuclear-reactor" then
			create_entity_chain(surface, {name = "heat-pipe", position = position, force = "player"}, math_random(16,32), 25)
		end
		if e.name == "chemical-plant" or e.name == "steam-turbine" or e.name == "steam-engine" or e.name == "oil-refinery" then
			create_entity_chain(surface, {name = "pipe", position = position, force = "player"}, math_random(8,16), 25)
		end
		e.active = false
		return
	end
	if r < 100 then
		local e = surface.create_entity({name = "gun-turret", position = position, force = "scrap_defense"})
		e.insert({name = "piercing-rounds-magazine", count = math_random(8, 128)})
		return
	end

	local e = surface.create_entity({name = "storage-tank", position = position, force = "scrap", direction = math_random(0, 3)})
	local fluids = {"crude-oil", "lubricant", "heavy-oil", "light-oil", "petroleum-gas", "sulfuric-acid", "water"}
	e.fluidbox[1] = {name = fluids[math_random(1, #fluids)], amount = math_random(15000, 25000)}
	create_entity_chain(surface, {name = "pipe", position = position, force = "player"}, math_random(6,8), 1)
	create_entity_chain(surface, {name = "pipe", position = position, force = "player"}, math_random(6,8), 1)
	create_entity_chain(surface, {name = "pipe", position = position, force = "player"}, math_random(15,30), 80)
end

local function create_inner_content(surface, pos, noise)
	if math_random(1, 90000) == 1 then
		if noise < 0.3 or noise > -0.3 then
			map_functions.draw_noise_entity_ring(surface, pos, "laser-turret", "scrap_defense", 0, 2)
			map_functions.draw_noise_entity_ring(surface, pos, "accumulator", "scrap_defense", 2, 3)
			map_functions.draw_noise_entity_ring(surface, pos, "substation", "scrap_defense", 3, 4)
			map_functions.draw_noise_entity_ring(surface, pos, "solar-panel", "scrap_defense", 4, 6)
			map_functions.draw_noise_entity_ring(surface, pos, "stone-wall", "scrap_defense", 6, 7)

			create_tile_chain(surface, {name = "concrete", position = pos}, math_random(16, 32), 50)
			create_tile_chain(surface, {name = "concrete", position = pos}, math_random(16, 32), 50)
			create_tile_chain(surface, {name = "stone-path", position = pos}, math_random(16, 32), 50)
			create_tile_chain(surface, {name = "stone-path", position = pos}, math_random(16, 32), 50)
		end
		return
	end
end

local function get_noise_tile(pos)
	local noise = get_noise(1, pos)
	local tile_name

	if noise > 0 then
		tile_name = "dirt-1"
		if noise > 0.5 then
			tile_name = "dirt-2"
		end
	else
		tile_name = "dirt-3"
	end

	local noise2 = get_noise(2, pos)
	if noise2 > 0.71 then
		tile_name = "water"
		if noise > 0.78 then
			tile_name = "deepwater"
		end
	end

	if noise < -0.76 then
		tile_name = "water-green"
	end

	return tile_name
end

local function get_entity(pos)
	local noise = get_noise(5, pos)
	local entity_name = false
	if noise > 0 then
		if math_random(1, 50) ~= 1 then

			if noise > 0.6 then
				entity_name = rock_raffle[math_random(1, #rock_raffle)]
				if math_random(1, 24) == 1 then
					if pos.x > 32 or pos.x < -32 or pos.y > 32 or pos.y < -32 then
						local e = math.ceil(game.forces.enemy.evolution_factor*10)
						if e < 1 then e = 1 end
						entity_name = enemies[e][math_random(1, #enemies[e])]
					end
				end
			end
		end
	else
		if math_random(1, 2048) == 1 then
			entity_name = "market"
		end

		if math_random(1, 128) == 1 then
			local noise_spawners = get_noise(6, pos)
			if noise_spawners > 0.25 and pos.x^2 + pos.y^2 > 3000 then
				entity_name = "biter-spawner"
				if math_random(1,5) == 1 then
					entity_name = "spitter-spawner"
				end
			end
		end
	end
	return entity_name
end

function Public.reveal(player)
	local position = player.position
	local surface = player.surface
	local circles = shapes.circles
	local reveal_area = {}
	local tiles = {}
	local fishes = {}
	local entities = {}
	for r = uncover_radius -1, uncover_radius, 1 do
		for _, v in pairs(circles[r]) do
			local pos = {x = position.x + v.x, y = position.y + v.y}
			if surface.get_tile(pos).name == "out-of-map" then
				local rivers = get_noise(7, pos)
				local noise = get_noise(1, pos)
				local noise2 = get_noise(2, pos)
				local distance_to_center = math.sqrt(pos.x^2 + pos.y^2)
				insert(tiles, {name = "dirt-" .. math_random(1, 7), position = pos})
				if distance_to_center < 40 then
					insert(tiles, {name = "dirt-" .. math_random(1, 7), position = pos})
				else
					if noise > 0.43 or noise < -0.43 then
						if math_random(1,4) ~= 1 then
							insert(entities, {name = "mineable-wreckage", position = pos})
						else
							if math_random(1,256) == 1 then
								Loot.create_loot(surface, pos, "wooden-chest")
							else
								if math_random(1,512) == 1 then
									place_random_scrap_entity(surface, pos)
								end
							end
						end
					elseif noise2 > 0.25 or noise2 < -0.25 then
					create_inner_content(surface, pos, noise)
					local tile_name = get_noise_tile(pos)
					insert(tiles, {name = tile_name, position = pos})
					if rivers < -0.3 then insert(tiles, {name = "water-shallow", position = pos}) end
						if tile_name == "water" or tile_name == "deepwater" or tile_name == "water-green" then
							if math_random(1, 24) == 1 then insert(fishes, pos) end
						else
							local entity = get_entity(pos)
							if entity then
								if entity == "market" then
									local area = {{pos.x - 64, pos.y - 64}, {pos.x + 64, pos.y + 64}}
									if surface.count_entities_filtered({name = "market", area = area}) == 0 then
										Market.secret_shop(pos, surface)
									end
								elseif math_floor(distance_to_center) > tonumber(128) then
									if entity == "biter-spawner" or entity == "spitter-spawner" then
										local area = {{pos.x - 16, pos.y - 16}, {pos.x + 16, pos.y + 16}}
										if surface.count_entities_filtered({name = "biter-spawner", area = area}) == 0 then
											insert(entities, {name = entity, position = pos})
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	if #tiles > 0 then
		surface.set_tiles(tiles, true)
	end
	for _, entity in pairs(entities) do
		surface.create_entity(entity)
	end
	for _, pos in pairs(reveal_area) do
		Public.reveal(surface, pos, 1, 16)
	end
	for _, fish in pairs(fishes) do
		surface.create_entity({name = "fish", position = fish})
	end
end

local function generate_spawn_area(surface, position_left_top)
	if position_left_top.x > 32 then return end
	if position_left_top.y > 32 then return end
	if position_left_top.x < -32 then return end
	if position_left_top.y < -32 then return end

	local entities = {}
	local tiles = {}
	local circles = shapes.circles

	for r = 1, 12 do
		for k, v in pairs(circles[r]) do
			local t_insert = false
			local pos = {x = position_left_top.x + v.x, y = position_left_top.y + v.y}
			if pos.x > -15 and pos.x < 15 and pos.y > -15 and pos.y < 15 then
				t_insert = "stone-path"
			end
			if t_insert then
				insert(tiles, {name = t_insert, position = pos})
			end
		end
	end
	surface.set_tiles(tiles, true)

	for _, entity in pairs(entities) do
		surface.create_entity(entity)
	end
end

local function is_out_of_map(p)
	if p.x < 96 and p.x >= -96 then return end
	if p.y * 0.5 >= math_abs(p.x) then return end
	if p.y * -0.5 > math_abs(p.x) then return end
	return true
end

local function border_chunk(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if not is_out_of_map(pos) then
				if math_random(1, pos.y + 23) == 1 then
					surface.create_entity{
					name = "gun-turret-remnants", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))
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
				if math_random(1, pos.y + 22) == 1 then
					surface.create_entity{
					name = "wall-remnants", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))
					}
				end
			end
		end
	end

	for _, e in pairs(surface.find_entities_filtered({area = {{left_top.x, left_top.y},{left_top.x + 32, left_top.y + 32}}, type = "cliff"})) do	e.destroy() end
end

local function replace_water(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			if surface.get_tile(p).collides_with("resource-layer") then
				surface.set_tiles({{name = "dirt-" .. math_random(1,5), position = p}}, true)
			end
		end
	end
end

local function process(surface, left_top)
	local position_left_top = left_top
	local tiles = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local tile_to_insert = "out-of-map"
			local pos = {x = position_left_top.x + x, y = position_left_top.y + y}
			local tile_name = surface.get_tile(pos).name
			if tile_name ~= "stone-path" then
				insert(tiles, {name = tile_to_insert, position = pos})
			end
		end
	end
	surface.set_tiles(tiles, true)
	for _, e in pairs (surface.find_entities_filtered({area = {{-50, -50},{50, 50}}})) do
		local distance_to_center = math.sqrt(e.position.x^2 + e.position.y^2)
		if e.valid then
			if distance_to_center < 8 and e.name == "mineable-wreckage" and math_random(1,5) ~= 1 then e.destroy() end
		end
		if e.valid then
			if distance_to_center < 30 and e.name == "gun-turret" then e.destroy() end
		end
	end
	if global.spawn_generated then return end
	if left_top.x < 96 then return end
	map_functions.draw_rainbow_patch_v2({x = 0, y = 0}, surface, 12, 2500)
	global.spawn_generated = true
	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
			decorative_names[#decorative_names+1] = k
		end
	end
	surface.regenerate_decorative(decorative_names, {position_left_top})

	if math_random(1, 16) ~= 1 then return end
	local pos = {x = position_left_top.x * 32 + math_random(1,32), y = position_left_top.y * 32 + math_random(1,32)}
	local noise = get_noise(1, pos)
	if noise > 0.4 or noise < -0.4 then return end
	local distance_to_center = math.sqrt(pos.x^2 + pos.y^2)
	local size = 7 + math.floor(distance_to_center * 0.0075)
	if size > 20 then size = 20 end
	local amount = 500 + distance_to_center * 2
	map_functions.draw_rainbow_patch_v2(pos, surface, size, amount)
end

local function out_of_map_area(event)
	local surface = event.surface
	local left_top = event.area.left_top
	for x = -1, 32, 1 do
		for y = -1, 32, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			if is_out_of_map(p) then
				surface.set_tiles({{name = "out-of-map", position = p}}, true)
			end
		end
	end
end

local function biter_chunk(surface, left_top)
	local tile_positions = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			tile_positions[#tile_positions + 1] = p
		end
	end

	for i = 1, 1, 1 do
		local position = surface.find_non_colliding_position("biter-spawner", tile_positions[math_random(1, #tile_positions)], 16, 2)
		if position then
			local e = surface.create_entity({name = enemies[math_random(1, #enemies)], position = position, force = "enemy"})
			e.destructible = false
			e.active = false
		end
	end

	for i = 1, 3, 1 do
		local position = surface.find_non_colliding_position("big-worm-turret", tile_positions[math_random(1, #tile_positions)], 16, 2)
		if position then
			local e = surface.create_entity({name = "big-worm-turret", position = position, force = "enemy"})
			e.destructible = false
		end
	end
end

local function on_chunk_generated(event)
	if event.surface.index == 1 then return end
	local surface = event.surface
	local left_top = event.area.left_top
	if surface.name ~= event.surface.name then return end
	local position_left_top = event.area.left_top

	generate_spawn_area(surface, position_left_top)
	if left_top.y >= 0 then replace_water(surface, left_top) end
	if left_top.y > 210 then biter_chunk(surface, left_top) end
	if left_top.y >= 0 then border_chunk(surface, left_top) end
	if left_top.y < 0 then process(surface, left_top) end
	out_of_map_area(event)
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)

return Public