local Server = require 'utils.server'
local Session = require 'utils.datastore.session_data'
local Modifers = require 'utils.player_modifiers'
local Public = require 'maps.mountain_fortress_v3.table'
local Event = require 'utils.event'

local mapkeeper = '[color=blue]Mapkeeper:[/color]'

local function show_all_gui(player)
    for _, child in pairs(player.gui.top.children) do
        child.visible = true
    end
end

local function clear_spec_tag(player)
    if player.tag == '[Spectator]' then
        player.tag = ''
    end
end

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
    game.forces.player.set_spawn_position({-27, 25}, surface)
    local position = game.forces.player.get_spawn_position(surface)

    if not position then
        game.forces.player.set_spawn_position({-27, 25}, surface)
        position = game.forces.player.get_spawn_position(surface)
    end

    for _, player in pairs(game.connected_players) do
        player.teleport(surface.find_non_colliding_position('character', position, 3, 0, 5), surface)
    end
end

local function equip_players(player_starting_items, data)
    for _, player in pairs(game.players) do
        if player.character and player.character.valid then
            player.character.destroy()
        end
        if player.connected then
            if not player.character then
                player.set_controller({type = defines.controllers.god})
                player.create_character()
            end
            player.clear_items_inside()
            Modifers.update_player_modifiers(player)
            for item, item_data in pairs(player_starting_items) do
                player.insert({name = item, count = item_data.count})
            end
            show_all_gui(player)
            clear_spec_tag(player)
        else
            data.players[player.index] = nil
            Session.clear_player(player)
            game.remove_offline_players({player.index})
        end
    end
end

local function clear_scheduler(scheduler)
    scheduler.operation = nil
    scheduler.surface = nil
    scheduler.remove_surface = false
    scheduler.start_after = 0
end

local function scheduled_surface_clearing()
    local scheduler = Public.get('scheduler')
    if not scheduler.operation then
        return
    end

    local tick = game.tick

    if scheduler.start_after > tick then
        return
    end

    local operation = scheduler.operation

    if operation == 'warn' then
        game.print(mapkeeper .. ' Preparing to remove old entites and clearing surface - this might lag the server a bit.')
        scheduler.operation = 'player_clearing'
        scheduler.start_after = tick + 100
    elseif operation == 'player_clearing' then
        local surface = scheduler.surface
        if not surface or not surface.valid then
            clear_scheduler(scheduler)
            return
        end
        game.print(mapkeeper .. ' Removing old entities.')

        local ent = surface.find_entities_filtered {force = 'player', limit = 1000}
        for _, e in pairs(ent) do
            if e.valid then
                e.destroy()
            end
        end
        scheduler.operation = 'clear'
        scheduler.start_after = tick + 100
    elseif operation == 'clear' then
        local surface = scheduler.surface
        if not surface or not surface.valid then
            clear_scheduler(scheduler)
            return
        end

        game.print(mapkeeper .. ' Clearing old surface.')
        surface.clear()
        if scheduler.remove_surface then
            scheduler.operation = 'delete'
        else
            scheduler.operation = 'done'
        end
        scheduler.start_after = tick + 100
    elseif operation == 'delete' then
        local surface = scheduler.surface
        if not surface or not surface.valid then
            clear_scheduler(scheduler)
            return
        end

        game.print(mapkeeper .. ' Deleting old surface.')

        game.delete_surface(surface)
        scheduler.operation = 'done'
        scheduler.start_after = tick + 100
    elseif operation == 'done' then
        game.print(mapkeeper .. ' Done clearing old surface.')
        clear_scheduler(scheduler)
    end
end

function Public.soft_reset_map(old_surface, map_gen_settings, player_starting_items)
    local this = Public.get()

    if not this.soft_reset_counter then
        this.soft_reset_counter = 0
    end
    if not this.original_surface_name then
        this.original_surface_name = old_surface.name
    end
    this.soft_reset_counter = this.soft_reset_counter + 1

    local new_surface = game.create_surface(this.original_surface_name .. '_' .. tostring(this.soft_reset_counter), map_gen_settings)
    new_surface.request_to_generate_chunks({0, 0}, 0.1)
    new_surface.force_generate_chunk_requests()

    reset_forces(new_surface, old_surface)
    teleport_players(new_surface)
    equip_players(player_starting_items, this)

    Public.add_schedule_to_delete_surface(true)

    local radius = 512
    local area = {{x = -radius, y = -radius}, {x = radius, y = radius}}
    for _, entity in pairs(new_surface.find_entities_filtered {area = area, type = 'logistic-robot'}) do
        entity.destroy()
    end

    for _, entity in pairs(new_surface.find_entities_filtered {area = area, type = 'construction-robot'}) do
        entity.destroy()
    end

    local message = table.concat({mapkeeper .. ' Welcome to ', this.original_surface_name, '!'})
    local message_to_discord = table.concat({'** Welcome to ', this.original_surface_name, '! **'})

    if this.soft_reset_counter > 1 then
        message =
            table.concat(
            {
                mapkeeper,
                ' The world has been reshaped, welcome to attempt number ',
                tostring(this.soft_reset_counter),
                '!'
            }
        )
    end
    game.print(message, {r = 0.98, g = 0.66, b = 0.22})
    Server.to_discord_embed(message_to_discord)

    return new_surface
end

function Public.add_schedule_to_delete_surface(remove_surface)
    local old_surface_index = Public.get('old_surface_index')
    local surface = game.get_surface(old_surface_index)
    if not surface or not surface.valid then
        return
    end

    local tick = game.tick

    local scheduler = Public.get('scheduler')
    scheduler.operation = 'warn'
    scheduler.surface = surface
    scheduler.remove_surface = remove_surface or false
    scheduler.start_after = tick + 500
end

Event.on_nth_tick(10, scheduled_surface_clearing)

return Public
