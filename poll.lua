----------------------------------------------------------------------------------------------------------------------------------------
-- create polls for players to vote on                              
-- by MewMew -- with some help from RedLabel, Klonan, Morcup, BrainClot   
----------------------------------------------------------------------------------------------------------------------------------------

local event = require 'utils.event'
local poll_duration_in_seconds = 99

local function create_poll_gui(player)
	if player.gui.top.poll then return end
	local button = player.gui.top.add { name = "poll", type = "sprite-button", sprite = "item/programmable-speaker", tooltip = "Show current poll" }
	button.style.font = "default-bold"
	button.style.minimal_height = 38
	button.style.minimal_width = 38
	button.style.top_padding = 2
	button.style.left_padding = 4
	button.style.right_padding = 4
	button.style.bottom_padding = 2
end

local function poll_show(player)
	if player.gui.left["poll-panel"]	then player.gui.left["poll-panel"].destroy() end
	
	local frame = player.gui.left.add { type = "frame", name = "poll-panel", direction = "vertical" }	

	frame.add { type = "table", name = "poll_panel_table", column_count = 2 }
	
	local poll_panel_table = frame.poll_panel_table
	
	if not (global.poll_question == "") then
		
		local str = "Poll #" .. global.score_total_polls_created .. ":"
		if global.score_total_polls_created > 1 then
			local x = game.tick
			x = ((x / 60) / 60) / 60
			x = global.score_total_polls_created / x 
			x = math.round(x, 0)
			str = str .. "                   (Polls/hour: "
			str = str .. x
			str = str .. ")"
		end
		
		poll_panel_table.add { type = "label", caption = str, single_line = false, name = "poll_number_label" }
		poll_panel_table.poll_number_label.style.font_color = { r=0.75, g=0.75, b=0.75}
		poll_panel_table.add { type = "label"}					
		poll_panel_table.add { type = "label", caption = global.poll_question, name = "question_label" }
		poll_panel_table.question_label.style.maximal_width = 208
		poll_panel_table.question_label.style.maximal_height = 170
		poll_panel_table.question_label.style.font = "default-bold"
		poll_panel_table.question_label.style.font_color = { r=0.98, g=0.66, b=0.22}
		poll_panel_table.question_label.style.single_line = false
		poll_panel_table.add { type = "label" }
	end
	
	local y = 1
	while (y < 4) do
		if not (global.poll_answers[y] == "") then				
			local z = tostring(y)						
			local l = poll_panel_table.add { type = "label", caption = global.poll_answers[y], name = "answer_label_" .. z }		
			l.style.maximal_width = 208
			l.style.minimal_width = 208
			l.style.maximal_height = 165
			l.style.font = "default"
			l.style.single_line = false			
			local answerbutton = poll_panel_table.add  { type = "button", caption = global.poll_button_votes[y], name = "answer_button_" .. z }	
			answerbutton.style.font = "default-listbox"
			answerbutton.style.minimal_width = 32
		end
		y = y + 1
	end
	
	frame.add { type = "table", name = "poll_panel_button_table", column_count = 3 }
	local poll_panel_button_table = frame.poll_panel_button_table
	poll_panel_button_table.add { type = "button", caption = "New Poll", name = "new_poll_assembler_button" }
	
	if not global.poll_panel_creation_times then global.poll_panel_creation_times = {} end
	global.poll_panel_creation_times[player.index] = {player_index = player.index, tick = 5940}
	
	local str = "Hide (" .. poll_duration_in_seconds
	str = str .. ")"
		
	poll_panel_button_table.add { type = "button", caption = str, name = "poll_hide_button" }
	
	poll_panel_button_table.poll_hide_button.style.minimal_width = 70		
	poll_panel_button_table.new_poll_assembler_button.style.font = "default-bold"
	poll_panel_button_table.new_poll_assembler_button.style.minimal_height = 38
	poll_panel_button_table.poll_hide_button.style.font = "default-bold"		
	poll_panel_button_table.poll_hide_button.style.minimal_height = 38		
	poll_panel_button_table.add { type = "checkbox", caption = "Show Polls", state = global.autoshow_polls_for_player[player.name], name = "auto_show_polls_checkbox"	}						
end

local function poll(player)	
	local frame = player.gui.left["poll-assembler"]
	frame = frame.table_poll_assembler
	
	if frame.textfield_question.text == "" then	return end
	if frame.textfield_answer_1.text == "" and frame.textfield_answer_2.text == "" and frame.textfield_answer_3.text == "" then return end
	
	global.poll_question = frame.textfield_question.text	
	global.poll_answers = {frame.textfield_answer_1.text, frame.textfield_answer_2.text, frame.textfield_answer_3.text}
	
	local msg = player.name
	msg = msg .. " has created a new Poll!"
	
	global.score_total_polls_created = global.score_total_polls_created + 1
	
	local frame = player.gui.left["poll-assembler"]
	frame.destroy()
	
	global.poll_voted = nil		
	global.poll_voted  = {}
	global.poll_button_votes = {0,0,0}
	
	for _, player in pairs(game.players) do
		if player.gui.left["poll-panel"] then
			player.gui.left["poll-panel"].destroy()
		end
		if global.autoshow_polls_for_player[player.name] == true then
			poll_show(player)
		end
		player.print(msg, { r=0.22, g=0.99, b=0.99})
	end
end

local function poll_refresh()		
	for _, player in pairs(game.players) do
		if player.gui.left["poll-panel"] then		
			local frame = player.gui.left["poll-panel"]
			frame = frame.poll_panel_table		
			if frame.answer_button_1 then frame.answer_button_1.caption = global.poll_button_votes[1] end
			if frame.answer_button_2 then frame.answer_button_2.caption = global.poll_button_votes[2] end
			if frame.answer_button_3 then frame.answer_button_3.caption = global.poll_button_votes[3] end										
		end
	end
end

local function poll_assembler(player)				
	local frame = player.gui.left.add { type = "frame", name = "poll-assembler", caption = "" }	
	local frame_table = frame.add { type = "table", name = "table_poll_assembler", column_count = 2 }
	frame_table.add { type = "label", caption = "Question:" }
	frame_table.add { type = "textfield", name = "textfield_question", text = "" }
	frame_table.add { type = "label", caption = "Answer #1:" }
	frame_table.add { type = "textfield", name = "textfield_answer_1", text = "" }
	frame_table.add { type = "label", caption = "Answer #2:" }
	frame_table.add { type = "textfield", name = "textfield_answer_2", text = "" }
	frame_table.add { type = "label", caption = "Answer #3:" }
	frame_table.add { type = "textfield", name = "textfield_answer_3", text = "" }
	frame_table.add { type = "label", caption = "" }
	frame_table.add { type = "button", name = "create_new_poll_button", caption = "Create" }
end

function on_player_joined_game(event)
	if not global.poll_init_done then
		global.poll_voted = {}
		global.poll_question = ""
		global.poll_answers = {"","",""}
		global.poll_button_votes = {0,0,0}
		global.poll_voted = {}
		global.autoshow_polls_for_player = {}
		global.score_total_polls_created = 0
		global.poll_init_done = true
	end	
	
	local player = game.players[event.player_index]	
			
	if global.autoshow_polls_for_player[player.name] == nil then 
		global.autoshow_polls_for_player[player.name] = true
	end
	
	create_poll_gui(player)
			
	if global.poll_question == "" then return end
		
	poll_show(player)			
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end	
		
	local player = game.players[event.element.player_index]
	local name = event.element.name
	
	if name == "poll" then
		local frame = player.gui.left["poll-panel"]
		if frame then
			frame.destroy()
		else
			poll_show(player)
		end
		
		local frame = player.gui.left["poll-assembler"]
		if frame then
			frame.destroy()
		end
	end
	
	if name == "new_poll_assembler_button" then
		local frame = player.gui.left["poll-assembler"]
		if (frame) then
			frame.destroy()
		else
			poll_assembler(player)
		end
	end
	
	if name == "create_new_poll_button" then			
		poll(player)
	end
	
	if name == "poll_hide_button" then
		local frame = player.gui.left["poll-panel"]
		if (frame) then
			frame.destroy()
		end
		local frame = player.gui.left["poll-assembler"]
		if frame then
			frame.destroy()
		end
	end
	
	if name == "auto_show_polls_checkbox" then
		global.autoshow_polls_for_player[player.name] = event.element.state 		
	end		
					
	if global.poll_voted[event.player_index] == nil then		
		
		if name == "answer_button_1" then
			global.poll_button_votes[1] = global.poll_button_votes[1] + 1
			global.poll_voted[event.player_index] = player.name
			poll_refresh()
		end
			
		if name == "answer_button_2" then
			global.poll_button_votes[2] = global.poll_button_votes[2] + 1
			global.poll_voted[event.player_index] = player.name
			poll_refresh()
		end
			
		if name == "answer_button_3" then
			global.poll_button_votes[3] = global.poll_button_votes[3] + 1
			global.poll_voted[event.player_index] = player.name
			poll_refresh()
		end
		
	end					
end

local function process_timeout(creation_time)
	local player = game.players[creation_time.player_index]
	local frame = player.gui.left["poll-panel"]
	if not frame then global.poll_panel_creation_times[player.index] = nil return end
	
	global.poll_panel_creation_times[player.index].tick = global.poll_panel_creation_times[player.index].tick - 60
	
	if global.poll_panel_creation_times[player.index].tick <= 0 then
		frame.destroy()
		global.poll_panel_creation_times[player.index] = nil
		return
	end	
	
	frame.poll_panel_button_table.poll_hide_button.caption = "Hide (" .. math.ceil(global.poll_panel_creation_times[player.index].tick / 60) .. ")"	
end

local function on_tick()	
	if game.tick % 60 ~= 0 then return end
	if not global.poll_panel_creation_times then return end
	if #global.poll_panel_creation_times == 0 then
		global.poll_panel_creation_times = nil
		return
	end
	
	for _, creation_time in pairs(global.poll_panel_creation_times) do
		process_timeout(creation_time)						
	end		
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_player_joined_game, on_player_joined_game)