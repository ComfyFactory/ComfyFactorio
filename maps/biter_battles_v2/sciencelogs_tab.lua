-- science logs tab -- 

local Tabs = require 'comfy_panel.main'


local function add_science_logs(element)
	local t = element.add { type = "table", name = "science_logs_header_table", column_count = 4 }
	local column_widths = {tonumber(100), tonumber(400), tonumber(145), tonumber(145)}
	for _, w in ipairs(column_widths) do
		local label = t.add { type = "label", caption = "" }
		label.style.minimal_width = w
		label.style.maximal_width = w
	end

	local headers = {
		[1] = "Date",
		[2] = "Science details",
		[3] = "Evo jump",
		[4] = "Threat jump",
	}
	
	for k, v in ipairs(headers) do
		local label = t.add {
			type = "label",
			name = "science_logs_panel_header_" .. k,
			caption = v
		}
		label.style.font = "default-bold"
		label.style.font_color = { r=0.98, g=0.66, b=0.22 }
	end

	-- special style on first header
	local label = t["science_logs_panel_header_1"]
	label.style.minimal_width = 36
	label.style.maximal_width = 36
	label.style.horizontal_align = "right"
	
	-- List management
	local science_panel_table = element.add { type = "scroll-pane", name = "scroll_pane", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"}
	science_panel_table.style.maximal_height = 530
	science_panel_table = science_panel_table.add { type = "table", name = "science_panel_table", column_count = 4, draw_horizontal_lines = true }
	if global.science_logs_date then
		for i = 1, #global.science_logs_date, 1 do
			local label = science_panel_table.add { type = "label", name = "science_logs_date" .. i, caption = global.science_logs_date[i] }
			label.style.minimal_width = column_widths[1]
			label.style.maximal_width = column_widths[1]
			local label = science_panel_table.add { type = "label", name = "science_logs_text" .. i, caption = global.science_logs_text[i] }
			label.style.minimal_width = column_widths[2]
			label.style.maximal_width = column_widths[2]
			local label = science_panel_table.add { type = "label", name = "science_logs_evo_jump" .. i, caption = global.science_logs_evo_jump[i] }
			label.style.minimal_width = column_widths[3]
			label.style.maximal_width = column_widths[3]
			local label = science_panel_table.add { type = "label", name = "science_logs_threat" .. i, caption = global.science_logs_threat[i] }
			label.style.minimal_width = column_widths[4]
			label.style.maximal_width = column_widths[4]
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

comfy_panel_tabs["ScienceLogs"] = build_config_gui


local event = require 'utils.event'
event.add(defines.events.on_gui_click, on_gui_click)