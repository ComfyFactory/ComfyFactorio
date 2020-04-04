local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs
local math_sqrt = math.sqrt
local math_floor = math.floor

local ores = {"iron-ore", "iron-ore", "coal"}
local trees = {"dead-dry-hairy-tree", "dead-grey-trunk", "dead-tree-desert", "dry-hairy-tree", "dry-tree"}
local size_of_trees = #trees
local worms = {}
for _ = 1, 64, 1 do table_insert(worms, "small") end
for _ = 1, 8, 1 do table_insert(worms, "medium") end
for _ = 1, 4, 1 do table_insert(worms, "big") end
for _ = 1, 1, 1 do table_insert(worms, "behemoth") end
local size_of_worms = #worms

local function red_desert(surface, room)
	for _, tile in pairs(room.path_tiles) do
		surface.set_tiles({{name = "red-desert-0", position = tile.position}}, true)
	end
	
	if #room.room_tiles > 1 then table_shuffle_table(room.room_tiles) end
	for key, tile in pairs(room.room_tiles) do
		surface.set_tiles({{name = "dry-dirt", position = tile.position}}, true)
		if math_random(1, 32) == 1 then
			surface.create_entity({name = ores[math_random(1, #ores)], position = tile.position, amount = math_random(250, 500) + global.dungeons.depth * 2})
		else
			if math_random(1, 8) == 1 and surface.can_place_entity({name = trees[math_random(1, size_of_trees)], position = tile.position}) then			
				surface.create_entity({name = trees[math_random(1, size_of_trees)], position = tile.position})
			end
		end
		if math_random(1, 256) == 1 then
			local turret_name = worms[math_random(1, size_of_worms)] .. "-worm-turret"
			surface.create_entity({name = turret_name, position = tile.position})
		end
		if math_random(1, 5) == 1 then
			surface.create_entity({name = "rock-huge", position = tile.position})
		end
	end
	
	if room.center then
		if math_random(1, 8) == 1 then
			local r = math_floor(math_sqrt(#room.room_tiles) * 0.15) + 1
			for x = r * -1, r, 1 do
				for y = r * -1, r, 1 do
					local p = {room.center.x + x, room.center.y + y}
					surface.set_tiles({{name = "water", position = p}})
					if math_random(1, 8) == 1 then
						surface.create_entity({name = "fish", position = p})
					end
				end
			end
		end	
	end
	
	if #room.room_border_tiles > 1 then table_shuffle_table(room.room_border_tiles) end
	for key, tile in pairs(room.room_border_tiles) do
		surface.set_tiles({{name = "red-desert-1", position = tile.position}}, true)
		if key < 9 then
			surface.create_entity({name = "rock-big", position = tile.position})
		else
			if math_random(1, 8) == 1 then
				surface.create_entity({name = trees[math_random(1, size_of_trees)], position = tile.position})
			end
		end
	end
end

return red_desert