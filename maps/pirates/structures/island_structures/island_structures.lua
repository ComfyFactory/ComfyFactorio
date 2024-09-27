-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

-- local Memory = require 'maps.pirates.memory'
-- local Math = require 'maps.pirates.math'
-- local Balance = require 'maps.pirates.balance'
-- local Common = require 'maps.pirates.common'
-- local Utils = require 'maps.pirates.utils_local'
local _inspect = require("utils.inspect").inspect

local Public = {}
local enum = {
    MATTISSO = "MATTISSO",
    ROC = "ROC",
}
Public[enum.MATTISSO] = require("maps.pirates.structures.island_structures.mattisso.mattisso")
Public[enum.ROC] = require("maps.pirates.structures.island_structures.roc.roc")
Public.enum = enum

return Public
