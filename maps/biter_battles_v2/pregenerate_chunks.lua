local event = require 'utils.event' 

local function get_chunk_coords(radius)
	local coords = {}
	for r = radius, 1, -1 do
		for x = r * -1, r - 1, 1 do
			local pos = {x = x, y = r * -1}
			if math.sqrt(pos.x ^ 2 + pos.y ^ 2) <= radius then table.insert(coords, pos) end			
		end
		for y = r * -1, r - 1, 1 do
			local pos = {x = r, y = y}
			if math.sqrt(pos.x ^ 2 + pos.y ^ 2) <= radius then table.insert(coords, pos) end
		end	
		for x = r, r * -1 + 1, -1 do
			local pos = {x = x, y = r}
			if math.sqrt(pos.x ^ 2 + pos.y ^ 2) <= radius then table.insert(coords, pos) end
		end	
		for y = r, r * -1 + 1, -1 do
			local pos = {x = r * -1, y = y}
			if math.sqrt(pos.x ^ 2 + pos.y ^ 2) <= radius then table.insert(coords, pos) end
		end	
	end
	return coords
end

local function draw_gui(chunks_left, connected_players)	
	for _, player in pairs(connected_players) do						
		local caption = "Map is generating... " ..  chunks_left .. " chunks left."
		if player.gui.left["map_pregen"] then
			player.gui.left["map_pregen"].caption = caption
		else
			local frame = player.gui.left.add({
				type = "frame",
				caption = caption,
				name = "map_pregen"
			})
			frame.style.font_color = {r = 100, g = 100, b = 250}
			frame.style.font = "heading-2"
			frame.style.maximal_height = 36
		end		
	end
end

local function kill_gui(connected_players)
	for _, player in pairs(connected_players) do
		if player.gui.left["map_pregen"] then	player.gui.left["map_pregen"].destroy() end
	end
end

local function process_chunk(surface, coord)			
	if surface.is_chunk_generated(coord) then return end
	surface.request_to_generate_chunks({x = (coord.x * 32) - 16, y = (coord.y * 32) - 16}, 1)
	surface.force_generate_chunk_requests()
end

local function create_schedule(radius)
	local coords = get_chunk_coords(radius)
	local speed = 10
	
	for t = speed, #coords * speed + speed, speed do
		if not global.on_tick_schedule[game.tick + t] then global.on_tick_schedule[game.tick + t] = {} end	
		
		if coords[1] then			 
			global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
				func = process_chunk,
				args = {game.surfaces["biter_battles"], {x = coords[#coords].x, y = coords[#coords].y}, game}
			}
			
			global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
				func = draw_gui,
				args = {#coords, game.connected_players}
			}
		else
			global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
				func = kill_gui,
				args = {game.connected_players}
			}
		end
		
		coords[#coords] = nil
	end
end

local function on_player_joined_game(event)
	if not global.map_generation_complete then
		create_schedule(32)
		global.map_generation_complete = true		
	end
	local player = game.players[event.player_index]
	if player.gui.left["map_pregen"] then	player.gui.left["map_pregen"].destroy() end
end

event.add(defines.events.on_player_joined_game, on_player_joined_game)