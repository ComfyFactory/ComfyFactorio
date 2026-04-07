local Event = require 'utils.event'
local Global = require 'utils.global'
local Color = require 'utils.color_presets'
local Gui = require 'utils.gui'
local Misc = require 'utils.commands.misc'
local SessionData = require 'utils.datastore.session_data'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Commands = require 'utils.commands'

local this =
{
    main_containers = {},
    ores_only = false,
    allow_barrels = true
}

local ore_names =
{
    ['coal'] = true,
    ['stone'] = true,
    ['iron-ore'] = true,
    ['copper-ore'] = true,
    ['uranium-ore'] = true,
    ['wood'] = true
}

local format = string.format
local size = 35
local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local stack_slider_name = Gui.uid_name()
local delete_mode_name = Gui.uid_name()
local close_name = Gui.uid_name()

local Public = {}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

function Public.get_table()
    return this
end

local function does_exists(player_index)
    local containers = this.main_containers
    if containers[player_index] then
        return true
    else
        return false
    end
end

local function add_object(player_index)
    local containers = this.main_containers

    if not does_exists(player_index) then
        containers[player_index] =
        {
            chest_id = player_index,
            item_storage =
            {
                ['normal'] = {},
                ['uncommon'] = {},
                ['rare'] = {},
                ['epic'] = {},
                ['legendary'] = {}
            },
            stack_size = 1,
            total_slots = 50,
            gui = {}
        }
    end
end

local function get_quality(name, quality)
    return name .. '_' .. quality
end

local function fetch_container(player_index)
    local containers = this.main_containers
    if containers[player_index] then
        return containers[player_index]
    end
end

local function clear_gui(player)
    local container = fetch_container(player.index)
    if not container then
        return
    end

    local data = container.gui
    if not data.main_frame then
        return
    end

    Gui.remove_data_recursively(data.main_frame)
    Gui.remove_data_recursively(data.item_frame)

    local screen = player.gui.screen
    local frame = screen[main_frame_name]

    if frame and frame.valid then
        frame.destroy()
    end

    if data.viewing_player then
        data.viewing_player = false
    end

    container.gui = {}
end

local function remove_gui(player)
    local container = fetch_container(player.index)
    if not next(container.gui) then
        return
    end
    container.gui = {}
end

local function create_button(player)
    if not SessionData.allowed(player, 'portable-chest') then
        if Gui.get_button_flow(player)[main_button_name] then
            Gui.get_button_flow(player)[main_button_name].destroy()
        end
        return
    end
    if Gui.get_button_flow(player)[main_button_name] then
        return
    end

    local button = Gui.get_button_flow(player).add(
        {
            type = 'sprite-button',
            sprite = 'item/requester-chest',
            name = main_button_name,
            tooltip = 'Portable inventory stash!',
            style = Gui.button_style
        }
    )
    if button then
        button.style.font_color = { 165, 165, 165 }
        button.style.font = 'default-semibold'
        button.style.minimal_height = 36
        button.style.maximal_height = 36
        button.style.minimal_width = 40
        button.style.padding = -2
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
    if not game.players[player.index] then
        return false
    end
    return true
end

local function item(data, inv, quality_storage, stack_size)
    local item_stack
    local proto = prototypes.item[data.name]
    local chest_item = quality_storage[data.name]
    if not proto then
        quality_storage[data.name] = nil
        return
    end

    if stack_size then
        item_stack = proto.stack_size * stack_size
    else
        item_stack = proto.stack_size
    end


    local diff = data.count - item_stack

    if diff > 0 then
        local s = { name = data.name, count = diff, quality = data.quality }
        local count = inv.remove(s)
        if not chest_item then
            quality_storage[data.name] = { name = data.name, count = count, quality = data.quality }
        else
            chest_item.count = chest_item.count + count
        end
    elseif diff < 0 then
        if not chest_item or chest_item.count <= 0 then
            goto continue
        end
        if chest_item.count > (diff * -1) then
            local s = { name = data.name, count = (diff * -1), quality = data.quality }
            local inserted = inv.insert(s)
            chest_item.count = chest_item.count - inserted
        else
            local s = { name = data.name, count = chest_item.count, quality = data.quality }
            inv.insert(s)
            chest_item.count = 0
        end
    end
    ::continue::
end

local function update_containers()
    local containers = this.main_containers
    for index, _ in pairs(containers) do
        local player = game.get_player(index)
        if not player or not player.valid then
            goto continue
        end
        local container = fetch_container(index)
        local stack_size = container.stack_size
        local item_storage = container.item_storage
        if not item_storage then
            goto continue
        end

        local inv = player.get_inventory(defines.inventory.character_main)
        if not inv or not inv.valid then
            goto continue
        end
        local content = inv.get_contents()

        local temp_inv = {}


        for _, data in pairs(content) do
            temp_inv[data.name .. '_' .. data.quality] = { count = data.count, quality = data.quality }
            if item_storage[data.quality][data.name] then
                item(data, inv, item_storage[data.quality], stack_size)
            end
        end

        for _, storage_quality in pairs(item_storage) do
            for item_name, data in pairs(storage_quality) do
                local inventory_item = temp_inv[item_name .. '_' .. data.quality]
                if (not inventory_item) or inventory_item.quality == data.quality and inventory_item.count == 0 then
                    local s = { name = item_name, count = 0, quality = data.quality }
                    item(s, inv, item_storage[data.quality], stack_size)
                end
            end
        end

        ::continue::
    end
end

local function draw_main_frame(player, target)
    local container = fetch_container(player.index)
    local p = player
    if target and target.valid then
        container = fetch_container(target.index)
        p = target
    end

    local frame, main_frame = Gui.add_main_frame_with_toolbar(player.gui.screen, 'screen', main_frame_name, nil, close_name,
        p.name .. '´s private portable stash', 'Your personal storage chest.')
    container.gui.main_frame = main_frame
    frame.auto_center = true

    local data = {}

    local controls = frame.add { type = 'flow', direction = 'horizontal' }
    local items = frame.add { type = 'flow', direction = 'vertical' }
    container.gui.item_frame = items

    local tbl = controls.add { type = 'table', column_count = 1 }
    tbl.style.cell_padding = 4
    local btn =
        tbl.add
        {
            type = 'sprite-button',
            tooltip = '[color=blue]Info![/color]\nYou can easily remove an item by left/right-clicking it.\n\nItems selected in the table below will remove all stacks except one from the player inventory.\nIf the stack-size is bigger in the personal stash than the players inventory stack then the players inventory will automatically refill from the personal stash.\n\n[color=red]Usage[/color]\nPressing the following keys will do the following actions:\nCTRL: Retrieves all stacks from clicked item\nSHIFT:Retrieves a stack from clicked item.\nStack-Size slider will always ensure that you have <x> amounts of stacks in your inventory.\n\n[color=red]Deleting[/color]\nDelete Mode: Will delete the clicked item instantly.',
            sprite = 'utility/questionmark'
        }
    btn.style.height = 20
    btn.style.width = 20
    btn.enabled = false
    btn.focus()

    if not player.admin and this.ores_only then
        container.total_slots = 6
    end

    local amount_and_types
    if this.ores_only then
        amount_and_types = container.total_slots .. ' different ore'
    else
        amount_and_types = container.total_slots .. ' different item'
    end

    local text =
        tbl.add
        {
            type = 'label',
            caption = format('Stores unlimited quantity of items (up to ' .. amount_and_types .. ' types).\nRead the tooltip by hovering the question-mark above!')
        }
    text.style.single_line = false

    local tbl_2 = tbl.add { type = 'table', column_count = 4 }
    local stack_size = container.stack_size

    local stack_value = tbl_2.add({ type = 'label', caption = 'Stack Size: ' .. stack_size .. ' ' })
    stack_value.style.font = 'default-bold'
    data.stack_value = stack_value

    local slider =
        tbl_2.add(
            {
                type = 'slider',
                minimum_value = 0,
                maximum_value = 10,
                name = stack_slider_name,
                value = stack_size
            }
        )
    data.slider = slider
    slider.style.width = 115
    Gui.set_data(slider, data)

    local delete_mode = tbl_2.add({ type = 'label', caption = '  Delete Mode: ' })
    delete_mode.style.font = 'default-bold'
    local checkbox = tbl_2.add({ type = 'checkbox', name = delete_mode_name, state = false })
    data.checkbox = checkbox

    Gui.set_data(checkbox, data)

    tbl.add({ type = 'line' })

    player.opened = frame
    container.gui.updated = false
    container.gui.delete_mode = false

    if target and target.valid then
        container.gui.viewing_player = true
    else
        if container.gui.viewing_player then
            container.gui.viewing_player = false
        end
    end
end

local function update_gui()
    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]

        local container = fetch_container(player.index)
        if not container then
            goto continue
        end

        local frame = container.gui.item_frame
        if not frame or not frame.valid then
            remove_gui(player)
            goto continue
        end

        local chest_id = container.chest_id
        if not chest_id then
            goto continue
        end
        if container.gui.updated then
            goto continue
        end
        frame.clear()

        local tbl = frame.add { type = 'table', column_count = 10, name = 'personal_inventory' }

        tbl.style.cell_padding = 0
        local total = 0
        local items = {}

        local item_storage = container.item_storage

        if not item_storage then
            goto no_storage
        end
        for _, quality_storage in pairs(item_storage) do
            for _, data in pairs(quality_storage) do
                total = total + 1
                items[#items + 1] = { name = data.name, count = data.count, quality = data.quality }
            end
        end
        ::no_storage::

        local btn
        for _, item_data in pairs(items) do
            btn =
                tbl.add
                {
                    type = 'sprite-button',
                    sprite = 'item/' .. item_data.name,
                    style = 'slot_button',
                    tooltip = 'Name: ' .. item_data.name .. '\n' .. 'Quality: ' .. item_data.quality,
                    number = item_data.count,
                    name = get_quality(item_data.name, item_data.quality)
                }

            btn.enabled = true
            btn.style.height = size
            btn.style.width = size
            if container.gui.delete_mode then
                btn.tooltip = 'Press to delete this item.'
            end
            btn.focus()
        end

        while total < container.total_slots do
            local btn_1 = tbl.add { type = 'choose-elem-button', style = 'slot_button', elem_type = 'item-with-quality' }
            btn_1.enabled = true
            btn_1.style.height = size
            btn_1.style.width = size
            btn_1.focus()
            if container.gui.viewing_player then
                btn_1.enabled = false
            end
            total = total + 1
        end

        container.gui.updated = true
        ::continue::
    end
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
    local parent = element.parent
    if not parent then
        return
    end
    if parent.name ~= 'personal_inventory' then
        return
    end

    local container = fetch_container(player.index)

    if container.gui.viewing_player then
        goto update
    end

    local shift = event.shift
    local ctrl = event.control
    local name = element.name
    local item_storage = container.item_storage

    if not item_storage then
        return
    end

    local stripped_name = string.gsub(name, "_.*", "")
    local quality = string.match(name, "_(.+)$")

    local quality_storage = item_storage[quality]
    if not quality_storage then return end


    if container.gui.delete_mode then
        quality_storage[stripped_name] = nil
        container.gui.updated = false
        return
    end

    local creative_enabled = Misc.get('creative_enabled')
    if player.admin and (container.editor or creative_enabled) then
        if not quality_storage[stripped_name] then
            return
        end
        if ctrl then
            quality_storage[stripped_name].count = quality_storage[stripped_name].count + 5000000
            container.gui.updated = false
            goto update
        elseif shift then
            quality_storage[stripped_name].count = quality_storage[stripped_name].count - 5000000
            container.gui.updated = false
            if quality_storage[stripped_name].count <= 0 then
                quality_storage[stripped_name] = nil
            end
            goto update
        end
    end

    if quality_storage[stripped_name] and quality_storage[stripped_name].count and quality_storage[stripped_name].count <= 0 then
        quality_storage[stripped_name] = nil
        container.gui.updated = false
        goto update
    end

    if ctrl then
        local count = quality_storage[stripped_name] and quality_storage[stripped_name].count
        if not count then
            return
        end
        local inserted = player.insert { name = stripped_name, count = count, quality = quality_storage[stripped_name].quality }
        if not inserted then
            return
        end
        if inserted == count then
            quality_storage[stripped_name] = nil
        else
            quality_storage[stripped_name].count = quality_storage[stripped_name].count - inserted
        end
        container.gui.updated = false
    elseif shift then
        local count = quality_storage[stripped_name] and quality_storage[stripped_name].count
        if not count then
            return
        end


        if not prototypes.item[stripped_name] then
            quality_storage[stripped_name] = nil
            return
        end

        local stack = prototypes.item[stripped_name].stack_size
        if not stack then
            return
        end
        if count > stack then
            local inserted = player.insert { name = stripped_name, count = stack, quality = quality_storage[stripped_name].quality }
            quality_storage[stripped_name].count = quality_storage[stripped_name].count - inserted
        else
            player.insert { name = stripped_name, count = count, quality = quality_storage[stripped_name].quality }
            quality_storage[stripped_name] = nil
        end
        container.gui.updated = false
    end

    ::update::
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
    if parent.name ~= 'personal_inventory' then
        return
    end

    local container = fetch_container(player.index)
    local chest_id = container.chest_id
    if not chest_id then
        return
    end
    local item_storage = container.item_storage
    if not item_storage then
        container.item_storage = {}

        item_storage = container.item_storage
    end

    if not element.elem_value then return end

    local name = element.elem_value.name
    local quality = element.elem_value.quality

    if not name then
        return
    end

    local creative_enabled = Misc.get('creative_enabled')

    local storage_quality = item_storage[quality]

    if this.ores_only then
        if not ore_names[name] then
            player.print('You can only stash ores and wood.', Color.warning)
            goto update
        end
    end

    if this.allow_barrels then
        if string.match(name, 'barrel') then
            player.print('You can´t stash barrels.', Color.warning)
            goto update
        end
    end

    storage_quality[name] = { name = name, count = 0, quality = quality }

    if player.admin and (container.editor or creative_enabled) then
        storage_quality[name].count = 5000000
    end

    ::update::

    container.gui.updated = false
end

local function on_player_joined_game(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end

    if not does_exists(player.index) then
        add_object(player.index)
    end

    create_button(player)
end

local function tick()
    update_containers()
    update_gui()
end

local function on_pre_player_left_game(event)
    local player = game.get_player(event.player_index)

    if not player or not player.valid then
        return
    end

    clear_gui(player)
end

local function on_player_died(event)
    local player = game.get_player(event.player_index)

    if not player or not player.valid then
        return
    end

    clear_gui(player)
end

Gui.on_click(
    main_button_name,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local main_frame = screen[main_frame_name]
        if main_frame and main_frame.valid then
            Gui.clear_all_screen_frames(player)
        else
            Gui.clear_all_active_frames(player)
            draw_main_frame(player)
        end
    end
)

Gui.on_click(
    close_name,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid or not player.character then
            return
        end

        Gui.clear_all_screen_frames(player)
    end
)
Gui.on_value_changed(
    stack_slider_name,
    function (event)
        local player = event.player
        local element = event.element

        local data = Gui.get_data(element)
        local stack_value = data.stack_value
        if not stack_value or not stack_value.valid then
            return
        end

        local slider = data.slider
        if not slider or not slider.valid then
            return
        end

        local screen = player.gui.screen
        local main_frame = screen[main_frame_name]
        if main_frame and main_frame.valid then
            local container = fetch_container(player.index)
            container.stack_size = element.slider_value
            stack_value.caption = 'Stack Size: ' .. container.stack_size .. ' '
            container.gui.updated = false
        end
    end
)

Gui.on_checked_state_changed(
    delete_mode_name,
    function (event)
        local player = event.player
        local element = event.element

        local data = Gui.get_data(element)
        local checkbox = data.checkbox
        if not checkbox or not checkbox.valid then
            return
        end

        local screen = player.gui.screen
        local main_frame = screen[main_frame_name]
        local container = fetch_container(player.index)
        if container and main_frame and main_frame.valid then
            container.gui.delete_mode = element.state
            container.gui.updated = false
        end
    end
)

Commands.new('open_stash', 'Opens a players private stash!')
    :require_role('portable_chest')
    :callback(function (player, target_player)
        if not target_player or not target_player.valid then
            player.print('Please type a valid player name.', Color.warning)
            return
        end

        if target_player == player then
            return player.print('Cannot open self.', Color.warning)
        end

        if target_player.admin then
            return
        end

        draw_main_frame(player, target_player)
    end
    )

function Public.ores_only(value)
    if value then
        this.ores_only = value
    else
        this.ores_only = false
    end
    return this.ores_only
end

function Public.remove_player(index)
    this.main_containers[index] = nil
end

function Public.allow_barrels(value)
    if value then
        this.allow_barrels = value
    else
        this.allow_barrels = false
    end
    return this.allow_barrels
end

local reassign_settings_button =
    Token.register(
        function (data)
            local player_index = data.player_index
            local player = game.get_player(player_index)
            if player and player.valid then
                create_button(player)
            end
        end
    )

Event.add(
    ServerCommands.events.on_role_change,
    function (event)
        Task.set_timeout_in_ticks(10, reassign_settings_button, { player_index = event.player_index })
    end
)

Event.on_nth_tick(10, tick)
Event.add(defines.events.on_gui_click, gui_click)
Event.add(defines.events.on_player_created, on_player_joined_game)
Event.add(defines.events.on_gui_elem_changed, on_gui_elem_changed)
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)
Event.add(defines.events.on_player_died, on_player_died)
Event.add(
    defines.events.on_player_removed,
    function (event)
        Public.remove_player(event.player_index)
    end
)

Event.add(
    defines.events.on_gui_closed,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid or not player.character then
            return
        end

        clear_gui(player)
    end
)

Public.create_player = add_object
Public.create_button = create_button

return Public
