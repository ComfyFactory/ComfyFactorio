local Public = require 'maps.mountain_fortress_v3.table'
local Session = require 'utils.datastore.session_data'

local Antigrief = require 'utils.antigrief'

local required_playtime = 5184000 -- 24 hours

local valid_groups = {
    ['default'] = true,
    ['limited'] = true,
    ['init_island'] = true,
    ['main_surface'] = true,
    ['near_locomotive'] = true,
    ['not_trusted'] = true
}

function Public.add_player_to_permission_group(player, group, forced)
    local enable_permission_group_disconnect = Public.get('disconnect_wagon')
    local session = Session.get_session_table()
    local AG = Antigrief.get()
    if not AG then
        return
    end



    local default_group = game.permissions.get_group('Default')
    if not default_group then
        return
    end

    if not valid_groups[string.lower(player.permission_group.name)] then
        return
    end

    local allow_decon = Public.get('allow_decon')
    local allow_decon_main_surface = Public.get('allow_decon_main_surface')

    if allow_decon_main_surface then
        default_group.set_allows_action(defines.input_action.deconstruct, true)
    else
        default_group.set_allows_action(defines.input_action.deconstruct, false)
    end

    local limited_group = game.permissions.get_group('limited') or game.permissions.create_group('limited')
    limited_group.set_allows_action(defines.input_action.cancel_craft, false)
    limited_group.set_allows_action(defines.input_action.drop_item, false)
    if allow_decon then
        limited_group.set_allows_action(defines.input_action.deconstruct, true)
    else
        limited_group.set_allows_action(defines.input_action.deconstruct, false)
    end

    local spectator = game.permissions.get_group('spectator') or game.permissions.create_group('spectator')
    spectator.set_allows_action(defines.input_action.open_gui, false)

    local init_island = game.permissions.get_group('init_island') or game.permissions.create_group('init_island')
    init_island.set_allows_action(defines.input_action.cancel_craft, false)
    init_island.set_allows_action(defines.input_action.drop_item, false)
    init_island.set_allows_action(defines.input_action.gui_click, false)
    init_island.set_allows_action(defines.input_action.deconstruct, false)
    init_island.set_allows_action(defines.input_action.gui_checked_state_changed, false)
    init_island.set_allows_action(defines.input_action.gui_click, false)
    init_island.set_allows_action(defines.input_action.gui_confirmed, false)
    init_island.set_allows_action(defines.input_action.gui_elem_changed, false)
    init_island.set_allows_action(defines.input_action.gui_hover, false)
    init_island.set_allows_action(defines.input_action.gui_leave, false)
    init_island.set_allows_action(defines.input_action.gui_location_changed, false)
    init_island.set_allows_action(defines.input_action.gui_selected_tab_changed, false)
    init_island.set_allows_action(defines.input_action.gui_selection_state_changed, false)
    init_island.set_allows_action(defines.input_action.gui_switch_state_changed, false)
    init_island.set_allows_action(defines.input_action.gui_text_changed, false)
    init_island.set_allows_action(defines.input_action.gui_value_changed, false)

    local near_locomotive_group = game.permissions.get_group('near_locomotive') or game.permissions.create_group('near_locomotive')
    near_locomotive_group.set_allows_action(defines.input_action.cancel_craft, false)
    near_locomotive_group.set_allows_action(defines.input_action.drop_item, false)
    if allow_decon_main_surface then
        near_locomotive_group.set_allows_action(defines.input_action.deconstruct, true)
    else
        near_locomotive_group.set_allows_action(defines.input_action.deconstruct, false)
    end

    local main_surface_group = game.permissions.get_group('main_surface') or game.permissions.create_group('main_surface')
    if allow_decon_main_surface then
        main_surface_group.set_allows_action(defines.input_action.deconstruct, true)
    else
        main_surface_group.set_allows_action(defines.input_action.deconstruct, false)
    end

    local not_trusted = game.permissions.get_group('not_trusted') or game.permissions.create_group('not_trusted')

    not_trusted.set_allows_action(defines.input_action.cancel_craft, false)
    not_trusted.set_allows_action(defines.input_action.edit_permission_group, false)
    not_trusted.set_allows_action(defines.input_action.import_permissions_string, false)
    not_trusted.set_allows_action(defines.input_action.delete_permission_group, false)
    not_trusted.set_allows_action(defines.input_action.add_permission_group, false)
    not_trusted.set_allows_action(defines.input_action.admin_action, false)
    not_trusted.set_allows_action(defines.input_action.drop_item, false)
    not_trusted.set_allows_action(defines.input_action.cancel_research, false)
    not_trusted.set_allows_action(defines.input_action.disconnect_rolling_stock, false)
    not_trusted.set_allows_action(defines.input_action.connect_rolling_stock, false)
    not_trusted.set_allows_action(defines.input_action.open_train_gui, false)
    not_trusted.set_allows_action(defines.input_action.open_train_station_gui, false)
    not_trusted.set_allows_action(defines.input_action.open_trains_gui, false)
    not_trusted.set_allows_action(defines.input_action.change_train_stop_station, false)
    not_trusted.set_allows_action(defines.input_action.change_train_wait_condition, false)
    not_trusted.set_allows_action(defines.input_action.change_train_wait_condition_data, false)
    not_trusted.set_allows_action(defines.input_action.drag_train_schedule, false)
    not_trusted.set_allows_action(defines.input_action.drag_train_wait_condition, false)
    not_trusted.set_allows_action(defines.input_action.go_to_train_station, false)
    not_trusted.set_allows_action(defines.input_action.remove_train_station, false)
    not_trusted.set_allows_action(defines.input_action.set_trains_limit, false)
    not_trusted.set_allows_action(defines.input_action.set_train_stopped, false)
    not_trusted.set_allows_action(defines.input_action.deconstruct, false)
    not_trusted.set_allows_action(defines.input_action.upgrade_opened_blueprint_by_record, false)
    not_trusted.set_allows_action(defines.input_action.upgrade_opened_blueprint_by_item, false)
    not_trusted.set_allows_action(defines.input_action.setup_single_blueprint_record, false)
    not_trusted.set_allows_action(defines.input_action.select_blueprint_entities, false)
    not_trusted.set_allows_action(defines.input_action.setup_blueprint, false)
    not_trusted.set_allows_action(defines.input_action.reassign_blueprint, false)
    not_trusted.set_allows_action(defines.input_action.parametrise_blueprint, false)
    not_trusted.set_allows_action(defines.input_action.open_blueprint_record, false)
    not_trusted.set_allows_action(defines.input_action.open_blueprint_library_gui, false)
    not_trusted.set_allows_action(defines.input_action.import_blueprints_filtered, false)
    not_trusted.set_allows_action(defines.input_action.import_blueprint_string, false)
    not_trusted.set_allows_action(defines.input_action.import_blueprint, false)
    not_trusted.set_allows_action(defines.input_action.grab_blueprint_record, false)
    not_trusted.set_allows_action(defines.input_action.export_blueprint, false)
    not_trusted.set_allows_action(defines.input_action.edit_blueprint_tool_preview, false)
    not_trusted.set_allows_action(defines.input_action.drop_blueprint_record, false)
    not_trusted.set_allows_action(defines.input_action.delete_blueprint_record, false)
    not_trusted.set_allows_action(defines.input_action.delete_blueprint_library, false)
    not_trusted.set_allows_action(defines.input_action.cycle_blueprint_book_forwards, false)
    not_trusted.set_allows_action(defines.input_action.cycle_blueprint_book_forwards, false)
    not_trusted.set_allows_action(defines.input_action.cycle_blueprint_book_backwards, false)
    not_trusted.set_allows_action(defines.input_action.copy_opened_blueprint, false)
    not_trusted.set_allows_action(defines.input_action.cycle_blueprint_book_forwards, false)
    not_trusted.set_allows_action(defines.input_action.copy_large_opened_blueprint, false)
    not_trusted.set_allows_action(defines.input_action.alt_select_blueprint_entities, false)
    not_trusted.set_allows_action(defines.input_action.alt_select_blueprint_entities, false)
    not_trusted.set_allows_action(defines.input_action.cancel_new_blueprint, false)
    not_trusted.set_allows_action(defines.input_action.alt_select_blueprint_entities, false)
    not_trusted.set_allows_action(defines.input_action.adjust_blueprint_snapping, false)

    if not AG.enabled then
        default_group.add_player(player)
        log('Antigrief is not enabled. Default group added to player.')
        return
    end

    local playtime = player.online_time
    if session[player.name] then
        playtime = player.online_time + session[player.name]
    end


    limited_group.set_allows_action(defines.input_action.delete_blueprint_library, false)
    limited_group.set_allows_action(defines.input_action.delete_blueprint_record, false)
    main_surface_group.set_allows_action(defines.input_action.delete_blueprint_library, false)
    main_surface_group.set_allows_action(defines.input_action.delete_blueprint_record, false)
    near_locomotive_group.set_allows_action(defines.input_action.delete_blueprint_library, false)
    near_locomotive_group.set_allows_action(defines.input_action.delete_blueprint_record, false)
    default_group.set_allows_action(defines.input_action.delete_blueprint_library, false)
    default_group.set_allows_action(defines.input_action.delete_blueprint_record, false)

    if enable_permission_group_disconnect then
        if limited_group then
            limited_group.set_allows_action(defines.input_action.disconnect_rolling_stock, true)
        end
        if main_surface_group then
            main_surface_group.set_allows_action(defines.input_action.disconnect_rolling_stock, true)
        end
        if near_locomotive_group then
            near_locomotive_group.set_allows_action(defines.input_action.disconnect_rolling_stock, true)
        end
        if default_group then
            default_group.set_allows_action(defines.input_action.disconnect_rolling_stock, true)
        end
    else
        if limited_group then
            limited_group.set_allows_action(defines.input_action.disconnect_rolling_stock, false)
        end
        if main_surface_group then
            main_surface_group.set_allows_action(defines.input_action.disconnect_rolling_stock, false)
        end
        if near_locomotive_group then
            near_locomotive_group.set_allows_action(defines.input_action.disconnect_rolling_stock, false)
        end
        if default_group then
            default_group.set_allows_action(defines.input_action.disconnect_rolling_stock, false)
        end
    end

    if not Session.get_trusted_player(player) and playtime < required_playtime and not forced then
        if not player.admin then
            not_trusted.add_player(player)
        end
    else
        if group == 'limited' then
            limited_group.add_player(player)
        elseif group == 'spectator' then
            spectator.add_player(player)
        elseif group == 'main_surface' then
            main_surface_group.add_player(player)
        elseif group == 'init_island' then
            init_island.add_player(player)
        elseif group == 'near_locomotive' then
            near_locomotive_group.add_player(player)
        elseif group == 'default' then
            default_group.add_player(player)
        end
    end
end

return Public
