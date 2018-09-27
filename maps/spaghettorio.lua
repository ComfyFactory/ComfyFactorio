--spaghettorio-- mewmew made this -- inspired by redlabel
require "maps.labyrinth_map_intro"
local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local event = require 'utils.event'

local function on_chunk_generated(event)
	local surface = game.surfaces[1]
	if event.surface.name ~= surface then return end
	
	
end

---kyte
local function on_player_rotated_entity(event)
	if event.entity.type ~= "inserter" then return end
	local surface = game.surfaces[1]
	local tiles = {}
	if event.entity.position.x == 459 and event.entity.position.y == 1 then 
		for x = -11, 21, 1 do
			for y = -4, 0, 1 do
				table.insert(tiles, {name = "dirt-6", position = {x = event.entity.position.x + x, y = event.entity.position.y + y}})
			end
		end
		surface.set_tiles(tiles, true)		
	end	
end

function cheat_mode()
	local cheat_mode_enabed = false
	if cheat_mode_enabed == true then
		local surface = game.surfaces["labyrinth"]
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
		local surface = game.surfaces["labyrinth"]	
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