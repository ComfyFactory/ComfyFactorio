local Public = {}
local math_random = math.random
--cumul_chance must be sum of this and all previous chances, add new planets at the end only, or recalculate
--biters: used in spawner generation within math_random(1, 52 - biters), so higher number gives better chance. not to be greater than 50.
local variants = {
  [1] = {id = 1, name = "iron planet", iron = 10, copper = 1, coal = 1, stone = 1, uranium = 0, oil = 1, biters = 16, moisture = 0, chance = 1, cumul_chance = 1},
  [2] = {id = 2, name = "copper planet", iron = 1, copper = 10, coal = 1, stone = 1, uranium = 0, oil = 1, biters = 16, moisture = 0, chance = 1, cumul_chance = 2},
  [3] = {id = 3, name = "stone planet", iron = 1, copper = 1, coal = 1, stone = 10, uranium = 0, oil = 1, biters = 16, moisture = -0.2, chance = 1, cumul_chance = 3},
  [4] = {id = 4, name = "oil planet", iron = 1, copper = 1, coal = 1, stone = 1, uranium = 0, oil = 5, biters = 16, moisture = 0.1, chance = 1, cumul_chance = 4},
  [5] = {id = 5, name = "uranium planet", iron = 1, copper = 1, coal = 1, stone = 1, uranium = 7, oil = 1, biters = 16, moisture = -0.2, chance = 1, cumul_chance = 5},
  [6] = {id = 6, name = "mixed planet", iron = 2, copper = 2, coal = 2, stone = 2, uranium = 1, oil = 1, biters = 10, moisture = 0, chance = 10, cumul_chance = 15},
  [7] = {id = 7, name = "biter planet", iron = 2, copper = 2, coal = 2, stone = 2, uranium = 4, oil = 3, biters = 40, moisture = 0.2, chance = 8, cumul_chance = 23},
  [8] = {id = 8, name = "water planet", iron = 1, copper = 1, coal = 1, stone = 1, uranium = 0, oil = 0, biters = 6, moisture = 0.5, chance = 2, cumul_chance = 25},
  [9] = {id = 9, name = "coal planet", iron = 1, copper = 1, coal = 10, stone = 1, uranium = 0, oil = 1, biters = 16, moisture = 0, chance = 1, cumul_chance = 26},
  [10] = {id = 10, name = "scrapyard", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 1, oil = 0, biters = 0, moisture = -0.2, chance = 4, cumul_chance = 30},
  [11] = {id = 11, name = "rocky planet", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 0, biters = 6, moisture = -0.2, chance = 2, cumul_chance = 32},
  [12] = {id = 12, name = "choppy planet", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 1, biters = 6, moisture = 0.4, chance = 2, cumul_chance = 34},
  [13] = {id = 13, name = "river planet", iron = 1, copper = 1, coal = 3, stone = 1, uranium = 0, oil = 0, biters = 8, moisture = 0.5, chance = 2, cumul_chance = 36},
  [14] = {id = 14, name = "lava planet", iron = 1, copper = 1, coal = 1, stone = 1, uranium = 0, oil = 0, biters = 6, moisture = -0.5, chance = 0, cumul_chance = 36},
  [15] = {id = 15, name = "ruins planet", iron = 1, copper = 1, coal = 1, stone = 1, uranium = 2, oil = 0, biters = 8, moisture = 0, chance = 0, cumul_chance = 36},

}

local time_speed_variants = {
  [1] = {name = "static", timer = 0},
  [2] = {name = "normal", timer = 100},
  [3] = {name = "slow", timer = 50},
  [4] = {name = "superslow", timer = 25},
  [5] = {name = "fast", timer = 200},
  [6] = {name = "superfast", timer = 400}
}

local richness = {
  [1] = {name = "very rich", factor = 4},
  [2] = {name = "rich", factor = 3},
  [3] = {name = "above average", factor = 2},
  [4] = {name = "normal", factor = 1},
  [5] = {name = "poor", factor = 0.5},
  [6] = {name = "very poor", factor = 0.2}
}
local function roll(weight)
  for i = 1, 100, 1 do
    local planet = variants[math_random(1, #variants)]
    local planet_weight = planet.chance
    local planet_cumul = planet.cumul_chance
    local rolling = math_random(1, weight)
    if ((planet_cumul - planet_weight < rolling) and (rolling  <= planet_cumul)) then
      return planet
    end
  end
  --default planet if 100 rolls fail
  return variants[6]
end

function Public.determine_planet(choice)
  local weight = variants[#variants].cumul_chance
  local planet_choice = nil
  if not choice then
    planet_choice = roll(weight)
  else
    planet_choice = variants[choice]
  end
  local planet = {
    [1] = {
      name = planet_choice,
      day_speed = time_speed_variants[math_random(1, #time_speed_variants)],
      time = math_random(1,100) / 100,
      ore_richness = richness[math_random(1, #richness)],
    }
  }
  return planet
end

return Public
