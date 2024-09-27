-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

-- local Memory = require 'maps.pirates.memory'
-- local Math = require 'maps.pirates.math'
-- local Balance = require 'maps.pirates.balance'
-- local Common = require 'maps.pirates.common'
local CoreData = require("maps.pirates.coredata")
-- local Utils = require 'maps.pirates.utils_local'
-- local _inspect = require 'utils.inspect'.inspect

local Public = {}
local enum = {
    SEA = "Sea",
    ISLAND = "Island",
    CROWSNEST = "Crowsnest",
    LOBBY = "Lobby",
    HOLD = "Hold",
    CABIN = "Cabin",
    CHANNEL = "Channel",
    DOCK = "Dock",
}
Public.enum = enum

function Public.encode_surface_name(crewid, destination_index, type, subtype) -- crewid=0 is shared surfaces
    local str
    if subtype then
        str = string.format("%03d-%03d-%s-%s", crewid, destination_index, type, subtype) --uses the fact that type and subtype resolve to strings
    else
        str = string.format("%03d-%03d-%s", crewid, destination_index, type)
    end
    return str
end

function Public.decode_surface_name(name)
    local crewid = tonumber(string.sub(name, 1, 3)) or nil
    local destination_index = tonumber(string.sub(name, 5, 7)) or nil
    local type = nil
    local subtype = nil

    local substring = string.sub(name, 9, -1)
    local pull = {}
    for a, b in string.gmatch(substring, "(%w+)-(%w+)") do
        pull[1] = a
        pull[2] = b
    end
    if #pull == 0 then
        type = substring
    elseif #pull == 2 then
        type = pull[1]
        subtype = pull[2]
    end
    return { crewid = crewid, destination_index = destination_index, type = type, subtype = subtype }
end

function Public.fetch_iconized_map(destination)
    local type = destination.type

    if type == Public.enum.LOBBY then
        return CoreData.Lobby_iconized_map()
    elseif type == Public.enum.DOCK then
        return CoreData.Dock_iconized_map()
    else
        return destination.iconized_map
    end
end

return Public
