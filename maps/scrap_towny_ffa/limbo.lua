local Public = {}

local function initialize_limbo()
    if game.surfaces['limbo'] then
        -- clear the surface
        game.surfaces['limbo'].clear(false)
    else
        game.create_surface('limbo')
    end
    local surface = game.surfaces['limbo']
    surface.generate_with_lab_tiles = true
    surface.peaceful_mode = true
    surface.always_day = true
    surface.freeze_daytime = true
    surface.clear(true)
end

function Public.initialize()
    initialize_limbo()
end

return Public
