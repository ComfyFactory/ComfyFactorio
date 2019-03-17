local event = require 'utils.event'

local gui = require "maps.biter_battles_v2.gui"
local ai = require "maps.biter_battles_v2.ai"
local chunk_pregen = require "maps.biter_battles_v2.pregenerate_chunks"
local mirror_map = require "maps.biter_battles_v2.mirror_terrain"

local function reveal_team(f)
	local m = 32
	if f == "north" then
		game.forces["south"].chart(
			game.surfaces["biter_battles"],
			{{x = global.force_area[f].x_top - m, y = global.force_area[f].y_top - m}, {x = global.force_area[f].x_bot + m, y = global.force_area[f].y_bot + m}}
		)
	else
		game.forces["north"].chart(
			game.surfaces["biter_battles"],
			{{x = global.force_area[f].x_top - m, y = global.force_area[f].y_top - m}, {x = global.force_area[f].x_bot + m, y = global.force_area[f].y_bot + m}}
		)
	end	
end

local function on_tick(event)
	if game.tick % 30 ~= 15 then return end
	chunk_pregen()
	mirror_map()
	
	if game.tick % 60 ~= 15 then return end
	global.bb_threat["north_biters"] = global.bb_threat["north_biters"] + global.bb_threat_income["north_biters"]
	global.bb_threat["south_biters"] = global.bb_threat["south_biters"] + global.bb_threat_income["south_biters"]		
	gui()
	
	if game.tick % 300 ~= 15 then return end	
	if global.spy_fish_timeout["south"] - game.tick > 0 then
		reveal_team("north")
	else
		global.spy_fish_timeout["south"] = 0
	end
	if global.spy_fish_timeout["north"] - game.tick > 0 then
		reveal_team("south")
	else
		global.spy_fish_timeout["north"] = 0
	end
	
	if game.tick % 3600 ~= 15 then return end
	if global.bb_game_won_by_team then return end	
	ai.main_attack()
	ai.send_near_biters_to_silo()		
end

event.add(defines.events.on_tick, on_tick)
