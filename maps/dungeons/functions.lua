local Public = {}

local FLOOR_ZERO_ROCK_ORE = 40
local ROCK_ORE_INCREASE_PER_FLOOR = 15
local FLOOR_FOR_MAX_ROCK_ORE = 15
local LOOT_EVOLUTION_SCALE_FACTOR = 0.9
local LOOT_MULTIPLIER = 3000
local EVOLUTION_PER_FLOOR = 0.06

local BiterRaffle = require 'utils.functions.biter_raffle'
local LootRaffle = require 'utils.functions.loot_raffle'
local Get_noise = require 'utils.get_noise'
local DungeonsTable = require 'maps.dungeons.table'

local table_shuffle_table = table.shuffle_table
local math_random = math.random
local math_abs = math.abs
local math_floor = math.floor

-- Epic loot chest is 0.05 * (floor + 1) * 4000 * 8 + rand(512,1024)
-- So floor 0 = 2112 .. 2624
-- floor 4 = 8512 .. 9024
-- floor 9 = 16512 .. 17024
-- floor 19 = 32512 .. 33024
LootRaffle.TweakItemWorth(
    {
        ['modular-armor'] = 512, -- floors 1-5 from research.lua
        ['power-armor'] = 4096, -- floors 8-13 from research.lua
        ['personal-laser-defense-equipment'] = 1536, -- floors 10-14 from research.lua
        ['power-armor-mk2'] = 24576, -- floors 14-21 from research.lua
        -- reduce ammo/follower rates
        ['firearm-magazine'] = 8,
        ['piercing-rounds-magazine'] = 16,
        ['uranium-rounds-magazine'] = 128,
        ['shotgun-shell'] = 8,
        ['piercing-shotgun-shell'] = 64,
        ['flamethrower-ammo'] = 128,
        ['rocket'] = 16,
        ['explosive-rocket'] = 128,
        ['grenade'] = 32,
        ['cluster-grenade'] = 128,
        ['poison-capsule'] = 64,
        ['slowdown-capsule'] = 32,
        ['defender-capsule'] = 96,
        ['distractor-capsule'] = 512,
        ['destroyer-capsule'] = 2048
    }
)

function Public.get_dungeon_evolution_factor(surface_index)
    local dungeontable = DungeonsTable.get_dungeontable()
    local e = dungeontable.depth[surface_index] * EVOLUTION_PER_FLOOR / 100
    if dungeontable.tiered then
        e = math.min(e, (surface_index - dungeontable.original_surface_index) * EVOLUTION_PER_FLOOR + EVOLUTION_PER_FLOOR)
    end
    return e
end

function Public.get_loot_evolution_factor(surface_index)
    return Public.get_dungeon_evolution_factor(surface_index) * LOOT_EVOLUTION_SCALE_FACTOR
end

local function blacklist(surface_index, special)
    local dungeontable = DungeonsTable.get_dungeontable()
    local evolution_factor = Public.get_loot_evolution_factor(surface_index)
    if special then
        -- treasure rooms act as if they are 3 levels farther down.
        evolution_factor = evolution_factor + 3 * EVOLUTION_PER_FLOOR
    end
    local blacklists = {}
    --general unused items on dungeons
    blacklists['cliff-explosives'] = true
    --items that would trivialize stuff if dropped too early
    if dungeontable.item_blacklist then
        if evolution_factor < 0.9 then -- floor 18
            blacklists['power-armor-mk2'] = true
            blacklists['fusion-reactor-equipment'] = true
            blacklists['rocket-silo'] = true
            blacklists['atomic-bomb'] = true
        end
        if evolution_factor < 0.7 then -- floor 14
            blacklists['energy-shield-mk2-equipment'] = true
            blacklists['personal-laser-defense-equipment'] = true
            blacklists['personal-roboport-mk2-equipment'] = true
            blacklists['battery-mk2-equipment'] = true
            blacklists['artillery-turret'] = true
            blacklists['artillery-wagon'] = true
            blacklists['power-armor'] = true
        end
        if evolution_factor < 0.55 then -- floor 11
            blacklists['discharge-defense-equipment'] = true
            blacklists['discharge-defense-remote'] = true
            blacklists['nuclear-reactor'] = true
        end
        if evolution_factor < 0.4 then -- floor 8
            blacklists['steam-turbine'] = true
            blacklists['heat-exchanger'] = true
            blacklists['heat-pipe'] = true
            blacklists['express-loader'] = true
            blacklists['modular-armor'] = true
            blacklists['energy-shield-equipment'] = true
            blacklists['battery-equipment'] = true
        end
    end
    return blacklists
end

local function special_loot(value)
    local items = {
        [1] = {item = 'tank-machine-gun', value = 16384},
        [2] = {item = 'tank-cannon', value = 32728},
        [3] = {item = 'artillery-wagon-cannon', value = 65536}
    }
    if math_random(1, 20) == 1 then
        local roll = math_random(1, #items)
        if items[roll].value < value then
            return {loot = {name = items[roll].item, count = 1}, value = value - items[roll].value}
        end
    end
    return {loot = nil, value = value}
end

function Public.roll_spawner_name()
    if math_random(1, 3) == 1 then
        return 'spitter-spawner'
    end
    return 'biter-spawner'
end

function Public.roll_worm_name(surface_index)
    return BiterRaffle.roll('worm', Public.get_dungeon_evolution_factor(surface_index))
end

function Public.get_crude_oil_amount(surface_index)
    local dungeontable = DungeonsTable.get_dungeontable()
    local amount = math_random(200000, 400000) + Public.get_dungeon_evolution_factor(surface_index) * 500000
    if dungeontable.tiered then
        amount = amount / 4
    end
    return amount
end

function Public.get_common_resource_amount(surface_index)
    local dungeontable = DungeonsTable.get_dungeontable()
    local amount = math_random(350, 700) + Public.get_dungeon_evolution_factor(surface_index) * 16000
    if dungeontable.tiered then
        amount = amount / 8
        local floor = surface_index - dungeontable.original_surface_index
        -- rocks stop going up here, so more than make up for it in resources on ground
        if floor > FLOOR_FOR_MAX_ROCK_ORE then
            amount = amount * (1 + (floor - FLOOR_FOR_MAX_ROCK_ORE) / 10)
        end
    end
    return amount
end

function Public.get_base_loot_value(surface_index)
    return Public.get_loot_evolution_factor(surface_index) * LOOT_MULTIPLIER
end

local function get_loot_value(surface_index, multiplier)
    return Public.get_base_loot_value(surface_index) * multiplier
end

function Public.common_loot_crate(surface, position, special)
    local item_stacks = LootRaffle.roll(get_loot_value(surface.index, 1) + math_random(8, 16), 16, blacklist(surface.index, special))
    local container = surface.create_entity({name = 'wooden-chest', position = position, force = 'neutral'})
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
    container.minable = false
end

function Public.uncommon_loot_crate(surface, position, special)
    local item_stacks = LootRaffle.roll(get_loot_value(surface.index, 2) + math_random(32, 64), 16, blacklist(surface.index, special))
    local container = surface.create_entity({name = 'iron-chest', position = position, force = 'neutral'})
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
    container.minable = false
end

function Public.rare_loot_crate(surface, position, special)
    local item_stacks = LootRaffle.roll(get_loot_value(surface.index, 4) + math_random(128, 256), 32, blacklist(surface.index, special))
    local container = surface.create_entity({name = 'steel-chest', position = position, force = 'neutral'})
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
    container.minable = false
end

function Public.epic_loot_crate(surface, position, special)
    local dungeontable = DungeonsTable.get_dungeontable()
    local loot_value = get_loot_value(surface.index, 8) + math_random(512, 1024)
    if special then
        loot_value = loot_value * 1.5
    end
    local bonus_loot = nil
    if dungeontable.tiered and loot_value > 32000 and Public.get_dungeon_evolution_factor(surface.index) > 1 then
        local bonus = special_loot(loot_value)
        bonus_loot = bonus.loot
        loot_value = bonus.value
    end
    local item_stacks = LootRaffle.roll(loot_value, 48, blacklist(surface.index, special))
    local container = surface.create_entity({name = 'blue-chest', position = position, force = 'neutral'})
    if bonus_loot then
        container.insert(bonus_loot)
    end
    if item_stacks then
        for _, item_stack in pairs(item_stacks) do
            container.insert(item_stack)
        end
    end
    container.minable = false
end

function Public.crash_site_chest(surface, position, special)
    local item_stacks = LootRaffle.roll(get_loot_value(surface.index, 3) + math_random(160, 320), 48, blacklist(surface.index, special))
    local container = surface.create_entity({name = 'crash-site-chest-' .. math_random(1, 2), position = position, force = 'neutral'})
    for _, item_stack in pairs(item_stacks) do
        container.insert(item_stack)
    end
end

function Public.market(surface, position)
    local offers = {
        {price = {{'pistol', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(3, 4)}},
        {price = {{'submachine-gun', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(15, 20)}},
        {price = {{'shotgun', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(12, 18)}},
        {price = {{'combat-shotgun', 1}}, offer = {type = 'give-item', item = 'steel-plate', count = math_random(7, 10)}},
        {price = {{'rocket-launcher', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(7, 10)}},
        {price = {{'flamethrower', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(12, 18)}},
        {price = {{'light-armor', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(15, 20)}},
        {price = {{'heavy-armor', 1}}, offer = {type = 'give-item', item = 'steel-plate', count = math_random(15, 20)}},
        {price = {{'modular-armor', 1}}, offer = {type = 'give-item', item = 'advanced-circuit', count = math_random(15, 20)}},
        {price = {{'night-vision-equipment', 1}}, offer = {type = 'give-item', item = 'steel-plate', count = math_random(3, 4)}},
        {price = {{'solar-panel-equipment', 1}}, offer = {type = 'give-item', item = 'copper-plate', count = math_random(15, 25)}},
        {price = {{'red-wire', 100}}, offer = {type = 'give-item', item = 'copper-cable', count = math_random(75, 100)}},
        {price = {{'green-wire', 100}}, offer = {type = 'give-item', item = 'copper-cable', count = math_random(75, 100)}},
        {price = {{'empty-barrel', 10}}, offer = {type = 'give-item', item = 'steel-plate', count = math_random(6, 8)}},
        {price = {{'arithmetic-combinator', 10}}, offer = {type = 'give-item', item = 'electronic-circuit', count = math_random(15, 25)}},
        {price = {{'decider-combinator', 10}}, offer = {type = 'give-item', item = 'electronic-circuit', count = math_random(15, 25)}},
        {price = {{'constant-combinator', 10}}, offer = {type = 'give-item', item = 'electronic-circuit', count = math_random(9, 12)}},
        {price = {{'power-switch', 10}}, offer = {type = 'give-item', item = 'electronic-circuit', count = math_random(9, 12)}},
        {price = {{'programmable-speaker', 10}}, offer = {type = 'give-item', item = 'electronic-circuit', count = math_random(20, 30)}},
        {price = {{'belt-immunity-equipment', 1}}, offer = {type = 'give-item', item = 'advanced-circuit', count = math_random(2, 3)}},
        {price = {{'discharge-defense-remote', 1}}, offer = {type = 'give-item', item = 'electronic-circuit', count = 1}},
        {price = {{'rail-signal', 10}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(30, 40)}},
        {price = {{'rail-chain-signal', 10}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(30, 40)}},
        {price = {{'train-stop', 10}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(75, 100)}},
        {price = {{'locomotive', 1}}, offer = {type = 'give-item', item = 'steel-plate', count = math_random(30, 40)}},
        {price = {{'cargo-wagon', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(30, 40)}},
        {price = {{'fluid-wagon', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(30, 40)}},
        {price = {{'car', 1}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(15, 20)}},
        {price = {{'radar', 10}}, offer = {type = 'give-item', item = 'iron-plate', count = math_random(15, 20)}},
        {price = {{'cannon-shell', 10}}, offer = {type = 'give-item', item = 'steel-plate', count = math_random(7, 10)}},
        {price = {{'uranium-cannon-shell', 10}}, offer = {type = 'give-item', item = 'uranium-238', count = math_random(7, 10)}}
    }
    table.shuffle_table(offers)
    local market = surface.create_entity({name = 'market', position = position, force = 'neutral'})
    market.destructible = false
    market.minable = false
    local text = 'Buys: '
    for i = 1, math.random(6, 10), 1 do
        market.add_market_item(offers[i])
        text = text .. '[item=' .. offers[i].price[1][1] .. '],'
    end
    game.forces.player.add_chart_tag(surface, {position = position, text = text})
end

function Public.laboratory(surface, position)
    local lab = surface.create_entity({name = 'lab', position = position, force = 'neutral'})
    lab.destructible = false
    lab.minable = false
    local evo = Public.get_dungeon_evolution_factor(surface.index)
    local amount = math.min(200, math_floor(evo * 100))
    amount = math.max(amount, 1)
    lab.insert({name = 'automation-science-pack', count = math.min(200, math_floor(amount * 5))})
    if evo >= 0.1 then
        lab.insert({name = 'logistic-science-pack', count = math.min(200, math_floor(amount * 4))})
    end
    if evo >= 0.2 then
        lab.insert({name = 'military-science-pack', count = math.min(200, math_floor(amount * 3))})
    end
    if evo >= 0.4 then
        lab.insert({name = 'chemical-science-pack', count = math.min(200, math_floor(amount * 2))})
    end
    if evo >= 0.6 then
        lab.insert({name = 'production-science-pack', count = amount})
    end
    if evo >= 0.8 then
        lab.insert({name = 'utility-science-pack', count = amount})
    end
    if evo >= 1 then
        lab.insert({name = 'space-science-pack', count = amount})
    end
end

function Public.add_room_loot_crates(surface, room)
    if not room.room_border_tiles[1] then
        return
    end
    for key, tile in pairs(room.room_tiles) do
        if math_random(1, 384) == 1 then
            Public.common_loot_crate(surface, tile.position)
        else
            if math_random(1, 1024) == 1 then
                Public.uncommon_loot_crate(surface, tile.position)
            else
                if math_random(1, 4096) == 1 then
                    Public.rare_loot_crate(surface, tile.position)
                else
                    if math_random(1, 16384) == 1 then
                        Public.epic_loot_crate(surface, tile.position)
                    end
                end
            end
        end
    end
end

function Public.set_spawner_tier(spawner, surface_index)
    local dungeontable = DungeonsTable.get_dungeontable()
    local tier = math_floor(Public.get_dungeon_evolution_factor(surface_index) * 8 - math_random(0, 8)) + 1
    if tier < 1 then
        tier = 1
    end
    dungeontable.spawner_tier[spawner.unit_number] = tier
    --[[
	rendering.draw_text{
		text = "-Tier " .. tier .. "-",
		surface = spawner.surface,
		target = spawner,
		target_offset = {0, -2.65},
		color = {25, 0, 100, 255},
		scale = 1.25,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	]]
end

function Public.spawn_random_biter(surface, position)
    local dungeontable = DungeonsTable.get_dungeontable()
    local name = BiterRaffle.roll('mixed', Public.get_dungeon_evolution_factor(surface.index))
    local non_colliding_position = surface.find_non_colliding_position(name, position, 16, 1)
    local unit
    if non_colliding_position then
        unit = surface.create_entity({name = name, position = non_colliding_position, force = dungeontable.enemy_forces[surface.index]})
    else
        unit = surface.create_entity({name = name, position = position, force = dungeontable.enemy_forces[surface.index]})
    end
    unit.ai_settings.allow_try_return_to_spawner = false
    unit.ai_settings.allow_destroy_when_commands_fail = false
end

function Public.place_border_rock(surface, position)
    local vectors = {{0, -1}, {0, 1}, {1, 0}, {-1, 0}}
    table_shuffle_table(vectors)
    local key = false
    for k, v in pairs(vectors) do
        local tile = surface.get_tile({position.x + v[1], position.y + v[2]})
        if tile.name == 'out-of-map' then
            key = k
            break
        end
    end
    local pos = {x = position.x + 0.5, y = position.y + 0.5}
    if key then
        pos = {pos.x + vectors[key][1] * 0.45, pos.y + vectors[key][2] * 0.45}
    end
    surface.create_entity({name = 'rock-big', position = pos})
end

function Public.create_scrap(surface, position)
    local scraps = {
        'crash-site-spaceship-wreck-small-1',
        'crash-site-spaceship-wreck-small-1',
        'crash-site-spaceship-wreck-small-2',
        'crash-site-spaceship-wreck-small-2',
        'crash-site-spaceship-wreck-small-3',
        'crash-site-spaceship-wreck-small-3',
        'crash-site-spaceship-wreck-small-4',
        'crash-site-spaceship-wreck-small-4',
        'crash-site-spaceship-wreck-small-5',
        'crash-site-spaceship-wreck-small-5',
        'crash-site-spaceship-wreck-small-6'
    }
    surface.create_entity({name = scraps[math_random(1, #scraps)], position = position, force = 'neutral'})
end

function Public.on_marked_for_deconstruction(event)
    local disabled_for_deconstruction = {
        ['fish'] = true,
        ['rock-huge'] = true,
        ['rock-big'] = true,
        ['sand-rock-big'] = true,
        ['crash-site-spaceship-wreck-small-1'] = true,
        ['crash-site-spaceship-wreck-small-2'] = true,
        ['crash-site-spaceship-wreck-small-3'] = true,
        ['crash-site-spaceship-wreck-small-4'] = true,
        ['crash-site-spaceship-wreck-small-5'] = true,
        ['crash-site-spaceship-wreck-small-6'] = true
    }
    if event.entity and event.entity.valid then
        if disabled_for_deconstruction[event.entity.name] then
            event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
        end
    end
end

local function get_ore_amount(surface_index)
    local floor = surface_index - DungeonsTable.get_dungeontable().original_surface_index

    local amount = FLOOR_ZERO_ROCK_ORE + ROCK_ORE_INCREASE_PER_FLOOR * math.min(FLOOR_FOR_MAX_ROCK_ORE, floor)
    return math_random(math_floor(amount * 0.7), math_floor(amount * 1.3))
end

local function reward_ores(amount, mined_loot, surface, player, entity)
    local a = 0
    if player then
        a = player.insert {name = mined_loot, count = amount}
    end
    amount = amount - a
    if amount > 0 then
        if amount >= 50 then
            for i = 1, math_floor(amount / 50), 1 do
                local e = surface.create_entity {name = 'item-on-ground', position = entity.position, stack = {name = mined_loot, count = 50}}
                if e and e.valid then
                    e.to_be_looted = true
                end
                amount = amount - 50
            end
        end
        if amount > 0 then
            if amount < 5 then
                surface.spill_item_stack(entity.position, {name = mined_loot, count = amount}, true)
            else
                local e = surface.create_entity {name = 'item-on-ground', position = entity.position, stack = {name = mined_loot, count = amount}}
                if e and e.valid then
                    e.to_be_looted = true
                end
            end
        end
    end
end

local function flying_text(surface, position, text, color)
    surface.create_entity(
        {
            name = 'flying-text',
            position = {position.x, position.y - 0.5},
            text = text,
            color = color
        }
    )
end

function Public.rocky_loot(event)
    if not event.entity or not event.entity.valid then
        return
    end
    local allowed = {
        ['rock-big'] = true,
        ['rock-huge'] = true,
        ['sand-rock-big'] = true
    }
    if not allowed[event.entity.name] then
        return
    end
    local player = game.players[event.player_index]
    local amount = math.ceil(get_ore_amount(player.surface.index))
    local rock_mining
    local floor = player.surface.index - DungeonsTable.get_dungeontable().original_surface_index
    if floor < 10 then
        -- early game science uses less copper and more iron/stone
        rock_mining = {'iron-ore', 'iron-ore', 'iron-ore', 'iron-ore', 'copper-ore', 'copper-ore', 'stone', 'stone', 'coal', 'coal', 'coal'}
    else
        -- end game prod 3 base uses (for all-sciences) 1 stone : 2 coal : 3.5 copper : 4.5 iron
        -- this is a decent approximation which will still require some modest amount of mining setup
        -- coal gets 3 to compensate for coal-based power generation
        rock_mining = {'iron-ore', 'iron-ore', 'iron-ore', 'iron-ore', 'copper-ore', 'copper-ore', 'copper-ore', 'stone', 'coal', 'coal', 'coal'}
    end
    local mined_loot = rock_mining[math_random(1, #rock_mining)]
    local text = '+' .. amount .. ' [item=' .. mined_loot .. ']'
    flying_text(player.surface, player.position, text, {r = 0.98, g = 0.66, b = 0.22})
    reward_ores(amount, mined_loot, player.surface, player, player)
    event.buffer.clear()
end

function Public.mining_events(entity)
    if math_random(1, 16) == 1 then
        Public.spawn_random_biter(entity.surface, entity.position)
        return
    end
    if math_random(1, 24) == 1 then
        Public.common_loot_crate(entity.surface, entity.position)
        return
    end
    if math_random(1, 128) == 1 then
        Public.uncommon_loot_crate(entity.surface, entity.position)
        return
    end
    if math_random(1, 512) == 1 then
        Public.rare_loot_crate(entity.surface, entity.position)
        return
    end
    if math_random(1, 1024) == 1 then
        Public.epic_loot_crate(entity.surface, entity.position)
        return
    end
end

function Public.draw_spawn(surface)
    local dungeontable = DungeonsTable.get_dungeontable()
    local spawn_size = dungeontable.spawn_size

    for _, e in pairs(surface.find_entities({{spawn_size * -1, spawn_size * -1}, {spawn_size, spawn_size}})) do
        e.destroy()
    end

    local tiles = {}
    local i = 1
    for x = spawn_size * -1, spawn_size, 1 do
        for y = spawn_size * -1, spawn_size, 1 do
            local position = {x = x, y = y}
            if math_abs(position.x) < 2 or math_abs(position.y) < 2 then
                tiles[i] = {name = 'dirt-7', position = position}
                i = i + 1
                tiles[i] = {name = 'stone-path', position = position}
                i = i + 1
            else
                tiles[i] = {name = 'dirt-7', position = position}
                i = i + 1
            end
        end
    end
    surface.set_tiles(tiles, true)

    tiles = {}
    i = 1
    for x = -2, 2, 1 do
        for y = -2, 2, 1 do
            local position = {x = x, y = y}
            if math_abs(position.x) > 1 or math_abs(position.y) > 1 then
                tiles[i] = {name = 'black-refined-concrete', position = position}
                i = i + 1
            else
                tiles[i] = {name = 'purple-refined-concrete', position = position}
                i = i + 1
            end
        end
    end
    surface.set_tiles(tiles, true)

    tiles = {}
    i = 1
    for x = spawn_size * -1, spawn_size, 1 do
        for y = spawn_size * -1, spawn_size, 1 do
            local position = {x = x, y = y}
            local r = math.sqrt(position.x ^ 2 + position.y ^ 2)
            if r < 2 then
                tiles[i] = {name = 'purple-refined-concrete', position = position}
                --tiles[i] = {name = "water-mud", position = position}
                i = i + 1
            else
                if r < 2.5 then
                    tiles[i] = {name = 'black-refined-concrete', position = position}
                    --tiles[i] = {name = "water-shallow", position = position}
                    i = i + 1
                else
                    if r < 4.5 then
                        tiles[i] = {name = 'dirt-7', position = position}
                        i = i + 1
                        tiles[i] = {name = 'concrete', position = position}
                        i = i + 1
                    end
                end
            end
        end
    end
    surface.set_tiles(tiles, true)

    local decoratives = {'brown-hairy-grass', 'brown-asterisk', 'brown-fluff', 'brown-fluff-dry', 'brown-asterisk', 'brown-fluff', 'brown-fluff-dry'}
    local a = spawn_size * -1 + 1
    local b = spawn_size - 1
    for _, decorative_name in pairs(decoratives) do
        local seed = game.surfaces[surface.index].map_gen_settings.seed + math_random(1, 1000000)
        for x = a, b, 1 do
            for y = a, b, 1 do
                local position = {x = x + 0.5, y = y + 0.5}
                if surface.get_tile(position).name == 'dirt-7' or math_random(1, 5) == 1 then
                    local noise = Get_noise('decoratives', position, seed)
                    if math_abs(noise) > 0.37 then
                        surface.create_decoratives {
                            check_collision = false,
                            decoratives = {{name = decorative_name, position = position, amount = math.floor(math.abs(noise * 3)) + 1}}
                        }
                    end
                end
            end
        end
    end

    local entities = {}
    i = 1
    for x = spawn_size * -1 - 16, spawn_size + 16, 1 do
        for y = spawn_size * -1 - 16, spawn_size + 16, 1 do
            local position = {x = x, y = y}
            if position.x <= spawn_size and position.y <= spawn_size and position.x >= spawn_size * -1 and position.y >= spawn_size * -1 then
                if position.x == spawn_size then
                    entities[i] = {name = 'rock-big', position = {position.x + 0.95, position.y}}
                    i = i + 1
                end
                if position.y == spawn_size then
                    entities[i] = {name = 'rock-big', position = {position.x, position.y + 0.95}}
                    i = i + 1
                end
                if position.x == spawn_size * -1 or position.y == spawn_size * -1 then
                    entities[i] = {name = 'rock-big', position = position}
                    i = i + 1
                end
            end
        end
    end

    for k, e in pairs(entities) do
        if k % 3 > 0 then
            surface.create_entity(e)
        end
    end

    if dungeontable.tiered then
        if surface.index > dungeontable.original_surface_index then
            table.insert(dungeontable.transport_surfaces, surface.index)
            dungeontable.transport_chests_inputs[surface.index] = {}
            for iv = 1, 2, 1 do
                local chest = surface.create_entity({name = 'blue-chest', position = {-12 + iv * 8, -4}, force = 'player'})
                dungeontable.transport_chests_inputs[surface.index][iv] = chest
                chest.destructible = false
                chest.minable = false
            end
            dungeontable.transport_poles_outputs[surface.index] = {}
            for ix = 1, 2, 1 do
                local pole = surface.create_entity({name = 'constant-combinator', position = {-15 + ix * 10, -5}, force = 'player'})
                dungeontable.transport_poles_outputs[surface.index][ix] = pole
                pole.destructible = false
                pole.minable = false
            end
        end
        dungeontable.transport_chests_outputs[surface.index] = {}
        for ic = 1, 2, 1 do
            local chest = surface.create_entity({name = 'red-chest', position = {-12 + ic * 8, 4}, force = 'player'})
            dungeontable.transport_chests_outputs[surface.index][ic] = chest
            chest.destructible = false
            chest.minable = false
        end
        dungeontable.transport_poles_inputs[surface.index] = {}
        for ib = 1, 2, 1 do
            local pole = surface.create_entity({name = 'medium-electric-pole', position = {-15 + ib * 10, 5}, force = 'player'})
            dungeontable.transport_poles_inputs[surface.index][ib] = pole
            pole.destructible = false
            pole.minable = false
        end
    end

    local trees = {'dead-grey-trunk', 'dead-tree-desert', 'dry-hairy-tree', 'dry-tree', 'tree-04'}
    local size_of_trees = #trees
    local r = 4
    for x = spawn_size * -1, spawn_size, 1 do
        for y = spawn_size * -1, spawn_size, 1 do
            local position = {x = x + 0.5, y = y + 0.5}
            if position.x > 5 and position.y > 5 and math_random(1, r) == 1 then
                surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
            end
            if position.x <= -4 and position.y <= -4 and math_random(1, r) == 1 then
                surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
            end
            if position.x > 5 and position.y <= -4 and math_random(1, r) == 1 then
                surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
            end
            if position.x <= -4 and position.y > 5 and math_random(1, r) == 1 then
                surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
            end
        end
    end
    surface.set_tiles(tiles, true)
end

return Public
