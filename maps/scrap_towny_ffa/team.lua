local Public = {}

local math_random = math.random
local table_size = table.size
local string_match = string.match
local string_lower = string.lower

local Server = require 'utils.server'
local Map = require 'maps.scrap_towny_ffa.map'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local PvPShield = require 'maps.scrap_towny_ffa.pvp_shield'

local outlander_color = {150, 150, 150}
local outlander_chat_color = {170, 170, 170}
local rogue_color = {150, 150, 150}
local rogue_chat_color = {170, 170, 170}
local item_drop_radius = 1.65

local destroy_wall_types = {
    ['gate'] = true,
    ['wall'] = true
}

local destroy_military_types = {
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

local destroy_robot_types = {
    ['combat-robot'] = true,
    ['construction-robot'] = true,
    ['logistic-robot'] = true
}

local storage_types = {
    ['container'] = true,
    ['logistic-container'] = true,
    ['storage-tank'] = true
}

local player_force_disabled_recipes = {
    'lab',
    'automation-science-pack',
    'stone-brick',
    'radar'
}
local all_force_enabled_recipes = {
    'submachine-gun',
    'small-lamp',
    'shotgun',
    'shotgun-shell',
    'underground-belt',
    'splitter',
}

local function min_slots(slots)
    local min = 0
    for i = 1, 3, 1 do
        if slots[i] > min then
            min = slots[i]
        end
    end
    return min
end

local function can_force_accept_member(force)
    if not force or not force.valid then
        log('force nil or not valid!')
        return
    end
    local this = ScenarioTable.get_table()
    local town_centers = this.town_centers
    if this.member_limit == nil then
        this.member_limit = 1
    end

    -- get the members of each force name into a table
    local slots = {0, 0, 0}
    for _, town_center in pairs(town_centers) do
        local players = table_size(town_center.market.force.players)
        -- get min value for all slots
        local min = min_slots(slots)
        -- if our value greater than min of all three replace that slot
        if players > min then
            for i = 1, 3, 1 do
                if slots[i] == min then
                    slots[i] = players
                    break
                end
            end
        end
    end
    -- get the min of all slots
    local member_limit = min_slots(slots) + 1
    this.member_limit = member_limit

    if #force.connected_players >= member_limit then
        game.print('>> Town ' .. force.name .. ' has too many settlers! Current limit (' .. member_limit .. ')', {255, 255, 0})
        return false
    end
    return true
end

function Public.is_rogue(force)
    return force.name == 'rogue'
end

function Public.is_outlander(force)
    return force.name == 'player'
end

function Public.is_towny(force)
    return force.name ~= 'rogue' and force.name ~= 'player'
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
    town_center.color = {player.color.r, player.color.g, player.color.b}
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
end

-- given to player upon respawn
function Public.give_player_items(player)
    if not player or not player.valid then
        log('player nil or not valid!')
        return
    end
    player.clear_items_inside()
    player.insert({name = 'raw-fish', count = 3})
    if player.force.name == 'rogue' or player.force.name == 'player' then
        player.insert {name = 'stone-furnace', count = '1'}
    end
end

function Public.set_player_to_outlander(player)
    if not player or not player.valid then
        log('player nil or not valid!')
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
end

local function set_player_to_rogue(player)
    if not player or not player.valid then
        log('player nil or not valid!')
        return
    end

    player.print("You have broken the peace with the biters. They will seek revenge!")
    player.force = 'rogue'
    local group = game.permissions.get_group('rogue')
    if group == nil then
        group = game.permissions.create_group('rogue')
    end

    if not player.object_name == 'LuaPlayer' then
        log('Given object is not of LuaPlayer!')
        return
    end
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

    -- don't handle if towns not yet enabled
    if not this.towns_enabled then
        player.print('You must wait for more players to join!', {255, 255, 0})
        return false
    end
    -- don't handle request if target is not a town
    if not Public.is_towny(requesting_force) and not Public.is_towny(target_force) then
        return false
    end

    -- don't handle request to  another town if already in a town
    if Public.is_towny(requesting_force) and Public.is_towny(target_force) then
        return false
    end

    -- handle the request
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
                    if this.town_centers[target_force.name] then
                        if not can_force_accept_member(target_force) then
                            return true
                        end
                        game.print('>> ' .. player.name .. ' has settled in ' .. target_force.name .. "'s Town!", {255, 255, 0})
                        Public.add_player_to_town(player, this.town_centers[target_force.name])
                        return true
                    end
                end
            end
        end

        game.print('>> ' .. player.name .. ' wants to settle in ' .. target_force.name .. ' Town!', {255, 255, 0})
        return true
    end

    -- handle the approval
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
                if not can_force_accept_member(player.force) then
                    return true
                end
                if player.force.name == player.name then
                    game.print('>> ' .. player.name .. ' has accepted ' .. target_player.name .. ' into their Town!', {255, 255, 0})
                else
                    game.print('>> ' .. player.name .. ' has accepted ' .. target_player.name .. ' into' .. player.force.name .. "'s Town!", {255, 255, 0})
                end
                Public.add_player_to_town(target_player, this.town_centers[player.force.name])
                return true
            end
        end

        if player.force.name == player.name then
            game.print('>> ' .. player.name .. ' is inviting ' .. target_player.name .. ' into their Town!', {255, 255, 0})
        else
            game.print('>> ' .. player.name .. ' is inviting ' .. target_player.name .. ' into ' .. player.force.name .. "'s Town!", {255, 255, 0})
        end
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
    game.print('>> Town ' .. requesting_force.name .. ' has set ' .. target_force.name .. ' as their friend!', {255, 255, 0})

    if target_force.get_friend(requesting_force) then
        game.print('>> The towns ' .. requesting_force.name .. ' and ' .. target_force.name .. ' have formed an alliance!', {255, 255, 0})
    end
end

local function ally_town(player, item)
    if not player or not player.valid then
        log('player nil or not valid!')
        return
    end
    local position = item.position
    local surface = player.surface
    local area = {{position.x - item_drop_radius, position.y - item_drop_radius}, {position.x + item_drop_radius, position.y + item_drop_radius}}
    local requesting_force = player.force
    local target = false

    for _, e in pairs(surface.find_entities_filtered({type = {'character', 'market'}, area = area})) do
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
    local area = {{position.x - item_drop_radius, position.y - item_drop_radius}, {position.x + item_drop_radius, position.y + item_drop_radius}}

    local requesting_force = player.force
    local target = surface.find_entities_filtered({type = {'character', 'market'}, area = area})[1]

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
            game.print('>> ' .. player.name .. ' has abandoned ' .. target_force.name .. "'s Town!", {255, 255, 0})
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
            game.print('>> ' .. player.name .. ' has banished ' .. target_player.name .. ' from their Town!', {255, 255, 0})
            this.requests[player.index] = nil
        end
        return
    end

    if not Public.is_towny(requesting_force) then
        return
    end

    requesting_force.set_friend(target_force, false)
    target_force.set_friend(requesting_force, false)

    game.print('>> ' .. player.name .. ' has dropped the coal! Town ' .. target_force.name .. ' and ' .. requesting_force.name .. ' are now at war!', {255, 255, 0})
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
        local tags = force.find_chart_tags(surface, {{position.x - 0.1, position.y - 0.1}, {position.x + 0.1, position.y + 0.1}})
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
    local tags = force.find_chart_tags(market.surface, {{position.x - 0.1, position.y - 0.1}, {position.x + 0.1, position.y + 0.1}})
    if tags[1] then
        return
    end
    force.add_chart_tag(market.surface, {icon = {type = 'item', name = 'stone-furnace'}, position = position, text = town_center.town_name})
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
    if game.forces['player'] ~= nil then
        game.forces['player'].clear_chart(game.surfaces['nauvis'])
    end
    if game.forces['rogue'] ~= nil then
        game.forces['rogue'].clear_chart(game.surfaces['nauvis'])
    end
end

local function reset_permissions(permission_group)
    for action_name, _ in pairs(defines.input_action) do
        permission_group.set_allows_action(defines.input_action[action_name], true)
    end
end

local function enable_blueprints(permission_group)
    local defs = {
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
    local defs = {
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
    local defs = {
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
    local defs = {
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

--local function enable_artillery(force, permission_group)
--    permission_group.set_allows_action(defines.input_action.use_artillery_remote, true)
--    force.technologies['artillery'].enabled = true
--    force.technologies['artillery-shell-range-1'].enabled = true
--    force.technologies['artillery-shell-speed-1'].enabled = true
--    force.recipes['artillery-turret'].enabled = false
--    force.recipes['artillery-wagon'].enabled = false
--    force.recipes['artillery-targeting-remote'].enabled = false
--    force.recipes['artillery-shell'].enabled = false
--end

local function disable_artillery(force, permission_group)
    permission_group.set_allows_action(defines.input_action.use_artillery_remote, false)
    force.technologies['artillery'].enabled = false
    force.technologies['artillery-shell-range-1'].enabled = false
    force.technologies['artillery-shell-speed-1'].enabled = false
    force.recipes['artillery-turret'].enabled = false
    force.recipes['artillery-wagon'].enabled = false
    force.recipes['artillery-targeting-remote'].enabled = false
    force.recipes['artillery-shell'].enabled = false
end

local function disable_spidertron(force, permission_group)
    permission_group.set_allows_action(defines.input_action.send_spidertron, false)
    force.technologies['spidertron'].enabled = false
    force.recipes['spidertron'].enabled = false
    force.recipes['spidertron-remote'].enabled = false
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

local function enable_radar(force)
    force.recipes['radar'].enabled = true
    force.share_chart = true
    force.clear_chart('nauvis')
end

local function disable_radar(force)
    force.recipes['radar'].enabled = false
    force.share_chart = false
    force.clear_chart('nauvis')
end

local function disable_achievements(permission_group)
    permission_group.set_allows_action(defines.input_action.open_achievements_gui, false)
end

local function disable_tips_and_tricks(permission_group)
    permission_group.set_allows_action(defines.input_action.open_tips_and_tricks_gui, false)
end

-- setup a team force
function Public.add_new_force(force_name)
    local this = ScenarioTable.get_table()
    -- disable permissions
    local force = game.create_force(force_name)
    local permission_group = game.permissions.create_group(force_name)
    reset_permissions(permission_group)
    enable_blueprints(permission_group)
    enable_deconstruct(permission_group)
    disable_artillery(force, permission_group)
    disable_spidertron(force, permission_group)
    disable_rockets(force)
    disable_nukes(force)
    disable_cluster_grenades(force)
    enable_radar(force)
    disable_achievements(permission_group)
    disable_tips_and_tricks(permission_group)
    -- friendly fire
    force.friendly_fire = true
    -- disable technologies
    for _, recipe_name in pairs(all_force_enabled_recipes) do
        force.recipes[recipe_name].enabled = true
    end
    force.research_queue_enabled = true
    -- balance initial combat
    force.set_ammo_damage_modifier('landmine', -0.75)
    force.set_ammo_damage_modifier('grenade', -0.5)
    if (this.testing_mode == true) then
        local e_force = game.forces['enemy']
        e_force.set_friend(force, true) -- team force should not be attacked by turrets
        e_force.set_cease_fire(force, true) -- team force should not be attacked by units
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
    surface.create_entity({name = 'big-artillery-explosion', position = position})

    local is_suicide = force_name == cause.force.name

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
    for _, e in pairs(surface.find_entities_filtered({force = force_name})) do
        if e.valid then
            if destroy_military_types[e.type] == true then
                surface.create_entity({name = 'big-artillery-explosion', position = position})
                e.die()
            elseif destroy_robot_types[e.type] == true then
                surface.create_entity({name = 'explosion', position = position})
                e.die()
            elseif destroy_wall_types[e.type] == true then
                e.die()
            elseif storage_types[e.type] ~= true then   -- spare chests
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
    for _, e in pairs(surface.find_entities_filtered({area = {{position.x - r, position.y - r}, {position.x + r, position.y + r}}, force = 'neutral', type = 'resource'})) do
        if e.name ~= 'crude-oil' then
            e.destroy()
        end
    end
    if this.pvp_shields[force_name] then
        PvPShield.remove_shield(this.pvp_shields[force_name])
    end

    game.merge_forces(force_name, 'neutral')
    this.town_centers[force_name] = nil
    delete_chart_tag_for_all_forces(market)

    -- reward the killer
    local message
    if is_suicide then
        message = town_name .. ' has given up'
    elseif cause == nil or not cause.valid or cause.force == nil then
        message = town_name .. ' has fallen to an unknown entity (FIXME ID0)!' -- TODO: remove after some testing
    elseif cause.force.name == 'player' or cause.force.name == 'rogue' then
        local items = {name = 'coin', count = balance}
        town_center.coin_balance = 0
        if balance > 0 then
            if cause.can_insert(items) then
                cause.insert(items)
            else
                local chest = surface.create_entity({name = 'steel-chest', position = position, force = 'neutral'})
                chest.insert(items)
            end
        end
        if cause.player then
            message = town_name .. ' has fallen to ' .. cause.player.name .. '!'
        elseif cause.force.name == 'player' then
            message = town_name .. ' has fallen to outlanders!'
        elseif cause.force.name == 'rogue' then
            message = town_name .. ' has fallen to rogues!'
        else
            message = town_name .. ' has fallen to an unknown entity (FIXME ID1)!' -- TODO: remove after some testing
        end
    elseif cause.force.name ~= 'enemy' then
        if this.town_centers[cause.force.name] ~= nil then
            local killer_town_center = this.town_centers[cause.force.name]
            if balance > 0 then
                killer_town_center.coin_balance = killer_town_center.coin_balance + balance
                cause.force.print(balance .. " coins have been transferred to your town")
            end
            if cause.player then
                message = town_name .. ' has fallen to ' .. cause.player.name .. ' from '  .. killer_town_center.town_name .. '!'
            else
                message = town_name .. ' has fallen to ' .. killer_town_center.town_name .. '!'
            end
        else
            message = town_name .. ' has fallen to an unknown entity (FIXME ID2)!' -- TODO: remove after some testing
        end
    else
        message = town_name .. ' has fallen to the biters!'
    end

    Server.to_discord_embed(message)
    game.print('>> ' .. message, {255, 255, 0})
end

local function on_forces_merged()
    -- Remove any ghosts that have been moved into neutral after a town is destroyed. This caused desyncs before.
    for _, e in pairs(game.surfaces.nauvis.find_entities_filtered({force = 'neutral', type = "entity-ghost"})) do
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

-- setup the player force (this is the default for Outlanders)
local function setup_player_force()
    local this = ScenarioTable.get_table()
    local force = game.forces.player
    local permission_group = game.permissions.create_group('outlander')
    -- disable permissions
    reset_permissions(permission_group)
    disable_blueprints(permission_group)
    disable_deconstruct(permission_group)
    disable_artillery(force, permission_group)
    disable_spidertron(force, permission_group)
    disable_rockets(force)
    disable_nukes(force)
    disable_cluster_grenades(force)
    disable_radar(force)
    disable_achievements(permission_group)
    disable_tips_and_tricks(permission_group)
    -- disable research
    force.disable_research()
    force.research_queue_enabled = false
    -- friendly fire
    force.friendly_fire = true
    -- disable recipes
    local recipes = force.recipes
    for _, recipe_name in pairs(player_force_disabled_recipes) do
        recipes[recipe_name].enabled = false
    end
    for _, recipe_name in pairs(all_force_enabled_recipes) do
        recipes[recipe_name].enabled = true
    end
    force.set_ammo_damage_modifier('landmine', -0.75)
    force.set_ammo_damage_modifier('grenade', -0.5)
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
    -- disable permissions
    reset_permissions(permission_group)
    disable_blueprints(permission_group)
    disable_deconstruct(permission_group)
    disable_artillery(force, permission_group)
    disable_spidertron(force, permission_group)
    disable_rockets(force)
    disable_nukes(force)
    disable_cluster_grenades(force)
    disable_radar(force)
    disable_achievements(permission_group)
    disable_tips_and_tricks(permission_group)
    -- disable research
    force.disable_research()
    force.research_queue_enabled = false
    -- friendly fire
    force.friendly_fire = true
    -- disable recipes
    local recipes = force.recipes
    for _, recipe_name in pairs(player_force_disabled_recipes) do
        recipes[recipe_name].enabled = false
    end
    for _, recipe_name in pairs(all_force_enabled_recipes) do
        recipes[recipe_name].enabled = true
    end
    force.set_ammo_damage_modifier('landmine', -0.75)
    force.set_ammo_damage_modifier('grenade', -0.5)
    if (this.testing_mode == true) then
        force.enable_all_prototypes()
    end
end

local function setup_enemy_force()
    local this = ScenarioTable.get_table()
    local e_force = game.forces['enemy']
    e_force.evolution_factor = 1 -- this should never change since we are changing biter types on spawn
    e_force.set_friend(game.forces.player, true) -- outlander force (player) should not be attacked by turrets
    e_force.set_cease_fire(game.forces.player, true) -- outlander force (player) should not be attacked by units
    if (this.testing_mode == true) then
        e_force.set_friend(game.forces['rogue'], true) -- rogue force (rogue) should not be attacked by turrets
        e_force.set_cease_fire(game.forces['rogue'], true) -- rogue force (rogue) should not be attacked by units
    else
        -- note, these don't prevent an outlander or rogue from attacking a unit or spawner, we need to handle separately
        e_force.set_friend(game.forces['rogue'], false) -- rogue force (rogue) should be attacked by turrets
        e_force.set_cease_fire(game.forces['rogue'], false) -- rogue force (rogue) should be attacked by units
    end
end

local function reset_forces()
    local players = game.players
    local forces = game.forces
    for i = 1, #players do
        local player = players[i]
        local force = forces[player.name]
        if force then
            game.merge_forces(force, 'player')
        end
    end
end

local function on_player_dropped_item(event)
    local player = game.players[event.player_index]
    local entity = event.entity
    if entity.stack.name == 'coin' then
        ally_town(player, entity)
        return
    end
    if entity.stack.name == 'coal' then
        declare_war(player, entity)
        return
    end
end

local function on_entity_damaged(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end
    local cause = event.cause
    local force = event.force

    -- special case to handle enemies attacked by outlanders
    if entity.force == game.forces['enemy'] then
        if cause ~= nil then
            if cause.type == 'character' and force.index == game.forces['player'].index then
                local player = cause.player
                if player and player.valid and force.index == game.forces['player'].index then
                    -- set the force of the player to rogue until they die or create a town
                    set_player_to_rogue(player)
                end
            end
            -- cars and tanks
            if cause.type == 'car' or cause.type == 'tank' then
                local driver = cause.get_driver()
                if driver and driver.valid then
                    -- driver may be LuaEntity or LuaPlayer
                    local player = driver
                    if driver.object_name == 'LuaEntity' then
                        player = driver.player
                    end
                    if player and player.valid and player.force.index == game.forces['player'].index then
                        -- set the force of the player to rogue until they die or create a town
                        set_player_to_rogue(player)
                    end
                end

                local passenger = cause.get_passenger()
                if passenger and passenger.valid then
                    -- passenger may be LuaEntity or LuaPlayer
                    local player = passenger
                    if passenger.object_name == 'LuaEntity' then
                        player = passenger.player
                    end
                    if player and player.valid and player.force.index == game.forces['player'].index then
                        -- set the force of the player to rogue until they die or create a town
                        set_player_to_rogue(player)
                        -- set the vehicle to rogue
                        cause.force = game.forces['rogue']
                    end
                end
            end
            -- trains
            if cause.type == 'locomotive' or cause.type == 'cargo-wagon' or cause.type == 'fluid-wagon' or cause.type == 'artillery-wagon' then
                local train = cause.train
                for _, passenger in pairs(train.passengers) do
                    if passenger and passenger.valid then
                        -- passenger may be LuaEntity or LuaPlayer
                        local player = passenger
                        if passenger.object_name == 'LuaEntity' then
                            player = passenger.player
                        end
                        if player and player.valid and player.force.index == game.forces['player'].index then
                            set_player_to_rogue(player)
                            -- set the vehicle to rogue
                            cause.force = game.forces['rogue']
                        end
                    end
                end
            end
            -- combat robots
            if cause.type == 'combat-robot' then
                local owner = cause.combat_robot_owner
                if owner and owner.valid and owner.force == game.forces['player'] then
                    -- set the force of the player to rogue until they die or create a town
                    set_player_to_rogue(owner)
                    -- set the robot to rogue
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
    local entities = game.surfaces[event.surface_index].find_entities_filtered({position = event.position, radius = 1})
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

local Event = require 'utils.event'
Event.add(defines.events.on_player_dropped_item, on_player_dropped_item)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_post_entity_died, on_post_entity_died)
Event.add(defines.events.on_console_command, on_console_command)
Event.add(defines.events.on_console_chat, on_console_chat)
Event.add(defines.events.on_forces_merged, on_forces_merged)
return Public
