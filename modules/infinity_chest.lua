local Event = require 'utils.event'
local Color = require 'utils.color_presets'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Commands = require 'utils.commands'

local this =
{
    main_containers = {},
    inf_gui = {},
    saved_containers = {},
    valid_chests =
    {
        -- ['infinity-chest'] = true
        ['iron-chest'] = true,
        ['steel-chest'] = true,
        ['passive-provider-chest'] = true
    },
    enabled = true,
    editor = {},
    disable_normal_placement = true,
    debug = false,
    cost_to_convert = 200,
    limit_some_items = false,
    valid_items =
    {
        ['coal'] = true,
        ['stone'] = true,
        ['iron-ore'] = true,
        ['copper-ore'] = true,
        ['uranium-ore'] = true,
        ['wood'] = true,
        ['barrel'] = true,
        ['crude-oil-barrel'] = true,
        ['heavy-oil-barrel'] = true,
        ['light-oil-barrel'] = true,
        ['lubricant-barrel'] = true,
        ['petroleum-gas-barrel'] = true,
        ['sulfuric-acid-barrel'] = true,
        ['water-barrel'] = true,
        ['firearm-magazine'] = true,
        ['piercing-rounds-magazine'] = true,
        ['uranium-rounds-magazine'] = true
    }
}

local chest_converter_frame_for_player_name = Gui.uid_name()
local convert_chest_to_infinite_chest = Gui.uid_name()
local item_name_frame_name = Gui.uid_name()
local upgrade_chest_btn_name = Gui.uid_name()
local master_chest_btn_name = Gui.uid_name()
local info_chest_btn_name = Gui.uid_name('info_chest')
local player_container_summary_frame_name = Gui.uid_name('player_container_summary_frame')
local player_container_summary_close_btn_name = Gui.uid_name('player_container_summary_close_btn')

local default_limit = 1000
local module_name = '[Infinity Chests] '
local insert = table.insert
local floor = math.floor
-- local floor = math.floor
local pairs = pairs
local Public = {}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local remove_chest
local toggle_render

function Public.get_table()
    return this
end

local function draw_convert_chest_button(parent, entity)
    local frame = parent[chest_converter_frame_for_player_name]
    if frame and frame.valid then
        Gui.destroy(frame)
    end

    local ancor_type = defines.relative_gui_type.container_gui

    -- if entity.type == 'asteroid-collector' then
    --     ancor_type = defines.relative_gui_type.asteroid_collector_gui
    -- elseif entity.type == 'space-platform-hub' then
    --     ancor_type = defines.relative_gui_type.space_platform_hub_gui
    -- end

    local anchor =
    {
        gui = ancor_type,
        position = defines.relative_gui_position.right
    }
    frame =
        parent.add
        {
            type = 'frame',
            name = chest_converter_frame_for_player_name,
            anchor = anchor,
            direction = 'vertical'
        }

    local button =
        frame.add
        {
            type = 'sprite-button',
            sprite = 'item/' .. entity.name,
            name = convert_chest_to_infinite_chest,
            style = Gui.button_style,
            tooltip = '[color=blue][Infinity chest][/color]\nYou can easily convert this chest to an infinity chest.\nAllowing almost unlimited items to be stored.\n\nCosts ' .. this.cost_to_convert .. ' coins.'
        }
    Gui.set_data(button, entity)
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

local function item_counter(container)
    local count = 0

    local storage = container.item_storage
    if not storage then
        return count
    end

    if storage.count then
        storage.count = nil
    end

    for _, item_count in pairs(storage) do
        count = count + item_count
    end

    return count
end

local function aggregate_owned_container_items(player)
    local merged_items = {}
    for _, container in pairs(this.main_containers) do
        local private = container and container.private
        if private and private.owner == player.index then
            local item_storage = container.item_storage
            if item_storage then
                for item_name, item_count in pairs(item_storage) do
                    if type(item_name) == 'string' and item_name ~= 'count' and type(item_count) == 'number' and item_count > 0 then
                        merged_items[item_name] = (merged_items[item_name] or 0) + item_count
                    end
                end
            end

            local content = container.content
            if content and content.valid then
                for _, item_data in pairs(content.get_contents()) do
                    if item_data and item_data.name and item_data.count and item_data.count > 0 then
                        merged_items[item_data.name] = (merged_items[item_data.name] or 0) + item_data.count
                    end
                end
            end
        end
    end
    return merged_items
end

local function destroy_player_container_summary_frame(player)
    local frame = player.gui.center[player_container_summary_frame_name]
    if frame and frame.valid then
        Gui.destroy(frame)
    end
end

local function draw_player_container_summary_frame(player)
    destroy_player_container_summary_frame(player)
    local frame =
        player.gui.center.add
        {
            type = 'frame',
            name = player_container_summary_frame_name,
            caption = 'All items across all containers',
            direction = 'vertical'
        }

    local header = frame.add { type = 'flow', direction = 'horizontal' }
    header.style.horizontally_stretchable = true
    local spacer = header.add { type = 'empty-widget' }
    spacer.style.horizontally_stretchable = true
    local close_button =
        header.add
        {
            type = 'sprite-button',
            name = player_container_summary_close_btn_name,
            style = 'frame_action_button',
            mouse_button_filter = { 'left' },
            sprite = 'utility/close',
            hovered_sprite = 'utility/close_fat',
            clicked_sprite = 'utility/close_fat',
            tooltip = 'Close',
            tags =
            {
                action = 'close_main_frame_gui'
            }
        }
    close_button.style.left_margin = 4

    local items = aggregate_owned_container_items(player)
    local entries = {}
    for item_name, item_count in pairs(items) do
        entries[#entries + 1] = { name = item_name, count = item_count }
    end
    table.sort(
        entries,
        function (a, b)
            return a.count > b.count
        end
    )

    if #entries == 0 then
        frame.add { type = 'label', caption = 'No items stored in your containers.' }
        player.opened = frame
        return
    end

    local scroll_pane =
        frame.add
        {
            type = 'scroll-pane',
            vertical_scroll_policy = 'auto',
            horizontal_scroll_policy = 'never'
        }
    scroll_pane.style.maximal_height = 420
    scroll_pane.style.maximal_width = 620
    scroll_pane.style.vertically_squashable = true
    scroll_pane.style.horizontally_stretchable = true

    local table_items = scroll_pane.add { type = 'table', column_count = 10 }
    local item_prototypes = prototypes.item
    for _, entry in pairs(entries) do
        local item_name = entry.name
        local item_count = entry.count
        local item_prototype = item_prototypes[item_name]
        if item_prototype then
            local button =
                table_items.add
                {
                    type = 'sprite-button',
                    sprite = 'item/' .. item_name,
                    style = 'slot_button',
                    number = item_count,
                    name = item_name,
                    tooltip = { '', item_prototype.localised_name, '\nCount: ', item_count }
                }
            button.enabled = false
        end
    end

    -- player.opened = frame
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

local function make_master_chest(player, source_container, destination_container)
    local master, slave
    if source_container.linked_to == destination_container.unit_number then
        master = destination_container
        slave = source_container
    else
        player.print('This chest is not linked to the destination chest (0).', Color.warning)
        return
    end

    if master.mode ~= 1 or slave.mode ~= 3 then
        player.print('This chest is not a valid chest (1).', Color.warning)
        return
    end

    local links = master.links
    if not links then
        player.print('This chest is not linked to the destination chest (2).', Color.warning)
        return
    end
    local slave_un = slave.unit_number
    if not links[slave_un] and not links[tostring(slave_un)] then
        player.print('This chest is not linked to the destination chest (3).', Color.warning)
        return
    end

    local old_master_un = master.unit_number
    local new_master_un = slave_un

    local stored_items = master.item_storage
    master.item_storage = {}

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
    master.destination_container = slave
    master.mode = 3
    if master.share then
        master.share.state = false
        master.share.name = old_master_un
    end
    master.full = false
    master.destination_full = false

    slave.linked_to = nil
    slave.mode = 1
    slave.links = new_links
    slave.destination_container = nil
    slave.limit = master.limit
    slave.item_storage = stored_items or {}
    if slave.share then
        slave.share.state = true
        if share_name ~= nil then
            slave.share.name = share_name
        end
    end
    slave.full = false
    slave.destination_full = false

    for _, data in pairs(this.main_containers) do
        if data and data.linked_to == old_master_un and data.unit_number ~= new_master_un then
            data.linked_to = new_master_un
        end
    end

    toggle_render(master)
    toggle_render(slave)
end

Public.make_master_chest = make_master_chest

toggle_render = function (container)
    if not container.chest or not container.chest.valid then
        remove_chest(container.unit_number)
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
                surface = container.chest.surface,
                target = { entity = container.chest, offset = { 0, -0.6 } },
                scale = 1,
                color = { r = 0, g = 0.6, b = 1 },
                alignment = 'center',
            }
    elseif container.linked_to then
        container.render =
            rendering.draw_text
            {
                text = 'L',
                surface = container.chest.surface,
                target = { entity = container.chest, offset = { 0, -0.6 } },
                scale = 1,
                color = { r = 0, g = 0.6, b = 1 },
                alignment = 'center',
            }
    else
        container.render =
            rendering.draw_text
            {
                text = '♾',
                surface = container.chest.surface,
                target = { entity = container.chest, offset = { 0, -0.6 } },
                scale = 1,
                color = { r = 0, g = 0.6, b = 1 },
                alignment = 'center',
            }
    end
end

local function create_chest(entity, player)
    if entity.type == 'container' then
        entity.active = false
    end
    local unit_number = entity.unit_number

    if not does_exists(unit_number) then
        local container =
        {
            chest = entity,
            content = entity.get_inventory(defines.inventory.chest),
            owner = player.force.index,
            unit_number = unit_number,
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
            item_storage = {},
            total_slots = 48
        }
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
        create_chest(entity, player)
    end

    return container.share
end

local function restore_chest(entity, player)
    if this.saved_containers[player.index] and has_value(this.saved_containers[player.index]) >= 1 then
        if not this.enabled then
            goto continue
        end

        local chest_index = this.saved_containers[player.index]
        local chest_to_place = return_value(chest_index)

        local container =
        {
            chest = entity,
            content = entity.get_inventory(defines.inventory.chest),
            owner = player.force.index,
            unit_number = entity.unit_number,
            limit = chest_to_place.limit,
            direction = chest_to_place.direction,
            share = chest_to_place.share,
            private = chest_to_place.private,
            mode = 1,
            item_storage = chest_to_place.item_storage,
            total_slots = 48
        }

        local c = add_object(entity.unit_number, container)
        toggle_render(c)
        return true
    end
    ::continue::
    return false
end

local function built_entity_robot(event)
    if this.disable_normal_placement then
        return
    end
    local entity = event.entity
    if not entity.valid then
        return
    end
    if not this.valid_chests[entity.name] then
        return
    end

    local robot = event.robot
    if robot and robot.valid then
        local created = event.entity
        if created and created.valid then
            local inventory = robot.get_inventory(defines.inventory.robot_cargo)
            inventory.insert({ name = created.name, count = 1 })
            created.destroy()
        end
    end
end

local function relink_chests(old_unit_number, new_unit_number)
    if not old_unit_number then
        return
    end

    for _, data in pairs(this.main_containers) do
        if data and data.linked_to and data.linked_to == old_unit_number then
            data.linked_to = new_unit_number
        end
    end
end

local function upgrade_chest(player, entity, chest_gui_data)
    if chest_gui_data.frame and chest_gui_data.frame.valid then
        chest_gui_data.frame.destroy()
    end

    local container = fetch_container(entity.unit_number)
    if not container then
        return
    end

    if container.render then
        container.render.destroy()
    end

    local position = entity.position
    local surface = entity.surface
    local force = entity.force

    local new_entity = surface.create_entity { name = 'passive-provider-chest', position = position, force = force }
    if not new_entity then
        return
    end

    local content = new_entity.get_inventory(defines.inventory.chest)
    local unit_number = new_entity.unit_number
    local old_unit_number = entity.unit_number

    -- transfer everything from the old container to the new container real storage not virtual storage
    for _, item in pairs(container.content.get_contents()) do
        content.insert(item)
    end

    container.chest = new_entity
    container.content = content
    container.unit_number = unit_number

    local deep_new_container = table.deepcopy(container)
    this.main_containers[unit_number] = deep_new_container

    this.main_containers[old_unit_number] = nil

    relink_chests(old_unit_number, unit_number)

    entity.destroy()

    toggle_render(container)
    this.inf_gui[player.name] = nil
end

local function item(item_data, inv, container, item_prototypes)
    if not item_data then
        return
    end
    if not item_prototypes[item_data.name] then
        return
    end
    local item_stack = item_prototypes[item_data.name].stack_size
    local diff = item_data.count - item_stack

    local storage = container.item_storage
    if not storage then
        container.item_storage = {}
        storage = container.item_storage
    end

    local mode = container.mode
    if mode == 2 then
        diff = 2 ^ 31
    elseif mode == 4 then
        diff = 2 ^ 31
    end

    if container.destination_full then return end

    if diff > 0 then
        if not storage[item_data.name] then
            local count = inv.remove({ name = item_data.name, count = diff })
            storage[item_data.name] = count
        else
            local count = inv.remove({ name = item_data.name, count = diff })
            storage[item_data.name] = storage[item_data.name] + count
        end
    elseif diff < 0 then
        if not storage[item_data.name] then
            return
        end
        if storage[item_data.name] > (diff * -1) then -- more items in central storage and chest has lower
            local inserted = inv.insert({ name = item_data.name, count = (diff * -1) })
            storage[item_data.name] = storage[item_data.name] - inserted
        else -- less items in central storage - remove central storage after ins
            if storage[item_data.name] > 0 then
                inv.insert({ name = item_data.name, count = storage[item_data.name] })
            end
            storage[item_data.name] = nil
        end
    end
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
                    l_container.destination_container = nil
                    toggle_render(l_container)
                end
            end
        end
    end
end

remove_chest = function (unit_number)
    remove_link(unit_number)
    remove_object(unit_number)
end

local function item_links(data)
    local source_item_storage = data.source_container.item_storage
    local destination_content = data.destination_container.content
    local destination_direction = data.destination_container.direction
    local destination_requested_item = data.destination_container.requested_item

    if data.destination_container.mode == 3 and data.destination_container.destination_full then return end

    if destination_direction.state == 'import' then
        local destination_storage_content = destination_content.get_contents()

        for _, item_data in pairs(destination_storage_content) do
            if destination_requested_item then
                if item_data.name == destination_requested_item then
                    local source_item = source_item_storage[destination_requested_item]
                    if not source_item then
                        source_item_storage[destination_requested_item] = 0
                    end

                    local inserted = destination_content.remove(
                        {
                            name = destination_requested_item,
                            count = item_data
                                .count,
                            quality = item_data.quality
                        })
                    source_item_storage[destination_requested_item] = source_item_storage[destination_requested_item] +
                        inserted
                end
            else
                local source_item = source_item_storage[item_data.name]
                if not source_item then
                    source_item_storage[item_data.name] = 0
                end

                local inserted = destination_content.remove({ name = item_data.name, count = item_data.count })
                source_item_storage[item_data.name] = source_item_storage[item_data.name] + inserted
            end
        end
    else
        for item_name, item_count in pairs(source_item_storage) do
            local item_data =
            {
                name = item_name,
                count = item_count,
                quality = 'normal'
            }
            if not prototypes.item[item_data.name] then
                break
            end
            local item_stack = prototypes.item[item_data.name].stack_size

            if destination_requested_item then
                if item_data.name == destination_requested_item then
                    if item_data.count and item_data.count > 0 then
                        local dest_item = destination_content.get_item_count(destination_requested_item)
                        if not dest_item or dest_item == 0 then
                            local to_insert = item_data.count
                            if to_insert > item_stack then
                                to_insert = floor(item_stack / 2)
                            elseif to_insert > 1 then
                                to_insert = floor(to_insert / 2)
                            end

                            if item_stack == 1 then
                                to_insert = 1
                            end

                            local inserted = destination_content.insert(
                                {
                                    name = destination_requested_item,
                                    count =
                                        to_insert,
                                    quality = item_data.quality
                                })
                            source_item_storage[destination_requested_item] = source_item_storage
                                [destination_requested_item] - inserted
                            if source_item_storage[destination_requested_item] < 0 then
                                source_item_storage[destination_requested_item] = nil
                            end
                        else
                            local dest_diff_remote_storage = source_item_storage[destination_requested_item] - dest_item
                            local dest_diff_local_storage = item_stack - dest_item
                            if dest_diff_remote_storage > 0 and dest_diff_local_storage > 0 and dest_diff_local_storage < item_stack then
                                if source_item_storage[destination_requested_item] >= dest_diff_local_storage then
                                    local inserted = destination_content.insert(
                                        {
                                            name = destination_requested_item,
                                            count =
                                                dest_diff_local_storage,
                                            quality = item_data.quality
                                        })
                                    source_item_storage[destination_requested_item] = source_item_storage
                                        [destination_requested_item] - inserted
                                    if source_item_storage[destination_requested_item] < 0 then
                                        source_item_storage[destination_requested_item] = nil
                                    end
                                end
                            end
                        end
                    end
                end
            else
                if item_data.count > 0 then
                    local dest_item = destination_content.get_item_count(item_data.name)
                    if not dest_item or dest_item == 0 then
                        local to_insert = item_data.count
                        if to_insert > item_stack then
                            to_insert = floor(item_stack / 2)
                        elseif to_insert > 1 then
                            to_insert = floor(to_insert / 2)
                        end

                        if item_stack == 1 then
                            to_insert = 1
                        end

                        local inserted = destination_content.insert(
                            {
                                name = item_data.name,
                                count = to_insert,
                                quality =
                                    item_data.quality
                            })
                        source_item_storage[item_data.name] = source_item_storage[item_data.name] - inserted
                        if source_item_storage[item_data.name] < 0 then
                            source_item_storage[item_data.name] = nil
                        end
                    else
                        local dest_diff_remote_storage = source_item_storage[item_data.name] - dest_item
                        local dest_diff_local_storage = item_stack - dest_item
                        if dest_diff_remote_storage > 0 and dest_diff_local_storage > 0 and dest_diff_local_storage < item_stack then
                            if source_item_storage[item_data.name] >= dest_diff_local_storage then
                                local inserted = destination_content.insert(
                                    {
                                        name = item_data.name,
                                        count =
                                            dest_diff_local_storage,
                                        quality = item_data.quality
                                    })
                                source_item_storage[item_data.name] = source_item_storage[item_data.name] - inserted
                                if source_item_storage[item_data.name] < 0 then
                                    source_item_storage[item_data.name] = nil
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function item_links_ores_only(data)
    local destination_direction = data.destination_container.direction
    local destination_requested_item = data.destination_container.requested_item

    if destination_direction.state == 'import' then
        local source_item_storage = data.source_container.item_storage
        local destination_content = data.destination_container.content
        local destination_storage_content = destination_content.get_contents()
        for _, item_data in pairs(destination_storage_content) do
            if this.valid_items[item_data.name] then
                if destination_requested_item then
                    local source_item = source_item_storage[item_data.name]
                    if not source_item then
                        source_item_storage[item_data.name] = 0
                    end

                    local inserted = destination_content.remove(item_data)
                    source_item_storage[item_data.name] = source_item_storage[item_data.name] + inserted
                else
                    local source_item = source_item_storage[item_data.name]
                    if not source_item then
                        source_item_storage[item_data.name] = 0
                    end

                    local inserted = destination_content.remove(item_data)
                    source_item_storage[item_data.name] = source_item_storage[item_data.name] + inserted
                end
            end
        end
    else
        local source_item_storage = data.source_container.item_storage
        local destination_content = data.destination_container.content

        for _, item_data in next, source_item_storage do
            if this.valid_items[item_data.name] then
                local item_stack = data.item_prototypes[item_data.name].stack_size

                if item_data.count > 0 then
                    local dest_item = destination_content.get_item_count(item_data.name)
                    if not dest_item or dest_item == 0 then
                        local to_insert = item_data.count
                        if to_insert > item_stack then
                            to_insert = floor(item_stack / 2)
                        elseif to_insert > 1 then
                            to_insert = floor(to_insert / 2)
                        end

                        if item_stack == 1 then
                            to_insert = 1
                        end

                        local inserted = destination_content.insert(
                            {
                                name = item_data.name,
                                count = to_insert,
                                quality =
                                    item_data.quality
                            })
                        source_item_storage[item_data.name] = source_item_storage[item_data.name] - inserted
                        if source_item_storage[item_data.name] < 0 then
                            source_item_storage[item_data.name] = nil
                        end
                    else
                        local dest_diff_remote_storage = source_item_storage[item_data.name] - dest_item
                        local dest_diff_local_storage = item_stack - dest_item
                        if dest_diff_remote_storage > 0 and dest_diff_local_storage > 0 and dest_diff_local_storage < item_stack then
                            if source_item_storage[item_data.name] >= dest_diff_local_storage then
                                local inserted = destination_content.insert(
                                    {
                                        name = item_data.name,
                                        count =
                                            dest_diff_local_storage,
                                        quality = item_data.quality
                                    })
                                source_item_storage[item_data.name] = source_item_storage[item_data.name] - inserted
                                if source_item_storage[item_data.name] < 0 then
                                    source_item_storage[item_data.name] = nil
                                end
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

local function is_chest_empty(entity, player)
    local unit_number = entity.unit_number
    local container = fetch_container(unit_number)
    if not container then
        return
    end

    local mode = container.mode
    local items = container.item_storage
    if not items then
        goto no_storage
    end
    if mode == 2 then
        if has_value(items) >= 1 then
            if not this.saved_containers[player.index] then
                this.saved_containers[player.index] = {}
            end
            container.chest = nil
            container.content = nil

            this.saved_containers[player.index][unit_number] = container
        end
    end
    ::no_storage::

    remove_chest(unit_number)
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity then
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
    refund_player(entity)
    is_chest_empty(entity, player)
    local data = this.inf_gui[player.name]
    if not data then
        return
    end
    data.frame.destroy()
end

local function check_limit_on_source_and_content_on_destination(data)
    local source_links = data.source_container.links
    if source_links then
        if data.source_container.content.get_bar() > 2 then
            if (not data.destination_container.destination_full and data.destination_container.direction.state == 'import') or data.destination_container.direction.state == 'export' then
                data.destination_container.content.set_bar()
            end
        else
            if data.destination_container.direction.state == 'import' then
                data.destination_container.content.set_bar(1)
            else
                data.destination_container.content.set_bar()
            end
        end
    end

    if data.source_container.private then
        data.destination_container.private.state = data.source_container.private.state or false
    end
end

local function check_mode_on_chest(data)
    local chest = data.container.chest
    local mode = data.container.mode

    if data.container.linked_to then
        local linked_to = fetch_container(data.container.linked_to)
        if linked_to then
            data.container.destination_container = linked_to

            if data.container.direction.state == 'import' then
                if mode == 3 then
                    if linked_to.full then
                        data.container.destination_full = true
                        data.inv.set_bar(1)
                    else
                        data.container.destination_full = false
                        data.inv.set_bar()
                    end
                end
            elseif data.container.direction.state == 'export' and data.container.destination_full then
                data.container.destination_full = false
            end
        end
    end

    if mode == 1 then
        if data.container.limit.state and data.count > data.container.limit.number and data.container.direction.state == 'import' then
            data.container.full = true
            data.inv.set_bar()
        else
            data.container.full = false
            data.inv.set_bar()
        end
        chest.destructible = false
        chest.minable = false
    elseif mode == 2 then
        data.inv.set_bar(1)
        chest.destructible = true
        chest.minable = true
    elseif mode == 3 then
        chest.destructible = false
        chest.minable = false
        if data.container.direction.state == 'export' then
            data.inv.set_bar()
        end
    end
end

local function get_link(data)
    if data.destination_container and data.destination_container.linked_to then
        local linked_to = tonumber(data.destination_container.linked_to)
        if not linked_to then
            return false
        end
        local source_container = fetch_container(linked_to)
        if not source_container then
            remove_chest(linked_to)
            return false
        end

        data.source_container = source_container
    end
end

local function check_links(data)
    get_link(data)

    if data.source_container then
        check_limit_on_source_and_content_on_destination(data)
        if this.limit_some_items then
            item_links_ores_only(data)
        else
            item_links(data)
        end
    end
end

local function update_chest(item_prototypes)
    local containers = this.main_containers
    for unit_number, container in next, containers do
        if container and not container.chest.valid then
            remove_chest(unit_number)
            goto continue
        end

        if container.direction and container.direction.state == 'left' then
            container.direction.state = 'import'
        end
        if container.direction and container.direction.state == 'right' then
            container.direction.state = 'export'
        end

        local inv = container.content
        local content = inv.get_contents()
        local item_storage = container.item_storage

        local count = item_counter(container)

        check_mode_on_chest({ container = container, count = count, inv = inv })

        check_links({ destination_container = container, inv = inv, item_prototypes = item_prototypes })

        local temp_items = {}

        if this.limit_some_items then
            for _, item_data in pairs(content) do
                temp_items[item_data.name] = item_data.count
                if this.valid_items[item_data.name] then
                    if item_data.name ~= 'count' then
                        item(item_data, inv, container, item_prototypes)
                    end
                end
            end
        else
            for _, item_data in pairs(content) do
                if item_data.name ~= 'count' then
                    item(item_data, inv, container, item_prototypes)
                end
            end
        end

        if not item_storage then
            goto continue
        end

        if this.limit_some_items then
            for item_name, _ in pairs(item_storage) do
                if this.valid_items[item_name] then
                    if not temp_items[item_name] then
                        if item_name ~= 'count' then
                            item({ name = item_name, count = 0 }, inv, container, item_prototypes)
                        end
                    end
                end
            end
        else
            for item_name, _ in pairs(item_storage) do
                if not temp_items[item_name] then
                    if item_name ~= 'count' then
                        item({ name = item_name, count = 0 }, inv, container, item_prototypes)
                    end
                end
            end
        end

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

--- Iterates over player chests.
---@param index any
---@param unit_number any
---@return table
local function get_owner_chests(index, unit_number)
    local t = {}
    local containers = this.main_containers
    for check_unit_number, container in pairs(containers) do
        if container.owner == index then
            if container.chest and container.chest.valid then
                if check_unit_number ~= unit_number and container.share.state then
                    insert(t, container)
                end
            end
        end
    end
    return t
end

--- Get first item of item storage.
---@param container table
local function get_first_item_in_item_storage(container)
    return next(container)
end

local function refresh_main_frame(data)
    local player = data.player
    local unit_number = data.unit_number

    local container = fetch_container(unit_number)
    local entity = container.chest
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
        local share_tooltip =
        '[color=yellow]Share Info:[/color]\nA name for the share so you can easy find it when you want to link it with another chest.'

        local primary_tbl = volatile_tbl.add { type = 'table', column_count = 8, name = 'primary_tbl' }

        local limit_one_label = primary_tbl.add({ type = 'label', caption = 'Limit Enabled: ', tooltip = limit_tooltip })
        limit_one_label.style.font = 'heading-2'
        local limit_one_checkbox = primary_tbl.add(
            {
                type = 'checkbox',
                name = 'limit_chest',
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
                    .number
            })
        limit_two_text.style.width = 80
        limit_two_text.numeric = true
        limit_two_text.tooltip = limit_tooltip
        limit_two_text.style.minimal_width = 25

        this.inf_gui[player.name].text_field = limit_two_text
        this.inf_gui[player.name].limited = limit_one_checkbox

        local private_tooltip =
        '[color=yellow]Private Info:[/color]\nThis will make it so no one else other than you can open this chest.'

        local private_label = bottom_flow.add({ type = 'label', caption = 'Private Chest? ', tooltip = private_tooltip })
        private_label.style.font = 'heading-2'
        local private_checkbox = bottom_flow.add(
            {
                type = 'checkbox',
                name = 'private_chest',
                state = container.private
                    .state
            })
        private_checkbox.tooltip = private_tooltip
        private_checkbox.style.minimal_height = 25

        local share_tbl = volatile_tbl.add { type = 'table', column_count = 8, name = 'share_tbl' }

        local share_one_label = share_tbl.add({ type = 'label', caption = 'Share Enabled: ', tooltip = share_tooltip })
        share_one_label.style.font = 'heading-2'
        local share_one_checkbox = share_tbl.add(
            {
                type = 'checkbox',
                name = 'share_chest',
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
        local linker_tooltip = '[color=yellow]Link Info:[/color]\nThis will only work with chests that you have placed.'
        local directions_tooltip =
        '[color=yellow]Direction Info:[/color]\nChoose whether to import the item(s) to the main storage or export the item(s) from the main storage.'

        local linker = volatile_tbl.add { type = 'table', column_count = 8, name = 'linker' }
        if container then
            if container and container.owner ~= player.force.index then
                local link_label = linker.add(
                    {
                        type = 'label',
                        caption = 'Not owner of chest. ',
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
                            name = 'directions_chest',
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
                local chests = get_owner_chests(container.owner, unit_number)
                local linked_container = fetch_container(container.linked_to)

                if not next(chests) then
                    local link_label = sublinker.add({ type = 'label', caption = 'No chests found.' })
                    link_label.style.font = 'heading-2'
                    return
                end

                if container.linked_to and linked_container then
                    if container.requested_item then
                        local localized_name = prototypes.item[container.requested_item].localised_name
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

                    for i = 1, #chests do
                        if chests then
                            local chest = chests[i]
                            if type(chest) ~= 'string' then
                                if next(chest.item_storage) then
                                    for name, _ in pairs(chest.item_storage) do
                                        local localized_name = prototypes.item[name].localised_name

                                        local flowlinker = itemlinker.add { type = 'flow' }
                                        local chestitem =
                                            flowlinker.add
                                            {
                                                type = 'sprite-button',
                                                name = item_name_frame_name,
                                                style = 'slot_button',
                                                sprite = 'item/' .. name,
                                                tooltip = { '', localized_name, '\n', chest.share.name, '\n', get_first_item_in_item_storage(chest.item_storage) }
                                            }
                                        Gui.set_data(chestitem,
                                            { name = name, unit_number = unit_number, share = chest.share.name })
                                    end
                                end
                            end
                        end
                    end
                    sublinker.add({ type = 'line' })
                    local link_chest_label = sublinker.add(
                        {
                            type = 'label',
                            caption = 'Link with chest:\n',
                            tooltip =
                                linker_tooltip
                        })
                    link_chest_label.style.font = 'heading-2'
                    local chest_scroll_pane =
                        sublinker.add
                        {
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
                    local chestlinker = chest_scroll_pane.add { type = 'table', column_count = 8, name = 'chestlinker' }

                    for i = 1, #chests do
                        if chests then
                            local chest = chests[i]
                            if type(chest) ~= 'string' then
                                local primary_item_name = chest.item_storage and next(chest.item_storage) and next(chest.item_storage) or nil
                                local flowlinker = chestlinker.add { type = 'flow' }
                                local chestitem = flowlinker.add { type = 'sprite-button', name = item_name_frame_name, style = 'slot_button', sprite = 'item/' .. (primary_item_name or container.chest.name), tooltip = 'Chest share name: ' .. chest.share.name }
                                Gui.set_data(chestitem,
                                    {
                                        name = nil,
                                        unit_number = unit_number,
                                        share = chest.share
                                            .name
                                    })
                            end
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
    if not this.valid_chests[entity.name] then
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
                caption = 'Unlimited Chest',
                direction = 'vertical',
                name = tostring(unit_number)
            }
    end

    local controls = frame.add { type = 'flow', direction = 'horizontal' }
    local controls2 = frame.add { type = 'flow', direction = 'horizontal' }
    local items = frame.add { type = 'flow', direction = 'vertical' }

    local mode = container.mode
    local selected = mode and mode or 1
    local controltbl = controls.add { type = 'table', column_count = 1 }
    local btntbl = controltbl.add { type = 'table', column_count = 3 }
    local modetbl = controltbl.add { type = 'table', column_count = 2 }
    local volatile_tbl = controls2.add { type = 'table', column_count = 1 }

    local mode_tooltip =
    '[color=yellow]Mode Info:[/color]\nEnabled: will active the chest and allow for insertions.\nDisabled: will deactivate the chest and let´s the player utilize the GUI to retrieve items.\nLink: Link a chest with another chest. Content is divided between them.'

    if not player.admin and this.limit_some_items then
        container.total_slots = 6
    end

    local amount_and_types
    if this.limit_some_items then
        amount_and_types = container.total_slots .. ' different ores, barrels and ammo.'
    else
        amount_and_types = container.total_slots .. ' different items'
    end

    local btn =
        btntbl.add
        {
            type = 'sprite-button',
            name = info_chest_btn_name,
            tooltip = '[color=blue]Info![/color]\nChest ID: ' ..
                unit_number ..
                '\nThis chest stores unlimited quantity of items (up to ' ..
                amount_and_types ..
                ").\nThe chest is best used with an inserter to add / remove items.\nThe chest is mineable if state is disabled.\nContent is kept when mined.\n[color=yellow]Limit:[/color]\nThis will stop the input after the limit is reached.\n\n[color=red]NOTE![/color]\nIf the chest can't keep up with outputting the items,\nallow it first to fill up, then try again!",
            sprite = Gui.info_icon
        }
    btn.style.height = 20
    btn.style.width = 20
    btn.enabled = true
    btn.focus()

    if entity.name ~= 'passive-provider-chest' and entity.type == 'container' then
        local upgradebtn =
            btntbl.add
            {
                type = 'sprite-button',
                name = upgrade_chest_btn_name,
                tooltip = 'Click to upgrade to passive-chest.',
                sprite = 'utility/alert_arrow'
            }
        upgradebtn.style.height = 20
        upgradebtn.style.width = 20
        upgradebtn.enabled = true
    end

    if container.mode == 3 then
        local master_btn =
            btntbl.add
            {
                type = 'sprite-button',
                name = master_chest_btn_name,
                tooltip = 'Click to make this chest a master chest.',
                sprite = 'utility/bookmark'
            }
        master_btn.style.height = 20
        master_btn.style.width = 20
        master_btn.enabled = true
    end

    local mode_label = modetbl.add { type = 'label', caption = 'Mode: ', tooltip = mode_tooltip }
    mode_label.style.font = 'heading-2'
    local drop_down_items

    if player.admin and (this.editor[player.name]) then
        drop_down_items = { 'Enabled', 'Disabled', 'Link', 'Editor' }
    else
        drop_down_items = { 'Enabled', 'Disabled', 'Link' }
    end

    local drop_down =
        modetbl.add
        {
            type = 'drop-down',
            items = drop_down_items,
            selected_index = selected,
            name = unit_number,
            tooltip = mode_tooltip
        }

    this.inf_gui[player.name] =
    {
        item_frame = items,
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
    if not entity.valid then
        return
    end
    if not this.valid_chests[entity.name] then
        return
    end
    if event.player_index then
        local player = game.get_player(event.player_index)
        local c = restore_chest(entity, player)
        if c then
            gui_opened(event)
        end

        local s = create_chest(entity, player)
        if s then
            gui_opened(event)
        end
    end
end

local function update_gui()
    for _, player in pairs(game.connected_players) do
        local chest_gui_data = this.inf_gui[player.name]
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
        if (mode == 2 or mode == 4) and this.inf_gui[player.name].updated then
            goto continue
        end
        if not frame or not frame.valid then
            goto continue
        end

        frame.clear()

        local tbl = frame.add { type = 'table', column_count = 10, name = 'infinity_chest_inventory' }
        local total = 0
        local items = {}

        local storage = container.item_storage
        local content = container.content.get_contents()
        local limit = container.limit.number
        local limit_state = container.limit.state
        local full

        if not storage then
            goto no_storage
        end
        for item_name, item_count in pairs(storage) do
            if item_name ~= 'count' and type(item_name) == 'string' then
                total = total + 1
                items[item_name] = item_count
                if storage[item_name] >= limit and limit_state then
                    full = true
                end
            end
        end
        ::no_storage::

        if full then
            goto full
        end

        for _, item_data in pairs(content) do
            if item_data.name ~= 'count' and type(item_data.name) == 'string' then
                if not items[item_data.name] then
                    total = total + 1
                    items[item_data.name] = item_data.count
                else
                    items[item_data.name] = items[item_data.name] + item_data.count
                end
            end
        end

        ::full::

        local btn
        if container.requested_item then
            local destination_storage = container.destination_container and container.destination_container.item_storage
            local destination_count = destination_storage and destination_storage[container.requested_item] or 0
            local localized_name = prototypes.item[container.requested_item].localised_name
            local flow = tbl.add { type = 'flow' }
            flow.style.horizontally_stretchable = true
            btn =
                flow.add
                {
                    type = 'sprite-button',
                    sprite = 'item/' .. container.requested_item,
                    style = 'slot_button',
                    name = container.requested_item,
                    number = destination_count,
                    tooltip = { '', localized_name, '\nMaster storage count: ', destination_count }
                }
            btn.enabled = false
        end


        for item_name, item_count in pairs(items) do
            local localized_name = prototypes.item[item_name].localised_name[1]
            if mode == 1 or mode == 3 then
                if container.requested_item and tbl[container.requested_item] then
                    tbl[container.requested_item].number = item_count
                else
                    btn =
                        tbl.add
                        {
                            type = 'sprite-button',
                            sprite = 'item/' .. item_name,
                            style = 'slot_button',
                            number = item_count,
                            name = item_name,
                            tooltip = { '', { localized_name }, '\nThis chest count: ', item_count }
                        }
                    btn.enabled = false
                end
            elseif mode == 2 or mode == 4 then
                btn =
                    tbl.add
                    {
                        type = 'sprite-button',
                        sprite = 'item/' .. item_name,
                        style = 'slot_button',
                        number = item_count,
                        name = item_name,
                        tooltip = { '', { localized_name }, '\nCount: ', item_count }
                    }
                btn.enabled = true
            end
        end

        while total < container.total_slots do
            local btns
            if mode == 1 or mode == 2 then
                btns = tbl.add { type = 'sprite-button', style = 'slot_button' }
                btns.enabled = false
            elseif mode == 4 then
                btns = tbl.add { type = 'choose-elem-button', style = 'slot_button', elem_type = 'item' }
                btns.enabled = true
            end

            total = total + 1
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
        if data then
            data.frame.destroy()
            this.inf_gui[player.name] = nil
        end
    end
    destroy_player_container_summary_frame(player)
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
        local items = element.items
        if not items then
            return
        end
        local selected = items[element.selected_index]
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
        if not container then
            return
        end
        if not container.mode then
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
                if container.chest and container.chest.valid then
                    container.chest.destroy()
                end
                remove_chest(unit_number)
            end
        end
    end

    this.saved_containers[index] = nil
end

local function content_mismatches(source, destination)
    local source_container = fetch_container(source)
    if not source_container then
        return
    end
    local source_content = source_container.content
    local source_inventory = source_content.get_contents()

    local destination_container = fetch_container(destination)
    if not destination_container then
        return
    end
    local destination_content = destination_container.content
    local destination_inventory = destination_content.get_contents()

    local mismatch = false

    for _, source_item_data in pairs(source_inventory) do
        for _, destination_item_data in pairs(destination_inventory) do
            if source_item_data.name ~= destination_item_data.name then
                mismatch = true
            end
        end
    end
    return mismatch
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
    if element.name == 'directions_chest' then
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
        return
    end

    local parent = element.parent
    if not parent then
        return
    end
    if parent.name ~= 'infinity_chest_inventory' then
        return
    end
    local unit_number = tonumber(parent.parent.parent.name)
    if tonumber(element.name) == unit_number then
        return
    end

    local shift = event.shift
    local ctrl = event.control
    local name = element.name
    local container = fetch_container(unit_number)
    local storage = container.item_storage
    local mode = container.mode

    if not storage then
        return
    end

    if player.admin then
        if mode == 4 then
            if not storage[name] then
                return
            end

            if ctrl then
                storage[name] = storage[name] + 500000
                goto update
            elseif shift then
                storage[name] = storage[name] - 500000
                if storage[name] <= 0 then
                    storage[name] = nil
                end
                goto update
            end
        end
    end

    if mode == 1 then
        return
    end

    if ctrl then
        local count = storage[name]
        if not count then
            return
        end
        local inserted = player.insert { name = name, count = count }
        if not inserted then
            return
        end

        if inserted == count then
            storage[name] = nil
        else
            storage[name] = storage[name] - inserted
        end
    elseif shift then
        local count = storage[name]
        local proto = prototypes.item
        local stack = proto[name].stack_size
        if not count then
            return
        end
        if not stack then
            return
        end
        if count > stack then
            local inserted = player.insert { name = name, count = stack }
            storage[name] = storage[name] - inserted
        else
            player.insert { name = name, count = count }
            storage[name] = nil
        end
    else
        if not storage[name] then
            return
        end
        storage[name] = storage[name] - 1
        player.insert { name = name, count = 1 }
        if storage[name] <= 0 then
            storage[name] = nil
        end
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
    if parent.name ~= 'infinity_chest_inventory' then
        return
    end
    local unit_number = tonumber(parent.parent.parent.name)
    if tonumber(element.name) == unit_number then
        return
    end

    local container = fetch_container(unit_number)

    local button = event.button
    local storage = container.item_storage
    local name = element.elem_value

    if button == defines.mouse_button_type.right then
        storage[name] = nil
        return
    end

    if not name then
        return
    end
    storage[name] = 500000

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

    if element.name == 'private_chest' then
        container.private.state = state
    elseif element.name == 'limit_chest' then
        container.limit.state = state
    elseif element.name == 'share_chest' then
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

local function on_entity_settings_pasted(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local source = event.source
    if not source or not source.valid then
        return
    end

    local destination = event.destination
    if not destination or not destination.valid then
        return
    end

    local source_number = source.unit_number
    local destination_number = destination.unit_number

    local source_container = fetch_container(source_number)
    local destination_container = fetch_container(destination_number)

    if not source_container then
        return
    end

    if source_container.mode == 2 then
        return
    end

    if not destination_container then
        if not this.valid_chests[destination.name] then
            return
        end
        local inventory = player.get_main_inventory()
        local player_item_count = inventory.get_item_count('coin')

        if player_item_count >= this.cost_to_convert then
            player.remove_item({ name = 'coin', count = this.cost_to_convert })

            event.entity = destination
            event.entity = destination

            on_built_entity(event, true)
            player.print(module_name .. 'The destination chest has been upgraded to infinity chest.', Color.warning)
        else
            player.print(module_name .. 'Not enough coins when trying to convert normal chest to infinity chest.',
                Color.warning)
        end
        player.opened = nil
        return
    end

    local source_share = source_container.share
    local destination_share = destination_container.share

    if content_mismatches(source_number, destination_number) then
        player.print(
            module_name .. 'The destination chest that you are trying to paste to mismatches with the original chest.',
            Color.fail)
        return
    end

    destination_container.limit = source_container.limit
    destination_container.direction.state = source_container.direction.state

    destination_container.private = source_container.private
    if source_container.mode == 3 then
        destination_container.mode = source_container.mode
    end

    if source_container.linked_to and not destination_container.linked_to then
        goto continue
    end

    if source_container.linked_to and destination_container.linked_to then
        player.print(module_name .. 'The destination chest is already linked.', Color.fail)
        return
    end

    if source_share and not source_share.state then
        player.print(module_name .. 'The source chest is not shared.', Color.fail)
        return
    end

    if source_share and source_share.state and destination_share and destination_share.state then
        player.print(module_name .. 'The source and destination chest are both shared.', Color.fail)
        return
    end

    if not source_container.links and destination_container.links then
        player.print(module_name .. 'The source chest is not shared.', Color.fail)
        return
    end

    if source_container.links and destination_container.links then
        player.print(module_name .. 'The source chest and destination chests have links.', Color.fail)
        return
    end

    if source_container.private.state and source_container.owner ~= destination_container.owner then
        player.print(module_name .. 'The source chest is private.', Color.fail)
        return
    end

    if source_container.links and destination_container.linked_to then
        player.print(module_name .. 'The destination chest is already linked.', Color.fail)
        return
    end

    ::continue::

    if source_share and source_share.state then
        if not source_container.links then
            source_container.links = {}
            source_container.links[destination_number] = true
        end

        if source_container.links then
            source_container.links[destination_number] = true
        end

        destination_container.linked_to = source_number
        destination_container.mode = 3
        toggle_render(destination_container)
    end

    if source_container.linked_to then
        local source_linked_to = source_container.linked_to
        local source_linked_chest = fetch_container(source_linked_to)
        local source_mode = source_container.mode
        destination_container.linked_to = source_linked_to
        destination_container.mode = source_mode

        if source_linked_chest and source_linked_chest.links then
            source_linked_chest.links[destination_number] = true
        end
        toggle_render(source_container)
        toggle_render(destination_container)
    end

    player.print(module_name .. 'Successfully pasted settings.', Color.success)
end

Event.on_nth_tick(
    10,
    function ()
        if not this.enabled then
            return
        end

        local item_prototypes = prototypes.item
        update_chest(item_prototypes)
    end
)

Event.on_nth_tick(
    5,
    function ()
        if not this.enabled then
            return
        end
        update_gui()
    end
)

Gui.on_click(
    info_chest_btn_name,
    function (event)
        local player = event.player
        local summary_frame = player.gui.center[player_container_summary_frame_name]
        if summary_frame and summary_frame.valid then
            Gui.destroy(summary_frame)
            return
        end
        draw_player_container_summary_frame(player)
    end)

Gui.on_click(
    player_container_summary_close_btn_name,
    function (event)
        destroy_player_container_summary_frame(event.player)
    end
)

Gui.on_click(
    convert_chest_to_infinite_chest,
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

        if entity and entity.valid and this.valid_chests[entity.name] then
            draw_convert_chest_button(panel, entity)
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
        local panel = relative[chest_converter_frame_for_player_name]
        if panel and panel.valid then
            Gui.destroy(panel)
        end
        destroy_player_container_summary_frame(player)
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
            container.requested_item = data.name

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

Gui.on_click(
    upgrade_chest_btn_name,
    function (event)
        local player = event.player

        local chest_gui_data = this.inf_gui[player.name]
        if not chest_gui_data then
            return
        end

        local entity = chest_gui_data.entity
        if not entity or not entity.valid then
            return
        end

        upgrade_chest(player, entity, chest_gui_data)
    end
)

Gui.on_click(
    master_chest_btn_name,
    function (event)
        local player = event.player
        local chest_gui_data = this.inf_gui[player.name]
        if not chest_gui_data then
            return
        end

        if not chest_gui_data.validation then
            player.print('Are you sure you want to make this chest a master chest?', Color.warning)
            chest_gui_data.validation = true
            return
        end

        local entity = chest_gui_data.entity
        if not entity or not entity.valid then
            return
        end

        local source_container = fetch_container(entity.unit_number)
        if not source_container then
            player.print('This chest is not a valid chest.', Color.warning)
            return
        end

        if source_container.mode ~= 3 then
            player.print('This chest is not a slave chest.', Color.warning)
            return
        end

        local destination_container = fetch_container(source_container.linked_to)
        if not destination_container then
            player.print('This chest is not a valid chest.', Color.warning)
            return
        end

        if destination_container.mode ~= 1 then
            player.print('This chest is not a master chest.', Color.warning)
            return
        end

        make_master_chest(player, source_container, destination_container)
        player.print('Successfully made this chest a master chest.', Color.success)
        chest_gui_data.validation = nil
        if chest_gui_data.frame and chest_gui_data.frame.valid then
            chest_gui_data.frame.destroy()
        end
    end
)

Event.add(defines.events.on_gui_click, gui_click)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, built_entity_robot)
Event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)
Event.add(defines.events.on_gui_selection_state_changed, state_changed)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_gui_elem_changed, on_gui_elem_changed)
Event.add(defines.events.on_gui_checked_state_changed, on_gui_checked_state_changed)
Event.add(defines.events.on_gui_text_changed, text_changed)
Event.add(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)
Event.add(
    defines.events.on_player_removed,
    function (event)
        Public.remove_player(event.player_index)
    end
)

Commands.new('increase_stack', 'Increases stack capacity')
    :require_role('infinity_chest')
    :callback(function (player)
        if player.selected and player.selected.unit_number then
            local linked_container = fetch_container(player.selected.unit_number)
            if linked_container and linked_container.item_storage then
                for k, _ in pairs(linked_container.item_storage) do
                    linked_container.item_storage[k] = linked_container.item_storage[k] + 5000000
                end
                player.print('Item capacity increased by 5000000.', Color.success)
            else
                player.print('Please select a container.', Color.warning)
            end
        else
            player.print('Please select a container.', Color.warning)
        end
    end
    )

Commands.new('toggle_chest_render', 'Changes the render state of the chest')
    :require_role('infinity_chest')
    :callback(function (player)
        for _, container in pairs(this.main_containers) do
            toggle_render(container)
        end
        player.print('[Infinity Chest] Render state changed.', Color.success)
    end
    )

return Public
