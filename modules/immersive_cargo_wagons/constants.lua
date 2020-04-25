local Public = {}

Public.wagon_types = {
	["cargo-wagon"] = true,
	["artillery-wagon"] = true,
	["fluid-wagon"] = true,
	["locomotive"] = true,
}

Public.wagon_areas = {
	["cargo-wagon"] = {left_top = {x = -10, y = 0}, right_bottom = {x = 10, y = 36}},
	["artillery-wagon"] = {left_top = {x = -10, y = 0}, right_bottom = {x = 10, y = 36}},
	["fluid-wagon"] = {left_top = {x = -10, y = 0}, right_bottom = {x = 10, y = 36}},
	["locomotive"] = {left_top = {x = -10, y = 0}, right_bottom = {x = 10, y = 36}},
}

return Public