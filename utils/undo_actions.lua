local Server = require 'utils.server'
local Event = require 'utils.event'
local CustomEvents = require 'utils.created_events'
local Global = require 'utils.global'
local Commands = require 'utils.commands'
local Task = require 'utils.task_token'
local Discord = require 'utils.discord_handler'

local module_name = '[Undo actions] '
local undo_polls = {}
local undo_inventories = {}
local Public = {}

Global.register(
    {
        undo_polls = undo_polls,
        undo_inventories = undo_inventories
    },
    function (tbl)
        undo_polls = tbl.undo_polls
        undo_inventories = tbl.undo_inventories
    end
)

local make_entity_destructible_token =
    Task.register(
        function (event)
            local entity = event.entity
            if not entity or not entity.valid then
                return
            end

            entity.destructible = true
        end
    )

local function check_undo_queue(player)
    if not type(player) == 'userdata' then
        error('Player is not userdata.')
    end

    local undo_redo_stack = player.undo_redo_stack
    if undo_redo_stack and undo_redo_stack.get_undo_item_count() > 0 then
        return undo_redo_stack.get_undo_item_count()
    end
end

local function do_action_poll(player)
    if player and type(player) ~= 'userdata' then
        Server.output_script_data(module_name .. 'Player is not userdata. Getting player from name ' .. player)
        player = game.get_player(player)
    end

    if not player or not player.valid then
        Server.output_script_data(module_name .. 'Player is not valid. Not doing action poll.')
        return
    end

    local undo_count = check_undo_queue(player)
    if not undo_count or undo_count <= 0 then
        Server.output_script_data(module_name .. 'No undo count found for ' .. player.name .. '. Not doing action poll.')
        return
    end
    Server.output_script_data(module_name .. 'Doing action poll for ' .. player.name .. ' with undo count ' .. undo_count)
    if undo_count > 0 then
        game.print(module_name .. player.name .. ' has ' .. undo_count .. ' entities in the undo queue. Creating poll before restoring them.')
        local unique_id = player.name .. '_' .. 'undo_poll'

        Event.raise(CustomEvents.events.on_poll_created,
            {
                question = player.name .. ' removed ' .. undo_count .. ' entities before getting dealt with. Proceed with restoration?',
                answers = { 'Yes, restore the entities!', 'No, do not restore the entities!' },
                duration = 30,
                custom_data =
                {
                    unique_id = unique_id,
                    player_name = player.name,
                    surface_index = player.surface.index
                }
            })

        Server.output_script_data(module_name .. 'Poll created for ' .. player.name .. ' with id ' .. unique_id)

        undo_polls[#undo_polls + 1] =
        {
            unique_id = unique_id,
            player_index = player.index,
            player_name = player.name,
            surface_index = player.surface.index
        }
    end
end

local converted_entities =
{
    ['straight-rail'] = 'rail',
    ['curved-rail'] = 'rail',
}

local function on_pre_player_mined_item(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end
    local player_index = event.player_index
    undo_inventories[player_index] = undo_inventories[player_index] or {}
    if not entity.get_output_inventory() then return end

    local max_inv = entity.get_max_inventory_index() or 0
    for inv_id = 1, max_inv do
        local inv = entity.get_inventory(inv_id)
        if inv and inv.valid then
            local stacks = {}
            for slot = 1, #inv do
                local stack = inv[slot]
                if stack.valid_for_read then
                    stacks[#stacks + 1] = stack.export_stack()
                end
            end
            if #stacks > 0 then
                table.insert(undo_inventories[player_index], {
                    entity_name = entity.name,
                    position = { x = entity.position.x, y = entity.position.y },
                    surface_index = entity.surface.index,
                    inventory_index = inv_id,
                    stacks = stacks,
                })
            end
        end
    end
end

local function check_undo_redo_stack(player)
    if not type(player) == 'userdata' then
        error('Player is not userdata.')
    end

    local valid_undos = {}
    local restored_entities = 0
    local to_remove_items = 0

    local undo_redo_stack = player.undo_redo_stack
    if undo_redo_stack and undo_redo_stack.get_undo_item_count() > 0 then
        for i = 1, undo_redo_stack.get_undo_item_count() do
            local actions = undo_redo_stack.get_undo_item(i)

            if actions and #actions > 0 then
                valid_undos[#valid_undos + 1] = actions

                for _, action in pairs(actions) do
                    if not action.surface_index then
                        Server.output_script_data(module_name .. 'Action has no surface index. Not restoring entity.')
                        goto continue_action
                    end

                    local surface = game.get_surface(action.surface_index)
                    if not (surface and surface.valid) then
                        Server.output_script_data(module_name .. 'Invalid surface for action.')
                        goto continue_action
                    end

                    local target = action.target
                    if not (target and target.name and target.position) then
                        Server.output_script_data(module_name .. 'Invalid target data.')
                        goto continue_action
                    end

                    target.force = player.force
                    local entity = surface.create_entity(target)
                    if entity and entity.valid then
                        restored_entities = restored_entities + 1

                        local name = converted_entities[target.name]
                            or (string.find(target.name, 'curved') and 'rail')
                            or target.name

                        player.remove_item
                        {
                            name = name,
                            quality = target.quality,
                            count = 999
                        }

                        if action.insert_plan and next(action.insert_plan) then
                            for _, plan in pairs(action.insert_plan) do
                                for _, items in pairs(plan.items.in_inventory) do
                                    if entity.get_module_inventory().index == items.inventory then
                                        to_remove_items = to_remove_items + 1
                                        entity.get_module_inventory().insert
                                        {
                                            name = plan.id.name,
                                            quality = plan.id.quality,
                                            count = 1
                                        }
                                    end
                                end
                                if to_remove_items > 0 then
                                    player.remove_item
                                    {
                                        name = plan.id.name,
                                        quality = plan.id.quality,
                                        count = to_remove_items
                                    }
                                end
                            end
                        end
                    end

                    ::continue_action::
                end
            end
        end
    end

    Server.output_script_data(module_name .. 'Restored ' .. restored_entities .. ' entities for ' .. player.name)

    if #valid_undos > 0 then
        while player.undo_redo_stack.get_undo_item_count() > 0 do
            player.undo_redo_stack.remove_undo_item(player.undo_redo_stack.get_undo_item_count())
        end
    end


    local player_index = player.index
    local saved_inventories = undo_inventories[player_index]
    if saved_inventories and #saved_inventories > 0 then
        for j = 1, #saved_inventories do
            local entry = saved_inventories[j]
            local surface = game.get_surface(entry.surface_index)
            if surface and surface.valid then
                local entity = surface.find_entity(entry.entity_name, entry.position)
                if entity and entity.valid then
                    local inv = entity.get_inventory(entry.inventory_index)
                    if inv and inv.valid and entry.stacks and #entry.stacks > 0 then
                        for k = 1, #entry.stacks do
                            local stack_data = entry.stacks[k]
                            local player_has = player.get_item_count(stack_data.name)
                            if player_has > 0 then
                                local to_restore = math.min(stack_data.count or 0, player_has)
                                if to_restore > 0 then
                                    local insert_spec = {}
                                    for key, val in pairs(stack_data) do
                                        insert_spec[key] = val
                                    end
                                    insert_spec.count = to_restore
                                    local inserted = inv.insert(insert_spec)
                                    if inserted > 0 then
                                        local remove_spec = {}
                                        for key, val in pairs(stack_data) do
                                            remove_spec[key] = val
                                        end
                                        remove_spec.count = inserted
                                        player.remove_item(remove_spec)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        undo_inventories[player_index] = nil
    end
end

Event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)

Event.add(CustomEvents.events.on_poll_complete, function (event)
    if not event.winning_answer or not event.winning_answer.text then
        return
    end

    local custom_data = event.custom_data
    if not custom_data then
        Server.output_script_data(module_name .. 'Custom data is not set. Not checking undo redo stack.')
        return
    end

    local player_name = custom_data.player_name
    if not player_name then
        return
    end

    Server.output_script_data(module_name .. 'Poll complete for ' .. player_name .. ' with winning answer ' .. event.winning_answer.text)


    if not undo_polls or not next(undo_polls) then
        Server.output_script_data(module_name .. 'No undo polls found. Not checking undo redo stack.')
        return
    end

    for i = 1, #undo_polls do
        local poll_action = undo_polls[i]
        if poll_action and poll_action.unique_id == custom_data.unique_id then
            local surface = game.get_surface(poll_action.surface_index)
            if not surface or not surface.valid then
                Server.output_script_data(module_name .. 'Surface is not valid. Not checking undo redo stack.')
                return
            end
            local player = game.get_player(player_name)
            if not player or not player.valid then
                Server.output_script_data(module_name .. 'Player is not valid. Not checking undo redo stack.')
                return
            end
            if string.find(event.winning_answer.text, 'Yes') then
                check_undo_redo_stack(player)
                Server.output_script_data(module_name .. 'Undo redo stack checked for ' .. player_name)
            else
                Server.output_script_data(module_name .. 'Not restore entities. Adding all items to a chest near spawn.')
                local spawn_position = game.forces.player.get_spawn_position(surface)
                local non_collidin_position = surface.find_non_colliding_position('blue-chest', spawn_position, 10, 5)
                local e = surface.create_entity({ name = 'blue-chest', position = non_collidin_position or spawn_position, force = 'player' })
                if e and e.valid then
                    Task.set_timeout_in_ticks(1000, make_entity_destructible_token, { entity = e })
                    e.set_inventory_size_override(defines.inventory.chest, 1000)
                    game.print(module_name .. 'Adding all items have been transferred to a chest near spawn.')
                    game.print('Located here: [gps=' .. e.position.x .. ',' .. e.position.y .. ',' .. e.surface.name .. ']')
                    local main_inventory = player.get_main_inventory()
                    if main_inventory and main_inventory.valid then
                        for _, item in pairs(main_inventory.get_contents()) do
                            e.insert({ name = item.name, count = item.count })
                        end
                    end
                    player.clear_items_inside()
                end
            end
            Server.output_script_data(module_name .. 'Poll removed from undo polls for ' .. player_name)
            undo_polls[i] = nil
            break
        end
    end
end)

Event.add(CustomEvents.events.on_player_banned, function (event)
    if not event.player_name then
        return
    end
    local player = game.get_player(event.player_name)
    if not player or not player.valid then
        Server.output_script_data(module_name .. 'Player is not valid. Not checking undo redo stack.')
        return
    end

    Server.output_script_data(module_name .. 'Player event received for ' .. player.name)
    local undo_count = check_undo_queue(player)
    if not undo_count or undo_count <= 0 then
        Server.output_script_data(module_name .. 'No undo count found for ' .. player.name .. '. Not checking undo redo stack.')
        return
    end

    check_undo_redo_stack(player)
    Server.output_script_data(module_name .. 'Undo redo stack checked for ' .. player.name)
end)

Commands.new('undo_player_actions', 'Undoes the actions of a player as a player by creating a poll.')
    :add_parameter('player', false, 'player')
    :require_validation('Only utilize this command if the player is jailed and has entities in the undo queue.')
    :require_playtime(60 * 60 * 60 * 24 * 40) -- 40 days
    :callback(function (player, target_player)
        if not target_player or not target_player.valid then
            return player.print('Player is not valid.')
        end

        local undo_count = check_undo_queue(target_player)
        if not undo_count or undo_count <= 0 then
            return player.print('No undo count found for ' .. target_player.name .. '.')
        end

        do_action_poll(target_player)
        player.print('Logging your actions to discord.')
        Discord.send_notification(
            {
                title = 'Undo actions',
                description = 'Undone ' .. undo_count .. ' actions for ' .. target_player.name .. ' by ' .. player.name .. '.',
                color = 'success',
                fields =
                {
                    {
                        title = "Server",
                        description = Server.get_server_name() or 'CommandHandler',
                        inline = "false"
                    }
                }
            })
    end)

Commands.new('undo_player_actions_admin', 'Undoes the actions of a player as an admin.')
    :add_parameter('player', false, 'player')
    :require_validation('Only utilize this command if the player is jailed and has entities in the undo queue.')
    :require_admin()
    :callback(function (player, target_player)
        if not target_player or not target_player.valid then
            return player.print('Player is not valid.')
        end

        local undo_count = check_undo_queue(target_player)
        if not undo_count or undo_count <= 0 then
            return player.print('No undo count found for ' .. target_player.name .. '.')
        end

        check_undo_redo_stack(target_player)
        player.print('Logging your actions to discord.')
        player.print('Undone ' .. undo_count .. ' actions for ' .. target_player.name .. '.')
        Discord.send_notification(
            {
                title = 'Undo actions',
                description = 'Undone ' .. undo_count .. ' actions for ' .. target_player.name .. ' by ' .. player.name .. '.',
                color = 'success',
                fields =
                {
                    {
                        title = "Server",
                        description = Server.get_server_name() or 'CommandHandler',
                        inline = "false"
                    }
                }
            })
    end)

Public.check_undo_redo_stack = check_undo_redo_stack
Public.do_action_poll = do_action_poll

return Public
