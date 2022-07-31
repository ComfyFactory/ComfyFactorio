-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Balance = require 'maps.pirates.balance'
local _inspect = require 'utils.inspect'.inspect
local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Common = require 'maps.pirates.common'
-- local Parrot = require 'maps.pirates.parrot'
local CoreData = require 'maps.pirates.coredata'
local Server = require 'utils.server'
local Utils = require 'maps.pirates.utils_local'
local Surfaces = require 'maps.pirates.surfaces.surfaces'
-- local Structures = require 'maps.pirates.structures.structures'
local Boats = require 'maps.pirates.structures.boats.boats'
local Crowsnest = require 'maps.pirates.surfaces.crowsnest'
local Hold = require 'maps.pirates.surfaces.hold'
local Lobby = require 'maps.pirates.surfaces.lobby'
local Cabin = require 'maps.pirates.surfaces.cabin'
local Roles = require 'maps.pirates.roles.roles'
local Classes = require 'maps.pirates.roles.classes'
local Token = require 'utils.token'
local Task = require 'utils.task'
local SurfacesCommon = require 'maps.pirates.surfaces.common'

local Public = {}
local enum = {
		ADVENTURING = 'adventuring',
		LEAVING_INITIAL_DOCK = 'leavinginitialdock'
}
Public.enum = enum


function Public.difficulty_vote(player_index, difficulty_id)
	local memory = Memory.get_crew_memory()


	if not (memory.difficulty_votes) then memory.difficulty_votes = {} end
	local player = game.players[player_index]
	if not (player and player.valid) then return end


	if memory.difficulty_votes[player_index] and memory.difficulty_votes[player_index] == difficulty_id then
		return nil
	else
		local option = CoreData.difficulty_options[difficulty_id]
		if not option then return end

		local color = option.associated_color
		Common.notify_force(memory.force, {'pirates.notify_difficulty_vote',player.name, color.r, color.g, color.b, option.text})

		memory.difficulty_votes[player_index] = difficulty_id

		Public.update_difficulty()
	end
end


function Public.update_difficulty()
	local memory = Memory.get_crew_memory()

	local vote_counts = {}
	for _, difficulty_id in pairs(memory.difficulty_votes) do
		if not vote_counts[difficulty_id] then
			vote_counts[difficulty_id] = 1
		else
			vote_counts[difficulty_id] = vote_counts[difficulty_id] + 1
		end
	end

	local modal_id = 1
	local modal_count = 0
	for difficulty_id, votes in pairs(vote_counts) do
		if votes > modal_count or (votes == modal_count and difficulty_id < modal_id) then
			modal_count = votes
			modal_id = difficulty_id
		end
	end

	if modal_id ~= memory.difficulty_option then
		local color = CoreData.difficulty_options[modal_id].associated_color

		local message1 = {'pirates.notify_difficulty_change', color.r, color.g, color.b, CoreData.difficulty_options[modal_id].text}

		Common.notify_force(memory.force, message1)

		-- local message2 = 'Difficulty changed to ' .. CoreData.difficulty_options[modal_id].text .. '.'
		Server.to_discord_embed_raw({'', CoreData.comfy_emojis.kewl .. '[' .. memory.name .. '] ', message1}, true)

		memory.difficulty_option = modal_id
		memory.difficulty = CoreData.difficulty_options[modal_id].value
	end
end


function Public.try_add_extra_time_at_sea(ticks)
	local memory = Memory.get_crew_memory()

	if not memory.extra_time_at_sea then memory.extra_time_at_sea = 0 end

	if memory.extra_time_at_sea >= CoreData.max_extra_seconds_at_sea * 60 then return false end

	-- if memory.boat and memory.boat.state and memory.boat.state == Boats.enum_state.ATSEA_LOADING_MAP then return false end

	memory.extra_time_at_sea = memory.extra_time_at_sea + ticks
	return true
end

function Public.get_crewmembers_printable_string()
	local crewmembers_string = ''
	for _, player in pairs(Common.crew_get_crew_members()) do
		if player.valid then
			if crewmembers_string ~= '' then crewmembers_string = crewmembers_string .. ', ' end
			crewmembers_string = crewmembers_string .. player.name
		end
	end
	if crewmembers_string ~= '' then crewmembers_string = crewmembers_string .. '.' end

	return crewmembers_string
end

function Public.try_lose(loss_reason)
	local memory = Memory.get_crew_memory()

	if (not memory.game_lost) then
	-- if (not memory.game_lost) and (not memory.game_won) then
		memory.game_lost = true
		memory.crew_disband_tick_message = game.tick + 60*10
		memory.crew_disband_tick = game.tick + 60*40

		local playtimetext = Utils.time_longform((memory.age or 0)/60)

		local message = {'',loss_reason,' ',{'pirates.loss_rest_of_message_long', playtimetext, Public.get_crewmembers_printable_string()}}

		Server.to_discord_embed_raw({'',CoreData.comfy_emojis.trashbin .. '[' .. memory.name .. '] ', message}, true)

		local message2 = {'',loss_reason,' ',{'pirates.loss_rest_of_message_short', '[font=default-large-semibold]' .. playtimetext .. '[/font]'}}

		Common.notify_game({'', '[' .. memory.name .. '] ',message2}, CoreData.colors.notify_gameover)

		local force = memory.force
		if not (force and force.valid) then return end

		force.play_sound{path='utility/game_lost', volume_modifier=0.75} --playing to the whole game might scare ppl
	end
end

function Public.try_win()
	local memory = Memory.get_crew_memory()

	if (not (memory.game_lost or memory.game_won)) then
	-- if (not memory.game_lost) and (not memory.game_won) then
		memory.completion_time = Math.floor((memory.age or 0)/60)

		local speedrun_time = (memory.age or 0)/60
		local speedrun_time_str = Utils.time_longform(speedrun_time)
		memory.game_won = true
		-- memory.crew_disband_tick = game.tick + 1200

		Server.to_discord_embed_raw({'', CoreData.comfy_emojis.goldenobese .. '[' .. memory.name .. '] Victory, on v' .. CoreData.version_string .. ', ', CoreData.difficulty_options[memory.difficulty_option].text, ', capacity ' .. CoreData.capacity_options[memory.capacity_option].text3 .. '. Playtime: ' .. speedrun_time_str .. ' since 1st island. Crewmembers: ' .. Public.get_crewmembers_printable_string()}, true)

		Common.notify_game({'','[' .. memory.name .. '] ',{'pirates.victory',CoreData.version_string, CoreData.difficulty_options[memory.difficulty_option].text, CoreData.capacity_options[memory.capacity_option].text3, speedrun_time_str, Public.get_crewmembers_printable_string()}}, CoreData.colors.notify_victory)

		game.play_sound{path='utility/game_won', volume_modifier=0.9}

		memory.boat.state = Boats.enum_state.ATSEA_WAITING_TO_SAIL
		memory.victory_continue_reminder = game.tick + 60*14
		memory.victory_continue_message = true
	end
end


function Public.choose_crew_members()
	-- local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()
	local capacity = memory.capacity
	local boat = memory.boat

	-- if the boat is over capacity, should prefer original endorsers over everyone else:
	local crew_members = {}
	local crew_members_count = 0
	for _, player in pairs(game.connected_players) do
		if crew_members_count < capacity and player.surface.name == CoreData.lobby_surface_name and Boats.on_boat(boat, player.position) then
			-- check if they were an endorser
			local endorser = false
			for _, index in pairs(memory.original_proposal.endorserindices) do
				if player.index == index then endorser = true end
			end
			if endorser then
				crew_members[player.index] = player
				crew_members_count = crew_members_count + 1
			end
		end
	end

	if crew_members_count < capacity then
		for _, player in pairs(game.connected_players) do
			if crew_members_count < capacity and (not crew_members[player.index]) and player.surface.name == CoreData.lobby_surface_name and Boats.on_boat(boat, player.position) then
				crew_members[player.index] = player
				crew_members_count = crew_members_count + 1
			end
		end
	end

	for _, player in pairs(crew_members) do
		player.force = memory.force
		memory.crewplayerindices[#memory.crewplayerindices + 1] = player.index
	end

	return crew_members
end


function Public.join_spectators(player, crewid)
	if not (crewid > 0) then return end

	Memory.set_working_id(crewid)
	local memory = Memory.get_crew_memory()

	local force = memory.force
	if not (force and force.valid and Common.validate_player(player)) then return end

	local surface = game.surfaces[CoreData.lobby_surface_name]

	local adventuring = false
	local spectating = false
	if memory.crewstatus and memory.crewstatus == enum.ADVENTURING then
		for _, playerindex in pairs(memory.crewplayerindices) do
			if player.index == playerindex then adventuring = true end
		end
		for _, playerindex in pairs(memory.spectatorplayerindices) do
			if player.index == playerindex then spectating = true end
		end
	end

	if spectating then return end

	if adventuring then
		local char = player.character

		if char and char.valid then
			local p = char.position
			-- local surface_name = char.surface.name
			if p then
				Common.notify_force(force, {'pirates.crew_to_spectator', player.name})
				-- Server.to_discord_embed_raw(CoreData.comfy_emojis.feel .. '[' .. memory.name .. '] ' .. message)
			end
			-- if p then
			-- 	Common.notify_force(force, message .. ' to become a spectator.' .. ' [gps=' .. Math.ceil(p.x) .. ',' .. Math.ceil(p.y) .. ',' .. surface_name ..']')
			-- 	-- Server.to_discord_embed_raw(CoreData.comfy_emojis.feel .. '[' .. memory.name .. '] ' .. message)
			-- end

			Common.send_important_items_from_player_to_crew(player, true)
			char.die(memory.force_name)

			player.set_controller{type = defines.controllers.spectator}
		else
			Common.notify_force(force, {'pirates.crew_to_spectator', player.name})
			-- Server.to_discord_embed_raw(CoreData.comfy_emojis.feel .. '[' .. memory.name .. '] ' .. message)
			player.set_controller{type = defines.controllers.spectator}
		end

		local c = surface.create_entity{name = 'character', position = surface.find_non_colliding_position('character', Common.lobby_spawnpoint, 32, 0.5) or Common.lobby_spawnpoint, force = 'player'}

		player.associate_character(c)

		player.set_controller{type = defines.controllers.spectator}

		memory.crewplayerindices = Utils.ordered_table_with_values_removed(memory.crewplayerindices, player.index)

		Roles.player_left_so_redestribute_roles(player)
	else
		Public.player_abandon_endorsements(player)
		local c = player.character
		player.set_controller{type = defines.controllers.spectator}
		player.teleport(memory.spawnpoint, game.surfaces[memory.boat.surface_name])
		player.force = force
		player.associate_character(c)

		Common.notify_force(force, {'pirates.lobby_to_spectator', player.name})
		Common.notify_lobby({'pirates.lobby_to_spectator_2', player.name, memory.name})
	end
	memory.spectatorplayerindices[#memory.spectatorplayerindices + 1] = player.index
	memory.tempbanned_from_joining_data[player.index] = game.tick
	-- if #Common.crew_get_crew_members() == 0 then
	-- 	memory.crew_disband_tick = game.tick + 30
	-- 	-- memory.crew_disband_tick = game.tick + 60*60*2 --give players time to log back in after a crash or save
	-- end
	if not (memory.difficulty_votes) then memory.difficulty_votes = {} end
	memory.difficulty_votes[player.index] = nil
end


function Public.leave_spectators(player, quiet)
	quiet = quiet or false
	local memory = Memory.get_crew_memory()
	local surface = game.surfaces[CoreData.lobby_surface_name]

	if not Common.validate_player(player) then return end

	if not quiet then
		Common.notify_force(player.force, {'pirates.spectator_to_lobby', player.name})
	end

	local chars = player.get_associated_characters()
	if #chars > 0 then
		player.teleport(chars[1].position, surface)
		player.set_controller{type = defines.controllers.character, character = chars[1]}
	else
		player.set_controller{type = defines.controllers.god}
		player.teleport(surface.find_non_colliding_position('character', Common.lobby_spawnpoint, 32, 0.5) or Common.lobby_spawnpoint, surface)
		player.create_character()
	end

	memory.spectatorplayerindices = Utils.ordered_table_with_values_removed(memory.spectatorplayerindices, player.index)

	if #Common.crew_get_crew_members() == 0 then
		if Common.autodisband_ticks then
			memory.crew_disband_tick = game.tick + Common.autodisband_ticks
		end
		if _DEBUG then memory.crew_disband_tick = game.tick + 30*60*60 end
	end

	player.force = 'player'
end


function Public.join_crew(player, crewid, rejoin)
	if not crewid then return end

	Memory.set_working_id(crewid)
	local memory = Memory.get_crew_memory()

	if not Common.validate_player(player) then return end

	-- local startsurface = game.surfaces[CoreData.lobby_surface_name]

	local boat = memory.boat
	local surface
	if boat and boat.surface_name and game.surfaces[boat.surface_name] and game.surfaces[boat.surface_name].valid then
		surface = game.surfaces[boat.surface_name]
	else
		surface = game.surfaces[Common.current_destination().surface_name]
	end

	-- local adventuring = false
	local spectating = false
	if memory.crewstatus and memory.crewstatus == enum.ADVENTURING then
		-- for _, playerindex in pairs(memory.crewplayerindices) do
		-- 	if player.index == playerindex then adventuring = true end
		-- end
		for _, playerindex in pairs(memory.spectatorplayerindices) do
			if player.index == playerindex then spectating = true end
		end
	end

	if spectating then
		local chars = player.get_associated_characters()
		for _, char in pairs(chars) do
				char.destroy()
		end

		player.teleport(surface.find_non_colliding_position('character', memory.spawnpoint, 32, 0.5) or memory.spawnpoint, surface)

		player.set_controller{type = defines.controllers.god}
		player.create_character()

		memory.spectatorplayerindices = Utils.ordered_table_with_values_removed(memory.spectatorplayerindices, player.index)
	else
		Public.player_abandon_endorsements(player)
		player.force = memory.force
		player.teleport(surface.find_non_colliding_position('character', memory.spawnpoint, 32, 0.5) or memory.spawnpoint, surface)

	Common.notify_lobby({'pirates.lobby_to_crew_2', player.name, memory.name})
	end

	Common.notify_force(player.force, {'pirates.lobby_to_crew', player.name})
	-- Server.to_discord_embed_raw(CoreData.comfy_emojis.yum1 .. '[' .. memory.name .. '] ' .. message)

	memory.crewplayerindices[#memory.crewplayerindices + 1] = player.index

	-- don't give them items if they've been in the crew recently:
	if not (memory.tempbanned_from_joining_data and memory.tempbanned_from_joining_data[player.index]) and (not rejoin) then --just using tempbanned_from_joining_data as a quick proxy for whether the player has ever been in this run before
		for item, amount in pairs(Balance.starting_items_player_late) do
			player.insert({name = item, count = amount})
		end
	end

	Roles.confirm_captain_exists(player)

	if #Common.crew_get_crew_members() == 1 and memory.crew_disband_tick then
		memory.crew_disband_tick = nil --to prevent disbanding the crew after saving the game (booting everyone) and loading it again (joining the crew as the only member)
	end

	if memory.overworldx > 0 then
		local color = CoreData.difficulty_options[memory.difficulty_option].associated_color

		Common.notify_player_announce(player, {'pirates.personal_join_string_1', memory.name, CoreData.capacity_options[memory.capacity_option].text3, color.r, color.g, color.b, CoreData.difficulty_options[memory.difficulty_option].text})
	else
		Common.notify_player_announce(player, {'pirates.personal_join_string_1', memory.name, CoreData.capacity_options[memory.capacity_option].text3})
	end
end

function Public.leave_crew(player, to_lobby, quiet)
	quiet = quiet or false
	local memory = Memory.get_crew_memory()
	local surface = game.surfaces[CoreData.lobby_surface_name]

	if not Common.validate_player(player) then return end

	local char = player.character
	if char and char.valid then
		-- local p = char.position
		-- local surface_name = char.surface.name
		if not quiet then
			Common.notify_force(player.force, {'pirates.crew_leave', player.name})
		-- else
		-- 	message = player.name .. ' left.'
		end
		-- if p then
		-- 	Common.notify_force(player.force, message .. ' [gps=' .. Math.ceil(p.x) .. ',' .. Math.ceil(p.y) .. ',' .. surface_name ..']')
		-- 	-- Server.to_discord_embed_raw(CoreData.comfy_emojis.feel .. '[' .. memory.name .. '] ' .. message)
		-- end

		if to_lobby then
			Common.send_important_items_from_player_to_crew(player, true)
			char.die(memory.force_name)
		else
			Common.send_important_items_from_player_to_crew(player)
			memory.temporarily_logged_off_characters[player.index] = game.tick
		end
	-- else
	-- 	if not quiet then
	-- 		-- local message = player.name .. ' left the crew.'
	-- 		-- Common.notify_force(player.force, message)
	-- 	end
	end

	if to_lobby then
		player.set_controller{type = defines.controllers.god}

		player.teleport(surface.find_non_colliding_position('character', Common.lobby_spawnpoint, 32, 0.5) or Common.lobby_spawnpoint, surface)
		player.force = 'player'
		player.create_character()
	end

	memory.crewplayerindices = Utils.ordered_table_with_values_removed(memory.crewplayerindices, player.index)

	-- setting it to this won't ban them from rejoining, it just affects the loot they spawn in with:
	memory.tempbanned_from_joining_data[player.index] = game.tick - Common.ban_from_rejoining_crew_ticks

	if not (memory.difficulty_votes) then memory.difficulty_votes = {} end
	memory.difficulty_votes[player.index] = nil

	Roles.player_left_so_redestribute_roles(player)

	if #Common.crew_get_crew_members() == 0 then
		if Common.autodisband_ticks then
			memory.crew_disband_tick = game.tick + Common.autodisband_ticks
		end
		-- memory.crew_disband_tick = game.tick + 60*60*2 --give players time to log back in after a crash or save
		if _DEBUG then memory.crew_disband_tick = game.tick + 30*60*60 end
	end
end



function Public.get_unaffiliated_players()
	local global_memory = Memory.get_global_memory()

	local playerlist = {}
	for _, player in pairs(game.connected_players) do
		local found = false
		for _, id in pairs(global_memory.crew_active_ids) do
			Memory.set_working_id(id)
			for _, player2 in pairs(Common.crew_get_crew_members_and_spectators()) do
				if player == player2 then found = true end
			end
		end
		if not found then playerlist[#playerlist + 1] = player end
	end
	return playerlist
end


function Public.plank(captain, player)
	local memory = Memory.get_crew_memory()

	if Utils.contains(Common.crew_get_crew_members(), player) then
		if (not (captain.index == player.index)) then
			Server.to_discord_embed_raw(CoreData.comfy_emojis.monkas .. string.format("%s planked %s!", captain.name, player.name))

			Common.notify_force(player.force, {'pirates.plank', captain.name, player.name})

			Public.join_spectators(player, memory.id)
			memory.tempbanned_from_joining_data[player.index] = game.tick + 60 * 120
			return true
		else
			Common.notify_player_error(player, {'pirates.plank_error_self'})
			return false
		end
	else
		Common.notify_player_error(player, {'pirates.plank_error_invalid_player'})
		return false
	end
end



function Public.disband_crew(donotprint)
	local global_memory = Memory.get_global_memory()
	local memory = Memory.get_crew_memory()

	if not memory.name then return end

	local id = memory.id
	local players = Common.crew_get_crew_members_and_spectators()

	for _,player in pairs(players) do
		if player.controller_type == defines.controllers.editor then player.toggle_map_editor() end
		player.force = 'player'
	end

	if (not donotprint) then

		local message = {'pirates.crew_disband', memory.name, Utils.time_longform((memory.real_age or 0)/60)}
		Common.notify_game(message)
		Server.to_discord_embed_raw({'', CoreData.comfy_emojis.monkas, message}, true)

		-- if memory.game_won then
		--		 game.print({'chronosphere.message_game_won_restart'}, {r=0.98, g=0.66, b=0.22})
		-- end
	end


	Public.reset_crew_and_enemy_force(id)

	local lobby = game.surfaces[CoreData.lobby_surface_name]
	for _, player in pairs(players) do

		if player.character then
			player.character.destroy()
			player.character = nil
		end

		player.set_controller({type=defines.controllers.god})

		if player.get_associated_characters() and #player.get_associated_characters() == 1 then
			local char = player.get_associated_characters()[1]
			player.teleport(char.position, char.surface)

			player.set_controller({type=defines.controllers.character, character=char})
		else
			local pos = lobby.find_non_colliding_position('character', Common.lobby_spawnpoint, 32, 0.5) or Common.lobby_spawnpoint
			player.teleport(pos, lobby)
			player.create_character()
		end
	end

	if memory.sea_name then
		local seasurface = game.surfaces[memory.sea_name]
		if seasurface then game.delete_surface(seasurface) end
	end

	for i = 1, memory.hold_surface_count do
		local holdname = Hold.get_hold_surface_name(i)
		if game.surfaces[holdname] then
			game.delete_surface(game.surfaces[holdname])
		end
	end

	local cabinname = Cabin.get_cabin_surface_name()
	if game.surfaces[cabinname] then
		game.delete_surface(game.surfaces[cabinname])
	end

	local s = Hold.get_hold_surface(1)
	if s and s.valid then
		log('hold failed to delete')
	end

	s = Cabin.get_cabin_surface()
	if s and s.valid then
		log(_inspect(cabinname))
		log('cabin failed to delete')
	end

	local crowsnestname = SurfacesCommon.encode_surface_name(memory.id, 0, Surfaces.enum.CROWSNEST, nil)
	if game.surfaces[crowsnestname] then game.delete_surface(game.surfaces[crowsnestname]) end

	for _, destination in pairs(memory.destinations) do
		if game.surfaces[destination.surface_name] then game.delete_surface(game.surfaces[destination.surface_name]) end
	end

	global_memory.crew_memories[id] = nil
	for k, idd in pairs(global_memory.crew_active_ids) do
		if idd == id then table.remove(global_memory.crew_active_ids, k) end
	end

	Lobby.place_starting_dock_showboat(id)
end


function Public.generate_new_crew_id()
	local global_memory = Memory.get_global_memory()

	if not global_memory.crew_memories[1] then return 1
	elseif not global_memory.crew_memories[2] then return 2
	elseif not global_memory.crew_memories[3] then return 3
	else return end
end


function Public.player_abandon_proposal(player)
	local global_memory = Memory.get_global_memory()

	for k, proposal in pairs(global_memory.crewproposals) do
		if proposal.endorserindices and proposal.endorserindices[1] and proposal.endorserindices[1] == player.index then
			proposal.endorserindices[k] = nil
			Common.notify_lobby({'pirates.proposal_retracted', proposal.name})
			-- Server.to_discord_embed(message)
			global_memory.crewproposals[k] = nil
		end
	end
end

function Public.player_abandon_endorsements(player)
	local global_memory = Memory.get_global_memory()

	for k, proposal in pairs(global_memory.crewproposals) do
		for k2, i in pairs(proposal.endorserindices) do
			if i == player.index then
				proposal.endorserindices[k2] = nil
				if #proposal.endorserindices == 0 then
					Common.notify_lobby({'pirates.proposal_abandoned', proposal.name})
					-- Server.to_discord_embed(message)
					global_memory.crewproposals[k] = nil
				end
			end
		end
	end
end


local crowsnest_delayed = Token.register(
	function(data)
		Memory.set_working_id(data.crew_id)
		Crowsnest.crowsnest_surface_delayed_init()
	end
)
function Public.initialise_crowsnest()
	local memory = Memory.get_crew_memory()
	Crowsnest.create_crowsnest_surface()
	Task.set_timeout_in_ticks(5, crowsnest_delayed, {crew_id = memory.id})
end

function Public.initialise_crowsnest_1()
	Crowsnest.create_crowsnest_surface()
end
function Public.initialise_crowsnest_2()
	Crowsnest.crowsnest_surface_delayed_init()
end

function Public.initialise_crew(accepted_proposal)
	local global_memory = Memory.get_global_memory()

	local new_id = Public.generate_new_crew_id()

	global_memory.crew_active_ids[#global_memory.crew_active_ids + 1] = new_id

	Memory.initialise_crew_memory(new_id)
	Memory.set_working_id(new_id)

	game.reset_time_played() -- affects the multiplayer lobby view

	local memory = Memory.get_crew_memory()

    local secs = Server.get_current_time()
	if not secs then secs = 0 end
	memory.secs_id = secs

	memory.id = new_id

	memory.force_name = Common.get_crew_force_name(new_id)
	memory.enemy_force_name = Common.get_enemy_force_name(new_id)
	memory.ancient_enemy_force_name = Common.get_ancient_hostile_force_name(new_id)
	memory.ancient_friendly_force_name = Common.get_ancient_friendly_force_name(new_id)

	memory.force = game.forces[memory.force_name]
	memory.enemy_force = game.forces[memory.enemy_force_name]
	memory.ancient_enemy_force = game.forces[memory.ancient_enemy_force_name]
	memory.ancient_friendly_force = game.forces[memory.ancient_friendly_force_name]

	memory.evolution_factor = 0

	memory.delayed_tasks = {}
	memory.buffered_tasks = {}
	memory.crewplayerindices = {}
	memory.spectatorplayerindices = {}
	memory.tempbanned_from_joining_data = {}
	memory.destinations = {}
	memory.temporarily_logged_off_characters = {}
	memory.class_renderings = {}
	memory.class_auxiliary_data = {}

	memory.hold_surface_count = 1

	memory.speed_boost_characters = {}

	memory.original_proposal = accepted_proposal
	memory.name = accepted_proposal.name
	memory.difficulty_option = accepted_proposal.difficulty_option
	memory.capacity_option = accepted_proposal.capacity_option
	-- memory.mode_option = accepted_proposal.mode_option
	memory.difficulty = CoreData.difficulty_options[accepted_proposal.difficulty_option].value
	memory.capacity = CoreData.capacity_options[accepted_proposal.capacity_option].value
	-- memory.mode = CoreData.mode_options[accepted_proposal.mode_option].value

	memory.destinationsvisited_indices = {}
	memory.stored_fuel = Balance.starting_fuel
	memory.available_classes_pool = Classes.initial_class_pool()
	memory.playtesting_stats = {
		coins_gained_by_biters = 0,
		coins_gained_by_nests_and_worms = 0,
		coins_gained_by_trees_and_rocks = 0,
		coins_gained_by_ore = 0,
		coins_gained_by_rocket_launches = 0,
		coins_gained_by_markets = 0,
		coins_gained_by_krakens = 0,
		fuel_spent_at_sea = 0,
		fuel_spent_at_destinations_passively = 0,
		fuel_spent_at_destinations_while_moving = 0,
	}

	memory.captain_accrued_time_data = {}
	memory.max_players_recorded = 0

	memory.classes_table = {}
	memory.officers_table = {}
	memory.spare_classes = {}
	memory.unlocked_classes = {}

	memory.healthbars = {}
	memory.overworld_krakens = {}
	memory.kraken_stream_registrations = {}

	memory.overworldx = 0
	memory.overworldy = 0

	memory.hold_surface_destroyable_wooden_chests = {}

	memory.seaname = SurfacesCommon.encode_surface_name(memory.id, 0, SurfacesCommon.enum.SEA, enum.DEFAULT)

	local surface = game.surfaces[CoreData.lobby_surface_name]
	memory.spawnpoint = Common.lobby_spawnpoint

	memory.force.set_spawn_position(memory.spawnpoint, surface)

	local message = {'pirates.crew_launch', accepted_proposal.name}
	Common.notify_game(message)
	-- Server.to_discord_embed_raw(CoreData.comfy_emojis.pogkot .. message .. ' Difficulty: ' .. CoreData.difficulty_options[memory.difficulty_option].text .. ', Capacity: ' .. CoreData.capacity_options[memory.capacity_option].text3 .. '.')
	Server.to_discord_embed_raw({'',CoreData.comfy_emojis.pogkot,message,' Capacity: ',CoreData.capacity_options[memory.capacity_option].text3,'.'}, true)
	game.surfaces[CoreData.lobby_surface_name].play_sound{path='utility/new_objective', volume_modifier=0.75}

	memory.boat = global_memory.lobby_boats[new_id]
	local boat = memory.boat

	for _, e in pairs(memory.boat.cannons_temporary_reference or {}) do
		Common.new_healthbar(true, e, Balance.cannon_starting_hp, nil, e.health, 0.3, -0.1, memory.boat)
	end

	boat.dockedposition = boat.position
	boat.speed = 0
	boat.cannonscount = 2
end


function Public.summon_crew()
	local memory = Memory.get_crew_memory()
	local boat = memory.boat

	local print = false
	for _, player in pairs(game.connected_players) do
		if player.surface and player.surface.valid and boat.surface_name and player.surface.name == boat.surface_name and (not Boats.on_boat(boat, player.position)) then
			local p = player.surface.find_non_colliding_position('character', memory.spawnpoint, 5, 0.1)
			if p then
				player.teleport(p)
			else
				player.teleport(memory.spawnpoint)
			end
			print = true
		end
	end
	if print then
		Common.notify_force(memory.force, {'pirates.crew_summon'})
	end
end


function Public.reset_crew_and_enemy_force(id)
	local crew_force = game.forces[Common.get_crew_force_name(id)]
	local enemy_force = game.forces[Common.get_enemy_force_name(id)]
	local ancient_friendly_force = game.forces[Common.get_ancient_friendly_force_name(id)]
	local ancient_enemy_force = game.forces[Common.get_ancient_hostile_force_name(id)]

	crew_force.reset()
	enemy_force.reset()
	ancient_friendly_force.reset()
	ancient_enemy_force.reset()

    ancient_enemy_force.set_turret_attack_modifier('gun-turret', 0.2)

	enemy_force.reset_evolution()
	for _, tech in pairs(crew_force.technologies) do
		crew_force.set_saved_technology_progress(tech, 0)
	end
	local lobby = game.surfaces[CoreData.lobby_surface_name]
	crew_force.set_spawn_position(Common.lobby_spawnpoint, lobby)

	enemy_force.ai_controllable = true



	crew_force.set_friend('player', true)
	game.forces['player'].set_friend(crew_force, true)
	crew_force.set_friend(ancient_friendly_force, true)
	ancient_friendly_force.set_friend(crew_force, true)
	enemy_force.set_friend(ancient_friendly_force, true)
	ancient_friendly_force.set_friend(enemy_force, true)
	enemy_force.set_friend(ancient_enemy_force, true)
	ancient_enemy_force.set_friend(enemy_force, true)

	-- enemy_force.set_friend(environment_force, true)
	-- environment_force.set_friend(enemy_force, true)

	-- environment_force.set_friend(ancient_enemy_force, true)
	-- ancient_enemy_force.set_friend(environment_force, true)

	-- environment_force.set_friend(ancient_friendly_force, true)
	-- ancient_friendly_force.set_friend(environment_force, true)

	-- maybe make these dependent on map... it could be slower to mine on poor maps, so that players jump more often rather than getting every last drop
	crew_force.mining_drill_productivity_bonus = 1
	-- crew_force.mining_drill_productivity_bonus = 1.25
	crew_force.manual_mining_speed_modifier = 3
	crew_force.character_inventory_slots_bonus = 0
	-- crew_force.character_inventory_slots_bonus = 10
	-- crew_force.character_running_speed_modifier = Balance.base_extra_character_speed
	crew_force.laboratory_productivity_bonus = 0
	crew_force.ghost_time_to_live = 12 * 60 * 60
	crew_force.worker_robots_speed_modifier = 0.5

	for k, v in pairs(Balance.player_ammo_damage_modifiers()) do
		crew_force.set_ammo_damage_modifier(k, v)
	end
	for k, v in pairs(Balance.player_gun_speed_modifiers()) do
		crew_force.set_gun_speed_modifier(k, v)
	end
	for k, v in pairs(Balance.player_turret_attack_modifiers()) do
		crew_force.set_turret_attack_modifier(k, v)
	end

	crew_force.technologies['circuit-network'].researched = true
	crew_force.technologies['uranium-processing'].researched = true
	crew_force.technologies['kovarex-enrichment-process'].researched = true
	crew_force.technologies['gun-turret'].researched = true
	crew_force.technologies['electric-energy-distribution-1'].researched = true
	crew_force.technologies['electric-energy-distribution-2'].researched = true
	crew_force.technologies['advanced-material-processing'].researched = true
	crew_force.technologies['advanced-material-processing-2'].researched = true
	crew_force.technologies['solar-energy'].researched = true
	crew_force.technologies['inserter-capacity-bonus-1'].researched = true --needed to make stack inserters different to fast inserters
	-- crew_force.technologies['inserter-capacity-bonus-2'].researched = true

	--as prerequisites for uranium ammo and automation 3:
	crew_force.technologies['speed-module'].researched = true
	crew_force.technologies['tank'].researched = true
	crew_force.recipes['speed-module'].enabled = false
	crew_force.recipes['tank'].enabled = false
	crew_force.recipes['cannon-shell'].enabled = false
	crew_force.recipes['explosive-cannon-shell'].enabled = false



	--@TRYING this out:
	crew_force.technologies['coal-liquefaction'].enabled = true
	crew_force.technologies['coal-liquefaction'].researched = true

	crew_force.technologies['automobilism'].enabled = false

	crew_force.technologies['toolbelt'].enabled = false --trying this. we don't actually want players to carry too many things manually, and in fact in a resource-tight scenario that's problematic

	-- note: many of these recipes are overwritten after tech researched!!!!!!! like pistol. check elsewhere in code

	crew_force.recipes['pistol'].enabled = false

	-- these are redundant I think...?:
	crew_force.recipes['centrifuge'].enabled = false
	crew_force.recipes['flamethrower-turret'].enabled = false

	crew_force.technologies['railway'].researched = true --needed for purple sci
	crew_force.recipes['rail'].enabled = true --needed for purple sci
	crew_force.recipes['locomotive'].enabled = false
	crew_force.recipes['car'].enabled = false
	crew_force.recipes['cargo-wagon'].enabled = false

	crew_force.recipes['nuclear-fuel'].enabled = false -- reduce clutter

	-- crew_force.recipes['underground-belt'].enabled = false
	-- crew_force.recipes['fast-underground-belt'].enabled = false
	-- crew_force.recipes['express-underground-belt'].enabled = false

	crew_force.technologies['land-mine'].enabled = false
	crew_force.technologies['landfill'].enabled = false
	crew_force.technologies['cliff-explosives'].enabled = false

	crew_force.technologies['rail-signals'].enabled = false

	crew_force.technologies['logistic-system'].enabled = false


	crew_force.technologies['tank'].enabled = false
	crew_force.technologies['rocketry'].enabled = false
	crew_force.technologies['artillery'].enabled = false
	crew_force.technologies['destroyer'].enabled = false
	crew_force.technologies['spidertron'].enabled = false
	crew_force.technologies['atomic-bomb'].enabled = false
	crew_force.technologies['explosive-rocketry'].enabled = false

	crew_force.technologies['research-speed-1'].enabled = false
	crew_force.technologies['research-speed-2'].enabled = false
	crew_force.technologies['research-speed-3'].enabled = false
	crew_force.technologies['research-speed-4'].enabled = false
	crew_force.technologies['research-speed-5'].enabled = false
	crew_force.technologies['research-speed-6'].enabled = false
	-- crew_force.technologies['follower-robot-count-1'].enabled = false
	-- crew_force.technologies['follower-robot-count-2'].enabled = false
	-- crew_force.technologies['follower-robot-count-3'].enabled = false
	-- crew_force.technologies['follower-robot-count-4'].enabled = false

	-- crew_force.technologies['inserter-capacity-bonus-3'].enabled = false
	-- crew_force.technologies['inserter-capacity-bonus-4'].enabled = false
	-- crew_force.technologies['inserter-capacity-bonus-5'].enabled = false
	-- crew_force.technologies['inserter-capacity-bonus-6'].enabled = false
	-- crew_force.technologies['refined-flammables-3'].enabled = false
	-- crew_force.technologies['refined-flammables-4'].enabled = false
	-- crew_force.technologies['refined-flammables-5'].enabled = false

	crew_force.technologies['mining-productivity-3'].enabled = false --huge trap. even the earlier ones are a trap?

	-- for lategame balance:
	-- crew_force.technologies['worker-robots-storage-1'].enabled = false
	crew_force.technologies['worker-robots-storage-2'].enabled = false
	crew_force.technologies['worker-robots-storage-3'].enabled = false
	crew_force.technologies['worker-robots-speed-5'].enabled = false
	crew_force.technologies['worker-robots-speed-6'].enabled = false
	crew_force.technologies['follower-robot-count-5'].enabled = false
	crew_force.technologies['follower-robot-count-6'].enabled = false
	crew_force.technologies['follower-robot-count-7'].enabled = false
	crew_force.technologies['inserter-capacity-bonus-6'].enabled = false
	crew_force.technologies['inserter-capacity-bonus-7'].enabled = false

	crew_force.technologies['weapon-shooting-speed-6'].enabled = false
	crew_force.technologies['laser-shooting-speed-6'].enabled = false
	crew_force.technologies['laser-shooting-speed-7'].enabled = false
	crew_force.technologies['refined-flammables-5'].enabled = false
	crew_force.technologies['refined-flammables-6'].enabled = false
	crew_force.technologies['refined-flammables-7'].enabled = false
	crew_force.technologies['energy-weapons-damage-5'].enabled = false --5 makes krakens too easy
	crew_force.technologies['energy-weapons-damage-6'].enabled = false
	crew_force.technologies['energy-weapons-damage-7'].enabled = false
	crew_force.technologies['physical-projectile-damage-5'].enabled = false
	crew_force.technologies['physical-projectile-damage-6'].enabled = false
	crew_force.technologies['physical-projectile-damage-7'].enabled = false
	crew_force.technologies['stronger-explosives-5'].enabled = false
	crew_force.technologies['stronger-explosives-6'].enabled = false
	crew_force.technologies['stronger-explosives-7'].enabled = false
	-- these require 2000 white sci each:
	crew_force.technologies['artillery-shell-range-1'].enabled = false --infinite techs
	crew_force.technologies['artillery-shell-speed-1'].enabled = false --infinite techs

	crew_force.technologies['steel-axe'].enabled = false

	crew_force.technologies['concrete'].enabled = false
	crew_force.technologies['nuclear-power'].enabled = false

	crew_force.technologies['effect-transmission'].enabled = true

	-- exploit?:
	crew_force.technologies['gate'].enabled = true

	crew_force.technologies['productivity-module-2'].enabled = true
	crew_force.technologies['productivity-module-3'].enabled = false
	crew_force.technologies['speed-module'].enabled = true
	crew_force.technologies['speed-module-2'].enabled = false
	crew_force.technologies['speed-module-3'].enabled = false
	crew_force.technologies['effectivity-module'].enabled = false
	crew_force.technologies['effectivity-module-2'].enabled = false
	crew_force.technologies['effectivity-module-3'].enabled = false
	crew_force.technologies['automation-3'].enabled = true
	crew_force.technologies['rocket-control-unit'].enabled = false
	crew_force.technologies['rocket-silo'].enabled = false
	crew_force.technologies['space-science-pack'].enabled = false
	crew_force.technologies['mining-productivity-4'].enabled = false
	crew_force.technologies['logistics-3'].enabled = true
	crew_force.technologies['nuclear-fuel-reprocessing'].enabled = false

	-- crew_force.technologies['railway'].enabled = false
	crew_force.technologies['automated-rail-transportation'].enabled = false
	crew_force.technologies['braking-force-1'].enabled = false
	crew_force.technologies['braking-force-2'].enabled = false
	crew_force.technologies['braking-force-3'].enabled = false
	crew_force.technologies['braking-force-4'].enabled = false
	crew_force.technologies['braking-force-5'].enabled = false
	crew_force.technologies['braking-force-6'].enabled = false
	crew_force.technologies['braking-force-7'].enabled = false
	crew_force.technologies['fluid-wagon'].enabled = false

	crew_force.technologies['production-science-pack'].enabled = true
	crew_force.technologies['utility-science-pack'].enabled = true

	crew_force.technologies['modular-armor'].enabled = false
	crew_force.technologies['power-armor'].enabled = false
	crew_force.technologies['solar-panel-equipment'].enabled = false
	crew_force.technologies['personal-roboport-equipment'].enabled = false
	crew_force.technologies['personal-laser-defense-equipment'].enabled = false
	crew_force.technologies['night-vision-equipment'].enabled = false
	crew_force.technologies['energy-shield-equipment'].enabled = false
	crew_force.technologies['belt-immunity-equipment'].enabled = false
	crew_force.technologies['exoskeleton-equipment'].enabled = false
	crew_force.technologies['battery-equipment'].enabled = false
	crew_force.technologies['fusion-reactor-equipment'].enabled = false
	crew_force.technologies['power-armor-mk2'].enabled = false
	crew_force.technologies['energy-shield-mk2-equipment'].enabled = false
	crew_force.technologies['personal-roboport-mk2-equipment'].enabled = false
	crew_force.technologies['battery-mk2-equipment'].enabled = false
	crew_force.technologies['discharge-defense-equipment'].enabled = false

	crew_force.technologies['distractor'].enabled = false
	crew_force.technologies['military-4'].enabled = true
	crew_force.technologies['uranium-ammo'].enabled = true
end


return Public