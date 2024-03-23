--luacheck: ignore
local Public = {}
local math_random = math.random

local starting_items = {['iron-plate'] = 32, ['iron-gear-wheel'] = 16, ['stone'] = 20, ['pistol'] = 1, ['firearm-magazine'] = 128, ['rail'] = 16}

function Public.init_teams()
    game.create_force('north')
    game.create_force('south')
    game.create_force('spectator')
    game.forces.spectator.set_friend('north', true)
    game.forces.spectator.set_friend('south', true)
end

function Public.configure_teams(mountain_race)
    for _, force_name in pairs({'north', 'south'}) do
        local force = game.forces[force_name]
        force.reset()
        force.share_chart = true
        force.research_queue_enabled = true
        force.technologies['artillery'].enabled = false
        force.technologies['artillery-shell-range-1'].enabled = false
        force.technologies['artillery-shell-speed-1'].enabled = false
        force.technologies['land-mine'].enabled = false
        force.technologies['railway'].researched = true
        force.manual_mining_speed_modifier = 1
    end
    game.forces.north.set_friend('spectator', true)
    game.forces.south.set_friend('spectator', true)

    local y = mountain_race.playfield_height * 0.5 + mountain_race.border_half_width

    game.forces.north.set_spawn_position({32, y * -1}, game.surfaces.nauvis)
    game.forces.south.set_spawn_position({32, y}, game.surfaces.nauvis)
end

function Public.teleport_player_to_spawn(player)
    local surface = game.surfaces.nauvis
    local position
    position = surface.find_non_colliding_position('character', player.force.get_spawn_position(surface), 48, 1)
    if not position then
        position = player.force.get_spawn_position(surface)
    end
    player.teleport(position, surface)
end

local function assign_force_to_player(player)
    if #game.forces.south.connected_players > #game.forces.north.connected_players then
        player.force = game.forces.north
        return
    end
    if #game.forces.north.connected_players > #game.forces.south.connected_players then
        player.force = game.forces.south
        return
    end
    if math_random(1, 2) == 1 then
        player.force = game.forces.south
    else
        player.force = game.forces.north
    end
end

function Public.setup_player(mountain_race, player)
    if player.force.name == 'player' then
        assign_force_to_player(player)
        player.print("You have been assigned to team " .. player.force.name .. "!")

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

        Public.teleport_player_to_spawn(player)
    end
end

function Public.update_spawn_positions(mountain_race)
    if not mountain_race.locomotives.north then
        return
    end
    if not mountain_race.locomotives.south then
        return
    end

    local surface = game.surfaces.nauvis

    for _, force_name in pairs({'north', 'south'}) do
        local force = game.forces[force_name]
        local p = mountain_race.locomotives[force_name].position
        force.set_spawn_position({p.x, p.y + 2}, surface)
    end

    local p = mountain_race.locomotives['north'].position
    game.forces.player.set_spawn_position({p.x, p.y + 2}, surface)
end

return Public
