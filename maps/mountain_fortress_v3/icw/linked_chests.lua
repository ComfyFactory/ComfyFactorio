local Event = require 'utils.event'
local Color = require 'utils.color_presets'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Where = require 'utils.commands.where'
local Math2D = require 'math2d'
local WPT = require 'maps.mountain_fortress_v3.table'
local Session = require 'utils.datastore.session_data'
local AG = require 'utils.antigrief'
local Discord = require 'utils.discord_handler'

local this = {
    main_containers = {},
    linked_gui = {},
    valid_chests = {
        ['linked-chest'] = true,
        ['steel-chest'] = true,
        ['iron-chest'] = true
    },
    enabled = true,
    uid_counter = 0,
    disable_normal_placement = true,
    converted_chests = 0,
    cost_to_convert = 500
}

local chest_converter_frame_for_player_name = Gui.uid_name()
local convert_chest_to_linked = Gui.uid_name()
local item_name_frame_name = Gui.uid_name()

local module_name = '[Linked Chests] '
local deepcopy = table.deepcopy
local insert = table.insert
local pairs = pairs
local Public = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local remove_chest

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

local remove_all_linked_items_token =
    Token.register(
    function(event)
        local player_index = event.player_index
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end

        player.remove_item({name = 'linked-chest', count = 99999})
    end
)

local function create_message(player, action, source_position, destination_position)
    local data = {
        title = 'Mountain_fortress_v3',
        description = 'Linked chests action was triggered.',
        field1 = {
            text1 = player.name,
            text2 = action
        },
        field2 = {
            text1 = 'Source position:',
            text2 = '{x = ' .. source_position.x .. ', y = ' .. source_position.y .. '}'
        }
    }
    if destination_position then
        data.field3 = {
            text1 = 'Destination position:',
            text2 = '{x = ' .. destination_position.x .. ', y = ' .. destination_position.y .. '}'
        }
    end

    Discord.send_notification(data)
end

local function draw_convert_chest_button(parent, entity)
    local frame = parent[chest_converter_frame_for_player_name]
    if frame and frame.valid then
        Gui.destroy(frame)
    end

    local anchor = {
        gui = defines.relative_gui_type.container_gui,
        position = defines.relative_gui_position.right
    }
    frame =
        parent.add {
        type = 'frame',
        name = chest_converter_frame_for_player_name,
        anchor = anchor,
        direction = 'vertical'
    }

    local button =
        frame.add {
        type = 'sprite-button',
        sprite = 'item/' .. entity.name,
        name = convert_chest_to_linked,
        style = Gui.button_style,
        tooltip = '[color=blue][Linked chest][/color]\nYou can easily convert this chest to an linked chest.\nAllowing items to be moved instantly.\n\nCosts ' .. this.cost_to_convert .. ' coins.'
    }
    Gui.set_data(button, entity)
end

local function uid_counter()
    this.uid_counter = this.uid_counter + 1

    if this.uid_counter > 4294967295 then
        this.uid_counter = 5000
    end

    return this.uid_counter
end

local function validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if not player.character then
        return false
    end
    if not player.connected then
        return false
    end
    return true
end

local function does_exists(unit_number)
    local containers = this.main_containers
    if containers.index == 1 then
        return false
    end

    if containers[unit_number] then
        return true
    else
        return false
    end
end

local function add_object(unit_number, state)
    local containers = this.main_containers

    if not containers[unit_number] then
        containers[unit_number] = state
    end

    return containers[unit_number]
end

local function remove_object(unit_number)
    local container = this.main_containers[unit_number]

    if container and container.chest and container.chest.valid then
        container.chest.destroy()
    end

    this.main_containers[unit_number] = nil
end

local function fetch_container(unit_number)
    return this.main_containers[unit_number]
end

local function fetch_share(text)
    local containers = this.main_containers
    for unit_number, container in pairs(containers) do
        if container.share.name == text then
            return true, unit_number, container
        end
    end
    return false
end

local function fetch_link_id(id)
    local containers = this.main_containers
    for unit_number, container in pairs(containers) do
        if container.link_id == id then
            return true, unit_number, container
        end
    end
    return false
end

local function create_chest(entity, name, raised)
    entity.active = false
    entity.destructible = false
    local unit_number = entity.unit_number

    entity.link_id = uid_counter()

    if not does_exists(unit_number) then
        local container = {
            chest = entity,
            unit_number = unit_number,
            mode = 1,
            link_id = entity.link_id,
            share = {
                name = name or entity.unit_number
            }
        }

        if raised then
            container.mode = 2
        end

        add_object(unit_number, container)
        return true
    end
    return false
end

local function restore_links(unit_number)
    local containers = this.main_containers
    local source_container = fetch_container(unit_number)
    local new_unit_number
    for _, container in pairs(containers) do
        if container.chest and container.chest.valid and container.linked_to == unit_number then
            container.linked_to = nil
            if not new_unit_number then
                container.mode = 1
                new_unit_number = container.unit_number
                container.share.name = source_container.share.name
            elseif new_unit_number and new_unit_number ~= container.unit_number then
                container.linked_to = new_unit_number
            end
            container.link_id = source_container.link_id
            container.chest.link_id = source_container.link_id
        end
    end
end

local function restore_link(unit_number, new_unit_number)
    local containers = this.main_containers
    local source_container = fetch_container(unit_number)
    for _, container in pairs(containers) do
        if container.chest and container.chest.valid and container.linked_to == unit_number then
            container.linked_to = new_unit_number
            container.link_id = source_container.link_id
            container.chest.link_id = source_container.link_id
        end
    end
end

local function built_entity_robot(event)
    if this.disable_normal_placement then
        return
    end
    local entity = event.created_entity
    if not entity.valid then
        return
    end
    if not this.valid_chests[entity.name] then
        return
    end

    local robot = event.robot
    if robot and robot.valid then
        local created = event.created_entity
        if created and created.valid then
            local inventory = robot.get_inventory(defines.inventory.robot_cargo)
            inventory.insert({name = created.name, count = 1})
            created.destroy()
        end
    end
end

remove_chest = function(unit_number)
    restore_links(unit_number)
    remove_object(unit_number)
end

local function refund_player(source_player, entity)
    local unit_number = entity.unit_number
    local container = fetch_container(unit_number)
    if not container then
        return
    end

    source_player.insert({name = 'coin', count = this.cost_to_convert})
    source_player.remove_item({name = 'linked-chest', count = 99999})

    Task.set_timeout_in_ticks(10, remove_all_linked_items_token, {player_index = source_player.index})
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end
    if not this.valid_chests[entity.name] then
        return
    end

    local unit_number = entity.unit_number
    remove_chest(unit_number)
end

local function on_pre_player_mined_item(event)
    local entity = event.entity
    local player = game.get_player(event.player_index)
    if not player then
        return
    end
    if not this.valid_chests[entity.name] then
        return
    end
    refund_player(player, entity)
    remove_chest(entity.unit_number)
    AG.append_scenario_history(player, entity, player.name .. ' mined chest (' .. entity.unit_number .. ')')
    create_message(player, 'Mined chest', entity.position, nil)

    local data = this.linked_gui[player.name]
    if not data then
        return
    end
    data.frame.destroy()
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

    local data = this.linked_gui[player.name]
    if not data then
        return
    end

    local name = element.name

    if not data.text_field or not data.text_field.valid then
        return
    end

    if not data.text_field.text then
        return
    end

    local entity = data.entity
    if not entity or not entity.valid then
        return
    end

    local unit_number = entity.unit_number
    local container = fetch_container(unit_number)

    if name and name == 'share_name' and element.text then
        if string.len(element.text) > 2 then
            if not fetch_share(element.text) then
                container.share.name = element.text
            else
                player.print(module_name .. 'A share with name "' .. element.text .. '" already exists.', Color.fail)
            end
        end
    end

    local value = tonumber(element.text)
    if not value then
        return
    end

    if value ~= '' then
        if name and name == 'link_id_label' then
            if value > 4294967295 then
                player.print(module_name .. 'The data type allows values from 0 to 4294967295.', Color.fail)
                return
            end

            if value >= 0 and not fetch_link_id(value) then
                container.chest.link_id = value
                container.link_id = value
            else
                player.print(module_name .. 'A chest with link-id "' .. value .. '" already exists.', Color.fail)
            end
        end
    end
    this.linked_gui[player.name].updated = false
end

--- Iterates all chests.
---@param unit_number any
---@return table
local function get_all_chests(unit_number)
    local t = {}
    local loco_surface = WPT.get('loco_surface')
    local containers = this.main_containers
    for check_unit_number, container in pairs(containers) do
        if container.chest and container.chest.valid and container.share.name ~= '' and container.share.name ~= container.unit_number and container.chest.surface.index == loco_surface.index then
            if check_unit_number ~= unit_number then
                insert(t, container)
            end
        end
    end
    return t
end

local function get_share(entity)
    local unit_number = entity.unit_number
    local container = fetch_container(unit_number)
    if not container.share then
        create_chest(entity)
    end

    return container.share
end

local function refresh_main_frame(data)
    local player = data.player
    local unit_number = data.unit_number

    local container = fetch_container(unit_number)
    local entity = container.chest
    if not entity or not entity.valid then
        return
    end

    local player_gui = this.linked_gui[player.name]
    local trusted_player = Session.get_trusted_player(player)
    local volatile_tbl = player_gui.volatile_tbl

    volatile_tbl.clear()

    local mode = container.mode

    if mode ~= 2 then
        if container and container.linked_to then
            container.linked_to = nil
        end
    end

    if mode == 1 then
        local share_tbl = volatile_tbl.add {type = 'table', column_count = 8, name = 'share_tbl'}
        local share_one_bottom_flow = share_tbl.add {type = 'flow'}
        share_one_bottom_flow.style.minimal_width = 40

        local share_two_label = share_one_bottom_flow.add({type = 'label', caption = 'Share Name: '})
        share_two_label.style.font = 'heading-2'
        local share_two_text = share_one_bottom_flow.add({type = 'textfield', name = 'share_name', text = get_share(entity).name})
        share_two_text.enabled = false
        share_two_text.style.width = 150
        share_two_text.allow_decimal = true
        share_two_text.allow_negative = false
        share_two_text.style.minimal_width = 25
    elseif mode == 2 then
        local linker_tooltip = '[color=yellow]Link Info:[/color]\nThis will only work if there are any current placed linked chests.'

        if container then
            local disconnect = volatile_tbl.add {type = 'table', column_count = 2, name = 'disconnect'}
            local linker = volatile_tbl.add {type = 'table', column_count = 1, name = 'linker'}
            local chests = get_all_chests(unit_number)
            local linked_container = fetch_container(container.linked_to)

            if not next(chests) then
                local link_label = linker.add({type = 'label', caption = 'No chests found. '})
                link_label.style.font = 'heading-2'
                local link_info_label = linker.add({type = 'label', caption = 'A chest needs an unique share name.'})
                link_info_label.style.font = 'heading-2'
                return
            end

            if container.linked_to and linked_container then
                local disconnect_label = disconnect.add({type = 'label', caption = 'Disconnect link? '})
                disconnect_label.style.font = 'heading-2'
                local disconnect_button = disconnect.add({type = 'checkbox', name = 'disconnect_state', state = false})
                disconnect_button.tooltip = 'Click to disconnect this link!'
                disconnect_button.style.minimal_height = 25

                if not trusted_player then
                    disconnect_button.enabled = false
                    disconnect_button.tooltip = '[Antigrief] You have not grown accustomed to this technology yet.'
                end

                local link_label = linker.add({type = 'label', caption = 'Linked with:', tooltip = linker_tooltip})
                link_label.style.font = 'heading-2'

                local chest_id = linker.add({type = 'label', caption = 'Chest Id:[color=yellow] ' .. linked_container.unit_number .. '[/color]'})
                chest_id.style.font = 'heading-2'

                local link_id = linker.add({type = 'label', caption = 'Link Id: [color=yellow] ' .. linked_container.link_id .. '[/color]'})
                link_id.style.font = 'heading-2'
            else
                local link_chest_label = linker.add({type = 'label', caption = 'Link with chest:\n', tooltip = linker_tooltip})
                link_chest_label.style.font = 'heading-2'
                local chest_scroll_pane =
                    linker.add {
                    type = 'scroll-pane',
                    vertical_scroll_policy = 'auto',
                    horizontal_scroll_policy = 'never'
                }
                local chest_scroll_style = chest_scroll_pane.style
                chest_scroll_style.maximal_height = 150
                chest_scroll_style.vertically_squashable = true
                chest_scroll_style.bottom_padding = 2
                chest_scroll_style.left_padding = 2
                chest_scroll_style.right_padding = 2
                chest_scroll_style.top_padding = 2
                local chestlinker = chest_scroll_pane.add {type = 'table', column_count = 8, name = 'chestlinker'}

                for i = 1, #chests do
                    if chests then
                        local source_chest = chests[i]
                        if type(source_chest) ~= 'string' and source_chest.share.name ~= '' and source_chest.share.name ~= source_chest.chest.unit_number then
                            local flowlinker = chestlinker.add {type = 'flow'}
                            local chestitem =
                                flowlinker.add {
                                type = 'sprite-button',
                                name = item_name_frame_name,
                                style = 'slot_button',
                                sprite = 'item/' .. source_chest.chest.name,
                                tooltip = 'Chest: [color=yellow]' .. source_chest.share.name .. '[/color]\nRight click to show on map.'
                            }
                            if not trusted_player then
                                chestitem.enabled = false
                                chestitem.tooltip = '[Antigrief] You have not grown accustomed to this technology yet.'
                            end
                            Gui.set_data(chestitem, {name = nil, unit_number = unit_number, share = source_chest.share.name})
                        end
                    end
                end
            end
        end
    end
end

local function gui_opened(event)
    if not event.player_index then
        return
    end

    if not event.gui_type == defines.gui_type.entity then
        return
    end
    local entity = event.entity
    if not (entity and entity.valid) then
        return
    end
    if not this.valid_chests[entity.name] then
        return
    end
    local unit_number = entity.unit_number
    local player = game.get_player(event.player_index)

    local container = fetch_container(unit_number)
    if not container then
        return
    end

    local frame = player.gui.center[tostring(unit_number)]
    if not frame or not frame.valid then
        frame =
            player.gui.center.add {
            type = 'frame',
            caption = 'Linked chest',
            direction = 'vertical',
            name = tostring(unit_number)
        }
    end

    local controls = frame.add {type = 'flow', direction = 'horizontal'}
    local controls2 = frame.add {type = 'flow', direction = 'horizontal'}
    local items = frame.add {type = 'flow', direction = 'vertical'}

    local mode = container.mode
    local selected = mode and mode or 1
    local controltbl = controls.add {type = 'table', column_count = 1}
    local btntbl = controltbl.add {type = 'table', column_count = 2}
    local volatile_tbl = controls2.add {type = 'table', column_count = 1}

    local btn =
        btntbl.add {
        type = 'sprite-button',
        tooltip = '[color=blue]Info![/color]\nChest ID: ' .. unit_number .. '\n\nFor a smoother link:\nSHIFT + RMB on the source entity\nSHIFT + LMB on the destination entity.\n\nTo mine a linked chest, disconnect the link first.',
        sprite = Gui.info_icon
    }
    btn.style.height = 20
    btn.style.width = 20
    btn.enabled = false
    btn.focus()

    this.linked_gui[player.name] = {
        item_frame = items,
        frame = frame,
        volatile_tbl = volatile_tbl,
        entity = entity,
        updated = false
    }

    container.mode = selected
    player.opened = frame

    refresh_main_frame({unit_number = unit_number, player = player})
end

local function on_built_entity(event, raised, bypass)
    if this.disable_normal_placement and not raised then
        return
    end
    local entity = event.created_entity
    if not entity.valid then
        return
    end
    if not this.valid_chests[entity.name] and not bypass then
        return
    end
    local surface = entity.surface
    local position = entity.position
    if raised and entity.name ~= 'linked-chest' then
        entity.destroy()
        entity = surface.create_entity {name = 'linked-chest', position = position, force = game.forces.player}
        event.entity = entity
    end
    if not entity.valid then
        return
    end

    local s = create_chest(entity, nil, raised)
    if s then
        gui_opened(event)
    end
end

local function update_gui()
    for _, player in pairs(game.connected_players) do
        local chest_gui_data = this.linked_gui[player.name]
        if not chest_gui_data then
            goto continue
        end
        local frame = chest_gui_data.item_frame
        local entity = chest_gui_data.entity
        if not frame then
            goto continue
        end
        if not entity or not entity.valid then
            goto continue
        end

        local unit_number = entity.unit_number
        local container = fetch_container(unit_number)

        local mode = container.mode

        if not frame or not frame.valid then
            goto continue
        end

        frame.clear()

        if mode ~= 1 then
            return
        end

        local tbl = frame.add {type = 'table', column_count = 10, name = 'linked_chest_inventory'}
        local total = 0
        local items = {}

        local content = container.chest.get_inventory(defines.inventory.chest).get_contents()

        for item_name, item_count in pairs(content) do
            if item_name ~= 'count' then
                if not items[item_name] then
                    total = total + 1
                    items[item_name] = item_count
                else
                    items[item_name] = items[item_name] + item_count
                end
            end
        end

        local btn

        for item_name, item_count in pairs(items) do
            local localized_name = game.item_prototypes[item_name].localised_name[1]
            if container.requested_item and tbl[container.requested_item] then
                tbl[container.requested_item].number = item_count
            else
                btn =
                    tbl.add {
                    type = 'sprite-button',
                    sprite = 'item/' .. item_name,
                    style = 'slot_button',
                    number = item_count,
                    name = item_name,
                    tooltip = {'', {localized_name}, '\nCount: ', item_count}
                }
                btn.enabled = false
            end
        end

        while total < 16 do
            local btns = tbl.add {type = 'sprite-button', style = 'slot_button'}
            btns.enabled = false

            total = total + 1
        end

        this.linked_gui[player.name].updated = true
        ::continue::
    end
end

local function gui_closed(event)
    local player = game.get_player(event.player_index)
    local type = event.gui_type

    if type == defines.gui_type.custom then
        local data = this.linked_gui[player.name]
        if not data then
            return
        end
        data.frame.destroy()
        this.linked_gui[player.name] = nil
    end
end

local function on_gui_checked_state_changed(event)
    local element = event.element
    local player = game.get_player(event.player_index)
    if not validate_player(player) then
        return
    end
    if not element.valid then
        return
    end

    local pGui = this.linked_gui[player.name]
    if not pGui then
        return
    end

    local entity = pGui.entity
    if not (entity and entity.valid) then
        return
    end

    local unit_number = entity.unit_number
    local container = fetch_container(unit_number)
    if not container then
        return
    end

    if element.name == 'disconnect_state' then
        container.chest.link_id = uid_counter()
        AG.append_scenario_history(player, container.chest, player.name .. ' disconnected link from chest (' .. container.unit_number .. ') to chest (' .. container.linked_to .. ')')
        local destination_chest = fetch_container(container.linked_to)
        if destination_chest then
            create_message(player, 'Disconnected link', container.chest.position, destination_chest.chest.position)
        else
            create_message(player, 'Disconnected link', container.chest.position, nil)
        end
        container.mode = 2
        container.linked_to = nil
        container.link_id = nil
        container.chest.minable = true
        refresh_main_frame({unit_number = unit_number, player = player})
    end

    pGui.updated = false
end

local function state_changed(event)
    local player = game.get_player(event.player_index)
    if not validate_player(player) then
        return
    end

    local element = event.element
    if not element.valid then
        return
    end
    if not element.selected_index then
        return
    end

    local unit_number = tonumber(element.name)
    if unit_number then
        local container = fetch_container(unit_number)
        if not container then
            return
        end
        if not container.mode then
            return
        end
        container.mode = element.selected_index
        local mode = container.mode

        refresh_main_frame({unit_number = unit_number, player = player})

        if mode >= 2 then
            this.linked_gui[player.name].updated = false
            return
        end
    end
end

local function content_mismatches(source, destination)
    local source_container = fetch_container(source)
    if not source_container then
        return
    end
    local source_content = source_container.get_inventory(defines.inventory.chest)
    local source_inventory = source_content.get_contents()

    local destination_container = fetch_container(destination)
    if not destination_container then
        return
    end
    local destination_content = destination_container.get_inventory(defines.inventory.chest)
    local destination_inventory = destination_content.get_contents()

    local mismatch = false

    for source_item_name, _ in pairs(source_inventory) do
        for destination_item_name, _ in pairs(destination_inventory) do
            if source_item_name ~= destination_item_name then
                mismatch = true
            end
        end
    end
    return mismatch
end

local function on_entity_settings_pasted(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local source = event.source
    if not source or not source.valid then
        return
    end
    if source.name ~= 'linked-chest' then
        return
    end

    local destination = event.destination
    if not destination or not destination.valid then
        return
    end

    local source_link_id = source.link_id
    local destination_link_id = destination.link_id

    local source_container = fetch_container(source.unit_number)
    local destination_container = fetch_container(destination.unit_number)

    if not source_container then
        player.print(module_name .. 'The source container was not found.', Color.warning)
        return
    end

    if not destination_container then
        return
    end

    local source_share = source_container.share

    if content_mismatches(source_link_id, destination_link_id) then
        player.print(module_name .. 'The destination chest that you are trying to paste to mismatches with the original chest.', Color.fail)
        destination_container.chest.link_id = destination_container.link_id
        return
    end

    if source_container.linked_to and not destination_container.linked_to then
        goto continue
    end

    if source_container.mode == 1 and destination_container.mode == 1 then
        player.print(module_name .. 'Destination chest cannot be linked since source chest is of same mode.', Color.fail)
        destination_container.chest.link_id = destination_container.link_id
        return
    end

    if source_container.linked_to and destination_container.linked_to then
        player.print(module_name .. 'The destination chest is already linked.', Color.fail)
        destination_container.chest.link_id = destination_container.link_id
        return
    end

    if source_container.share.name == '' then
        player.print(module_name .. 'The source chest is not shared.', Color.fail)
        destination_container.chest.link_id = destination_container.link_id
        return
    end

    if source_container.chest.unit_number == source_container.share.name then
        player.print(module_name .. 'The source chest is not shared.', Color.fail)
        destination_container.chest.link_id = destination_container.link_id
        return
    end

    if destination_container.linked_to then
        player.print(module_name .. 'The destination chest is already linked.', Color.fail)
        destination_container.chest.link_id = destination_container.link_id
        return
    end

    ::continue::

    if source_share and source_share.name ~= '' then
        AG.append_scenario_history(player, destination_container.chest, player.name .. ' pasted settings from chest (' .. source_container.unit_number .. ') to chest (' .. destination_container.unit_number .. ')')
        create_message(player, 'Pasted settings', source_container.chest.position, destination_container.chest.position)

        destination_container.linked_to = source_container.linked_to or source.unit_number
        destination_container.link_id = source_link_id
        destination_container.chest.link_id = source_link_id
        destination_container.mode = 2
    end

    player.print(module_name .. 'Successfully pasted settings.', Color.success)
end

function Public.add(surface, position, force, name)
    local entity = surface.create_entity {name = 'linked-chest', position = position, force = force, create_build_effect_smoke = false}
    if not entity.valid then
        return
    end

    create_chest(entity, name)
    return entity
end

function Public.migrate(source, destination)
    local source_container = fetch_container(source.unit_number)
    if not source_container then
        return
    end

    local source_data = deepcopy(source_container)
    source_data.chest = destination
    source_data.unit_number = destination.unit_number

    this.main_containers[destination.unit_number] = source_data

    destination.minable = false
    destination.destructible = false
    restore_link(source.unit_number, destination.unit_number)

    this.main_containers[source.unit_number] = nil
end

Event.on_nth_tick(
    5,
    function()
        if not this.enabled then
            return
        end
        update_gui()
    end
)

Event.on_nth_tick(
    120,
    function()
        local containers = this.main_containers
        local active_surface_index = WPT.get('active_surface_index')

        for index, container in pairs(containers) do
            if container then
                if container.chest and container.chest.valid then
                    if container.chest.surface.index == active_surface_index then
                        if not WPT.locomotive.is_around_train(container.chest) then
                            remove_chest(container.unit_number)
                        end
                    end
                    if container.mode == 1 then
                        container.chest.minable = false
                    end
                end
                if not container.chest or not container.chest.valid then
                    containers[index] = nil
                end
            end
        end
    end
)

Gui.on_click(
    convert_chest_to_linked,
    function(event)
        local player = event.player
        local inventory = player.get_main_inventory()
        local player_item_count = inventory.get_item_count('coin')

        local active_surface_index = WPT.get('active_surface_index')

        local trusted_player = Session.get_trusted_player(player)

        if not trusted_player then
            player.print('[Antigrief] You have not grown accustomed to this technology yet.', Color.warning)
            return
        end

        if player_item_count >= this.cost_to_convert then
            local entity = Gui.get_data(event.element)
            if entity and entity.valid then
                if not WPT.locomotive.is_around_train(entity) or active_surface_index ~= entity.surface.index then
                    player.print(module_name .. 'The placed entity is not near the locomotive or is on the wrong surface.', Color.warning)
                    return
                end

                player.remove_item({name = 'coin', count = this.cost_to_convert})
                player.opened = nil
                event.created_entity = entity
                event.entity = entity
                event.player_index = player.index
                AG.append_scenario_history(player, entity, player.name .. ' converted chest (' .. entity.unit_number .. ')')
                create_message(player, 'Converted chest', entity.position, nil)

                this.converted_chests = this.converted_chests + 1

                on_built_entity(event, true)
            end
        else
            player.print(module_name .. 'Not enough coins.', Color.warning)
        end
    end
)

Event.add(
    defines.events.on_gui_opened,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local panel = player.gui.relative
        local entity = event.entity

        if entity and entity.valid and this.valid_chests[entity.name] then
            draw_convert_chest_button(panel, entity)
        end

        gui_opened(event)
    end
)

Event.add(
    defines.events.on_gui_closed,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        gui_closed(event)

        local relative = player.gui.relative
        local panel = relative[chest_converter_frame_for_player_name]
        if panel and panel.valid then
            Gui.destroy(panel)
        end
    end
)

Gui.on_click(
    item_name_frame_name,
    function(event)
        local data = Gui.get_data(event.element)
        if not data then
            return
        end
        local button = event.button

        local _, _unit_number, share_container = fetch_share(data.share)
        if _unit_number then
            local container = fetch_container(data.unit_number)

            if button == defines.mouse_button_type.right then
                local player = game.get_player(event.player_index)
                if player and player.valid then
                    Where.create_mini_camera_gui(player, {valid = true, name = share_container.share.name, surface = share_container.chest.surface, position = share_container.chest.position}, 0.7, true)
                end
                return
            end

            AG.append_scenario_history(event.player, container.chest, event.player.name .. ' linked chest (' .. data.unit_number .. ') with: ' .. share_container.share.name)
            create_message(event.player, 'Linked chest', container.chest.position, share_container.chest.position)
            container.linked_to = _unit_number
            container.chest.link_id = share_container.link_id
            container.link_id = share_container.link_id

            container.chest.minable = false

            this.linked_gui[event.player.name].updated = false
            refresh_main_frame({unit_number = container.unit_number, player = event.player})
        end
    end
)

local function on_player_changed_position(event)
    local player = game.get_player(event.player_index)
    local data = this.linked_gui[player.name]
    if not data then
        return
    end

    if data and data.frame and data.frame.valid then
        local position = data.entity.position
        local area = {
            left_top = {x = position.x - 8, y = position.y - 8},
            right_bottom = {x = position.x + 8, y = position.y + 8}
        }
        if Math2D.bounding_box.contains_point(area, player.position) then
            return
        end
        data.frame.destroy()
    end
end

function Public.reset()
    this.main_containers = {}
    this.linked_gui = {}
    this.valid_chests = {
        ['linked-chest'] = true,
        ['steel-chest'] = true,
        ['iron-chest'] = true
    }
    this.enabled = true
    this.converted_chests = 0
    this.uid_counter = 0
    this.disable_normal_placement = true
    this.cost_to_convert = 500
end

Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, built_entity_robot)
Event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)
Event.add(defines.events.on_gui_selection_state_changed, state_changed)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_gui_text_changed, text_changed)
Event.add(defines.events.on_gui_checked_state_changed, on_gui_checked_state_changed)
Event.add(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)

return Public
