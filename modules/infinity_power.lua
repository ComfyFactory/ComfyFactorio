local Event = require 'utils.event'
local Color = require 'utils.color_presets'
local Global = require 'utils.global'
local Gui = require 'utils.gui'

local this =
{
    main_containers = {},
    inf_gui = {},
    valid_poles =
    {
        ['electric-pole'] = true,
    },
    enabled = true,
    disable_normal_placement = true,
    debug = false,
    cost_to_convert = 200,
}

local converter_frame_for_player_name = Gui.uid_name()
local convert_to_power_pole = Gui.uid_name()
local item_name_frame_name = Gui.uid_name()

local module_name = '[Infinity Power] '
local insert = table.insert
-- local floor = math.floor
local pairs = pairs
local Public = {}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local remove_pole

function Public.get_table()
    return this
end

local function draw_convert_power_pole(parent, entity)
    local frame = parent[converter_frame_for_player_name]
    if frame and frame.valid then
        Gui.destroy(frame)
    end

    local anchor =
    {
        gui = defines.relative_gui_type.electric_network_gui,
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
            name = convert_to_power_pole,
            style = Gui.button_style,
            tooltip = '[color=blue][Infinity Power][/color]\nYou can easily convert this power pole to an infinity power pole.\nAllowing power poles to be connected from anywhere.\n\nCosts ' .. this.cost_to_convert .. ' coins.'
        }
    Gui.set_data(button, entity)
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

local function toggle_render(container)
    if not container.pole or not container.pole.valid then
        remove_pole(container.unit_number)
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
                surface = container.pole.surface,
                target = { entity = container.pole, offset = { 0, -0.4 } },
                scale = 1,
                color = { r = 0, g = 0.6, b = 1 },
                alignment = 'center',
            }
    elseif container.linked_to then
        container.render =
            rendering.draw_text
            {
                text = 'L',
                surface = container.pole.surface,
                target = { entity = container.pole, offset = { 0, -0.4 } },
                scale = 1,
                color = { r = 0, g = 0.6, b = 1 },
                alignment = 'center',
            }
    else
        container.render =
            rendering.draw_text
            {
                text = '♾',
                surface = container.pole.surface,
                target = { entity = container.pole, offset = { 0, -0.4 } },
                scale = 1,
                color = { r = 0, g = 0.6, b = 1 },
                alignment = 'center',
            }
    end
end

local function create_connection(entity, player)
    entity.disabled_by_script = true
    local unit_number = entity.unit_number

    if not does_exists(unit_number) then
        local container =
        {
            pole = entity,
            owner = player.force.index,
            unit_number = unit_number,
            wire = entity.get_wire_connector(5),
            share =
            {
                state = false,
                name = entity.unit_number
            },
            private = { state = true, owner = player.index },
            mode = 1,
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
        create_connection(entity, player)
    end

    return container.share
end

local function built_entity_robot(event)
    if this.disable_normal_placement then
        return
    end
    local entity = event.entity
    if not entity.valid then
        return
    end
    if not this.valid_poles[entity.type] then
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

local function remove_wire(unit_number)
    local source_container = fetch_container(unit_number)
    if not source_container then
        return
    end

    if source_container and source_container.linked_to then
        local destination_container = fetch_container(source_container.linked_to)
        if not destination_container then
            return false
        end

        destination_container.wire.disconnect_from(source_container.wire, defines.wire_origin.script)
        destination_container.wire.disconnect_from(source_container.wire, defines.wire_origin.player)
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

                    toggle_render(l_container)
                end
            end
        end
    end
end

remove_pole = function (unit_number)
    remove_wire(unit_number)
    remove_link(unit_number)
    remove_object(unit_number)
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

local function on_entity_died(event)
    local entity = event.entity
    if not entity then
        return
    end
    if not this.valid_poles[entity.type] then
        return
    end

    local unit_number = entity.unit_number
    remove_pole(unit_number)
end

local function on_pre_player_mined_item(event)
    local entity = event.entity
    local player = game.get_player(event.player_index)
    if not player then
        return
    end
    if not this.valid_poles[entity.type] then
        return
    end
    refund_player(entity)
    remove_pole(entity.unit_number)
    local data = this.inf_gui[player.name]
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

    this.inf_gui[player.name].updated = false
end

--- Iterates over player power poles.
---@param index any
---@param unit_number any
---@return table
local function get_owner_poles(index, unit_number)
    local t = {}
    local containers = this.main_containers
    for check_unit_number, container in pairs(containers) do
        if container.owner == index then
            if container.pole and container.pole.valid then
                if check_unit_number ~= unit_number and container.share.state then
                    insert(t, container)
                end
            end
        end
    end
    return t
end

local function refresh_main_frame(data)
    local player = data.player
    local unit_number = data.unit_number

    local container = fetch_container(unit_number)
    local entity = container.pole
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
            remove_wire(unit_number)
            container.linked_to = nil
        end
    end

    if mode == 1 then
        local share_tooltip =
        '[color=yellow]Share Info:[/color]\nA name for the share so you can easy find it when you want to link it with another power pole.'

        local primary_tbl = volatile_tbl.add { type = 'table', column_count = 8, name = 'primary_tbl' }

        local bottom_flow = primary_tbl.add { type = 'flow' }
        bottom_flow.style.minimal_width = 40

        local private_tooltip =
        '[color=yellow]Private Info:[/color]\nThis will make it so no one else other than you can open this power pole.'

        local private_label = bottom_flow.add({ type = 'label', caption = 'Private Pole? ', tooltip = private_tooltip })
        private_label.style.font = 'heading-2'
        local private_checkbox = bottom_flow.add(
            {
                type = 'checkbox',
                name = 'private_pole',
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
                name = 'share_pole',
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
        local linker_tooltip = '[color=yellow]Link Info:[/color]\nThis will only work with poles that you have placed.'

        local linker = volatile_tbl.add { type = 'table', column_count = 8, name = 'linker' }
        if container then
            if container and container.owner ~= player.force.index then
                local link_label = linker.add(
                    {
                        type = 'label',
                        caption = 'Not owner of pole. ',
                        tooltip =
                            linker_tooltip
                    })
                link_label.style.font = 'heading-2'
            else
                local sublinker = volatile_tbl.add { type = 'table', column_count = 1, name = 'sublinker' }
                local itemdesc = volatile_tbl.add { type = 'table', column_count = 2, name = 'itemdesc' }
                local poles = get_owner_poles(container.owner, unit_number)
                local linked_container = fetch_container(container.linked_to)

                if not next(poles) then
                    local link_label = sublinker.add({ type = 'label', caption = 'No poles found.' })
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
                    sublinker.add({ type = 'line' })
                    local link_pole_label = sublinker.add(
                        {
                            type = 'label',
                            caption = 'Link with pole:\n',
                            tooltip =
                                linker_tooltip
                        })
                    link_pole_label.style.font = 'heading-2'
                    local pole_scroll_pane =
                        sublinker.add
                        {
                            type = 'scroll-pane',
                            vertical_scroll_policy = 'auto',
                            horizontal_scroll_policy = 'never'
                        }
                    local pole_scroll_style = pole_scroll_pane.style
                    pole_scroll_style.maximal_height = 150
                    pole_scroll_style.vertically_squashable = true
                    pole_scroll_style.bottom_padding = 2
                    pole_scroll_style.left_padding = 2
                    pole_scroll_style.right_padding = 2
                    pole_scroll_style.top_padding = 2
                    local polelinker = pole_scroll_pane.add { type = 'table', column_count = 8, name = 'polelinker' }

                    for i = 1, #poles do
                        if poles then
                            local pole = poles[i]
                            if type(pole) ~= 'string' then
                                local flowlinker = polelinker.add { type = 'flow' }
                                local poleitem = flowlinker.add { type = 'sprite-button', name = item_name_frame_name, style = 'slot_button', sprite = 'item/' .. container.pole.name, tooltip = 'pole share name: ' .. pole.share.name }
                                Gui.set_data(poleitem,
                                    {
                                        name = nil,
                                        unit_number = unit_number,
                                        share = pole.share
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
    if not this.valid_poles[entity.type] then
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
                caption = 'Infinity Power',
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
    local btntbl = controltbl.add { type = 'table', column_count = 2 }
    local modetbl = controltbl.add { type = 'table', column_count = 2 }
    local volatile_tbl = controls2.add { type = 'table', column_count = 1 }

    local mode_tooltip =
    '[color=yellow]Mode Info:[/color]\nEnabled: will active the pole and allow for insertions.\nDisabled: will deactivate the pole and let´s the player utilize the GUI to retrieve items.\nLink: Link a pole with another pole. Content is divided between them.'


    local btn =
        btntbl.add
        {
            type = 'sprite-button',
            tooltip = '[color=blue]Info![/color]\npole ID: ' ..
                unit_number ..
                "\nThe pole is best used with an inserter to add / remove items.\nThe pole is mineable if state is disabled.\nContent is kept when mined.\n[color=yellow]Limit:[/color]\nThis will stop the input after the limit is reached.\n\n[color=red]NOTE![/color]\nIf the pole can't keep up with outputting the items,\nallow it first to fill up, then try again!",
            sprite = Gui.info_icon
        }
    btn.style.height = 20
    btn.style.width = 20
    btn.enabled = false
    btn.focus()

    local mode_label = modetbl.add { type = 'label', caption = 'Mode: ', tooltip = mode_tooltip }
    mode_label.style.font = 'heading-2'
    local drop_down_items = { 'Enabled', 'Disabled', 'Link' }

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
    if not this.valid_poles[entity.type] then
        return
    end
    if event.player_index then
        local player = game.get_player(event.player_index)

        local s = create_connection(entity, player)
        if s then
            gui_opened(event)
        end
    end
end

local function update_gui()
    for _, player in pairs(game.connected_players) do
        local pole_gui_data = this.inf_gui[player.name]
        if not pole_gui_data then
            goto continue
        end
        local frame = pole_gui_data.item_frame
        local entity = pole_gui_data.entity
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
                        linked_container.wire.connect_to(container.wire, false)
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
                if container.pole and container.pole.valid then
                    container.pole.destroy()
                end
                remove_pole(unit_number)
            end
        end
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

    if element.name == 'private_pole' then
        container.private.state = state
    elseif element.name == 'share_pole' then
        if container.share.name ~= 'Share name' then
            if container.share.state then
                remove_wire(unit_number)
                remove_link(unit_number)
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

local function check_mode_on_container(data)
    local container = data.container.pole
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

local function update_container()
    local containers = this.main_containers
    for unit_number, container in next, containers do
        if container and not container.pole.valid then
            remove_pole(unit_number)
            goto continue
        end

        check_mode_on_container({ container = container })
        ::continue::
    end
end

Event.on_nth_tick(
    5,
    function ()
        if not this.enabled then
            return
        end
        update_gui()
        update_container()
    end
)

Gui.on_click(
    convert_to_power_pole,
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

        if entity and entity.valid and this.valid_poles[entity.type] then
            draw_convert_power_pole(panel, entity)
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
                linked_container.wire.connect_to(container.wire, false, defines.wire_origin.script)
            end
            this.inf_gui[event.player.name].updated = false
            toggle_render(container)
            refresh_main_frame({ unit_number = container.unit_number, player = event.player })
        end
    end
)



Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, built_entity_robot)
Event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)
Event.add(defines.events.on_gui_selection_state_changed, state_changed)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_gui_checked_state_changed, on_gui_checked_state_changed)
Event.add(defines.events.on_gui_text_changed, text_changed)
Event.add(
    defines.events.on_player_removed,
    function (event)
        Public.remove_player(event.player_index)
    end
)

return Public
