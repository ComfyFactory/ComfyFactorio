local Public = {}

Public.food_values = {
	["automation-science-pack"] =	{value = 0.001, name = "automation science", color = "255, 50, 50"},
	["logistic-science-pack"] =		{value = 0.00263, name = "logistic science", color = "50, 255, 50"},
	["military-science-pack"] =		{value = 0.00788, name = "military science", color = "105, 105, 105"},
	["chemical-science-pack"] = 		{value = 0.02121, name = "chemical science", color = "100, 200, 255"},
	["production-science-pack"] =	{value = 0.1008, name = "production science", color = "150, 25, 255"},
	["utility-science-pack"] =			{value = 0.1099, name = "utility science", color = "210, 210, 60"},
	["space-science-pack"] = 			{value = 0.4910, name = "space science", color = "255, 255, 255"},
}

Public.gui_foods = {}
for k, v in pairs(Public.food_values) do
	Public.gui_foods[k] = math.floor(v.value * 10000) .. " Mutagen strength"
end
Public.gui_foods["raw-fish"] = "Send spy"

Public.force_translation = {
	["south_biters"] = "south",
	["north_biters"] = "north"
}

Public.enemy_team_of = {
	["north"] = "south",
	["south"] = "north"
}

Public.wait_messages = {
	"please get comfy.",
	"get comfy!!",
	"go and grab a drink.",
	"take a short healthy break.",
	"go and stretch your legs.",
	"please pet the cat.",
	"time to get a bowl of snacks :3",
}

Public.food_names = {
	["automation-science-pack"] = true,
	["logistic-science-pack"] = true,
	["military-science-pack"] = true,
	["chemical-science-pack"] = true,
	["production-science-pack"] = true,
	["utility-science-pack"] = true,
	["space-science-pack"] = true
}

return Public