local Event = require 'utils.event'
local Global = require 'utils.global'
local Color = require 'utils.color_presets'
local Gui = require 'utils.gui'
local m_gui = require 'mod-gui'
local mod = m_gui.get_button_flow

local this = {
    inf_chests = {},
    inf_storage = {},
    inf_gui = {},
    player_chests = {},
    viewing_player = {},
    editor = {},
    ores_only = false,
    allow_barrels = true
}

local ore_names = {
    ['coal'] = true,
    ['stone'] = true,
    ['iron-ore'] = true,
    ['copper-ore'] = true,
    ['uranium-ore'] = true,
    ['wood'] = true
}

local format = string.format
local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()

local Public = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

function Public.get_table()
    return this
end

local function clear_gui(player)
    local data = this.inf_gui[player.index]
    if not data then
        return
    end
    if data.frame and data.frame.valid then
        data.frame.destroy()
    end
    this.inf_gui[player.index] = nil
    if this.viewing_player[player.index] then
        this.viewing_player[player.index] = nil
    end
end

local function create_button(player)
    mod(player).add(
        {
            type = 'sprite-button',
            sprite = 'item/logistic-chest-requester',
            name = main_button_name,
            tooltip = 'Portable inventory stash!',
            style = m_gui.button_style
        }
    )
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

local function item(item_name, item_count, player, chest_id)
    local item_stack = game.item_prototypes[item_name].stack_size
    local diff = item_count - item_stack

    if not this.inf_storage[chest_id] then
        this.inf_storage[chest_id] = {}
    end
    local storage = this.inf_storage[chest_id]

    if diff > 0 then
        local count = player.remove({name = item_name, count = diff})
        if not storage[item_name] then
            this.inf_storage[chest_id][item_name] = count
        else
            this.inf_storage[chest_id][item_name] = storage[item_name] + count
        end
    elseif diff < 0 then
        if not storage[item_name] or storage[item_name] <= 0 then
            goto continue
        end
        if storage[item_name] > (diff * -1) then
            local inserted = player.insert({name = item_name, count = (diff * -1)})
            this.inf_storage[chest_id][item_name] = storage[item_name] - inserted
        else
            player.insert({name = item_name, count = storage[item_name]})
            this.inf_storage[chest_id][item_name] = 0
        end
    end
    ::continue::
end

local function update_chest()
    for chest_id, chest in pairs(this.inf_chests) do
        if not chest.valid then
            goto continue
        end
        local storage = this.inf_storage[chest_id]
        if not storage then
            goto continue
        end

        local inv = chest.get_inventory(defines.inventory.character_main)
        local content = inv.get_contents()

        for item_name, item_count in pairs(content) do
            if storage[item_name] then
                item(item_name, item_count, inv, chest_id)
            end
        end

        for item_name, _ in pairs(this.inf_storage[chest_id]) do
            if not content[item_name] then
                item(item_name, 0, inv, chest_id)
            end
        end

        ::continue::
    end
end

local function draw_main_frame(player, target, chest_id)
    chest_id = chest_id or this.player_chests[player.index].chest_id
    if not chest_id then
        return
    end
    local p = target or player
    local frame =
        player.gui.screen.add {
        type = 'frame',
        caption = p.name .. '´s private portable stash',
        direction = 'vertical',
        name = main_frame_name
    }
    frame.auto_center = true
    local controls = frame.add {type = 'flow', direction = 'horizontal'}
    local items = frame.add {type = 'flow', direction = 'vertical'}

    local tbl = controls.add {type = 'table', column_count = 1}
    local btn =
        tbl.add {
        type = 'sprite-button',
        tooltip = '[color=blue]Info![/color]\nYou can easily remove an item by left/right-clicking it.\n\nItems selected in the table below will remove all stacks except one from the player inventory.\nIf the stack-size is bigger in the personal stash than the players inventory stack then the players inventory will automatically refill from the personal stash.\n\n[color=red]Usage[/color]\nPressing the following keys will do the following actions:\nCTRL: Retrieves all stacks from clicked item\nSHIFT:Retrieves a stack from clicked item.',
        sprite = 'utility/questionmark'
    }
    btn.style.height = 20
    btn.style.width = 20
    btn.enabled = false
    btn.focus()

    local amount_and_types
    if this.ores_only then
        amount_and_types = '6 different ore'
    else
        amount_and_types = '48 different item'
    end

    local text =
        tbl.add {
        type = 'label',
        caption = format(
            'Stores unlimited quantity of items (up to ' ..
                amount_and_types .. ' types).\nRead the tooltip by hovering the question-mark above!'
        )
    }
    text.style.single_line = false

    tbl.add({type = 'line'})

    player.opened = frame
    if target and target.valid then
        this.viewing_player[player.index] = true
    else
        if this.viewing_player[player.index] then
            this.viewing_player[player.index] = nil
        end
    end
    this.inf_gui[player.index] = {
        item_frame = items,
        frame = frame,
        updated = false
    }
end

local function update_gui()
    for _, player in pairs(game.connected_players) do
        local chest_gui_data = this.inf_gui[player.index]
        if not chest_gui_data then
            goto continue
        end
        local frame = chest_gui_data.item_frame
        if not frame or not frame.valid then
            clear_gui(player)
            goto continue
        end

        local chest_id = this.player_chests[player.index].chest_id
        if not chest_id then
            return
        end
        if this.inf_gui[player.index].updated then
            goto continue
        end
        frame.clear()

        local tbl = frame.add {type = 'table', column_count = 10, name = 'personal_inventory'}
        local total = 0
        local items = {}

        local storage = this.inf_storage[chest_id]

        if not storage then
            goto no_storage
        end
        for item_name, item_count in pairs(storage) do
            total = total + 1
            items[item_name] = item_count
        end
        ::no_storage::

        local btn
        for item_name, item_count in pairs(items) do
            btn =
                tbl.add {
                type = 'sprite-button',
                sprite = 'item/' .. item_name,
                style = 'slot_button',
                number = item_count,
                name = item_name
            }
            btn.enabled = true
        end

        if this.ores_only then
            while total < 6 do
                local btns = tbl.add {type = 'choose-elem-button', style = 'slot_button', elem_type = 'item'}
                btns.enabled = true
                if this.viewing_player[player.index] then
                    btns.enabled = false
                end
                total = total + 1
            end
        else
            while total < 48 do
                local btns = tbl.add {type = 'choose-elem-button', style = 'slot_button', elem_type = 'item'}
                btns.enabled = true
                if this.viewing_player[player.index] then
                    btns.enabled = false
                end
                total = total + 1
            end
        end

        this.inf_gui[player.index].updated = true
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
    local chest_id = this.player_chests[player.index].chest_id
    if not chest_id then
        return
    end

    if this.viewing_player[player.index] then
        goto update
    end

    local shift = event.shift
    local ctrl = event.control
    local name = element.name
    local storage = this.inf_storage[chest_id]

    if not storage then
        return
    end

    if this.editor[player.index] then
        if not storage[name] then
            return
        end
        if ctrl then
            storage[name] = storage[name] + 5000000
            goto update
        elseif shift then
            storage[name] = storage[name] - 5000000
            if storage[name] <= 0 then
                storage[name] = nil
            end
            goto update
        end
        if this.inf_gui[player.index] then
            this.inf_gui[player.index].updated = false
        end
    end

    if storage[name] and storage[name] <= 0 then
        storage[name] = nil
        if this.inf_gui[player.index] then
            this.inf_gui[player.index].updated = false
        end
        goto update
    end

    if ctrl then
        local count = storage[name]
        if not count then
            return
        end
        local inserted = player.insert {name = name, count = count}
        if not inserted then
            return
        end
        if inserted == count then
            storage[name] = nil
        else
            storage[name] = storage[name] - inserted
        end
        if this.inf_gui[player.index] then
            this.inf_gui[player.index].updated = false
        end
    elseif shift then
        local count = storage[name]
        local stack = game.item_prototypes[name].stack_size
        if not count then
            return
        end
        if not stack then
            return
        end
        if count > stack then
            local inserted = player.insert {name = name, count = stack}
            storage[name] = storage[name] - inserted
        else
            player.insert {name = name, count = count}
            storage[name] = nil
        end
        if this.inf_gui[player.index] then
            this.inf_gui[player.index].updated = false
        end
    end

    ::update::
end

local function gui_closed(event)
    local player = game.get_player(event.player_index)
    local type = event.gui_type

    if type == defines.gui_type.custom then
        clear_gui(player)
    end
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

    local chest_id = this.player_chests[player.index].chest_id
    if not chest_id then
        return
    end
    local storage = this.inf_storage[chest_id]
    if not storage then
        this.inf_storage[chest_id] = {}
        storage = this.inf_storage[chest_id]
    end
    local name = element.elem_value

    if not name then
        return
    end

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

    storage[name] = 0
    element.tooltip = 'Right click to remove.'
    if this.editor[player.index] then
        storage[name] = 5000000
    end

    ::update::

    if this.inf_gui[player.index] then
        this.inf_gui[player.index].updated = false
    end
end

local function on_player_joined_game(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end
    local chest_id = Gui.uid()
    if not this.player_chests[player.index] then
        this.player_chests[player.index] = {
            chest_id = chest_id
        }
    end

    if not this.inf_chests[player.index] then
        this.inf_chests[chest_id] = player
    end

    if not mod(player)[main_button_name] then
        create_button(player)
    end
end

local function tick()
    update_chest()
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
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local main_frame = screen[main_frame_name]
        if main_frame and main_frame.valid then
            clear_gui(player)
        else
            draw_main_frame(player)
        end
    end
)

commands.add_command(
    'open_stash',
    'Opens a players private stash!',
    function(cmd)
        local player = game.player

        if not validate_player(player) then
            return
        end

        if not cmd.parameter then
            return
        end
        local target_player = game.players[cmd.parameter]

        if target_player == player then
            return player.print('Cannot open self.', Color.warning)
        end

        if target_player.admin then
            return
        end

        if target_player and target_player.valid then
            local chest_id = this.player_chests[target_player.index].chest_id
            if not chest_id then
                return
            end
            draw_main_frame(player, target_player, chest_id)
        else
            player.print('Please type a valid player name.', Color.warning)
        end
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

function Public.allow_barrels(value)
    if value then
        this.allow_barrels = value
    else
        this.allow_barrels = false
    end
    return this.allow_barrels
end

Event.on_nth_tick(15, tick)
Event.add(defines.events.on_gui_click, gui_click)
Event.add(defines.events.on_gui_closed, gui_closed)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_elem_changed, on_gui_elem_changed)
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)
Event.add(defines.events.on_player_died, on_player_died)

return Public
