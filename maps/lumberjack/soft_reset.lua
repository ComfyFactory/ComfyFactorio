local Server = require 'utils.server'
local Modifers = require 'player_modifiers'
local WPT = require 'maps.lumberjack.table'

local grandmaster = '[color=blue]Grandmaster:[/color]'

local Public = {}

local function reset_forces(new_surface, old_surface)
    for _, f in pairs(game.forces) do
        local spawn = {
            x = game.forces.player.get_spawn_position(old_surface).x,
            y = game.forces.player.get_spawn_position(old_surface).y
        }
        f.reset()
        f.reset_evolution()
        f.set_spawn_position(spawn, new_surface)
    end
    for _, tech in pairs(game.forces.player.technologies) do
        tech.researched = false
        game.forces.player.set_saved_technology_progress(tech, 0)
    end
end

local function teleport_players(surface)
    game.forces.player.set_spawn_position({0, 21}, surface)

    for _, player in pairs(game.connected_players) do
        player.teleport(
            surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5),
            surface
        )
    end
end

local function equip_players(player_starting_items)
    for k, player in pairs(game.connected_players) do
        if player.character then
            player.character.destroy()
        end
        player.character = nil
        player.set_controller({type = defines.controllers.god})
        player.create_character()
        for item, amount in pairs(player_starting_items) do
            player.insert({name = item, count = amount})
        end
        Modifers.update_player_modifiers(player)
    end
end

function Public.soft_reset_map(old_surface, map_gen_settings, player_starting_items)
    local this = WPT.get_table()

    if not this.soft_reset_counter then
        this.soft_reset_counter = 0
    end
    if not this.original_surface_name then
        this.original_surface_name = old_surface.name
    end
    this.soft_reset_counter = this.soft_reset_counter + 1

    local new_surface =
        game.create_surface(this.original_surface_name .. '_' .. tostring(this.soft_reset_counter), map_gen_settings)
    new_surface.request_to_generate_chunks({0, 0}, 0.5)
    new_surface.force_generate_chunk_requests()

    reset_forces(new_surface, old_surface)
    teleport_players(new_surface)
    equip_players(player_starting_items)

    game.delete_surface(old_surface)

    local message = table.concat({grandmaster .. ' Welcome to ', this.original_surface_name, '!'})
    local message_to_discord = table.concat({'** Welcome to ', this.original_surface_name, '! **'})

    if this.soft_reset_counter > 1 then
        message =
            table.concat(
            {
                grandmaster,
                ' The world has been reshaped, welcome to ',
                this.original_surface_name,
                ' number ',
                tostring(this.soft_reset_counter),
                '!'
            }
        )
    end
    game.print(message, {r = 0.98, g = 0.66, b = 0.22})
    Server.to_discord_embed(message_to_discord)

    return new_surface
end

return Public
