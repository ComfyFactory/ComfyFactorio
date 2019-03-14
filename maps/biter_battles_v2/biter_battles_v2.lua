-- Biter Battles v2 -- by MewMew

local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random

local function init_surface()
	if game.surfaces["biter_battles"] then return end
	local map_gen_settings = {}
	--map_gen_settings.water = "none"
	--map_gen_settings.starting_area = "5"	
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 12, cliff_elevation_0 = 32}		
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "0.8", size = "1", richness = "0.3"},
		["stone"] = {frequency = "0.8", size = "1", richness = "0.3"},
		["copper-ore"] = {frequency = "0.8", size = "2", richness = "0.3"},
		["iron-ore"] = {frequency = "0.8", size = "2", richness = "0.3"},
		["crude-oil"] = {frequency = "0.8", size = "2", richness = "0.4"},
		["trees"] = {frequency = "0.8", size = "0.5", richness = "0.3"},
		["enemy-base"] = {frequency = "0.8", size = "1", richness = "0.4"}			
	}
	game.create_surface("biter_battles", map_gen_settings)
			
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.enemy_expansion.enabled = false
	game.map_settings.pollution.enabled = false
end

local function init_forces(surface)
	if game.forces.north then return end	
		
	game.create_force("north")		
	game.create_force("south")		
	game.create_force("spectator")
	
	local f = game.forces["north"]
	f.set_spawn_position({0, -32}, surface)
	f.set_cease_fire("player", true)
	f.set_friend("spectator", true)
	f.share_chart = true
	
	local f = game.forces["south"]
	f.set_spawn_position({0, 32}, surface)
	f.set_cease_fire("player", true)
	f.set_friend("spectator", true)
	f.share_chart = true
	
	local f = game.forces["spectator"]
	f.technologies["toolbelt"].researched=true
	f.set_spawn_position({0,0},surface)
	f.set_friend("north", true)
	f.set_friend("south", true)
	f.set_friend("player", true)
	
	local f = game.forces["player"]
	f.set_spawn_position({0,0},surface)			
	
	for _, force in pairs(game.forces) do
		game.forces[force.name].technologies["artillery"].enabled = false
		game.forces[force.name].technologies["artillery-shell-range-1"].enabled = false					
		game.forces[force.name].technologies["artillery-shell-speed-1"].enabled = false	
		game.forces[force.name].technologies["atomic-bomb"].enabled = false			
		game.forces[force.name].set_ammo_damage_modifier("shotgun-shell", 1)
	end		
end

local function on_player_joined_game(event)
	init_surface()
	local surface = game.surfaces["biter_battles"]
	init_forces(surface)
	
	local player = game.players[event.player_index]		
	--player.character.destroy()
	
	if player.online_time == 0 then
		if surface.is_chunk_generated({0,0}) then
			player.teleport(surface.find_non_colliding_position("player", {0,0}, 3, 0.5), surface)
		else
			player.teleport({0,0}, surface)
		end
		player.character.destructible = false
	end
	
end

event.add(defines.events.on_player_joined_game, on_player_joined_game)

require "maps.biter_battles_v2.terrain"
require "maps.biter_battles_v2.mirror_terrain"
require "maps.biter_battles_v2.gui"
require "maps.biter_battles_v2.chat"
require "maps.biter_battles_v2.ai"
require "maps.biter_battles_v2.game_won"