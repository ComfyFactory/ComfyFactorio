local Public = {}
local math_random = math.random
local math_floor = math.floor

local ScenarioTable = require 'maps.scrap_towny_ffa.table'

function Public.reproduce()
    local this = ScenarioTable.get_table()
    for _, town_center in pairs(this.town_centers) do
        if not town_center then
            return
        end

        if not town_center.market or not town_center.market.valid then
            return
        end

        local surface = town_center.market.surface
        local position = town_center.market.position
        local fishes = surface.find_entities_filtered({name = 'fish', position = position, radius = 27})
        if #fishes == 0 then
            return
        end
        if #fishes >= 100 then
            return
        end
        -- pick a random fish
        local t = math_random(1, #fishes)
        local fish = fishes[t]
        -- test against all other fishes
        local guppy = false
        for i, f in pairs(fishes) do
            if i ~= t then
                if math_floor(fish.position.x) == math_floor(f.position.x) and math_floor(fish.position.y) == math_floor(f.position.y) then
                    guppy = true
                end
            end
        end
        if guppy == true then
            for i = 1, math_random(1, 5) do
                surface.create_entity({name = 'water-splash', position = fish.position})
                surface.create_entity({name = 'fish', position = fish.position})
            end
        end
    end
end

return Public
