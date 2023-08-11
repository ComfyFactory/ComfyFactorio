local Public = require 'maps.mountain_fortress_v3.stateful.table'
local map_name = 'boss_room'

local bp =
    '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'

function Public.create()
    local surface =
        game.surfaces.music or
        game.create_surface(
            map_name,
            {
                autoplace_controls = {
                    ['coal'] = {frequency = 0, size = 3, richness = 3},
                    ['stone'] = {frequency = 0, size = 3, richness = 3},
                    ['copper-ore'] = {frequency = 0, size = 3, richness = 3},
                    ['iron-ore'] = {frequency = 0, size = 3, richness = 3},
                    ['uranium-ore'] = {frequency = 0, size = 3, richness = 3},
                    ['crude-oil'] = {frequency = 0, size = 3, richness = 1},
                    ['trees'] = {frequency = 0, size = 0, richness = 0},
                    ['enemy-base'] = {frequency = 15, size = 0, richness = 1}
                },
                cliff_settings = {cliff_elevation_0 = 1024, cliff_elevation_interval = 10, name = 'cliff'},
                height = 1024,
                width = 1024,
                peaceful_mode = false,
                seed = 1337,
                starting_area = 'very-low',
                starting_points = {{x = 0, y = 0}},
                terrain_segmentation = 'none',
                water = 'none'
            }
        )
    local position = {x = -500, y = 503}
    surface.daytime = 0.5
    surface.freeze_daytime = true
    surface.min_brightness = 0.3
    surface.brightness_visual_weights = {1, 1, 1}
    surface.request_to_generate_chunks(position, 2)
    surface.request_to_generate_chunks({0, 0}, 2)
    surface.force_generate_chunk_requests()

    local item = surface.create_entity {name = 'item-on-ground', position = position, stack = {name = 'blueprint', count = 1}}
    if not item then
        return
    end

    local success = item.stack.import_stack(bp)
    if success <= 0 then
        local ghosts = item.stack.build_blueprint {surface = surface, force = 'player', position = position, force_build = true}
        for _, ghost in pairs(ghosts) do
            local _, ent = ghost.silent_revive({raise_revive = true})
            if ent and ent.valid then
                ent.destructible = false
                ent.minable = false
            end
        end
    end

    if item.valid then
        item.destroy()
    end

    return surface
end

function Public.nuke_world()
    if game.surfaces.boss_room then
        game.delete_surface(map_name)
    end
    Public.create()
end

function Public.nuke_blueprint()
    local position = {x = -500, y = 503}
    local surface = game.get_surface('boss_room')
    if not surface or not surface.valid then
        return
    end

    local radius = 512
    local area = {{position.x - radius, position.y - radius}, {position.x + radius, position.y + radius}}
    for _, entity in pairs(surface.find_entities_filtered {area = area, name = 'programmable-speaker'}) do
        if entity and entity.valid then
            entity.destroy()
        end
    end
end

return Public
