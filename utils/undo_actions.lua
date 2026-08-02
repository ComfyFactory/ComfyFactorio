local Server = require 'utils.server'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Commands = require 'utils.commands'
local Task = require 'utils.task_token'
local Discord = require 'utils.discord_handler'
local module_name = '[Undo actions] '
local undo_polls = {}
local Public = {}

Global.register(
    {
        undo_polls = undo_polls
    },
    function (tbl)
        undo_polls = tbl.undo_polls
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

local converted_entities =
{
    ['legacy-straight-rail'] = 'rail',
    ['legacy-curved-rail'] = 'rail',
    ['half-diagonal-rail'] = 'rail',
    ['straight-rail'] = 'rail',
    ['curved-rail'] = 'rail'
}

local ignored_entity_types =
{
    ['simple-entity'] = true,
    ['simple-entity-with-owner'] = true,
    ['tree'] = true
}

---@param player LuaPlayer
---@return number
local function check_undo_queue(player)
    if type(player) ~= "userdata" then
        error("Player is not userdata.")
    end
    if not player.valid then
        return 0
    end
    local undo_redo_stack = player.undo_redo_stack
    if not undo_redo_stack then
        return 0
    end
    local undo_item_count = undo_redo_stack.get_undo_item_count()
    if undo_item_count <= 0 then
        return 0
    end
    local restorable_actions = 0
    for i = 1, undo_item_count do
        local actions = undo_redo_stack.get_undo_item(i)
        if actions and # actions > 0 then
            for _, action in pairs(actions) do
                if action.type == "removed-entity" and action.surface_index and action.target and action.target.name and action.target.position then
                    restorable_actions = restorable_actions + 1
                end
            end
        end
    end
    return restorable_actions
end

local function do_action_poll(player)
    if player and type(player) ~= "userdata" then
        Server.output_script_data(
            module_name .. "Player is not userdata. Getting player from name " .. tostring(player))
        player = game.get_player(player)
    end
    if not player or not player.valid then
        Server.output_script_data(module_name .. "Player is not valid. Not doing action poll.")
        return
    end
    local undo_count = check_undo_queue(player)
    if not undo_count or undo_count <= 0 then
        Server.output_script_data(
            module_name .. "No restorable undo actions found for " .. player.name .. ". Not doing action poll.")
        return
    end
    local unique_id = player.name .. "_undo_poll"
    for _, poll_action in pairs(undo_polls) do
        if poll_action and poll_action.unique_id == unique_id then
            Server.output_script_data(module_name .. "Undo poll already exists for " .. player.name .. ".")
            return
        end
    end
    Server.output_script_data(
        module_name .. "Doing action poll for " .. player.name .. " with " .. undo_count .. " restorable removed entities.")
    game.print(
        module_name .. player.name .. " has " .. undo_count .. " removed entities in the undo queue. Creating poll before restoring them.")
    Event.raise(
        ServerCommands.events.on_poll_created,
        {
            question = player.name .. " removed " .. undo_count .. " entities before getting dealt with. Proceed with restoration?",
            answers =
            {
                "Yes, restore the entities!",
                "No, do not restore the entities!"
            },
            duration = 30,
            custom_data =
            {
                unique_id = unique_id,
                player_name = player.name,
                surface_index = player.surface.index
            }
        })
    Server.output_script_data(module_name .. "Poll created for " .. player.name .. " with id " .. unique_id)
    undo_polls[# undo_polls + 1] =
    {
        unique_id = unique_id,
        player_index = player.index,
        player_name = player.name,
        surface_index = player.surface.index
    }
end

---@param surface LuaSurface
---@param target table
---@return boolean
local function entity_already_exists(surface, target)
    local entities = surface.find_entities_filtered(
        {
            position = target.position,
            name = target.name
        }
    )

    if not entities then
        return false
    end

    for _, entity in pairs(entities) do
        if entity and entity.valid then
            return true
        end
    end

    return false
end

---@param player LuaPlayer
---@param entity LuaEntity
---@param insert_plan table
local function restore_insert_plan(player, entity, insert_plan)
    if not insert_plan or not next(insert_plan) then
        return
    end
    local module_inventory = entity.get_module_inventory()
    if not module_inventory or not module_inventory.valid then
        return
    end
    for _, plan in pairs(insert_plan) do
        if plan and plan.id and plan.id.name and plan.items then
            local inserted_count = 0
            if plan.items.in_inventory then
                for _, item in pairs(plan.items.in_inventory) do
                    if item.inventory == module_inventory.index then
                        local inserted = module_inventory.insert(
                            {
                                name = plan.id.name,
                                quality = plan.id.quality,
                                count = 1
                            })
                        inserted_count = inserted_count + inserted
                    end
                end
            end
            if inserted_count > 0 then
                player.remove_item(
                    {
                        name = plan.id.name,
                        quality = plan.id.quality,
                        count = inserted_count
                    })
            end
        end
    end
end

---@param player LuaPlayer
local function check_undo_redo_stack(player)
    if type(player) ~= "userdata" then
        error("Player is not userdata.")
    end
    if not player.valid then
        return
    end
    local undo_redo_stack = player.undo_redo_stack
    if not undo_redo_stack then
        Server.output_script_data(module_name .. "No undo redo stack found for " .. player.name)
        return
    end
    local undo_item_count = undo_redo_stack.get_undo_item_count()
    if undo_item_count <= 0 then
        Server.output_script_data(module_name .. "Undo redo stack is empty for " .. player.name)
        return
    end
    local restored_entities = 0
    local skipped_actions = 0
    local skipped_existing = 0
    local failed_entities = 0
    for i = 1, undo_item_count do
        local actions = undo_redo_stack.get_undo_item(i)
        if actions and # actions > 0 then
            for _, action in pairs(actions) do
                if action.type ~= "removed-entity" then
                    skipped_actions = skipped_actions + 1
                    goto continue_action
                end
                if not action.surface_index then
                    Server.output_script_data(module_name .. "Removed entity action has no surface index. Skipping.")
                    skipped_actions = skipped_actions + 1
                    goto continue_action
                end
                local target = action.target
                if not (target and target.name and target.position) then
                    Server.output_script_data(module_name .. "Removed entity action has invalid target data. Skipping.")
                    skipped_actions = skipped_actions + 1
                    goto continue_action
                end
                local prototype = prototypes.entity[target.name]
                if not prototype then
                    Server.output_script_data(
                        module_name .. "Entity prototype does not exist: " .. tostring(target.name))
                    skipped_actions = skipped_actions + 1
                    goto continue_action
                end
                if ignored_entity_types[prototype.type] then
                    skipped_actions = skipped_actions + 1
                    goto continue_action
                end
                local surface = game.get_surface(action.surface_index)
                if not surface or not surface.valid then
                    Server.output_script_data(module_name .. "Invalid surface for removed entity action.")
                    skipped_actions = skipped_actions + 1
                    goto continue_action
                end
                if entity_already_exists(surface, target) then
                    Server.output_script_data(
                        module_name .. "Entity already exists at position for " .. target.name .. ". Skipping duplicate restoration.")
                    skipped_existing = skipped_existing + 1
                    goto continue_action
                end
                target.force = player.force
                local entity = surface.create_entity(target)
                if not entity or not entity.valid then
                    Server.output_script_data(
                        module_name .. "Failed restoring entity " .. target.name .. " at [gps=" .. target.position.x .. "," .. target.position.y .. "," .. surface.name .. "]")
                    failed_entities = failed_entities + 1
                    goto continue_action
                end
                restored_entities = restored_entities + 1
                local item_name = converted_entities[target.name] or (string.find(target.name, "curved") and "rail") or target.name
                player.remove_item(
                    {
                        name = item_name,
                        quality = target.quality,
                        count = 999
                    })
                if action.insert_plan and next(action.insert_plan) then
                    restore_insert_plan(player, entity, action.insert_plan)
                end
                ::continue_action::
            end
        end
    end
    Server.output_script_data(module_name .. "Restore finished for " .. player.name .. ". Restored: " .. restored_entities .. ", skipped non-restorable/invalid: " .. skipped_actions .. ", skipped existing: " .. skipped_existing .. ", failed: " .. failed_entities)
    game.print(module_name .. "Restored " .. restored_entities .. " entities for " .. player.name .. ".")
    while undo_redo_stack.get_undo_item_count() > 0 do
        undo_redo_stack.remove_undo_item(1)
    end
end

Event.add(
    ServerCommands.events.on_poll_complete, function (event)
        if not event.winning_answer or not event.winning_answer.text then
            return
        end
        local custom_data = event.custom_data
        if not custom_data then
            Server.output_script_data(module_name .. "Custom data is not set. Not checking undo redo stack.")
            return
        end
        local player_name = custom_data.player_name
        if not player_name then
            return
        end
        Server.output_script_data(
            module_name .. "Poll complete for " .. player_name .. " with winning answer " .. event.winning_answer.text)
        if not undo_polls or not next(undo_polls) then
            Server.output_script_data(module_name .. "No undo polls found. Not checking undo redo stack.")
            return
        end
        for i = 1, # undo_polls do
            local poll_action = undo_polls[i]
            if poll_action and poll_action.unique_id == custom_data.unique_id then
                local surface = game.get_surface(poll_action.surface_index)
                if not surface or not surface.valid then
                    Server.output_script_data(module_name .. "Surface is not valid. Not checking undo redo stack.")
                    undo_polls[i] = nil
                    return
                end
                local player = game.get_player(player_name)
                if not player or not player.valid then
                    Server.output_script_data(module_name .. "Player is not valid. Not checking undo redo stack.")
                    undo_polls[i] = nil
                    return
                end
                if string.find(event.winning_answer.text, "Yes", 1, true) then
                    check_undo_redo_stack(player)
                    Server.output_script_data(module_name .. "Undo redo stack checked for " .. player_name)
                else
                    Server.output_script_data(
                        module_name .. "Not restoring entities. Adding all items to a chest near spawn.")
                    local spawn_position = game.forces.player.get_spawn_position(surface)
                    local non_colliding_position = surface.find_non_colliding_position("blue-chest", spawn_position, 10, 5)
                    local e = surface.create_entity(
                        {
                            name = "blue-chest",
                            position = non_colliding_position or spawn_position,
                            force = "player"
                        })
                    if e and e.valid then
                        Task.set_timeout_in_ticks(1000, make_entity_destructible_token,
                            {
                                entity = e
                            })
                        e.set_inventory_size_override(defines.inventory.chest, 1000)
                        game.print(module_name .. "All items have been transferred to a chest near spawn. Located here: [gps=" .. e.position.x .. "," .. e.position.y .. "," .. e.surface.name .. "]")
                        game.print(module_name .. "Located here: [gps=" .. e.position.x .. "," .. e.position.y .. "," .. e.surface.name .. "]")
                        local main_inventory = player.get_main_inventory()
                        if main_inventory and main_inventory.valid then
                            for _, item in pairs(main_inventory.get_contents()) do
                                e.insert(
                                    {
                                        name = item.name,
                                        quality = item.quality,
                                        count = item.count
                                    })
                            end
                        end
                        player.clear_items_inside()
                    end
                end
                Server.output_script_data(module_name .. "Poll removed from undo polls for " .. player_name)
                undo_polls[i] = nil
                break
            end
        end
    end
)

Event.add(
    ServerCommands.events.on_player_banned, function (event)
        if not event.player_name then
            return
        end
        local player = game.get_player(event.player_name)
        if not player or not player.valid then
            Server.output_script_data(module_name .. "Player is not valid. Not checking undo redo stack.")
            return
        end
        Server.output_script_data(module_name .. "Player banned event received for " .. player.name)
        local undo_count = check_undo_queue(player)
        if not undo_count or undo_count <= 0 then
            Server.output_script_data(
                module_name .. "No restorable removed entities found for " .. player.name .. ". Not creating undo poll.")
            return
        end
        Server.output_script_data(
            module_name .. "Found " .. undo_count .. " restorable removed entities for banned player " .. player.name .. ". Creating poll.")
        do_action_poll(player)
    end
)

Commands.new("undo_player_actions", "Undoes the actions of a player as a player by creating a poll.")
    :add_parameter("player", false, "player")
    :require_validation("Only utilize this command if the player is jailed and has entities in the undo queue.")
    :require_playtime(60 * 60 * 60 * 24 * 40)
    :callback(
        function (player, target_player)
            if not target_player or not target_player.valid then
                return player.print(module_name .. "Player is not valid.")
            end
            local undo_count = check_undo_queue(target_player)
            if not undo_count or undo_count <= 0 then
                return player.print(module_name .. "No restorable removed entities found for " .. target_player.name .. ".")
            end
            do_action_poll(target_player)
            player.print(module_name .. "Logging your actions to discord.")
            Discord.send_notification(
                {
                    title = "Undo actions",
                    description = "Requested restoration of " .. undo_count .. " removed entities for " .. target_player.name .. " by " .. player.name .. ".",
                    color = "success",
                    fields =
                    {
                        {
                            title = "Server",
                            description = Server.get_server_name() or "CommandHandler",
                            inline = "false"
                        }
                    }
                })
        end
    )

Commands.new("undo_player_actions_admin", "Undoes the actions of a player as an admin.")
    :add_parameter("player", false, "player")
    :require_validation("Only utilize this command if the player is jailed and has entities in the undo queue.")
    :require_admin()
    :callback(
        function (player, target_player)
            if not target_player or not target_player.valid then
                return player.print(module_name .. "Player is not valid.")
            end
            local undo_count = check_undo_queue(target_player)
            if not undo_count or undo_count <= 0 then
                return player.print(module_name .. "No restorable removed entities found for " .. target_player.name .. ".")
            end
            check_undo_redo_stack(target_player)
            player.print(module_name .. "Logging your actions to discord. Restored " .. undo_count .. " removed entities for " .. target_player.name .. ".")
            player.print(module_name .. "Restored " .. undo_count .. " removed entities for " .. target_player.name .. ".")
            Discord.send_notification(
                {
                    title = "Undo actions",
                    description = "Restored " .. undo_count .. " removed entities for " .. target_player.name .. " by " .. player.name .. ".",
                    color = "success",
                    fields =
                    {
                        {
                            title = "Server",
                            description = Server.get_server_name() or "CommandHandler",
                            inline = "false"
                        }
                    }
                })
        end
    )

Public.check_undo_redo_stack = check_undo_redo_stack
Public.check_undo_queue = check_undo_queue
Public.do_action_poll = do_action_poll

return Public
