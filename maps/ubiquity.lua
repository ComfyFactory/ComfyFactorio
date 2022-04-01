require 'modules.custom_death_messages'

local ComfyGui = require 'comfy_panel.main'
local Autostash = require 'modules.autostash'
local BottomFrame = require 'comfy_panel.bottom_frame'

local function set_disable_crashsite(value)
	if remote.interfaces["freeplay"] then
		remote.call("freeplay", "set_disable_crashsite", value)
	else
		log("ubiquity.lua tried to call the non-existant remote interface 'freeplay'")
	end
end

local function set_skip_intro(value)
	if remote.interfaces["freeplay"] then
		remote.call("freeplay", "set_skip_intro", value)
	else
		log("ubiquity.lua tried to call the non-existant remote interface 'freeplay'")
	end
end

local function set_created_items()
	if remote.interfaces["freeplay"] then
		local items = {}
		items["pistol"] = 1
		items["firearm-magazine"] = 10
		remote.call("freeplay", "set_created_items", items)
	else
		log("ubiquity.lua tried to call the non-existant remote interface 'freeplay'")
	end
end

local function set_respawn_items()
	if remote.interfaces["freeplay"] then
		local items = {}
		items["fish"] = 5
		remote.call("freeplay", "set_respawn_items", items)
	else
		log("ubiquity.lua tried to call the non-existant remote interface 'freeplay'")
	end
end

local function set_ship_items()
	if remote.interfaces["freeplay"] then
		local items = {}
		items["kr-shelter"] = 1
		items["underground-access"] = 1
		items["basic-tech-card"] = 10
		items["iron-plate"] = 8
		items["copper-plate"] = 8
		remote.call("freeplay", "set_ship_items", items)
	else
		log("ubiquity.lua tried to call the non-existant remote interface 'freeplay'")
	end
end

local function set_debris_items()
	if remote.interfaces["freeplay"] then
		local items = {}
		items["iron-gear-wheel"] = 8
		items["copper-cable"] = 8
		items["iron_stick"] = 8
		remote.call("freeplay", "set_debris_items", items)
	end
end

local function enable_custom_hud_buttons()
	Autostash.insert_into_furnace(true)
	Autostash.insert_into_wagon(true)
	Autostash.bottom_button(true)
	BottomFrame.reset()
	BottomFrame.activate_custom_buttons(true)
end

local function on_init()
	set_created_items()
	set_respawn_items()
	set_ship_items()
	set_debris_items()
	set_disable_crashsite(false)
	set_skip_intro(false)
	ComfyGui.set_mod_gui_top_frame(true)
	enable_custom_hud_buttons()
end

local Event = require 'utils.event'
Event.on_init(on_init)
