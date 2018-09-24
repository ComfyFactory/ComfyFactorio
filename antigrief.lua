local event = require 'utils.event'

local function jail(player)
	
end

local function free(player)
	
end

local function on_marked_for_deconstruction(event)
	local player = game.players[event.player_index]
	if player.admin == true then return end
	local playtime = player.online_time
	if global.player_totals then
		if global.player_totals[player.name] then
			playtime = player.online_time + global.player_totals[player.name][1]
		end
	end 
	if playtime < 1296000 then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)	
		player.print("You have not grown accustomed to this technology yet.", { r=0.22, g=0.99, b=0.99})
	end
end

local function on_player_ammo_inventory_changed(event)
	local player = game.players[event.player_index]
	if player.admin == true then return end
	local playtime = player.online_time
	if global.player_totals then
		if global.player_totals[player.name] then
			playtime = player.online_time + global.player_totals[player.name][1]
		end
	end	      
	if playtime < 1296000 then
		local nukes = player.remove_item({name="atomic-bomb", count=1000})
		if nukes > 0 then
			player.surface.spill_item_stack(player.position, {name = "atomic-bomb", count = nukes}, false)
			player.print("You have not grown accustomed to this technology yet.", { r=0.22, g=0.99, b=0.99})
		end
	end
end

local function on_console_command(event)
	if event.command ~= "silent-command" then return end
	if not event.player_index then return end
	local player = game.players[event.player_index]	
	for _, p in pairs(game.connected_players) do
		if p.admin == true and p.name ~= player.name then
			p.print(player.name .. " did a silent-command: " .. event.parameters, { r=0.22, g=0.99, b=0.99})
		end
	end
end

local function on_player_built_tile(event)
	local placed_tiles = event.tiles
	local player = game.players[event.player_index]	
	
	--landfill history--
	if placed_tiles[1].old_tile.name == "deepwater" or placed_tiles[1].old_tile.name == "water" or placed_tiles[1].old_tile.name == "water-green" then		
		if not global.landfill_history then global.landfill_history = {} end
		if #global.landfill_history > 999 then global.landfill_history = {} end
		local str = player.name .. " placed landfill at X:"
		str = str .. placed_tiles[1].position.x
		str = str .. " Y:"
		str = str .. placed_tiles[1].position.y
		table.insert(global.landfill_history, str)		
	end	
end

event.add(defines.events.on_player_built_tile, on_player_built_tile)
event.add(defines.events.on_console_command, on_console_command)
event.add(defines.events.on_player_ammo_inventory_changed, on_player_ammo_inventory_changed)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)