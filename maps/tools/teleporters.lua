local event = require 'utils.event' 
local key_item = "small-plane"
local key_item = "transport-belt"
local blacklisted_tiles = {"out-of-map", "water", "deepwater", "water-green", "lab-white", "lab-dark-1"}
local teleporter_names = {"Stuedrik", "Wrirrirb", "Cekoht", "Deokels", "Gnaecl", "Yffolf", "Xuohsywae", "Flublodoe", "Dicyhnea", "Ruovyk", "Truecuhz", "Vaux'ers", "Gyttux", "Flys", "Qlammed", "Gynneo", "Xraeqoeht", "Phuashlk", "Cuahnennu", "Kneizigh", "Zruex'iz", "Stux'ar", "Zrihq", "Opsyms", "Ogigh", "Nek'oke", "Knoebhybeo", "Kluetryrceo", "Chahz", "Xralarb", "Wrib", "Breipuhz", "Nueglahloe", "Wuammea", "Iblameo", "Wuansyrfua", "Flohlilue", "Vev'unnae", "Deivrym", "Atahz", "Zrux'ysk", "Kyq'yks", "Gnyf'ilm", "Knaegnom", "Gnaelphiss", "Kmaek'irba", "Zruffira", "Kicremme", "Tuot'az", "Ouprard", "Tyv'im", "Get'yks", "Essyh", "Vliln", "Glucutha", "Teoblux", "Feohshowtha", "Dedrapt"}

local function gui_spawn_new_teleporter(player)		
	if player.gui.left["spawn_new_teleporter_button"] then player.gui.left["spawn_new_teleporter_button"].destroy() end	
	local b = player.gui.left.add({ type = "button", name = "spawn_new_teleporter_button", caption = "Deploy Teleporter"})
	b.style.minimal_height = 38
	b.style.minimal_width = 38
	b.style.top_padding = 6
	b.style.left_padding = 12
	b.style.right_padding = 12
	b.style.bottom_padding = 6
	b.style.font = "default-listbox"
	b.style.font_color = {r = 0.35, g = 0.5, b = 1}
end

local function gui_teleporter(player, blacklisted_teleporter_index)
	if player.gui.left["gui_teleporter"] then player.gui.left["gui_teleporter"].destroy() end	
	local frame = player.gui.left.add({ type = "frame", name = "gui_teleporter", direction = "vertical"})
	local t = frame.add({type = "table", column_count = 2})
	local l = t.add({type = "label", caption = "<Teleporter> "})
	l.style.font_color = {r = 0.35, g = 0.5, b = 1}
	l.style.font = "default-frame"
	local l = t.add({type = "label", caption = global.teleporters[blacklisted_teleporter_index].name})
	l.style.font_color = {r = 0.77, g = 0.77, b = 0.77}
	l.style.font = "default-bold"
	l.style.top_padding = 4
	
	local frame2 = frame.add({ type = "frame", direction = "vertical"})
	if #global.teleporters < 2 then
		frame2.caption = "No other connected teleporters found."
		frame2.style.font = "default-bold"
		return
	end
	for x, teleporter in pairs(global.teleporters) do
		if x ~= blacklisted_teleporter_index then
			local t = frame2.add({ type = "table", column_count = 2})
			
			local b = t.add({type = "button", caption = teleporter.name})
			b.style.minimal_width = 200
			b.style.font_color = {r = 0.35, g = 0.5, b = 1}
			b.style.font = "default-frame"
						
			local tt = t.add({ type = "table", column_count = 2})
			
			local l = tt.add({type = "label", caption = "Position: "})
			l.style.font_color = {r = 0.22, g = 0.88, b = 0.44}
			l.style.font = "default-bold"
			l.style.minimal_width = 65
			 
			local l = tt.add({type = "label", caption = "X: " .. tostring(teleporter.position.x) .. "  Y: " .. tostring(teleporter.position.y)})
			l.style.font = "default"
			l.style.font_color = {r = 0.77, g = 0.77, b = 0.77}
			l.style.minimal_width = 100
			
			local l = tt.add({type = "label", caption = "Distance: "})
			l.style.font_color = {r = 0.22, g = 0.88, b = 0.44}
			l.style.font = "default-bold"
			l.style.minimal_width = 65
			
			local l = tt.add({type = "label", caption = tostring(math.ceil(math.sqrt((teleporter.position.x - player.position.x)^2 + (teleporter.position.y - player.position.y)^2), 0)) .. " Units"})
			l.style.font = "default"
			l.style.font_color = {r = 0.77, g = 0.77, b = 0.77}
			l.style.minimal_width = 100
		end
	end
end

local function spawn_teleporter(player)
	if not global.teleporters then global.teleporters = {} end
	local surface = player.surface
	local pos = {x = math.floor(player.position.x, 0), y = math.floor(player.position.y, 0)}
	local a = {
				left_top = {x = pos.x - 3, y = pos.y - 3},
				right_bottom = {x = pos.x + 3, y = pos.y + 3}
				}
	local c = surface.count_tiles_filtered{area = a, name = blacklisted_tiles, limit = 1}		
	if c == 0 then
		local i = player.get_quickbar()
		local removed_item_count = i.remove({name = key_item, count = 1})
		if removed_item_count ~= 1 then
			local i = player.get_main_inventory()
			removed_item_count = i.remove({name = key_item, count = 1})
		end		
		if removed_item_count ~= 1 then return end		
		local str = teleporter_names[math.random(1, #teleporter_names)]
		local str = str2
		while str == str2 do
			str2 = teleporter_names[math.random(1, #teleporter_names)]
		end		
		table.insert(global.teleporters, {position = {x = pos.x, y = pos.y}, name = str .. " " .. str2})
		local tiles = {
						{name = "lab-white", position = pos},	
						{name = "lab-dark-1", position = {pos.x - 1, pos.y - 1}},
						{name = "lab-dark-1", position = {pos.x, pos.y - 1}},
						{name = "lab-dark-1", position = {pos.x + 1, pos.y - 1}},
						{name = "lab-dark-1", position = {pos.x + 1, pos.y}},
						{name = "lab-dark-1", position = {pos.x + 1, pos.y + 1}},
						{name = "lab-dark-1", position = {pos.x, pos.y + 1}},
						{name = "lab-dark-1", position = {pos.x - 1, pos.y + 1}},
						{name = "lab-dark-1", position = {pos.x - 1, pos.y}},						
						}		
		surface.set_tiles(tiles, true)				
	end
end

local function check_inventory_for_key_item(player_index)
	local player = game.players[player_index]
	if player.get_item_count(key_item) > 0 then
		gui_spawn_new_teleporter(player)
	else
		if player.gui.left["spawn_new_teleporter_button"] then player.gui.left["spawn_new_teleporter_button"].destroy() end
	end
end

local function on_player_changed_position(event)
	if not global.teleporters then return end
	local player = game.players[event.player_index]
	local a = {
				left_top = {x = player.position.x - 1, y = player.position.y - 1},
				right_bottom = {x = player.position.x + 1, y = player.position.y + 1}
				}
	local tile = player.surface.find_tiles_filtered{area = a, name = "lab-white", limit = 1}
	if not tile[1] then
		if player.gui.left["gui_teleporter"] then player.gui.left["gui_teleporter"].destroy() end
		return 
	end	
	for x, teleporter in pairs(global.teleporters) do
		if teleporter.position.x == tile[1].position.x and teleporter.position.y == tile[1].position.y then
			gui_teleporter(player, x)
			break
		end
	end
end

local function on_player_main_inventory_changed(event)
	check_inventory_for_key_item(event.player_index)
end

local function on_player_quickbar_inventory_changed(event)
	check_inventory_for_key_item(event.player_index)
end

local function on_player_dropped_item(event)
	check_inventory_for_key_item(event.player_index)
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end	
	local player = game.players[event.element.player_index]
	local name = event.element.name
	if name == "spawn_new_teleporter_button" then spawn_teleporter(player) end
end

event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_player_dropped_item, on_player_dropped_item)
event.add(defines.events.on_player_main_inventory_changed, on_player_main_inventory_changed)
event.add(defines.events.on_player_quickbar_inventory_changed, on_player_quickbar_inventory_changed)
event.add(defines.events.on_gui_click, on_gui_click)