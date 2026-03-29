local Color = require 'utils.color_presets'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local Role = require 'utils.role.main'
local Commands = require 'utils.commands'

local this =
{
    forces = {},
    valid_chest =
    {
        ['wooden-chest'] = { valid = true, limit = 4 }
    },
    valid_turrets =
    {
        ['artillery-turret'] = { valid = true, category = 'artillery-shell' }
    },
    valid_ammo = {},
    valid_fuel = {},
    autofill_on_placement_amount = 10,
    fill_amount_on_turrets = 2,
    force_only = true,
    disable_chests = false,
    turret_limits_per_role =
    {
        [1] = 9999999,
        [2] = 10000,
        [3] = 500,
        [4] = 350,
        [5] = 250,
        [6] = 150,
        [7] = 50
    }
}

Global.register(
    this,
    function (t)
        this = t
    end
)

local Public = {}
local insert = table.insert
local unpack = table.unpack
local round = math.round
local container_frame_autofill = Gui.uid_name()
local player_toggled_autofill_on_container_gui_click = Gui.uid_name()
local autofill_main_label = '[color=yellow][Autofill][/color]: '

local function validate_entity(entity)
    if not entity then
        return false
    end
    if not entity.valid then
        return false
    end
    return true
end

local function get_role_turret_limit(player)
    local role = Role.get_role(player)
    if this.turret_limits_per_role[role.power] then
        return this.turret_limits_per_role[role.power]
    end
end

local function fast_remove(tbl, index)
    local count = #tbl
    if index > count then
        return
    elseif index < count then
        tbl[index] = tbl[count]
    end

    tbl[count] = nil
end

local function contains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

local function contains_chest(tbl, entity, rtn, remove)
    if not tbl then
        return
    end
    for index, data in pairs(tbl) do
        if type(data) ~= 'number' then
            if validate_entity(entity) and validate_entity(data.chest) then
                if data.unit_number == entity.unit_number then
                    if remove then
                        return fast_remove(tbl, index)
                    end

                    if rtn then
                        return entity
                    else
                        return true, index
                    end
                end
            end
        end
    end
    return false
end

local function contains_turret(tbl, entity, rtn, remove)
    if not tbl then
        return
    end
    for index, data in pairs(tbl) do
        if type(data) ~= 'number' then
            if validate_entity(entity) and validate_entity(data.turret) then
                if data.unit_number == entity.unit_number then
                    if remove then
                        return fast_remove(tbl, index)
                    end

                    if rtn then
                        return entity, data
                    else
                        return true, index
                    end
                end
            end
        end
    end
    return false
end

local function get_highest(chest, tbl, turret_name, turret_ammo)
    local highest = -math.huge
    local item
    local count

    for _, data in next, tbl do
        if not data then
            goto final
        end

        if not this.valid_ammo[data.name] then
            chest.remove { name = data.name, count = 999999, quality = 'normal' }
            goto final
        end

        local is_valid_ammo = this.valid_ammo[data.name]
        local is_valid_target = this.valid_turrets[turret_name]

        local is_from_chest = is_valid_ammo and is_valid_ammo.category == is_valid_target.category

        if is_from_chest then
            local ammo_or_fuel = turret_ammo and this.valid_ammo[turret_ammo] and this.valid_ammo[turret_ammo].priority
            if ammo_or_fuel and is_valid_ammo.priority > ammo_or_fuel then
                item = data.name
                count = data.count
            elseif ammo_or_fuel and is_valid_ammo.category == is_valid_target.category and is_valid_ammo.priority > highest then
                item = data.name
                count = data.count
            elseif is_valid_ammo.category == is_valid_target.category and is_valid_ammo.priority > highest then
                item = data.name
                count = data.count
            end
        end
    end

    ::final::

    if not item or not count then
        return false, false
    end

    return item, count
end

local function get_valid_chest(force)
    local chests = {}
    local forces = this.forces

    if not next(forces) then
        return
    end

    for _, tbl in pairs(forces) do
        local refill_chests = tbl.refill_chests
        for index = 1, #refill_chests do
            local data = refill_chests[index]
            if force and force == data.force.name then
                if data then
                    chests[#chests + 1] = data
                end
                if not data.chest.valid then
                    fast_remove(refill_chests, index)
                    tbl.refill_chests_placed = tbl.refill_chests_placed - 1
                    if tbl.refill_chests_placed <= 0 then
                        tbl.refill_chests_placed = 0
                    end
                    return false
                end
            else
                if data then
                    chests[#chests + 1] = data
                end
                if not data.chest.valid then
                    fast_remove(refill_chests, index)
                    tbl.refill_chests_placed = tbl.refill_chests_placed - 1
                    if tbl.refill_chests_placed <= 0 then
                        tbl.refill_chests_placed = 0
                    end
                    return false
                end
            end
        end
    end

    return chests
end

local function get_ammo(turret)
    local contents = turret.get_contents()

    local item, count
    local i = 0

    for _, dbc in pairs(contents) do
        i = i + 1
        item = dbc.name
        count = dbc.count
    end

    if i >= 11 then
        return item, i
    else
        return item, count
    end
end

local function get_items(chest, turret_name, turret_ammo)
    local contents = chest.get_contents()
    local item, count = get_highest(chest, contents, turret_name, turret_ammo)


    if this.valid_ammo[item] and this.valid_ammo[item].valid and count >= 1 then
        return item, count
    end

    return false, false
end

local function remove_ammo(chest, turret)
    if not chest or not chest.valid then
        return
    end

    local contents = turret.get_contents()

    for _, data in pairs(contents) do
        if data.count >= 1 then
            if chest.can_insert(data) then
                turret.remove(data)
                chest.insert(data)
                return data.name
            end
        end
    end
end

local function check_count(chest_item_name, chest_item_count)
    if this.valid_ammo[chest_item_name] and this.valid_ammo[chest_item_name].valid and chest_item_count >= 1 then
        return true
    else
        return false
    end
end

local function check_tier(turret_ammo_name, chest_item_name)
    if this.valid_ammo[chest_item_name] and this.valid_ammo[turret_ammo_name] then
        if turret_ammo_name and this.valid_ammo[chest_item_name] and this.valid_ammo[turret_ammo_name] and round(this.valid_ammo[chest_item_name].priority) > round(this.valid_ammo[turret_ammo_name].priority) then
            return true
        else
            return false
        end
    elseif this.valid_fuel[chest_item_name] and this.valid_fuel[turret_ammo_name] then
        if turret_ammo_name and this.valid_fuel[chest_item_name] and this.valid_fuel[turret_ammo_name] and round(this.valid_fuel[chest_item_name].priority) > round(this.valid_fuel[turret_ammo_name].priority) then
            return true
        else
            return false
        end
    end
end

local function refill(turret, chest, data)
    local turret_ammo_name, turret_ammo_count = get_ammo(turret)
    local chest_item_name, chest_item_count = get_items(chest, data.name, turret_ammo_name)
    if turret_ammo_count and turret_ammo_count >= this.autofill_on_placement_amount then return end

    if turret_ammo_count and turret_ammo_count >= this.autofill_on_placement_amount then
        if turret_ammo_count >= 20 or check_tier(turret_ammo_name, chest_item_name) then
            remove_ammo(chest, turret)
        end
        goto final
    end

    if not (this.valid_ammo[chest_item_name]) then
        goto final
    end

    if check_count(chest_item_name, chest_item_count) then
        if check_tier(turret_ammo_name, chest_item_name) then
            remove_ammo(chest, turret)
            goto continue
        end

        local t = { name = chest_item_name, count = this.fill_amount_on_turrets, quality = 'normal' }
        local c = turret.insert(t)
        if (c > 0) then
            chest.remove({ name = chest_item_name, count = c, quality = 'normal' })
        end

        ::continue::
    end

    ::final::
end

local function do_refill_turrets()
    local chests = get_valid_chest()

    if not chests then
        goto continue
    end

    local forces = this.forces

    if not next(forces) then
        return
    end

    for _, tbl in pairs(forces) do
        local refill_turrets = tbl.refill_turrets
        if refill_turrets then
            for i = 1, #refill_turrets do
                local data = refill_turrets[i]
                if not data then
                    goto continue
                end

                if not data.turret or not data.turret.valid then
                    fast_remove(refill_turrets, i)
                else
                    for x = 1, #chests do
                        local chest_data = chests[x]
                        if chest_data.force == data.force then
                            refill(data.turret, chest_data.chest, data)
                        end
                    end
                end
            end
        end
    end

    ::continue::
end

local function display_text(player, msg, pos, color)
    if color == nil then
        player.create_local_flying_text({ text = msg, position = pos, target = pos })
    else
        player.create_local_flying_text({ text = msg, position = pos, target = pos, color = color })
    end
end

local function move_items(source, destination, stack)
    if (source.get_item_count(stack.name) == 0) then
        return -1
    end

    if (not destination.can_insert(stack)) then
        return -2
    end

    local itemsRemoved = source.remove(stack)
    stack.count = itemsRemoved
    return destination.insert(stack)
end

local function transfer_items(source, destination, stack, amount)
    local ret = 0
    for itemName, _ in pairs(stack) do
        ret = move_items(source, destination, { name = itemName, count = amount, quality = 'normal' })
        if (ret > 0) then
            return ret
        end
    end
    return ret
end

local function into_turret(player, turret)
    local inventory = player.get_main_inventory()
    if (inventory == nil) then
        return
    end

    local success = transfer_items(inventory, turret, this.valid_ammo, this.autofill_on_placement_amount)

    if (success >= 1) then
        display_text(player, autofill_main_label .. 'Inserted ' .. success .. '!', turret.position, Color.success
            .surface)
    elseif (success == -1) then
        display_text(player, autofill_main_label .. 'Out of ammo!', turret.position, Color.red)
    end
end

local function auto_insert_into_vehicle(player, vehicle)
    local inventory = player.get_main_inventory()
    if (inventory == nil) then
        return
    end

    if ((vehicle.type == 'car') or (vehicle.type == 'locomotive')) then
        local success = transfer_items(inventory, vehicle, this.valid_fuel, 50)
        if (success >= 1) then
            display_text(player, autofill_main_label .. 'Inserted ' .. success .. '!', vehicle.position, Color.success
                .surface)
        elseif (success == -1) then
            display_text(player, autofill_main_label .. 'Out of fuel!', vehicle.position, Color.red)
        end
    end
end

local function get_fuel_items()
    local filter = prototypes.get_item_filtered
    for name, fuel in pairs(filter({ { filter = 'fuel' } })) do
        this.valid_fuel[name] =
        {
            valid = true,
            priority = fuel.fuel_value
        }
    end
end

local function draw_container_frame(parent, entity, player)
    local frame = parent[container_frame_autofill]
    if frame and frame.valid then
        Gui.destroy(frame)
    end

    local anchor =
    {
        gui = defines.relative_gui_type.container_gui,
        position = defines.relative_gui_position.right
    }

    frame =
        parent.add
        {
            type = 'frame',
            name = container_frame_autofill,
            anchor = anchor,
            direction = 'vertical'
        }

    local force = Public.get_force(player)

    if not force then
        Public.create_force(player)
    end

    local limit = this.valid_chest[entity.name] and this.valid_chest[entity.name].limit
    local placeholder = ''

    local tooltip
    if force then
        local isMember, id = contains_chest(force.refill_chests, entity)
        if isMember then
            placeholder = 'Chest ID: ' .. id
        end
        local hasTurrets = ''
        if force.refill_turrets and #force.refill_turrets > 0 then
            hasTurrets = 'Turret amount: ' .. #force.refill_turrets .. '/' .. get_role_turret_limit(player)
        else
            force.refill_turrets = {}
        end
        tooltip =
            '[color=blue][AutoFill][/color]\nYou can easily toggle this chest autofill status.\nAmmo in this chest will inserted automatically onto turrets that are owned by your force.\nYou currently have: ' ..
            force.refill_chests_placed ..
            '/' .. limit .. ' autofill ' .. entity.name .. '.\n' .. placeholder .. '\n' .. hasTurrets
    else
        tooltip =
        '[color=blue][AutoFill][/color]\nYou can easily toggle this chest autofill status.\nAmmo in this chest will inserted automatically onto turrets that are owned by your force.\n'
    end

    local data = {}

    local button =
        frame.add
        {
            type = 'sprite-button',
            sprite = 'item/firearm-magazine',
            name = player_toggled_autofill_on_container_gui_click,
            tooltip = tooltip,
            style = Gui.button_style
        }

    data.entity = entity
    data.button = button
    data.frame = frame

    Gui.set_data(button, data)
end

local function player_toggled_autofill_on_container(event)
    local player = event.player
    local button = event.button
    local data = Gui.get_data(event.element)
    local entity = data.entity
    local btn = data.button

    if button == defines.mouse_button_type.left then
        if not (entity and entity.valid) then
            return
        end

        if entity.force.name ~= player.force.name then
            return player.print('[Autofill] This chest is not owned by your force.', Color.warning)
        end

        local force = Public.get_force(player, true)

        if (this.valid_chest[entity.name] and this.valid_chest[entity.name].valid) then
            local isMember = contains_chest(force.refill_chests, entity)
            local limit = this.valid_chest[entity.name] and this.valid_chest[entity.name].limit
            if not isMember then
                if (force.refill_chests_placed < limit) then
                    Public.add_chest_to_force(player, entity)
                    entity.minable = false
                    local _, id = contains_chest(force.refill_chests, entity)
                    local placeholder = 'Chest ID: ' .. id
                    player.print('[Autofill] Chest added to autofill!', Color.success)
                    local tooltip =
                        '[color=blue][AutoFill][/color]\nYou can easily toggle this chest autofill status.\n\nAmmo in this chest will inserted automatically onto turrets that are owned by your force.\nYou currently have: ' ..
                        force.refill_chests_placed .. '/' .. limit .. ' autofill ' .. entity.name .. '.\n' .. placeholder
                    btn.tooltip = tooltip
                else
                    player.print('[Autofill] Chest limit reached.', Color.warning)
                end
            else
                player.print('[Autofill] Chest removed from autofill!', Color.warning)
                entity.minable = true
                Public.remove_chest_from_force(player, entity)
                local tooltip =
                    '[color=blue][AutoFill][/color]\nYou can easily toggle this chest autofill status.\n\nAmmo in this chest will inserted automatically onto turrets that are owned by your force.\nYou currently have: ' ..
                    force.refill_chests_placed .. '/' .. limit .. ' autofill ' .. entity.name .. '.'
                btn.tooltip = tooltip
            end
        end
    else
        return
    end
end

local function get_valid_turrets()
    local filter = prototypes.entity
    for name, prototype in pairs(filter) do
        if prototype.attack_parameters and prototype.attack_parameters.ammo_categories then
            if prototype.attack_parameters.ammo_categories[1] then
                this.valid_turrets[name] =
                {
                    valid = true,
                    category = prototype.attack_parameters.ammo_categories[1]
                }
            end
        end
    end
end

local function get_damage_from_entity(entity_name, validator)
    if contains(validator, entity_name) then
        return 0
    end
    insert(validator, entity_name)

    local list = prototypes.entity
    local dmg = 0
    local ent = list[entity_name]
    if ent then
        if ent.attack_result then
            dmg = dmg + Public.actions(ent.attack_result, { unpack(validator) })
        end
        if ent.final_attack_result then
            dmg = dmg + Public.actions(ent.final_attack_result, { unpack(validator) })
        end
    end
    return dmg
end

local function get_damage(ad, validator)
    local dmg = 0
    if ad.type == 'instant' then
        if ad.target_effects then
            for _, te in pairs(ad.target_effects) do
                if te.action then
                    dmg = dmg + Public.actions(te.action, validator)
                end
                if te.type == 'damage' then
                    dmg = dmg + te.damage.amount
                end
                if te.type == 'create-entity' and te.entity_name then
                    dmg = dmg + get_damage_from_entity(te.entity_name, validator)
                end
            end
        end
    elseif ad.projectile then
        dmg = dmg + get_damage_from_entity(ad.projectile, validator)
    elseif ad.stream then
        dmg = dmg + get_damage_from_entity(ad.stream, validator)
    end
    return dmg
end

local function result(action, validator)
    local dmg = 0
    local function calc_radius()
        local r
        r = action.radius * action.radius * math.pi
        return r
    end
    if action.action_delivery then
        for _, ad in pairs(action.action_delivery) do
            local radius = 1
            if action.radius then
                radius = calc_radius()
            end
            dmg = dmg + get_damage(ad, validator) * radius
        end
    end
    return dmg
end

function Public.actions(action_tbl, validator)
    local priority = 0
    for _, act in pairs(action_tbl) do
        priority = priority + result(act, validator) * act.repeat_count
    end
    return priority
end

Public.get_priorities = function ()
    for _, prototype in pairs(prototypes.item) do
        local ammo_type = prototype.get_ammo_type()
        if ammo_type and ammo_type.action then
            local priority = Public.actions(ammo_type.action, {})
            this.valid_ammo[prototype.name] =
            {
                valid = true,
                priority = round(priority),
                category = prototype.ammo_category.name
            }
        end
    end
end

Public.create_force = function (player)
    if not this.forces[player.force.name] then
        this.forces[player.force.name] =
        {
            refill_turrets = {},
            refill_chests = {},
            refill_chests_placed = 0,
            render_targets = {}
        }
        return this.forces[player.force.name]
    else
        return this.forces[player.force.name]
    end
end

Public.get_force = function (player, create)
    if create then
        if not this.forces[player.force.name] then
            return Public.create_force(player)
        else
            return this.forces[player.force.name]
        end
    end
    if this.forces[player.force.name] then
        return this.forces[player.force.name]
    end
    return false
end

Public.remove_force = function (player)
    if this.forces[player.force.name] then
        this.forces[player.force.name] = nil
    end
end

Public.is_force_tbl_empty = function (player)
    local s = 0
    if this.forces[player.force.name] then
        if #this.forces[player.force.name].refill_chests <= 0 then
            s = s + 1
        end
        if #this.forces[player.force.name].refill_turrets <= 0 then
            s = s + 1
        end
        if s == 2 then
            Public.remove_force(player)
        end
    end
end

Public.add_chest_to_force = function (player, entity)
    if entity and entity.valid then
        local force = Public.get_force(player)
        if not force then
            return
        end
        local refill_chests = force.refill_chests
        local render_targets = force.render_targets
        local chest = entity.get_inventory(defines.inventory.chest)
        refill_chests[#refill_chests + 1] = { chest = chest, force = entity.force.name, unit_number = entity.unit_number }
        force.refill_chests_placed = force.refill_chests_placed + 1

        render_targets[entity.unit_number] =
            rendering.draw_text
            {
                text = '⚙',
                surface = entity.surface,
                target = { entity = entity, offset = { 0, -0.6 } },
                scale = 2.2,
                color = { r = 0, g = 0.6, b = 1 },
                alignment = 'center'
            }
    end
end

Public.remove_chest_from_force = function (player, entity)
    local force = Public.get_force(player)
    if not force then
        return
    end
    local refill_chests = force.refill_chests
    local render_targets = force.render_targets

    contains_chest(refill_chests, entity, false, true)

    if render_targets[entity.unit_number] then
        render_targets[entity.unit_number].destroy()
        render_targets[entity.unit_number] = nil
    end

    force.refill_chests_placed = force.refill_chests_placed - 1

    Public.is_force_tbl_empty(player)
end

Public.add_turret_to_force = function (player, entity)
    if entity and entity.valid then
        local force = Public.get_force(player)
        if not force then
            return
        end
        local refill_turrets = force.refill_turrets
        if refill_turrets and #refill_turrets > get_role_turret_limit(player) then
            return
        end

        local turret_inv = entity.get_inventory(defines.inventory.turret_ammo)

        refill_turrets[#refill_turrets + 1] =
        {
            turret = turret_inv,
            force = entity.force.name,
            unit_number = entity.unit_number,
            name = entity.name
        }
    end
end

Public.remove_turret_from_force = function (player, entity)
    local force = Public.get_force(player)
    if not force then
        return
    end
    local refill_turrets = force.refill_turrets

    contains_turret(refill_turrets, entity, false, true)

    Public.is_force_tbl_empty(player)
end

Public.set_disable_chests = function (state)
    this.disable_chests = state or false
end

local get_priorities = Public.get_priorities

Gui.on_click(
    player_toggled_autofill_on_container_gui_click,
    function (event)
        player_toggled_autofill_on_container(event)
    end
)

Event.on_configuration_changed(
    function ()
        log('[Autofill] - Called Configuration Changed.')
        this.valid_ammo = {}
        this.valid_fuel = {}
        this.valid_turrets = {}
        get_priorities()
        get_fuel_items()
        get_valid_turrets()
    end
)

Event.add(
    defines.events.script_raised_built,
    function (event)
        local entity = event.entity
        if not entity or not entity.valid then
            return
        end
        if this.disable_chests then
            return
        end

        if this.valid_turrets[entity.name] then
            Public.add_turret_to_force(entity, entity)
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

        if this.disable_chests then
            return
        end

        local panel = player.gui.relative
        local entity = event.entity
        if entity and entity.valid and entity.type == 'container' and entity.force.name == player.force.name then
            if not this.valid_chest[entity.name] then
                return
            end

            draw_container_frame(panel, entity, player)
        end
    end
)

Event.add(
    defines.events.on_gui_closed,
    function (event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        if this.disable_chests then
            return
        end

        local relative = player.gui.relative
        local panel = relative[container_frame_autofill]
        if panel and panel.valid then
            Gui.destroy(panel)
        end
    end
)

Event.add(
    defines.events.on_built_entity,
    function (event)
        local player = game.players[event.player_index]
        if not (player and player.valid) then
            return
        end

        local ce = event.entity
        if not (ce and ce.valid) then
            return
        end

        if ((ce.type == 'car') or (ce.type == 'locomotive')) then
            auto_insert_into_vehicle(player, ce)
            return
        end

        if (this.valid_turrets[ce.name]) then
            if not this.disable_chests then
                Public.add_turret_to_force(player, ce)
            end
            into_turret(player, ce)
        end
    end
)

Event.add(
    defines.events.on_robot_built_entity,
    function (event)
        local ce = event.entity
        if not (ce and ce.valid) then
            return
        end

        if not (this.valid_turrets[ce.name]) then
            return
        end

        local robot = event.robot
        if not robot or not robot.valid then
            return
        end
        local net_point = robot.logistic_network
        if net_point and net_point.storage_points and net_point.storage_points[1] and net_point.storage_points[1].owner and net_point.storage_points[1].owner.valid then
            local owner = net_point.storage_points[1].owner.player
            if (this.valid_turrets[ce.name]) then
                if not this.disable_chests then
                    Public.add_turret_to_force(owner, ce)
                end
            end
        end
    end
)

Event.add(
    defines.events.on_pre_player_mined_item,
    function (event)
        local player = game.get_player(event.player_index)

        if this.disable_chests then
            return
        end

        if not validate_entity(player) then
            return
        end

        local entity = event.entity
        if not validate_entity(entity) then
            return
        end

        local chests = get_valid_chest(player.force.name)
        if not chests then
            return
        end

        local force = Public.get_force(player)

        if not force then
            return
        end

        if not this.valid_turrets[entity.name] then
            return
        end

        local refill_turrets = force.refill_turrets

        local ent, data = contains_turret(refill_turrets, entity, true)

        if data then
            for index = 1, #chests do
                local chest_data = chests[index]
                if chest_data.force == data.force then
                    remove_ammo(chest_data.chest, data.turret)
                end
            end

            Public.remove_turret_from_force(player, ent)
        end
    end
)

Event.on_nth_tick(
    30,
    function ()
        if this.disable_chests then
            return
        end
        do_refill_turrets()
    end
)

Event.on_init(
    function ()
        get_priorities()
        get_fuel_items()
        get_valid_turrets()
    end
)

Commands.new('autofill-toggle-chests', 'Toggles autofill chests')
    :require_role('autofill_chests')
    :callback(function (player)
        if this.disable_chests then
            Public.set_disable_chests(false)
            player.print('[Autofill] Chests are now enabled.', Color.yellow)
        else
            Public.set_disable_chests(true)
            player.print('[Autofill] Chests are now disabled.', Color.yellow)
        end
    end
    )

Commands.new('autofill-refresh', 'Refresh the autofill system')
    :require_role('autofill_chests')
    :callback(function (player)
        this.valid_ammo = {}
        this.valid_fuel = {}
        this.valid_turrets = {}
        get_priorities()
        get_fuel_items()
        get_valid_turrets()
        player.print('[Autofill] System refreshed.', Color.yellow)
    end
    )

return Public
