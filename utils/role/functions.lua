local Public = require 'utils.role.table'
local Core = require 'utils.core'
local Color = require 'utils.color_presets'
local Table = require 'utils.extended_table'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Event = require 'utils.event'
local CustomEvents = require 'utils.created_events'

local insert = table.insert

local update_player_status =
    Token.register(
        function (data)
            local index = data.index
            local admin = data.admin
            local trusted = data.trusted
            local spectator = data.spectator
            local player = game.get_player(index)
            if player and player.valid then
                if trusted then
                    Event.raise(CustomEvents.events.on_player_trusted, { player_index = player.index })
                else
                    Event.raise(CustomEvents.events.on_player_untrusted, { player_index = player.index })
                end
                player.admin = admin
                player.spectator = spectator
            end
        end
    )

function Public.get_groups()
    local r = {}
    local settings = Public.get('settings')
    for _, group in pairs(settings.group) do
        r[group.name] = group
    end

    return r
end

function Public.get_role_name(role)
    local settings = Public.get('settings')
    for _, stored_role in pairs(settings.role) do
        if role == stored_role.name then
            return stored_role
        end
    end
end

function Public.get_roles()
    local r = {}
    local settings = Public.get('settings')
    for _, role in pairs(settings.role) do
        r[role.name] = role
    end

    return r
end

function Public.raise_player_role(player)
    if type(player) == 'string' then
        player = game.get_player(player)
        if not player or not player.valid then
            return
        end
    end

    local by_player_name = 'script'
    local role = Public.get_role(player)
    if not role then
        return
    end

    script.raise_event(
        Public.events.on_role_change,
        {
            tick = game.tick,
            player_index = player.index,
            by_player_name = by_player_name,
            new_role = role
        }
    )
end

function Public.give_role(player, role, by_player)
    if type(player) == 'string' then
        player = game.get_player(player)
        if not player or not player.valid then
            return
        end
    end
    local settings = Public.get('settings')
    -- local print_color = Color.warning
    local tick = game.tick
    local by_player_name = Core.is_type(by_player, 'string') and by_player or 'Script'
    local this_role = Public.get_role(role) or Public.get_role(settings.meta.default)
    local old_role = Public.get_role(player) or Public.get_role(settings.meta.default)
    -- local message = 'Roles.role-down'

    if not old_role then
        return
    end
    if not this_role then
        return
    end

    if old_role.name == this_role.name then
        return
    end

    if this_role.power < old_role.power then
        -- message = 'Roles.role-up'
        player.play_sound { path = 'utility/achievement_unlocked' }
    else
        player.play_sound { path = 'utility/game_lost' }
    end

    -- if player.online_time > 60 or by_player_name ~= 'server' then
    --     game.print({ message, player.name, this_role.name, by_player_name }, print_color)
    -- end

    -- if this_role.group.name ~= 'User' then
    --     player.print({ 'Roles.role-given', this_role.name }, print_color)
    -- end

    -- if player.tag ~= old_role.tag then
    --     player.print({ 'Roles.tag-reset' }, print_color)
    -- end

    Public.add_player_to_players_tbl(player, role)

    -- role change
    player.permission_group = game.permissions.get_group(this_role.name)
    player.tag = this_role.tag

    if old_role.group.name ~= 'Jail' then
        settings.old[player.index] = old_role.name
    end

    Task.set_timeout_in_ticks(5, update_player_status,
        {
            index = player.index,
            admin = this_role.is_admin,
            spectator = this_role.is_spectator,
            trusted = this_role
                .trusted
        })
    Task.set_timeout_in_ticks(15, update_player_status,
        {
            index = player.index,
            admin = this_role.is_admin,
            spectator = this_role.is_spectator,
            trusted = this_role
                .trusted
        })

    script.raise_event(
        Public.events.on_role_change,
        {
            tick = tick,
            player_index = player.index,
            by_player_name = by_player_name,
            new_role = this_role,
            old_role = old_role
        }
    )
end

function Public.revert(player, by_player)
    player = player or game.get_player(player)
    local settings = Public.get('settings')
    Public.give_role(player, settings.old[player.index], by_player)
end

function Public.add_player_to_players_tbl(player, level)
    local settings = Public.get('settings')
    settings.players[string.lower(player.name)] = level
end

function Public.get_player_from_players_tbl(player)
    local settings = Public.get('settings')
    return settings.players[string.lower(player.name)]
end

function Public.get_player_role(player)
    local settings = Public.get('settings')
    return Public.get_role(settings.players[string.lower(player.name)])
end

local function get_session_player(player)
    local session_storage = storage.tokens.utils_datastore_session_data
    return session_storage and session_storage.session and player and player.valid and session_storage.session[player.name] or false
end

function Public.update_role(player)
    local settings = Public.get('settings')
    local default = Public.get_role(settings.meta.default)
    local current_role = Public.get_role(player) or
        { power = -1, is_admin = false, is_spectator = false, group = { name = 'undefined' } }
    local _roles = { default }
    local online_time
    if type(player) == 'string' then
        player = game.players[player]
        if not player then
            return
        end
    end
    if not player or not player.name then
        return
    end
    if not default then
        return
    end

    local played_time = get_session_player(player)
    if played_time then
        online_time = player.online_time + played_time
    else
        online_time = player.online_time
    end

    local exists_in_players_table = Public.get_player_from_players_tbl(player)

    if player.admin and not exists_in_players_table then
        Public.add_player_to_players_tbl(player, 'Moderator')
    end
    if current_role.group.name == 'Jail' then
        return
    end
    if exists_in_players_table then
        insert(_roles, Public.get_player_role(player))
    end

    Task.set_timeout_in_ticks(15, update_player_status,
        {
            index = player.index,
            admin = current_role.is_admin,
            spectator = current_role.is_spectator,
            trusted =
                current_role.trusted
        })

    if not settings.meta.next_role_power then
        return
    end

    if current_role.power > settings.meta.next_role_power and Core.tick_to_min(online_time) > settings.meta.time_lowest then
        for _, role_name in pairs(settings.meta.next_role_name) do
            local role = Public.get_role(role_name)
            if role then
                if Core.tick_to_min(online_time) > role.time then
                    insert(_roles, role)
                end
            end
        end
    end

    local _role = current_role
    for _, role in pairs(_roles) do
        if role and role.power < _role.power or _role.power == -1 then
            _role = role
        end
    end

    if player.color ~= _role.role_color and settings.enforce_color then
        player.color = _role.role_color
    end

    if _role then
        if _role.name == default.name then
            player.tag = _role.tag
            player.permission_group = game.permissions.get_group(_role.name)
        else
            Public.give_role(player, _role, 'Script')
        end
    end
end

function Public.set_highest_power()
    local settings = Public.get('settings')
    for power, role in pairs(settings.role) do
        role.power = power
    end
end

function Public.adjust_permission()
    local settings = Public.get('settings')
    for power, role in pairs(settings.role) do
        if settings.role[power - 1] then
            Public.edit(role, 'disallow', false, settings.role[power - 1].disallow)
        end
    end
    for power = #settings.role, 1, -1 do
        local role = settings.role[power]
        Public.edit(role, 'disallow', false, role.disallow)
        if settings.role[power + 1] then
            Public.edit(role, 'allow', false, settings.role[power + 1].allow)
        end
    end
end

function Public.allowed(self, action)
    local role = Public.get_role(self)
    if not role then
        return false
    end
    return role.allow[action] or role.is_root or false
end

function Public.disallowed(self, action)
    local role = Public.get_role(self)
    if not role then
        return false
    end
    return not role.allow[action] or role.is_root or false
end

function Public.get_players(self, online)
    local players = game.permissions.get_group(self.name).players
    local r = {}
    if online then
        for _, player in pairs(players) do
            if player.connected then
                insert(r, player)
            end
        end
    else
        r = players
    end
    return r
end

--- Adds a new action to the given role.
---@param self table
---@param key any
---@param value any
---@return boolean
function Public.set_new_action(self, key, value, action)
    self = Public.get_role_name(self)
    if not self then
        return false
    end

    local settings = Public.get('settings')
    if settings.role[self.power] then
        if action == 'allow' then
            settings.role[self.power].allow[key] = value or nil
        elseif action == 'deny' then
            settings.role[self.power].deny[key] = value or nil
        end
    end
    Public.adjust_permission()
    return self
end

function Public.edit(self, key, set_value, value)
    Public.debugStr('Edited role: ' .. self.name .. '/' .. key)
    if set_value then
        self[key] = value
        return
    end
    if key == 'disallow' then
        if value ~= {} then
            self.disallow = Table.merge(self.disallow, value)
        end
    elseif key == 'allow' then
        self.allow = Table.merge(self.allow, value)
    end
    local settings = Public.get('settings')
    settings.role[self.power] = self
    return self
end

function Public.print(self)
    return log(serpent.block(self))
end

function Public.get_all_roles(player)
    player = player or game.player or game.player.name
    if not player then
        return
    end

    local settings = Public.get('settings')

    for power, role in pairs(settings.role) do
        local output = power .. ') ' .. role.name
        output = output .. ' ' .. role.tag
        local admin = 'No'
        if role.is_root then
            admin = 'Root'
        elseif role.is_admin then
            admin = 'Yes'
        end
        output = output .. ' Admin: ' .. admin
        output = output .. ' Group: ' .. role.group.name
        output = output .. ' AFK: ' .. tostring(role.base_afk_time)
        player.print(output, role.role_color)
    end
end

function Public.standard_roles(tbl)
    local settings = Public.get('settings')

    if tbl then
        local player_roles = settings.players
        for k, new_role in pairs(tbl) do
            player_roles[k] = new_role
        end
    end
end

function Public.get_group(name)
    local settings = Public.get('settings')
    for _, group in pairs(settings.group) do
        if group.name == name then
            return group
        end
    end
end

function Public.is_allowed_by_role(player)
    if not player then
        return false
    end
    local role = Public.get_role(player)
    if not role then
        return
    end
    if role.power < 0 then
        return false
    end

    if role.power <= 3 then
        return true
    else
        return false
    end
end

function Public.get_role(player)
    if not player then
        return false
    end
    local _roles = Public.get_roles()
    local settings = Public.get('settings')
    local r
    if type(player) == 'table' then
        if player.index then
            if not player.permission_group then
                r = nil
            else
                r = game.get_player(player.index) and _roles[player.permission_group.name] or nil
            end
        else
            r = player.group and player or nil
        end
    else
        local p = player and player.index and player.index or player
        r =
            game.get_player(p) and _roles[game.get_player(p).permission_group.name] or
            Table.contains(_roles, p) and Table.contains(_roles, p) or
            Table.string_contains(p, 'server') and Public.get_role(settings.meta.root) or
            Table.string_contains(p, 'root') and Public.get_role(settings.meta.root) or
            nil
    end

    return r
end

function Public.fix_roles()
    local settings = Public.get('settings')
    if not settings.meta.next_role_name then
        settings.meta.next_role_name = {}
    end

    for power, role in pairs(settings.role) do
        settings.meta.role_count = power

        if role.is_default then
            settings.meta.default = role.name
        end

        if role.is_root then
            settings.meta.root = role.name
        end

        if role.time then
            insert(settings.meta.next_role_name, role.name)
            if not settings.meta.next_role_power or power < settings.meta.next_role_power then
                settings.meta.next_role_power = power
            end
            if not settings.meta.time_lowest or role.time < settings.meta.time_lowest then
                settings.meta.time_lowest = role.time
            end
        end
    end
    return settings.meta
end

function Public.create_group(obj)
    local settings = Public.get('settings')

    Public.debugStr('Created Group: ' .. obj.name)

    if not type(obj.name) == 'string' then
        return
    end

    obj.index = #settings.group + 1
    obj.allow = obj.allow or {}
    obj.disallow = obj.disallow or {}
    insert(settings.group, obj)

    return obj
end

function Public.create_role(self, obj)
    local settings = Public.get('settings')

    if not type(obj.name) == 'string' or not type(obj.short_hand) == 'string' or not type(obj.tag) == 'string' or not type(obj.name) == 'role_color' then
        return
    end

    Public.debugStr('Created role: ' .. obj.name)
    obj.group = { name = obj.name }
    obj.allow = obj.allow or {}
    obj.disallow = obj.disallow or {}
    obj.power = obj.power and self.highest and self.highest.power + obj.power or obj.power or
        self.lowest and self.lowest.power + 1 or nil

    if obj.power then
        insert(settings.role, obj.power, obj)
    else
        insert(settings.role, obj)
    end

    Public.set_highest_power()
    if not self.highest or obj.power < self.highest.power then
        self.highest = { name = obj.name, power = obj.power }
    end
    if not self.lowest or obj.power > self.lowest.power then
        self.lowest = { name = obj.name, power = obj.power }
    end
    return self
end

function Public.set_roles_on_init()
    local Groups = Public.get_groups()

    Public.create_role(
        Groups['Root'],
        {
            name = 'Overlord',
            short_hand = 'Overlord',
            tag = '',
            time = nil,
            role_color = { r = 142, g = 194, b = 40 },
            disallow = {},
            is_admin = true,
            is_spectator = true,
            base_afk_time = false,
            trusted = true
        }
    )

    Public.create_role(
        Groups['Admin'],
        {
            name = 'Moderator',
            short_hand = 'Mod',
            tag = '',
            role_color = { r = 0, g = 170, b = 0 },
            disallow = {},
            is_admin = false,
            is_spectator = true,
            base_afk_time = false,
            trusted = true
        }
    )

    Public.edit(
        Public.get_role_name('Overlord'),
        'allow',
        false,
        {
            ['debugger'] = true,
            ['surface_resource'] = true,
            ['surface_darkness'] = true,
            ['autofill_chests'] = true,
            ['infinity_chest'] = true,
            ['infinity_storage'] = true,
            ['render_beam'] = true,
            ['game-settings'] = true,
            ['warp-override'] = true,
            ['bonus-override'] = true,
            ['ic-override'] = true,
            ['always-warp'] = true,
            ['admin-items'] = true,
            ['admin-commands'] = true,
            ['interface'] = true,
            ['warp-list'] = true,
            ['pregen_map'] = true,
            ['dump_layout'] = true,
            ['creative'] = true,
            ['delete_uncharted_chunks'] = true,
            ['remove_chunks'] = true
        }
    )

    Public.edit(
        Public.get_role_name('Moderator'),
        'allow',
        false,
        {
            ['repair'] = true,
            ['spaghetti'] = true,
            ['config-management'] = true
        }
    )

    Public.edit(
        Public.get_role_name('Expert'),
        'allow',
        false,
        {
            ['unlimited-radars'] = true,
            ['bonus-ore-x4'] = true,
            ['bonus-respawn'] = true,
            ['poll'] = true,
            ['personal_hidden_dimension'] = true,
            ['instant_hd_unlock'] = true
        }
    )

    Public.edit(
        Public.get_role_name('Professional'),
        'allow',
        false,
        {
            ['tree-decon'] = true,
            ['circle_square'] = true,
            ['layout_square'] = true
        }
    )

    Public.edit(
        Public.get_role_name('Talented'),
        'allow',
        false,
        {
            ['bonus-ore-x3'] = true
        }
    )

    Public.edit(
        Public.get_role_name('Seasoned'),
        'allow',
        false,
        {
            ['modular_armor'] = true
        }
    )

    Public.edit(
        Public.get_role_name('Experienced'),
        'allow',
        false,
        {
            ['bonus-ore-x2'] = true,
            ['bonus'] = true,
            ['create-warp'] = true,
            ['remove-warp'] = true,
            ['clear-corpses'] = true,
            ['portable-chest'] = true
        }
    )

    Public.edit(
        Public.get_role_name('Apprentice'),
        'allow',
        false,
        {
            ['show-warp'] = true,
            ['bonus-limit'] = true,
            ['rpg'] = true
        }
    )

    Public.edit(
        Public.get_role_name('Rookie'),
        'allow',
        false,
        {
            ['global-chat'] = true,
            ['main_button'] = true
        }
    )
end

function Public.set_permissions_on_init()
    local root =
        Public.create_group
        {
            name = 'Root',
            disallow = {}
        }
    local admin =
        Public.create_group
        {
            name = 'Admin',
            allow = {},
            disallow =
            {
                'edit_permission_group',
                'delete_permission_group',
                'add_permission_group'
            }
        }
    local trusted =
        Public.create_group
        {
            name = 'Trusted',
            allow = {},
            disallow =
            {
                'edit_permission_group',
                'delete_permission_group',
                'add_permission_group'
            }
        }
    local user =
        Public.create_group
        {
            name = 'User',
            allow = {},
            disallow =
            {
                'edit_permission_group',
                'delete_permission_group',
                'add_permission_group'
            }
        }
    local jail =
        Public.create_group
        {
            name = 'Jail',
            allow = {},
            disallow =
            {
                'edit_permission_group',
                'delete_permission_group',
                'add_permission_group',
                'open_character_gui',
                'begin_mining',
                'start_walking',
                'open_blueprint_library_gui',
                'use_item',
                'select_item',
                'rotate_entity',
                'select_blueprint_entities',
                'open_train_gui',
                'open_train_station_gui',
                'open_gui',
                'open_item',
                'deconstruct',
                'build_rail',
                'cancel_research',
                'start_research',
                'set_train_stopped',
                'select_next_valid_gun',
                'open_technology_gui',
                'open_trains_gui',
                'edit_custom_tag',
                'craft',
                'setup_assembling_machine'
            }
        }

    Public.create_role(
        root,
        {
            name = 'Root',
            short_hand = 'Root',
            tag = '',
            power = 1,
            role_color = Color.white,
            is_root = true,
            is_admin = true,
            is_spectator = true,
            base_afk_time = false,
            trusted = true
        }
    )

    Public.create_role(
        admin,
        {
            name = 'Admin',
            short_hand = 'Admin',
            tag = '',
            role_color = { r = 233, g = 63, b = 233 },
            is_admin = true,
            is_spectator = true,
            base_afk_time = false,
            trusted = true
        }
    )

    Public.create_role(
        trusted,
        {
            name = 'Expert',
            short_hand = 'Expert',
            tag = '',
            time = 6000,
            role_color = Color.dark_blue,
            base_afk_time = 360,
            trusted = true
        }
    )

    Public.create_role(
        trusted,
        {
            name = 'Professional',
            short_hand = 'Professional',
            tag = '',
            time = 2500,
            role_color = Color.purple,
            base_afk_time = 190,
            trusted = true
        }
    )

    Public.create_role(
        trusted,
        {
            name = 'Talented',
            short_hand = 'Talented',
            tag = '',
            time = 2000,
            role_color = Color.red,
            base_afk_time = 190,
            trusted = true
        }
    )

    Public.create_role(
        trusted,
        {
            name = 'Seasoned',
            short_hand = 'Seasoned',
            tag = '',
            time = 1500,
            role_color = Color.blue,
            base_afk_time = 190,
            trusted = true
        }
    )

    Public.create_role(
        trusted,
        {
            name = 'Experienced',
            short_hand = 'Experienced',
            tag = '',
            time = 300,
            role_color = Color.pink,
            base_afk_time = 120,
            trusted = true
        }
    )

    Public.create_role(
        trusted,
        {
            name = 'Apprentice',
            short_hand = 'Apprentice',
            tag = '',
            time = 50,
            role_color = Color.green,
            base_afk_time = 60,
            trusted = true
        }
    )

    Public.create_role(
        user,
        {
            name = 'Rookie',
            short_hand = '',
            tag = '',
            role_color = Color.white,
            is_default = true,
            disallow =
            {
                'build_terrain',
                'remove_cables',
                'launch_rocket',
                'reset_assembling_machine',
                'cancel_research'
            },
            base_afk_time = 30
        }
    )

    Public.create_role(
        jail,
        {
            name = 'Jail',
            short_hand = 'Jail',
            tag = '[Jail]',
            role_color = { r = 50, g = 50, b = 50 },
            disallow = {},
            base_afk_time = false
        }
    )
end

Public.promote = Public.give_role
Public.demote = Public.give_role

return Public
