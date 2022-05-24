local Public = {}

local FFATable = require 'modules.scrap_towny_ffa.ffa_table'
local Team = require 'modules.scrap_towny_ffa.team'
local Spawn = require 'modules.scrap_towny_ffa.spawn'
local Info = require 'modules.scrap_towny_ffa.info'

-- how long in ticks between spawn and death will be considered spawn kill (10 seconds)
local max_ticks_between_spawns = 60 * 10

-- how many players must login before teams are teams_enabled
local min_players_for_enabling_towns = 0

function Public.settings(player)
	player.game_view_settings.show_minimap = false
	player.game_view_settings.show_map_view_options = false
	player.game_view_settings.show_entity_info = true
	player.map_view_settings = {
		['show-logistic-network'] = false,
		['show-electric-network'] = false,
		['show-turret-range'] = false,
		['show-pollution'] = false,
		['show-train-station-names'] = false,
		['show-player-names'] = false,
		['show-networkless-logistic-members'] = false,
		['show-non-standard-map-info'] = false
	}
	player.show_on_map = false
	--player.game_view_settings.show_side_menu = false
end

function Public.initialize(player)
	player.teleport({0, 0}, game.surfaces['limbo'])
	Team.set_player_to_outlander(player)
	Team.give_player_items(player)
	player.insert {name = 'coin', count = '100'}
	player.insert {name = 'stone-furnace', count = '1'}
	Team.give_key(player.index)
	local ffatable = FFATable.get_table()
	if (ffatable.testing_mode == true) then
		player.cheat_mode = true
		player.force.research_all_technologies()
		player.insert {name = 'coin', count = '9900'}
	end
end

function Public.spawn(player)
	-- first time spawn point
	local surface = game.surfaces['nauvis']
	local spawn_point = Spawn.get_new_spawn_point(player, surface)
	local ffatable = FFATable.get_table()
	ffatable.strikes[player.name] = 0
	Spawn.clear_spawn_point(spawn_point, surface)
	-- reset cooldown
	ffatable.cooldowns_town_placement[player.index] = 0
	ffatable.last_respawn[player.name] = 0
	player.teleport(spawn_point, surface)
end

function Public.load_buffs(player)
	if player.force.name ~= 'player' and player.force.name ~= 'rogue' then
		return
	end
	local ffatable = FFATable.get_table()
	local player_index = player.index
	if player.character == nil then
		return
	end
	if ffatable.buffs[player_index] == nil then
		ffatable.buffs[player_index] = {}
	end
	if ffatable.buffs[player_index].character_inventory_slots_bonus ~= nil then
		player.character.character_inventory_slots_bonus = ffatable.buffs[player_index].character_inventory_slots_bonus
	end
	if ffatable.buffs[player_index].character_mining_speed_modifier ~= nil then
		player.character.character_mining_speed_modifier = ffatable.buffs[player_index].character_mining_speed_modifier
	end
	if ffatable.buffs[player_index].character_crafting_speed_modifier ~= nil then
		player.character.character_crafting_speed_modifier = ffatable.buffs[player_index].character_crafting_speed_modifier
	end
end

function Public.requests(player)
	local ffatable = FFATable.get_table()
	if ffatable.requests[player.index] and ffatable.requests[player.index] == 'kill-character' then
		if player.character then
			if player.character.valid then
				player.character.die()
			end
		end
		ffatable.requests[player.index] = nil
	end
end

function Public.increment()
	local ffatable = FFATable.get_table()
	local count = ffatable.players + 1
	ffatable.players = count
	if ffatable.testing_mode then
		ffatable.towns_enabled = true
	else
		if ffatable.players >= min_players_for_enabling_towns then
			ffatable.towns_enabled = true
		end
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	Public.settings(player)
	Info.toggle_button(player)
	Team.set_player_color(player)
	if player.online_time == 0 then
		Public.increment()
		Public.initialize(player)
		Public.spawn(player)
		Info.show(player)
	end
	Public.load_buffs(player)
	Public.requests(player)
end

local function on_player_respawned(event)
	local ffatable = FFATable.get_table()
	local player = game.players[event.player_index]
	local surface = player.surface
	Team.give_player_items(player)
	if player.force == game.forces['rogue'] then
		Team.set_player_to_outlander(player)
	end
	if player.force == game.forces['player'] then
		Team.give_key(player.index)
	end

	-- get_spawn_point will always return a valid spawn
	local spawn_point = Spawn.get_spawn_point(player, surface)

	-- reset cooldown
	ffatable.last_respawn[player.name] = game.tick
	player.teleport(spawn_point, surface)
	Public.load_buffs(player)
end

local function on_player_died(event)
	local ffatable = FFATable.get_table()
	local player = game.players[event.player_index]
	if ffatable.strikes[player.name] == nil then
		ffatable.strikes[player.name] = 0
	end

	local ticks_elapsed = game.tick - ffatable.last_respawn[player.name]
	if ticks_elapsed < max_ticks_between_spawns then
		ffatable.strikes[player.name] = ffatable.strikes[player.name] + 1
	else
		ffatable.strikes[player.name] = 0
	end
end

local Event = require 'utils.event'
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_died, on_player_died)

return Public
