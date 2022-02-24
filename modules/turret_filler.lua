local Event = require 'utils.event'
local Global = require 'utils.global'

local turrettable = {
    players = {},
    enabled = true
}
local Public = {}

Global.register(
    turrettable,
    function(tbl)
        turrettable = tbl
    end
)

function Public.get_table()
    return turrettable
end

local function draw_turret_button()
    for _, player in pairs(game.connected_players) do
        if not player.gui.top.turret_filler_button then
            local b = player.gui.top.add({type = 'sprite-button', name = 'turret_filler_button', sprite = 'entity/gun-turret', tooltip = {'modules.turret_filler_tooltip'}})
            b.style.minimal_height = 38
            b.style.maximal_height = 38
        end
        player.gui.top.turret_filler_button.visible = turrettable.enabled
    end
end

local function turret_gui(player)
    if player.gui.screen['turret_filler'] then
        player.gui.screen['turret_filler'].destroy()
        return
    end
    if turrettable.enabled == false then
        player.gui.top.turret_filler_button.visible = false
        return
    end
    local playerdata = turrettable.players[player.index]
    local frame = player.gui.screen.add({type = 'frame', name = 'turret_filler', caption = {'modules.turret_filler'}, direction = 'vertical'})
    frame.location = {x = 150, y = 45}
    frame.style.minimal_height = 200
    frame.style.maximal_height = 500
    frame.style.minimal_width = 200
    frame.style.maximal_width = 400
    frame.add({type = 'label', caption = {'modules.turret_filler_tooltip'}})
    local switch_state = 'left'
    if playerdata.enabled then
        switch_state = 'right'
    end
    local t = frame.add({type = 'table', column_count = 4, name = 'turret_filler_enabled_table'})
    t.add({type = 'label', caption = {'modules.turret_filler_label_enabled'}})
    local label = t.add({type = 'label', caption = 'OFF'})
    label.style.padding = 0
    label.style.left_padding = 10
    label.style.font_color = {0.77, 0.77, 0.77}
    local switch = t.add({type = 'switch', name = 'turret_filler_enabled'})
    switch.switch_state = switch_state
    switch.style.padding = 0
    switch.style.margin = 0
    local label2 = t.add({type = 'label', caption = 'ON'})
    label2.style.padding = 0
    label2.style.font_color = {0.70, 0.70, 0.70}

    local amount = playerdata.amount
    local t2 = frame.add({type = 'table', column_count = 3, name = 'turret_filler_amount_table'})
    t2.add({type = 'label', caption = {'modules.turret_filler_label_amount'}})
    t2.add({type = 'slider', name = 'turret_filler_amount', minimum_value = 1, maximum_value = 100, value = amount or 5})
    local textfield = t2.add({type = 'textfield', name = 'turret_filler_amount2', numeric = true, text = amount or 5})
    textfield.style.width = 40
    local t3 = frame.add({type = 'table', column_count = 4, name = 'turret_filler_ammo_table'})
    t3.add({type = 'label', caption = {'modules.turret_filler_ammo_type'}})
    local filter = {{filter = 'name', name = {'firearm-magazine', 'piercing-rounds-magazine', 'uranium-rounds-magazine'}}}
    t3.add({type = 'choose-elem-button', name = 'turret_filler_ammo', elem_type = 'item', item = playerdata.ammo_type or 'firearm-magazine', elem_filters = filter})
    t3.add({type = 'label', caption = {'modules.turret_filler_ammo_lower'}})
    t3.add({type = 'checkbox', name = 'turret_filler_lower', state = playerdata.lower_allowed})
    frame.add({type = 'line'})
    local close = frame.add({type = 'button', name = 'close_turret_filler', caption = 'Save & Close'})
    close.style.horizontally_stretchable = true
end

local function save_and_close(player)
    local frame = player.gui.screen['turret_filler']
    if not frame or not frame.valid then
        return
    end
    turrettable.players[player.index].enabled = frame['turret_filler_enabled_table']['turret_filler_enabled'].switch_state == 'right'
    turrettable.players[player.index].amount = frame['turret_filler_amount_table']['turret_filler_amount'].slider_value
    turrettable.players[player.index].ammo_type = frame['turret_filler_ammo_table']['turret_filler_ammo'].elem_value
    turrettable.players[player.index].lower_allowed = frame['turret_filler_ammo_table']['turret_filler_lower'].state
    frame.destroy()
end

local function on_player_joined_game(event)
    draw_turret_button()
    if not turrettable.players[event.player_index] then
        turrettable.players[event.player_index] = {
            enabled = true,
            amount = 5,
            ammo_type = 'firearm-magazine',
            lower_allowed = false
        }
    end
end

local function on_gui_click(event)
    if not event then
        return
    end
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    local player = game.get_player(event.player_index)
    if event.element.name == 'turret_filler_button' then
        turret_gui(player)
        return
    elseif event.element.name == 'close_turret_filler' then
        save_and_close(player)
        return
    end
end

local function flying_text(surface, position, text, color)
    surface.create_entity(
        {
            name = 'flying-text',
            position = {position.x, position.y - 0.5},
            text = text,
            color = color
        }
    )
end

local function on_gui_value_changed(event)
    local slider = event.element
    if not slider or not slider.valid then
        return
    end
    if slider.name ~= 'turret_filler_amount' then
        return
    end
    local frame = slider.parent
    frame['turret_filler_amount2'].text = tostring(slider.slider_value)
end

local function on_gui_text_changed(event)
    local field = event.element
    if not field or not field.valid then
        return
    end
    if field.name ~= 'turret_filler_amount2' then
        return
    end
    local frame = field.parent
    local slider = frame['turret_filler_amount']
    local number = tonumber(field.text) or 1
    if number <= slider.get_slider_maximum() and number >= slider.get_slider_minimum() then
        slider.slider_value = number
    end
end

local function transfer_ammo(player, turret)
    if not turrettable.players[player.index].enabled then
        return
    end
    local item = turrettable.players[player.index].ammo_type
    local count = player.get_item_count(item) or 0
    if count == 0 and turrettable.players[player.index].lower_allowed then
        if item == 'uranium-rounds-magazine' then
            item = 'piercing-rounds-magazine'
            count = player.get_item_count(item) or 0
        end
        if count == 0 and item == 'piercing-rounds-magazine' then
            item = 'firearm-magazine'
            count = player.get_item_count(item) or 0
        end
    end
    if count > 0 then
        local inserted = turret.insert({name = item, count = math.min(count, turrettable.players[player.index].amount)})
        player.remove_item({name = item, count = inserted})
        local text = '-' .. inserted .. ' [item=' .. item .. ']'
        flying_text(turret.surface, turret.position, text, {r = 0.8, g = 0.2, b = 0.2})
    end
end

local function on_built_entity(event)
    if not turrettable.enabled then
        return
    end
    local turret = event.created_entity
    if not turret or not turret.valid then
        return
    end
    if turret.name ~= 'gun-turret' then
        return
    end
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end
    transfer_ammo(player, turret)
end

local function on_robot_built_entity(event)
    if not turrettable.enabled then
        return
    end
    local turret = event.created_entity
    if not turret or not turret.valid then
        return
    end
    if turret.name ~= 'gun-turret' then
        return
    end
    local player = turret.last_user
    if player and player.valid and player.connected then
        local x, y = player.position.x - turret.position.x, player.position.y - turret.position.y
        if player.surface == turret.surface and math.sqrt(x * x + y * y) <= 40 then
            transfer_ammo(player, turret)
        end
    end
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_gui_value_changed, on_gui_value_changed)
Event.add(defines.events.on_gui_text_changed, on_gui_text_changed)

return Public
