-- Created by Gerkiz
local Global = require 'utils.global'
local Event = require 'utils.event'
local Core = require 'utils.core'

local Public = {}
local loaded, named, count = {}, {}, 0

local this =
{
    tasks = {},
    intervals = {},
    next_id = 0,
    can_run_scheduler = true
}


Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

---@class Task
---@field _id number
---@field _uid number|nil
---@field _tick number
---@field _delay number
---@field _name string
---@field _data table|nil
---@field _completed boolean|nil
---@field _children table|nil
---@field _next_child_ix number|nil
---@field _parent Task|nil
local Task = {}
Task.__index = Task

--- Registers the metatable for the Task class
script.register_metatable('Task', Task)

--- Registers a callback for a task (data stage / module load time; not at runtime).
---@param name string - Helps identify the task in the debugger
---@param fn   function - The callback function
---@param uid? string|number - The unique identifier for the task
---@return number|string|nil
function Public.register_function(name, fn, uid)
    if game then error('Cannot register functions in runtime') end

    if uid then
        loaded[uid] = fn
        named[uid] = name
        return uid
    else
        count = count + 1
        loaded[count] = fn
        named[count] = name
        return count
    end
end

--- Gets the function by id
---@param id number|string - The unique identifier for the task
---@return function|nil - The callback function
---@return string|nil - The name of the task
function Public.get_function_by_id(id)
    return loaded[id], named[id]
end

local function normalize_delay(d)
    d = tonumber(d or 0) or 0
    if d < 0 then d = 0 end
    return math.floor(d)
end

local function new_task(delay, uid)
    this.next_id = this.next_id + 1
    local t = setmetatable(
        {
            _id = this.next_id,
            _uid = uid,
            _name = named[uid] or ("task_" .. this.next_id),
            _tick = nil,
            _delay = normalize_delay(delay),
            _completed = false,

            _data = nil,
            _children = {},
            _next_child_ix = 1,
            _parent = nil,
        }, Task)
    return t
end


--- Gets the callback for this task
---@return function|nil - The callback function
function Task:get_callback()
    return Public.get_function_by_id(self._uid)
end

--- Sets the data for this task
---@param tbl table - The data for the task
---@return Task - Self for chaining
function Task:set_data(tbl)
    self._data = tbl
    return self
end

--- Sets the interval for this task to run on
---@param time number - The time in ticks before the task is executed
---i.e. if you want the task to run every 10 ticks, you would set the interval to 10
---@param until_tick number - The tick until the task should stop running
---@return Task - Self for chaining
function Task:set_interval(time, until_tick)
    self._interval = normalize_delay(time)
    self._until_tick = until_tick
    return self
end

--- Delays this task for later execution
---@param delay number - The delay in ticks before the task is executed
---@return Task - Self for chaining
function Task:set_delay(delay)
    self._delay = normalize_delay(delay)
    self._tick = game.tick + normalize_delay(delay)
    return self
end

--- Validates the data for this task
---@return Task - Self for chaining
function Task:log()
    Core.log(self)
    return self
end

--- Creates a new child task
---@param delay number - The delay in ticks before the task is executed
---@param uid number|string|nil - The unique identifier for the task
---@return Task - The new child task
function Task:new_child(delay, uid)
    local c = new_task(delay, uid)
    c._parent = self
    c._delay = math.max(1, delay or 1)
    table.insert(self._children, c)
    return c
end

--- Runs the task
---@param current_tick number - The current tick
---@return boolean - Whether the task was executed
function Task:run(current_tick)
    if self._tick and self._tick > current_tick then return false end
    if self._completed then return false end

    local cb, name = self:get_callback()
    self._name = self._name or name or self._name

    if cb then
        cb(self._data or {}, self)
    end

    self._completed = true
    return true
end

--- Runs the task on an interval
---@param current_tick number - The current tick
---@return boolean - Whether the task was executed
function Task:run_interval(current_tick)
    if self._interval and current_tick % self._interval == 0 then
        if self._until_tick and self._until_tick <= current_tick then
            self._completed = true
            return false
        end

        local cb, name = self:get_callback()
        self._name = self._name or name or self._name

        if cb then
            cb(self._data or {}, self)
        end
        return true
    end
    return false
end

--- Cancels the task
---@return Task - Self for chaining
function Task:cancel_task()
    self._completed = true
    return self
end

--- Schedules the next task in the DFS
---@param n Task - The task to schedule
---@param current_tick number - The current tick
local function schedule_next_in_dfs(n, current_tick)
    while n do
        if n._next_child_ix <= #n._children then
            local child = n._children[n._next_child_ix]
            n._next_child_ix = n._next_child_ix + 1

            local base = n._tick or current_tick
            child._tick = math.max(current_tick, base) + child._delay
            table.insert(this.tasks, child)
            return
        end
        n = n._parent
    end
end

--- Creates a new task
---@param delay number - The delay in ticks before the task is executed
---@param uid number|string|nil - The unique identifier for the task
---@return Task - The new task
function Public.new(delay, uid)
    local t = new_task(delay, uid)
    t._tick = game.tick + normalize_delay(delay)
    table.insert(this.tasks, t)
    return t
end

--- Creates a new task
---@param time number - The time in ticks before the task is executed
---@param until_tick number - The tick until the task should stop running
---@param uid number|string|nil - The unique identifier for the task
---@return Task - The new task
function Public.new_interval(time, until_tick, uid)
    local t = new_task(1, uid)
    t._interval = normalize_delay(time)
    t._until_tick = until_tick
    table.insert(this.intervals, t)
    return t
end

--- Gets the task by unique identifier
---@param uid number|string - The unique identifier for the task
---@return Task|nil, number|nil - The task and the index
function Public.get_task_by_uid(uid)
    if not uid then
        return nil, nil
    end
    for i, t in pairs(this.tasks) do
        if t._uid == uid then
            return t, i
        end
    end
    for i, t in pairs(this.intervals) do
        if t._uid == uid then
            return t, i
        end
    end
    return nil, nil
end

--- Sets whether the scheduler can run
---@param condition boolean - Whether the scheduler can run (true to run, false to stop)
function Public.set_can_run_scheduler(condition)
    this.can_run_scheduler = condition or false
end

--- Clears the tasks
function Public.clear_tasks()
    this.tasks = {}
    this.next_id = 0
    Core.log('Scheduler tasks have been cleared!')
end

Event.add(defines.events.on_tick,
    function ()
        local tick = game.tick

        local can_run_scheduler = this.can_run_scheduler
        if not can_run_scheduler then
            return
        end

        if not this.tasks or #this.tasks == 0 then
            this.next_id = 0
            return
        end

        local i = 1
        while i <= #this.tasks do
            local t = this.tasks[i]

            ---@class Task
            t = t

            if not t._interval and t._tick and t._tick <= tick and not t._completed then
                local ran = t:run(tick)
                table.remove(this.tasks, i)

                if ran then
                    schedule_next_in_dfs(t, tick)
                end
            else
                i = i + 1
            end
        end
    end)

Event.add(defines.events.on_tick,
    function ()
        local tick = game.tick

        if tick < 100 then
            return
        end

        local can_run_scheduler = this.can_run_scheduler
        if not can_run_scheduler then
            return
        end

        if not this.intervals or #this.intervals == 0 then
            return
        end

        for i = 1, #this.intervals do
            local t = this.intervals[i]
            ---@class Task
            t = t

            if t._interval and not t._completed then
                t:run_interval(tick)
            else
                table.remove(this.intervals, i)
            end
        end
    end)

return Public
