local Event = require 'utils.event'
local Server = require 'utils.server'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Team = require 'maps.scrap_towny_ffa.team'
local Building = require 'maps.scrap_towny_ffa.building'
local Colors = require 'maps.scrap_towny_ffa.colors'
local Enemy = require 'maps.scrap_towny_ffa.enemy'
local Color = require 'utils.color_presets'

local PvPTownShield
if ScenarioTable.enabled('pvp_offline_shield') or ScenarioTable.enabled('pvp_league_shield') or ScenarioTable.enabled('pvp_afk_shield') then
    PvPTownShield = require 'maps.scrap_towny_ffa.pvp_town_shield'
end

local Public = {}

local math_max = math.max
local math_min = math.min
local math_abs = math.abs

local town_rest_min_period_ticks = 2 * 60 * 60 * 60
local town_rest_loop_time = 60
local town_rest_up_per_loop = town_rest_loop_time * (1 / (20 - 2) / (60 * 60 * 60))
local town_rest_down_per_loop = town_rest_loop_time * (1 / 4 / (60 * 60 * 60))

local market_label_offsets =
{
    town_name = { 0, -4.25 },
    health = { 0, -3.25 },
}

local function round(num)
    return num >= 0 and math.floor(num + 0.5) or math.ceil(num - 0.5)
end

local function format_rest_modifier(modifier)
    return string.format('+%.0f%%', 100 * modifier)
end
Public.format_rest_modifier = format_rest_modifier

function Public.init_score_fields(town_center)
    town_center.survival_time_ticks = town_center.survival_time_ticks or 0
    town_center.last_swarm = town_center.last_swarm or 0
    town_center.laser_turrets = town_center.laser_turrets or 0
    town_center.labs = town_center.labs or 0
    town_center.pvp_shield_mgmt = town_center.pvp_shield_mgmt or {}
    town_center.marked_afk = false
    town_center.scoring_last_online = game.tick
    town_center.town_rest = town_center.town_rest or {}
    town_center.town_rest.last_online = game.tick
    town_center.town_rest.current_modifier = 0
    town_center.town_rest.previous_modifier = 0
    town_center.town_rest.mining_prod_bonus = 0

    local market = town_center.market

    if town_center.enemies_text and town_center.enemies_text.valid then
        town_center.enemies_text.destroy()
        town_center.enemies_text = nil
    end
    if town_center.shield_text and town_center.shield_text.valid then
        town_center.shield_text.destroy()
        town_center.shield_text = nil
    end
    if town_center.coins_text and town_center.coins_text.valid then
        town_center.coins_text.destroy()
        town_center.coins_text = nil
    end

    if market.valid then
        if town_center.town_caption and town_center.town_caption.valid then
            town_center.town_caption.target = { entity = market, offset = market_label_offsets.town_name }
        end
        if town_center.health_text and town_center.health_text.valid then
            town_center.health_text.target = { entity = market, offset = market_label_offsets.health }
        end
    end

    if PvPTownShield then
        PvPTownShield.init_town()
    end
end

local function update_town_rest()
    if not ScenarioTable.enabled('town_rest_bonus') then
        return
    end
    local this = ScenarioTable.get_table()
    for _, town_center in pairs(this.town_centers) do
        if not town_center.town_rest then
            Public.init_score_fields(town_center)
        end
        local town_force = town_center.market.force
        if #town_force.connected_players > 0 then
            town_center.town_rest.current_modifier = math_max(town_center.town_rest.current_modifier - town_rest_down_per_loop, 0)
            town_center.town_rest.last_online = game.tick
        elseif game.tick - town_center.town_rest.last_online > town_rest_min_period_ticks then
            town_center.town_rest.current_modifier = math_min(town_center.town_rest.current_modifier + town_rest_up_per_loop, 1)
        end
        local target_prod_bonus = town_center.town_rest.current_modifier * 0.5
        if math_abs(town_center.town_rest.mining_prod_bonus - target_prod_bonus) >= 0.01 then
            local diff = target_prod_bonus - town_center.town_rest.mining_prod_bonus
            local combined_bonus_precise = town_center.market.force.mining_drill_productivity_bonus + diff
            local combined_bonus_rounded = round(100 * combined_bonus_precise) / 100
            local rounding_error = combined_bonus_rounded - combined_bonus_precise
            town_center.market.force.mining_drill_productivity_bonus = combined_bonus_rounded
            town_center.town_rest.mining_prod_bonus = town_center.town_rest.mining_prod_bonus + diff + rounding_error
        end
    end
end

if ScenarioTable.enabled('town_rest_bonus') then
    Event.on_nth_tick(town_rest_loop_time, update_town_rest)
end

local math_random = math.random
local table_insert = table.insert
local math_floor = math.floor
local table_shuffle = table.shuffle_table
local table_size = table.size
local town_radius = 27
local radius_between_towns = 120
local ore_amount = 500 * (200 / 168.5)

local colors = {}
local c1 = 250
local c2 = 210
local c3 = -40
for v = c1, c2, c3 do
    table_insert(colors, { 0, 0, v })
end
for v = c1, c2, c3 do
    table_insert(colors, { 0, v, 0 })
end
for v = c1, c2, c3 do
    table_insert(colors, { v, 0, 0 })
end
for v = c1, c2, c3 do
    table_insert(colors, { 0, v, v })
end
for v = c1, c2, c3 do
    table_insert(colors, { v, v, 0 })
end
for v = c1, c2, c3 do
    table_insert(colors, { v, 0, v })
end

local town_wall_vectors = {}
for x = 2, town_radius, 1 do
    table_insert(town_wall_vectors, { x, town_radius })
    table_insert(town_wall_vectors, { x * -1, town_radius })
    table_insert(town_wall_vectors, { x, town_radius * -1 })
    table_insert(town_wall_vectors, { x * -1, town_radius * -1 })
end
for y = 2, town_radius - 1, 1 do
    table_insert(town_wall_vectors, { town_radius, y })
    table_insert(town_wall_vectors, { town_radius, y * -1 })
    table_insert(town_wall_vectors, { town_radius * -1, y })
    table_insert(town_wall_vectors, { town_radius * -1, y * -1 })
end

local gate_vectors_horizontal = {}
for x = -1, 1, 1 do
    table_insert(gate_vectors_horizontal, { x, town_radius })
    table_insert(gate_vectors_horizontal, { x, town_radius * -1 })
end
local gate_vectors_vertical = {}
for y = -1, 1, 1 do
    table_insert(gate_vectors_vertical, { town_radius, y })
    table_insert(gate_vectors_vertical, { town_radius * -1, y })
end

local resource_vectors = {}
resource_vectors[1] = {}
for x = 10, 22, 1 do
    for y = 10, 22, 1 do
        table_insert(resource_vectors[1], { x, y })
    end
end
resource_vectors[2] = {}
for _, vector in pairs(resource_vectors[1]) do
    table_insert(resource_vectors[2], { vector[1] * -1, vector[2] })
end
resource_vectors[3] = {}
for _, vector in pairs(resource_vectors[1]) do
    table_insert(resource_vectors[3], { vector[1] * -1, vector[2] * -1 })
end
resource_vectors[4] = {}
for _, vector in pairs(resource_vectors[1]) do
    table_insert(resource_vectors[4], { vector[1], vector[2] * -1 })
end

local additional_resource_vectors = {}
additional_resource_vectors[1] = {}
for x = 10, 22, 1 do
    for y = -4, 4, 1 do
        table_insert(additional_resource_vectors[1], { x, y })
    end
end
additional_resource_vectors[2] = {}
for _, vector in pairs(additional_resource_vectors[1]) do
    table_insert(additional_resource_vectors[2], { vector[1] * -1, vector[2] })
end
additional_resource_vectors[3] = {}
for y = 10, 22, 1 do
    for x = -4, 4, 1 do
        table_insert(additional_resource_vectors[3], { x, y })
    end
end
additional_resource_vectors[4] = {}
for _, vector in pairs(additional_resource_vectors[3]) do
    table_insert(additional_resource_vectors[4], { vector[1], vector[2] * -1 })
end

local starter_supplies =
{
    { name = 'raw-fish', count = 20 },
    { name = 'grenade', count = 5 },
    { name = 'stone', count = 100 },
    { name = 'land-mine', count = 4 },
    { name = 'iron-gear-wheel', count = 16 },
    { name = 'iron-plate', count = 200 },
    { name = 'shotgun', count = 1 },
    { name = 'shotgun-shell', count = 8 },
    { name = 'firearm-magazine', count = 20 },
    { name = 'gun-turret', count = 4 }
}

local function count_nearby_ore(surface, position, ore_name)
    local count = 0
    local r = town_radius + 8
    for _, e in pairs(surface.find_entities_filtered({ area = { { position.x - r, position.y - r }, { position.x + r, position.y + r } }, force = 'neutral', name = ore_name })) do
        count = count + e.amount
    end
    return count
end

local function draw_town_spawn(player_name)
    local this = ScenarioTable.get_table()
    local market = this.town_centers[player_name].market
    local position = market.position
    local surface = market.surface

    for _, vector in pairs(gate_vectors_horizontal) do
        local p = { position.x + vector[1], position.y + vector[2] }

        if p then
            surface.create_entity({ name = 'gate', position = p, force = player_name, direction = 4 })
        end
    end
    for _, vector in pairs(gate_vectors_vertical) do
        local p = { position.x + vector[1], position.y + vector[2] }

        if p then
            surface.create_entity({ name = 'gate', position = p, force = player_name, direction = 0 })
        end
    end

    for _, vector in pairs(town_wall_vectors) do
        local p = { position.x + vector[1], position.y + vector[2] }

        if p then
            surface.create_entity({ name = 'stone-wall', position = p, force = player_name })
        end
    end

    local ores = { 'iron-ore', 'copper-ore', 'stone', 'coal' }
    table_shuffle(ores)

    for i = 1, 4, 1 do
        if count_nearby_ore(surface, position, ores[i]) < 100000 then
            for _, vector in pairs(resource_vectors[i]) do
                local p = { position.x + vector[1], position.y + vector[2] }
                p = surface.find_non_colliding_position(ores[i], p, 64, 1)
                if p then
                    surface.create_entity({ name = ores[i], position = p, amount = ore_amount })
                end
            end
        end
    end

    for _, item_stack in pairs(starter_supplies) do
        local m1 = -8 + math_random(0, 16)
        local m2 = -8 + math_random(0, 16)
        local p = { position.x + m1, position.y + m2 }
        p = surface.find_non_colliding_position('wooden-chest', p, 64, 1)
        if p then
            local e = surface.create_entity({ name = 'iron-chest', position = p, force = player_name })
            local inventory = e.get_inventory(defines.inventory.chest)
            inventory.insert(item_stack)
        end
    end

    local vector_indexes = { 1, 2, 3, 4 }
    table_shuffle(vector_indexes)

    for _, vector in pairs(additional_resource_vectors[vector_indexes[2]]) do
        local x = position.x + vector[1]
        local y = position.y + vector[2]
        local p = { x = x, y = y }
        if surface.get_tile(p).name ~= 'out-of-map' then
            surface.set_tiles({ { name = 'water-shallow', position = p } })
        end
    end

    for _, vector in pairs(additional_resource_vectors[vector_indexes[2]]) do
        local x = position.x + vector[1] + 0.5
        local y = position.y + vector[2] + 0.5
        local p = { x = x, y = y }
        if math_random(1, 3) == 1 then
            if surface.can_place_entity({ name = 'fish', position = p }) then
                surface.create_entity({ name = 'water-splash', position = p })
                surface.create_entity({ name = 'fish', position = p })
            end
        end
    end
end

local function is_valid_location(force_name, surface, position)
    local this = ScenarioTable.get_table()
    if not surface.can_place_entity({ name = 'market', position = position }) then
        for _, p in pairs(game.connected_players) do
            if p.surface == surface then
                p.create_local_flying_text(
                    {
                        position = position,
                        text = 'Position is obstructed - no room for market!',
                        color = { r = 0.77, g = 0.0, b = 0.0 }
                    })
            end
        end
        return false
    end

    for _, vector in pairs(town_wall_vectors) do
        local p = { x = math_floor(position.x + vector[1]), y = math_floor(position.y + vector[2]) }
        if Building.in_restricted_zone(surface, p) then
            for _, player in pairs(game.connected_players) do
                if player.surface == surface then
                    player.create_local_flying_text(
                        {
                            position = position,
                            text = 'Can not build in restricted zone!',
                            color = { r = 0.77, g = 0.0, b = 0.0 }
                        })
                end
            end
            return false
        end
    end

    if table_size(this.town_centers) > 48 then
        for _, p in pairs(game.connected_players) do
            if p.surface == surface then
                p.create_local_flying_text(
                    {
                        position = position,
                        text = 'Too many towns on the map!',
                        color = { r = 0.77, g = 0.0, b = 0.0 }
                    })
            end
        end
        return false
    end

    if Building.near_another_town(force_name, position, surface, radius_between_towns) == true then
        for _, p in pairs(game.connected_players) do
            if p.surface == surface then
                p.create_local_flying_text(
                    {
                        position = position,
                        text = 'Town location is too close to others!',
                        color = { r = 0.77, g = 0.0, b = 0.0 }
                    })
            end
        end
        return false
    end

    return true
end

function Public.in_any_town(position)
    local this = ScenarioTable.get_table()
    local town_centers = this.town_centers
    for _, town_center in pairs(town_centers) do
        local market = town_center.market
        if market ~= nil then
            if Building.in_area(position, market.position, town_radius) == true then
                return true
            end
        end
    end
    return false
end

function Public.update_town_name(force)
    local this = ScenarioTable.get_table()
    local town_center = this.town_centers[force.name]
    town_center.town_caption.text = town_center.town_name
end

function Public.set_market_health(entity, final_damage_amount)
    local this = ScenarioTable.get_table()
    local town_center = this.town_centers[entity.force.name]
    town_center.health = math_floor(town_center.health - final_damage_amount)
    if town_center.health > town_center.max_health then
        town_center.health = town_center.max_health
    end
    local m = town_center.health / town_center.max_health
    entity.health = 150 * m
    town_center.health_text.text = 'HP: ' .. town_center.health .. ' / ' .. town_center.max_health
end

local function found_town(event)
    local entity = event.entity

    if entity == nil or not entity.valid then
        return
    end

    local player = game.players[event.player_index]

    local character = player.character
    if character == nil then
        return
    end

    if entity.name ~= 'stone-furnace' then
        return
    end

    if player.force.index ~= game.forces.player.index and player.force.index ~= game.forces['rogue'].index then
        return
    end

    local force_name = tostring(player.name)
    local surface = entity.surface
    local position = entity.position

    entity.destroy()

    local this = ScenarioTable.get_table()
    if not this.towns_enabled then
        player.print('You must wait for more players to join!', { 255, 255, 0 })
        player.insert({ name = 'stone-furnace', count = 1 })
        return
    end

    if game.forces[force_name] then
        player.insert({ name = 'stone-furnace', count = 1 })
        return
    end

    if Team.has_key(player.index) == false then
        player.insert({ name = 'stone-furnace', count = 1 })
        return
    end

    if this.cooldowns_town_placement[player.index] then
        if game.tick < this.cooldowns_town_placement[player.index] then
            for _, p in pairs(game.connected_players) do
                if p.surface == surface then
                    p.create_local_flying_text(
                        {
                            position = position,
                            text = 'Town founding is on cooldown for ' .. math.ceil((this.cooldowns_town_placement[player.index] - game.tick) / 3600) .. ' minutes.',
                            color = { r = 0.77, g = 0.0, b = 0.0 }
                        })
                end
            end
            player.insert({ name = 'stone-furnace', count = 1 })
            return
        end
    end

    if not is_valid_location(force_name, surface, position) then
        player.insert({ name = 'stone-furnace', count = 1 })
        return
    end

    local force = Team.add_new_force(force_name)

    this.town_centers[force_name] = {}
    local town_center = this.town_centers[force_name]
    town_center.town_name = player.name .. "'s Town"
    town_center.market = surface.create_entity({ name = 'market', position = position, force = force_name })
    town_center.chunk_position = { math.floor(town_center.market.position.x / 32), math.floor(town_center.market.position.y / 32) }
    town_center.max_health = 100
    town_center.coin_balance = 0
    town_center.input_buffer = {}
    town_center.output_buffer = {}
    town_center.health = town_center.max_health
    local crayola = Colors.get_random_color()
    town_center.color = crayola.color
    town_center.research_counter = 1
    town_center.upgrades = {}
    town_center.upgrades.mining_prod = 0
    town_center.upgrades.mining_speed = 0
    town_center.upgrades.crafting_speed = 0
    town_center.upgrades.laser_turret = {}
    town_center.upgrades.laser_turret.slots = 8
    town_center.upgrades.laser_turret.locations = 0
    town_center.evolution = {}
    town_center.evolution.biters = 0
    town_center.evolution.spitters = 0
    town_center.evolution.worms = 0
    town_center.creation_tick = game.tick

    town_center.town_caption =
        rendering.draw_text
        {
            text = town_center.town_name,
            surface = surface,
            forces = { force_name, game.forces.player, game.forces.rogue },
            target = { entity = town_center.market, offset = market_label_offsets.town_name },
            color = town_center.color,
            scale = 1.30,
            font = 'default-game',
            alignment = 'center',
            scale_with_zoom = false
        }

    town_center.health_text =
        rendering.draw_text
        {
            text = 'HP: ' .. town_center.health .. ' / ' .. town_center.max_health,
            surface = surface,
            forces = { force_name, game.forces.player, game.forces.rogue },
            target = { entity = town_center.market, offset = market_label_offsets.health },
            color = { 200, 200, 200 },
            scale = 1.00,
            font = 'default-game',
            alignment = 'center',
            scale_with_zoom = false
        }

    Enemy.clear_enemies(position, surface, town_radius * 5)
    draw_town_spawn(force_name)

    local pos = { x = town_center.market.position.x, y = town_center.market.position.y + 4 }

    force.set_spawn_position(pos, surface)

    if ScenarioTable.enabled('town_rest_bonus') or ScenarioTable.enabled('market_enemy_display') or ScenarioTable.enabled('pvp_offline_shield')
        or ScenarioTable.enabled('pvp_league_shield') or ScenarioTable.enabled('pvp_afk_shield') then
        Public.init_score_fields(town_center)
    end

    Team.add_player_to_town(player, town_center)
    Team.remove_key(player.index)
    Team.add_chart_tag(town_center)

    game.print('>> ' .. player.name .. ' has founded a new town!', { 255, 255, 0 })
    Server.to_discord_embed(player.name .. ' has founded a new town!')
    player.print('Your town color is ' .. crayola.name, crayola.color)
end

local function on_built_entity(event)
    found_town(event)
end

local function on_player_repaired_entity(event)
    local entity = event.entity
    if entity.name == 'market' then
        Public.set_market_health(entity, -4)
    end
end

local function on_entity_damaged(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    if entity.name == 'market' then
        Public.set_market_health(entity, event.final_damage_amount)
    end
end

local function rename_town(cmd)
    local player = game.players[cmd.player_index]
    if not player or not player.valid then
        return
    end
    local force = player.force
    if force.name == 'player' or force.name == 'rogue' then
        player.print('You are not member of a town!', { color = Color.fail })
        return
    end
    local name = cmd.parameter
    if name == nil then
        player.print('Must specify new town name!', { color = Color.fail })
        return
    end
    local this = ScenarioTable.get_table()
    local town_center = this.town_centers[force.name]
    local old_name = town_center.town_name
    town_center.town_name = name
    Public.update_town_name(force)

    for _, p in pairs(force.players) do
        if p == player then
            player.print('Your town name is now ' .. name, town_center.color)
        else
            player.print(player.name .. ' has renamed the town to ' .. name, town_center.color)
        end
        Team.set_player_color(p)
    end

    game.print('>> ' .. old_name .. ' is now known as ' .. '"' .. name .. '"', { 255, 255, 0 })
    Server.to_discord_embed(old_name .. ' is now known as ' .. '"' .. name .. '"')
end

commands.add_command(
    'rename-town',
    'Renames your town..',
    function (cmd)
        rename_town(cmd)
    end
)

Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)

return Public
