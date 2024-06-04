require 'utils.start'
local Freeplay = require 'utils.freeplay'
local Autostash = require 'modules.autostash'
local Misc = require 'utils.commands.misc'
local Gui = require 'utils.gui'
local Event = require 'utils.event'

Gui.mod_gui_button_enabled = true
Gui.button_style = 'mod_gui_button'
Gui.set_toggle_button(true)
Gui.set_mod_gui_top_frame(true)

Event.on_init(function ()
	Freeplay.set_enabled(false)
	Autostash.set_enabled(false)
	Misc.set_enabled(false)
end)
