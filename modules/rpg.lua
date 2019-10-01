--[[
STRENGTH > character_inventory_slots_bonus , character_mining_speed_modifier 

MAGIC >	character_build_distance_bonus, character_item_drop_distance_bonus, character_reach_distance_bonus,
				character_resource_reach_distance_bonus, character_item_pickup_distance_bonus, character_loot_pickup_distance_bonus, 

DEXTERITY > character_running_speed_modifier, character_crafting_speed_modifier

VITALITY > character_health_bonus + damage resistance

?? > Melee damage
]]

local visuals_delay = 60

local gui_width = 360
local gui_height = 480
local font = "default-bold"
local font_color = {222, 222, 222}

local experience_levels = {0}
for a = 1, 9999, 1 do
	experience_levels[#experience_levels + 1] = experience_levels[#experience_levels] + a * 2
end

local function draw_gui(player)
	if player.gui.left.rpg then player.gui.left.rpg.destroy() end
	local frame = player.gui.left.add({type = "frame", name = "rpg", direction = "vertical"})
	frame.style.maximal_width = gui_width
	frame.style.minimal_width = gui_width
	
	local t = frame.add({type = "table", column_count = 2})
	local element = t.add({type = "sprite-button", caption = player.name})
	local element = t.add({type = "sprite-button", caption = "Rogue"})
	for _, element in pairs(t.children) do
		element.style.maximal_width = math.floor(gui_width * 0.46)
		element.style.minimal_width = math.floor(gui_width * 0.46)
		element.style.font = font
		element.style.font_color = font_color
	end
	
	local element = frame.add({type = "line"})
	element.style.maximal_width = math.floor(gui_width * 0.96)
	element.style.minimal_width = math.floor(gui_width * 0.96)
	
	local t = frame.add({type = "table", column_count = 4})
	local element = t.add({type = "label", caption = "LEVEL"})
	element.style.maximal_width = math.floor(gui_width * 0.15)
	element.style.minimal_width = math.floor(gui_width * 0.15)
	local element = t.add({type = "sprite-button", caption = global.rpg[player.index].level})
	element.style.maximal_width = math.floor(gui_width * 0.15)
	element.style.minimal_width = math.floor(gui_width * 0.15)
	local element = t.add({type = "label", caption = "EXPERIENCE"})
	element.style.maximal_width = math.floor(gui_width * 0.25)
	element.style.minimal_width = math.floor(gui_width * 0.25)
	local element = t.add({type = "sprite-button", caption = math.floor(global.rpg[player.index].xp)})
	element.style.maximal_width = math.floor(gui_width * 0.33)
	element.style.minimal_width = math.floor(gui_width * 0.33)
	local element = t.add({type = "label", caption = " "})
	element.style.maximal_width = math.floor(gui_width * 0.15)
	element.style.minimal_width = math.floor(gui_width * 0.15)
	local element = t.add({type = "label", caption = " "})
	element.style.maximal_width = math.floor(gui_width * 0.15)
	element.style.minimal_width = math.floor(gui_width * 0.15)
	local element = t.add({type = "label", caption = "NEXT LEVEL"})
	element.style.maximal_width = math.floor(gui_width * 0.25)
	element.style.minimal_width = math.floor(gui_width * 0.25)
	local element = t.add({type = "sprite-button", caption = experience_levels[global.rpg[player.index].level + 1]})
	element.style.maximal_width = math.floor(gui_width * 0.33)
	element.style.minimal_width = math.floor(gui_width * 0.33)
	for _, element in pairs(t.children) do
		element.style.font = font
		element.style.font_color = font_color
	end
	local element = frame.add({type = "line"})
	element.style.maximal_width = math.floor(gui_width * 0.96)
	element.style.minimal_width = math.floor(gui_width * 0.96)
	
	local sprite = "virtual-signal/signal-red"
	if global.rpg[player.index].points_to_distribute <= 0 then sprite = "virtual-signal/signal-black" end
	local t = frame.add({type = "table", column_count = 2})
	local tt = frame.add({type = "table", column_count = 3})
	local element = tt.add({type = "label", caption = "STRENGTH"})
	local element = tt.add({type = "sprite-button", caption = global.rpg[player.index].strength})
	local element = tt.add({type = "sprite-button", caption = "+", sprite = sprite})
	local element = tt.add({type = "label", caption = "MAGIC"})
	local element = tt.add({type = "sprite-button", caption = global.rpg[player.index].magic})
	local element = tt.add({type = "sprite-button", caption = "+", sprite = sprite})
	local element = tt.add({type = "label", caption = "DEXTERITY"})
	local element = tt.add({type = "sprite-button", caption = global.rpg[player.index].dexterity})
	local element = tt.add({type = "sprite-button", caption = "+", sprite = sprite})
	local element = tt.add({type = "label", caption = "VITALITY"})
	local element = tt.add({type = "sprite-button", caption = global.rpg[player.index].vitality})
	local element = tt.add({type = "sprite-button", caption = "+", sprite = sprite})
	local element = tt.add({type = "label", caption = "POINTS TO DISTRIBUTE"})
	element.style.minimal_width = 96
	element.style.maximal_width = 96
	element.style.single_line = false
	local element = tt.add({type = "sprite-button", caption = global.rpg[player.index].points_to_distribute})
	local element = tt.add({type = "label", caption = " "})
	local element = tt.add({type = "label", caption = " "})
	local element = tt.add({type = "label", caption = " "})
	local element = tt.add({type = "label", caption = " "})
	local element = tt.add({type = "label", caption = "LIFE"})
	local element = tt.add({type = "sprite-button", caption = player.character.health})
	local element = tt.add({type = "sprite-button", caption = player.character.prototype.max_health + player.character_health_bonus + player.force.character_health_bonus})
	
	local shield = 0
	local shield_max = 0	
	local i = player.character.get_inventory(defines.inventory.character_armor)
	if not i.is_empty() then
		if i[1].grid then
			shield = math.floor(i[1].grid.shield) 
			shield_max = math.floor(i[1].grid.max_shield)
		end
	end
	local element = tt.add({type = "label", caption = "SHIELD"})
	local element = tt.add({type = "sprite-button", caption = shield})
	local element = tt.add({type = "sprite-button", caption = shield_max})
	for _, element in pairs(tt.children) do
		element.style.font = font
		element.style.font_color = font_color
	end
end

local function draw_level_text(player)
	if global.rpg[player.index].text then
		rendering.destroy(global.rpg[player.index].text)
		global.rpg[player.index].text = nil
	end
	
	global.rpg[player.index].text = rendering.draw_text{
		text = "lvl " .. global.rpg[player.index].level,
		surface = player.surface,
		target = player.character,
		target_offset = {-0.05, -3},
		color = {
			r = player.color.r * 0.6 + 0.25,
			g = player.color.g * 0.6 + 0.25,
			b = player.color.b * 0.6 + 0.25,
			a = 1
		},
		--time_to_live = 600,
		scale = 1.0 + global.rpg[player.index].level * 0.01,
		font = "scenario-message-dialog",
		alignment = "center",
		scale_with_zoom = false
	}
end

local function level_up(player)
	global.rpg[player.index].level = global.rpg[player.index].level + 1
	global.rpg[player.index].points_to_distribute = global.rpg[player.index].points_to_distribute + 5
	draw_level_text(player)
	draw_gui(player)
end

local function gain_xp(player, amount)
	global.rpg[player.index].xp = global.rpg[player.index].xp + amount
	global.rpg[player.index].xp_since_last_floaty_text = global.rpg[player.index].xp_since_last_floaty_text + amount
	if not experience_levels[global.rpg[player.index].level + 1] then return end
	if global.rpg[player.index].xp >= experience_levels[global.rpg[player.index].level + 1] then
		level_up(player)
		return
	end
	if global.rpg[player.index].last_floaty_text > game.tick then return end
	player.create_local_flying_text{text="+" .. global.rpg[player.index].xp_since_last_floaty_text .. " xp", position=player.position, color={r = 177, g = 177, b = 177}, time_to_live=120, speed=1}
	if player.gui.left.rpg then draw_gui(player) end
	global.rpg[player.index].xp_since_last_floaty_text = 0
	global.rpg[player.index].last_floaty_text = game.tick + visuals_delay
end

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	if not player.character then return end
	gain_xp(player, 0.1)
	if player.character.driving == true then return end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.rpg[player.index] then
		global.rpg[player.index] = {level = 0, xp = 0, strength = 15, magic = 15, dexterity = 15, vitality = 15, points_to_distribute = 0, last_floaty_text = 0, xp_since_last_floaty_text = 0}
	end
	level_up(player)
	
	draw_gui(player)
end

local function on_init(event)
	global.rpg = {}
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_player_joined_game, on_player_joined_game)