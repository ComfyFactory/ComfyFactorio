-- by Hasbetack
-- used to select a Item out of a given list works by inputing a list with weights.
-- Functions
-- get_Total -> used for adding all the weights of a list
-- roll -> used for selecting an item randomly accordingly to the weights
local Public = {}

local math_random = math.random

local function get_Total(list,blacklist)

    total_value = 0
    if not blacklist then
        for k, v in pairs(list) do
            total_value = v
        end
    else
        for k, v in pairs(list) do
            if not (blacklist[k] ~= nil) then
                total_value = v
            end 
        end
    end
    return total_value
end

function Public.roll(list,blacklist)
    if not list then
        return
    end
    if not blacklist then
        rand =math_random(0,get_Total(list))
        for k, v in pairs(list) do
            rand = rand - v
            if rand <= 0 then
                return k
            end
        end
    else
        rand =math_random(0,get_Total(list,blacklist))
        for k, v in pairs(list) do
            if not (blacklist[k] ~= nil) then
                rand = rand - v
                if rand <= 0 then
                    return k
                end
            end
        end
    end
end

return Public