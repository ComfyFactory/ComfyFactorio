local Event = require 'utils.event'
local Global = require 'utils.global'

local Public = {}
--by hanakocz
--module to alternate what happens when landmine gets detonated
--nuke module: there is 1 in nuke_chance chance that the landmine was hidden nuclear device
--vehicle module: landmine causes affected vehicles to lose part of speed
--vehicle_slowdown should be <0, 1>, where 1 is no effect and 0 is full loss of speed
--can also add bonus damage to hit vehicles, as landmines should be counterplay to tanks,
--  while just buffing their damage causes players being oneshot and that's not fun.
local this = {
    nuke_landmines = false,
    nuke_chance = 512,
    vehicle_effects = true,
    bonus_damage_to_vehicles = 100,
    vehicle_slowdown = 0.4
}
Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local function detonate_nuke(entity)
    local surface = entity.surface
    surface.create_entity({name = 'atomic-rocket', position = entity.position, force = entity.force, speed = 1, max_range = 800, target = entity, source = entity})
end

local function hit_car(car, hitting_force)
    if not car or not car.valid then return end
    car.speed = car.speed * this.vehicle_slowdown
    if this.bonus_damage_to_vehicles > 0 then
        --cars do have no resistance to explosions and 450 hp
        --tanks do have 15/70% resistance to explosions and 2000 hp, so get (damage - 15) * (1 - 0.70) actual damage
        car.damage(this.bonus_damage_to_vehicles, hitting_force or 'enemy', 'explosion')
    end
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    if entity.type == 'land-mine' and entity.armed then
        if this.vehicle_effects then
            local surface = entity.surface
            local cars = surface.find_entities_filtered{type = 'car', position = entity.position, radius = 6}
            for _, car in pairs(cars) do
                if car.force.is_enemy(entity.force) then
                    hit_car(car, entity.force)
                end
            end
        end
        if this.nuke_landmines then
            if math.random(1, this.nuke_chance) == 1 then
                detonate_nuke(entity)
            end
        end
    end
end

--- Forces a value of nuke_landmines
---@param boolean
function Public.enable_nuke_landmines(boolean)
    this.nuke_landmines = boolean or false

    return this.nuke_landmines
end

--- Forces a value of vehicle_effects
---@param boolean
function Public.enable_vehicle_effects(boolean)
    this.vehicle_effects = boolean or false

    return this.vehicle_effects
end

--- Forces a number for bonus_damage_to_vehicles
---@param number
function Public.set_bonus_damage_to_vehicles(number)
    if number and type(number) == 'number' then
        this.bonus_damage_to_vehicles = number or 0
    end

    return this.bonus_damage_to_vehicles
end

--- Forces a number for vehicle_slowdown
---@param number
function Public.set_vehicle_slowdown(number)
    if number and type(number) == 'number' then
        this.vehicle_slowdown = number or 1
    end

    return this.vehicle_slowdown
end

Event.add(defines.events.on_entity_died, on_entity_died)

return Public
