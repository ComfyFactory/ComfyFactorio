require 'util'
local Global = require 'utils.global'
local surface_name = 'mountain_fortress_v3'
local level_width = require 'maps.mountain_fortress_v3.terrain'.level_width
local Reset = require 'maps.mountain_fortress_v3.soft_reset'

local Public = {}

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

local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16, ['rail'] = 16, ['wood'] = 16, ['explosives'] = 32}

function Public.create_surface()
    local map_gen_settings = {
        ['seed'] = math.random(10000, 99999),
        ['width'] = level_width,
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
        this.active_surface_index =
            Reset.soft_reset_map(game.surfaces[this.active_surface_index], map_gen_settings, starting_items).index
    end

    return this.active_surface_index
end

function Public.get_active_surface()
    return this.active_surface
end

function Public.get_surface_name()
    return this.surface_name
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

--[[


    local function clear_nauvis()
        local surface = game.surfaces['nauvis']
        local mgs = surface.map_gen_settings
        mgs.width = 16
        mgs.height = 16
        surface.map_gen_settings = mgs
        surface.clear()
        surface.request_to_generate_chunks({0, 0}, 0.5)
        surface.force_generate_chunk_requests()

        game.forces.player.chart(surface, {{-16, -16}, {16, 16}})
    end

    local function place_grid()
        local surface = game.surfaces['nauvis']
        rendering.draw_text {
            text = 'How did you end up here? O_o',
            surface = surface,
            target = {0, -12},
            color = {r = 0.98, g = 0.66, b = 0.22},
            scale = 3,
            font = 'heading-1',
            alignment = 'center',
            scale_with_zoom = false
        }
        local e =
            surface.create_entity(
            {
                name = 'player-port',
                position = {0, 5},
                force = 'neutral',
                create_build_effect_smoke = false
            }
        )
        e.destructible = false
        e.minable = false
        e.operable = false
    end

    local clear_nauvis_token = Token.register(clear_nauvis)
    local place_grid_token = Token.register(place_grid)

 ]]
return Public
