local Get_noise = require 'utils.get_noise'
local BiterRaffle = require 'functions.biter_raffle'
local math_random = math.random
local math_abs = math.abs
local math_floor = math.floor
local math_sqrt = math.sqrt
local rock_raffle = {'sand-rock-big', 'sand-rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-huge'}
local size_of_rock_raffle = #rock_raffle
local ore_raffle =  {}
for i = 1, 25, 1 do table.insert(ore_raffle, 'iron-ore') end
for i = 1, 17, 1 do table.insert(ore_raffle, 'copper-ore') end
for i = 1, 15, 1 do table.insert(ore_raffle, 'coal') end
local size_of_ore_raffle = #ore_raffle
local ore_raffle_2 =  {}
for i = 1, 15, 1 do table.insert(ore_raffle_2, 'iron-ore') end
for i = 1, 9, 1 do table.insert(ore_raffle_2, 'copper-ore') end
for i = 1, 7, 1 do table.insert(ore_raffle_2, 'coal') end
for i = 1, 5, 1 do table.insert(ore_raffle_2, 'stone') end
local size_of_ore_raffle_2 = #ore_raffle_2
local rock_yield = {
    ['rock-big'] = 1,
    ['rock-huge'] = 2,
    ['sand-rock-big'] = 1
}
local solid_tiles = {
    ['concrete'] = true,
    ['hazard-concrete-left'] = true,
    ['hazard-concrete-right'] = true,
    ['refined-concrete'] = true,
    ['refined-hazard-concrete-left'] = true,
    ['refined-hazard-concrete-right'] = true,
    ['stone-path'] = true,
	["lab-dark-1"] = true,
	["lab-dark-2"] = true,
}

local Public = {}

Public.lush = {}

Public.eternal_night = {
	on_world_start = function(journey)
		game.surfaces.nauvis.daytime = 0.5
		game.surfaces.nauvis.freeze_daytime = true
	end,
}

Public.eternal_day = {
	on_world_start = function(journey)
		game.surfaces.nauvis.daytime = 0
		game.surfaces.nauvis.freeze_daytime = true
	end,
}

Public.matter_anomaly = {
	on_world_start = function(journey)
		local force = game.forces.player
		for i = 1, 4, 1 do force.technologies['mining-productivity-' .. i].researched = true end
		for i = 1, 6, 1 do force.technologies['mining-productivity-4'].researched = true end
	end,
}

Public.quantum_anomaly = {
	on_world_start = function(journey)
		local force = game.forces.player
		for i = 1, 6, 1 do force.technologies['research-speed-' .. i].researched = true end
	end,
}

Public.mountainous = {
	on_player_mined_entity = function(event)
		local entity = event.entity
		if not entity.valid then	return end
		if not rock_yield[entity.name] then	return end
		local surface = entity.surface
		event.buffer.clear()
		local ore = ore_raffle[math_random(1, size_of_ore_raffle)]
		local count = math_floor(math_sqrt(entity.position.x ^ 2 + entity.position.y ^ 2) * 0.02) + math_random(25, 75)
		local ore_amount = math_floor(count * 0.85)
		local stone_amount = math_floor(count * 0.15)
		surface.spill_item_stack(entity.position, {name = ore, count = ore_amount}, true)
		surface.spill_item_stack(entity.position, {name = 'stone', count = stone_amount}, true)   
	end,
	on_chunk_generated = function(event, journey)
		local surface = event.surface
		local seed = surface.map_gen_settings.seed
		local left_top_x = event.area.left_top.x
		local left_top_y = event.area.left_top.y
		local get_tile = surface.get_tile
		local position
		local noise
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				if math_random(1, 3) ~= 1 then
					position = {x = left_top_x + x, y = left_top_y + y}
					if surface.can_place_entity({name = "coal", position = position}) then
						noise = math_abs(Get_noise('scrapyard', position, seed))
						if noise < 0.025 or noise > 0.50 then
							surface.create_entity({name = rock_raffle[math_random(1, size_of_rock_raffle)], position = position})
						end
					end
				end
			end
		end
	end,
}

Public.replicant_fauna = {
	on_entity_died = function(event)
		local entity = event.entity
		if not entity.valid then	return end
		local cause = event.cause
		if not cause then return end
		if not cause.valid then return end
		if cause.force.index == 2 then cause.surface.create_entity({name = cause.name, position = entity.position, force = "enemy"}) end
	end,
}

Public.pitch_black = {
	on_world_start = function(journey)
		local surface = game.surfaces.nauvis
		surface.daytime = 0.5
		surface.freeze_daytime = true
		surface.min_brightness = 0
		surface.brightness_visual_weights = {1, 1, 1, 1}
	end,
}

Public.tarball = {	
	on_robot_built_entity = function(event)
		local entity = event.created_entity
		if not entity.valid then return end
		if entity.surface.index ~= 1 then return end
		entity.minable = false
	end,
	on_built_entity = function(event)
		local entity = event.created_entity
		if not entity.valid then return end
		if entity.surface.index ~= 1 then return end
		entity.minable = false
	end,
	on_chunk_generated = function(event, journey)
		table.insert(journey.world_color_filters, rendering.draw_sprite(
			{
				sprite = 'tile/lab-dark-1',
				x_scale = 32,
				y_scale = 32,
				target = event.area.left_top,
				surface = event.surface,
				tint = {r = 0.0, g = 0.0, b = 0.0, a = 0.5},
				render_layer = 'ground'
			}
		))
	end,
}

Public.swamps = {
	on_chunk_generated = function(event, journey)	
		local surface = event.surface
		local seed = surface.map_gen_settings.seed
		local left_top_x = event.area.left_top.x
		local left_top_y = event.area.left_top.y
		
		local tiles = {}
		for _, tile in pairs(surface.find_tiles_filtered({name = {"water", "deepwater"}, area = event.area})) do
			table.insert(tiles, {name = "water-shallow", position = tile.position})
		end
		surface.set_tiles(tiles, true, false, false, false)
		
		local tiles = {}
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do				
				local position = {x = left_top_x + x, y = left_top_y + y}
				local noise = Get_noise('journey_swamps', position, seed)
				if noise > 0.45 or noise < -0.65 then table.insert(tiles, {name = "water-shallow", position = {x = position.x, y = position.y}}) end							
			end
		end
		surface.set_tiles(tiles, true, false, false, false)
		
		for _, tile in pairs(tiles) do
			if math_random(1, 32) == 1 then
				surface.create_entity({name = "fish", position = tile.position})
			end
		end
	end,
}

Public.volcanic = {
	on_chunk_generated = function(event, journey)
		table.insert(journey.world_color_filters, rendering.draw_sprite({
				sprite = 'tile/lab-dark-2',
				x_scale = 32,
				y_scale = 32,
				target = event.area.left_top,
				surface = event.surface,
				tint = {r = 0.55, g = 0.0, b = 0.0, a = 0.5},
				render_layer = 'ground'
		}))
	end,
	on_player_changed_position = function(event)
		local player = game.players[event.player_index]
		if player.driving then return end
		local surface = player.surface
		if surface.index ~= 1 then return end
		if solid_tiles[surface.get_tile(player.position).name] then return end
		surface.create_entity({name = "fire-flame", position = player.position})
	end,
	on_world_start = function(journey)
		local surface = game.surfaces.nauvis
		surface.request_to_generate_chunks({x = 0, y = 0}, 3)
		surface.force_generate_chunk_requests()
		surface.spill_item_stack({0, 0}, {name = "stone-brick", count = 4096}, true)
	end,
}

Public.chaotic_resources = {
	on_chunk_generated = function(event, journey)
		local surface = event.surface
		for _, ore in pairs(surface.find_entities_filtered({area = event.area, name = {'iron-ore', 'copper-ore', 'coal', 'stone'}})) do
			surface.create_entity({name = ore_raffle_2[math_random(1, size_of_ore_raffle_2)], position = ore.position, amount = ore.amount})
			ore.destroy()
		end
	end,
}

Public.infested = {
	on_entity_died = function(event)
		local entity = event.entity
		if not entity.valid then	return end
		if entity.force.index ~= 3 then return end
		entity.surface.create_entity({name = BiterRaffle.roll('mixed', game.forces.enemy.evolution_factor + 0.1), position = entity.position, force = 'enemy'})
	end,
	on_player_mined_entity = function(event)
		local entity = event.entity
		if not entity.valid then	return end
		if entity.force.index ~= 3 then return end
		entity.surface.create_entity({name = BiterRaffle.roll('mixed', game.forces.enemy.evolution_factor + 0.1), position = entity.position, force = 'enemy'})
	end,
	on_robot_mined_entity = function(event)
		local entity = event.entity
		if not entity.valid then	return end
		if entity.force.index ~= 3 then return end
		entity.surface.create_entity({name = BiterRaffle.roll('mixed', game.forces.enemy.evolution_factor + 0.1), position = entity.position, force = 'enemy'})
	end,
}

Public.undead_plague = {
	on_entity_died = function(event)
		local entity = event.entity
		if not entity.valid then	return end
		if entity.force.index ~= 2 then return end
		if math_random(1,2) == 1 then return end
		entity.surface.create_entity({name = entity.name, position = entity.position, force = 'enemy'})
	end,
}

Public.low_mass = {
	on_world_start = function(journey)
		local force = game.forces.player
		force.character_running_speed_modifier = 0.5
		for i = 1, 6, 1 do force.technologies['worker-robots-speed-' .. i].researched = true end		
	end,
}

Public.dense_atmosphere = {
	on_robot_built_entity = function(event)
		local entity = event.created_entity
		if not entity.valid then return end
		if entity.surface.index ~= 1 then return end
		if entity.name == "roboport" then entity.die() end
	end,
	on_built_entity = function(event)
		local entity = event.created_entity
		if not entity.valid then return end
		if entity.surface.index ~= 1 then return end
		if entity.name == "roboport" then entity.die() end
	end,
}

return Public