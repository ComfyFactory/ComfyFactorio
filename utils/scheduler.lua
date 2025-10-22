local Event = require 'utils.event'
local Server = require 'utils.server'
local Global = require 'utils.global'
local loaded = {}
local chained_loaded = {}
local count = 1

local this =
{
    tasks = {},
    task_index = 1,
    next_task_index = 1,
}

---@class Task
---@field _id number|nil
---@field _is_parent boolean|nil
---@field _tick number -- the tick to run the task at
---@field _increment_tick number -- the increment tick to run the task at
---@field _task_index number
---@field _custom_name string|nil
---@field _parent_name string|nil
---@field _parent_id number|nil
---@field _run_after string|table|nil
---@field _data table|nil
---@field _ttl number|nil
---@field _sleep_after_execution number|nil
---@field _completed boolean|nil
---@field _linked_tasks MetaTask|nil

---@class MetaTask
local Public = {}

Public.tasks = { __index = Public }

Global.register(
    this,
    function (tbl)
        this = tbl
        for _, task in pairs(this.tasks) do
            setmetatable(task, Public.tasks)
        end
    end
)

--- Registers a callback for a task
---@param var function - Callback function
---@param chained_task_id number|table|nil - Chained task ID
---@return number|nil - Callback ID
function Public.register_function(var, chained_task_id)
    if game then
        return
    end

    count = count + 1
    loaded[count] = var
    if chained_task_id then
        if chained_loaded[count] then
            table.insert(chained_loaded[count], chained_task_id)
        else
            if type(chained_task_id) == 'table' then
                chained_loaded[count] = chained_task_id
            else
                chained_loaded[count] = { chained_task_id }
            end
        end
    end
    return count
end

--- Removes a task by index
---@param index number - Task index
---@return nil - Nothing
function Public.remove_task_by_index(index)
    local tasks = this.tasks
    for i, task in pairs(tasks) do
        if task._task_index == index then
            table.remove(tasks, i)
            return
        end
    end
end

--- Sets whether the scheduler can run
---@param condition boolean - Whether the scheduler can run
function Public.can_run_scheduler(condition)
    this.can_run_scheduler = condition or false
end

--- Searches for a task by ID that is NOT completed
---@param ref string|number - Task reference (custom_name or id)
---@return MetaTask|nil - The task if it exists and is not completed
function Public.search_task(ref) -- ref can be custom_name (string) or id (number)
    local handlers = this.tasks
    for _, data in pairs(handlers) do
        if data and not data._completed then
            if (data._custom_name == ref) or (data._id == ref) then
                return data
            end
        end
    end
    return nil
end

--- Searches for a task by index
---@param index number - Task index
---@return MetaTask|nil - The task if it exists
function Public.search_task_by_index(index)
    local handlers = this.tasks

    for _, data in pairs(handlers) do
        if data and data._task_index == index then
            return data
        end
    end
    return nil
end

--- Checks if any tasks are waiting for this task to complete
---@param custom_name string - Custom name to check
---@return boolean - Whether any tasks are waiting
local function has_dependent_tasks(custom_name)
    if not custom_name then
        return false
    end

    local handlers = this.tasks
    for _, data in pairs(handlers) do
        if data and data._run_after then
            for _, task_name in ipairs(data._run_after) do
                if task_name == custom_name then
                    return true
                end
            end
            -- if data._parent_name then
            --     if data._parent_name == custom_name then
            --         return true
            --     end
            -- end
        end
    end
    return false
end

--- Gets a callback by ID
---@param id number - Task ID
---@return function|nil - The callback function
function Public.get_function_by_id(id)
    return loaded[id]
end

--- Returns a callback
---@param callback_data table - Callback data
---@param callback function - Callback function
---@return function|nil - The callback function
function Public.return_callback(callback_data, callback)
    if not callback then
        return
    end

    local data =
    {
        iterator_index = 1,
        tick_index = 1,
        point_index = 1,
        pos_tbl = {},
        total_calls = 256,
        table_index = 1
    }

    if not callback_data then
        return callback()
    else
        for _, tbl in pairs(callback_data) do
            local start_index = (data.table_index - 1) * data.total_calls + 1
            local end_index = start_index + data.total_calls - 1

            if tbl then
                data.pos_tbl[#data.pos_tbl + 1] = tbl.position
                if data.iterator_index == end_index or data.iterator_index > #callback_data then
                    data.table_index = data.table_index + 1
                    data.tick_index = data.tick_index + 1
                    callback(data, tbl)
                    data.pos_tbl = {}
                    data.point_index = 1
                    if data.table_index > #callback_data then
                        break
                    end
                end
                data.iterator_index = data.iterator_index + 1
                data.point_index = data.point_index + 1
            end
        end
        return callback(data)
    end
end

--- Creates a new task
---@param tick number - Tick to run the task at
---@param id number - Callback ID returned from Public.set()
---@return MetaTask
function Public.new(tick, id)
    if id and type(id) == 'function' then
        error('Callback must be of type string. Please register your callback with Token.register()')
    end

    local tasks = this.tasks

    local self =
        setmetatable(
            {
                _id = id,
                _tick = game.tick + tick,
                _increment_tick = tick,
                _task_index = this.task_index
            },
            Public.tasks
        )


    tasks[#tasks + 1] = self
    this.task_index = this.task_index + 1
    return self
end

--- Creates a new task
---@param tick number - Tick to run the task at
---@return MetaTask
function Public.new_parent(tick)
    local tasks = this.tasks

    local self =
        setmetatable(
            {
                _tick = game.tick + tick,
                _task_index = this.task_index,
                _is_parent = true
            },
            Public.tasks
        )


    tasks[#tasks + 1] = self
    this.task_index = this.task_index + 1
    return self
end

--- Gets the callback for this task
---@return function|nil - The callback function
function Public:get_callback()
    local callback = Public.get_function_by_id(self._id)
    return callback
end

--- Gets the chained callback for this task
---@return number|nil - The chained callback ID
function Public:get_chained_callback()
    return chained_loaded[self._id]
end

--- Removes the task (marks as completed if it has dependents)
---@param index number - Task index to remove
function Public:remove_task(index)
    if has_dependent_tasks(self._custom_name) then
        self._id = nil
    else
        table.remove(this.tasks, index)
    end
end

--- Pushes the task without running the callback
---@param ticks number - Number of ticks to push
---@return MetaTask - Self for chaining
function Public:push_without_action(ticks)
    self._tick = self._tick + (ticks or 1)

    return self
end

--- Sets the tick for this task
---@param ticks number - Number of ticks to push
---@return MetaTask - Self for chaining
function Public:set_tick(ticks)
    self._tick = ticks

    return self
end

--- Sets the sleep time after execution for this task
---@param ticks number - Number of ticks to sleep
---@return MetaTask - Self for chaining
function Public:set_sleep_after_execution(ticks)
    if not ticks or ticks < 0 then
        error('Ticks must be a positive number')
    end

    self._sleep_after_execution = game.tick + ticks
    return self
end

--- Sets a custom name for this task (used by run_after)
---@param name string - Custom identifier
---@return MetaTask - Self for chaining
function Public:set_custom_name(name)
    self._custom_name = name
    return self
end

--- Sets task(s) that must complete before this one runs
---@param tasks string|table - Name(s) of task(s) to wait for
---@return MetaTask - Self for chaining
function Public:run_after(tasks)
    self._run_after = tasks and type(tasks) == 'table' and tasks or { tasks }
    return self
end

--- Validates the data for this task
---@return MetaTask - Self for chaining
function Public:validate_data()
    log(serpent.block(self))
    return self
end

--- Sets the parent name for this task (used by chain_run_after)
---@param name string - Parent identifier
---@return MetaTask - Self for chaining
function Public:set_parent_name(name)
    self._parent_name = name
    return self
end

--- Sets the parent id for this task (used by chain_run_after)
---@param id number - Parent identifier
---@return MetaTask - Self for chaining
function Public:set_parent_id(id)
    self._parent_id = id
    return self
end

--- Sets custom data to pass to the callback
---@param data table - Data to pass
---@return MetaTask - Self for chaining
function Public:set_data(data)
    if not data or type(data) ~= 'table' then
        error('Data must be a table')
    end

    self._data = data
    return self
end

--- Sets how many times the task should run before being removed
---@param times number - Number of times to run
---@return MetaTask - Self for chaining
function Public:set_ttl(times)
    self._ttl = times
    return self
end

--- Works the ttl for this task
---@return MetaTask - Self for chaining
function Public:work_ttl()
    if self._ttl then
        self._ttl = self._ttl - 1
        if self._ttl <= 0 then
            self:remove_task(this.next_task_index)
        else
            self._completed = false
            self:set_tick(game.tick + self._increment_tick)
        end
    end
    return self
end

--- Immediately queues the task to run on the next tick
---@return MetaTask - Self for chaining
function Public:run_task()
    local callback = self:get_callback()
    if callback then
        callback(self._data or {})
    end
    return self
end

--- Chains another task to run after this one completes
---@param callback_id number - Callback ID for the chained task
---@return MetaTask - Self for chaining
function Public:chain_task(callback_id)
    self:set_custom_name('chain_' .. self._task_index)

    local chained_task = Public.new(1, callback_id)
        :set_parent_name(self._custom_name)
        :set_parent_id(self._id)
        :run_after(self._custom_name)


    self._linked_tasks = self._linked_tasks or {}
    self._linked_tasks[callback_id] = chained_task._task_index
    return chained_task
end

--- Gets the linked task
---@param callback_id number - Callback ID for the chained task
---@return MetaTask|nil - The linked task
function Public:get_linked_task(callback_id)
    local task = Public.search_task_by_index(self._linked_tasks[callback_id])
    return task
end

--- Runs the scheduler on the next tick
local function on_tick()
    local tick = game.tick
    local can_run_scheduler = this.can_run_scheduler
    if not can_run_scheduler then
        this.tasks = {}
        Server.output_script_data('Scheduler task has been cleared and stopped!')
        return
    end

    local handlers = this.tasks

    local self
    this.next_task_index, self = next(handlers, this.next_task_index)
    if not self then
        return
    end

    self = self --[[@as MetaTask]]

    if self._tick > tick then
        return
    end

    -- self:push_without_action(1)

    local callback = self:get_callback()
    if not callback then
        if self._sleep_after_execution then
            if self._sleep_after_execution > tick then
                self:push_without_action(5)
                return
            else
                self:remove_task(this.next_task_index)
                return
            end
        end
    end

    if self._parent_name then
        local parent_task = Public.search_task(self._parent_name)
        if parent_task then
            -- Parent still running
            self:push_without_action(5)
            return
        end
    end



    if self._run_after and next(self._run_after) then
        for _, task_name in ipairs(self._run_after) do
            local run_after = Public.search_task(task_name)
            if run_after then
                self:push_without_action(5)
                return
            end
        end
    end

    if callback and not self._completed then
        callback(self._data or {}, self)
    end

    if self._ttl then
        self:work_ttl()
        return
    end

    if self._sleep_after_execution then
        self._id = nil
        return
    end

    -- Mark as completed instead of removing immediately
    self._completed = true

    -- if not self._is_parent and not self._is_linked then
    --     log_flat(self, 'Removing task')
    --     self:remove_task(this.next_task_index)
    --     return
    -- end

    local chained_callback = self:get_chained_callback()
    if chained_callback then
        for _, chained_task_id in ipairs(chained_callback) do
            local chained_task = Public.search_task(chained_task_id)
            if chained_task then
                self:push_without_action(5)
                return
            end
        end
    end

    -- Only remove if no other tasks are waiting for this one
    if not has_dependent_tasks(self._custom_name) then
        self:remove_task(this.next_task_index)

        -- Clean up parent tasks that this task was waiting for
        if self._run_after and next(self._run_after) then
            for _, parent_name in ipairs(self._run_after) do
                -- Find and potentially remove completed parent tasks
                for _, parent_task in pairs(handlers) do
                    if parent_task._custom_name == parent_name and parent_task._completed then
                        if not has_dependent_tasks(parent_name) then
                            Public.remove_task_by_index(parent_task._task_index)
                        end
                    end
                end
            end
        end
    end
end

Event.add(defines.events.on_tick, on_tick)

return Public
