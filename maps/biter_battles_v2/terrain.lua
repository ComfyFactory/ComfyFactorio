-- Terrain for Biter Battles -- by MewMew
local event = require 'utils.event' 
local math_random = math.random
local simplex_noise = require 'utils.simplex_noise'.d2
local biter_territory_starting_radius = 160

local worms = {
		[1] = {"small-worm-turret"},
		[2] = {"medium-worm-turret", "small-worm-turret"},
		[3] = {"medium-worm-turret"},
		[4] = {"big-worm-turret", "medium-worm-turret"},
		[5] = {"big-worm-turret"},
		[6] = {"behemoth-worm-turret","big-worm-turret"},
		[7] = {"behemoth-worm-turret"}
	}

local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000
	if name == 1 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.005, pos.y * 0.005, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		local noise = noise[1] + noise[2] * 0.25
		--noise = noise * 0.5
		return noise
	end	
end

local function get_worm(distance_to_center)	
	local index = math.ceil((distance_to_center - biter_territory_starting_radius) * 0.01)
	if index > 7 then index = 7 end
	local worm = worms[index][math_random(1, #worms[index])]
	return worm
end

local function generate_biters(surface, pos, distance_to_center)
	if distance_to_center < biter_territory_starting_radius then return end
	
	if distance_to_center < biter_territory_starting_radius + 64 then
		if math_random(1,96) == 1 and surface.can_place_entity({name = "behemoth-worm-turret", position = pos}) then
			surface.create_entity({name = get_worm(distance_to_center), position = pos})
		end
		return
	end
	
	local noise = get_noise(1, pos)
	
	if noise > 0.3 or noise < -0.3 then		
		if math_random(1,8) == 1 and surface.can_place_entity({name = "rocket-silo", position = pos}) then
			surface.create_entity({name = "biter-spawner", position = pos})
		end
		return
	end
	
	if noise < 0.1 or noise > -0.1 then
		if math_random(1,64) == 1 then
			if surface.can_place_entity({name = "behemoth-worm-turret", position = pos}) then
				surface.create_entity({name = get_worm(distance_to_center), position = pos})
			end
		end
		return
	end
end

local function on_chunk_generated(event)
	if event.area.left_top.y >= 0 then return end
	local surface = event.surface
		 
	for _, e in pairs(surface.find_entities_filtered({area = event.area, force = "enemy"})) do
		e.destroy()
	end
	
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	for x = 0.5, 31.5, 1 do
		for y = 0.5, 31.5, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			local distance_to_center = math.sqrt(pos.x ^ 2 + pos.y ^ 2)
			generate_biters(surface, pos, distance_to_center)
		end
	end
	
end

event.add(defines.events.on_chunk_generated, on_chunk_generated)
