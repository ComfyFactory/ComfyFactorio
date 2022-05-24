local table_insert = table.insert

local Server = require 'utils.server'
local Alert = require 'utils.alert'
local FFATable = require 'modules.scrap_towny_ffa.ffa_table'
local Nauvis = require 'modules.scrap_towny_ffa.nauvis'
local Team = require 'modules.scrap_towny_ffa.team'
local Player = require 'modules.scrap_towny_ffa.player'
local Color = require 'utils.color_presets'

-- game duration in ticks
-- 7d * 24h * 60m * 60s * 60t
-- local game_duration = 36288000
local game_duration = 36288000
local armageddon_duration = 3600
local warning_duration = 600

local function on_rocket_launched(event)
	local ffatable = FFATable.get_table()
	local rocket = event.rocket
	local tick = event.tick
	local force_index = rocket.force.index
	table_insert(ffatable.rocket_launches, {force_index = force_index, tick = tick})
end

local function get_victorious_force()
	local ffatable = FFATable.get_table()
	if ffatable.rocket_launches then
		for _, launch in pairs(ffatable.rocket_launches) do
			local force = game.forces[launch.force_index]
			if force.valid then
				return force.name
			end
		end
	end
	return nil
end

local function warning()
	Alert.alert_all_players(5, 'The world is ending!', Color.white, 'warning-white', 1.0)
end

local function armageddon()
	if not get_victorious_force() then
		Nauvis.armageddon()
	end
end

local function reset_map()
	local surface = game.surfaces['nauvis']
	if get_victorious_force() then
		surface.play_sound({path = 'utility/game_won', volume_modifier = 1})
	else
		surface.play_sound({path = 'utility/game_lost', volume_modifier = 1})
	end
	game.reset_time_played()
	game.reset_game_state()
	for _, player in pairs(game.players) do
		player.teleport({0, 0}, game.surfaces['limbo'])
	end
	Nauvis.initialize()
	Team.initialize()
	if game.forces['rogue'] == nil then
		log('rogue force is missing!')
	end
	for _, player in pairs(game.players) do
		Player.increment()
		Player.initialize(player)
		Team.set_player_color(player)
		Player.spawn(player)
		Player.load_buffs(player)
		Player.requests(player)
	end
end

local function on_tick()
	local tick = game.tick
	if tick > 0 then
		if (tick + armageddon_duration + warning_duration) % game_duration == 0 then
			warning()
		end
		if (tick + armageddon_duration) % game_duration == 0 then
			armageddon()
		end
		if (tick + 1) % game_duration == 0 then
			Nauvis.clear_nuke_schedule()
			Team.reset_all_forces()
		end
		if tick % game_duration == 0 then
			reset_map()
			Alert.alert_all_players(5, 'The world has been reset!', Color.white, 'restart_required', 1.0)
			Server.to_discord_embed('ScrapTowny FFA map has been reset!')
		end
	end
end

commands.add_command(
		'resetmap',
		'Resets the map..',
		function()
			local player = game.player
			if not (player and player.valid) then
				return
			end

			local p = player.print
			if not player.admin then
				p("[ERROR] You're not admin!", Color.fail)
				return
			end
			reset_map()
		end
)

local Event = require 'utils.event'
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_rocket_launched, on_rocket_launched)