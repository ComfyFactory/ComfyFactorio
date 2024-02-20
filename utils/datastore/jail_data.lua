-- created by Gerkiz for ComfyFactorio
local Global = require 'utils.global'
local Session = require 'utils.datastore.session_data'
local Game = require 'utils.game'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Utils = require 'utils.core'
local table = require 'utils.table'
local Gui = require 'utils.gui'

local module_name = '[Jail handler] '

local jailed_data_set = 'jailed'
local revoked_permissions_set = 'revoked_permissions_jailed'
local jailed = {}
local player_data = {}
local terms_tbl = {}
local votejail = {}
local votefree = {}
local revoked_permissions = {}
local settings = {
    playtime_for_vote = 77760000, -- 15 days
    playtime_for_instant_jail = 362880000, -- 70 days
    -- playtime_for_instant_jail = 103680000, -- 20 days
    clear_voted_player = 36000, -- remove player from vote-tbl after 10 minutes
    clear_terms_tbl = 2000,
    votejail_count = 5,
    valid_surface = 'nauvis',
    normies_can_jail = true -- states that normal players with enough playtime can jail
}

local set_data = Server.set_data
local try_get_data = Server.try_get_data
local concat = table.concat

local release_player_from_temporary_prison_token
local remove_notice
local remove_action_needed
local draw_notice_frame

local jail_frame_name = Gui.uid_name()
local notice_frame_name = Gui.uid_name()
local placeholder_jail_text_box = Gui.uid_name()
local save_button_name = Gui.uid_name()
local discard_button_name = Gui.uid_name()

local valid_commands = {
    ['free'] = true,
    ['jail'] = true
}

Global.register(
    {
        jailed = jailed,
        votejail = votejail,
        votefree = votefree,
        settings = settings,
        player_data = player_data,
        terms_tbl = terms_tbl,
        revoked_permissions = revoked_permissions
    },
    function(t)
        jailed = t.jailed
        votejail = t.votejail
        votefree = t.votefree
        settings = t.settings
        player_data = t.player_data
        terms_tbl = t.terms_tbl
        revoked_permissions = t.revoked_permissions
    end
)

local Public = {}

local function validate_entity(entity)
    if not (entity and entity.valid) then
        return false
    end

    return true
end

local function is_revoked(name)
    if name then
        if revoked_permissions[name] then
            return true
        else
            return false
        end
    end
    return false
end

local function add_revoked(name, admin, reason)
    if name then
        local date = Server.get_current_date_with_time()

        if not revoked_permissions[name] then
            revoked_permissions[name] = true
            set_data(revoked_permissions_set, name, {revoked = true, actor = admin, reason = reason, date = date})
            return true
        else
            return false
        end
    end
    return false
end

local function remove_revoked(name)
    if name then
        if revoked_permissions[name] then
            revoked_permissions[name] = nil
            set_data(revoked_permissions_set, name, nil)
            return true
        else
            return false
        end
    end
    return false
end

local clear_terms_tbl =
    Token.register(
    function(data)
        local player = data.player
        if not player then
            return
        end

        if terms_tbl[player] then
            terms_tbl[player] = nil
            return
        end
    end
)

local play_alert_sound =
    Token.register(
    function(data)
        local name = data.name
        if not name then
            return
        end
        local player = game.get_player(name)
        if not player or not player.valid then
            return
        end

        player.play_sound {path = 'utility/scenario_message', volume_modifier = 1}
    end
)

local clear_jail_data_token =
    Token.register(
    function(data)
        local offender = data.offender
        if not offender then
            return
        end
        if votejail[offender] and votejail[offender].jailed then
            return
        end

        local msg_two = 'You have been cleared of all accusations because not enough players voted against you.'
        Utils.print_to(offender, msg_two)
        votejail[offender] = nil
        votefree[offender] = nil
    end
)

local clear_gui =
    Token.register(
    function(data)
        local player = data.player
        if player and player.valid then
            for _, child in pairs(player.gui.center.children) do
                child.destroy()
            end
            for _, child in pairs(player.gui.left.children) do
                child.destroy()
            end
        end
    end
)

local function validate_playtime(player)
    local tracker = Session.get_session_table()

    local playtime = player.online_time

    if tracker[player.name] then
        playtime = player.online_time + tracker[player.name]
    end

    return playtime
end

local function validate_trusted(player)
    local trusted = Session.get_trusted_table()

    local is_trusted = false

    if trusted[player.name] then
        is_trusted = true
    end

    return is_trusted
end

local function get_player_data(player, remove)
    if remove and player_data[player.name] then
        player_data[player.name] = nil
        return
    end
    if not player_data[player.name] then
        player_data[player.name] = {}
    end
    return player_data[player.name]
end

local function get_gulag_permission_group()
    local gulag = game.permissions.get_group('gulag')
    if not gulag then
        gulag = game.permissions.create_group('gulag')
        for action_name, _ in pairs(defines.input_action) do
            ---@diagnostic disable-next-line: need-check-nil
            gulag.set_allows_action(defines.input_action[action_name], false)
        end
        ---@diagnostic disable-next-line: need-check-nil
        gulag.set_allows_action(defines.input_action.write_to_console, true)
    end

    return gulag
end

local function get_super_gulag_permission_group()
    local gulag = game.permissions.get_group('super_gulag')
    if not gulag then
        gulag = game.permissions.create_group('super_gulag')
        for action_name, _ in pairs(defines.input_action) do
            ---@diagnostic disable-next-line: need-check-nil
            gulag.set_allows_action(defines.input_action[action_name], false)
        end
    end

    return gulag
end

local function create_gulag_surface()
    local surface = game.surfaces['gulag']
    if not surface then
        local walls = {}
        local tiles = {}
        pcall(
            function()
                surface =
                    game.create_surface(
                    'gulag',
                    {
                        autoplace_controls = {
                            ['coal'] = {frequency = 23, size = 3, richness = 3},
                            ['stone'] = {frequency = 20, size = 3, richness = 3},
                            ['copper-ore'] = {frequency = 25, size = 3, richness = 3},
                            ['iron-ore'] = {frequency = 35, size = 3, richness = 3},
                            ['uranium-ore'] = {frequency = 20, size = 3, richness = 3},
                            ['crude-oil'] = {frequency = 80, size = 3, richness = 1},
                            ['trees'] = {frequency = 0.75, size = 2, richness = 0.1},
                            ['enemy-base'] = {frequency = 15, size = 0, richness = 1}
                        },
                        cliff_settings = {cliff_elevation_0 = 1024, cliff_elevation_interval = 10, name = 'cliff'},
                        height = 64,
                        width = 256,
                        peaceful_mode = false,
                        seed = 1337,
                        starting_area = 'very-low',
                        starting_points = {{x = 0, y = 0}},
                        terrain_segmentation = 'normal',
                        water = 'normal'
                    }
                )
            end
        )
        if not surface then
            surface = game.create_surface('gulag', {width = 40, height = 40})
        end
        surface.always_day = true
        surface.request_to_generate_chunks({0, 0}, 9)
        surface.force_generate_chunk_requests()
        local area = {left_top = {x = -128, y = -32}, right_bottom = {x = 128, y = 32}}
        for x = area.left_top.x, area.right_bottom.x, 1 do
            for y = area.left_top.y, area.right_bottom.y, 1 do
                tiles[#tiles + 1] = {name = 'black-refined-concrete', position = {x = x, y = y}}
                if x == area.left_top.x or x == area.right_bottom.x or y == area.left_top.y or y == area.right_bottom.y then
                    walls[#walls + 1] = {name = 'stone-wall', force = 'neutral', position = {x = x, y = y}}
                end
            end
        end
        surface.set_tiles(tiles)
        for _, entity in pairs(walls) do
            local e = surface.create_entity(entity)
            e.destructible = false
            e.minable = false
        end

        rendering.draw_text {
            text = 'The pit of despair ☹',
            surface = surface,
            target = {0, -50},
            color = {r = 0.98, g = 0.66, b = 0.22},
            scale = 10,
            font = 'heading-1',
            alignment = 'center',
            scale_with_zoom = false
        }
    end
    surface = game.surfaces['gulag']
    return surface
end

local function teleport_player_to_gulag(player, action, mute)
    local p_data = get_player_data(player)
    if not p_data then
        return
    end

    if action == 'jail' then
        local gulag = game.surfaces['gulag']
        if p_data and not p_data.locked then
            p_data.fallback_surface_index = player.surface.index
            p_data.position = player.position
            p_data.p_group_id = player.permission_group.group_id
            p_data.locked = true
            p_data.muted = mute or false
        end
        player.teleport(gulag.find_non_colliding_position('character', {0, 0}, 128, 1), gulag.name)
        local data = {
            player = player
        }
        Task.set_timeout_in_ticks(5, clear_gui, data)
    elseif action == 'free' then
        jailed[player.name] = nil
        if votejail[player.name] then
            votejail[player.name] = nil
        end
        if votefree[player.name] then
            votefree[player.name] = nil
        end

        local surface = game.surfaces[p_data.fallback_surface_index]
        if not surface or not surface.valid then
            if settings.valid_surface then
                surface = game.surfaces[settings.valid_surface]
            end
        end

        local p = p_data.position
        local p_group = game.permissions.get_group(p_data.p_group_id)
        if not p_group then
            return
        end

        p_group.add_player(player)
        local pos = {x = p.x, y = p.y}
        ---@diagnostic disable-next-line: missing-parameter
        local get_tile = surface.get_tile(pos)
        if get_tile.valid and get_tile.name == 'out-of-map' then
            player.teleport(surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 128, 1), surface.name)
        else
            local valid_to_teleport = surface.find_non_colliding_position('character', p, 128, 1)
            if valid_to_teleport then
                player.teleport(valid_to_teleport, surface.name)
            else
                player.teleport(game.forces.player.get_spawn_position(surface), surface.name)
            end
        end

        get_player_data(player, true)
    end
end

local function validate_args(data)
    local player = data.player
    local offender = data.offender
    local trusted = data.trusted
    local playtime = data.playtime
    local message = data.message
    local cmd = data.cmd

    if not offender then
        return
    end

    if not type(offender) == 'string' then
        Utils.print_to(player, 'Invalid name.')
        return false
    end

    local get_offender_player = game.get_player(offender)

    if not validate_entity(get_offender_player) then
        Utils.print_to(player, module_name .. 'No valid player given. Reason is no longer required.')
        Utils.print_to(player, module_name .. 'Valid input: /jail ' .. player.name)
        return false
    end

    if not offender or not get_offender_player then
        Utils.print_to(player, module_name .. 'No valid player given. Reason is no longer required.')
        Utils.print_to(player, module_name .. 'Valid input: /jail ' .. player.name)
        return false
    end

    if cmd == 'jail' and jailed[get_offender_player.name] then
        Utils.print_to(player, module_name .. 'Player is already jailed.')
        return false
    end

    if cmd == 'free' and not jailed[get_offender_player.name] then
        Utils.print_to(player, module_name .. 'Player is not jailed.')
        return false
    end

    if votejail[player.name] and not player.admin then
        Utils.print_to(player, module_name .. 'You are currently being investigated since you have griefed.')
        return false
    end

    if votefree[player.name] and not player.admin then
        Utils.print_to(player, module_name .. 'You are currently being investigated since you have griefed.')
        return false
    end

    if jailed[player.name] and not player.admin then
        Utils.print_to(player, module_name .. 'You are jailed, you can´t run this command.')
        return false
    end

    if is_revoked(player.name) then
        Utils.print_to(player, module_name .. 'Your jail permissions have been revoked. Contact an admin to appeal this.')
        return false
    end

    if player.name == offender then
        Utils.print_to(player, module_name .. 'You can´t select yourself.')
        return false
    end

    if get_offender_player.admin and not player.admin then
        Utils.print_to(player, module_name .. 'You can´t select an admin.')
        return false
    end

    if not trusted and not player.admin or playtime <= settings.playtime_for_vote and not player.admin then
        Utils.print_to(player, module_name .. 'You are not trusted enough to run this command.')
        return false
    end

    if not message then
        Utils.print_to(player, module_name .. 'No valid reason was given.')
        return false
    end

    if cmd == 'jail' and message and string.len(message) <= 0 then
        Utils.print_to(player, module_name .. 'No valid reason was given.')
        return false
    end

    if cmd == 'jail' and message and string.len(message) <= 10 then
        Utils.print_to(player, module_name .. 'Reason is too short.')
        return false
    end

    return true
end

local function validate_server_args(data)
    local offender = data.offender
    local message = data.message
    local cmd = data.cmd

    if not offender then
        return
    end

    if not type(offender) == 'string' then
        print(module_name .. 'Invalid name.')
        return false
    end

    local get_offender_player = game.get_player(offender)

    if not validate_entity(get_offender_player) then
        print(module_name .. 'Invalid name.')
        return false
    end

    if not offender or not get_offender_player then
        print(module_name .. 'Invalid name.')
        return false
    end

    if cmd == 'jail' and jailed[get_offender_player.name] then
        print(module_name .. 'Player is already jailed.')
        return false
    end

    if cmd == 'free' and not jailed[get_offender_player.name] then
        print(module_name .. 'Player is not jailed.')
        return false
    end

    if cmd == 'jail' and get_offender_player.admin then
        print(module_name .. 'You can´t jail an admin.')
        return false
    end

    if not message then
        print(module_name .. 'No valid reason was given.')
        return false
    end

    if cmd == 'jail' and message and string.len(message) <= 0 then
        print(module_name .. 'No valid reason was given.')
        return false
    end

    if cmd == 'jail' and message and string.len(message) <= 10 then
        print(module_name .. 'Reason is too short.')
        return false
    end

    return true
end

local function vote_to_jail(player, offender, msg)
    if not offender then
        return
    end

    if type(offender) == 'table' then
        offender = offender.name
    end

    if not votejail[offender] then
        votejail[offender] = {index = 0, actor = player.name}
        local message = player.name .. ' has started a vote to jail player ' .. offender
        Utils.print_to(nil, message)
        Task.set_timeout_in_ticks(settings.clear_voted_player, clear_jail_data_token, {offender = offender})
    end

    if not votejail[offender][player.name] then
        votejail[offender][player.name] = true
        votejail[offender].index = votejail[offender].index + 1
        Utils.print_to(player, 'You have voted to jail player ' .. offender .. '.')
        if votejail[offender].index >= settings.votejail_count or (votejail[offender].index == #game.connected_players - 1 and #game.connected_players > votejail[offender].index) then
            Public.try_ul_data(offender, true, votejail[offender].actor, msg)
        end
    else
        Utils.print_to(player, 'You have already voted to kick ' .. offender .. '.')
    end
end

local function vote_to_free(player, offender)
    if not offender then
        return
    end

    if type(offender) == 'table' then
        offender = offender.name
    end

    if not votefree[offender] then
        votefree[offender] = {index = 0, actor = player.name}
        local message = player.name .. ' has started a vote to free player ' .. offender
        Utils.print_to(nil, message)
    end

    if not votefree[offender][player.name] then
        votefree[offender][player.name] = true
        votefree[offender].index = votefree[offender].index + 1

        Utils.print_to(player, 'You have voted to free player ' .. offender .. '.')
        if votefree[offender].index >= settings.votejail_count or (votefree[offender].index == #game.connected_players - 1 and #game.connected_players > votefree[offender].index) then
            Public.try_ul_data(offender, false, votefree[offender].actor)
            votejail[offender] = nil
            votefree[offender] = nil
        end
    else
        Utils.print_to(player, 'You have already voted to free ' .. offender .. '.')
    end
    return
end

local function jail(player, offender, msg, raised, mute)
    player = player or 'script'

    if jailed[offender] then
        return false
    end

    if not msg then
        msg = 'Jailed by script - no reason was provided.'
    end

    if not game.get_player(offender) then
        return
    end

    local to_jail_player = game.get_player(offender)
    if not to_jail_player or not to_jail_player.valid then
        return
    end

    if to_jail_player.character and to_jail_player.character.valid and to_jail_player.character.driving then
        to_jail_player.character.driving = false
    end

    teleport_player_to_gulag(to_jail_player, 'jail', mute)

    draw_notice_frame(to_jail_player)

    if mute then
        local gulag = get_super_gulag_permission_group()
        gulag.add_player(offender)
    else
        local gulag = get_gulag_permission_group()
        gulag.add_player(offender)
    end

    local date = Server.get_current_date_with_time()

    local message = offender .. ' has been jailed by ' .. player .. '. Cause: ' .. msg

    jailed[offender] = {jailed = true, actor = player, reason = msg}
    if not raised then
        set_data(jailed_data_set, offender, {jailed = true, actor = player, reason = msg, date = date})
    end

    Utils.print_to(nil, message)
    local data = Server.build_embed_data()
    data.username = offender
    data.admin = player
    data.reason = msg
    Server.to_jailed_named_embed(data)

    if votejail[offender] then
        votejail[offender].jailed = true
    end

    to_jail_player.clear_console()
    Utils.print_to(offender, message)
    return true
end

--- Jails a player temporary
---@param player LuaPlayer
---@param offender LuaPlayer
---@param msg string
---@param mute boolean
---@return boolean
local function jail_temporary(player, offender, msg, mute)
    if jailed[offender.name] then
        return false
    end

    if not msg then
        msg = 'Jailed by script - no reason was provided.'
    end

    if offender.character and offender.character.valid and offender.character.driving then
        offender.character.driving = false
    end

    teleport_player_to_gulag(offender, 'jail', mute)

    if mute then
        local gulag = get_super_gulag_permission_group()
        gulag.add_player(offender)
    else
        local gulag = get_gulag_permission_group()
        gulag.add_player(offender)
    end

    local message = offender.name .. ' has been temporary jailed by ' .. player.name .. '.'

    jailed[offender.name] = {jailed = true, actor = player.name, reason = msg, temporary = true}

    Utils.print_to(nil, message)
    local data = Server.build_embed_data()
    data.username = offender.name
    data.admin = player.name
    data.reason = msg
    Server.to_jailed_named_embed(data)

    if votejail[offender.name] then
        votejail[offender.name].jailed = true
    end

    offender.clear_console()

    draw_notice_frame(offender)

    Task.set_timeout_in_ticks(10800, release_player_from_temporary_prison_token, {offender_name = offender.name, actor_name = player.name})
    return true
end

local function free(player, offender)
    player = player or 'script'
    if not jailed[offender] then
        return false
    end

    if not game.get_player(offender) then
        return
    end

    local to_jail_player = game.get_player(offender)
    teleport_player_to_gulag(to_jail_player, 'free')

    local message = offender .. ' was set free from jail by ' .. player .. '.'

    set_data(jailed_data_set, offender, nil)

    Utils.print_to(nil, message)
    local data = Server.build_embed_data()
    data.username = offender
    data.admin = player
    Server.to_unjailed_embed(data)
    Server.to_unjailed_named_embed(data)
    offender = game.get_player(offender)
    remove_notice(offender)
    return true
end

local is_jailed =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value
        if value and value.jailed and value.reason then
            jail('script', key, value.reason, true)
        else
            free('script', key)
        end
    end
)

--! start gui handler

release_player_from_temporary_prison_token =
    Token.register(
    function(event)
        local actor_name = event.actor_name
        local offender_name = event.offender_name

        if jailed[offender_name] and jailed[offender_name].temporary then
            free('script', offender_name)
            Utils.print_to(nil, module_name .. 'If you find someone abusing their jail permissions - report them to the admins of Comfy!')

            local actor = game.get_player(actor_name)
            remove_action_needed(actor)
        end
    end
)

local function remove_target_frame(target_frame)
    Gui.remove_data_recursively(target_frame)
    target_frame.destroy()
end

local function draw_main_frame(player, offender)
    local main_frame, inside_table = Gui.add_main_frame_with_toolbar(player, 'screen', jail_frame_name, nil, nil, 'Jail in progress', true)

    if not main_frame or not inside_table then
        return
    end

    local main_frame_style = main_frame.style
    main_frame_style.width = 500
    main_frame.auto_center = true

    local warning_message =
        concat {
        '[font=heading-2]You have jailed player: [color=yellow]',
        offender.name,
        '\n[/color][/font]'
    }

    local info_warning_text = inside_table.add({type = 'label', caption = warning_message})
    local info_warning_text_style = info_warning_text.style
    info_warning_text_style.single_line = false
    info_warning_text_style.width = 470
    info_warning_text_style.horizontal_align = 'center'
    info_warning_text_style.vertical_align = 'center'
    info_warning_text_style.top_padding = 4
    info_warning_text_style.left_padding = 4
    info_warning_text_style.right_padding = 4
    info_warning_text_style.bottom_padding = 4

    local abuse_message =
        concat {
        'Jailing is [color=red]NOT[/color] allowed to solve personal disputes, talk to each other instead of jailing!\n',
        'Jail is only a temporary solution, the jailed offender will be released in less than one week automatically.\n',
        'If the actions done by the offender was serious, report the offender to the admins on [color=yellow]https://getcomfy.eu/discord[/color]\n',
        'Providing NO reason will free the offender after 3 minutes or if you close this window - note - this will log your actions to our admins.\n\n',
        '[color=yellow]Explain why you jailed ' .. offender.name .. '[/color]'
    }

    local info_warning_text_extended = inside_table.add({type = 'label', caption = abuse_message})
    local info_warning_text_extended_style = info_warning_text_extended.style
    info_warning_text_extended_style.single_line = false
    info_warning_text_extended_style.font = 'heading-2'
    info_warning_text_extended_style.horizontal_align = 'center'
    info_warning_text_extended_style.vertical_align = 'center'
    info_warning_text_extended_style.top_padding = 4
    info_warning_text_extended_style.left_padding = 4
    info_warning_text_extended_style.right_padding = 4
    info_warning_text_extended_style.bottom_padding = 4

    local placeholder_text = inside_table.add({type = 'text-box', text = '', name = placeholder_jail_text_box})
    local placeholder_text_style = placeholder_text.style
    placeholder_text_style.width = 470
    placeholder_text_style.height = 200
    placeholder_text_style.vertically_stretchable = false
    placeholder_text_style.horizontally_stretchable = false
    placeholder_text_style.vertically_stretchable = false
    placeholder_text_style.horizontally_squashable = false
    placeholder_text_style.vertically_squashable = false

    local bottom_flow = main_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add({type = 'button', name = discard_button_name, caption = 'Discard report'})
    close_button.style = 'back_button'

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button = right_flow.add({type = 'button', name = save_button_name, caption = 'Save report'})
    save_button.style = 'confirm_button'

    local data = {
        offender = offender.name
    }

    Gui.set_data(placeholder_text, data)
    Gui.set_data(save_button, data)
    Gui.set_data(close_button, data)

    player.opened = main_frame
end

remove_notice = function(player)
    local screen = player.gui.screen
    local notice = screen[notice_frame_name]

    if notice and notice.valid then
        notice.destroy()
    end
end

remove_action_needed = function(player)
    local screen = player.gui.screen
    local action_needed = screen[jail_frame_name]

    if action_needed and action_needed.valid then
        action_needed.destroy()
    end
end

draw_notice_frame = function(player)
    local main_frame, inside_table = Gui.add_main_frame_with_toolbar(player, 'screen', notice_frame_name, nil, nil, 'Notice', true, 2)

    if not main_frame or not inside_table then
        return
    end

    local main_frame_style = main_frame.style
    main_frame_style.width = 400
    main_frame.auto_center = true

    local content_flow = inside_table.add {type = 'flow', direction = 'horizontal'}
    content_flow.style.top_padding = 16
    content_flow.style.bottom_padding = 16
    content_flow.style.left_padding = 24
    content_flow.style.right_padding = 24
    content_flow.style.horizontally_stretchable = false

    local sprite_flow = content_flow.add {type = 'flow'}
    sprite_flow.style.vertical_align = 'center'
    sprite_flow.style.vertically_stretchable = false

    sprite_flow.add {type = 'sprite', sprite = 'utility/warning_icon'}

    local label_flow = content_flow.add {type = 'flow'}
    label_flow.style.horizontal_align = 'left'
    label_flow.style.top_padding = 10
    label_flow.style.left_padding = 24

    local warning_message = '[font=heading-2]You have been jailed.[/font]\nPlease respond to questions if you are asked something.'

    local p_data = get_player_data(player)
    if p_data and p_data.muted then
        warning_message = '[font=heading-2]You have been jailed and muted.[/font]\nPlease seek out assistance at our discord: https://getcomfy.eu/discord.'
    end

    label_flow.style.horizontally_stretchable = false
    local label = label_flow.add {type = 'label', caption = warning_message}
    label.style.single_line = false

    player.opened = main_frame
end

--! end gui handler

local update_jailed =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value or false
        local player = data.player or 'script'
        local message = data.message
        local mute = data.mute or false
        if value then
            jail(player, key, message, nil, mute)
        else
            free(player, key)
        end
    end
)

--- Tries to get data from the webpanel and updates the local table with values.
-- @param data_set player token
function Public.try_dl_data(key)
    key = tostring(key)

    local secs = Server.get_current_time()

    if not secs then
        return
    else
        try_get_data(jailed_data_set, key, is_jailed)
    end
end

--- Tries to get data from the webpanel and updates the local table with values.
-- @param key LuaPlayer
-- @param value boolean
-- @param player LuaPlayer or <script>
-- @param message string
-- @param mute boolean
function Public.try_ul_data(key, value, player, message, mute)
    if type(key) == 'table' then
        key = key.name
    end

    key = tostring(key)

    local data = {
        key = key,
        value = value,
        player = player,
        message = message,
        mute = mute or false
    }

    Task.set_timeout_in_ticks(1, update_jailed, data)
end

--- Checks if a player exists within the table
-- @param player_name <string>
-- @return <boolean>
function Public.exists(player_name)
    return jailed[player_name] ~= nil
end

--- Prints a list of all players in the player_jailed table.
function Public.print_jailed()
    local result = {}

    for k, _ in pairs(jailed) do
        result[#result + 1] = k
    end

    local final = concat(result, ', ')
    Game.player_print(final)
end

--- Returns the table of jailed
-- @return <table>
function Public.get_jailed_table()
    return jailed
end

--- Sets a value to required_playtime_for_instant_jail
-- @param value<int>
function Public.required_playtime_for_instant_jail(value)
    if value then
        settings.playtime_for_instant_jail = value
    end
    return settings.playtime_for_instant_jail
end

--- Sets a value to set_valid_surface
-- @param value<string>
function Public.set_valid_surface(value)
    settings.valid_surface = value or 'nauvis'
    return settings.valid_surface
end

--- Sets a value to required_playtime_for_vote
-- @param value<int>
function Public.required_playtime_for_vote(value)
    if value then
        settings.playtime_for_vote = value
    end
    return settings.playtime_for_vote
end

--- Resets reset_vote_table
function Public.reset_vote_table()
    for k, _ in pairs(votejail) do
        votejail[k] = nil
    end
    for k, _ in pairs(votefree) do
        votefree[k] = nil
    end
end

--- Writes the data called back from the server into the revoked_permissions table, clearing any previous entries
local sync_revoked_permissions_callback =
    Token.register(
    function(data)
        if not data then
            return
        end
        if not data.entries then
            return
        end

        table.clear_table(revoked_permissions)
        for k, v in pairs(data.entries) do
            revoked_permissions[k] = v
        end
    end
)

--- Signals the server to retrieve the revoked_permissions dataset
function Public.sync_revoked_permissions()
    Server.try_get_all_data(revoked_permissions_set, sync_revoked_permissions_callback)
end

---
--- This toggles normal players ability to jail other players (non admins)
---@param value boolean
function Public.normies_can_jail(value)
    settings.normies_can_jail = value or false
end

---
--- Mutes a player completely from chatting
---@param player LuaPlayer
function Public.mute_player(player)
    if not player or not player.valid then
        return error('Player was not valid.')
    end

    local gulag = get_super_gulag_permission_group()
    if not gulag.players[player.index] then
        gulag.add_player(player)
        return true
    else
        gulag.remove_player(player)
        return false
    end
end

Server.on_data_set_changed(
    jailed_data_set,
    function(data)
        if not data then
            return
        end

        local v = data.value
        local k = data.key
        if v and v.actor then
            jail(v.actor, data.key, v.reason, true)
        elseif k then
            free('script', data.key)
        end
    end
)

Server.on_data_set_changed(
    revoked_permissions_set,
    function(data)
        if not data then
            return
        end

        revoked_permissions[data.key] = data.value
    end
)

commands.add_command(
    'jail',
    'Sends the player to gulag! Valid arguments are:\n/jail <LuaPlayer>',
    function()
    end
)

commands.add_command(
    'free',
    'Brings back the player from gulag.',
    function()
    end
)

commands.add_command(
    'toggle_jail_permission',
    'Usable only for admins - controls who may use jail commands!',
    function(cmd)
        local name
        local player = game.player

        if not player or not player.valid then
            name = 'Server'
        else
            name = player.name

            if not player.admin then
                return
            end
        end

        local param = cmd.parameter

        local t_player
        local revoke_reason
        local revoke_player
        local str = ''

        if not param then
            return Utils.print_to(player, 'Both player and reason is needed!')
        end

        local t = {}
        for i in string.gmatch(param, '%S+') do
            table.insert(t, i)
        end

        t_player = t[1]

        for i = 2, #t do
            str = str .. t[i] .. ' '
            revoke_reason = str
        end

        if game.get_player(t_player) then
            revoke_player = game.get_player(t_player)
        else
            return Utils.print_to(player, 'No player was provided.')
        end

        if not revoke_player then
            return
        end

        if is_revoked(revoke_player.name) then
            remove_revoked(revoke_player.name)
            Utils.print_to(player, revoke_player.name .. ' can now utilize jail commands once again!')
            return
        end

        if revoke_reason then
            if revoke_reason and string.len(revoke_reason) <= 0 then
                Utils.print_to(player, 'No valid reason was given.')
                return
            end

            if revoke_reason and string.len(revoke_reason) <= 10 then
                Utils.print_to(player, 'Reason is too short.')
                return
            end

            add_revoked(revoke_player.name, name, revoke_reason)
            Utils.print_to(player, revoke_player.name .. ' is now forbidden from utilizing jail commands!')
        else
            Utils.print_to(player, 'No message was provided')
        end
    end
)

Event.on_init(
    function()
        get_gulag_permission_group()
        create_gulag_surface()
    end
)

Event.add(
    Server.events.on_server_started,
    function()
        Public.sync_revoked_permissions()
    end
)

Event.add(
    defines.events.on_console_command,
    function(event)
        local cmd = event.command
        if not valid_commands[cmd] then
            return
        end

        local offender = event.parameters
        local message = 'Temporary jail'

        if event.player_index then
            local player = game.get_player(event.player_index)
            if not player or not player.valid then
                return
            end
            local playtime = validate_playtime(player)
            local trusted = validate_trusted(player)

            if is_revoked(player.name) then
                Utils.warning(player, module_name .. 'You have abused your trusted permissions and therefore')
                Utils.warning(player, 'your permissions have been revoked! Contact an admin to appeal this.')
                return
            end

            if not offender then
                return Utils.print_to(player, module_name .. 'Valid input: /jail ' .. player.name)
            end

            local data = {
                player = player,
                offender = offender,
                trusted = trusted,
                playtime = playtime,
                message = message,
                cmd = cmd
            }

            local success = validate_args(data)

            if not success then
                return
            end

            local delay = 30

            offender = game.get_player(offender)

            if not offender or not offender.valid then
                return
            end

            if settings.normies_can_jail and trusted and playtime >= settings.playtime_for_vote and playtime < settings.playtime_for_instant_jail and not player.admin then
                if cmd == 'jail' then
                    if not terms_tbl[player.name] then
                        Utils.warning(player, module_name .. 'Abusing the jail command will lead to revoked permissions. Jailing someone in cases of disagreement is _NEVER_ OK!')
                        Utils.warning(player, "Jailing someone because they're afk or other stupid reasons is NOT valid!")
                        Utils.warning(player, 'Run this command again to if you really want to do this!')
                        for _ = 1, 4 do
                            Task.set_timeout_in_ticks(delay, play_alert_sound, {name = player.name})
                            delay = delay + 30
                        end
                        terms_tbl[player.name] = true
                        Task.set_timeout_in_ticks(settings.clear_terms_tbl, clear_terms_tbl, {player = player.name})
                        return
                    end

                    message = message .. ' executed by ' .. player.name

                    Utils.warning(player, 'Logging your actions.')
                    vote_to_jail(player, offender, message)
                    return
                elseif cmd == 'free' then
                    vote_to_free(player, offender)
                    return
                end
            end
            if player.admin then
                if cmd == 'jail' then
                    Utils.warning(player, 'Logging your actions.')
                    message = message .. ' executed by ' .. player.name
                    Public.try_ul_data(offender, true, player.name, message)
                    return
                elseif cmd == 'free' then
                    Public.try_ul_data(offender, false, player.name)
                    return
                end
            elseif settings.normies_can_jail and playtime >= settings.playtime_for_instant_jail then
                if cmd == 'jail' then
                    if not terms_tbl[player.name] then
                        Utils.warning(player, module_name .. 'Abusing the jail command will lead to revoked permissions. Jailing someone in cases of disagreement is _NEVER_ OK!')
                        Utils.warning(player, "Jailing someone because they're afk or other stupid reasons is NOT valid!")
                        Utils.warning(player, 'Run this command again to if you really want to do this!')
                        for _ = 1, 4 do
                            Task.set_timeout_in_ticks(delay, play_alert_sound, {name = player.name})
                            delay = delay + 30
                        end
                        terms_tbl[player.name] = true
                        Task.set_timeout_in_ticks(settings.clear_terms_tbl, clear_terms_tbl, {player = player.name})
                        return
                    end

                    Utils.warning(player, 'Logging your actions.')
                    message = message .. ' executed by ' .. player.name
                    jail_temporary(player, offender, message, false)
                    draw_main_frame(player, offender)

                    return
                elseif cmd == 'free' then
                    Public.try_ul_data(offender, false, player.name)
                    return
                end
            end
        else
            if not offender then
                return print(module_name .. 'No valid player given.')
            end

            local data = {
                offender = offender,
                message = message,
                cmd = cmd
            }

            local success = validate_server_args(data)

            if not success then
                return
            end

            if game.get_player(offender) then
                offender = game.get_player(offender).name
            end

            if cmd == 'jail' then
                if not terms_tbl['script'] then
                    print(module_name .. 'Abusing the jail command will lead to revoked permissions. Jailing someone in case of disagreement is _NEVER_ OK!')
                    print(module_name .. 'Run this command again to if you really want to do this!')
                    terms_tbl['script'] = true
                    Task.set_timeout_in_ticks(settings.clear_terms_tbl, clear_terms_tbl, {player = 'script'})
                    return
                end

                print(module_name .. 'Logging your actions.')
                message = message .. ' executed by script'
                Public.try_ul_data(offender, true, 'script', message)
                return
            elseif cmd == 'free' then
                Public.try_ul_data(offender, false, 'script')
                return
            end
        end
    end
)

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        Public.try_dl_data(player.name)

        if not jailed[player.name] then
            return
        end

        local surface = game.surfaces['gulag']

        if player.surface.index ~= surface.index then
            local p_data = get_player_data(player)
            if jailed[player.name] and p_data and p_data.locked then
                teleport_player_to_gulag(player, 'jail', p_data.muted or false)
            end
        end

        local gulag = get_gulag_permission_group()
        gulag.add_player(player)

        if player.character and player.character.valid and player.character.driving then
            player.character.driving = false
        end
    end
)

Event.add(
    defines.events.on_player_changed_surface,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        if not jailed[player.name] then
            return
        end

        local surface = game.surfaces['gulag']
        if player.surface.index ~= surface.index then
            local p_data = get_player_data(player)
            if jailed[player.name] and p_data and p_data.locked then
                teleport_player_to_gulag(player, 'jail', p_data.muted or false)
                draw_notice_frame(player)
            end
        end
    end
)

Gui.on_text_changed(
    placeholder_jail_text_box,
    function(event)
        local player = event.player
        if not player or not player.valid then
            return
        end

        local textfield = event.element
        local data = Gui.get_data(textfield)

        if not data then
            return
        end

        local offender = data.offender

        if textfield and textfield.valid then
            if string.len(textfield.text) >= 2000 then
                textfield.text = ''
                return
            end
            if jailed[offender] then
                jailed[offender].reason = textfield.text
            end
        end
    end
)

Gui.on_click(
    save_button_name,
    function(event)
        local player = event.player
        if not player or not player.valid then
            return
        end

        local screen = player.gui.screen
        local frame = screen[jail_frame_name]
        local data = Gui.get_data(event.element)
        if not data then
            return
        end

        local offender = data.offender
        local date = Server.get_current_date_with_time()

        if jailed[offender] and jailed[offender].temporary then
            jailed[offender].temporary = false
        end

        if jailed[offender] and jailed[offender].reason then
            if string.len(jailed[offender].reason) <= 40 then
                return Utils.print_to(player, module_name .. 'Reason is too short. Explain thoroughly why you jailed ' .. offender .. '!')
            end

            set_data(jailed_data_set, offender, {jailed = true, actor = player.name, reason = jailed[offender].reason, date = date})
        end

        Utils.print_to(player, module_name .. 'Jail data has been submitted!')
        Utils.print_to(nil, module_name .. offender .. ' was jailed by ' .. player.name .. '.')

        local jail_data = Server.build_embed_data()
        jail_data.username = offender
        jail_data.admin = player.name
        jail_data.reason = jailed[offender].reason
        Server.to_jailed_named_embed(jail_data)

        if frame and frame.valid then
            remove_target_frame(frame)
        end
    end
)

Gui.on_click(
    discard_button_name,
    function(event)
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[jail_frame_name]
        if not player or not player.valid then
            return
        end
        local data = Gui.get_data(event.element)
        if not data then
            return
        end

        local offender = data.offender

        if jailed[offender] and jailed[offender].temporary then
            jailed[offender].temporary = false
        end

        free(player.name, offender)

        if frame and frame.valid then
            remove_target_frame(frame)
        end
    end
)

return Public
