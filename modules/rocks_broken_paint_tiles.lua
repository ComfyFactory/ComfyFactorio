--Mining or breaking a rock paints the tiles underneath
local Event = require 'utils.event'

local valid_entities = {
    ['rock-big'] = true,
    ['rock-huge'] = true,
    ['sand-rock-big'] = true
}

local replacement_tiles = {
    ['nuclear-ground'] = 'dirt-7',
    ['dirt-7'] = 'dirt-6',
    ['dirt-6'] = 'dirt-5',
    ['dirt-5'] = 'dirt-4',
    ['dirt-4'] = 'dirt-3',
    ['dirt-3'] = 'dirt-2'
}

local coords = {
    {x = 0, y = 0},
    {x = -1, y = -1},
    {x = 1, y = -1},
    {x = 0, y = -1},
    {x = -1, y = 0},
    {x = -1, y = 1},
    {x = 0, y = 1},
    {x = 1, y = 1},
    {x = 1, y = 0},
    {x = 2, y = 0},
    {x = -2, y = 0},
    {x = 0, y = 2},
    {x = 0, y = -2}
}

local function on_pre_player_mined_item(event)
    local entity = event.entity
    if not valid_entities[entity.name] then
        return
    end

    local tiles = {}
    for i = 1, #coords do
        local p = coords[i]

        local pos = {x = entity.position.x + p.x, y = entity.position.y + p.y}
        local tile = entity.surface.get_tile(pos)
        if not tile.collides_with('player-layer') then
            if replacement_tiles[tile.name] and math.random(1, 2) == 1 then
                table.insert(tiles, {name = replacement_tiles[tile.name], position = pos})
            end
        end
    end
    if #tiles == 0 then
        return
    end
    entity.surface.set_tiles(tiles, true)
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local cause = event.cause

    if cause and cause.valid and cause.force.index == 2 then
        return
    end

    on_pre_player_mined_item(event)
end

Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)
