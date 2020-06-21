local Event = require 'utils.event'
local random = math.random

local function void_replace_tiles_in_chunk(event)
    local surface = event.surface
    local map_name = 'mountain_fortress_v3'

    if string.sub(surface.name, 0, #map_name) ~= map_name then
        return
    end
    local area = event.area
    local top_x = area.left_top.x
    local top_y = area.left_top.y
    local bottom_x = area.right_bottom.x
    local bottom_y = area.right_bottom.y
    local tiles = {}
    if top_x > -33 and bottom_x < 1 and top_y > -33 and bottom_y < 1 then
        return
    end
    for i = top_y, bottom_y do
        for j = top_x, bottom_x do
            if (random(100) < global.void.tile_chance) then
                if (random(100) > global.void.void_chance) then
                    table.insert(tiles, {name = 'water', position = {j, i}})
                else
                    table.insert(tiles, {name = 'out-of-map', position = {j, i}})
                end
            end
        end
    end
    surface.set_tiles(tiles)
end

Event.add(
    defines.events.on_chunk_generated,
    function(event)
        void_replace_tiles_in_chunk(event)
    end
)

Event.on_init(
    function()
        global.void = global.void or {}
        global.void.seed = 1
        global.void.tile_chance = 7
        global.void.void_chance = 90
        global.void_module.seed = random(1, 999999)
    end
)
