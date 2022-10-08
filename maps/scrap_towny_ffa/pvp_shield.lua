local Public = {}

local Event = require 'utils.event'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local CommonFunctions = require 'utils.common'

local max_size = 120
local beam_type = 'electric-beam-no-sound'
local max_lifetime_ticks = 4 * 60 * 60 * 60
local time_to_full_size_ticks = 60 * 60

local function draw_borders(zone)
    local surface = zone.surface
    local right = zone.box.right_bottom.x
    local left = zone.box.left_top.x
    local top = zone.box.left_top.y
    local bottom = zone.box.right_bottom.y

    surface.create_entity({name = beam_type, position = {right, top},
                           source = {right, top}, target = {right, bottom + 0.5}})    -- intentional offset here to correct visual appearance
    surface.create_entity({name = beam_type, position = {right, bottom},
                           source = {right, bottom}, target = {left, bottom + 0.5}})
    surface.create_entity({name = beam_type, position = {left, bottom},
                           source = {left, bottom}, target = {left, top}})
    surface.create_entity({name = beam_type, position = {left, top - 0.5},
                           source = {left, top - 0.5}, target = {right, top}})
end

local function remove_drawn_borders(zone)
    for _, e in pairs(zone.surface.find_entities_filtered({area = zone.box, name = beam_type})) do
        if e.valid then
            e.destroy()
        end
    end
end

local function scale_size_and_box(zone)
    local time_scale = math.min(1, (game.tick - zone.lifetime_start) / time_to_full_size_ticks)
    local scaled_size = time_scale * max_size

    local center = zone.center
    local box = {left_top = { x = center.x - scaled_size / 2, y = center.y - scaled_size / 2},
                 right_bottom = { x = center.x + scaled_size / 2, y = center.y + scaled_size / 2}}
    zone.box = box
    zone.size = scaled_size
end

function Public.add_zone(surface, force, center)
    local this = ScenarioTable.get_table()

    local zone = {surface = surface, force = force, center = center, lifetime_start = game.tick}
    scale_size_and_box(zone)
    this.pvp_shields[force.name] = zone
end

function Public.remove_zone(zone)
    local this = ScenarioTable.get_table()
    remove_drawn_borders(zone)
    this.pvp_shields[zone.force.name] = nil
    zone.force.print("Your PvP Shield has expired", {r = 1, g = 0, b = 0})
end

function Public.remaining_lifetime(zone)
    return max_lifetime_ticks - (game.tick - zone.lifetime_start)
end

local function vector_norm(vector)
    return math.sqrt(vector.x ^ 2 + vector.y ^ 2)
end

local function update_zone_lifetime()
    local this = ScenarioTable.get_table()
    for _, zone in pairs(this.pvp_shields) do
        if Public.remaining_lifetime(zone) > 0 then
            if zone.size < max_size then
                remove_drawn_borders(zone)
                scale_size_and_box(zone)
                draw_borders(zone)

                -- Push everyone out as we grow (even if they're just standing)
                for _, player in pairs(game.connected_players) do
                    Public.push_enemies_out(player)
                end
            end
        else
            Public.remove_zone(zone)
        end
    end
end

function Public.push_enemies_out(player)
    local this = ScenarioTable.get_table()
    for _, zone in pairs(this.pvp_shields) do
        if not (zone.force == player.force or zone.force.get_friend(player.force) or player.surface ~= zone.surface) then
            if CommonFunctions.point_in_bounding_box(player.position, zone.box) then
                if player.character then
                    -- Push player away from center
                    local center_diff = { x = player.position.x - zone.center.x, y = player.position.y - zone.center.y}
                    center_diff.x = center_diff.x / vector_norm(center_diff)
                    center_diff.y = center_diff.y / vector_norm(center_diff)
                    player.teleport({ player.position.x + center_diff.x, player.position.y + center_diff.y}, player.surface)

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

local function on_player_changed_position(event)
    local player = game.get_player(event.player_index)
    local surface = player.surface
    if not surface or not surface.valid then
        return
    end

    Public.push_enemies_out(player)
end

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.on_nth_tick(60, update_zone_lifetime)

return Public
