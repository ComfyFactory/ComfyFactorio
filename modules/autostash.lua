--this adds a button that stashes/sorts your inventory into nearby chests in some kind of intelligent way - mewmew

local print_color = {r = 120, g = 255, b = 0}

local function create_floaty_text(surface, position, name, count, height_offset)
	if chest_floating_text_y_offsets[position.x .. "_" .. position.y] then
		chest_floating_text_y_offsets[position.x .. "_" .. position.y] = chest_floating_text_y_offsets[position.x .. "_" .. position.y] - 0.5
	else
		chest_floating_text_y_offsets[position.x .. "_" .. position.y] = 0
	end
	surface.create_entity({
		name = "flying-text",
		position = {position.x, position.y + chest_floating_text_y_offsets[position.x .. "_" .. position.y]},
		text = "-" .. count .. " " .. name,
		color = {r = 255, g = 255, b = 255},
	})
end

local function chest_is_valid(chest)
	for _, e in pairs(chest.surface.find_entities_filtered({type = {"inserter", "loader"}, area = {{chest.position.x - 1, chest.position.y - 1},{chest.position.x + 1, chest.position.y + 1}}})) do
		if e.position.x == chest.position.x then
			if e.direction == 0 or e.direction == 4 then
				return false
			end
		end
		if e.position.y == chest.position.y then
			if e.direction == 2 or e.direction == 6 then
				return false
			end
		end
	end
	return true
end

local function get_nearby_chests(player)
	local r = player.force.character_reach_distance_bonus + 10
	local r_square = r * r
	local chests = {}
	local area = {{player.position.x - r, player.position.y - r}, {player.position.x + r, player.position.y + r}}
	for _, e in pairs(player.surface.find_entities_filtered({type = "container", area = area})) do
		if ((player.position.x - e.position.x) ^ 2 + (player.position.y - e.position.y) ^ 2) <= r_square then
			if chest_is_valid(e) then chests[#chests + 1] = e end
		end
	end
	for _, e in pairs(player.surface.find_entities_filtered({name = "logistic-chest-storage", area = area})) do
		if ((player.position.x - e.position.x) ^ 2 + (player.position.y - e.position.y) ^ 2) <= r_square then
			if chest_is_valid(e) then chests[#chests + 1] = e end
		end
	end
	for _, e in pairs(player.surface.find_entities_filtered({name = "logistic-chest-passive-provider", area = area})) do
		if ((player.position.x - e.position.x) ^ 2 + (player.position.y - e.position.y) ^ 2) <= r_square then
			if chest_is_valid(e) then chests[#chests + 1] = e end
		end
	end
	return chests
end

local function does_inventory_contain_item_type(inventory, item_subgroup)
	for name, count in pairs(inventory.get_contents()) do
		if game.item_prototypes[name].subgroup.name == item_subgroup then return true end
	end
	return false
end

local function insert_item_into_chest(player_inventory, chests, name, count)
	--Attempt to store in chests that already have the kind of item and add more of it's kind.
	for _, chest in pairs(chests) do
		local chest_inventory = chest.get_inventory(defines.inventory.chest)
		if chest_inventory.can_insert({name = name, count = count}) then
			if chest_inventory.find_item_stack(name) then
				local inserted_count = chest_inventory.insert({name = name, count = count})
				player_inventory.remove({name = name, count = inserted_count})				
				create_floaty_text(chest.surface, chest.position, name, inserted_count)
				count = count - inserted_count
				if count <= 0 then return end
			end
		end
	end
	
	--Attempt to store in empty chests.
	for _, chest in pairs(chests) do
		local chest_inventory = chest.get_inventory(defines.inventory.chest)
		if chest_inventory.can_insert({name = name, count = count}) then
			if chest_inventory.is_empty() then
				local inserted_count = chest_inventory.insert({name = name, count = count})
				player_inventory.remove({name = name, count = inserted_count})				
				create_floaty_text(chest.surface, chest.position, name, inserted_count)
				count = count - inserted_count
				if count <= 0 then return end
			end
		end
	end	
	
	--Attempt to store in chests with same item subgroup.
	local item_subgroup = game.item_prototypes[name].subgroup.name
	if item_subgroup then
		for _, chest in pairs(chests) do
			local chest_inventory = chest.get_inventory(defines.inventory.chest)
			if chest_inventory.can_insert({name = name, count = count}) then
				if does_inventory_contain_item_type(chest_inventory, item_subgroup) then
					local inserted_count = chest_inventory.insert({name = name, count = count})
					player_inventory.remove({name = name, count = inserted_count})		
					create_floaty_text(chest.surface, chest.position, name, inserted_count)
					count = count - inserted_count
					if count <= 0 then return end
				end		
			end
		end
	end
	
	--Attempt to store in mixed chests.
	for _, chest in pairs(chests) do
		local chest_inventory = chest.get_inventory(defines.inventory.chest)
		if chest_inventory.can_insert({name = name, count = count}) then			
			local inserted_count = chest_inventory.insert({name = name, count = count})
			player_inventory.remove({name = name, count = inserted_count})		
			create_floaty_text(chest.surface, chest.position, name, inserted_count)
			count = count - inserted_count
			if count <= 0 then return end		
		end
	end
end

local function auto_stash(player)
	if not player.character then player.print("It seems that you are not in the realm of the living.", print_color) return end
	if not player.character.valid then player.print("It seems that you are not in the realm of the living.", print_color) return end
	local inventory = player.get_inventory(defines.inventory.character_main)
	if inventory.is_empty() then player.print("Inventory is empty.", print_color) return end
	local chests = get_nearby_chests(player)
	if not chests[1] then player.print("No valid nearby containers found.", print_color) return end
	
	chest_floating_text_y_offsets = {}
	
	for name, count in pairs(inventory.get_contents()) do
		insert_item_into_chest(inventory, chests, name, count)
	end
end

local function create_gui_button(player)
	if player.gui.top.auto_stash then return end
	local b = player.gui.top.add({type = "sprite-button", sprite = "item/wooden-chest", name = "auto_stash", tooltip = "Stash your inventory into nearby chests."})
	b.style.font_color = {r=0.11, g=0.8, b=0.44}
	b.style.font = "heading-1"
	b.style.minimal_height = 38
	b.style.minimal_width = 38
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
end

local function on_player_joined_game(event)
	create_gui_button(game.players[event.player_index])
end

local function on_gui_click(event)
	if not event.element then return end
	if not event.element.valid then return end
	if event.element.name == "auto_stash" then
		auto_stash(game.players[event.player_index])
	end
end

local event = require 'utils.event' 
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_gui_click, on_gui_click)