local Global = require 'utils.global'
local Event = require 'utils.event'
local this = {
    chunks = {}
}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local Public = {}

function Public.get_chunk_and_remove()
    local chunk
    this.current_index, chunk = next(this.chunks, this.current_index)

    if this.current_index and this.chunks[this.current_index] then
        this.chunks[this.current_index] = nil
        return chunk
    end
end

function Public.apply_tiles(tiles)
    if tiles and next(tiles) then
        local surface = game.get_surface(this.map_name)
        surface.set_tiles(tiles, true)
    end
end

function Public.apply_entities(entities)
    if entities and next(entities) then
        local surface = game.get_surface(this.map_name)
        for _, e in ipairs(entities) do
            if e then
                surface.create_entity(e)
            end
        end
    end
end

function Public.apply_decoratives(decoratives)
    if decoratives and next(decoratives) then
        local surface = game.get_surface(this.map_name)
        surface.create_decoratives({check_collision = true, decoratives = decoratives})
    end
end

function Public.apply_map_name(map_name)
    this.map_name = map_name or nil
end

Event.add(
    defines.events.on_chunk_generated,
    function(event)
        local left_top = event.area.left_top
        local surface = event.surface
        local map_name = this.map_name

        if not map_name then
            return
        end

        if string.sub(surface.name, 0, #map_name) ~= map_name then
            return
        end

        local seed = surface.map_gen_settings.seed

        if not surface.generate_with_lab_tiles then
            surface.generate_with_lab_tiles = true
        end

        this.chunks[#this.chunks + 1] = {
            seed = seed,
            left_top = left_top
        }
    end
)

return Public
