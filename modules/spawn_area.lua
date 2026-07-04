local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local market_items = require 'modules.map_market_items'
local Global = require 'utils.global'
local Utils = require 'utils.utils'

local this =
{
    enable_market = true,
    turrets = {},
    surface_name = 'nauvis'
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local Public = {}
local random = math.random
local base_bp =
[[0eJylm11vozoQhv8L13AUg8HQy/0bR6sVTa0WiQAi5OxWVf77IZtCDfEw79CrfuaZD78eD57kI3iuL7brq2YInj6C6tg25+Dp34/gXL02ZX373fDe2eApqAZ7CsKgKU+3n85D29jod1nXwTUMqubF/gme1DVkX1j1bRMd3+x5cF4YX3+GgW2Gaqjs3fzfH95/NZfTs+1Hss9wGHTteXxJ29ysjZio+CcNg/f7N9ebMytMjGFyBpNgGMNgNIbJGEyKYVIGk2EYzWAMhkkYTI5hYgZTzJjXcrAewMEFhMFL1dvj/e+xB6cOmFuKcUspxi+hW5iuWa8wXXM5V5iuOQUoTNecHhWma253KEzX3F5VmK65yqEKCMOWQ0zOXDmMpdU5JzhgeZ45huA4Oj6NiKguT91WRaQ4GuPEHCeFOCwmgzBsVJiS2cXClMyuFabkrzVPiSMZrMwzJyM4jpbbuuyjrmzs5nFKORRj4jEcZy1mW49HQV8do66tfSda4kY4vtZWr2/P7aW/9VWJDvXhp8/KWuqMlU0jSahTrxFsH7AZwSo6qxjhPqAEA3YqMychONKNoImm8iDUS+Y69riUJvYtpXYamEsTDZe+t4NPjJ9or6fgDom5iBPIl01XsErPerIWOJP7zdTr0GTe1AvlT+hNC+VPhSyVvyI4UvnHxMPQWv5c2aU4CuNojoOJnMVgLQ0bFdaac4uVYq05u1ZfSiaezibCgQAYFBBRhJwhcB5wD5icA5mwbyFSmQlbcGJhM2HTQnkDNuCawWjJIeMt7FkqOBv8BKzr5kIxov1LUWQ9N0WRPTwSUjFC4RLnhxEKlzjNzFq4aNfjOXnHDir3Nj0GlHXMhCxrNiiKU4O3HlSm5xSiCzZreYMtiy9vaZgn3rzJWg0qYJn4KaEI+wyi68+F6ieyn4NdhmEwUvUnTnSrVRx3kn8Vc+GD6JaNjNhhObY1uHTI2hNqiWV9NuULeB8+YYjbllzYZhO3LXmB6S3dxhRgkx0zGEz9HAXrWbiQsLtvZpkKWX9N+QJOdCYMNfsAJzo5gwEVbBgMqOCMwYD1O93GqANYwDXHAfuXhOOAd98xx3EuQ7YnXuDACxxSKs6vlPFL6BambdYrTNts0jFtsxrAtM1JEhxScjtEYcpm9qsCZ5NM9VDgbJKpZQqcTTKVVS1mk9bWn29o2BgEE+2oWownIRLRHqvFhBIiES2LWgwpIRLRQqnFnBIiEUeiWowqN0g8SAlBVGyLaSUCotLtjishEKUAd14JgShRxqi85/tG4pJAxai8M5aEyjtlSai8NUtC5Z1wpASU90wiQaC85+BIECjvOd8kCJT3LAESBMp7ViUJAuXN5hoUN5tqUNpspkFhs4kGZc3lWYOiZquIBkXNFhENipqtIRoUNVtCNChqtoJoUNRT8adqvwZFPXGow0iDop441OmoQVFPHOq41qCoJw7VP6RopWZBaKXmIkvRSs2lOkUrNbf2KVqpOTE6g8byeLycLnU5tL1n43+2an5IhkGiO4WAfMnZ/ul6ez5Hl+bF9q99O36Nnm29dRLdb8un90M33eX25mePkfw7RqKFlfYykGaKPWbmCmQentCB0Jw5J24TMbkRpzMU3ZNOjS2aMzPdYyUDF82ZqQrMZN9bNL3Hpv7mqqU7jCI2N+LMdphEUrsV5p6CslKNY1MjYe4pL6vt4DW5FeaeWrOqaMIwzZ5Ss6zU0ijNnkpjnFNUHuSeqmOcTmJHkHsqUOZ0QQuTGRLknvqjeYtbQe6pPsm3gtxTfCLA5FaUu7oZILMbYe7qbQD5bIW5q9FZ7hI2sHxPuYmWm/8xlBVx6Mvm3LX9MPGWxw3ZXdzz9uCyEprQdIkmLMRCCxlpgTCQCA0c6CwRFrRj4c2WQ9RVnW+gNl0WxGuNHjzQVAh9OI980AyEagnUCKEPx5gPmoPQRAItMOh8qYMsVHHAoJpsVXxQJfQUgsZCT5GcFgkGTURQcEfN0BSBgjsqFkHRHTW5CkHRHRVLoPnto9N/P2L95HyUOwz+s/35fjzkSpsiNjouiuT2lpu6HKvj+N8/5v++Xv8HeTb26A==]]

local force_name = 'defenders'

local tile_positions =
{
    { x = -3, y = -2 },
    { x = -3, y = -1 },
    { x = -3, y = 0 },
    { x = -3, y = 1 },
    { x = -3, y = 2 },
    { x = 3, y = -2 },
    { x = 3, y = -1 },
    { x = 3, y = 0 },
    { x = 3, y = 1 },
    { x = 3, y = 2 },
    { x = -2, y = -3 },
    { x = -1, y = -3 },
    { x = 0, y = -3 },
    { x = 1, y = -3 },
    { x = 2, y = -3 },
    { x = -2, y = 3 },
    { x = -1, y = 3 },
    { x = 0, y = 3 },
    { x = 1, y = 3 },
    { x = 2, y = 3 }
}

local global_offset = { x = 0, y = 0 }
local center_radius = 20
local p_tile = 'stone-path'
local concrete_tiles =
{
    'refined-concrete',
    'blue-refined-concrete',
    'brown-refined-concrete',
    'cyan-refined-concrete',
    'green-refined-concrete',
    'orange-refined-concrete',
    'red-refined-concrete',
    'yellow-refined-concrete'
}

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = math.random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

local function generate_random_tile()
    local tile = concrete_tiles[random(1, #concrete_tiles)]
    return tile
end

local function is_spawn(position)
    if math.abs(position.x) > 32 then
        return false
    end
    if math.abs(position.y) > 32 then
        return false
    end
    local p = { x = position.x, y = position.y }
    if p.x > 0 then
        p.x = p.x + 1
    end
    if p.y > 0 then
        p.y = p.y + 1
    end
    local d = math.sqrt(p.x ^ 2 + p.y ^ 2)
    if d < 32 then
        return true
    end
end

local function create_force()
    if not game.forces[force_name] then
        game.create_force(force_name)
    end
end

local function set_force_friendly()
    create_force()
    for _, force in pairs(game.forces) do
        if force.name ~= 'enemy' then
            local d = game.forces[force_name]
            d.set_friend(force.name, true)
            force.set_friend(d.name, true)
        end
    end
end

local function spawn_market()
    if not this.enable_market then
        return
    end

    if this.market and this.market.valid then
        return
    end

    local get_surface = this.surface_name
    local surface = game.surfaces[get_surface]
    local pos = { { x = -10, y = -10 }, { x = 10, y = 10 }, { x = -10, y = -10 }, { x = 10, y = -10 } }
    local _pos = shuffle(pos)
    local p = surface.find_non_colliding_position('market', { _pos[1].x, _pos[1].y }, 60, 2)

    this.market = surface.create_entity { name = 'market', position = p, force = 'neutral' }

    rendering.draw_text
    {
        text = 'Spawn Market',
        surface = surface,
        target = { entity = this.market, offset = { 0, 2 } },
        color = { r = 0.98, g = 0.66, b = 0.22 },
        alignment = 'center'
    }

    this.market.destructible = false

    local items = shuffle(market_items.spawn)

    local space_age = script.active_mods['space-age']

    for _, item in pairs(items) do
        if not space_age then
            item.offer.quality = 'normal'
        end
        this.market.add_market_item(item)
    end
end

local spawn_market_token = Token.register(spawn_market)

local function spawn_area()
    if this.spawn_generated then
        return
    end

    this.spawn_generated = true
    local get_surface = this.surface_name
    local surface = game.surfaces[get_surface]
    local offset = { x = -0, y = 0 }
    local base_tiles = {}
    local tiles = {}
    for x = -center_radius, center_radius + 5 do
        for y = -center_radius, center_radius + 5 do
            if x ^ 2 + y ^ 2 < center_radius ^ 2 then
                local tile = generate_random_tile()
                base_tiles[#base_tiles + 1] = { name = tile, position = { x + offset.x, y + offset.y } }
                local entities =
                    surface.find_entities_filtered
                    {
                        area = { { x + offset.x - 1, y + offset.y - 1 }, { x + offset.x, y + offset.y } }
                    }
                for _, entity in pairs(entities) do
                    if entity.name ~= 'character' then
                        entity.destroy()
                    end
                end
            end
        end
    end
    surface.set_tiles(base_tiles)
    for _, position in pairs(tile_positions) do
        table.insert(
            tiles,
            {
                name = p_tile,
                position = { position.x + offset.x + global_offset.x, position.y + offset.y + global_offset.y }
            }
        )
    end
    surface.set_tiles(tiles)

    local positions = {}
    for x = -center_radius, center_radius + 5 do
        for y = -center_radius, center_radius + 5 do
            if x ^ 2 + y ^ 2 < center_radius ^ 2 then
                local position = { x = x, y = y }
                if is_spawn(position) then
                    table.insert(positions, position)
                end
            end
        end
    end

    shuffle(positions)

    for _, position in pairs(positions) do
        if surface.count_tiles_filtered({ area = { { position.x - 1, position.y - 1 }, { position.x + 2, position.y + 2 } }, name = 'black-refined-concrete' }) < 4 then
            surface.set_tiles({ { name = 'black-refined-concrete', position = position } }, true)
        end
    end

    create_force()

    Public.build_from_blueprint(base_bp, global_offset, force_name, false)
end

local spawn_area_token = Token.register(spawn_area)

function Public.build_from_blueprint(bp_string, pos, force, flipped)
    local surface_name = this.surface_name
    local surface = game.get_surface(surface_name)
    flipped = flipped or false

    local bp_entity = game.surfaces.nauvis.create_entity { name = 'item-on-ground', position = { x = 0, y = 0 }, stack = 'blueprint' }
    bp_entity.stack.import_stack(bp_string)

    local direction = flipped and defines.direction.south or defines.direction.north

    local entities = bp_entity.stack.build_blueprint { surface = surface, force = force, position = { x = pos.x, y = pos.y }, force_build = true, skip_fog_of_war = false, direction = direction }

    bp_entity.destroy()

    for _, e in pairs(entities) do
        if e and e.valid then
            if e.ghost_name == 'steel-chest' then
                local entity = e.surface.create_entity { name = 'blue-chest', position = e.position, force = e.force }
                if entity and entity.valid then
                    entity.destructible = false
                    entity.minable_flag = false
                    entity.rotatable = false
                    entity.operable = false
                end
            else
                local _, entity = e.silent_revive()
                if entity and entity.valid then
                    entity.destructible = false
                    entity.minable_flag = false
                    entity.rotatable = false
                    entity.operable = false
                    if entity.energy then
                        entity.energy = 100000000
                    end

                    if entity.name == 'gun-turret' then
                        entity.force = force_name
                        this.turrets[#this.turrets + 1] = entity
                        entity.insert({ name = 'uranium-rounds-magazine', count = 200 })
                    end
                end
            end
        end
    end
end

Event.add(
    defines.events.on_force_created,
    function ()
        set_force_friendly()
    end
)

Event.add(
    defines.events.on_player_created,
    function (event)
        if event.player_index == 1 then
            set_force_friendly()
            Task.set_timeout_in_ticks(10, spawn_area_token)
            Task.set_timeout_in_ticks(15, spawn_market_token)
        end
    end
)

Event.on_nth_tick(
    350,
    function ()
        local tick = game.tick
        if tick < 100 then
            return
        end

        set_force_friendly()

        if not this.market or not this.market.valid then
            Task.set_timeout_in_ticks(15, spawn_market_token)
        end

        if next(this.turrets) then
            for _, unit in pairs(this.turrets) do
                if unit and unit.valid then
                    unit.insert({ name = 'uranium-rounds-magazine', count = 200 })
                end
            end
        end
    end
)

Event.add(
    defines.events.on_robot_built_entity,
    function (event)
        local ce = event.entity
        if not (ce and ce.valid) then
            return
        end

        local surface_name = this.surface_name

        if ce.surface.name ~= surface_name then
            return
        end

        local area =
        {
            left_top = { x = ce.position.x - 12, y = ce.position.y - 12 },
            right_bottom = { x = ce.position.x + 12, y = ce.position.y + 12 }
        }

        if Utils.contains_positions_only(tile_positions, area) then
            ce.destroy()
        end
    end
)

Event.add(
    defines.events.on_built_entity,
    function (event)
        local ce = event.entity
        if not (ce and ce.valid) then
            return
        end
        if event.player_index then
            local player = game.get_player(event.player_index)
            if player and player.valid and player.admin then return end
        end

        local surface_name = this.surface_name

        if ce.surface.name ~= surface_name then
            return
        end

        local area =
        {
            left_top = { x = ce.position.x - 12, y = ce.position.y - 12 },
            right_bottom = { x = ce.position.x + 12, y = ce.position.y + 12 }
        }

        if Utils.contains_positions_only(tile_positions, area) then
            ce.destroy()
        end
    end
)

Event.add(
    { defines.events.on_player_built_tile, defines.events.on_robot_built_tile },
    function (event)
        local ce = event.tiles
        if not ce or not ce[1] then
            return
        end

        local surface_index = event.surface_index

        ce = ce[1]

        local our_surface_index = this.surface_name

        if surface_index ~= our_surface_index then
            return
        end

        local area =
        {
            left_top = { x = ce.position.x - 12, y = ce.position.y - 12 },
            right_bottom = { x = ce.position.x + 12, y = ce.position.y + 12 }
        }

        local surface = game.get_surface(surface_index)

        local old_tile = ce.old_tile

        if Utils.contains_positions_only(tile_positions, area) then
            surface.set_tiles({ { name = old_tile.name, position = ce.position } }, true)
        end
    end
)

Public.spawn_area = spawn_area
Public.spawn_market = spawn_market

--- Sets surface name for spawn area to use
---@param name string
function Public.set_surface_name(name)
    this.surface_name = name or 'nauvis'
end

return Public
