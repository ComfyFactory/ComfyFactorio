local Team = require 'maps.scrap_towny_ffa.team'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local FlyingText = require 'utils.functions.flying_texts'
local Compat = require 'utils.functions.factorio_compat'

storage.force_available_recipe_cache = storage.force_available_recipe_cache or {}

local function update_recipes(force)
    storage.force_available_recipe_cache[force.name] = {}

    for _, rec in pairs(force.recipes) do
        if rec.enabled then
            for _, prod in pairs(rec.products) do
                storage.force_available_recipe_cache[force.name][prod.name] = true
            end
        end
    end
end

local function research_finished(event)
    update_recipes(event.research.force)
end

local allowed_for_all =
{
    ['entity-ghost'] = true,
    ['tile-ghost'] = true,
    ['gate'] = true,

    ['car'] = true,
    ['heavy-armor'] = true,
    ['modular-armor'] = true,
    ['solar-panel-equipment'] = true,
    ['battery-equipment'] = true,
    ['personal-roboport-equipment'] = true,
    ['night-vision-equipment'] = true,

    ['requester-chest'] = true,
    ['land-mine'] = true,

    ['curved-rail'] = true,
    ['straight-rail'] = true,

    ['loader'] = true,
    ['fast-loader'] = true,
    ['express-loader'] = true
}

local allowed_for_towns =
{
    ['laser-turret'] = true
}

local function error_floaty(surface, position)
    FlyingText.flying_text(nil, surface, position, 'Technology not available!', { r = 0.77, g = 0.0, b = 0.0 })
end

local function force_unequip_armor(player, armor_inventory, armor)
    local armor_stack = armor_inventory.find_item_stack(armor.name)

    local spill_item_stack_param =
    {
        position = player.position,
        stack = armor_stack,
        enable_looted = false,
        allow_belts = false,
        force = player.force
    }
    local floor_stack = Compat.spill_item_stack(player.surface, spill_item_stack_param)[1]
    armor_inventory.remove(armor_stack)
    local player_inventory = player.get_main_inventory()
    if player_inventory.insert(floor_stack.stack) == 1 then
        floor_stack.destroy()
    end
    player.print('Technology not available for your armor or one of its modules.', { 255, 0, 0 })
end

local function is_recipe_available(force, recipe_name)
    if not storage.force_available_recipe_cache[force.name] then
        update_recipes(force)
    end

    return storage.force_available_recipe_cache[force.name][recipe_name] or allowed_for_all[recipe_name]
end

local function process_armor(player)
    local armor_inventory = player.get_inventory(defines.inventory.character_armor)
    if not armor_inventory.valid then
        log('error: not armor_inventory.valid')
        return
    end
    local armor = armor_inventory[1]
    if not armor.valid_for_read then
        return
    end

    if not is_recipe_available(player.force, armor.name) then
        force_unequip_armor(player, armor_inventory, armor)
        return
    end

    local grid = armor.grid
    if not grid or not grid.valid then
        return
    end
    local equip = grid.equipment
    for _, piece in pairs(equip) do
        if piece.valid then
            if not is_recipe_available(player.force, piece.name) then
                force_unequip_armor(player, armor_inventory, armor)
            end
        end
    end
end

local function on_player_placed_equipment(event)
    process_armor(game.get_player(event.player_index))
end

local function on_player_armor_inventory_changed(event)
    process_armor(game.get_player(event.player_index))
end

local function process_building_limit(actor, event)
    local entity = event.entity
    if not entity.valid then return end

    if not is_recipe_available(actor.force, entity.name)
        and not (allowed_for_towns[entity.name] and Team.is_towny(actor.force)) then
        error_floaty(entity.surface, entity.position)
        local entity_to_refund = entity.name
        entity.destroy()
        actor.insert({ name = entity_to_refund, count = 1 })
    end
end

local function on_player_built_entity(event)
    local player = game.get_player(event.player_index)
    if player.controller_type == defines.controllers.editor then return end
    process_building_limit(player, event)
end

local function on_robot_built_entity(event)
    process_building_limit(event.robot, event)
end

local function on_entity_settings_pasted(event)
    local player = game.get_player(event.player_index)
    local destination = event.destination
    if not (destination and destination.valid) then return end
    if destination.type == 'assembling-machine' then
        local recipe = destination.get_recipe()
        if recipe and not is_recipe_available(player.force, recipe.name) then
            player.print('Recipe not available for your force.', { 255, 0, 0 })
            destination.set_recipe(nil)
        end
    end
end

local function on_player_driving_changed_state(event)
    local player = game.get_player(event.player_index)
    local this = ScenarioTable.get_table()
    if this.testing_mode then
        game.print('Testing mode is on - skip check')
        return
    end

    if player and player.valid and player.vehicle and not is_recipe_available(player.force, player.vehicle.name) then
        error_floaty(player.vehicle.surface, player.vehicle.position)
        player.driving = false
    end
end

local Event = require 'utils.event'
Event.add(defines.events.on_research_finished, research_finished)
Event.add(defines.events.on_built_entity, on_player_built_entity)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_player_armor_inventory_changed, on_player_armor_inventory_changed)
Event.add(defines.events.on_player_placed_equipment, on_player_placed_equipment)
Event.add(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)
Event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
