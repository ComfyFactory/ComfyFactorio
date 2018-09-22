--this script provides a way to keep track of player data across multiple play sessions
--playtime or other data can be saved in /script-output in the factorio folder
--to update the stats for the next game session:
--move the ../factorio/script-output files to ../factorio/scenarios/**SCENARIONAME**/session_data/
--and add the names of the new files after "local index = {" in the session_data.lua

local Event = require 'utils.event' 
local play_sessions = require 'session_data'

local function on_player_changed_position(event)
	if not global.file_name_found then
		if global.movement_done < global.movement_amount_required then
			local player = game.players[event.player_index]	
			global.movement_done = global.movement_done + 1		
		else
			if string.len(global.file_name) < 16 then	
				if math.random(1,2) == 1 then
					global.file_name = global.file_name .. string.char(math.random(97,122))
				else
					global.file_name = global.file_name .. string.char(math.random(65,90))
				end			
				global.movement_done = 0
			end
		end
		if string.len(global.file_name) == 16 then
			global.file_name = global.file_name .. ".lua"
			--game.print("Session data will be saved as " .. global.file_name,{r = 0.9, g = 0.9, b = 0.9})
			global.file_name_found = true
		end
	end
end

local function on_player_joined_game(event)
	if not global.tracker_init_done then		
		global.movement_done = 0
		global.file_name = ""
		global.movement_amount_required = 16
		global.player_totals = {}
		for _, session in pairs(play_sessions) do									
			for _, player_data in pairs(session) do
				if not global.player_totals[player_data[1]] then
					global.player_totals[player_data[1]] = {player_data[2][1]}
				else
					global.player_totals[player_data[1]] = {global.player_totals[player_data[1]][1] + player_data[2][1]}
				end
			end			
		end
		global.tracker_init_done = true
	end	
end

local function on_tick()
	if global.file_name_found then
		if game.tick % 36000 == 0 then
			game.remove_path(global.file_name)
			game.write_file(global.file_name, "local playsession = {\n" , true)
			for x = 1, #game.players, 1 do
				local p = game.players[x]
				local str = ""
				if game.players[x+1] then str = "," end
				game.write_file(global.file_name, '\t{"' .. p.name .. '", {' .. p.online_time .. '}}' .. str .. '\n' , true)
			end
			game.write_file(global.file_name, "}\nreturn playsession" , true)
		end
	end
end

Event.add(defines.events.on_tick, on_tick)	
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)