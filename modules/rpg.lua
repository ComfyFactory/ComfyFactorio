--[[
STRENGTH > character_inventory_slots_bonus , character_mining_speed_modifier 

MAGIC >	character_build_distance_bonus, character_item_drop_distance_bonus, character_reach_distance_bonus,
				character_resource_reach_distance_bonus, character_item_pickup_distance_bonus, character_loot_pickup_distance_bonus, 

DEXTERITY > character_running_speed_modifier, character_crafting_speed_modifier

VITALITY > character_health_bonus + damage resistance

?? > Melee damage
]]

local visuals_delay = 60

local experience_levels = {0}
for a = 1, 9999, 1 do
	experience_levels[#experience_levels + 1] = experience_levels[#experience_levels] + a * 2
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
	draw_level_text(player)
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
		global.rpg[player.index] = {level = 0, xp = 0, last_floaty_text = 0, xp_since_last_floaty_text = 0}
	end
	level_up(player)
end

local function on_init(event)
	global.rpg = {}
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_player_joined_game, on_player_joined_game)