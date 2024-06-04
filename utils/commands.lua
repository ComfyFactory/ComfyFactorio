---@diagnostic disable: deprecated
--luacheck: ignore 561
local Global = require 'utils.global'
local Core = require 'utils.core'
local Session = require 'utils.datastore.session_data'
local Supporters = require 'utils.datastore.supporters'
local Task = require 'utils.task_token'
local Server = require 'utils.server'

---@class CommandData
---@field name string
---@field help string
---@field aliases table
---@field parameters table
---@field parameters_count number
---@field parameters_required number
---@field check_server boolean
---@field check_backend boolean
---@field check_admin boolean
---@field check_supporter boolean
---@field check_trusted boolean
---@field check_playtime number
---@field callback function
---@field validate_self boolean
---@field validated_command boolean
---@field validate_activated boolean
---@field command_activated boolean

local this = {
    commands = {}
}
local trace = debug.traceback

local output = {
    backend_is_required = 'No backend is currently available. Please try again later.',
    server_is_required = 'This command requires to be run from the server.',
    admin_is_required = 'This command requires admin permissions to run.',
    supporter_is_required = 'This command requires supporter permissions to run.',
    trusted_is_required = 'This command requires trusted permissions to run.',
    playtime_is_required = 'This command requires a minimum playtime to run.',
    param_is_required = 'This command requires a parameter to run.',
    command_failed = 'Command failed to run.',
    command_success = 'Command ran successfully.',
    command_needs_validation =
    'This command requires validation to run. Please re-run the command if you wish to proceed.',
    command_needs_custom_validation =
    'This command requires validation to run. %s - please re-run the command if you wish to proceed.',
    command_is_active = 'This command is already active.',
    command_is_inactive = 'This command is already inactive.'
}

local check_boolean = {
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
        for _, command in pairs(this.commands) do
            setmetatable(command, Public.metatable)
        end
    end
)

local function conv(v)
    if tonumber(v) then
        return tonumber(v)
    end

    return v
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
            Server.output_data('[ERROR] Command failed to run: ' .. name .. ' - ' .. message)
        else
            Server.output_data('[ERROR] Command failed to run: ' .. name)
        end
    end
    return not has_run
end

---@param event EventData.on_console_command
local function execute(event)
    local command_data = this.commands[event.name] --[[@as CommandData]]

    local player
    if event.player_index and event.player_index > 0 then
        player = game.get_player(event.player_index)
    else
        player = {
            name = 'Server',
            position = { x = 0, y = 0 },
            surface = game.get_surface('nauvis'),
            force = game.forces.player,
            print = Server.output_data
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

    -- Check if the player is an admin and if the command requires it
    local check_admin = command_data.check_admin or false
    if (check_admin and not is_server) and player and not player.admin then
        reject(output.admin_is_required)
        return
    end

    -- Check if the player is trusted and if the command requires it
    local check_trusted = command_data.check_trusted or false
    if (check_trusted and not is_server) and Core.validate_player(player) then
        local is_trusted = Session.get_trusted_player(player)
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

    -- Check if the player has the required playtime and if the command requires it
    local check_playtime = command_data.check_playtime or false
    if (check_playtime and not is_server) and Core.validate_player(player) then
        local playtime = Session.get_session_player(player)
        if not playtime then
            reject(output.trusted_is_required)
            return
        end

        if playtime < check_playtime then
            reject(output.playtime_is_required)
            return
        end
    end

    -- Check for parameters
    if command_data.parameters_required > 0 and not event.parameter then
        reject(output.param_is_required)
        return
    end

    -- Check if the command requires the player to validate the command
    local validate_self = command_data.validate_self or false
    if validate_self and not command_data.validated_command then
        command_data.validated_command = true
        if command_data.custom_message then
            handle_error(string.format(output.command_needs_custom_validation, command_data.custom_message),
                'utility/cannot_build')
        else
            handle_error(output.command_needs_validation, 'utility/cannot_build')
        end
        return
    end

    -- Extract quoted arguments
    local input_text = event.parameter or ''
    local quoted_segments = {}

    local processed_input =
        input_text:gsub(
            '"([^"]-)"',
            function (segment)
                local no_spaces_segment = segment:gsub('%s', '%%s')
                quoted_segments[no_spaces_segment] = segment
                return ' ' .. no_spaces_segment .. ' '
            end
        )

    -- Extract unquoted arguments
    local parameters = {}
    local current_index = 0
    local parameter_count = 0

    for word in processed_input:gmatch('%S+') do
        parameter_count = parameter_count + 1
        local quoted_word = quoted_segments[word]
        local formatted_word = quoted_word and ('"' .. quoted_word .. '"') or word

        if parameter_count > command_data.parameters_count then
            parameters[current_index] = parameters[current_index] .. ' ' .. formatted_word
        else
            current_index = current_index + 1
            parameters[current_index] = formatted_word
        end
    end

    -- Check the param count
    local parameters_count = #parameters
    if parameters_count < command_data.parameters_required then
        reject(output.param_is_required)
        return
    end

    -- Parse the arguments
    local index = 1
    local handled_parameters = {}
    for _, param_data in pairs(command_data.parameters) do
        if param_data.as_type then
            local param = conv(parameters[index])
            if param_data.as_type == 'player' and param ~= nil then
                local player_name = param
                if type(player_name) ~= 'string' then
                    return reject('Inputted value is not of type string. Valid values are: "string"')
                end
                local player_data = game.get_player(player_name) --[[@type LuaPlayer]]
                if not player_data then
                    return reject('Player was not found.')
                end
                handled_parameters[index] = player_data
                index = index + 1
            end
            if param_data.as_type == 'player-online' and param ~= nil then
                local player_name = param
                if type(player_name) ~= 'string' then
                    return reject('Inputted value is not of type string. Valid values are: "string"')
                end
                local player_data = game.get_player(player_name) --[[@type LuaPlayer]]
                if not player_data or not player_data.valid then
                    return reject('Player was not found.')
                end
                if not player_data.connected then
                    return reject('Player is not online.')
                end
                handled_parameters[index] = player_data
                index = index + 1
            end
            if param_data.as_type == 'player-admin' and param ~= nil then
                local player_name = param
                if type(player_name) ~= 'string' then
                    return reject('Inputted value is not of type string. Valid values are: "string"')
                end
                local player_data = game.get_player(player_name) --[[@type LuaPlayer]]
                if not player_data or not player_data.valid then
                    return reject('Player was not found.')
                end
                if not player_data.admin then
                    return reject('Player is not an admin.')
                end
                handled_parameters[index] = player_data
                index = index + 1
            end
            if param_data.as_type == 'server' and param ~= nil then
                local player_name = param
                if type(player_name) ~= 'string' then
                    return reject('Inputted value is not of type string. Valid values are: "string"')
                end
                local player_data = game.get_player(player_name) --[[@type LuaPlayer]]
                if player_data and player_data.valid then
                    return reject('Not running from server.')
                end
                handled_parameters[index] = player_data
                index = index + 1
            end
            if (param_data.as_type == 'number' or param_data.as_type == 'integer') and param ~= nil then
                local num = tonumber(param)
                if not num then
                    return reject('Inputted value is not of type number. Valid values are: 1, 2, 3, etc.')
                end
                handled_parameters[index] = num
                index = index + 1
            end
            if param_data.as_type == 'string' and param ~= nil then
                if type(param) ~= 'string' then
                    return reject('Inputted value is not of type string. Valid values are: "string"')
                end

                handled_parameters[index] = param
                index = index + 1
            end
            if param_data.as_type == 'boolean' and param ~= nil then
                if not check_boolean[param] then
                    return reject('Inputted value is not of type boolean. Valid values are: true, false.')
                end

                if command_data.command_activated and param == 'true' then
                    return handle_error(output.command_is_active, 'utility/cannot_build')
                end

                if not command_data.command_activated and param == 'false' then
                    return handle_error(output.command_is_inactive, 'utility/cannot_build')
                end

                handled_parameters[index] = param
                index = index + 1
            end
        end
    end

    -- Run the command callback if everything is validated
    handled_parameters[#handled_parameters + 1] = input_text
    local callback = Task.get(command_data.callback)
    local success, err = pcall(callback, player, unpack(handled_parameters))
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

--- Requires that the command is not run from a player.
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

--- Requires the player to have a minimum playtime to run the command.
---@param playtime integer|number
---@return MetaCommand
function Public:require_playtime(playtime)
    self.check_playtime = playtime or nil
    return self
end

--- Adds a parameter to the command.
---@param name string
---@param optional boolean
---@param as_type? type|string
---@return MetaCommand
function Public:add_parameter(name, optional, as_type)
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

return Public
