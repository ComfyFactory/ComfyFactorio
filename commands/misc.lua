function generate_map(radius)
	local surface = game.players[1].surface
	if surface.is_chunk_generated({radius, radius}) then
		game.print("Map generation done!", {r=0.22, g=0.99, b=0.99})
		return
	end
	surface.request_to_generate_chunks({0,0}, radius)
	surface.force_generate_chunk_requests()
	for _, player in pairs(game.connected_players) do
		player.play_sound{path="utility/new_objective", volume_modifier=1}
	end
	game.print("Map generation done!", {r=0.22, g=0.99, b=0.99})
end

function spaghetti()
	game.forces["player"].technologies["logistic-system"].enabled = false
	game.forces["player"].technologies["construction-robotics"].enabled = false
	game.forces["player"].technologies["logistic-robotics"].enabled = false
	game.forces["player"].technologies["robotics"].enabled = false
	game.forces["player"].technologies["personal-roboport-equipment"].enabled = false
	game.forces["player"].technologies["personal-roboport-equipment-2"].enabled = false
	game.forces["player"].technologies["character-logistic-trash-slots-1"].enabled = false
	game.forces["player"].technologies["character-logistic-trash-slots-2"].enabled = false
	game.forces["player"].technologies["auto-character-logistic-trash-slots"].enabled = false
	game.forces["player"].technologies["worker-robots-storage-1"].enabled = false
	game.forces["player"].technologies["worker-robots-storage-2"].enabled = false
	game.forces["player"].technologies["worker-robots-storage-3"].enabled = false	
	game.forces["player"].technologies["character-logistic-slots-1"].enabled = false
	game.forces["player"].technologies["character-logistic-slots-2"].enabled = false
	game.forces["player"].technologies["character-logistic-slots-3"].enabled = false
	game.forces["player"].technologies["character-logistic-slots-4"].enabled = false
	game.forces["player"].technologies["character-logistic-slots-5"].enabled = false
	game.forces["player"].technologies["character-logistic-slots-6"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-1"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-2"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-3"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-4"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-5"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-6"].enabled = false
end

function dump_layout()
	local surface = game.surfaces["labyrinth"]
	game.write_file("layout.lua", "" , false)
	
	local area = {
			left_top = {x = 0, y = 0},
			right_bottom = {x = 32, y = 32}
			}
			
	local entities = surface.find_entities_filtered{area = area}
	local tiles = surface.find_tiles_filtered{area = area}
	
	for _, e in pairs(entities) do
		local str = "{position = {x = " ..  e.position.x
		str = str .. ", y = "
		str = str .. e.position.y
		str = str .. '}, name = "'
		str = str .. e.name
		str = str .. '", direction = '
		str = str .. tostring(e.direction)
		str = str .. ', force = "'
		str = str .. e.force.name
		str = str .. '"},'
		if e.name ~= "character" then
			game.write_file("layout.lua", str .. '\n' , true)
		end
	end
	
	game.write_file("layout.lua",'\n' , true)
	game.write_file("layout.lua",'\n' , true)
	game.write_file("layout.lua",'Tiles: \n' , true)
	
	for _, t in pairs(tiles) do
		local str = "{position = {x = " ..  t.position.x
		str = str .. ", y = "
		str = str .. t.position.y
		str = str .. '}, name = "'
		str = str .. t.name
		str = str .. '"},'
		game.write_file("layout.lua", str .. '\n' , true)
	end		
end