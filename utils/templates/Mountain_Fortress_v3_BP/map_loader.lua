require 'utils.comfy_logo'
local Event = require 'utils.event'
local Freeplay = require 'utils.freeplay'
require 'maps.mountain_fortress_v3.icw.main'
require 'maps.mountain_fortress_v3.ic.main'

local Misc = require 'utils.commands.misc'
local Autostash = require 'modules.autostash'
local BottomFrame = require 'utils.gui.bottom_frame'

local map_gen =
{
    cliff_settings =
    {
        cliff_elevation_0 = 10,
        cliff_elevation_interval = 40,
        cliff_smoothing = 0,
        control = "nauvis_cliff",
        name = "",
        richness = 1
    },
    default_enable_all_autoplace_controls = false,
    no_enemies_mode = true,
    peaceful_mode = true,
    property_expression_names = {},
    starting_area = 2,
    starting_points =
    {
        {
            x = 0,
            y = 5
        }
    },
}

Event.on_init(function ()
    Misc.creative()
    map_gen.seed = game.surfaces.nauvis.map_gen_settings.seed
    game.surfaces.nauvis.map_gen_settings = map_gen
    game.surfaces.nauvis.generate_with_lab_tiles = true
    Freeplay.set_enabled(true)
    Autostash.set_enabled(true)
    Misc.set_enabled(true)
    BottomFrame.activate_custom_buttons(true)
    Misc.bottom_button(true)
    BottomFrame.activate_custom_buttons(true)
    Autostash.bottom_button(true)
    Autostash.insert_into_furnace(true)
    Autostash.insert_into_wagon(true)
end)

Event.add(defines.events.on_player_created, function (event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    player.cheat_mode = true
    player.print('Welcome to the Mountain Fortress v3 BP!')
    player.print('Creative mode is enabled.')
    player.print('You can use all the cheats and features of the game.')
end)

return true
