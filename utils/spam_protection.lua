local Event = require 'utils.event'
local Global = require 'utils.global'
local Commands = require 'utils.commands'
local Server = require 'utils.server'
local Public = {}

local this =
{
    prevent_spam = {}, -- the default table where all player indexes will be stored
    default_tick = 10, -- this defines the default tick to check whether or not a user is spamming a button.
    debug_text = false,
    debug_spam = false,
    show_debug_text_for = {}
}

local main_text = '[Spam Info] '

Global.register(
    this,
    function (t)
        this = t
    end
)

local function debug_text(str)
    if not this.debug_text then
        return
    end
    Server.output_script_data(main_text .. str)
end

local function debug_spam(str)
    if not this.debug_spam then
        return
    end
    Server.output_script_data(main_text .. str)
end

function Public.reset_spam_table()
    local players = game.connected_players
    this.prevent_spam = {}
    for i = 1, #players do
        local player = players[i]
        this.prevent_spam[player.index] = game.tick
    end
end

function Public.set_new_value(player)
    if this.prevent_spam[player.index] then
        this.prevent_spam[player.index] = game.tick
    end
end

function Public.is_spamming(player, value_to_compare, text)
    if not player or not player.valid then
        player = game.get_player(player)
    end

    if not player or not player.valid then return end

    if not this.prevent_spam[player.index] then
        return false
    end

    if text then
        if this.show_debug_text_for then
            for name, _ in pairs(this.show_debug_text_for) do
                local debug_player = game.get_player(name)
                if debug_player and debug_player.valid then
                    debug_player.print('Player ' .. player.name .. ' clicked on: ' .. text .. ' on surface: ' .. player.surface.name .. ' at position: ' .. player.position.x .. ', ' .. player.position.y .. ' at tick: ' .. game.tick)
                end
            end
        end
        debug_text('Player ' .. player.name .. ' clicked on: ' .. text .. ' on surface: ' .. player.surface.name .. ' at position: ' .. player.position.x .. ', ' .. player.position.y .. ' at tick: ' .. game.tick)
    end

    if game.tick_paused then
        return false -- game is paused - shoo
    end

    if this.debug_spam then
        Server.output_script_data(debug.traceback())
    end

    local tick = game.tick
    local value = value_to_compare or this.default_tick
    if this.prevent_spam[player.index] then
        if (tick - this.prevent_spam[player.index]) > value then
            Public.set_new_value(player)
            return false -- is not spamming
        else
            if text then
                debug_spam(player.name .. ' is spamming: ' .. text)
            else
                debug_spam(player.name .. ' is spamming.')
            end
            return true -- is spamming
        end
    end
    return false
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

Event.add(
    defines.events.on_player_joined_game,
    function (event)
        local player = game.get_player(event.player_index)
        if not player then
            return
        end

        if not this.prevent_spam[player.index] then
            this.prevent_spam[player.index] = game.tick
        end
    end
)
Event.on_init(
    function ()
        Public.reset_spam_table()
    end
)

Commands.new('sp_debug_text', 'Spam Protection - Shows the debug text for when players are clicking gui buttons.')
    :require_admin()
    :add_parameter('state', false, 'boolean')
    :callback(
        function (player, state)
            this.debug_text = state
            player.print('Debug text for spam protection has been ' .. (state and 'enabled' or 'disabled') .. '!')
        end
    )

Commands.new('sp_debug_spam', 'Spam Protection - Shows the debug spam for when players are clicking gui buttons.')
    :require_admin()
    :add_parameter('state', false, 'boolean')
    :callback(
        function (player, state)
            this.debug_spam = state
            player.print('Debug spam for spam protection has been ' .. (state and 'enabled' or 'disabled') .. '!')
        end
    )

Commands.new('sp_print_text', 'Spam Protection - Prints the debug text for when players are clicking gui buttons to your console.')
    :require_admin()
    :add_parameter('state', false, 'boolean')
    :callback(
        function (player, state)
            this.show_debug_text_for = this.show_debug_text_for or {}

            if state then
                this.show_debug_text_for[player.name] = true
                player.print('Debug text for spam protection has been enabled!')
            else
                this.show_debug_text_for[player.name] = nil
                player.print('Debug text for spam protection has been disabled!')
            end
        end
    )

return Public
