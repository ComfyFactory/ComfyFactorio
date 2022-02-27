
local Color = require 'utils.color_presets'
local Server = require 'utils.server'

local Math = require 'maps.pirates.math'
local Ai = require 'maps.pirates.ai'
local Memory = require 'maps.pirates.memory'
local Gui = require 'maps.pirates.gui.gui'
local Common = require 'maps.pirates.common'
local CoreData = require 'maps.pirates.coredata'
local PlayerColors = require 'maps.pirates.player_colors'
local Utils = require 'maps.pirates.utils_local'

local Balance = require 'maps.pirates.balance'
local Crew = require 'maps.pirates.crew'
local Roles = require 'maps.pirates.roles.roles'
local Structures = require 'maps.pirates.structures.structures'
local Boats = require 'maps.pirates.structures.boats.boats'
local Surfaces = require 'maps.pirates.surfaces.surfaces'
local Overworld = require 'maps.pirates.overworld'
local Islands = require 'maps.pirates.surfaces.islands.islands'
local Progression = require 'maps.pirates.progression'
local Crowsnest = require 'maps.pirates.surfaces.crowsnest'
local Hold = require 'maps.pirates.surfaces.hold'
local Interface = require 'maps.pirates.interface'
local Upgrades = require 'maps.pirates.boat_upgrades'
local Effects = require 'maps.pirates.effects'
local Kraken = require 'maps.pirates.surfaces.sea.kraken'
local inspect = require 'utils.inspect'.inspect
local simplex_noise = require 'utils.simplex_noise'.d2
local Token = require 'utils.token'
local Task = require 'utils.task'
local Highscore = require 'maps.pirates.highscore'

local GUIcolor = require 'maps.pirates.gui.color'

commands.add_command(
'ok',
'Used to accept captainhood.',
function(cmd)
			local player = game.players[cmd.player_index]
	if not Common.validate_player(player) then return end
	local crew_id = tonumber(string.sub(game.players[cmd.player_index].force.name, -3, -1)) or nil
	Memory.set_working_id(crew_id)
	local memory = Memory.get_crew_memory()
	Roles.try_accept_captainhood(player)
end)

-- Disabled for information-flow reasons:
-- commands.add_command(
-- 'classes',
-- 'Prints the available classes in the game.',
-- function(cmd)
-- 	local player = game.players[cmd.player_index]
-- 	if not Common.validate_player(player) then return end
-- 	player.print('[color=gray]' .. Roles.get_classes_print_string() .. '[/color]')
-- end)

commands.add_command(
'class',
'/class [classname] returns the definition of the named class.',
function(cmd)
	local param = tostring(cmd.parameter)
	local player = game.players[cmd.player_index]
	if not Common.validate_player(player) then return end

	if param and param ~= 'nil' then
		local string = Roles.get_class_print_string(param)
		if string then
			Common.notify_player_expected(player, 'Class definition for ' .. string)
		else
			Common.notify_player_error(player, 'Class \'' .. param .. '\' not found.')
		end
	else
		Common.notify_player_expected(player, '/class {classname} returns the definition of the named class.')
	end
end)

commands.add_command(
'ccolor',
'ccolor is an extension to the built-in /color command, with more colors.',
function(cmd)
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
					local message = '[color=' .. rgb.r .. ',' .. rgb.g .. ',' .. rgb.b .. ']' .. player.name .. '\'s color is now ' .. param .. '[/color] (via /ccolor).'
					Common.notify_game(message)
				else
					Common.notify_player_error(player, 'Color \'' .. param .. '\' not found.')
				end
			else
				local color = PlayerColors.names[Math.random(#PlayerColors.names)]
				local rgb = PlayerColors.colors[color]
				if not rgb then return end
				player.color = rgb
				player.chat_color = rgb
				local message = '[color=' .. rgb.r .. ',' .. rgb.g .. ',' .. rgb.b .. ']' .. player.name .. '\'s color was randomized to ' .. color .. '[/color] (via /ccolor).'
				Common.notify_game(message)
				-- disabled due to lag:
				-- GUIcolor.toggle_window(player)
			end
		end
	end
end)




local go_2 = Token.register(
	function(data)
		Memory.set_working_id(1)
		local memory = Memory.get_crew_memory()
		
		memory.mapbeingloadeddestination_index = 1
		memory.loadingticks = 0
		Progression.go_from_starting_dock_to_first_destination()
	end
)
local go_1 = Token.register(
	function(data)
		Memory.set_working_id(1)
		local memory = Memory.get_crew_memory()
		Overworld.ensure_lane_generated_up_to(0, Crowsnest.Data.visibilitywidth/2)
		Overworld.ensure_lane_generated_up_to(24, Crowsnest.Data.visibilitywidth/2)
		Overworld.ensure_lane_generated_up_to(-24, Crowsnest.Data.visibilitywidth/2)
		memory.currentdestination_index = 1
		Surfaces.create_surface(Common.current_destination())
		Task.set_timeout_in_ticks(60, go_2, {})
	end
)




local function check_admin(cmd)
	local Session = require 'utils.datastore.session_data'
			local player = game.players[cmd.player_index]
	local trusted = Session.get_trusted_table()
	local p
	if player then
		if player ~= nil then
			p = player.print
			if not player.admin then
				p('[ERROR] Only admins and trusted weebs are allowed to run this command!', Color.fail)
				return false
			end
		else
			p = log
		end
	end
	return true
end


local function check_trusted(cmd)
	local Session = require 'utils.datastore.session_data'
			local player = game.players[cmd.player_index]
	local trusted = Session.get_trusted_table()
	local p
	if player then
		if player ~= nil then
			p = player.print
			if not (trusted[player.name] or player.admin) then
				p('[ERROR] Only admins and trusted weebs are allowed to run this command!', Color.fail)
				return false
			end
		else
			p = log
		end
	end
	return true
end


commands.add_command(
'setcaptain',
'setcaptain',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
		Memory.set_working_id(crew_id)
		local memory = Memory.get_crew_memory()
		if param and game.players[param] and game.players[param].index then
			Roles.make_captain(game.players[param])
		else
			player.print('Invalid player name.')
		end
	end
end)


commands.add_command(
'chnk',
'genchunk',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
		Memory.set_working_id(crew_id)
		local memory = Memory.get_crew_memory()

		for i = 0, 13 do
			for j = 0, 13 do
				Interface.event_on_chunk_generated({surface = player.surface, area = {left_top = {x = -7 * 32 + i * 32, y = -7 * 32 + j * 32}}})
			end
		end
		game.print('chunks generated')
	end
end)

commands.add_command(
'modi',
'setmodifiable',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
		Memory.set_working_id(crew_id)
		local memory = Memory.get_crew_memory()
		local surface = game.surfaces[Common.current_destination().surface_name]
		local entities = surface.find_entities_filtered{position = player.position, radius = 500}
		for _, e in pairs(entities) do
			if e and e.valid then
				-- e.force = game.forces[memory.force_name]
				e.minable = true
				e.destructible = true
				e.rotatable = true
			end
		end
		player.print('nearby entities made modifiable')
	end
end)

commands.add_command(
'spd',
'speed',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
		Memory.set_working_id(crew_id)
		local memory = Memory.get_crew_memory()
		memory.boat.speed = 60
	end
end)

commands.add_command(
'stp',
'stop',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
		Memory.set_working_id(crew_id)
		local memory = Memory.get_crew_memory()
		memory.boat.speed = 0
	end
end)

commands.add_command(
'ret',
'retreat',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
		Memory.set_working_id(crew_id)
		Progression.retreat_from_island()
	end
end)

commands.add_command(
'jump',
'jump',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
		Memory.set_working_id(crew_id)
		Overworld.try_overworld_move_v2({x = 40*10, y = 0})
	end
end)

commands.add_command(
'advu',
'advanceup',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
		Memory.set_working_id(crew_id)
		Overworld.try_overworld_move_v2{x = 0, y = -24}
	end
end)

commands.add_command(
'advd',
'advancedown',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
		Memory.set_working_id(crew_id)
		Overworld.try_overworld_move_v2{x = 0, y = 24}
	end
end)

commands.add_command(
'rms',
'rms',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local rms = 0
		local n = 100000
		local seed = Math.random(n^2)
		for i = 1,n do
			local noise = simplex_noise(i, 7.11, seed)
			rms = rms + noise^2
		end
		rms = rms/n
		game.print(rms)
	end
end)

commands.add_command(
'pro',
'pro',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local global_memory = Memory.get_global_memory()

		local proposal = {
			capacity_option = 3,
			difficulty_option = 2,
			-- mode_option = 'left',
			endorserindices = { 2 },
			name = "TestRun"
		}

		global_memory.crewproposals[#global_memory.crewproposals + 1] = proposal

	end
end)

commands.add_command(
'go',
'go',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]

		local proposal = {
			capacity_option = 3,
			difficulty_option = 2,
			-- mode_option = 'left',
			endorserindices = { 1 },
			name = "AdminRun"
		}

		Memory.set_working_id(1)

		Crew.initialise_crew(proposal)
		Crew.initialise_crowsnest() --contains a Task

		local memory = Memory.get_crew_memory()
		local boat = Utils.deepcopy(Surfaces.Lobby.StartingBoats[memory.id])
		
		for _, p in pairs(game.connected_players) do
			p.teleport({x = -30, y = boat.position.y}, game.surfaces[boat.surface_name])
		end

		Progression.set_off_from_starting_dock()

		-- local memory = Memory.get_crew_memory()
		-- local boat = Utils.deepcopy(Surfaces.Lobby.StartingBoats[memory.id])
		-- memory.boat = boat
		-- boat.dockedposition = boat.position
		-- boat.decksteeringchests = {}
		-- boat.crowsneststeeringchests = {}

		Task.set_timeout_in_ticks(120, go_1, {})
	end
end)

commands.add_command(
'lev',
'lev',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		Memory.set_working_id(1)
		local memory = Memory.get_crew_memory()
		Progression.go_from_currentdestination_to_sea()
	end
end)

commands.add_command(
'hld',
'hld',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		Memory.set_working_id(1)
		local memory = Memory.get_crew_memory()
		Upgrades.execute_upgade(Upgrades.enum.EXTRA_HOLD)
	end
end)

commands.add_command(
'pwr',
'pwr',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		Memory.set_working_id(1)
		local memory = Memory.get_crew_memory()
		Upgrades.execute_upgade(Upgrades.enum.MORE_POWER)
	end
end)




commands.add_command(
'maxcrews3',
'maxcrews3',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local global_memory = Memory.get_global_memory()

		global_memory.active_crews_cap = 3
	end
end)

commands.add_command(
'maxcrews2',
'maxcrews2',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local global_memory = Memory.get_global_memory()

		global_memory.active_crews_cap = 2
	end
end)

commands.add_command(
'maxcrews1',
'maxcrews1',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local global_memory = Memory.get_global_memory()

		global_memory.active_crews_cap = 1
	end
end)

commands.add_command(
'mincapacitysetting3',
'mincapacitysetting3',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local global_memory = Memory.get_global_memory()

		global_memory.minimum_capacity_slider_value = 3
	end
end)

commands.add_command(
'mincapacitysetting2',
'mincapacitysetting2',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local global_memory = Memory.get_global_memory()

		global_memory.minimum_capacity_slider_value = 2
	end
end)

commands.add_command(
'mincapacitysetting1',
'mincapacitysetting1',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local global_memory = Memory.get_global_memory()

		global_memory.minimum_capacity_slider_value = 1
	end
end)

commands.add_command(
'score',
'score',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
		Memory.set_working_id(crew_id)
		local memory = Memory.get_crew_memory()
		
		game.print('faking a highscore...')
		Highscore.write_score(memory.secs_id, 'fakers', 0, 40, CoreData.version_float, 1, 8)
	end
end)

commands.add_command(
'scrget',
'scrget',
function(cmd)
	local param = tostring(cmd.parameter)
	if check_admin(cmd) then
		local player = game.players[cmd.player_index]
		game.print('running Highscore.load_in_scores()')
		Highscore.load_in_scores()
	end
end)







if _DEBUG then

	commands.add_command(
	'tim',
	'tim',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			Memory.set_working_id(1)
			local memory = Memory.get_crew_memory()
			Common.current_destination().dynamic_data.timer = 88
			game.print('time set to 88 seconds')
		end
	end)

	commands.add_command(
	'gld',
	'gld',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			Memory.set_working_id(1)
			local memory = Memory.get_crew_memory()
			memory.stored_fuel = memory.stored_fuel + 20000
		end
	end)
	
	commands.add_command(
	'bld',
	'bld',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			Memory.set_working_id(1)
			local memory = Memory.get_crew_memory()
			memory.classes_table = {[1] = 1}
		end
	end)
	
	commands.add_command(
	'rad',
	'rad',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			Memory.set_working_id(1)
			local memory = Memory.get_crew_memory()
			Islands.spawn_enemy_boat(Boats.enum.RAFT)
			local boat = memory.enemyboats[1]
			Ai.spawn_boat_biters(boat, 0.89)
			game.print('enemy boat spawned')
		end
	end)

	commands.add_command(
	'krk',
	'krk',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			Memory.set_working_id(1)
			local memory = Memory.get_crew_memory()
			Kraken.try_spawn_kraken()
		end
	end)

	commands.add_command(
	'1',
	'1',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			game.speed = 1
		end
	end)
	
	commands.add_command(
	'4',
	'4',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			game.speed = 4
		end
	end)
	
	commands.add_command(
	'8',
	'8',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			game.speed = 8
		end
	end)
	
	commands.add_command(
	'16',
	'16',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			game.speed = 16
		end
	end)
	
	commands.add_command(
	'32',
	'32',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			game.speed = 32
		end
	end)
	
	commands.add_command(
	'64',
	'64',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			game.speed = 64
		end
	end)
	
	commands.add_command(
	'ef1',
	'ef1',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
			Memory.set_working_id(crew_id)
			local memory = Memory.get_crew_memory()
			local surface = game.surfaces[Common.current_destination().surface_name]
			Effects.worm_movement_effect(surface, {x = -45, y = 0}, false, true)
		end
	end)
	
	commands.add_command(
	'ef2',
	'ef2',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
			Memory.set_working_id(crew_id)
			local memory = Memory.get_crew_memory()
			local surface = game.surfaces[Common.current_destination().surface_name]
			Effects.worm_movement_effect(surface, {x = -45, y = 0}, false, false)
		end
	end)
	
	commands.add_command(
	'ef3',
	'ef3',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
			Memory.set_working_id(crew_id)
			local memory = Memory.get_crew_memory()
			local surface = game.surfaces[Common.current_destination().surface_name]
			Effects.worm_movement_effect(surface, {x = -45, y = 0}, true, false)
		end
	end)
	
	commands.add_command(
	'ef4',
	'ef4',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
			Memory.set_working_id(crew_id)
			local memory = Memory.get_crew_memory()
			local surface = game.surfaces[Common.current_destination().surface_name]
			Effects.worm_emerge_effect(surface, {x = -45, y = 0})
		end
	end)
	
	commands.add_command(
	'ef5',
	'ef5',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			local crew_id = tonumber(string.sub(player.force.name, -3, -1)) or nil
			Memory.set_working_id(crew_id)
			local memory = Memory.get_crew_memory()
			local surface = game.surfaces[Common.current_destination().surface_name]
			Effects.biters_emerge(surface, {x = -30, y = 0})
		end
	end)
	
	commands.add_command(
	'emoji',
	'emoji',
	function(cmd)
		local param = tostring(cmd.parameter)
		if check_admin(cmd) then
		local player = game.players[cmd.player_index]
			Server.to_discord_embed_raw(CoreData.comfy_emojis.monkas)
		end
	end)
end