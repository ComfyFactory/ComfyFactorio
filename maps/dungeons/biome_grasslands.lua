local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs
local math_sqrt = math.sqrt
local math_floor = math.floor

local ores = {"iron-ore", "iron-ore", "iron-ore", "iron-ore", "copper-ore", "copper-ore", "copper-ore","coal", "coal", "stone", "stone"}
local trees = {"tree-01", "tree-02", "tree-03", "tree-04", "tree-05"}
local size_of_trees = #trees
local worms = {}
for _ = 1, 64, 1 do table_insert(worms, "small") end
for _ = 1, 8, 1 do table_insert(worms, "medium") end
for _ = 1, 4, 1 do table_insert(worms, "big") end
for _ = 1, 1, 1 do table_insert(worms, "behemoth") end
local size_of_worms = #worms

local function grasslands(surface, room)
	for _, tile in pairs(room.path_tiles) do
		surface.set_tiles({{name = "grass-1", position = tile.position}}, true)
	end
	
	if #room.room_tiles > 1 then table_shuffle_table(room.room_tiles) end
	for key, tile in pairs(room.room_tiles) do
		surface.set_tiles({{name = "grass-2", position = tile.position}}, true)
		if math_random(1, 64) == 1 then
			surface.create_entity({name = ores[math_random(1, #ores)], position = tile.position, amount = math_random(250, 500) + global.dungeons.depth * 3})
		else
			if math_random(1, 24) == 1 then
				surface.create_entity({name = trees[math_random(1, size_of_trees)], position = tile.position})
			end
		end
		if math_random(1, 512) == 1 then
			local turret_name = worms[math_random(1, size_of_worms)] .. "-worm-turret"
			surface.create_entity({name = turret_name, position = tile.position})
		end
		if math_random(1, 1024) == 1 then
			surface.create_entity({name = "rock-huge", position = tile.position})
		end
	end
	
	if room.center then
		if math_random(1, 3) == 1 then
			local r = math_floor(math_sqrt(#room.room_tiles) * 0.25) + 1
			for x = r * -1, r, 1 do
				for y = r * -1, r, 1 do
					local p = {room.center.x + x, room.center.y + y}
					surface.set_tiles({{name = "water", position = p}})
					if math_random(1, 8) == 1 then
						surface.create_entity({name = "fish", position = p})
					end
				end
			end
		else
			if math_random(1, 3) == 1 then
				surface.create_entity({name = "biter-spawner", position = room.center})
			end
		end	
	end
	
	if #room.room_border_tiles > 1 then table_shuffle_table(room.room_border_tiles) end
	for key, tile in pairs(room.room_border_tiles) do
		surface.set_tiles({{name = "grass-3", position = tile.position}}, true)
		if key < 9 then
			surface.create_entity({name = "rock-big", position = tile.position})
		else
			if math_random(1, 8) == 1 then
				surface.create_entity({name = trees[math_random(1, size_of_trees)], position = tile.position})
			end
		end
	end
end

return grasslands