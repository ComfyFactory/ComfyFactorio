local Event = require 'utils.event'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'

local math_random = math.random
local math_floor = math.floor
local table_insert = table.insert
local table_shuffle = table.shuffle_table


local valid_entities = {
    ['rock-big'] = true,
    ['rock-huge'] = true,
    ['sand-rock-big'] = true
}

local size_raffle = {
    { 'giant', 500, 1000 },
    { 'huge',  300, 500 },
    { 'big',   150, 300 },
    { 'small', 80,  150 },
    { 'tiny',  50,  80 }
}

local function get_chances()
    local chances = {}
    table_insert(chances, { 'iron-ore', 24 })
    table_insert(chances, { 'copper-ore', 18 })
    table_insert(chances, { 'mixed', 12 })
    table_insert(chances, { 'coal', 14 })
    table_insert(chances, { 'stone', 12 })
    table_insert(chances, { 'uranium-ore', 8 })
    return chances
end

local function set_raffle()
    local this = ScenarioTable.get_table()
    this.rocks_yield_ore_veins.raffle = {}
    for _, t in pairs(get_chances()) do
        for _ = 1, t[2], 1 do
            table_insert(this.rocks_yield_ore_veins.raffle, t[1])
        end
    end
    this.rocks_yield_ore_veins.mixed_ores = { 'iron-ore', 'copper-ore', 'stone', 'coal' }
end

local function get_amount()
    return math_random(20, 200)
end

local function draw_chain(surface, count, ore, ore_entities, ore_positions)
    local this = ScenarioTable.get_table()
    local vectors = { { 0, -0.75 }, { -0.75, 0 }, { 0.75, 0 }, { 0, 0.75 } }
    local r = math_random(1, #ore_entities)
    local position = { x = ore_entities[r].ore.position.x, y = ore_entities[r].ore.position.y }
    for _ = 1, count, 1 do
        table_shuffle(vectors)
        for i = 1, 4, 1 do
            local p = { x = position.x + vectors[i][1], y = position.y + vectors[i][2] }
            -- dispersion will make patches more round
            local dx = (math_random(0, 100) - 50) / 100
            local dy = (math_random(0, 100) - 50) / 100
            local dp = { x = p.x + dx, y = p.y + dy }

            local name = ore
            if ore == 'mixed' then
                name = this.rocks_yield_ore_veins.mixed_ores[math_random(1, #this.rocks_yield_ore_veins.mixed_ores)]
            end
            if surface.can_place_entity({ name = name, position = p, force = 'neutral' }) then
                if math_random(1, 2) == 1 then
                    if not ore_positions[p.x .. '_' .. p.y] then
                        position.x = p.x
                        position.y = p.y
                        ore_positions[p.x .. '_' .. p.y] = true
                        ore_entities[#ore_entities + 1] = { ore = { name = name, position = dp }, amount = get_amount() }
                        break
                    end
                end
            else
                -- existing ore of same name
                if surface.can_fast_replace({ name = name, position = p, force = 'neutral' }) then
                    local amount = get_amount()
                    local deposit = surface.find_entity(name, p)
                    if deposit ~= nil then
                        amount = amount + deposit
                        if not ore_positions[p.x .. '_' .. p.y] then
                            position.x = p.x
                            position.y = p.y
                            ore_positions[p.x .. '_' .. p.y] = true
                            ore_entities[#ore_entities + 1] = { ore = { name = name, position = dp }, amount = amount, fast_replace = true }
                            break
                        end
                    end
                end
            end
        end
    end
end

local function ore_vein(event)
    local this = ScenarioTable.get_table()
    local surface = event.entity.surface
    local size = size_raffle[math_random(1, #size_raffle)]
    local ore = this.rocks_yield_ore_veins.raffle[math_random(1, #this.rocks_yield_ore_veins.raffle)]
    local icon
    if prototypes.entity[ore] then
        icon = '[img=entity/' .. ore .. ']'
    else
        icon = ' '
    end

    local player = game.players[event.player_index]
    for _, p in pairs(game.connected_players) do
        if p.index == player.index then
            p.print(
                {
                    'rocks_yield_ore_veins.player_print',
                    { 'rocks_yield_ore_veins_colors.' .. ore },
                    { 'rocks_yield_ore_veins.' .. size[1] },
                    { 'rocks_yield_ore_veins.' .. ore },
                    icon
                },
                { r = 0.80, g = 0.80, b = 0.80 }
            )
        else
            if p.force == player.force then
                game.print(
                    {
                        'rocks_yield_ore_veins.game_print',
                        '[color=' .. player.chat_color.r .. ',' .. player.chat_color.g .. ',' .. player.chat_color.b .. ']' .. player.name .. '[/color]',
                        { 'rocks_yield_ore_veins.' .. size[1] },
                        { 'rocks_yield_ore_veins.' .. ore },
                        icon
                    },
                    { r = 0.80, g = 0.80, b = 0.80 }
                )
            end
        end
    end

    local position = event.entity.position
    local ore_entities = { { ore = { name = ore, position = { x = position.x, y = position.y } }, amount = get_amount() } }
    if ore == 'mixed' then
        ore_entities = {
            {
                ore = {
                    name = this.rocks_yield_ore_veins.mixed_ores[math_random(1, #this.rocks_yield_ore_veins.mixed_ores)],
                    position = { x = position.x, y = position.y }
                },
                amount = get_amount()
            }
        }
    end

    local ore_positions = { [event.entity.position.x .. '_' .. event.entity.position.y] = true }
    local count = math_random(size[2], size[3])

    for _ = 1, 128, 1 do
        local c = math_random(math_floor(size[2] * 0.25) + 1, size[2])
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

    -- place the ore
    for _, ore_entity in pairs(ore_entities) do
        if ore_entity.fast_replace then
            local e = surface.find_entity(ore_entity.ore.name, ore_entity.ore.position)
            e.amount = ore_entity.amount
        else
            local e = surface.create_entity(ore_entity.ore)
            e.amount = ore_entity.amount
        end
    end
end

local function on_player_mined_entity(event)
    local rocks_yield_ore_veins = ScenarioTable.get('rocks_yield_ore_veins')
    if not rocks_yield_ore_veins then
        return
    end

    local player = game.players[event.player_index]
    if player.force.technologies['steel-processing'].researched == false then
        return
    end
    if not event.entity.valid then
        return
    end
    if not valid_entities[event.entity.name] then
        return
    end
    if math_random(1, rocks_yield_ore_veins.chance) ~= 1 and not ScenarioTable.get('testing_mode') then
        return
    end
    ore_vein(event)
end

local function on_init()
    local this = ScenarioTable.get_table()
    this.rocks_yield_ore_veins = {}
    this.rocks_yield_ore_veins.raffle = {}
    this.rocks_yield_ore_veins.mixed_ores = {}
    this.rocks_yield_ore_veins.chance = 10
    set_raffle()
end

Event.on_init(on_init)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
