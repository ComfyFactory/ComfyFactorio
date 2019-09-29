require "modules.mineable_wreckage_yields_scrap"

local difficulties_votes = {
    [1] = {tick_increase = 4500, amount_modifier = 0.52, strength_modifier = 0.40, boss_modifier = 3.0},
    [2] = {tick_increase = 4100, amount_modifier = 0.76, strength_modifier = 0.65, boss_modifier = 4.0},
    [3] = {tick_increase = 3800, amount_modifier = 0.92, strength_modifier = 0.85, boss_modifier = 5.0},
    [4] = {tick_increase = 3600, amount_modifier = 1.00, strength_modifier = 1.00, boss_modifier = 6.0},
    [5] = {tick_increase = 3400, amount_modifier = 1.08, strength_modifier = 1.25, boss_modifier = 7.0},
    [6] = {tick_increase = 3100, amount_modifier = 1.24, strength_modifier = 1.75, boss_modifier = 8.0},
    [7] = {tick_increase = 2700, amount_modifier = 1.48, strength_modifier = 2.50, boss_modifier = 9.0}
}

local simplex_noise = require 'utils.simplex_noise'.d2
local spawn_size = 96

local function clone_chunk(event, source_surface_name)
	local source_surface = game.surfaces[source_surface_name]
	
	source_surface.request_to_generate_chunks(event.area.left_top, 1)
	source_surface.force_generate_chunk_requests()
	
	source_surface.clone_area({
		source_area=event.area,
		destination_area=event.area,
		destination_surface=game.surfaces[1],
		--destination_force="neutral",
		clone_tiles=true,
		clone_entities=true,
		clone_decoratives=true,
		clear_destination=true,
		expand_map=false
	})
end

local function is_spawn_wall(p)
	if p.y < -32 and p.x < -32 then return false end
	if p.y > 32 and p.x > 32 then return false end
	if p.x >= spawn_size - 2 then return true end
	if p.x < spawn_size * -1 + 2 then return true end
	if p.y >= spawn_size - 2 then return true end
	if p.y < spawn_size * -1 + 2 then return true end
	return false
end

local function spawn_area(event)
	local left_top = event.area.left_top
	
	for _, entity in pairs(event.surface.find_entities_filtered({area = event.area, force = "neutral"})) do
		entity.destroy()
	end
	
	local ore = false
	if left_top.x == -64 and left_top.y == -64 then ore = "coal" end
	if left_top.x == 32 and left_top.y == 32 then ore = "stone" end
	if left_top.x == 32 and left_top.y == -64 then ore = "iron-ore" end
	if left_top.x == -64 and left_top.y == 32 then ore = "copper-ore" end

	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			event.surface.set_tiles({{name = "stone-path", position = p}})			
			if is_spawn_wall(p) then
				event.surface.create_entity({name = "stone-wall", position = p, force = "player"}) 
			else
				if not ore then
					if math.sqrt(p.x ^ 2 + p.y ^ 2) > 4 then
						if math.random(1, 3) ~= 1 then
							local noise = simplex_noise(p.x * 0.015, p.y * 0.015, game.surfaces[1].map_gen_settings.seed) + simplex_noise(p.x * 0.055, p.y * 0.055, game.surfaces[1].map_gen_settings.seed) * 0.5
							if noise > 0.6 then
								event.surface.create_entity({name = "mineable-wreckage", position = p, force = "neutral"})
							end
							if noise < -0.75 then
								if math.random(1, 16) == 1 then
									event.surface.create_entity({name = "rock-big", position = p, force = "neutral"})
								end
							end
						end
					end
				end
			end					
		end
	end
	
	if left_top.x == -64 and left_top.y == -64 then 
		local wreck = event.surface.create_entity({name = "big-ship-wreck-1", position = {0, -4}, force = "player"})
		wreck.insert({name = "submachine-gun", count = 3})
		wreck.insert({name = "firearm-magazine", count = 32})
		wreck.insert({name = "grenade", count = 8})
	end
	
	if not ore then return end
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			event.surface.create_entity({name = ore, position = p, amount = 1000})
		end
	end
end

local function draw_borders(surface, left_top, area)	
	if left_top.x == 0 or left_top.x == -32 then
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				local p = {left_top.x + x, left_top.y + y}
				surface.set_tiles({{name = "deepwater", position = p}})
			end
		end
		surface.destroy_decoratives({area = area})
	end
	
	if left_top.y == 0 or left_top.y == -32 then
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				local p = {left_top.x + x, left_top.y + y}
				surface.set_tiles({{name = "deepwater", position = p}})
			end
		end
		surface.destroy_decoratives({area = area})
	end
end

local function on_chunk_generated(event)
	if event.surface.index ~= 1 then return end
	local surface = event.surface
	local left_top = event.area.left_top
	
	if left_top.x < spawn_size and left_top.y < spawn_size and left_top.x >= spawn_size * -1 and left_top.y >= spawn_size * -1 then
		spawn_area(event)
		return
	end
	
	if left_top.x < 0 then
		if left_top.y < 0 then
			clone_chunk(event, "coal")
		else
			clone_chunk(event, "copper-ore")
		end
	else
		if left_top.y < 0 then
			clone_chunk(event, "iron-ore")
		else
			clone_chunk(event, "stone")
		end	
	end
	
	draw_borders(surface, left_top, event.area)
end

local function on_player_joined_game(event)
	
end

local function tick(event)
	local size = math.floor((8 + game.tick / difficulties_votes[global.difficulty_vote_index].tick_increase) * difficulties_votes[global.difficulty_vote_index].amount_modifier)
	if size > 80 then size = 80 end
	game.map_settings.enemy_expansion.settler_group_min_size = size
	game.map_settings.enemy_expansion.settler_group_max_size = size * 2	
	game.map_settings.enemy_expansion.min_expansion_cooldown = difficulties_votes[global.difficulty_vote_index].tick_increase
	game.map_settings.enemy_expansion.max_expansion_cooldown = difficulties_votes[global.difficulty_vote_index].tick_increase
end

--Flamethrower Turret Nerf
local function on_research_finished(event)
	local research = event.research
	local force_name = research.force.name
	if research.name == "flamethrower" then
		if not global.flamethrower_damage then global.flamethrower_damage = {} end
		global.flamethrower_damage[force_name] = -0.6
		game.forces[force_name].set_turret_attack_modifier("flamethrower-turret", global.flamethrower_damage[force_name])
		game.forces[force_name].set_ammo_damage_modifier("flamethrower", global.flamethrower_damage[force_name])						
	end
	
	if string.sub(research.name, 0, 18) == "refined-flammables" then
		global.flamethrower_damage[force_name] = global.flamethrower_damage[force_name] + 0.05
		game.forces[force_name].set_turret_attack_modifier("flamethrower-turret", global.flamethrower_damage[force_name])								
		game.forces[force_name].set_ammo_damage_modifier("flamethrower", global.flamethrower_damage[force_name])
	end	
end

local function on_init()
	
	for i, quarter in pairs({"coal", "iron-ore", "stone", "copper-ore"}) do
		local map_gen_settings = {}
		map_gen_settings.seed = math.random(1, 999999999)
		map_gen_settings.water = math.random(25, 50) * 0.01
		map_gen_settings.starting_area = 1.5
		map_gen_settings.terrain_segmentation = math.random(25, 50) * 0.1	
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 16, cliff_elevation_0 = 16}
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = 0, size = 0.5, richness = 0.25},
			["stone"] = {frequency = 0, size = 0.5, richness = 0.25},
			["copper-ore"] = {frequency = 0, size = 0.5, richness = 0.25},
			["iron-ore"] = {frequency = 0, size = 0.5, richness = 0.25},
			["uranium-ore"] = {frequency = 0, size = 0.75, richness = 0.5},
			["crude-oil"] = {frequency = 0, size = 1, richness = 1},
			["trees"] = {frequency = 3, size = 1.5, richness = 1},
			["enemy-base"] = {frequency = 0, size = 0.65, richness = 1}	
		}		
		if quarter == "coal" then
			map_gen_settings.autoplace_controls["coal"].frequency = 16
			map_gen_settings.autoplace_controls["iron-ore"].frequency = 16
			map_gen_settings.autoplace_controls["uranium-ore"].frequency = 2
		end
		if quarter == "stone" then
			map_gen_settings.autoplace_controls["stone"].frequency = 16
			map_gen_settings.autoplace_controls["copper-ore"].frequency = 16
			map_gen_settings.autoplace_controls["crude-oil"].frequency = 2
		end
		if quarter == "copper-ore" or quarter == "iron-ore" then
			map_gen_settings.autoplace_controls["enemy-base"].frequency = 256
			map_gen_settings.autoplace_controls["trees"].frequency = 3
			map_gen_settings.autoplace_controls["trees"].size = 0.4
			map_gen_settings.autoplace_controls["trees"].richness = 0.05
			map_gen_settings.cliff_settings = {cliff_elevation_interval = 32, cliff_elevation_0 = 32}
		end
		
		game.create_surface(quarter, map_gen_settings)
	end
	
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.settler_group_min_size = 8
	game.map_settings.enemy_expansion.settler_group_max_size = 16
	game.map_settings.enemy_expansion.min_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.max_expansion_cooldown = 3600
end

local event = require 'utils.event'
event.on_nth_tick(120, tick)
event.on_init(on_init)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_player_joined_game, on_player_joined_game)

require "modules.difficulty_vote"