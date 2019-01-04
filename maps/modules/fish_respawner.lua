-- this module respawns fish in all water tiles on every surface with a player on it -- by mewmew --

local respawn_interval = 3600							--interval in ticks 
local respawn_amount_per_chunk = 8				--maximum amount of fish to generate in one chunk per interval 
local max_amount_of_fish_in_one_chunk = 32	--maximum amount of fish one chunk is allowed to contain
local valid_water_tiles = {
		"water",
		"deepwater", 
		"water-green",
		"deepwater-green"
		}

local event = require 'utils.event'
local math_random = math.random

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function get_surfaces()
	local surfaces = {}
	for _, player in pairs(game.connected_players) do
		if not surfaces[player.surface.index] then
			surfaces[player.surface.index] = player.surface
		end		
	end
	return surfaces
end

local function create_new_fish_spawn_schedule()
	global.fish_respawn_chunk_schedule = {}

	local surfaces = get_surfaces()
	if #surfaces == 0 then return end
		
	for _, surface in pairs(surfaces) do		
		for chunk in surface.get_chunks() do
			global.fish_respawn_chunk_schedule[#global.fish_respawn_chunk_schedule + 1] = {chunk = {x = chunk.x, y = chunk.y}, surface_index = surface.index}
		end
	end
	
	global.fish_respawn_chunk_schedule = shuffle(global.fish_respawn_chunk_schedule)
	
	return global.fish_respawn_chunk_schedule
end

local function respawn_fishes_in_chunk(schedule)
	local surface = game.surfaces[schedule.surface_index]
	local chunk = schedule.chunk
	local chunk_area = {{chunk.x * 32, chunk.y * 32}, {chunk.x * 32 + 32, chunk.y * 32 + 32}}
	local chunk_fish_count = surface.count_entities_filtered({area = chunk_area, name = "fish"})
	if chunk_fish_count > max_amount_of_fish_in_one_chunk then return end 	
	local fish_to_spawn = respawn_amount_per_chunk
	local water_tiles = surface.find_tiles_filtered({name = valid_water_tiles, area = chunk_area})
	if not water_tiles[1] then return end
	water_tiles = shuffle(water_tiles)
	for _, tile in pairs(water_tiles) do
		if surface.can_place_entity({name = "fish", position = tile.position}) then
			surface.create_entity({name = "water-splash", position = tile.position})
			surface.create_entity({name = "fish", position = tile.position})
			fish_to_spawn = fish_to_spawn - 1
			if fish_to_spawn <= 0 then return end
		end
	end				
end

-- one chunk per tick
local function on_tick()
	local i = game.tick % respawn_interval
	if i == 0 then create_new_fish_spawn_schedule() return end
	if not global.fish_respawn_chunk_schedule[i] then return end
	respawn_fishes_in_chunk(global.fish_respawn_chunk_schedule[i])
	global.fish_respawn_chunk_schedule[i] = nil
end

event.add(defines.events.on_tick, on_tick)	