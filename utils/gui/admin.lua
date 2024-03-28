--antigrief things made by mewmew

local Event = require 'utils.event'
local Jailed = require 'utils.datastore.jail_data'
local Gui = require 'utils.gui'
local AntiGrief = require 'utils.antigrief'
local SpamProtection = require 'utils.spam_protection'
local Color = require 'utils.color_presets'
local Server = require 'utils.server'
local Task = require 'utils.task_token'
local Token = require 'utils.token'
local Global = require 'utils.global'
local Discord = require 'utils.discord_handler'

local Public = {}

local insert = table.insert
local lower = string.lower
local ceil = math.ceil
local max = math.max
local min = math.min
local module_name = Gui.uid_name()
local next_button_name = Gui.uid_name()
local prev_button_name = Gui.uid_name()
local listable_players_name = Gui.uid_name()
local count_label_name = Gui.uid_name()
local rows_per_page = 500
local create_admin_panel

local this = {
    player_data = {}
}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local function get_player_data(player, remove)
    local data = this.player_data[player.name]
    if remove and data then
        if data and data.frame and data.frame.valid then
            data.frame.destroy()
        end

        this.player_data[player.name] = nil
        return
    end

    if not this.player_data[player.name] then
        this.player_data[player.name] = {
            selected_history_index = nil,
            filter_player = nil,
            show_all_players = nil,
            current_page = nil
        }
    end

    return this.player_data[player.name]
end

local delayed_last_page_token =
    Task.register(
    function(event)
        local player_index = event.player_index
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end

        local element = event.element
        if not element or not element.valid then
            return
        end

        local player_data = get_player_data(player)
        if not player_data or not player_data.table_count then
            return
        end
        local last_page = ceil(player_data.table_count / rows_per_page)

        player_data.current_page = last_page
        local data = {player = player, frame = element}
        create_admin_panel(data)
    end
)

local function clear_validation_action(player_name, action)
    local admin_button_validation = AntiGrief.get('admin_button_validation')
    if admin_button_validation and admin_button_validation[action] then
        admin_button_validation[action][player_name] = nil
    end
end

local clear_validation_token =
    Token.register(
    function(event)
        local action = event.action
        if not action then
            return
        end
        local player_name = event.player_name
        if not player_name then
            return
        end

        local admin_button_validation = AntiGrief.get('admin_button_validation')
        if admin_button_validation and admin_button_validation[action] then
            admin_button_validation[action][player_name] = nil
        end
    end
)

local function validate_action(player, action)
    local admin_button_validation = AntiGrief.get('admin_button_validation')
    if not admin_button_validation[action] then
        admin_button_validation[action] = {}
    end

    if not admin_button_validation[action][player.name] then
        admin_button_validation[action][player.name] = true
        Task.set_timeout_in_ticks(100, clear_validation_token, {player_name = player.name, action = action})
        player.print('Please run this again if you are certain that you want to run this action[' .. action .. '].', Color.warning)
        return true
    end
    return false
end

local function admin_only_message(str)
    for _, player in pairs(game.connected_players) do
        if player.admin == true then
            player.print('Admins-only-message: ' .. str, {r = 0.88, g = 0.88, b = 0.88})
        end
    end
end

local function jail(player, source_player)
    if validate_action(source_player, 'jail') then
        return
    end

    if player.name == source_player.name then
        player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
        clear_validation_action(source_player.name, 'jail')
        return
    end
    Jailed.try_ul_data(player.name, true, source_player.name, 'Jailed by ' .. source_player.name .. '!')
    clear_validation_action(source_player.name, 'jail')
end

local function mute(player, source_player)
    if validate_action(source_player, 'mute') then
        return
    end

    if player.name == source_player.name then
        player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
        clear_validation_action(source_player.name, 'mute')
        return
    end
    Jailed.try_ul_data(player.name, true, source_player.name, 'Jailed and muted by ' .. source_player.name .. '!', true)
    local muted = Jailed.mute_player(player)
    local muted_str = muted and 'muted' or 'unmuted'
    clear_validation_action(source_player.name, 'jail')
    game.print(player.name .. ' was ' .. muted_str .. ' by player ' .. source_player.name .. '!', {r = 1, g = 0.5, b = 0.1})
end

local function free(player, source_player)
    if validate_action(source_player, 'free') then
        return
    end

    if player.name == source_player.name then
        player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
        clear_validation_action(source_player.name, 'free')
        return
    end
    Jailed.try_ul_data(player.name, false, source_player.name)
    clear_validation_action(source_player.name, 'free')
end

local bring_player_messages = {
    'Come here my friend!',
    'Papers, please.',
    'What are you up to?'
}

local function bring_player(player, source_player)
    if validate_action(source_player, 'bring_player') then
        return
    end

    if player.name == source_player.name then
        player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
        clear_validation_action(source_player.name, 'bring_player')
        return
    end
    if player.driving == true then
        source_player.print('Target player is in a vehicle, teleport not available.', {r = 0.88, g = 0.88, b = 0.88})
        clear_validation_action(source_player.name, 'bring_player')
        return
    end
    local pos = source_player.surface.find_non_colliding_position('character', source_player.position, 50, 1)
    if pos then
        player.teleport(pos, source_player.surface)
        game.print(player.name .. ' has been teleported to ' .. source_player.name .. '. ' .. bring_player_messages[math.random(1, #bring_player_messages)], {r = 0.98, g = 0.66, b = 0.22})
        clear_validation_action(source_player.name, 'bring_player')
    end
end

local go_to_player_messages = {
    'Papers, please.',
    'What are you up to?'
}
local function go_to_player(player, source_player)
    if validate_action(source_player, 'go_to_player') then
        return
    end

    if player.name == source_player.name then
        player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
        clear_validation_action(source_player.name, 'go_to_player')
        return
    end
    local pos = player.surface.find_non_colliding_position('character', player.position, 50, 1)
    if pos then
        source_player.teleport(pos, player.surface)
        game.print(source_player.name .. ' is visiting ' .. player.name .. '. ' .. go_to_player_messages[math.random(1, #go_to_player_messages)], {r = 0.98, g = 0.66, b = 0.22})
        clear_validation_action(source_player.name, 'go_to_player')
    end
end

local function spank(player, source_player)
    if player.name == source_player.name then
        return player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
    end
    if player.character then
        if player.character.health > 1 then
            player.character.damage(1, 'player')
        end
        player.character.health = player.character.health - 5
        player.surface.create_entity({name = 'water-splash', position = player.position})
        game.print(source_player.name .. ' spanked ' .. player.name, {r = 0.98, g = 0.66, b = 0.22})
    end
end

local damage_messages = {
    ' recieved a love letter from ',
    ' recieved a strange package from '
}
local function damage(player, source_player)
    if player.name == source_player.name then
        return player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
    end
    if player.character then
        if player.character.health > 1 then
            player.character.damage(1, 'player')
        end
        player.character.health = player.character.health - 125
        player.surface.create_entity({name = 'big-explosion', position = player.position})
        game.print(player.name .. damage_messages[math.random(1, #damage_messages)] .. source_player.name, {r = 0.98, g = 0.66, b = 0.22})
    end
end

local kill_messages = {
    ' did not obey the law.',
    ' should not have triggered the admins.',
    ' did not respect authority.',
    ' had a strange accident.',
    ' was struck by lightning.'
}
local function kill(player, source_player)
    if validate_action(source_player, 'kill') then
        return
    end
    if player.name == source_player.name then
        player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
        clear_validation_action(source_player.name, 'kill')
        return
    end
    if player.character then
        player.character.die('player')
        game.print(player.name .. kill_messages[math.random(1, #kill_messages)], {r = 0.98, g = 0.66, b = 0.22})
        admin_only_message(source_player.name .. ' killed ' .. player.name)
        clear_validation_action(source_player.name, 'kill')
    end
end

local enemy_messages = {
    'Shoot on sight!',
    'Wanted dead or alive!'
}
local function enemy(player, source_player)
    if validate_action(source_player, 'enemy') then
        return
    end

    if player.name == source_player.name then
        player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
        clear_validation_action(source_player.name, 'enemy')
        return
    end
    if not game.forces.enemy_players then
        game.create_force('enemy_players')
    end
    player.force = game.forces.enemy_players
    game.print(player.name .. ' is now an enemy! ' .. enemy_messages[math.random(1, #enemy_messages)], {r = 0.95, g = 0.15, b = 0.15})
    admin_only_message(source_player.name .. ' has turned ' .. player.name .. ' into an enemy')
    clear_validation_action(source_player.name, 'enemy')
end

local function ally(player, source_player)
    if validate_action(source_player, 'ally') then
        return
    end

    if player.name == source_player.name then
        player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
        clear_validation_action(source_player.name, 'ally')
        return
    end
    player.force = game.forces.player
    game.print(player.name .. ' is our ally again!', {r = 0.98, g = 0.66, b = 0.22})
    admin_only_message(source_player.name .. ' made ' .. player.name .. ' our ally')
    clear_validation_action(source_player.name, 'ally')
end

local function turn_off_global_speakers(player)
    if validate_action(player, 'turn_off_global_speakers') then
        return
    end

    local counter = 0
    for _, surface in pairs(game.surfaces) do
        local speakers = surface.find_entities_filtered({name = 'programmable-speaker'})
        for _, speaker in pairs(speakers) do
            if speaker.parameters.playback_globally == true then
                speaker.surface.create_entity({name = 'massive-explosion', position = speaker.position})
                speaker.destroy()
                counter = counter + 1
            end
        end
    end
    if counter == 0 then
        return
    end
    if counter == 1 then
        game.print(player.name .. ' has nuked ' .. counter .. ' global speaker.', {r = 0.98, g = 0.66, b = 0.22})
    else
        game.print(player.name .. ' has nuked ' .. counter .. ' global speakers.', {r = 0.98, g = 0.66, b = 0.22})
    end
    clear_validation_action(player.name, 'turn_off_global_speakers')
end

local function delete_all_blueprints(player)
    if validate_action(player, 'delete_all_blueprints') then
        return
    end

    local counter = 0
    for _, surface in pairs(game.surfaces) do
        for _, ghost in pairs(surface.find_entities_filtered({type = {'entity-ghost', 'tile-ghost'}})) do
            ghost.destroy()
            counter = counter + 1
        end
    end
    if counter == 0 then
        clear_validation_action(player.name, 'delete_all_blueprints')
        return
    end
    if counter == 1 then
        game.print(counter .. ' blueprint has been cleared!', {r = 0.98, g = 0.66, b = 0.22})
    else
        game.print(counter .. ' blueprints have been cleared!', {r = 0.98, g = 0.66, b = 0.22})
    end
    local server_name = Server.get_server_name() or 'CommandHandler'
    Discord.send_notification_raw(server_name, player.name .. ' cleared all the blueprints on the map.')
    admin_only_message(player.name .. ' has cleared all blueprints.')
    clear_validation_action(player.name, 'delete_all_blueprints')
end

local function pause_game_tick(player)
    if validate_action(player, 'pause_game_tick') then
        return
    end

    local paused = game.tick_paused
    local paused_str = paused and 'unpaused' or 'paused'
    game.tick_paused = not paused
    game.print('Game has been ' .. paused_str .. ' by ' .. player.name, {r = 0.98, g = 0.66, b = 0.22})
    local server_name = Server.get_server_name() or 'CommandHandler'
    Discord.send_notification_raw(server_name, player.name .. ' ' .. paused_str .. ' the game.')
    clear_validation_action(player.name, 'pause_game_tick')
end

local function save_game(player)
    if validate_action(player, 'save_game') then
        return
    end

    local date = Server.get_start_time() or game.tick
    game.server_save('_currently_running' .. tostring(date) .. '_' .. player.name)
    clear_validation_action(player.name, 'save_game')
end

local function clear_items_on_ground(player)
    if validate_action(player, 'clear_items_on_ground') then
        return
    end

    local i = 0
    for _, entity in pairs(player.surface.find_entities_filtered {type = 'item-entity', name = 'item-on-ground'}) do
        if entity and entity.valid then
            entity.destroy()
            i = i + 1
        end
    end
    if i == 0 then
        return player.print('No items to clear!', Color.warning)
    end

    player.print('Cleared: ' .. i .. ' items.', Color.success)
    clear_validation_action(player.name, 'clear_items_on_ground')
end

local function create_mini_camera_gui(player, caption, position, surface)
    if player.gui.center['mini_camera'] then
        player.gui.center['mini_camera'].destroy()
    end
    local frame = player.gui.center.add({type = 'frame', name = 'mini_camera', caption = caption})
    surface = tonumber(surface)
    surface = game.surfaces[surface]
    if not surface or not surface.valid then
        return
    end

    local camera =
        frame.add(
        {
            type = 'camera',
            name = 'mini_cam_element',
            position = position,
            zoom = 0.6,
            surface_index = surface.index
        }
    )
    camera.style.minimal_width = 640
    camera.style.minimal_height = 480
end

local function filter_brackets(str)
    return (string.find(str, '%[') ~= nil)
end

local function match_test(value, pattern)
    return lower(value:gsub('-', ' ')):find(pattern)
end

local function contains_text(key, value, search_text)
    if not key then
        return false
    end
    if filter_brackets(search_text) then
        return false
    end
    if value then
        if not match_test(key[value], search_text) then
            return false
        end
    else
        if not match_test(key, search_text) then
            return false
        end
    end
    return true
end

local function search_text_locally(history, player_data, callback)
    local antigrief = AntiGrief.get()
    local history_index = {
        ['Capsule History'] = antigrief.capsule_history,
        ['Message History'] = antigrief.message_history,
        ['Friendly Fire History'] = antigrief.friendly_fire_history,
        ['Mining History'] = antigrief.mining_history,
        ['Mining Override History'] = antigrief.whitelist_mining_history,
        ['Landfill History'] = antigrief.landfill_history,
        ['Corpse Looting History'] = antigrief.corpse_history,
        ['Cancel Crafting History'] = antigrief.cancel_crafting_history,
        ['Deconstruct History'] = antigrief.deconstruct_history,
        ['Scenario History'] = antigrief.scenario_history,
        ['Whisper History'] = antigrief.whisper_history
    }

    local tooltip = 'Click to open mini camera.'
    if not player_data.current_page then
        player_data.current_page = 1
    end

    local target = game.get_player(player_data.target_player_name)
    local search_text = player_data.search_text

    local start_index = (player_data.current_page - 1) * rows_per_page + 1
    local end_index = start_index + rows_per_page - 1

    if target ~= nil then
        if not history_index or not history_index[history] or #history_index[history] <= 0 then
            return
        end

        if search_text then
            for i = end_index, start_index, -1 do
                local success = contains_text(history_index[history][i], nil, search_text)
                if success then
                    if history == 'Message History' then
                        tooltip = ''
                    end

                    callback(history_index[history][i], tooltip)
                end
            end
        else
            for i = end_index, start_index, -1 do
                if history_index[history][i] and history_index[history][i]:find(player_data.target_player_name) then
                    callback(history_index[history][i], tooltip)
                end
            end
        end
    else
        if search_text then
            for i = end_index, start_index, -1 do
                local success = contains_text(history_index[history][i], nil, search_text)
                if success then
                    callback(history_index[history][i], tooltip)
                end
            end
        else
            for i = end_index, start_index, -1 do
                callback(history_index[history][i], tooltip)
            end
        end
    end
end

local function draw_events(player_data)
    local frame = player_data.frame
    local history = frame.pagination_table.admin_history_select.items[frame.pagination_table.admin_history_select.selected_index]
    local target_player_name = frame['admin_player_select'].items[frame['admin_player_select'].selected_index]
    player_data.target_player_name = target_player_name

    local scroll_pane
    if frame.datalog then
        frame.datalog.clear()
    else
        scroll_pane =
            frame.add(
            {
                type = 'scroll-pane',
                name = 'datalog',
                direction = 'vertical',
                horizontal_scroll_policy = 'never',
                vertical_scroll_policy = 'auto'
            }
        )
        scroll_pane.style.maximal_height = 200
        scroll_pane.style.minimal_width = 790
    end

    search_text_locally(
        history,
        player_data,
        function(history_label, tooltip)
            if not history_label then
                return
            end
            frame.datalog.add(
                {
                    type = 'label',
                    caption = history_label,
                    tooltip = tooltip
                }
            )
        end
    )
end

local function text_changed(event)
    local element = event.element
    if not element then
        return
    end
    if not element.valid then
        return
    end

    local player = game.get_player(event.player_index)

    local frame = Gui.get_player_active_frame(player)
    if not frame then
        return
    end
    if frame.name ~= 'Admin' then
        return
    end

    local is_spamming = SpamProtection.is_spamming(player, nil, 'Admin Text Changed')
    if is_spamming then
        return
    end

    local player_data = get_player_data(player)
    player_data.frame = frame
    player_data.search_text = element.text:lower()

    local value = string.len(element.text)
    if value >= 1000 then
        player_data.search_text = nil
        element.text = ''
        return
    end

    if player_data.search_text == '' then
        player_data.search_text = nil
        local last_page = ceil(player_data.table_count / rows_per_page)
        player_data.current_page = last_page
        local data = {player = player, frame = frame}
        create_admin_panel(data)
        return
    end

    draw_events(player_data)
end

local function create_pagination_buttons(player_data, frame, table_count)
    if table_count == 0 then
        return
    end
    local last_page = ceil(table_count / rows_per_page)

    if not player_data.current_page then
        player_data.current_page = last_page
    end

    local current_page = player_data.current_page

    if current_page == 1 and current_page == last_page then
        return
    end

    local button_flow =
        frame.add {
        type = 'flow',
        direction = 'horizontal'
    }
    local prev_button =
        button_flow.add {
        type = 'button',
        name = prev_button_name,
        caption = '◀️',
        style = 'back_button'
    }
    prev_button.style.font = 'default-bold'
    prev_button.style.minimal_width = 32
    prev_button.tooltip = 'Previous page\nHolding [color=yellow]shift[/color] while pressing LMB/RMB will jump to the first page.'

    local count_label =
        button_flow.add {
        type = 'label',
        name = count_label_name,
        caption = current_page .. '/' .. last_page
    }
    count_label.style.font = 'default-bold'
    player_data.count_label = count_label

    local next_button =
        button_flow.add {
        type = 'button',
        name = next_button_name,
        caption = '▶️',
        style = 'forward_button'
    }
    next_button.style.font = 'default-bold'
    next_button.style.minimal_width = 32
    next_button.tooltip = 'Next page\nHolding [color=yellow]shift[/color] while pressing LMB/RMB will jump to the last page.'

    player_data.table_count = table_count
end

create_admin_panel = function(data)
    local player = data.player
    local frame = data.frame
    local antigrief = AntiGrief.get()
    if not antigrief then
        return
    end

    local player_data = get_player_data(player)

    local checkbox_state = player_data.show_all_players

    frame.clear()

    local players = game.connected_players

    if checkbox_state then
        players = game.players
    end

    local player_names = {}
    for _, p in pairs(players) do
        insert(player_names, tostring(p.name))
    end
    insert(player_names, 'Select Player')

    local selected_index = #player_names
    local selected = player_data.filter_player
    if selected then
        if player_names[selected] then
            selected_index = selected
        end
    end

    local checkbox_caption = 'Currently showing: connected players only.'
    if checkbox_state then
        checkbox_caption = 'Currently showing: all players that have played on this server.'
    end

    frame.add({type = 'checkbox', name = listable_players_name, caption = checkbox_caption, state = checkbox_state or false})

    local drop_down = frame.add({type = 'drop-down', name = 'admin_player_select', items = player_names, selected_index = selected_index})
    drop_down.style.minimal_width = 326
    drop_down.style.right_padding = 12
    drop_down.style.left_padding = 12

    local t = frame.add({type = 'table', column_count = 4})
    local buttons = {
        t.add(
            {
                type = 'button',
                caption = 'Jail',
                name = 'jail',
                tooltip = 'Jails the player, they will no longer be able to perform any actions except writing in chat.'
            }
        ),
        t.add(
            {
                type = 'button',
                caption = 'Mute',
                name = 'mute',
                tooltip = 'Jails and mutes the player, they will no longer be able to chat.'
            }
        ),
        t.add({type = 'button', caption = 'Free', name = 'free', tooltip = 'Frees the player from jail.'}),
        t.add(
            {
                type = 'button',
                caption = 'Bring Player',
                name = 'bring_player',
                tooltip = 'Teleports the selected player to your position.'
            }
        ),
        t.add(
            {
                type = 'button',
                caption = 'Make Enemy',
                name = 'enemy',
                tooltip = 'Sets the selected players force to enemy_players.\nDO NOT USE IN PVP MAPS!!'
            }
        ),
        t.add(
            {
                type = 'button',
                caption = 'Make Ally',
                name = 'ally',
                tooltip = 'Sets the selected players force back to the default player force.\nDO NOT USE IN PVP MAPS!!'
            }
        ),
        t.add(
            {
                type = 'button',
                caption = 'Go to Player',
                name = 'go_to_player',
                tooltip = 'Teleport yourself to the selected player.'
            }
        ),
        t.add(
            {
                type = 'button',
                caption = 'Spank',
                name = 'spank',
                tooltip = 'Hurts the selected player with minor damage.\nCan not kill the player.'
            }
        ),
        t.add(
            {
                type = 'button',
                caption = 'Damage',
                name = 'damage',
                tooltip = 'Damages the selected player with greater damage.\nCan not kill the player.'
            }
        ),
        t.add({type = 'button', caption = 'Kill', name = 'kill', tooltip = 'Kills the selected player instantly.'})
    }
    for _, button in pairs(buttons) do
        button.style.font = 'default-bold'
        --button.style.font_color = { r=0.99, g=0.11, b=0.11}
        button.style.minimal_width = 106
    end

    local line = frame.add {type = 'line'}
    line.style.top_margin = 8
    line.style.bottom_margin = 8

    frame.add({type = 'label', caption = 'Global Actions:'})
    local actionTable = frame.add({type = 'table', column_count = 4})
    local bottomButtons = {
        actionTable.add(
            {
                type = 'button',
                caption = 'Destroy global speakers',
                name = 'turn_off_global_speakers',
                tooltip = 'Destroys all speakers that are set to play sounds globally.'
            }
        ),
        actionTable.add(
            {
                type = 'button',
                caption = 'Delete blueprints',
                name = 'delete_all_blueprints',
                tooltip = 'Deletes all placed blueprints on the map.'
            }
        ),
        actionTable.add(
            {
                type = 'button',
                caption = 'Pause game tick',
                name = 'pause_game_tick',
                tooltip = 'Pauses the game tick.'
            }
        ),
        actionTable.add(
            {
                type = 'button',
                caption = 'Save game',
                name = 'save_game',
                tooltip = 'Saves the game.'
            }
        ),
        actionTable.add(
            {
                type = 'button',
                caption = 'Clear items on ground',
                name = 'clear_items_on_ground',
                tooltip = 'Clears all items on the ground.\nThis might lag the game!'
            }
        )
        ---	t.add({type = "button", caption = "Cancel all deconstruction orders", name = "remove_all_deconstruction_orders"})
    }
    for _, button in pairs(bottomButtons) do
        button.style.font = 'default-bold'
        button.style.minimal_width = 80
    end

    local bottomLine = frame.add {type = 'line'}
    bottomLine.style.top_margin = 8
    bottomLine.style.bottom_margin = 8

    local histories = {}
    if antigrief.capsule_history then
        insert(histories, 'Capsule History')
    end
    if antigrief.message_history then
        insert(histories, 'Message History')
    end
    if antigrief.friendly_fire_history then
        insert(histories, 'Friendly Fire History')
    end
    if antigrief.mining_history then
        insert(histories, 'Mining History')
    end
    if antigrief.whitelist_mining_history then
        insert(histories, 'Mining Override History')
    end
    if antigrief.landfill_history then
        insert(histories, 'Landfill History')
    end
    if antigrief.corpse_history then
        insert(histories, 'Corpse Looting History')
    end
    if antigrief.cancel_crafting_history then
        insert(histories, 'Cancel Crafting History')
    end
    if antigrief.deconstruct_history then
        insert(histories, 'Deconstruct History')
    end
    if antigrief.scenario_history then
        insert(histories, 'Scenario History')
    end
    if antigrief.whisper_history then
        insert(histories, 'Whisper History')
    end

    if #histories == 0 then
        return
    end

    local search_table = frame.add({type = 'table', column_count = 3})
    search_table.add({type = 'label', caption = 'Search: '})
    local search_text = search_table.add({type = 'textfield'})
    search_text.text = player_data.search_text or ''
    search_text.style.width = 140
    local btn =
        search_table.add {
        type = 'sprite-button',
        tooltip = '[color=blue]Info![/color]\nSearching does not filter the amount of pages shown.\nThis is a limitation in the Factorio engine.\nIterating over the whole table would lag the game.\nSo when searching, you will still see the same amount of pages.\nAnd the results will be "janky".',
        sprite = 'utility/questionmark'
    }
    btn.style.height = 20
    btn.style.width = 20
    btn.enabled = false
    btn.focus()

    local bottomLine2 = frame.add({type = 'label', caption = '----------------------------------------------'})
    bottomLine2.style.font = 'default-listbox'
    bottomLine2.style.font_color = {r = 0.98, g = 0.66, b = 0.22}

    local selected_index_2 = 1
    if player_data and player_data.selected_history_index then
        selected_index_2 = player_data.selected_history_index
    end

    local pagination_table = frame.add({type = 'table', column_count = 2, name = 'pagination_table'})

    local drop_down_2 = pagination_table.add({type = 'drop-down', name = 'admin_history_select', items = histories, selected_index = selected_index_2})
    drop_down_2.style.right_padding = 12
    drop_down_2.style.left_padding = 12

    local history_index = {
        ['Capsule History'] = antigrief.capsule_history,
        ['Message History'] = antigrief.message_history,
        ['Friendly Fire History'] = antigrief.friendly_fire_history,
        ['Mining History'] = antigrief.mining_history,
        ['Mining Override History'] = antigrief.whitelist_mining_history,
        ['Landfill History'] = antigrief.landfill_history,
        ['Corpse Looting History'] = antigrief.corpse_history,
        ['Cancel Crafting History'] = antigrief.cancel_crafting_history,
        ['Deconstruct History'] = antigrief.deconstruct_history,
        ['Scenario History'] = antigrief.scenario_history,
        ['Whisper History'] = antigrief.whisper_history
    }

    local history = frame.pagination_table.admin_history_select.items[frame.pagination_table.admin_history_select.selected_index]

    create_pagination_buttons(player_data, pagination_table, #history_index[history])

    player_data.frame = frame

    draw_events(player_data)
end

local create_admin_panel_token = Token.register(create_admin_panel)

local admin_functions = {
    ['jail'] = jail,
    ['mute'] = mute,
    ['free'] = free,
    ['bring_player'] = bring_player,
    ['spank'] = spank,
    ['damage'] = damage,
    ['kill'] = kill,
    ['enemy'] = enemy,
    ['ally'] = ally,
    ['go_to_player'] = go_to_player
}

local admin_global_functions = {
    ['turn_off_global_speakers'] = turn_off_global_speakers,
    ['delete_all_blueprints'] = delete_all_blueprints,
    ['pause_game_tick'] = pause_game_tick,
    ['save_game'] = save_game,
    ['clear_items_on_ground'] = clear_items_on_ground
}

local function get_surface_from_string(str)
    if not str then
        return
    end
    if str == '' then
        return
    end
    str = string.lower(str)
    local start = string.find(str, 'surface:')
    local sname = string.len(str)
    local surface = string.sub(str, start + 8, sname)
    if not surface then
        return false
    end

    return surface
end

local function get_position_from_string(str)
    if not str then
        return
    end
    if str == '' then
        return
    end
    str = string.lower(str)
    local x_pos = string.find(str, 'x:')
    local y_pos = string.find(str, 'y:')
    if not x_pos then
        return false
    end
    if not y_pos then
        return false
    end
    x_pos = x_pos + 2
    y_pos = y_pos + 2

    local a = 1
    for i = 1, string.len(str), 1 do
        local s = string.sub(str, x_pos + i, x_pos + i)
        if not s then
            break
        end
        if string.byte(s) == 32 then
            break
        end
        a = a + 1
    end
    local x = string.sub(str, x_pos, x_pos + a)

    local a1 = 1
    for i = 1, string.len(str), 1 do
        local s = string.sub(str, y_pos + i, y_pos + i)
        if not s then
            break
        end
        if string.byte(s) == 32 then
            break
        end
        a1 = a1 + 1
    end

    local y = string.sub(str, y_pos, y_pos + a1)
    x = tonumber(x)
    y = tonumber(y)
    local position = {x = x, y = y}
    return position
end

local function on_gui_click(event)
    local element = event.element
    if not element or not element.valid then
        return
    end
    local player = game.get_player(event.player_index)

    local name = event.element.name

    local frame = Gui.get_player_active_frame(player)
    if not frame then
        return
    end

    if frame.name ~= 'Admin' then
        return
    end

    if name == 'mini_camera' or name == 'mini_cam_element' then
        player.gui.center['mini_camera'].destroy()
        return
    end

    local is_spamming = SpamProtection.is_spamming(player, nil, 'Admin Gui Click')
    if is_spamming then
        return
    end

    if admin_functions[name] then
        local target_player_name = frame['admin_player_select'].items[frame['admin_player_select'].selected_index]
        if not target_player_name then
            return
        end
        if target_player_name == 'Select Player' then
            player.print('[AdminGui] No target player selected.', {r = 0.88, g = 0.88, b = 0.88})
            return
        end
        local target_player = game.players[target_player_name]
        if target_player.connected == true then
            admin_functions[name](target_player, player)
        end
        return
    end

    if admin_global_functions[name] then
        admin_global_functions[name](player)
        return
    end

    if not frame then
        return
    end
    if not element.caption then
        return
    end
    local position = get_position_from_string(element.caption)
    if not position then
        return
    end

    local surface = get_surface_from_string(element.caption)
    if not surface then
        return
    end

    if player.gui.center['mini_camera'] then
        if player.gui.center['mini_camera'].caption == element.caption then
            player.gui.center['mini_camera'].destroy()
            return
        end
    end

    create_mini_camera_gui(player, element.caption, position, surface)
end

local function on_gui_closed(event)
    local player = game.get_player(event.player_index)

    get_player_data(player, true)
end

local function on_gui_selection_state_changed(event)
    local player = game.get_player(event.player_index)
    local name = event.element.name

    if name == 'admin_history_select' then
        local player_data = get_player_data(player)
        player_data.selected_history_index = event.element.selected_index

        local frame = Gui.get_player_active_frame(player)
        if not frame then
            return
        end
        if frame.name ~= 'Admin' then
            return
        end

        Task.set_timeout_in_ticks(5, delayed_last_page_token, {player_index = player.index, element = frame})

        player_data.current_page = 1

        local is_spamming = SpamProtection.is_spamming(player, nil, 'Admin Selection Changed')
        if is_spamming then
            return
        end
        local data = {player = player, frame = frame}
        create_admin_panel(data)
    end
    if name == 'admin_player_select' then
        local player_data = get_player_data(player)
        player_data.filter_player = event.element.selected_index

        local frame = Gui.get_player_active_frame(player)
        if not frame then
            return
        end
        if frame.name ~= 'Admin' then
            return
        end

        local is_spamming = SpamProtection.is_spamming(player, nil, 'Admin Player Select')
        if is_spamming then
            return
        end

        local data = {player = player, frame = frame}
        create_admin_panel(data)
    end
end

Gui.add_tab_to_gui({name = module_name, caption = 'Admin', id = create_admin_panel_token, admin = true})

Gui.on_click(
    module_name,
    function(event)
        local player = event.player
        Gui.reload_active_tab(player)
    end
)

function Public.contains_text(history, search_text, target_player_name)
    local antigrief = AntiGrief.get()
    local history_index = {
        ['Capsule History'] = antigrief.capsule_history,
        ['Message History'] = antigrief.message_history,
        ['Friendly Fire History'] = antigrief.friendly_fire_history,
        ['Mining History'] = antigrief.mining_history,
        ['Mining Override History'] = antigrief.whitelist_mining_history,
        ['Landfill History'] = antigrief.landfill_history,
        ['Corpse Looting History'] = antigrief.corpse_history,
        ['Cancel Crafting History'] = antigrief.cancel_crafting_history,
        ['Deconstruct History'] = antigrief.deconstruct_history,
        ['Scenario History'] = antigrief.scenario_history,
        ['Whisper History'] = antigrief.whisper_history
    }

    local remote_tbl = {}

    if target_player_name and string.len(target_player_name) > 0 and game.get_player(target_player_name) ~= nil then
        if not history_index or not history_index[history] or #history_index[history] <= 0 then
            return
        end

        for i = #history_index[history], 1, -1 do
            if history_index[history][i]:find(target_player_name) then
                if search_text then
                    local success = contains_text(history_index[history][i], nil, search_text)
                    if not success then
                        goto continue
                    end
                end

                remote_tbl[#remote_tbl + 1] = history_index[history][i]

                ::continue::
            end
        end
    else
        for i = #history_index[history], 1, -1 do
            if search_text then
                local success = contains_text(history_index[history][i], nil, search_text)
                if not success then
                    goto continue
                end
            end

            remote_tbl[#remote_tbl + 1] = history_index[history][i]

            ::continue::
        end
    end

    return remote_tbl
end

Gui.on_click(
    prev_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Prev button click')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local player_data = get_player_data(player)

        local element = event.element
        if not element or not element.valid then
            return
        end

        local last_page = ceil(player_data.table_count / rows_per_page)

        if not player_data.current_page then
            player_data.current_page = last_page
        end

        local current_page = player_data.current_page

        if current_page == 1 then
            current_page = 1
            player_data.current_page = current_page
            player.print('[Admin] There are no more pages beyond this point.', Color.warning)
            return
        end

        local shift = event.shift
        if shift then
            current_page = 1
        else
            current_page = max(1, current_page - 1)
        end

        player_data.current_page = current_page

        local data = {player = player, frame = element.parent.parent.parent}
        create_admin_panel(data)
    end
)

Gui.on_click(
    next_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Next button click')
        if is_spamming then
            return
        end

        local element = event.element
        if not element or not element.valid then
            return
        end

        local player = event.player
        if not player or not player.valid then
            return
        end

        local player_data = get_player_data(player)

        local table_count = player_data.table_count
        if not table_count then
            return
        end

        local last_page = ceil(table_count / rows_per_page)
        if not player_data.current_page then
            player_data.current_page = last_page
        end

        local current_page = player_data.current_page

        if current_page == last_page then
            current_page = last_page
            player_data.current_page = current_page
            player.print('[Admin] There are no more pages beyond this point.', Color.warning)
            return
        end

        local shift = event.shift
        if shift then
            current_page = last_page
        else
            current_page = min(last_page, current_page + 1)
        end

        player_data.current_page = current_page

        local data = {player = player, frame = element.parent.parent.parent}
        create_admin_panel(data)
    end
)

Gui.on_checked_state_changed(
    listable_players_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Listable players click')
        if is_spamming then
            return
        end

        local player = event.player
        if not player or not player.valid then
            return
        end

        local player_data = get_player_data(player)

        local element = event.element
        if not element or not element.valid then
            return
        end

        player_data.show_all_players = element.state

        local data = {player = player, frame = element.parent}
        create_admin_panel(data)
    end
)

Event.add(defines.events.on_gui_text_changed, text_changed)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_gui_selection_state_changed, on_gui_selection_state_changed)
Event.add(Gui.events.on_gui_closed_main_frame, on_gui_closed)

return Public
