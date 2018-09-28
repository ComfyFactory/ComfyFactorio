--spaghettorio-- mewmew made this -- inspired by redlabel

require "maps.spaghettorio_map_intro"
local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local event = require 'utils.event'

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.map_init_done then			
		local map_gen_settings = {}
		map_gen_settings.water = "none"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 50, cliff_elevation_0 = 50}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "none", size = "none", richness = "none"},
			["stone"] = {frequency = "none", size = "none", richness = "none"},
			["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
			["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
			["crude-oil"] = {frequency = "none", size = "none", richness = "none"},
			["trees"] = {frequency = "none", size = "none", richness = "none"},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"},
			["grass"] = {frequency = "none", size = "none", richness = "none"},
			["sand"] = {frequency = "none", size = "none", richness = "none"},
			["desert"] = {frequency = "none", size = "none", richness = "none"},
			["dirt"] = {frequency = "none", size = "none", richness = "none"}
		}
		game.map_settings.pollution.pollution_restored_per_tree_damage = 0
		game.create_surface("spaghettorio", map_gen_settings)		
		game.forces["player"].set_spawn_position({16,16},game.surfaces["spaghettorio"])
		local surface = game.surfaces["spaghettorio"]
		
		if not global.spaghettorio_size then	global.spaghettorio_size = 1 end
		global.map_init_done = true						
	end	
	local surface = game.surfaces["spaghettorio"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("player", {16,16}, 2, 1), "spaghettorio")
	else
		if player.online_time < 5 then
			player.teleport({16,16}, "spaghettorio")
		end
	end	
	if player.online_time < 10 then				
		player.insert {name = 'raw-fish', count = 3}
		player.insert {name = 'iron-axe', count = 1}		
		player.insert {name = 'pistol', count = 1}
		player.insert {name = 'firearm-magazine', count = 32}
	end	
end

local function on_chunk_generated(event)
	local surface = game.surfaces[1]
	if event.surface.name ~= surface then return end
	
	
end

---kyte
local function on_player_rotated_entity(event)
    if event.entity.type ~= "loader" then return end
    local surface = game.surfaces[1]
    local tiles = {}
	if not global.trainpath_1 then
		if event.entity.position.x == 448.5 and event.entity.position.y == -191 then
		game.print("Trainpath to rewards of level 1 unlocked!")
		global.trainpath_1 = true
			for x = -11, 21, 1 do
				for y = -4, 0, 1 do
					table.insert(tiles, {name = "dirt-6", position = {x = event.entity.position.x + x, y = event.entity.position.y + y}})
				end
			end
			surface.set_tiles(tiles, true)
		end
	end
end

function cheat_mode()
	local cheat_mode_enabed = false
	if cheat_mode_enabed == true then
		local surface = game.surfaces["spaghettorio"]
		game.player.cheat_mode=true
		game.players[1].insert({name="power-armor-mk2"})
		game.players[1].insert({name="fusion-reactor-equipment", count=4})
		game.players[1].insert({name="personal-laser-defense-equipment", count=8})
		game.players[1].insert({name="rocket-launcher"})		
		game.players[1].insert({name="explosive-rocket", count=200})		
		game.speed = 2
		surface.daytime = 1
		surface.freeze_daytime = 1
		game.player.force.research_all_technologies()
		game.forces["enemy"].evolution_factor = 0.2
		local chart = 200
		local surface = game.surfaces["spaghettorio"]	
		game.forces["player"].chart(surface, {lefttop = {x = chart*-1, y = chart*-1}, rightbottom = {x = chart, y = chart}})		
	end
end

event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)