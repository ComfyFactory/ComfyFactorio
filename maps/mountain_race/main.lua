--luacheck: ignore
require 'modules.biters_yield_ore'
require 'modules.rocks_yield_ore_veins'

local Map_score = require 'utils.gui.map_score'
local Collapse = require 'modules.collapse'
local Immersive_cargo_wagons = require 'modules.immersive_cargo_wagons.main'
local Terrain = require 'maps.mountain_race.terrain'
local Team = require 'maps.mountain_race.team'
local Gui = require 'maps.mountain_race.gui'
local Global = require 'utils.global'
local Server = require 'utils.server'

local mountain_race = {}
Global.register(
    mountain_race,
    function(tbl)
        mountain_race = tbl
    end
)

local function on_chunk_generated(event)
    local surface = event.surface
    if surface.index ~= 1 then
        return
    end
    local left_top = event.area.left_top
    if left_top.y >= mountain_race.playfield_height or left_top.y < 0 or left_top.x < 0 then
        Terrain.draw_out_of_map_chunk(surface, left_top)
        return
    end
    Terrain.draw_terrain(surface, left_top)
end

local function on_entity_damaged(event)
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity then
        return
    end
    if not entity.valid then
        return
    end
    if entity.name == 'locomotive' then
        if entity == mountain_race.locomotives.north then
            mountain_race.victorious_team = 'south'
            mountain_race.gamestate = 'game_over'
            return
        end
        if entity == mountain_race.locomotives.south then
            mountain_race.victorious_team = 'north'
            mountain_race.gamestate = 'game_over'
            return
        end
    end
end

local function on_player_died(event)
    Team.update_spawn_positions(mountain_race)
end

local function on_player_joined_game(event)
    Team.update_spawn_positions(mountain_race)

    local player = game.players[event.player_index]
    Gui.create_top_gui(player)

    if game.tick == 0 then
        if player.character then
            if player.character.valid then
                player.character.destroy()
            end
        end
        player.character = nil
        player.set_controller({type = defines.controllers.god})
        return
    end

    Team.setup_player(mountain_race, player)

    local surface = game.surfaces.nauvis
    local tile = surface.get_tile(player.position)
    if tile.valid then
        if tile.name == 'out-of-map' then
            player.teleport(surface.find_non_colliding_position('character', player.force.get_spawn_position(surface), 64, 0.5), surface)
        end
    end
end

local function on_research_finished(event)
    local force = event.research.force
    force.character_inventory_slots_bonus = force.mining_drill_productivity_bonus * 100 -- +10 Slots / level

    local mining_speed_bonus = 1 + force.mining_drill_productivity_bonus * 10 -- +100% speed / level
    if force.technologies['steel-axe'].researched then
        mining_speed_bonus = mining_speed_bonus + 1
    end -- +100% speed for steel-axe research
    force.manual_mining_speed_modifier = mining_speed_bonus
end

local function on_console_chat(event)
    if not event.message then
        return
    end
    if not event.player_index then
        return
    end
    local player = game.players[event.player_index]

    local color = {}
    color = player.color
    color.r = color.r * 0.6 + 0.35
    color.g = color.g * 0.6 + 0.35
    color.b = color.b * 0.6 + 0.35
    color.a = 1

    if player.force.name == 'south' then
        game.forces.north.print(player.name .. ' (south): ' .. event.message, color)
    end
    if player.force.name == 'north' then
        game.forces.south.print(player.name .. ' (north): ' .. event.message, color)
    end
end

local function init(mountain_race)
    if game.ticks_played % 120 ~= 30 then
        return
    end
    game.print('game resetting..')

    Immersive_cargo_wagons.reset()

    local surface = game.surfaces.nauvis

    Collapse.set_kill_entities(true)
    Collapse.set_speed(8)
    Collapse.set_amount(0)
    Collapse.set_max_line_size(mountain_race.border_width + mountain_race.playfield_height * 2)
    Collapse.set_surface_index(surface.index)
    Collapse.set_position({0, 0})
    Collapse.set_direction('east')
    Collapse.start_now(true)

    game.reset_time_played()

    mountain_race.clone_x = 0

    Team.configure_teams(mountain_race)

    game.print('rerolling terrain..')
    mountain_race.gamestate = 'reroll_terrain'
end

local function prepare_terrain(mountain_race)
    if game.ticks_played % 60 ~= 30 then
        return
    end
    Terrain.clone_south_to_north(mountain_race)

    if mountain_race.clone_x < 6 then
        return
    end
    game.print('preparing spawn..')
    mountain_race.gamestate = 'prepare_spawn'
end

local function prepare_spawn(mountain_race)
    if game.ticks_played % 60 ~= 0 then
        return
    end
    Terrain.generate_spawn(mountain_race, 'north')
    Terrain.generate_spawn(mountain_race, 'south')
    game.print('spawning players..')
    mountain_race.gamestate = 'spawn_players'
end

local function spawn_players(mountain_race)
    if game.ticks_played % 60 ~= 0 then
        return
    end
    for _, player in pairs(game.players) do
        player.force = game.forces.player
    end
    for _, player in pairs(game.connected_players) do
        Team.setup_player(mountain_race, player)
    end

    mountain_race.reset_counter = mountain_race.reset_counter + 1
    local message = 'Mountain race #' .. mountain_race.reset_counter .. ' has begun!'
    game.print(message, {255, 155, 0})
    Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
    mountain_race.gamestate = 'game_in_progress'
end

local function set_collapse_speed(mountain_race)
    if not mountain_race.locomotives.north then
        return
    end
    if not mountain_race.locomotives.south then
        return
    end
    local amount = math.abs(mountain_race.locomotives.north.position.x - mountain_race.locomotives.south.position.x)
    amount = math.floor(amount / 64)
    if amount < 0 then
        amount = 0
    end
    Collapse.set_amount(amount)
end

local function chart(mountain_race)
    local surface = game.surfaces.nauvis
    local north = game.forces.north
    local south = game.forces.south
    local r = 128
    local p = north.get_spawn_position(surface)
    local area = {{p.x - r, p.y - r}, {p.x + r, p.y + r}}
    north.chart(surface, area)
    south.chart(surface, area)

    local p = south.get_spawn_position(surface)
    local area = {{p.x - r, p.y - r}, {p.x + r, p.y + r}}
    north.chart(surface, area)
    south.chart(surface, area)

    local p = Collapse.get_position()
    local h = mountain_race.playfield_height + mountain_race.border_half_width
    local area = {{p.x - 32, p.y - h}, {p.x + 32, p.y + h}}
    north.chart(surface, area)
    south.chart(surface, area)
end

local game_tasks = {
    [15] = Gui.update_top_gui,
    [30] = set_collapse_speed,
    [60] = Terrain.clone_south_to_north,
    [90] = chart
}

local function game_in_progress(mountain_race)
    local tick = game.ticks_played
    if tick % 15 ~= 0 then
        return
    end
    local task = tick % 120
    if not game_tasks[task] then
        return
    end
    game_tasks[task](mountain_race)
end

local function game_over(mountain_race)
    local tick = game.ticks_played
    if tick % 60 ~= 0 then
        return
    end

    if not mountain_race.reset_countdown then
        mountain_race.reset_countdown = 10
        Collapse.set_amount(0)
        local message = 'Team ' .. mountain_race.victorious_team .. ' has won the race!'
        game.print(message, {255, 155, 0})
        Server.to_discord_bold(table.concat {'*** ', message, ' ***'})

        for _, player in pairs(game.forces[mountain_race.victorious_team].connected_players) do
            Map_score.set_score(player, Map_score.get_score(player) + 1)
        end

        return
    end

    mountain_race.reset_countdown = mountain_race.reset_countdown - 1
    if mountain_race.reset_countdown <= 0 then
        mountain_race.gamestate = 'init'
        mountain_race.reset_countdown = nil
    end
end

local gamestates = {
    ['init'] = init,
    ['reroll_terrain'] = Terrain.reroll_terrain,
    ['generate_chunks'] = Terrain.generate_chunks,
    ['prepare_terrain'] = prepare_terrain,
    ['prepare_spawn'] = prepare_spawn,
    ['spawn_players'] = spawn_players,
    ['game_in_progress'] = game_in_progress,
    ['game_over'] = game_over
}

local function on_tick()
    gamestates[mountain_race.gamestate](mountain_race)
end

local function on_init()
    game.difficulty_settings.technology_price_multiplier = 0.5
    mountain_race.reset_counter = 0
    mountain_race.gamestate = 'init'
    mountain_race.border_width = 32
    mountain_race.border_half_width = mountain_race.border_width * 0.5
    mountain_race.playfield_height = 128
    mountain_race.locomotives = {}
    Collapse.set_amount(0)
    Team.init_teams()
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_console_chat, on_console_chat)

require 'modules.rocks_yield_ore'
