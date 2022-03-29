local Global = require 'utils.global'
local Session = require 'utils.datastore.session_data'
local Game = require 'utils.game'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Utils = require 'utils.core'
local table = require 'utils.table'

local jailed_data_set = 'jailed'
local revoked_permissions_set = 'revoked_permissions_jailed'
local jailed = {}
local player_data = {}
local terms_tbl = {}
local votejail = {}
local votefree = {}
local revoked_permissions = {}
local settings = {
    playtime_for_vote = 25920000, -- 5 days
    playtime_for_instant_jail = 103680000, -- 20 days
    clear_voted_player = 36000, -- remove player from vote-tbl after 10 minutes
    clear_terms_tbl = 3600,
    votejail_count = 5,
    valid_surface = 'nauvis'
}

local set_data = Server.set_data
local try_get_data = Server.try_get_data
local concat = table.concat

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
        if not revoked_permissions[name] then
            revoked_permissions[name] = true
            set_data(revoked_permissions_set, name, {revoked = true, actor = admin, reason = reason})
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
        local griefer = data.griefer
        if not griefer then
            return
        end
        if votejail[griefer] and votejail[griefer].jailed then
            return
        end

        local msg_two = 'You have been cleared of all accusations because not enough players voted against you.'
        Utils.print_to(griefer, msg_two)
        votejail[griefer] = nil
        votefree[griefer] = nil
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
            gulag.set_allows_action(defines.input_action[action_name], false)
        end
        gulag.set_allows_action(defines.input_action.write_to_console, true)
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

local function teleport_player_to_gulag(player, action)
    local p_data = get_player_data(player)

    if action == 'jail' then
        local gulag = game.surfaces['gulag']
        if p_data and not p_data.locked then
            p_data.fallback_surface_index = player.surface.index
            p_data.position = player.position
            p_data.p_group_id = player.permission_group.group_id
            p_data.locked = true
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
        p_group.add_player(player)
        local pos = {x = p.x, y = p.y}
        local get_tile = surface.get_tile(pos)
        if get_tile.valid and get_tile.name == 'out-of-map' then
            player.teleport(surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 128, 1), surface.name)
        else
            player.teleport(surface.find_non_colliding_position('character', p, 128, 1), surface.name)
        end

        get_player_data(player, true)
    end
end

local function validate_args(data)
    local player = data.player
    local griefer = data.griefer
    local trusted = data.trusted
    local playtime = data.playtime
    local message = data.message
    local cmd = data.cmd

    if not griefer then
        return
    end

    if not type(griefer) == 'string' then
        Utils.print_to(player, 'Invalid name.')
        return false
    end

    local get_griefer_player = game.get_player(griefer)

    if not validate_entity(get_griefer_player) then
        Utils.print_to(player, 'Invalid name.')
        return false
    end

    if not griefer or not get_griefer_player then
        Utils.print_to(player, 'Invalid name.')
        return false
    end

    if votejail[player.name] and not player.admin then
        Utils.print_to(player, 'You are currently being investigated since you have griefed.')
        return false
    end

    if votefree[player.name] and not player.admin then
        Utils.print_to(player, 'You are currently being investigated since you have griefed.')
        return false
    end

    if jailed[player.name] and not player.admin then
        Utils.print_to(player, 'You are jailed, you can´t run this command.')
        return false
    end

    if player.name == griefer and not player.admin then
        Utils.print_to(player, 'You can´t select yourself.')
        return false
    end

    if get_griefer_player.admin and not player.admin then
        Utils.print_to(player, 'You can´t select an admin.')
        return false
    end

    if not trusted and not player.admin or playtime <= settings.playtime_for_vote and not player.admin then
        Utils.print_to(player, 'You are not trusted enough to run this command.')
        return false
    end

    if not message then
        Utils.print_to(player, 'No valid reason was given.')
        return false
    end

    if cmd == 'jail' and message and string.len(message) <= 0 then
        Utils.print_to(player, 'No valid reason was given.')
        return false
    end

    if cmd == 'jail' and message and string.len(message) <= 10 then
        Utils.print_to(player, 'Reason is too short.')
        return false
    end

    return true
end

local function vote_to_jail(player, griefer, msg)
    if not griefer then
        return
    end

    if type(griefer) == 'table' then
        griefer = griefer.name
    end

    if not votejail[griefer] then
        votejail[griefer] = {index = 0, actor = player.name}
        local message = player.name .. ' has started a vote to jail player ' .. griefer
        Utils.print_to(nil, message)
        Task.set_timeout_in_ticks(settings.clear_voted_player, clear_jail_data_token, {griefer = griefer})
    end

    if not votejail[griefer][player.name] then
        votejail[griefer][player.name] = true
        votejail[griefer].index = votejail[griefer].index + 1
        Utils.print_to(player, 'You have voted to jail player ' .. griefer .. '.')
        if
            votejail[griefer].index >= settings.votejail_count or
                (votejail[griefer].index == #game.connected_players - 1 and #game.connected_players > votejail[griefer].index)
         then
            Public.try_ul_data(griefer, true, votejail[griefer].actor, msg)
        end
    else
        Utils.print_to(player, 'You have already voted to kick ' .. griefer .. '.')
    end
end

local function vote_to_free(player, griefer)
    if not griefer then
        return
    end

    if type(griefer) == 'table' then
        griefer = griefer.name
    end

    if not votefree[griefer] then
        votefree[griefer] = {index = 0, actor = player.name}
        local message = player.name .. ' has started a vote to free player ' .. griefer
        Utils.print_to(nil, message)
    end

    if not votefree[griefer][player.name] then
        votefree[griefer][player.name] = true
        votefree[griefer].index = votefree[griefer].index + 1

        Utils.print_to(player, 'You have voted to free player ' .. griefer .. '.')
        if
            votefree[griefer].index >= settings.votejail_count or
                (votefree[griefer].index == #game.connected_players - 1 and #game.connected_players > votefree[griefer].index)
         then
            Public.try_ul_data(griefer, false, votefree[griefer].actor)
            votejail[griefer] = nil
            votefree[griefer] = nil
        end
    else
        Utils.print_to(player, 'You have already voted to free ' .. griefer .. '.')
    end
    return
end

local function jail(player, griefer, msg, raised)
    player = player or 'script'

    if jailed[griefer] then
        return false
    end

    if not msg then
        return
    end

    if not game.get_player(griefer) then
        return
    end

    local to_jail_player = game.get_player(griefer)

    teleport_player_to_gulag(to_jail_player, 'jail')

    local gulag = get_gulag_permission_group()
    gulag.add_player(griefer)

    local message = griefer .. ' has been jailed by ' .. player .. '. Cause: ' .. msg

    if to_jail_player.character and to_jail_player.character.valid and to_jail_player.character.driving then
        to_jail_player.character.driving = false
    end

    jailed[griefer] = {jailed = true, actor = player, reason = msg}
    if not raised then
        set_data(jailed_data_set, griefer, {jailed = true, actor = player, reason = msg})
    end

    Utils.print_to(nil, message)
    local data = Server.build_embed_data()
    data.username = griefer
    data.admin = player
    data.reason = msg
    Server.to_jailed_embed(data)

    if votejail[griefer] then
        votejail[griefer].jailed = true
    end

    to_jail_player.clear_console()
    Utils.print_to(griefer, message)
    return true
end

local function free(player, griefer)
    player = player or 'script'
    if not jailed[griefer] then
        return false
    end

    if not game.get_player(griefer) then
        return
    end

    local to_jail_player = game.get_player(griefer)
    teleport_player_to_gulag(to_jail_player, 'free')

    local message = griefer .. ' was set free from jail by ' .. player .. '.'

    set_data(jailed_data_set, griefer, nil)

    Utils.print_to(nil, message)
    local data = Server.build_embed_data()
    data.username = griefer
    data.admin = player
    Server.to_unjailed_embed(data)
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

local update_jailed =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value or false
        local player = data.player or 'script'
        local message = data.message
        if value then
            jail(player, key, message)
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
-- @param data_set player token
function Public.try_ul_data(key, value, player, message)
    if type(key) == 'table' then
        key = key.name
    end

    key = tostring(key)

    local data = {
        key = key,
        value = value,
        player = player,
        message = message
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

    result = concat(result, ', ')
    Game.player_print(result)
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

Server.on_data_set_changed(
    jailed_data_set,
    function(data)
        if not data then
            return
        end

        local v = data.value
        if v and v.actor then
            if v.jailed then
                jail(v.actor, data.key, v.reason, true)
            elseif not v.jailed then
                free('script', data.key)
            end
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
    'Sends the player to gulag! Valid arguments are:\n/jail <LuaPlayer> <reason>',
    function()
        return
    end
)

commands.add_command(
    'free',
    'Brings back the player from gulag.',
    function()
        return
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

        local param = event.parameters

        if event.player_index then
            local player = game.get_player(event.player_index)
            local playtime = validate_playtime(player)
            local trusted = validate_trusted(player)

            if is_revoked(player.name) then
                Utils.warning(player, 'You have abused your trusted permissions and therefore')
                Utils.warning(player, 'your permissions have been revoked!')
                return
            end

            if not param then
                return Utils.print_to(player, 'No valid reason given.')
            end

            local message
            local t = {}

            for i in string.gmatch(param, '%S+') do
                t[#t + 1] = i
            end

            local griefer = t[1]
            table.remove(t, 1)

            message = concat(t, ' ')

            local data = {
                player = player,
                griefer = griefer,
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

            if game.get_player(griefer) then
                griefer = game.get_player(griefer).name
            end

            if trusted and playtime >= settings.playtime_for_vote and playtime < settings.playtime_for_instant_jail and not player.admin then
                if cmd == 'jail' then
                    if not terms_tbl[player.name] then
                        Utils.warning(
                            player,
                            'Abusing the jail command will lead to revoked permissions. Jailing someone in case of disagreement is _NEVER_ OK!'
                        )
                        Utils.warning(player, "Jailing someone because they're afk or other stupid reasons is NOT valid!")
                        Utils.warning(player, 'Run this command again to if you really want to do this!')
                        for i = 1, 4 do
                            Task.set_timeout_in_ticks(delay, play_alert_sound, {name = player.name})
                            delay = delay + 30
                        end
                        terms_tbl[player.name] = true
                        Task.set_timeout_in_ticks(settings.clear_terms_tbl, clear_terms_tbl, {player = player.name})
                        return
                    end
                    Utils.warning(player, 'Logging your actions.')
                    vote_to_jail(player, griefer, message)
                    return
                elseif cmd == 'free' then
                    vote_to_free(player, griefer)
                    return
                end
            end

            if player.admin or playtime >= settings.playtime_for_instant_jail then
                if cmd == 'jail' then
                    if not terms_tbl[player.name] then
                        Utils.warning(
                            player,
                            'Abusing the jail command will lead to revoked permissions. Jailing someone in case of disagreement is _NEVER_ OK!'
                        )
                        Utils.warning(player, 'Run this command again to if you really want to do this!')
                        for i = 1, 4 do
                            Task.set_timeout_in_ticks(delay, play_alert_sound, {name = player.name})
                            delay = delay + 30
                        end
                        terms_tbl[player.name] = true
                        Task.set_timeout_in_ticks(settings.clear_terms_tbl, clear_terms_tbl, {player = player.name})
                        return
                    end
                    Utils.warning(player, 'Logging your actions.')
                    Public.try_ul_data(griefer, true, player.name, message)
                    return
                elseif cmd == 'free' then
                    Public.try_ul_data(griefer, false, player.name)
                    return
                end
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
                teleport_player_to_gulag(player, 'jail')
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
                teleport_player_to_gulag(player, 'jail')
            end
        end
    end
)

return Public
