local Color = require 'utils.color_presets'
local Event = require 'utils.event'
local WPT = require 'maps.mountain_fortress_v3.table'
local RPG = require 'modules.rpg.main'
local Alert = require 'utils.alert'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Public = {}

local shuffle = table.shuffle_table
local random = math.random
local floor = math.floor
local insert = table.insert
local abs = math.abs

local item_worths = {
    ['wooden-chest'] = 4,
    ['iron-chest'] = 8,
    ['steel-chest'] = 64,
    ['storage-tank'] = 64,
    ['transport-belt'] = 4,
    ['fast-transport-belt'] = 16,
    ['express-transport-belt'] = 64,
    ['underground-belt'] = 16,
    ['fast-underground-belt'] = 64,
    ['express-underground-belt'] = 256,
    ['splitter'] = 16,
    ['fast-splitter'] = 64,
    ['express-splitter'] = 256,
    ['burner-inserter'] = 2,
    ['inserter'] = 8,
    ['long-handed-inserter'] = 16,
    ['fast-inserter'] = 32,
    ['filter-inserter'] = 40,
    ['stack-inserter'] = 128,
    ['stack-filter-inserter'] = 160,
    ['small-electric-pole'] = 4,
    ['medium-electric-pole'] = 32,
    ['big-electric-pole'] = 64,
    ['substation'] = 256,
    ['pipe'] = 1,
    ['pipe-to-ground'] = 15,
    ['pump'] = 32,
    ['rail'] = 8,
    ['train-stop'] = 64,
    ['rail-signal'] = 16,
    ['rail-chain-signal'] = 16,
    ['logistic-robot'] = 256,
    ['construction-robot'] = 256,
    ['logistic-chest-active-provider'] = 256,
    ['logistic-chest-passive-provider'] = 256,
    ['logistic-chest-storage'] = 256,
    ['logistic-chest-buffer'] = 512,
    ['logistic-chest-requester'] = 512,
    ['roboport'] = 2048,
    ['small-lamp'] = 16,
    ['red-wire'] = 4,
    ['green-wire'] = 4,
    ['arithmetic-combinator'] = 16,
    ['decider-combinator'] = 16,
    ['constant-combinator'] = 16,
    ['power-switch'] = 16,
    ['programmable-speaker'] = 32,
    ['stone-brick'] = 2,
    ['concrete'] = 4,
    ['hazard-concrete'] = 4,
    ['refined-concrete'] = 16,
    ['refined-hazard-concrete'] = 16,
    ['cliff-explosives'] = 256,
    ['repair-pack'] = 8,
    ['boiler'] = 8,
    ['steam-engine'] = 32,
    ['solar-panel'] = 64,
    ['accumulator'] = 64,
    ['nuclear-reactor'] = 8192,
    ['heat-pipe'] = 128,
    ['heat-exchanger'] = 256,
    ['steam-turbine'] = 256,
    ['burner-mining-drill'] = 8,
    ['electric-mining-drill'] = 32,
    ['offshore-pump'] = 16,
    ['pumpjack'] = 64,
    ['stone-furnace'] = 4,
    ['steel-furnace'] = 64,
    ['electric-furnace'] = 256,
    ['assembling-machine-1'] = 32,
    ['assembling-machine-2'] = 128,
    ['assembling-machine-3'] = 512,
    ['oil-refinery'] = 256,
    ['chemical-plant'] = 128,
    ['centrifuge'] = 2048,
    ['lab'] = 64,
    ['beacon'] = 512,
    ['speed-module'] = 128,
    ['speed-module-2'] = 512,
    ['speed-module-3'] = 2048,
    ['effectivity-module'] = 128,
    ['effectivity-module-2'] = 512,
    ['effectivity-module-3'] = 2048,
    ['productivity-module'] = 128,
    ['productivity-module-2'] = 512,
    ['productivity-module-3'] = 2048,
    ['iron-plate'] = 1,
    ['copper-plate'] = 1,
    ['solid-fuel'] = 16,
    ['steel-plate'] = 8,
    ['plastic-bar'] = 8,
    ['sulfur'] = 4,
    ['battery'] = 16,
    ['explosives'] = 4,
    ['crude-oil-barrel'] = 8,
    ['heavy-oil-barrel'] = 16,
    ['light-oil-barrel'] = 16,
    ['lubricant-barrel'] = 16,
    ['petroleum-gas-barrel'] = 16,
    ['sulfuric-acid-barrel'] = 16,
    ['water-barrel'] = 4,
    ['copper-cable'] = 1,
    ['iron-stick'] = 1,
    ['iron-gear-wheel'] = 2,
    ['empty-barrel'] = 4,
    ['electronic-circuit'] = 4,
    ['advanced-circuit'] = 16,
    ['processing-unit'] = 128,
    ['engine-unit'] = 8,
    ['electric-engine-unit'] = 64,
    ['flying-robot-frame'] = 128,
    ['satellite'] = 32768,
    ['rocket-control-unit'] = 256,
    ['low-density-structure'] = 64,
    ['rocket-fuel'] = 256,
    ['nuclear-fuel'] = 1024,
    ['uranium-235'] = 1024,
    ['uranium-238'] = 32,
    ['uranium-fuel-cell'] = 128,
    ['automation-science-pack'] = 4,
    ['logistic-science-pack'] = 16,
    ['military-science-pack'] = 64,
    ['chemical-science-pack'] = 128,
    ['production-science-pack'] = 256,
    ['utility-science-pack'] = 256,
    ['space-science-pack'] = 512,
    ['submachine-gun'] = 32,
    ['shotgun'] = 16,
    ['combat-shotgun'] = 256,
    ['rocket-launcher'] = 128,
    ['flamethrower'] = 512,
    ['firearm-magazine'] = 4,
    ['piercing-rounds-magazine'] = 8,
    ['uranium-rounds-magazine'] = 64,
    ['shotgun-shell'] = 4,
    ['piercing-shotgun-shell'] = 16,
    ['cannon-shell'] = 8,
    ['explosive-cannon-shell'] = 16,
    ['uranium-cannon-shell'] = 64,
    ['explosive-uranium-cannon-shell'] = 64,
    ['rocket'] = 8,
    ['explosive-rocket'] = 8,
    ['flamethrower-ammo'] = 32,
    ['grenade'] = 16,
    ['cluster-grenade'] = 64,
    ['poison-capsule'] = 64,
    ['slowdown-capsule'] = 16,
    ['defender-capsule'] = 16,
    ['distractor-capsule'] = 128,
    ['destroyer-capsule'] = 256,
    ['light-armor'] = 32,
    ['heavy-armor'] = 256,
    ['modular-armor'] = 1024,
    ['power-armor'] = 4096,
    ['power-armor-mk2'] = 32768,
    ['solar-panel-equipment'] = 256,
    ['fusion-reactor-equipment'] = 8192,
    ['energy-shield-equipment'] = 512,
    ['energy-shield-mk2-equipment'] = 4096,
    ['battery-equipment'] = 128,
    ['battery-mk2-equipment'] = 2048,
    ['personal-laser-defense-equipment'] = 2048,
    ['belt-immunity-equipment'] = 256,
    ['exoskeleton-equipment'] = 1024,
    ['personal-roboport-equipment'] = 512,
    ['personal-roboport-mk2-equipment'] = 4096,
    ['night-vision-equipment'] = 256,
    ['stone-wall'] = 8,
    ['gate'] = 16,
    ['gun-turret'] = 64,
    ['laser-turret'] = 1024,
    ['flamethrower-turret'] = 2048,
    ['radar'] = 32,
    ['rocket-silo'] = 65536
}

local item_names = {}
for k, _ in pairs(item_worths) do
    insert(item_names, k)
end
local size_of_item_names = #item_names

local function get_raffle_keys()
    local raffle_keys = {}
    for i = 1, size_of_item_names, 1 do
        raffle_keys[i] = i
    end
    shuffle(raffle_keys)
    return raffle_keys
end

local function get_random_weighted(weighted_table, weight_index)
    local total_weight = 0
    weight_index = weight_index or 1

    for _, w in pairs(weighted_table) do
        total_weight = total_weight + w[weight_index]
    end

    local index = random() * total_weight
    local weight_sum = 0
    for k, w in pairs(weighted_table) do
        weight_sum = weight_sum + w[weight_index]
        if weight_sum >= index then
            return w, k
        end
    end
end

local function init_price_check(locomotive, mystical_chest)
    local roll = 48 + abs(locomotive.position.y) * 1.75
    roll = roll * random(25, 1337) * 0.01

    local item_stacks = {}
    local roll_count = 2
    for _ = 1, roll_count, 1 do
        for _, stack in pairs(Public.roll(floor(roll / roll_count), 2)) do
            if not item_stacks[stack.name] then
                item_stacks[stack.name] = stack.count
            else
                item_stacks[stack.name] = item_stacks[stack.name] + stack.count
            end
        end
    end

    local price = {}
    for k, v in pairs(item_stacks) do
        insert(price, {name = k, count = v})
    end

    mystical_chest.price = price
end

local function roll_item_stacks(remaining_budget, max_slots, blacklist)
    local item_stack_set = {}
    local item_stack_set_worth = 0

    for i = 1, max_slots, 1 do
        if remaining_budget <= 0 then
            break
        end
        local item_stack = Public.roll_item_stack(remaining_budget, blacklist)
        item_stack_set[i] = item_stack
        remaining_budget = remaining_budget - item_stack.count * item_worths[item_stack.name]
        item_stack_set_worth = item_stack_set_worth + item_stack.count * item_worths[item_stack.name]
    end

    return item_stack_set, item_stack_set_worth
end

local restore_mining_speed_token =
    Token.register(
    function()
        local mc_rewards = WPT.get('mc_rewards')
        local force = game.forces.player
        if mc_rewards.temp_boosts.mining then
            force.manual_mining_speed_modifier = force.manual_mining_speed_modifier - 0.5
            mc_rewards.temp_boosts.mining = nil
        end
    end
)

local restore_movement_speed_token =
    Token.register(
    function()
        local mc_rewards = WPT.get('mc_rewards')
        local force = game.forces.player
        if mc_rewards.temp_boosts.movement then
            force.character_running_speed_modifier = force.character_running_speed_modifier - 0.2
            mc_rewards.temp_boosts.movement = nil
        end
    end
)

local mc_random_rewards = {
    {
        name = 'XP',
        color = {r = 0.00, g = 0.45, b = 0.00},
        tooltip = 'Selecting this will insert random XP onto the global xp pool!',
        func = (function(player)
            local rng = random(1024, 10240)
            RPG.add_to_global_pool(rng)
            local message = ({'locomotive.xp_bonus', player.name})
            Alert.alert_all_players(15, message, nil, 'achievement/tech-maniac')
            return true
        end),
        512
    },
    {
        name = 'Coins',
        color = {r = 0.00, g = 0.35, b = 0.00},
        tooltip = 'Selecting this will grant each player some coins!',
        func = (function(p)
            local rng = random(256, 512)
            local players = game.connected_players
            for i = 1, #players do
                local player = players[i]
                if player and player.valid then
                    if player.can_insert({name = 'coin', count = rng}) then
                        player.insert({name = 'coin', count = rng})
                    end
                end
            end
            local message = ({'locomotive.coin_bonus', p.name})
            Alert.alert_all_players(15, message, nil, 'achievement/tech-maniac')
            return true
        end),
        512
    },
    {
        name = 'Movement bonus',
        str = 'movement',
        color = {r = 0.00, g = 0.25, b = 0.00},
        tooltip = 'Selecting this will grant the team a bonus movement speed for 15 minutes!',
        func = (function(player)
            local mc_rewards = WPT.get('mc_rewards')
            local force = game.forces.player
            if mc_rewards.temp_boosts.movement then
                return false, '[Rewards] Movement bonus is already applied. Please choose another reward.'
            end

            mc_rewards.temp_boosts.movement = true

            Task.set_timeout_in_ticks(54000, restore_movement_speed_token)
            force.character_running_speed_modifier = force.character_running_speed_modifier + 0.2
            local message = ({'locomotive.movement_bonus', player.name})
            Alert.alert_all_players(15, message, nil, 'achievement/tech-maniac')
            return true
        end),
        512
    },
    {
        name = 'Mining bonus',
        str = 'mining',
        color = {r = 0.00, g = 0.00, b = 0.25},
        tooltip = 'Selecting this will grant the team a bonus mining speed for 15 minutes!',
        func = (function(player)
            local mc_rewards = WPT.get('mc_rewards')
            local force = game.forces.player
            if mc_rewards.temp_boosts.mining then
                return false, '[Rewards] Mining bonus is already applied. Please choose another reward.'
            end

            mc_rewards.temp_boosts.mining = true

            Task.set_timeout_in_ticks(54000, restore_mining_speed_token)
            force.manual_mining_speed_modifier = force.manual_mining_speed_modifier + 0.5
            local message = ({'locomotive.mining_bonus', player.name})
            Alert.alert_all_players(15, message, nil, 'achievement/tech-maniac')
            return true
        end),
        512
    },
    {
        name = 'Heal Locomotive',
        color = {r = 0.00, g = 0.00, b = 0.25},
        tooltip = 'Selecting this will heal the main locomotive to full health!',
        func = (function(player)
            local locomotive_max_health = WPT.get('locomotive_max_health')
            WPT.set('locomotive_health', locomotive_max_health)
            local message = ({'locomotive.locomotive_health', player.name})
            Alert.alert_all_players(15, message, nil, 'achievement/tech-maniac')
            return true
        end),
        256
    }
}

local function mystical_chest_reward(player)
    if player.gui.screen['reward_system'] then
        player.gui.screen['reward_system'].destroy()
        return
    end

    local frame = player.gui.screen.add {type = 'frame', caption = 'Mystical Reward:', name = 'reward_system', direction = 'vertical'}
    frame.auto_center = true
    frame = frame.add {type = 'frame', name = 'reward_system_1', direction = 'vertical', style = 'inside_shallow_frame'}
    frame.style.padding = 4

    local mc_rewards = WPT.get('mc_rewards')
    mc_rewards.current = {}

    for i = 1, 3 do
        local d, key = get_random_weighted(mc_random_rewards)
        if not mc_rewards.current[key] and not mc_rewards.temp_boosts[d.str] then
            mc_rewards.current[key] = {
                id = i,
                name = d.name
            }
            local b = frame.add({type = 'button', name = tostring(i), caption = d.name})
            b.style.font_color = d.color
            b.style.font = 'heading-2'
            b.style.minimal_width = 180
            b.style.horizontal_align = 'center'
            b.tooltip = d.tooltip
        end
    end
    if not next(mc_rewards.current) then
        if player.gui.screen['reward_system'] then
            player.gui.screen['reward_system'].destroy()
        end
        return player.print('[Rewards] No rewards are available.', Color.fail)
    end

    -- something fancy to reward players
end

local function container_opened(event)
    local entity = event.entity
    if not entity then
        return
    end
    if not entity.valid then
        return
    end
    if not entity.unit_number then
        return
    end

    local mystical_chest = WPT.get('mystical_chest')
    if not mystical_chest then
        return
    end
    if not (mystical_chest.entity and mystical_chest.entity.valid) then
        return
    end

    if entity.unit_number ~= mystical_chest.entity.unit_number then
        return
    end

    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end

    Public.add_mystical_chest(player)
end

local function on_gui_opened(event)
    container_opened(event)
end

local function on_gui_closed(event)
    container_opened(event)
end

local function on_gui_click(event)
    local element = event.element
    if not (element and element.valid) then
        return
    end

    if element.type ~= 'button' then
        return
    end

    if element.parent.name ~= 'reward_system_1' then
        return
    end
    local i = tonumber(element.name)

    local mc_rewards = WPT.get('mc_rewards')
    local current = mc_rewards.current

    local player = game.get_player(element.player_index)
    if not (player and player.valid) then
        return
    end

    for id, data in pairs(current) do
        if data.id == i then
            local success, msg = mc_random_rewards[id].func(player)
            if not success then
                return player.print(msg, Color.fail)
            end
            break
        end
    end

    element.parent.parent.destroy()
end

function Public.roll_item_stack(remaining_budget, blacklist)
    if remaining_budget <= 0 then
        return
    end
    local raffle_keys = get_raffle_keys()
    local item_name = false
    local item_worth = 0
    for _, index in pairs(raffle_keys) do
        item_name = item_names[index]
        item_worth = item_worths[item_name]
        if not blacklist[item_name] and item_worth <= remaining_budget then
            break
        end
    end

    local stack_size = game.item_prototypes[item_name].stack_size * 32

    local item_count = 1

    for c = 1, random(1, stack_size), 1 do
        local price = c * item_worth
        if price <= remaining_budget then
            item_count = c
        else
            break
        end
    end

    return {name = item_name, count = item_count}
end

function Public.roll(budget, max_slots, blacklist)
    if not budget then
        return
    end
    if not max_slots then
        return
    end

    local b
    if not blacklist then
        b = {}
    else
        b = blacklist
    end

    budget = floor(budget)
    if budget == 0 then
        return
    end

    local final_stack_set
    local final_stack_set_worth = 0

    for _ = 1, 5, 1 do
        local item_stack_set, item_stack_set_worth = roll_item_stacks(budget, max_slots, b)
        if item_stack_set_worth > final_stack_set_worth or item_stack_set_worth == budget then
            final_stack_set = item_stack_set
            final_stack_set_worth = item_stack_set_worth
        end
    end
    return final_stack_set
end

function Public.add_mystical_chest(player)
    local locomotive = WPT.get('locomotive')
    if not locomotive then
        return
    end
    if not locomotive.valid then
        return
    end

    local mystical_chest = WPT.get('mystical_chest')
    if not (mystical_chest.entity and mystical_chest.entity.valid) then
        return
    end

    if not mystical_chest.price then
        init_price_check(locomotive, mystical_chest)
    end

    local entity = mystical_chest.entity

    local inventory = mystical_chest.entity.get_inventory(defines.inventory.chest)

    for key, item_stack in pairs(mystical_chest.price) do
        local count_removed = inventory.remove(item_stack)
        mystical_chest.price[key].count = mystical_chest.price[key].count - count_removed
        if mystical_chest.price[key].count <= 0 then
            table.remove(mystical_chest.price, key)
        end
    end

    if #mystical_chest.price == 0 then
        init_price_check(locomotive, mystical_chest)
        if player and player.valid then
            mystical_chest_reward(player)
        end
        return true
    end

    for slot = 1, 30, 1 do
        entity.clear_request_slot(slot)
    end

    for slot, item_stack in pairs(mystical_chest.price) do
        mystical_chest.entity.set_request_slot(item_stack, slot)
    end
end

Public.init_price_check = init_price_check

Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_gui_closed, on_gui_closed)
Event.add(defines.events.on_gui_click, on_gui_click)

return Public
