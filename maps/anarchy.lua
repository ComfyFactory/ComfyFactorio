--anarchy mode map -- by mewmew --

require "maps.anarchy_map_intro"
require "maps.modules.anarchy_mode"
local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random
local map_functions = require "maps.tools.map_functions"

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	if not global.map_init_done then				
		game.map_settings.enemy_expansion.enabled = false		
		game.map_settings.enemy_evolution.time_factor = 0
		game.map_settings.enemy_evolution.pollution_factor = 0					
		--game.map_settings.pollution.enabled = false
		global.map_init_done = true
	end	
	
	if player.online_time == 0 then		
		player.insert{name = 'iron-axe', count = 1}
		player.insert{name = 'iron-plate', count = 32}		
	end	
end

local function on_built_entity(event)
	local entity = event.created_entity
	if not entity.valid then return end
	local distance_to_center = math.sqrt(entity.position.x^2 + entity.position.y^2)
	if distance_to_center > 96 then return end
	local surface = entity.surface
	surface.create_entity({name = "flying-text", position = entity.position, text = "Spawn is protected from building.", color = {r=0.88, g=0.1, b=0.1}})					 
	local player = game.players[event.player_index]			
	player.insert({name = entity.name, count = 1})
	if global.score then
		if global.score[player.force.name] then
			if global.score[player.force.name].players[player.name] then
				global.score[player.force.name].players[player.name].built_entities = global.score[player.force.name].players[player.name].built_entities - 1
			end
		end
	end		
	entity.destroy()			
end

local function on_chunk_generated(event)
	local surface = event.surface
	local left_top = event.area.left_top
	
	--[[
	local entities = surface.find_entities_filtered({area = event.area, force = "enemy"})
	for _, entity in pairs(entities) do
		entity.destroy()
	end
	local entities = {}	
	]]
		
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}			
			if math_random(1, 50000) == 1 then
				map_functions.draw_entity_circle(pos, "stone", surface, 6, true, 1000000)
				map_functions.draw_entity_circle(pos, "coal", surface, 12, true, 1000000)
				map_functions.draw_entity_circle(pos, "copper-ore", surface, 18, true, 1000000)
				map_functions.draw_entity_circle(pos, "iron-ore", surface, 24, true, 1000000)
				map_functions.draw_noise_tile_circle(pos, "water", surface, 4)		
			end
			--[[
			if math_random(1, 75000) == 1 and pos.x^2 + pos.y^2 > 60000 then							
				if surface.can_place_entity({name = "biter-spawner", position = pos}) then
					if math_random(1, 4) == 1 then
						table_insert(entities, {name = "spitter-spawner", position = pos})					
					else
						table_insert(entities, {name = "biter-spawner", position = pos})						
					end
				end
			end
			]]
		end
	end
	
	--[[
	for _, entity in pairs(entities) do
		surface.create_entity(entity)
	end
	]]
	
	if not global.spawn_generated and left_top.x <= -96 then
		map_functions.draw_noise_tile_circle({x = 0, y = 0}, "stone-path", surface, 33)
		map_functions.draw_noise_tile_circle({x = 0, y = 0}, "concrete", surface, 11)		
		global.spawn_generated = true
	end
end

local function on_player_respawned(event)
	local player = game.players[event.player_index]	
	player.insert{name = 'iron-axe', count = 1}
	player.insert{name = 'iron-plate', count = 32}
end

----------share chat -------------------
local function on_console_chat(event)
	if not event.message then return end	
	if not event.player_index then return end	
	local player = game.players[event.player_index] 
	
	local color = {}
	color = player.color
	color.r = color.r * 0.6 + 0.35
	color.g = color.g * 0.6 + 0.35
	color.b = color.b * 0.6 + 0.35
	color.a = 1	
	
	for _, target_player in pairs(game.connected_players) do
		if target_player.name ~= player.name then
			if target_player.force ~= player.force then
				target_player.print(player.name .. ": ".. event.message, color)
			end
		end
	end
end

event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_console_chat, on_console_chat)
event.add(defines.events.on_player_respawned, on_player_respawned)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_chunk_generated, on_chunk_generated)