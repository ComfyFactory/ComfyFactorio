local Public = {}

local Event = require 'utils.event'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local CommonFunctions = require 'utils.common'

local zone_size = 100
local beam_type = 'electric-beam-no-sound'
local lifetime_ticks = 4 * 60 * 60 * 60

local function draw_borders(zone)
    local surface = zone.surface
    local right = zone.box.right_bottom.x
    local left = zone.box.left_top.x
    local top = zone.box.left_top.y
    local bottom = zone.box.right_bottom.y
    surface.create_entity({name = beam_type, position = {right, top},
                           source = {right, top}, target = {right, bottom + 1}})    -- intentional offset here to correct visual appearance
    surface.create_entity({name = beam_type, position = {right, bottom},
                           source = {right, bottom}, target = {left, bottom}})
    surface.create_entity({name = beam_type, position = {left, bottom},
                           source = {left, bottom}, target = {left, top}})
    surface.create_entity({name = beam_type, position = {left, top},
                           source = {left, top}, target = {right, top}})
end

local function remove_drawn_borders(zone)
    for _, e in pairs(zone.surface.find_entities_filtered({area = zone.box, name = beam_type})) do
        if e.valid then
            e.destroy()
        end
    end
end

function Public.add_zone(surface, force, center)
    local this = ScenarioTable.get_table()

    local box = {left_top = {x = center.x - zone_size / 2, y = center.y - zone_size / 2},
                right_bottom = {x = center.x + zone_size / 2, y = center.y + zone_size / 2}}
    local zone = {surface = surface, force = force, center = center, box = box,
                  lifetime_end = game.tick + lifetime_ticks}
    this.exclusion_zones[force.name] = zone

    draw_borders(zone)
end

function Public.remove_zone(zone)
    local this = ScenarioTable.get_table()

    remove_drawn_borders(zone)
    this.exclusion_zones[zone.force.name] = nil
    zone.force.print("Your protection zone has expired")
end

local function vector_norm(vector)
    return math.sqrt(vector.x ^ 2 + vector.y ^ 2)
end

local function update_zone_lifetime()
    local this = ScenarioTable.get_table()
    for _, zone in pairs(this.exclusion_zones) do
        if game.tick > zone.lifetime_end then
            Public.remove_zone(zone)
        end
    end
end

local function on_player_changed_position(event)
    local player = game.get_player(event.player_index)
    local surface = player.surface
    if not surface or not surface.valid then
        return
    end

    local this = ScenarioTable.get_table()
    for _, zone in pairs(this.exclusion_zones) do
        if not (zone.force == player.force or zone.force.get_friend(player.force)) then
            if CommonFunctions.point_in_bounding_box(player.position, zone.box) then
                local center_diff = { x = player.position.x - zone.center.x, y = player.position.y - zone.center.y}
                center_diff.x = center_diff.x / vector_norm(center_diff)
                center_diff.y = center_diff.y / vector_norm(center_diff)
                player.teleport({ player.position.x + center_diff.x, player.position.y + center_diff.y}, surface)

                if player.character then
                    -- Kick players out of vehicles if they try to drive in
                    if player.character.driving then
                        player.character.driving = false
                    end

                    -- Damage player
                    player.character.health = player.character.health - 25
                    player.character.surface.create_entity({name = 'water-splash', position = player.position})
                    if player.character.health <= 0 then
                        player.character.die('enemy')
                    end
                end
            end
        end
    end
end

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.on_nth_tick(60, update_zone_lifetime)

return Public
