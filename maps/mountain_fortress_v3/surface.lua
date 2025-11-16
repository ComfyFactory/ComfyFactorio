local Global = require 'utils.global'
local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local zone_settings = Public.zone_settings

local this =
{
    active_surface_index = nil,
}

local insert = table.insert

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local valid_surfaces =
{
    ['Gulag'] = true,
    ['Init'] = true,
}


local function exclude_surface(surface, state)
    for _, force in pairs(game.forces) do
        force.set_surface_hidden(surface, state or true)
    end
end


function Public.create_surface()
    exclude_surface(game.surfaces.nauvis)

    local map_gen_settings =
    {
        ['seed'] = math.random(10000, 99999),
        ['width'] = zone_settings.zone_width,
        ['water'] = 0.001,
        ['starting_area'] = 1,
        ['cliff_settings'] = { cliff_elevation_interval = 0, cliff_elevation_0 = 0 },
        ['default_enable_all_autoplace_controls'] = false,
        ['autoplace_settings'] =
        {
            ['entity'] = { treat_missing_as_default = false },
            ['tile'] = { treat_missing_as_default = false },
        },
        property_expression_names =
        {
            cliffiness = 0,
            ['tile:water:probability'] = -10000,
            ['tile:deep-water:probability'] = -10000
        }
    }

    if Public.is_modded_pt2 then
        map_gen_settings.autoplace_settings.decorative = { treat_missing_as_default = false }
    else
        map_gen_settings.autoplace_settings.decorative = prototypes.space_location.nauvis.map_gen_settings.autoplace_settings.decorative
    end

    local mine = {}
    mine['control-setting:moisture:bias'] = 0.33
    mine['control-setting:moisture:frequency:multiplier'] = 1

    map_gen_settings.property_expression_names = mine
    map_gen_settings.default_enable_all_autoplace_controls = false

    local starting_planet = Public.get_planet()
    local planets = Public.get_planets()

    if Public.is_modded then
        if not this.active_surface_index then
            this.active_surface_index = game.planets[starting_planet].create_surface().index
        else
            this.active_surface_index = Public.soft_reset_map(game.surfaces[starting_planet], map_gen_settings).index
        end
    else
        if not this.active_surface_index then
            this.active_surface_index = game.surfaces.fortress.index
        else
            this.active_surface_index = Public.soft_reset_map(game.surfaces[this.active_surface_index], map_gen_settings).index
        end
    end

    game.surfaces[starting_planet].map_gen_settings = map_gen_settings

    if has_space_age() then
        for planet, _ in pairs(planets) do
            if planet ~= 'nauvis' then
                game.planets[planet].create_surface()
            end
            local old_settings = game.surfaces[planet].map_gen_settings
            old_settings.seed = map_gen_settings.seed
            old_settings.width = map_gen_settings.width
            game.surfaces[planet].map_gen_settings = old_settings
        end
    end

    -- this.soft_reset_counter = Public.get_reset_counter()

    return this.active_surface_index
end

function Public.create_landing_surface()
    if game.surfaces['Init'] then
        return
    end

    local map_gen_settings =
    {
        autoplace_controls =
        {
            ['coal'] = { frequency = 25, size = 3, richness = 3 },
            ['stone'] = { frequency = 25, size = 3, richness = 3 },
            ['copper-ore'] = { frequency = 25, size = 3, richness = 3 },
            ['iron-ore'] = { frequency = 35, size = 3, richness = 3 },
            ['uranium-ore'] = { frequency = 25, size = 3, richness = 3 },
            ['crude-oil'] = { frequency = 80, size = 3, richness = 1 },
            ['trees'] = { frequency = 0.75, size = 3, richness = 0.1 },
            ['enemy-base'] = { frequency = 15, size = 0, richness = 1 }
        },
        cliff_settings = { cliff_elevation_0 = 1024, cliff_elevation_interval = 10, name = 'cliff' },
        height = 128,
        width = 128,
        default_enable_all_autoplace_controls = false,
        peaceful_mode = false,
        seed = math.random(10000, 99999),
        starting_area = 'very-low',
        starting_points = { { x = 0, y = 0 } },
        terrain_segmentation = 'normal',
        water = 'normal'
    }

    local surface
    if not this.landing_surface_index then
        surface = game.create_surface('Init', map_gen_settings)
    end

    if not surface or not surface.valid then return end

    surface.always_day = true
    surface.request_to_generate_chunks({ 0, 0 }, 1)
    surface.force_generate_chunk_requests()

    exclude_surface(surface)

    local walls = {}
    local tiles = {}

    local area = { left_top = { x = -64, y = -32 }, right_bottom = { x = 64, y = 32 } }
    for x = area.left_top.x, area.right_bottom.x, 1 do
        for y = area.left_top.y, area.right_bottom.y, 1 do
            tiles[#tiles + 1] = { name = 'black-refined-concrete', position = { x = x, y = y } }
            if x == area.left_top.x or x == area.right_bottom.x or y == area.left_top.y or y == area.right_bottom.y then
                walls[#walls + 1] = { name = 'stone-wall', force = 'neutral', position = { x = x, y = y } }
            end
        end
    end
    surface.set_tiles(tiles)
    for _, entity in pairs(walls) do
        local e = surface.create_entity(entity)
        e.destructible = false
        e.minable_flag = false
    end

    rendering.draw_text
    {
        text = 'Init zone',
        surface = surface,
        target = { 0, -50 },
        color = { r = 0.98, g = 0.66, b = 0.22 },
        scale = 10,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }

    rendering.draw_text
    {
        text = 'Map is resetting, please wait a moment. All GUI buttons are disabled at the moment.',
        surface = surface,
        target = { 0, -40 },
        color = { r = 0.98, g = 0.66, b = 0.22 },
        scale = 5,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }

    return this.landing_surface_index
end

--- Returns the surface index.
function Public.get_active_surface()
    return this.active_surface
end

--- Returns the amount of times the server has soft restarted.
function Public.get_reset_counter()
    return this.soft_reset_counter
end

local function is_inside_init_zone(x, y)
    return x > -65 and x < 65 and y > -33 and y < 33
end

Event.add(defines.events.on_chunk_generated, function (event)
    local surface = event.surface
    if not valid_surfaces[surface.name] then
        return
    end

    local left_top = event.area.left_top
    local tiles = {}

    local water_tile = 'water'
    if Public.is_modded_pt2 then
        water_tile = 'empty-space'
    end

    for x = 0, 32, 1 do
        for y = 0, 32, 1 do
            local pos = { x = left_top.x + x, y = left_top.y + y }
            if is_inside_init_zone(pos.x, pos.y) then
                insert(tiles, { name = 'black-refined-concrete', position = pos })
            else
                insert(tiles, { name = water_tile, position = pos })
            end
        end
    end
    surface.set_tiles(tiles, true)
end)

return Public
