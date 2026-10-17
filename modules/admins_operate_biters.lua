-- Biter Commander - lets admins (or whitelisted/regular players when enabled) command unit groups

local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local SpamProtection = require 'utils.spam_protection'
local AI = require 'utils.functions.AI'

local Public = {}

local random = math.random
local floor = math.floor

local this = {
    active_unit_groups = {},
    enabled = true,
    whitelist = {},
    admin_mode = true,   --if only admins can see and use the panel
    teleporting = false, --if teleporting is allowed for non-admins
    buildings = true,    --if player can trigger building nests and worms
    locations = {},      --last window location per player index
    selected_force = {}, --selected force name (or ALL) per player index
    selected_group = {}, --selected unit group id per player index
    dirty = false        --group list changed and open panels need refresh
}

Global.register(
    this,
    function (t)
        this = t
    end
)

local L = 'modules_biter_commander.'
local ALL = '*'
local builders_cost = 5
local unit_search_radius = 50
local default_location = { x = 5, y = 45 }

local main_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local info_button_name = Gui.uid_name()
local close_button_name = Gui.uid_name()
local force_select_name = Gui.uid_name()
local group_select_name = Gui.uid_name()

-- the window stays open when other comfy frames get cleared
Gui.screen_to_bypass(main_frame_name)

local sections = {
    { key = 'camera',     commands = { 'pan', 'teleport' } },
    { key = 'movement',   commands = { 'movetome', 'movetoposition', 'patroltome', 'patroltoposition' } },
    { key = 'build',      commands = { 'settle', 'siege' } },
    { key = 'attack',     commands = { 'attackenemiesaround', 'attackobstaclesaround', 'attackenemiesaroundme', 'attackobstaclesaroundme' } },
    { key = 'management', commands = { 'report', 'forcemove', 'addunitsaroundme', 'addunits', 'creategroup', 'disband' } }
}

local direction_pad = { 'nw', 'n', 'ne', 'w', 'center', 'e', 'sw', 's', 'se' }

local directions = {
    nw = { -25, -25 },
    n = { 0, -25 },
    ne = { 25, -25 },
    w = { -25, 0 },
    e = { 25, 0 },
    sw = { -25, 25 },
    s = { 0, 25 },
    se = { 25, 25 }
}

local element_names = {}
for _, section in pairs(sections) do
    for _, key in pairs(section.commands) do
        element_names[key] = Gui.uid_name()
    end
end
for _, key in pairs(direction_pad) do
    element_names[key] = Gui.uid_name()
end

local reply_counts = { ok = 5, no = 5, attack = 4, disband = 5 }
local reply_colors = {
    ok = { r = 0, g = 220, b = 0 },
    no = { r = 220, g = 0, b = 0 },
    attack = { r = 0, g = 100, b = 220 },
    disband = { r = 200, g = 200, b = 0 }
}
local message_color = { r = 255, g = 255, b = 255 }
local print_color = { color = { r = 0.88, g = 0.88, b = 0.88 } }

local group_states = {
    [defines.group_state.gathering] = 'gathering',
    [defines.group_state.moving] = 'moving',
    [defines.group_state.attacking_distraction] = 'attacking_distraction',
    [defines.group_state.attacking_target] = 'attacking_target',
    [defines.group_state.finished] = 'finished',
    [defines.group_state.pathfinding] = 'pathfinding',
    [defines.group_state.wander_in_group] = 'wander_in_group'
}

local function round(value)
    return floor(value + 0.5)
end

local function can_use(player)
    if this.admin_mode and not player.admin then
        return false
    end
    return this.enabled or this.whitelist[player.name] == true
end

local function reply(player, mood, position)
    player.create_local_flying_text { text = { L .. 'reply_' .. mood .. '_' .. random(1, reply_counts[mood]) }, position = position, color = reply_colors[mood] }
end

local function flying_message(player, key, position)
    player.create_local_flying_text { text = { L .. key }, position = position, color = message_color }
end

----------------------forces and groups-----------------

---Non-admins are always locked to their own force
local function get_selected_force(player)
    if not player.admin then
        return player.force.name
    end
    local name = this.selected_force[player.index]
    if name == ALL then
        return ALL
    end
    if name and game.forces[name] then
        return name
    end
    return player.force.name
end

local function build_force_items(player)
    local selected = get_selected_force(player)
    if not player.admin then
        return { selected }, { selected }, 1
    end
    ---@type LocalisedString[]
    local items = { { L .. 'force_all' } }
    local names = { ALL }
    local selected_index = 1
    for _, force in pairs(game.forces) do
        local name = force.name
        if name ~= 'neutral' then
            items[#items + 1] = name
            names[#names + 1] = name
            if name == selected then
                selected_index = #names
            end
        end
    end
    return items, names, selected_index
end

local function prune_groups()
    for id, entry in pairs(this.active_unit_groups) do
        if not entry.group.valid then
            this.active_unit_groups[id] = nil
        end
    end
end

local function build_group_items(player)
    prune_groups()
    local force_name = get_selected_force(player)
    local ids = {}
    for id, entry in pairs(this.active_unit_groups) do
        if force_name == ALL or entry.group.force.name == force_name then
            ids[#ids + 1] = id
        end
    end
    table.sort(ids)

    local items = { { L .. 'group_none' } }
    local group_ids = { false }
    local selected_index = 1
    for _, id in pairs(ids) do
        local group = this.active_unit_groups[id].group
        items[#items + 1] = { L .. 'group_label', id, #group.members, group.force.name }
        group_ids[#group_ids + 1] = id
        if id == this.selected_group[player.index] then
            selected_index = #group_ids
        end
    end
    if selected_index == 1 then
        this.selected_group[player.index] = nil
    end
    return items, group_ids, selected_index
end

----------------------------gui helpers-----------------------

local function get_frame(player)
    local frame = player.gui.screen[main_frame_name]
    if frame and frame.valid then
        return frame
    end
end

local function get_frame_data(player)
    local frame = get_frame(player)
    if frame then
        return Gui.get_data(frame), frame
    end
end

local function refresh_player(player)
    local data = get_frame_data(player)
    if not data then
        return
    end
    local items, names, selected_index = build_force_items(player)
    data.force_select.items = items
    data.force_select.selected_index = selected_index
    data.force_select.enabled = player.admin
    data.force_names = names

    local group_items, group_ids, group_index = build_group_items(player)
    data.group_select.items = group_items
    data.group_select.selected_index = group_index
    data.group_ids = group_ids
end

local function refresh_all()
    for _, player in pairs(game.connected_players) do
        refresh_player(player)
    end
end

---Returns the selected group if it is valid and the player may command it
local function get_selected_group(player)
    local id = this.selected_group[player.index]
    if not id then
        player.print({ L .. 'msg_no_group' }, print_color)
        return
    end
    local entry = this.active_unit_groups[id]
    if not (entry and entry.group.valid) then
        this.selected_group[player.index] = nil
        player.print({ L .. 'msg_group_gone' }, print_color)
        refresh_player(player)
        return
    end
    if not player.admin and entry.group.force ~= player.force then
        player.print({ L .. 'msg_no_permission' }, print_color)
        return
    end
    return entry.group
end

---Reads coordinates from the panel, empty fields get filled with the group position
local function get_coords(group, data)
    local x = tonumber(data.coord_x.text)
    local y = tonumber(data.coord_y.text)
    if not x then
        x = round(group.position.x)
        data.coord_x.text = tostring(x)
    end
    if not y then
        y = round(group.position.y)
        data.coord_y.text = tostring(y)
    end
    return { x = x, y = y }
end

local function set_directions(data, offset)
    local x = tonumber(data.coord_x.text) or 0
    local y = tonumber(data.coord_y.text) or 0
    data.coord_x.text = tostring(round(x + offset[1]))
    data.coord_y.text = tostring(round(y + offset[2]))
end

----------------------------building-----------------------

---Returns shuffled group members if there is enough valid ones to build something
local function get_builders(group)
    if not this.buildings then
        return
    end
    local units = group.members
    if #units < builders_cost then
        return
    end
    table.shuffle_table(units)
    for i = 1, builders_cost, 1 do
        if not units[i].valid then
            return
        end
    end
    return units
end

local function consume_builders(units, surface, position)
    surface.create_entity({ name = 'blood-explosion-huge', position = position })
    for i = 1, builders_cost, 1 do
        units[i].surface.create_entity({ name = 'blood-explosion-huge', position = units[i].position })
        units[i].destroy()
    end
end

local function place_nest_near_unit_group(group)
    local units = get_builders(group)
    if not units then
        return false
    end
    local name = 'biter-spawner'
    if random(1, 3) == 1 then
        name = 'spitter-spawner'
    end
    local position = group.surface.find_non_colliding_position(name, group.position, 16, 1)
    if not position then
        return false
    end
    group.surface.create_entity({ name = name, position = position, force = group.force })
    consume_builders(units, group.surface, position)
    return true
end

local function build_worm(group)
    local units = get_builders(group)
    if not units then
        return false
    end
    local position = group.surface.find_non_colliding_position('assembling-machine-1', group.position, 8, 1)
    if not position then
        return false
    end
    local worm = AI.pick_worm(group.force.get_evolution_factor(group.surface))
    group.surface.create_entity({ name = worm, position = position, force = group.force })
    consume_builders(units, group.surface, position)
    return true
end

----------------------------commands-----------------------

local function move_group(group, player, position, distraction)
    if position then
        group.set_command(AI.command_move_to(position, distraction))
        reply(player, 'ok', group.position)
    else
        reply(player, 'no', group.position)
    end
end

local function attack_area(group, player, position)
    group.set_command(AI.command_attack_area(position, 25))
    reply(player, 'attack', group.position)
end

local function attack_obstacles(group, player, surface, position, fail_message)
    -- obstacles closest to the group go first, so it eats its way through dense areas
    local command = AI.command_attack_obstacles(surface, position, nil, group.position)
    -- last command is always move_to, so there must be more to have any obstacles
    if #command.commands > 1 then
        group.set_command(command)
        reply(player, 'attack', group.position)
    else
        player.print({ L .. fail_message }, print_color)
        reply(player, 'no', group.position)
    end
end

local function register_group(group)
    this.active_unit_groups[group.unique_id] = { id = group.unique_id, group = group }
end

---Adds units around position into the group. The group gets recreated so everyone gathers at it, selections move to the new group.
local function add_units_around(group, player, surface, position)
    local units = surface.find_entities_filtered { position = position, radius = unit_search_radius, type = 'unit', force = group.force }
    local old_id = group.unique_id
    local new_group = AI.regroup(group, units)
    if new_group.unique_id == old_id then
        reply(player, 'no', group.position)
        return
    end
    register_group(new_group)
    this.active_unit_groups[old_id] = nil
    for player_index, id in pairs(this.selected_group) do
        if id == old_id then
            this.selected_group[player_index] = new_group.unique_id
        end
    end
    reply(player, 'ok', new_group.position)
    refresh_all()
end

---Commands working with the selected group, called with (group, player, data)
local group_commands = {
    pan = function (group, player)
        player.set_controller({ type = defines.controllers.remote, position = group.position, surface = group.surface })
    end,
    teleport = function (group, player)
        if player.admin or this.teleporting then
            player.teleport(group.position, group.surface)
        else
            flying_message(player, 'msg_teleport_disabled', player.position)
        end
    end,
    movetome = function (group, player)
        move_group(group, player, player.position, defines.distraction.none)
    end,
    movetoposition = function (group, player, data)
        move_group(group, player, get_coords(group, data), defines.distraction.none)
    end,
    patroltome = function (group, player)
        move_group(group, player, player.position, defines.distraction.by_enemy)
    end,
    patroltoposition = function (group, player, data)
        move_group(group, player, get_coords(group, data), defines.distraction.by_enemy)
    end,
    settle = function (group, player)
        if place_nest_near_unit_group(group) then
            reply(player, 'ok', group.position)
        else
            reply(player, 'no', group.position)
            player.print({ L .. 'msg_settle_failed' }, print_color)
        end
    end,
    siege = function (group, player)
        if build_worm(group) then
            reply(player, 'ok', group.position)
        else
            reply(player, 'no', group.position)
            player.print({ L .. 'msg_worm_failed' }, print_color)
        end
    end,
    attackenemiesaround = function (group, player)
        attack_area(group, player, group.position)
    end,
    attackobstaclesaround = function (group, player)
        attack_obstacles(group, player, group.surface, group.position, 'msg_no_obstacles_group')
    end,
    attackenemiesaroundme = function (group, player)
        attack_area(group, player, player.position)
    end,
    attackobstaclesaroundme = function (group, player)
        attack_obstacles(group, player, player.surface, player.position, 'msg_no_obstacles_player')
    end,
    report = function (group, player)
        local state = group_states[group.state] or 'unknown'
        flying_message(player, 'state_' .. state, group.position)
    end,
    forcemove = function (group, player)
        group.start_moving()
        reply(player, 'ok', group.position)
    end,
    addunitsaroundme = function (group, player)
        add_units_around(group, player, player.surface, player.position)
    end,
    addunits = function (group, player)
        add_units_around(group, player, group.surface, group.position)
    end,
    disband = function (group, player)
        reply(player, 'disband', group.position)
        group.destroy()
    end,
    center = function (group, _, data)
        data.coord_x.text = tostring(round(group.position.x))
        data.coord_y.text = tostring(round(group.position.y))
    end
}

---Creates group of the selected force from units around the player and selects it
local function create_group(player)
    local force_name = get_selected_force(player)
    if force_name == ALL then
        force_name = player.force.name
    end
    local units = player.surface.find_entities_filtered { position = player.position, radius = unit_search_radius, type = 'unit', force = force_name }
    if #units == 0 then
        player.print({ L .. 'msg_no_units', force_name }, print_color)
        reply(player, 'no', player.position)
        return
    end
    local group = AI.create_group(player.surface, player.position, force_name, units)
    -- registered directly, so the group is listed right away
    register_group(group)
    this.selected_group[player.index] = group.unique_id
    flying_message(player, 'msg_group_created', player.position)
    refresh_all()
end

local function on_command(player, key)
    local data, frame = get_frame_data(player)
    if not data then
        return
    end
    if not can_use(player) then
        Gui.destroy(frame)
        return
    end
    if directions[key] then
        set_directions(data, directions[key])
        return
    end
    if key == 'creategroup' then
        create_group(player)
        return
    end
    local group = get_selected_group(player)
    if not group then
        return
    end
    group_commands[key](group, player, data)
    refresh_player(player)
end

----------------------------gui-----------------------

local function get_top_button(player)
    if Gui.get_mod_gui_top_frame() then
        return Gui.get_button_flow(player)[main_button_name]
    end
    return player.gui.top[main_button_name]
end

local function top_button(player)
    local allowed = can_use(player)
    local button = get_top_button(player)
    if button and button.valid then
        button.visible = allowed
        return
    end
    if not allowed then
        return
    end
    local definition = {
        type = 'sprite-button',
        name = main_button_name,
        sprite = 'entity/medium-spitter',
        tooltip = { L .. 'top_button_tooltip' },
        style = Gui.button_style
    }
    if Gui.get_mod_gui_top_frame() then
        button = Gui.add_mod_button(player, definition)
        if button then
            button.style.minimal_height = 36
            button.style.maximal_height = 36
            button.style.minimal_width = 40
            button.style.padding = -2
        end
    else
        button = player.gui.top.add(definition)
        button.style.minimal_height = 38
        button.style.maximal_height = 38
        button.style.minimal_width = 40
        button.style.padding = -2
    end
end

local function style_button(button, width)
    button.style.font = 'default-bold'
    button.style.font_color = { r = 0.99, g = 0.99, b = 0.99 }
    button.style.minimal_width = width
end

local function draw_main_frame(player)
    local frame, inside_frame = Gui.add_main_frame_with_toolbar(player, 'screen', main_frame_name, info_button_name, close_button_name, { L .. 'title' }, true)
    if not (frame and inside_frame) then
        return
    end
    frame.location = this.locations[player.index] or default_location
    frame.style.minimal_width = 330
    frame.style.maximal_width = 330
    frame.titlebar[info_button_name].tooltip = { L .. 'info_tooltip' }

    local data = {}

    local top = inside_frame.add({ type = 'table', column_count = 2 })
    data.force_select = top.add({ type = 'drop-down', name = force_select_name, tooltip = { L .. 'force_tooltip' } })
    data.force_select.style.width = 145
    data.group_select = top.add({ type = 'drop-down', name = group_select_name, tooltip = { L .. 'group_tooltip' } })
    data.group_select.style.width = 145

    local body = inside_frame.add({ type = 'flow', direction = 'vertical' })
    for _, section in pairs(sections) do
        body.add({ type = 'label', caption = { L .. 'section_' .. section.key } })
        local tbl = body.add({ type = 'table', column_count = 2 })
        for _, key in pairs(section.commands) do
            local button = tbl.add({ type = 'button', name = element_names[key], caption = { L .. key }, tooltip = { L .. key .. '_tooltip' } })
            style_button(button, 150)
        end
    end

    local line = body.add({ type = 'line' })
    line.style.top_margin = 8
    line.style.bottom_margin = 8

    local pad = body.add({ type = 'table', column_count = 3 })
    for _, key in pairs(direction_pad) do
        local caption, tooltip
        if key == 'center' then
            caption, tooltip = { L .. 'center' }, { L .. 'center_tooltip' }
        else
            caption, tooltip = { L .. 'dir_' .. key }, { L .. 'dir_tooltip' }
        end
        local button = pad.add({ type = 'button', name = element_names[key], caption = caption, tooltip = tooltip })
        style_button(button, 70)
    end

    local coords = body.add({ type = 'table', column_count = 2 })
    coords.add({ type = 'label', caption = { L .. 'coord_x' } })
    data.coord_x = coords.add({ type = 'textfield', numeric = true, allow_negative = true, allow_decimal = true })
    coords.add({ type = 'label', caption = { L .. 'coord_y' } })
    data.coord_y = coords.add({ type = 'textfield', numeric = true, allow_negative = true, allow_decimal = true })

    -- help replaces the body while shown, so the window does not grow
    local help = inside_frame.add({ type = 'flow', direction = 'vertical', visible = false })
    for i = 1, 6 do
        local label = help.add({ type = 'label', caption = { L .. 'help_' .. i } })
        label.style.single_line = false
        label.style.maximal_width = 300
    end

    data.body = body
    data.help = help
    Gui.set_data(frame, data)
    refresh_player(player)
end

local function toggle_main_frame(player)
    local frame = get_frame(player)
    if frame then
        Gui.destroy(frame)
        return
    end
    if not can_use(player) then
        player.print({ L .. 'msg_disabled' }, print_color)
        top_button(player)
        return
    end
    draw_main_frame(player)
end

---Updates button and open window after admin status, force or module settings changed
local function update_access(player)
    top_button(player)
    local frame = get_frame(player)
    if not frame then
        return
    end
    if can_use(player) then
        refresh_player(player)
    else
        Gui.destroy(frame)
    end
end

Gui.on_click(
    main_button_name,
    function (event)
        if SpamProtection.is_spamming(event.player, nil, 'Biter Commander Main Button') then
            return
        end
        toggle_main_frame(event.player)
    end
)

Gui.on_click(
    close_button_name,
    function (event)
        local frame = get_frame(event.player)
        if frame then
            Gui.destroy(frame)
        end
    end
)

Gui.on_click(
    info_button_name,
    function (event)
        local data = get_frame_data(event.player)
        if not data then
            return
        end
        data.body.visible = not data.body.visible
        data.help.visible = not data.body.visible
    end
)

for key, name in pairs(element_names) do
    Gui.on_click(
        name,
        function (event)
            on_command(event.player, key)
        end
    )
end

Gui.on_selection_state_changed(
    force_select_name,
    function (event)
        local player = event.player
        local data = get_frame_data(player)
        if not data then
            return
        end
        if player.admin then
            this.selected_force[player.index] = data.force_names[event.element.selected_index]
        end
        refresh_player(player)
    end
)

Gui.on_selection_state_changed(
    group_select_name,
    function (event)
        local player = event.player
        local data = get_frame_data(player)
        if not data then
            return
        end
        this.selected_group[player.index] = data.group_ids[event.element.selected_index] or nil
    end
)

----------------------------events-----------------------

local function on_gui_location_changed(event)
    local element = event.element
    if element and element.valid and element.name == main_frame_name then
        this.locations[event.player_index] = element.location
    end
end

local function on_player_joined_game(event)
    local player = game.get_player(event.player_index)
    if player then
        top_button(player)
    end
end

local function on_player_access_changed(event)
    local player = game.get_player(event.player_index)
    if player then
        update_access(player)
    end
end

local function on_unit_group_created(event)
    local group = event.group
    if group and group.valid then
        register_group(group)
        this.dirty = true
    end
end

-- refresh only when group disappears, unit counts get updated on clicks so the open dropdown is not reset all the time
local function on_unit_removed_from_group(event)
    local group = event.group
    if not (group and group.valid) or #group.members == 0 then
        this.dirty = true
    end
end

-- group events can come in bursts (whole attack waves), so open panels get refreshed at most twice per second
local function refresh_if_dirty()
    if not this.dirty then
        return
    end
    this.dirty = false
    prune_groups()
    refresh_all()
end

---Gets module setting or state
---@param key string|nil #returns whole table if nil
function Public.get(key)
    if key then
        return this[key]
    end
    return this
end

---Sets module setting (enabled, admin_mode, teleporting, buildings)
---@param key string
---@param value any
function Public.set(key, value)
    this[key] = value
    for _, player in pairs(game.connected_players) do
        update_access(player)
    end
    return this[key]
end

---Allows player to use the panel even when module is disabled
---@param player_name string
---@param value boolean|nil
function Public.whitelist(player_name, value)
    this.whitelist[player_name] = value or nil
    local player = game.get_player(player_name)
    if player and player.connected then
        update_access(player)
    end
end

Event.add(defines.events.on_unit_removed_from_group, on_unit_removed_from_group)
Event.add(defines.events.on_unit_group_created, on_unit_group_created)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_promoted, on_player_access_changed)
Event.add(defines.events.on_player_demoted, on_player_access_changed)
Event.add(defines.events.on_player_changed_force, on_player_access_changed)
Event.add(defines.events.on_gui_location_changed, on_gui_location_changed)
Event.on_nth_tick(30, refresh_if_dirty)

return Public
