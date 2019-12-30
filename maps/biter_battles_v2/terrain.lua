local bb_config = require "maps.biter_battles_v2.config"
local event = require 'utils.event'
local Server = require 'utils.server'
local math_random = math.random
local math_abs = math.abs
local simplex_noise = require 'utils.simplex_noise'.d2
local create_tile_chain = require "functions.create_tile_chain"
local spawn_circle_size = 40
local ores = {"copper-ore", "iron-ore", "stone", "coal"}
local rocks = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big", "rock-huge"}

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
	if name == 1 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.0042, pos.y * 0.0042, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.031, pos.y * 0.031, seed)
		seed = seed + noise_seed_add
		noise[3] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		local noise = noise[1] + noise[2] * 0.08 + noise[3] * 0.025
		return noise
	end
	if name == 2 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.011, pos.y * 0.011, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.08, pos.y * 0.08, seed)
		local noise = noise[1] + noise[2] * 0.2
		return noise
	end
	if name == 3 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.02, pos.y * 0.02, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.08, pos.y * 0.08, seed)
		local noise = noise[1] + noise[2] * 0.1
		return noise
	end
end

local function get_replacement_tile(surface, position)
	for i = 1, 128, 1 do
		local vectors = {{0, i}, {0, i * -1}, {i, 0}, {i * -1, 0}}
		table.shuffle_table(vectors)
		for k, v in pairs(vectors) do
			local tile = surface.get_tile(position.x + v[1], position.y + v[2])
			if not tile.collides_with("resource-layer") then
				if tile.name ~= "stone-path" then
					return tile.name
				end
			end
		end
	end
	return "grass-1"
end

local function get_chunk_position(position)
	local chunk_position = {}
	position.x = math.floor(position.x, 0)
	position.y = math.floor(position.y, 0)
	for x = 0, 31, 1 do
		if (position.x - x) % 32 == 0 then chunk_position.x = (position.x - x)  / 32 end
	end
	for y = 0, 31, 1 do
		if (position.y - y) % 32 == 0 then chunk_position.y = (position.y - y)  / 32 end
	end
	return chunk_position
end

local function regenerate_decoratives(surface, position)
	local chunk = get_chunk_position(position)
	if not chunk then return end
	surface.destroy_decoratives({area = {{chunk.x * 32, chunk.y * 32}, {chunk.x * 32 + 32, chunk.y * 32 + 32}}})
	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
			decorative_names[#decorative_names+1] = k
		end
	end
	surface.regenerate_decorative(decorative_names, {chunk})
end

local function draw_noise_ore_patch(position, name, surface, radius, richness)
	if not position then return end
	if not name then return end
	if not surface then return end
	if not radius then return end
	if not richness then return end
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000
	local richness_part = richness / radius
	for y = radius * -3, radius * 3, 1 do
		for x = radius * -3, radius * 3, 1 do
			local pos = {x = x + position.x + 0.5, y = y + position.y + 0.5}			
			local noise_1 = simplex_noise(pos.x * 0.0125, pos.y * 0.0125, seed)
			local noise_2 = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed + 25000)
			local noise = noise_1 + noise_2 * 0.12
			local distance_to_center = math.sqrt(x^2 + y^2)
			local a = richness - richness_part * distance_to_center
			if distance_to_center < radius - math.abs(noise * radius * 0.85) and a > 1 then
				if surface.can_place_entity({name = name, position = pos, amount = a}) then
					surface.create_entity{name = name, position = pos, amount = a}

					local mirror_pos = {x = pos.x * -1, y = pos.y * -1}
					surface.create_entity{name = name, position = mirror_pos, amount = a}
					
					for _, e in pairs(surface.find_entities_filtered({position = pos, name = {"wooden-chest", "stone-wall", "gun-turret"}})) do					
						e.destroy()
					end
					for _, e in pairs(surface.find_entities_filtered({position = mirror_pos, name = {"wooden-chest", "stone-wall", "gun-turret"}})) do
						e.destroy()
					end
				end
			end
		end
	end
end

function is_within_spawn_circle(pos)
	if math_abs(pos.x) > spawn_circle_size then return false end
	if math_abs(pos.y) > spawn_circle_size then return false end
	if math.sqrt(pos.x ^ 2 + pos.y ^ 2) > spawn_circle_size then return false end
	return true
end

local river_y_1 = bb_config.border_river_width * -1.5
local river_y_2 = bb_config.border_river_width * 1.5
local river_width_half = math.floor(bb_config.border_river_width * -0.5)
function is_horizontal_border_river(pos)
	if pos.y < river_y_1 then return false end
	if pos.y > river_y_2 then return false end
	if pos.y > -5 and pos.x > -5 and pos.x < 5 then return false end
	if pos.y >= river_width_half - (math_abs(get_noise(1, pos)) * 4) then return true end
	return false
end

local function generate_inner_spawn_circle(pos, distance_to_center, surface)
	local tile = false
	if distance_to_center < spawn_circle_size then
		tile = "deepwater"
		if math_random(1, 48) == 1 then surface.create_entity({name = "fish", position = pos}) end
	end
	if distance_to_center < 9.5 then tile = "refined-concrete" end
	if distance_to_center < 7 then tile = "sand-1" end
	if tile then surface.set_tiles({{name = tile, position = pos}}, true) end
end

local function generate_starting_area(pos, distance_to_center, surface)
	local r = 116
	local noise = get_noise(2, pos) * 15

	if distance_to_center + noise < r - 10 and distance_to_center > spawn_circle_size and not is_horizontal_border_river(pos) then
		local tile_name = surface.get_tile(pos).name
		if tile_name == "water" or tile_name == "deepwater" then
			surface.set_tiles({{name = get_replacement_tile(surface, pos), position = pos}}, true)
		end
	end

	if tile then surface.set_tiles({{name = tile, position = pos}}, true) end

	if surface.can_place_entity({name = "wooden-chest", position = pos}) and surface.can_place_entity({name = "coal", position = pos}) then
		local noise_2 = get_noise(3, pos)
		if noise_2 < 0.25 then
			local spawn_wall_r = distance_to_center + noise
			if noise_2 > -0.5 then
				if spawn_wall_r < r and spawn_wall_r > r - 1.75 then				
					surface.create_entity({name = "stone-wall", position = pos, force = "north"})
				end
			else
				if spawn_wall_r < r and spawn_wall_r > r - 1.95 then				
					surface.create_entity({name = "stone-wall", position = pos, force = "north"})
				else
					if spawn_wall_r < r + 4.5 and spawn_wall_r > r then
						local name = "wooden-chest"
						local r_max = math.floor(math.abs(spawn_wall_r - r)) + 2
						if math_random(1,3) == 1 then name = name .. "-remnants" end
						if math_random(1,r_max) == 1 then surface.create_entity({name = name, position = pos, force = "north"}) end
					end
				end	
				if spawn_wall_r < r - 3 and spawn_wall_r > r - 6 then
					if math_random(1, 16) == 1 then
						if surface.can_place_entity({name = "gun-turret", position = pos}) then
							local t = surface.create_entity({name = "gun-turret", position = pos, force = "north"})
							t.insert({name = "firearm-magazine", count = math_random(6,12)})
						end
					else
						if math_random(1, 16) == 1 then
							if surface.can_place_entity({name = "gun-turret", position = pos}) then
								surface.create_entity({name = "gun-turret-remnants", position = pos, force = "north"})
							end
						end
					end
				end
			end
		end
	end
end

local function generate_circle_spawn(event)
	if global.bb_spawn_generated then return end

	local surface = event.surface

	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y

	if left_top_x < -320 then return end
	if left_top_x > 320 then return end
	if left_top_y < -320 then return end

	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			local distance_to_center = math.sqrt(pos.x ^ 2 + pos.y ^ 2)

			if distance_to_center < spawn_circle_size then
				generate_inner_spawn_circle(pos, distance_to_center, surface) 
			else 
				generate_starting_area(pos, distance_to_center, surface)
			end
		end
	end

	regenerate_decoratives(surface, event.area.left_top)
end

local function generate_north_silo(surface)
	local pos = {x = -32 + math.random(0, 64), y = -72}
	local mirror_position = {x = pos.x * -1, y = pos.y * -1}
	
	for _, t in pairs(surface.find_tiles_filtered({area = {{pos.x - 6, pos.y - 6},{pos.x + 6, pos.y + 6}}, name = {"water", "deepwater"}})) do
		surface.set_tiles({{name = get_replacement_tile(surface, t.position), position = t.position}})
	end
	for _, t in pairs(surface.find_tiles_filtered({area = {{mirror_position.x - 6, mirror_position.y - 6},{mirror_position.x + 6, mirror_position.y + 6}}, name = {"water", "deepwater"}})) do
		surface.set_tiles({{name = get_replacement_tile(surface, t.position), position = t.position}})
	end
	
	global.rocket_silo["north"] = surface.create_entity({
		name = "rocket-silo",
		position = pos,
		force = "north"
	})
	global.rocket_silo["north"].minable = false

	for i = 1, 32, 1 do
		create_tile_chain(surface, {name = "stone-path", position = global.rocket_silo["north"].position}, 32, 10)
	end
end

local function generate_river(event)
	if event.area.left_top.y < -32 then return end
	local surface = event.surface
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			local distance_to_center = math.sqrt(pos.x ^ 2 + pos.y ^ 2)
			if is_horizontal_border_river(pos) then
				surface.set_tiles({{name = "deepwater", position = pos}})
				if math_random(1, 64) == 1 then surface.create_entity({name = "fish", position = pos}) end
			end
		end
	end
end

local function generate_potential_spawn_ore(surface)
	local r = 130
	local area = {{r * -1, r * -1}, {r, 0}}
	local ores = {}
	ores["iron-ore"] = surface.count_entities_filtered({name = "iron-ore", area = area})
	ores["copper-ore"] = surface.count_entities_filtered({name = "copper-ore", area = area})
	ores["coal"] = surface.count_entities_filtered({name = "coal", area = area})
	ores["stone"] = surface.count_entities_filtered({name = "stone", area = area})
	for ore, ore_count in pairs(ores) do
		if ore_count < 1000 or ore_count == nil then
			local pos = {}
			for a = 1, 32, 1 do
				pos = {x = -96 + math_random(0, 192), y = -20 - math_random(0, 96)}
				if surface.can_place_entity({name = "coal", position = pos, amount = 1}) then
					break
				end
			end
			draw_noise_ore_patch(pos, ore, surface, math_random(18, 24), math_random(1500, 2000))
		end
	end
end

local worm_turrets = {
	[1] = "small-worm-turret",
	[2] = "medium-worm-turret",
	[3] = "big-worm-turret",
	[4] = "behemoth-worm-turret"
}

local worm_tile_coords = {}
for x = 0, 31, 1 do
	for y = 0, 31, 1 do
		worm_tile_coords[#worm_tile_coords + 1] = {x, y}
	end
end

local worm_chance = 15
local function generate_extra_worm_turrets(surface, left_top)
	local chunk_distance_to_center = math.sqrt(left_top.x ^ 2 + left_top.y ^ 2)
	if bb_config.bitera_area_distance > chunk_distance_to_center then return end

	for a = 1, 256, 1 do
		if math_random(1, 100) > worm_chance then break end
		local coord_modifier = worm_tile_coords[math_random(1, #worm_tile_coords)]
		local pos = {left_top.x + coord_modifier[1], left_top.y + coord_modifier[2]}
		local position = surface.find_non_colliding_position("big-worm-turret", pos, 8, 1)
		if position then
			local highest_worm_tier = math.floor((chunk_distance_to_center - bb_config.bitera_area_distance) * 0.002) + 1
			if highest_worm_tier > 4 then highest_worm_tier = 4 end
			local name = worm_turrets[math_random(1, highest_worm_tier)]
			surface.create_entity({name = name, position = position, force = "north_biters"})
		end
	end
end

local scrap_vectors = {}
for x = -5, 5, 1 do
	for y = -5, 5, 1 do
		if math.sqrt(x^2 + y^2) <= 5 then
			scrap_vectors[#scrap_vectors + 1] = {x, y}
		end
	end
end

local function generate_scrap(event)
	local distance_to_center = math.sqrt(event.area.left_top.x ^ 2 + event.area.left_top.y ^ 2)

	local worms = event.surface.find_entities_filtered({area = event.area, type = "turret"})
	if #worms == 0 then return end

	for _, e in pairs(worms) do
		if math_random(1,2) == 1 then
			for c = 1, math_random(2,12), 1 do
				local vector = scrap_vectors[math_random(1, #scrap_vectors)]
				local position = {e.position.x + vector[1], e.position.y + vector[2]}
				if e.surface.can_place_entity({name = "mineable-wreckage", position = position, force = "neutral"}) then
					e.surface.create_entity({name = "mineable-wreckage", position = position, force = "neutral"})
				end
			end
		end
	end
end

local function is_biter_area(position)
	--if position.x + position.y > -352 + (get_noise(3, position) * 16) then return false end
	if position.y + (get_noise(3, position) * 16) > (bb_config.bitera_area_distance * -1) - (math.abs(position.x) * 0.33) then return false end
	return true
end

local function builders_area_process_entity(e)
	if is_biter_area(e.position) then
		if e.type == "resource" then
			e.destroy()
			return
		end
		if e.type == "turret" then
			e.destroy()
			return
		end
		if e.type == "cliff" then
			e.destroy()
			return
		end
		if e.type == "tree" then
			if math_random(1, 32) == 1 then e.surface.create_entity({name = "rock-big", position = e.position, force = "neutral"}) end
			e.destroy()
			return
		end
	else
		if e.type == "turret" or e.type == "unit-spawner" then
			e.destroy()
			return
		end
	end
end

local function builders_area_process_tile(t, surface)
	if is_horizontal_border_river(t.position) then return end
	if not is_biter_area(t.position) then return end
	local noise_index = math.floor(math.abs(get_noise(3, t.position)) * 7) + 1
	if noise_index > 7 then noise_index = 7 end
	surface.set_tiles({{name = "dirt-" .. noise_index, position = t.position}})

	if math_random(1, 160) == 1 then
		if t.position.x ^ 2 + t.position.y ^ 2 < 129600 then return end
		local spawner_position = surface.find_non_colliding_position("biter-spawner", t.position, 8, 1)
		if spawner_position then
			if math_random(1, 4) == 1 then
				surface.create_entity({name = "spitter-spawner", position = spawner_position, force = "north_biters"})
			else
				surface.create_entity({name = "biter-spawner", position = spawner_position, force = "north_biters"})
			end
		end
	end
end

local function mixed_ore(event)
	local surface = event.surface
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y

	--Draw noise text values to determine which chunks are valid for mixed ore.
	--rendering.draw_text{text = get_noise(1, {x = left_top_x + 16, y = left_top_y + 16}), surface = surface, target = {x = left_top_x + 16, y = left_top_y + 16}, color = {255, 255, 255}, time_to_live = 3600, scale = 2, font = "default-game"}

	--Skip chunks that are too far off the ore noise value.
	if get_noise(1, {x = left_top_x + 16, y = left_top_y + 16}) < 0.52 then return end

	--Draw the mixed ore patches.
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			if surface.can_place_entity({name = "iron-ore", position = pos}) then
				local noise = get_noise(1, pos)
				if noise > 0.81 then
					local amount = math_random(1250, 1500) + math.sqrt(pos.x ^ 2 + pos.y ^ 2) * 1.1
					local m = (noise - 0.75) * 16
					amount = amount * m
					local i = math.ceil(math.abs(noise * 35)) % 4
					if i == 0 then i = 4 end
					surface.create_entity({name = ores[i], position = pos, amount = amount})
				end
			end
		end
	end
end
--[[
local cliff_vectors = {} 
local cliff_brush_radius = 3.5
for x = cliff_brush_radius * -1, cliff_brush_radius, 0.5 do
	for y = cliff_brush_radius * -1, cliff_brush_radius, 0.5 do
		if math.sqrt(x^2 + y^2) < cliff_brush_radius then
			cliff_vectors[#cliff_vectors + 1] = {x,y}
		end
	end
end

local function replace_cliff(surface, entity)
	if surface.get_tile(entity.position).collides_with("resource-layer") then return end
	for _, vector in pairs(cliff_vectors) do
		if math_random(0, (math_abs(vector[1]) + math_abs(vector[2])) * 0.75) == 0 then
			local position = {entity.position.x + vector[1], entity.position.y + vector[2]}
			if surface.count_entities_filtered({type = "simple-entity", position = position}) == 0 then
				surface.create_entity({name = rocks[math_random(1, 7)], position = position})
			end
		end
	end	
end

local function replace_cliffs_with_rocks(surface, area)
	for _, cliff in pairs(surface.find_entities_filtered({area = area, type = "cliff"})) do
		replace_cliff(surface, cliff)
		cliff.destroy()
	end
end
]]
local function on_chunk_generated(event)
	if event.area.left_top.y >= 0 then return end
	local surface = event.surface
	local left_top = event.area.left_top
	if surface.name ~= "biter_battles" then return end

	for _, e in pairs(surface.find_entities_filtered({area = event.area, force = "enemy"})) do		
		surface.create_entity({name = e.name, position = e.position, force = "north_biters", direction = e.direction})
		e.destroy()
	end

	--replace_cliffs_with_rocks(surface, event.area)
	
	mixed_ore(event)
	generate_river(event)
	generate_circle_spawn(event)

	if bb_config.builders_area then
		for _, t in pairs(surface.find_tiles_filtered({area = event.area, name = {"water", "deepwater"}})) do
			builders_area_process_tile(t, surface)
		end
		for _, e in pairs(surface.find_entities_filtered({area = event.area})) do
			builders_area_process_entity(e)
		end
	end

	generate_extra_worm_turrets(surface, left_top)

	if bb_config.random_scrap then
		generate_scrap(event)
	end

	if global.bb_spawn_generated then return end
	if game.tick > 0 then
		generate_potential_spawn_ore(surface)

		local area = {{-10,-10},{10,10}}
		for _, e in pairs(surface.find_entities_filtered({area = area})) do
			if e.name ~= "character" then e.destroy() end
		end
		surface.destroy_decoratives({area = area})

		for _, silo in pairs(global.rocket_silo) do
			for _, entity in pairs(surface.find_entities({{silo.position.x - 4, silo.position.y - 4}, {silo.position.x + 4, silo.position.y + 4}})) do
				if entity.type == "simple-entity" or entity.type == "tree" or entity.type == "resource" then
					entity.destroy()
				end
			end
		end

		global.bb_spawn_generated = true
	end
end

--Landfill Restriction
local function restrict_landfill(surface, inventory, tiles)
	for _, t in pairs(tiles) do
		local distance_to_center = math.sqrt(t.position.x ^ 2 + t.position.y ^ 2)
		local check_position = t.position
		if check_position.y > 0 then check_position = {x = check_position.x * -1, y = (check_position.y * -1) - 1} end
		if is_horizontal_border_river(check_position) or distance_to_center < spawn_circle_size then
			surface.set_tiles({{name = t.old_tile.name, position = t.position}}, true)
			inventory.insert({name = "landfill", count = 1})
		end
	end
end
local function on_player_built_tile(event)
	local player = game.players[event.player_index]
	restrict_landfill(player.surface, player, event.tiles)
end
local function on_robot_built_tile(event)
	restrict_landfill(event.robot.surface, event.robot.get_inventory(defines.inventory.robot_cargo), event.tiles)
end

--Construction Robot Restriction
local robot_build_restriction = {
	["north"] = function(y)
		if y >= -10 then return true end
	end,
	["south"] = function(y)
		if y <= 10 then return true end
	end
}

local function on_robot_built_entity(event)
	if not robot_build_restriction[event.robot.force.name] then return end
	if not robot_build_restriction[event.robot.force.name](event.created_entity.position.y) then return end
	local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
	inventory.insert({name = event.created_entity.name, count = 1})
	event.robot.surface.create_entity({name = "explosion", position = event.created_entity.position})
	game.print("Team " .. event.robot.force.name .. "'s construction drone had an accident.", {r = 200, g = 50, b = 100})
	event.created_entity.destroy()
end

local function on_marked_for_deconstruction(event)
	if not event.entity.valid then return end
	if event.entity.name == "fish" then event.entity.cancel_deconstruction(game.players[event.player_index].force.name) end
end

local function on_init(surface)
	local surface = game.surfaces["biter_battles"]
	if bb_config.on_init_pregen then
		Server.to_discord_embed("Generating chunks...")
		print("Generating chunks...")
		surface.request_to_generate_chunks({x = 0, y = -512}, 16)
		surface.request_to_generate_chunks({x = 1024, y = -512}, 16)
		surface.request_to_generate_chunks({x = -1024, y = -512}, 16)
		surface.force_generate_chunk_requests()
	else
		surface.request_to_generate_chunks({x = 0, y = -256}, 8)
		surface.force_generate_chunk_requests()
	end
	generate_north_silo(surface)
end

event.on_init(on_init)

event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_robot_built_tile, on_robot_built_tile)
event.add(defines.events.on_player_built_tile, on_player_built_tile)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
