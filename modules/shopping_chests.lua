local shop_list = {
	["iron-ore"] = 1,
	["copper-ore"] = 1,
	["uranium-ore"] = 3,
	["coal"] = 1,
	["stone"] = 1,
	["wood"] = 0.75,
	["crude-oil-barrel"] = 6,
	["empty-barrel"] = 5,
	["landfill"] = 2.5,
}

function create_shopping_chest(surface, position, destructible)
	global.shopping_chests[#global.shopping_chests + 1] = surface.create_entity({name = "logistic-chest-requester", position = position, force = "shopping_chests"})
	global.shopping_chests[#global.shopping_chests].minable = false
	if not destructible then	global.shopping_chests[#global.shopping_chests].destructible = false end	
end

function create_dump_chest(surface, position, destructible)
	global.dump_chests[#global.dump_chests + 1] = surface.create_entity({name = "logistic-chest-passive-provider", position = position, force = "shopping_chests"})
	global.dump_chests[#global.dump_chests].minable = false
	if not destructible then	global.dump_chests[#global.dump_chests].destructible = false end	
end

local function get_affordable_item_count(name, count)
	if global.credits >= count * shop_list[name] then
		return count
	end
	count = math.floor(global.credits / shop_list[name])
	return count
end

local function process_shopping_chest(k, chest)
	if not chest.valid then global.shopping_chests[k] = nil return end
	if global.credits <= 0 then return end
	local requested_item_stack = chest.get_request_slot(1)
	if not requested_item_stack then return end
	if not shop_list[requested_item_stack.name] then
		chest.surface.create_entity({name = "flying-text", position = {chest.position.x - 2, chest.position.y}, text = requested_item_stack.name .. " is not for sale", color = {r = 200, g = 160, b = 30}}) 
		return 
	end	
	local inventory = chest.get_inventory(defines.inventory.chest)
	--if not inventory.can_insert(requested_item_stack) then return end
	local current_count = inventory.get_item_count(requested_item_stack.name)
	if current_count >= requested_item_stack.count then return end	
	local count = requested_item_stack.count - current_count
	count = get_affordable_item_count(requested_item_stack.name, count)
	if count < 1 then return end
	local inserted_amount = inventory.insert({name = requested_item_stack.name, count = count})
	if inserted_amount == 0 then return end
	local spent_credits = inserted_amount * shop_list[requested_item_stack.name]
	global.credits = global.credits - spent_credits
	chest.surface.create_entity({name = "flying-text", position = chest.position, text = "-" .. spent_credits .. " ø", color = {r = 200, g = 160, b = 30}})
end

local function process_dump_chest(k, chest)
	if not chest.valid then global.dump_chests[k] = nil return end	
	local inventory = chest.get_inventory(defines.inventory.chest)	
	if inventory.is_empty() then return end
	for k, price in pairs(shop_list) do
		local removed = inventory.remove(k)
		global.credits = global.credits + (removed * shop_list[k])
	end
end

local function gui()
	for _, player in pairs(game.connected_players) do
		if player.gui.top.credits_button then player.gui.top.credits_button.destroy() end
		local element = player.gui.top.add({type = "frame", name = "credits_button", caption = global.credits .. " ø", tooltip = "Credits of the factory."})
		local style = element.style
		style.minimal_height = 38
		style.maximal_height = 38
		style.minimal_width = 140
		style.top_padding = 2
		style.left_padding = 4
		style.right_padding = 4
		style.bottom_padding = 2
		style.font_color = {r = 155, g = 85, b = 25}
		style.font = "default-large-bold"
	end
end

local function tick()
	for k, chest in pairs(global.shopping_chests) do
		process_shopping_chest(k, chest)
	end
	for k, chest in pairs(global.dump_chests) do
		process_dump_chest(k, chest)
	end
	gui()
	global.credits = global.credits + math.random(1,5)
end

local function on_init()
	global.shopping_chests = {}
	global.dump_chests = {}
	global.credits = 0
	game.create_force("shopping_chests")	
	game.forces.player.set_friend("shopping_chests", true)
	game.forces.shopping_chests.set_friend("player", true)
end

local event = require 'utils.event'
event.on_nth_tick(120, tick)
event.on_init(on_init)