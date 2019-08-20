local function reset_forces()
	for _, f in pairs(game.forces) do
		f.reset()
	end
end

local function set_spawn_positions(new_surface, old_surface)
	for _, f in pairs(game.forces) do
		f.set_spawn_position(f.get_spawn_position(old_surface), new_surface)
	end
end

local function teleport_players(surface)	
	for _, player in pairs(game.connected_players) do
		local spawn = player.force.get_spawn_position(surface)
		local chunk = {math.floor(spawn.x / 32), math.floor(spawn.y / 32)}
		if not surface.is_chunk_generated(chunk) then
			surface.request_to_generate_chunks(spawn, 2)
			surface.force_generate_chunk_requests()
		end		
		local pos = surface.find_non_colliding_position("character", spawn, 1, 0.5)
		player.teleport(pos, surface)
	end
end

local function equip_players(player_starting_items)
	for k, player in pairs(game.connected_players) do
		if player.character then	player.character.destroy()	end
		player.character = nil
		player.set_controller({type=defines.controllers.god})
		player.create_character()
		for item, amount in pairs(player_starting_items) do
			player.insert({name = item, count = amount})
		end
	end
end

function soft_reset_map(old_surface, map_gen_settings, player_starting_items)
	if not global.soft_reset_counter then global.soft_reset_counter = 0 end
	if not global.original_surface_name then global.original_surface_name = old_surface.name end
	global.soft_reset_counter = global.soft_reset_counter + 1

	local new_surface = game.create_surface(global.original_surface_name .. "_" .. tostring(global.soft_reset_counter), map_gen_settings)
	new_surface.request_to_generate_chunks({0,0}, 3)
	new_surface.force_generate_chunk_requests()
	
	reset_forces()
	set_spawn_positions(new_surface, old_surface)
	teleport_players(new_surface)
	equip_players(player_starting_items)
	
	game.delete_surface(old_surface)
	
	if global.soft_reset_counter > 1 then
		game.print(">> The world has been reshaped, welcome to " .. global.original_surface_name .. " number " .. tostring(global.soft_reset_counter) .. "!", {r=0.98, g=0.66, b=0.22})
	else
		game.print(">> Welcome to " .. global.original_surface_name .. "!", {r=0.98, g=0.66, b=0.22})
	end
	
	return new_surface
end