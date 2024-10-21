local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local RPG = require 'modules.rpg.main'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local StatData = require 'utils.datastore.statistics'
local insert = table.insert
local floor = math.floor
local random = math.random

local coin_yield = {
    ['behemoth-biter'] = 5,
    ['behemoth-spitter'] = 5,
    ['behemoth-worm-turret'] = 10,
    ['big-biter'] = 3,
    ['big-spitter'] = 3,
    ['big-worm-turret'] = 16,
    ['biter-spawner'] = 32,
    ['medium-biter'] = 2,
    ['medium-spitter'] = 2,
    ['medium-worm-turret'] = 4,
    ['small-biter'] = 1,
    ['small-spitter'] = 1,
    ['small-worm-turret'] = 2,
    ['spitter-spawner'] = 32
}

local entities_that_earn_coins = {
    ['artillery-turret'] = true,
    ['gun-turret'] = true,
    ['laser-turret'] = true,
    ['flamethrower-turret'] = true
}

local function check_quality()
    local quality_list = Public.get('quality_list')
    local quality_level = random(1, #quality_list)
    local quality = quality_list[quality_level]
    return quality
end

--extra coins for "boss" biters from biter_health_booster.lua
local function get_coin_count(entity)
    local coin_count = coin_yield[entity.name]
    if not coin_count then
        return
    end
    local quality = check_quality()
    local biter_health_boost_units = BiterHealthBooster.get('biter_health_boost_units')

    if not biter_health_boost_units then
        return coin_count, quality
    end
    local unit_number = entity.unit_number
    if not unit_number then
        return coin_count, quality
    end
    if not biter_health_boost_units[unit_number] then
        return coin_count, quality
    end
    if not biter_health_boost_units[unit_number][3] then
        return coin_count, quality
    end
    if not biter_health_boost_units[unit_number][3].healthbar_id then -- only bosses
        return coin_count, quality
    end
    local m = 1 / biter_health_boost_units[unit_number][2]
    coin_count = floor(coin_count * m)
    if coin_count < 1 then
        return 1
    end
    return coin_count, quality
end

---comment
---@param event EventData.on_entity_died
local function on_entity_died(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    if not Public.valid_enemy_forces[entity.force.name] then
        return
    end



    local cause = event.cause

    local coin_count, quality = get_coin_count(entity)
    if not coin_count then
        return
    end

    local players_to_reward = {}
    local p
    local reward_has_been_given = false

    if cause then
        if cause.valid then
            if (cause and cause.name == 'character' and cause.player) then
                p = cause.player
            end

            if cause.name == 'character' then
                insert(players_to_reward, cause)
                reward_has_been_given = true
            end
            if cause.type == 'car' then
                local player = cause.get_driver()
                local passenger = cause.get_passenger()
                if player then
                    insert(players_to_reward, player.player)
                end
                if passenger then
                    insert(players_to_reward, passenger.player)
                end
                reward_has_been_given = true
            end
            if cause.type == 'locomotive' then
                local train_passengers = cause.train.passengers
                if train_passengers then
                    for _, passenger in pairs(train_passengers) do
                        insert(players_to_reward, passenger)
                    end
                    reward_has_been_given = true
                end
            end
            for _, player in pairs(players_to_reward) do
                local forest_zone
                if p then
                    forest_zone = RPG.get_value_from_player(p.index, 'forest_zone')
                end
                if forest_zone then
                    if random(1, 12) == 1 then
                        player.insert({ name = 'coin', count = coin_count, quality = quality })
                        if p then
                            StatData.get_data(p.index):increase('coins', coin_count)
                        end
                    end
                else
                    player.insert({ name = 'coin', count = coin_count, quality = quality })
                    if p then
                        StatData.get_data(p.index):increase('coins', coin_count)
                    end
                end
            end
        end
        if not Public.get('final_battle') then
            if entities_that_earn_coins[cause.name] then
                event.entity.surface.spill_item_stack({ position = cause.position, stack = { name = 'coin', count = coin_count, quality = quality }, enable_looted = true })
                reward_has_been_given = true
            end
        end
    end

    if Public.get('final_battle') then
        return
    end

    if reward_has_been_given == false then
        event.entity.surface.spill_item_stack({ position = event.entity.position, stack = { name = 'coin', count = coin_count, quality = quality }, enable_looted = true })
    end
end

Event.add(defines.events.on_entity_died, on_entity_died)

return Public
