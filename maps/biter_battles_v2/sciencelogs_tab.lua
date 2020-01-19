-- science logs tab -- 

local Tabs = require 'comfy_panel.main'
local tables = require "maps.biter_battles_v2.tables"
local food_values = tables.food_values

local function get_science_text(food_name)
	return table.concat({"[img=item/", food_name, "][color=",food_values[food_name].color, "]", food_values[food_name].name, "[/color]"})
end

local function add_science_logs(element)
	local science_scrollpanel = element.add { type = "scroll-pane", name = "scroll_pane", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"}
	science_scrollpanel.style.maximal_height = 530
	local t_summary = science_scrollpanel.add { type = "table", name = "science_logs_summary_header_table", column_count = 3 }
	local column_widths = {tonumber(250), tonumber(200), tonumber(200)}
	local headersSummary = {
		[1] = "Science",
		[2] = "Total sent by North",
		[3] = "Total sent by South",
	}
	for _, w in ipairs(column_widths) do
	local label = t_summary.add { type = "label", caption = headersSummary[_] }
	label.style.minimal_width = w
	label.style.maximal_width = w
	label.style.font = "default-bold"
	label.style.font_color = { r=0.98, g=0.66, b=0.22 }
	if _ == 1 then
		label.style.horizontal_align = "center"
		end
	end
	
	if global.science_logs_category_potion == nil then
		local science_text = get_science_text("automation-science-pack")
		global.science_logs_category_potion = { science_text }
		science_text = get_science_text("logistic-science-pack")
		table.insert(global.science_logs_category_potion, science_text)
		science_text = get_science_text("military-science-pack")
		table.insert(global.science_logs_category_potion, science_text)
		science_text = get_science_text("chemical-science-pack")
		table.insert(global.science_logs_category_potion, science_text)
		science_text = get_science_text("production-science-pack")
		table.insert(global.science_logs_category_potion, science_text)
		science_text = get_science_text("utility-science-pack")
		table.insert(global.science_logs_category_potion, science_text)
		science_text = get_science_text("space-science-pack")
		table.insert(global.science_logs_category_potion, science_text)
	end
	if global.science_logs_total_north == nil then
		global.science_logs_total_north = { 0 }
		table.insert(global.science_logs_total_north, 0)
		table.insert(global.science_logs_total_north, 0)
		table.insert(global.science_logs_total_north, 0)
		table.insert(global.science_logs_total_north, 0)
		table.insert(global.science_logs_total_north, 0)
		table.insert(global.science_logs_total_north, 0)
		global.science_logs_total_south = { 0 }
		table.insert(global.science_logs_total_south, 0)
		table.insert(global.science_logs_total_south, 0)
		table.insert(global.science_logs_total_south, 0)
		table.insert(global.science_logs_total_south, 0)
		table.insert(global.science_logs_total_south, 0)
		table.insert(global.science_logs_total_south, 0)
	end
	
	for i = 1, 7, 1 do
		summary_panel_table = science_scrollpanel.add { type = "table", column_count = 3 }
		local label = summary_panel_table.add { type = "label", name = "science_logs_category_potion" .. i, caption = global.science_logs_category_potion[i] }
		label.style.minimal_width = column_widths[1]
		label.style.maximal_width = column_widths[1]
		label.style.horizontal_align = "center"
		local label = summary_panel_table.add { type = "label", name = "science_logs_total_north" .. i, caption = global.science_logs_total_north[i] }
		label.style.minimal_width = column_widths[2]
		label.style.maximal_width = column_widths[2]
		local label = summary_panel_table.add { type = "label", name = "science_logs_total_south" .. i, caption = global.science_logs_total_south[i] }
		label.style.minimal_width = column_widths[3]
		label.style.maximal_width = column_widths[3]
		science_scrollpanel.add({type = "line"})
	end

	science_scrollpanel.add { type = "label", name = "whitespace1", caption = " " }
	
	local t = science_scrollpanel.add { type = "table", name = "science_logs_header_table", column_count = 4 }
	local column_widths = {tonumber(75), tonumber(310), tonumber(165), tonumber(230)}
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
	
	if global.science_logs_date then
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

comfy_panel_tabs["MutagenLog"] = build_config_gui