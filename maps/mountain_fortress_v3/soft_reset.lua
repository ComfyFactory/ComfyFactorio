local Server = require 'utils.server'
local Public = require 'maps.mountain_fortress_v3.table'
local Event = require 'utils.event'

local mapkeeper = '[color=blue]Mapkeeper:[/color]'

local function reset_forces()
    for _, f in pairs(game.forces) do
        f.reset()
        f.reset_evolution()
    end
    for _, tech in pairs(game.forces.player.technologies) do
        tech.researched = false
        tech.saved_progress = 0
    end
end

local function teleport_players()
    local surface = game.get_surface('nauvis')
    if not surface or not surface.valid then
        return
    end
    local adjusted_zones = Public.get('adjusted_zones')
    local position

    if adjusted_zones.reversed then
        game.forces.player.set_spawn_position({ -27, -25 }, surface)
        position = game.forces.player.get_spawn_position(surface)

        if not position then
            game.forces.player.set_spawn_position({ -27, -25 }, surface)
            position = game.forces.player.get_spawn_position(surface)
        end
    else
        game.forces.player.set_spawn_position({ -27, 25 }, surface)
        position = game.forces.player.get_spawn_position(surface)

        if not position then
            game.forces.player.set_spawn_position({ -27, 25 }, surface)
            position = game.forces.player.get_spawn_position(surface)
        end
    end

    for _, player in pairs(game.connected_players) do
        local pos = surface.find_non_colliding_position('character', position, 3, 0)
        player.teleport({ x = pos.x, y = pos.y }, surface)
    end
end

local function clear_scheduler(scheduler)
    scheduler.operation = nil
    scheduler.surface = nil
    scheduler.old_surface_name = nil
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

        local ent = surface.find_entities_filtered { force = 'player', limit = 1000 }
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

        scheduler.operation = 'done'
        scheduler.start_after = tick + 100
    elseif operation == 'done' then
        game.print(mapkeeper .. ' Done clearing old surface.')
        clear_scheduler(scheduler)
    end
end

function Public.soft_reset_map(old_surface)
    local this = Public.get()

    if not this.soft_reset_counter then
        this.soft_reset_counter = 0
    end
    if not this.original_surface_name then
        this.original_surface_name = old_surface.name
    end
    this.soft_reset_counter = this.soft_reset_counter + 1

    local nauvis = game.surfaces.nauvis
    nauvis.clear(true)
    nauvis.request_to_generate_chunks({ 0, 0 }, 1)
    nauvis.force_generate_chunk_requests()

    local radius = 512
    local area = { { x = -radius, y = -radius }, { x = radius, y = radius } }
    for _, entity in pairs(nauvis.find_entities_filtered { area = area, type = 'logistic-robot' }) do
        entity.destroy()
    end

    for _, entity in pairs(nauvis.find_entities_filtered { area = area, type = 'construction-robot' }) do
        entity.destroy()
    end

    local message = table.concat({ mapkeeper .. ' Welcome to Mtn Fortress!' })
    local message_to_discord = table.concat({ '** Welcome to Mtn Fortress! **' })

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
    game.print(message, { r = 0.98, g = 0.66, b = 0.22 })
    Server.to_discord_embed(message_to_discord)

    return nauvis
end

Event.on_nth_tick(10, scheduled_surface_clearing)

Public.sr_teleport_players = teleport_players
Public.sr_reset_forces = reset_forces

return Public
