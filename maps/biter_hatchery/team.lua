--luacheck: ignore
local Public = {}
local math_random = math.random

local starting_items = {['iron-plate'] = 32, ['iron-gear-wheel'] = 16, ['stone'] = 20, ['pistol'] = 1, ['firearm-magazine'] = 16}

function Public.reset_forces()
    for _, force_name in pairs({'west', 'east'}) do
        global.map_forces[force_name].unit_health_boost = 1
        global.map_forces[force_name].unit_count = 0
        global.map_forces[force_name].units = {}
        global.map_forces[force_name].player_count = 0
        local force = game.forces[force_name]
        force.reset()
        force.share_chart = true
        force.research_queue_enabled = true
        force.technologies['artillery'].enabled = false
        force.technologies['artillery-shell-range-1'].enabled = false
        force.technologies['artillery-shell-speed-1'].enabled = false
        force.technologies['land-mine'].enabled = false
    end
    game.forces.west.set_friend('spectator', true)
    game.forces.east.set_friend('spectator', true)
    game.forces.west.set_spawn_position({-210, 0}, game.surfaces.nauvis)
    game.forces.east.set_spawn_position({210, 0}, game.surfaces.nauvis)
end

function Public.create_forces()
    game.create_force('west')
    game.create_force('east')
    game.create_force('spectator')
    game.forces.spectator.set_friend('west', true)
    game.forces.spectator.set_friend('east', true)
    for _, force_name in pairs({'west', 'east'}) do
        global.map_forces[force_name].max_unit_count = 1280
    end
    local surface = game.surfaces.nauvis
    game.forces.spectator.set_spawn_position({0, -128}, surface)
end

function Public.assign_random_force_to_active_players()
    local player_indexes = {}
    for _, player in pairs(game.connected_players) do
        if player.force.name ~= 'spectator' then
            player_indexes[#player_indexes + 1] = player.index
        end
    end
    if #player_indexes > 1 then
        table.shuffle_table(player_indexes)
    end
    local a = math_random(0, 1)
    for key, player_index in pairs(player_indexes) do
        if key % 2 == a then
            game.players[player_index].force = game.forces.west
        else
            game.players[player_index].force = game.forces.east
        end
    end
end

function Public.assign_force_to_player(player)
    player.spectator = false
    if math_random(1, 2) == 1 then
        if #game.forces.east.connected_players > #game.forces.west.connected_players then
            player.force = game.forces.west
        else
            player.force = game.forces.east
        end
    else
        if #game.forces.east.connected_players < #game.forces.west.connected_players then
            player.force = game.forces.east
        else
            player.force = game.forces.west
        end
    end
end

function Public.teleport_player_to_spawn(player)
    local surface = game.surfaces.nauvis
    local position
    if player.force.name == 'spectator' then
        position = player.force.get_spawn_position(surface)
        position = {x = (position.x - 160) + math_random(0, 320), y = (position.y - 16) + math_random(0, 32)}
    else
        position = surface.find_non_colliding_position('character', player.force.get_spawn_position(surface), 48, 1)
        if not position then
            position = player.force.get_spawn_position(surface)
        end
    end
    player.teleport(position, surface)
end

function Public.add_player_to_team(player)
    if player.character then
        if player.character.valid then
            player.character.destroy()
        end
    end
    player.character = nil
    player.set_controller({type = defines.controllers.god})
    player.create_character()
    for item, amount in pairs(starting_items) do
        player.insert({name = item, count = amount})
    end
    global.map_forces[player.force.name].player_count = global.map_forces[player.force.name].player_count + 1
end

function Public.set_player_to_spectator(player)
    if player.character and player.character.valid then
        player.character.die()
    end
    player.force = game.forces.spectator
    player.character = nil
    player.spectator = true
    player.set_controller({type = defines.controllers.spectator})
end

function Public.spawn_players(hatchery)
    if game.tick % 90 ~= 0 then
        return
    end
    game.print('spawning characters', {150, 150, 150})
    local surface = game.surfaces.nauvis
    for _, player in pairs(game.connected_players) do
        if player.force.name ~= 'spectator' then
            Public.assign_force_to_player(player)
            Public.add_player_to_team(player)
            Public.teleport_player_to_spawn(player)
        end
    end
    hatchery.gamestate = 'rejoin_question'
    print(hatchery.gamestate)
end

function Public.init(hatchery)
    game.reset_time_played()
    Public.reset_forces()

    for _, player in pairs(game.forces.spectator.players) do
        Public.teleport_player_to_spawn(player)
    end

    for _, player in pairs(game.forces.west.players) do
        if player.connected then
            if player.character and player.character.valid then
                player.character.destroy()
            end
            player.character = nil
            player.spectator = true
            player.set_controller({type = defines.controllers.spectator})
            player.force = game.forces.player
            Public.teleport_player_to_spawn(player)
        else
            player.force = game.forces.player
        end
    end

    for _, player in pairs(game.forces.east.players) do
        if player.connected then
            if player.character and player.character.valid then
                player.character.destroy()
            end
            player.character = nil
            player.spectator = true
            player.set_controller({type = defines.controllers.spectator})
            player.force = game.forces.player
            Public.teleport_player_to_spawn(player)
        else
            player.force = game.forces.player
        end
    end
    hatchery.gamestate = 'reset_nauvis'
    print(hatchery.gamestate)
end

return Public
