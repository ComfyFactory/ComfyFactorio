local Public = require 'modules.wave_defense.table'

local Biter_Rolls = require 'modules.wave_defense.biter_rolls'
Public.biter_rolls = Biter_Rolls

local Buried_enemies = require 'modules.wave_defense.buried_enemies'
Public.buried_enemies = Buried_enemies

local Commands = require 'modules.wave_defense.commands'
Public.commands = Commands

local Gui = require 'modules.wave_defense.gui'
Public.gui = Gui

local Side_targets = require 'modules.wave_defense.side_targets'
Public.side_targets = Side_targets

local Threat_events = require 'modules.wave_defense.threat_events'
Public.threat_events = Threat_events

local Threat_values = require 'modules.wave_defense.threat_values'
Public.threat_value = Threat_values

return Public
