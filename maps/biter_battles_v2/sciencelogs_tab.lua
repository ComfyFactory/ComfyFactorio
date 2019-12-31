-- science logs tab -- 

local Tabs = require 'comfy_panel.main'


local function add_science_logs(element)
	local t = element.add { type = "table", name = "science_logs_header_table", column_count = 4 }
	local column_widths = {tonumber(90), tonumber(340), tonumber(170), tonumber(190)}
	local headers = {
		[1] = "Time",
		[2] = "Details",
		[3] = "Evo jump",
		[4] = "Threat jump",
	}
	for _, w in ipairs(column_widths) do
	local label = t.add { type = "label", caption = headers[_] }
	label.style.minimal_width = w
	label.style.maximal_width = w
	label.style.font = "default-bold"
	label.style.font_color = { r=0.98, g=0.66, b=0.22 }
	if _ == 1 then
		label.style.horizontal_align = "center"
		end
	end
	
	-- List management
	if global.science_logs_date then
		local science_scrollpanel = element.add { type = "scroll-pane", name = "scroll_pane", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"}
		science_scrollpanel.style.maximal_height = 530
		for i = 1, #global.science_logs_date, 1 do
			science_panel_table = science_scrollpanel.add { type = "table", column_count = 4 }
			local label = science_panel_table.add { type = "label", name = "science_logs_date" .. i, caption = global.science_logs_date[i] }
			label.style.minimal_width = column_widths[1]
			label.style.maximal_width = column_widths[1]
			label.style.horizontal_align = "center"
			local label = science_panel_table.add { type = "label", name = "science_logs_text" .. i, caption = global.science_logs_text[i] }
			label.style.minimal_width = column_widths[2]
			label.style.maximal_width = column_widths[2]
			local label = science_panel_table.add { type = "label", name = "science_logs_evo_jump" .. i, caption = global.science_logs_evo_jump[i].."   [color=200,200,200](+"..global.science_logs_evo_jump_difference[i]..")[/color]" }
			label.style.minimal_width = column_widths[3]
			label.style.maximal_width = column_widths[3]
			local label = science_panel_table.add { type = "label", name = "science_logs_threat" .. i, caption = global.science_logs_threat[i].."   [color=200,200,200](+"..global.science_logs_threat_jump_difference[i]..")[/color]" }
			label.style.minimal_width = column_widths[4]
			label.style.maximal_width = column_widths[4]
			science_scrollpanel.add({type = "line"})
		end
	end
end


local build_config_gui = (function (player, frame)		
	frame.clear()
	add_science_logs(frame)
end)

local function on_gui_click(event)
	if not event.element then return end
	if not event.element.valid then return end
end

comfy_panel_tabs["MutagenLog"] = build_config_gui


local event = require 'utils.event'
event.add(defines.events.on_gui_click, on_gui_click)