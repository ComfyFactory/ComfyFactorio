-- Terrain for Biter Battles -- by MewMew
local event = require 'utils.event' 
local math_random = math.random
local simplex_noise = require 'utils.simplex_noise'.d2
local biter_territory_starting_radius = 256
local spawn_circle_size = 30

local worms = {
		[1] = {"small-worm-turret"},
		[2] = {"medium-worm-turret", "small-worm-turret"},
		[3] = {"medium-worm-turret"},
		[4] = {"big-worm-turret", "medium-worm-turret"},
		[5] = {"big-worm-turret"},
		[6] = {"behemoth-worm-turret","big-worm-turret"},
		[7] = {"behemoth-worm-turret"}
	}

local spawners = {"biter-spawner", "biter-spawner", "spitter-spawner"}
	
local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000
	if name == 1 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.005, pos.y * 0.005, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.05, pos.y * 0.05, seed)
		seed = seed + noise_seed_add
		local noise = noise[1] + noise[2] * 0.1
		--noise = noise * 0.5
		return noise
	end	
end

local function get_worm(distance_to_center)	
	local index = math.ceil((distance_to_center - biter_territory_starting_radius) * 0.01)
	if index < 1 then index = 1 end
	if index > 7 then index = 7 end
	local worm = worms[index][math_random(1, #worms[index])]
	return worm
end

local function generate_biters(surface, pos, distance_to_center)
	if distance_to_center < biter_territory_starting_radius then return end
	
	if distance_to_center < biter_territory_starting_radius + 32 then
		if math_random(1, 128) == 1 and surface.can_place_entity({name = "behemoth-worm-turret", position = pos}) then
			surface.create_entity({name = get_worm(distance_to_center), position = pos})
		end
		return
	end
	
	local noise = get_noise(1, pos)
	
	if noise > 0.5 or noise < -0.5 then		
		if math_random(1,12) == 1 and surface.can_place_entity({name = "rocket-silo", position = pos}) then
			surface.create_entity({name = spawners[math_random(1,3)], position = pos})
		end
		return
	end
	
	if noise > 0.4 or noise < -0.4 then
		if math_random(1,48) == 1 then
			if surface.can_place_entity({name = "behemoth-worm-turret", position = pos}) then
				surface.create_entity({name = get_worm(distance_to_center), position = pos})
			end
		end
		return
	end
end

local function generate_horizontal_river(surface, pos)
	if pos.y < -32 then return false end
	if pos.y > -2 and pos.y < 2 and pos.x > -2 and pos.x < 2 then return false end
	if -14 < pos.y + (get_noise(1, pos) * 5) then return true end
	return false	
end

local function generate_circle_spawn(surface)
	for x = -33, 33, 1 do
		for y = -33, 33, 1 do
			local distance_to_center = math.sqrt(x ^ 2 + y ^ 2)
			local pos = {x = x, y = y}
			local tile = false
			if distance_to_center < spawn_circle_size then tile = "deepwater" end			
			if distance_to_center < 8 then	tile = "refined-concrete"	end
			if distance_to_center < 6 then tile = "sand-1" end					
			if tile then surface.set_tiles({{name = tile, position = pos}}, true) end
		end
	end	
end

local function generate_silos()
	
end

local function on_chunk_generated(event)
	if event.area.left_top.y >= 0 then return end
	local surface = event.surface
		 
	for _, e in pairs(surface.find_entities_filtered({area = event.area, force = "enemy"})) do
		e.destroy()
	end
	
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			local distance_to_center = math.sqrt(pos.x ^ 2 + pos.y ^ 2)
			if generate_horizontal_river(surface, pos) then surface.set_tiles({{name = "deepwater", position = pos}}) end			
			generate_biters(surface, pos, distance_to_center)						
		end
	end
	
	if event.area.left_top.y == -256 and event.area.left_top.x == -256 then
		generate_circle_spawn(surface)
		generate_silos(surface)
		global.terrain_generation_complete = true
	end
end

--Landfill Prevention
local function restrict_landfill(surface, inventory, tiles)
	for _, t in pairs(tiles) do
		local distance_to_center = math.sqrt(t.position.x ^ 2 + t.position.y ^ 2)
		local check_position = t.position
		if check_position.y > 0 then check_position = {x = check_position.x * -1, y = (check_position.y * -1) - 1} end
		if generate_horizontal_river(surface, check_position) or distance_to_center < spawn_circle_size then																			
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

event.add(defines.events.on_robot_built_tile, on_robot_built_tile)
event.add(defines.events.on_player_built_tile, on_player_built_tile)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
