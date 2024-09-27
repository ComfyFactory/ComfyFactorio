-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Session = require("utils.datastore.session_data")
local Antigrief = require("utils.antigrief")
-- local Balance = require 'maps.pirates.balance'
local _inspect = require("utils.inspect").inspect
local Memory = require("maps.pirates.memory")
local Common = require("maps.pirates.common")
local CoreData = require("maps.pirates.coredata")

local Public = {}

local privilege_levels = {
    NORMAL = 1,
    OFFICER = 2,
    CAPTAIN = 3,
}
Public.privilege_levels = privilege_levels

function Public.player_privilege_level(player)
    local memory = Memory.get_crew_memory()

    if Common.is_id_valid(memory.id) and Common.is_captain(player) then
        return Public.privilege_levels.CAPTAIN
    elseif Common.is_officer(player.index) then
        return Public.privilege_levels.OFFICER
    else
        return Public.privilege_levels.NORMAL
    end
end

local function set_normal_permissions(group)
    if not _DEBUG then
        group.set_allows_action(defines.input_action.edit_permission_group, false)
    end
    group.set_allows_action(defines.input_action.import_permissions_string, false)
    group.set_allows_action(defines.input_action.delete_permission_group, false)
    group.set_allows_action(defines.input_action.add_permission_group, false)
    group.set_allows_action(defines.input_action.admin_action, false)
end

local function set_restricted_permissions(group)
    set_normal_permissions(group)

    group.set_allows_action(defines.input_action.cancel_craft, false)
    group.set_allows_action(defines.input_action.drop_item, false)
    group.set_allows_action(defines.input_action.drop_blueprint_record, false)
    group.set_allows_action(defines.input_action.build, false)
    group.set_allows_action(defines.input_action.build_rail, false)
    group.set_allows_action(defines.input_action.build_terrain, false)
    group.set_allows_action(defines.input_action.begin_mining, false)
    group.set_allows_action(defines.input_action.begin_mining_terrain, false)
    group.set_allows_action(defines.input_action.activate_paste, false)
    group.set_allows_action(defines.input_action.upgrade, false)
    group.set_allows_action(defines.input_action.deconstruct, false)
    group.set_allows_action(defines.input_action.open_gui, false)
    group.set_allows_action(defines.input_action.fast_entity_transfer, false)
    group.set_allows_action(defines.input_action.fast_entity_split, false)
end

function Public.try_create_permissions_groups()
    if not game.permissions.get_group("lobby") then
        local group = game.permissions.create_group("lobby")
        set_restricted_permissions(group)

        group.set_allows_action(defines.input_action.open_blueprint_library_gui, false)
        group.set_allows_action(defines.input_action.grab_blueprint_record, false)
        group.set_allows_action(defines.input_action.import_blueprint_string, false)
        group.set_allows_action(defines.input_action.import_blueprint, false)
    end

    if not game.permissions.get_group("crowsnest") then
        local group = game.permissions.create_group("crowsnest")
        set_restricted_permissions(group)
        group.set_allows_action(defines.input_action.deconstruct, true) --pick up dead players
    end

    if not game.permissions.get_group("crowsnest_privileged") then
        local group = game.permissions.create_group("crowsnest_privileged")
        set_restricted_permissions(group)
        group.set_allows_action(defines.input_action.deconstruct, true) --pick up dead players

        group.set_allows_action(defines.input_action.open_gui, true)
        group.set_allows_action(defines.input_action.fast_entity_transfer, true)
        group.set_allows_action(defines.input_action.fast_entity_split, true)
    end

    if not game.permissions.get_group("cabin") then
        local group = game.permissions.create_group("cabin")
        group.set_allows_action(defines.input_action.deconstruct, true) --pick up dead players
        set_restricted_permissions(group)

        group.set_allows_action(defines.input_action.open_gui, true) -- We want you to open the market, but there is other code to prevent you from opening certain chests
    end

    if not game.permissions.get_group("cabin_privileged") then
        local group = game.permissions.create_group("cabin_privileged")
        group.set_allows_action(defines.input_action.deconstruct, true) --pick up dead players
        set_restricted_permissions(group)

        group.set_allows_action(defines.input_action.open_gui, true) -- We want you to open the market, but there is other code to prevent you from opening certain chests
    end

    if not game.permissions.get_group("plebs") then
        local group = game.permissions.create_group("plebs")
        set_normal_permissions(group)
    end

    if not game.permissions.get_group("not_trusted") then
        local group = game.permissions.create_group("not_trusted")
        set_normal_permissions(group)

        -- not_trusted.set_allows_action(defines.input_action.cancel_craft, false)
        -- not_trusted.set_allows_action(defines.input_action.drop_item, false)
        group.set_allows_action(defines.input_action.disconnect_rolling_stock, false)
        group.set_allows_action(defines.input_action.connect_rolling_stock, false)
        group.set_allows_action(defines.input_action.open_train_gui, false)
        group.set_allows_action(defines.input_action.open_train_station_gui, false)
        group.set_allows_action(defines.input_action.open_trains_gui, false)
        group.set_allows_action(defines.input_action.change_train_stop_station, false)
        group.set_allows_action(defines.input_action.change_train_wait_condition, false)
        group.set_allows_action(defines.input_action.change_train_wait_condition_data, false)
        group.set_allows_action(defines.input_action.drag_train_schedule, false)
        group.set_allows_action(defines.input_action.drag_train_wait_condition, false)
        group.set_allows_action(defines.input_action.go_to_train_station, false)
        group.set_allows_action(defines.input_action.remove_train_station, false)
        group.set_allows_action(defines.input_action.set_trains_limit, false)
        group.set_allows_action(defines.input_action.set_train_stopped, false)
    end

    local blueprint_disabled_groups = {
        "crowsnest_bps_disabled",
        "crowsnest_privileged_bps_disabled",
        "cabin_bps_disabled",
        "cabin_privileged_bps_disabled",
        "plebs_bps_disabled",
        "not_trusted_bps_disabled",
    }

    for _, group_name in ipairs(blueprint_disabled_groups) do
        if not game.permissions.get_group(group_name) then
            local group = game.permissions.create_group(group_name)
            local base_group_name = group_name:gsub("_bps_disabled", "")
            local base_group = game.permissions.get_group(base_group_name)

            for _, action in pairs(defines.input_action) do
                group.set_allows_action(action, base_group.allows_action(action))
            end

            group.set_allows_action(defines.input_action.open_blueprint_library_gui, false)
            group.set_allows_action(defines.input_action.grab_blueprint_record, false)
            group.set_allows_action(defines.input_action.import_blueprint_string, false)
            group.set_allows_action(defines.input_action.import_blueprint, false)
        end
    end
end

local function add_player_to_permission_group(player, group_override)
    Public.try_create_permissions_groups()

    -- local jailed = Jailed.get_jailed_table()
    -- local enable_permission_group_disconnect = WPT.get('disconnect_wagon')

    local gulag = game.permissions.get_group("gulag")
    local tbl = gulag and gulag.players
    if tbl then
        for i = 1, #tbl do
            if tbl[i].index == player.index then
                return
            end
        end
    end

    -- if player.admin then
    --     return
    -- end

    -- if jailed[player.name] then
    --     return
    -- end

    local group = game.permissions.get_group(group_override)

    group.add_player(player)
end

function Public.update_privileges(player)
    Public.try_create_permissions_groups()

    if not Common.validate_player_and_character(player) then
        return
    end

    local memory = Memory.get_crew_memory()
    local bps_disabled_suffix = memory.run_has_blueprints_disabled and "_bps_disabled" or ""

    if string.sub(player.surface.name, 9, 17) == "Crowsnest" then
        if Public.player_privilege_level(player) >= Public.privilege_levels.OFFICER then
            return add_player_to_permission_group(player, "crowsnest_privileged" .. bps_disabled_suffix)
        else
            return add_player_to_permission_group(player, "crowsnest" .. bps_disabled_suffix)
        end
    elseif string.sub(player.surface.name, 9, 13) == "Cabin" then
        if Public.player_privilege_level(player) >= Public.privilege_levels.OFFICER then
            return add_player_to_permission_group(player, "cabin_privileged" .. bps_disabled_suffix)
        else
            return add_player_to_permission_group(player, "cabin" .. bps_disabled_suffix)
        end
    elseif player.surface.name == CoreData.lobby_surface_name then
        return add_player_to_permission_group(player, "lobby")
    else
        local session = Session.get_session_table()
        local AG = Antigrief.get()

        local playtime = player.online_time
        if session and session[player.name] then
            playtime = player.online_time + session[player.name]
        end

        if AG and AG.enabled and not player.admin and playtime < 5184000 then -- 24 hours
            add_player_to_permission_group(player, "not_trusted" .. bps_disabled_suffix)
        else
            add_player_to_permission_group(player, "plebs" .. bps_disabled_suffix)
        end
    end
end

return Public
