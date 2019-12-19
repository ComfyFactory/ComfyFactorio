local Public = {}

local info = [[
	This map has Towny is enabled!
	
	To ally or settle with another town, drop a fish on their market or character. (Default Hotkey Z)
	They will have to do the same to you to complete the request.
	Coal yields the opposite result, as it will make foes or banish settlers.
		
	To found your own town, place down a stone furnace at a valid location.
	Buildings can only be placed close to your other buildings.	
	Beware, biters are more aggressive towards towns that are advanced in research.
	
	Only one town center can be owned at a time.
	Only the owner can banish members.
	Members can invite other players and teams.
	Members can leave their town with a piece of coal.
	
	All towns are opponents to each other, if no alliance is formed with a raw fish.
	If a center falls, the whole team will fall with it and all buildings will turn neutral and lootable.
	The town center also acts as the team's respawn point. 
	
	There are very little rules. Have fun and be comfy ^.^
]]

function Public.show(player)
	if player.gui.center["towny_map_intro_frame"] then player.gui.center["towny_map_intro_frame"].destroy() end
	local frame = player.gui.center.add {type = "frame", name = "towny_map_intro_frame", direction = "vertical"}
	local frame = frame.add {type = "frame"}
	local l = frame.add {type = "label", caption = info, name = "towny_map_intro"}
	l.style.single_line = false
	l.style.font = "heading-2"
	l.style.font_color = {r=0.7, g=0.6, b=0.99}			
end

function Public.close(event)
	if not event.element then return end
	if not event.element.valid then return end		
	if event.element.name == "towny_map_intro" then
		game.players[event.element.player_index].gui.center["towny_map_intro_frame"].destroy()  
	end	
end

local event = require 'utils.event'
event.add(defines.events.on_gui_click, on_gui_click)

return Public