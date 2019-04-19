--biter noms you
local event = require 'utils.event'
local math_random = math.random

local strings = {
	"delicious!",
	"yum", "yum",
	"crunch", "crunch",
	"chomp", "chomp",
	"chow", "chow",
	"nibble", "nibble",
	"munch",
	"nom", "nom",  "nom",  "nom",  "nom",  "nom",  "nom",  "nom",  "nom",  "nom",  "nom", "nom", "nom", "nom", "nom", "nom", "nom", "nom", "nom", "nom", "nom", "nom"
}

local whitelist = {
	["small-biter"] = true,
	["medium-biter"] = true,
	["big-biter"] = true,
	["behemoth-biter"] = true
}

local function on_entity_damaged(event)
	if not event.cause then return end
	if not event.cause.valid then return end
	if not whitelist[event.cause.name] then return end
	if math.random(1,3) == 1 then
		event.cause.surface.create_entity({
			name = "flying-text",
			position = event.cause.position,
			text = strings[math_random(1,#strings)],
			color = {r = math_random(130, 170), g = math_random(130, 170), b = 130}
		})
	end
end
	
event.add(defines.events.on_entity_damaged, on_entity_damaged)