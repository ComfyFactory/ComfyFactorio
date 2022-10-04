local table_insert = table.insert

local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Event = require 'utils.event'

local function position_tostring(position)
    return '[x=' .. position.x .. ',y=' .. position.y .. ']'
end

local upgrade_functions = {
    -- Upgrade Backpack
    [1] = function(player)
        local this = ScenarioTable.get_table()
        local surface = player.surface
        if player.character.character_inventory_slots_bonus + 5 > 100 then
            return false
        end
        player.character.character_inventory_slots_bonus = player.character.character_inventory_slots_bonus + 5
        if not this.buffs[player.index] then
            this.buffs[player.index] = {}
        end
        if not this.buffs[player.index].character_inventory_slots_bonus then
            this.buffs[player.index].character_inventory_slots_bonus = 0
        end
        this.buffs[player.index].character_inventory_slots_bonus = player.character.character_inventory_slots_bonus
        surface.play_sound({path = 'utility/achievement_unlocked', position = player.position, volume_modifier = 1})
        return true
    end,
    -- Upgrade Pickaxe Speed
    [2] = function(player)
        local this = ScenarioTable.get_table()
        local surface = player.surface
        if player.character.character_mining_speed_modifier + 0.1 > 1 then
            return false
        end
        player.character.character_mining_speed_modifier = player.character.character_mining_speed_modifier + 0.1
        if not this.buffs[player.index] then
            this.buffs[player.index] = {}
        end
        if not this.buffs[player.index].character_mining_speed_modifier then
            this.buffs[player.index].character_mining_speed_modifier = 0
        end
        this.buffs[player.index].character_mining_speed_modifier = player.character.character_mining_speed_modifier
        surface.play_sound({path = 'utility/achievement_unlocked', position = player.position, volume_modifier = 1})
        return true
    end,
    -- Upgrade Crafting Speed
    [3] = function(player)
        local this = ScenarioTable.get_table()
        local surface = player.surface
        if player.character.character_crafting_speed_modifier + 0.1 > 1 then
            return false
        end
        player.character.character_crafting_speed_modifier = player.character.character_crafting_speed_modifier + 0.1
        if not this.buffs[player.index] then
            this.buffs[player.index] = {}
        end
        if not this.buffs[player.index].character_crafting_speed_modifier then
            this.buffs[player.index].character_crafting_speed_modifier = 0
        end
        this.buffs[player.index].character_crafting_speed_modifier = player.character.character_crafting_speed_modifier
        surface.play_sound({path = 'utility/achievement_unlocked', position = player.position, volume_modifier = 1})
        return true
    end,
    -- Set Spawn Point
    [4] = function(player)
        local this = ScenarioTable.get_table()
        local surface = player.surface
        local position = player.position
        position = surface.find_non_colliding_position('character', position, 0, 0.25)
        if position ~= nil and player ~= nil then
            this.spawn_point[player.index] = {x = position.x, y = position.y}
            surface.play_sound({path = 'utility/scenario_message', position = player.position, volume_modifier = 1})
        else
            surface.create_entity(
                {
                    name = 'flying-text',
                    position = position,
                    text = 'Could not find open space for spawnpoint!',
                    color = {r = 0.77, g = 0.0, b = 0.0}
                }
            )
        end
        return false
    end
}

local function clear_offers(market)
    for _ = 1, 256, 1 do
        local a = market.remove_market_item(1)
        if a == false then
            return
        end
    end
end

local function set_offers(market, player)
    local market_items = {}

    -- special offers are only for outlanders and rogues
    local special_offers = {}
    local force = player.force
    if force.index == game.forces['player'].index or force.index == game.forces['rogue'].index then
        if player.character.character_inventory_slots_bonus + 5 <= 100 then
            special_offers[1] = {{{'coin', (player.character.character_inventory_slots_bonus / 5 + 1) * 50}}, 'Upgrade Backpack +5 Slot'}
        else
            special_offers[1] = {{}, 'Maximum Backpack upgrades reached!'}
        end
        if player.character.character_mining_speed_modifier + 0.1 <= 1 then
            special_offers[2] = {{{'coin', (player.character.character_mining_speed_modifier * 10 + 1) * 400}}, 'Upgrade Mining Speed +10%'}
        else
            special_offers[2] = {{}, 'Maximum Mining Speed upgrades reached!'}
        end

        if player.character.character_crafting_speed_modifier + 0.1 <= 1 then
            special_offers[3] = {{{'coin', (player.character.character_crafting_speed_modifier * 10 + 1) * 400}}, 'Upgrade Crafting Speed +10%'}
        else
            special_offers[3] = {{}, 'Maximum Crafting Speed upgrades reached!'}
        end
        local spawn_point = 'Set Spawn Point'
        special_offers[4] = {{}, spawn_point}
    else
        local spawn_point = 'Set Spawn Point'
        special_offers[1] = {{}, spawn_point}
    end
    for _, v in pairs(special_offers) do
        table_insert(market_items, {price = v[1], offer = {type = 'nothing', effect_description = v[2]}})
    end

    -- coin purchases
    table_insert(market_items, {price = {{'coin', 1}}, offer = {type = 'give-item', item = 'raw-fish', count = 1}})
    table_insert(market_items, {price = {{'coin', 4}}, offer = {type = 'give-item', item = 'firearm-magazine', count = 5}})
    table_insert(market_items, {price = {{'coin', 10}}, offer = {type = 'give-item', item = 'grenade', count = 6}})
    table_insert(market_items, {price = {{'coin', 40}}, offer = {type = 'give-item', item = 'piercing-rounds-magazine', count = 10}})
    table_insert(market_items, {price = {{'coin', 75}}, offer = {type = 'give-item', item = 'heavy-armor', count = 1}})
    table_insert(market_items, {price = {{'coin', 150}}, offer = {type = 'give-item', item = 'modular-armor', count = 1}})
    -- scrap selling
    table_insert(market_items, {price = {{'raw-fish', 1}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'wood', 7}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'copper-cable', 12}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'copper-plate', 5}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'iron-stick', 12}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'iron-gear-wheel', 3}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'iron-plate', 5}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'steel-plate', 1}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'empty-barrel', 1}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'crude-oil-barrel', 1}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'heavy-oil-barrel', 1}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'light-oil-barrel', 1}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'lubricant-barrel', 1}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'petroleum-gas-barrel', 1}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'sulfuric-acid-barrel', 1}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'water-barrel', 1}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'electronic-circuit', 5}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'advanced-circuit', 1}}, offer = {type = 'give-item', item = 'coin', count = 5}})
    table_insert(market_items, {price = {{'processing-unit', 1}}, offer = {type = 'give-item', item = 'coin', count = 10}})
    table_insert(market_items, {price = {{'plastic-bar', 1}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'green-wire', 5}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'red-wire', 5}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'battery', 1}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'heat-pipe', 1}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'pipe', 8}}, offer = {type = 'give-item', item = 'coin', count = 1}})
    table_insert(market_items, {price = {{'pipe-to-ground', 1}}, offer = {type = 'give-item', item = 'coin', count = 1}})

    for _, item in pairs(market_items) do
        market.add_market_item(item)
    end
end

local function refresh_offers(event)
    local player_index = event.player_index
    if player_index == nil then
        return
    end
    local player = game.players[event.player_index]
    local this = ScenarioTable.get_table()
    local market = event.entity or event.market
    if not market then
        return
    end
    if not market.valid then
        return
    end
    if market.name ~= 'crash-site-spaceship-market' then
        return
    end

    local key = position_tostring(market.position)
    local spaceship = this.spaceships[key]
    if not spaceship then
        return
    end
    clear_offers(market)
    set_offers(market, player)
end

local function offer_purchased(event)
    local this = ScenarioTable.get_table()
    local player = game.players[event.player_index]
    local market = event.market
    local offer_index = event.offer_index
    local count = event.count
    if not upgrade_functions[offer_index] then
        return
    end
    local key = position_tostring(market.position)
    local spaceship = this.spaceships[key]
    if not spaceship then
        return
    end
    if upgrade_functions[offer_index](player) then
        -- reimburse extra purchased
        if count > 1 then
            local offers = market.get_market_items()
            if offers[offer_index].price ~= nil then
                local price = offers[offer_index].price[1].amount
                player.insert({name = 'coin', count = price * (count - 1)})
            end
        end
    else
        -- reimburse purchase
        local offers = market.get_market_items()
        if offers[offer_index].price ~= nil then
            local price = offers[offer_index].price[1].amount
            player.insert({name = 'coin', count = price * (count)})
        end
    end
end

local function on_gui_opened(event)
    local gui_type = event.gui_type
    if gui_type == defines.gui_type.entity then
        local entity = event.entity
        if entity ~= nil or entity.valid then
            -- crash-site-spaceship
            if entity.name == 'crash-site-spaceship-market' then
                refresh_offers(event)
            end
        end
    end
end

local function on_market_item_purchased(event)
    local market = event.market
    if market.name == 'crash-site-spaceship-market' then
        offer_purchased(event)
        refresh_offers(event)
    end
end

local function kill_spaceship(entity)
    local this = ScenarioTable.get_table()
    local key = position_tostring(entity.position)
    local spaceship = this.spaceships[key]
    if spaceship ~= nil then
        this.spaceships[key] = nil
    end
end

local function on_entity_died(event)
    local entity = event.entity
    if entity.name == 'crash-site-spaceship-market' then
        kill_spaceship(entity)
    end
end

Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
Event.add(defines.events.on_entity_died, on_entity_died)
