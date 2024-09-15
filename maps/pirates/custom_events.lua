-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.


local Event = require 'utils.event'

local Public = {}

-- just beginning this, gotta finish reformulating the gui updates in terms of events:

local enum = {
    update_crew_progress_gui = Event.generate_event_name('update_crew_progress_gui'),
}
Public.enum = enum

return Public
