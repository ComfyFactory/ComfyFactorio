
--[[
 Pirate Ship is maintained by thesixthroc and hosted by Comfy.
 Want to host it? Ask us at getcomfy.eu/discord!
 ]]

 --[[personal note for thesixthroc in XX years: my design notes are all in Obsidian (edit: partially moved to Github Projects)]]

--[[

== Tips for Developers! ==

The scenario is quite complex, but there are ways to get started, even if you don't know much Lua. Some ideas (incomplete):

• Go to pirates/surfaces/islands/first and edit stuff there to see the effect it has on the first island
• Ask thesixthroc for access to the ToDo list on Github Projects, to see what needs doing
]]

-- require 'modules.biters_yield_coins'
require 'modules.biter_noms_you'
require 'modules.no_deconstruction_of_neutral_entities'

require 'maps.pirates.custom_events' --probably do this before anything else

require 'utils.server'
local _inspect = require 'utils.inspect'.inspect
-- local Modifers = require 'player_modifiers'
local BottomFrame = require 'comfy_panel.bottom_frame'
local Autostash = require 'modules.autostash'
require 'modules.inserter_drops_pickup'


local TickFunctions = require 'maps.pirates.tick_functions'
local ClassTickFunctions = require 'maps.pirates.tick_functions_classes'

require 'maps.pirates.commands'
require 'maps.pirates.math'
local Memory = require 'maps.pirates.memory'
require 'maps.pirates.gui.gui'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
require 'maps.pirates.utils_local'
local Balance = require 'maps.pirates.balance'
local Crew = require 'maps.pirates.crew'
local Roles = require 'maps.pirates.roles.roles'
local Structures = require 'maps.pirates.structures.structures'
local Surfaces = require 'maps.pirates.surfaces.surfaces'
local Interface = require 'maps.pirates.interface'
require 'maps.pirates.structures.boats.boats'
local Progression = require 'maps.pirates.progression'
local Ai = require 'maps.pirates.ai'
require 'maps.pirates.ores'
require 'maps.pirates.quest'
require 'maps.pirates.parrot'
require 'maps.pirates.shop.shop'
require 'maps.pirates.boat_upgrades'
local Token = require 'utils.token'
local Task = require 'utils.task'

require 'utils.profiler'

local Public = {}

-- parrot sprites from https://elthen.itch.io/2d-pixel-art-parrot-sprites, licensed appropriately

local jetty_delayed = Token.register(
	-- function(data)
	function()
		Surfaces.Lobby.place_lobby_jetty_and_boats()
	end
)
local function on_init()
	Memory.global_reset_memory()
	local global_memory = Memory.get_global_memory()

	game.reset_time_played()

	-- local spectator = game.create_force('spectator')
	-- local spectator_permissions = game.permissions.create_group('spectator')
	-- spectator_permissions.set_allows_action(defines.input_action.start_walking,false)

    Autostash.insert_into_furnace(true)
    -- Autostash.insert_into_wagon(true)
    Autostash.bottom_button(true)
    BottomFrame.reset()
    BottomFrame.activate_custom_buttons(true)
    -- BottomFrame.bottom_right(true)

	local mgs = game.surfaces['nauvis'].map_gen_settings
	mgs.width = 16
	mgs.height = 16
	game.surfaces['nauvis'].map_gen_settings = mgs
	game.surfaces['nauvis'].clear()

	game.create_surface('piratedev1', Common.default_map_gen_settings(100, 100))
	game.surfaces['piratedev1'].clear()

	Common.init_game_settings(Balance.technology_price_multiplier)

	global_memory.active_crews_cap = Common.active_crews_cap
	global_memory.minimum_capacity_slider_value = Common.minimum_capacity_slider_value

	Surfaces.Lobby.create_starting_dock_surface()
	local lobby = game.surfaces[CoreData.lobby_surface_name]
	game.forces.player.set_spawn_position(Common.lobby_spawnpoint, lobby)
	game.forces.player.character_running_speed_modifier = Balance.base_extra_character_speed

	game.create_force('environment')
	for id = 1, 3, 1 do
		game.create_force(string.format('enemy-%03d', id))
		game.create_force(string.format('ancient-friendly-%03d', id))
		game.create_force(string.format('ancient-hostile-%03d', id))

		local crew_force = game.create_force(string.format('crew-%03d', id))

		Crew.reset_crew_and_enemy_force(id)
		crew_force.research_queue_enabled = true
	end

	-- Delay.global_add(Delay.global_enum.PLACE_LOBBY_JETTY_AND_BOATS)
	Task.set_timeout_in_ticks(2, jetty_delayed, {})

	if _DEBUG then
		game.print('Debug mode on. Use /go to get started (sometimes crashes)')
	end

end

local event = require 'utils.event'
event.on_init(on_init)





local function crew_tick()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local tick = game.tick

	TickFunctions.boat_movement_tick(5) --arguments are tick intervals
	-- TickFunctions.parrot_tick(5)

	if tick % 10 == 0 then
		TickFunctions.prevent_disembark(10)
		TickFunctions.prevent_unbarreling_off_ship(10)
	end

	if memory.age and memory.overworldx and memory.overworldx > 0 then
		memory.age = memory.age + 5
	end
	if memory.real_age then
		memory.real_age = memory.real_age + 5
	end
	if tick % 60 == 0 then
		TickFunctions.captain_warn_afk(60)
	end

	if tick % Common.loading_interval == 0 then
		TickFunctions.loading_update(Common.loading_interval)
	end

	if tick % 5 == 0 then
		TickFunctions.quest_progress_tick(5)
	end

	if tick % 5 == 0 then
		TickFunctions.strobe_player_colors(5)
	end

	if tick % 10 == 0 then
		TickFunctions.shop_ratelimit_tick(10)
	end

	if tick % 30 == 0 then
		TickFunctions.silo_update(30)
	end

	if tick % 60 == 0 then
		TickFunctions.ship_deplete_fuel(60)
	end

	if tick % 10 == 0 then
		TickFunctions.pick_up_tick(10)
	end

	if tick % 60 == 0 then
		if memory.boat and memory.boat.state == Structures.Boats.enum_state.ATSEA_SAILING then
			TickFunctions.crowsnest_natural_move(120)
		end
	end

	if tick % 60 == 15 or tick % 60 == 45 then
		if memory.boat and memory.boat.state == Structures.Boats.enum_state.ATSEA_SAILING then
			TickFunctions.overworld_check_collisions(120)
		end
	end

	if tick % 60 == 30 then
		if memory.boat and memory.boat.state == Structures.Boats.enum_state.ATSEA_SAILING then
			TickFunctions.crowsnest_steer(120)
		end
	end

	if tick % 60 == 0 then
		TickFunctions.slower_boat_tick(60)
	end

	if tick % 10 == 0 then
		TickFunctions.update_boat_stored_resources(10)
	end

	if tick % 10 == 0 then
		TickFunctions.covered_requirement_check(10)
	end

	if tick % 30 == 0 then
		TickFunctions.buried_treasure_check(30)
	end

	if tick % 60 == 0 then
		TickFunctions.raft_raids(60)
	end

	if tick % 60 == 0 then
		TickFunctions.place_cached_structures(60)
	end

	if tick % 240 == 0 then
		TickFunctions.check_all_spawners_dead(240)
	end

	if tick % 60 == 0 then

		if destination.dynamic_data.timer then
			destination.dynamic_data.timer = destination.dynamic_data.timer + 1
		end

		if memory.captain_acceptance_timer then
			memory.captain_acceptance_timer = memory.captain_acceptance_timer - 1
			if memory.captain_acceptance_timer == 0 then
				Roles.assign_captain_based_on_priorities()
			end
		end

		if memory.captain_accrued_time_data and memory.playerindex_captain and memory.overworldx and memory.overworldx > 0 and memory.overworldx < CoreData.victory_x then --only count time in the 'main game'
			local player = game.players[memory.playerindex_captain]
			if player and player.name then
				if (not memory.captain_accrued_time_data[player.name]) then memory.captain_accrued_time_data[player.name] = 0 end
				memory.captain_accrued_time_data[player.name] = memory.captain_accrued_time_data[player.name] + 1
			end
		end

		if destination.dynamic_data.time_remaining and destination.dynamic_data.time_remaining > 0 then
			destination.dynamic_data.time_remaining = destination.dynamic_data.time_remaining - 1

			if destination.dynamic_data.time_remaining == 0 then
				if memory.boat and memory.boat.surface_name then
					local surface_name_decoded = Surfaces.SurfacesCommon.decode_surface_name(memory.boat.surface_name)
					local type = surface_name_decoded.type
					if type == Surfaces.enum.ISLAND then
						Progression.retreat_from_island(false)
					elseif type == Surfaces.enum.DOCK then
						Progression.undock_from_dock(false)
					end
				end
			end
		end
	end

	if tick % 240 == 0 then
		if memory.max_players_recorded then
			local count_now = #Common.crew_get_crew_members()
			if count_now and count_now > memory.max_players_recorded then
				memory.max_players_recorded = count_now
			end
		end
	end

	if tick % 240 == 0 then
		TickFunctions.Kraken_Destroyed_Backup_check(240)
	end

	if tick % 300 == 0 then
		TickFunctions.periodic_free_resources(300)
	end

	if tick % 30 == 0 then
		ClassTickFunctions.update_character_properties(30)
	end

	if tick % 30 == 0 then
		ClassTickFunctions.class_renderings(30)
	end

	if tick % 120 == 0 then
		Ai.Tick_actions(120)
	end

	if tick % 240 == 0 then
		TickFunctions.LOS_tick(240)
	end

	if tick % 420 == 0 then
		ClassTickFunctions.class_rewards_tick(420)
	end

	if tick % 300 == 0 then
		TickFunctions.update_recentcrewmember_list(300)
	end

	if tick % 1800 == 0 then
		TickFunctions.transfer_pollution(1800)
	end

	if tick % 3600 == 0 then
		TickFunctions.prune_offline_characters_list(3600)
	end

	-- if tick % (60*60*60) == 0 then
	-- 	Parrot.parrot_say_tip()
	-- end

	if memory.crew_disband_tick then
		if memory.crew_disband_tick < tick then
			memory.crew_disband_tick = nil
			Crew.disband_crew()
		end
		return
	end
end


local function global_tick()
	local global_memory = Memory.get_global_memory()
	local tick = game.tick

	if tick % 60 == 0 then
		TickFunctions.update_players_second()
	end

	if tick % 30 == 0 then
		for _, player in pairs(game.connected_players) do
			-- figure out which crew this is about:
			local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or 0
			Memory.set_working_id(crew_id)
			Roles.update_tags(player)
		end
	end

	for _, id in pairs(global_memory.crew_active_ids) do
		Memory.set_working_id(id)

		crew_tick()
	end

	TickFunctions.update_player_guis(5)
end

event.on_nth_tick(5, global_tick)


local function instatick()
	local global_memory = Memory.get_global_memory()
	for _, id in pairs(global_memory.crew_active_ids) do
		Memory.set_working_id(id)
		TickFunctions.minimap_jam(1)
		TickFunctions.silo_insta_update()
	end
end

event.on_nth_tick(1, instatick)



----- FOR BUGFIXING HARD CRASHES (segfaults) ------
-- often, segfaults are due to an error during chunk generation (as of 1.1.0 or so, anyway.)
-- to help debug, comment this out, and instead use the command /chnk to generate some chunks manually
event.add(defines.events.on_chunk_generated, Interface.event_on_chunk_generated)

----- FOR DESYNC BUGFIXING -----
local gMeta = getmetatable(_ENV)
if not gMeta then
    gMeta = {}
    setmetatable(_ENV, gMeta)
end

gMeta.__newindex = function(_, n, v)
    log('Desync warning: attempt to write to undeclared var ' .. n)
    global[n] = v
end
gMeta.__index = function(_, n)
    return global[n]
end

return Public