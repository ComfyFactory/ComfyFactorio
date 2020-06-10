local Global = require 'utils.global'

local icw = {}
Global.register(
    icw,
    function(tbl)
        icw = tbl
    end
)

local Public = {}

function Public.reset()
    if icw.surfaces then
        for k, surface in pairs(icw.surfaces) do
            if surface and surface.valid then
                game.delete_surface(surface)
            end
        end
    end
    for k, _ in pairs(icw) do
        icw[k] = nil
    end
    icw.doors = {}
    icw.wagons = {}
    icw.trains = {}
    icw.players = {}
    icw.surfaces = {}
    icw.multiple_chests = true
end

function Public.get(key)
    if key then
        return icw[key]
    else
        return icw
    end
end

return Public
