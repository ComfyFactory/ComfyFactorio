local event = require 'utils.event'
local message_color = {r = 0.5, g = 0.3, b = 1}

local brain = {
	[1] = {"Our Discord server is at https://comfyplay.net/discord"},
	[2] = {"Need an admin? Type @Mods in game chat to notify moderators!", "Or put a message in the discord help channel."}
}

local links = {
	["discord"] = brain[1],
	["admin"] = brain[2],
	["administrator"] = brain[2],
	["mod"] = brain[2],
	["moderator"] = brain[2],
	["grief"] = brain[2],
	["troll"] = brain[2],
	["trolling"] = brain[2],
	["stealing"] = brain[2],
	["stole"] = brain[2],
	["griefer"] = brain[2]
}

local function on_player_created(event)
	local player = game.players[event.player_index]
	player.print("Join the comfy discord >> comfyplay.net/discord", message_color)
end

local function on_console_chat(event)
	local message = event.message
	message = string.lower(message)
	for word in string.gmatch(message, "%a+") do
		if links[word] then
			local player = game.players[event.player_index]
			for _, bot_answer in pairs(links[word]) do
				player.print(bot_answer, message_color)
			end
			return
		end
	end
end

event.add(defines.events.on_player_created, on_player_created)
event.add(defines.events.on_console_chat, on_console_chat)