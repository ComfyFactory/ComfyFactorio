-- just an empty map for testing thingies
local event = require 'utils.event'
local map_functions = require "tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'.d2

function dump_boom_layout()
	local surface = game.surfaces["empty_map"]
	game.write_file("layout.lua", "" , false)
	
	local area = {
			left_top = {x = -100, y = -100},
			right_bottom = {x = 100, y = 100}
			}
			
	local entities = surface.find_entities_filtered{area = area}
	local tiles = surface.find_tiles_filtered{area = area}
	
	local str = "{"
	for i = 1, #entities, 1 do
		if entities[i].name ~= "character" then
			str = str .. "{x = " ..  math.floor(entities[i].position.x, 0)
			str = str .. ", y = "
			str = str .. math.floor(entities[i].position.y, 0)
			str = str .. '},'
									
		end
	end
	str = str .. "}"
	game.write_file("layout.lua", str .. '\n' , true)		
end


local function on_chunk_generated(event)
	local surface = game.surfaces["empty_map"]
	if event.surface.name ~= surface.name then return end	 
	local chunk_pos_x = event.area.left_top.x
	local chunk_pos_y = event.area.left_top.y
	local area = {
			left_top = {x = chunk_pos_x, y = chunk_pos_y},
			right_bottom = {x = chunk_pos_x + 31, y = chunk_pos_y + 31}
			}							
	surface.destroy_decoratives({area = area})
	local decoratives = {}	
	
	local entities = surface.find_entities(area)
	for _, e in pairs(entities) do
		if e.valid then
			if e.name ~= "character" then
				e.destroy()				
			end
		end
	end
	
	local tiles = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = event.area.left_top.x + x, y = event.area.left_top.y + y}	
			table.insert(tiles, {name = "grass-1", position = pos}) 
		end
	end
	surface.set_tiles(tiles,true)		
end

local function draw_smoothed_out_ore_circle(position, name, surface, radius, richness)
	if not position then return end
	if not name then return end
	if not surface then return end
	if not radius then return end
	if not richness then return end
	local math_random = math.random	
	local noise_seed_add = 25000	
	local richness_part = richness / radius
	for y = radius * -3, radius * 3, 1 do
		for x = radius * -3, radius * 3, 1 do
			local pos = {x = x + position.x, y = y + position.y}
			local seed = game.surfaces[1].map_gen_settings.seed
			local noise_1 = simplex_noise(pos.x * 0.0125, pos.y * 0.0125, seed)
			seed = seed + noise_seed_add
			local noise_2 = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
			local noise = noise_1 + noise_2 * 0.12
			local distance_to_center = math.sqrt(x^2 + y^2)						
			local a = richness - richness_part * distance_to_center
			if distance_to_center < radius - math.abs(noise * radius * 0.85) and a > 1 then			
				if surface.can_place_entity({name = name, position = pos, amount = a}) then
					surface.create_entity{name = name, position = pos, amount = a}
					
					local mirror_pos = {x = pos.x * -1, y = pos.y * -1}
					surface.create_entity{name = name, position = mirror_pos, amount = a}
				end
			end			
		end
	end
end

local function on_chunk_charted(event)
	if not global.chunks_charted then global.chunks_charted = {} end
	local surface = game.surfaces[event.surface_index]
	local position = event.position
	if global.chunks_charted[tostring(position.x) .. tostring(position.y)] then return end
	global.chunks_charted[tostring(position.x) .. tostring(position.y)] = true
	local force = event.force
	
	if position.x % 4 ~= 0 then return end
	if position.y % 4 ~= 0 then return end
	--map_functions.draw_rainbow_patch_v2({x = position.x * 32, y = position.y * 32}, surface, 28, 1000)	
	--map_functions.draw_derpy_tile_circle(surface, {x = position.x * 32, y = position.y * 32}, "concrete", 20, 26)
	draw_smoothed_out_ore_circle({x = position.x * 32, y = position.y * 32}, "coal", surface, 25, 3000)
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.map_init_done then			
		local map_gen_settings = {}
		map_gen_settings.water = "none"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 20, cliff_elevation_0 = 20}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "none", size = "none", richness = "none"},
			["stone"] = {frequency = "none", size = "none", richness = "none"},
			["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
			["uranium-ore"] = {frequency = "none", size = "none", richness = "none"},
			["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
			["crude-oil"] = {frequency = "none", size = "none", richness = "none"},
			["trees"] = {frequency = "none", size = "none", richness = "none"},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"}
		}
		game.map_settings.pollution.pollution_restored_per_tree_damage = 0
		game.create_surface("empty_map", map_gen_settings)		
		game.forces["player"].set_spawn_position({0,0},game.surfaces["empty_map"])
		local surface = game.surfaces["empty_map"]
		
		surface.daytime = 1
		surface.freeze_daytime = 1
		--local radius = 512
		--game.forces.player.chart(surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})	
		global.map_init_done = true						
	end	
	local surface = game.surfaces["empty_map"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("character", {0,0}, 2, 1), "empty_map")
	else
		if player.online_time < 5 then
			player.teleport({0,0}, "empty_map")
		end
	end	
	if player.online_time < 10 then				
		player.insert {name = 'raw-fish', count = 3}
		player.insert {name = 'light-armor', count = 1}
	end	
end

event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_chunk_charted, on_chunk_charted)
event.add(defines.events.on_player_joined_game, on_player_joined_game)