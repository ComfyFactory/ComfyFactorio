-- by Hasbetack
-- used to select a Item out of a given list works by inputing a list with weights.
-- Functions
-- get_Total -> used for adding all the weights of a list
-- roll -> used for selecting an item randomly accordingly to the weights

local math_random = math.random

local function get_Total(list)
    total_value = 0
    for k, v in pairs(list) do
        total_value = v
    end
    return total_value
end

function Public.roll(list,blacklist)
    if not list then
        return
    end
    rand =math_random(0,getTotal(list)) 
    for k, v in pairs(list) do
        rand = rand - v
        if rand <= 0 then
            return k
        end
    end
end
