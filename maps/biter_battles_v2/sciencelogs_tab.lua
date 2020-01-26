-- science logs tab -- 

local Tabs = require 'comfy_panel.main'
local tables = require "maps.biter_battles_v2.tables"
local event = require 'utils.event'
local bb_config = require "maps.biter_battles_v2.config"
local food_values = tables.food_values
local dropdown_users_choice_force = {}
local dropdown_users_choice_science = {}
local dropdown_users_choice_evo_filter = {}
local frame_sciencelogs = nil

local function get_science_text(food_name)
	return table.concat({"[img=item/", food_name, "][color=",food_values[food_name].color, "]", food_values[food_name].name, "[/color]"})
end

local function add_science_logs(player, element)
	local science_scrollpanel = element.add { type = "scroll-pane", name = "scroll_pane", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"}
	science_scrollpanel.style.maximal_height = 530
	
	local t_summary = science_scrollpanel.add { type = "table", name = "science_logs_summary_header_table", column_count = 3 }
	local column_widths = {tonumber(250), tonumber(200), tonumber(200)}
	local headersSummary = {
		[1] = "  Science",
		[2] = "Total sent by North",
		[3] = "Total sent by South",
	}
	for _, w in ipairs(column_widths) do
	local label = t_summary.add { type = "label", caption = headersSummary[_] }
	label.style.minimal_width = w
	label.style.maximal_width = w
	label.style.font = "default-bold"
	label.style.font_color = { r=0.98, g=0.66, b=0.22 }
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
		local label = summary_panel_table.add { type = "label", name = "science_logs_total_north" .. i, caption = global.science_logs_total_north[i] }
		label.style.minimal_width = column_widths[2]
		label.style.maximal_width = column_widths[2]
		local label = summary_panel_table.add { type = "label", name = "science_logs_total_south" .. i, caption = global.science_logs_total_south[i] }
		label.style.minimal_width = column_widths[3]
		label.style.maximal_width = column_widths[3]
		science_scrollpanel.add({type = "line"})
	end

--	science_scrollpanel.add { type = "label", name = "whitespace1", caption = " " }
	
	local forces_list = { "all teams" }
	table.insert(forces_list, "north")
	table.insert(forces_list, "south")
	local science_list = { "all science" }
	table.insert(science_list, "very high tier (white, yellow, purple)")
	table.insert(science_list, " high tier (white, yellow, purple, blue)")
	table.insert(science_list, " mid+ tier (white, yellow, purple, blue, mil)")
	table.insert(science_list, "white")
	table.insert(science_list, "yellow")
	table.insert(science_list, "purple")
	table.insert(science_list, "blue")
	table.insert(science_list, "mil")
	table.insert(science_list, "green")
	table.insert(science_list, "red")
	local evofilter_list = { "all evo jump" }
	table.insert(evofilter_list, "no 0 evo jump")
	table.insert(evofilter_list, "10+ only")
	table.insert(evofilter_list, "5+ only")
	table.insert(evofilter_list, "4+ only")
	table.insert(evofilter_list, "3+ only")
	table.insert(evofilter_list, "2+ only")
	table.insert(evofilter_list, "1+ only")
	if dropdown_users_choice_force[player.name] == nil then
		dropdown_users_choice_force[player.name] = 1
	end
	if dropdown_users_choice_science[player.name] == nil then
		dropdown_users_choice_science[player.name] = 1
	end
	if dropdown_users_choice_evo_filter[player.name] == nil then
		dropdown_users_choice_evo_filter[player.name] = 1
	end
	
	local dropdown_force = science_scrollpanel.add { name = "dropdown-force", type = "drop-down", items = forces_list, selected_index = dropdown_users_choice_force[player.name] }
	local dropdown_science = science_scrollpanel.add { name = "dropdown-science", type = "drop-down", items = science_list, selected_index = dropdown_users_choice_science[player.name] }
	local dropdown_evofilter = science_scrollpanel.add { name = "dropdown-evofilter", type = "drop-down", items = evofilter_list, selected_index = dropdown_users_choice_evo_filter[player.name] }
	
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
	
	local n = bb_config.north_side_team_name
	local s = bb_config.south_side_team_name
	if global.tm_custom_name["north"] then n = global.tm_custom_name["north"] end
	if global.tm_custom_name["south"] then s = global.tm_custom_name["south"] end	
	local team_strings = {
		["north"] = table.concat({"[color=120, 120, 255]", n, "[/color]"}),
		["south"] = table.concat({"[color=255, 65, 65]", s, "[/color]"})
	}
	if global.science_logs_date then
		for i = 1, #global.science_logs_date, 1 do
			local real_force_name = global.science_logs_fed_team[i]
			local custom_force_name = team_strings[real_force_name];
			local easy_food_name = ""
			
			if global.science_logs_food_name[i] == "automation-science-pack" then
				easy_food_name = "red"
			elseif global.science_logs_food_name[i] == "logistic-science-pack" then
				easy_food_name = "green"
			elseif global.science_logs_food_name[i] == "military-science-pack" then
				easy_food_name = "mil"
			elseif global.science_logs_food_name[i] == "chemical-science-pack" then
				easy_food_name = "blue"
			elseif global.science_logs_food_name[i] == "production-science-pack" then
				easy_food_name = "purple"
			elseif global.science_logs_food_name[i] == "utility-science-pack" then
				easy_food_name = "yellow"
			elseif global.science_logs_food_name[i] == "space-science-pack" then
				easy_food_name = "white"
			end
			game.print(dropdown_force.selected_index.."<VSSS>"..real_force_name .. "||" .. dropdown_force.selected_index)
			if dropdown_force.selected_index == 1 or real_force_name:match(dropdown_force.get_item(dropdown_force.selected_index)) then
				if dropdown_science.selected_index == 1
				or (dropdown_science.selected_index == 2 and (easy_food_name:match("white") or easy_food_name:match("yellow") or easy_food_name:match("purple")))
				or (dropdown_science.selected_index == 3 and (easy_food_name:match("white") or easy_food_name:match("yellow") or easy_food_name:match("purple")or easy_food_name:match("blue")))
				or (dropdown_science.selected_index == 4 and (easy_food_name:match("white") or easy_food_name:match("yellow") or easy_food_name:match("purple")or easy_food_name:match("blue") or easy_food_name:match("mil")))
				or easy_food_name:match(dropdown_science.get_item(dropdown_science.selected_index))
				then
					if dropdown_evofilter.selected_index == 1 
					or (dropdown_evofilter.selected_index == 2 and (global.science_logs_evo_jump_difference[i] >= 0))
					or (dropdown_evofilter.selected_index == 3 and (global.science_logs_evo_jump_difference[i] >= 10))
					or (dropdown_evofilter.selected_index == 4 and (global.science_logs_evo_jump_difference[i] >= 5))
					or (dropdown_evofilter.selected_index == 5 and (global.science_logs_evo_jump_difference[i] >= 4))
					or (dropdown_evofilter.selected_index == 6 and (global.science_logs_evo_jump_difference[i] >= 3))
					or (dropdown_evofilter.selected_index == 7 and (global.science_logs_evo_jump_difference[i] >= 2))
					or (dropdown_evofilter.selected_index == 8 and (global.science_logs_evo_jump_difference[i] >= 1))
					then
						science_panel_table = science_scrollpanel.add { type = "table", column_count = 4 }
						local label = science_panel_table.add { type = "label", name = "science_logs_date" .. i, caption = global.science_logs_date[i] }
						label.style.minimal_width = column_widths[1]
						label.style.maximal_width = column_widths[1]
						label.style.horizontal_align = "center"
						local label = science_panel_table.add { type = "label", name = "science_logs_text" .. i, caption = global.science_logs_text[i] .. custom_force_name }
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
		end
	end
end

local build_config_gui = (function (player, frame)		
	frame_sciencelogs = frame
	frame.clear()
	add_science_logs(player, frame)
end)


local function on_gui_selection_state_changed(event)
	local player = game.players[event.player_index]	
	local name = event.element.name
	if name == "dropdown-force" then
		dropdown_users_choice_force[player.name] = event.element.selected_index
	end
	if name == "dropdown-science" then
		dropdown_users_choice_science[player.name] = event.element.selected_index
	end
	if name == "dropdown-evofilter" then
		dropdown_users_choice_evo_filter[player.name] = event.element.selected_index
	end
	build_config_gui(player, frame_sciencelogs)
end


event.add(defines.events.on_gui_selection_state_changed, on_gui_selection_state_changed)


comfy_panel_tabs["MutagenLog"] = build_config_gui