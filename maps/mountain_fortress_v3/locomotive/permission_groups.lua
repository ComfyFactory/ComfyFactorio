local Public = require 'maps.mountain_fortress_v3.table'
local Session = require 'utils.datastore.session_data'

local Antigrief = require 'utils.antigrief'

local required_playtime = 5184000 -- 24 hours

local valid_groups = {
    ['default'] = true,
    ['limited'] = true,
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

    default_group.set_allows_action(defines.input_action.activate_cut, false)
    if allow_decon_main_surface then
        default_group.set_allows_action(defines.input_action.deconstruct, true)
    else
        default_group.set_allows_action(defines.input_action.deconstruct, false)
    end

    if not game.permissions.get_group('limited') then
        local limited_group = game.permissions.create_group('limited')
        if not limited_group then
            return
        end
        limited_group.set_allows_action(defines.input_action.cancel_craft, false)
        limited_group.set_allows_action(defines.input_action.drop_item, false)
        -- limited_group.set_allows_action(defines.input_action.upgrade, false) -- fixes factorio base issue
        -- limited_group.set_allows_action(defines.input_action.upgrade_opened_blueprint_by_item, false)
        -- limited_group.set_allows_action(defines.input_action.upgrade_opened_blueprint_by_record, false)
        -- limited_group.set_allows_action(defines.input_action.cancel_upgrade, false)
        if allow_decon then
            limited_group.set_allows_action(defines.input_action.deconstruct, true)
        else
            limited_group.set_allows_action(defines.input_action.deconstruct, false)
        end
        limited_group.set_allows_action(defines.input_action.activate_cut, false)
    end

    if not game.permissions.get_group('near_locomotive') then
        local near_locomotive_group = game.permissions.create_group('near_locomotive')
        if not near_locomotive_group then
            return
        end
        near_locomotive_group.set_allows_action(defines.input_action.cancel_craft, false)
        near_locomotive_group.set_allows_action(defines.input_action.drop_item, false)
        if allow_decon_main_surface then
            near_locomotive_group.set_allows_action(defines.input_action.deconstruct, true)
        else
            near_locomotive_group.set_allows_action(defines.input_action.deconstruct, false)
        end
        near_locomotive_group.set_allows_action(defines.input_action.activate_cut, false)
    end

    if not game.permissions.get_group('main_surface') then
        local main_surface_group = game.permissions.create_group('main_surface')
        if not main_surface_group then
            return
        end
        if allow_decon_main_surface then
            main_surface_group.set_allows_action(defines.input_action.deconstruct, true)
        else
            main_surface_group.set_allows_action(defines.input_action.deconstruct, false)
        end
        main_surface_group.set_allows_action(defines.input_action.activate_cut, false)
    end

    if not game.permissions.get_group('not_trusted') then
        local not_trusted = game.permissions.create_group('not_trusted')
        if not not_trusted then
            return
        end
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
        not_trusted.set_allows_action(defines.input_action.activate_cut, false)
    end

    if not AG.enabled then
        default_group.add_player(player)
        return
    end

    if forced then
        default_group.add_player(player)
        return
    end

    local playtime = player.online_time
    if session[player.name] then
        playtime = player.online_time + session[player.name]
    end

    local limited_group = game.permissions.get_group('limited')
    local main_surface_group = game.permissions.get_group('main_surface')
    local near_locomotive_group = game.permissions.get_group('near_locomotive')

    if limited_group then
        limited_group.set_allows_action(defines.input_action.delete_blueprint_library, false)
        limited_group.set_allows_action(defines.input_action.delete_blueprint_record, false)
    end
    if main_surface_group then
        main_surface_group.set_allows_action(defines.input_action.delete_blueprint_library, false)
        main_surface_group.set_allows_action(defines.input_action.delete_blueprint_record, false)
    end
    if near_locomotive_group then
        near_locomotive_group.set_allows_action(defines.input_action.delete_blueprint_library, false)
        near_locomotive_group.set_allows_action(defines.input_action.delete_blueprint_record, false)
    end
    if default_group then
        default_group.set_allows_action(defines.input_action.delete_blueprint_library, false)
        default_group.set_allows_action(defines.input_action.delete_blueprint_record, false)
    end

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

    if playtime < required_playtime then
        local not_trusted = game.permissions.get_group('not_trusted')
        if not not_trusted then
            return
        end

        if not player.admin then
            not_trusted.add_player(player)
        end
    else
        if group == 'limited' then
            local limited_group_inner = game.permissions.get_group('limited')
            if not limited_group_inner then
                return
            end
            limited_group_inner.add_player(player)
        elseif group == 'main_surface' then
            local main_surface_group_inner = game.permissions.get_group('main_surface')
            if not main_surface_group_inner then
                return
            end

            main_surface_group_inner.add_player(player)
        elseif group == 'near_locomotive' then
            local near_locomotive_group_inner = game.permissions.get_group('near_locomotive')
            if not near_locomotive_group_inner then
                return
            end

            near_locomotive_group_inner.add_player(player)
        elseif group == 'default' then
            default_group.add_player(player)
        end
    end
end

return Public
