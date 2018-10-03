require "utils.utils"
require "utils.corpse_util"
require "bot"
require "session_tracker"
require "antigrief"
require "group"
require "player_list"
require "poll"
require "score"

--require "maps.tools.cheat_mode"

---- enable maps here ----
--require "maps.biter_battles"
--require "maps.cave_miner"
--require "maps.deep_jungle"
--require "maps.lost_desert"
require "maps.labyrinth"
--require "maps.spaghettorio"
-----------------------------

local Event = require 'utils.event'

local function player_created(event)	
	local player = game.players[event.player_index]	
	player.gui.top.style = 'slot_table_spacing_horizontal_flow'
	player.gui.left.style = 'slot_table_spacing_vertical_flow'
	
	player.print("Join the comfy discord >> comfyplay.net/discord", {r = 110, g = 0, b = 220})
end

function spaghetti()
	game.forces["player"].technologies["logistic-system"].enabled = false
	game.forces["player"].technologies["construction-robotics"].enabled = false
	game.forces["player"].technologies["logistic-robotics"].enabled = false
	game.forces["player"].technologies["robotics"].enabled = false
	game.forces["player"].technologies["personal-roboport-equipment"].enabled = false
	game.forces["player"].technologies["personal-roboport-equipment-2"].enabled = false
	game.forces["player"].technologies["character-logistic-trash-slots-1"].enabled = false
	game.forces["player"].technologies["character-logistic-trash-slots-2"].enabled = false
	game.forces["player"].technologies["auto-character-logistic-trash-slots"].enabled = false
	game.forces["player"].technologies["worker-robots-storage-1"].enabled = false
	game.forces["player"].technologies["worker-robots-storage-2"].enabled = false
	game.forces["player"].technologies["worker-robots-storage-3"].enabled = false	
	game.forces["player"].technologies["character-logistic-slots-1"].enabled = false
	game.forces["player"].technologies["character-logistic-slots-2"].enabled = false
	game.forces["player"].technologies["character-logistic-slots-3"].enabled = false
	game.forces["player"].technologies["character-logistic-slots-4"].enabled = false
	game.forces["player"].technologies["character-logistic-slots-5"].enabled = false
	game.forces["player"].technologies["character-logistic-slots-6"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-1"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-2"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-3"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-4"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-5"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-6"].enabled = false
end

Event.add(defines.events.on_player_created, player_created)