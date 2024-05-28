local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local Global = require 'utils.global'
local StatData = require 'utils.datastore.statistics'
StatData.add_normalize('ore_veins', 'Ore veins located'):set_tooltip('Amount of ore veins located by the player.')

local random = math.random

local this = {
    raffle = {},
    mixed_ores = {},
    chance = 512,
    amount_modifier = 1
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local valid_entities = {
    ['simple-entity'] = true,
    ['tree'] = true,
    ['simple-entity-with-owner'] = true
}

local size_raffle = {
    {'giant', 65, 96},
    {'huge', 33, 64},
    {'big', 17, 32},
    {'small', 9, 16},
    {'tiny', 4, 8}
}

local function get_chances()
    local chances = {}

    table.insert(chances, {'iron-ore', 25})
    table.insert(chances, {'copper-ore', 18})
    table.insert(chances, {'mixed', 15})
    table.insert(chances, {'coal', 14})
    table.insert(chances, {'stone', 8})
    table.insert(chances, {'uranium-ore', 3})

    return chances
end

local function set_raffle()
    this.raffle = {}
    for _, t in pairs(get_chances()) do
        for _ = 1, t[2], 1 do
            table.insert(this.raffle, t[1])
        end
    end

    this.mixed_ores = {'iron-ore', 'copper-ore', 'stone', 'coal'}
end

local function get_amount(position)
    local distance_to_center = math.sqrt(position.x ^ 2 + position.y ^ 2) * 2 + 1500
    distance_to_center = distance_to_center * this.amount_modifier
    local m = (75 + random(0, 50)) * 0.01
    return distance_to_center * m
end

local function draw_chain(surface, count, ore, ore_entities, ore_positions)
    local vectors = {{0, -1}, {-1, 0}, {1, 0}, {0, 1}}
    local r = random(1, #ore_entities)
    local position = {x = ore_entities[r].position.x, y = ore_entities[r].position.y}
    for _ = 1, count, 1 do
        table.shuffle_table(vectors)
        for i = 1, 4, 1 do
            local p = {x = position.x + vectors[i][1], y = position.y + vectors[i][2]}
            if surface.can_place_entity({name = 'coal', position = p, amount = 1}) then
                if not ore_positions[p.x .. '_' .. p.y] then
                    position.x = p.x
                    position.y = p.y
                    ore_positions[p.x .. '_' .. p.y] = true
                    local name = ore
                    if ore == 'mixed' then
                        name = this.mixed_ores[random(1, #this.mixed_ores)]
                    end
                    ore_entities[#ore_entities + 1] = {name = name, position = p, amount = get_amount(position)}
                    break
                end
            end
        end
    end
end

local function ore_vein(player, entity)
    local surface = entity.surface
    local size = size_raffle[random(1, #size_raffle)]
    local ore = this.raffle[random(1, #this.raffle)]
    local icon
    if game.entity_prototypes[ore] then
        icon = '[img=entity/' .. ore .. ']'
    else
        icon = ' '
    end

    player.print(
        {
            'rocks_yield_ore_veins.player_print',
            {'rocks_yield_ore_veins_colors.' .. ore},
            {'rocks_yield_ore_veins.' .. size[1]},
            {'rocks_yield_ore_veins.' .. ore},
            icon
        },
        {r = 0.80, g = 0.80, b = 0.80}
    )

    local ore_entities = {{name = ore, position = {x = entity.position.x, y = entity.position.y}, amount = get_amount(entity.position)}}
    if ore == 'mixed' then
        ore_entities = {
            {
                name = this.mixed_ores[random(1, #this.mixed_ores)],
                position = {x = entity.position.x, y = entity.position.y},
                amount = get_amount(entity.position)
            }
        }
    end

    StatData:get_data(player):increase('ore_veins')

    local ore_positions = {[entity.position.x .. '_' .. entity.position.y] = true}
    local count = random(size[2], size[3])

    for _ = 1, 128, 1 do
        local c = random(math.floor(size[2] * 0.25) + 1, size[2])
        if count < c then
            c = count
        end

        local placed_ore_count = #ore_entities

        draw_chain(surface, c, ore, ore_entities, ore_positions)

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
