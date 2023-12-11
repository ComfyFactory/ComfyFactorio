--[[
Journey, launch a rocket in increasingly harder getting worlds. - MewMew
]]--

require 'modules.rocket_launch_always_yields_science'

local Server = require 'utils.server'
local Constants = require 'maps.journey.constants'
local Functions = require 'maps.journey.functions'
local Unique_modifiers = require 'maps.journey.unique_modifiers'
local Map = require 'modules.map_info'
local Global = require 'utils.global'
local Token = require 'utils.token'
local Event = require 'utils.event'
local Vacants = require 'modules.clear_vacant_players'

local journey = {
	announce_capsules = true
}

local events = {
	import = Event.generate_event_name('import'),
	check_import = Event.generate_event_name('check_import'),
}

Global.register(
    journey,
    function(tbl)
        journey = tbl
    end
)

journey.import = Token.register(
	function(data)
		if not data then
            return
        end
		script.raise_event(events.import, data)
	end
)

journey.check_import = Token.register(
	function(data)
		if not data then
            return
        end
		script.raise_event(events.check_import, data)
	end
)

local function on_chunk_generated(event)
	local surface = event.surface

	if surface.index == 1 then
		Functions.place_mixed_ore(event, journey)
		local unique_modifier = Unique_modifiers[journey.world_trait]
		if unique_modifier.on_chunk_generated then unique_modifier.on_chunk_generated(event, journey) end
		return
	end

	if surface.name ~= 'mothership' then return end
	Functions.on_mothership_chunk_generated(event)
end

local function on_console_chat(event)
    if not event.player_index then return end
    local message = event.message
    message = string.lower(message)
	local a = string.find(message, '?', 1, true)
    if not a then return end
	local b = string.find(message, 'mother', 1, true)
    if not b then return end
	local answer = Constants.mothership_messages.answers[math.random(1, #Constants.mothership_messages.answers)]
	if math.random(1, 4) == 1 then
		for _ = 1, math.random(2, 5), 1 do table.insert(journey.mothership_messages, '') end
		table.insert(journey.mothership_messages, '...')
	end
	for _ = 1, math.random(15, 30), 1 do table.insert(journey.mothership_messages, '') end
	table.insert(journey.mothership_messages, answer)
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
	Functions.draw_gui(journey)
	Functions.set_minimum_to_vote(journey)

	if player.surface.name == 'mothership' then
		journey.characters_in_mothership = journey.characters_in_mothership + 1
	end

	if player.force.name == 'enemy' then
		Functions.clear_player(player)
		player.force = game.forces.player
		local position = game.surfaces.nauvis.find_non_colliding_position('character', {0,0}, 32, 0.5)
		if position then
			player.teleport(position, game.surfaces.nauvis)
		else
			player.teleport({0,0}, game.surfaces.nauvis)
		end
	end
end

local function on_player_left_game(event)
    local player = game.players[event.player_index]
	Functions.draw_gui(journey)

	if player.surface.name == 'mothership' then
		journey.characters_in_mothership = journey.characters_in_mothership - 1
        player.clear_items_inside()
	end
end

local function on_player_changed_position(event)
    local player = game.players[event.player_index]
    Functions.teleporters(journey, player)
	local unique_modifier = Unique_modifiers[journey.world_trait]
	if unique_modifier.on_player_changed_position then unique_modifier.on_player_changed_position(event) end
end

local function on_built_entity(event)
    Functions.deny_building(event)
	Functions.register_built_silo(event, journey)
	local unique_modifier = Unique_modifiers[journey.world_trait]
	if unique_modifier.on_built_entity then unique_modifier.on_built_entity(event, journey) end
end

local function on_robot_built_entity(event)
    Functions.deny_building(event)
	Functions.register_built_silo(event, journey)
	local unique_modifier = Unique_modifiers[journey.world_trait]
	if unique_modifier.on_robot_built_entity then unique_modifier.on_robot_built_entity(event, journey) end
end

local function on_player_mined_entity(event)
    local unique_modifier = Unique_modifiers[journey.world_trait]
	if unique_modifier.on_player_mined_entity then unique_modifier.on_player_mined_entity(event, journey) end
end

local function on_robot_mined_entity(event)
    local unique_modifier = Unique_modifiers[journey.world_trait]
	if unique_modifier.on_robot_mined_entity then unique_modifier.on_robot_mined_entity(event, journey) end
end

local function on_research_finished(event)
	local unique_modifier = Unique_modifiers[journey.world_trait]
	if unique_modifier.on_research_finished then
		unique_modifier.on_research_finished(event, journey)
		Functions.update_tooltips(journey)
		Functions.draw_gui(journey)
	end
end

local function on_entity_damaged(event)
	local entity = event.entity
	if not entity or not entity.valid then return end
	if entity ~= journey.beacon_objective then return end
	if event.force and event.force.name == 'enemy' then
		Functions.deal_damage_to_beacon(journey, event.final_damage_amount)
	end
	entity.health = 200
end

local function on_entity_died(event)
    local unique_modifier = Unique_modifiers[journey.world_trait]
	if unique_modifier.on_entity_died then unique_modifier.on_entity_died(event, journey) end
end

local function on_rocket_launched(event)
	local rocket_inventory = event.rocket.get_inventory(defines.inventory.rocket)
	local slot = rocket_inventory[1]
	if slot and slot.valid and slot.valid_for_read then
		if journey.mothership_cargo[slot.name] then
			journey.mothership_cargo[slot.name] = journey.mothership_cargo[slot.name] + slot.count
		else
			journey.mothership_cargo[slot.name] = slot.count
		end
		if journey.mothership_cargo_space[slot.name] then
			if journey.mothership_cargo[slot.name] > journey.mothership_cargo_space[slot.name] then
				journey.mothership_cargo[slot.name] = journey.mothership_cargo_space[slot.name]
			end
			if slot.name == 'uranium-fuel-cell' or slot.name == 'nuclear-reactor' then
				Server.to_discord_embed('Refueling progress: ' .. slot.name .. ': ' .. journey.mothership_cargo[slot.name] .. '/' .. journey.mothership_cargo_space[slot.name])
			elseif journey.speedrun.enabled and slot.name == journey.speedrun.item then
                Server.to_discord_embed('Orbital Station delivery: ' .. slot.name .. ': ' .. journey.mothership_cargo[slot.name] .. '/' .. journey.mothership_cargo_space[slot.name])
            end
		end
	end
	Functions.draw_gui(journey)
end

local function make_import(data)
	if not data then
		return
	end

	if data.key ~= 'journey_data' then
		return
	end
	local old_selectors = journey.world_selectors
	for key, value in pairs(data.value) do
		journey[key] = value
	end
	for k, selector in pairs(old_selectors) do
		journey.world_selectors[k].border = selector.border
		journey.world_selectors[k].texts = selector.texts
		journey.world_selectors[k].rectangles = selector.rectangles
	end
	journey.importing = true
	game.print('Journey data imported.')
	journey.game_state = 'importing_world'
end

local function check_import(data)
	if not data then
		return
	end
	if data.key ~= 'journey_updating' then
		return
	end
	journey.import_checked = true
	local importing = data.value
	if importing then
		Functions.import_journey(journey)
	end
end

local function on_nth_tick()
	Functions[journey.game_state](journey)
	Functions.mothership_message_queue(journey)
	local tick = game.tick

	if tick % 3600 == 0 then
		Functions.lure_far_biters(journey)
	elseif tick % 600 == 0 then
		Functions.lure_biters(journey)
	end
end

local function on_init()
    local T = Map.Pop_info()
    T.localised_category = 'journey'
    T.main_caption_color = {r = 100, g = 20, b = 255}
    T.sub_caption_color = {r = 100, g = 100, b = 100}

	game.permissions.get_group('Default').set_allows_action(defines.input_action.set_auto_launch_rocket, false)
    Vacants.init(1, true)
	Functions.hard_reset(journey)
end

local function cmd_handler()
	local player = game.player
	local p
	if not (player and player.valid) then
		p = log
	else
		p = player.print
	end
	if player and not player.admin then
		p('You are not an admin!')
		return false
	end
	return true, player or {name = 'Server'}, p
end

commands.add_command(
    'journey-reset',
    'Fully resets the journey map.',
    function()
		local s, player = cmd_handler()
		if s then
			Functions.hard_reset(journey)
			game.print(player.name .. ' has reset the map.')
		end
	end
)

commands.add_command(
    'journey-skip-world',
    'Instantly wins and skips the current world.',
    function()
		local s, _, p = cmd_handler()
		if s then
			if journey.game_state ~= 'dispatch_goods' and journey.game_state ~= 'world' then return end
			journey.game_state = 'set_world_selectors'
			p('The current world was skipped...')
		end
	end
)

commands.add_command(
	'journey-update',
	'Restarts the server with newest version of Journey scenario code during next map reset',
	function()
		local s, _, p = cmd_handler()
		if s then
			journey.restart_from_scenario = not journey.restart_from_scenario
			p('Journey marking for full restart with updates on next reset was switched to ' .. tostring(journey.restart_from_scenario))
		end
	end
)

commands.add_command(
	'journey-update-now',
	'Restarts the server with newest version of Journey scenario code right now. Only doable during map selection.',
	function()
		local s, _, p = cmd_handler()
		if s then
			Functions.restart_server(journey)
			p('Journey is restarting to apply changes...')
		end
	end
)

commands.add_command(
	'journey-import',
	'Sets the journey gamestate to the last exported one.',
	function()
		local s, _, p = cmd_handler()
		if s then
			Functions.import_journey(journey)
			p('Journey world settings importing...')
		end
	end
)

commands.add_command(
	'journey-export',
	'Exports the journey gamestate to the server',
	function()
		local s, _, p = cmd_handler()
		if s then
			Functions.export_journey(journey, journey.restart_from_scenario)
			p('Journey world settings exporting...')
		end
	end
)

Event.on_init(on_init)
Event.on_nth_tick(10, on_nth_tick)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_left_game, on_player_left_game)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_rocket_launched, on_rocket_launched)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_mined_entity, on_robot_mined_entity)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_console_chat, on_console_chat)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(events['import'], make_import)
Event.add(events['check_import'], check_import)
