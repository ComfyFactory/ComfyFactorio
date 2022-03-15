local Public = {}

local math_random = math.random
local table_size = table.size
local string_match = string.match
local string_lower = string.lower

local Server = require 'utils.server'
local Map = require 'modules.scrap_towny_ffa.map'
local Table = require 'modules.scrap_towny_ffa.table'

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
    local ffatable = Table.get_table()
    local town_centers = ffatable.town_centers
    if ffatable.member_limit == nil then
        ffatable.member_limit = 1
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
    ffatable.member_limit = member_limit

    if #force.connected_players >= member_limit then
        game.print('>> Town ' .. force.name .. ' has too many settlers! Current limit (' .. member_limit .. ')', {255, 255, 0})
        return false
    end
    return true
end

local function is_towny(force)
    if force.index == game.forces['player'].index or force.index == game.forces['rogue'].index then
        return false
    end
    return true
end

function Public.has_key(index)
    local ffatable = Table.get_table()
    if ffatable.key == nil then
        ffatable.key = {}
    end
    if ffatable.key[index] ~= nil then
        return ffatable.key[index]
    end
    return false
end

function Public.give_key(index)
    local ffatable = Table.get_table()
    if ffatable.key == nil then
        ffatable.key = {}
    end
    ffatable.key[index] = true
end

function Public.remove_key(index)
    local ffatable = Table.get_table()
    if ffatable.key == nil then
        ffatable.key = {}
    end
    ffatable.key[index] = false
end

function Public.set_player_color(player)
    local ffatable = Table.get_table()
    if player.force.index == game.forces['player'].index then
        player.color = outlander_color
        player.chat_color = outlander_chat_color
        return
    end
    if player.force.index == game.forces['rogue'].index then
        player.color = rogue_color
        player.chat_color = rogue_chat_color
        return
    end
    local town_center = ffatable.town_centers[player.force.name]
    if not town_center then
        return
    end
    player.color = town_center.color
    player.chat_color = town_center.color
end

local function set_town_color(event)
    local ffatable = Table.get_table()
    if event.command ~= 'color' then
        return
    end
    local player = game.players[event.player_index]
    local force = player.force
    local town_center = ffatable.town_centers[force.name]
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
    if player.character ~= nil then
        local character = player.character
        character.character_crafting_speed_modifier = 0.0
        character.character_mining_speed_modifier = 0.0
        character.character_inventory_slots_bonus = 0
    end
end

function Public.add_player_to_town(player, town_center)
    local ffatable = Table.get_table()
    local market = town_center.market
    local force = market.force
    local surface = market.surface
    reset_player(player)
    player.force = market.force
    Public.remove_key(player.index)
    ffatable.spawn_point[player.name] = force.get_spawn_position(surface)
    game.permissions.get_group(force.name).add_player(player)
    player.tag = ''
    Map.enable_world_map(player)
    Public.set_player_color(player)
end

-- given to player upon respawn
function Public.give_player_items(player)
    player.clear_items_inside()
    player.insert({name = 'raw-fish', count = 3})
end

function Public.set_player_to_outlander(player)
    if player == nil then
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
    if player == nil then
        return
    end
    player.force = 'rogue'
    if game.permissions.get_group('rogue') == nil then
        game.permissions.create_group('rogue')
    end
    game.permissions.get_group('rogue').add_player(player)
    player.tag = '[Rogue]'
    Map.disable_world_map(player)
    Public.set_player_color(player)
end

local function ally_outlander(player, target)
    local ffatable = Table.get_table()
    local requesting_force = player.force
    local target_force = target.force

    -- don't handle if towns not yet enabled
    if not ffatable.towns_enabled then
        player.print('You must wait for more players to join!', {255, 255, 0})
        return false
    end
    -- don't handle request if target is not a town
    if not is_towny(requesting_force) and not is_towny(target_force) then
        return false
    end

    -- don't handle request to  another town if already in a town
    if is_towny(requesting_force) and is_towny(target_force) then
        return false
    end

    -- handle the request
    if not is_towny(requesting_force) and is_towny(target_force) then
        ffatable.requests[player.index] = target_force.name

        local target_player
        if target.type == 'character' then
            target_player = target.player
        else
            target_player = game.players[target_force.name]
        end

        if target_player then
            if ffatable.requests[target_player.index] then
                if ffatable.requests[target_player.index] == player.name then
                    if ffatable.town_centers[target_force.name] then
                        if not can_force_accept_member(target_force) then
                            return true
                        end
                        game.print('>> ' .. player.name .. ' has settled in ' .. target_force.name .. "'s Town!", {255, 255, 0})
                        Public.add_player_to_town(player, ffatable.town_centers[target_force.name])
                        return true
                    end
                end
            end
        end

        game.print('>> ' .. player.name .. ' wants to settle in ' .. target_force.name .. ' Town!', {255, 255, 0})
        return true
    end

    -- handle the approval
    if is_towny(requesting_force) and not is_towny(target_force) then
        if target.type ~= 'character' then
            return true
        end
        local target_player = target.player
        if not target_player then
            return true
        end
        ffatable.requests[player.index] = target_player.name

        if ffatable.requests[target_player.index] then
            if ffatable.requests[target_player.index] == player.force.name then
                if not can_force_accept_member(player.force) then
                    return true
                end
                if player.force.name == player.name then
                    game.print('>> ' .. player.name .. ' has accepted ' .. target_player.name .. ' into their Town!', {255, 255, 0})
                else
                    game.print('>> ' .. player.name .. ' has accepted ' .. target_player.name .. ' into' .. player.force.name .. "'s Town!", {255, 255, 0})
                end
                Public.add_player_to_town(target_player, ffatable.town_centers[player.force.name])
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
    local ffatable = Table.get_table()
    local position = item.position
    local surface = player.surface
    local area = {{position.x - item_drop_radius, position.y - item_drop_radius}, {position.x + item_drop_radius, position.y + item_drop_radius}}

    local requesting_force = player.force
    local target = surface.find_entities_filtered({type = {'character', 'market'}, area = area})[1]

    if not target then
        return
    end
    local target_force = target.force
    if not is_towny(target_force) then
        return
    end

    if requesting_force.name == target_force.name then
        if player.name ~= target.force.name then
            Public.set_player_to_outlander(player)
            game.print('>> ' .. player.name .. ' has abandoned ' .. target_force.name .. "'s Town!", {255, 255, 0})
            ffatable.requests[player.index] = nil
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
            ffatable.requests[player.index] = nil
        end
        return
    end

    if not is_towny(requesting_force) then
        return
    end

    requesting_force.set_friend(target_force, false)
    target_force.set_friend(requesting_force, false)

    game.print(
        '>> ' .. player.name .. ' has dropped the coal! Town ' .. target_force.name .. ' and ' .. requesting_force.name .. ' are now at war!',
        {255, 255, 0}
    )
end

local function delete_chart_tag_for_all_forces(market)
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
    local ffatable = Table.get_table()
    local town_centers = ffatable.town_centers
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

local function enable_artillery(force, permission_group)
    permission_group.set_allows_action(defines.input_action.use_artillery_remote, true)
    force.technologies['artillery'].enabled = true
    force.technologies['artillery-shell-range-1'].enabled = true
    force.technologies['artillery-shell-speed-1'].enabled = true
    force.recipes['artillery-turret'].enabled = false
    force.recipes['artillery-wagon'].enabled = false
    force.recipes['artillery-targeting-remote'].enabled = false
    force.recipes['artillery-shell'].enabled = false
end

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
    local ffatable = Table.get_table()
    -- disable permissions
    local force = game.create_force(force_name)
    local permission_group = game.permissions.create_group(force_name)
    reset_permissions(permission_group)
    enable_blueprints(permission_group)
    enable_deconstruct(permission_group)
    enable_artillery(force, permission_group)
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
    force.research_queue_enabled = true
    -- balance initial combat
    force.set_ammo_damage_modifier('landmine', -0.75)
    force.set_ammo_damage_modifier('grenade', -0.5)
    if (ffatable.testing_mode == true) then
        local e_force = game.forces['enemy']
        e_force.set_friend(force, true) -- team force should not be attacked by turrets
        e_force.set_cease_fire(force, true) -- team force should not be attacked by units
        force.enable_all_prototypes()
        force.research_all_technologies()
    end
    return force
end

local function kill_force(force_name, cause)
    local ffatable = Table.get_table()
    local force = game.forces[force_name]
    local town_center = ffatable.town_centers[force_name]
    local market = town_center.market
    local position = market.position
    local surface = market.surface
    local balance = town_center.coin_balance
    local town_name = town_center.town_name
    surface.create_entity({name = 'big-artillery-explosion', position = position})
    for _, player in pairs(force.players) do
        ffatable.spawn_point[player.name] = nil
        ffatable.cooldowns_town_placement[player.index] = game.tick + 3600 * 15
        if player.character then
            player.character.die()
        else
            ffatable.requests[player.index] = 'kill-character'
        end
        player.force = game.forces.player
        Public.set_player_color(player)
        Public.give_key(player.index)
    end
    for _, e in pairs(surface.find_entities_filtered({force = force_name})) do
        if e.valid then
            if destroy_military_types[e.type] == true then
                surface.create_entity({name = 'big-artillery-explosion', position = position})
                e.die()
            else
                if destroy_robot_types[e.type] == true then
                    surface.create_entity({name = 'explosion', position = position})
                    e.die()
                else
                    if destroy_wall_types[e.type] == true then
                        e.die()
                    end
                end
            end
        end
    end
    for _, e in pairs(surface.find_entities_filtered({force = force_name})) do
        if e.valid then
            e.force = game.forces['neutral']
            local damage = math_random() * 2.5 - 0.5
            if damage > 0 then
                if damage >= 1 or e.health == nil then
                    e.die()
                else
                    local health = e.health
                    e.health = health * damage
                end
            end
        end
    end
    local r = 27
    for _, e in pairs(
        surface.find_entities_filtered({area = {{position.x - r, position.y - r}, {position.x + r, position.y + r}}, force = 'neutral', type = 'resource'})
    ) do
        if e.name ~= 'crude-oil' then
            e.destroy()
        end
    end

    game.merge_forces(force_name, 'neutral')
    ffatable.town_centers[force_name] = nil
    ffatable.number_of_towns = ffatable.number_of_towns - 1
    delete_chart_tag_for_all_forces(market)
    -- reward the killer
    if cause == nil or not cause.valid then
        Server.to_discord_embed(town_name .. ' has fallen!')
        game.print('>> ' .. town_name .. ' has fallen!', {255, 255, 0})
        return
    end
    if cause.force == nil then
        Server.to_discord_embed(town_name .. ' has fallen!')
        game.print('>> ' .. town_name .. ' has fallen!', {255, 255, 0})
        return
    end
    if cause.force.name == 'player' or cause.force.name == 'rogue' then
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
        if cause.force.name == 'player' then
            Server.to_discord_embed(town_name .. ' has fallen to outlanders!')
            game.print('>> ' .. town_name .. ' has fallen to outlanders!', {255, 255, 0})
        else
            Server.to_discord_embed(town_name .. ' has fallen to rogues!')
            game.print('>> ' .. town_name .. ' has fallen to rogues!', {255, 255, 0})
        end
    else
        if cause.force.name ~= 'enemy' then
            if ffatable.town_centers[cause.force.name] ~= nil then
                local killer_town_center = ffatable.town_centers[cause.force.name]
                if balance > 0 then
                    killer_town_center.coin_balance = killer_town_center.coin_balance + balance
                end
                Server.to_discord_embed(town_name .. ' has fallen to ' .. killer_town_center.town_name .. '!')
                game.print('>> ' .. town_name .. ' has fallen to ' .. killer_town_center.town_name .. '!', {255, 255, 0})
            end
        else
            Server.to_discord_embed(town_name .. ' has fallen!')
            game.print('>> ' .. town_name .. ' has fallen!', {255, 255, 0})
        end
    end
end

-- hand craftable
local player_force_disabled_recipes = {
    'lab',
    'automation-science-pack',
    'steel-furnace',
    'electric-furnace',
    'stone-wall',
    'stone-brick',
    'radar'
}
local player_force_enabled_recipes = {
    'submachine-gun',
    'assembling-machine-1',
    'small-lamp',
    'shotgun',
    'shotgun-shell',
    'underground-belt',
    'splitter',
    'steel-plate',
    'car',
    'tank',
    'engine-unit',
    'constant-combinator',
    'green-wire',
    'red-wire',
    'arithmetic-combinator',
    'decider-combinator'
}

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
    local ffatable = Table.get_table()
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
    for _, recipe_name in pairs(player_force_enabled_recipes) do
        recipes[recipe_name].enabled = true
    end
    force.set_ammo_damage_modifier('landmine', -0.75)
    force.set_ammo_damage_modifier('grenade', -0.5)
    if (ffatable.testing_mode == true) then
        force.enable_all_prototypes()
    end
end

local function setup_rogue_force()
    local ffatable = Table.get_table()
    local force_name = 'rogue'
    local force = game.create_force(force_name)
    local permission_group = game.permissions.create_group(force_name)
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
    for _, recipe_name in pairs(player_force_enabled_recipes) do
        recipes[recipe_name].enabled = true
    end
    force.set_ammo_damage_modifier('landmine', -0.75)
    force.set_ammo_damage_modifier('grenade', -0.5)
    if (ffatable.testing_mode == true) then
        force.enable_all_prototypes()
    end
end

local function setup_enemy_force()
    local ffatable = Table.get_table()
    local e_force = game.forces['enemy']
    e_force.evolution_factor = 1 -- this should never change since we are changing biter types on spawn
    e_force.set_friend(game.forces.player, true) -- outlander force (player) should not be attacked by turrets
    e_force.set_cease_fire(game.forces.player, true) -- outlander force (player) should not be attacked by units
    if (ffatable.testing_mode == true) then
        e_force.set_friend(game.forces['rogue'], true) -- rogue force (rogue) should not be attacked by turrets
        e_force.set_cease_fire(game.forces['rogue'], true) -- rogue force (rogue) should not be attacked by units
    else
        -- note, these don't prevent an outlander or rogue from attacking a unit or spawner, we need to handle separately
        e_force.set_friend(game.forces['rogue'], false) -- rogue force (rogue) should be attacked by turrets
        e_force.set_cease_fire(game.forces['rogue'], false) -- rogue force (rogue) should be attacked by units
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

---- when a player dies, reveal their base to everyone
--local function on_player_died(event)
--	local player = game.players[event.player_index]
--	if not player.character then return end
--	if not player.character.valid then return end
--	reveal_entity_to_all(player.character)
--end

local function on_entity_damaged(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    local cause = event.cause
    local force = event.force

    -- special case to handle enemies attacked by outlanders
    if entity.force == game.forces['enemy'] then
        if cause ~= nil then
            if cause.type == 'character' and force.index == game.forces['player'].index then
                local player = cause.player
                if player ~= nil and force.index == game.forces['player'].index then
                    -- set the force of the player to rogue until they die or create a town
                    set_player_to_rogue(player)
                end
            end
            -- cars and tanks
            if cause.type == 'car' or cause.type == 'tank' then
                local driver = cause.get_driver()
                if driver ~= nil and driver.type == 'character' and driver.force.index == game.forces['player'].index then
                    -- set the force of the player to rogue until they die or create a town
                    set_player_to_rogue(driver)
                end
                local passenger = cause.get_passenger()
                if passenger ~= nil and passenger.type == 'character' and passenger.force.index == game.forces['player'].index then
                    -- set the force of the player to rogue until they die or create a town
                    set_player_to_rogue(passenger)
                end
            end
            -- trains
            if cause.type == 'locomotive' or cause.type == 'cargo-wagon' or cause.type == 'fluid-wagon' or cause.type == 'artillery-wagon' then
                local train = cause.train
                for _, passenger in pairs(train.passengers) do
                    if passenger ~= nil and passenger.type == 'character' and passenger.force.index == game.forces['player'].index then
                        set_player_to_rogue(passenger)
                    end
                end
            end
            -- combat robots
            if cause.type == 'combat-robot' then
                local owner = cause.last_user
                if owner ~= nil and owner.type == 'character' and owner.force == game.forces['player]'] then
                    -- set the force of the player to rogue until they die or create a town
                    set_player_to_rogue(owner)
                end
            end
        end
    end
end

local function on_entity_died(event)
    local entity = event.entity
    local cause = event.cause
    if entity ~= nil and entity.valid and entity.name == 'market' then
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
        if string_match(event.message, player.name) then
            return
        end
        player.clear_console()
        game.print('>> ' .. player.name .. ' is trying to gain an unfair advantage!')
    end
end

function Public.initialize()
    setup_neutral_force()
    setup_player_force()
    setup_rogue_force()
    setup_enemy_force()
end

local on_init = function()
    local ffatable = Table.get_table()
    ffatable.key = {}
    ffatable.spawn_point = {}
    ffatable.requests = {}
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_player_dropped_item, on_player_dropped_item)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_post_entity_died, on_post_entity_died)
Event.add(defines.events.on_console_command, on_console_command)
Event.add(defines.events.on_console_chat, on_console_chat)

return Public
