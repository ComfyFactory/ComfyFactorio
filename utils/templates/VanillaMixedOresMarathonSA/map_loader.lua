require 'utils.start'
local Freeplay = require 'utils.freeplay'
local Autostash = require 'modules.autostash'
local Misc = require 'utils.commands.misc'
local Gui = require 'utils.gui'
local Event = require 'utils.event'
local MixedOres = require 'modules.ores_are_mixed'
MixedOres.settings.mixed_ores_on_nauvis_only = true

Gui.mod_gui_button_enabled = true
Gui.button_style = 'mod_gui_button'
Gui.set_mod_gui_top_frame(true)

local map_gen =
{
    autoplace_controls =
    {
        aquilo_crude_oil =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        calcite =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        coal =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        ["copper-ore"] =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        ["crude-oil"] =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        ["enemy-base"] =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        fluorine_vent =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        fulgora_cliff =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        fulgora_islands =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        gleba_cliff =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        gleba_enemy_base =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        gleba_plants =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        gleba_stone =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        gleba_water =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        ["iron-ore"] =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        lithium_brine =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        nauvis_cliff =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        rocks =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        scrap =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        starting_area_moisture =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        stone =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        sulfuric_acid_geyser =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        trees =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        tungsten_ore =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        ["uranium-ore"] =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        vulcanus_coal =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        vulcanus_volcanism =
        {
            frequency = 1,
            richness = 1,
            size = 1
        },
        water =
        {
            frequency = 1,
            richness = 1,
            size = 1
        }
    },
    autoplace_settings =
    {
        decorative =
        {
            settings =
            {
                ["brown-asterisk"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["brown-asterisk-mini"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["brown-carpet-grass"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["brown-fluff"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["brown-fluff-dry"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["brown-hairy-grass"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["cracked-mud-decal"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["dark-mud-decal"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                garballo =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["garballo-mini-dry"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["green-asterisk"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["green-asterisk-mini"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["green-bush-mini"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["green-carpet-grass"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["green-croton"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["green-desert-bush"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["green-hairy-grass"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["green-pita"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["green-pita-mini"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["green-small-grass"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["light-mud-decal"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["medium-rock"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["medium-sand-rock"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["red-asterisk"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["red-croton"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["red-desert-bush"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["red-desert-decal"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["red-pita"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["sand-decal"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["sand-dune-decal"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["small-rock"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["small-sand-rock"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["tiny-rock"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["white-desert-bush"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                }
            },
            treat_missing_as_default = true
        },
        entity =
        {
            settings =
            {
                ["big-rock"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["big-sand-rock"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                coal =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["copper-ore"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["crude-oil"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                fish =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["huge-rock"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["iron-ore"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                stone =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["uranium-ore"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                }
            },
            treat_missing_as_default = true
        },
        tile =
        {
            settings =
            {
                deepwater =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["dirt-1"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["dirt-2"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["dirt-3"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["dirt-4"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["dirt-5"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["dirt-6"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["dirt-7"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["dry-dirt"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["grass-1"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["grass-2"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["grass-3"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["grass-4"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["red-desert-0"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["red-desert-1"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["red-desert-2"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["red-desert-3"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["sand-1"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["sand-2"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                ["sand-3"] =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                },
                water =
                {
                    frequency = 1,
                    richness = 1,
                    size = 1
                }
            },
            treat_missing_as_default = true
        }
    },
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
    no_enemies_mode = false,
    peaceful_mode = false,
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
    Freeplay.set_enabled(false)
    Autostash.set_enabled(false)
    Misc.set_enabled(false)
    map_gen.seed = game.surfaces.nauvis.map_gen_settings.seed
    game.surfaces.nauvis.map_gen_settings = map_gen
end)

Event.add(defines.events.on_research_finished,
    function (event)
        if event.research.name == 'uranium-processing' then
            game.forces.player.technologies['recycling'].researched = true
        end
    end)
