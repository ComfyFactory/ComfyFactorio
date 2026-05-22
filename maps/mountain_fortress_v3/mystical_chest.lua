local Server = require 'utils.server'
local Color = require 'utils.color_presets'
local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local RPG = require 'modules.rpg.main'
local Alert = require 'utils.alert'
local Task = require 'utils.task_token'
local StatData = require 'utils.datastore.statistics'
local Commands = require 'utils.commands'

local zone_settings = Public.zone_settings
local shuffle = table.shuffle_table
local random = math.random
local deep_copy = table.deep_copy
local floor = math.floor
local insert = table.insert
local abs = math.abs

local modifier_cooldown = 108000 -- 30 minutes

local techs_to_research =
{
    'automation-science-pack',
    'logistic-science-pack',
    'military-science-pack',
    'chemical-science-pack',
    'production-science-pack',
    'utility-science-pack',
    'space-science-pack'
}

local ammo_to_research =
{
    ['firearm-magazine'] = { tech = 'automation' },
    ['piercing-rounds-magazine'] = { tech = 'military-2' },
    ['uranium-rounds-magazine'] = { tech = 'uranium-ammo' },
    ['shotgun-shell'] = { tech = 'military' },
    ['piercing-shotgun-shell'] = { tech = 'military-4' },
    ['cannon-shell'] = { tech = 'military' },
    ['explosive-cannon-shell'] = { tech = 'military-3' },
    ['uranium-cannon-shell'] = { tech = 'uranium-ammo' },
    ['explosive-uranium-cannon-shell'] = { tech = 'military-3' },
    ['rocket'] = { tech = 'rocketry' },
    ['explosive-rocket'] = { tech = 'explosive-rocketry' },
    ['flamethrower-ammo'] = { tech = 'flamethrower' },
    ['grenade'] = { tech = 'military-2' },
    ['cluster-grenade'] = { tech = 'military-4' },
    ['poison-capsule'] = { tech = 'military-3' },
    ['slowdown-capsule'] = { tech = 'military-3' },
    ['defender-capsule'] = { tech = 'military-3' },
    ['distractor-capsule'] = { tech = 'military-4' },
    ['destroyer-capsule'] = { tech = 'military-4' }
}

local item_worths =
{
    ['water-barrel'] = 4,
    ['copper-cable'] = 1,
    ['iron-stick'] = 1,
    ['iron-gear-wheel'] = 2,
    ['electronic-circuit'] = 4,
    ['advanced-circuit'] = 16,
    ['processing-unit'] = 128,
    ['engine-unit'] = 8,
    ['electric-engine-unit'] = 64,
    ['flying-robot-frame'] = 128,
    ['satellite'] = 32768,
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
    ['fission-reactor-equipment'] = 8192,
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

local function init_price_check(locomotive)
    local mystical_chest = Public.get('mystical_chest')
    if not (mystical_chest and mystical_chest.valid) then
        return
    end
    local adjusted_zones = Public.get('adjusted_zones')
    local size = 132
    if adjusted_zones and adjusted_zones.size then
        size = adjusted_zones.size
    end

    local zone = floor((abs(locomotive.position.y / zone_settings.zone_depth)) % size) + 1

    local roll = 48 + abs(locomotive.position.y) * 1.75
    roll = roll * random(25, 1337) * 0.01
    roll = roll * zone

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
        insert(price, { min = v, value = { comparator = "=", name = k, quality = "normal" } })
    end

    Public.set('mystical_chest_price', price)
    Public.set('mystical_chest_price_init', deep_copy(price))
end

local function roll_item_stacks(remaining_budget, max_slots, blacklist)
    local item_stack_set = {}
    local item_stack_set_worth = 0

    for i = 1, max_slots, 1 do
        if remaining_budget <= 0 then
            break
        end
        local item_stack = Public.roll_item_stack(remaining_budget, blacklist)
        if not item_stack then
            item_stack = Public.roll_item_stack(remaining_budget, blacklist)
        end
        if not item_stack then
            Server.output_script_data('No item stack found for remaining budget: ' .. tostring(remaining_budget))
            break
        end
        item_stack_set[i] = item_stack
        remaining_budget = remaining_budget - item_stack.count * item_worths[item_stack.name]
        item_stack_set_worth = item_stack_set_worth + item_stack.count * item_worths[item_stack.name]
    end

    if not item_stack_set or #item_stack_set == 0 then
        Server.output_script_data('No item stack set found for remaining budget: ' .. tostring(remaining_budget) .. ' with max slots: ' .. tostring(max_slots))
        return {}, 0
    end
    return item_stack_set, item_stack_set_worth
end

local restore_mining_speed_token =
    Task.register(
        function ()
            local mc_rewards = Public.get('mc_rewards')
            local force = game.forces.player
            if mc_rewards.temp_boosts.mining then
                force.manual_mining_speed_modifier = force.manual_mining_speed_modifier - 0.5
                mc_rewards.temp_boosts.mining = nil
                local message = ({ 'locomotive.mining_bonus_end' })
                Alert.alert_all_players(10, message, nil, 'achievement/tech-maniac')
            end
        end
    )

local restore_crafting_speed_token =
    Task.register(
        function ()
            local mc_rewards = Public.get('mc_rewards')
            local force = game.forces.player
            if mc_rewards.temp_boosts.crafting then
                force.manual_crafting_speed_modifier = force.manual_crafting_speed_modifier - 1
                mc_rewards.temp_boosts.crafting = nil
                local message = ({ 'locomotive.crafting_bonus_end' })
                Alert.alert_all_players(10, message, nil, 'achievement/tech-maniac')
            end
        end
    )

local restore_modifier_token =
    Task.register(
        function (event)
            local mc_rewards = Public.get('mc_rewards')
            local modifier = event.modifier
            if not modifier then
                return
            end

            mc_rewards.temp_boosts[modifier] = false
            local message = ({ 'locomotive.restore_bonus_end', modifier })
            Alert.alert_all_players(10, message, nil, 'achievement/tech-maniac')
        end
    )

local restore_active_modifier_token =
    Task.register(
        function (event)
            local mc_rewards = Public.get('mc_rewards')
            local modifier = event.modifier
            if not modifier then
                return
            end

            mc_rewards.active_boosts[modifier] = false
            local message = ({ 'locomotive.bonus_bonus_end', modifier:gsub("_", " ") })
            Alert.alert_all_players(10, message, nil, 'achievement/tech-maniac')

            if modifier == 'coins' then
                Public.set('coin_amount', Public.get('coin_amount_previous'))
            end
            if modifier == 'prototype_data_disk' then
                Public.set('prototype_data_disk_bonus', false)
            end
            if modifier == 'lab_overclock' then
                game.forces.player.laboratory_speed_modifier = game.forces.player.laboratory_speed_modifier - 1
            end
        end
    )

local restore_movement_speed_token =
    Task.register(
        function (event)
            local mc_rewards = Public.get('mc_rewards')
            local force = game.forces.player
            if mc_rewards.temp_boosts.movement then
                force.character_running_speed_modifier = event.speed
                mc_rewards.temp_boosts.movement = nil
                local message = ({ 'locomotive.movement_bonus_end' })
                Alert.alert_all_players(10, message, nil, 'achievement/tech-maniac')
            end
        end
    )

local mc_random_rewards =
{
    {
        name = 'XP',
        str = 'xp',
        color = { r = 0.00, g = 0.45, b = 0.00 },
        tooltip = 'Selecting this will insert random XP onto the global xp pool!',
        func = (function (player, zone)
            local mc_rewards = Public.get('mc_rewards')
            if mc_rewards.temp_boosts.xp then
                return false, '[Rewards] XP bonus is already applied and is currently on cooldown. Please choose another reward.'
            end
            local mystical_rewards = Public.get('mystical_rewards')
            mystical_rewards.xp_bonus = mystical_rewards.xp_bonus and mystical_rewards.xp_bonus + 1 or 1

            mc_rewards.temp_boosts.xp = true
            Task.set_timeout_in_ticks(modifier_cooldown, restore_modifier_token, { modifier = 'xp' })
            local rng = random(2048, 10240)
            local scale_factor = 0.5 + (zone / 20)
            rng = floor(rng * scale_factor)
            RPG.add_to_global_pool(rng)
            local message = ({ 'locomotive.xp_bonus', player.name })
            Alert.alert_all_players(15, message, nil, 'achievement/tech-maniac')
            Server.to_discord_bold(table.concat { '*** ', '[Mystical Chest] ' .. player.name .. ' has granted xp bonus for the whole team!', ' ***' })
            return true
        end),
        512
    },
    {
        name = 'Science glory',
        str = 'science',
        color = { r = 0.00, g = 0.80, b = 0.00 },
        tooltip = 'Selecting this will grant all of the researched tech in the mystical chest!',
        func = (function (player, _)
            local mc_rewards = Public.get('mc_rewards')
            if mc_rewards.temp_boosts.science then
                return false, '[Rewards] Science bonus is already applied and is currently on cooldown. Please choose another reward.'
            end
            mc_rewards.temp_boosts.science = true
            Task.set_timeout_in_ticks(modifier_cooldown, restore_modifier_token, { modifier = 'science' })


            local mystical_chest = Public.get('mystical_chest')
            if not (mystical_chest and mystical_chest.valid) then
                return
            end

            local mystical_rewards = Public.get('mystical_rewards')
            mystical_rewards.science_bonus = mystical_rewards.science_bonus and mystical_rewards.science_bonus + 1 or 1

            local techs = game.forces.player.technologies

            for _, tech in pairs(techs_to_research) do
                if techs[tech] and techs[tech].researched then
                    if mystical_chest.can_insert({ name = tech, count = random(200, 1500) }) then
                        mystical_chest.insert({ name = tech, count = random(200, 1500) })
                    else
                        mystical_chest.surface.spill_item_stack({ position = mystical_chest.position, stack = { name = tech, count = random(200, 1500) }, enable_looted = true })
                    end
                end
            end

            Alert.alert_all_players(15, 'Science for all! Check out the mystical chest!', nil, 'achievement/tech-maniac')
            Server.to_discord_bold(table.concat { '*** ', '[Mystical Chest] ' .. player.name .. ' has granted science bonus to the team!', ' ***' })
            return true
        end),
        1024
    },
    {
        name = 'Ammo for all',
        str = 'ammo',
        color = { r = 0.00, g = 0.35, b = 0.20 },
        tooltip = 'Selecting this will grant ammo to the team!',
        func = (function (player, _)
            local mc_rewards = Public.get('mc_rewards')
            if mc_rewards.temp_boosts.ammo then
                return false, '[Rewards] Ammo bonus is already applied and is currently on cooldown. Please choose another reward.'
            end
            mc_rewards.temp_boosts.ammo = true
            Task.set_timeout_in_ticks(modifier_cooldown, restore_modifier_token, { modifier = 'ammo' })


            local mystical_chest = Public.get('mystical_chest')
            if not (mystical_chest and mystical_chest.valid) then
                return
            end

            local mystical_rewards = Public.get('mystical_rewards')
            mystical_rewards.ammo_bonus = mystical_rewards.ammo_bonus and mystical_rewards.ammo_bonus + 1 or 1

            local techs = game.forces.player.technologies

            for name, tech in pairs(ammo_to_research) do
                if techs[tech.tech] and techs[tech.tech].researched then
                    if mystical_chest.can_insert({ name = name, count = random(200, 400) }) then
                        mystical_chest.insert({ name = name, count = random(200, 400) })
                    else
                        mystical_chest.surface.spill_item_stack({ position = mystical_chest.position, stack = { name = name, count = random(200, 400) }, enable_looted = true })
                    end
                end
            end

            Alert.alert_all_players(15, 'Ammo for all! Check out the mystical chest!', nil, 'achievement/tech-maniac')
            Server.to_discord_bold(table.concat { '*** ', '[Mystical Chest] ' .. player.name .. ' has granted ammo bonus to the team!', ' ***' })
            return true
        end),
        512
    },
    {
        name = 'Market reroll',
        str = 'market_reroll',
        color = { r = 0.20, g = 0.35, b = 0.35 },
        tooltip = 'Selecting this will reroll all the market items in the map!',
        func = (function (player, _)
            local mc_rewards = Public.get('mc_rewards')
            if mc_rewards.temp_boosts.market_reroll then
                return false, '[Rewards] Market reroll bonus is already applied and is currently on cooldown. Please choose another reward.'
            end
            mc_rewards.temp_boosts.market_reroll = true
            mc_rewards.active_boosts.market_reroll = true
            Task.set_timeout_in_ticks(modifier_cooldown, restore_modifier_token, { modifier = 'market_reroll' })

            Public.set('market_reroll_bonus', Public.get('market_reroll_bonus') and Public.get('market_reroll_bonus') + 1 or 1)

            local mystical_chest = Public.get('mystical_chest')
            if not (mystical_chest and mystical_chest.valid) then
                return
            end


            local active_surface_index = Public.get('active_surface_index')
            local surface = game.get_surface(active_surface_index)
            if not (surface and surface.valid) then
                return
            end

            local markets = surface.find_entities_filtered({ name = 'market', })
            if #markets > 0 then
                for _, mrk in pairs(markets) do
                    if mrk and mrk.valid then
                        Public.reroll_market(mrk, abs(mrk.position.y) * 0.004)
                    end
                end
            end

            local mystical_rewards = Public.get('mystical_rewards')
            mystical_rewards.market_reroll_bonus = mystical_rewards.market_reroll_bonus and mystical_rewards.market_reroll_bonus + 1 or 1

            Alert.alert_all_players(15, 'Market reroll! All markets in the main surface have been rerolled!', nil, 'achievement/tech-maniac')
            Server.to_discord_bold(table.concat { '*** ', '[Mystical Chest] ' .. player.name .. ' has granted market reroll bonus to the team!', ' ***' })
            return true
        end),
        512
    },
    {
        name = 'Coin overclock',
        str = 'coins',
        color = { r = 0.20, g = 0.35, b = 0.00 },
        tooltip = 'Selecting this will grant a higher chance of finding extra coins when killing biters!',
        func = (function (player, _)
            local mc_rewards = Public.get('mc_rewards')
            if mc_rewards.temp_boosts.coins then
                return false, '[Rewards] Coins bonus is already applied and is currently on cooldown. Please choose another reward.'
            end
            mc_rewards.temp_boosts.coins = true
            mc_rewards.active_boosts.coins = true
            Task.set_timeout_in_ticks(modifier_cooldown, restore_modifier_token, { modifier = 'coins' })
            Task.set_timeout_in_ticks(54000, restore_active_modifier_token, { modifier = 'coins' })
            Public.set('coin_amount_previous', Public.get('coin_amount'))
            Public.set('coin_amount', 3)

            local mystical_chest = Public.get('mystical_chest')
            if not (mystical_chest and mystical_chest.valid) then
                return
            end

            local mystical_rewards = Public.get('mystical_rewards')
            mystical_rewards.coins_bonus = mystical_rewards.coins_bonus and mystical_rewards.coins_bonus + 1 or 1

            Alert.alert_all_players(15, 'Coins overclock! Get extra coins when killing biters!', nil, 'achievement/tech-maniac')
            Server.to_discord_bold(table.concat { '*** ', '[Mystical Chest] ' .. player.name .. ' has granted coins overclock bonus to the team!', ' ***' })
            return true
        end),
        1024
    },
    {
        name = 'Tactical bacon',
        str = 'tactical_bacon',
        color = { r = 0.00, g = 0.35, b = 0.20 },
        tooltip = 'Selecting this will grant the team some defensive items!',
        func = (function (player, _)
            local mc_rewards = Public.get('mc_rewards')
            if mc_rewards.temp_boosts.tactical_bacon then
                return false, '[Rewards] Tactical Bacon bonus is already applied and is currently on cooldown. Please choose another reward.'
            end
            mc_rewards.temp_boosts.tactical_bacon = true
            mc_rewards.active_boosts.tactical_bacon = true
            Task.set_timeout_in_ticks(modifier_cooldown, restore_modifier_token, { modifier = 'tactical_bacon' })

            local mystical_chest = Public.get('mystical_chest')
            if not (mystical_chest and mystical_chest.valid) then
                return
            end

            if mystical_chest.can_insert({ name = 'stone-wall', count = random(100, 240) }) then
                mystical_chest.insert({ name = 'stone-wall', count = random(100, 240) })
            else
                mystical_chest.surface.spill_item_stack({ position = mystical_chest.position, stack = { name = 'stone-wall', count = random(100, 240) }, enable_looted = true })
            end

            if mystical_chest.can_insert({ name = 'gate', count = random(100, 240) }) then
                mystical_chest.insert({ name = 'gate', count = random(100, 240) })
            else
                mystical_chest.surface.spill_item_stack({ position = mystical_chest.position, stack = { name = 'gate', count = random(100, 240) }, enable_looted = true })
            end

            if mystical_chest.can_insert({ name = 'repair-pack', count = random(100, 240) }) then
                mystical_chest.insert({ name = 'repair-pack', count = random(100, 240) })
            else
                mystical_chest.surface.spill_item_stack({ position = mystical_chest.position, stack = { name = 'repair-pack', count = random(100, 240) }, enable_looted = true })
            end

            if mystical_chest.can_insert({ name = 'gun-turret', count = random(20, 100) }) then
                mystical_chest.insert({ name = 'gun-turret', count = random(20, 100) })
            else
                mystical_chest.surface.spill_item_stack({ position = mystical_chest.position, stack = { name = 'gun-turret', count = random(20, 100) }, enable_looted = true })
            end

            if mystical_chest.can_insert({ name = 'laser-turret', count = random(20, 100) }) then
                mystical_chest.insert({ name = 'laser-turret', count = random(20, 100) })
            else
                mystical_chest.surface.spill_item_stack({ position = mystical_chest.position, stack = { name = 'laser-turret', count = random(20, 100) }, enable_looted = true })
            end

            if mystical_chest.can_insert({ name = 'flamethrower-turret', count = random(20, 40) }) then
                mystical_chest.insert({ name = 'flamethrower-turret', count = random(20, 40) })
            else
                mystical_chest.surface.spill_item_stack({ position = mystical_chest.position, stack = { name = 'flamethrower-turret', count = random(20, 40) }, enable_looted = true })
            end

            if mystical_chest.can_insert({ name = 'firearm-magazine', count = random(400, 800) }) then
                mystical_chest.insert({ name = 'firearm-magazine', count = random(400, 800) })
            else
                mystical_chest.surface.spill_item_stack({ position = mystical_chest.position, stack = { name = 'firearm-magazine', count = random(400, 800) }, enable_looted = true })
            end

            if mystical_chest.can_insert({ name = 'shotgun-shell', count = random(400, 800) }) then
                mystical_chest.insert({ name = 'shotgun-shell', count = random(400, 800) })
            else
                mystical_chest.surface.spill_item_stack({ position = mystical_chest.position, stack = { name = 'shotgun-shell', count = random(400, 800) }, enable_looted = true })
            end

            if mystical_chest.can_insert({ name = 'piercing-shotgun-shell', count = random(400, 800) }) then
                mystical_chest.insert({ name = 'piercing-shotgun-shell', count = random(400, 800) })
            else
                mystical_chest.surface.spill_item_stack({ position = mystical_chest.position, stack = { name = 'piercing-shotgun-shell', count = random(400, 800) }, enable_looted = true })
            end

            if mystical_chest.can_insert({ name = 'combat-shotgun', count = random(10, 20) }) then
                mystical_chest.insert({ name = 'combat-shotgun', count = random(10, 20) })
            else
                mystical_chest.surface.spill_item_stack({ position = mystical_chest.position, stack = { name = 'combat-shotgun', count = random(10, 20) }, enable_looted = true })
            end

            if mystical_chest.can_insert({ name = 'submachine-gun', count = random(10, 20) }) then
                mystical_chest.insert({ name = 'submachine-gun', count = random(10, 20) })
            else
                mystical_chest.surface.spill_item_stack({ position = mystical_chest.position, stack = { name = 'submachine-gun', count = random(10, 20) }, enable_looted = true })
            end

            if mystical_chest.can_insert({ name = 'piercing-rounds-magazine', count = random(400, 800) }) then
                mystical_chest.insert({ name = 'piercing-rounds-magazine', count = random(400, 800) })
            else
                mystical_chest.surface.spill_item_stack({ position = mystical_chest.position, stack = { name = 'piercing-rounds-magazine', count = random(400, 800) }, enable_looted = true })
            end

            local mystical_rewards = Public.get('mystical_rewards')
            mystical_rewards.tactical_bacon_bonus = mystical_rewards.tactical_bacon_bonus and mystical_rewards.tactical_bacon_bonus + 1 or 1

            Alert.alert_all_players(15, 'Tactical Bacon! Get extra defensive items - check out the mystical chest!', nil, 'achievement/tech-maniac')
            Server.to_discord_bold(table.concat { '*** ', '[Mystical Chest] ' .. player.name .. ' has granted tactical bacon bonus to the team!', ' ***' })
            return true
        end),
        512
    },
    {
        name = 'Lab Overclock',
        str = 'lab_overclock',
        color = { r = 0.20, g = 0.35, b = 0.20 },
        tooltip = 'Selecting this will make labs research techs faster!',
        func = (function (player, _)
            local mc_rewards = Public.get('mc_rewards')
            if mc_rewards.temp_boosts.lab_overclock then
                return false, '[Rewards] Lab Overclock bonus is already applied and is currently on cooldown. Please choose another reward.'
            end
            mc_rewards.temp_boosts.lab_overclock = true
            mc_rewards.active_boosts.lab_overclock = true
            Task.set_timeout_in_ticks(modifier_cooldown, restore_modifier_token, { modifier = 'lab_overclock' })
            Task.set_timeout_in_ticks(54000, restore_active_modifier_token, { modifier = 'lab_overclock' })

            game.forces.player.laboratory_speed_modifier = game.forces.player.laboratory_speed_modifier + 1

            local mystical_chest = Public.get('mystical_chest')
            if not (mystical_chest and mystical_chest.valid) then
                return
            end

            local mystical_rewards = Public.get('mystical_rewards')
            mystical_rewards.lab_overclock_bonus = mystical_rewards.lab_overclock_bonus and mystical_rewards.lab_overclock_bonus + 1 or 1

            Alert.alert_all_players(15, 'Lab Overclock! Get extra lab research techs faster!', nil, 'achievement/tech-maniac')
            Server.to_discord_bold(table.concat { '*** ', '[Mystical Chest] ' .. player.name .. ' has granted lab overclock bonus to the team!', ' ***' })
            return true
        end),
        512
    },
    {
        name = 'Prototype Data Disk',
        str = 'prototype_data_disk',
        color = { r = 0.20, g = 0.35, b = 0.60 },
        tooltip = 'Selecting this will make market items more cheaper!',
        func = (function (player, _)
            local mc_rewards = Public.get('mc_rewards')
            if mc_rewards.temp_boosts.prototype_data_disk then
                return false, '[Rewards] Prototype Data Disk bonus is already applied and is currently on cooldown. Please choose another reward.'
            end
            mc_rewards.temp_boosts.prototype_data_disk = true
            mc_rewards.active_boosts.prototype_data_disk = true
            Task.set_timeout_in_ticks(modifier_cooldown, restore_modifier_token, { modifier = 'prototype_data_disk' })
            Task.set_timeout_in_ticks(54000, restore_active_modifier_token, { modifier = 'prototype_data_disk' })

            Public.set('prototype_data_disk_bonus', (random(50, 90) / 100))

            local mystical_chest = Public.get('mystical_chest')
            if not (mystical_chest and mystical_chest.valid) then
                return
            end

            local mystical_rewards = Public.get('mystical_rewards')
            mystical_rewards.prototype_data_disk_bonus = mystical_rewards.prototype_data_disk_bonus and mystical_rewards.prototype_data_disk_bonus + 1 or 1

            Alert.alert_all_players(15, 'Prototype Data Disk! Get extra market items more cheaper!', nil, 'achievement/tech-maniac')
            Server.to_discord_bold(table.concat { '*** ', '[Mystical Chest] ' .. player.name .. ' has granted prototype data disk bonus to the team!', ' ***' })
            return true
        end),
        1024
    },
    -- { -- needs fixing
    --     name = 'Lucky Looter',
    --     str = 'lucky',
    --     color = { r = 0.20, g = 0.35, b = 0.40 },
    --     tooltip = 'Selecting this will grant a higher chance of finding better loot!',
    --     func = (function (player, _)
    --         local mc_rewards = Public.get('mc_rewards')
    --         if mc_rewards.temp_boosts.lucky then
    --             return false, '[Rewards] Lucky bonus is already applied and is currently on cooldown. Please choose another reward.'
    --         end
    --         mc_rewards.temp_boosts.lucky = true
    --         mc_rewards.active_boosts.lucky = true
    --         Task.set_timeout_in_ticks(modifier_cooldown, restore_modifier_token, { modifier = 'lucky' })
    --         Task.set_timeout_in_ticks(54000, restore_active_modifier_token, { modifier = 'lucky' })


    --         local mystical_chest = Public.get('mystical_chest')
    --         if not (mystical_chest and mystical_chest.valid) then
    --             return
    --         end

    --         local mystical_rewards = Public.get('mystical_rewards')
    --         mystical_rewards.lucky_bonus = mystical_rewards.lucky_bonus and mystical_rewards.lucky_bonus + 1 or 1

    --         Alert.alert_all_players(15, 'Lucky Looter! Bonus magicka for all!', nil, 'achievement/tech-maniac')
    --         Server.to_discord_bold(table.concat { '*** ', '[Mystical Chest] ' .. player.name .. ' has granted lucky loot bonus to the team!', ' ***' })
    --         return true
    --     end),
    --     1024
    -- },
    {
        name = 'Oil Barrels',
        str = 'oil',
        color = { r = 0.20, g = 0.75, b = 0.40 },
        tooltip = 'Selecting this will grant oil to the team!',
        func = (function (player, _)
            local mc_rewards = Public.get('mc_rewards')
            if mc_rewards.temp_boosts.oil then
                return false, '[Rewards] Oil bonus is already applied and is currently on cooldown. Please choose another reward.'
            end
            mc_rewards.temp_boosts.oil = true
            Task.set_timeout_in_ticks(modifier_cooldown, restore_modifier_token, { modifier = 'oil' })


            local mystical_chest = Public.get('mystical_chest')
            if not (mystical_chest and mystical_chest.valid) then
                return
            end

            local mystical_rewards = Public.get('mystical_rewards')
            mystical_rewards.oil_bonus = mystical_rewards.oil_bonus and mystical_rewards.oil_bonus + 1 or 1

            if mystical_chest.can_insert({ name = 'crude-oil-barrel', count = random(200, 480) }) then
                mystical_chest.insert({ name = 'crude-oil-barrel', count = random(200, 480) })
            else
                mystical_chest.surface.spill_item_stack({ position = mystical_chest.position, stack = { name = 'crude-oil-barrel', count = random(200, 480) }, enable_looted = true })
            end

            Alert.alert_all_players(15, 'Oil for all! Check out the mystical chest!', nil, 'achievement/tech-maniac')
            Server.to_discord_bold(table.concat { '*** ', '[Mystical Chest] ' .. player.name .. ' has granted oil bonus to the team!', ' ***' })
            return true
        end),
        512
    },
    {
        name = 'Coins',
        str = 'coins',
        color = { r = 0.00, g = 0.35, b = 0.00 },
        tooltip = 'Selecting this will grant each player some coins!',
        func = (function (p, zone)
            local mc_rewards = Public.get('mc_rewards')
            if mc_rewards.temp_boosts.coins then
                return false, '[Rewards] Coin bonus is already applied and is currently on cooldown. Please choose another reward.'
            end

            local mystical_rewards = Public.get('mystical_rewards')
            mystical_rewards.coins_bonus = mystical_rewards.coins_bonus and mystical_rewards.coins_bonus + 1 or 1

            mc_rewards.temp_boosts.coins = true
            Task.set_timeout_in_ticks(modifier_cooldown, restore_modifier_token, { modifier = 'coins' })
            local players = game.connected_players
            for i = 1, #players do
                local rng = random(256, 1024)
                local scale_factor = 0.5 + (zone / 20)
                rng = floor(rng * scale_factor)
                local player = players[i]
                if player and player.valid then
                    if player.can_insert({ name = 'coin', count = rng }) then
                        player.insert({ name = 'coin', count = rng })
                        StatData.get_data(player):increase('coins', rng)
                    end
                end
            end
            local message = ({ 'locomotive.coin_bonus', p.name })
            Alert.alert_all_players(15, message, nil, 'achievement/tech-maniac')
            Server.to_discord_bold(table.concat { '*** ', '[Mystical Chest] ' .. p.name .. ' has granted coinsies for the whole team!', ' ***' })
            return true
        end),
        512
    },
    {
        name = 'Movement bonus',
        str = 'movement',
        color = { r = 0.00, g = 0.25, b = 0.00 },
        tooltip = 'Selecting this will grant the team a bonus movement speed for 30 minutes!',
        func = (function (player, zone)
            local mc_rewards = Public.get('mc_rewards')
            local force = game.forces.player
            if mc_rewards.temp_boosts.movement then
                return false, '[Rewards] Movement bonus is already applied. Please choose another reward.'
            end

            local mystical_rewards = Public.get('mystical_rewards')
            mystical_rewards.movement_speed = mystical_rewards.movement_speed and mystical_rewards.movement_speed + 1 or 1

            mc_rewards.temp_boosts.movement = true

            Task.set_timeout_in_ticks(108000, restore_movement_speed_token, { speed = force.character_running_speed_modifier })
            local scale_factor = 0.5 + (zone / 10)
            local speed = 0.6 * scale_factor
            if speed > 1 then
                speed = 1
            end
            force.character_running_speed_modifier = force.character_running_speed_modifier + speed
            local message = ({ 'locomotive.movement_bonus', player.name })
            Alert.alert_all_players(15, message, nil, 'achievement/tech-maniac')
            Server.to_discord_bold(table.concat { '*** ', '[Mystical Chest] ' .. player.name .. ' has granted movement speed bonus for the whole team!', ' ***' })
            return true
        end),
        512
    },
    {
        name = 'Mining bonus',
        str = 'mining',
        color = { r = 0.00, g = 0.00, b = 0.25 },
        tooltip = 'Selecting this will grant the team a bonus mining speed for 30 minutes!',
        func = (function (player)
            local mc_rewards = Public.get('mc_rewards')
            local force = game.forces.player
            if mc_rewards.temp_boosts.mining then
                return false, '[Rewards] Mining bonus is already applied. Please choose another reward.'
            end

            local mystical_rewards = Public.get('mystical_rewards')
            mystical_rewards.mining_speed = mystical_rewards.mining_speed and mystical_rewards.mining_speed + 1 or 1

            mc_rewards.temp_boosts.mining = true

            Task.set_timeout_in_ticks(108000, restore_mining_speed_token)
            force.manual_mining_speed_modifier = force.manual_mining_speed_modifier + 1
            local message = ({ 'locomotive.mining_bonus', player.name })
            Alert.alert_all_players(15, message, nil, 'achievement/tech-maniac')
            Server.to_discord_bold(table.concat { '*** ', '[Mystical Chest] ' .. player.name .. ' has granted mining speed bonus for the whole team!', ' ***' })
            return true
        end),
        512
    },
    {
        name = 'Crafting speed bonus',
        str = 'crafting',
        color = { r = 0.00, g = 0.00, b = 0.25 },
        tooltip = 'Selecting this will grant all players 100% crafting bonus for 30 minutes!',
        func = (function (player)
            local mc_rewards = Public.get('mc_rewards')
            local force = game.forces.player
            if mc_rewards.temp_boosts.crafting then
                return false, '[Rewards] Crafting bonus is already applied. Please choose another reward.'
            end

            local mystical_rewards = Public.get('mystical_rewards')
            mystical_rewards.crafting_speed = mystical_rewards.crafting_speed and mystical_rewards.crafting_speed + 1 or 1

            mc_rewards.temp_boosts.crafting = true

            Task.set_timeout_in_ticks(108000, restore_crafting_speed_token)
            force.manual_crafting_speed_modifier = force.manual_crafting_speed_modifier + 2
            local message = ({ 'locomotive.crafting_bonus', player.name })
            Alert.alert_all_players(15, message, nil, 'achievement/tech-maniac')
            Server.to_discord_bold(table.concat { '*** ', '[Mystical Chest] ' .. player.name .. ' has granted crafting speed bonus for the whole team!', ' ***' })
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

    local frame = player.gui.screen.add { type = 'frame', caption = 'Mystical Reward:', name = 'reward_system', direction = 'vertical' }
    frame.auto_center = true
    frame = frame.add { type = 'frame', name = 'reward_system_1', direction = 'vertical', style = 'inside_shallow_frame' }
    frame.style.padding = 4

    local mc_rewards = Public.get('mc_rewards')
    mc_rewards.current = {}

    for i = 1, 3 do
        local d, key = get_random_weighted(mc_random_rewards)
        if not mc_rewards.current[key] and not mc_rewards.temp_boosts[d.str] then
            mc_rewards.current[key] =
            {
                id = i,
                name = d.name
            }
            local b = frame.add({ type = 'button', name = tostring(i), caption = d.name })
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
        return player.print('[Rewards] No rewards are available.', { color = Color.fail })
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

    local mystical_chest = Public.get('mystical_chest')
    if not (mystical_chest and mystical_chest.valid) then
        return
    end

    if entity.unit_number ~= mystical_chest.unit_number then
        return
    end

    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end

    if player.controller_type == defines.controllers.remote then
        return
    end

    if player.controller_type == defines.controllers.spectator then
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

    local mc_rewards = Public.get('mc_rewards')
    local current = mc_rewards.current

    local player = game.get_player(element.player_index)
    if not (player and player.valid) then
        return
    end

    for id, data in pairs(current) do
        if data.id == i then
            local locomotive = Public.get('locomotive')
            if not locomotive then
                return
            end
            if not locomotive.valid then
                return
            end
            local adjusted_zones = Public.get('adjusted_zones')
            local zone = floor((abs(locomotive.position.y / zone_settings.zone_depth)) % adjusted_zones.size) + 1
            local success, msg = mc_random_rewards[id].func(player, zone)
            if not success then
                return player.print(msg, { color = Color.fail })
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

    if not item_name then
        Server.output_script_data('No item name found for remaining budget: ' .. tostring(remaining_budget))
        Server.output_script_data('Item name: ' .. tostring(item_name))
        return
    end

    local stack_size = prototypes.item[item_name] and prototypes.item[item_name].stack_size and prototypes.item[item_name].stack_size * 32
    if not stack_size then
        Server.output_script_data('No stack size found for item name: ' .. tostring(item_name) .. ' with worth: ' .. tostring(item_worth))
        return
    end

    local item_count = 1

    for c = 1, random(1, stack_size), 1 do
        local price = c * item_worth
        if price <= remaining_budget then
            item_count = c
        else
            break
        end
    end

    return { name = item_name, count = item_count }
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
    local locomotive = Public.get('locomotive')
    if not locomotive then
        return
    end
    if not locomotive.valid then
        return
    end


    local mystical_chest_price = Public.get('mystical_chest_price')
    local mystical_chest = Public.get('mystical_chest')
    if not (mystical_chest and mystical_chest.valid) then
        return
    end

    if not mystical_chest_price then
        init_price_check(locomotive)
        mystical_chest_price = Public.get('mystical_chest_price')
    end

    local entity = mystical_chest

    local inventory = entity.get_inventory(defines.inventory.chest)

    for key, item_stack in pairs(mystical_chest_price) do
        local stack = { name = item_stack.value.name, count = item_stack.min }
        local count_removed = inventory.remove(stack)
        mystical_chest_price[key].min = mystical_chest_price[key].min - count_removed
        if mystical_chest_price[key].min <= 0 then
            table.remove(mystical_chest_price, key)
        end
    end

    if #mystical_chest_price == 0 then
        init_price_check(locomotive)
        if player and player.valid then
            mystical_chest_reward(player)
            local mystical_chest_completed = Public.get('mystical_chest_completed')
            Public.set('mystical_chest_completed', mystical_chest_completed + 1)
        end
        return true
    end

    if entity.get_requester_point() then
        entity.get_requester_point().remove_section(1)
        entity.get_requester_point().add_section()

        for slot, item_stack in pairs(mystical_chest_price) do
            entity.get_requester_point().get_section(1).set_slot(slot, item_stack)
        end
    end
end

function Public.get_active_boosts()
    local mc_rewards = Public.get('mc_rewards')
    return mc_rewards.active_boosts
end

function Public.get_temp_boosts()
    local mc_rewards = Public.get('mc_rewards')
    return mc_rewards.temp_boosts
end

function Public.is_active_boost(modifier)
    local mc_rewards = Public.get('mc_rewards')
    return mc_rewards.active_boosts[modifier]
end

Public.init_price_check = init_price_check
Public.mystical_chest_reward = mystical_chest_reward

Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_gui_closed, on_gui_closed)
Event.add(defines.events.on_gui_click, on_gui_click)


if _DEBUG then
    Commands.new('mtn_mystical_reward', 'Brings up the mystical chest reward system')
        :require_admin()
        :require_validation()
        :callback(
            function (player, _)
                if player and player.valid then
                    mystical_chest_reward(player)
                end
            end)
end

return Public
