--luacheck: ignore
local Public = {}
local math_random = math.random
local Immersive_cargo_wagons = require 'modules.immersive_cargo_wagons.main'
local GetNoise = require 'utils.get_noise'
local LootRaffle = require 'utils.functions.loot_raffle'

local wagon_raffle = {'cargo-wagon', 'cargo-wagon', 'cargo-wagon', 'locomotive', 'fluid-wagon'}
local rock_raffle = {'sand-rock-big', 'sand-rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-huge'}

local function draw_border(surface, left_x, height)
    local tiles = {}
    local i = 1
    for x = left_x, left_x + 31, 1 do
        for y = height * -1, height - 1, 1 do
            tiles[i] = {name = 'out-of-map', position = {x = x, y = y}}
            i = i + 1
        end
    end
    surface.set_tiles(tiles, true)
end

function Public.clone_south_to_north(mountain_race)
    if game.tick < 60 then
        return
    end
    local surface = game.surfaces.nauvis
    if not surface.is_chunk_generated({mountain_race.clone_x + 2, 0}) then
        return
    end

    local area = {{mountain_race.clone_x * 32, 0}, {mountain_race.clone_x * 32 + 32, mountain_race.playfield_height}}
    local offset = mountain_race.playfield_height + mountain_race.border_half_width

    draw_border(surface, mountain_race.clone_x * 32, mountain_race.border_half_width)

    surface.clone_area(
        {
            source_area = area,
            destination_area = {{area[1][1], area[1][2] - offset}, {area[2][1], area[2][2] - offset}},
            destination_surface = surface,
            --destination_force = …,
            clone_tiles = true,
            clone_entities = true,
            clone_decoratives = true,
            clear_destination_entities = true,
            clear_destination_decoratives = true,
            expand_map = true
        }
    )

    mountain_race.clone_x = mountain_race.clone_x + 1
end

local function common_loot_crate(surface, position)
    local item_stacks = LootRaffle.roll(math.abs(position.x), 16)
    local container = surface.create_entity({name = 'wooden-chest', position = position, force = 'neutral'})
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
    container.minable = false
end

function Public.draw_terrain(surface, left_top)
    if left_top.x < 64 then
        return
    end
    local seed = surface.map_gen_settings.seed
    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local position = {x = left_top.x + x, y = left_top.y + y}
            local tile = surface.get_tile(position)
            if not tile.collides_with('resource-layer') then
                if math_random(1, 3) > 1 and surface.can_place_entity({name = 'coal', position = position, amount = 1}) and GetNoise('decoratives', position, seed) > 0.2 then
                    surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = position})
                end
                if math_random(1, 756) == 1 then
                    common_loot_crate(surface, position)
                end
            end
        end
    end
end

function Public.draw_out_of_map_chunk(surface, left_top)
    local tiles = {}
    local i = 1
    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            tiles[i] = {name = 'out-of-map', position = {x = left_top.x + x, y = left_top.y + y}}
            i = i + 1
        end
    end
    surface.set_tiles(tiles, true)
end

function Public.generate_spawn(mountain_race, force_name)
    local force = game.forces[force_name]
    local surface = game.surfaces.nauvis
    local p = force.get_spawn_position(surface)

    local v = {{0, 0}, {1, 0}, {0, 1}, {1, 1}}
    local teams = {
        ['north'] = {75, 75, 255},
        ['south'] = {255, 65, 65}
    }

    for x = 0, 48, 2 do
        surface.create_entity({name = 'straight-rail', position = {p.x + x, p.y}, direction = 2, force = force_name})
        for k, tile in pairs(surface.find_tiles_filtered({area = {{p.x + x, p.y}, {p.x + x + 2, p.y + 2}}})) do
            if tile.collides_with('resource-layer') then
                surface.set_tiles({{name = 'landfill', position = tile.position}}, true)
            end
        end
    end

    local entity = surface.create_entity({name = 'locomotive', position = {p.x + 6, p.y}, force = force_name, direction = 2})
    entity.minable = false
    entity.color = teams[force_name]

    rendering.draw_text(
        {
            text = string.upper(force_name),
            surface = surface,
            target = entity,
            target_offset = {0, -3},
            color = teams[force_name],
            scale = 2,
            font = 'default-game',
            alignment = 'center',
            scale_with_zoom = false
        }
    )

    mountain_race.locomotives[force_name] = entity

    local wagon = Immersive_cargo_wagons.register_wagon(entity)
    wagon.entity_count = 999
end

function Public.generate_chunks(mountain_race)
    if game.ticks_played % 60 ~= 0 then
        return
    end
    local surface = game.surfaces.nauvis
    surface.request_to_generate_chunks({0, 0}, 10)
    if not surface.is_chunk_generated({9, 0}) then
        return
    end
    game.print('preparing terrain..')
    mountain_race.gamestate = 'prepare_terrain'
end

function Public.reroll_terrain(mountain_race)
    if game.ticks_played % 60 ~= 0 then
        return
    end

    for _, player in pairs(game.connected_players) do
        if player.character then
            if player.character.valid then
                player.character.destroy()
            end
        end
        player.character = nil
        player.set_controller({type = defines.controllers.god})
    end

    local surface = game.surfaces.nauvis
    local mgs = surface.map_gen_settings
    mgs.seed = math_random(1, 99999999)
    mgs.water = 0.5
    mgs.starting_area = 1
    mgs.terrain_segmentation = 12
    mgs.cliff_settings = {cliff_elevation_interval = 0, cliff_elevation_0 = 0}
    mgs.autoplace_controls = {
        ['coal'] = {frequency = 16, size = 1, richness = 0.5},
        ['stone'] = {frequency = 16, size = 1, richness = 0.5},
        ['copper-ore'] = {frequency = 16, size = 1, richness = 0.75},
        ['iron-ore'] = {frequency = 16, size = 1, richness = 1},
        ['uranium-ore'] = {frequency = 8, size = 0.5, richness = 0.5},
        ['crude-oil'] = {frequency = 32, size = 1, richness = 1},
        ['trees'] = {frequency = math.random(4, 32) * 0.1, size = math.random(4, 16) * 0.1, richness = math.random(1, 10) * 0.1},
        ['enemy-base'] = {frequency = 16, size = 1, richness = 1}
    }
    surface.map_gen_settings = mgs
    surface.clear(false)
    for chunk in surface.get_chunks() do
        surface.delete_chunk({chunk.x, chunk.y})
    end

    game.print('generating chunks..')
    mountain_race.gamestate = 'generate_chunks'
end

return Public
