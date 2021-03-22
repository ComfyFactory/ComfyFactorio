local Global = require('utils.global')

local this = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local Public = {}

Public.init = function()
    this.timers = {}
end

--[[
set_timer - Sets a timer.
@param left - Time left on the timer in ticks.
@param hook - Action executed after timer is elapsed.
--]]
Public.set_timer = function(left, hook)
    local id = game.tick
    local entry = {
        left = left,
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

        entry.left = entry.left - (game.tick - entry.last_update)
        if entry.left > 0 then
            entry.last_update = game.tick

            if entry.hook_update ~= nil then
                if not entry.hook_update(entry.left, entry.deps) then
                    goto premature_finish
                end
            end

            goto continue
        end

        ::premature_finish::
        entry.hook_finish(entry.deps)
        this.timers[id] = nil

        ::continue::
    end
end

return Public
