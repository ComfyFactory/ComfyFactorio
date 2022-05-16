local Public = require 'modules.rpg.table'

local Spells = require 'modules.rpg.spells'
Public.spells = Spells

local Bullets = require 'modules.rpg.explosive_gun_bullets'
Public.explosive_bullet = Bullets

local RangeBuffs = require 'modules.rpg.range_buffs'
Public.range_buffs = RangeBuffs

local Functions = require 'modules.rpg.functions'
Public.functions = Functions

local Gui = require 'modules.rpg.gui'
Public.gui = Gui

local Settings = require 'modules.rpg.settings'
Public.settings = Settings

local Commands = require 'modules.rpg.commands'
Public.commands = Commands

return Public
