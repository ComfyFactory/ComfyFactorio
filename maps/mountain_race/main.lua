--local Collapse = require "modules.collapse"
local Terrain = require 'maps.mountain_race.terrain'
local Global = require 'utils.global'

local mountain_race = {}
Global.register(
    mountain_race,
    function(tbl)
        mountain_race = tbl
    end
)

local function on_chunk_generated(event)
	local surface = event.surface
	if surface.index ~= 1 then return end
	local left_top = event.area.left_top
	if left_top.y >= mountain_race.playfield_height or left_top.y < mountain_race.playfield_height * -1 or left_top.x < -64 then
		Terrain.draw_out_of_map_chunk(surface, left_top)
		return
	end
end

local function on_entity_damaged(event)
end

local function on_entity_died(event)
end

local function on_player_joined_game(event)
end

local function init(mountain_race)
end

local function game_in_progress(mountain_race)
	local tick = game.tick
	if tick % 120 == 0 then
		Terrain.clone_south_to_north(mountain_race)
	end
end

local gamestates = {
	["init"] = init,
	["game_in_progress"] = game_in_progress,	
}

local function on_tick()
	--Terrain.mirror_queue(mountain_race)
	gamestates[mountain_race.gamestate](mountain_race)	
end

local function on_init()
	mountain_race.gamestate = "game_in_progress"
	mountain_race.border_width = 4
	mountain_race.border_half_width = mountain_race.border_width * 0.5
	mountain_race.playfield_height = 128
	mountain_race.clone_x = -3
end


local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)