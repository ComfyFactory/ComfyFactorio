local Functions = require "maps.dungeons.functions"

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs

local ores = {"iron-ore", "iron-ore", "iron-ore", "iron-ore", "copper-ore", "copper-ore", "copper-ore","coal", "coal", "stone", "stone","uranium-ore"}
local worms = {}
for _ = 1, 64, 1 do table_insert(worms, "small") end
for _ = 1, 8, 1 do table_insert(worms, "medium") end
for _ = 1, 4, 1 do table_insert(worms, "big") end
for _ = 1, 1, 1 do table_insert(worms, "behemoth") end
local size_of_worms = #worms

local function concrete(surface, room)
	for _, tile in pairs(room.path_tiles) do		
		surface.set_tiles({{name = "concrete", position = tile.position}}, true)	
	end
	
	if not room.room_border_tiles[1] then return end
	
	table_shuffle_table(room.room_border_tiles)
	for key, tile in pairs(room.room_border_tiles) do
		surface.set_tiles({{name = "refined-concrete", position = tile.position}}, true)
		if key < 8 then
			surface.create_entity({name = "rock-big", position = tile.position})
		else
			surface.create_entity({name = "stone-wall", position = tile.position})
		end
	end
	
	table_shuffle_table(room.room_tiles)
	for key, tile in pairs(room.room_tiles) do
		surface.set_tiles({{name = "stone-path", position = tile.position}}, true)
	end
	
	if room.center then
		if math_random(1, 8) == 1 then
			for x = -1, 1, 1 do
				for y = -1, 1, 1 do
					local p = {room.center.x + x, room.center.y + y}
					surface.set_tiles({{name = "water", position = p}})
					if math_random(1, 4) == 1 then
						surface.create_entity({name = "fish", position = p})
					end
				end
			end
		end	
	end
	
	if room.entrance_tile then
		local p = room.entrance_tile.position
		local area = {{p.x - 1, p.y - 1}, {p.x + 1.5, p.y + 1.5}}
		for _, entity in pairs(surface.find_entities_filtered({area = area})) do
			entity.destroy()
		end
	end
end

return concrete