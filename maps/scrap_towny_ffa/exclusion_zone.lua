local Public = {}

local math_random = math.random
local table_insert = table.insert
local math_floor = math.floor
local atan2 = math.atan2

local Event = require 'utils.event'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Team = require 'maps.scrap_towny_ffa.team'
local Building = require 'maps.scrap_towny_ffa.building'
local Colors = require 'maps.scrap_towny_ffa.colors'
local Enemy = require 'maps.scrap_towny_ffa.enemy'
local Color = require 'utils.color_presets'
local CommonFunctions = require 'utils.common'

local zone_size = 80

local function draw_borders(zone)
    local surface = zone.surface
    local right = zone.box.right_bottom.x
    local left = zone.box.left_top.x
    local top = zone.box.left_top.y
    local bottom = zone.box.right_bottom.y
    local beam_type = 'electric-beam-no-sound'
    surface.create_entity({name = beam_type, position = {right, top},
                           source = {right, top}, target = {right, bottom + 1}})    -- intentional offset here to correct visual appearance
    surface.create_entity({name = beam_type, position = {right, bottom},
                           source = {right, bottom}, target = {left, bottom}})
    surface.create_entity({name = beam_type, position = {left, bottom},
                           source = {left, bottom}, target = {left, top}})
    surface.create_entity({name = beam_type, position = {left, top},
                           source = {left, top}, target = {right, top}})
end

function Public.add_zone(surface, force, center)
    local this = ScenarioTable.get_table()

    -- Init zone geometry
    local box = {left_top = {x = center.x - zone_size / 2, y = center.y - zone_size / 2},
                right_bottom = {x = center.x + zone_size / 2, y = center.y + zone_size / 2}}
    local zone = {surface = surface, force = force, center = center, box = box}

    table_insert(this.exclusion_zones, zone)
    draw_borders(zone)
end

local function vector_norm(vector)
    return math.sqrt(vector.x ^ 2 + vector.y ^ 2)
end

local function on_player_changed_position(event)
    --TODO: fast 1st level check: count_entities(beam) around zone_size?
    local player = game.get_player(event.player_index)
    local surface = player.surface
    if not surface or not surface.valid then
        return
    end

    local this = ScenarioTable.get_table()
    for _, zone in pairs(this.exclusion_zones) do
        if CommonFunctions.point_in_bounding_box(player.position, zone.box) then
            local center_diff = { x = player.position.x - zone.center.x, y = player.position.y - zone.center.y}
            center_diff.x = center_diff.x / vector_norm(center_diff)
            center_diff.y = center_diff.y / vector_norm(center_diff)
            player.teleport({ player.position.x + center_diff.x, player.position.y + center_diff.y}, surface)

            if player.character then
                player.character.health = player.character.health - 25
                player.character.surface.create_entity({name = 'water-splash', position = player.position})
                if player.character.health <= 0 then
                    player.character.die('enemy')
                end
            end
        end
    end
end

Event.add(defines.events.on_player_changed_position, on_player_changed_position)

return Public
