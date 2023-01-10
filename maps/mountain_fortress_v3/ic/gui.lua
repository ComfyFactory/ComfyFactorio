local ICT = require 'maps.mountain_fortress_v3.ic.table'
local Functions = require 'maps.mountain_fortress_v3.ic.functions'
local Color = require 'utils.color_presets'
local Gui = require 'utils.gui'
local Tabs = require 'utils.gui'
local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'
local SpamProtection = require 'utils.spam_protection'

local Public = {}
local insert = table.insert

--! Gui Frames
local save_add_player_button_name = Gui.uid_name()
local save_transfer_car_button_name = Gui.uid_name()
local save_destroy_surface_button_name = Gui.uid_name()
local discard_add_player_name = Gui.uid_name()
local discard_transfer_car_name = Gui.uid_name()
local discard_destroy_surface_name = Gui.uid_name()
local transfer_player_select_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local draw_add_player_frame_name = Gui.uid_name()
local draw_transfer_car_frame_name = Gui.uid_name()
local draw_destroy_surface_frame_name = Gui.uid_name()
local main_toolbar_name = Gui.uid_name()
local add_player_name = Gui.uid_name()
local transfer_car_name = Gui.uid_name()
local allow_anyone_to_enter_name = Gui.uid_name()
local auto_upgrade_name = Gui.uid_name()
local kick_player_name = Gui.uid_name()
local destroy_surface_name = Gui.uid_name()

local add_toolbar
local remove_toolbar

local function increment(t, k)
    t[k] = true
end

local function decrement(t, k)
    t[k] = nil
end

local function create_player_table(player)
    local trust_system = ICT.get('trust_system')
    if not trust_system[player.index] then
        trust_system[player.index] = {
            players = {
                [player.name] = true
            },
            allow_anyone = 'right',
            auto_upgrade = 'left'
        }
    end
    return trust_system[player.index]
end

local function does_player_table_exist(player)
    local trust_system = ICT.get('trust_system')
    if not trust_system[player.index] then
        return false
    else
        return true
    end
end

local function get_players(player, frame, all)
    local tbl = {}
    local players = game.connected_players
    local trust_system = create_player_table(player)

    for _, p in pairs(players) do
        if next(trust_system.players) and not all then
            if not trust_system.players[p.name] then
                insert(tbl, tostring(p.name))
            end
        else
            insert(tbl, tostring(p.name))
        end
    end
    insert(tbl, ({'ic.select_player'}))

    local selected_index = #tbl

    local f = frame.add({type = 'drop-down', name = transfer_player_select_name, items = tbl, selected_index = selected_index})
    return f
end

local function transfer_player_table(player, new_player)
    local trust_system = ICT.get('trust_system')
    if not trust_system[player.index] then
        return false
    end

    if player.index == new_player.index then
        return false
    end

    if not trust_system[new_player.index] then
        trust_system[new_player.index] = trust_system[player.index]
        local name = new_player.name

        if not trust_system[new_player.index].players[name] then
            increment(trust_system[new_player.index].players, name)
        end

        local cars = ICT.get('cars')
        local renders = ICT.get('renders')
        local c = Functions.get_owner_car_object(cars, player)
        local car = cars[c]
        car.owner = new_player.index

        Functions.render_owner_text(renders, player, car.entity, new_player)

        remove_toolbar(player)
        add_toolbar(new_player)

        trust_system[player.index] = nil
    else
        return false
    end

    return trust_system[new_player.index]
end

local function remove_main_frame(main_frame)
    if not main_frame or not main_frame.valid then
        return
    end

    Gui.remove_data_recursively(main_frame)
    main_frame.destroy()
end

local function draw_add_player(player, frame)
    local main_frame =
        frame.add(
        {
            type = 'frame',
            name = draw_add_player_frame_name,
            caption = ({'ic.add_player'}),
            direction = 'vertical'
        }
    )
    local main_frame_style = main_frame.style
    main_frame_style.width = 370
    main_frame_style.use_header_filler = true

    local inside_frame = main_frame.add {type = 'frame', style = 'inside_shallow_frame'}
    local inside_frame_style = inside_frame.style
    inside_frame_style.padding = 0
    local inside_table = inside_frame.add {type = 'table', column_count = 1}
    local inside_table_style = inside_table.style
    inside_table_style.vertical_spacing = 5
    inside_table_style.top_padding = 10
    inside_table_style.left_padding = 10
    inside_table_style.right_padding = 0
    inside_table_style.bottom_padding = 10
    inside_table_style.width = 325

    local add_player_frame = get_players(player, main_frame)

    local bottom_flow = main_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add({type = 'button', name = discard_add_player_name, caption = ({'ic.discard'})})
    close_button.style = 'back_button'
    close_button.style.maximal_width = 100

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button = right_flow.add({type = 'button', name = save_add_player_button_name, caption = ({'ic.save'})})
    save_button.style = 'confirm_button'
    save_button.style.maximal_width = 100

    Gui.set_data(save_button, add_player_frame)
end

local function draw_transfer_car(player, frame)
    local main_frame =
        frame.add(
        {
            type = 'frame',
            name = draw_transfer_car_frame_name,
            caption = ({'ic.transfer_car'}),
            direction = 'vertical'
        }
    )
    local main_frame_style = main_frame.style
    main_frame_style.width = 370
    main_frame_style.use_header_filler = true

    local inside_frame = main_frame.add {type = 'frame', style = 'inside_shallow_frame'}
    local inside_frame_style = inside_frame.style
    inside_frame_style.padding = 0
    local inside_table = inside_frame.add {type = 'table', column_count = 1}
    local inside_table_style = inside_table.style
    inside_table_style.vertical_spacing = 5
    inside_table_style.top_padding = 10
    inside_table_style.left_padding = 10
    inside_table_style.right_padding = 0
    inside_table_style.bottom_padding = 10
    inside_table_style.width = 325

    local transfer_car_alert_frame = main_frame.add({type = 'label', caption = ({'ic.warning'})})
    transfer_car_alert_frame.style.font_color = {r = 255, g = 0, b = 0}
    transfer_car_alert_frame.style.font = 'heading-1'
    local transfer_car_frame = get_players(player, main_frame, true)

    local bottom_flow = main_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add({type = 'button', name = discard_transfer_car_name, caption = ({'ic.discard'})})
    close_button.style = 'back_button'
    close_button.style.maximal_width = 100

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button = right_flow.add({type = 'button', name = save_transfer_car_button_name, caption = ({'ic.save'})})
    save_button.style = 'confirm_button'
    save_button.style.maximal_width = 100

    Gui.set_data(save_button, transfer_car_frame)
end

local function draw_destroy_surface_name(frame)
    local main_frame =
        frame.add(
        {
            type = 'frame',
            name = draw_destroy_surface_frame_name,
            caption = ({'ic.destroy_surface'}),
            direction = 'vertical'
        }
    )
    local main_frame_style = main_frame.style
    main_frame_style.width = 370
    main_frame_style.use_header_filler = true

    local inside_frame = main_frame.add {type = 'frame', style = 'inside_shallow_frame'}
    local inside_frame_style = inside_frame.style
    inside_frame_style.padding = 0
    local inside_table = inside_frame.add {type = 'table', column_count = 1}
    local inside_table_style = inside_table.style
    inside_table_style.vertical_spacing = 5
    inside_table_style.top_padding = 10
    inside_table_style.left_padding = 10
    inside_table_style.right_padding = 0
    inside_table_style.bottom_padding = 10
    inside_table_style.width = 325

    local destroy_car_frame = main_frame.add({type = 'label', caption = ({'ic.warning'})})
    destroy_car_frame.style.font_color = {r = 255, g = 0, b = 0}
    destroy_car_frame.style.font = 'heading-1'

    local warn_again_frame = main_frame.add({type = 'label', caption = ({'ic.warning_2'})})
    warn_again_frame.style.font_color = {r = 255, g = 0, b = 0}
    warn_again_frame.style.font = 'heading-1'

    local bottom_flow = main_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add({type = 'button', name = discard_destroy_surface_name, caption = ({'ic.discard'})})
    close_button.style = 'back_button'
    close_button.style.maximal_width = 100

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button = right_flow.add({type = 'button', name = save_destroy_surface_button_name, caption = ({'ic.save'})})
    save_button.style = 'confirm_button'
    save_button.style.maximal_width = 100

    Gui.set_data(save_button, save_destroy_surface_button_name)
end

local function draw_players(data)
    local player_table = data.player_table
    local add_player_frame = data.add_player_frame
    local player = data.player
    local player_list = create_player_table(player)

    for p, _ in pairs(player_list.players) do
        Gui.set_data(add_player_frame, p)
        local t_label =
            player_table.add(
            {
                type = 'label',
                caption = p
            }
        )
        t_label.style.minimal_width = 75
        t_label.style.horizontal_align = 'center'

        local a_label =
            player_table.add(
            {
                type = 'label',
                caption = '✔️'
            }
        )
        a_label.style.minimal_width = 75
        a_label.style.horizontal_align = 'center'
        a_label.style.font = 'default-large-bold'

        local kick_flow = player_table.add {type = 'flow'}
        local kick_player_button =
            kick_flow.add(
            {
                type = 'button',
                caption = ({'ic.kick', p}),
                name = kick_player_name
            }
        )
        if player.name == t_label.caption then
            kick_player_button.enabled = false
        end
        kick_player_button.style.minimal_width = 75
        Gui.set_data(kick_player_button, p)
    end
end

local function draw_main_frame(player)
    local main_frame =
        player.gui.screen.add(
        {
            type = 'frame',
            name = main_frame_name,
            caption = ({'ic.car_settings'}),
            direction = 'vertical',
            style = 'inner_frame_in_outer_frame'
        }
    )

    main_frame.auto_center = true
    local main_frame_style = main_frame.style
    main_frame_style.width = 400
    main_frame_style.use_header_filler = true

    local inside_frame = main_frame.add {type = 'frame', style = 'inside_shallow_frame'}
    local inside_frame_style = inside_frame.style
    inside_frame_style.padding = 0

    local inside_table = inside_frame.add {type = 'table', column_count = 1}
    local inside_table_style = inside_table.style
    inside_table_style.vertical_spacing = 5
    inside_table_style.top_padding = 10
    inside_table_style.left_padding = 10
    inside_table_style.right_padding = 0
    inside_table_style.bottom_padding = 10
    inside_table_style.width = 350

    local player_list = create_player_table(player)

    local add_player_frame = inside_table.add({type = 'button', caption = ({'ic.add_player'}), name = add_player_name})
    local transfer_car_frame = inside_table.add({type = 'button', caption = ({'ic.car_settings'}), name = transfer_car_name})
    local destroy_surface_frame = inside_table.add({type = 'button', caption = ({'ic.destroy_surface'}), name = destroy_surface_name})
    local allow_anyone_to_enter =
        inside_table.add(
        {
            type = 'switch',
            name = allow_anyone_to_enter_name,
            switch_state = player_list.allow_anyone,
            allow_none_state = false,
            left_label_caption = ({'ic.allow_anyone'}),
            right_label_caption = ({'ic.off'})
        }
    )
    local auto_upgrade =
        inside_table.add(
        {
            type = 'switch',
            name = auto_upgrade_name,
            switch_state = player_list.auto_upgrade,
            allow_none_state = false,
            left_label_caption = ({'ic.auto_upgrade'}),
            right_label_caption = ({'ic.off'})
        }
    )

    local player_table =
        inside_table.add {
        type = 'table',
        column_count = 3,
        draw_horizontal_lines = true,
        draw_vertical_lines = true,
        vertical_centering = true
    }
    local player_table_style = player_table.style
    player_table_style.vertical_spacing = 10
    player_table_style.width = 350
    player_table_style.horizontal_spacing = 30

    local name_label =
        player_table.add(
        {
            type = 'label',
            caption = ({'ic.name'}),
            tooltip = ''
        }
    )
    name_label.style.minimal_width = 75
    name_label.style.horizontal_align = 'center'

    local trusted_label =
        player_table.add(
        {
            type = 'label',
            caption = ({'ic.allowed'}),
            tooltip = ''
        }
    )
    trusted_label.style.minimal_width = 75
    trusted_label.style.horizontal_align = 'center'

    local operations_label =
        player_table.add(
        {
            type = 'label',
            caption = ({'ic.operations'}),
            tooltip = ''
        }
    )
    operations_label.style.minimal_width = 75
    operations_label.style.horizontal_align = 'center'

    local data = {
        player_table = player_table,
        add_player_frame = add_player_frame,
        transfer_car_frame = transfer_car_frame,
        destroy_surface_frame = destroy_surface_frame,
        allow_anyone_to_enter = allow_anyone_to_enter,
        auto_upgrade = auto_upgrade,
        player = player
    }
    draw_players(data)

    player.opened = main_frame
end

local function toggle(player, recreate)
    local screen = player.gui.screen
    local main_frame = screen[main_frame_name]

    if recreate and main_frame then
        local location = main_frame.location
        remove_main_frame(main_frame)
        draw_main_frame(player, location)
        return
    end
    if main_frame then
        remove_main_frame(main_frame)
    else
        Tabs.clear_all_active_frames(player)
        draw_main_frame(player)
    end
end

add_toolbar = function(player, remove)
    if remove then
        if player.gui.top[main_toolbar_name] then
            player.gui.top[main_toolbar_name].destroy()
            return
        end
    end
    if player.gui.top[main_toolbar_name] then
        return
    end

    local tooltip = ({'ic.control'})
    player.gui.top.add(
        {
            type = 'sprite-button',
            sprite = 'item/spidertron',
            name = main_toolbar_name,
            tooltip = tooltip
        }
    )
end

remove_toolbar = function(player)
    local screen = player.gui.screen
    local main_frame = screen[main_frame_name]

    if main_frame and main_frame.valid then
        remove_main_frame(main_frame)
    end

    if player.gui.top[main_toolbar_name] then
        player.gui.top[main_toolbar_name].destroy()
        return
    end
end

local function trigger_on_used_car_door(data)
    local state = data.state
    local player = data.player

    if state == 'add' then
        add_toolbar(player)
    elseif state == 'remove' then
        remove_toolbar(player)
    end
end

Gui.on_click(
    add_player_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Ic Gui Add Player')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end
        local player_frame = frame[draw_add_player_frame_name]
        if not player_frame or not player_frame.valid then
            draw_add_player(player, frame)
        else
            player_frame.destroy()
        end
    end
)

Gui.on_click(
    transfer_car_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Ic Gui Transfer Car')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end
        local player_frame = frame[draw_transfer_car_frame_name]
        if not player_frame or not player_frame.valid then
            draw_transfer_car(player, frame)
        else
            player_frame.destroy()
        end
    end
)

Gui.on_click(
    destroy_surface_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Ic Gui Destroy Surface')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end
        local player_frame = frame[draw_destroy_surface_frame_name]
        if not player_frame or not player_frame.valid then
            draw_destroy_surface_name(frame)
        else
            player_frame.destroy()
        end
    end
)

Gui.on_click(
    allow_anyone_to_enter_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Ic Gui Allow Anyone To Enter')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local player_list = create_player_table(player)

        local screen = player.gui.screen
        local frame = screen[main_frame_name]

        if frame and frame.valid then
            if player_list.allow_anyone == 'right' then
                player_list.allow_anyone = 'left'
                player.print('[IC] Everyone is allowed to enter your car!', Color.warning)
            else
                player_list.allow_anyone = 'right'
                player.print('[IC] Everyone is disallowed to enter your car except your trusted list!', Color.warning)
            end

            if player.gui.screen[main_frame_name] then
                toggle(player, true)
            end
        end
    end
)

Gui.on_click(
    auto_upgrade_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Ic Gui Auto Upgrade')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local player_list = create_player_table(player)

        local screen = player.gui.screen
        local frame = screen[main_frame_name]

        if frame and frame.valid then
            if player_list.auto_upgrade == 'right' then
                player_list.auto_upgrade = 'left'
                player.print('[IC] Auto upgrade is now enabled!', Color.success)
            else
                player_list.auto_upgrade = 'right'
                player.print('[IC] Auto upgrade is now disabled!', Color.warning)
            end

            if player.gui.screen[main_frame_name] then
                toggle(player, true)
            end
        end
    end
)

Gui.on_click(
    save_add_player_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Ic Gui Save Add Player')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local player_list = create_player_table(player)

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        local add_player_frame = Gui.get_data(event.element)

        if frame and frame.valid then
            if add_player_frame and add_player_frame.valid and add_player_frame then
                local player_gui_data = ICT.get('player_gui_data')
                local fetched_name = player_gui_data[player.name]
                if not fetched_name then
                    return
                end

                local player_to_add = game.get_player(fetched_name)
                if not player_to_add or not player_to_add.valid then
                    return player.print('[IC] Target player was not valid.', Color.warning)
                end

                local name = player_to_add.name

                if not player_list.players[name] then
                    player.print('[IC] ' .. name .. ' was added to your vehicle.', Color.info)
                    player_to_add.print(player.name .. ' added you to their vehicle. You may now enter it.', Color.info)
                    increment(player_list.players, name)
                else
                    return player.print('[IC] Target player is already trusted.', Color.warning)
                end

                remove_main_frame(event.element)

                if player.gui.screen[main_frame_name] then
                    toggle(player, true)
                end
            end
        end
    end
)

Gui.on_click(
    save_transfer_car_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Ic Gui Save Transfer Car')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        local transfer_car_frame = Gui.get_data(event.element)

        if frame and frame.valid then
            if transfer_car_frame and transfer_car_frame.valid then
                local player_gui_data = ICT.get('player_gui_data')
                local fetched_name = player_gui_data[player.name]
                if not fetched_name then
                    return
                end
                if type(fetched_name) == 'table' and fetched_name[1] == 'ic.select_player' then
                    return player.print('[IC] Target player was not valid.', Color.warning)
                end

                local player_to_add = game.get_player(fetched_name)
                if not player_to_add or not player_to_add.valid then
                    return player.print('[IC] Target player was not valid.', Color.warning)
                end
                local name = player_to_add.name

                local does_player_have_a_car = does_player_table_exist(player_to_add)
                if does_player_have_a_car then
                    return player.print('[IC] ' .. name .. ' already has a vehicle.', Color.warning)
                end

                local success = transfer_player_table(player, player_to_add)
                if not success then
                    player.print('[IC] Please try again.', Color.warning)
                else
                    player.print('[IC] You have successfully transferred your car to ' .. name, Color.success)
                    player_to_add.print('[IC] You have become the rightfully owner of ' .. player.name .. "'s car!", Color.success)
                end

                remove_main_frame(event.element)

                if player.gui.screen[main_frame_name] then
                    player.gui.screen[main_frame_name].destroy()
                end
            end
        end
    end
)

local clear_misc_settings =
    Token.register(
    function(data)
        local player_index = data.player_index
        local misc_settings = ICT.get('misc_settings')
        if not misc_settings[player_index] then
            return
        end

        misc_settings[player_index] = nil
    end
)

Gui.on_click(
    save_destroy_surface_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Ic Gui Save Destroy Car')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]

        local element = event.element
        if not (element and element.valid) then
            return
        end

        local misc_settings = ICT.get('misc_settings')
        if not misc_settings[player.index] then
            misc_settings[player.index] = {
                first_warning = true
            }

            player.print('[IC] ARE YOU SURE? This action is irreversible!', Color.warning)
            Task.set_timeout_in_ticks(600, clear_misc_settings, {player_index = player.index})
            return
        end

        if not misc_settings[player.index].final_warning then
            misc_settings[player.index].final_warning = true
            player.print('[IC] WARNING! WARNING WARNING! Pressing the save button ONE MORE TIME will DELETE your surface. This action is irreversible!', Color.red)
            Task.set_timeout_in_ticks(600, clear_misc_settings, {player_index = player.index})
            return
        end

        if frame and frame.valid then
            local cars = ICT.get('cars')
            local c = Functions.get_owner_car_object(cars, player)
            local car = cars[c]
            if not car then
                return
            end

            local entity = car.entity
            if entity and entity.valid then
                Functions.kill_car_but_save_surface(entity)
                game.print('[IC] ' .. player.name .. ' has destroyed their surface!', Color.warning)
            end

            remove_main_frame(event.element)

            if player.gui.screen[main_frame_name] then
                player.gui.screen[main_frame_name].destroy()
            end
        end
    end
)

Gui.on_click(
    kick_player_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Ic Gui Kick Player')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local player_list = create_player_table(player)

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        local player_name = Gui.get_data(event.element)

        if frame and frame.valid then
            if not player_name then
                return
            end
            local target = game.get_player(player_name)
            if not target or not target.valid then
                player.print('[IC] Target player was not valid.', Color.warning)
                return
            end
            local name = target.name

            if player_list.players[name] then
                player.print('[IC] ' .. name .. ' was removed from your vehicle.', Color.info)
                decrement(player_list.players, name)
                Event.raise(
                    ICT.events.on_player_kicked_from_surface,
                    {
                        player = player,
                        target = target
                    }
                )
            end

            remove_main_frame(event.element)

            if player.gui.screen[main_frame_name] then
                toggle(player, true)
            end
        end
    end
)

Gui.on_click(
    discard_add_player_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Ic Gui Discard Add Player')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end
        local player_frame = frame[draw_add_player_frame_name]

        if player_frame and player_frame.valid then
            player_frame.destroy()
        end
    end
)

Gui.on_click(
    discard_transfer_car_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Ic Gui Discard Transfer Car')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end
        local player_frame = frame[draw_transfer_car_frame_name]

        if player_frame and player_frame.valid then
            player_frame.destroy()
        end
    end
)

Gui.on_click(
    discard_destroy_surface_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Ic Gui Discard Destroy Surface')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end
        local player_frame = frame[draw_destroy_surface_frame_name]

        if player_frame and player_frame.valid then
            player_frame.destroy()
        end
    end
)

Gui.on_click(
    main_toolbar_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Ic Gui Main Toolbar')
        if is_spamming then
            return
        end
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]

        if frame and frame.valid then
            frame.destroy()
        else
            draw_main_frame(player)
        end
    end
)

Gui.on_selection_state_changed(
    transfer_player_select_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end

        local element = event.element
        if not element or not element.valid then
            return
        end

        local player_gui_data = ICT.get('player_gui_data')
        local fetched_name = element.items[element.selected_index]
        if not fetched_name then
            return
        end

        if type(fetched_name) == 'table' and fetched_name[1] == 'ic.select_player' then
            return player.print('[IC] Target player was not valid.', Color.warning)
        end

        if fetched_name == 'Select Player' then
            player.print('[IC] No target player selected.', Color.warning)
            player_gui_data[player.name] = nil
            return
        end

        if fetched_name == player.name then
            player.print('[IC] You can´t select yourself.', Color.warning)
            player_gui_data[player.name] = nil
            return
        end

        player_gui_data[player.name] = fetched_name
    end
)

Public.draw_main_frame = draw_main_frame
Public.toggle = toggle
Public.add_toolbar = add_toolbar
Public.remove_toolbar = remove_toolbar

Event.add(
    defines.events.on_gui_closed,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]

        if frame and frame.valid then
            frame.destroy()
        end
    end
)

Event.add(ICT.events.used_car_door, trigger_on_used_car_door)

return Public
