--luacheck: ignore
--[[
Journey, launch a rocket in increasingly harder getting worlds. - MewMew
]] --

require 'modules.rocket_launch_always_yields_science'

local Server = require 'utils.server'
local Constants = require 'maps.journey.constants'
local Functions = require 'maps.journey.functions'
local Unique_modifiers = require 'maps.journey.unique_modifiers'
local Map = require 'modules.map_info'
local Global = require 'utils.global'
local ClearVacantPlayers = require 'modules.clear_vacant_players'

local journey = {}
Global.register(
    journey,
    function(tbl)
        journey = tbl
    end
)
-- Init and share within Journey the module ClearVacantPlayers.
if ClearVacantPlayers then
    local base_surface_id = 1 -- sending "Nauvis" also works.
    local surfaces_to_ignore = { "mothership" }
    ClearVacantPlayers.init(base_surface_id, surfaces_to_ignore)
    ClearVacantPlayers.set_enabled(true)

    journey.clear_vacant_players = ClearVacantPlayers
end

local function on_chunk_generated(event)
    local surface = event.surface

    if surface.index == 1 then
        Functions.place_mixed_ore(event, journey)
        local unique_modifier = Unique_modifiers[journey.world_trait]
        if unique_modifier.on_chunk_generated then unique_modifier.on_chunk_generated(event, journey) end
        return
    end

    if surface.name ~= "mothership" then return end
    Functions.on_mothership_chunk_generated(event)
end

local function on_console_chat(event)
    if not event.player_index then return end
    local player = game.players[event.player_index]
    local message = event.message
    message = string.lower(message)
    local a, b = string.find(message, "?", 1, true)
    if not a then return end
    local a, b = string.find(message, "mother", 1, true)
    if not a then return end
    local answer = Constants.mothership_messages.answers[math.random(1, #Constants.mothership_messages.answers)]
    if math.random(1, 4) == 1 then
        for _ = 1, math.random(2, 5), 1 do table.insert(journey.mothership_messages, "") end
        table.insert(journey.mothership_messages, "...")
    end
    for _ = 1, math.random(15, 30), 1 do table.insert(journey.mothership_messages, "") end
    table.insert(journey.mothership_messages, answer)
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    Functions.draw_gui(journey)

    if player.surface.name == "mothership" then
        journey.characters_in_mothership = journey.characters_in_mothership + 1
    end

    if player.force.name == "enemy" then
        Functions.clear_player(player)
        player.force = game.forces.player
        local position = game.surfaces.nauvis.find_non_colliding_position("character", { 0, 0 }, 32, 0.5)
        if position then
            player.teleport(position, game.surfaces.nauvis)
        else
            player.teleport({ 0, 0 }, game.surfaces.nauvis)
        end
    end
end

local function on_player_left_game(event)
    local player = game.players[event.player_index]
    Functions.draw_gui(journey)

    if player.surface.name == "mothership" then
        journey.characters_in_mothership = journey.characters_in_mothership - 1
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
            if slot.name == "uranium-fuel-cell" then
                Server.to_discord_embed("Refueling progress: " ..
                    journey.mothership_cargo[slot.name] .. "/" .. journey.mothership_cargo_space[slot.name])
            end
        end
    end
    Functions.draw_gui(journey)
end

local function on_nth_tick()
    Functions[journey.game_state](journey)
    Functions.mothership_message_queue(journey)
end

local function on_init()
    local T = Map.Pop_info()
    T.localised_category = 'journey'
    T.main_caption_color = { r = 100, g = 20, b = 255 }
    T.sub_caption_color = { r = 100, g = 100, b = 100 }

    game.permissions.get_group('Default').set_allows_action(defines.input_action.set_auto_launch_rocket, false)

    Functions.hard_reset(journey)
end

commands.add_command(
    'reset-journey',
    'Fully resets the journey map.',
    function()
        local player = game.player
        if not (player and player.valid) then
            return
        end
        if not player.admin then
            player.print("You are not an admin!")
            return
        end
        Functions.hard_reset(journey)
        game.print(player.name .. " has reset the map.")
    end
)

commands.add_command(
    'skip-world',
    'Instantly wins and skips the current world.',
    function()
        local player = game.player
        if not (player and player.valid) then
            return
        end
        if not player.admin then
            player.print("You are not an admin!")
            return
        end
        if journey.game_state ~= "dispatch_goods" and journey.game_state ~= "world" then return end
        journey.game_state = "set_world_selectors"
    end
)

local Event = require 'utils.event'
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
Event.add(defines.events.on_console_chat, on_console_chat)
