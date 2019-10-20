--[[
Comfy Panel

To add a tab, insert into the "comfy_panel_tabs" table.

Example: comfy_panel_tabs["mapscores"] = draw_map_scores
draw_map_scores would be a function with the player and the frame as arguments

]]

comfy_panel_tabs = {}

function comfy_panel_get_active_frame(player)
	if not player.gui.left.comfy_panel then return false end
	if not player.gui.left.comfy_panel.tabbed_pane.selected_tab_index then return player.gui.left.comfy_panel.tabbed_pane.tabs[1].content end
	return player.gui.left.comfy_panel.tabbed_pane.tabs[player.gui.left.comfy_panel.tabbed_pane.selected_tab_index].content 
end

function comfy_panel_refresh_active_tab(player)
	local frame = comfy_panel_get_active_frame(player)
	if not frame then return end
	comfy_panel_tabs[frame.name](player, frame)
end

local function top_button(player)
	if player.gui.top["comfy_panel_top_button"] then return end
	local button = player.gui.top.add({type = "sprite-button", name = "comfy_panel_top_button", sprite = "item/raw-fish"})
	button.style.minimal_height = 38
	button.style.minimal_width = 38
	button.style.padding = -2	
end

local function main_frame(player)
	if player.gui.left["comfy_panel"] then return end
	local frame = player.gui.left.add({type = "frame", name = "comfy_panel"})
	frame.style.margin = 8
	
	local tabbed_pane = frame.add({type = "tabbed-pane", name = "tabbed_pane"})
		
	for name, func in pairs(comfy_panel_tabs) do
		if name == "Admin" then
			if player.admin then
				local tab = tabbed_pane.add({type = "tab", caption = name})
				local frame = tabbed_pane.add({type = "frame", name = name, direction = "vertical"})
				frame.style.minimal_height = 480
				frame.style.minimal_width = 800
				frame.style.maximal_width = 800
				tabbed_pane.add_tab(tab, frame)
			end
		else
			local tab = tabbed_pane.add({type = "tab", caption = name})
			local frame = tabbed_pane.add({type = "frame", name = name, direction = "vertical"})
			frame.style.minimal_height = 480
			frame.style.minimal_width = 800
			frame.style.maximal_width = 800
			tabbed_pane.add_tab(tab, frame)
		end
	end
	
	comfy_panel_refresh_active_tab(player)
end

local function on_player_joined_game(event)
	top_button(game.players[event.player_index])
end

local function on_gui_click(event)
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.player_index]
	
	if event.element.name == "comfy_panel_top_button" then
		if player.gui.left.comfy_panel then
			player.gui.left.comfy_panel.destroy()
			return
		else
			main_frame(player)
			return
		end	
	end
	
	if not event.element.caption then return end
	if event.element.type ~= "tab" then return end
	comfy_panel_refresh_active_tab(player)
end

local event = require 'utils.event'
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_gui_click, on_gui_click)