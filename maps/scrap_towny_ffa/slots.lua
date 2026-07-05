local Event = require 'utils.event'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local FlyingText = require 'utils.functions.flying_texts'

local function on_built_entity(event)
    local this = ScenarioTable.get_table()
    local entity = event.entity
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
        FlyingText.flying_text(nil, surface, entity.position, 'You are not acclimated to this technology!', { r = 0.77, g = 0.0, b = 0.0 })
        player.insert({ name = 'laser-turret', count = 1 })
        entity.destroy()
        return
    end
    local slots = town_center.upgrades.laser_turret.slots
    local locations = town_center.upgrades.laser_turret.locations

    if locations >= slots then
        FlyingText.flying_text(nil, surface, entity.position, 'You do not have enough slots!', { r = 0.77, g = 0.0, b = 0.0 })
        player.insert({ name = 'laser-turret', count = 1 })
        entity.destroy()
        return
    end
    local key = script.register_on_object_destroyed(entity)
    if (this.laser_turrets == nil) then
        this.laser_turrets = {}
    end
    this.laser_turrets[key] = force.index
    locations = locations + 1
    town_center.upgrades.laser_turret.locations = locations

    FlyingText.flying_text(nil, surface, entity.position, 'Using ' .. locations .. '/' .. slots .. ' slots', { r = 1.0, g = 1.0, b = 1.0 })
end

local function on_robot_built_entity(event)
    local this = ScenarioTable.get_table()
    local entity = event.entity
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
        FlyingText.flying_text(nil, surface, entity.position, 'Robot not acclimated to this technology!', { r = 0.77, g = 0.0, b = 0.0 })
        robot.insert({ name = 'laser-turret', count = 1 })
        entity.destroy()
        return
    end
    local slots = town_center.upgrades.laser_turret.slots
    local locations = town_center.upgrades.laser_turret.locations
    if locations >= slots then
        FlyingText.flying_text(nil, surface, entity.position, 'Town does not have enough slots!', { r = 0.77, g = 0.0, b = 0.0 })
        robot.insert({ name = 'laser-turret', count = 1 })
        entity.destroy()
        return
    end
    local key = script.register_on_object_destroyed(entity)
    if (this.laser_turrets == nil) then
        this.laser_turrets = {}
    end
    this.laser_turrets[key] = force.index
    locations = locations + 1
    town_center.upgrades.laser_turret.locations = locations
    FlyingText.flying_text(nil, surface, entity.position, 'Using ' .. locations .. '/' .. slots .. ' slots', { r = 1.0, g = 1.0, b = 1.0 })
end

local function on_object_destroyed(event)
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

Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_object_destroyed, on_object_destroyed)
