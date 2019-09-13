local map_functions = require "tools.map_functions"
local simplex_noise = require "utils.simplex_noise".d2
local math_random = math.random

local hourglass_center_piece_length = 64
local worm_raffle_table = {
		[1] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret"},
		[2] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret"},
		[3] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret"},
		[4] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret"},
		[5] = {"small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"},
		[6] = {"small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"},
		[7] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret"},
		[8] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret"},
		[9] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"},
		[10] = {"medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"}
	}	
local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}

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

local function spawn_obstacles(left_top, surface)
	if not global.obstacle_start_x then global.obstacle_start_x = math.abs(left_top.x) - 32 end
	local current_depth = math.abs(left_top.x) - global.obstacle_start_x
	local worm_amount = math.ceil(current_depth / 64)
	local i = math.ceil(current_depth / 256)
	if i > 10 then i = 10 end
	if i < 1 then i = 1 end
	local worm_raffle = worm_raffle_table[i]

	local rocks_amount = math.ceil(current_depth / 16)

	local tile_positions = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if not surface.get_tile(pos).collides_with("player-layer") then
				tile_positions[#tile_positions + 1] = pos
			end
		end
	end
	if #tile_positions == 0 then return end

	table.shuffle_table(tile_positions)
	for _, pos in pairs(tile_positions) do
		surface.create_entity({name = worm_raffle[math_random(1, #worm_raffle)], position = pos, force = "enemy"})
		worm_amount = worm_amount - 1
		if worm_amount < 1 then break end
	end

	table.shuffle_table(tile_positions)
	for _, pos in pairs(tile_positions) do
		surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = pos})
		rocks_amount = rocks_amount - 1
		if rocks_amount < 1 then break end
	end
end

local function is_enemy_territory(p)
	if p.x - 64 < math.abs(p.y) then return false end
	--if p.x - 64 < p.y then return false end
	if p.x < 160 then return false end
	if p.x > 1024 then return false end
	if p.y > 512 then return false end
	if p.y < -512 then return false end
	local noise = math.abs(simplex_noise(0, p.y * 0.015, game.surfaces[1].map_gen_settings.seed) * 96)
	local noise_2 = math.abs(simplex_noise(0, p.y * 0.1, game.surfaces[1].map_gen_settings.seed) * 16)
	if p.x > 288 + noise + noise_2 + math.abs(p.y * 0.75) then return false end
	return true
end

local body_radius = 3072
local body_square_radius = body_radius ^ 2
local body_center_position = {x = -1500, y = 0}
local body_spacing = math.floor(body_radius * 0.82)
local body_circle_center_1 = {x = body_center_position.x, y = body_center_position.y - body_spacing}
local body_circle_center_2 = {x = body_center_position.x, y = body_center_position.y + body_spacing}

local fin_radius = 800
local square_fin_radius = fin_radius ^ 2
local fin_circle_center_1 = {x = -480, y = 0}
local fin_circle_center_2 = {x = -480 - 360, y = 0}

local function is_body(p)	
	if p.y <= map_height and p.y >= map_height * -1 and p.x <= 160 and p.x > body_center_position.x then return true end
	
	--Main Fish Body			
	local distance_to_center_1 = ((p.x - body_circle_center_1.x)^2 + (p.y - body_circle_center_1.y)^2)
	local distance_to_center_2 = ((p.x - body_circle_center_2.x)^2 + (p.y - body_circle_center_2.y)^2)	
	if distance_to_center_1 < body_square_radius and distance_to_center_2 < body_square_radius then return true end
	
	--Fish Fins
	local distance_to_center_1 = ((p.x - fin_circle_center_1.x)^2 + (p.y - fin_circle_center_1.y)^2)
	if distance_to_center_1 + math.abs(simplex_noise(0, p.y * 0.075, game.surfaces[1].map_gen_settings.seed) * 32000) > square_fin_radius then
		local distance_to_center_2 = ((p.x - fin_circle_center_2.x)^2 + (p.y - fin_circle_center_2.y)^2)
		if distance_to_center_2 < square_fin_radius then
			return true
		end
	end
	
	return false
end

local function is_out_of_map_tile(surface, p)
	if is_enemy_territory(p) then return false end
	if is_body(p) then return false end
	return true
end

local function generate_spawn_area(surface, left_top)
	if global.spawn_ores_generated then return end
	if left_top.x ~= -256 then return end
	if left_top.y ~= -256 then return end
	
	local spawn_position_x = -76

	surface.create_entity({name = "electric-beam", position = {160, -96}, source = {160, -96}, target = {160,96}})

	for _, tile in pairs(surface.find_tiles_filtered({name = {"water", "deepwater"}, area = {{-160, -160},{160, 160}}})) do
		local noise = math.abs(simplex_noise(tile.position.x * 0.02, tile.position.y * 0.02, game.surfaces[1].map_gen_settings.seed) * 16)
		if tile.position.x > -160 + noise then	surface.set_tiles({{name = get_replacement_tile(surface, tile.position), position = {tile.position.x, tile.position.y}}}, true) end
	end
	
	local entities = surface.find_entities_filtered({type = {"resource", "cliff"}, area = {{-160, -160},{160, 160}}})
	for _, entity in pairs(entities) do
		entity.destroy()
	end	

	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
		  decorative_names[#decorative_names+1] = k
		end
	 end
	for x = -4, 4, 1 do
		for y = -3, 3, 1 do
			surface.regenerate_decorative(decorative_names, {{x,y}})
		end
	end

	local ore_positions = {{x = -128, y = -64},{x = -128, y = -32},{x = -128, y = 32},{x = -128, y = 64},{x = -128, y = 0}}
	table.shuffle_table(ore_positions)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[1], "copper-ore", surface, 15, 2500)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[2], "iron-ore", surface, 15, 2500)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[3], "coal", surface, 15, 1500)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[4], "stone", surface, 15, 1500)
	map_functions.draw_noise_tile_circle({x = -96, y = 0}, "water", surface, 16)
	map_functions.draw_oil_circle(ore_positions[5], "crude-oil", surface, 8, 200000)

	local pos = surface.find_non_colliding_position("market",{spawn_position_x, 0}, 50, 1)
	global.market = place_fish_market(surface, pos)
	
	local r = 96
	for _, entity in pairs(surface.find_entities_filtered({area = {{global.market.position.x - r, global.market.position.y - r}, {global.market.position.x + r, global.market.position.y + r}}, type = "tree"})) do
		local distance_to_center = math.sqrt((entity.position.x - global.market.position.x)^2 + (entity.position.y - global.market.position.y)^2)
		if distance_to_center < r then
			if math_random(1, r) > distance_to_center then entity.destroy() end
		end
	end
	
	local pos = surface.find_non_colliding_position("gun-turret",{spawn_position_x + 5, 1}, 50, 1)
	local turret = surface.create_entity({name = "gun-turret", position = pos, force = "player"})
	turret.insert({name = "firearm-magazine", count = 32})

	for x = -20, 20, 1 do
		for y = -20, 20, 1 do
			local pos = {x = global.market.position.x + x, y = global.market.position.y + y}
			local distance_to_center = math.sqrt(x^2 + y^2)
			if distance_to_center > 8 and distance_to_center < 15 then
				if math_random(1,3) == 1 and surface.can_place_entity({name = "wooden-chest", position = pos, force = "player"}) then
					local chest = surface.create_entity({name = "wooden-chest", position = pos, force = "player"})
				end
			end
		end
	end

	local area = {{x = -160, y = -96}, {x = 160, y = 96}}
	for _, tile in pairs(surface.find_tiles_filtered({name = "water", area = area})) do
		if math_random(1, 32) == 1 then
			surface.create_entity({name = "fish", position = tile.position})
		end
	end

	local pos = surface.find_non_colliding_position("character",{spawn_position_x + 1, 4}, 50, 1)
	game.forces["player"].set_spawn_position(pos, surface)
	for _, player in pairs(game.connected_players) do
		local pos = surface.find_non_colliding_position("character",{spawn_position_x + 1, 4}, 50, 1)
		player.teleport(pos, surface)
	end

	global.spawn_ores_generated = true
end

local function enemy_territory_entities_and_tiles(surface, pos)
	if not is_enemy_territory(pos) then return end
	--if surface.get_tile(pos).name == "out-of-map" then return end
	if pos.x < 160 then return end
	local a = 0 + (pos.x - 160) * 0.01
	local b = (pos.x - 160) * 0.035
	local r = (pos.x - 160) * 0.015
	if a > 0.75 then a = 0.75 end
	if b > 1 then b = 1 end
	if r > 0.6 then r = 0.6 end
	
	rendering.draw_sprite({sprite = "tile/lab-dark-2", target = {pos.x + 0.5, pos.y + 0.5}, surface = surface, tint = {r = r, g = 0, b = b, a = a}, render_layer = "ground"})

	if pos.x > 296 and math_random(1, 256) == 1 then
		if surface.can_place_entity({name = "biter-spawner", force = "decoratives", position = pos}) then
			local entity
			if math_random(1,4) == 1 then
				entity = surface.create_entity({name = "spitter-spawner", force = "decoratives", position = pos})
			else
				entity = surface.create_entity({name = "biter-spawner", force = "decoratives", position = pos})
			end
			entity.active = false
			entity.destructible = false
		end
	end	
end

local function enemy_territory(surface, left_top, area)
	for _, entity in pairs(surface.find_entities_filtered({area = area, type = {"tree", "cliff"}})) do
		if is_enemy_territory(entity.position) then entity.destroy() end
	end

	for _, entity in pairs(surface.find_entities_filtered({area = area, type = "resource"})) do
		if is_enemy_territory(entity.position) then
			surface.create_entity({name = "uranium-ore", position = entity.position, amount = math_random(200, 8000)})
			entity.destroy()
		end
	end

	for _, tile in pairs(surface.find_tiles_filtered({name = {"water", "deepwater"}, area = area})) do
		if is_enemy_territory(tile.position) then
			surface.set_tiles({{name = get_replacement_tile(surface, tile.position), position = {tile.position.x, tile.position.y}}}, true)
		end
	end
	
	if is_enemy_territory(left_top) then
		local decorative_names = {}
		for k,v in pairs(game.decorative_prototypes) do
			if v.autoplace_specification then
			  decorative_names[#decorative_names+1] = k
			end
		 end
		surface.regenerate_decorative(decorative_names, {{x=math.floor(left_top.x/32),y=math.floor(left_top.y/32)}})
	end
end

local function fish_mouth(surface, pos)
	if pos.y > 64 then return end
	if pos.y < -64 then return end
	if pos.x > -2300 then return end
	if pos.x < -3260 then return end
	local noise = simplex_noise(pos.x * 0.006, 0, game.surfaces[1].map_gen_settings.seed) * 20
	if pos.y > 12 + noise then return end
	if pos.y < -12 + noise then return end
	surface.set_tiles({{name = "water", position = pos}})
end

local function plankton_territory(surface, position)	
	local noise = simplex_noise(position.x * 0.01, position.y * 0.01, game.surfaces[1].map_gen_settings.seed)
	local d = 256
	if position.x + position.y > (d * -1) - (math.abs(noise) * d) and position.x > position.y - (d + (math.abs(noise) * d)) then return false end
	
	if noise > 0.8 then surface.set_tiles({{name = "deepwater-green", position = position}}, true) return true end
	if noise > 0.7 then surface.set_tiles({{name = "grass-2", position = position}}, true) return true end	
	if noise < -0.7 then
		surface.set_tiles({{name = "grass-2", position = position}}, true)
		if noise < -0.78 then surface.create_entity({name = "uranium-ore", position = position, amount = 1000 * math.abs(noise * 2)}) end
		return true 
	end

	local noise_2 = simplex_noise(position.x * 0.01, position.y * 0.01, game.surfaces[1].map_gen_settings.seed + 10000)
	if noise_2 < 0.10 and noise_2 > -0.10 then
		surface.set_tiles({{name = "dirt-7", position = position}}, true)
		if math_random(1, 3) ~= 1 then surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = position}) end
		return true
	end
	
	surface.set_tiles({{name = "water", position = position}}, true)
	return true
end

local function on_chunk_generated(event)
	local surface = game.surfaces["fish_defender"]
	if not surface then return end
	if surface.name ~= event.surface.name then return end

	local left_top = event.area.left_top

	generate_spawn_area(surface, left_top)	
	enemy_territory(surface, left_top, event.area)

	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if is_out_of_map_tile(surface, pos) then	
				if not plankton_territory(surface, pos) then surface.set_tiles({{name = "out-of-map", position = pos}}, true) end
			else
				enemy_territory_entities_and_tiles(surface, pos)
				fish_mouth(surface, pos)
			end
		end
	end

	--if left_top.x < -2048 then spawn_obstacles(left_top, surface) end	
end

local event = require 'utils.event'
event.add(defines.events.on_chunk_generated, on_chunk_generated)