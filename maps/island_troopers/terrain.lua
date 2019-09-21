local math_random = math.random
local simplex_noise = require 'utils.simplex_noise'.d2

local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}

local function island_noise(p, seed_1, seed_2, seed_3)
	local noise_1 = simplex_noise(p.x * 0.01, p.y * 0.01, seed_1)
	local noise_2 = simplex_noise(p.x * 0.04, p.y * 0.04, seed_2)
	local noise_3 = simplex_noise(p.x * 0.1, p.y * 0.1, seed_3)
	return math.abs(noise_1 + noise_2 * 0.5 + noise_3 * 0.2)
end

local function process_island_position(position, radius, noise, distance)
	if distance + noise * radius * 1.7 <= radius then
		return {name = "grass-1", position = position}
	end
	if distance + noise * radius * 0.4 <= radius then
		return {name = "sand-1", position = position}
	end
	if distance + noise * radius * 0.2 <= radius  then
		return {name = "water", position = position}
	end
end

local function draw_island_tiles(surface, position, radius)
	local seed_1 = math.random(1, 9999999)
	local seed_2 = math.random(1, 9999999)
	local seed_3 = math.random(1, 9999999)
	local tiles = {}
	for y = radius * -2, radius * 2, 1 do
		for x = radius * -2, radius * 2, 1 do
			local p = {x = x + position.x, y = y + position.y}
			if surface.get_tile(p).name == "deepwater" then
				local noise = island_noise(p, seed_1, seed_2, seed_3)
				local distance = math.sqrt(x^2 + y^2)
				local tile = process_island_position(p, radius, noise, distance)
				if tile then tiles[#tiles + 1] = tile end
			end
		end
	end
	surface.set_tiles(tiles, true)
	return tiles
end

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
	return {1, y_modifier}
end

function draw_the_island()
	if not global.stages[global.current_stage].size then global.gamestate = 4 return end
	local surface = game.surfaces[1]
	local position = global.path_tiles[#global.path_tiles].position	
	
	local tiles = draw_island_tiles(surface, position, global.stages[global.current_stage].size)
	local tree = "tree-0" .. math_random(1,9)
	local seed = math.random(1, 1000000)
	
	for _, t in pairs(tiles) do
		if math.random(1, 32) == 1 then
			local noise = simplex_noise(t.position.x * 0.02, t.position.y * 0.02, seed)
			if noise > 0.75 or noise < -0.75 then
				surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = t.position})
			end
		end
		
		if surface.can_place_entity({name = "wooden-chest", position = t.position}) then
			if math.random(1, 64) == 1 then
				if simplex_noise(t.position.x * 0.02, t.position.y * 0.02, seed) > 0.25 then
					surface.create_entity({name = tree, position = t.position}) 
				end
			end
		end
	end
	
	add_enemies(surface, tiles)
	global.gamestate = 4
end

local draw_path_tile_whitelist = {
	["water"] = true,
	["deepwater"] = true,
}

local path_tile_names = {"grass-2", "grass-3", "grass-4", "water-shallow"}
function draw_path_to_next_stage()
	local surface = game.surfaces[1]
	
	--if global.current_stage ~= #global.stages then
	--	if global.current_stage == #global.stages - 1 then
			--game.print("--Final Stage--")
	--	else
			--game.print("--Stage " .. global.current_stage .. "--")
	--	end
	--end
	
	local position = {x = 0, y = 0}
	if global.path_tiles then position = global.path_tiles[#global.path_tiles].position end
	--game.print(get_vector()[1] .. " " .. get_vector()[2])
	global.path_tiles = noise_vector_tile_path(surface, path_tile_names[math_random(1, #path_tile_names)], position, get_vector(), global.stages[global.current_stage].path_length, math.random(2, 3), draw_path_tile_whitelist)
	
	if global.current_stage ~= #global.stages and global.current_stage > 2 then
		if math_random(1, 3) == 1 then
			noise_vector_tile_path(surface, path_tile_names[math_random(1, 3)], position, {0, 1}, global.stages[#global.stages].path_length, math.random(2, 3), draw_path_tile_whitelist)
		end
	end
	
	global.gamestate = 3
end

local tile_whitelist = {"grass-1", "grass-2", "grass-3", "grass-4", "water-mud", "water-shallow", "sand-1", "water", "landfill"}
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
	for i = 1, 4, 1 do 
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
	if not global.kill_the_level_speed then global.kill_the_level_speed = 0 end
	global.kill_the_level_speed = global.kill_the_level_speed + 0.0025
	local amount = global.kill_the_level_speed 
	for i = #global.level_tiles, 1, -1 do
		if global.level_tiles[i] then
			for k, tile in pairs(global.level_tiles[i]) do
				surface.set_tiles({{name = "deepwater", position = tile.position}}, true)
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
		global.kill_the_level_speed = nil
		global.level_tiles = nil
		global.gamestate = 1 
	end
end

local function process_tile(surface, position)
	if position.x < -96 then surface.set_tiles({{name = "out-of-map", position = position}}, true) return end
	if position.y < 0 then surface.set_tiles({{name = "deepwater", position = position}}, true) return end
	if position.y > 32 then surface.set_tiles({{name = "water-green", position = position}}, true) return end
	
	if position.y > 10 + simplex_noise(position.x * 0.010, 0, game.surfaces[1].map_gen_settings.seed) * 4 then surface.set_tiles({{name = "water-green", position = position}}, true) return end
	
	surface.set_tiles({{name = "sand-1", position = position}}, true)
	
	if position.y == 6 then
		if position.x % 64 == 32 then create_shopping_chest(surface, position, false) end
		if position.x % 128 == 0 then create_dump_chest(surface, position, false) end
	end
end

local function on_chunk_generated(event)
	local left_top = event.area.left_top
	local surface = event.surface
	
	for k, e in pairs(surface.find_entities_filtered({area = event.area})) do
		if e.force.name ~= "player" then e.destroy() end
	end
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top.x + x, y = left_top.y + y}
			process_tile(surface, position)
		end
	end
	
	surface.destroy_decoratives(event.area)
end

local event = require 'utils.event'
event.add(defines.events.on_chunk_generated, on_chunk_generated)