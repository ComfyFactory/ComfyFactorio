local Functions = require "maps.dungeons.functions"

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs
local math_sqrt = math.sqrt
local math_floor = math.floor

local ores = {"iron-ore", "iron-ore", "iron-ore", "iron-ore", "copper-ore", "copper-ore", "copper-ore","coal", "coal","stone", "stone"}
local worms = {}
for _ = 1, 64, 1 do table_insert(worms, "small") end
for _ = 1, 8, 1 do table_insert(worms, "medium") end
for _ = 1, 4, 1 do table_insert(worms, "big") end
for _ = 1, 1, 1 do table_insert(worms, "behemoth") end
local size_of_worms = #worms

local function doom(surface, room)
	for _, tile in pairs(room.path_tiles) do
		surface.set_tiles({{name = "refined-concrete", position = tile.position}}, true)
	end
	
	if #room.room_tiles > 1 then table_shuffle_table(room.room_tiles) end
	for key, tile in pairs(room.room_tiles) do
		surface.set_tiles({{name = "red-refined-concrete", position = tile.position}}, true)
		if math_random(1, 480) == 1 then
			surface.create_entity({name = ores[math_random(1, #ores)], position = tile.position, amount = 99999999})
		end
		if math_random(1, 16) == 1 then
			local turret_name = worms[math_random(1, size_of_worms)] .. "-worm-turret"
			surface.create_entity({name = turret_name, position = tile.position})
		end		
		if key % 10 == 0 and math_random(1, 2) == 1 then
			surface.create_entity({name = Functions.roll_spawner_name(), position = tile.position})
		end
	end
	
	if room.center then
		if math_random(1, 5) == 1 then
			local r = math_floor(math_sqrt(#room.room_tiles) * 0.15) + 1
			for x = r * -1, r, 1 do
				for y = r * -1, r, 1 do
					local p = {room.center.x + x, room.center.y + y}
					surface.set_tiles({{name = "deepwater-green", position = p}})
					if math_random(1, 9) == 1 then
						surface.create_entity({name = "fish", position = p})
					end
				end
			end
		end	
	end
	
	if #room.room_border_tiles > 1 then table_shuffle_table(room.room_border_tiles) end
	for key, tile in pairs(room.room_border_tiles) do
		surface.set_tiles({{name = "black-refined-concrete", position = tile.position}}, true)
		if key < 9 then
			surface.create_entity({name = "rock-big", position = tile.position})
		end
	end
end

return doom