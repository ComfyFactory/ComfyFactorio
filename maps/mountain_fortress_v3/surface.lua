require 'util'
local Global = require 'utils.global'
local Event = require 'utils.event'
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

local function on_init()
    local mgs = game.surfaces['nauvis'].map_gen_settings
    mgs.width = 16
    mgs.height = 16
    game.surfaces['nauvis'].map_gen_settings = mgs
    game.surfaces['nauvis'].clear()

    Public.create_surface()
end

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
            ['tile'] = {treat_missing_as_default = true},
            ['decorative'] = {treat_missing_as_default = true}
        }
    }
    local mine = {}
    mine['control-setting:moisture:bias'] = 0.33
    mine['control-setting:moisture:frequency:multiplier'] = 1

    map_gen_settings.property_expression_names = mine

    if not this.active_surface_index then
        this.active_surface_index = game.create_surface(surface_name, map_gen_settings).index
        game.forces.player.set_spawn_position({-27, 25}, game.surfaces[this.active_surface_index])
    else
        game.forces.player.set_spawn_position({-27, 25}, game.surfaces[this.active_surface_index])
        this.active_surface_index =
            Reset.soft_reset_map(game.surfaces[this.active_surface_index], map_gen_settings, starting_items).index
    end

    local surface = game.surfaces[this.active_surface_index]

    surface.request_to_generate_chunks({-17, 45}, 1)
    surface.force_generate_chunk_requests()

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

Event.on_init(on_init)

return Public
