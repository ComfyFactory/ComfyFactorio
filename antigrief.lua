require "utils.utils"

local event = require 'utils.event'

local function on_marked_for_deconstruction(event)
	local player = game.players[event.player_index]
	local playtime = player.online_time
	if global.player_totals then
		if global.player_totals[player.name] then
			playtime = player.online_time + global.player_totals[player.name][1]
		end
	end 
	if playtime < 1296000 then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)	
		player.print("You have not grown accustomed to this technology yet.")
	end
end

--[[
local function on_entity_died(event)
	local player = game.players[event.player_index]
	local playtime = player.online_time
	if global.player_totals then
		if global.player_totals[player.name] then
			playtime = player.online_time + global.player_totals[player.name][1]
		end
	end 
	if playtime < 1296000 then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)	
		player.print("You have not grown accustomed to this technology yet.")
	end
end
event.add(defines.events.on_entity_died, on_entity_died)
]]--

event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)