--When a player is banned, their inventory will be spilled on the ground.

local function drop_inventory(player, inventory)
	if not inventory then return end
	if not inventory.valid then return end
	if inventory.is_empty() then return end
	local position = player.position
	local surface = player.surface
	for i = 1, #inventory, 1 do
		if inventory[i] and inventory[i].valid_for_read then
			surface.spill_item_stack(position, inventory[i], true)
		end
	end	
	inventory.clear()
end

local function on_player_banned(event)
	local player = game.players[event.player_index]
	local position = player.position
	drop_inventory(player, player.get_inventory(defines.inventory.character_main))
	drop_inventory(player, player.get_inventory(defines.inventory.character_guns))
	drop_inventory(player, player.get_inventory(defines.inventory.character_ammo))
	drop_inventory(player, player.get_inventory(defines.inventory.character_armor))
	drop_inventory(player, player.get_inventory(defines.inventory.character_trash))
end

local Event = require 'utils.event'
Event.add(defines.events.on_player_banned, on_player_banned)