-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

local Math = require("maps.pirates.math")

local Public = {}

-- Returns random value from values, with given probability weights. Both table parameters are expected to be arrays.
-- NOTE: This function:
-- - MAY return random equally distributed item from "values" when there is at least 1 weight <= 0 and
-- - WILL with all weights <= 0
function Public.raffle(values, weights) --arguments of the form {[a] = A, [b] = B, ...} and {[a] = a_weight, [b] = b_weight, ...} or just {a,b,c,...} and {1,2,3...}
    local total_weight = 0
    for k, w in pairs(weights) do
        assert(values[k])
        if w > 0 then
            total_weight = total_weight + w
        end
        -- negative weights treated as zero
    end

    -- Fallback case
    if total_weight <= 0 then
        local index = Math.random(1, table_size(values))
        return values[index]
    end

    local cumulative_probability = 0
    local rng = Math.random()
    for k, v in pairs(values) do
        assert(weights[k])
        cumulative_probability = cumulative_probability + (weights[k] / total_weight)
        if rng <= cumulative_probability then
            return v
        end
    end

    -- Fallback case
    local index = Math.random(1, table_size(values))
    return values[index]
end

-- Returns random key from table, with given probability values. Works with all types of keys.
-- NOTE: This function:
-- - MAY return random equally distributed item from "values" when there is at least 1 weight <= 0 and
-- - WILL with all weights <= 0
function Public.raffle2(table) --arguments of the form {v1 = w1, v2 = w2, ...}
    local total_weight = 0
    for _, w in pairs(table) do
        if w > 0 then
            total_weight = total_weight + w
        end
        -- negative weights treated as zero
    end

    -- Fallback case
    if total_weight <= 0 then
        local index = Math.random(1, table_size(table))
        for k, _ in pairs(table) do
            if index == 1 then
                return k
            end

            index = index - 1
        end
    end

    local cumulative_probability = 0
    local rng = Math.random()
    for k, w in pairs(table) do
        cumulative_probability = cumulative_probability + w / total_weight
        if rng <= cumulative_probability then
            return k
        end
    end

    -- Fallback case
    local index = Math.random(1, table_size(table))
    for k, _ in pairs(table) do
        if index == 1 then
            return k
        end

        index = index - 1
    end
end

--==thesixthroc's Lambda Raffles

-- This file provides a one-parameter family of raffles called 'Lambda raffles'. When you want to roll the raffle, you also provide a parameter 'lambda', and the raffle weights vary with lambda in a specified way. For example, the parameter could be the game completion progress, and the raffle could produce certain items only in the late game.

function Public.LambdaRaffle(data, lambda, extraConditionParameter)
    -- 	example_argument = {
    -- 	['iron-stick'] = {
    -- 		overallWeight = 1,
    -- 		minLambda = 0,
    -- 		maxLambda = 0.5,
    -- 		shape = 'uniform', -- a uniform raffle weight of 1, if lambda is between 0 and 1
    -- 	},
    -- 	['coal'] = {
    -- 		overallWeight = 3,
    -- 		minLambda = 0,
    -- 		maxLambda = 0.5,
    -- 		shape = 'density', -- a uniform raffle weight of 6, if lambda is between 0 and 1
    -- 	},
    -- 	['copper-wire'] = {
    -- 		overallWeight = 1,
    -- 		minLambda = 0,
    -- 		maxLambda = 1,
    -- 		shape = 'bump', -- the raffle weight is a ⋀ shape, going from (0, 0) to (0.5, 2) to (1, 0)
    -- 		condition = function(x) return x == 'copperIsland' end, --this optional key performs a check on extraConditionParameter to see whether this raffle value should be included at all
    -- 	},
    -- }
    local raffle = {}

    for k, v in pairs(data) do
        if (not v.shape) or (v.shape == "uniform" or v.shape == "flat") then
            if (not v.minLambda) or (lambda >= v.minLambda) then
                if (not v.maxLambda) or (lambda <= v.maxLambda) then
                    if (not v.condition) or (extraConditionParameter and v.condition(extraConditionParameter)) then
                        raffle[k] = v.overallWeight
                    end
                end
            end
        elseif v.shape == "density" then
            if
                v.minLambda
                and v.maxLambda
                and v.maxLambda ~= v.minLambda
                and lambda >= v.minLambda
                and lambda <= v.maxLambda
            then
                if (not v.condition) or (extraConditionParameter and v.condition(extraConditionParameter)) then
                    raffle[k] = v.overallWeight / (v.maxLambda - v.minLambda)
                end
            end
        elseif v.shape == "bump" then
            if v.minLambda and v.maxLambda and lambda >= v.minLambda and lambda <= v.maxLambda then
                if (not v.condition) or (extraConditionParameter and v.condition(extraConditionParameter)) then
                    if v.minLambda == v.maxLambda and lambda == v.minLambda then
                        raffle[k] = v.overallWeight
                    else
                        local midpoint = (v.minLambda + v.maxLambda) / 2
                        local peak = 2 * v.overallWeight
                        local slope = peak / ((v.maxLambda - v.minLambda) / 2)
                        local difference = Math.abs(lambda - midpoint)
                        raffle[k] = peak * (1 - difference * slope)
                    end
                end
            end
        end
    end

    return Public.raffle2(raffle)
end

-- a function that accepts more abbreviated raffle data:
function Public.LambdaRaffleFromAbbreviatedData(abbreviatedData, lambda, extraConditionParameter)
    -- 	example_argument = {
    -- 	['iron-stick'] = {
    -- 		1, 0, 1, 'uniform'
    -- 	},
    -- 	['copper-plate'] = {
    -- 		1, 0, 1, 'uniform', function(x) return x == 'copperIsland' end
    -- 	},
    -- }

    local data = {}
    for k, v in pairs(abbreviatedData) do
        data[k] = {
            overallWeight = v[1],
            minLambda = v[2],
            maxLambda = v[3],
            shape = v[4],
            condition = v[4],
        }
    end
    return Public.LambdaRaffle(data, lambda, extraConditionParameter)
end

return Public
