local Event = require 'utils.event'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Team = require 'maps.scrap_towny_ffa.team'
local Building = require 'maps.scrap_towny_ffa.building'
local FlyingText = require 'utils.functions.flying_texts'

local BuildingRules
local PvPTownShield
if ScenarioTable.enabled('bulldozer_mode') then
    BuildingRules = require 'maps.scrap_towny_ffa.building_rules'
    PvPTownShield = require 'maps.scrap_towny_ffa.pvp_town_shield'
end

local Public = {}

local extended_pipeline = ScenarioTable.mode('damage_pipeline') == 'extended'

local player_ammo_damage_starting_modifiers =
{
    ['bullet'] = 0,
    ['cannon-shell'] = -0.5,
    ['capsule'] = 0,
    ['beam'] = -0.5,
    ['laser'] = -0.5,
    ['electric'] = -0.5,
    ['flamethrower'] = 0,
    ['grenade'] = -0.5,
    ['landmine'] = -0.75,
    ['shotgun-shell'] = 0
}
local player_ammo_damage_modifiers =
{
    ['bullet'] = 0,
    ['cannon-shell'] = -0.5,
    ['capsule'] = 0,
    ['beam'] = -0.5,
    ['laser'] = -0.5,
    ['electric'] = -0.5,
    ['flamethrower'] = 0,
    ['grenade'] = -0.5,
    ['landmine'] = -0.5,
    ['shotgun-shell'] = 0
}
local player_gun_speed_modifiers =
{
    ['bullet'] = 0,
    ['cannon-shell'] = -0.5,
    ['capsule'] = -0.5,
    ['beam'] = -0.5,
    ['laser'] = 0,
    ['electric'] = -0.5,
    ['flamethrower'] = 0,
    ['grenade'] = -0.5,
    ['landmine'] = 0,
    ['shotgun-shell'] = 0
}

local extended_ammo_damage_starting_modifiers =
{
    ['bullet'] = 0,
    ['cannon-shell'] = -0.4,
    ['capsule'] = 0,
    ['beam'] = -0.5,
    ['laser'] = -0.5,
    ['electric'] = -0.5,
    ['flamethrower'] = 0,
    ['grenade'] = -0.5,
    ['landmine'] = -0.75,
    ['shotgun-shell'] = 0
}
local extended_ammo_damage_upgrade_modifiers =
{
    ['bullet'] = 0,
    ['cannon-shell'] = -0.75,
    ['capsule'] = 0,
    ['beam'] = -0.5,
    ['laser'] = -0.75,
    ['electric'] = -0.5,
    ['flamethrower'] = 0,
    ['grenade'] = -0.5,
    ['landmine'] = -0.5,
    ['shotgun-shell'] = 0
}
local extended_ammo_speed_starting_modifiers =
{
    ['bullet'] = 0,
    ['cannon-shell'] = -0.3,
    ['capsule'] = -0.5,
    ['beam'] = -0.5,
    ['laser'] = -0.7,
    ['electric'] = -0.5,
    ['flamethrower'] = 0,
    ['grenade'] = -0.5,
    ['landmine'] = -0.75,
    ['shotgun-shell'] = 0
}
local extended_ammo_speed_upgrade_modifiers =
{
    ['bullet'] = 0,
    ['cannon-shell'] = -0.3,
    ['capsule'] = -0.5,
    ['beam'] = -0.5,
    ['laser'] = -0.5,
    ['electric'] = -0.5,
    ['flamethrower'] = 0,
    ['grenade'] = -0.5,
    ['landmine'] = 0,
    ['shotgun-shell'] = 0
}

function Public.init_player_weapon_damage(force)
    if extended_pipeline then
        for k, v in pairs(extended_ammo_damage_starting_modifiers) do
            force.set_ammo_damage_modifier(k, v)
        end
        for k, v in pairs(extended_ammo_speed_starting_modifiers) do
            force.set_gun_speed_modifier(k, v)
        end
        force.set_turret_attack_modifier('laser-turret', 6)
        return
    end
    for k, v in pairs(player_ammo_damage_starting_modifiers) do
        force.set_ammo_damage_modifier(k, v)
    end
    for k, v in pairs(player_gun_speed_modifiers) do
        force.set_gun_speed_modifier(k, v)
    end
    force.set_turret_attack_modifier('laser-turret', 3)
end

local function research_finished(event)
    local r = event.research
    local p_force = r.force

    if extended_pipeline then
        p_force.recipes['slowdown-capsule'].enabled = false
    end

    for _, e in ipairs(r.prototype.effects) do
        local t = e.type

        if t == 'ammo-damage' then
            local category = e.ammo_category
            local factor = extended_pipeline and extended_ammo_damage_upgrade_modifiers[category] or player_ammo_damage_modifiers[category]

            if factor then
                local current_m = p_force.get_ammo_damage_modifier(category)
                p_force.set_ammo_damage_modifier(category, current_m + factor * e.modifier)
            end
        elseif t == 'gun-speed' then
            local category = e.ammo_category
            local factor = extended_pipeline and extended_ammo_speed_upgrade_modifiers[category] or player_gun_speed_modifiers[category]

            if factor then
                local current_m = p_force.get_gun_speed_modifier(category)
                p_force.set_gun_speed_modifier(category, current_m + factor * e.modifier)
            end
        end
    end
end

local force_damage_modifier_excluded =
{
    ['laser-turret'] = true,
    ['flamethrower-turret'] = true,
    ['gun-turret'] = true
}

local function format_dmg_modifier(modifier)
    return string.format('%.0f%%', 100 * modifier)
end
Public.format_dmg_modifier = format_dmg_modifier

local function calculate_modifier_for_town(town_center)
    local force = town_center.market.force
    if Team.is_towny(force) then
        return math.min(1 / #force.connected_players + 0.2, 1) + ((town_center.town_rest and town_center.town_rest.current_modifier) or 0) / 2
    else
        return 1
    end
end

local function update_modifiers()
    local this = ScenarioTable.get_table()
    for _, town_center in pairs(this.town_centers) do
        if not town_center.combat_balance then
            town_center.combat_balance = {}
            town_center.combat_balance.previous_modifier = 1
        end
        town_center.combat_balance.current_modifier = calculate_modifier_for_town(town_center)

        if math.abs(town_center.combat_balance.current_modifier - town_center.combat_balance.previous_modifier) >= 0.1 then
            town_center.market.force.print('Your town members attack damage is now '
                .. format_dmg_modifier(town_center.combat_balance.current_modifier)
                .. ' (previously ' .. format_dmg_modifier(town_center.combat_balance.previous_modifier) .. ')', { 255, 255, 0 })
            town_center.combat_balance.previous_modifier = town_center.combat_balance.current_modifier
        end
    end
end

function Public.player_changes_town_status()
    update_modifiers()
end

local non_bulldozable_entities =
{
    ['car'] = true,
    ['tank'] = true,
    ['locomotive'] = true,
    ['cargo-wagon'] = true,
    ['fluid-wagon'] = true,
}

storage.bulldoze_rate_limits = storage.bulldoze_rate_limits or {}

local function bulldoze_rate_limit_check(force)
    local force_name = force.name
    local force_limit = storage.bulldoze_rate_limits[force_name]
    if not force_limit or game.tick - force_limit > 60 then
        storage.bulldoze_rate_limits[force_name] = game.tick
        return true
    end
    return false
end

function Public.on_entity_damaged(event)
    if not extended_pipeline then
        return
    end
    local entity = event.entity
    if not entity.valid then
        return
    end
    local cause_force = event.force
    if cause_force == game.forces.enemy then
        return
    end
    local event_cause = event.cause

    local is_vehicle_damage = false
    local vehicle_modifier = 1

    if ScenarioTable.enabled('bulldozer_mode') and event.damage_type.name == 'explosion' and event_cause then
        local inv = event_cause.get_main_inventory()
        local grenade_name = 'grenade'
        local position = entity.position
        local min_grenades_inv = 500

        if inv and inv.get_item_count(grenade_name) > min_grenades_inv - 100 then
            local min_clear_distance = 30
            if not Building.near_another_town(cause_force.name, position, entity.surface, min_clear_distance)
                and not BuildingRules.near_outlander_town(cause_force, position, entity.surface, min_clear_distance)
                and not PvPTownShield.enemy_players_nearby(position, entity.surface, cause_force, min_clear_distance)
                and not Team.is_friendly_towards(cause_force, entity.force)
                and not non_bulldozable_entities[entity.type]
                and entity.force ~= game.forces.enemy
            then
                FlyingText.flying_text(event_cause.player, entity.surface, position, 'Bulldozed!', { r = 0.8, g = 0.7, b = 0.0 })
                entity.health = 0
                inv.remove({ name = grenade_name, count = 1 })
                return
            end
        else
            if bulldoze_rate_limit_check(event_cause) then
                FlyingText.flying_text(event_cause.player, entity.surface, position, 'Need ' .. min_grenades_inv .. ' grenades in inventory to bulldoze!', { r = 1.0, g = 1.0, b = 0.0 })
            end
        end
    end

    if ScenarioTable.enabled('tank_combat_tweaks') and entity.name == 'tank' then
        local damage_type_name = event.damage_type.name
        if damage_type_name == 'physical' or damage_type_name == 'fire' or damage_type_name == 'laser' then
            is_vehicle_damage = true
            if damage_type_name == 'laser' then
                vehicle_modifier = 2
            elseif damage_type_name == 'physical' and event.original_damage_amount > 80 then
                vehicle_modifier = vehicle_modifier * 2.1
            else
                vehicle_modifier = 0.3
            end

            if event_cause and (event_cause.name == 'tank' or event_cause.name == 'car') then
                vehicle_modifier = vehicle_modifier * 3
            end
        end
    end

    local force_modifier
    if not event_cause or force_damage_modifier_excluded[event_cause.name] then
        force_modifier = 1
    else
        local town_center = ScenarioTable.get_table().town_centers[cause_force.name]
        if town_center and town_center.combat_balance then
            force_modifier = town_center.combat_balance.current_modifier

            local last_shown = ScenarioTable.get_table().last_damage_multiplier_shown[cause_force.index]
            if (not last_shown or game.tick - last_shown > 60 * 60) and event_cause
                and entity.force ~= game.forces.neutral and entity.force ~= game.forces.enemy then
                FlyingText.flying_text(event_cause.player, entity.surface, event_cause.position, 'Damage: ' .. format_dmg_modifier(force_modifier), { r = 1, g = 1, b = 1 })
                ScenarioTable.get_table().last_damage_multiplier_shown[cause_force.index] = game.tick
            end
        else
            force_modifier = 1
        end
    end

    local would_be_killed = entity.health == 0

    if is_vehicle_damage then
        entity.health = entity.health + event.final_damage_amount - event.original_damage_amount * vehicle_modifier * force_modifier
    else
        if force_modifier == 1 then
            return
        else
            if event.final_damage_amount * force_modifier >= entity.health then
                entity.health = 0
            else
                entity.health = math.max(0, entity.health - event.final_damage_amount * (force_modifier - 1))
            end
        end
    end

    if would_be_killed and entity.health < entity.prototype.max_health * 0.05 then
        entity.health = 0
    end
end

local function on_player_used_capsule(event)
    if event.item.name ~= 'raw-fish' then
        return
    end
    local player = game.players[event.player_index]
    if player.character.health < 250 then
        player.character.health = player.character.health - 40
    end
    FlyingText.flying_text(player, player.surface, player.position, '-1 [img=item/' .. 'raw-fish' .. ']', { r = 0.98, g = 0.66, b = 0.22 })
end

Event.add(defines.events.on_research_finished, research_finished)

if extended_pipeline and ScenarioTable.enabled('dynamic_damage_modifier') then
    Event.on_nth_tick(63, update_modifiers)
end
if extended_pipeline and ScenarioTable.enabled('slowdown_capsule_disabled') then
    Event.add(defines.events.on_player_used_capsule, on_player_used_capsule)
end

return Public
