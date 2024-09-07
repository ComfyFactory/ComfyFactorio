-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.

--[[
 Pirate Ship is maintained by thesixthroc and hosted by Comfy.
 Want to host it? Ask us at getcomfy.eu/discord!
 ]]
--[[

== Tips for Developers! ==

The scenario is quite complex, but there are ways to get started, even if you don't know much Lua. Some ideas (incomplete):

• Go to pirates/surfaces/islands/first and edit stuff there to see the effect it has on the first island
• Ask thesixthroc for access to the ToDo list on Github Projects, to see what needs doing
• Make sure to use debug=true in control.lua
]]

--[[
	Convention for Factorio blueprints in this folder: Use Snap to grid -> Relative, Offset of zeroes.
	We record tiles and entities separately. For tiles, we use the factorio dev approved 'concrete trick', painting each tile type separately as concrete. The concrete BP will typically need an offset, since it doesn't remember the center of the entities BP — we configure this offset in the Lua rather than the BP itself, since it's easier to edit that way.
]]


-- require 'modules.biters_yield_coins'
require 'modules.biter_noms_you'
require 'modules.no_deconstruction_of_neutral_entities'
require 'maps.pirates.custom_events' --probably do this before anything else
require 'utils.server'
local _inspect = require 'utils.inspect'.inspect
-- local Modifers = require 'player_modifiers'
local BottomFrame = require 'utils.gui.bottom_frame'
local Autostash = require 'modules.autostash'
local Misc = require 'utils.commands.misc'
local AntiGrief = require 'utils.antigrief'
require 'modules.inserter_drops_pickup'
local PiratesApiOnTick = require 'maps.pirates.api_on_tick'
local ClassPiratesApiOnTick = require 'maps.pirates.roles.tick_functions'
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
local Kraken = require 'maps.pirates.surfaces.sea.kraken'
local PiratesApiEvents = require 'maps.pirates.api_events'
require 'maps.pirates.structures.boats.boats'
-- local Progression = require 'maps.pirates.progression'
local QuestStructures = require 'maps.pirates.structures.quest_structures.quest_structures'
local Ai = require 'maps.pirates.ai'
require 'maps.pirates.ores'
require 'maps.pirates.quest'
require 'maps.pirates.parrot'
require 'maps.pirates.shop.shop'
require 'maps.pirates.boat_upgrades'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Server = require 'utils.server'

local Math = require 'maps.pirates.math'

-- require 'utils.profiler'

local Public = {}

-- parrot sprites from https://elthen.itch.io/2d-pixel-art-parrot-sprites

local jetty_delayed = Token.register(
-- function(data)
	function ()
		Surfaces.Lobby.place_lobby_jetty_and_boats()
	end
)

local function on_init()
	Memory.global_reset_memory()
	local global_memory = Memory.get_global_memory()

	AntiGrief.enable_capsule_cursor_warning(false)

	game.reset_time_played()

	-- local spectator = game.create_force('spectator')
	-- local spectator_permissions = game.permissions.create_group('spectator')
	-- spectator_permissions.set_allows_action(defines.input_action.start_walking,false)

	Autostash.insert_into_furnace(true)
	-- Autostash.insert_into_wagon(true)
	Autostash.bottom_button(true)
    Misc.bottom_button(true)
	BottomFrame.reset()
	BottomFrame.activate_custom_buttons(true)
	-- BottomFrame.bottom_right(true)

	local mgs = game.surfaces['nauvis'].map_gen_settings
	mgs.width = 16
	mgs.height = 16
	game.surfaces['nauvis'].map_gen_settings = mgs
	game.surfaces['nauvis'].clear()

	game.create_surface('piratedev1', Common.default_map_gen_settings(100, 100)) --Create a surface used during the entity movement process
	game.surfaces['piratedev1'].clear()

	Common.init_game_settings(Balance.technology_price_multiplier)

	global_memory.active_crews_cap = Common.activeCrewsCap
	global_memory.protected_run_cap = Common.protected_run_cap
	global_memory.private_run_cap = Common.private_run_cap

	global_memory.minimumCapacitySliderValue = Common.minimumCapacitySliderValue

	Surfaces.Lobby.create_starting_dock_surface()
	local lobby = game.surfaces[CoreData.lobby_surface_name]
	game.forces.player.set_spawn_position(Common.lobby_spawnpoint, lobby)
	-- game.forces.player.character_running_speed_modifier = Balance.base_extra_character_speed

	game.create_force('environment')
	for id = 1, 5, 1 do
		game.create_force(Common.get_enemy_force_name(id))
		game.create_force(Common.get_ancient_friendly_force_name(id))
		game.create_force(Common.get_ancient_hostile_force_name(id))

		game.create_force(Common.get_crew_force_name(id))

		Crew.reset_crew_and_enemy_force(id)
	end

	-- Delay.global_add(Delay.global_enum.PLACE_LOBBY_JETTY_AND_BOATS)
	Task.set_timeout_in_ticks(2, jetty_delayed, {})
end

local event = require 'utils.event'
event.on_init(on_init)





local function crew_tick()
	local memory = Memory.get_crew_memory()
	local destination = Common.current_destination()
	local tick = game.tick

	if memory.age and memory.overworldx and memory.overworldx > 0 then
		memory.age = memory.age + 5
	end
	if memory.real_age then
		memory.real_age = memory.real_age + 5
	end

	PiratesApiOnTick.boat_movement_tick(5) --arguments are tick intervals
	-- PiratesApiOnTick.parrot_tick(5)

	PiratesApiOnTick.quest_progress_tick(5)
	PiratesApiOnTick.strobe_player_colors(5)

	if tick % 10 == 0 then
		PiratesApiOnTick.prevent_disembark(10)
		PiratesApiOnTick.prevent_unbarreling_off_ship(10)
		-- PiratesApiOnTick.shop_ratelimit_tick(10)
		PiratesApiOnTick.pick_up_tick(10)
		QuestStructures.tick_quest_structure_entry_price_check()
		PiratesApiOnTick.update_boat_stored_resources(10)

		if tick % 30 == 0 then
			PiratesApiOnTick.silo_update(30)
			PiratesApiOnTick.buried_treasure_check(30)
			ClassPiratesApiOnTick.update_character_properties(30)
			ClassPiratesApiOnTick.class_update_auxiliary_data(30)
			ClassPiratesApiOnTick.class_renderings(30)

			if tick % 60 == 0 then
				PiratesApiOnTick.captain_warn_afk(60)
				PiratesApiOnTick.ship_deplete_fuel(60)
				PiratesApiOnTick.crowsnest_natural_move(60)
				PiratesApiOnTick.slower_boat_tick(60)
				PiratesApiOnTick.raft_raids(60)
				PiratesApiOnTick.place_cached_structures(60)
				PiratesApiOnTick.update_alert_sound_frequency_tracker()
				PiratesApiOnTick.check_for_cliff_explosives_in_hold_wooden_chests()
				PiratesApiOnTick.equalise_fluid_storages() -- Made the update less often for small performance gain, but frequency can be increased if players complain
				PiratesApiOnTick.revealed_buried_treasure_distance_check()
				PiratesApiOnTick.victory_continue_reminder()
				Kraken.overall_kraken_tick()

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

				PiratesApiOnTick.update_time_remaining()

				if destination.dynamic_data.disabled_wave_timer then
					destination.dynamic_data.disabled_wave_timer = Math.max(0, destination.dynamic_data.disabled_wave_timer - 1)
				end

				if tick % 120 == 0 then
					Ai.Tick_actions(120)

					if tick % 240 == 0 then
						-- PiratesApiOnTick.check_all_spawners_dead(240) -- incentivises killing all spawners too much
						if memory.max_players_recorded then
							local count_now = #Common.crew_get_crew_members()
							if count_now and count_now > memory.max_players_recorded then
								memory.max_players_recorded = count_now
							end
						end
						PiratesApiOnTick.Kraken_Destroyed_Backup_check(240)
						PiratesApiOnTick.LOS_tick(240)
					end
				end


				if tick % (60 * Balance.class_reward_tick_rate_in_seconds) == 0 then
					ClassPiratesApiOnTick.class_rewards_tick(60 * Balance.class_reward_tick_rate_in_seconds)
				end

				if tick % 300 == 0 then
					PiratesApiOnTick.periodic_free_resources(300)
					PiratesApiOnTick.update_pet_biter_lifetime(300)

					if tick % 1800 == 0 then
						PiratesApiOnTick.transfer_pollution(1800)

						if tick % 3600 == 0 then
							PiratesApiOnTick.prune_offline_characters_list(3600)
							PiratesApiOnTick.update_protected_run_lock_timer(3600)
							PiratesApiOnTick.update_private_run_lock_timer(3600)
						end
					end
				end
			end
		end
	end

	if tick % 60 == 15 or tick % 60 == 45 then
		-- @TODO move this ugly check to function?
		if memory.boat and memory.boat.state == Structures.Boats.enum_state.ATSEA_SAILING then
			PiratesApiOnTick.overworld_check_collisions(120)
		end
	end

	if tick % 60 == 30 then
		PiratesApiOnTick.crowsnest_steer(120)
	end

	if tick % Common.loading_interval == 0 then
		PiratesApiOnTick.loading_update(Common.loading_interval)
	end

	if memory.crew_disband_tick_message then
		if memory.crew_disband_tick_message < tick then
			memory.crew_disband_tick_message = nil

			local message1 = { 'pirates.crew_disband_tick_message' }

			Common.notify_force(memory.force, message1)

			Server.to_discord_embed_raw({ '', '[' .. memory.name .. '] ', message1 }, true)
		end
	end

	if memory.crew_disband_tick then
		if memory.crew_disband_tick < tick then
			memory.crew_disband_tick = nil
			Crew.disband_crew()
		end
	end
end


local function global_tick()
	local global_memory = Memory.get_global_memory()
	local tick = game.tick

	if tick % 60 == 0 then
		PiratesApiOnTick.update_players_second()
	end

	if tick % 30 == 0 then
		for _, player in pairs(game.connected_players) do
			local crew_id = Common.get_id_from_force_name(player.force.name)
			Memory.set_working_id(crew_id)
			Roles.update_tags(player)
		end
	end

	for _, id in pairs(global_memory.crew_active_ids) do
		Memory.set_working_id(id)

		crew_tick()
	end

	PiratesApiOnTick.update_player_guis(5)
end

event.on_nth_tick(5, global_tick)


local function instatick()
	local global_memory = Memory.get_global_memory()
	for _, id in pairs(global_memory.crew_active_ids) do
		Memory.set_working_id(id)
		PiratesApiOnTick.minimap_jam(1)
		PiratesApiOnTick.silo_insta_update()
	end
end

event.on_nth_tick(1, instatick)



----- FOR BUGFIXING HARD CRASHES (segfaults) ------
-- often, segfaults are due to an error during chunk generation (as of 1.1.0 or so, anyway.)
-- to help debug, comment this out, and instead use the command /chnk to generate some chunks manually
event.add(defines.events.on_chunk_generated, PiratesApiEvents.event_on_chunk_generated)

----- FOR DESYNC BUGFIXING -----
local gMeta = getmetatable(_ENV)
if not gMeta then
	gMeta = {}
	setmetatable(_ENV, gMeta)
end

gMeta.__newindex = function (_, n, v)
	log('Desync warning: attempt to write to undeclared var ' .. n)
	global[n] = v
end
gMeta.__index = function (_, n)
	return global[n]
end

return Public
