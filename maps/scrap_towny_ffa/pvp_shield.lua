local Public = {}

local math_sqrt = math.sqrt

local Event = require 'utils.event'
local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local CommonFunctions = require 'utils.common'

local max_size = 120
local beam_type = 'electric-beam-no-sound'
local default_lifetime_ticks = 2 * 60 * 60 * 60
local default_time_to_full_size_ticks = 60 * 60

local function draw_borders(shield)
    local surface = shield.surface
    local right = shield.box.right_bottom.x
    local left = shield.box.left_top.x
    local top = shield.box.left_top.y
    local bottom = shield.box.right_bottom.y

    surface.create_entity({name = beam_type, position = {right, top},
                           source = {right, top}, target = {right, bottom + 0.5}})    -- intentional offset here to correct visual appearance
    surface.create_entity({name = beam_type, position = {right, bottom},
                           source = {right, bottom}, target = {left, bottom + 0.5}})
    surface.create_entity({name = beam_type, position = {left, bottom},
                           source = {left, bottom}, target = {left, top}})
    surface.create_entity({name = beam_type, position = {left, top - 0.5},
                           source = {left, top - 0.5}, target = {right, top}})
end

local function remove_drawn_borders(shield)
    for _, e in pairs(shield.surface.find_entities_filtered({area = shield.box, name = beam_type})) do
        if e.valid then
            e.destroy()
        end
    end
end

local function scale_size_and_box(shield)
    local time_scale = math.min(1, (game.tick - shield.lifetime_start) / shield.time_to_full_size_ticks)
    local scaled_size = time_scale * max_size

    local center = shield.center
    local box = {left_top = { x = center.x - scaled_size / 2, y = center.y - scaled_size / 2},
                 right_bottom = { x = center.x + scaled_size / 2, y = center.y + scaled_size / 2}}
    shield.box = box
    shield.size = scaled_size
end

function Public.add_shield(surface, force, center, lifetime_ticks, time_to_full_size_ticks, is_pause_mode)
    local this = ScenarioTable.get_table()

    if not lifetime_ticks then
        lifetime_ticks = default_lifetime_ticks
    end
    if not time_to_full_size_ticks then
        time_to_full_size_ticks = default_time_to_full_size_ticks
    end

    local shield = {surface = surface, force = force, center = center, max_lifetime_ticks = lifetime_ticks,
                  time_to_full_size_ticks = time_to_full_size_ticks, lifetime_start = game.tick, is_pause_mode = is_pause_mode}

    if is_pause_mode then
        -- Freeze players to avoid AFK abuse
        shield.force.character_running_speed_modifier = -1
        shield.force.print("Your AFK PvP shield is now rolling out. You will be frozen until it expires in " ..
                string.format("%.0f", (Public.remaining_lifetime(shield)) / 60 / 60) .. ' minutes')
    end

    scale_size_and_box(shield)
    this.pvp_shields[force.name] = shield
end

function Public.remove_shield(shield)
    local this = ScenarioTable.get_table()
    remove_drawn_borders(shield)

    if shield.is_pause_mode then
        shield.force.character_running_speed_modifier = 0
    end

    this.pvp_shields[shield.force.name] = nil
    shield.force.print("Your PvP Shield has expired", {r = 1, g = 0, b = 0})
end

function Public.remaining_lifetime(shield)
    return shield.max_lifetime_ticks - (game.tick - shield.lifetime_start)
end

local function update_shield_lifetime()
    local this = ScenarioTable.get_table()
    for _, shield in pairs(this.pvp_shields) do
        if Public.remaining_lifetime(shield) > 0 then
            if shield.size < max_size then
                remove_drawn_borders(shield)
                scale_size_and_box(shield)
                draw_borders(shield)

                -- Push everyone out as we grow (even if they're just standing)
                for _, player in pairs(game.connected_players) do
                    Public.push_enemies_out(player)
                end
            end
        else
            Public.remove_shield(shield)
        end
    end
end

local function vector_norm(vector)
    return math_sqrt(vector.x ^ 2 + vector.y ^ 2)
end

function Public.push_enemies_out(player)
    local this = ScenarioTable.get_table()
    for _, shield in pairs(this.pvp_shields) do
        if not (shield.force == player.force or shield.force.get_friend(player.force) or player.surface ~= shield.surface) then
            if CommonFunctions.point_in_bounding_box(player.position, shield.box) then
                if player.character then
                    -- Push player away from center
                    local center_diff = { x = player.position.x - shield.center.x, y = player.position.y - shield.center.y}
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
Event.on_nth_tick(60, update_shield_lifetime)

return Public
