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

return Public
