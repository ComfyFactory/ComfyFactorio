local Global = require 'utils.global'
local surface_name = 'mtn_v3'
local Public = require 'maps.mountain_fortress_v3.table'
local zone_settings = Public.zone_settings

local this = {
    active_surface_index = nil,
    surface_name = surface_name
}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

function Public.create_surface()
    local map_gen_settings = {
        ['seed'] = math.random(10000, 99999),
        ['width'] = zone_settings.zone_width,
        ['water'] = 0.001,
        ['starting_area'] = 1,
        ['cliff_settings'] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
        ['default_enable_all_autoplace_controls'] = true,
        ['autoplace_settings'] = {
            ['entity'] = {treat_missing_as_default = false},
            ['tile'] = {
                settings = {
                    ['deepwater'] = {frequency = 1, size = 0, richness = 1},
                    ['deepwater-green'] = {frequency = 1, size = 0, richness = 1},
                    ['water'] = {frequency = 1, size = 0, richness = 1},
                    ['water-green'] = {frequency = 1, size = 0, richness = 1},
                    ['water-mud'] = {frequency = 1, size = 0, richness = 1},
                    ['water-shallow'] = {frequency = 1, size = 0, richness = 1}
                },
                treat_missing_as_default = true
            },
            ['decorative'] = {treat_missing_as_default = true}
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

    if not this.active_surface_index then
        this.active_surface_index = game.create_surface(surface_name, map_gen_settings).index
    else
        this.active_surface_index = Public.soft_reset_map(game.surfaces[this.active_surface_index], map_gen_settings).index
    end

    -- this.soft_reset_counter = Public.get_reset_counter()

    if not this.cleared_nauvis then
        local mgs = game.surfaces['nauvis'].map_gen_settings
        mgs.width = 16
        mgs.height = 16
        game.surfaces['nauvis'].map_gen_settings = mgs
        game.surfaces['nauvis'].clear()
        this.cleared_nauvis = true
    end

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
