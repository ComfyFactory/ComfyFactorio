local map_functions = require "tools.map_functions"
local math_random = math.random

local function get_vector()
	if global.current_stage == 1 then return {0, -1} end
	if global.current_stage == #global.stages then return {0, 1} end
	local position = global.path_tiles[#global.path_tiles].position
	local island_size = global.stages[global.current_stage].size
	local y_modifier = 0
	if math.abs(position.y) < 32 + island_size * 3 then
		y_modifier = math.random(50, 100) * -0.01
	else
		y_modifier = math.random(50, 100) * 0.01
	end
	game.print(y_modifier)
	return {1, y_modifier}
end

local function add_enemies(surface, position)
	local radius = global.stages[global.current_stage].size
	local amount = math.ceil(((global.current_level * 10) / #global.stages) * global.current_stage)
	for a = 1, amount, 1 do
		local p = {x = position.x + (radius - math.random(0, radius * 2)), y = position.y + (radius - math.random(0, radius * 2))}
		if surface.can_place_entity({name = "small-biter", position = p, force = enemy}) then
			surface.create_entity({name = "small-biter", position = p, force = enemy})
			global.alive_enemies = global.alive_enemies + 1
		end
	end
	
	if global.current_stage == #global.stages - 1 then	
		local unit = surface.create_entity({name = "medium-spitter", position = position, force = enemy})
		add_boss_unit(unit, global.current_level * 2, 0.55)
		global.alive_enemies = global.alive_enemies + 1
	end
end

function draw_the_island()
	if not global.stages[global.current_stage].size then global.gamestate = 4 return end
	local surface = game.surfaces[1]
	local position = global.path_tiles[#global.path_tiles].position	
	map_functions.draw_noise_tile_circle(position, "grass-2", surface, global.stages[global.current_stage].size)
	add_enemies(surface, position)
	global.gamestate = 4
end

local draw_path_tile_whitelist = {
	["water"] = true,
}

function draw_path_to_next_stage()
	local surface = game.surfaces[1]
	
	if global.current_stage ~= #global.stages then
		if global.current_stage == #global.stages - 1 then
			game.print("--Final Stage--")
		else
			game.print("--Stage " .. global.current_stage .. "--")
		end
	end
	
	local position = {x = 0, y = 0}
	if global.path_tiles then position = global.path_tiles[#global.path_tiles].position end
	--game.print(get_vector()[1] .. " " .. get_vector()[2])
	global.path_tiles = noise_vector_tile_path(surface, "grass-1", position, get_vector(), global.stages[global.current_stage].path_length, math.random(2, 5), draw_path_tile_whitelist)
	
	if global.current_stage ~= #global.stages and global.current_stage > 1 then
		if math_random(1, 3) == 1 then
			noise_vector_tile_path(surface, "grass-1", position, {0, 1}, global.stages[#global.stages].path_length, math.random(2, 5), draw_path_tile_whitelist)
		end
	end
	
	--for _, t in pairs(global.path_tiles) do
	--	global.level_tiles[#global.level_tiles + 1] = t
	--end
	
	global.gamestate = 3
end

local tile_whitelist = {"grass-1", "grass-2", "grass-3", "grass-4"}
local function get_level_tiles(surface)
	global.level_tiles = {}
	for chunk in surface.get_chunks() do
		if chunk.y < 0 and game.forces.player.is_chunk_charted(surface, chunk) then
			for _, tile in pairs(surface.find_tiles_filtered({area = {{chunk.x * 32, chunk.y * 32}, {chunk.x * 32 + 32, chunk.y * 32 + 32}}, name = tile_whitelist})) do
				local index = math.abs(tile.position.y)
				if not global.level_tiles[index] then global.level_tiles[index] = {} end
				global.level_tiles[index][#global.level_tiles[index] + 1] = tile
			end
		end
	end
	for k, tile_row in pairs(global.level_tiles) do
		table.shuffle_table(global.level_tiles[k])
	end
end

local function wipe_vision(surface)
	for chunk in surface.get_chunks() do
		if chunk.y < 0 then game.forces.player.unchart_chunk(chunk, surface) end
	end
end

local particles = {"coal-particle", "copper-ore-particle", "iron-ore-particle", "stone-particle"}
local function create_particles(surface, position)
	local particle = particles[math_random(1, #particles)]
	local m = math_random(10, 30)
	local m2 = m * 0.005
	for i = 1, 8, 1 do 
		surface.create_entity({
			name = particle,
			position = position,
			frame_speed = 0.1,
			vertical_speed = 0.1,
			height = 0.1,
			movement = {m2 - (math_random(0, m) * 0.01), m2 - (math_random(0, m) * 0.01)}
		})
	end
end

function kill_the_level()
	local surface = game.surfaces[1]
	if not global.level_tiles then get_level_tiles(surface) end
	
	local amount = global.current_level * 2
	for i = #global.level_tiles, 1, -1 do
		if global.level_tiles[i] then
			for k, tile in pairs(global.level_tiles[i]) do
				surface.set_tiles({{name = "water", position = tile.position}}, true)
				create_particles(surface, tile.position)
				global.level_tiles[i][k] = nil
				amount = amount - 1
				if amount <= 0 then return end
			end
			global.level_tiles[i] = nil
		end
	end
	
	if #global.level_tiles == 0 then
		wipe_vision(surface)
		global.level_tiles = nil
		global.gamestate = 1 
	end
end

local function process_tile(surface, position)
	if position.y < 0 then surface.set_tiles({{name = "water", position = position}}, true) return end
	if position.y > 4 then surface.set_tiles({{name = "water-green", position = position}}, true) return end
	surface.set_tiles({{name = "sand-1", position = position}}, true)
end

local function on_chunk_generated(event)
	local left_top = event.area.left_top
	local surface = event.surface
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top.x + x, y = left_top.y + y}
			process_tile(surface, position)
		end
	end
end

local event = require 'utils.event'
event.add(defines.events.on_chunk_generated, on_chunk_generated)