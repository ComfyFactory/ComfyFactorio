-- custom planet generations to be used for scenarios if wanted
local get_noise = require 'utils.math.get_noise'

local Public = {}

local profiles =
{
    aquilo =
    {
        seed_offset = 104729,
        palettes =
        {
            {
                source = { 'snow-flat', 'snow-crests', 'snow-lumpy', 'snow-patchy', 'ice-rough', 'ice-smooth' },
                rim = { 'snow-patchy', 'ice-rough' },
                core = { 'ice-smooth', 'snow-flat' }
            }
        }
    },
    vulcanus =
    {
        seed_offset = 130363,
        palettes =
        {
            {
                source = { 'volcanic-ash-flats', 'volcanic-ash-light', 'volcanic-ash-dark', 'volcanic-ash-soil' },
                rim = { 'volcanic-ash-dark', 'volcanic-ash-light' },
                core = { 'volcanic-ash-flats', 'volcanic-ash-soil' }
            }
        }
    },
    fulgora =
    {
        seed_offset = 155921,
        palettes =
        {
            {
                source = { 'fulgoran-rock', 'fulgoran-dust', 'fulgoran-sand', 'fulgoran-dunes', 'fulgoran-paving' },
                rim = { 'fulgoran-sand', 'fulgoran-dust' },
                core = { 'fulgoran-paving', 'fulgoran-rock' }
            }
        }
    },
    gleba =
    {
        seed_offset = 180503,
        palettes =
        {
            {
                source = { 'midland-turquoise-bark', 'midland-turquoise-bark-2', 'midland-cracked-lichen', 'midland-cracked-lichen-dull', 'midland-cracked-lichen-dark' },
                rim = { 'midland-cracked-lichen-dull', 'midland-cracked-lichen-dark' },
                core = { 'midland-turquoise-bark', 'midland-turquoise-bark-2' }
            },
            {
                source = { 'lowland-brown-blubber', 'lowland-olive-blubber', 'lowland-olive-blubber-2', 'lowland-olive-blubber-3', 'lowland-pale-green' },
                rim = { 'lowland-brown-blubber', 'lowland-olive-blubber' },
                core = { 'lowland-pale-green', 'lowland-olive-blubber-3' }
            }
        }
    }
}

for _, profile in pairs(profiles) do
    profile.tile_palettes = {}
    for _, palette in ipairs(profile.palettes) do
        for _, name in ipairs(palette.source) do
            profile.tile_palettes[name] = palette
        end
    end
end

function Public.generate(surface, area)
    if surface.platform or not surface.planet then
        return
    end
    local profile = profiles[surface.planet.name]
    if not profile then
        return
    end
    local seed = (surface.map_gen_settings.seed + profile.seed_offset) % 4294967296
    local tiles = {}
    for _, tile in pairs(surface.find_tiles_filtered({ area = area })) do
        local position = tile.position
        local palette = profile.tile_palettes[tile.name]
        if palette and position.x * position.x + position.y * position.y > 128 * 128 then
            local noise = get_noise('oasis', position, seed)
            if noise >= 0.5 then
                local variants = noise >= 0.65 and palette.core or palette.rim
                local detail = get_noise('n2', position, seed)
                local name = variants[detail >= 0 and 1 or 2]
                if name ~= tile.name then
                    tiles[#tiles + 1] = { name = name, position = position }
                end
            end
        end
    end
    if #tiles > 0 then
        surface.set_tiles(tiles, false, false, false)
    end
end

return Public
