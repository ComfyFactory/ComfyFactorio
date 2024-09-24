local Event = require 'utils.event'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Town_center = require 'maps.scrap_towny_ffa.town_center'

local table_insert = table.insert

local upgrade_functions = {
    -- Upgrade Town Center Health
    [1] = function (town_center, player)
        local market = town_center.market
        local surface = market.surface
        if town_center.max_health > 50000 then
            return false
        end
        town_center.health = town_center.health + town_center.max_health
        town_center.max_health = town_center.max_health * 2
        Town_center.set_market_health(market, 0)
        surface.play_sound({ path = 'utility/achievement_unlocked', position = player.position, volume_modifier = 1 })
        return true
    end,
    -- Upgrade Backpack
    [2] = function (town_center, player)
        local market = town_center.market
        local force = market.force
        local surface = market.surface
        if force.character_inventory_slots_bonus + 5 > 50 then
            return false
        end
        force.character_inventory_slots_bonus = force.character_inventory_slots_bonus + 5
        surface.play_sound({ path = 'utility/achievement_unlocked', position = player.position, volume_modifier = 1 })
        return true
    end,
    -- Upgrade Mining Productivity
    [3] = function (town_center, player)
        local market = town_center.market
        local force = market.force
        local surface = market.surface
        if town_center.upgrades.mining_prod + 1 > 10 then
            return false
        end
        town_center.upgrades.mining_prod = town_center.upgrades.mining_prod + 1
        force.mining_drill_productivity_bonus = force.mining_drill_productivity_bonus + 0.1
        surface.play_sound({ path = 'utility/achievement_unlocked', position = player.position, volume_modifier = 1 })
        return true
    end,
    -- Upgrade Pickaxe Speed
    [4] = function (town_center, player)
        local market = town_center.market
        local force = market.force
        local surface = market.surface
        if town_center.upgrades.mining_speed + 1 > 10 then
            return false
        end
        town_center.upgrades.mining_speed = town_center.upgrades.mining_speed + 1
        force.manual_mining_speed_modifier = force.manual_mining_speed_modifier + 0.1
        surface.play_sound({ path = 'utility/achievement_unlocked', position = player.position, volume_modifier = 1 })
        return true
    end,
    -- Upgrade Crafting Speed
    [5] = function (town_center, player)
        local market = town_center.market
        local force = market.force
        local surface = market.surface
        if town_center.upgrades.crafting_speed + 1 > 10 then
            return false
        end
        town_center.upgrades.crafting_speed = town_center.upgrades.crafting_speed + 1
        force.manual_crafting_speed_modifier = force.manual_crafting_speed_modifier + 0.1
        surface.play_sound({ path = 'utility/achievement_unlocked', position = player.position, volume_modifier = 1 })
        return true
    end,
    -- Laser Turret Slot
    [6] = function (town_center, player)
        local market = town_center.market
        local surface = market.surface
        town_center.upgrades.laser_turret.slots = town_center.upgrades.laser_turret.slots + 1
        surface.play_sound({ path = 'utility/new_objective', position = player.position, volume_modifier = 1 })
        return true
    end,
    -- Set Spawn Point
    [7] = function (town_center, player)
        local this = ScenarioTable.get_table()
        local market = town_center.market
        local force = market.force
        local surface = market.surface
        local spawn_point = force.get_spawn_position(surface)
        this.spawn_point[player.index] = spawn_point
        surface.play_sound({ path = 'utility/scenario_message', position = player.position, volume_modifier = 1 })
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

local function set_offers(town_center)
    local market = town_center.market
    local force = market.force
    local market_items = {}

    -- special offers
    local special_offers = {}
    if town_center.max_health < 50000 then
        special_offers[1] = { { { 'coin', town_center.max_health * 0.1 } }, 'Upgrade Town Center Health' }
    else
        special_offers[1] = { {}, 'Maximum Health upgrades reached!' }
    end
    if force.character_inventory_slots_bonus + 5 <= 50 then
        special_offers[2] = { { { 'coin', (force.character_inventory_slots_bonus / 5 + 1) * 50 } }, 'Upgrade Backpack +5 Slot' }
    else
        special_offers[2] = { {}, 'Maximum Backpack upgrades reached!' }
    end
    if town_center.upgrades.mining_prod + 1 <= 10 then
        special_offers[3] = { { { 'coin', (town_center.upgrades.mining_prod + 1) * 1000 } }, 'Upgrade Mining Productivity +10% (Drills, Pumps, Scrap)' }
    else
        special_offers[3] = { {}, 'Maximum Productivity upgrades reached!' }
    end
    if town_center.upgrades.mining_speed + 1 <= 10 then
        special_offers[4] = { { { 'coin', (town_center.upgrades.mining_speed + 1) * 400 } }, 'Upgrade Mining Speed +10%' }
    else
        special_offers[4] = { {}, 'Maximum Mining Speed upgrades reached!' }
    end
    if town_center.upgrades.crafting_speed + 1 <= 10 then
        special_offers[5] = { { { 'coin', (town_center.upgrades.crafting_speed + 1) * 400 } }, 'Upgrade Crafting Speed +10%' }
    else
        special_offers[5] = { {}, 'Maximum Crafting Speed upgrades reached!' }
    end
    local laser_turret = 'Laser Turret Slot [#' .. tostring(town_center.upgrades.laser_turret.slots + 1) .. ']'
    special_offers[6] = { { { 'coin', (town_center.upgrades.laser_turret.slots * 200) } }, laser_turret }
    local spawn_point = 'Set Spawn Point'
    special_offers[7] = { {}, spawn_point }
    for _, v in pairs(special_offers) do
        table_insert(market_items, { price = v[1], offer = { type = 'nothing', effect_description = v[2] } })
    end

    -- item purchases
    table_insert(market_items, { price = { { 'coin', 25 } }, offer = { type = 'give-item', item = 'raw-fish', count = 1 } })
    table_insert(market_items, { price = { { 'coin', 6 } }, offer = { type = 'give-item', item = 'wood', count = 1 } })
    table_insert(market_items, { price = { { 'coin', 1 } }, offer = { type = 'give-item', item = 'iron-ore', count = 6 } })
    table_insert(market_items, { price = { { 'coin', 1 } }, offer = { type = 'give-item', item = 'copper-ore', count = 6 } })
    table_insert(market_items, { price = { { 'coin', 1 } }, offer = { type = 'give-item', item = 'stone', count = 6 } })
    table_insert(market_items, { price = { { 'coin', 1 } }, offer = { type = 'give-item', item = 'coal', count = 6 } })
    table_insert(market_items, { price = { { 'coin', 1 } }, offer = { type = 'give-item', item = 'uranium-ore', count = 2 } })
    table_insert(market_items, { price = { { 'coin', 1000 } }, offer = { type = 'give-item', item = 'laser-turret', count = 1 } })
    table_insert(market_items, { price = { { 'coin', 300 } }, offer = { type = 'give-item', item = 'loader', count = 1 } })
    table_insert(market_items, { price = { { 'coin', 600 } }, offer = { type = 'give-item', item = 'fast-loader', count = 1 } })
    table_insert(market_items, { price = { { 'coin', 900 } }, offer = { type = 'give-item', item = 'express-loader', count = 1 } })
    -- item selling
    table_insert(market_items, { price = { { 'raw-fish', 1 } }, offer = { type = 'give-item', item = 'coin', count = 15 } })
    table_insert(market_items, { price = { { 'wood', 1 } }, offer = { type = 'give-item', item = 'coin', count = 3 } })
    table_insert(market_items, { price = { { 'iron-ore', 7 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items, { price = { { 'copper-ore', 7 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items, { price = { { 'stone', 7 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items, { price = { { 'coal', 7 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items, { price = { { 'uranium-ore', 3 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items, { price = { { 'copper-cable', 12 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items, { price = { { 'iron-gear-wheel', 3 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items, { price = { { 'iron-stick', 12 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items, { price = { { 'barrel', 1 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
    table_insert(market_items, { price = { { 'car', 1 } }, offer = { type = 'give-item', item = 'coin', count = 10 } })
    table_insert(market_items, { price = { { 'tank', 1 } }, offer = { type = 'give-item', item = 'coin', count = 50 } })

    for _, item in pairs(market_items) do
        market.add_market_item(item)
    end
end

local function refresh_offers(event)
    local this = ScenarioTable.get_table()
    local player = game.players[event.player_index]
    local market = event.entity or event.market
    if not market then
        return
    end
    if not market.valid then
        return
    end
    if market.name ~= 'market' then
        return
    end
    local town_center = this.town_centers[market.force.name]
    if not town_center then
        return
    end
    if player.force == market.force then
        clear_offers(market)
        set_offers(town_center)
    else
        if player.opened ~= nil then
            player.opened = nil
            player.surface.create_entity(
                {
                    name = 'flying-text',
                    position = { market.position.x - 1.75, market.position.y },
                    text = 'Sorry, we are closed.',
                    color = { r = 1, g = 0.68, b = 0.26 }
                }
            )
        end
    end
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
    local town_center = this.town_centers[market.force.name]
    if not town_center then
        return
    end
    if upgrade_functions[offer_index](town_center, player) then
        -- reimburse extra purchased
        if count > 1 then
            local offers = market.get_market_items()
            if offers[offer_index].price ~= nil then
                local price = offers[offer_index].price[1].amount
                player.insert({ name = 'coin', count = price * (count - 1) })
            end
        end
    else
        -- reimburse purchase
        local offers = market.get_market_items()
        if offers[offer_index].price ~= nil then
            local price = offers[offer_index].price[1].amount
            player.insert({ name = 'coin', count = price * (count) })
        end
    end
end

-- called for all gui events
local function on_gui_opened(event)
    local gui_type = event.gui_type
    if gui_type ~= defines.gui_type.entity then
        return
    end
    local entity = event.entity
    if entity == nil or not entity.valid then
        return
    end
    if entity.name == 'market' then
        refresh_offers(event)
    end
end

-- called for all market events
local function on_market_item_purchased(event)
    local market = event.market
    if market.name == 'market' then
        offer_purchased(event)
        refresh_offers(event)
    end
end

local function inside(pos, area)
    return pos.x >= area.left_top.x and pos.x <= area.right_bottom.x and pos.y >= area.left_top.y and pos.y <= area.right_bottom.y
end

local function equal(pos1, pos2)
    return pos1.x == pos2.x and pos1.y == pos2.y
end

local function is_loader(entity)
    return entity.name == 'loader' or entity.name == 'fast-loader' or entity.name == 'express-loader'
end

local function is_filtered_inserter(entity)
    return entity.name == 'filter-inserter' or entity.name == 'stack-filter-inserter'
end

local function max_stack_size(entity)
    if is_loader(entity) then
        return 1
    end
    if (entity.name == 'stack-inserter' or entity.name == 'stack-filter-inserter') then
        local override = entity.inserter_stack_size_override
        if override > 0 then
            return override
        end
        local capacity = entity.force.stack_inserter_capacity_bonus
        return 1 + capacity
    else
        local override = entity.inserter_stack_size_override
        if override > 0 then
            return override
        end
        local bonus = entity.force.inserter_stack_size_bonus
        return 1 + bonus
    end
end

local function get_connected_entities(market)
    if not market.valid then
        return {}
    end
    local items = {
        'burner-inserter',
        'inserter',
        'long-handed-inserter',
        'fast-inserter',
        'filter-inserter',
        'stack-inserter',
        'stack-filter-inserter',
        'loader',
        'fast-loader',
        'express-loader'
    }
    local items2 = {
        'long-handed-inserter'
    }
    local bb = market.bounding_box
    local s = market.surface
    local area = { left_top = { bb.left_top.x - 1, bb.left_top.y - 1 }, right_bottom = { bb.right_bottom.x + 1, bb.right_bottom.y + 1 } }
    local entities = s.find_entities_filtered({ area = area, name = items })
    local area2 = { left_top = { bb.left_top.x - 2, bb.left_top.y - 2 }, right_bottom = { bb.right_bottom.x + 2, bb.right_bottom.y + 2 } }
    local entities2 = s.find_entities_filtered({ area = area2, name = items2 })
    for k, v in pairs(entities2) do
        entities[k] = v
    end
    return entities
end

local function get_inserter_filter(entity)
    -- return the first filter
    local filter_mode = entity.inserter_filter_mode
    if filter_mode == 'whitelist' then
        return entity.get_filter(1)
    end
    return nil
end

local function get_loader_filter(entity, index)
    -- return first two filter types
    return entity.get_filter(index)
end

local function get_loader_market_position(entity)
    -- gets the position of the market relative to the loader
    local position = { x = entity.position.x, y = entity.position.y }
    local orientation = entity.orientation
    local type = entity.loader_type
    if (orientation == 0.0 and type == 'input') or (orientation == 0.5 and type == 'output') then
        position.y = position.y - 1.5
    end
    if (orientation == 0.25 and type == 'input') or (orientation == 0.75 and type == 'output') then
        position.x = position.x + 1.5
    end
    if (orientation == 0.5 and type == 'input') or (orientation == 0.0 and type == 'output') then
        position.y = position.y + 1.5
    end
    if (orientation == 0.75 and type == 'input') or (orientation == 0.25 and type == 'output') then
        position.x = position.x - 1.5
    end
    return position
end

local function output_loader_items(town_center, trade, entity, index)
    local item = trade.offer.item
    local line = entity.get_transport_line(index)
    if line.can_insert_at_back() and town_center.output_buffer[item] > 0 then
        local stack = { name = item, count = 1 }
        town_center.output_buffer[item] = town_center.output_buffer[item] - 1
        line.insert_at_back(stack)
    end
end

local function output_inserter_items(town_center, trade, entity)
    local item = trade.offer.item
    local stack_size = max_stack_size(entity)
    local count = 0
    while town_center.output_buffer[item] > 0 and count < stack_size do
        town_center.output_buffer[item] = town_center.output_buffer[item] - 1
        count = count + 1
    end
    if count > 0 then
        local stack = { name = item, count = count }
        entity.held_stack.set_stack(stack)
    end
end

local function trade_scrap_for_coin(town_center, market, trade, stack)
    local item = stack.name
    local amount = stack.count
    -- buffer the input in an item buffer that can be sold for coin
    if town_center.input_buffer[item] == nil then
        town_center.input_buffer[item] = 0
    end
    town_center.input_buffer[item] = town_center.input_buffer[item] + amount
    --log("input_buffer[" .. item .. "] = " .. town_center.input_buffer[item])

    local price = trade.price[1].amount
    local count = trade.offer.count
    while town_center.input_buffer[item] >= price do
        town_center.input_buffer[item] = town_center.input_buffer[item] - price
        town_center.coin_balance = town_center.coin_balance + count
    end
    Town_center.update_coin_balance(market.force)
    --log("input_buffer[" .. item .. "] = " .. town_center.input_buffer[item])
end

local function trade_coin_for_items(town_center, market, trade)
    local item = trade.offer.item
    local count = trade.offer.count
    local price = trade.price[1].amount
    if town_center.output_buffer[item] == nil then
        town_center.output_buffer[item] = 0
    end
    while town_center.coin_balance - price >= 0 do
        if town_center.output_buffer[item] == 0 then
            town_center.coin_balance = town_center.coin_balance - price
            town_center.output_buffer[item] = town_center.output_buffer[item] + count
        else
            break
        end
    end
    Town_center.update_coin_balance(market.force)
end

local function handle_loader_output(town_center, market, entity, index)
    local line = entity.get_transport_line(index)
    -- get loader filters
    local filter = get_loader_filter(entity, index)
    if filter == nil then
        return
    end
    if filter == 'coin' then
        -- output for coins
        while town_center.coin_balance > 0 and line.can_insert_at_back() do
            town_center.coin_balance = town_center.coin_balance - 1
            local stack = { name = 'coin', count = 1 }
            line.insert_at_back(stack)
        end
        Town_center.update_coin_balance(market.force)
    else
        -- output for matching purchases
        local offers = market.get_market_items()
        if offers == nil then
            set_offers(town_center)
        end
        if offers ~= nil then
            for _, trade in ipairs(offers) do
                if trade.offer.type == 'give-item' then
                    local item = trade.price[1].name
                    if item == 'coin' and trade.offer.item == filter then
                        trade_coin_for_items(town_center, market, trade)
                        output_loader_items(town_center, trade, entity, index)
                    end
                end
            end
        end
    end
end

local function handle_inserter_output(town_center, market, entity)
    -- get inserter filter
    local filter = get_inserter_filter(entity)
    if filter == nil then
        return
    end
    local amount = max_stack_size(entity)
    local stack = { name = 'coin', count = amount }
    if filter == 'coin' then
        -- output coins
        if amount > town_center.coin_balance then
            amount = town_center.coin_balance
        end
        stack.count = amount
        if town_center.coin_balance > 0 then
            town_center.coin_balance = town_center.coin_balance - amount
            entity.held_stack.set_stack(stack)
        end
        Town_center.update_coin_balance(market.force)
    else
        -- for matching coin purchases
        local offers = market.get_market_items()
        if offers == nil then
            set_offers(town_center)
        end
        if offers ~= nil then
            for _, trade in ipairs(offers) do
                if trade.offer.type == 'give-item' and trade.offer.item == filter then
                    local item = trade.price[1].name
                    if item == 'coin' then
                        trade_coin_for_items(town_center, market, trade)
                        output_inserter_items(town_center, trade, entity)
                    end
                end
            end
        end
    end
end

local function handle_loader_input(town_center, market, entity, index)
    local line = entity.get_transport_line(index)
    -- check for a line item at the back where we can pull
    if line.valid then
        local length = #line
        if length > 1 or (length == 1 and line.can_insert_at_back()) then
            local line_item = line[length].name
            local stack = { name = line_item, count = 1 }
            if line_item == 'coin' then
                -- insert coins
                line.remove_item(stack)
                town_center.coin_balance = town_center.coin_balance + stack.count
                Town_center.update_coin_balance(market.force)
            else
                local offers = market.get_market_items()
                if offers == nil then
                    set_offers(town_center)
                end
                if offers ~= nil then
                    for _, trade in ipairs(offers) do
                        if trade.offer.type == 'give-item' then
                            local item = trade.price[1].name
                            if item == stack.name and trade.offer.item == 'coin' then
                                -- trade scrap for coin
                                line.remove_item(stack)
                                trade_scrap_for_coin(town_center, market, trade, stack)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function handle_inserter_input(town_center, market, entity)
    -- check if stack is coin or resource
    local stack = { name = entity.held_stack.name, count = entity.held_stack.count }
    if stack.name == 'coin' and stack.count > 0 then
        -- insert coins
        entity.remove_item(stack)
        town_center.coin_balance = town_center.coin_balance + stack.count
        Town_center.update_coin_balance(market.force)
    else
        local offers = market.get_market_items()
        if offers == nil then
            set_offers(town_center)
        end
        if offers ~= nil then
            for _, trade in ipairs(offers) do
                if trade.offer.type == 'give-item' and trade.offer.item == 'coin' then
                    local item = trade.price[1].name
                    if item == stack.name and trade.offer.item == 'coin' then
                        -- trade scrap for coin
                        entity.remove_item(stack)
                        trade_scrap_for_coin(town_center, market, trade, stack)
                    end
                end
            end
        end
    end
end

local function handle_market_input(town_center, market, entity)
    if is_loader(entity) then
        -- handle loader input
        -- we don't care about filters
        local max_index = entity.get_max_transport_line_index()
        for index = 1, max_index, 1 do
            handle_loader_input(town_center, market, entity, index)
        end
    else
        -- handle inserter input
        -- we don't care about filters
        local stack = entity.held_stack
        if stack ~= nil then
            -- if there is a pickup target
            local spos = entity.held_stack_position
            local dpos = entity.drop_position
            if equal(spos, dpos) then
                if stack.valid_for_read and stack.count > 0 then
                    -- if there is a stack
                    -- insert an item into the market
                    handle_inserter_input(town_center, market, entity)
                end
            end
        end
    end
end

local function handle_market_output(town_center, market, entity)
    if is_loader(entity) then
        -- handle loader output
        local max_index = entity.get_max_transport_line_index()
        for index = 1, max_index, 1 do
            if get_loader_filter(entity, index) ~= nil then
                handle_loader_output(town_center, market, entity, index)
            end
        end
    else
        if is_filtered_inserter(entity) then
            -- handle inserter output
            if entity.drop_target ~= nil then
                -- if the pickup position is inside the market
                --log("inside pickup position and there is a drop target")
                local stack = entity.held_stack
                local spos = entity.held_stack_position
                local ppos = entity.pickup_position
                if equal(spos, ppos) then
                    -- if the stack position is inside the market
                    if stack == nil or stack.count == 0 then
                        -- if there is space on the stack
                        -- pull an item from the market
                        handle_inserter_output(town_center, market, entity, stack)
                    end
                end
            end
        end
    end
end

local function get_entity_mode(market, entity)
    local bb = market.bounding_box
    if is_loader(entity) then
        local mpos = get_loader_market_position(entity)
        if inside(mpos, bb) then
            return entity.loader_type
        else
            return 'none'
        end
    else
        local dpos = entity.drop_position
        local ppos = entity.pickup_position
        if inside(dpos, bb) then
            return 'input'
        end
        if inside(ppos, bb) then
            return 'output'
        end
        return 'none'
    end
end

local function handle_connected_entity(town_center, market, entity)
    local mode = get_entity_mode(market, entity)
    if mode == 'input' then
        handle_market_input(town_center, market, entity)
    end
    if mode == 'output' then
        handle_market_output(town_center, market, entity)
    end
end

local function on_tick(_)
    local this = ScenarioTable.get_table()
    if not this.town_centers then
        return
    end
    for _, town_center in pairs(this.town_centers) do
        -- get connected entities on markets
        local market = town_center.market
        local entities = get_connected_entities(market)
        -- handle connected entity
        for _, entity in pairs(entities) do
            if entity.force == market.force then
                handle_connected_entity(town_center, market, entity)
            end
        end
    end
end

Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
