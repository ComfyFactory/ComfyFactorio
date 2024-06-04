require 'utils.start'
require 'utils.freeplay'.set('disabled', false)

require 'modules.autostash'.set_enable_autostash_module(false)
require 'utils.commands.misc'.set_enable_clear_corpse_button(false)

local Gui = require 'utils.gui'

Gui.mod_gui_button_enabled = true
Gui.button_style = 'mod_gui_button'
Gui.set_toggle_button(true)
Gui.set_mod_gui_top_frame(true)
