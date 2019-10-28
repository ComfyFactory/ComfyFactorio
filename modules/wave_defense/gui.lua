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
	label.style.font = "default-bold"
	label.style.left_padding = 4
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 150, g = 0, b = 255}
	
	local label = frame.add({ type = "label", caption = " ", name = "threat_gains", tooltip = "gain / minute"})
	label.style.font = "default"
	label.style.left_padding = 1
	label.style.right_padding = 1
end

--display threat gain/loss per minute during last 15 minutes
local function get_threat_gain()
	local past_index = global.wave_defense.threat_log_index - 900
	if past_index < 1 then past_index = 1 end
	local gain = math.floor((global.wave_defense.threat_log[global.wave_defense.threat_log_index] - global.wave_defense.threat_log[past_index]) / 15)
	return gain
end

local function update_gui(player)
	if not player.gui.top.wave_defense then create_gui(player) end
	player.gui.top.wave_defense.label.caption = "Wave: " .. global.wave_defense.wave_number
	if global.wave_defense.wave_number == 0 then player.gui.top.wave_defense.label.caption = "First wave in " .. math.floor((global.wave_defense.next_wave - game.tick) / 60) + 1 end
	local interval = global.wave_defense.next_wave - global.wave_defense.last_wave
	player.gui.top.wave_defense.progressbar.value = 1 - (global.wave_defense.next_wave - game.tick) / interval
	
	player.gui.top.wave_defense.threat.caption = "Threat: " .. math.floor(global.wave_defense.threat)
	
	if global.wave_defense.wave_number == 0 then
		player.gui.top.wave_defense.threat_gains.caption = ""
		return 
	end
	
	local gain = get_threat_gain()
	local d = global.wave_defense.wave_number / 75
	
	if gain >= 0 then
		player.gui.top.wave_defense.threat_gains.caption = " (+" .. gain .. ")"
		local g = 255 - math.floor(gain / d)
		if g < 0 then g = 0 end
		player.gui.top.wave_defense.threat_gains.style.font_color = {255, g, 0}
	else
		player.gui.top.wave_defense.threat_gains.caption = " (" .. gain .. ")"
		local r = 255 - math.floor(math.abs(gain) / d)
		if r < 0 then r = 0 end
		player.gui.top.wave_defense.threat_gains.style.font_color = {r, 255, 0}
	end
end

return update_gui