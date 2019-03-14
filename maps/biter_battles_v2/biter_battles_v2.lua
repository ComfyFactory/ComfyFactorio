-- Biter Battles v2 -- by MewMew

local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random

local function init_surface()
	if game.surfaces["biter_battles"] then return end
	local map_gen_settings = {}
	map_gen_settings.water = "0.5"
	map_gen_settings.starting_area = "5"	
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 12, cliff_elevation_0 = 32}		
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "4", size = "1", richness = "1"},
		["stone"] = {frequency = "4", size = "1", richness = "1"},
		["copper-ore"] = {frequency = "4", size = "1", richness = "1"},
		["iron-ore"] = {frequency = "4", size = "1", richness = "1"},
		["uranium-ore"] = {frequency = "2", size = "1", richness = "1"},
		["crude-oil"] = {frequency = "3", size = "1", richness = "1"},
		["trees"] = {frequency = "2", size = "1", richness = "1"},
		["enemy-base"] = {frequency = "2", size = "4", richness = "1"}	
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
	game.create_force("north_biters")
	game.create_force("south")
	game.create_force("south_biters")	
	game.create_force("spectator")
	
	local f = game.forces["north"]
	f.set_spawn_position({0, -32}, surface)
	f.set_cease_fire("player", true)
	f.set_friend("spectator", true)
	f.share_chart = true
	
	local f = game.forces["north_biters"]
	f.set_friend("south_biters", true)
	f.set_cease_fire("player", true)
	f.set_cease_fire("spectator", true)
	f.set_cease_fire("south", true)
	
	local f = game.forces["south"]
	f.set_spawn_position({0, 32}, surface)
	f.set_cease_fire("player", true)
	f.set_friend("spectator", true)
	f.share_chart = true
	
	local f = game.forces["south_biters"]
	f.set_friend("north_biters", true)
	f.set_cease_fire("player", true)
	f.set_cease_fire("spectator", true)
	f.set_cease_fire("north", true)
	
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

	global.game_lobby_active = true
end

local function on_player_joined_game(event)
	init_surface()
	local surface = game.surfaces["biter_battles"]
	init_forces(surface)
	
	local player = game.players[event.player_index]	
	
	if player.gui.left["map_pregen"] then player.gui.left["map_pregen"].destroy() end
	
	if player.online_time == 0 then
		if surface.is_chunk_generated({0,0}) then
			player.teleport(surface.find_non_colliding_position("player", {0,0}, 3, 0.5), surface)
		else
			player.teleport({0,0}, surface)
		end
		player.character.destructible = false
	end
	
	--player.character.destroy()
end

event.add(defines.events.on_player_joined_game, on_player_joined_game)

require "maps.biter_battles_v2.terrain"
require "maps.biter_battles_v2.mirror_terrain"
require "maps.biter_battles_v2.chat"
require "maps.biter_battles_v2.game_won"
require "maps.biter_battles_v2.on_tick"
require "maps.biter_battles_v2.pregenerate_chunks"