require 'utils.table'

local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Team = require 'maps.scrap_towny_ffa.team'
local Building = require 'maps.scrap_towny_ffa.building'
local FlyingText = require 'utils.functions.flying_texts'

storage.tracked_labs = storage.tracked_labs or {}

local function undo_build(entity, player_index, actor, event_robot, force, surface, message)
    local position = entity.position
    local inventory
    if player_index then
        inventory = actor
    else
        inventory = event_robot.get_inventory(defines.inventory.robot_cargo)
    end
    inventory.insert({ name = entity.name, count = 1 })
    entity.destroy()

    Building.build_error_notification(force, surface, position, message, player_index and actor or nil)
end

local function process_building_limit(actor, event)
    local entity = event.entity
    if not entity.valid then return end

    local force = actor.force
    if not Team.is_towny(force) then
        return
    end

    local this = ScenarioTable.get_table()
    local surface = entity.surface
    local town_center = this.town_centers[force.name]
    local starter_laser_slots = 8

    if entity.type == 'electric-turret' then
        local turret_count = town_center.laser_turrets
        local laser_count_is_limited = not force.technologies["laser-turret"].researched

        if laser_count_is_limited and turret_count >= starter_laser_slots then
            undo_build(entity, event.player_index, actor, event.robot, force, surface, "Not enough laser slots. Research laser turret for unlimited slots!")
            return
        end

        if surface.count_entities_filtered({ position = entity.position, type = 'electric-turret', radius = 9, limit = 2 }) == 2 then
            undo_build(entity, event.player_index, actor, event.robot, force, surface, "Too close to other turrets of this type!")
            return
        end

        local event_key = script.register_on_object_destroyed(entity)
        this.laser_turrets_destroy_events[event_key] = force.index
        town_center.laser_turrets = turret_count + 1

        if laser_count_is_limited then
            FlyingText.flying_text(nil, surface, entity.position, 'Using ' .. town_center.laser_turrets .. '/' .. starter_laser_slots .. ' laser slots', { r = 1.0, g = 1.0, b = 1.0 })
        end
    elseif entity.name == 'lab' then
        table.insert(storage.tracked_labs, entity)

        local nearby_beacons = surface.find_entities_filtered(
            {
                area =
                { { entity.position.x - 4, entity.position.y - 4 },
                    { entity.position.x + 4, entity.position.y + 4 }
                },
                name = 'beacon'
            })
        if #nearby_beacons > 0 then
            FlyingText.flying_text(nil, surface, entity.position, "Beacons can't affect labs!", { r = 0.77, g = 0.0, b = 0.0 })
            actor.insert({ name = 'lab', count = 1 })
            entity.destroy()
            return
        end

        local slots_max = 10
        local labs = town_center.labs or 0
        if labs >= slots_max then
            FlyingText.flying_text(nil, surface, entity.position, "You can't have more than 8 labs!", { r = 0.77, g = 0.0, b = 0.0 })
            actor.insert({ name = 'lab', count = 1 })
            entity.destroy()
            return
        end
        town_center.labs = labs + 1
        local event_key = script.register_on_object_destroyed(entity)
        this.labs_destroy_events[event_key] = force.index

        FlyingText.flying_text(nil, surface, entity.position, 'Using ' .. town_center.labs .. '/' .. slots_max .. ' lab slots', { r = 1.0, g = 1.0, b = 1.0 })
    elseif entity.name == 'beacon' then

        local nearby_entities = surface.find_entities_filtered(
            {
                area =
                { { entity.position.x - 4, entity.position.y - 4 },
                    { entity.position.x + 4, entity.position.y + 4 }
                },
                name = 'lab'
            })
        if #nearby_entities > 0 then
            FlyingText.flying_text(nil, surface, entity.position, "Beacons can't affect labs!", { r = 0.77, g = 0.0, b = 0.0 })
            actor.insert({ name = 'beacon', count = 1 })
            entity.destroy()
        end
    end
end

local function on_player_built_entity(event)
    process_building_limit(game.get_player(event.player_index), event)
end

local function on_robot_built_entity(event)
    process_building_limit(event.robot, event)
end

local function labs_cant_have_speed_modules()
    for i = #storage.tracked_labs, 1, -1 do
        local lab = storage.tracked_labs[i]
        if lab.valid then
            local inventory = lab.get_module_inventory()
            if not inventory.is_empty() then
                for ii = #inventory, 1, -1 do
                    if inventory[ii].valid_for_read then
                        if string.find(inventory[ii].name, "speed") then
                            inventory[ii].count = 0
                            FlyingText.flying_text(nil, lab.surface, lab.position, "Labs can't have speed modules!", { r = 0.77, g = 0.0, b = 0.0 })
                        end
                    end
                end
            end
        else
            table.remove(storage.tracked_labs, i)
        end
    end
end

local function on_object_destroyed(event)
    local key = event.registration_number
    local this = ScenarioTable.get_table()
    if this.laser_turrets_destroy_events[key] then
        local index = this.laser_turrets_destroy_events[key]
        local force = game.forces[index]
        if force ~= nil then
            local town_center = this.town_centers[force.name]
            if town_center ~= nil then
                town_center.laser_turrets = town_center.laser_turrets - 1
            end
        end
    end
    if this.labs_destroy_events[key] then
        local index = this.labs_destroy_events[key]
        local force = game.forces[index]
        if force ~= nil then
            local town_center = this.town_centers[force.name]
            if town_center ~= nil then
                town_center.labs = town_center.labs - 1
            end
        end
    end
end

local Event = require 'utils.event'
Event.add(defines.events.on_built_entity, on_player_built_entity)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_object_destroyed, on_object_destroyed)
Event.on_nth_tick(18, labs_cant_have_speed_modules)
