-- created by Gerkiz

local Global = require 'utils.global'
local Color = require 'utils.color_presets'
-- local SpamProtection = require 'utils.spam_protection'
local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Commands = require 'utils.commands'

local this = {
    data = {},
    module_disabled = false
}
local Public = {}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local main_frame_name = Gui.uid_name()

local space = {
    minimal_height = 10,
    top_padding = 0,
    bottom_padding = 0
}

local function get_player_data(player, remove)
    local data = this.data[player.index]
    if remove and data then
        if data and data.frame and data.frame.valid then
            data.frame.destroy()
        end

        this.data[player.index] = nil
        return
    end

    if not this.data[player.index] then
        this.data[player.index] = {}
    end

    return this.data[player.index]
end

local function unpack_inventory(inventory)
    if not inventory then
        return
    end
    local unpacked = {}
    for i = 1, #inventory do
        unpacked[i] = inventory[i]
    end
    return unpacked
end

local function add_style(guiIn, styleIn)
    for k, v in pairs(styleIn) do
        guiIn.style[k] = v
    end
end

local function adjust_space(guiIn)
    add_style(guiIn.add { type = 'line', direction = 'horizontal' }, space)
end

local function is_valid(obj)
    if not obj then
        return false
    end
    if not obj.valid then
        return false
    end
    return true
end

local function get_target_player(index)
    local viewingPlayer = game.get_player(index)
    if not viewingPlayer or not viewingPlayer.valid then
        return false
    end
    return viewingPlayer
end

local function watching_inventory(player)
    for index, data in pairs(this.data) do
        if data and data.player_opened == player.index then
            local source_player = game.get_player(index)
            if not source_player or not source_player.valid then
                return false
            else
                return source_player, data
            end
        end
    end
    return false
end

local function player_opened(player)
    local data = get_player_data(player)

    if not data then
        return false
    end

    local opened = data.player_opened

    if not opened or not player.gui.screen[main_frame_name] then
        return false
    end

    return true, opened
end

local function validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if not game.get_player(player.index) then
        return false
    end
    return true
end

local function close_player_inventory(player)
    local data = get_player_data(player)

    if not data then
        return
    end

    local gui = player.gui.screen

    if not is_valid(gui) then
        return
    end

    local element = gui[main_frame_name]

    if not is_valid(element) then
        return
    end

    element.destroy()
    get_player_data(player, true)
end

local function get_inventory_type(player, inventory_type)
    local target_types = {
        ['Main'] = function ()
            return unpack_inventory(player.get_main_inventory())
        end,
        ['Armor'] = function ()
            return unpack_inventory(player.get_inventory(defines.inventory.character_armor))
        end,
        ['Guns'] = function ()
            return unpack_inventory(player.get_inventory(defines.inventory.character_guns))
        end,
        ['Ammo'] = function ()
            return unpack_inventory(player.get_inventory(defines.inventory.character_ammo))
        end,
        ['Trash'] = function ()
            return unpack_inventory(player.get_inventory(defines.inventory.character_trash))
        end
    }
    return target_types[inventory_type]()
end

local function redraw_inventory(gui, source, target, caption, panel_type)
    gui.clear()

    if not panel_type then
        if gui and gui.valid then
            gui.destroy()
        end
        return
    end

    local items_table = gui.add({ type = 'table', column_count = 11 })
    local types = prototypes.item

    local screen = source.gui.screen

    if not is_valid(screen) then
        return
    end

    local inventory_gui = screen[main_frame_name]
    inventory_gui.caption = 'Inventory of ' .. target.name

    for i = 1, #panel_type do
        if panel_type[i] and panel_type[i].valid_for_read then
            local name = panel_type[i].name
            local count = panel_type[i].count
            local quality = panel_type[i].quality
            local flow = items_table.add({ type = 'flow' })
            flow.style.vertical_align = 'bottom'

            local button =
                flow.add(
                    {
                        type = 'sprite-button',
                        sprite = 'item/' .. name,
                        number = count,
                        name = name,
                        tooltip = { '', (quality.name == 'normal' and '' or { '', quality.localised_name, ' ' }), types[name].localised_name },
                        style = 'slot_button'
                    }
                )
            button.enabled = false
            if quality.name ~= 'normal' then
                local qual_button = button.add({ type = 'sprite-button', sprite = 'quality/' .. quality.name, style = 'transparent_slot' })
                qual_button.style.top_padding = 18
                qual_button.style.right_padding = 18
            end

            if caption == 'Armor' then
                if target.get_inventory(5)[1].grid then
                    local p_armor = target.get_inventory(5)[1].grid.get_contents()
                    local grid_flow = items_table.add({ type = 'table', column_count = 10 })
                    for _, item in pairs(p_armor) do
                        local armor_gui =
                            grid_flow.add(
                                {
                                    type = 'sprite-button',
                                    sprite = 'item/' .. item.name,
                                    number = item.count,
                                    name = item.name .. item.quality,
                                    tooltip = { '', (item.quality == 'normal' and '' or { '', prototypes.quality[item.quality].localised_name, ' ' }), types[item.name].localised_name },
                                    style = 'slot_button'
                                }
                            )
                        armor_gui.enabled = false
                        if item.quality ~= 'normal' then
                            local qualgrid_button = armor_gui.add({ type = 'sprite-button', sprite = 'quality/' .. quality.name, style = 'transparent_slot' })
                            qualgrid_button.style.top_padding = 18
                            qualgrid_button.style.right_padding = 18
                        end
                    end
                end
            end
        end
    end
end

local function add_inventory(panel, source, target, caption, panel_type)
    local data = get_player_data(source)
    data.panel_type = data.panel_type or {}
    local pane_name = panel.add({ type = 'tab', caption = caption, name = caption })
    local scroll_pane =
        panel.add {
            type = 'scroll-pane',
            name = caption .. 'tab',
            direction = 'vertical',
            vertical_scroll_policy = 'always',
            horizontal_scroll_policy = 'never'
        }
    scroll_pane.style.maximal_height = 200
    scroll_pane.style.horizontally_stretchable = true
    scroll_pane.style.minimal_height = 200
    scroll_pane.style.right_padding = 0
    panel.add_tab(pane_name, scroll_pane)

    data.panel_type[caption] = panel_type

    redraw_inventory(scroll_pane, source, target, caption, panel_type)
end

local function open_inventory(source, target)
    if not validate_player(source) then
        return
    end
    source.opened = nil

    if not validate_player(target) then
        return
    end

    local screen = source.gui.screen

    if not is_valid(screen) then
        return
    end

    local inventory_gui = screen[main_frame_name]
    if inventory_gui then
        close_player_inventory(source)
    end

    local frame =
        screen.add(
            {
                type = 'frame',
                caption = 'Inventory',
                direction = 'vertical',
                name = main_frame_name
            }
        )

    if not (frame and frame.valid) then
        return
    end

    frame.auto_center = true
    frame.style.minimal_width = 500
    frame.style.minimal_height = 250

    adjust_space(frame)

    local panel = frame.add({ type = 'tabbed-pane', name = 'tabbed_pane' })
    panel.selected_tab_index = 1

    local data = get_player_data(source)

    data.player_opened = target.index
    data.last_tab = 'Main'

    local main = unpack_inventory(target.get_main_inventory())
    if not main then
        return
    end

    local armor = unpack_inventory(target.get_inventory(defines.inventory.character_armor))
    local guns = unpack_inventory(target.get_inventory(defines.inventory.character_guns))
    local ammo = unpack_inventory(target.get_inventory(defines.inventory.character_ammo))
    local trash = unpack_inventory(target.get_inventory(defines.inventory.character_trash))

    local types = {
        ['Main'] = main,
        ['Armor'] = armor,
        ['Guns'] = guns,
        ['Ammo'] = ammo,
        ['Trash'] = trash
    }

    for frame_name, callback in pairs(types) do
        if callback ~= nil then
            add_inventory(panel, source, target, frame_name, callback)
        end
    end
    source.opened = frame
end

local function on_gui_click(event)
    local player = game.get_player(event.player_index)
    if not player or not this.data[player.index] then
        return
    end

    local element = event.element

    if not element or not element.valid then
        return
    end

    local types = {
        ['Main'] = true,
        ['Armor'] = true,
        ['Guns'] = true,
        ['Ammo'] = true,
        ['Trash'] = true
    }

    local name = element.name

    if not types[name] then
        return
    end

    -- local is_spamming = SpamProtection.is_spamming(player, nil, 'Player Inventory')
    -- if is_spamming then
    --     return
    -- end

    local data = get_player_data(player)
    if not data then
        return
    end

    data.last_tab = name

    local valid, target = player_opened(player)
    if valid and target then
        local viewingPlayer = get_target_player(target)
        if not viewingPlayer then
            return false
        end

        local frame = Public.get_active_frame(player)

        if frame then
            local callback = get_inventory_type(viewingPlayer, name)
            redraw_inventory(frame, player, viewingPlayer, name, callback)
        end
    end
end

local function on_pre_player_left_game(event)
    local player = game.get_player(event.player_index)
    if not player or not this.data[player.index] then
        return
    end

    close_player_inventory(player)
end

local function update_gui(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local source_player, source_data = watching_inventory(player)
    if not source_player or not source_data then
        return
    end

    local frame = Public.get_active_frame(source_player)
    if frame and frame.valid then
        local callback = get_inventory_type(player, source_data.last_tab)
        if frame.name == source_data.last_tab .. 'tab' then
            redraw_inventory(frame, source_player, player, source_data.last_tab, callback)
        end
    end
end

Commands.new('inventory', 'Open another players inventory')
    :add_parameter('player', false, 'player-online')
    :callback(
        function (player, target)
            if this.module_disabled then
                return false
            end

            if target and target.valid then
                local valid, opened = player_opened(player)
                if valid then
                    if target.index == opened then
                        player.print('You are already viewing this players inventory.', Color.warning)
                        return false
                    end
                end

                open_inventory(player, target)
            else
                player.print('[Inventory] Please type a name of a player who is connected.', Color.warning)
            end
        end
    )

function Public.show_inventory(player, target_player)
    if not player or not player.valid then
        return false
    end
    if not target_player or not target_player.valid then
        return false
    end

    local valid, opened = player_opened(player)
    if valid then
        if target_player.index == opened then
            player.print('You are already viewing this players inventory.', Color.warning)
            return false
        end
    end

    if validate_player(target_player) then
        open_inventory(player, target_player)
        return true
    else
        player.print('[Inventory] Please type a valid player name.', Color.warning)
        return false
    end
end

function Public.get_active_frame(player)
    if not player.gui.screen[main_frame_name] then
        return false
    end
    return player.gui.screen[main_frame_name].tabbed_pane.tabs[player.gui.screen[main_frame_name].tabbed_pane.selected_tab_index].content
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

--- Disables the module.
---@param state boolean
function Public.module_disabled(state)
    this.module_disabled = state or false
end

Gui.on_custom_close(
    main_frame_name,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not this.data[player.index] then
            return
        end

        close_player_inventory(player)
    end
)

Event.add(defines.events.on_player_main_inventory_changed, update_gui)
Event.add(defines.events.on_player_gun_inventory_changed, update_gui)
Event.add(defines.events.on_player_ammo_inventory_changed, update_gui)
Event.add(defines.events.on_player_armor_inventory_changed, update_gui)
Event.add(defines.events.on_player_trash_inventory_changed, update_gui)
Event.add(defines.events.on_player_placed_equipment, update_gui)
Event.add(defines.events.on_player_removed_equipment, update_gui)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)

Public.close_player_inventory = close_player_inventory

return Public
