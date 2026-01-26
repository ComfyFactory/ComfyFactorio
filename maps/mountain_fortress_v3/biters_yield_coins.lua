local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local RPG = require 'modules.rpg.main'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local StatData = require 'utils.datastore.statistics'
local insert = table.insert
local floor = math.floor
local random = math.random

local coin_yield =
{
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
    ['spitter-spawner'] = 32,

    ['mtn-addon-small-piercing-biter-t1'] = 1,
    ['mtn-addon-small-piercing-biter-t2'] = 1,
    ['mtn-addon-small-piercing-biter-t3'] = 1,
    ['mtn-addon-small-acid-biter-t1'] = 1,
    ['mtn-addon-small-acid-biter-t2'] = 1,
    ['mtn-addon-small-acid-biter-t3'] = 1,
    ['mtn-addon-small-explosive-biter-t1'] = 1,
    ['mtn-addon-small-explosive-biter-t2'] = 1,
    ['mtn-addon-small-explosive-biter-t3'] = 1,
    ['mtn-addon-small-poison-biter-t1'] = 1,
    ['mtn-addon-small-poison-biter-t2'] = 1,
    ['mtn-addon-small-poison-biter-t3'] = 1,
    ['mtn-addon-small-fire-biter-t1'] = 1,
    ['mtn-addon-small-fire-biter-t2'] = 1,
    ['mtn-addon-small-fire-biter-t3'] = 1,
    ['mtn-addon-small-piercing-spitter-t1'] = 1,
    ['mtn-addon-small-piercing-spitter-t2'] = 1,
    ['mtn-addon-small-piercing-spitter-t3'] = 1,
    ['mtn-addon-small-acid-spitter-t1'] = 1,
    ['mtn-addon-small-acid-spitter-t2'] = 1,
    ['mtn-addon-small-acid-spitter-t3'] = 1,
    ['mtn-addon-small-explosive-spitter-t1'] = 1,
    ['mtn-addon-small-explosive-spitter-t2'] = 1,
    ['mtn-addon-small-explosive-spitter-t3'] = 1,
    ['mtn-addon-small-poison-spitter-t1'] = 1,
    ['mtn-addon-small-poison-spitter-t2'] = 1,
    ['mtn-addon-small-poison-spitter-t3'] = 1,
    ['mtn-addon-small-fire-spitter-t1'] = 1,
    ['mtn-addon-small-fire-spitter-t2'] = 1,
    ['mtn-addon-small-fire-spitter-t3'] = 1,

    ['mtn-addon-medium-piercing-biter-t1'] = 2,
    ['mtn-addon-medium-piercing-biter-t2'] = 2,
    ['mtn-addon-medium-piercing-biter-t3'] = 2,
    ['mtn-addon-medium-acid-biter-t1'] = 2,
    ['mtn-addon-medium-acid-biter-t2'] = 2,
    ['mtn-addon-medium-acid-biter-t3'] = 2,
    ['mtn-addon-medium-explosive-biter-t1'] = 2,
    ['mtn-addon-medium-explosive-biter-t2'] = 2,
    ['mtn-addon-medium-explosive-biter-t3'] = 2,
    ['mtn-addon-medium-poison-biter-t1'] = 2,
    ['mtn-addon-medium-poison-biter-t2'] = 2,
    ['mtn-addon-medium-poison-biter-t3'] = 2,
    ['mtn-addon-medium-fire-biter-t1'] = 2,
    ['mtn-addon-medium-fire-biter-t2'] = 2,
    ['mtn-addon-medium-fire-biter-t3'] = 2,
    ['mtn-addon-medium-piercing-spitter-t1'] = 2,
    ['mtn-addon-medium-piercing-spitter-t2'] = 2,
    ['mtn-addon-medium-piercing-spitter-t3'] = 2,
    ['mtn-addon-medium-acid-spitter-t1'] = 2,
    ['mtn-addon-medium-acid-spitter-t2'] = 2,
    ['mtn-addon-medium-acid-spitter-t3'] = 2,
    ['mtn-addon-medium-explosive-spitter-t1'] = 2,
    ['mtn-addon-medium-explosive-spitter-t2'] = 2,
    ['mtn-addon-medium-explosive-spitter-t3'] = 2,
    ['mtn-addon-medium-poison-spitter-t1'] = 2,
    ['mtn-addon-medium-poison-spitter-t2'] = 2,
    ['mtn-addon-medium-poison-spitter-t3'] = 2,
    ['mtn-addon-medium-fire-spitter-t1'] = 2,
    ['mtn-addon-medium-fire-spitter-t2'] = 2,
    ['mtn-addon-medium-fire-spitter-t3'] = 2,

    ['mtn-addon-big-piercing-biter-t1'] = 3,
    ['mtn-addon-big-piercing-biter-t2'] = 3,
    ['mtn-addon-big-piercing-biter-t3'] = 3,
    ['mtn-addon-big-acid-biter-t1'] = 3,
    ['mtn-addon-big-acid-biter-t2'] = 3,
    ['mtn-addon-big-acid-biter-t3'] = 3,
    ['mtn-addon-big-explosive-biter-t1'] = 3,
    ['mtn-addon-big-explosive-biter-t2'] = 3,
    ['mtn-addon-big-explosive-biter-t3'] = 3,
    ['mtn-addon-big-poison-biter-t1'] = 3,
    ['mtn-addon-big-poison-biter-t2'] = 3,
    ['mtn-addon-big-poison-biter-t3'] = 3,
    ['mtn-addon-big-fire-biter-t1'] = 3,
    ['mtn-addon-big-fire-biter-t2'] = 3,
    ['mtn-addon-big-fire-biter-t3'] = 3,
    ['mtn-addon-big-piercing-spitter-t1'] = 3,
    ['mtn-addon-big-piercing-spitter-t2'] = 3,
    ['mtn-addon-big-piercing-spitter-t3'] = 3,
    ['mtn-addon-big-acid-spitter-t1'] = 3,
    ['mtn-addon-big-acid-spitter-t2'] = 3,
    ['mtn-addon-big-acid-spitter-t3'] = 3,
    ['mtn-addon-big-explosive-spitter-t1'] = 3,
    ['mtn-addon-big-explosive-spitter-t2'] = 3,
    ['mtn-addon-big-explosive-spitter-t3'] = 3,
    ['mtn-addon-big-poison-spitter-t1'] = 3,
    ['mtn-addon-big-poison-spitter-t2'] = 3,
    ['mtn-addon-big-poison-spitter-t3'] = 3,
    ['mtn-addon-big-fire-spitter-t1'] = 3,
    ['mtn-addon-big-fire-spitter-t2'] = 3,
    ['mtn-addon-big-fire-spitter-t3'] = 3,

    ['mtn-addon-behemoth-piercing-biter-t1'] = 5,
    ['mtn-addon-behemoth-piercing-biter-t2'] = 5,
    ['mtn-addon-behemoth-piercing-biter-t3'] = 5,
    ['mtn-addon-behemoth-acid-biter-t1'] = 5,
    ['mtn-addon-behemoth-acid-biter-t2'] = 5,
    ['mtn-addon-behemoth-acid-biter-t3'] = 5,
    ['mtn-addon-behemoth-explosive-biter-t1'] = 5,
    ['mtn-addon-behemoth-explosive-biter-t2'] = 5,
    ['mtn-addon-behemoth-explosive-biter-t3'] = 5,
    ['mtn-addon-behemoth-poison-biter-t1'] = 5,
    ['mtn-addon-behemoth-poison-biter-t2'] = 5,
    ['mtn-addon-behemoth-poison-biter-t3'] = 5,
    ['mtn-addon-behemoth-fire-biter-t1'] = 5,
    ['mtn-addon-behemoth-fire-biter-t2'] = 5,
    ['mtn-addon-behemoth-fire-biter-t3'] = 5,
    ['mtn-addon-behemoth-piercing-spitter-t1'] = 5,
    ['mtn-addon-behemoth-piercing-spitter-t2'] = 5,
    ['mtn-addon-behemoth-piercing-spitter-t3'] = 5,
    ['mtn-addon-behemoth-acid-spitter-t1'] = 5,
    ['mtn-addon-behemoth-acid-spitter-t2'] = 5,
    ['mtn-addon-behemoth-acid-spitter-t3'] = 5,
    ['mtn-addon-behemoth-explosive-spitter-t1'] = 5,
    ['mtn-addon-behemoth-explosive-spitter-t2'] = 5,
    ['mtn-addon-behemoth-explosive-spitter-t3'] = 5,
    ['mtn-addon-behemoth-poison-spitter-t1'] = 5,
    ['mtn-addon-behemoth-poison-spitter-t2'] = 5,
    ['mtn-addon-behemoth-poison-spitter-t3'] = 5,
    ['mtn-addon-behemoth-fire-spitter-t1'] = 5,
    ['mtn-addon-behemoth-fire-spitter-t2'] = 5,
    ['mtn-addon-behemoth-fire-spitter-t3'] = 5,
    -- worms
    ['mtn-addon-small-explosive-worm-turret'] = 2,
    ['mtn-addon-small-fire-worm-turret'] = 2,
    ['mtn-addon-small-piercing-worm-turret'] = 2,
    ['mtn-addon-small-poison-worm-turret'] = 2,
    ['mtn-addon-small-electric-worm-turret'] = 2,
    ['mtn-addon-medium-explosive-worm-turret'] = 4,
    ['mtn-addon-medium-fire-worm-turret'] = 4,
    ['mtn-addon-medium-piercing-worm-turret'] = 4,
    ['mtn-addon-medium-poison-worm-turret'] = 4,
    ['mtn-addon-medium-electric-worm-turret'] = 4,
    ['mtn-addon-big-explosive-worm-turret'] = 16,
    ['mtn-addon-big-fire-worm-turret'] = 16,
    ['mtn-addon-big-piercing-worm-turret'] = 16,
    ['mtn-addon-big-poison-worm-turret'] = 16,
    ['mtn-addon-big-electric-worm-turret'] = 16,
    ['mtn-addon-giant-worm-turret'] = 200,
}

local entities_that_earn_coins =
{
    ['artillery-turret'] = true,
    ['gun-turret'] = true,
    ['laser-turret'] = true,
    ['flamethrower-turret'] = true
}

local function check_quality()
    local quality_list = Public.get('quality_list')
    local quality_level = random(1, #quality_list)
    local quality = quality_list[quality_level]

    if random(1, 2) == 1 then
        return quality[random(1, #quality)]
    end

    return 'normal'
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

    local current_task = Public.get('current_task')
    if not current_task.done then
        return
    end

    local current_planet = Public.get_planet()
    if string.sub(entity.surface.name, 0, #current_planet) ~= current_planet then
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

    local is_coin_quality_enabled = Public.get('is_coin_quality_enabled')
    if not is_coin_quality_enabled then
        quality = 'normal'
    end

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
