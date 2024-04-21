if (debug.sethook) then
    local table_sort = table.sort
    local string_rep = string.rep
    local string_format = string.format
    local debug_getinfo = debug.getinfo
    local Color = require 'utils.color_presets'
    local Task = require 'utils.task'
    local Token = require 'utils.token'
    local Event = require 'utils.event'

    local Public = {
        call_tree = nil,
        is_running = false
    }

    local stop_profiler_token =
        Token.register(
        function()
            Public.stop()
            game.print('[PROFILER] Stopped!')
            log('[PROFILER] Stopped!')
        end
    )

    -- we can have this on runtime,
    -- but never ever can a player run this without notifying us.
    local allowed = {
        ['Gerkiz'] = true,
        ['mewmew'] = true
    }

    local ignored_functions = {
        [debug.sethook] = true
    }

    local named_sources = {
        ['[string "local n, v = "serpent", "0.30" -- (C) 2012-17..."]'] = 'serpent'
    }

    local function start_command(command)
        local player = game.player
        if player then
            if player ~= nil then
                if not player.admin then
                    local p = player.print
                    p('[ERROR] Only admins are allowed to run this command!', Color.fail)
                    return
                else
                    if allowed[player.name] then
                        Public.start(command.parameter ~= nil)
                    elseif _DEBUG then
                        Public.start(command.parameter ~= nil)
                    end
                end
            end
        end
    end
    local function stop_command(command)
        local player = game.player
        if player then
            if player ~= nil then
                if not player.admin then
                    local p = player.print
                    p('[ERROR] Only admins are allowed to run this command!', Color.fail)
                    return
                else
                    if allowed[player.name] then
                        Public.stop(command.parameter ~= nil, nil)
                    elseif _DEBUG then
                        Public.stop(command.parameter ~= nil, nil)
                    end
                end
            end
        end
    end
    ignored_functions[start_command] = true
    ignored_functions[stop_command] = true

    commands.add_command('start_profiler', 'Starts profiling', start_command)
    commands.add_command('stop_profiler', 'Stops profiling', stop_command)

    --local assert_raw = assert
    --function assert(expr, ...)
    --	if not expr then
    --		Public.stop(false, "Assertion failed")
    --	end
    --	assert_raw(expr, ...)
    --end
    local error_raw = error
    --luacheck: ignore error
    function error(...)
        Public.stop(false, 'Error raised')
        error_raw(...)
    end

    function Public.start(exclude_called_ms)
        if Public.is_running then
            return
        end

        local create_profiler = game.create_profiler

        Public.is_running = true

        Public.call_tree = {
            name = 'root',
            calls = 0,
            profiler = create_profiler(),
            next = {}
        }

        --	Array of Call
        local stack = {[0] = Public.call_tree}
        local stack_count = 0

        debug.sethook(
            function(event)
                local info = debug_getinfo(2, 'nSf')

                if ignored_functions[info.func] then
                    return
                end

                if event == 'call' or event == 'tail call' then
                    local prev_call = stack[stack_count]
                    if exclude_called_ms and prev_call then
                        prev_call.profiler.stop()
                    end

                    local what = info.what
                    local name
                    if what == 'C' then
                        name = string_format('C function %q', info.name or 'anonymous')
                    else
                        local source = info.short_src
                        local namedSource = named_sources[source]
                        if namedSource ~= nil then
                            source = namedSource
                        elseif string.sub(source, 1, 1) == '@' then
                            source = string.sub(source, 1)
                        end
                        name = string_format('%q in %q, line %d', info.name or 'anonymous', source, info.linedefined)
                    end

                    local prev_call_next = prev_call.next
                    if prev_call_next == nil then
                        prev_call_next = {}
                        prev_call.next = prev_call_next
                    end

                    local currCall = prev_call_next[name]
                    local profilerStartFunc
                    if currCall == nil then
                        local prof = create_profiler()
                        currCall = {
                            name = name,
                            calls = 1,
                            profiler = prof
                        }
                        prev_call_next[name] = currCall
                        profilerStartFunc = prof.reset
                    else
                        currCall.calls = currCall.calls + 1
                        profilerStartFunc = currCall.profiler.restart
                    end

                    stack_count = stack_count + 1
                    stack[stack_count] = currCall

                    profilerStartFunc()
                end

                if event == 'return' or event == 'tail call' then
                    if stack_count > 0 then
                        stack[stack_count].profiler.stop()
                        stack[stack_count] = nil
                        stack_count = stack_count - 1

                        if exclude_called_ms then
                            stack[stack_count].profiler.restart()
                        end
                    end
                end
            end,
            'cr'
        )
    end
    ignored_functions[Public.start] = true

    local function dump_tree(averageMs)
        local function sort_Call(a, b)
            return a.calls > b.calls
        end
        local fullStr = {''}
        local str = fullStr
        local line = 1

        local function recurse(curr, depth)
            local sort = {}
            local i = 1
            for k, v in pairs(curr) do
                sort[i] = v
                i = i + 1
            end
            table_sort(sort, sort_Call)

            for ii = 1, #sort do
                local call = sort[ii]

                if line >= 19 then --Localised string can only have up to 20 parameters
                    local newStr = {''} --So nest them!
                    str[line + 1] = newStr
                    str = newStr
                    line = 1
                end

                if averageMs then
                    call.profiler.divide(call.calls)
                end

                str[line + 1] = string_format('\n%s%dx %s. %s ', string_rep('\t', depth), call.calls, call.name, averageMs and 'Average' or 'Total')
                str[line + 2] = call.profiler
                line = line + 2

                local next = call.next
                if next ~= nil then
                    recurse(next, depth + 1)
                end
            end
        end
        if Public.call_tree.next ~= nil then
            recurse(Public.call_tree.next, 0)
            return fullStr
        end
        return 'No calls'
    end

    function Public.stop(averageMs, message)
        if not Public.is_running then
            return
        end

        debug.sethook()

        local text = {'', '\n\n----------PROFILER DUMP----------\n', dump_tree(averageMs), '\n\n----------PROFILER STOPPED----------\n'}
        if message ~= nil then
            text[#text + 1] = string.format('Reason: %s\n', message)
        end
        log(text)
        Public.call_tree = nil
        Public.is_running = false
    end
    ignored_functions[Public.stop] = true

    if _PROFILE and _PROFILE_ON_INIT then
        Event.on_init(
            function()
                game.print('[PROFILER] Started!')
                log('[PROFILER] Started!')
                Public.start()
                Task.set_timeout_in_ticks(3600, stop_profiler_token)
            end
        )
    end

    return Public
end
