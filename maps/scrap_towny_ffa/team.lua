local Event = require 'utils.event'
local Server = require 'utils.server'
local Map = require 'maps.scrap_towny_ffa.map'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'

local Public = {}

local math_random = math.random
local table_size = table.size
local string_match = string.match
local string_lower = string.lower
local math_min = math.min
local outlander_color = { 150, 150, 150 }
local outlander_chat_color = { 170, 170, 170 }
local rogue_color = { 150, 150, 150 }
local rogue_chat_color = { 170, 170, 170 }
local item_drop_radius = 1.65

local destroy_wall_types =
{
    ['gate'] = true,
    ['wall'] = true
}

local destroy_military_types =
{
    ['ammo-turret'] = true,
    ['artillery-turret'] = true,
    ['artillery-wagon'] = true,
    ['electric-turret'] = true,
    ['fluid-turret'] = true,
    ['lab'] = true,
    ['land-mine'] = true,
    ['logistic-robot'] = true,
    ['radar'] = true,
    ['reactor'] = true,
    ['roboport'] = true,
    ['rocket-silo'] = true
}

local destroy_robot_types =
{
    ['combat-robot'] = true,
    ['construction-robot'] = true,
    ['logistic-robot'] = true
}

local storage_types =
{
    ['container'] = true,
    ['logistic-container'] = true,
    ['storage-tank'] = true
}

local player_force_disabled_recipes =
{
    'lab',
    'automation-science-pack',
    'stone-brick',
    'radar'
}
local all_force_enabled_recipes =
{
    'submachine-gun',
    'shotgun',
    'shotgun-shell'
}

local function update_member_limit(force)
    if not force or not force.valid then
        log('force nil or not valid!')
        return
    end
    local this = ScenarioTable.get_table()
    local town_centers = this.town_centers

    local limit = 1
    while true do
        local towns_near_limit = 0
        for _, town_center in pairs(town_centers) do
            local players = table_size(town_center.market.force.players)
            if players >= limit then
                towns_near_limit = towns_near_limit + 1
            end
        end
        if towns_near_limit >= 2 then
            limit = limit + 1
        else
            break
        end
    end

    this.member_limit = math_min(limit, 3)
end

local function can_force_accept_member(force)
    if not force or not force.valid then
        log('force nil or not valid!')
        return
    end
    local this = ScenarioTable.get_table()
    update_member_limit(force)

    if #force.players >= this.member_limit then
        game.print('>> Town ' .. force.name .. ' has too many settlers! Current limit: ' .. this.member_limit .. '.' .. ' The limit will increase once other towns have more settlers.', { 255, 255, 0 })
        return false
    end
    return true
end

function Public.is_outlander(force)
    if ScenarioTable.mode('outlander_forces') == 'individual' then
        return string.sub(force.name, 1, 2) == 'o_'
    end
    return force.name == 'player' or force.name == 'rogue'
end

function Public.is_towny(force)
    if ScenarioTable.mode('outlander_forces') == 'individual' then
        return string.sub(force.name, 1, 2) == 't_'
    end
    return force.name ~= 'rogue' and force.name ~= 'player'
end

function Public.non_town_display_name(force)
    assert(not Public.is_towny(force))
    if Public.is_outlander(force) then
        if ScenarioTable.mode('outlander_forces') == 'individual' then
            return string.sub(force.name, 3)
        end
        return force.name
    elseif force == game.forces.enemy then
        return 'the biters'
    else
        return force.name
    end
end

function Public.is_friendly_towards(my_force, other_force)
    return my_force == other_force or my_force.get_friend(other_force) or my_force.get_cease_fire(other_force)
end

local function force_display_name(force)
    if Public.is_towny(force) then
        local town_center = ScenarioTable.get_table().town_centers[force.name]
        if town_center then
            return town_center.town_name
        end
    end
    if Public.is_outlander(force) then
        return Public.non_town_display_name(force)
    end
    return force.name
end

function Public.has_key(index)
    local this = ScenarioTable.get_table()
    if this.key == nil then
        this.key = {}
    end
    if this.key[index] ~= nil then
        return this.key[index]
    end
    return false
end

function Public.give_key(index)
    local this = ScenarioTable.get_table()
    if this.key == nil then
        this.key = {}
    end
    this.key[index] = true
end

function Public.remove_key(index)
    local this = ScenarioTable.get_table()
    if this.key == nil then
        this.key = {}
    end
    this.key[index] = false
end

function Public.set_player_color(player)
    if not player or not player.valid then
        log('player nil or not valid!')
        return
    end
    local this = ScenarioTable.get_table()
    local force_name = player.force.name
    if force_name == 'player' then
        player.color = outlander_color
        player.chat_color = outlander_chat_color
        return
    end
    if force_name == 'rogue' then
        player.color = rogue_color
        player.chat_color = rogue_chat_color
        return
    end
    local town_center = this.town_centers[player.force.name]
    if not town_center then
        return
    end
    player.color = town_center.color
    player.chat_color = town_center.color
end

local function set_town_color(event)
    local this = ScenarioTable.get_table()
    if event.command ~= 'color' then
        return
    end
    local player = game.players[event.player_index]
    local force = player.force
    local town_center = this.town_centers[force.name]
    if not town_center then
        Public.set_player_color(player)
        return
    end
    town_center.color = { player.color.r, player.color.g, player.color.b }
    rendering.set_color(town_center.town_caption, town_center.color)
    for _, p in pairs(force.players) do
        Public.set_player_color(p)
    end
end

function Public.set_all_player_colors()
    for _, p in pairs(game.connected_players) do
        Public.set_player_color(p)
    end
end

local function reset_player(player)
    if not player or not player.valid then
        log('player nil or not valid!')
        return
    end
    if player.character ~= nil then
        local character = player.character
        character.character_crafting_speed_modifier = 0.0
        character.character_mining_speed_modifier = 0.0
        character.character_inventory_slots_bonus = 0
    end
end

local function update_balance_hud(player, in_town)
    if ScenarioTable.enabled('research_balance') then
        require('maps.scrap_towny_ffa.research_balance').player_changes_town_status(player, in_town)
    end
    if ScenarioTable.enabled('dynamic_damage_modifier') or ScenarioTable.enabled('hud_damage') then
        require('maps.scrap_towny_ffa.combat_balance').player_changes_town_status(player, in_town)
    end
    local TownStatus = require 'maps.scrap_towny_ffa.town_status'
    if TownStatus.enabled() then
        TownStatus.player_changes_town_status(player, in_town)
    end
end

function Public.add_player_to_town(player, town_center)
    if not player or not player.valid then
        log('player nil or not valid!')
        return
    end
    if not town_center then
        log('town_center nil!')
        return
    end
    local this = ScenarioTable.get_table()
    local market = town_center.market
    local force = market.force
    local surface = market.surface
    reset_player(player)
    player.force = market.force
    Public.remove_key(player.index)
    this.spawn_point[player.index] = force.get_spawn_position(surface)
    game.permissions.get_group(force.name).add_player(player)
    player.tag = ''
    Map.enable_world_map(player)
    Public.set_player_color(player)

    update_member_limit(force)
    game.print('>> The member limit for all towns is now: ' .. this.member_limit, { 255, 255, 0 })
    update_balance_hud(player, true)
end

function Public.give_player_items(player)
    if not player or not player.valid then
        log('player nil or not valid!')
        return
    end
    player.clear_items_inside()
    player.insert({ name = 'raw-fish', count = 3 })
    if player.force.name == 'rogue' or player.force.name == 'player' then
        player.insert { name = 'stone-furnace', count = '1' }
    end
end

local outlander_force_disabled_recipes =
{
    'automation-science-pack',
    'logistic-science-pack',
    'chemical-science-pack',
    'military-science-pack',
    'production-science-pack',
    'utility-science-pack',
    'lab',
    'radar',
}

local function set_biter_peace(force, peace)
    game.forces.enemy.set_cease_fire(force, peace)
    force.set_cease_fire(game.forces.enemy, peace)
end

local function create_outlander_force(player)
    local force = game.create_force('o_' .. player.name)
    if ScenarioTable.enabled('individual_outlander_peace_with_biters') then
        set_biter_peace(force, true)
    end
    force.share_chart = true
    force.friendly_fire = true
    if game.permissions.get_group('outlander') == nil then
        game.permissions.create_group('outlander')
    end
    game.permissions.get_group('outlander').add_player(player)
    force.disable_research()
    for _, recipe_name in pairs(outlander_force_disabled_recipes) do
        if force.recipes[recipe_name] then
            force.recipes[recipe_name].enabled = false
        end
    end
    require('maps.scrap_towny_ffa.combat_balance').init_player_weapon_damage(force)
    if ScenarioTable.mode('map_mode') == 'fixed' then
        local MapLayout = require 'maps.scrap_towny_ffa.map_layout'
        MapLayout.reveal_strategic_resources(force)
    end
    return force
end

local function set_player_to_individual_outlander(player)
    player.force = create_outlander_force(player)
    player.tag = '[Outlander]'
    Map.disable_world_map(player)
    Public.set_player_color(player)
    Public.give_key(player.index)
end

function Public.set_player_to_outlander(player)
    if not player or not player.valid then
        log('player nil or not valid!')
        return
    end
    if ScenarioTable.mode('outlander_forces') == 'individual' then
        set_player_to_individual_outlander(player)
        update_balance_hud(player, false)
        return
    end
    player.force = game.forces.player
    if game.permissions.get_group('outlander') == nil then
        game.permissions.create_group('outlander')
    end
    game.permissions.get_group('outlander').add_player(player)
    player.tag = '[Outlander]'
    Map.disable_world_map(player)
    Public.set_player_color(player)
    Public.give_key(player.index)
    update_balance_hud(player, false)
end

local function set_player_to_rogue(player)
    if not player or not player.valid then
        log('player nil or not valid!')
        return
    end

    player.force = 'rogue'
    local group = game.permissions.get_group('rogue')
    if group == nil then
        group = game.permissions.create_group('rogue')
    end

    if not player.object_name == 'LuaPlayer' then
        log('Given object is not of LuaPlayer!')
        return
    end
    player.print('You have broken the peace with the biters. They will seek revenge!')
    group.add_player(player)
    player.tag = '[Rogue]'
    Map.disable_world_map(player)
    Public.set_player_color(player)
end

local function ally_outlander(player, target)
    if not player or not player.valid then
        log('player nil or not valid!')
        return
    end
    if not target or not target.valid then
        log('target nil or not valid!')
        return
    end
    local this = ScenarioTable.get_table()
    local requesting_force = player.force
    local target_force = target.force
    local target_town_center = this.town_centers[target_force.name]

    if not this.towns_enabled then
        player.print('You must wait for more players to join!', { 255, 255, 0 })
        return false
    end

    if not Public.is_towny(requesting_force) and not Public.is_towny(target_force) then
        return false
    end

    if Public.is_towny(requesting_force) and Public.is_towny(target_force) then
        return false
    end

    if not Public.is_towny(requesting_force) and Public.is_towny(target_force) then
        this.requests[player.index] = target_force.name

        local target_player
        if target.type == 'character' then
            target_player = target.player
        else
            target_player = game.players[target_force.name]
        end

        if target_player then
            if this.requests[target_player.index] then
                if this.requests[target_player.index] == player.name then
                    if not can_force_accept_member(target_force) then
                        return true
                    end
                    game.print('>> ' .. player.name .. ' has settled in ' .. target_town_center.town_name, { 255, 255, 0 })
                    Public.add_player_to_town(player, target_town_center)
                    return true
                end
            end
        end

        game.print('>> ' .. player.name .. ' wants to settle in ' .. target_town_center.town_name, { 255, 255, 0 })
        return true
    end

    if Public.is_towny(requesting_force) and not Public.is_towny(target_force) then
        if target.type ~= 'character' then
            return true
        end
        local target_player = target.player
        if not target_player then
            return true
        end
        this.requests[player.index] = target_player.name

        if this.requests[target_player.index] then
            if this.requests[target_player.index] == player.force.name then
                if target_town_center then
                    if not can_force_accept_member(player.force) then
                        return true
                    end
                    game.print('>> ' .. player.name .. ' has accepted ' .. target_player.name .. ' into' .. target_town_center.town_name, { 255, 255, 0 })
                    Public.add_player_to_town(target_player, this.town_centers[player.force.name])
                    return true
                end
            end
        end

        local target_town_center_player = this.town_centers[player.force.name]
        game.print('>> ' .. player.name .. ' is inviting ' .. target_player.name .. ' into ' .. target_town_center_player.town_name, { 255, 255, 0 })
        return true
    end
end

local function ally_neighbour_towns(player, target)
    if not player or not player.valid then
        log('player nil or not valid!')
        return
    end
    if not target or not target.valid then
        log('target nil or not valid!')
        return
    end
    local requesting_force = player.force
    local target_force = target.force

    if target_force.get_friend(requesting_force) and requesting_force.get_friend(target_force) then
        return
    end

    requesting_force.set_friend(target_force, true)
    game.print('>> Town ' .. requesting_force.name .. ' has set ' .. target_force.name .. ' as their friend!', { 255, 255, 0 })

    if target_force.get_friend(requesting_force) then
        game.print('>> The towns ' .. requesting_force.name .. ' and ' .. target_force.name .. ' have formed an alliance!', { 255, 255, 0 })
    end
end

local function ally_town(player, item)
    if not player or not player.valid then
        log('player nil or not valid!')
        return
    end
    local position = item.position
    local surface = player.surface
    local area = { { position.x - item_drop_radius, position.y - item_drop_radius }, { position.x + item_drop_radius, position.y + item_drop_radius } }
    local requesting_force = player.force
    local target = false

    for _, e in pairs(surface.find_entities_filtered({ type = { 'character', 'market' }, area = area })) do
        if e.force.name ~= requesting_force.name then
            target = e
            break
        end
    end

    if not target then
        return
    end
    if target.force == game.forces['enemy'] or target.force == game.forces['neutral'] then
        return
    end

    if ally_outlander(player, target) then
        return
    end
    ally_neighbour_towns(player, target)
end

local function declare_war(player, item)
    if not player or not player.valid then
        log('player nil or not valid!')
        return
    end
    local this = ScenarioTable.get_table()
    local position = item.position
    local surface = player.surface
    local area = { { position.x - item_drop_radius, position.y - item_drop_radius }, { position.x + item_drop_radius, position.y + item_drop_radius } }

    local requesting_force = player.force
    local target = surface.find_entities_filtered({ type = { 'character', 'market' }, area = area })[1]

    if not target then
        return
    end
    local target_force = target.force
    if not Public.is_towny(target_force) then
        return
    end

    if requesting_force.name == target_force.name then
        if player.name ~= target.force.name then
            Public.set_player_to_outlander(player)
            local town_center = this.town_centers[target_force.name]
            game.print('>> ' .. player.name .. ' has abandoned ' .. town_center.town_name, { 255, 255, 0 })
            this.requests[player.index] = nil
        end
        if player.name == target.force.name then
            if target.type ~= 'character' then
                return
            end
            local target_player = target.player
            if not target_player then
                return
            end
            if target_player.index == player.index then
                return
            end
            Public.set_player_to_outlander(target_player)
            local town_center = this.town_centers[player.force.name]
            game.print('>> ' .. player.name .. ' has banished ' .. target_player.name .. ' from ' .. town_center.town_name, { 255, 255, 0 })
            this.requests[player.index] = nil
        end
        return
    end

    if not Public.is_towny(requesting_force) then
        return
    end

    requesting_force.set_friend(target_force, false)
    target_force.set_friend(requesting_force, false)

    game.print('>> ' .. player.name .. ' has dropped the coal! Town ' .. target_force.name .. ' and ' .. requesting_force.name .. ' are now at war!', { 255, 255, 0 })
end

local function delete_chart_tag_for_all_forces(market)
    if not market or not market.valid then
        log('market nil or not valid!')
        return
    end
    local forces = game.forces
    local position = market.position
    local surface = market.surface
    for _, force in pairs(forces) do
        local tags = force.find_chart_tags(surface, { { position.x - 0.1, position.y - 0.1 }, { position.x + 0.1, position.y + 0.1 } })
        local tag = tags[1]
        if tag then
            if tag.icon.name == 'stone-furnace' then
                tag.destroy()
            end
        end
    end
end

function Public.add_chart_tag(town_center)
    if not town_center then
        log('town_center nil or not valid!')
        return
    end
    local market = town_center.market
    local force = market.force
    local position = market.position
    local tags = force.find_chart_tags(market.surface, { { position.x - 0.1, position.y - 0.1 }, { position.x + 0.1, position.y + 0.1 } })
    if tags[1] then
        return
    end
    force.add_chart_tag(market.surface, { icon = { type = 'item', name = 'stone-furnace' }, position = position, text = town_center.town_name })
end

function Public.update_town_chart_tags()
    local this = ScenarioTable.get_table()
    local town_centers = this.town_centers
    local forces = game.forces
    for _, town_center in pairs(town_centers) do
        local market = town_center.market
        if market ~= nil and market.valid then
            for _, force in pairs(forces) do
                if force.is_chunk_visible(market.surface, town_center.chunk_position) then
                    Public.add_chart_tag(town_center)
                end
            end
        end
    end
    local surface = game.get_surface(this.active_surface_index)
    if not surface or not surface.valid then
        return
    end
    if game.forces['player'] ~= nil then
        game.forces['player'].clear_chart(surface)
    end
    if game.forces['rogue'] ~= nil then
        game.forces['rogue'].clear_chart(surface)
    end
end

local function reset_permissions(permission_group)
    for action_name, _ in pairs(defines.input_action) do
        permission_group.set_allows_action(defines.input_action[action_name], true)
    end
end

local function enable_blueprints(permission_group)
    local defs =
    {
        defines.input_action.alt_select_blueprint_entities,
        defines.input_action.cancel_new_blueprint,
        defines.input_action.change_blueprint_record_label,
        defines.input_action.clear_selected_blueprint,
        defines.input_action.create_blueprint_like,
        defines.input_action.cycle_blueprint_backwards,
        defines.input_action.cycle_blueprint_forwards,
        defines.input_action.delete_blueprint_library,
        defines.input_action.delete_blueprint_record,
        defines.input_action.drop_blueprint_record,
        defines.input_action.drop_to_blueprint_book,
        defines.input_action.export_blueprint,
        defines.input_action.grab_blueprint_record,
        defines.input_action.import_blueprint,
        defines.input_action.import_blueprint_string,
        defines.input_action.open_blueprint_library_gui,
        defines.input_action.open_blueprint_record,
        defines.input_action.select_blueprint_entities,
        defines.input_action.setup_blueprint,
        defines.input_action.setup_single_blueprint_record,
        defines.input_action.upgrade_open_blueprint
    }
    for _, d in pairs(defs) do
        permission_group.set_allows_action(d, true)
    end
end

local function disable_blueprints(permission_group)
    local defs =
    {
        defines.input_action.alt_select_blueprint_entities,
        defines.input_action.cancel_new_blueprint,
        defines.input_action.change_blueprint_record_label,
        defines.input_action.clear_selected_blueprint,
        defines.input_action.create_blueprint_like,
        defines.input_action.cycle_blueprint_backwards,
        defines.input_action.cycle_blueprint_forwards,
        defines.input_action.delete_blueprint_library,
        defines.input_action.delete_blueprint_record,
        defines.input_action.drop_blueprint_record,
        defines.input_action.drop_to_blueprint_book,
        defines.input_action.export_blueprint,
        defines.input_action.grab_blueprint_record,
        defines.input_action.import_blueprint,
        defines.input_action.import_blueprint_string,
        defines.input_action.open_blueprint_library_gui,
        defines.input_action.open_blueprint_record,
        defines.input_action.select_blueprint_entities,
        defines.input_action.setup_blueprint,
        defines.input_action.setup_single_blueprint_record,
        defines.input_action.upgrade_open_blueprint
    }
    for _, d in pairs(defs) do
        permission_group.set_allows_action(d, false)
    end
end

local function enable_deconstruct(permission_group)
    local defs =
    {
        defines.input_action.deconstruct,
        defines.input_action.clear_selected_deconstruction_item,
        defines.input_action.cancel_deconstruct,
        defines.input_action.toggle_deconstruction_item_entity_filter_mode,
        defines.input_action.toggle_deconstruction_item_tile_filter_mode,
        defines.input_action.set_deconstruction_item_tile_selection_mode,
        defines.input_action.set_deconstruction_item_trees_and_rocks_only
    }
    for _, d in pairs(defs) do
        permission_group.set_allows_action(d, true)
    end
end

local function disable_deconstruct(permission_group)
    local defs =
    {
        defines.input_action.deconstruct,
        defines.input_action.clear_selected_deconstruction_item,
        defines.input_action.cancel_deconstruct,
        defines.input_action.toggle_deconstruction_item_entity_filter_mode,
        defines.input_action.toggle_deconstruction_item_tile_filter_mode,
        defines.input_action.set_deconstruction_item_tile_selection_mode,
        defines.input_action.set_deconstruction_item_trees_and_rocks_only
    }
    for _, d in pairs(defs) do
        permission_group.set_allows_action(d, false)
    end
end

local function disable_artillery(force, permission_group)
    permission_group.set_allows_action(defines.input_action.toggle_artillery_auto_targeting, false)
    force.technologies['artillery'].enabled = false
    force.technologies['artillery-shell-range-1'].enabled = false
    force.technologies['artillery-shell-speed-1'].enabled = false
    force.recipes['artillery-turret'].enabled = false
    force.recipes['artillery-wagon'].enabled = false
    force.recipes['artillery-shell'].enabled = false
end

local function disable_spidertron(force, permission_group)
    permission_group.set_allows_action(defines.input_action.send_spidertron, false)
    force.technologies['spidertron'].enabled = false
    force.recipes['spidertron'].enabled = false
end

local function disable_rockets(force)
    force.technologies['rocketry'].enabled = false
    force.technologies['explosive-rocketry'].enabled = false
    force.recipes['rocket-launcher'].enabled = false
    force.recipes['rocket'].enabled = false
    force.recipes['explosive-rocket'].enabled = false
end

local function disable_nukes(force)
    force.technologies['atomic-bomb'].enabled = false
    force.recipes['atomic-bomb'].enabled = false
end

local function disable_cluster_grenades(force)
    force.recipes['cluster-grenade'].enabled = false
end

local function enable_radar(surface, force)
    force.recipes['radar'].enabled = true
    force.share_chart = true
    force.clear_chart(surface.name)
end

local function disable_radar(surface, force)
    force.recipes['radar'].enabled = false
    force.share_chart = false
    force.clear_chart(surface.name)
end

local function disable_achievements(permission_group)
    permission_group.set_allows_action(defines.input_action.open_achievements_gui, false)
end

function Public.add_new_force(force_name)
    local this = ScenarioTable.get_table()

    local force = game.create_force(force_name)
    local surface = game.get_surface(this.active_surface_index)
    if not surface or not surface.valid then
        return
    end
    local permission_group = game.permissions.create_group(force_name)
    reset_permissions(permission_group)
    enable_blueprints(permission_group)
    enable_deconstruct(permission_group)
    disable_artillery(force, permission_group)
    disable_spidertron(force, permission_group)
    disable_rockets(force)
    disable_nukes(force)
    disable_cluster_grenades(force)
    enable_radar(surface, force)
    disable_achievements(permission_group)

    force.friendly_fire = true

    for _, recipe_name in pairs(all_force_enabled_recipes) do
        force.recipes[recipe_name].enabled = true
    end

    require('maps.scrap_towny_ffa.combat_balance').init_player_weapon_damage(force)
    if (this.testing_mode == true) then
        local e_force = game.forces['enemy']
        e_force.set_friend(force, true)
        e_force.set_cease_fire(force, true)
        force.enable_all_prototypes()
        force.research_all_technologies()
    end
    return force
end

function Public.reset_all_forces()
    for _, force in pairs(game.forces) do
        if force and force.valid then
            if force.name ~= 'enemy' and force.name ~= 'player' and force.name ~= 'neutral' and force.name ~= 'rogue' then
                game.merge_forces(force.name, 'player')
            end
        end
    end
    game.forces['enemy'].reset()
    game.forces['neutral'].reset()
    game.forces['player'].reset()
end

local function kill_force(force_name, cause)
    local this = ScenarioTable.get_table()
    local force = game.forces[force_name]
    local town_center = this.town_centers[force_name]
    local market = town_center.market
    local position = market.position
    local surface = market.surface
    local balance = town_center.coin_balance
    local town_name = town_center.town_name
    surface.create_entity({ name = 'big-artillery-explosion', position = position })

    local is_suicide = cause and force_name == cause.force.name

    for _, player in pairs(force.players) do
        this.spawn_point[player.index] = nil
        this.cooldowns_town_placement[player.index] = game.tick + 3600 * 5
        this.buffs[player.index] = {}
        if player.character then
            player.character.die()
        else
            this.requests[player.index] = 'kill-character'
        end
        player.force = game.forces.player
        Map.disable_world_map(player)
        Public.set_player_color(player)
        Public.give_key(player.index)
    end
    for _, e in pairs(surface.find_entities_filtered({ force = force_name })) do
        if e.valid then
            if destroy_military_types[e.type] then
                surface.create_entity({ name = 'big-artillery-explosion', position = position })
                e.die()
            elseif destroy_robot_types[e.type] then
                surface.create_entity({ name = 'explosion', position = position })
                e.die()
            elseif destroy_wall_types[e.type] then
                e.die()
            elseif storage_types[e.type] ~= true then
                local random = math_random()
                if random > 0.5 or e.health == nil then
                    e.die()
                elseif random < 0.25 then
                    e.health = e.health * math_random()
                end
            end
        end
    end
    local r = 27
    for _, e in pairs(surface.find_entities_filtered({ area = { { position.x - r, position.y - r }, { position.x + r, position.y + r } }, force = 'neutral', type = 'resource' })) do
        if e.name ~= 'crude-oil' then
            e.destroy()
        end
    end

    game.merge_forces(force_name, 'neutral')
    this.town_centers[force_name] = nil
    delete_chart_tag_for_all_forces(market)

    local message
    if is_suicide then
        message = town_name .. ' has given up'
    elseif cause == nil or not cause.valid or cause.force == nil then
        message = town_name .. ' has fallen to an unknown entity (DEBUG ID 0)!'
    elseif cause.force.name == 'player' or cause.force.name == 'rogue' then
        local items = { name = 'coin', count = balance }
        town_center.coin_balance = 0
        if balance > 0 then
            if cause.can_insert(items) then
                cause.insert(items)
            else
                local chest = surface.create_entity({ name = 'steel-chest', position = position, force = 'neutral' })
                chest.insert(items)
            end
        end
        if cause.name == 'character' then
            message = town_name .. ' has fallen to ' .. cause.player.name .. '!'
        elseif cause.force.name == 'player' then
            message = town_name .. ' has fallen to outlanders!'
        elseif cause.force.name == 'rogue' then
            message = town_name .. ' has fallen to rogues!'
        else
            message = town_name .. ' has fallen to an unknown entity (DEBUG ID 1)!'
        end
    elseif cause.force.name ~= 'enemy' then
        if this.town_centers[cause.force.name] ~= nil then
            local killer_town_center = this.town_centers[cause.force.name]
            if balance > 0 then
                killer_town_center.coin_balance = killer_town_center.coin_balance + balance
                cause.force.print(balance .. ' coins have been transferred to your town')
            end
            if cause.name == 'character' then
                message = town_name .. ' has fallen to ' .. cause.player.name .. ' from ' .. killer_town_center.town_name .. '!'
            else
                message = town_name .. ' has fallen to ' .. killer_town_center.town_name .. '!'
            end
        else
            message = town_name .. ' has fallen to an unknown entity (DEBUG ID 2)!'
            log('cause.force.name=' .. cause.force.name)
        end
    else
        message = town_name .. ' has fallen to the biters!'
    end

    Server.to_discord_embed(message)
    game.print('>> ' .. message, { 255, 255, 0 })
end

local function on_forces_merged()
    local this = ScenarioTable.get_table()
    local map_surface = game.get_surface(this.active_surface_index)
    if not map_surface or not map_surface.valid then
        return
    end

    for _, e in pairs(map_surface.find_entities_filtered({ force = 'neutral', type = 'entity-ghost' })) do
        if e.valid then
            e.destroy()
        end
    end
end

local function setup_neutral_force()
    local force = game.forces['neutral']
    force.technologies['military'].researched = true
    force.technologies['automation'].researched = true
    force.technologies['logistic-science-pack'].researched = true
    force.technologies['steel-processing'].researched = true
    force.technologies['engine'].researched = true
    force.recipes['submachine-gun'].enabled = true
    force.recipes['engine-unit'].enabled = true
    force.recipes['stone-brick'].enabled = false
    force.recipes['radar'].enabled = false
    force.recipes['lab'].enabled = false
    force.recipes['automation-science-pack'].enabled = false
    force.recipes['logistic-science-pack'].enabled = false
end

local function setup_player_force()
    local this = ScenarioTable.get_table()
    local force = game.forces.player
    local permission_group = game.permissions.create_group('outlander')

    local surface = game.get_surface(this.active_surface_index)
    if not surface or not surface.valid then
        return
    end
    reset_permissions(permission_group)
    disable_blueprints(permission_group)
    disable_deconstruct(permission_group)
    disable_artillery(force, permission_group)
    disable_spidertron(force, permission_group)
    disable_rockets(force)
    disable_nukes(force)
    disable_cluster_grenades(force)
    disable_radar(surface, force)
    disable_achievements(permission_group)

    force.friendly_fire = true

    local recipes = force.recipes
    for _, recipe_name in pairs(player_force_disabled_recipes) do
        recipes[recipe_name].enabled = false
    end
    for _, recipe_name in pairs(all_force_enabled_recipes) do
        recipes[recipe_name].enabled = true
    end
    require('maps.scrap_towny_ffa.combat_balance').init_player_weapon_damage(force)
    if (this.testing_mode == true) then
        force.enable_all_prototypes()
    end
end

local function setup_rogue_force()
    local this = ScenarioTable.get_table()
    local force = game.forces['rogue']
    if game.forces['rogue'] == nil then
        force = game.create_force('rogue')
    end
    local permission_group = game.permissions.create_group('rogue')

    local surface = game.get_surface(this.active_surface_index)
    if not surface or not surface.valid then
        return
    end
    reset_permissions(permission_group)
    disable_blueprints(permission_group)
    disable_deconstruct(permission_group)
    disable_artillery(force, permission_group)
    disable_spidertron(force, permission_group)
    disable_rockets(force)
    disable_nukes(force)
    disable_cluster_grenades(force)
    disable_radar(surface, force)
    disable_achievements(permission_group)

    force.friendly_fire = true

    local recipes = force.recipes
    for _, recipe_name in pairs(player_force_disabled_recipes) do
        recipes[recipe_name].enabled = false
    end
    for _, recipe_name in pairs(all_force_enabled_recipes) do
        recipes[recipe_name].enabled = true
    end
    require('maps.scrap_towny_ffa.combat_balance').init_player_weapon_damage(force)
    if (this.testing_mode == true) then
        force.enable_all_prototypes()
    end
end

local function setup_enemy_force()
    local this = ScenarioTable.get_table()
    local e_force = game.forces['enemy']
    local surface = game.get_surface(this.active_surface_index)
    if not surface or not surface.valid then
        return
    end
    e_force.set_evolution_factor(1, surface.name)
    e_force.set_friend(game.forces.player, true)
    e_force.set_cease_fire(game.forces.player, true)
    if (this.testing_mode == true) then
        e_force.set_friend(game.forces['rogue'], true)
        e_force.set_cease_fire(game.forces['rogue'], true)
    else

        e_force.set_friend(game.forces['rogue'], false)
        e_force.set_cease_fire(game.forces['rogue'], false)
    end
end

local function reset_forces()
    local forces = game.forces
    for name, force in pairs(forces) do
        if name ~= 'rogue' and name ~= 'player' and name ~= 'enemy' and name ~= 'neutral' then
            game.merge_forces(force, 'player')
        end
    end
end

local cease_fire_item_drop_radius = 1.5

local function set_cease_fire(player, entity)
    if not ScenarioTable.enabled('cease_fire_fish') then
        return
    end
    local position = entity.position
    local surface = player.surface
    local area = { { position.x - cease_fire_item_drop_radius, position.y - cease_fire_item_drop_radius }, { position.x + cease_fire_item_drop_radius, position.y + cease_fire_item_drop_radius } }
    local requesting_force = player.force
    local target

    for _, e in pairs(surface.find_entities_filtered({ type = { 'character', 'market' }, area = area })) do
        if e.force.name ~= requesting_force.name then
            target = e
            break
        end
    end

    if not target then
        return
    end
    local target_force = target.force
    if target_force == game.forces.enemy or target_force == game.forces.neutral then
        return
    end

    if requesting_force.get_cease_fire(target_force) then
        player.print('You already have a cease fire agreement with ' .. force_display_name(target_force), { 255, 255, 0 })
        return
    end

    requesting_force.set_cease_fire(target_force, true)
    local pm_tag = '[Private message] '
    if target_force.get_cease_fire(requesting_force) then
        requesting_force.print(pm_tag .. 'You have agreed on a mutual cease-fire with ' .. force_display_name(target_force), { 255, 255, 0 })
        target_force.print(pm_tag .. force_display_name(requesting_force) .. ' has agreed on a mutual cease-fire with you', { 255, 255, 0 })
    else
        requesting_force.print(pm_tag .. 'You have set a one-sided cease-fire with ' .. force_display_name(target_force), { 255, 255, 0 })
        target_force.print(pm_tag .. force_display_name(requesting_force) .. ' has set one-sided cease-fire with you', { 255, 255, 0 })
    end
end

local function on_player_dropped_item(event)
    local player = game.players[event.player_index]
    local entity = event.entity
    if not entity or not entity.valid or not entity.stack.valid_for_read then
        return
    end
    if entity.stack.name == 'coin' then
        ally_town(player, entity)
        return
    end
    if entity.stack.name == 'coal' then
        declare_war(player, entity)
        return
    end
    if entity.stack.name == 'raw-fish' then
        set_cease_fire(player, entity)
    end
end

local function on_entity_damaged(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end
    local cause = event.cause
    local force = event.force

    if entity.force == game.forces['enemy'] then
        if cause ~= nil then
            if cause.type == 'character' and force.index == game.forces['player'].index then
                local player = cause.player
                if player and player.valid and force.index == game.forces['player'].index then

                    set_player_to_rogue(player)
                end
            end

            if cause.type == 'car' or cause.type == 'tank' then
                local driver = cause.get_driver()
                if driver and driver.valid then

                    local player = driver
                    if driver.object_name == 'LuaEntity' then
                        player = driver.player
                    end
                    if player and player.valid and player.force.index == game.forces['player'].index then

                        set_player_to_rogue(player)
                    end
                end

                local passenger = cause.get_passenger()
                if passenger and passenger.valid then

                    local player = passenger
                    if passenger.object_name == 'LuaEntity' then
                        player = passenger.player
                    end
                    if player and player.valid and player.force.index == game.forces['player'].index then

                        set_player_to_rogue(player)

                        cause.force = game.forces['rogue']
                    end
                end
            end

            if cause.type == 'locomotive' or cause.type == 'cargo-wagon' or cause.type == 'fluid-wagon' or cause.type == 'artillery-wagon' then
                local train = cause.train
                for _, passenger in pairs(train.passengers) do
                    if passenger and passenger.valid then

                        local player = passenger
                        if passenger.object_name == 'LuaEntity' then
                            player = passenger.player
                        end
                        if player and player.valid and player.force.index == game.forces['player'].index then
                            set_player_to_rogue(player)

                            cause.force = game.forces['rogue']
                        end
                    end
                end
            end

            if cause.type == 'combat-robot' then
                local owner = cause.combat_robot_owner
                if owner and owner.valid and owner.force == game.forces['player'] then

                    set_player_to_rogue(owner)

                    cause.force = game.forces['rogue']
                end
            end
        end
    end
end

local function on_entity_died(event)
    local entity = event.entity
    local cause = event.cause
    if entity and entity.valid and entity.name == 'market' then
        kill_force(entity.force.name, cause)
    end
end

local function on_post_entity_died(event)
    local prototype = event.prototype.type
    if prototype ~= 'character' then
        return
    end
    local this = ScenarioTable.get_table()
    local surface = game.get_surface(this.active_surface_index)
    if not surface or not surface.valid then
        return
    end
    local entities = surface.find_entities_filtered({ position = event.position, radius = 1 })
    for _, e in pairs(entities) do
        if e.type == 'character-corpse' then
            Public.remove_key(e.character_corpse_player_index)
        end
    end
end

local function on_console_command(event)
    set_town_color(event)
end

local function on_console_chat(event)
    local player = game.players[event.player_index]
    if string_match(string_lower(event.message), '%[armor%=') then
        player.clear_console()
        game.print('Viewing player armor is disabled')
    end
end

function Public.initialize()
    reset_forces()
    setup_neutral_force()
    setup_player_force()
    setup_rogue_force()
    setup_enemy_force()
end

Event.add(defines.events.on_player_dropped_item, on_player_dropped_item)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_post_entity_died, on_post_entity_died)
Event.add(defines.events.on_console_command, on_console_command)
Event.add(defines.events.on_console_chat, on_console_chat)
Event.add(defines.events.on_forces_merged, on_forces_merged)

function Public.on_cease_fire_damage(event)
    if not ScenarioTable.enabled('cease_fire_fish') then
        return
    end
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end
    local damaged_force = entity.force
    local attacker_force = event.force
    if not attacker_force or not attacker_force.valid then
        return
    end

    if damaged_force.get_cease_fire(attacker_force) or attacker_force.get_cease_fire(damaged_force) then
        if damaged_force == game.forces.enemy then
            attacker_force.print('You have broken the peace with the biters. They will seek revenge!', { r = 1, g = 0, b = 0 })
        else
            attacker_force.print('You broke a cease fire agreement with ' .. force_display_name(damaged_force), { 255, 255, 0 })
        end
        damaged_force.print('A cease fire agreement with you was broken by ' .. force_display_name(attacker_force), { 255, 255, 0 })
        if attacker_force ~= game.forces.enemy then
            damaged_force.set_cease_fire(attacker_force, false)
            attacker_force.set_cease_fire(damaged_force, false)
        end
    end
end

if ScenarioTable.enabled('kick_town_member') then
    commands.add_command(
        'kick-town-member',
        'Removes a member from your town',
        function (cmd)
            local player = game.players[cmd.player_index]
            if not player or not player.valid then
                return
            end
            local param = cmd.parameter
            if not param then
                player.print('[ERROR] No player name provided', { 255, 0, 0 })
                return
            end
            local target_player = game.players[param]
            if not target_player then
                player.print('[ERROR] No player with that name was found', { 255, 0, 0 })
                return
            end
            if target_player == player then
                player.print("Can't kick yourself, drop coal on town center instead", { 255, 0, 0 })
                return
            end
            if target_player.force ~= player.force then
                player.print('Player is not in your town', { 255, 0, 0 })
                return
            end
            if string.find(target_player.force.name, target_player.name) then
                player.print("Can't kick the town founder", { 255, 0, 0 })
                return
            end
            local this = ScenarioTable.get_table()
            local town_center = this.town_centers[player.force.name]
            game.print(player.name .. ' has banished ' .. target_player.name .. ' from ' .. town_center.town_name, { 255, 255, 0 })
            Public.set_player_to_outlander(target_player)
            this.requests[player.index] = nil
        end
    )
end

function Public.on_player_joined(player)
    if ScenarioTable.mode('outlander_forces') ~= 'individual' then
        return
    end
    if player.force.name == 'player' then
        if player.online_time > 0 then
            player.print(
                "Welcome back, outlander! You've left the server for some time, "
                .. 'so your buildings have become neutral and your map and diplomacy has reset',
                { 255, 255, 0 }
            )
        end
        player.force = create_outlander_force(player)
    end
end

local function delete_old_outlander_forces()
    if ScenarioTable.mode('outlander_forces') ~= 'individual' then
        return
    end
    local current_tick = game.tick
    local cleanup_after_age = 3600 * 60
    for _, force in pairs(game.forces) do
        if Public.is_outlander(force) then
            local all_players_offline = true
            for _, force_player in pairs(force.players) do
                if current_tick - force_player.last_online < cleanup_after_age then
                    all_players_offline = false
                    break
                end
            end
            if all_players_offline then
                for _, force_player in pairs(force.players) do
                    force_player.force = 'player'
                end
                game.merge_forces(force, 'neutral')
            end
        end
    end
end

if ScenarioTable.mode('outlander_forces') == 'individual' then
    Event.on_nth_tick(3600, delete_old_outlander_forces)
end

return Public
