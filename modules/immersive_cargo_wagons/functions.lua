local Public = {}

local table_insert = table.insert
local math_round = math.round

function Public.create_room_surface(unit_number)
	if game.surfaces[unit_number] then return game.surfaces[unit_number] end
	local map_gen_settings = {
		["width"] = 1,
		["height"] = 1,
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
	return surface
end

local function construct_wagon_doors(icw, wagon)
	local area = wagon.area
	local surface = wagon.surface
	
	for _, x in pairs({area.left_top.x, area.right_bottom.x}) do
		local e = surface.create_entity({
			name = "car",
			position = {x, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5)},
			force = wagon.entity.force,
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

function Public.create_wagon_room(icw, wagon)
	local surface = wagon.surface
	surface.freeze_daytime = true
	surface.daytime = 0.1
	surface.request_to_generate_chunks({16, 16}, 0)
	surface.force_generate_chunk_requests()

	local area = wagon.area
	for x = area.left_top.x, area.right_bottom.x - 1, 1 do
		for y = area.left_top.y, area.right_bottom.y - 1, 1 do
			surface.set_tiles({{name = "tutorial-grid", position = {x,y}}})
		end
	end

	construct_wagon_doors(icw, wagon)
end

function Public.create_wagon(icw, created_entity)
	if not created_entity.unit_number then return end
	if created_entity.type == "cargo-wagon" then
		icw.wagons[created_entity.unit_number] = {
			entity = created_entity,
			area = {left_top = {x = -12, y = 0}, right_bottom = {x = 12, y = 32}},
			surface = Public.create_room_surface(created_entity.unit_number),
			doors = {},
			entity_count = 0,
		}		
		Public.create_wagon_room(icw, icw.wagons[created_entity.unit_number])
	end		
end

function Public.add_wagon_entity_count(icw, added_entity)
	local wagon = icw.wagons[tonumber(added_entity.surface.name)]
	if not wagon then return end	
	wagon.entity_count = wagon.entity_count + 1
	wagon.entity.minable = false
end

function Public.subtract_wagon_entity_count(icw, removed_entity)	
	local wagon = icw.wagons[tonumber(removed_entity.surface.name)]
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
	
	if destination_area.left_top.x == wagon.area.left_top.x and destination_area.left_top.y == wagon.area.left_top.y then return end
	
	for k, e in pairs(wagon.doors) do
		icw.doors[e.unit_number] = nil
		e.destroy()		
		wagon.doors[k] = nil
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
	
	for _, tile in pairs(wagon.surface.find_tiles_filtered({area = wagon.area})) do
		wagon.surface.set_tiles({{name = "out-of-map", position = tile.position}}, true)
	end
	
	wagon.surface = train.surface
	wagon.area = destination_area	
	construct_wagon_doors(icw, wagon)
end

function Public.is_train_reconstruction_needed(icw, unit_number)
	local train = icw.trains[unit_number]
	local wagon = icw.wagons[unit_number]
	if tonumber(wagon.surface.name) ~= unit_number then
		wagon.surface = Public.create_room_surface(unit_number)
	end
	if not train then icw.trains[unit_number] = {surface = wagon.surface, wagons = {}, top_y = 0} return true end
	train.surface = wagon.surface
	local carriages = wagon.entity.train.carriages
	for i = 1, #carriages, 1 do
		if not train.wagons[i] then return true end
		if train.wagons[i] ~= carriages[i].unit_number then return true end
	end
end

function Public.construct_train(icw, carriages)
	local train_index = carriages[1].unit_number
	
	if not Public.is_train_reconstruction_needed(icw, train_index) then return end
	
	local train = icw.trains[train_index]
	train.wagons = {}
	train.top_y = 0
	
	for k, carriage in pairs(carriages) do
		Public.move_room_to_train(icw, train, icw.wagons[carriage.unit_number])
	end
end

function Public.construct_trains(icw, entity)
	if entity.name ~= "cargo-wagon" then return end

	for unit_number, wagon in pairs(icw.wagons) do
		local carriages = wagon.entity.train.carriages
		Public.construct_train(icw, carriages)
	end
end

return Public