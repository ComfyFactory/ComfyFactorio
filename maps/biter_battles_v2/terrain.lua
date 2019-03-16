-- Terrain for Biter Battles -- by MewMew
local event = require 'utils.event' 
local math_random = math.random
local simplex_noise = require 'utils.simplex_noise'.d2
local create_tile_chain = require "functions.create_tile_chain"
local spawn_circle_size = 28
local ores = {"copper-ore", "iron-ore", "stone", "coal"}	
	
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

local function generate_horizontal_river(surface, pos)
	if pos.y < -32 then return false end
	if pos.y > -3 and pos.x > -3 and pos.x < 3 then return false end
	if -14 < pos.y + (get_noise(1, pos) * 5) then return true end
	return false	
end

local function generate_circle_spawn(event)
	if event.area.left_top.y < -64 then return end
	if event.area.left_top.x < -64 then return end
	if event.area.left_top.x > 64 then return end	
	local surface = event.surface		
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			local distance_to_center = math.sqrt(pos.x ^ 2 + pos.y ^ 2)
			
			local tile = false
			if distance_to_center < spawn_circle_size then
				tile = "deepwater"
				if math_random(1, 48) == 1 then surface.create_entity({name = "fish", position = pos}) end
			end						
			if distance_to_center < 9 then tile = "refined-concrete" end
			if distance_to_center < 6 then tile = "sand-1" end					
			if tile then surface.set_tiles({{name = tile, position = pos}}, true) end
		end
	end
end

local function generate_silos(event)
	if global.rocket_silo then return end
	if event.area.left_top.y < -128 then return end
	if event.area.left_top.x < -128 then return end
	if event.area.left_top.x > 128 then return end
	global.rocket_silo = {}	
	local surface = event.surface
	global.rocket_silo["north"] =surface.create_entity({
		name = "rocket-silo",
		position = surface.find_non_colliding_position("rocket-silo", {0,-64}, 128, 1),
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
			if generate_horizontal_river(surface, pos) then
				surface.set_tiles({{name = "deepwater", position = pos}})
				if math_random(1, 48) == 1 then surface.create_entity({name = "fish", position = pos}) end
			end			
		end
	end
end

local function generate_rainbow_ore(event)
	local surface = event.surface
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			if surface.can_place_entity({name = "iron-ore", position = pos}) then
				local noise = get_noise(1, pos)
				if noise > 0.83 then
					local amount = math_random(1500, 2000) + math.sqrt(pos.x ^ 2 + pos.y ^ 2) * noise * 4
					local i = math.ceil(math.abs(noise * 25)) % 4
					if i == 0 then i = 4 end
					surface.create_entity({name = ores[i], position = pos, amount = amount}) 
				end
			end
		end
	end
end

local function on_chunk_generated(event)
	if event.area.left_top.y >= 0 then return end
	local surface = event.surface
	if surface.name ~= "biter_battles" then return end		 	
	
	for _, e in pairs(surface.find_entities_filtered({area = event.area, force = "enemy"})) do
		surface.create_entity({name = e.name, position = e.position, force = "north_biters", direction = e.direction})
		e.destroy()
	end
	
	generate_river(event)
	generate_circle_spawn(event)
	generate_silos(event)
	generate_rainbow_ore(event)
	
	if event.area.left_top.y == -160 and event.area.left_top.x == -160 then
		local area = {{-10,-10},{10,10}}
		for _, e in pairs(surface.find_entities_filtered({area = area})) do
			if e.name ~= "player" then e.destroy() end
		end
		surface.destroy_decoratives({area = area})
	end
end

--Landfill Restriction
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

--Construction Robot Restriction
local function on_robot_built_entity(event)
	local deny_building = false
	local force_name = event.robot.force.name
	if force_name == "north" then
		if event.created_entity.position.y >= -10 then deny_building = true end
	end
	if force_name == "player" then
		if event.created_entity.position.y <= 10 then deny_building = true end
	end	
	if not deny_building then return end
	local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
	inventory.insert({name = event.created_entity.name, count = 1})
	event.robot.surface.create_entity({name = "explosion", position = event.created_entity.position})
	event.created_entity.destroy()			
end

--Prevent Players from damaging the Rocket Silo
local function on_entity_damaged(event)	
	if event.cause then
		if event.cause.type == "unit" then return end		 
	end
	if event.entity.name ~= "rocket-silo" then return end		
	event.entity.health = event.entity.health + event.final_damage_amount
end

local function on_marked_for_deconstruction(event)
	if event.entity.name == "fish" then event.entity.cancel_deconstruction(game.players[event.player_index].force.name) end
end

event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_robot_built_tile, on_robot_built_tile)
event.add(defines.events.on_player_built_tile, on_player_built_tile)
event.add(defines.events.on_chunk_generated, on_chunk_generated)