local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local Global = require 'utils.global'
local StatData = require 'utils.datastore.statistics'
StatData.add_normalize('ore_veins', 'Ore veins located'):set_tooltip('Amount of ore veins located by the player.')

local ore_patch_gap = 4
local spawn_search_radius = 32
local is_modded_pt2 = Public.is_modded_pt2
local random = math.random

local this =
{
    raffle = {},
    mixed_ores = { 'iron-ore', 'copper-ore', 'stone', 'coal' },
    chance = 512,
    amount_modifier = 1
}

Global.register(
    this,
    function (t)
        this = t
    end
)

local valid_entities =
{
    ['simple-entity'] = true,
    ['tree'] = true,
    ['simple-entity-with-owner'] = true
}

local size_raffle =
{
    { 'giant', 65, 96 },
    { 'huge', 33, 64 },
    { 'big', 17, 32 },
    { 'small', 9, 16 },
    { 'tiny', 4, 8 }
}

function Public.add_to_raffle(raffle)
    for _, t in pairs(raffle) do
        for _ = 1, t[2], 1 do
            table.insert(this.raffle, t[1])
        end
    end
end

function Public.add_to_mixed_ores(ores)
    for _, o in pairs(ores) do
        table.insert(this.mixed_ores, o)
    end
end

function Public.remove_from_raffle(ores)
    local skip = {}
    for _, o in pairs(ores) do
        skip[o] = true
    end
    for i = #this.raffle, 1, -1 do
        if skip[this.raffle[i]] then
            table.fast_remove(this.raffle, i)
        end
    end
end

function Public.remove_from_mixed_ores(ores)
    local skip = {}
    for _, o in pairs(ores) do
        skip[o] = true
    end
    for i = #this.mixed_ores, 1, -1 do
        if skip[this.mixed_ores[i]] then
            table.fast_remove(this.mixed_ores, i)
        end
    end
end

local function get_blocked_resource_positions(surface, origin, radius, gap)
    local blocked = {}

    local resources = surface.find_entities_filtered(
        {
            area =
            {
                { origin.x - radius, origin.y - radius },
                { origin.x + radius, origin.y + radius }
            },
            type = 'resource'
        })

    for i = 1, #resources do
        local position = resources[i].position

        for x = -gap, gap do
            for y = -gap, gap do
                blocked[
                (position.x + x) .. '_' .. (position.y + y)
                ] = true
            end
        end
    end

    return blocked
end

local function get_chances()
    local chances = {}

    table.insert(chances, { 'iron-ore', 25 })
    table.insert(chances, { 'copper-ore', 18 })
    table.insert(chances, { 'mixed', 15 })
    table.insert(chances, { 'coal', 14 })
    table.insert(chances, { 'stone', 8 })
    table.insert(chances, { 'uranium-ore', 3 })

    local starting_planet = Public.get_planet()
    if is_modded_pt2 then
        if starting_planet == 'fulgora' then
            table.insert(chances, { 'scrap', 30 })
        end
        if starting_planet == 'vulcanus' then
            table.insert(chances, { 'tungsten-ore', 30 })
            table.insert(chances, { 'calcite', 22 })
        end
    end

    return chances
end

local function set_raffle()
    this.raffle = {}
    for _, t in pairs(get_chances()) do
        for _ = 1, t[2], 1 do
            table.insert(this.raffle, t[1])
        end
    end

    local starting_planet = Public.get_planet()
    if is_modded_pt2 then
        if starting_planet == 'fulgora' then
            table.insert(this.mixed_ores, 'scrap')
        end
        if starting_planet == 'vulcanus' then
            table.insert(this.mixed_ores, 'tungsten-ore')
            table.insert(this.mixed_ores, 'calcite')
        end
    end
end

local function get_amount(position)
    local distance_to_center = math.sqrt(position.x ^ 2 + position.y ^ 2) * 2 + 1500
    distance_to_center = distance_to_center * this.amount_modifier
    local m = (75 + random(0, 50)) * 0.01
    return distance_to_center * m
end

local function is_resource_nearby(surface, position, radius)
    return surface.count_entities_filtered(
        {
            area =
            {
                { position.x - radius, position.y - radius },
                { position.x + radius, position.y + radius }
            },
            type = 'resource',
            limit = 1
        }) > 0
end

local function find_spawn_position(surface, origin)
    if
        not is_resource_nearby(surface, origin, ore_patch_gap)
        and surface.can_place_entity(
            {
                name = 'coal',
                position = origin,
                amount = 1
            })
    then
        return origin
    end

    for radius = 1, spawn_search_radius do
        local candidates = {}

        -- Top / bottom
        for x = -radius, radius do
            candidates[#candidates + 1] =
            {
                x = origin.x + x,
                y = origin.y - radius
            }

            candidates[#candidates + 1] =
            {
                x = origin.x + x,
                y = origin.y + radius
            }
        end

        -- Left / right
        for y = -radius + 1, radius - 1 do
            candidates[#candidates + 1] =
            {
                x = origin.x - radius,
                y = origin.y + y
            }

            candidates[#candidates + 1] =
            {
                x = origin.x + radius,
                y = origin.y + y
            }
        end

        table.shuffle_table(candidates)

        for i = 1, #candidates do
            local position = candidates[i]

            if
                not is_resource_nearby(surface, position, ore_patch_gap)
                and surface.can_place_entity(
                    {
                        name = 'coal',
                        position = position,
                        amount = 1
                    })
            then
                return position
            end
        end
    end

    return nil
end

local function draw_chain(
    surface,
    count,
    ore,
    ore_entities,
    ore_positions,
    blocked_positions
)
    local vectors =
    {
        { 0, -1 },
        { -1, 0 },
        { 1, 0 },
        { 0, 1 }
    }

    local r = random(1, #ore_entities)

    local position =
    {
        x = ore_entities[r].position.x,
        y = ore_entities[r].position.y
    }

    for _ = 1, count do
        table.shuffle_table(vectors)

        local placed = false

        for i = 1, 4 do
            local p =
            {
                x = position.x + vectors[i][1],
                y = position.y + vectors[i][2]
            }

            local key = p.x .. '_' .. p.y

            if
                not ore_positions[key]
                and not blocked_positions[key]
                and surface.can_place_entity(
                    {
                        name = 'coal',
                        position = p,
                        amount = 1
                    })
            then
                position.x = p.x
                position.y = p.y

                ore_positions[key] = true

                local name = ore

                if ore == 'mixed' then
                    name = this.mixed_ores[
                    random(1, #this.mixed_ores)
                    ]
                end

                ore_entities[#ore_entities + 1] =
                {
                    name = name,
                    position = p,
                    amount = get_amount(position)
                }

                placed = true
                break
            end
        end

        if not placed then
            break
        end
    end
end

local function ore_vein(player, entity)
    local surface = entity.surface
    local size = size_raffle[random(1, #size_raffle)]
    local ore = this.raffle[random(1, #this.raffle)]
    local icon
    if prototypes.entity[ore] then
        icon = '[img=entity/' .. ore .. ']'
    else
        icon = ' '
    end

    player.print(
        {
            'rocks_yield_ore_veins.player_print',
            { 'rocks_yield_ore_veins_colors.' .. ore },
            { 'rocks_yield_ore_veins.' .. size[1] },
            { 'rocks_yield_ore_veins.' .. ore },
            icon
        },
        { r = 0.80, g = 0.80, b = 0.80 }
    )

    local origin = find_spawn_position(surface, entity.position)

    if not origin then
        return
    end

    local name = ore
    if ore == 'mixed' then
        name = this.mixed_ores[random(1, #this.mixed_ores)]
    end
    local ore_entities = { { name = name, position = { x = origin.x, y = origin.y }, amount = get_amount(origin) } }

    StatData.get_data(player):increase('ore_veins')

    local ore_positions = { [origin.x .. '_' .. origin.y] = true }
    local blocked_positions = get_blocked_resource_positions(
        surface,
        origin,
        100,
        ore_patch_gap
    )

    local count = random(size[2], size[3])

    for _ = 1, 128, 1 do
        local c = random(math.floor(size[2] * 0.25) + 1, size[2])
        if count < c then
            c = count
        end

        local placed_ore_count = #ore_entities

        draw_chain(
            surface,
            c,
            ore,
            ore_entities,
            ore_positions,
            blocked_positions
        )

        count = count - (#ore_entities - placed_ore_count)

        if count <= 0 then
            break
        end
    end

    for _, e in pairs(ore_entities) do
        surface.create_entity(e)
    end
end

local function on_player_mined_entity(event)
    local entity = event.entity
    if not (entity and entity.valid) then
        return
    end
    if not valid_entities[entity.type] then
        return
    end
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local chance = this.chance

    local is_around_train = Public.is_around_train_simple(player)
    if is_around_train then
        chance = chance / 2
    end

    if random(1, chance) ~= 1 then
        return
    end

    ore_vein(player, entity)
end

local function on_init()
    set_raffle()
end

Event.on_init(on_init)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)

return Public
