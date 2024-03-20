local Global = require 'utils.global'
local Event = require 'utils.event'
local BottomFrame = require 'utils.gui.bottom_frame'
local Task = require 'utils.task_token'

local Public = {}

local this = {
    created_items = {},
    respawn_items = {},
    disabled = false,
    skip_intro = true,
    chart_distance = 0,
    disable_crashsite = false,
    crashed_ship_items = {},
    crashed_debris_items = {},
    custom_surface_name = nil
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local util = require('util')
local crash_site = require('crash-site')

local clear_mod_gui_top_frame_token =
    Task.register(
    function(event)
        local player_index = event.player_index
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end

        if player.gui.top.mod_gui_top_frame and player.gui.top.mod_gui_top_frame.valid then
            player.gui.top.mod_gui_top_frame.destroy()
        end
    end
)

local toggle_screen_for_player_token =
    Task.register(
    function(data)
        local index = data.index
        local state = data.state
        local player = game.get_player(index)
        if not player or not player.valid then
            return
        end
        if state then
            BottomFrame.toggle_player_frame(player, true)
        else
            BottomFrame.toggle_player_frame(player, false)
        end
    end
)

local created_items = function()
    return {
        ['iron-plate'] = 8,
        ['wood'] = 1,
        ['pistol'] = 1,
        ['firearm-magazine'] = 10,
        ['burner-mining-drill'] = 1,
        ['stone-furnace'] = 1
    }
end

local respawn_items = function()
    return {
        ['pistol'] = 1,
        ['firearm-magazine'] = 10
    }
end

local ship_parts = function()
    return crash_site.default_ship_parts()
end

local ship_items = function()
    return {
        ['firearm-magazine'] = 8
    }
end

local debris_items = function()
    return {
        ['iron-plate'] = 8
    }
end

local chart_starting_area = function()
    local r = this.chart_distance or 200
    local force = game.forces.player
    local surface = game.surfaces[1]
    local origin = force.get_spawn_position(surface)
    force.chart(surface, {{origin.x - r, origin.y - r}, {origin.x + r, origin.y + r}})
end

local on_player_joined_game = function(event)
    Task.set_timeout_in_ticks(5, clear_mod_gui_top_frame_token, event)
end

local on_player_created = function(event)
    if not this.modded then
        return
    end
    if this.disabled then
        return
    end

    local player = game.get_player(event.player_index)
    util.insert_safe(player, this.created_items)

    if not this.init_ran then
        --This is so that other mods and scripts have a chance to do remote calls before we do things like charting the starting area, creating the crash site, etc.
        this.init_ran = true

        chart_starting_area()

        if not this.disable_crashsite then
            local surface = player.surface
            surface.daytime = 0.7
            crash_site.create_crash_site(surface, {-5, -6}, util.copy(this.crashed_ship_items), util.copy(this.crashed_debris_items), util.copy(this.crashed_ship_parts))

            util.remove_safe(player, this.crashed_ship_items)
            util.remove_safe(player, this.crashed_debris_items)
            player.get_main_inventory().sort_and_merge()

            if player.character then
                player.character.destructible = false
            end

            if not this.skip_intro then
                BottomFrame.toggle_player_frame(player, false)
                Task.set_timeout_in_ticks(1, toggle_screen_for_player_token, {index = player.index, state = false})
                crash_site.create_cutscene(player, {-5, -4})
            end
            return
        end
    end
end

local on_player_respawned = function(event)
    if not this.modded then
        return
    end
    if this.disabled then
        return
    end
    local player = game.players[event.player_index]
    util.insert_safe(player, this.respawn_items)
end

local on_cutscene_waypoint_reached = function(event)
    if not this.modded then
        return
    end
    if not crash_site.is_crash_site_cutscene(event) then
        return
    end

    local player = game.get_player(event.player_index)

    player.exit_cutscene()
    BottomFrame.toggle_player_frame(player, true)
    Task.set_timeout_in_ticks(5, toggle_screen_for_player_token, {index = player.index, state = true})

    if this.custom_surface_name then
        if player.surface.name == 'nauvis' then
            local get_custom_surface = game.get_surface(this.custom_surface_name)
            if not get_custom_surface or not get_custom_surface.valid then
                return
            end
            player.teleport(get_custom_surface.find_non_colliding_position('character', {64, 64}, 50, 0.5), get_custom_surface.name)
        end
    end
end

local skip_crash_site_cutscene = function(event)
    if not this.modded then
        return
    end

    if event.player_index ~= 1 then
        return
    end
    if event.tick > 2000 then
        return
    end

    local player = game.get_player(event.player_index)
    if player.controller_type == defines.controllers.cutscene then
        player.exit_cutscene()
        BottomFrame.toggle_player_frame(player, true)
        Task.set_timeout_in_ticks(5, toggle_screen_for_player_token, {index = player.index, state = true})
    end
    if this.custom_surface_name then
        if player.surface.name == 'nauvis' then
            local get_custom_surface = game.get_surface(this.custom_surface_name)
            if not get_custom_surface or not get_custom_surface.valid then
                return
            end
            player.teleport(get_custom_surface.find_non_colliding_position('character', {64, 64}, 50, 0.5), get_custom_surface.name)
        end
    end
end

local on_cutscene_cancelled = function(event)
    if not this.modded then
        return
    end

    if this.disabled then
        return
    end

    local player = game.get_player(event.player_index)
    if player.gui.screen.skip_cutscene_label then
        player.gui.screen.skip_cutscene_label.destroy()
    end
    if player.character then
        player.character.destructible = true
    end
    BottomFrame.toggle_player_frame(player, true)
    Task.set_timeout_in_ticks(5, toggle_screen_for_player_token, {index = player.index, state = true})
    if this.custom_surface_name then
        if player.surface.name == 'nauvis' then
            local get_custom_surface = game.get_surface(this.custom_surface_name)
            if not get_custom_surface or not get_custom_surface.valid then
                return
            end
            player.teleport(get_custom_surface.find_non_colliding_position('character', {64, 64}, 50, 0.5), get_custom_surface.name)
        end
    end

    player.zoom = 1.5
end

local freeplay_interface = {
    get_created_items = function()
        return this.created_items
    end,
    set_created_items = function(map)
        this.created_items = map or error("Remote call parameter to freeplay set created items can't be nil.")
    end,
    get_respawn_items = function()
        return this.respawn_items
    end,
    set_respawn_items = function(map)
        this.respawn_items = map or error("Remote call parameter to freeplay set respawn items can't be nil.")
    end,
    set_skip_intro = function(bool)
        this.skip_intro = bool
    end,
    set_disabled = function(bool)
        this.disabled = bool
    end,
    set_custom_surface_name = function(str)
        this.custom_surface_name = str or error('Remote call parameter to freeplay set custom_surface_name must be string')
    end,
    set_chart_distance = function(value)
        this.chart_distance = tonumber(value) or error('Remote call parameter to freeplay set chart distance must be a number')
    end,
    set_disable_crashsite = function(bool)
        this.disable_crashsite = bool
    end,
    get_ship_items = function()
        return this.crashed_ship_items
    end,
    set_ship_items = function(map)
        this.crashed_ship_items = map or error("Remote call parameter to freeplay set created items can't be nil.")
    end,
    get_debris_items = function()
        return this.crashed_debris_items
    end,
    set_debris_items = function(map)
        this.crashed_debris_items = map or error("Remote call parameter to freeplay set respawn items can't be nil.")
    end
}

if not remote.interfaces['freeplay'] then
    remote.add_interface('freeplay', freeplay_interface)
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

Event.on_init(
    function()
        local game_has_mods = is_game_modded()
        if game_has_mods then
            this.modded = true
            this.created_items = created_items()
            this.respawn_items = respawn_items()
            this.crashed_ship_items = ship_items()
            this.crashed_debris_items = debris_items()
            this.crashed_ship_parts = this.crashed_ship_parts or ship_parts()
        end
    end
)

local on_configuration_changed = function()
    this.created_items = this.created_items or created_items()
    this.respawn_items = this.respawn_items or respawn_items()
    this.crashed_ship_items = this.crashed_ship_items or ship_items()
    this.crashed_debris_items = this.crashed_debris_items or debris_items()
    this.crashed_ship_parts = this.crashed_ship_parts or ship_parts()

    if not this.init_ran then
        this.init_ran = #game.players > 0
    end
end

Event.on_configuration_changed(on_configuration_changed)

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_created, on_player_created)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_cutscene_waypoint_reached, on_cutscene_waypoint_reached)
Event.add('crash-site-skip-cutscene', skip_crash_site_cutscene)
Event.add(defines.events.on_cutscene_cancelled, on_cutscene_cancelled)

return Public
