
local Event = require 'utils.event'

local Public = {}

-- gotta finish reformulating the gui updates in terms of events:
local enum = {
    update_crew_progress_gui = Event.generate_event_name('update_crew_progress_gui'),
    update_crew_fuel_gui = Event.generate_event_name('update_crew_fuel_gui'),
}
Public.enum = enum

return Public