local Global = require 'utils.global'
local Public = require 'maps.mountain_fortress_v3.table'
local surface_name = Public.scenario_name
local zone_settings = Public.zone_settings

local this = {
    active_surface_index = nil,
    surface_name = surface_name
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

function Public.create_surface()
    local map_gen_settings = {
        ['seed'] = math.random(10000, 99999),
        ['width'] = zone_settings.zone_width,
        ['water'] = 0.001,
        ['starting_area'] = 1,
        ['cliff_settings'] = { cliff_elevation_interval = 0, cliff_elevation_0 = 0 },
        ['default_enable_all_autoplace_controls'] = false,
        ['autoplace_settings'] = {
            ['entity'] = { treat_missing_as_default = false },
            ['tile'] = {
                settings = {
                    ['deepwater'] = { frequency = 1, size = 0, richness = 1 },
                    ['deepwater-green'] = { frequency = 1, size = 0, richness = 1 },
                    ['water'] = { frequency = 1, size = 0, richness = 1 },
                    ['water-green'] = { frequency = 1, size = 0, richness = 1 },
                    ['water-mud'] = { frequency = 1, size = 0, richness = 1 },
                    ['water-shallow'] = { frequency = 1, size = 0, richness = 1 }
                },
                treat_missing_as_default = true
            },
            ['decorative'] = { treat_missing_as_default = false }
        },
        property_expression_names = {
            cliffiness = 0,
            ['tile:water:probability'] = -10000,
            ['tile:deep-water:probability'] = -10000
        }
    }

    local mine = {}
    mine['control-setting:moisture:bias'] = 0.33
    mine['control-setting:moisture:frequency:multiplier'] = 1

    map_gen_settings.property_expression_names = mine
    map_gen_settings.default_enable_all_autoplace_controls = false


    if not this.active_surface_index then
        this.active_surface_index = game.surfaces.nauvis.index
        -- this.active_surface_index = game.planets['fulgora'].create_surface(surface_name, map_gen_settings).index
    else
        this.active_surface_index = Public.soft_reset_map(game.surfaces[this.active_surface_index], map_gen_settings).index
    end

    game.surfaces.nauvis.map_gen_settings = map_gen_settings


    -- this.soft_reset_counter = Public.get_reset_counter()

    return this.active_surface_index
end

--- Returns the surface index.
function Public.get_active_surface()
    return this.active_surface
end

--- Returns the surface name.
function Public.get_surface_name()
    return this.surface_name
end

--- Returns the amount of times the server has soft restarted.
function Public.get_reset_counter()
    return this.soft_reset_counter
end

return Public
