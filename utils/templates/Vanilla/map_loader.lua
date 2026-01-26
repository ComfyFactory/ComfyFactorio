require 'utils.comfy_logo'
require 'modules.map_info'
require 'utils.freeplay'
local Autostash = require 'modules.autostash'
local Misc = require 'utils.commands.misc'
local Gui = require 'utils.gui'
local Event = require 'utils.event'

Gui.mod_gui_button_enabled = true
Gui.button_style = 'mod_gui_button'
Gui.set_mod_gui_top_frame(true)

Event.on_init(
    function()
        Autostash.set_enabled(true)
        Autostash.insert_into_furnace(true)
        Misc.set_enabled(true)
    end
)
