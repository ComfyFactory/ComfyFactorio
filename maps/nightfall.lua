-- nightfall -- by mewmew --

local event = require 'utils.event'
local math_random = math.random
local insert = table.insert
local map_functions = require "maps.tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'
local simplex_noise = simplex_noise.d2
require "maps.modules.splice"
require "maps.modules.explosive_biters"
require "maps.modules.biters_yield_coins"
require "maps.modules.spawners_contain_biters"

local spawn_turret_amount = 8

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function create_time_gui(player)
	if player.gui.top["time_gui"] then player.gui.top["time_gui"].destroy() end
	local frame = player.gui.top.add({ type = "frame", name = "time_gui"})
	frame.style.maximal_height = 38

	local night_count = 0
	if global.night_count then night_count = global.night_count end
		
	local label = frame.add({ type = "label", caption = "Night: " .. night_count })
	label.style.font_color = {r=0.75, g=0.0, b=0.25}
	label.style.font = "default-listbox"
	label.style.left_padding = 4
	label.style.right_padding = 4
	label.style.minimal_width = 50	
end

local function send_attack_group(surface)
	local spawners = surface.find_entities_filtered({type = "unit-spawner"})
	if not spawners[1] then return end
	
	local spawner = spawners[math_random(1, #spawners)]	
	
	local biters = surface.find_enemy_units(spawner.position, 128, "player")	
	if not biters[1] then return end
	
	biters = shuffle(biters)
	
	local pos = surface.find_non_colliding_position("rocket-silo", spawner.position, 64, 1)
	if not pos then return end
	
	local unit_group = surface.create_unit_group({position=pos, force="enemy"})
	
	local group_size = 4 + (global.night_count * 4)
	if group_size > 250 then group_size = 250 end
	
	for i = 1, group_size, 1 do
		if not biters[i] then break end
		unit_group.add_member(biters[i])
	end
	
	if global.rocket_silo.valid then
		unit_group.set_command({
			type = defines.command.compound,
			structure_type = defines.compound_command.return_last,
			commands = {
						{
							type = defines.command.attack_area,
							destination = {x = 0, y = 0},
							radius = 48,
							distraction=defines.distraction.by_anything
						},									
						{
							type = defines.command.attack,
							target = global.rocket_silo,
							distraction = defines.distraction.by_enemy
						}
				}
			})
	else
		unit_group.set_command({
			type = defines.command.compound,
			structure_type = defines.compound_command.return_last,
			commands = {
						{
							type = defines.command.attack_area,
							destination = {x = 0, y = 0},
							radius = 48,
							distraction=defines.distraction.by_anything
						}														
				}
			})
	end
end

local function set_daytime_modifiers(surface)
	if surface.peaceful_mode == true then return end
	
	game.map_settings.enemy_expansion.enabled = false
	surface.peaceful_mode = true
	
	game.print("Daytime!", {r = 255, g = 255, b = 50})
end

local function set_nighttime_modifiers(surface)
	if surface.peaceful_mode == false then return end
	
	if not global.night_count then
		global.night_count = 1
		global.splice_modifier = 1
	else
		global.night_count = global.night_count + 1
		--if game.forces["enemy"].evolution_factor > 0.75 then
			global.splice_modifier = global.splice_modifier + 0.25
		--end	
	end
	
	for _, player in pairs(game.connected_players) do
		create_time_gui(player)
	end
	
	surface.peaceful_mode = false	
	game.map_settings.enemy_expansion.enabled = true
	
	local max_expansion_distance = global.night_count
	if max_expansion_distance > 20 then max_expansion_distance = 20 end
	game.map_settings.enemy_expansion.max_expansion_distance = max_expansion_distance
	
	local settler_group_min_size = global.night_count
	if settler_group_min_size > 20 then settler_group_min_size = 20 end
	game.map_settings.enemy_expansion.settler_group_min_size = settler_group_min_size
	
	local settler_group_min_size = global.night_count
	if settler_group_min_size > 50 then settler_group_min_size = 50 end
	game.map_settings.enemy_expansion.settler_group_max_size = settler_group_min_size
	
	local min_expansion_cooldown = 54000 - global.night_count * 1800
	if min_expansion_cooldown < 1800 then min_expansion_cooldown = 1800 end
	game.map_settings.enemy_expansion.min_expansion_cooldown = min_expansion_cooldown
	
	local max_expansion_cooldown = 108000 - global.night_count * 1800
	if max_expansion_cooldown < 1800 then max_expansion_cooldown = 1800 end
	game.map_settings.enemy_expansion.max_expansion_cooldown = max_expansion_cooldown

	game.print("Night is falling!", {r = 150, g = 0, b = 0})	
end

local function generate_spawn_area(surface)		
	local entities = {}
	local tiles = {}	
	local fort_size = 64
	local fort_wall_width = 4
	local turrets = {}
	
	for x = -160, 160, 1 do
		for y = -160, 160, 1 do
			local pos = {x = x, y = y}
			if pos.x > fort_size * -1 and pos.x < fort_size and pos.y > fort_size * -1 and pos.y < fort_size then
				
				if pos.x > (fort_size - fort_wall_width) * -1 and pos.x < fort_size - fort_wall_width and pos.y > (fort_size - fort_wall_width) * -1 and pos.y < fort_size - fort_wall_width then
					if pos.x <= (fort_size - fort_wall_width * 2) * -1 or pos.x >= (fort_size - fort_wall_width * 2) or pos.y <= (fort_size - fort_wall_width * 2) * -1 or pos.y >= (fort_size - fort_wall_width * 2) then
						table.insert(turrets, {name = "gun-turret", position = {x = pos.x, y = pos.y}, force = "player"})
					end
				end
				
				for _, entity in pairs(surface.find_entities_filtered({area = {{pos.x, pos.y}, {pos.x + 0.99, pos.y + 0.99}}})) do
					if entity.name ~= "player" then
						entity.destroy()
					end
				end
								
				table.insert(tiles, {name = "stone-path", position = {x = pos.x, y = pos.y}})				
				
				if pos.x <= (fort_size - fort_wall_width) * -1 or pos.x >= (fort_size - fort_wall_width) or pos.y <= (fort_size - fort_wall_width) * -1 or pos.y >= (fort_size - fort_wall_width) then
					if math_random(1, 3) ~= 1 then
						table.insert(entities, {name = "stone-wall", position = {x = pos.x, y = pos.y}, force = "player"})
					end
				end
			end
		end						
	end
	surface.set_tiles(tiles, true)
	
	for _, entity in pairs(entities) do
		surface.create_entity(entity)
	end
	
	local ore_positions = {{x = -16, y = -16},{x = 16, y = -16},{x = -16, y = 16},{x = 16, y = 16}}
	ore_positions = shuffle(ore_positions)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[1], "copper-ore", surface, 18, 2500)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[2], "iron-ore", surface, 18, 2500)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[3], "coal", surface, 18, 2500)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[4], "stone", surface, 18, 2500)	
	
	local lake_size = 14
	local lake_distance = fort_size - (lake_size + fort_wall_width)
	local lake_positions = {{x = lake_distance * -1, y = lake_distance * -1},{x = lake_distance, y = lake_distance * -1},{x = lake_distance, y = lake_distance},{x = lake_distance * -1, y = lake_distance}}
	lake_positions = shuffle(lake_positions)
	map_functions.draw_noise_tile_circle(lake_positions[1], "water", surface, lake_size)
	map_functions.draw_oil_circle(lake_positions[2], "crude-oil", surface, 8, 200000)
	
	turrets = shuffle(turrets)	
	local x = spawn_turret_amount
	for _, entity in pairs(turrets) do
		if surface.can_place_entity(entity) then
			local turret = surface.create_entity(entity)
			if math_random(1, 3) ~= 1 then
				turret.health = turret.health - math_random(1, 250)
			end
			turret.insert({name = "firearm-magazine", count = math_random(4, 16)})
			x = x - 1
			if x == 0 then break end
		end
	end
	
	global.rocket_silo = surface.create_entity({name = "rocket-silo", position = {0, 0}, force = "player"})
	global.rocket_silo.minable = false
	
	local radius = 256
	game.forces.player.chart(surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})
end
			
local function on_chunk_generated(event)
	local surface = game.surfaces["nightfall"]
	--local seed = game.surfaces[1].map_gen_settings.seed
	if event.surface.name ~= surface.name then return end
	local left_top = event.area.left_top
	local tiles = {}		
	
	if left_top.x > 160 then
		if not global.nightfall_spawn_generated then
			generate_spawn_area(surface)
			global.nightfall_spawn_generated = true
		end
	end
end

local function on_entity_damaged(event)
	if not event.cause then return end
	if event.entity.valid then		
		if event.entity == global.rocket_silo then	
			if event.cause.force.name == "enemy" then return end
			event.entity.health = event.entity.health + event.final_damage_amount
		end
	end
end

local function on_tick(event)
	if game.tick % 600 ~= 0 then return end
	local surface = game.surfaces["nightfall"]
	if surface.daytime > 0.25 and surface.daytime < 0.75 then
		set_nighttime_modifiers(surface)
		if surface.daytime < 0.55 then
			send_attack_group(surface)
		end
	else
		set_daytime_modifiers(surface)
	end
	
	if global.rocket_silo then
		if global.rocket_silo.valid then return end
	end
	
	if game.tick < 3600 then return end
			
	if not global.game_restart_timer then
		global.game_restart_timer = 7200
	else
		if global.game_restart_timer < 0 then return end
		global.game_restart_timer = global.game_restart_timer - 600
	end
	if global.game_restart_timer % 1800 == 0 then 
		if global.game_restart_timer > 0 then game.print("Map will restart in " .. global.game_restart_timer / 60 .. " seconds!", { r=0.22, g=0.88, b=0.22}) end
		if global.game_restart_timer == 0 then
			game.print("Map is restarting!", { r=0.22, g=0.88, b=0.22})
			game.write_file("commandPipe", ":loadscenario --force", false, 0)
		end							
	end			
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]

	if not global.fish_defense_init_done then	
		local map_gen_settings = {}
		map_gen_settings.water = "small"
		map_gen_settings.starting_area = "small"		 
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 35, cliff_elevation_0 = 35}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "high", size = "very-big", richness = "normal"},
			["stone"] = {frequency = "high", size = "very-big", richness = "normal"},
			["copper-ore"] = {frequency = "high", size = "very-big", richness = "normal"},
			["iron-ore"] = {frequency = "high", size = "very-big", richness = "normal"},
			["crude-oil"] = {frequency = "very-high", size = "very-big", richness = "normal"},
			["trees"] = {frequency = "normal", size = "normal", richness = "normal"},
			["enemy-base"] = {frequency = "normal", size = "normal", richness = "very-good"},
			["grass"] = {frequency = "normal", size = "normal", richness = "normal"},
			["sand"] = {frequency = "normal", size = "normal", richness = "normal"},
			["desert"] = {frequency = "normal", size = "normal", richness = "normal"},
			["dirt"] = {frequency = "normal", size = "normal", richness = "normal"}
		}		
		game.create_surface("nightfall", map_gen_settings)							
		local surface = game.surfaces["nightfall"]
		
		local radius = 512
		game.forces.player.chart(surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})											
		
		--game.map_settings.enemy_evolution.destroy_factor = 0
		--game.map_settings.enemy_evolution.time_factor = 0
		--game.map_settings.enemy_evolution.pollution_factor = 0	
		
		game.forces.player.set_ammo_damage_modifier("shotgun-shell", 1)				
		
		global.fish_defense_init_done = true
	end

	if player.online_time < 1 then
		player.insert({name = "pistol", count = 1})
		player.insert({name = "iron-axe", count = 1})
		player.insert({name = "raw-fish", count = 3})
		player.insert({name = "firearm-magazine", count = 16})
		player.insert({name = "iron-plate", count = 32})
		if global.show_floating_killscore then global.show_floating_killscore[player.name] = false end
	end
	
	local surface = game.surfaces["nightfall"]
	if player.online_time < 2 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("player", {0, 8}, 50, 1), "nightfall")
	else
		if player.online_time < 2 then
			player.teleport({0, 8}, "nightfall")
		end
	end
	
	create_time_gui(player)
end

event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)