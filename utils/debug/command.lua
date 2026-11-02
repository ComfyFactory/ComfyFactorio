local DebugView = require 'utils.debug.main_view'
local Commands = require 'utils.commands'
local Gui = require 'utils.gui'

Commands.new('debug', 'Usable only for admins - opens the debugger!')
    :require_admin()
    :callback(
        function (player)
            local screen = player.gui.screen
            local frame = screen[DebugView.main_frame_name]
            if frame and frame.valid then
                Gui.destroy(frame)
            end

            DebugView.open_debug(player)
        end
    )

if _DEBUG then
    local Model = require 'model'

    local loadstring = loadstring
    local pcall = pcall
    local dump = Model.dump
    local log = log

    Commands.new('dump-log', 'Dumps value to log')
        :require_admin()
        :add_parameter('value', false, 'string')
        :callback(
            function (player, value)
                local func, err = loadstring('return ' .. value)

                if not func then
                    player.print(err)
                    return false
                end

                local suc, v = pcall(func)

                if not suc then
                    player.print(v)
                    return false
                end

                log(dump(v))
            end
        )

    Commands.new('dump-file', 'Dumps value to dump.lua')
        :require_admin()
        :add_parameter('value', false, 'string')
        :callback(
            function (player, value)
                local func, err = loadstring('return ' .. value)

                if not func then
                    player.print(err)
                    return false
                end

                local suc, v = pcall(func)

                if not suc then
                    player.print(v)
                    return false
                end

                v = dump(v)
                game.write_file('dump.lua', v, false)
            end
        )


    Commands.new('check_storage', 'Check for dumdum lua funcs.')
        :require_admin()
        :callback(
            function (player)
                local seen, identities = {}, {}
                local count, serial = 0, 0
                local function report(message)
                    log(message)
                    if player then player.print(message) end
                end
                local function label(key)
                    local kind = type(key)
                    if kind == 'string' then
                        if key:match('^[%a_][%w_]*$') then return '.' .. key end
                        return '[' .. string.format('%q', key) .. ']'
                    end
                    if kind == 'number' or kind == 'boolean' then return '[' .. tostring(key) .. ']' end
                    if not identities[key] then
                        serial = serial + 1
                        identities[key] = serial
                    end
                    return '[<' .. kind .. '#' .. identities[key] .. '>]'
                end
                local function scan(value, path)
                    if count >= 20 then return end
                    local kind = type(value)
                    if kind == 'function' then
                        count = count + 1
                        report('[Storage check] Function at ' .. path)
                        return
                    end
                    if kind ~= 'table' or seen[value] or type(rawget(value, '__self')) == 'userdata' then return end
                    seen[value] = true
                    for key, child in next, value do
                        local suffix = label(key)
                        scan(key, path .. '.<key' .. suffix .. '>')
                        scan(child, path .. suffix)
                        if count >= 20 then return end
                    end
                end
                scan(storage, 'storage')
                if count == 20 then
                    report('[Storage check] Stopped at 20 functions')
                else
                    report('[Storage check] Complete: ' .. count .. ' lua functions found.')
                end
            end
        )
end
