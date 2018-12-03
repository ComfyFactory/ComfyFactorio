--antigrief things made by mewmew

local event = require 'utils.event'

local function create_admin_button(player)
	if player.gui.top["admin_button"] then return end
	local b = player.gui.top.add({type = "button", caption = "Admin", name = "admin_button"})
	b.style.font_color = {r = 0.95, g = 0.11, b = 0.11}
	b.style.font = "default-bold"
	b.style.minimal_height = 38
	b.style.minimal_width = 38
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if player.admin == true then
		create_admin_button(player)
	end
end

local function on_player_promoted(event)
	local player = game.players[event.player_index]	
	create_admin_button(player)
end

local function on_player_demoted(event)
	local player = game.players[event.player_index]	
	if player.gui.top["admin_button"] then player.gui.top["admin_button"].destroy() end
	if player.gui.left["admin_panel"] then player.gui.left["admin_panel"].destroy() end
end

local function on_marked_for_deconstruction(event)
	if not event.player_index then return end
	local player = game.players[event.player_index]
	if player.admin == true then return end
	local playtime = player.online_time
	if global.player_totals then
		if global.player_totals[player.name] then
			playtime = player.online_time + global.player_totals[player.name][1]
		end
	end 
	if playtime < 2592000 then
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
		local str = player.name .. " at X:"
		str = str .. placed_tiles[1].position.x
		str = str .. " Y:"
		str = str .. placed_tiles[1].position.y
		table.insert(global.landfill_history, str)		
	end	
end

local function on_built_entity(event)
	if game.tick < 1296000 then return end
	
	if event.created_entity.type == "entity-ghost" then
		local player = game.players[event.player_index]
		
		if player.admin == true then return end
		
		local playtime = player.online_time
		if global.player_totals then
			if global.player_totals[player.name] then
				playtime = player.online_time + global.player_totals[player.name][1]
			end
		end
		
		if playtime < 432000 then
			event.created_entity.destroy()
			player.print("You have not grown accustomed to this technology yet.", { r=0.22, g=0.99, b=0.99})
		end		
	end
end

--Artillery History and Antigrief
local function on_player_used_capsule(event)
	local player = game.players[event.player_index]
	local position = event.position
	local used_item = event.item			
	if used_item.name ~= "artillery-targeting-remote" then return end	
	
	local playtime = player.online_time
	if global.player_totals then
		if global.player_totals[player.name] then
			playtime = player.online_time + global.player_totals[player.name][1]
		end
	end 
	if playtime < 1296000 and player.admin == false then	
		player.print("You have not grown accustomed to this technology yet.", { r=0.22, g=0.99, b=0.99})
		local area = {{position.x - 1, position.y - 1},{position.x + 1, position.y + 1}}
		local entities = player.surface.find_entities_filtered({area = area, name = "artillery-flare"})
		for _, e in pairs(entities) do			
			e.destroy()		
		end
		return
	end	
	
	if not global.artillery_history then global.artillery_history = {} end
	if #global.artillery_history > 999 then global.artillery_history = {} end
	local str = player.name .. " at X:"
	str = str .. math.floor(position.x)
	str = str .. " Y:"
	str = str .. math.floor(position.y)
	table.insert(global.artillery_history, str)	
end

local blacklisted_types = {
	["transport-belt"] = true,
	["wall"] = true,
	["underground-belt"] = true,
	["inserter"] = true,
	["land-mine"] = true,
	["gate"] = true,
	["lamp"] = true,
	["mining-drill"] = true,
	["splitter"] = true	
}

--Friendly Fire History
local function on_entity_died(event)
	if not event.cause then return end
	if event.cause.name ~= "player" then return end	
	if event.cause.force.name ~= event.entity.force.name then return end
	if blacklisted_types[event.entity.type] then return end
	local player = event.cause.player		
	if not global.friendly_fire_history then global.friendly_fire_history = {} end
	if #global.friendly_fire_history > 999 then global.friendly_fire_history = {} end
	
	local str = player.name .. " destroyed "
	str = str .. event.entity.name
	str = str .. " at X:"	
	str = str .. math.floor(event.entity.position.x)
	str = str .. " Y:"
	str = str .. math.floor(event.entity.position.y)
	
	global.friendly_fire_history[#global.friendly_fire_history + 1] = str	
end

--Mining Thieves History
local function on_player_mined_entity(event)
	if not event.entity.last_user then return end
	local player = game.players[event.player_index]
	if event.entity.last_user.name == player.name then return end
	if event.entity.force.name ~= player.force.name then return end
	if blacklisted_types[event.entity.type] then return end
		 	
	if not global.mining_history then global.mining_history = {} end
	if #global.mining_history > 999 then global.mining_history = {} end
	
	local str = player.name .. " mined "
	str = str .. event.entity.name
	str = str .. " at X:"	
	str = str .. math.floor(event.entity.position.x)
	str = str .. " Y:"
	str = str .. math.floor(event.entity.position.y)
	
	global.mining_history[#global.mining_history + 1] = str	
end

local function on_gui_opened(event)
	if not event.entity then return end
	if event.entity.name ~= "character-corpse" then return end
	local player = game.players[event.player_index].name
	local corpse_owner = game.players[event.entity.character_corpse_player_index].name
	if player ~= corpse_owner then
		game.print(player .. " is looting " .. corpse_owner .. "´s body.", { r=0.85, g=0.85, b=0.85})
	end
end

local function on_pre_player_mined_item(event)
	if event.entity.name ~= "character-corpse" then return end
	local player = game.players[event.player_index].name	
	local corpse_owner = game.players[event.entity.character_corpse_player_index].name
	if player ~= corpse_owner then
		game.print(player .. " has looted " .. corpse_owner .. "´s body.", { r=0.85, g=0.85, b=0.85})	
	end
end

event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_console_command, on_console_command)
event.add(defines.events.on_gui_opened, on_gui_opened)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_ammo_inventory_changed, on_player_ammo_inventory_changed)
event.add(defines.events.on_player_built_tile, on_player_built_tile)
event.add(defines.events.on_player_demoted, on_player_demoted)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)
event.add(defines.events.on_player_promoted, on_player_promoted)
event.add(defines.events.on_player_used_capsule, on_player_used_capsule)