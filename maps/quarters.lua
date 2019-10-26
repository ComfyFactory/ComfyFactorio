require "modules.mineable_wreckage_yields_scrap"
require "modules.wave_defense.main"
require "modules.map_info"
map_info = {}
map_info.main_caption = "4 Quarters"
map_info.sub_caption =  "coal ++ iron ++ copper ++ stone"
map_info.text = table.concat({
	"Green energy ore may be found in the stone area.\n",
	"Oil may be found in the coal area.\n",
	"\n",
	"Hold the door as long as possible.\n",
	"Don't let them in!\n",
})
map_info.main_caption_color = {r = 0, g = 120, b = 0}
map_info.sub_caption_color = {r = 255, g = 0, b = 255}

--require "modules.biters_attack_moving_players"
--[[
local difficulties_votes = {
    [1] = {tick_increase = 4500, amount_modifier = 0.52, strength_modifier = 0.40, boss_modifier = 3.0},
    [2] = {tick_increase = 4100, amount_modifier = 0.76, strength_modifier = 0.65, boss_modifier = 4.0},
    [3] = {tick_increase = 3800, amount_modifier = 0.92, strength_modifier = 0.85, boss_modifier = 5.0},
    [4] = {tick_increase = 3600, amount_modifier = 1.00, strength_modifier = 1.00, boss_modifier = 6.0},
    [5] = {tick_increase = 3400, amount_modifier = 1.08, strength_modifier = 1.25, boss_modifier = 7.0},
    [6] = {tick_increase = 3100, amount_modifier = 1.24, strength_modifier = 1.75, boss_modifier = 8.0},
    [7] = {tick_increase = 2700, amount_modifier = 1.48, strength_modifier = 2.50, boss_modifier = 9.0}
}
]]
local simplex_noise = require 'utils.simplex_noise'.d2
local spawn_size = 96
local wall_thickness = 3

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
	--if p.y < -32 and p.x < -32 then return false end
	--if p.y > 32 and p.x > 32 then return false end
	if p.x >= spawn_size - wall_thickness then return true end
	if p.x < spawn_size * -1 + wall_thickness then return true end
	if p.y >= spawn_size - wall_thickness then return true end
	if p.y < spawn_size * -1 + wall_thickness then return true end
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

local function get_quarter_name(position)
	if position.x < 0 then
		if position.y < 0 then
			return "NW"
		else
			return "SW"
		end
	else
		if position.y < 0 then
			return "NE"
		else
			return "SE"
		end	
	end
end
--[[
local function send_peace_quarter_biters()
	local surface = game.surfaces[1]
	local target = surface.find_nearest_enemy({position = {0, 0}, max_distance = 99999, force = "enemy"})
	if target then
		target = target.position
	else
		target = {x = 0, y = 0}
	end
	local units_nw = {}
	local units_se = {}
	for _, unit in pairs(surface.find_entities_filtered({type = "unit"})) do
		local quarter = get_quarter_name(unit.position)
		if quarter == "NW" then units_nw[#units_nw + 1] = unit end
		if quarter == "SE" then units_se[#units_se + 1] = unit end
	end
	if #units_nw > 2 then table.shuffle_table(units_nw) end
	if #units_se > 2 then table.shuffle_table(units_se) end
	for i = 1, 512, 1 do
		if units_nw[i] then	
			units_nw[i].set_command({type=defines.command.attack_area, destination=target, radius=8, distraction=defines.distraction.by_anything})
		end
		if units_se[i] then
			units_se[i].set_command({type=defines.command.attack_area, destination=target, radius=8, distraction=defines.distraction.by_anything})
		end
	end
end
]]
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
	
	if left_top.x ^ 2 + left_top.y ^ 2 > 360000 then return end
	game.forces.player.chart(surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}})
end

local function set_difficulty()
	--20 Players for maximum difficulty
	global.wave_defense.wave_interval = 7200 - #game.connected_players * 270
	if global.wave_defense.wave_interval < 1800 then global.wave_defense.wave_interval = 1800 end	
end

local function on_player_joined_game(event)
	set_difficulty()
end

local function on_player_left_game(event)
	set_difficulty()
end

--[[
local function tick(event)
	local size = math.floor((8 + game.tick / difficulties_votes[global.difficulty_vote_index].tick_increase) * difficulties_votes[global.difficulty_vote_index].amount_modifier)
	if size > 80 then size = 80 end
	game.map_settings.enemy_expansion.settler_group_min_size = size
	game.map_settings.enemy_expansion.settler_group_max_size = size * 2
	
	game.map_settings.enemy_evolution.destroy_factor = global.enemy_evolution_destroy_factor * difficulties_votes[global.difficulty_vote_index].strength_modifier
	game.map_settings.enemy_evolution.time_factor = global.enemy_evolution_time_factor * difficulties_votes[global.difficulty_vote_index].strength_modifier
	game.map_settings.enemy_evolution.pollution_factor = global.enemy_evolution_pollution_factor * difficulties_votes[global.difficulty_vote_index].strength_modifier

	if game.tick % 240 == 0 then
		game.forces.player.chart(game.surfaces[1], {{-192, -192},{160, 160}})
	end
	
	if game.tick % 18000 == 0 then
		send_peace_quarter_biters()
	end
	--game.map_settings.enemy_expansion.min_expansion_cooldown = difficulties_votes[global.difficulty_vote_index].tick_increase
	--game.map_settings.enemy_expansion.max_expansion_cooldown = difficulties_votes[global.difficulty_vote_index].tick_increase
	
	--local amount = 1 + game.tick / 120
	--if amount > 32 then amount = 32 end
	--game.surfaces[1].pollute({-1 + math.random(0, 2), -1 + math.random(0, 2)}, amount)
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
]]

local function on_init()
	for i, quarter in pairs({"coal", "iron-ore", "stone", "copper-ore"}) do
		local map_gen_settings = {}
		map_gen_settings.seed = math.random(1, 999999999)
		map_gen_settings.water = math.random(25, 50) * 0.01
		map_gen_settings.starting_area = 1.5
		map_gen_settings.terrain_segmentation = math.random(25, 50) * 0.1	
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 0, cliff_elevation_0 = 0}
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = 0, size = 0.5, richness = 0.5},
			["stone"] = {frequency = 0, size = 0.5, richness = 0.5},
			["copper-ore"] = {frequency = 0, size = 0.5, richness = 0.5},
			["iron-ore"] = {frequency = 0, size = 0.5, richness = 0.5},
			["uranium-ore"] = {frequency = 0, size = 1, richness = 1},
			["crude-oil"] = {frequency = 0, size = 1, richness = 1},
			["trees"] = {frequency = math.random(10, 50) * 0.1, size = math.random(5, 15) * 0.1, richness = math.random(1, 10) * 0.1},
			["enemy-base"] = {frequency = 2, size = 2, richness = 1}	
		}	
		map_gen_settings.autoplace_controls[quarter].frequency = 16
		
		if quarter == "coal" then
			map_gen_settings.autoplace_controls["crude-oil"].frequency = 8
		end
		if quarter == "stone" then
			map_gen_settings.autoplace_controls["uranium-ore"].frequency = 8
		end
		
		game.create_surface(quarter, map_gen_settings)
	end
	
	--[[
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.settler_group_min_size = 8
	game.map_settings.enemy_expansion.settler_group_max_size = 16
	game.map_settings.enemy_expansion.min_expansion_cooldown = 2700
	game.map_settings.enemy_expansion.max_expansion_cooldown = 2700
	
	game.map_settings.pollution.enabled = true
	game.map_settings.enemy_evolution.enabled = true
	
	local modifier_factor = 2
	
	--default game setting values
	global.enemy_evolution_destroy_factor = game.map_settings.enemy_evolution.destroy_factor * modifier_factor
	global.enemy_evolution_time_factor = game.map_settings.enemy_evolution.time_factor * modifier_factor
	global.enemy_evolution_pollution_factor = game.map_settings.enemy_evolution.pollution_factor * modifier_factor
	]]
end

local event = require 'utils.event'
--event.on_nth_tick(60, tick)
event.on_init(on_init)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_entity_died, on_entity_died)
--event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_left_game, on_player_left_game)

--require "modules.difficulty_vote"