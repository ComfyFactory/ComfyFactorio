local Team = require 'maps.scrap_towny_ffa.team'
local Event = require 'utils.event'

storage.tracked_vehicles = storage.tracked_vehicles or {}

local function on_entity_placed(event)
    local entity = event.entity or event.entity
    if entity and entity.valid and entity.type == 'car' then
        table.insert(storage.tracked_vehicles, entity)
    end
end

local function try_shoot_vehicle(turret, vehicle)
    if not Team.is_friendly_towards(turret.force, vehicle.force)
        and (turret.type == 'electric-turret' and turret.status ~= defines.entity_status.no_power
            or turret.type == 'ammo-turret' and turret.status ~= defines.entity_status.no_ammo)
        and turret.status ~= defines.entity_status.disabled_by_script
        and vehicle.get_driver() == nil
        and vehicle.get_passenger() == nil then
        game.surfaces.nauvis.create_entity(
            {
                name = 'flying-text',
                position = vehicle.position,
                text = 'Turret damages vehicle',
                color = { r = 1, g = 0, b = 0 }
            }
        )
        vehicle.damage(500, turret.force)
    end
end

local function turrets_shoot_empty_vehicles()
    local surface = game.surfaces.nauvis
    for i = #storage.tracked_vehicles, 1, -1 do
        local vehicle = storage.tracked_vehicles[i]
        if vehicle.valid then
            for _, turret in pairs(surface.find_entities_filtered({ type = 'electric-turret', position = vehicle.position, radius = 24 })) do
                if turret.valid then
                    try_shoot_vehicle(turret, vehicle)
                end
            end
            if vehicle.valid then
                for _, turret in pairs(surface.find_entities_filtered({ type = 'ammo-turret', position = vehicle.position, radius = 18 })) do
                    if turret.valid then
                        try_shoot_vehicle(turret, vehicle)
                    end
                end
            end
        else
            table.remove(storage.tracked_vehicles, i)
        end
    end
end

Event.add(defines.events.on_built_entity, on_entity_placed)
Event.add(defines.events.on_robot_built_entity, on_entity_placed)

Event.on_nth_tick(37, turrets_shoot_empty_vehicles)
