---@diagnostic disable: deprecated
--luacheck: ignore 561
local Global = require 'utils.global'
local Core = require 'utils.core'
local Supporters = require 'utils.datastore.supporters'
local Task = require 'utils.task_token'
local Server = require 'utils.server'
local SessionData = require 'utils.datastore.session_data'

---@class CommandData
---@field name string
---@field help string
---@field aliases table
---@field parameters table
---@field parameters_count number
---@field parameters_required number
---@field check_server boolean
---@field check_backend boolean
---@field check_offline_mode boolean
---@field check_admin boolean
---@field check_supporter boolean
---@field check_role string[]
---@field skip_param boolean
---@field check_trusted boolean
---@field check_playtime number
---@field callback function
---@field validate_self boolean
---@field validated_command boolean
---@field validate_activated boolean
---@field command_activated boolean

local this =
{
    commands = {}
}
local trace = debug.traceback

local output =
{
    backend_is_required = 'No backend is currently available. Please try again later.',
    server_is_required = 'This command requires to be run from the server.',
    offline_mode_is_required = 'This command requires the server to be in offline mode to run.',
    admin_is_required = 'This command requires admin permissions to run.',
    supporter_is_required = 'This command requires supporter permissions to run.',
    trusted_is_required = 'This command requires trusted permissions to run.',
    playtime_is_required = 'This command requires a minimum playtime of %s to run.',
    param_is_required = 'This command requires a parameter to run.',
    command_failed = 'Command failed to run.',
    command_success = 'Command ran successfully.',
    role_is_required = 'This command requires the player to have the %s role to run.',
    command_needs_validation =
    'This command requires validation to run. Please re-run the command if you wish to proceed.',
    command_needs_custom_validation =
    'This command requires validation to run. %s - please re-run the command if you wish to proceed.',
    command_is_active = 'This command is already active.',
    command_is_inactive = 'This command is already inactive.'
}

local validate_types =
{
    ['string'] = true,
    ['number'] = true,
    ['integer'] = true,
    ['boolean'] = true,
    ['player'] = true,
    ['player-online'] = true,
    ['position'] = true,
    ['player-admin'] = true,
    ['server'] = true,
    ['surface'] = true,
    ['any'] = true
}

local check_boolean =
{
    ['true'] = true,
    ['false'] = true
}

---@class MetaCommand
local Public = {}

Public.metatable = { __index = Public }

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

script.register_metatable('CommandData', Public.metatable)

local function conv(v)
    if tonumber(v) then
        return tonumber(v)
    end

    return v
end

local handlers = {}

handlers["player"] = function (param)
    local p = game.get_player(param)
    if not p then return nil, "Player was not found." end
    return p
end

handlers["player-online"] = function (param)
    local p = game.get_player(param)
    if not p or not p.valid then return nil, "Player was not found." end
    if not p.connected then return nil, "Player is not online." end
    return p
end

handlers["player-admin"] = function (param)
    local p = game.get_player(param)
    if not p or not p.valid then return nil, "Player was not found." end
    if not p.admin then return nil, "Player is not an admin." end
    return p
end

handlers["surface"] = function (param)
    if type(param) ~= "string" then
        return nil, 'Inputted value is not of type string. Valid values are: "string"'
    end

    local s = game.get_surface(param)
    if not s then return nil, "Surface was not found." end
    return s
end

handlers["position"] = function (param)
    local func = load("return " .. param, "command_param", "t", {})
    local pos = func and func()

    if type(pos) ~= "table" then
        return nil, "Inputted value is not of type table. Valid values are: { x = 0, y = 0 }"
    end

    if not pos.x or not pos.y then
        return nil, "Inputted value is not of type position. Valid values are: { x = 0, y = 0 }"
    end

    return pos
end

handlers["server"] = function (param)
    local p = game.get_player(param)
    if p and p.valid then
        return nil, "Not running from server."
    end
    return param
end

handlers["number"] = function (param)
    local n = tonumber(param)
    if not n then
        return nil, "Inputted value is not of type number. Valid values are: 1, 2, 3, etc."
    end
    return n
end

handlers["integer"] = handlers["number"]

handlers["string"] = function (param)
    if type(param) ~= "string" then
        return nil, 'Inputted value is not of type string. Valid values are: "string"'
    end
    return param
end

handlers["any"] = function (param)
    return param
end

handlers["boolean"] = function (param)
    if not check_boolean[param] then
        return nil, "Inputted value is not of type boolean. Valid values are: true, false."
    end
    return param == "true"
end

--- Handles errors.
---@param message string
---@param notify_sound string
local function handle_error(message, notify_sound)
    message = message or ''
    Core.output_message('Command failed: ' .. message, 'warning')
    if notify_sound then
        notify_sound = notify_sound or 'utility/wire_pickup'
        if game.player then
            game.player.play_sound { path = notify_sound }
        end
    end
end

--- Handles internal errors.
---@param has_run boolean
---@param name string
---@param message string
---@return boolean
local function internal_error(has_run, name, message)
    if not has_run then
        handle_error('Action has been logged!', 'utility/cannot_build')
        if type(message) == 'string' then
            Server.output_script_data('[ERROR] Command failed to run: ' .. name .. ' - ' .. message)
        else
            Server.output_script_data('[ERROR] Command failed to run: ' .. name)
        end
    end
    return not has_run
end

local function parseCommandArguments(input, command_data)
    local skip_param = command_data.skip_param or false
    if skip_param then
        return input
    end

    local tokens = {}
    local i = 1
    if input == nil then
        return tokens
    end
    local len = #input

    while i <= len do
        local s, e = input:find("^%s+", i)
        if s then
            i = e + 1
        else
            local char = input:sub(i, i)

            if char == '"' then
                local j = i + 1
                local buffer = {}

                while j <= len do
                    local c = input:sub(j, j)

                    if c == '"' then break end

                    if c == "\\" then
                        j = j + 1
                        c = input:sub(j, j)
                    end

                    table.insert(buffer, c)
                    j = j + 1
                end

                table.insert(tokens, table.concat(buffer))
                i = j + 1
            elseif char == '{' then
                local depth = 1
                local j = i + 1
                local buffer = { "{" }

                while j <= len and depth > 0 do
                    local c = input:sub(j, j)

                    if c == '{' then depth = depth + 1 end
                    if c == '}' then depth = depth - 1 end

                    table.insert(buffer, c)
                    j = j + 1
                end

                table.insert(tokens, table.concat(buffer))
                i = j
            else
                local j = i
                local buffer = {}

                while j <= len and not input:sub(j, j):match("%s") do
                    table.insert(buffer, input:sub(j, j))
                    j = j + 1
                end

                table.insert(tokens, table.concat(buffer))
                i = j
            end
        end
    end

    local max = command_data.parameters_count

    if not max then
        return tokens
    end

    if #tokens == max then
        return tokens
    end

    if #tokens < max then
        return tokens
    end

    if command_data.catch_all_last then
        local result = {}

        for index = 1, max - 1 do
            result[index] = tokens[index]
        end

        result[max] = table.concat(tokens, " ", max)

        return result
    end

    return tokens
end

---@param event EventData.on_console_command
local function execute(event)
    local command_data = this.commands[event.name] --[[@as CommandData]]

    local player
    if event.player_index and event.player_index > 0 then
        player = game.get_player(event.player_index)
    else
        player =
        {
            name = '<server>',
            position = { x = 0, y = 0 },
            surface = game.get_surface('nauvis'),
            force = game.forces.player,
            print = Server.output_script_data
        }
    end

    local is_server = event.player_index == nil

    local function reject(error_message)
        error_message = error_message or ''
        command_data.validated_command = false
        return handle_error(error_message, 'utility/cannot_build')
    end

    -- Check if player and return
    local check_server = command_data.check_server or false
    if (check_server and not is_server) and player and player.valid then
        reject(output.server_is_required)
        return
    end

    -- Check if player and return
    local check_backend = command_data.check_backend or false
    if (check_backend and not is_server) and event.player_index then
        if not Server.get_current_time() then
            reject(output.backend_is_required)
            return
        end
    end

    -- Check if the server is in offline mode and if the command requires it
    local check_offline_mode = command_data.check_offline_mode or false
    if (check_offline_mode and not is_server) and game.is_multiplayer() then
        reject(output.offline_mode_is_required)
        return
    end

    -- Check if the player is an admin and if the command requires it
    local check_admin = command_data.check_admin or false
    if (check_admin and not is_server) and player and not player.admin then
        reject(output.admin_is_required)
        return
    end

    -- Check if the player is trusted and if the command requires it
    local check_trusted = command_data.check_trusted or false
    if (check_trusted and not is_server) and Core.validate_player(player) then
        local is_trusted = SessionData.get_trusted_player(player)
        if not is_trusted then
            reject(output.trusted_is_required)
            return
        end
    end

    -- Check if the player is a supporter and if the command requires it
    local check_supporter = command_data.check_supporter or false
    if (check_supporter and not is_server) and Core.validate_player(player) then
        local is_supporter = Supporters.is_supporter(player.name)
        if not is_supporter then
            reject(output.supporter_is_required)
            return
        end
    end

    -- Check if the player has the required role and if the command requires it
    local check_role = command_data.check_role or false
    if check_role then
        local has_roles = false
        for _, role in pairs(check_role) do
            if SessionData.allowed(player, role) then
                has_roles = true
                break
            end
        end

        if not has_roles then
            reject(string.format(output.role_is_required, table.concat(check_role, ', ')))
            return
        end
    end

    -- Check if the player has the required playtime and if the command requires it
    local check_playtime = command_data.check_playtime or false
    if (check_playtime and not is_server) and Core.validate_player(player) then
        local playtime = SessionData.get_session_player(player)
        if not playtime then
            reject(string.format(output.playtime_is_required, Core.get_formatted_playtime(check_playtime)))
            return
        end

        if playtime < check_playtime then
            reject(string.format(output.playtime_is_required, Core.get_formatted_playtime(check_playtime)))
            return
        end
    end

    -- Check for parameters
    if command_data.parameters_required > 0 and not event.parameter then
        reject(output.param_is_required)
        return
    end

    local is_multiplayer = game.is_multiplayer()

    -- Check if the command requires the player to validate the command
    local validate_self = command_data.validate_self or false
    if validate_self and not command_data.validated_command and is_multiplayer then
        command_data.validated_command = true
        if command_data.custom_message then
            handle_error(string.format(output.command_needs_custom_validation, command_data.custom_message),
                'utility/cannot_build')
        else
            handle_error(output.command_needs_validation, 'utility/cannot_build')
        end
        return
    end

    local parameters = parseCommandArguments(event.parameter, command_data)

    -- Check the param count
    local parameters_count = #parameters
    if parameters_count < command_data.parameters_required then
        reject(output.param_is_required)
        return
    end

    -- Parse the arguments
    local handled_parameters = {}

    local index_count = 1
    for _, param_data in pairs(command_data.parameters) do
        if param_data.as_type then
            local handler = handlers[param_data.as_type]

            if not handler then
                return reject("Unknown parameter type: " .. param_data.as_type)
            end

            local param = conv(parameters[index_count])
            local value, err = handler(param)

            if err and not param_data.optional and param == nil then
                return reject(err)
            elseif err and param_data.optional and param ~= nil then
                return reject(err)
            end

            table.insert(handled_parameters, value)
            index_count = index_count + 1
        end
    end

    -- Run the command callback if everything is validated
    local callback = Task.get(command_data.callback)
    local success, err
    if not command_data.skip_param then
        success, err = pcall(callback, player, unpack(handled_parameters))
    else
        success, err = pcall(callback, player, event.parameter)
    end
    if internal_error(success, command_data.name, err) then
        return reject(output.command_failed)
    end

    -- Check if the command can only be run once
    local validate_activated = command_data.validate_activated or false
    if validate_activated then
        if not command_data.command_activated then
            command_data.command_activated = true
        else
            command_data.command_activated = false
        end
    end

    command_data.validated_command = false

    if err ~= nil then
        if type(err) == 'boolean' then
            if err == false then
                Core.output_message(output.command_failed, 'warning')
            else
                Core.output_message(output.command_success, 'success')
            end
        else
            Core.output_message(err)
        end
    else
        Core.output_message(output.command_success, 'success')
    end
end

--- Creates a new command.
---@param name string
---@param help string
---@return MetaCommand
function Public.new(name, help)
    if this.commands[name] then
        error('Command already exists: ' .. name, 2)
    end

    if game then error('Cannot run new() when game is initialized : ' .. name, 2) end

    local command =
        setmetatable(
            {
                name = name,
                help = help,
                aliases = {},
                parameters = {},
                parameters_count = 0,
                parameters_required = 0,
                check_admin = false,
                check_server = false,
                check_backend = false,
                check_supporter = false,
                check_trusted = false,
                check_playtime = false,
                validate_self = false,
                validated_command = false
            },
            Public.metatable
        )

    this.commands[name] = command

    return command
end

--- Requires the player to validate the command before running it.
---@param custom_message? string
---@return MetaCommand
function Public:require_validation(custom_message)
    self.validate_self = true
    if custom_message then
        self.custom_message = custom_message
    end

    return self
end

--- Requires the player to validate the command before running it.
---@return MetaCommand
function Public:is_activated()
    self.validate_activated = true
    return self
end

--- Requires the player to be an admin to run the command.
---@return MetaCommand
function Public:require_admin()
    self.check_admin = true
    return self
end

---@return MetaCommand
function Public:require_server()
    self.check_server = true
    return self
end

--- Requires that the server is connected to a backend
---@return MetaCommand
function Public:require_backend()
    self.check_backend = true
    return self
end

--- Requires that the server is in offline mode
---@return MetaCommand
function Public:require_offline_mode()
    self.check_offline_mode = true
    return self
end

--- Requires the player to be a supporter to run the command.
---@return MetaCommand
function Public:require_supporter()
    self.check_supporter = true
    return self
end

--- Requires the player to be trusted to run the command.
---@return MetaCommand
function Public:require_trusted()
    self.check_trusted = true
    return self
end

--- Requires the player to have a minimum role to run the command.
---@param role_name string
---@return MetaCommand
function Public:require_role(role_name)
    if not self.check_role then
        self.check_role = {}
    end

    table.insert(self.check_role, role_name)
    return self
end

--- Skips the param validation/extraction process.
---@return MetaCommand
function Public:skip_param_validation()
    self.skip_param = true
    return self
end

--- Requires the player to have a minimum playtime to run the command.
---@param playtime integer|number
---@return MetaCommand
function Public:require_playtime(playtime)
    self.check_playtime = playtime or nil
    return self
end

---@alias ParamName
---| '"string"'
---| '"number"'
---| '"integer"'
---| '"boolean"'
---| '"player"'
---| '"player-online"'
---| '"player-admin"'
---| '"server"'
---| '"surface"'
---| '"position"'
---| '"any"'

--- Adds a parameter to the command.
---@param name string
---@param optional boolean
---@param as_type? ParamName
---@return MetaCommand
function Public:add_parameter(name, optional, as_type)
    if not validate_types[as_type] then
        error('Invalid type: ' .. as_type .. ' for parameter: ' .. name, 2)
    end

    if self.parameters[name] then
        error('Parameter: ' .. name .. ' already exists for command: ' .. self.name, 2)
    end

    self.parameters[name] = { optional = optional, as_type = as_type }
    self.parameters_count = self.parameters_count + 1

    if not optional then
        self.parameters_required = self.parameters_required + 1
    end

    return self
end

--- Adds an alias to the command.
---@param name string
---@return MetaCommand
function Public:add_alias(name)
    if self.aliases[name] then
        error('Alias: ' .. name .. ' already exists for command: ' .. self.name, 2)
    end

    self.aliases[name] = name

    return self
end

--- Sets the command as default if marking paramaters as optional.
---@param defaults any
---@return MetaCommand
function Public:set_default(defaults)
    for name, value in pairs(defaults) do
        if self.parameters[name] then
            self.parameters[name].default = value
        end
    end
    return self
end

--- Restores the command_activated state for each command
function Public.restore_states()
    for _, command in pairs(this.commands) do
        command.validated_command = false
        command.command_activated = false
    end
end

--- Registers the command to the game. Will return the player/server and the args as separate arguments.
---@param func function
function Public:callback(func)
    -- Generates a description to be used
    local description = ''
    for param_name, param_details in pairs(self.parameters) do
        if param_details.optional then
            description = string.format('%s [%s]', description, param_name)
        else
            description = string.format('%s <%s>', description, param_name)
        end
    end
    self.description = description

    -- If command fails to run, notify the player/server
    local function command_error(err)
        internal_error(false, self.name, trace(err))
    end

    -- Registers the command as a token
    local id = Task.register(func)
    self.callback = id

    -- Callback
    local function command_callback(event)
        event.name = self.name
        xpcall(execute, command_error, event)
    end

    -- Lastly, adds the command to the game
    local help = description .. ' - ' .. self.help
    commands.add_command(self.name, help, command_callback)

    -- Adds any aliases if any
    for _, alias in pairs(self.aliases) do
        if not commands.commands[alias] and not commands.game_commands[alias] then
            commands.add_command(alias, help, command_callback)
        end
    end
end

local directions =
{
    [0] = 'defines.direction.north',
    [1] = 'defines.direction.northnortheast',
    [2] = 'defines.direction.northeast',
    [3] = 'defines.direction.eastnortheast',
    [4] = 'defines.direction.east',
    [5] = 'defines.direction.eastsoutheast',
    [6] = 'defines.direction.southeast',
    [7] = 'defines.direction.southsoutheast',
    [8] = 'defines.direction.south',
    [9] = 'defines.direction.southsouthwest',
    [10] = 'defines.direction.southwest',
    [11] = 'defines.direction.westsouthwest',
    [12] = 'defines.direction.west',
    [13] = 'defines.direction.westnorthwest',
    [14] = 'defines.direction.northwest',
    [15] = 'defines.direction.northnorthwest',
}

Public.new('get', 'Hover over an object to get its name.')
    :require_admin()
    :add_parameter('die', true, 'string')
    :add_alias('entity')
    :callback(
        function (player, action)
            local entity = player.selected
            if not entity or not entity.valid then
                return false
            end

            if action and action == 'die' then
                entity.die()
                return true
            end

            player.print('[color=orange]Name:[/color] ' .. entity.name)
            player.print('[color=orange]Type:[/color] ' .. entity.type)
            player.print('[color=orange]Force:[/color] ' .. entity.force.name)
            player.print('[color=orange]Direction:[/color] ' .. entity.direction .. ' (' .. directions[entity.direction] .. ')')
            player.print('[color=orange]Destructible:[/color] ' .. (entity.destructible and 'true' or 'false'))
            player.print('[color=orange]Minable:[/color] ' .. (entity.minable and 'true' or 'false'))
            player.print('[color=orange]Unit Number:[/color] ' .. (entity.unit_number or 'nil'))
            player.print('[color=orange]Position:[/color] ' .. serpent.line(entity.position))
            player.print('[color=orange]Active:[/color] ' .. (entity.active and 'true' or 'false'))
            return true
        end
    )

Public.new('spawn', 'Spawns a new entity near the player.')
    :require_admin()
    :add_parameter('entity', false, 'string')
    :add_parameter('force', true, 'string')
    :callback(
        function (player, name, force)
            local surface = player.surface
            local position = player.position
            local entity = surface.create_entity({ name = name, position = surface.find_non_colliding_position(name, position, 10, 0.5) or position, force = force or player.force })
            if entity then
                player.print('Entity spawned successfully.')
            else
                player.print('Failed to spawn entity.')
            end
        end
    )

Public.new('tp', 'Teleports the player to a specific position.')
    :require_admin()
    :add_parameter('position', false, 'position')
    :add_parameter('surface', true, 'surface')
    :callback(
        function (player, position, surface)
            player.teleport(position, surface)
        end
    )

local function interface(callback, ...)
    if type(callback) == 'function' then
        local success, err = pcall(callback, ...)
        return success, err
    else
        local success, err = pcall(load(callback), ...)
        return success, err
    end
end

Public.new('interface', 'Runs the given input from the script')
    :require_role('interface')
    :skip_param_validation()
    :add_parameter('callback', false, 'any')
    :callback(function (player, callback)
        if not callback then
            return
        end
        if not string.find(callback, '%s') and not string.find(callback, 'return') and not string.find(callback, 'return') then
            callback = 'return ' .. callback
        end
        if player and not string.find(callback, 'utils.event') then
            callback =
                'local player, surface, force, entity = game.player, game.player.surface, game.player.force, game.player.selected;' ..
                callback
        end
        if
            string.find(callback, 'Roles') or string.find(callback, 'roles') or string.find(callback, 'Role') or
            string.find(callback, 'role') and not string.find(callback, 'utils.event')
        then
            callback =
                'local Roles = require "utils.datastore.session_data"; local Role = Roles; local roles = Roles; local role = Role; Roles.get_role(game.player);' ..
                callback
        end

        if not string.find(callback, 'utils.event') then
            callback = 'local Event = require "utils.event";' .. callback
        end

        if not string.find(callback, 'utils.gui') then
            callback = 'local Gui = require "utils.gui";' .. callback
        end

        local success, err = interface(callback)
        if not success then
            if type(err) == 'string' then
                local _end = string.find(err, 'stack traceback')
                if _end then
                    err = string.sub(err, 0, _end - 2)
                end

                err = err:gsub('..-/temp/currently%-playing..-%....', '')
                err = '[color=red][Interface error][/color] ' .. err
                pcall(player.print, err)
            end
        end
    end)

return Public
