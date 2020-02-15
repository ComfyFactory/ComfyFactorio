require "modules.satellite_score"

local Map_info = require "modules.map_info"

local get_noise = require "utils.get_noise"
local table_insert = table.insert
local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs
local string_sub = string.sub

local oasis_start = 0.5
local water_start = 0.75
local sand_damage = oasis_start * 100 + 20

local save_tiles = {
	["grass-1"] = true,
	["grass-2"] = true,
	["grass-3"] = true,
	["water"] = true,
	["deepwater"] = true,
}

local ores = {"iron-ore", "copper-ore", "coal", "stone"}

local function get_moisture(position)	
	local moisture = get_noise("oasis", position, global.desert_oasis_seed)	
	moisture = moisture * 128
	moisture = math.round(moisture, 1)
	return moisture
end

local function moisture_meter(player, moisture)
	local moisture_meter = player.gui.top.moisture_meter
	
	if not moisture_meter then
		moisture_meter = player.gui.top.add({type = "frame", name = "moisture_meter"})
		moisture_meter.style.padding = 3
		
		local label = moisture_meter.add({type = "label", caption = "Moisture Meter:"})
		label.style.font = "heading-2"
		label.style.font_color = {0, 150, 0}
		local label = moisture_meter.add({type = "label", caption = 0})
		label.style.font = "heading-2"
		label.style.font_color = {175, 175, 175}
	end
	
	moisture_meter.children[2].caption = moisture
end

local function on_chunk_generated(event)
	local surface = event.surface
	if surface.name ~= "desert_oasis" then return end
	local seed = global.desert_oasis_seed
	local left_top = event.area.left_top
	
	local tiles = {}
	local size_of_tiles = 0
	local entities = {}
	local size_of_entities = 0
	
	local noise = get_noise("oasis", left_top, seed)
	if noise < oasis_start - 0.25 then return end
	
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top_x + x, y = left_top_y + y}
			local noise = get_noise("oasis", position, seed)
			if noise > oasis_start then		
				if noise > water_start then
					size_of_tiles = size_of_tiles + 1
					tiles[size_of_tiles] = {name = "water", position = position}
				else
					size_of_tiles = size_of_tiles + 1
					tiles[size_of_tiles] = {name = "grass-" .. math_floor(noise * 32) % 3 + 1, position = position}
					
					for _, cliff in pairs(surface.find_entities_filtered({type = "cliff", position = position})) do
						cliff.destroy()
					end

					if math_random(1, 48) == 1 then
						size_of_entities = size_of_entities + 1
						entities[size_of_entities] = {name = "tree-0" .. math_random(1, 4), position = position}
					end
					
					if noise > water_start - 0.07 then
						size_of_entities = size_of_entities + 1
						entities[size_of_entities] = {name = ores[math_floor(get_noise("small_caves", position, seed) * 4) % 4 + 1], position = position, amount = math_random(600, 800)}
					else
						if get_noise("n3", position, seed) > 0.68 then
							if math_random(1, 128) == 1 then
								size_of_entities = size_of_entities + 1
								entities[size_of_entities] = {name = "crude-oil", position = position, amount = math_random(250000, 500000)}
							end
						end
					end
				end
			end
		end
	end
	
	surface.set_tiles(tiles, true)
	
	for _, entity in pairs(entities) do
		if surface.can_place_entity(entity) then
			surface.create_entity(entity)
		end
	end
end

local function on_init()
	if game.surfaces["desert_oasis"] then return end
	
	local T = Map_info.Pop_info()
	T.localised_category = "desert_oasis"
	T.main_caption_color = {r = 170, g = 170, b = 0}
	T.sub_caption_color = {r = 120, g = 120, b = 0}
	
	local map_gen_settings = {
		water = 0.0,		
		property_expression_names = {
			temperature = 50,
			moisture = 0,
		},
		starting_area = 1,
		terrain_segmentation = 0.1,
		cliff_settings = {cliff_elevation_interval = 4, cliff_elevation_0 = 4},
		autoplace_controls = {
			["coal"] = {frequency = 0.5, size = 0.5, richness = 0.5},
			["stone"] = {frequency = 0.5, size = 0.5, richness = 0.5},
			["copper-ore"] = {frequency = 0.5, size = 0.5, richness = 0.5},
			["iron-ore"] = {frequency = 0.5, size = 0.5, richness = 0.5},
			["crude-oil"] = {frequency = 1, size = 0.5, richness = 0.5},
			["trees"] = {frequency = 0.5, size = 0.5, richness = 0.15},
			["enemy-base"] = {frequency = 0.5, size = 1.5, richness = 1},
		},
	}
	
	global.desert_oasis_seed = 0
	local noise
	local seed = 0
	local position = {x = 0, y = 0}
	for _ = 1, 1024 ^ 2, 1 do
		seed = math_random(1, 999999999)
		noise = get_noise("oasis", position, seed)
		if noise > 0.82 then
			global.desert_oasis_seed = seed
			break
		end
	end
	
	game.create_surface("desert_oasis", map_gen_settings)
	
	local surface = game.surfaces["desert_oasis"]
	surface.request_to_generate_chunks({0,0}, 5)
	surface.force_generate_chunk_requests()
	
	local force = game.forces.player
	force.research_queue_enabled = true
	force.technologies["landfill"].enabled = false
	force.technologies["cliff-explosives"].enabled = false
end

local type_whitelist = {
	["car"] = true,
	["electric-pole"] = true,	
	["entity-ghost"] = true,
	["heat-pipe"] = true,
	["lamp"] = true,
	["loader"] = true,
	["mining-drill"] = true,	
	["pipe"] = true,
	["pipe-to-ground"] = true,
	["rail-chain-signal"] = true,
	["rail-signal"] = true,
	["splitter"] = true,
	["straight-rail"] = true,
	["train-stop"] = true,
	["transport-belt"] = true,
	["underground-belt"] = true,
}

local function deny_building(event)
	local entity = event.created_entity
	if not entity.valid then return end
	
	if type_whitelist[event.created_entity.type] then return end

	if save_tiles[entity.surface.get_tile(entity.position).name] then return end

	if event.player_index then
		game.players[event.player_index].insert({name = entity.name, count = 1})		
	else	
		local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
		inventory.insert({name = entity.name, count = 1})													
	end
	
	event.created_entity.surface.create_entity({
		name = "flying-text",
		position = entity.position,
		text = "Can not be built in the sands!",
		color = {r=0.98, g=0.66, b=0.22}
	})
	
	entity.destroy()
end

local function on_built_entity(event)
	deny_building(event)
end

local function on_robot_built_entity(event)
	deny_building(event)
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if player.online_time == 0 then
		player.insert({name = "iron-plate", count = 32})
		player.insert({name = "iron-gear-wheel", count = 16})
		player.teleport(game.surfaces["desert_oasis"].find_non_colliding_position("character", {64, 64}, 50, 0.5), "desert_oasis")
	end		
end

local function on_player_changed_position(event)
	if math_random(1, 4) ~= 1 then return end
	local player = game.players[event.player_index]
	
	local moisture = get_moisture(player.position)
	moisture_meter(player, moisture)
	
	if not player.character then return end
	if not player.character.valid then return end
	if player.vehicle then return end
	
	if save_tiles[player.surface.get_tile(player.position).name] then return end

	player.character.health = player.character.health - (sand_damage - moisture) * 0.5
	if player.character.health == 0 then player.character.die() end
end

local Event = require 'utils.event' 
Event.on_init(on_init)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)