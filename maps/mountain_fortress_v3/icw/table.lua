local Global = require 'utils.global'

local this = {}
Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local Public = {}

function Public.reset()
    if this.surfaces then
        for k, surface in pairs(this.surfaces) do
            if surface and surface.valid then
                game.delete_surface(surface)
            end
        end
    end
    for k, _ in pairs(this) do
        this[k] = nil
    end
    this.doors = {}
    this.wagons = {}
    this.speed = 0.1
    this.hazardous_debris = true
    this.current_wagon_index = nil
    this.trains = {}
    this.players = {}
    this.surfaces = {}
    this.multiple_chests = true
    this.wagon_types = {
        ['cargo-wagon'] = true,
        ['artillery-wagon'] = true,
        ['fluid-wagon'] = true,
        ['locomotive'] = true
    }

    this.wagon_areas = {
        ['cargo-wagon'] = {left_top = {x = -30, y = 0}, right_bottom = {x = 30, y = 80}},
        ['artillery-wagon'] = {left_top = {x = -30, y = 0}, right_bottom = {x = 30, y = 80}},
        ['fluid-wagon'] = {left_top = {x = -30, y = 0}, right_bottom = {x = 30, y = 80}},
        ['locomotive'] = {left_top = {x = -30, y = 0}, right_bottom = {x = 30, y = 80}}
    }
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set_wagon_area(tbl)
    if not tbl then
        return
    end

    this.wagon_areas = tbl
end

return Public
