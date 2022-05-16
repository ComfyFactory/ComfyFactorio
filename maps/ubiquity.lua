local Global = require 'utils.global'
local ComfyGui = require 'comfy_panel.main'
local Autostash = require 'modules.autostash'
local BottomFrame = require 'comfy_panel.bottom_frame'
local Task = require 'utils.task'
local Token = require 'utils.token'
local util = require 'util'
local MGS = require 'modules.ubiquity.map_gen_settings'
local CrashSite = require 'modules.ubiquity.crash-site'
require 'modules.custom_death_messages'
require 'modules.worms_create_oil_patches'
require 'modules.ubiquity.on_tick_schedule'
require 'modules.ubiquity.mining'
require 'modules.ubiquity.rocks_yield_ore'
require 'modules.ubiquity.mining_yields_unknown'
require 'modules.ubiquity.wreckage_yields_scrap'

local Public = {}

local this = {
	-- settings
	disabled = false,
	skip_intro = false,
	disable_crashsite = false,
	chart_distance = 0,
	custom_surface_name = 'nauvis',
	-- state
	init_ran = false,
	crash_site_cutscene_active = false,
	-- items
	created_items = {},
	respawn_items = {},
	crashed_ship_items = {},
	crashed_debris_items = {},
	crashed_ship_parts = {}
}

Global.register(
		this,
		function(t)
			this = t
		end
)

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

local toggle_screen_for_player_token =
Token.register(
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

local function created_items()
	return {
		['pistol'] = 1,
		['firearm-magazine'] = 10,
		["raw-fish"] = 5
	}
end

local function respawn_items()
	return {
		["raw-fish"] = 5
	}
end

local function ship_items()
	return {
		["kr-shelter"] = 1,
		["underground-access"] = 1,
		["basic-tech-card"] = 10,
		["iron-plate"] = 8,
		["copper-plate"] = 8,
	}
end

local function debris_items()
	return {
		["iron-plate"] = 8,
		["copper-plate"] = 8,
		["iron-gear-wheel"] = 8,
		["copper-cable"] = 8,
		["iron-stick"] = 8
	}
end

local function ship_parts()
	return CrashSite.default_ship_parts()
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
	get_skip_intro = function()
		return this.skip_intro
	end,
	set_skip_intro = function(bool)
		this.skip_intro = bool
	end,
	set_chart_distance = function(value)
		this.chart_distance = tonumber(value) or error('Remote call parameter to freeplay set chart distance must be a number')
	end,
	get_disable_crashsite = function()
		return this.disable_crashsite
	end,
	set_disable_crashsite = function(bool)
		this.disable_crashsite = bool
	end,
	get_init_ran = function()
		return this.init_ran
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
	end,
	get_ship_parts = function()
		return this.crashed_ship_parts
	end,
	set_ship_parts = function(parts)
		this.crashed_ship_parts = parts or error("Remote call parameter to freeplay set ship parts can't be nil.")
	end
}

if not remote.interfaces['freeplay'] then
	remote.add_interface('freeplay', freeplay_interface)
end

local function chart_starting_area()
	local r = this.chart_distance or 200
	local force = game.forces.player
	local surface = game.surfaces[1]
	local origin = force.get_spawn_position(surface)
	force.chart(surface, {{origin.x - r, origin.y - r}, {origin.x + r, origin.y + r}})
end

local function set_destructible(player_index, value)
	local player = game.get_player(player_index)
	player.character.destructible = value
end

local build_crash_site =
Token.register(
	function(data)
		local index = data.index
		local player = game.get_player(index)
		local surface = game.surfaces['nauvis']
		surface.daytime = 0.7
		CrashSite.create_crash_site(surface, {x=-5, y=-6}, util.copy(this.crashed_ship_items), util.copy(this.crashed_debris_items), util.copy(this.crashed_ship_parts))
		util.remove_safe(player, this.crashed_ship_items)
		util.remove_safe(player, this.crashed_debris_items)
		player.get_main_inventory().sort_and_merge()
		BottomFrame.toggle_player_frame(player, false)
		Task.set_timeout_in_ticks(1, toggle_screen_for_player_token, {index = index, state = false})
		this.crash_site_cutscene_active = true
		CrashSite.create_cutscene(player, {x=-5, y=-4})
		this.build_ran = true
	end
)

local function on_player_created(event)
	local player = game.get_player(event.player_index)
	util.insert_safe(player, this.created_items)
	if not this.init_ran then
		--This is so that other mods and scripts have a chance to do remote calls before we do things like charting the starting area, creating the crash site, etc.
		this.init_ran = true
		chart_starting_area()
		set_destructible(event.player_index, false)
		Task.set_timeout_in_ticks(60, build_crash_site, {index = player.index})
	end
end

local function on_player_joined_game(event)
	local player = game.get_player(event.player_index)
	if player.online_time == 0 and player.index == 1 then
		player.teleport({0, 0}, game.surfaces['limbo'])
	end
end

local function on_player_respawned(event)
	local player = game.get_player(event.player_index)
	util.insert_safe(player, this.respawn_items)
end

local function on_cutscene_waypoint_reached(event)
	if not this.crash_site_cutscene_active then return end
	if event.waypoint_index < 1 then return end
	this.crash_site_cutscene_active = nil
	local player = game.get_player(event.player_index)
	player.exit_cutscene()
end

local function on_cutscene_cancelled(event)
	local player = game.get_player(event.player_index)
	if player.gui.screen.skip_cutscene_label then
		player.gui.screen.skip_cutscene_label.destroy()
	end
	player.zoom = 1.5
	BottomFrame.toggle_player_frame(player, true)
	Task.set_timeout_in_ticks(5, toggle_screen_for_player_token, {index = player.index, state = true})
	set_destructible(event.player_index, true)
	player.teleport({ x=0,y=0 }, game.surfaces['nauvis'])
end

local function on_player_display_refresh(event)
	CrashSite.on_player_display_refresh(event)
end

local function enable_custom_hud_buttons()
	Autostash.insert_into_furnace(true)
	Autostash.insert_into_wagon(true)
	Autostash.bottom_button(true)
	BottomFrame.reset()
	BottomFrame.activate_custom_buttons(true)
end

local function on_configuration_changed()
	this.created_items = this.created_items or created_items()
	this.respawn_items = this.respawn_items or respawn_items()
	this.crashed_ship_items = this.crashed_ship_items or ship_items()
	this.crashed_debris_items = this.crashed_debris_items or debris_items()
	this.crashed_ship_parts = this.crashed_ship_parts or ship_parts()

	if not this.init_ran then
		this.init_ran = #game.players > 0
	end
end

local function on_init()
	MGS.initialize()
	this.modded = true
	this.created_items = created_items()
	this.respawn_items = respawn_items()
	this.crashed_ship_items = ship_items()
	this.crashed_debris_items = debris_items()
	this.crashed_ship_parts = ship_parts()
	ComfyGui.set_mod_gui_top_frame(true)
	enable_custom_hud_buttons()
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.on_configuration_changed(on_configuration_changed)
Event.add(defines.events.on_player_created, on_player_created)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_cutscene_waypoint_reached, on_cutscene_waypoint_reached)
Event.add(defines.events.on_cutscene_cancelled, on_cutscene_cancelled)
Event.add(defines.events.on_player_display_resolution_changed, on_player_display_refresh)
Event.add(defines.events.on_player_display_scale_changed, on_player_display_refresh)

return Public