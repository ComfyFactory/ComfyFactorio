local Public = require 'maps.mountain_fortress_v3.stateful.table'
local Event = require 'utils.event'
local WD = require 'modules.wave_defense.table'

Public.stateful_gui = require 'maps.mountain_fortress_v3.stateful.gui'
Public.stateful_terrain = require 'maps.mountain_fortress_v3.stateful.terrain'
Public.stateful_generate = require 'maps.mountain_fortress_v3.stateful.generate'
Public.stateful_blueprints = require 'maps.mountain_fortress_v3.stateful.blueprints'

local random = math.random
local shuffle = table.shuffle_table

Event.add(
    defines.events.on_research_finished,
    function(event)
        local research = event.research
        if not research then
            return
        end

        local name = research.name
        local objectives = Public.get_stateful('objectives')
        if not objectives then
            return
        end

        if name == objectives.research_level_selection then
            objectives.research_level_count = objectives.research_level_count + 1
        end
    end
)

Event.on_nth_tick(
    200,
    function()
        local final_battle = Public.get_stateful('final_battle')
        if not final_battle then
            return
        end

        Public.set('final_battle', true)
        Public.allocate()

        local spawn_positions = Public.stateful_spawn_points
        local sizeof = Public.sizeof_stateful_spawn_points

        local area = spawn_positions[random(1, sizeof)]

        shuffle(area)

        WD.set_spawn_position(area[1])
        Event.raise(WD.events.on_spawn_unit_group, {fs = true, bypass = true})
    end
)

return Public
