local Event = require 'utils.event'
local WPT = require 'maps.mountain_fortress_v3.table'

local function spawn_ores(surface, position, resource, amount)
    local radius = math.floor(amount ^ 0.24)
    for x = position.x - radius, position.x + radius do
        for y = position.y - radius, position.y + radius do
            local intensity = math.floor(radius ^ 2 - (position.x - x) ^ 2 - (position.y - y) ^ 2)
            if intensity > 0 then
                local corrected_pos = surface.find_non_colliding_position('iron-ore', {x, y}, 5, 1)
                if corrected_pos ~= nil then
                    surface.create_entity {
                        name = resource,
                        position = corrected_pos,
                        amount = intensity,
                        enable_tree_removal = false,
                        enable_cliff_removal = false
                    }
                end
            end
        end
    end
    local miners =
        surface.find_entities_filtered {
        type = 'mining-drill',
        area = {{position.x - radius, position.y - radius}, {position.x + radius, position.y + radius}}
    }
    for k, v in pairs(miners) do
        v.active = false
        v.active = true
    end
end

local function generate()
    if game.tick % 216000 ~= 25200 then
        return
    end
    local ore_loot = WPT.get('ore_loot')
    local market = WPT.get('market')
    if not market then
        return
    end
    if not market.valid then
        return
    end
    local force = game.forces.player
    local item = math.random(1, 3)
    item = ore_loot.ore_list[item]
    if force and force.valid then
        for _, surface_list in pairs(force.logistic_networks) do
            for _, network in pairs(surface_list) do
                if network and network.valid then
                    if network.get_item_count(item) < 1500000000 and network.get_item_count(item) >= ore_loot.limit then
                        local cell = network.cells[math.random(#network.cells)]
                        if cell and cell.valid and cell.owner and cell.owner.valid then
                            local least = {'iron-ore', 1000000000}
                            for k, v in pairs(ore_loot.ore_list) do
                                if least[2] > network.get_item_count(v) then
                                    least[1], least[2] = v, network.get_item_count(v)
                                end
                            end
                            local res = least[1]
                            local amount = math.floor(network.get_item_count(item) / ore_loot.divisor)
                            spawn_ores(market.surface, market.position, res, amount * 20)
                            network.remove_item {name = item, count = amount}
                            game.print('The market has been blessed by the god of industry.')
                        end
                    end
                end
            end
        end
    end
end

Event.add(defines.events.on_tick, generate)
