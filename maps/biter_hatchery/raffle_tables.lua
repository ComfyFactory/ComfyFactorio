local raffle = {
	["automation-science-pack"] =	{{}, 1},	
	["logistic-science-pack"] = {{}, 2},
	["military-science-pack"] = {{}, 3},	
	["chemical-science-pack"] = {{}, 4},
	["production-science-pack"] = {{}, 5},
	["utility-science-pack"] = {{}, 6},	
	["space-science-pack"] = {{}, 7},
}

local t = raffle["automation-science-pack"][1]
for _ = 1, 4, 1 do table.insert(t, "small-biter") end
for _ = 1, 1, 1 do table.insert(t, "small-spitter") end

local t = raffle["logistic-science-pack"][1]
for _ = 1, 32, 1 do table.insert(t, "small-biter") end
for _ = 1, 8, 1 do table.insert(t, "small-spitter") end
for _ = 1, 4, 1 do table.insert(t, "medium-biter") end
for _ = 1, 1, 1 do table.insert(t, "medium-spitter") end

local t = raffle["military-science-pack"][1]
for _ = 1, 8, 1 do table.insert(t, "small-biter") end
for _ = 1, 2, 1 do table.insert(t, "small-spitter") end
for _ = 1, 16, 1 do table.insert(t, "medium-biter") end
for _ = 1, 4, 1 do table.insert(t, "medium-spitter") end
for _ = 1, 4, 1 do table.insert(t, "big-biter") end
for _ = 1, 1, 1 do table.insert(t, "big-spitter") end

local t = raffle["chemical-science-pack"][1]
for _ = 1, 8, 1 do table.insert(t, "medium-biter") end
for _ = 1, 2, 1 do table.insert(t, "medium-spitter") end
for _ = 1, 4, 1 do table.insert(t, "big-biter") end
for _ = 1, 1, 1 do table.insert(t, "big-spitter") end

local t = raffle["production-science-pack"][1]
for _ = 1, 4, 1 do table.insert(t, "medium-biter") end
for _ = 1, 1, 1 do table.insert(t, "medium-spitter") end
for _ = 1, 12, 1 do table.insert(t, "big-biter") end
for _ = 1, 3, 1 do table.insert(t, "big-spitter") end

local t = raffle["utility-science-pack"][1]
for _ = 1, 32, 1 do table.insert(t, "big-biter") end
for _ = 1, 8, 1 do table.insert(t, "big-spitter") end
for _ = 1, 4, 1 do table.insert(t, "behemoth-biter") end
for _ = 1, 1, 1 do table.insert(t, "behemoth-spitter") end

local t = raffle["space-science-pack"][1]
for _ = 1, 4, 1 do table.insert(t, "behemoth-biter") end
for _ = 1, 1, 1 do table.insert(t, "behemoth-spitter") end

return raffle