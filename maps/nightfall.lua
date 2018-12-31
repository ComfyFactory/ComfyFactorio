-- nightfall -- by mewmew --

local event = require 'utils.event'
local math_random = math.random
local insert = table.insert
local map_functions = require "maps.tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'
local simplex_noise = simplex_noise.d2
require "maps.modules.splice"
require "maps.modules.explosive_biters"

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
	
	for i = 1, global.night_count * 4, 1 do
		if not biters[i] then break end
		unit_group.add_member(biters[i])
	end
	
	unit_group.set_command({type = defines.command.attack_area, destination = {0,0}, radius = 32, distraction = defines.distraction.by_anything})
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
		global.splice_modifier = global.splice_modifier + 0.33
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
	map_functions.draw_smoothed_out_ore_circle(ore_positions[1], "copper-ore", surface, 15, 2500)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[2], "iron-ore", surface, 15, 2500)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[3], "coal", surface, 15, 1500)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[4], "stone", surface, 15, 1500)	
	map_functions.draw_oil_circle({x = 0, y = 0}, "crude-oil", surface, 8, 200000)
	
	local lake_size = 14
	local lake_distance = fort_size - (lake_size + fort_wall_width)
	local lake_positioons = {{x = lake_distance * -1, y = lake_distance * -1},{x = lake_distance, y = lake_distance * -1},{x = lake_distance, y = lake_distance},{x = lake_distance * -1, y = lake_distance}}
	lake_positioons = shuffle(lake_positioons)
	map_functions.draw_noise_tile_circle(lake_positioons[1], "water", surface, lake_size)
	
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
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]

	if not global.fish_defense_init_done then	
		local map_gen_settings = {}
		map_gen_settings.water = "small"
		map_gen_settings.starting_area = "small"		 
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 5, cliff_elevation_0 = 5}		
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
		
		----game.map_settings.enemy_evolution.destroy_factor = 0
		--game.map_settings.enemy_evolution.time_factor = 0
		--game.map_settings.enemy_evolution.pollution_factor = 0	
		
		game.forces.player.set_ammo_damage_modifier("shotgun-shell", 1)				
		--game.forces.player.set_turret_attack_modifier("flamethrower-turret", -0.5)
		
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
		player.teleport(surface.find_non_colliding_position("player", {0, 0}, 50, 1), "nightfall")
	else
		if player.online_time < 2 then
			player.teleport({0, 0}, "nightfall")
		end
	end
	
	create_time_gui(player)
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)