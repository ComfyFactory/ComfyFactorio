-- just an empty map
local event = require 'utils.event'



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
		if entities[i].name ~= "player" then
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
	
	surface.destroy_decoratives(area)
	local decoratives = {}	
	
	local entities = surface.find_entities(area)
	for _, e in pairs(entities) do
		if e.name ~= "player" then
			e.destroy()				
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
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"},
			["grass"] = {frequency = "none", size = "none", richness = "none"},
			["sand"] = {frequency = "none", size = "none", richness = "none"},
			["desert"] = {frequency = "none", size = "none", richness = "none"},
			["dirt"] = {frequency = "normal", size = "normal", richness = "normal"}
		}
		game.map_settings.pollution.pollution_restored_per_tree_damage = 0
		game.create_surface("empty_map", map_gen_settings)		
		game.forces["player"].set_spawn_position({0,0},game.surfaces["empty_map"])
		local surface = game.surfaces["empty_map"]
		
		--create_cluster("crude-oil", {x=0,y=0}, 5, surface, 10, math.random(300000,400000))
		global.map_init_done = true						
	end	
	local surface = game.surfaces["empty_map"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("player", {0,0}, 2, 1), "empty_map")
	else
		if player.online_time < 5 then
			player.teleport({0,0}, "empty_map")
		end
	end	
	if player.online_time < 10 then				
		player.insert {name = 'raw-fish', count = 3}
		player.insert {name = 'iron-axe', count = 1}
		player.insert {name = 'light-armor', count = 1}
	end	
end

event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)