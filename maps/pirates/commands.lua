-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

--luacheck: ignore
--luacheck ignores because mass requires is a code templating choice...

local Color = require 'utils.color_presets'
local Server = require 'utils.server'
local Math = require 'maps.pirates.math'
local Ai = require 'maps.pirates.ai'
local Memory = require 'maps.pirates.memory'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local PlayerColors = require 'maps.pirates.player_colors'
local Utils = require 'maps.pirates.utils_local'
local Crew = require 'maps.pirates.crew'
local Roles = require 'maps.pirates.roles.roles'
local Boats = require 'maps.pirates.structures.boats.boats'
local Surfaces = require 'maps.pirates.surfaces.surfaces'
local Overworld = require 'maps.pirates.overworld'
local Islands = require 'maps.pirates.surfaces.islands.islands'
local Progression = require 'maps.pirates.progression'
local Crowsnest = require 'maps.pirates.surfaces.crowsnest'
local PiratesApiEvents = require 'maps.pirates.api_events'
local Upgrades = require 'maps.pirates.boat_upgrades'
local Effects = require 'maps.pirates.effects'
local Kraken = require 'maps.pirates.surfaces.sea.kraken'
local _inspect = require 'utils.inspect'.inspect
local simplex_noise = require 'utils.simplex_noise'.d2
local Token = require 'utils.token'
local Task = require 'utils.task'
local Highscore = require 'maps.pirates.highscore'
local CustomEvents = require 'maps.pirates.custom_events'
local Classes = require 'maps.pirates.roles.classes'
local Gui = require 'maps.pirates.gui.gui'
-- local Session = require 'utils.datastore.session_data'

-- *** *** --
--*** HELPERS ***--
-- *** *** --

local function cmd_set_memory(cmd)
	local player = game.players[cmd.player_index]
	local crew_id = Common.get_id_from_force_name(player.force.name)
	Memory.set_working_id(crew_id)
end

local function check_admin(cmd)
	local player = game.players[cmd.player_index]
	--local trusted = Session.get_trusted_table()
	local p
	if player then
		if player ~= nil then
			p = player.print
			--@temporary
			if player.name == "Piratux" or player.name == "thesixthroc" then
				return true
			end
			if not player.admin then
				p({ 'pirates.cmd_error_not_admin' }, Color.fail)
				return false
			end
		else
			p = log
		end
	end
	return true
end

local function check_captain(cmd)
	local player = game.players[cmd.player_index]
	local p
	if player then
		if player ~= nil then
			p = player.print
			if not Common.validate_player(player) then return end
			if not (Roles.player_privilege_level(player) >= Roles.privilege_levels.CAPTAIN) then
				p({ 'pirates.cmd_error_not_captain' }, Color.fail)
				return false
			end
		else
			p = log
		end
	end
	return true
end

local function check_captain_or_admin(cmd)
	local player = game.players[cmd.player_index]
	local p
	if player then
		if player ~= nil then
			p = player.print
			if not Common.validate_player(player) then return end
			if not (player.admin or Roles.player_privilege_level(player) >= Roles.privilege_levels.CAPTAIN) then
				p({ 'pirates.cmd_error_not_captain' }, Color.fail)
				return false
			end
		else
			p = log
		end
	end
	return true
end


-- @UNUSED
-- local function check_trusted(cmd)
-- 	local Session = require 'utils.datastore.session_data'
-- 	local player = game.players[cmd.player_index]
-- 	local trusted = Session.get_trusted_table()
-- 	local p
-- 	if player then
-- 		if player ~= nil then
-- 			p = player.print
-- 			if not (trusted[player.name] or player.admin) then
-- 				p('[ERROR] Only admins and trusted weebs are allowed to run this command!', Color.fail)
-- 				return false
-- 			end
-- 		else
-- 			p = log
-- 		end
-- 	end
-- 	return true
-- end

-- *** *** --
--*** PUBLIC COMMANDS ***--
-- *** *** --

commands.add_command(
	'ok',
	{ 'pirates.cmd_explain_ok' },
	function (cmd)
		cmd_set_memory(cmd)

		local memory = Memory.get_crew_memory()
		if not Common.is_id_valid(memory.id) then return end

		local player = game.players[cmd.player_index]
		if not Common.validate_player(player) then return end

		--local memory = Memory.get_crew_memory()
		Roles.player_confirm_captainhood(player)
	end)

-- Disabled, better to find these out through gameplay:
-- commands.add_command(
-- 'classes',
-- 'Prints the available classes in the game.',
-- function(cmd)
-- 	local player = game.players[cmd.player_index]
-- 	if not Common.validate_player(player) then return end
-- 	player.print('[color=gray]' .. Roles.get_classes_print_string() .. '[/color]')
-- end)

commands.add_command(
	'classinfo',
	{ 'pirates.cmd_explain_classinfo' },
	function (cmd)
		cmd_set_memory(cmd)
		local param = tostring(cmd.parameter)
		local player = game.players[cmd.player_index]
		if not Common.validate_player(player) then return end

		if param and param ~= 'nil' then
			local string = Roles.get_class_print_string(param, true)
			if string then
				Common.notify_player_expected(player, { '', { 'pirates.class_definition_for' }, ' ', string })
			else
				Common.notify_player_error(player, { 'pirates.cmd_error_invalid_class_name', param })
			end
		else
			Common.notify_player_expected(player, { '', '/classinfo ', { 'pirates.cmd_explain_classinfo' } })
		end
	end)

commands.add_command(
	'ccolor',
	{ 'pirates.cmd_explain_ccolor' },
	function (cmd)
		local param = tostring(cmd.parameter)
		local player_index = cmd.player_index
		if player_index then
			local player = game.players[player_index]
			if player and player.valid then
				if cmd.parameter then
					if PlayerColors.colors[param] then
						local rgb = PlayerColors.colors[param]
						player.color = rgb
						player.chat_color = rgb
						local message = { '', '[color=' .. rgb.r .. ',' .. rgb.g .. ',' .. rgb.b .. ']', { 'pirates.choose_chat_color', player.name, param }, '[/color] (via /ccolor).' }
						-- local message = '[color=' .. rgb.r .. ',' .. rgb.g .. ',' .. rgb.b .. ']' .. player.name .. ' chose the color ' .. param .. '[/color] (via /ccolor).'
						Common.notify_game(message)
					else
						Common.notify_player_error(player, { 'pirates.cmd_error_color_not_found', param })
					end
				else
					local color = PlayerColors.bright_color_names[Math.random(#PlayerColors.bright_color_names)]
					local rgb = PlayerColors.colors[color]
					if not rgb then return end
					player.color = rgb
					player.chat_color = rgb
					local message = { '', '[color=' .. rgb.r .. ',' .. rgb.g .. ',' .. rgb.b .. ']', { 'pirates.randomize_chat_color', player.name, color }, '[/color] (via /ccolor).' } --'randomly became' was amusing, but let's not
					-- local message = '[color=' .. rgb.r .. ',' .. rgb.g .. ',' .. rgb.b .. ']' .. player.name .. '\'s color randomized to ' .. color .. '[/color] (via /ccolor).' --'randomly became' was amusing, but let's not
					Common.notify_game(message)
					-- disabled due to lag:
					-- GUIcolor.toggle_window(player)
				end
			end
		end
	end)

commands.add_command(
	'fixpower',
	{ 'pirates.cmd_explain_fixpower' },
	function (cmd)
		cmd_set_memory(cmd)

		local memory = Memory.get_crew_memory()
		if not Common.is_id_valid(memory.id) then return end

		Boats.force_reconnect_boat_poles()
	end)

-- *** *** --
--*** CAPTAIN COMMANDS ***--
-- *** *** --

commands.add_command(
	'plank',
	{ 'pirates.cmd_explain_plank' },
	function (cmd)
		cmd_set_memory(cmd)

		local memory = Memory.get_crew_memory()
		if not Common.is_id_valid(memory.id) then return end

		local player = game.players[cmd.player_index]
		local param = tostring(cmd.parameter)
		if check_captain_or_admin(cmd) then
			if param and game.players[param] and game.players[param].index then
				Crew.plank(player, game.players[param])
			else
				Common.notify_player_error(player, { 'pirates.cmd_error_invalid_player_name', param })
			end
		end
	end)

commands.add_command(
	'officer',
	{ 'pirates.cmd_explain_officer' },
	function (cmd)
		cmd_set_memory(cmd)

		local memory = Memory.get_crew_memory()
		if not Common.is_id_valid(memory.id) then return end

		local player = game.players[cmd.player_index]
		local param = tostring(cmd.parameter)
		if check_captain_or_admin(cmd) then
			if param and game.players[param] and game.players[param].index then
				if Common.is_officer(game.players[param].index) then
					Roles.unmake_officer(player, game.players[param])
				else
					Roles.make_officer(player, game.players[param])
				end
			else
				Common.notify_player_error(player, { 'pirates.cmd_error_invalid_player_name', param })
			end
		end
	end)

commands.add_command(
	'tax',
	{ 'pirates.cmd_explain_tax' },
	function (cmd)
		cmd_set_memory(cmd)

		local memory = Memory.get_crew_memory()
		if not Common.is_id_valid(memory.id) then return end

		--local param = tostring(cmd.parameter)
		if check_captain(cmd) then
			--local player = game.players[cmd.player_index]
			Roles.captain_tax(memory.playerindex_captain)
		end
	end)

-- Try undock from an island or dock
commands.add_command(
	'undock',
	{ 'pirates.cmd_explain_undock' },
	function (cmd)
		cmd_set_memory(cmd)

		local memory = Memory.get_crew_memory()
		if not Common.is_id_valid(memory.id) then return end

		--local param = tostring(cmd.parameter)
		if check_captain_or_admin(cmd) then
			local player = game.players[cmd.player_index]
			if memory.boat.state == Boats.enum_state.DOCKED then
				Progression.undock_from_dock(true)
			elseif memory.boat.state == Boats.enum_state.LANDED then
				Progression.try_retreat_from_island(player, true)
			end
		end
	end)

commands.add_command(
	'clear_north_tanks',
	{ 'pirates.cmd_explain_clear_north_tanks' },
	function (cmd)
		cmd_set_memory(cmd)

		local memory = Memory.get_crew_memory()
		if not Common.is_id_valid(memory.id) then return end

		if check_captain_or_admin(cmd) then
			Boats.clear_fluid_from_ship_tanks(1)
		end
	end)

commands.add_command(
	'clear_south_tanks',
	{ 'pirates.cmd_explain_clear_south_tanks' },
	function (cmd)
		cmd_set_memory(cmd)

		local memory = Memory.get_crew_memory()
		if not Common.is_id_valid(memory.id) then return end

		if check_captain(cmd) then
			Boats.clear_fluid_from_ship_tanks(2)
		end
	end)

-- *** *** --
--*** ADMIN COMMANDS ***--
-- *** *** --

commands.add_command(
	'set_max_crews',
	{ 'pirates.cmd_explain_set_max_crews' },
	function (cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
			local player = game.players[cmd.player_index]
			local global_memory = Memory.get_global_memory()

			if tonumber(param) then
				global_memory.active_crews_cap_in_memory = tonumber(param)
				Common.notify_player_expected(player, { 'pirates.cmd_notify_set_max_crews', param })
			end
		end
	end)

commands.add_command(
	'setcaptain',
	{ 'pirates.cmd_explain_setcaptain' },
	function (cmd)
		cmd_set_memory(cmd)

		local memory = Memory.get_crew_memory()
		if not Common.is_id_valid(memory.id) then return end

		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
			local player = game.players[cmd.player_index]
			if param and game.players[param] and game.players[param].index then
				Roles.make_captain(game.players[param])
			else
				Common.notify_player_error(player, { 'pirates.cmd_error_invalid_player_name', param })
			end
		end
	end)

commands.add_command(
	'summoncrew',
	{ 'pirates.cmd_explain_summoncrew' },
	function (cmd)
		cmd_set_memory(cmd)

		local memory = Memory.get_crew_memory()
		if not Common.is_id_valid(memory.id) then return end

		--local param = tostring(cmd.parameter)
		if check_admin(cmd) then
			Crew.summon_crew()
		end
	end)

-- Force undock from an island or dock
commands.add_command(
	'ret',
	{ 'pirates.cmd_explain_dev' },
	function (cmd)
		cmd_set_memory(cmd)

		local memory = Memory.get_crew_memory()
		if not Common.is_id_valid(memory.id) then return end

		-- local param = tostring(cmd.parameter)
		if check_admin(cmd) then
			if memory.boat.state == Boats.enum_state.DOCKED then
				Progression.undock_from_dock(true)
			elseif memory.boat.state == Boats.enum_state.LANDED then
				Progression.retreat_from_island(true)
			end
		end
	end)

commands.add_command(
	'dump_highscores',
	{ 'pirates.cmd_explain_dev' },
	function (cmd)
		cmd_set_memory(cmd)

		if check_admin(cmd) then
			local player = game.players[cmd.player_index]
			if not Common.validate_player(player) then return end
			Highscore.dump_highscores()
			player.print('Highscores dumped.')
		end
	end)

commands.add_command(
	'setevo',
	{ 'pirates.cmd_explain_dev' },
	function (cmd)
		cmd_set_memory(cmd)

		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
			local player = game.players[cmd.player_index]
			Common.set_evo(tonumber(param))
		end
	end)

commands.add_command(
	'modi',
	{ 'pirates.cmd_explain_dev' },
	function (cmd)
		cmd_set_memory(cmd)

		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
			local player = game.players[cmd.player_index]
			local memory = Memory.get_crew_memory()
			local surface = game.surfaces[Common.current_destination().surface_name]
			local entities = surface.find_entities_filtered { position = player.position, radius = 500 }
			for _, e in pairs(entities) do
				if e and e.valid then
					-- e.force = memory.force
					e.minable = true
					e.destructible = true
					e.rotatable = true
				end
			end
			player.print('nearby entities made modifiable')
		end
	end)

commands.add_command(
	'night',
	'night',
	function (cmd)
		if check_admin(cmd) then
			local player = game.players[cmd.player_index]
			local surface = player.surface
			surface.daytime = 0.5
		end
	end)

commands.add_command(
	'overwrite_scores_specific',
	{ 'pirates.cmd_explain_dev' },
	function (cmd)
		cmd_set_memory(cmd)

		if check_admin(cmd) then
			local player = game.players[cmd.player_index]
			if not Common.validate_player(player) then return end
			local memory = Memory.get_crew_memory()
			if Highscore.overwrite_scores_specific() then player.print('Highscores overwritten.') end
		end
	end)

-- Unlock a class
commands.add_command(
	'unlock',
	{ 'pirates.cmd_explain_dev' },
	function (cmd)
		cmd_set_memory(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
			local memory = Memory.get_crew_memory()
			if not Common.is_id_valid(memory.id) then return end
			local player = game.players[cmd.player_index]
			if not Classes.try_unlock_class(param, player, true) then
				Common.notify_player_error(player, { 'pirates.cmd_error_invalid_class_name', param })
			end
		end
	end)

-- Remove all classes
commands.add_command(
	'remove_classes',
	{ 'pirates.cmd_explain_dev' },
	function (cmd)
		cmd_set_memory(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
			local memory = Memory.get_crew_memory()
			if not Common.is_id_valid(memory.id) then return end

			if not Gui.classes then return end

			memory.classes_table = {}
			memory.spare_classes = {}
			memory.recently_purchased_classes = {}
			memory.unlocked_classes = {}
			memory.available_classes_pool = Classes.initial_class_pool()
			memory.class_entry_count = 0

			local players = Common.crew_get_crew_members_and_spectators()

			for _, player in pairs(players) do
				Gui.classes.full_update(player, true)
			end
		end
	end)

-- *** *** --
--*** DEVELOPER COMMANDS ***--
-- *** *** --

if _DEBUG then
	local go_2 = Token.register(
		function (data)
			Memory.set_working_id(data.id)
			local memory = Memory.get_crew_memory()

			memory.loadingticks = 0

			-- local surface = game.surfaces[Common.current_destination().surface_name]
			-- surface.request_to_generate_chunks({x = 0, y = 0}, 10)
			-- surface.force_generate_chunk_requests()
			Progression.go_from_starting_dock_to_first_destination()
		end
	)
	local go_1 = Token.register(
		function (data)
			Memory.set_working_id(data.id)
			local memory = Memory.get_crew_memory()
			Overworld.ensure_lane_generated_up_to(0, Crowsnest.Data.visibilitywidth)
			Overworld.ensure_lane_generated_up_to(24, Crowsnest.Data.visibilitywidth)
			Overworld.ensure_lane_generated_up_to(-24, Crowsnest.Data.visibilitywidth)

			for i = 1, #memory.destinations do
				if memory.destinations[i].overworld_position.x == 0 then
					memory.mapbeingloadeddestination_index = i
					break
				end
			end

			memory.currentdestination_index = memory.mapbeingloadeddestination_index
			script.raise_event(CustomEvents.enum['update_crew_progress_gui'], {})
			Surfaces.create_surface(Common.current_destination())
			Task.set_timeout_in_ticks(60, go_2, { id = data.id })
		end
	)

	-- Move overworld boat right by a lot (you can jump over islands that way to skip them)
	commands.add_command(
		'jump',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)

			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				Overworld.try_overworld_move_v2({ x = 40, y = 0 })
			end
		end)

	-- Move overworld boat up
	commands.add_command(
		'advu',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)

			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				Overworld.try_overworld_move_v2 { x = 0, y = -24 }
			end
		end)

	-- Move overworld boat down
	commands.add_command(
		'advd',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)

			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				Overworld.try_overworld_move_v2 { x = 0, y = 24 }
			end
		end)

	-- Teleport player to available boat in lobby, automatically start journey and arrive at sea faster
	commands.add_command(
		'go',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				-- Doesn't completely prevent server from crashing when used twice at lobby, but at least saves from crashing when boat leaves lobby
				if not Common.get_id_from_force_name(player.character.force.name) then
					local proposal = {
						capacity_option = 3,
						difficulty_option = 4,
						-- mode_option = 'left',
						name = "AdminRun",
						created_by_player = cmd.player_index
					}

					Crew.initialise_crew(proposal, player.position)
					Crew.initialise_crowsnest() --contains a Task

					local memory = Memory.get_crew_memory()
					local boat = Utils.deepcopy(Surfaces.Lobby.StartingBoats[memory.id])

					for _, p in pairs(game.connected_players) do
						p.teleport({ x = -30, y = boat.position.y }, game.surfaces[boat.surface_name])
					end

					Progression.set_off_from_starting_dock()

					-- local memory = Memory.get_crew_memory()
					-- local boat = Utils.deepcopy(Surfaces.Lobby.StartingBoats[memory.id])
					-- memory.boat = boat
					-- boat.dockedposition = boat.position
					-- boat.decksteeringchests = {}
					-- boat.crowsneststeeringchests = {}

					Task.set_timeout_in_ticks(120, go_1, { id = memory.id })
				else
					game.print('Can\'t use this command when run has already launched')
				end
			end
		end)

	commands.add_command(
		'chnk',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)

			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()

				for i = 0, 13 do
					for j = 0, 13 do
						PiratesApiEvents.event_on_chunk_generated({ surface = player.surface, area = { left_top = { x = -7 * 32 + i * 32, y = -7 * 32 + j * 32 } } })
					end
				end
				game.print('chunks generated')
			end
		end)

	commands.add_command(
		'spd',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)

			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()
				memory.boat.speed = 60
			end
		end)

	commands.add_command(
		'stp',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)

			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()
				memory.boat.speed = 0
			end
		end)

	commands.add_command(
		'rms',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local rms = 0
				local n = 100000
				local seed = Math.random(n ^ 2)
				for i = 1, n do
					local noise = simplex_noise(i, 7.11, seed)
					rms = rms + noise ^ 2
				end
				rms = rms / n
				game.print(rms)
			end
		end)

	commands.add_command(
		'pro',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local global_memory = Memory.get_global_memory()

				local proposal = {
					capacity_option = 3,
					difficulty_option = 2,
					-- mode_option = 'left',
					name = "TestRun",
					created_by_player = cmd.player_index
				}

				global_memory.crewproposals[#global_memory.crewproposals + 1] = proposal
			end
		end)

	-- Leave island, or dock immediately
	commands.add_command(
		'lev',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()
				Progression.go_from_currentdestination_to_sea()
			end
		end)

	-- Add another hold
	commands.add_command(
		'hld',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()
				Upgrades.execute_upgade(Upgrades.enum.EXTRA_HOLD)
			end
		end)

	-- Upgrade power generators
	commands.add_command(
		'pwr',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()
				Upgrades.execute_upgade(Upgrades.enum.MORE_POWER)
			end
		end)


	commands.add_command(
		'score',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)

			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()

				game.print('faking a highscore...')
				Highscore.write_score(memory.secs_id, 'fakers', 0, 40, CoreData.version_string, 1, 1)
			end
		end)

	commands.add_command(
		'scrget',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				game.print('running Highscore.load_in_scores()')
				Highscore.load_in_scores()
			end
		end)

	commands.add_command(
		'tim',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()
				Common.current_destination().dynamic_data.timer = 88
				game.print('time set to 88 seconds')
			end
		end)

	-- Add 20000 coal fuel to ship
	commands.add_command(
		'gld',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()
				memory.stored_fuel = memory.stored_fuel + 20000
			end
		end)

	commands.add_command(
		'rad',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local destination = Common.current_destination()
				Islands.spawn_enemy_boat(Boats.enum.RAFT)
				local boat = destination.dynamic_data.enemyboats[1]
				Ai.spawn_boat_biters(boat, 0.89, Boats.get_scope(boat).Data.capacity, Boats.get_scope(boat).Data.width)
				game.print('enemy boat spawned')
			end
		end)

	commands.add_command(
		'rad2',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local destination = Common.current_destination()
				Islands.spawn_enemy_boat(Boats.enum.RAFTLARGE)
				local boat = destination.dynamic_data.enemyboats[1]
				Ai.spawn_boat_biters(boat, 0.89, Boats.get_scope(boat).Data.capacity, Boats.get_scope(boat).Data.width)
				game.print('large enemy boat spawned')
			end
		end)

	-- Spawns kraken if at sea
	commands.add_command(
		'krk',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()
				Kraken.try_spawn_kraken()
			end
		end)

	-- Sets game speed to 0.25
	commands.add_command(
		'1/4',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				game.speed = 0.25
			end
		end)

	-- Sets game speed to 0.5
	commands.add_command(
		'1/2',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				game.speed = 0.5
			end
		end)

	-- Sets game speed to 1
	commands.add_command(
		'1',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				game.speed = 1
			end
		end)

	-- Sets game speed to 2
	commands.add_command(
		'2',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				game.speed = 2
			end
		end)

	-- Sets game speed to 4
	commands.add_command(
		'4',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				game.speed = 4
			end
		end)

	-- Sets game speed to 8
	commands.add_command(
		'8',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				game.speed = 8
			end
		end)

	-- Sets game speed to 16
	commands.add_command(
		'16',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				game.speed = 16
			end
		end)

	-- Sets game speed to 32
	commands.add_command(
		'32',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				game.speed = 32
			end
		end)

	-- Sets game speed to 64
	commands.add_command(
		'64',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				game.speed = 64
			end
		end)

	commands.add_command(
		'ef1',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)

			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()
				local surface = game.surfaces[Common.current_destination().surface_name]
				Effects.worm_movement_effect(surface, { x = -45, y = 0 }, false, true)
			end
		end)

	commands.add_command(
		'ef2',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)

			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()
				local surface = game.surfaces[Common.current_destination().surface_name]
				Effects.worm_movement_effect(surface, { x = -45, y = 0 }, false, false)
			end
		end)

	commands.add_command(
		'ef3',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)

			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()
				local surface = game.surfaces[Common.current_destination().surface_name]
				Effects.worm_movement_effect(surface, { x = -45, y = 0 }, true, false)
			end
		end)

	commands.add_command(
		'ef4',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)

			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()
				local surface = game.surfaces[Common.current_destination().surface_name]
				Effects.worm_emerge_effect(surface, { x = -45, y = 0 })
			end
		end)

	commands.add_command(
		'ef5',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)

			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()
				local surface = game.surfaces[Common.current_destination().surface_name]
				Effects.biters_emerge(surface, { x = -30, y = 0 })
			end
		end)

	commands.add_command(
		'emoji',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				Server.to_discord_embed_raw(CoreData.comfy_emojis.despair)
			end
		end)

	-- Spawn friendly gun turrets with ammo to defend your ship
	commands.add_command(
		'def',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()
				if not Common.is_id_valid(memory.id) then return end

				local boat = memory.boat
				local scope = Boats.get_scope(boat)
				local surface = game.surfaces[boat.surface_name]
				if not surface then return end

				if scope.Data.cannons then
					for i = -2, 2 do
						local p1 = scope.Data.cannons[1]
						local p2 = { x = boat.position.x + p1.x + i * 2, y = boat.position.y + p1.y - 4 }
						local e = surface.create_entity({ name = 'gun-turret', position = p2, force = boat.force_name, create_build_effect_smoke = false })
						if e and e.valid then
							e.insert({ name = "uranium-rounds-magazine", count = 200 })
						end
					end
					for i = -2, 2 do
						local p1 = scope.Data.cannons[2]
						local p2 = { x = boat.position.x + p1.x + i * 2, y = boat.position.y + p1.y + 3 }
						local e = surface.create_entity({ name = 'gun-turret', position = p2, force = boat.force_name, create_build_effect_smoke = false })
						if e and e.valid then
							e.insert({ name = "uranium-rounds-magazine", count = 200 })
						end
					end
				end
			end
		end)

	-- Spawn friendly gun turrets with ammo around you
	commands.add_command(
		'atk',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			cmd_set_memory(cmd)
			local param = tostring(cmd.parameter)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				local memory = Memory.get_crew_memory()
				if not Common.is_id_valid(memory.id) then return end
				local boat = memory.boat

				local p = player.character.position
				local turret_positions = {
					{ x = p.x - 2, y = p.y - 2 },
					{ x = p.x - 2, y = p.y + 2 },
					{ x = p.x + 2, y = p.y - 2 },
					{ x = p.x + 2, y = p.y + 2 },
				}

				for _, pos in pairs(turret_positions) do
					local e = player.surface.create_entity({ name = 'gun-turret', position = pos, force = boat.force_name, create_build_effect_smoke = false })
					if e and e.valid then
						e.insert({ name = "uranium-rounds-magazine", count = 200 })
					end
				end
			end
		end)

	-- Give advanced starter kit to make exploration easier
	commands.add_command(
		'kit',
		{ 'pirates.cmd_explain_dev' },
		function (cmd)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]

				player.insert { name = 'substation', count = 50 }
				player.insert { name = 'solar-panel', count = 50 }
				player.insert { name = 'vehicle-machine-gun', count = 1 }
				player.insert { name = 'uranium-rounds-magazine', count = 200 }
				player.insert { name = 'raw-fish', count = 100 }
				player.insert { name = 'coin', count = 50000 }
				player.insert { name = 'cluster-grenade', count = 100 }
				player.insert { name = 'steel-chest', count = 50 }
				player.insert { name = 'express-loader', count = 50 }
				player.insert { name = 'burner-inserter', count = 50 }
				player.insert { name = 'accumulator', count = 50 }
			end
		end)

	commands.add_command(
		'buff',
		'buffs all damage by 10%',
		function (cmd)
			if check_admin(cmd) then
				local player = game.players[cmd.player_index]
				Crew.buff_all_damage(0.1)
			end
		end)
end
