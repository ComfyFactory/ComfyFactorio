local Public = {}

local Constants = require "modules.immersive_cargo_wagons.constants"

local table_insert = table.insert
local table_remove = table.remove
local math_round = math.round
local math_random = math.random

function Public.request_reconstruction(icw)
	icw.rebuild_tick = game.tick + 30
end

local function delete_empty_surfaces(icw)
	for k, surface in pairs(icw.surfaces) do
		if not icw.trains[tonumber(surface.name)] then
			game.delete_surface(surface)
			table_remove(icw.surfaces, k)
		end
	end
end	

local function divide_fluid(wagon, storage_tank)
	local wagon_fluidbox = wagon.entity.fluidbox
	local fluid_wagon = wagon.entity
	local wagon_fluid = wagon_fluidbox[1]
	local tank_fluidbox = storage_tank.fluidbox
	local tank_fluid = tank_fluidbox[1]
	if not wagon_fluid and not tank_fluid then return end
	if wagon_fluid and tank_fluid then
		if wagon_fluid.name ~= tank_fluid.name then return end
	end
	if not wagon_fluid then
		wagon_fluidbox[1] = {name = tank_fluid.name, amount = tank_fluid.amount * 0.5, temperature = tank_fluid.temperature}
		storage_tank.remove_fluid({name = tank_fluid.name, amount = tank_fluid.amount * 0.5})
		return
	end
	if not tank_fluid then
		tank_fluidbox[1] = {name = wagon_fluid.name, amount = wagon_fluid.amount * 0.5, temperature = wagon_fluid.temperature}
		fluid_wagon.remove_fluid({name = wagon_fluid.name, amount = wagon_fluid.amount * 0.5})
		return
	end
	
	local a = (wagon_fluid.amount + tank_fluid.amount) * 0.5
	local n = wagon_fluid.name
	local t = wagon_fluid.temperature
	
	wagon_fluidbox[1] = {name = n, amount = a, temperature = t}
	tank_fluidbox[1] = {name = n, amount = a, temperature = t}
end

local function input_filtered(wagon_inventory, chest, chest_inventory, free_slots)
	local request_stacks = {}
	local prototypes = game.item_prototypes
	for slot_index = 1, 4, 1 do
		local stack = chest.get_request_slot(slot_index)
		if stack then
			request_stacks[stack.name] = 10 * prototypes[stack.name].stack_size
		end
	end
	for i = 1, wagon_inventory.get_bar() - 1, 1 do
		if free_slots <= 0 then return end
		local stack = wagon_inventory[i]
		if stack.valid_for_read then
			local request_stack = request_stacks[stack.name]
			if request_stack and request_stack > chest_inventory.get_item_count(stack.name) then			
				chest_inventory.insert(stack)
				stack.clear()
				free_slots = free_slots - 1
			end
		end		
	end
end

local function input_cargo(wagon, chest)
	local wagon_inventory = wagon.entity.get_inventory(defines.inventory.cargo_wagon)
	if wagon_inventory.is_empty() then return end
	if not chest.request_from_buffers then return end
	 	
	local chest_inventory = chest.get_inventory(defines.inventory.chest)	
	local free_slots = 0
	for i = 1, chest_inventory.get_bar() - 1, 1 do
		if not chest_inventory[i].valid_for_read then free_slots = free_slots + 1 end
	end	
	
	if chest.get_request_slot(1) then input_filtered(wagon_inventory, chest, chest_inventory, free_slots) return end
	
	for i = 1, wagon_inventory.get_bar() - 1, 1 do
		if free_slots <= 0 then return end
		if wagon_inventory[i].valid_for_read then
			chest_inventory.insert(wagon_inventory[i])
			wagon_inventory[i].clear()
			free_slots = free_slots - 1
		end		
	end
end

local function output_cargo(wagon, passive_chest)
	local passive_chest_inventory = passive_chest.get_inventory(defines.inventory.cargo_wagon)
	if passive_chest_inventory.is_empty() then return end
	local wagon_inventory = wagon.entity.get_inventory(defines.inventory.cargo_wagon)	
	local free_slots = 0
	for i = 1, wagon_inventory.get_bar() - 1, 1 do
		if not wagon_inventory[i].valid_for_read and not wagon_inventory.get_filter(i) then free_slots = free_slots + 1 end
	end
	for i = 1, passive_chest_inventory.get_bar() - 1, 1 do
		if free_slots <= 0 then return end
		if passive_chest_inventory[i].valid_for_read then
			wagon_inventory.insert(passive_chest_inventory[i])
			passive_chest_inventory[i].clear()
			free_slots = free_slots - 1
		end		
	end
end

local transfer_functions = {
	["storage-tank"] = divide_fluid,
	["logistic-chest-requester"] = input_cargo,
	["logistic-chest-passive-provider"] = output_cargo,
}

local function get_wagon_for_entity(icw, entity)
	local train = icw.trains[tonumber(entity.surface.name)]
	if not train then return end
	local position = entity.position
	for k, unit_number in pairs(train.wagons) do
		local wagon = icw.wagons[unit_number]
		local left_top = wagon.area.left_top
		local right_bottom = wagon.area.right_bottom
		if position.x >= left_top.x and position.y >= left_top.y and position.x <= right_bottom.x and position.y <= right_bottom.y then
			return wagon
		end
	end
	return false
end

local function kill_wagon_doors(icw, wagon)
	for k, e in pairs(wagon.doors) do
		icw.doors[e.unit_number] = nil
		e.destroy()		
		wagon.doors[k] = nil
	end
end

local function construct_wagon_doors(icw, wagon)
	local area = wagon.area
	local surface = wagon.surface
	
	for _, x in pairs({area.left_top.x - 0.55, area.right_bottom.x + 0.55}) do
		local e = surface.create_entity({
			name = "car",
			position = {x, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5)},
			force = "neutral",
			create_build_effect_smoke = false
		})
		e.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 1})
		e.destructible = false
		e.minable = false
		e.operable = false
		icw.doors[e.unit_number] = wagon.entity.unit_number
		table_insert(wagon.doors, e)
	end
end

function Public.kill_minimap(player)
	local element = player.gui.left.icw_map
	if element then element.destroy() end
end

function Public.kill_wagon(icw, entity)
	if not Constants.wagon_types[entity.type] then return end
	local wagon = icw.wagons[entity.unit_number]	
	local surface = wagon.surface
	kill_wagon_doors(icw, wagon)
	for _, e in pairs(surface.find_entities_filtered({area = wagon.area})) do
		if e.name == "character" and e.player then
			local p = wagon.entity.surface.find_non_colliding_position("character", wagon.entity.position, 128, 0.5)
			if p then 
				e.player.teleport(p, wagon.entity.surface)
			else
				e.player.teleport(wagon.entity.position, wagon.entity.surface)
			end
			Public.kill_minimap(e.player)
		else
			e.die() 
		end	
	end
	for _, tile in pairs(surface.find_tiles_filtered({area = wagon.area})) do
		surface.set_tiles({{name = "out-of-map", position = tile.position}}, true)
	end
	icw.wagons[entity.unit_number] = nil
	Public.request_reconstruction(icw)
end

function Public.create_room_surface(icw, unit_number)
	if game.surfaces[tostring(unit_number)] then return game.surfaces[tostring(unit_number)] end
	local map_gen_settings = {
		["width"] = 2,
		["height"] = 2,
		["water"] = 0,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["default_enable_all_autoplace_controls"] = true,
		["autoplace_settings"] = {
			["entity"] = {treat_missing_as_default = false},
			["tile"] = {treat_missing_as_default = true},
			["decorative"] = {treat_missing_as_default = false},
		},
	}
	local surface = game.create_surface(unit_number, map_gen_settings)
	surface.freeze_daytime = true
	surface.daytime = 0.1
	surface.request_to_generate_chunks({16, 16}, 2)
	surface.force_generate_chunk_requests()
	for _, tile in pairs(surface.find_tiles_filtered({area = {{-2, -2}, {2, 2}}})) do
		surface.set_tiles({{name = "out-of-map", position = tile.position}}, true)
	end
	table_insert(icw.surfaces, surface)
	return surface
end

function Public.create_wagon_room(icw, wagon)
	local surface = wagon.surface
	local area = wagon.area
	
	local main_tile_name = "concrete"
	if wagon.entity.type == "locomotive" then
		main_tile_name = "black-refined-concrete"
	end
	
	local tiles = {}	
	for x = -3, 2, 1 do
		table_insert(tiles, {name = "hazard-concrete-right", position = {x, area.left_top.y}}) 
		table_insert(tiles, {name = "hazard-concrete-right", position = {x, area.right_bottom.y - 1}}) 
	end		
	for x = area.left_top.x, area.right_bottom.x - 1, 1 do
		for y = area.left_top.y + 2, area.right_bottom.y - 3, 1 do
			table_insert(tiles, {name = main_tile_name, position = {x, y}}) 
		end
	end
	for x = -3, 2, 1 do
		for y = 1, 3, 1 do
			table_insert(tiles, {name = main_tile_name, position = {x,y}}) 
		end
		for y = area.right_bottom.y - 4, area.right_bottom.y - 2, 1 do
			table_insert(tiles, {name = main_tile_name, position = {x,y}}) 
		end
	end
	
	if wagon.entity.type == "locomotive" then
		local vectors = {}
		local r1 = math_random(1, 2) * -1
		local r2 = math_random(1, 2)
		for x = math_random(1, 2) * -1, math_random(1, 2), 1 do
			for y = r1, r2, 1 do
				table_insert(vectors, {x, y}) 
			end
		end
		local position = {x = area.left_top.x + (area.right_bottom.x - area.left_top.x) * 0.5, y = area.left_top.y + (area.right_bottom.y - area.left_top.y) * 0.5}
		position = {x = position.x + (-4 + math_random(0, 8)), y = position.y + (-6 + math_random(0, 12))}
		for _, v in pairs(vectors) do
			table_insert(tiles, {name = "water", position = {position.x + v[1], position.y + v[2]}}) 
		end	
	end
	
	surface.set_tiles(tiles, true)
	
	construct_wagon_doors(icw, wagon)
	
	if wagon.entity.type == "fluid-wagon" then
		local height = area.right_bottom.y - area.left_top.y
		local positions = {
			{area.right_bottom.x, area.left_top.y + height * 0.25},
			{area.right_bottom.x, area.left_top.y + height * 0.75},
			{area.left_top.x - 1, area.left_top.y + height * 0.25},
			{area.left_top.x - 1, area.left_top.y + height * 0.75},	
		}		
		table.shuffle_table(positions)		
		local e = surface.create_entity({
			name = "storage-tank",
			position = positions[1],
			force = "neutral",
			create_build_effect_smoke = false
		})
		e.destructible = false
		e.minable = false
		wagon.transfer_entities = {e}
		return
	end
	
	if wagon.entity.type == "cargo-wagon" then
		local vectors = {{0, -1}, {0, 1}, {-1, 0}, {1, 0}}
		local v = vectors[math_random(1, 4)]
		local position = {math_random(area.left_top.x + 4, area.right_bottom.x - 4), math_random(area.left_top.y + 6, area.right_bottom.y - 6)}
		
		local e = surface.create_entity({
			name = "logistic-chest-requester",
			position = position,
			force = "neutral",
			create_build_effect_smoke = false
		})
		e.set_request_slot({name = "small-plane", count = 1}, 1)
		e.destructible = false
		e.minable = false
		
		e2 = surface.create_entity({
			name = "logistic-chest-passive-provider",
			position = {position[1] + v[1], position[2] + v[2]},
			force = "neutral",
			create_build_effect_smoke = false
		})
		e2.destructible = false
		e2.minable = false
		
		wagon.transfer_entities = {e, e2}
		return
	end
end

function Public.create_wagon(icw, created_entity)
	if not created_entity.unit_number then return end
	if icw.trains[tonumber(created_entity.surface.name)] or icw.wagons[tonumber(created_entity.surface.name)] then return end
	if not Constants.wagon_types[created_entity.type] then return end
	local wagon_area = Constants.wagon_areas[created_entity.type]

	icw.wagons[created_entity.unit_number] = {
		entity = created_entity,
		area = {left_top = {x = wagon_area.left_top.x, y = wagon_area.left_top.y}, right_bottom = {x = wagon_area.right_bottom.x, y = wagon_area.right_bottom.y}},
		surface = Public.create_room_surface(icw, created_entity.unit_number),
		doors = {},
		entity_count = 0,
	}		
	Public.create_wagon_room(icw, icw.wagons[created_entity.unit_number])
	Public.request_reconstruction(icw)
	return icw.wagons[created_entity.unit_number]
end

function Public.add_wagon_entity_count(icw, added_entity)
	local wagon = get_wagon_for_entity(icw, added_entity)
	if not wagon then return end	
	wagon.entity_count = wagon.entity_count + 1
	wagon.entity.minable = false
end

function Public.subtract_wagon_entity_count(icw, removed_entity)	
	local wagon = get_wagon_for_entity(icw, removed_entity)
	if not wagon then return end
	wagon.entity_count = wagon.entity_count - 1
	if wagon.entity_count > 0 then return end
	wagon.entity.minable = true
end

function Public.use_cargo_wagon_door(icw, player, door)
	if icw.players[player.index] then
		icw.players[player.index] = icw.players[player.index] - 1
		if icw.players[player.index] == 0 then
			icw.players[player.index] = nil
		end
		return
	end

	if not door then return end
	if not door.valid then return end
	local doors = icw.doors
	local wagons = icw.wagons
	
	local wagon = false
	if doors[door.unit_number] then wagon = wagons[doors[door.unit_number]] end
	if wagons[door.unit_number] then wagon = wagons[door.unit_number] end 
	if not wagon then return end

	if wagon.entity.surface.name ~= player.surface.name then
		local surface = wagon.entity.surface
		local x_vector = (door.position.x / math.abs(door.position.x)) * 2
		local position = {wagon.entity.position.x + x_vector, wagon.entity.position.y}
		local position = surface.find_non_colliding_position("character", position, 128, 0.5)
		if not position then return end
		player.teleport(position, surface)
		icw.players[player.index] = 2
		player.driving = true
		Public.kill_minimap(player)
	else
		local surface = wagon.surface
		local area = wagon.area
		local x_vector = door.position.x - player.position.x
		local position
		if x_vector > 0 then			
			position = {area.left_top.x + 0.5, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5)}
		else
			position = {area.right_bottom.x - 0.5, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5)}
		end
		local p = surface.find_non_colliding_position("character", position, 128, 0.5)
		if p then 
			player.teleport(p, surface)
		else
			player.teleport(position, surface)
		end
	end
end

function Public.move_room_to_train(icw, train, wagon)
	if not wagon then return end		
	
	table_insert(train.wagons, wagon.entity.unit_number)
	
	local destination_area = {
		left_top = {x = wagon.area.left_top.x, y = train.top_y},
		right_bottom = {x = wagon.area.right_bottom.x, y = train.top_y + (wagon.area.right_bottom.y - wagon.area.left_top.y)}
	}
	
	train.top_y = destination_area.right_bottom.y
	
	if destination_area.left_top.x == wagon.area.left_top.x and destination_area.left_top.y == wagon.area.left_top.y and wagon.surface.name == train.surface.name then return end
	
	kill_wagon_doors(icw, wagon)
	
	local player_positions = {}
	for _, e in pairs(wagon.surface.find_entities_filtered({name = "character", area = wagon.area})) do
		local player = e.player
		if player then
			player_positions[player.index] = {player.position.x, player.position.y + (destination_area.left_top.y - wagon.area.left_top.y)}
			player.teleport({0,0}, game.surfaces.nauvis)
		end	
	end
	
	wagon.surface.clone_area({
		source_area = wagon.area,
		destination_area = destination_area,
		destination_surface = train.surface,
		clone_tiles = true,
		clone_entities = true,
		clone_decoratives = true,
		clear_destination_entities = true,
		clear_destination_decoratives = true,
		expand_map = true,
	})
	
	for player_index, position in pairs(player_positions) do
		local player = game.players[player_index]
		player.teleport(position, train.surface)			
	end
	
	for _, tile in pairs(wagon.surface.find_tiles_filtered({area = wagon.area})) do
		wagon.surface.set_tiles({{name = "out-of-map", position = tile.position}}, true)
	end
	
	wagon.surface = train.surface
	wagon.area = destination_area
	wagon.transfer_entities = {}
	construct_wagon_doors(icw, wagon)
	
	for _, e in pairs(wagon.surface.find_entities_filtered({area = wagon.area, force = "neutral"})) do
		if transfer_functions[e.name] then
			table_insert(wagon.transfer_entities, e)
		end
	end
end

function Public.construct_train(icw, carriages)
	local unit_number = carriages[1].unit_number
	
	if icw.trains[unit_number] then return end
	
	local train = {surface = Public.create_room_surface(icw, unit_number), wagons = {}, top_y = 0}
	icw.trains[unit_number] = train
	
	for k, carriage in pairs(carriages) do
		Public.move_room_to_train(icw, train, icw.wagons[carriage.unit_number])
	end
end

function Public.reconstruct_all_trains(icw)
	icw.trains = {}
	for unit_number, wagon in pairs(icw.wagons) do
		local carriages = wagon.entity.train.carriages
		Public.construct_train(icw, carriages)
	end
	delete_empty_surfaces(icw)
end

function Public.item_transfer(icw)
	for _, wagon in pairs(icw.wagons) do
		if wagon.transfer_entities then
			for k, e in pairs(wagon.transfer_entities) do
				transfer_functions[e.name](wagon, e)
			end
		end
	end
end

function Public.draw_minimap(player, surface, position)
	local element = player.gui.left.icw_map
	if not element then
		element = player.gui.left.add({
			type = "camera",
			name = "icw_map",
			position = position,
			surface_index = surface.index,
			zoom = 0.30,
		})
		element.style.margin = 2
		element.style.minimal_height = 360
		element.style.minimal_width = 360
		return
	end
	
	element.position = position
	element.surface_index = surface.index
end

function Public.update_minimap(icw)
	for k, player in pairs(game.connected_players) do
		if player.character and player.character.valid then
			local wagon = get_wagon_for_entity(icw, player.character)
			if wagon then
				Public.draw_minimap(player, wagon.entity.surface, wagon.entity.position)
			end
		end
	end
end

return Public