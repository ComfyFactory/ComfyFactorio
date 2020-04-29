local Public = {}

Public.wagon_types = {
	["cargo-wagon"] = true,
	["artillery-wagon"] = true,
	["fluid-wagon"] = true,
	["locomotive"] = true,
}

Public.wagon_areas = {
	["cargo-wagon"] = {left_top = {x = -18, y = 0}, right_bottom = {x = 18, y = 70}},
	["artillery-wagon"] = {left_top = {x = -18, y = 0}, right_bottom = {x = 18, y = 70}},
	["fluid-wagon"] = {left_top = {x = -18, y = 0}, right_bottom = {x = 18, y = 70}},
	["locomotive"] = {left_top = {x = -18, y = 0}, right_bottom = {x = 18, y = 70}},
}

return Public