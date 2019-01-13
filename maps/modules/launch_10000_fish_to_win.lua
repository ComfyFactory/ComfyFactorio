-- launch 10000 fish into space to win the game -- by mewmew

local event = require 'utils.event'
global.fish_in_space_needed = 10000

local function fish_in_space_toggle_button(player)
	if player.gui.top["fish_in_space_toggle"] then return end
	local button = player.gui.top.add { name = "fish_in_space_toggle", type = "sprite-button", sprite = "item/raw-fish", tooltip = "Fish in Space" }
	button.style.font = "default-bold"
	button.style.minimal_height = 38
	button.style.minimal_width = 38
	button.style.top_padding = 2
	button.style.left_padding = 4
	button.style.right_padding = 4
	button.style.bottom_padding = 2
end

function fish_in_space_gui(player)
	if not global.fish_in_space then return end
	
	fish_in_space_toggle_button(player)
	
	if player.gui.left["fish_in_space"] then player.gui.left["fish_in_space"].destroy() end
	
	if global.fish_in_space >= global.fish_in_space_needed then
		local frame = player.gui.left.add({type = "frame", name = "fish_in_space", direction = "vertical"})
		local label = frame.add({type = "label", caption = "All the fish have been evacuated to cat planet!!"})
		label.style.font = "default-listbox"
		label.style.font_color = { r=0.98, g=0.66, b=0.22}
		local label = frame.add({type = "label", caption = "The biters have calmed down."})
		label.style.font = "default-listbox"
		label.style.font_color = { r=0.98, g=0.66, b=0.22}
		local label = frame.add({type = "label", caption = "The world is now in peace(ful mode)."})
		label.style.font = "default-listbox"
		label.style.font_color = { r=0.98, g=0.66, b=0.22}
		local label = frame.add({type = "label", caption = "Good Job!! =^.^="})
		label.style.font = "default-listbox"
		label.style.font_color = { r=0.98, g=0.66, b=0.22}
		local label = frame.add({type = "label", caption = '(do "/c game.player.surface.peaceful_mode = false" to continue the map)'})
		label.style.font = "default"
		label.style.font_color = { r=0.77, g=0.77, b=0.77}	
	else
		local frame = player.gui.left.add({type = "frame", name = "fish_in_space"})
		local label = frame.add({type = "label", caption = "Fish rescued: "})
		label.style.font_color = {r=0.11, g=0.8, b=0.44}	
			
		
		local progress = global.fish_in_space / global.fish_in_space_needed
		if progress > 1 then progress = 1 end
		local progressbar = frame.add({ type = "progressbar", value = progress})
		progressbar.style.minimal_width = 100
		progressbar.style.maximal_width = 100
		progressbar.style.top_padding = 10
		
		local label = frame.add({type = "label", caption = global.fish_in_space .. "/" .. tostring(global.fish_in_space_needed)})
		label.style.font_color = {r=0.33, g=0.66, b=0.9}	
	end			
end

local function fireworks(entity)
	for x = entity.position.x - 64, entity.position.x + 64, 1 do
		for y = entity.position.y - 64, entity.position.y + 64, 1 do
			if math.random(1,50) == 1 then
				entity.surface.create_entity({name = "big-explosion", position = {x = x, y = y}})
			end
			if math.random(1,50) == 1 then
				entity.surface.create_entity({name = "uranium-cannon-shell-explosion", position = {x = x, y = y}})
			end
			if math.random(1,50) == 1 then
				entity.surface.create_entity({name = "blood-explosion-huge", position = {x = x, y = y}})
			end
			if math.random(1,50) == 1 then
				entity.surface.create_entity({name = "big-artillery-explosion", position = {x = x, y = y}})
			end
		end
	end
end

local function on_rocket_launched(event)	
	local rocket_inventory = event.rocket.get_inventory(defines.inventory.rocket)
	local launched_fish_count = rocket_inventory.get_item_count("raw-fish")
	if launched_fish_count == 0 then return end
	if not global.fish_in_space then global.fish_in_space = 0 end
	global.fish_in_space = global.fish_in_space + launched_fish_count
	
	if global.fish_in_space <= global.fish_in_space_needed then
		game.print(launched_fish_count .. " fish have been saved.", {r=0.11, g=0.8, b=0.44})
	end
	
	for _, player in pairs(game.connected_players) do
		fish_in_space_gui(player)
	end
	
	if not global.fish_in_space_win_condition then
		if global.fish_in_space >= global.fish_in_space_needed then
			event.rocket_silo.surface.peaceful_mode = true
			global.fish_in_space_win_condition = true
			for _, player in pairs(game.connected_players) do
				player.play_sound{path = "utility/game_won", volume_modifier = 1}
			end
			fireworks(event.rocket_silo)			
		end		
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]	
	fish_in_space_gui(player)
end

local function on_gui_click(event)	
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end			
	local player = game.players[event.element.player_index]
	local name = event.element.name
	
	if name == "fish_in_space_toggle" then
		local frame = player.gui.left["fish_in_space"]
		if frame then
			frame.destroy()
		else
			fish_in_space_gui(player)
		end
	end
end

event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_player_joined_game, on_player_joined_game)	
event.add(defines.events.on_rocket_launched, on_rocket_launched)
