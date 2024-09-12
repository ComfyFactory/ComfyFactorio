-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local SurfacesCommon = require 'maps.pirates.surfaces.common'
local BoatData = require 'maps.pirates.structures.boats.sloop.data'
local Event = require 'utils.event'
local IslandEnum = require 'maps.pirates.surfaces.islands.island_enum'
local Balance = require 'maps.pirates.balance'
local CoreData = require 'maps.pirates.coredata'

local Public = {}
Public.Data = require 'maps.pirates.surfaces.islands.cave.data'


-- Code imported from cave_miner_v2 scenario for cave generation

--lab-dark-1 > position has been copied
--lab-dark-2 > position has been visited
function Public.reveal(surface, source_surface, position, brushsize)
    local source_tile = source_surface.get_tile(position)
    if not source_tile.valid then return end
    if source_tile.name == 'lab-dark-2' then return end

    local tiles = {}
    local copied_tiles = {}
    local i = 0
    local brushsize_square = brushsize ^ 2

    local surface_name_decoded = SurfacesCommon.decode_surface_name(surface.name)
    local chunk_destination_index = surface_name_decoded.destination_index
    local memory = Memory.get_crew_memory()

    local destination = memory.destinations[chunk_destination_index]
    local terraingen_coordinates_offset = destination.static_params.terraingen_coordinates_offset

    -- TODO: use radius search for "find_tiles_filtered" instead to avoid the check?
    for _, tile in pairs(source_surface.find_tiles_filtered({ area = { { position.x - brushsize, position.y - brushsize }, { position.x + brushsize, position.y + brushsize } } })) do
        local tile_position = tile.position
        if tile.name ~= 'lab-dark-2' and tile.name ~= 'lab-dark-1' and (position.x - tile_position.x) ^ 2 + (position.y - tile_position.y) ^ 2 < brushsize_square then
            i = i + 1
            copied_tiles[i] = { name = 'lab-dark-1', position = tile.position }

            -- Avoid re-exploring these areas as they have been already revealed when map was loaded
            -- Revealed areas when map gets loaded are: river and entrance (beach with sand)
            local true_pos = Utils.psum { tile_position, { 1, terraingen_coordinates_offset } }
            true_pos = Utils.psum { true_pos, { x = 0.5, y = 0.5 } }
            local d = true_pos.x ^ 2 + true_pos.y ^ 2

            local boat_height = Math.max(BoatData.height, 15) -- even if boat height is smaller, we need to be at least 10+ just so formulas below play out nicely
            local spawn_radius = boat_height + 15
            -- local entrance_radius = boat_height + 45
            local river_width = boat_height + 40

            -- Don't copy river upon which ship arrives + ship entrance
            if not (true_pos.x < 0 and d >= spawn_radius ^ 2 and Math.abs(2 * true_pos.y) < river_width) then
                tiles[i] = { name = tile.name, position = tile.position }
            end
        end
    end
    surface.set_tiles(tiles, true, false, false, false)
    source_surface.set_tiles(copied_tiles, false, false, false, false)

    for _, entity in pairs(source_surface.find_entities_filtered({ area = { { position.x - brushsize, position.y - brushsize }, { position.x + brushsize, position.y + brushsize } } })) do
        if entity.valid then
            local entity_position = { x = entity.position.x, y = entity.position.y }
            if (position.x - entity_position.x) ^ 2 + (position.y - entity_position.y) ^ 2 < brushsize_square then
                local e = entity.clone({ position = entity_position, surface = surface })
                if e and e.valid then
                    if e.name == 'market' then
                        rendering.draw_light(
                            {
                                sprite = 'utility/light_medium',
                                scale = 7,
                                intensity = 0.8,
                                minimum_darkness = 0,
                                oriented = true,
                                color = { 255, 255, 255 },
                                target = e,
                                surface = surface,
                                visible = true,
                                only_in_alt_mode = false
                            }
                        )
                    end

                    entity.destroy()

                    -- make revealing a spawner recursively reveal nearby ones too
                    if e.name == 'biter-spawner' or e.name == 'spitter-spawner' then
                        -- prevent spawners immediately spawning tons of biters for a while to give player a chance to clear them or run away
                        if destination.dynamic_data and destination.dynamic_data.disabled_wave_timer then
                            destination.dynamic_data.disabled_wave_timer = Balance.prevent_waves_from_spawning_in_cave_timer_length
                        end

                        Public.try_make_spawner_elite(e, destination)

                        Public.reveal(surface, source_surface, entity_position, 15)
                    end
                end
            end
        end
    end

    source_surface.set_tiles({ { name = 'lab-dark-2', position = position } }, false)
    source_surface.request_to_generate_chunks(position, 3)
end

function Public.try_make_spawner_elite(spawner, destination)
    local memory = Memory.get_crew_memory()

    if spawner and CoreData.get_difficulty_option_from_value(memory.difficulty) >= 3 then
        if Math.random(20) == 1 then
            local max_health = Balance.elite_spawner_health()
            Common.new_healthbar(true, spawner, max_health, nil, max_health, 0.8, nil)

            local elite_spawners = destination.dynamic_data.elite_spawners
            if elite_spawners then
                elite_spawners[#elite_spawners + 1] = spawner
            end
        end
    end
end

function Public.roll_source_surface(destination_data)
    local map_gen_settings = {
        ['water'] = 0,
        ['seed'] = Math.random(1, 1000000),
        ['starting_area'] = 1,
        ['cliff_settings'] = { cliff_elevation_interval = 0, cliff_elevation_0 = 0 },
        ['default_enable_all_autoplace_controls'] = false,
        ['autoplace_settings'] = {
            ['entity'] = { treat_missing_as_default = false },
            ['tile'] = { treat_missing_as_default = false },
            ['decorative'] = { treat_missing_as_default = false }
        },
        autoplace_controls = {
            ['coal'] = { frequency = 0, size = 0, richness = 0 },
            ['stone'] = { frequency = 0, size = 0, richness = 0 },
            ['copper-ore'] = { frequency = 0, size = 0, richness = 0 },
            ['iron-ore'] = { frequency = 0, size = 0, richness = 0 },
            ['uranium-ore'] = { frequency = 0, size = 0, richness = 0 },
            ['crude-oil'] = { frequency = 0, size = 0, richness = 0 },
            ['trees'] = { frequency = 0, size = 0, richness = 0 },
            ['enemy-base'] = { frequency = 0, size = 0, richness = 0 }
        },
    }

    local cave_miner = destination_data.dynamic_data.cave_miner

    local island_surface_name = SurfacesCommon.decode_surface_name(destination_data.surface_name)
    local cave_surface_name = SurfacesCommon.encode_surface_name(island_surface_name.crewid, island_surface_name.destination_index, island_surface_name.type, IslandEnum.enum.CAVE_SOURCE)

    cave_miner.cave_surface = game.create_surface(cave_surface_name, map_gen_settings)
    cave_miner.cave_surface.request_to_generate_chunks({ x = 0, y = 0 }, 2)
    -- cave_miner.cave_surface.force_generate_chunk_requests() -- Figure out if this is needed at all since it causes issues
end

function Public.cleanup_cave_surface(destination_data)
    local dynamic_data = destination_data.dynamic_data
    if dynamic_data and dynamic_data.cave_miner and dynamic_data.cave_miner.cave_surface then
        game.delete_surface(dynamic_data.cave_miner.cave_surface)
    end
end

local biomes = {}

function biomes.void(args)
    args.tiles[#args.tiles + 1] = { name = 'out-of-map', position = args.p }
end

function biomes.entrance(args, square_distance)
    if square_distance < (BoatData.height + 40) ^ 2 then
        args.tiles[#args.tiles + 1] = { name = 'sand-1', position = args.p }
    else
        args.tiles[#args.tiles + 1] = { name = 'water-shallow', position = args.p }
    end
end

function biomes.river(args)
    args.tiles[#args.tiles + 1] = { name = 'water', position = args.p }

    Public.Data.spawn_fish(args);
end

function Public.terrain(args)
    local position = args.p
    local d = position.x ^ 2 + position.y ^ 2

    local boat_height = Math.max(BoatData.height, 15) -- even if boat height is smaller, we need to be at least 10+ just so formulas below play out nicely
    local spawn_radius = boat_height + 15
    local entrance_radius = boat_height + 45
    local river_width = boat_height + 40

    -- Spawn location for market
    if d < spawn_radius ^ 2 then
        biomes.void(args)
        -- Cave entrance
    elseif position.x < 0 and d < entrance_radius ^ 2 and Math.abs(2 * position.y) < river_width then
        biomes.entrance(args, d)
        -- River upon which ship arrives
    elseif position.x < 0 and Math.abs(2 * position.y) < river_width then
        biomes.river(args)
    else
        biomes.void(args)
    end

    -- fallback case when no tiles were placed
    if #args.tiles == 0 then
        args.tiles[#args.tiles + 1] = { name = 'dirt-7', position = args.p }
    end
end

-- function Public.chunk_structures(args)

-- end

-- Launching rocket in caves sounds silly
-- function Public.generate_silo_setup_position(points_to_avoid)

-- end

local function on_player_changed_position(event)
    if not event.player_index then return end

    local player = game.players[event.player_index]

    if not player.character then return end
    if not player.character.valid then return end

    local crew_id = Common.get_id_from_force_name(player.force.name)
    if not crew_id then return end
    Memory.set_working_id(crew_id)

    local destination_data = Common.current_destination()
    if destination_data.surface_name ~= player.surface.name then return end

    if not (destination_data and destination_data.subtype == IslandEnum.enum.CAVE) then return end

    local cave_miner = destination_data.dynamic_data.cave_miner

    -- TODO: make more reliable way to get island surface
    Public.reveal(player.surface, cave_miner.cave_surface, { x = Math.floor(player.position.x), y = Math.floor(player.position.y) }, 11)
end

Event.add(defines.events.on_player_changed_position, on_player_changed_position)


return Public
