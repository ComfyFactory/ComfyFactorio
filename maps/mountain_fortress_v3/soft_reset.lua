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
            for item, amount in pairs(player_starting_items) do
                player.insert({name = item, count = amount})
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

local function add_step(this)
    if this.schedule_step ~= this.schedule_max_step then
        this.schedule_step = this.schedule_step + 1
    end
end

local function scheduled_surface_clearing()
    local this = Public.get()
    if not this.initial_tick then
        return
    end

    if this.initial_tick > game.tick then
        return
    end
    local step = this.schedule_step
    local schedule = this.schedule
    if schedule[step] then
        local surface = schedule[step].surface
        if not surface.valid then
            schedule[step] = nil
            add_step(this)
            return
        end
        if schedule[step].operation == 'player_clearing' then
            local ent = surface.find_entities_filtered {force = 'player', limit = 1000}
            for _, e in pairs(ent) do
                if e.valid then
                    e.destroy()
                end
            end
            schedule[step] = nil
            add_step(this)
        elseif schedule[step].operation == 'clear' then
            surface.clear()
            schedule[step] = nil
            add_step(this)
        elseif schedule[step].operation == 'delete' then
            game.delete_surface(surface)
            schedule[step] = nil
            add_step(this)
        elseif schedule[step].operation == 'done' then
            game.print(mapkeeper .. ' Done clearing old surface.')
            schedule[step] = nil
            add_step(this)
        end
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
    local this = Public.get()
    local surface = game.get_surface(this.active_surface_index)
    if not surface or not surface.valid then
        return
    end

    game.print(mapkeeper .. ' Preparing to remove old entites and clearing surface - this might lag the server a bit.')

    local step = this.schedule_max_step

    if not step then
        this.schedule_step = 0
        this.schedule_max_step = 0
        this.schedule = {}
        this.initial_tick = 0
        step = this.schedule_max_step
    end

    local add = 1
    local count_scrap = surface.count_entities_filtered {force = 'player'}
    for _ = 1, count_scrap, 1000 do
        this.schedule[step + add] = {operation = 'player_clearing', surface = surface}
        add = add + 1
    end
    this.schedule[step + add] = {operation = 'clear', surface = surface}
    add = add + 1
    if remove_surface then
        this.schedule[step + add] = {operation = 'delete', surface = surface}
        add = add + 1
    end
    this.schedule[step + add] = {operation = 'done', surface = surface}
    this.schedule_max_step = this.schedule_max_step + add
    if this.schedule_step == step then
        this.schedule_step = this.schedule_step + 1
    end
    if this.initial_tick <= game.tick then
        this.initial_tick = game.tick + 500
    end
end

Event.on_nth_tick(10, scheduled_surface_clearing)

return Public
