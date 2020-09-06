local math_abs = math.abs
local math_random = math.random
local GetNoise = require "utils.get_noise"
local Public = {}

local hatchery_position = {x = 192, y = 0}

local function get_replacement_tile(surface, position)
	for i = 1, 128, 1 do
		local vectors = {{0, i}, {0, i * -1}, {i, 0}, {i * -1, 0}}
		table.shuffle_table(vectors)
		for k, v in pairs(vectors) do
			local tile = surface.get_tile(position.x + v[1], position.y + v[2])
			if not tile.collides_with("resource-layer") then return tile.name end
		end
	end
	return "landfill"
end

local function create_nests(surface)
	local x = hatchery_position.x
	
	local e = surface.create_entity({name = "biter-spawner", position = {x * -1, 0}, force = "west"})
	for _, p in pairs({{x * -1 + 6, 0}, {x * -1 + 3, 6}, {x * -1 + 3, -5}}) do
		surface.create_entity({name = "small-worm-turret", position = p, force = "west"})
		surface.create_decoratives{check_collision = false, decoratives = {{name = "enemy-decal", position = p, amount = 1}}}
	end
	e.active = false
	global.map_forces.west.hatchery = e
	global.map_forces.east.target = e	
	surface.create_decoratives{check_collision = false, decoratives = {{name = "enemy-decal", position = e.position, amount = 3}}}
	
	local e = surface.create_entity({name = "biter-spawner", position = {x, 0}, force = "east"})
	for _, p in pairs({{x - 6, 0}, {x - 3, 6}, {x - 3, -5}}) do
		surface.create_entity({name = "small-worm-turret", position = p, force = "east"})
		surface.create_decoratives{check_collision = false, decoratives = {{name = "enemy-decal", position = p, amount = 1}}}
	end
	
	e.active = false
	global.map_forces.east.hatchery = e
	global.map_forces.west.target = e	
	surface.create_decoratives{check_collision = false, decoratives = {{name = "enemy-decal", position = e.position, amount = 3}}}
end

local function create_border_beams(surface)
	surface.create_entity({name = "electric-beam", position = {4, -96}, source = {4, -96}, target = {4,96}})
	surface.create_entity({name = "electric-beam", position = {-4, -96}, source = {-4, -96}, target = {-4,96}})
end

local function draw_spawn_ore(surface, position)
	local ores = {"copper-ore", "iron-ore", "coal", "stone"}
	table.shuffle_table(ores)
	
	local seed = math_random(1, 1000000)
	local r = 25
	local r_square = r ^ 2
	
	for x = -32, 32, 1 do
		for y = -32, 32, 1 do
			local position = {x = position.x + x + 0.5, y = position.y + y + 0.5}
			if x ^ 2 + y ^ 2 + math_abs(GetNoise("decoratives", position, seed) * 300) < r_square then
				local name = ores[1]
				if y <= 0 and x < 0 then
					name = ores[2]
				end
				if y >= 0 and x >= 0 then
					name = ores[3]
				end
				if y >= 0 and x < 0 then
					name = ores[4]
				end
				for _, e in pairs(surface.find_entities_filtered({position = position})) do e.destroy() end
				local tile = surface.get_tile(position)
				if tile.name == "water" or tile.name == "deepwater" then
					surface.set_tiles({{name = get_replacement_tile(surface, position), position = position}}, true)
				end				
				surface.create_entity({name = name, position = position, amount = math_random(800, 1000)})
			end
		end
	end
end

function Public.create_mirror_surface()
	if game.surfaces["mirror_terrain"] then return end

	local map_gen_settings = {}
	map_gen_settings.seed = math_random(1, 99999999)
	map_gen_settings.water = 1
	map_gen_settings.starting_area = 1
	map_gen_settings.terrain_segmentation = 2
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 0, cliff_elevation_0 = 0}	
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = 8, size = 0.7, richness = 0.5,},
		["stone"] = {frequency = 8, size = 0.7, richness = 0.5,},
		["copper-ore"] = {frequency = 8, size = 0.7, richness = 0.75,},
		["iron-ore"] = {frequency = 8, size = 0.7, richness = 1,},
		["uranium-ore"] = {frequency = 5, size = 0.5, richness = 0.5,},
		["crude-oil"] = {frequency = 5, size = 1, richness = 1,},
		["trees"] = {frequency = math.random(4, 32) * 0.1, size = math.random(4, 16) * 0.1, richness = math.random(1, 10) * 0.1},
		["enemy-base"] = {frequency = 0, size = 0, richness = 0}	
	}
	local surface = game.create_surface("mirror_terrain", map_gen_settings)
	
	local x = hatchery_position.x - 16
	
	surface.request_to_generate_chunks({x, 0}, 5)
	surface.force_generate_chunk_requests()
	
	draw_spawn_ore(surface, {x = 240, y = 0})
	
	local r = 32
	local seed = surface.map_gen_settings.seed
	for x = r * -1, r, 1 do
		for y = r * -1, r, 1 do
			local p = {x = hatchery_position.x + x, y = hatchery_position.y + y}
			if math.sqrt(x ^ 2 + y ^ 2) + math_abs(GetNoise("decoratives", p, seed) * 9) < r then
				local tile = surface.get_tile(p)
				if tile.name == "water" or tile.name == "deepwater" then
					surface.set_tiles({{name = get_replacement_tile(surface, p), position = p}}, true)
				end
			end
		end
	end
end

local function mirror_chunk(event, source_surface, x_modifier)
	local surface = event.surface	
	local left_top = event.area.left_top
	local offset = 0
	if x_modifier == -1 then offset = 32 end
	local mirror_left_top = {x = left_top.x * x_modifier - offset, y = left_top.y}
	
	source_surface.request_to_generate_chunks({x = mirror_left_top.x + 16, y = mirror_left_top.y + 16}, 0)
	source_surface.force_generate_chunk_requests()
	
	local mirror_area = {{mirror_left_top.x, mirror_left_top.y}, {mirror_left_top.x + 32, mirror_left_top.y + 32}}
	
	for _, tile in pairs(source_surface.find_tiles_filtered({area = mirror_area})) do
		surface.set_tiles({{name = tile.name, position = {x = tile.position.x * x_modifier, y = tile.position.y}}}, true)
	end
	for _, entity in pairs(source_surface.find_entities_filtered({area = mirror_area})) do
		if surface.can_place_entity({name = entity.name, position = {x = entity.position.x * x_modifier, y = entity.position.y}}) then
			entity.clone({position = {x = entity.position.x * x_modifier, y = entity.position.y}, surface = surface, force = "neutral"})
		end
	end	
	for _, decorative in pairs(source_surface.find_decoratives_filtered{area = mirror_area}) do
		surface.create_decoratives{
			check_collision=false,
			decoratives={{name = decorative.decorative.name, position = {x = decorative.position.x * x_modifier, y = decorative.position.y}, amount = decorative.amount}}
		}
	end
end

local function combat_area(event)
	local surface = event.surface
	local left_top = event.area.left_top
	local seed = surface.map_gen_settings.seed
	if left_top.y >= 96 then return end
	if left_top.y < -96 then return end
	
	for _, tile in pairs(surface.find_tiles_filtered({area = event.area})) do		
		if tile.position.x >= -4 and tile.position.x < 4 then
			surface.set_tiles({{name = "water-shallow", position = tile.position}}, true)
		end	
	end
end

local function is_out_of_map_chunk(p)
	if p.y < 96 and p.y >= -96 then return end
	if p.x * 0.5 + 32 >= math_abs(p.y) then return end
	if p.x * -0.5 + 32 > math_abs(p.y) then return end
	return true
end

local function is_out_of_map(p)
	if p.y < 96 and p.y >= -96 then return end
	if p.x * 0.5 >= math_abs(p.y) then return end
	if p.x * -0.5 > math_abs(p.y) then return end
	return true
end

local function out_of_map_area(event)
	local surface = event.surface
	local left_top = event.area.left_top
	for x = -1, 32, 1 do
		for y = -1, 32, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}			
			if is_out_of_map(p) then
				surface.set_tiles({{name = "out-of-map", position = p}}, true) 
			end
		end
	end
end

local function modify_source_surface(event)
	local surface = event.surface
	local left_top = event.area.left_top
	if left_top.x >= 256 or left_top.x < 0 or left_top.y < -192 or left_top.y > 192 then return end
	local seed = surface.map_gen_settings.seed
	for _, tile in pairs(surface.find_tiles_filtered({area = event.area, name = {"water", "deepwater"}})) do
		if tile.position.x + math_abs(GetNoise("cave_rivers", {x = 0, y = tile.position.y}, seed) * 64) < 224 then		
			if math_abs(GetNoise("n5", tile.position, seed)) < 0.25 then
				surface.set_tiles({{name = get_replacement_tile(surface, tile.position), position = tile.position}}, true)
			end
		end
	end
end

local function on_chunk_generated(event)
	local source_surface = game.surfaces["mirror_terrain"]
	if not source_surface then return end
	if not source_surface.valid then return end
	if event.surface.index == source_surface.index then modify_source_surface(event) return end
	
	local left_top = event.area.left_top
	
	if not is_out_of_map_chunk(left_top) then
		if left_top.x >= 0 then
			mirror_chunk(event, source_surface, 1)
		else
			mirror_chunk(event, source_surface, -1)
		end
	end
	
	out_of_map_area(event)
	
	if left_top.x >= -192 and left_top.x < 192 then combat_area(event) end
	
	if left_top.x == 256 and left_top.y == 256 then 
		create_nests(event.surface) 
		create_border_beams(event.surface)
	end
	
	if left_top.x > 320 then return end
	if left_top.x < -320 then return end
	if left_top.y > 320 then return end
	if left_top.y < -320 then return end
	
	game.forces.west.chart(event.surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}})
	game.forces.east.chart(event.surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}})
end

local event = require 'utils.event'
event.add(defines.events.on_chunk_generated, on_chunk_generated)

return Public