local Event = require 'utils.event'
local Terrain = require 'maps.cave_miner_v2.terrain'
local Functions = require 'maps.cave_miner_v2.functions'
local Global = require 'utils.global'
local Server = require 'utils.server'

local math_floor = math.floor

local cave_miner = {}
Global.register(
    cave_miner,
    function(tbl)
        cave_miner = tbl
    end
)

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	local tick = game.ticks_played
	if tick == 0 then
		if player.character and player.character.valid then
			player.character.destroy()
		end
	end	
end

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	if not player.character then return end
	if not player.character.valid then return end
	Terrain.reveal(game.surfaces.nauvis, game.surfaces.cave_miner_source, {x = math_floor(player.position.x), y = math_floor(player.position.y)}, 8)
end

local function on_chunk_generated(event)
	local surface = event.surface
	if surface.index == 1 then
		Terrain.out_of_map(event)
		return
	end
	if surface.name == "cave_miner_source" then
		Terrain.generate_cave(event)
		return
	end
end

local function init(cave_miner)
	local tick = game.ticks_played
	if tick % 60 ~= 0 then return end
	Terrain.roll_source_surface()
	
	game.forces.player.manual_mining_speed_modifier = cave_miner.mining_speed_bonus
	
	cave_miner.gamestate = "spawn_players"
end

local function spawn_players(cave_miner)
	local tick = game.ticks_played
	if tick % 60 ~= 0 then return end
	Terrain.reveal(game.surfaces.nauvis, game.surfaces.cave_miner_source, {x = 0, y = 0}, 8)
	for _, player in pairs(game.connected_players) do
		Functions.spawn_player(player)
	end
	cave_miner.gamestate = "game_in_progress"
end

local function game_in_progress(cave_miner)
	local tick = game.ticks_played
	if tick % 60 ~= 0 then return end
end

local gamestates = {
	["init"] = init,
	["spawn_players"] = spawn_players,
	["game_in_progress"] = game_in_progress,
}

local function on_tick()
	gamestates[cave_miner.gamestate](cave_miner)	
end

local function on_init()
	cave_miner.reset_counter = 0
	cave_miner.gamestate = "init"
	cave_miner.mining_speed_bonus = 100
end

Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)