local Event = require 'utils.event'
local Color = require 'utils.color_presets'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Commands = require 'utils.commands'

local this =
{
    main_containers = {},
    inf_gui = {},
    saved_containers = {},
    valid_storage =
    {
        ['storage-tank'] = true
    },
    enabled = true,
    editor = {},
    disable_normal_placement = true,
    debug = false,
    cost_to_convert = 200
}

local default_limit = 50000

local converter_frame_for_player_name = Gui.uid_name()
local convert_to_infinite_container = Gui.uid_name()
local item_name_frame_name = Gui.uid_name()
local master_storage_btn_name = Gui.uid_name()

local toggle_render

local module_name = '[Infinity Storage] '
local insert = table.insert
local floor = math.floor
local pairs = pairs
local Public = {}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local remove_container
local refresh_main_frame

local delay_refresh_main_frame_task_token =
    Token.register(
        function (event)
            local player_index = event.player_index
            local player = game.get_player(player_index)
            if not player or not player.valid then
                return
            end

            local unit_number = event.unit_number
            if not unit_number then
                return
            end

            refresh_main_frame({ unit_number = unit_number, player = player })
        end
    )

function Public.get_table()
    return this
end

local function draw_convert_button(parent, entity)
    local frame = parent[converter_frame_for_player_name]
    if frame and frame.valid then
        Gui.destroy(frame)
    end

    local anchor =
    {
        gui = defines.relative_gui_type.storage_tank_gui,
        position = defines.relative_gui_position.right
    }
    frame =
        parent.add
        {
            type = 'frame',
            name = converter_frame_for_player_name,
            anchor = anchor,
            direction = 'vertical'
        }

    local button =
        frame.add
        {
            type = 'sprite-button',
            sprite = 'item/' .. entity.name,
            name = convert_to_infinite_container,
            style = Gui.button_style,
            tooltip = '[color=blue][Infinity storage][/color]\nYou can easily convert this container to an infinity storage.\n\nCosts ' .. this.cost_to_convert .. ' coins.'
        }
    Gui.set_data(button, entity)
end

local function validate()
    if not this or not this.main_containers then
        this =
        {
            main_containers = {},
            inf_gui = {},
            saved_containers = {},
            valid_storage =
            {
                ['storage-tank'] = true
            },
            enabled = true,
            editor = {},
            disable_normal_placement = true,
            debug = false,
            cost_to_convert = 200
        }
    end
end

local function has_value(tab)
    local count = 0
    for _, _ in pairs(tab) do
        count = count + 1
    end
    return count
end

local function return_value(tab)
    for index, value in pairs(tab) do
        if value then
            tab[index] = nil
            return value, index
        end
    end
end

local function detect_item(container)
    local fluidbox = container.entity.fluidbox
    local fluid = fluidbox[1]
    if fluid then
        fluidbox.set_filter(1, { name = fluid.name, force = true })
        container.item = fluid.name
        container.temperature = fluid.temperature
        return true, container.item
    end
    return false
end

local function combine_tempatures(first_count, first_tempature, second_count, second_tempature)
    if first_tempature == second_tempature then
        return first_tempature
    end
    if first_tempature == nil then
        return second_tempature
    end
    local total_count = first_count + second_count
    return (first_tempature * first_count / total_count) + (second_tempature * second_count / total_count)
end

local function update_single_container(container)
    local entity = container.entity
    if not entity or not entity.valid then
        return
    end

    if container.direction.state == 'none' then
        return
    end

    if container.item == nil then
        detect_item(container)
    end
    local item = container.item
    if item == nil then
        return
    end
    local capacity = container.capacity
    local max_capacity = entity.fluidbox.get_capacity(1) * 0.5
    if capacity > max_capacity then
        container.capacity = max_capacity
        capacity = max_capacity
    end

    local inventory_count = entity.get_fluid_count(item)
    if inventory_count > capacity then
        local amount_removed = entity.remove_fluid { name = item, amount = inventory_count - capacity }
        container.temperature = combine_tempatures(container.count, container.temperature, amount_removed,
            entity.fluidbox[1].temperature)
        container.count = container.count + amount_removed
    elseif inventory_count < capacity then
        local to_add = capacity - inventory_count
        if container.count < to_add then
            to_add = container.count
        end
        if to_add ~= 0 then
            local amount_added = entity.insert_fluid { name = item, amount = to_add, temperature = container.temperature }
            container.count = container.count - amount_added
        end
    end
end

local function make_master_storage(player, source_container, destination_container)
    local master, slave
    if source_container.linked_to == destination_container.unit_number then
        master = destination_container
        slave = source_container
    else
        player.print('This storage is not linked to the destination storage (0).', Color.warning)
        return
    end

    if not master or not slave then
        player.print('This storage is not a valid storage (1).', Color.warning)
        return
    end

    if master.mode ~= 1 or slave.mode ~= 3 then
        player.print('This storage is not a valid storage (2).', Color.warning)
        return
    end

    local links = master.links
    if not links then
        player.print('This storage is not linked to the destination storage (3).', Color.warning)
        return
    end
    local slave_un = slave.unit_number
    if not links[slave_un] and not links[tostring(slave_un)] then
        player.print('This storage is not linked to the destination storage (4).', Color.warning)
        return
    end

    local old_master_un = master.unit_number
    local new_master_un = slave_un

    local stored_count = master.count
    master.count = 0

    local new_links = {}
    for unit, _ in pairs(links) do
        local u = tonumber(unit) or unit
        if u ~= new_master_un then
            new_links[u] = true
        end
    end
    new_links[old_master_un] = true

    local share_name = master.share and master.share.name

    master.links = nil
    master.linked_to = new_master_un
    master.mode = 3
    master.requested_fluid = slave.requested_fluid
    if master.share then
        master.share.state = false
        master.share.name = old_master_un
    end

    slave.linked_to = nil
    slave.mode = 1
    slave.requested_fluid = nil
    slave.links = new_links
    slave.limit = master.limit
    slave.count = stored_count
    if slave.share then
        slave.share.state = true
        if share_name ~= nil then
            slave.share.name = share_name
        end
    end

    for _, data in pairs(this.main_containers) do
        if data and data.linked_to == old_master_un and data.unit_number ~= new_master_un then
            data.linked_to = new_master_un
        end
    end

    toggle_render(master)
    toggle_render(slave)
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
    this.main_containers[unit_number] = nil
end

local function fetch_container(unit_number)
    return this.main_containers[unit_number]
end

local function fetch_share(player, text)
    local containers = this.main_containers
    for unit_number, container in pairs(containers) do
        if container.share.name == text and container.owner == player.force.index then
            return true, unit_number
        end
    end
    return false
end

toggle_render = function (container)
    if not container.entity or not container.entity.valid then
        remove_container(container.unit_number)
        return
    end

    if container.render then
        container.render.destroy()
    end

    if container.share.state then
        container.render =
            rendering.draw_text
            {
                text = 'M',
                surface = container.entity.surface,
                target = container.entity,
                target_offset = { 0, -0.6 },
                scale = 2,
                color = { r = 0, g = 0.6, b = 1 },
                alignment = 'center'
            }
    elseif container.linked_to then
        container.render =
            rendering.draw_text
            {
                text = 'L',
                surface = container.entity.surface,
                target = container.entity,
                target_offset = { 0, -0.6 },
                scale = 2,
                color = { r = 0, g = 0.6, b = 1 },
                alignment = 'center'
            }
    else
        container.render =
            rendering.draw_text
            {
                text = '♾',
                surface = container.entity.surface,
                target = container.entity,
                target_offset = { 0, -0.6 },
                scale = 2,
                color = { r = 0, g = 0.6, b = 1 },
                alignment = 'center'
            }
    end
end

local function create_container(entity, stack, player)
    entity.disabled_by_script = true
    local unit_number = entity.unit_number

    if not does_exists(unit_number) then
        local container =
        {
            entity = entity,
            capacity = 0.5 * entity.fluidbox.get_capacity(1),
            count = 0,
            owner = player.force.index,
            unit_number = unit_number,
            clear_fluid = { state = false },
            limit = { state = true, number = default_limit },
            direction =
            {
                state = 'import'
            },
            share =
            {
                state = false,
                name = entity.unit_number
            },
            private = { state = true, owner = player.index },
            mode = 1,
            total_slots = 48
        }

        local tags = stack and stack.valid_for_read and stack.type == 'item-with-tags' and stack.tags
        if tags and tags.name then
            container.count = tags.count
            container.temperature = tags.temperature
            container.item = tags.name
            entity.fluidbox.set_filter(1, { name = tags.name, force = true })
            update_single_container(container)
        end
        local c = add_object(unit_number, container)
        toggle_render(c)
        return true
    end
    return false
end

local function get_share(entity, player)
    local unit_number = entity.unit_number
    local container = fetch_container(unit_number)
    if not container.share then
        create_container(entity, nil, player)
    end

    return container.share
end

local function restore_container(entity, player)
    if this.saved_containers[player.index] and has_value(this.saved_containers[player.index]) >= 1 then
        if not this.enabled then
            goto continue
        end

        local container_index = this.saved_containers[player.index]
        local container_to_place = return_value(container_index)

        local container =
        {
            entity = entity,
            owner = player.force.index,
            capacity = container_to_place.capacity,
            item = container_to_place.item,
            count = container_to_place.count,
            limit = container_to_place.limit,
            unit_number = entity.unit_number,
            clear_fluid = container_to_place.clear_fluid,
            direction = container_to_place.direction,
            share = container_to_place.share,
            private = container_to_place.private,
            mode = 1
        }

        local c = add_object(entity.unit_number, container)
        toggle_render(c)
        return true
    end
    ::continue::
    return false
end

local function remove_link(unit_number)
    local container = fetch_container(unit_number)
    if not container then
        return
    end

    local links = container.links
    -- container.share.name = default_share_name
    container.share.state = false
    if links then
        for unit, _ in pairs(links) do
            unit = tonumber(unit)
            if unit then
                local l_container = fetch_container(unit)
                if l_container then
                    l_container.linked_to = nil
                    l_container.mode = 1
                    links[unit] = nil
                    toggle_render(l_container)
                end
            end
        end
    end
end

remove_container = function (unit_number)
    remove_link(unit_number)
    remove_object(unit_number)
end

local function item_links(data)
    local destination_direction = data.destination_container.direction
    local destination_requested_fluid = data.destination_container.requested_fluid

    if data.source_container.item == nil and data.destination_container.item ~= nil then
        data.source_container.item = data.destination_container.item
    end

    if destination_direction.state == 'import' then -- import
        if destination_requested_fluid then
            if data.destination_container.item == destination_requested_fluid then
                local source_item = data.source_container.item == destination_requested_fluid
                if not source_item and destination_requested_fluid then
                    data.source_container.item = destination_requested_fluid
                    data.source_container.count = 0
                end

                local inventory_count = data.destination_container.entity.get_fluid_count(data.destination_container
                    .item)
                if inventory_count then
                    local amount_removed = data.destination_container.entity.remove_fluid { name = data.destination_container.item, amount = inventory_count }
                    data.source_container.count = data.source_container.count + amount_removed
                    if data.source_container.item == nil then
                        data.source_container.item = destination_requested_fluid
                    end
                end
            end
        else
            local source_item = data.source_container.item == destination_requested_fluid
            if not source_item and destination_requested_fluid then
                data.source_container.item = destination_requested_fluid
                data.source_container.count = 0
            end

            if not data.destination_container.entity or not data.destination_container.entity.valid then return end

            if data.destination_container.item == nil then
                -- detect_item(data.destination_container)
                data.destination_container.item = data.source_container.item
            end

            local inventory_count = data.destination_container.entity.get_fluid_count(data.destination_container.item)
            if inventory_count then
                local amount_removed = data.destination_container.entity.remove_fluid { name = data.destination_container.item, amount = inventory_count }
                data.source_container.count = data.source_container.count + amount_removed
            end
        end
    else
        if not prototypes.fluid[data.source_container.item] then
            return
        end
        local item_stack = 10000

        if not data.destination_container.item or data.destination_container.item ~= destination_requested_fluid then
            data.destination_container.item = destination_requested_fluid
        end

        if not data.destination_container.temperature or data.destination_container.temperature ~= data.source_container.temperature then
            data.destination_container.temperature = data.source_container.temperature
        end

        if destination_requested_fluid then
            if data.source_container.item == destination_requested_fluid then
                if data.source_container.count and data.source_container.count > 0 then
                    local dest_inventory_count = data.destination_container.entity.get_fluid_count(data
                        .destination_container.item)
                    if not dest_inventory_count or dest_inventory_count < (item_stack / 2) then
                        local to_insert = data.source_container.count
                        if to_insert > item_stack then
                            to_insert = floor(item_stack / 2)
                        elseif to_insert > 1 then
                            to_insert = floor(to_insert / 2)
                        end

                        if to_insert < 0 or to_insert == 0 then
                            return
                        end

                        local amount_added = data.destination_container.entity.insert_fluid { name = data.destination_container.item, amount = to_insert, temperature = data.destination_container.temperature }
                        data.source_container.count = data.source_container.count - amount_added

                        if data.source_container.count < 0 then
                            data.source_container.count = 0
                            data.source_container.item = nil
                            data.source_container.entity.clear_fluid_inside()
                        end
                    else
                        local dest_diff_remote_storage = data.source_container.count - data.destination_container.count
                        local dest_diff_local_storage = item_stack - data.destination_container.count
                        if dest_diff_remote_storage > 0 and dest_diff_local_storage > 0 and dest_diff_local_storage < item_stack then
                            if data.source_container.count >= dest_diff_local_storage then
                                local amount_added = data.destination_container.entity.insert_fluid { name = data.destination_container.item, amount = dest_diff_local_storage, temperature = data.destination_container.temperature }
                                data.source_container.count = data.source_container.count - amount_added
                                if data.source_container.count < 0 then
                                    data.source_container.count = 0
                                    data.source_container.item = nil
                                    data.source_container.entity.clear_fluid_inside()
                                end
                            end
                        end
                    end
                end
            end
        else
            if data.source_container.count > 0 then
                local dest_inventory_count = data.destination_container.entity.get_fluid_count(data
                    .destination_container.item)
                if not dest_inventory_count or dest_inventory_count == 0 then
                    local to_insert = 50
                    if to_insert > item_stack then
                        to_insert = floor(item_stack / 2)
                    elseif to_insert > 1 then
                        to_insert = floor(to_insert / 2)
                    end

                    if item_stack == 1 then
                        to_insert = 1
                    end

                    if data.destination_container.item == nil then
                        -- detect_item(data.destination_container)
                        data.destination_container.item = data.source_container.item
                    end

                    local amount_added = data.destination_container.entity.insert_fluid { name = data.destination_container.item, amount = to_insert, temperature = data.destination_container.temperature }
                    data.source_container.count = data.source_container.count - amount_added

                    if data.source_container.count < 0 then
                        data.source_container.count = 0
                        data.source_container.item = nil
                        data.source_container.entity.clear_fluid_inside()
                    end
                else
                    if not data.destination_container.item then
                        detect_item(data.destination_container)
                    end
                    local dest_diff_remote_storage = data.source_container.count - data.destination_container.count
                    local dest_diff_local_storage = item_stack - data.destination_container.count
                    if dest_diff_remote_storage > 0 and dest_diff_local_storage > 0 and dest_diff_local_storage < item_stack then
                        if data.source_container.count >= dest_diff_local_storage then
                            local amount_added = data.destination_container.entity.insert_fluid { name = data.destination_container.item, amount = dest_diff_local_storage, temperature = data.destination_container.temperature }
                            data.source_container.count = data.source_container.count - amount_added
                            if data.source_container.count < 0 then
                                data.source_container.count = 0
                                data.source_container.item = nil
                                data.source_container.entity.clear_fluid_inside()
                            end
                        end
                    end
                end
            end
        end
    end
end

local function refund_player(entity)
    local unit_number = entity.unit_number
    local container = fetch_container(unit_number)
    if not container then
        return
    end
    local player = game.get_player(container.private.owner)

    if player and player.valid then
        player.insert({ name = 'coin', count = this.cost_to_convert })
        return
    end
end

local function is_container_empty(entity, player)
    local unit_number = entity.unit_number
    local container = fetch_container(unit_number)
    if not container then
        return
    end

    local mode = container.mode
    local fluids = container.item
    if not fluids then
        goto no_storage
    end
    if mode == 2 then
        if container.count >= 1000 then
            if not this.saved_containers[player.index] then
                this.saved_containers[player.index] = {}
            end
            container.entity = nil

            this.saved_containers[player.index][unit_number] = container
        end
    end
    ::no_storage::

    remove_container(unit_number)
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity then
        return
    end
    if not this.valid_storage[entity.type] then
        return
    end

    local unit_number = entity.unit_number
    remove_container(unit_number)
end

local function check_limit_on_source_and_content_on_destination(data)
    local source_links = data.source_container.links
    if source_links then
        if data.source_container and data.source_container.count and data.source_container.limit and data.source_container.limit.number and data.destination_container.mode ~= 1 then
            if data.source_container.limit.state and data.source_container.count > data.source_container.limit.number and data.destination_container.direction.state == 'import' then
                data.destination_container.direction.previous = data.destination_container.direction.state
                data.destination_container.direction.state = 'none'
            elseif data.source_container.limit.state then
                if data.source_container.count < data.source_container.limit.number and data.destination_container.direction.state == 'none' then
                    data.destination_container.direction.state = data.destination_container.direction.previous
                end
            elseif data.destination_container.direction.previous then
                data.destination_container.direction.state = data.destination_container.direction.previous
                data.destination_container.direction.previous = nil
            end
        else
            if not data.source_container.limit then
                data.source_container.limit = { state = true, number = default_limit }
            end
        end
    end
end

local function on_pre_player_mined_item(event)
    local entity = event.entity
    local player = game.get_player(event.player_index)
    if not player then
        return
    end
    if not this.valid_storage[entity.type] then
        return
    end
    refund_player(entity)
    is_container_empty(entity, player)
    local data = this.inf_gui[player.name]
    if not data then
        return
    end
    data.frame.destroy()
end

local function get_link(data)
    if data.destination_container and data.destination_container.linked_to then
        local linked_to = tonumber(data.destination_container.linked_to)
        if not linked_to then
            return false
        end
        local source_container = fetch_container(linked_to)
        if not source_container then
            remove_container(linked_to)
            return false
        end

        data.source_container = source_container
    end
end

local function check_links(data)
    get_link(data)

    if data.source_container then
        check_limit_on_source_and_content_on_destination(data)
        item_links(data)
    end
end

local function check_mode_on_container(data)
    local container = data.container.entity
    local mode = data.container.mode

    if mode == 1 then
        container.destructible = false
        container.minable_flag = false
    elseif mode == 2 then
        container.destructible = true
        container.minable_flag = true
    elseif mode == 3 then
        container.destructible = false
        container.minable_flag = false
    end
end

local function update_container(fluid_prototypes)
    local containers = this.main_containers
    for unit_number, container in next, containers do
        if container and not container.entity.valid then
            remove_container(unit_number)
            goto continue
        end

        local inv = container.content
        check_mode_on_container({ container = container, count = 0, inv = inv })
        check_links({ destination_container = container, inv = inv, fluid_prototypes = fluid_prototypes })

        update_single_container(container)

        ::continue::
    end
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

    local data = this.inf_gui[player.name]
    if not data then
        return
    end

    local name = element.name

    local entity = data.entity
    if not entity or not entity.valid then
        return
    end

    if string.len(element.text) > 50 then
        element.text = ''
    end

    local unit_number = entity.unit_number
    local container = fetch_container(unit_number)

    if name and name == 'share_name' and element.text then
        if string.len(element.text) > 2 then
            if not fetch_share(player, element.text) then
                container.share.name = element.text
            else
                player.print(module_name .. 'A share with name "' .. element.text .. '" already exists.', Color.fail)
            end
        end
    end

    local value = tonumber(element.text)

    if not value then
        this.inf_gui[player.name].updated = false
        return
    end

    if value ~= '' then
        if name and name == 'limit_number' then
            if value >= 1 then
                data.text_field.text = tostring(value)
                container.limit.number = value
            elseif value <= default_limit then
                return
            end
        end
    end

    this.inf_gui[player.name].updated = false
end

--- Iterates over player containers.
---@param index any
---@param unit_number any
---@return table
local function get_owner_containers(index, unit_number)
    local t = {}
    local containers = this.main_containers
    for check_unit_number, container in pairs(containers) do
        if container.owner == index then
            if container.entity and container.entity.valid then
                if check_unit_number ~= unit_number and container.share.state then
                    insert(t, container)
                end
            end
        end
    end
    return t
end

refresh_main_frame = function (data)
    local player = data.player
    local unit_number = data.unit_number

    local container = fetch_container(unit_number)
    local entity = container.entity
    if not entity or not entity.valid then
        return
    end

    local player_gui = this.inf_gui[player.name]
    local volatile_tbl = player_gui.volatile_tbl

    volatile_tbl.clear()

    local mode = container.mode

    if mode ~= 1 then
        if mode ~= 4 then
            remove_link(unit_number)
        end
    end

    if mode ~= 3 then
        if container and container.linked_to then
            container.linked_to = nil
        end
    end

    if mode == 1 then
        local limit_tooltip = '[color=yellow]Limit Info:[/color]\nThis will stop the input after the limit is reached.'
        local clear_tooltip = '[color=yellow]Info:[/color]\nThis will clear all fluids.'
        local share_tooltip =
        '[color=yellow]Share Info:[/color]\nA name for the share so you can easy find it when you want to link it with another container.'

        local primary_tbl = volatile_tbl.add { type = 'table', column_count = 8, name = 'primary_tbl' }

        local limit_one_label = primary_tbl.add({ type = 'label', caption = 'Limit Enabled: ', tooltip = limit_tooltip })
        limit_one_label.style.font = 'heading-2'
        local limit_one_checkbox = primary_tbl.add(
            {
                type = 'checkbox',
                name = 'limit_storage',
                state = container.limit
                    .state
            })
        limit_one_checkbox.tooltip = limit_tooltip
        limit_one_checkbox.style.minimal_height = 25
        limit_one_checkbox.style.minimal_width = 25

        local bottom_flow = primary_tbl.add { type = 'flow' }
        bottom_flow.style.minimal_width = 40

        local limit_two_label = bottom_flow.add({ type = 'label', caption = 'Limit: ', tooltip = limit_tooltip })
        limit_two_label.style.font = 'heading-2'
        local limit_two_text = bottom_flow.add(
            {
                type = 'textfield',
                name = 'limit_number',
                text = container.limit
                    .number,
            })
        limit_two_text.style.width = 80
        limit_two_text.numeric = true
        limit_two_text.tooltip = limit_tooltip
        limit_two_text.style.minimal_width = 25

        this.inf_gui[player.name].text_field = limit_two_text
        this.inf_gui[player.name].limited = limit_one_checkbox

        local private_tooltip =
        '[color=yellow]Private Info:[/color]\nThis will make it so no one else other than you can open this container.'



        local clear_tbl = volatile_tbl.add { type = 'table', column_count = 8, name = 'clear_tbl' }

        local clear_one_label = clear_tbl.add({ type = 'label', caption = 'Clear fluids: ', tooltip = clear_tooltip })
        clear_one_label.style.font = 'heading-2'
        local clear_checkbox = clear_tbl.add(
            {
                type = 'checkbox',
                name = 'clear_checkbox',
                state = container
                    .clear_fluid.state
            })
        clear_checkbox.tooltip = clear_tooltip
        clear_checkbox.style.minimal_height = 25
        clear_checkbox.style.minimal_width = 25
        if not container.item then
            clear_checkbox.enabled = false
            clear_checkbox.tooltip = 'No fluids to clear.'
        end

        local private_label = clear_tbl.add(
            {
                type = 'label',
                caption = 'Private container? ',
                tooltip =
                    private_tooltip
            })
        private_label.style.font = 'heading-2'
        local private_checkbox = clear_tbl.add(
            {
                type = 'checkbox',
                name = 'private_container',
                state = container
                    .private.state
            })
        private_checkbox.tooltip = private_tooltip
        private_checkbox.style.minimal_height = 25

        local share_tbl = volatile_tbl.add { type = 'table', column_count = 8, name = 'share_tbl' }

        local share_one_label = share_tbl.add({ type = 'label', caption = 'Share Enabled: ', tooltip = share_tooltip })
        share_one_label.style.font = 'heading-2'
        local share_one_checkbox = share_tbl.add(
            {
                type = 'checkbox',
                name = 'share_container',
                state = get_share(entity,
                    player).state
            })
        share_one_checkbox.tooltip = share_tooltip
        share_one_checkbox.style.minimal_height = 25
        share_one_checkbox.style.minimal_width = 25

        local share_one_bottom_flow = share_tbl.add { type = 'flow' }
        share_one_bottom_flow.style.minimal_width = 40

        local share_two_label = share_one_bottom_flow.add(
            {
                type = 'label',
                caption = 'Share Name: ',
                tooltip =
                    share_tooltip
            })
        share_two_label.style.font = 'heading-2'
        local share_two_text = share_one_bottom_flow.add(
            {
                type = 'textfield',
                name = 'share_name',
                text = get_share(
                    entity, player).name
            })
        share_two_text.style.width = 150
        share_two_text.allow_decimal = true
        share_two_text.allow_negative = false
        share_two_text.tooltip = share_tooltip
        share_two_text.style.minimal_width = 25
    elseif mode == 3 then
        local linker_tooltip =
        '[color=yellow]Link Info:[/color]\nThis will only work with containers that you have placed.'
        local directions_tooltip =
        '[color=yellow]Direction Info:[/color]\nChoose whether to import the item(s) to the main storage or export the item(s) from the main storage.'

        local linker = volatile_tbl.add { type = 'table', column_count = 8, name = 'linker' }
        if container then
            if container and container.owner ~= player.force.index then
                local link_label = linker.add(
                    {
                        type = 'label',
                        caption = 'Not owner of container. ',
                        tooltip =
                            linker_tooltip
                    })
                link_label.style.font = 'heading-2'
            else
                local directions_tbl = volatile_tbl.add { type = 'table', column_count = 8, name = 'directions_tbl' }
                local state
                if container.direction and container.direction.state then
                    state = container.direction.state
                else
                    state = 'export'
                end
                local directions_switch =
                    directions_tbl.add(
                        {
                            type = 'switch',
                            name = 'directions_container',
                            allow_none_state = false,
                            switch_state = state == 'import' and 'left' or 'right',
                            left_label_caption = 'Import',
                            right_label_caption = 'Export'
                        }
                    )
                directions_switch.tooltip = directions_tooltip

                this.inf_gui[player.name].directions = directions_switch
                local sublinker = volatile_tbl.add { type = 'table', column_count = 1, name = 'sublinker' }
                local itemdesc = volatile_tbl.add { type = 'table', column_count = 2, name = 'itemdesc' }
                local containers = get_owner_containers(container.owner, unit_number)
                local linked_container = fetch_container(container.linked_to)

                if not next(containers) then
                    local link_label = sublinker.add({ type = 'label', caption = 'No containers found.' })
                    link_label.style.font = 'heading-2'
                    return
                end

                if container.linked_to and linked_container then
                    if container.requested_fluid then
                        local localized_name = prototypes.fluid[container.requested_fluid].localised_name
                        local link_label = sublinker.add(
                            {
                                type = 'label',
                                caption = 'Linked with: [color=yellow]' ..
                                    linked_container.share.name .. '[/color]',
                                tooltip = linker_tooltip
                            })
                        link_label.style.font = 'heading-2'
                        link_label = itemdesc.add(
                            {
                                type = 'label',
                                caption = 'Linked item:',
                                tooltip =
                                    linker_tooltip
                            })
                        link_label.style.font = 'heading-2'
                        link_label = itemdesc.add(
                            {
                                type = 'label',
                                caption = localized_name,
                                tooltip =
                                    linker_tooltip
                            })
                        link_label.style.font_color = Color.green
                        link_label.style.font = 'heading-2'
                    else
                        local link_label = sublinker.add(
                            {
                                type = 'label',
                                caption = 'Linked with: [color=yellow]' ..
                                    linked_container.share.name .. '[/color]',
                                tooltip = linker_tooltip
                            })
                        link_label.style.font = 'heading-2'
                    end
                else
                    local link_item_label = sublinker.add(
                        {
                            type = 'label',
                            caption = 'Link with specific item:\n',
                            tooltip =
                                linker_tooltip
                        })
                    link_item_label.style.font = 'heading-2'

                    local item_scroll_pane =
                        sublinker.add
                        {
                            type = 'scroll-pane',
                            vertical_scroll_policy = 'auto',
                            horizontal_scroll_policy = 'never'
                        }
                    local item_scroll_style = item_scroll_pane.style
                    item_scroll_style.maximal_height = 150
                    item_scroll_style.vertically_squashable = true
                    item_scroll_style.bottom_padding = 2
                    item_scroll_style.left_padding = 2
                    item_scroll_style.right_padding = 2
                    item_scroll_style.top_padding = 2
                    local itemlinker = item_scroll_pane.add { type = 'table', column_count = 8, name = 'itemlinker' }

                    for i = 1, #containers do
                        if containers then
                            local container_chest = containers[i]
                            if type(container_chest) ~= 'string' then
                                if container_chest.item then
                                    local localized_name = prototypes.fluid[container_chest.item].localised_name

                                    local flowlinker = itemlinker.add { type = 'flow' }
                                    local container_item =
                                        flowlinker.add
                                        {
                                            type = 'sprite-button',
                                            name = item_name_frame_name,
                                            style = 'slot_button',
                                            sprite = 'fluid/' .. container_chest.item,
                                            tooltip = { '', localized_name, '\n', container_chest.share.name, '\n', container_chest.count }
                                        }
                                    Gui.set_data(container_item,
                                        { name = container_chest.item, unit_number = unit_number, share = container_chest.share.name })
                                end
                            end
                        end
                    end
                    -- if directions_switch.switch_state == 'import' then
                    sublinker.add({ type = 'line' })
                    local link_container_label = sublinker.add(
                        {
                            type = 'label',
                            caption = 'Link with container:\n',
                            tooltip =
                                linker_tooltip
                        })
                    link_container_label.style.font = 'heading-2'
                    local container_scroll_pane =
                        sublinker.add
                        {
                            type = 'scroll-pane',
                            vertical_scroll_policy = 'auto',
                            horizontal_scroll_policy = 'never'
                        }
                    local container_scroll_style = container_scroll_pane.style
                    container_scroll_style.maximal_height = 150
                    container_scroll_style.vertically_squashable = true
                    container_scroll_style.bottom_padding = 2
                    container_scroll_style.left_padding = 2
                    container_scroll_style.right_padding = 2
                    container_scroll_style.top_padding = 2
                    local containerlinker = container_scroll_pane.add { type = 'table', column_count = 8, name = 'containerlinker' }

                    for i = 1, #containers do
                        if containers then
                            local container_chest = containers[i]
                            if type(container_chest) ~= 'string' then
                                local flowlinker = containerlinker.add { type = 'flow' }
                                local containeritem = flowlinker.add { type = 'sprite-button', name = item_name_frame_name, style = 'slot_button', sprite = 'item/' .. container_chest.entity.name, tooltip = 'Container share name: ' .. container_chest.share.name }
                                Gui.set_data(containeritem,
                                    { name = nil, unit_number = unit_number, share = container_chest.share.name })
                            end
                            -- end
                        end
                    end
                end
            end
        end
    end
end

local function gui_opened(event)
    if not event.gui_type == defines.gui_type.entity then
        return
    end
    local entity = event.entity
    if not (entity and entity.valid) then
        return
    end
    if not this.valid_storage[entity.type] then
        return
    end
    local unit_number = entity.unit_number
    local player = game.get_player(event.player_index)

    local container = fetch_container(unit_number)
    if not container then
        return
    end

    if container.private.state then
        if player.index ~= container.private.owner and not player.admin then
            player.opened = nil
            return
        end
    end

    local frame = player.gui.center[tostring(unit_number)]
    if not frame or not frame.valid then
        frame =
            player.gui.center.add
            {
                type = 'frame',
                caption = 'Unlimited Storage',
                direction = 'vertical',
                name = tostring(unit_number)
            }
    end

    local controls = frame.add { type = 'flow', direction = 'horizontal' }
    local controls2 = frame.add { type = 'flow', direction = 'horizontal' }
    local fluids = frame.add { type = 'flow', direction = 'vertical' }

    local mode = container.mode
    local selected = mode and mode or 1
    local controltbl = controls.add { type = 'table', column_count = 1 }
    local btntbl = controltbl.add { type = 'table', column_count = 2 }
    local modetbl = controltbl.add { type = 'table', column_count = 2 }
    local volatile_tbl = controls2.add { type = 'table', column_count = 1 }

    local mode_tooltip =
    '[color=yellow]Mode Info:[/color]\nEnabled: will active the container and allow for insertions.\nDisabled: will deactivate the container and let´s the player utilize the GUI to retrieve fluids.\nLink: Link a container with another container. Content is divided between them.'

    local btn =
        btntbl.add
        {
            type = 'sprite-button',
            tooltip = '[color=blue]Info![/color]\nContainer ID: ' .. unit_number .. '\nThis container stores unlimited quantity of a fluid',
            sprite = Gui.info_icon
        }
    btn.style.height = 20
    btn.style.width = 20
    btn.enabled = false
    btn.focus()

    local mode_label = modetbl.add { type = 'label', caption = 'Mode: ', tooltip = mode_tooltip }
    mode_label.style.font = 'heading-2'
    local drop_down_fluids

    if player.admin and (this.editor[player.name]) then
        drop_down_fluids = { 'Enabled', 'Disabled', 'Link', 'Editor' }
    else
        drop_down_fluids = { 'Enabled', 'Disabled', 'Link' }
    end

    if container.mode == 3 and container.linked_to then
        local master_storage_btn =
            btntbl.add
            {
                type = 'sprite-button',
                name = master_storage_btn_name,
                tooltip = 'Click to make this storage a master storage.',
                sprite = 'utility/bookmark'
            }
        master_storage_btn.style.height = 20
        master_storage_btn.style.width = 20
        master_storage_btn.enabled = true
    end

    local drop_down =
        modetbl.add
        {
            type = 'drop-down',
            items = drop_down_fluids,
            selected_index = selected,
            name = unit_number,
            tooltip = mode_tooltip
        }

    this.inf_gui[player.name] =
    {
        fluid_frame = fluids,
        frame = frame,
        volatile_tbl = volatile_tbl,
        drop_down = drop_down,
        entity = entity,
        updated = false
    }

    container.mode = drop_down.selected_index
    player.opened = frame

    refresh_main_frame({ unit_number = unit_number, player = player })
end

local function on_built_entity(event, raised)
    if this.disable_normal_placement and not raised then
        return
    end
    local entity = event.entity
    local stack = event.stack
    if not entity.valid then
        return
    end
    if not this.valid_storage[entity.type] then
        return
    end
    if event.player_index then
        local player = game.get_player(event.player_index)
        local c = restore_container(entity, player)
        if c then
            gui_opened(event)
        end

        local s = create_container(entity, stack, player)
        if s then
            gui_opened(event)
        end
    end
end

local function update_gui()
    for _, player in pairs(game.connected_players) do
        local container_gui_data = this.inf_gui[player.name]
        if not container_gui_data then
            goto continue
        end
        local frame = container_gui_data.fluid_frame
        local entity = container_gui_data.entity
        if not frame then
            goto continue
        end
        if not entity or not entity.valid then
            goto continue
        end

        local unit_number = entity.unit_number
        local container = fetch_container(unit_number)

        local mode = container.mode
        if (mode == 2 or mode == 4) and this.inf_gui[player.name].updated then
            goto continue
        end
        if not frame or not frame.valid then
            goto continue
        end

        frame.clear()

        local tbl = frame.add { type = 'table', column_count = 10, name = 'infinity_storage_inventory' }

        if not container.item or not container.count then
            if mode == 1 or mode == 2 then
                local no_fluid = tbl.add { type = 'sprite-button', style = 'slot_button' }
                no_fluid.enabled = false
            elseif mode == 4 then
                local no_fluid = tbl.add { type = 'choose-elem-button', style = 'slot_button', elem_type = 'fluid' }
                no_fluid.enabled = true
            end
            this.inf_gui[player.name].updated = true
            goto continue
        end

        local btn
        if container.requested_fluid then
            local localized_name = prototypes.fluid[container.requested_fluid].localised_name
            local flow = tbl.add { type = 'flow' }
            flow.style.horizontally_stretchable = true
            btn =
                flow.add
                {
                    type = 'sprite-button',
                    sprite = 'fluid/' .. container.requested_fluid,
                    style = 'slot_button',
                    name = container.requested_fluid,
                    tooltip = localized_name
                }
            btn.enabled = false
        end

        local inventory_count = entity.get_fluid_count(container.item)
        local total_fluid_count = inventory_count + container.count

        if mode == 1 or mode == 3 then
            local localized_name = prototypes.fluid[container.item].localised_name
            if container.requested_fluid and tbl[container.requested_fluid] then
                tbl[container.requested_fluid].number = total_fluid_count
            else
                btn =
                    tbl.add
                    {
                        type = 'sprite-button',
                        sprite = 'fluid/' .. container.item,
                        style = 'slot_button',
                        number = total_fluid_count,
                        name = container.item,
                        tooltip = localized_name
                    }
                btn.enabled = false
            end
        elseif mode == 2 or mode == 4 then
            local localized_name = prototypes.fluid[container.item].localised_name
            btn =
                tbl.add
                {
                    type = 'sprite-button',
                    sprite = 'fluid/' .. container.item,
                    tooltip = localized_name,
                    style = 'slot_button',
                    number = total_fluid_count,
                    name = container.item
                }
            btn.enabled = true
        end

        this.inf_gui[player.name].updated = true
        ::continue::
    end
end

local function gui_closed(event)
    local player = game.get_player(event.player_index)
    local type = event.gui_type

    if type == defines.gui_type.custom then
        local data = this.inf_gui[player.name]
        if not data then
            return
        end
        data.frame.destroy()
        this.inf_gui[player.name] = nil
    end
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
    local name = element.name

    if name == 'linker' then
        local fluids = element.fluids
        if not fluids then
            return
        end
        local selected = fluids[element.selected_index]
        if not selected then
            return
        end
        if element.selected_index == 1 then
            return
        end
        local unit_number = this.inf_gui[player.name] and this.inf_gui[player.name].entity and
            this.inf_gui[player.name].entity.unit_number
        local container = fetch_container(unit_number)
        if container then
            local _, _unit_number = fetch_share(player, selected)
            if _unit_number then
                container.linked_to = _unit_number
                local linked_container = fetch_container(_unit_number)
                if linked_container then
                    if not linked_container.links then
                        linked_container.links = {}
                    end
                    if not linked_container.links[unit_number] then
                        linked_container.links[unit_number] = true
                    end
                end
            else
                container.linked_to = selected
            end
            this.inf_gui[player.name].updated = false
            toggle_render(container)
            refresh_main_frame({ unit_number = unit_number, player = player })
            return
        end
    end

    local unit_number = tonumber(element.name)
    if unit_number then
        local container = fetch_container(unit_number)
        if not container or not container.mode then
            return
        end
        container.mode = element.selected_index
        local mode = container.mode

        refresh_main_frame({ unit_number = unit_number, player = player })

        toggle_render(container)

        if mode >= 2 then
            this.inf_gui[player.name].updated = false
            return
        end
    end
end

function Public.remove_player(index)
    local containers = this.main_containers
    if next(containers) then
        for unit_number, container in pairs(containers) do
            if container.private.owner == index then
                if container.entity and container.entity.valid then
                    container.entity.destroy()
                end
                remove_container(unit_number)
            end
        end
    end

    this.saved_containers[index] = nil
end

local function gui_click(event)
    local element = event.element
    local player = game.get_player(event.player_index)
    if not validate_player(player) then
        return
    end
    if not element.valid then
        return
    end
    if element.name == 'directions_container' then
        local pGui = this.inf_gui[player.name]
        if not pGui then
            return
        end

        local entity = pGui.entity
        if not (entity and entity.valid) then
            return
        end
        local unit_number = entity.unit_number
        local container = fetch_container(unit_number)
        container.direction.state = element.switch_state
        this.inf_gui[player.name].updated = false
        return
    end

    local parent = element.parent
    if not parent then
        return
    end
    if parent.name ~= 'infinity_storage_inventory' then
        return
    end
    local unit_number = tonumber(parent.parent.parent.name)
    if tonumber(element.name) == unit_number then
        return
    end

    local shift = event.shift
    local ctrl = event.control
    local container = fetch_container(unit_number)
    local mode = container.mode

    if not container.item then
        return
    end

    if player.admin then
        if mode == 4 then
            if ctrl then
                container.count = container.count + 500000
                goto update
            elseif shift then
                container.count = container.count - 500000
                if container.count <= 0 then
                    container.item = nil
                    container.count = 0
                    container.entity.clear_fluid_inside()
                end
                goto update
            end
        end
    end

    if mode == 1 then
        return
    end

    ::update::

    this.inf_gui[player.name].updated = false
end

local function on_gui_elem_changed(event)
    local element = event.element
    local player = game.get_player(event.player_index)
    if not validate_player(player) then
        return
    end
    if not element.valid then
        return
    end
    local parent = element.parent
    if not parent then
        return
    end
    if parent.name ~= 'infinity_storage_inventory' then
        return
    end
    local unit_number = tonumber(parent.parent.parent.name)
    if tonumber(element.name) == unit_number then
        return
    end

    local container = fetch_container(unit_number)

    local button = event.button
    local name = element.elem_value

    if button == defines.mouse_button_type.right then
        container.item = nil
        container.count = 0
        container.entity.clear_fluid_inside()
        if this.inf_gui[player.name] then
            this.inf_gui[player.name].updated = false
        end
        return
    end

    if not name then
        return
    end
    container.item = name
    container.count = 500000

    if this.inf_gui[player.name] then
        this.inf_gui[player.name].updated = false
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
    local state = element.state and true or false

    local pGui = this.inf_gui[player.name]
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

    if element.name == 'private_container' then
        container.private.state = state
    elseif element.name == 'limit_storage' then
        container.limit.state = state
    elseif element.name == 'clear_checkbox' then
        if container.item then
            if not pGui.validate then
                player.print(module_name .. 'Are you sure you want to clear all fluids?', Color.warning)
                pGui.validate = true
                Task.set_timeout_in_ticks(30, delay_refresh_main_frame_task_token,
                    { player_index = player.index, unit_number = container.unit_number })
                return
            end

            pGui.validate = nil

            player.print(module_name .. 'Cleared all fluids.')
            container.clear_fluid.state = false
            container.item = nil
            container.count = 0
            container.entity.clear_fluid_inside()
            Task.set_timeout_in_ticks(30, delay_refresh_main_frame_task_token,
                { player_index = player.index, unit_number = container.unit_number })
        else
            Task.set_timeout_in_ticks(30, delay_refresh_main_frame_task_token,
                { player_index = player.index, unit_number = container.unit_number })
        end
        return
    elseif element.name == 'share_container' then
        if container.share.name ~= 'Share name' then
            container.direction.state = 'import'
            if container.share.state then
                remove_link(unit_number)
                container.direction.state = 'export'
            end
            container.share.state = state
            toggle_render(container)
        else
            player.print(module_name .. 'Please provide a valid share name.', Color.warning)
            element.state = false
        end
    end

    pGui.updated = false
end

Event.on_nth_tick(
    10,
    function ()
        if not this or not this.enabled then
            validate()
            return
        end
        local fluid_prototypes = prototypes.fluid
        update_container(fluid_prototypes)
    end
)

Event.on_nth_tick(
    5,
    function ()
        if not this or not this.enabled then
            validate()
            return
        end
        update_gui()
    end
)

Gui.on_click(
    convert_to_infinite_container,
    function (event)
        local player = event.player
        local inventory = player.get_main_inventory()
        local player_item_count = inventory.get_item_count('coin')

        if player_item_count >= this.cost_to_convert then
            local entity = Gui.get_data(event.element)
            if entity and entity.valid then
                player.remove_item({ name = 'coin', count = this.cost_to_convert })
                player.opened = nil
                event.entity = entity
                event.entity = entity

                on_built_entity(event, true)
            end
        else
            player.print(module_name .. 'Not enough coins.', Color.warning)
        end
    end
)

Event.add(
    defines.events.on_gui_opened,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        local panel = player.gui.relative
        local entity = event.entity

        if entity and entity.valid and this.valid_storage[entity.type] then
            draw_convert_button(panel, entity)
        end

        gui_opened(event)
    end
)

Event.add(
    defines.events.on_gui_closed,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        gui_closed(event)

        local relative = player.gui.relative
        local panel = relative[converter_frame_for_player_name]
        if panel and panel.valid then
            Gui.destroy(panel)
        end
    end
)

Gui.on_click(
    master_storage_btn_name,
    function (event)
        local player = event.player
        local chest_gui_data = this.inf_gui[player.name]
        if not chest_gui_data then
            return
        end

        if not chest_gui_data.validation then
            player.print('Are you sure you want to make this storage a master storage?', Color.warning)
            chest_gui_data.validation = true
            return
        end

        local entity = chest_gui_data.entity
        if not entity or not entity.valid then
            return
        end

        local source_container = fetch_container(entity.unit_number)
        if not source_container then
            player.print('This storage is not a valid storage.', Color.warning)
            return
        end

        if source_container.mode ~= 3 then
            player.print('This storage is not a slave storage.', Color.warning)
            return
        end

        local destination_container = fetch_container(source_container.linked_to)
        if not destination_container then
            player.print('This storage is not a valid storage.', Color.warning)
            return
        end

        if destination_container.mode ~= 1 then
            player.print('This storage is not a master storage.', Color.warning)
            return
        end

        make_master_storage(player, source_container, destination_container)
        player.print('Successfully made this storage a master storage.', Color.success)
        chest_gui_data.validation = nil
        if chest_gui_data.frame and chest_gui_data.frame.valid then
            chest_gui_data.frame.destroy()
        end
    end
)

Gui.on_click(
    item_name_frame_name,
    function (event)
        local data = Gui.get_data(event.element)
        if not data then
            return
        end

        local _, _unit_number = fetch_share(event.player, data.share)
        if _unit_number then
            local container = fetch_container(data.unit_number)
            container.linked_to = _unit_number
            container.requested_fluid = data.name

            local linked_container = fetch_container(_unit_number)
            if linked_container then
                if not linked_container.links then
                    linked_container.links = {}
                end
                if not linked_container.links[container.unit_number] then
                    linked_container.links[container.unit_number] = true
                end
            end
            this.inf_gui[event.player.name].updated = false
            toggle_render(container)
            refresh_main_frame({ unit_number = container.unit_number, player = event.player })
        end
    end
)

Event.add(defines.events.on_gui_click, gui_click)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)
Event.add(defines.events.on_gui_selection_state_changed, state_changed)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_gui_elem_changed, on_gui_elem_changed)
Event.add(defines.events.on_gui_checked_state_changed, on_gui_checked_state_changed)
Event.add(defines.events.on_gui_text_changed, text_changed)
Event.add(
    defines.events.on_player_removed,
    function (event)
        Public.remove_player(event.player_index)
    end
)

Event.on_configuration_changed(
    function ()
        validate()
    end
)

Commands.new('increase_fluid', 'Increases fluid capacity')
    :require_role('infinity_storage')
    :callback(function (player)
        if player.selected and player.selected.unit_number then
            local linked_container = fetch_container(player.selected.unit_number)
            if linked_container and linked_container.count then
                linked_container.count = linked_container.count + 5000000
                player.print('Fluid capacity increased by 5000000.', Color.success)
            else
                player.print('Please select a container.', Color.warning)
            end
        else
            player.print('Please select a container.', Color.warning)
        end
    end
    )


Commands.new('toggle_storage_render', 'Changes the render state of the storage')
    :require_role('infinity_storage')
    :callback(function (player)
        for _, container in pairs(this.main_containers) do
            toggle_render(container)
        end
        player.print('[Infinity Storage] Render state changed.', Color.success)
    end
    )

return Public
