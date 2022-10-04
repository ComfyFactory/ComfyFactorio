local ScenarioTable = require 'maps.scrap_towny_ffa.table'

-- called whenever a player places an item
local function on_built_entity(event)
    local this = ScenarioTable.get_table()
    local entity = event.created_entity
    if not entity.valid then
        return
    end
    if entity.name ~= 'laser-turret' then
        return
    end
    local player = game.players[event.player_index]
    local force = player.force
    local town_center = this.town_centers[force.name]
    local surface = entity.surface
    if force.index == game.forces['player'].index or force.index == game.forces['rogue'].index or town_center == nil then
        surface.create_entity(
            {
                name = 'flying-text',
                position = entity.position,
                text = 'You are not acclimated to this technology!',
                color = {r = 0.77, g = 0.0, b = 0.0}
            }
        )
        player.insert({name = 'laser-turret', count = 1})
        entity.destroy()
        return
    end
    local slots = town_center.upgrades.laser_turret.slots
    local locations = town_center.upgrades.laser_turret.locations

    if locations >= slots then
        surface.create_entity(
            {
                name = 'flying-text',
                position = entity.position,
                text = 'You do not have enough slots!',
                color = {r = 0.77, g = 0.0, b = 0.0}
            }
        )
        player.insert({name = 'laser-turret', count = 1})
        entity.destroy()
        return
    end
    local key = script.register_on_entity_destroyed(entity)
    if (this.laser_turrets == nil) then
        this.laser_turrets = {}
    end
    this.laser_turrets[key] = force.index
    locations = locations + 1
    town_center.upgrades.laser_turret.locations = locations
    surface.create_entity(
        {
            name = 'flying-text',
            position = entity.position,
            text = 'Using ' .. locations .. '/' .. slots .. ' slots',
            color = {r = 1.0, g = 1.0, b = 1.0}
        }
    )
end

-- called whenever a robot places an item
local function on_robot_built_entity(event)
    local this = ScenarioTable.get_table()
    local entity = event.created_entity
    if not entity.valid then
        return
    end
    if entity.name ~= 'laser-turret' then
        return
    end
    local robot = event.robot
    local force = robot.force
    local town_center = this.town_centers[force.name]
    local surface = entity.surface
    if force.index == game.forces['player'].index or force.index == game.forces['rogue'].index or town_center == nil then
        surface.create_entity(
            {
                name = 'flying-text',
                position = entity.position,
                text = 'Robot not acclimated to this technology!',
                color = {r = 0.77, g = 0.0, b = 0.0}
            }
        )
        robot.insert({name = 'laser-turret', count = 1})
        entity.destroy()
        return
    end
    local slots = town_center.upgrades.laser_turret.slots
    local locations = town_center.upgrades.laser_turret.locations
    if locations >= slots then
        surface.create_entity(
            {
                name = 'flying-text',
                position = entity.position,
                text = 'Town does not have enough slots!',
                color = {r = 0.77, g = 0.0, b = 0.0}
            }
        )
        robot.insert({name = 'laser-turret', count = 1})
        entity.destroy()
        return
    end
    local key = script.register_on_entity_destroyed(entity)
    if (this.laser_turrets == nil) then
        this.laser_turrets = {}
    end
    this.laser_turrets[key] = force.index
    locations = locations + 1
    town_center.upgrades.laser_turret.locations = locations
    surface.create_entity(
        {
            name = 'flying-text',
            position = entity.position,
            text = 'Using ' .. locations .. '/' .. slots .. ' slots',
            color = {r = 1.0, g = 1.0, b = 1.0}
        }
    )
end

-- called whenever a laser-turret is removed from the map
local function on_entity_destroyed(event)
    local key = event.registration_number
    local this = ScenarioTable.get_table()
    if (this.laser_turrets == nil) then
        return
    end
    if (this.laser_turrets[key] ~= nil) then
        local index = this.laser_turrets[key]
        local force = game.forces[index]
        if force ~= nil then
            local town_center = this.town_centers[force.name]
            if town_center ~= nil then
                if force.index == game.forces['player'].index or force.index == game.forces['rogue'].index or town_center == nil then
                    return
                end
                local locations = town_center.upgrades.laser_turret.locations
                locations = locations - 1
                if (locations < 0) then
                    locations = 0
                end
                town_center.upgrades.laser_turret.locations = locations
            end
        end
    end
end

local Event = require 'utils.event'
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_entity_destroyed, on_entity_destroyed)
