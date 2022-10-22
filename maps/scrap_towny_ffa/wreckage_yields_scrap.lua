local Event = require 'utils.event'
local Scrap = require 'maps.scrap_towny_ffa.scrap'

local insert = table.insert
local random = math.random

local entity_loot_chance = {
    {name = 'advanced-circuit', chance = 150},
    {name = 'battery', chance = 150},
    {name = 'cannon-shell', chance = 50},
    {name = 'copper-cable', chance = 5000},
    {name = 'copper-plate', chance = 2500},
    {name = 'crude-oil-barrel', chance = 500},
    {name = 'defender-capsule', chance = 100},
    {name = 'destroyer-capsule', chance = 20},
    {name = 'distractor-capsule', chance = 40},
    {name = 'electric-engine-unit', chance = 20},
    {name = 'electronic-circuit', chance = 1500},
    {name = 'empty-barrel', chance = 100},
    {name = 'engine-unit', chance = 50},
    {name = 'explosive-cannon-shell', chance = 50},
    {name = 'explosives', chance = 50},
    {name = 'grenade', chance = 100},
    {name = 'heavy-oil-barrel', chance = 200},
    {name = 'iron-gear-wheel', chance = 5000},
    {name = 'iron-plate', chance = 5000},
    {name = 'iron-stick', chance = 500},
    {name = 'land-mine', chance = 30},
    {name = 'light-oil-barrel', chance = 200},
    {name = 'lubricant-barrel', chance = 200},
    {name = 'nuclear-fuel', chance = 20},
    {name = 'petroleum-gas-barrel', chance = 300},
    {name = 'pipe', chance = 1000},
    {name = 'pipe-to-ground', chance = 100},
    {name = 'plastic-bar', chance = 50},
    {name = 'processing-unit', chance = 20},
    {name = 'rocket-fuel', chance = 50},
    {name = 'solid-fuel', chance = 1000},
    {name = 'steel-plate', chance = 1500},
    {name = 'sulfuric-acid-barrel', chance = 150},
    {name = 'uranium-fuel-cell', chance = 10},
    {name = 'water-barrel', chance = 100},
    {name = 'tank', chance = 1},
    {name = 'car', chance = 5}
}

-- positive numbers can scale, 0 is disabled, and negative numbers are fixed absolute values
local entity_loot_amounts = {
    ['advanced-circuit'] = 6,
    ['battery'] = 2,
    ['cannon-shell'] = 2,
    ['copper-cable'] = 24,
    ['copper-plate'] = 16,
    ['crude-oil-barrel'] = 3,
    ['defender-capsule'] = 2,
    ['destroyer-capsule'] = 0.3,
    ['distractor-capsule'] = 0.3,
    ['electric-engine-unit'] = 2,
    ['electronic-circuit'] = 8,
    ['empty-barrel'] = 3,
    ['engine-unit'] = 2,
    ['explosive-cannon-shell'] = 1,
    ['explosives'] = 4,
    ['green-wire'] = 8,
    ['grenade'] = 6,
    ['heat-pipe'] = 1,
    ['heavy-oil-barrel'] = 3,
    ['iron-gear-wheel'] = 8,
    ['iron-plate'] = 16,
    ['iron-stick'] = 16,
    ['land-mine'] = 6,
    ['light-oil-barrel'] = 3,
    ['lubricant-barrel'] = 3,
    ['nuclear-fuel'] = 0.1,
    ['petroleum-gas-barrel'] = 3,
    ['pipe'] = 8,
    ['pipe-to-ground'] = 1,
    ['plastic-bar'] = 4,
    ['processing-unit'] = 2,
    ['red-wire'] = 8,
    ['rocket-fuel'] = 0.3,
    ['solid-fuel'] = 4,
    ['steel-plate'] = 4,
    ['sulfuric-acid-barrel'] = 3,
    ['uranium-fuel-cell'] = 0.3,
    ['water-barrel'] = 3,
    ['tank'] = -1,
    ['car'] = -1
}

local scrap_raffle = {}
for _, t in pairs(entity_loot_chance) do
    for _ = 1, t.chance, 1 do
        insert(scrap_raffle, t.name)
    end
end

local size_of_scrap_raffle = #scrap_raffle

local function on_player_mined_entity(event)
    local entity = event.entity
    local buffer = event.buffer
    if not entity.valid then
        return
    end
    local position = entity.position
    if not Scrap.is_scrap(entity) then
        return
    end
    if entity.name == 'crash-site-chest-1' or entity.name == 'crash-site-chest-2' then
        return
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local enemy = game.forces.enemy

    -- scrap entities drop loot
    buffer.clear()

    local scrap = scrap_raffle[random(1, size_of_scrap_raffle)]

    local scrap_amount_modifier = 3
    local amount_bonus = scrap_amount_modifier * (enemy.evolution_factor * 2) + (player.force.mining_drill_productivity_bonus * 2)
    local amount
    if entity_loot_amounts[scrap] <= 0 then
        amount = math.abs(entity_loot_amounts[scrap])
    else
        local m1 = 0.3 + (amount_bonus * 0.3)
        local m2 = 1.7 + (amount_bonus * 1.7)
        local r1 = math.ceil(entity_loot_amounts[scrap] * m1)
        local r2 = math.ceil(entity_loot_amounts[scrap] * m2)
        amount = random(r1, r2)
    end

    local inserted_count = player.insert({name = scrap, count = amount})

    if inserted_count ~= amount then
        local amount_to_spill = amount - inserted_count
        entity.surface.spill_item_stack(position, {name = scrap, count = amount_to_spill}, true)
    end

    entity.surface.create_entity(
        {
            name = 'flying-text',
            position = position,
            text = '+' .. amount .. ' [img=item/' .. scrap .. ']',
            color = {r = 0.98, g = 0.66, b = 0.22}
        }
    )
end

Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
