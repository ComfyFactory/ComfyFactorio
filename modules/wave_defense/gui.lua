local function create_gui(player)
	local frame = player.gui.top.add({ type = "frame", name = "wave_defense"})
	frame.style.maximal_height = 38

	local label = frame.add({ type = "label", caption = " ", name = "label"})
	label.style.font_color = {r=0.88, g=0.88, b=0.88}
	label.style.font = "default-bold"
	label.style.left_padding = 4
	label.style.right_padding = 4
	label.style.minimal_width = 68
	label.style.font_color = {r=0.33, g=0.66, b=0.9}

	local progressbar = frame.add({ type = "progressbar", name = "progressbar", value = 0})
	progressbar.style.minimal_width = 96
	progressbar.style.maximal_width = 96
	progressbar.style.top_padding = 10
	
	local line = frame.add({type = "line", direction = "vertical"})
	line.style.left_padding = 4
	line.style.right_padding = 4
	
	local label = frame.add({ type = "label", caption = " ", name = "threat", tooltip = "high threat may empower biters"})
	label.style.font_color = {r=0.88, g=0.88, b=0.88}
	label.style.font = "default-bold"
	label.style.left_padding = 4
	label.style.right_padding = 4
	label.style.minimal_width = 10
	label.style.font_color = {r=0.99, g=0.0, b=0.5}
end

local function update_gui(player)
	if not player.gui.top.wave_defense then create_gui(player) end
	player.gui.top.wave_defense.label.caption = "Wave: " .. global.wave_defense.wave_number
	if global.wave_defense.wave_number == 0 then player.gui.top.wave_defense.label.caption = "First wave in " .. math.floor((global.wave_defense.next_wave - game.tick) / 60) + 1 end
	local interval = global.wave_defense.next_wave - global.wave_defense.last_wave
	player.gui.top.wave_defense.progressbar.value = 1 - (global.wave_defense.next_wave - game.tick) / interval
	player.gui.top.wave_defense.threat.caption = "Threat: " .. math.floor(global.wave_defense.threat)
end

return update_gui