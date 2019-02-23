server_commands = require 'utils.server'
require "utils.server_commands"
require "utils.utils"
require "utils.corpse_util"
require "chatbot"
require "commands"
require "session_tracker"
require "antigrief"
require "antigrief_admin_panel"
require "group"
require "player_list"
require "poll"
require "score"

---- enable modules here ----
--require "maps.tools.cheat_mode"
--require "maps.modules.hunger"
--require "maps.modules.fish_respawner"
--require "maps.modules.rocket_launch_always_yields_science"
--require "maps.modules.launch_fish_to_win"
--require "maps.modules.satellite_score"
--require "maps.modules.restrictive_fluid_mining"
--require "maps.modules.fluids_are_explosive"
--require "maps.modules.explosives_are_explosive"
--require "maps.modules.explosive_biters"
--require "maps.modules.railgun_enhancer"
--require "maps.modules.dynamic_landfill"
--require "maps.modules.players_trample_paths"
--require "maps.modules.hunger_games"
--require "maps.modules.burden"
-----------------------------

---- enable maps here ----
--require "maps.biter_battles"
--require "maps.cave_miner"
--require "maps.labyrinth"
--require "maps.spooky_forest"
--require "maps.nightfall"
--require "maps.atoll"
--require "maps.tank_battles"
--require "maps.spiral_troopers"
--require "maps.fish_defender"
--require "maps.mountain_fortress"
--require "maps.stoneblock"
require "maps.deep_jungle"
--require "maps.crossing"
--require "maps.anarchy"
--require "maps.railworld"
--require "maps.spaghettorio"
--require "maps.lost_desert"
--require "maps.empty_map"
--require "maps.custom_start"
-----------------------------

local event = require 'utils.event'

local function on_player_created(event)	
	local player = game.players[event.player_index]	
	player.gui.top.style = 'slot_table_spacing_horizontal_flow'
	player.gui.left.style = 'slot_table_spacing_vertical_flow'
end

event.add(defines.events.on_player_created, on_player_created)
