local Global = require 'utils.global'
local Token = require 'utils.token'

local this = {
    timers = {}
}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local Public = {}

--[[
set_timer - Sets a timer.
@param time_left - Time time_left on the timer in ticks.
@param hook - Action executed after timer is elapsed.
--]]
Public.set_timer = function(time_left, hook)
    local id = game.tick
    local entry = {
        time_left = time_left,
        hook_finish = hook,
        hook_update = nil,
        deps = nil,
        running = false,
        last_update = 0
    }

    this.timers[id] = entry
    return id
end

--[[
set_timer_on_update - Adds a hook that is executed everytime a
timers is updated.
@param id - Id of the timer.
@param hook - Hook that will be executed per update.
--]]
Public.set_timer_on_update = function(id, hook)
    this.timers[id].hook_update = hook
end

--[[
set_timer_dependency - Adds dependency into user callback.
@param id - Id of the timer,
@param deps - Dependency of timer to add.
--]]
Public.set_timer_dependency = function(id, deps)
    this.timers[id].deps = deps
end

--[[
set_timer_start - Sets the timer to run.
@param id - Id of a timer.
--]]
Public.set_timer_start = function(id)
    this.timers[id].running = true
    this.timers[id].last_update = game.tick
end

--[[
kill_timer - Effectivly kills the timer.
@param id - Timer id.
--]]
Public.kill_timer = function(id)
    this.timers[id] = nil
end

--[[
do_job - Execute timer logic within a tick.
--]]
Public.do_job = function()
    for id, entry in pairs(this.timers) do
        if entry.running == false then
            goto continue
        end

        entry.time_left = entry.time_left - (game.tick - entry.last_update)
        if entry.time_left > 0 then
            entry.last_update = game.tick

            if entry.hook_update ~= nil then
                local func = Token.get(entry.hook_update)
                local data = entry.deps
                data.time_left = entry.time_left
                if func then
                    if not func(data) then
                        goto premature_finish
                    end
                end
            end

            goto continue
        end

        ::premature_finish::
        local func = Token.get(entry.hook_finish)
        local data = entry.deps
        if func then
            func(data)
        end
        this.timers[id] = nil

        ::continue::
    end
end

return Public
