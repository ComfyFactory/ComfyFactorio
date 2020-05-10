local Public = {}

Public.wagon_types = {
	["cargo-wagon"] = true,
	["artillery-wagon"] = true,
	["fluid-wagon"] = true,
	["locomotive"] = true,
}

Public.wagon_areas = {
	["cargo-wagon"] = {left_top = {x = -20, y = 0}, right_bottom = {x = 20, y = 60}},
	["artillery-wagon"] = {left_top = {x = -20, y = 0}, right_bottom = {x = 20, y = 60}},
	["fluid-wagon"] = {left_top = {x = -20, y = 0}, right_bottom = {x = 20, y = 60}},
	["locomotive"] = {left_top = {x = -20, y = 0}, right_bottom = {x = 20, y = 60}},
}

return Public