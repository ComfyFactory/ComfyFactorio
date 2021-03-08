local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {
    hidden_dimension = {
        logistic_research_level = 0,
        energy = {}
    }
}
local Public = {}

local deepcopy = table.deepcopy

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

Public.transport_table = {
    transport_type = 'in_and_out',
    reference = nil,
    name = nil,
    entities = {
        chest_1 = nil,
        chest_2 = nil,
        loader_1 = nil,
        loader_2 = nil,
        pipe_1 = nil,
        pipe_2 = nil,
        pipe_3 = nil,
        pipe_4 = nil,
        pipe_5 = nil,
        pipe_6 = nil
    }
}

Public.levels_table = {
    surface = nil,
    size = nil,
    going_up = deepcopy(Public.transport_table),
    going_down = deepcopy(Public.transport_table),
    upgrade_level = 0
}

--- Resets the table to default
function Public.reset_table()
    if this.hidden_dimension then
        this.hidden_dimension.logistic_research_level = 0
    end
    this.hidden_dimension.energy = {}
end

--- Gets key from this table
function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

Event.on_init(
    function()
        Public.reset_table()
    end
)

return Public
