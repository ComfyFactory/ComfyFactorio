--created by Gerkiz
local Event = require 'utils.event'
local simplex_noise = require 'utils.math.simplex_noise'.d2
local MapFunctions = require 'utils.tools.map_functions'
local Scheduler = require 'utils.scheduler'
local Public = require 'maps.infestation_islands.table'
local ParticleEffects = require 'modules.particle_effects'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Server = require 'utils.server'
local Poll = require 'utils.gui.poll'
local Color = require 'utils.color_presets'
local Config = require 'utils.gui.config'
local Core = require 'utils.core'

local random = math.random
local sqrt = math.sqrt
local abs = math.abs
local floor = math.floor
local min = math.min
local pi = math.pi
local cos = math.cos
local sin = math.sin
local rad = math.rad
local huge = math.huge
local pow = math.pow
local max = math.max

local function get_player_options(player)
    local player_options = Public.get('player_options')
    if not player_options[player.index] then
        player_options[player.index] =
        {
            ore_drop = true
        }
    end
    return player_options[player.index]
end

Config.register_scenario_module(
    {
        id = "infestation_islands",
        admin_only = false,
        gui_rows = Config.register_token(
            function (player, frame)
                local player_options = get_player_options(player)
                local switch_state = 'right'
                if player_options.ore_drop then
                    switch_state = 'left'
                end
                Config.add_switch(frame, switch_state, 'ore_drop', 'Ore Drop', 'Toggle to select if you want the ore to drop to ground or inserted into your inventory.')
                frame.add({ type = 'line' })
            end),
        handlers =
        {
            ore_drop = Config.register_token(
                function (player, event)
                    local player_options = get_player_options(player)
                    if event.element.switch_state == 'left' then
                        player_options.ore_drop = true
                        player.print('Ores will now get dropped to ground when an enemy is killed!', { color = Color.yellow })
                    else
                        player_options.ore_drop = false
                        player.print('Ores will now get inserted to your inventory when an enemy is killed!', { color = Color.yellow })
                    end
                end)
        }
    })

local function is_inside_island(x, y, radius)
    radius = radius or Public.island_radius_param
    local distance_to_center = sqrt(x ^ 2 + y ^ 2)
    return distance_to_center < radius
end

local function tile_placement(surface, position, name, tiles)
    local w_max = 256
    local h_max = 256

    local biases = { [0] = { [0] = 1 } }
    local ti = 1

    local function grow(grid, t)
        local old = {}
        local new_count = 0
        for x, _ in pairs(grid) do
            for y, _ in pairs(_) do
                table.insert(old, { x, y })
            end
        end
        for _, pos in pairs(old) do
            local x, y = pos[1], pos[2]
            for dx = -1, 1, 1 do
                for dy = -1, 1, 1 do
                    local a, b = x + dx, y + dy
                    if (random() > 0.9) and (abs(a) < w_max) and (abs(b) < h_max) then
                        grid[a] = grid[a] or {}
                        if not grid[a][b] then
                            grid[a][b] = 1 - (t / tiles)
                            new_count = new_count + 1
                            if (new_count + t) == tiles then
                                return new_count
                            end
                        end
                    end
                end
            end
        end
        return new_count
    end

    repeat
        ti = ti + grow(biases, ti)
    until ti >= tiles

    local total_bias = 0
    for _, d in pairs(biases) do
        for _, bias in pairs(d) do
            total_bias = total_bias + bias
        end
    end

    for x, _ in pairs(biases) do
        for y, _ in pairs(_) do
            surface.set_tiles({ { name = name, position = { position.x + x, position.y + y } } }, true)
        end
    end
end

local function island_noise(p, divided_by)
    local this = Public.get()
    local seeds = this.seeds
    local noise_1 = simplex_noise(p.x * seeds.seed_m1, p.y * seeds.seed_m1, seeds.seed_1)
    local noise_2 = simplex_noise(p.x * seeds.seed_m2, p.y * seeds.seed_m2, seeds.seed_2)
    local noise_3 = simplex_noise(p.x * seeds.seed_m3, p.y * seeds.seed_m3, seeds.seed_3)
    local noise = abs(noise_1 + noise_2 + noise_3)
    divided_by = divided_by or 2.3
    noise = noise / divided_by
    return noise
end

local function connected_ground_size(surface, start, max_radius, max_count)
    local start_x, start_y = floor(start.x), floor(start.y)
    local queue, head = { { x = start_x, y = start_y } }, 1
    local visited = {}
    local count = 0
    local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

    local function key(x, y) return x .. "," .. y end

    while head <= #queue and count < max_count do
        local p = queue[head]; head = head + 1
        local k = key(p.x, p.y)
        if not visited[k] then
            visited[k] = true
            local t = surface.get_tile(p)
            if t and t.valid and not t.collides_with("water_tile") then
                count = count + 1
                for i = 1, 4 do
                    local nx, ny = p.x + dirs[i][1], p.y + dirs[i][2]
                    if abs(nx - start_x) <= max_radius and abs(ny - start_y) <= max_radius then
                        table.insert(queue, { x = nx, y = ny })
                    end
                end
            end
        end
    end
    return count
end


local function get_quality_for_stage(current_level, last_level)
    local level = current_level or 1
    local normalized = min(level / last_level, 1.0)
    local tier = floor(normalized * 50 + 0.5)
    local t = Public.quality_per_level[tier].thresholds

    local r = random()
    if r < t[1] then
        return "normal"
    elseif r < t[2] then
        return "uncommon"
    elseif r < t[3] then
        return "rare"
    elseif r < t[4] then
        return "epic"
    else
        return "legendary"
    end
end

local function roll_biter(level)
    local choices
    if not level or level <= 1 then
        choices = { 'small-biter', 'small-spitter' }
    elseif level <= 2 then
        choices = { 'small-biter', 'medium-biter', 'small-wriggler-pentapod', 'small-spitter', 'medium-spitter' }
    elseif level <= 5 then
        choices = { 'small-wriggler-pentapod', 'medium-biter', 'medium-wriggler-pentapod', 'small-spitter', 'medium-spitter' }
    elseif level <= 6 then
        choices = { 'medium-biter', 'big-biter', 'medium-wriggler-pentapod', 'small-strafer-pentapod', 'medium-spitter', 'big-spitter' }
    elseif level < 8 then
        choices = { 'big-biter', 'small-wriggler-pentapod', 'medium-wriggler-pentapod', 'big-biter', 'big-wriggler-pentapod', 'small-strafer-pentapod', 'medium-strafer-pentapod', 'big-spitter' }
    else
        choices = { 'big-biter', 'big-wriggler-pentapod', 'behemoth-biter', 'medium-wriggler-pentapod', 'big-strafer-pentapod', 'big-strafer-pentapod', 'medium-spitter', 'big-spitter', 'behemoth-spitter' }
    end
    return choices[random(1, #choices)]
end

local function create_units_and_command(unit_count, market, surface, position, current_level)
    local commands = {}
    commands[#commands + 1] =
    {
        type = defines.command.attack_area,
        destination = { x = market.position.x, y = market.position.y },
        radius = 125,
        distraction = defines.distraction.by_anything
    }

    local unit_group = surface.create_unit_group({ position = position, force = 'enemy' }) --[[@as LuaCommandable]]

    for _ = 1, unit_count do
        local p = surface.find_non_colliding_position('wooden-chest', position, 128, 4)
        if p then
            local biter = surface.create_entity({ name = roll_biter(current_level), position = p, force = 'enemy' })
            if biter and biter.valid then
                if unit_group and unit_group.valid then
                    unit_group.add_member(biter)
                end
            end
        end
    end

    if not unit_group or not unit_group.valid then
        return
    end

    unit_group.set_command(
        {
            type = defines.command.compound,
            structure_type = defines.compound_command.return_last,
            commands = commands
        }
    )
end

local function is_valid_position(all_islands, current_radius, x, y)
    for _, island in pairs(all_islands) do
        local dx = island.position.x - x
        local dy = island.position.y - y
        local dist = sqrt(dx * dx + dy * dy)
        local min_dist = (island.radius) + current_radius
        if dist < min_dist then
            return false
        end
    end
    return true
end


local function get_ore_count(level)
    return random(level, level + 1)
end

local function reward_items(loot, surface, position)
    local amount = loot.count
    if amount > 0 then
        if amount >= 50 then
            for _ = 1, floor(amount / 50), 1 do
                local e = surface.create_entity { name = 'item-on-ground', position = position, stack = { name = loot.name, quality = loot.quality, count = 50 } }
                if e and e.valid then
                    e.to_be_looted = false
                    e.order_deconstruction('player')
                end
                amount = amount - 50
            end
        end
        if amount > 0 then
            local e = surface.create_entity { name = 'item-on-ground', position = position, stack = { name = loot.name, quality = loot.quality, count = amount } }
            if e and e.valid then
                e.to_be_looted = false
                e.order_deconstruction('player')
            end
        end
    end
end

local function on_entity_died(event)
    local entity = event.entity
    local this = Public.get()
    local cause = event.cause
    if entity.name == 'market' then
        local island_data = this.islands_data[entity.unit_number]
        if island_data then
            island_data.market = nil
            island_data.no_rerolls = true
            if this.game_over_if_market_dies then
                this.fallen_market = { level = island_data.level, position = island_data.position }
                this.top_label_caption_override = 'The market was overrun by hungry biters at level ' .. island_data.level .. '!'
            else
                island_data.captured = false
                Public.delayed_message(10, Public.island_keeper .. 'The market at level ' .. island_data.level .. ' was overrun by hungry biters!')
                game.print('[gps=' .. island_data.market_position.x .. ',' .. island_data.market_position.y .. ',' .. game.surfaces[1].name .. ']')
                if island_data.render_protect_text then
                    island_data.render_protect_text.destroy()
                    island_data.render_protect_text = nil
                end
                if island_data.render_checkpoint_text then
                    island_data.render_checkpoint_text.destroy()
                    island_data.render_checkpoint_text = nil
                end
                this.market_prices[entity.unit_number] = nil
                this.islands_data[entity.unit_number] = nil

                -- Create biters and revive the market if this is not the last market standing
                if not Public.has_any_islands_been_captured() then
                    Public.delayed_message(100, Public.island_keeper .. 'The last market has been chewed up by the biters - GG!')
                    Server.to_discord_embed('** The last market has been chewed up by the biters! **')
                    this.top_label_caption_override = 'The market was overrun by hungry biters at level ' .. island_data.level .. '!'
                    for _, market_data in pairs(this.islands_data) do
                        if market_data and market_data.market and market_data.market.valid then
                            if market_data.render_protect_text then
                                market_data.render_protect_text.destroy()
                                market_data.render_protect_text = nil
                            end
                            if market_data.render_checkpoint_text then
                                market_data.render_checkpoint_text.destroy()
                                market_data.render_checkpoint_text = nil
                            end
                            market_data.market.destroy()
                            market_data.market = nil
                        end
                    end
                else
                    Public.delayed_message(200, Public.island_keeper .. Public.overrun_messages[random(1, #Public.overrun_messages)])
                    Scheduler.new(800, Public.do_place_enemies_token)
                        :set_data({ surface = game.surfaces[1], position = island_data.position, radius = island_data.radius })
                        :new_child(100, Public.do_revive_market_token):set_data({ surface = game.surfaces[1], position = island_data.market_position, level = island_data.level })
                    return
                end
            end
        end


        for _, player in pairs(game.connected_players) do
            player.play_sound { path = 'utility/game_lost', volume_modifier = 1 }
        end
        this.game_reset_tick = 5400
        this.game_lost = true
        Public.delayed_message(10, Public.island_keeper .. 'The market was overrun by hungry biters!')
        Server.to_discord_embed('** The market was overrun by hungry biters! **')
        return
    end
    if entity and entity.valid and entity.force.name == 'enemy' and entity.type == 'unit' then
        local premature = false
        local drop_to_ground = true
        local player
        local surface = entity.surface

        if string.find(entity.name, 'premature') then
            premature = true
            if random(1, 10) ~= 1 then return end
        end

        if cause and cause.valid then
            if string.find(cause.name, 'premature') then
                premature = true
                if random(1, 10) ~= 1 then return end
            end

            if cause.name == 'character' and cause.player then
                local player_options = get_player_options(cause.player)
                if player_options then
                    drop_to_ground = player_options.ore_drop
                end
                player = cause.player
            end
        end

        local ore_drop_1 = Public.harvest_raffle_ores[random(1, Public.size_of_ore_raffle)]
        local ore_drop_2 = Public.harvest_raffle_ores[random(1, Public.size_of_ore_raffle)]

        local quality_1 = get_quality_for_stage(this.current_level, this.last_level)
        local quality_2 = get_quality_for_stage(this.current_level, this.last_level)

        if ore_drop_1 == "calcite" then quality_1 = "normal" end
        if ore_drop_2 == "calcite" then quality_2 = "normal" end

        if premature then
            quality_1 = "normal"
            quality_2 = "normal"
        end

        local coin_drop = { name = 'coin', count = random(1, 2), quality = 'normal' }
        local ore_1_drop = { name = ore_drop_1, count = get_ore_count(this.current_level), quality = quality_1 }
        local ore_2_drop = { name = ore_drop_2, count = get_ore_count(this.current_level), quality = quality_2 }

        if drop_to_ground then
            reward_items(coin_drop, surface, entity.position)
            reward_items(ore_1_drop, surface, entity.position)
            reward_items(ore_2_drop, surface, entity.position)
        elseif player and player.valid and player.can_insert(coin_drop) then
            player.insert(coin_drop)
            player.insert(ore_1_drop)
            player.insert(ore_2_drop)
        end
    end
end

local function on_market_item_purchased(event)
    local entity = event.market
    if not entity or not entity.valid then
        return
    end

    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end
    local this = Public.get()

    if this.game_lost or this.game_won then
        return
    end

    local offer_index = event.offer_index
    local offers = entity.get_market_items()
    local bought_offer = offers[offer_index].offer
    if bought_offer.type ~= 'nothing' then
        return
    end

    local market_prices = this.market_prices[entity.unit_number]
    if not market_prices then
        return
    end

    if string.find(bought_offer.effect_description, 'onwards') then
        Public.advance_to_next_island(entity, player, offer_index)
    elseif string.find(bought_offer.effect_description, 'Capture') then
        Public.capture_island(entity, player, market_prices, offer_index)
    elseif string.find(bought_offer.effect_description, 'more ammo') then
        Public.upgrade_ammo_count_at_market(entity, player, market_prices, offer_index)
    elseif string.find(bought_offer.effect_description, 'piercing') then
        Public.upgrade_piercing_ammo_at_market(entity, player, market_prices, offer_index)
    elseif string.find(bought_offer.effect_description, 'uranium') then
        Public.upgrade_uranium_ammo_at_market(entity, player, market_prices, offer_index)
    elseif string.find(bought_offer.effect_description, 'reroll') then
        Public.upgrade_market_rerolls_at_market(entity, player, offer_index)
    elseif string.find(bought_offer.effect_description, 'Grants') then
        Public.purchase_special_force_modifiers(entity, player, offer_index)
    elseif string.find(bought_offer.effect_description, 'bridge') then
        Public.generate_bridge_to_next_island(entity, player, market_prices, offer_index)
    end

    if not entity.get_market_items() then
        local island_data = this.islands_data[entity.unit_number]
        if island_data and island_data.no_rerolls then
            entity.operable = false
            return
        end

        Public.island_market(entity, (this.current_level * random(1, 3)) * 4)
        game.print(Public.island_keeper .. 'The market at level ' .. this.current_level - 1 .. ' has been refilled by ' .. player.name .. '!')
        Server.to_discord_embed('** The market at level ' .. this.current_level - 1 .. ' has been refilled by ' .. player.name .. '! **')
    end
end

local on_player_or_robot_built_tile = function (event)
    local surface = game.surfaces[event.surface_index]

    local tiles = event.tiles
    if not tiles then
        return
    end

    for _, v in pairs(tiles) do
        local old_tile = v.old_tile
        if old_tile.name == 'water' then
            surface.set_tiles({ { name = 'water', position = v.position } }, true)
        end
        if old_tile.name == 'water-mud' then
            surface.set_tiles({ { name = 'water-mud', position = v.position } }, true)
        end
    end
end

function Public.is_rocket_silo_alive()
    local this = Public.get()
    if not this.initial_rocket_silo_created then
        return false
    end
    if this.current_level < 4 then return end
    if this.rocket_silo and this.rocket_silo.valid then
        return true
    end

    Scheduler.new(1, Public.create_rocket_silo_token)
        :set_data({ surface = game.surfaces[1], center_position = this.islands_data[4] })
    -- :run_task()

    return true
end

function Public.delayed_message(tick, message)
    local this = Public.get()
    this.delayed_messages[game.tick + tick] = message
end

function Public.set_islands_data()
    local this = Public.get()
    local position = this.next_island_position


    local radius = this.stages[this.current_level].size

    if this.last_level < 11 and this.current_level == this.last_level then
        radius = Public.max_island_radius_param
    end

    local level_data =
    {
        position = position,
        level = this.current_level,
        radius = radius
    }

    if not next(level_data.position) then
        error('No position found for level ' .. this.current_level)
    end

    this.islands_data[this.current_level] = level_data

    return this.islands_data[this.current_level]
end

function Public.shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

function Public.resource_placement(surface, position, name, amount, tiles, level)
    local w_max = 256
    local h_max = 256

    local biases = { [0] = { [0] = 1 } }
    local ti = 1

    local function grow(grid, t)
        local old = {}
        local new_count = 0
        for x, _ in pairs(grid) do
            for y, _ in pairs(_) do
                table.insert(old, { x, y })
            end
        end
        for _, pos in pairs(old) do
            local x, y = pos[1], pos[2]
            for dx = -1, 1, 1 do
                for dy = -1, 1, 1 do
                    local a, b = x + dx, y + dy
                    if (random() > 0.9) and (abs(a) < w_max) and (abs(b) < h_max) then
                        grid[a] = grid[a] or {}
                        if not grid[a][b] then
                            grid[a][b] = 1 - (t / tiles)
                            new_count = new_count + 1
                            if (new_count + t) == tiles then
                                return new_count
                            end
                        end
                    end
                end
            end
        end
        return new_count
    end

    repeat
        ti = ti + grow(biases, ti)
    until ti >= tiles

    local total_bias = 0
    for _, d in pairs(biases) do
        for _, bias in pairs(d) do
            total_bias = total_bias + bias
        end
    end

    local skip_tiles = false
    if level == 1 then
        skip_tiles = true
    end

    for x, _ in pairs(biases) do
        for y, bias in pairs(_) do
            local c = amount * (bias / total_bias)
            if c < 1 then
                c = 1
            end
            if not skip_tiles then
                surface.set_tiles({ { name = 'volcanic-jagged-ground', position = { position.x + x, position.y + y } } }, true)
            end
            surface.create_entity
            {
                name = name,
                amount = c,
                force = 'neutral',
                position = { position.x + x, position.y + y }
            }
        end
    end
end

function Public.reward_level(surface, level)
    local radius = level.radius
    local ore = Public.raw_ores[random(1, #Public.raw_ores)]
    local oil = Public.oil_raffle[random(1, #Public.oil_raffle)]
    local offset_oil_position = { x = level.position.x - random(10, 20), y = level.position.y - random(10, 20) }
    Public.delayed_message(1, Public.island_keeper .. 'A reward has been given for clearing the island at level ' .. level.level .. '!')
    MapFunctions.draw_oil_circle(offset_oil_position, oil, surface, 8, 50000)
    Public.resource_placement(surface, level.position, ore, random(75000, 75000 * 3), radius * 3, level.level)

    if level.level > 1 then
        local position = { x = level.position.x + random(10, 20), y = level.position.y + random(10, 20) }
        tile_placement(surface, position, Public.plantable_soil[random(1, #Public.plantable_soil)], radius * 2)
    end
end

function Public.upgrade_ammo_count_at_market(entity, player, market_prices, offer_index)
    local this = Public.get()
    local price = market_prices['ammo'] or 500
    local inventory = player.get_main_inventory()
    if not inventory then
        return
    end
    local count = inventory.get_item_count({ name = 'coin' })
    if count and count < price then
        player.print('You do not have enough coins to purchase this offer!', { color = Color.warning })
        return
    elseif not count then
        return
    end
    if this.infinite_ammo_grants > 10 then
        player.print('You have reached the maximum number of infinite ammo grants!', { color = Color.warning })
        return
    end
    inventory.remove({ name = 'coin', count = price })
    this.infinite_ammo_grants = this.infinite_ammo_grants + 1
    game.print(Public.island_keeper .. 'Infinite ammo now grants more ammo thanks to ' .. player.name .. '!')
    Server.to_discord_embed('** Infinite ammo now grants more ammo thanks to ' .. player.name .. '! **')
    entity.remove_market_item(offer_index)
end

function Public.upgrade_piercing_ammo_at_market(entity, player, market_prices, offer_index)
    local this = Public.get()
    local price = market_prices['piercing'] or 1000
    if this.piercing_ammo_grants then
        entity.remove_market_item(offer_index)
        return player.print('You already have piercing rounds ammo!', { color = Color.warning })
    end
    local inventory = player.get_main_inventory()
    if not inventory then
        return
    end
    local count = inventory.get_item_count({ name = 'coin' })
    if count and count < price then
        player.print('You do not have enough coins to purchase this offer!', { color = Color.warning })
        return
    elseif not count then
        return
    end
    inventory.remove({ name = 'coin', count = price })
    this.piercing_ammo_grants = true
    Public.delayed_message(1, Public.island_keeper .. 'Infinite ammo now grants piercing rounds ammo thanks to ' .. player.name .. '!')
    Server.to_discord_embed('** Infinite ammo now grants piercing rounds ammo thanks to ' .. player.name .. '! **')
    entity.remove_market_item(offer_index)
end

function Public.upgrade_uranium_ammo_at_market(entity, player, market_prices, offer_index)
    local this = Public.get()
    local price = market_prices['uranium'] or 1000
    if this.uranium_ammo_grants then
        entity.remove_market_item(offer_index)
        return player.print('You already have uranium rounds ammo!', { color = Color.warning })
    end
    local inventory = player.get_main_inventory()
    if not inventory then
        return
    end
    local count = inventory.get_item_count({ name = 'coin' })
    if count and count < price then
        player.print('You do not have enough coins to purchase this offer!', { color = Color.warning })
        return
    elseif not count then
        return
    end
    inventory.remove({ name = 'coin', count = price })
    this.uranium_ammo_grants = true
    Public.delayed_message(1, Public.island_keeper .. 'Infinite ammo now grants uranium rounds ammo thanks to ' .. player.name .. '!')
    Server.to_discord_embed('** Infinite ammo now grants uranium rounds ammo thanks to ' .. player.name .. '! **')
    entity.remove_market_item(offer_index)
end

function Public.upgrade_market_rerolls_at_market(entity, player, offer_index)
    local this = Public.get()
    local market_rerolls = Public.get('market_rerolls')
    if not market_rerolls[entity.unit_number] then
        return
    end
    local market_level = this.islands_data[entity.unit_number] and this.islands_data[entity.unit_number].level or nil
    if not market_level then
        error('No market level found for unit number ' .. entity.unit_number)
    end

    local inventory = player.get_main_inventory()
    if not inventory then
        return
    end
    local count = inventory.get_item_count({ name = 'coin' })
    local price = market_rerolls[entity.unit_number].price
    if count and count < price then
        player.print('You do not have enough coins to purchase this offer!', { color = Color.warning })
        return
    elseif not count then
        return
    end
    inventory.remove({ name = 'coin', count = price })

    market_rerolls[entity.unit_number].rerolls = market_rerolls[entity.unit_number].rerolls - 1
    if market_rerolls[entity.unit_number].rerolls < 0 then
        market_rerolls[entity.unit_number].rerolls = 0
    end
    market_rerolls[entity.unit_number].price = market_rerolls[entity.unit_number].price + 250

    entity.remove_market_item(offer_index)
    Public.island_market(entity, (market_level * random(1, 3)) * 4, false, true)
    if market_rerolls[entity.unit_number].rerolls == 0 then
        Public.delayed_message(1, Public.island_keeper .. 'The market at level ' .. market_level .. ' has been re-rolled one last time by ' .. player.name .. '!')
        Server.to_discord_embed('** The market at level ' .. market_level .. ' has been re-rolled one last time by ' .. player.name .. '! **')
    else
        Public.delayed_message(1, Public.island_keeper .. 'The market at level ' .. market_level .. ' has been re-rolled by ' .. player.name .. '!')
        Server.to_discord_embed('** The market at level ' .. market_level .. ' has been re-rolled by ' .. player.name .. '! **')
    end
end

function Public.purchase_special_force_modifiers(entity, player, offer_index)
    local market_rerolls = Public.get('market_rerolls')
    if not market_rerolls[entity.unit_number] then
        return
    end
    local inventory = player.get_main_inventory()
    if not inventory then
        return
    end
    local count = inventory.get_item_count({ name = 'coin' })
    local price = market_rerolls[entity.unit_number].modifier_price
    if count and count < price then
        player.print('You do not have enough coins to purchase this offer!', { color = Color.warning })
        return
    elseif not count then
        return
    end
    inventory.remove({ name = 'coin', count = price })

    game.forces.player[market_rerolls[entity.unit_number].modifier] = game.forces.player[market_rerolls[entity.unit_number].modifier] + market_rerolls[entity.unit_number].modifier_value

    entity.remove_market_item(offer_index)
    game.print(Public.island_keeper .. player.name .. ' has granted the whole team ' .. market_rerolls[entity.unit_number].modifier_name .. '!')
    Server.to_discord_embed('** ' .. player.name .. ' has granted the whole team ' .. market_rerolls[entity.unit_number].modifier_name .. '! **')
    Server.output_script_data('** ' .. player.name .. ' has granted the whole team ' .. market_rerolls[entity.unit_number].modifier_name .. '! **')
end

function Public.generate_bridge_to_next_island(entity, player, market_prices, offer_index)
    local this = Public.get()
    local count = entity.surface.count_entities_filtered({ force = 'enemy', type = { 'unit', 'turret', 'unit-spawner', 'spider-unit' }, area = { { entity.position.x - 16, entity.position.y - 16 }, { entity.position.x + 16, entity.position.y + 16 } } })
    if count > 0 then
        player.print('You must kill all enemies at island ' .. market_prices.level .. ' before you can buy this offer')
        return
    end

    if this.voting_to_progress_enabled then
        local can_progress = false
        if this.islands_voting[this.current_level] and this.islands_voting[this.current_level].id and Poll.poll_complete(this.islands_voting[this.current_level].id) then
            local _, winning_answer = Poll.poll_result(this.islands_voting[this.current_level].id)
            if winning_answer and winning_answer.text == 'Progress!' then
                can_progress = true
            end

            if not can_progress and not this.islands_voting[this.current_level].timeout_until_next_vote then
                this.islands_voting[this.current_level].timeout_until_next_vote = game.tick + 18000
            end
            if not this.islands_voting[this.current_level].completed then
                this.islands_voting[this.current_level].completed = true
            end
        end

        if this.islands_voting[this.current_level] and not this.islands_voting[this.current_level].completed then
            return player.print('There is already a poll ongoing regarding the islands advancement!', { color = Color.warning })
        end

        if not this.islands_voting[this.current_level] or (this.islands_voting[this.current_level] and this.islands_voting[this.current_level].timeout_until_next_vote and game.tick >= this.islands_voting[this.current_level].timeout_until_next_vote) then
            this.islands_voting[this.current_level] = { id = nil, completed = false, timeout_until_next_vote = nil }

            local _, id = Poll.poll(
                {
                    question = player.name .. ' wants to advance to island ' .. this.current_level + 1,
                    answers = { 'Progress!', 'No, we are not ready!' },
                    duration = 300,
                })
            this.islands_voting[this.current_level].id = id
            return
        end

        if not can_progress and game.tick < this.islands_voting[this.current_level].timeout_until_next_vote then
            player.print('The team has decided to not progress yet to the next island!', { color = Color.warning })
            player.print('The next vote will be available in ' .. floor((this.islands_voting[this.current_level].timeout_until_next_vote - game.tick) / 60) .. ' seconds!', { color = Color.warning })
            return
        end
    end

    -- clear the timer, the players want to proceed
    this.time_until_next_island_is_created = nil
    this.time_until_next_island_is_created_static = nil

    entity.remove_market_item(offer_index)
    this.position = entity.position
    if this.islands_data[entity.unit_number] then
        this.islands_data[entity.unit_number].captured = true
    end

    local market = this.islands_data[entity.unit_number] and this.islands_data[entity.unit_number].market or nil
    if not market then error('No market found for unit number ' .. entity.unit_number .. ' and level ' .. this.current_level) end

    if market and market.valid then
        market.destructible = true
    end

    this.islands_data[this.current_level].auto_generated_bridge = nil

    Public.delayed_message(10, Public.island_keeper .. player.name .. ' has generated a bridge to level ' .. this.current_level .. '!')
    Public.delayed_message(100, Public.island_keeper .. Public.spooky_lines[random(1, #Public.spooky_lines)])
    Server.to_discord_embed('** ' .. player.name .. ' has generated a bridge to level ' .. this.current_level .. '! **')

    Scheduler.new(1, Public.do_generate_bridge_token):set_data({ surface = game.surfaces[1], reroll_enabled = true })
end

function Public.advance_to_next_island(entity, player, offer_index)
    local this = Public.get()
    if this.alive_enemies > 0 then
        player.print('You must kill all enemies before you can buy this offer')
        return
    end
    if not Difficulty.has_votes_ended() then
        return player.print('The difficulty vote has not ended yet!', { color = Color.warning })
    end
    if this.game_won then
        return
    end
    if this.voting_to_progress_enabled then
        local can_progress = false
        if this.islands_voting[this.current_level] and this.islands_voting[this.current_level].id and Poll.poll_complete(this.islands_voting[this.current_level].id) then
            local _, winning_answer = Poll.poll_result(this.islands_voting[this.current_level].id)
            if winning_answer and winning_answer.text == 'Progress!' then
                can_progress = true
            end

            if not can_progress and not this.islands_voting[this.current_level].timeout_until_next_vote then
                this.islands_voting[this.current_level].timeout_until_next_vote = game.tick + 18000
            end
            if not this.islands_voting[this.current_level].completed then
                this.islands_voting[this.current_level].completed = true
            end
        end

        if this.islands_voting[this.current_level] and not this.islands_voting[this.current_level].completed then
            return player.print('There is already a poll ongoing regarding the islands advancement!', { color = Color.warning })
        end

        if not this.islands_voting[this.current_level] or (this.islands_voting[this.current_level] and this.islands_voting[this.current_level].timeout_until_next_vote and game.tick >= this.islands_voting[this.current_level].timeout_until_next_vote) then
            this.islands_voting[this.current_level] = { id = nil, completed = false, timeout_until_next_vote = nil }

            local _, id = Poll.poll(
                {
                    question = player.name .. ' wants to advance to island ' .. this.current_level + 1,
                    answers = { 'Progress!', 'No, we are not ready!' },
                    duration = 300,
                })
            this.islands_voting[this.current_level].id = id
            return
        end

        if not can_progress and game.tick < this.islands_voting[this.current_level].timeout_until_next_vote then
            player.print('The team has decided to not progress yet to the next island!', { color = Color.warning })
            player.print('The next vote will be available in ' .. floor((this.islands_voting[this.current_level].timeout_until_next_vote - game.tick) / 60) .. ' seconds!', { color = Color.warning })
            return
        end
    end

    entity.remove_market_item(offer_index)
    this.position = entity.position
    if this.islands_data[entity.unit_number] then
        this.islands_data[entity.unit_number].captured = true
    end

    local surface = entity.surface

    local market = this.islands_data[entity.unit_number] and this.islands_data[entity.unit_number].market or nil
    if not market then error('No market found for unit number ' .. entity.unit_number .. ' and level ' .. this.current_level) end

    if market and market.valid then
        market.destructible = true
    end

    if this.current_level == 4 then
        Scheduler.new(1, Public.create_rocket_silo_token)
            :set_data({ surface = surface, center_position = this.islands_data[4] })
    end

    this.current_level = this.current_level + 1

    -- clear the timer, the players want to proceed
    this.time_until_next_island_is_created_static = nil
    this.time_until_next_island_is_created = nil

    Public.delayed_message(10, Public.island_keeper .. player.name .. ' has advanced to level ' .. this.current_level)
    Public.delayed_message(100, Public.island_keeper .. Public.spooky_lines[random(1, #Public.spooky_lines)])
    Server.to_discord_embed('** ' .. player.name .. ' has advanced to level ' .. this.current_level .. ' **')

    this.alive_enemies = 0


    local loot_found = 0
    for _ = 1, random(1, 3), 1 do
        local treasure_position = surface.find_non_colliding_position('stone-furnace', market.position, 32, 1)

        if treasure_position then
            if random(1, 2) == 1 then
                loot_found = loot_found + 1
                Public.add_loot(surface, treasure_position, 'iron-chest', true)
                ParticleEffects.particle_effects(surface, treasure_position, 80)
            elseif random(1, 20) == 1 then
                loot_found = loot_found + 1
                Public.add_loot(surface, treasure_position, 'steel-chest', true)
                ParticleEffects.particle_effects(surface, treasure_position, 80)
            elseif random(1, 40) == 1 then
                loot_found = loot_found + 1
                Public.add_loot_rare(surface, treasure_position, 'crash-site-chest-1', random(1, 1024))
                ParticleEffects.particle_effects(surface, treasure_position, 120)
            end
        end
    end

    if loot_found == 1 then
        Public.delayed_message(30, Public.island_keeper .. 'A magical chest has appeared near the market!')
    elseif loot_found > 1 then
        Public.delayed_message(30, Public.island_keeper .. 'Magical chests have appeared near the market!')
    end

    this.attack_grace_period = game.tick + 54000

    this.cooldown_complete_level = game.tick + (60 * 60)

    this.alive_enemies = 999

    Scheduler.new(1, Public.init_next_island_token)
        :set_data({ surface = entity.surface, position = this.position })
end

function Public.capture_island(entity, player, market_prices, offer_index)
    local count = entity.surface.count_entities_filtered({ force = 'enemy', type = { 'unit', 'turret', 'unit-spawner', 'spider-unit' }, area = { { entity.position.x - 16, entity.position.y - 16 }, { entity.position.x + 16, entity.position.y + 16 } } })
    if count > 0 then
        player.print('You must kill all enemies at island ' .. market_prices.level .. ' before you can buy this offer')
        return
    end

    local this = Public.get()

    if this.game_won then
        return
    end

    entity.remove_market_item(offer_index)

    local surface = entity.surface

    local market = this.islands_data[entity.unit_number] and this.islands_data[entity.unit_number].market or nil
    if not market then error('No market found for unit number ' .. entity.unit_number .. ' and level ' .. market_prices.level) end

    if market and market.valid then
        market.destructible = true
    end

    if market_prices.level == 4 then
        Scheduler.new(1, Public.create_rocket_silo_token)
            :set_data({ surface = surface, center_position = this.islands_data[4] })
    end

    Public.reward_level(surface, this.islands_data[market_prices.level])

    entity.destructible = true

    Public.delayed_message(10, Public.island_keeper .. player.name .. ' has captured island ' .. market_prices.level)
    Server.to_discord_embed('** ' .. player.name .. ' has captured island ' .. market_prices.level .. ' **')


    local loot_found = 0
    for _ = 1, random(1, 3), 1 do
        local treasure_position = surface.find_non_colliding_position('stone-furnace', market.position, 32, 1)

        if treasure_position then
            if random(1, 2) == 1 then
                loot_found = loot_found + 1
                Public.add_loot(surface, treasure_position, 'iron-chest', true)
                ParticleEffects.particle_effects(surface, treasure_position, 80)
            elseif random(1, 20) == 1 then
                loot_found = loot_found + 1
                Public.add_loot(surface, treasure_position, 'steel-chest', true)
                ParticleEffects.particle_effects(surface, treasure_position, 80)
            elseif random(1, 40) == 1 then
                loot_found = loot_found + 1
                Public.add_loot_rare(surface, treasure_position, 'crash-site-chest-1', random(1, 1024))
                ParticleEffects.particle_effects(surface, treasure_position, 120)
            end
        end
    end

    if this.islands_data[entity.unit_number] then
        this.islands_data[entity.unit_number].captured = true
    end

    if loot_found == 1 then
        Public.delayed_message(30, Public.island_keeper .. 'A magical chest has appeared near the market!')
    elseif loot_found > 1 then
        Public.delayed_message(30, Public.island_keeper .. 'Magical chests have appeared near the market!')
    end
end

function Public.find_dirt_tile(surface, position)
    local this = Public.get()
    local min_island_tiles = 1500
    local check_radius = 64

    for r = 1, 64 do
        local vectors = { { r, 0 }, { -r, 0 }, { 0, r }, { 0, -r } }
        if this.current_level == 1 then vectors = Public.shuffle(vectors) end

        for _, v in ipairs(vectors) do
            local pos = { x = position.x + v[1], y = position.y + v[2] }
            local tile = surface.get_tile(pos)
            if tile and tile.valid and not tile.collides_with("water_tile") then
                if connected_ground_size(surface, pos, check_radius, min_island_tiles) >= min_island_tiles then
                    return tile.position
                end
            end
        end
    end
end

function Public.has_any_islands_been_captured()
    local islands_data = Public.get('islands_data')
    for _, island_data in pairs(islands_data) do
        if island_data and island_data.captured then
            return true
        end
    end
    return false
end

function Public.do_buried_biters()
    local current_level = Public.get('current_level')
    local islands_data = Public.get('islands_data')
    local center_position = islands_data[current_level]
    if not center_position then
        return
    end
    if current_level > 2 then
        local count = random(4, 10)
        local position = Public.get_random_position(center_position.position, 40)
        if random(1, 10) == 1 then
            Public.buried_biter(game.surfaces[1], position, count, 'enemy', Public.qualities[random(1, #Public.qualities)])
        elseif random(1, 15) == 1 then
            Public.buried_worm(game.surfaces[1], position, Public.qualities[random(1, #Public.qualities)])
        elseif random(1, 60) == 1 then
            Public.buried_spawner(game.surfaces[1], position, 1, 'enemy')
        end
    end
end

--- Not in used
function Public.do_buried_biters_on_completed_levels()
    local current_level = Public.get('current_level')
    local islands_data = Public.get('islands_data')
    local center_position = islands_data[current_level]
    if not center_position then
        return
    end

    local surface = game.surfaces[1]
    if surface.daytime < 0.35 then
        return
    end
    if surface.daytime > 0.65 then
        return
    end

    local difficulty_index = Difficulty.get('index')
    local base_min, base_max
    if difficulty_index == 1 then
        base_min, base_max = 16, 32
    elseif difficulty_index == 2 then
        base_min, base_max = 32, 64
    else
        base_min, base_max = 64, 128
    end

    local count = random(base_min, base_max)

    if current_level > 2 then
        local position = Public.get_random_position(center_position.position, 40)
        if random(1, 10) == 1 then
            Public.buried_biter(surface, position, count, 'enemy', Public.qualities[random(1, #Public.qualities)])
        elseif random(1, 15) == 1 then
            Public.buried_worm(surface, position, Public.qualities[random(1, #Public.qualities)])
        elseif random(1, 60) == 1 then
            Public.buried_spawner(surface, position, 1, 'enemy')
        end
    end
end

function Public.normalize_time_until_next_island_is_created()
    local this = Public.get()
    if not this.time_until_next_island_is_created then
        return 'unknown time', 9999
    end

    local raw = math.round((this.time_until_next_island_is_created - game.tick) / 60 / 60, 0)
    local raw_half = math.round(raw / 2, 0)

    local half = raw_half .. ' minutes'
    local time = raw .. ' minutes'

    if raw == 0 then
        half = math.round((this.time_until_next_island_is_created - game.tick) / 60, 0) .. ' seconds'
        time = math.round((this.time_until_next_island_is_created - game.tick) / 60, 0) .. ' seconds'
    end

    return time, raw, half, raw_half
end

function Public.check_alive_enemies()
    local this = Public.get()
    if this.alive_enemies <= 0 then
        return
    end

    if this.alive_enemies == 999 then
        return
    end

    local current_level = Public.get('current_level')
    local center_position = Public.get('islands_data')[current_level] or { position = { x = 0, y = 0 }, radius = 50 }

    local surface = game.surfaces[1]

    local center = center_position.position
    local center_radius = center_position.radius + 50

    local count = surface.count_entities_filtered({ force = 'enemy', type = { 'unit', 'turret', 'unit-spawner', 'spider-unit' }, area = { { center.x - center_radius, center.y - center_radius }, { center.x + center_radius, center.y + center_radius } } })

    if this.debug_island_values then
        rendering.draw_rectangle
        {
            color = { r = 0, g = 1, b = 0, a = 0.25 },
            filled = false,
            left_top = { center.x - center_radius, center.y - center_radius },
            right_bottom = { center.x + center_radius, center.y + center_radius },
            surface = surface,
            time_to_live = 600
        }
    end

    this.alive_enemies = count

    if this.alive_enemies == 0 then
        Public.complete_level()
    end
end

function Public.update_evolution_static()
    local evolution_factor = Public.get('evolution_factor')
    if not evolution_factor then return end
    if evolution_factor <= 0 then
        return
    end

    local force = game.forces.enemy
    force.set_evolution_factor(evolution_factor, game.surfaces[1])
end

function Public.update_evolution(this)
    local surface = game.surfaces[1]
    local force = game.forces.enemy

    local normalized = min(this.current_level / this.last_level, 1)
    local curve = pow(normalized, 1.3)

    local evolution_factor = max(0.05, min(curve, 1.0))

    this.evolution_factor = evolution_factor

    force.set_evolution_factor(evolution_factor, surface)
    Server.output_script_data(string.format("[Evo] Island level %d -> evolution %.2f", this.current_level, evolution_factor))
end

function Public.get_radius(position, size, divided_by)
    local noise = island_noise(position, divided_by)
    local rr = size
    return rr * 0.5 + noise * rr * 0.5
end

function Public.print_grid_value(value, surface, position, scale, offset)
    local this = Public.get()
    if not this.debug_island_values then
        return
    end

    local is_string = type(value) == 'string'
    local color = { r = 1, g = 1, b = 1 }
    local text = value

    if not is_string then
        scale = scale or 1
        offset = offset or 0
        position = { x = position.x + offset, y = position.y + offset }
        local r = max(1, value) / scale
        local g = 1 - abs(value) / scale
        local b = min(1, value) / scale

        if (r > 0) then
            r = 0
        end

        if (b < 0) then
            b = 0
        end

        if (g < 0) then
            g = 0
        end

        r = abs(r)

        color = { r = r, g = g, b = b }

        text = floor(100 * value) * 0.01

        if (0 == text) then
            text = '0.00'
        end
    end

    text = tostring(text)

    local text_entity = surface.find_entity('flying-text', position)

    if text_entity then
        text_entity.text = text
        text_entity.color = color
        return
    end

    surface.create_entity
    {
        name = 'flying-text',
        color = color,
        text = text,
        position = position
    }.active = false
end

function Public.get_tile_name_by_level(level)
    local tile_names =
    {
        'deepwater',
        'brash-ice',
        'lava-hot',
        'wetland-yumako',
        'wetland-jellynut',
    }
    return tile_names[(level - 1) % #tile_names + 1]
end

function Public.disable_tech()
    local force = game.forces['player']
    -- force.technologies['landfill'].enabled = false
    force.technologies['night-vision-equipment'].enabled = false
    force.technologies['artillery-shell-range-1'].enabled = false
    force.technologies['artillery-shell-speed-1'].enabled = false
    force.technologies['artillery'].enabled = false
    force.technologies['atomic-bomb'].enabled = false
    force.technologies['elevated-rail'].enabled = false
    force.technologies['rail-support-foundations'].enabled = false
    force.technologies['lightning-collector'].enabled = false
    force.technologies['land-mine'].enabled = false
    force.technologies['mech-armor'].enabled = false
    force.technologies['planet-discovery-fulgora'].researched = true
    force.technologies['planet-discovery-gleba'].researched = true
    force.technologies['planet-discovery-vulcanus'].researched = true
    force.technologies['planet-discovery-aquilo'].researched = true
    force.technologies['recycling'].researched = true
    force.technologies['lithium-processing'].researched = true
    force.technologies['holmium-processing'].researched = true
    force.technologies['calcite-processing'].researched = true
    force.technologies['agriculture'].researched = true
    force.technologies['heating-tower'].researched = true
    force.technologies['tungsten-carbide'].researched = true
    force.technologies['quality-module'].researched = true
    force.recipes['rocket-silo'].enabled = false
    force.recipes['mech-armor'].enabled = false
    force.recipes['railgun-turret'].enabled = false
    force.recipes['artillery-turret'].enabled = false
    force.recipes['land-mine'].enabled = false
    force.recipes['rail-ramp'].enabled = false
    force.recipes['rail-support'].enabled = false
    force.recipes['thruster'].enabled = false

    force.set_surface_hidden(game.surfaces['island'], true)
end

function Public.run_clear_items_on_ground()
    local this = Public.get()
    if not this.islands_data or not next(this.islands_data) then
        return
    end

    if not this.checked_island then
        this.checked_island = {}
    end


    for island_level, data in pairs(this.islands_data) do
        this.checked_island[island_level] = this.checked_island[island_level] or { next_check = 0 }
        if this.checked_island[island_level] and game.tick < this.checked_island[island_level].next_check then
            goto continue
        end

        if data and data.position then
            local radius = (data.radius or 0) + 100

            Scheduler.new(1, Public.find_items_on_ground_token)
                :set_data(
                    {
                        surface = game.surfaces[1],
                        position = data.position,
                        radius = radius
                    })

            this.checked_island[island_level] = { next_check = game.tick + 6000 }
        end
        ::continue::
    end
end

function Public.do_clear_items_on_ground_slowly()
    local clear_items_on_ground = Public.get('clear_items_on_ground')
    if not clear_items_on_ground or not next(clear_items_on_ground) then
        return
    end

    for _ = 1, 1000 do
        local entity = table.remove(clear_items_on_ground, #clear_items_on_ground)
        if entity and entity.valid then
            entity.destroy()
        end
    end
end

function Public.set_multi_command()
    local surface = game.get_surface('nauvis')
    if not surface or not surface.valid then
        return
    end

    local current_level = Public.get('current_level')
    local islands_data = Public.get('islands_data')
    if not islands_data or not next(islands_data) then
        error('No islands data found')
        return
    end

    local island_data = islands_data[current_level]
    if not island_data then
        error('No island data found for level ' .. current_level)
        return
    end

    local parent_island = island_data.parent_island
    if not parent_island then
        error('No parent island found for level ' .. current_level)
        return
    end

    if not island_data.bridge_generated then
        return
    end

    if island_data and parent_island and parent_island.market and parent_island.market.valid then
        local enemies = surface.find_entities_filtered({ type = 'unit', force = 'enemy', area = { { island_data.position.x - 30, island_data.position.y - 30 }, { island_data.position.x + 30, island_data.position.y + 30 } }, limit = 64 })
        if enemies and enemies[1] then
            for _, enemy in pairs(enemies) do
                if enemy and enemy.valid then
                    enemy.commandable.set_command(
                        {
                            type = defines.command.attack_area,
                            destination = parent_island.market.position,
                            radius = 125,
                            distraction = defines.distraction.by_anything
                        }
                    )
                end
            end
        end
    end
end

function Public.send_biters_to_market()
    local current_level = Public.get('current_level')
    if current_level == 1 then
        return
    end
    local disable_multi_command_attack = Public.get('disable_multi_command_attack')
    if disable_multi_command_attack then
        return
    end

    local alive_enemies = Public.get('alive_enemies')
    if alive_enemies == 0 or alive_enemies == 999 then
        return
    end

    local attack_grace_period = Public.get('attack_grace_period')
    if attack_grace_period and attack_grace_period > game.tick then
        return
    else
        local notified_enemies_to_attack = Public.get('notified_enemies_to_attack')
        if not notified_enemies_to_attack[current_level] then
            Public.delayed_message(1, Public.island_keeper .. 'The bugs have smelled the market at island level ' .. current_level - 1 .. ' and are swarming toward it!')
            notified_enemies_to_attack[current_level] = true
        end
    end

    local last_attack_tick = Public.get('last_attack_tick')
    if last_attack_tick and last_attack_tick > game.tick then
        return
    end

    local check_surface_daytime_for_attacks = Public.get('check_surface_daytime_for_attacks')

    local surface = game.surfaces[1]
    if check_surface_daytime_for_attacks then
        if surface.daytime < 0.35 then
            return
        end
        if surface.daytime > 0.65 then
            return
        end
    end

    Public.set('last_attack_tick', game.tick + 2000)

    local islands_data = Public.get('islands_data')
    if not islands_data or not next(islands_data) then
        error('No islands data found')
        return
    end

    local island_data = islands_data[current_level]
    if not island_data then
        error('No island data found for level ' .. current_level)
        return
    end

    local parent_island = island_data.parent_island
    if not parent_island then
        error('No parent island found for level ' .. current_level)
        return
    end

    local market = parent_island.market
    if not market or not market.valid then
        error('No connected market found for level ' .. current_level)
        return
    end

    if not island_data.bridge_generated then
        return
    end

    local count = game.surfaces[1].count_entities_filtered({ force = 'enemy', type = { 'unit', 'turret', 'unit-spawner', 'spider-unit' }, area = { { island_data.position.x - 256, island_data.position.y - 256 }, { island_data.position.x + 256, island_data.position.y + 256 } } })

    if count > 1500 then return end

    local difficulty_index = Difficulty.get('index')
    local base_min, base_max
    if difficulty_index == 1 then
        base_min, base_max = 16, 32
    elseif difficulty_index >= 2 then
        base_min, base_max = 32, 64
    end

    local scale = max(1, current_level * 0.1)
    local unit_count = random(base_min * scale, base_max * scale)
    unit_count = floor(unit_count)

    create_units_and_command(unit_count, market, surface, island_data.position, current_level)

    if random(1, 10) == 1 then
        local limit = 1
        if current_level > 5 then
            limit = 2
        elseif current_level > 8 then
            limit = 4
        end

        local enemies = surface.find_entities_filtered({ type = 'spider-unit', force = 'enemy', area = { { island_data.position.x - 125, island_data.position.y - 125 }, { island_data.position.x + 125, island_data.position.y + 125 } }, limit = limit })
        if enemies and enemies[1] then
            for _, enemy in pairs(enemies) do
                if enemy and enemy.valid then
                    enemy.commandable.set_command(
                        {
                            type = defines.command.attack_area,
                            destination = market.position,
                            radius = 125,
                            distraction = defines.distraction.by_anything
                        }
                    )
                end
            end
        end
    end
end

function Public.add_market_slot(market)
    local this = Public.get()
    local current_level = Public.get('current_level')
    this.market_prices[market.unit_number] = {}
    local offers =
    {
        {
            price = {},
            offer = { type = 'nothing', effect_description = 'Progress onwards to the next island!' }
        }
    }
    if random(1, 4) == 1 and this.infinite_ammo_grants < 10 then
        offers[#offers + 1] =
        {
            price = {},
            offer = { type = 'nothing', effect_description = 'Generate more ammo in the infinity chest!\nPrice: ' .. 500 * current_level .. ' coins' }
        }
        this.market_prices[market.unit_number]['ammo'] = 500 * current_level
    end
    if not this.piercing_ammo_grants and (current_level >= 1 and current_level <= 3) and not this.piercing_ammo_grants_added then
        if random(1, 6) == 1 then
            offers[#offers + 1] =
            {
                price = {},
                offer = { type = 'nothing', effect_description = 'Generate piercing rounds ammo in the infinity chest!\nPrice: ' .. 1000 * current_level .. ' coins' }
            }
            this.piercing_ammo_grants_added = true
            this.market_prices[market.unit_number]['piercing'] = 1000 * current_level
        end
    end
    if not this.uranium_ammo_grants and (current_level >= 7 and current_level <= this.last_level) and not this.uranium_ammo_grants_added then
        if random(1, 12) == 1 then
            offers[#offers + 1] =
            {
                price = {},
                offer = { type = 'nothing', effect_description = 'Generate uranium rounds ammo in the infinity chest!\nPrice: ' .. 1000 * current_level .. ' coins' }
            }
            this.market_prices[market.unit_number]['uranium'] = 1000 * current_level
            this.uranium_ammo_grants_added = true
        end
    end
    for _, offer in pairs(offers) do
        market.add_market_item(offer)
    end
end

function Public.add_market_revive_slot(market, revive_level, position)
    local this = Public.get()
    this.market_prices[market.unit_number] =
    {
        level = revive_level,
        position = position
    }
    local offers =
    {
        {
            price = {},
            offer = { type = 'nothing', effect_description = 'Capture this island!' }
        }
    }
    for _, offer in pairs(offers) do
        market.add_market_item(offer)
    end
end

function Public.get_random_position(center, radius)
    local angle = random() * pi * 2
    local r = sqrt(random()) * radius
    return { x = center.x + cos(angle) * r, y = center.y + sin(angle) * r }
end

function Public.get_enemy_tier(raw_level)
    local prev_tier
    for _, tier in ipairs(Public.enemy_progression) do
        if raw_level <= tier.max_level then
            if prev_tier then
                local mixed = table.deepcopy(tier)
                for _, list_name in ipairs({ 'biter_types', 'spitter_types', 'worm_types' }) do
                    for _, e in ipairs(prev_tier[list_name]) do
                        if random() < 0.3 then
                            table.insert(mixed[list_name], e)
                        end
                    end
                end
                return mixed
            end
            return tier
        end
        prev_tier = tier
    end
    return Public.enemy_progression[#Public.enemy_progression]
end

function Public.prepare_next_island(this)
    local level = this.current_level

    if level == 1 then
        this.next_island_position = { x = 0, y = 0 }
        return
    end

    local all_islands = this.islands_data
    if #all_islands == 0 then return end

    local origin_island = all_islands[random(1, #all_islands)]
    local island_radius = origin_island.radius
    if origin_island.level == 1 then
        island_radius = 100
    end

    local origin_pos = origin_island.position
    local origin_radius = island_radius or 50

    local current_level = this.stages[this.current_level]
    local current_radius = current_level and current_level.size or 100
    local base_distance = origin_radius + current_radius

    local new_x, new_y
    local attempts = 0
    local max_attempts = 500
    repeat
        attempts = attempts + 1
        local angle = rad(random(0, 359))
        local distance = base_distance + random(50, 250) + attempts
        new_x = origin_pos.x + cos(angle) * distance
        new_y = origin_pos.y + sin(angle) * distance
    until is_valid_position(all_islands, current_radius, new_x, new_y) or attempts >= max_attempts

    if attempts >= max_attempts then
        Core.log("Warning: Failed to find valid spacing for new island, forcing placement.")
    end

    local nearest, nearest_dist = nil, huge
    for _, island in pairs(all_islands) do
        local dx = island.position.x - new_x
        local dy = island.position.y - new_y
        local dist = sqrt(dx * dx + dy * dy)
        if dist < nearest_dist then
            nearest = island
            nearest_dist = dist
        end
    end

    if not nearest then
        error("Failed to find valid spacing for new island.")
        return
    end

    this.position = table.deep_copy(nearest.position)
    this.bridge_position = { x = this.position.x, y = this.position.y }
    this.next_island_position = { x = new_x, y = new_y }

    if this.reverse_start_position then
        this.bridge_position = { x = this.next_island_position.x, y = this.next_island_position.y }
    end

    this.nearest_island_level = { from = nearest.level, to = level, position = nearest.position }

    Core.log(string.format(
        "Island #%d branched from #%d at [%.1f, %.1f] (%.1f tiles, after %d tries)",
        level,
        nearest.level or 0,
        new_x, new_y,
        nearest_dist,
        attempts
    ))
end

function Public.draw_main_island(position, radius)
    local surface = game.surfaces[1]

    position = position or { x = 0, y = 0 }
    radius = radius or 200

    local root = Scheduler.new(1, Public.chart_area_for_player_force_token):set_data({ surface = surface })
    root:new_child(300, Public.do_island_creation_token)
        :set_data({ surface = surface, radius = radius, position = position, caller_name = 'draw_main_island' })
end

local function on_chunk_generated(event)
    if event.surface.index ~= 1 then
        return
    end
    local left_top = event.area.left_top
    local surface = event.surface

    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            local position = { x = left_top.x + x, y = left_top.y + y }
            if not is_inside_island(position.x, position.y) then
                surface.set_tiles { { name = 'water', position = position } }
            else
                surface.set_tiles({ { name = 'black-refined-concrete', position = position } }, true)
            end
        end
    end
end

function Public.complete_level()
    local this = Public.get()
    local island_data = this.islands_data[this.current_level]
    if this.alive_enemies == 0 and not island_data.completed and game.tick > this.cooldown_complete_level then
        island_data.completed = true
        island_data.auto_generated_island = nil
        island_data.auto_generated_bridge = nil
        for _, player in pairs(game.connected_players) do
            player.play_sound { path = 'utility/game_won', volume_modifier = 1 }
        end
        if this.current_level == this.last_level then
            game.print(Public.island_keeper .. 'All the bugs have been vanquished from the islands! GG!')
            Server.to_discord_embed('** All the bugs have been vanquished from the islands! GG! **')
            this.game_won = true
            this.game_reset_tick = 54000
        else
            Public.delayed_message(5, Public.island_keeper .. 'Level ' .. this.current_level .. ' has been completed!')
            Server.to_discord_embed('** Level ' .. this.current_level .. ' has been completed! **')
        end
    end
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_research_finished, Public.disable_tech)
Event.add(defines.events.on_player_built_tile, on_player_or_robot_built_tile)
Event.add(defines.events.on_robot_built_tile, on_player_or_robot_built_tile)

Public.on_chunk_generated = on_chunk_generated
Public.on_entity_died = on_entity_died
Public.on_market_item_purchased = on_market_item_purchased

return Public
