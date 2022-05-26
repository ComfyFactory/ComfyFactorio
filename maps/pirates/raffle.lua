local Math = require 'maps.pirates.math'

local Public = {}

function Public.raffle(values, weights) --arguments of the form {[a] = A, [b] = B, ...} and {[a] = a_weight, [b] = b_weight, ...} or just {a,b,c,...} and {1,2,3...}

	local total_weight = 0
	for k,w in pairs(weights) do
		assert(values[k])
		if w > 0 then
			total_weight = total_weight + w
		end
		-- negative weights treated as zero
	end
	if (not (total_weight > 0)) then return nil end

	local cumulative_probability = 0
	local rng = Math.random()
	for k,v in pairs(values) do
		assert(weights[k])
		cumulative_probability = cumulative_probability + (weights[k] / total_weight)
		if rng <= cumulative_probability then
			return v
		end
	end
end

function Public.raffle2(table) --arguments of the form {v1 = w1, v2 = w2, ...}

	local total_weight = 0
	for k,w in pairs(table) do
		if w > 0 then
			total_weight = total_weight + w
		end
		-- negative weights treated as zero
	end
	if (not (total_weight > 0)) then return nil end

	local cumulative_probability = 0
	local rng = Math.random()
	for k,v in pairs(table) do
		cumulative_probability = cumulative_probability + v/total_weight
		if rng <= cumulative_probability then
			return k
		end
	end
end


function Public.LambdaRaffle(data, lambda, extraConditionParameter)
-- 	example_argument = {
-- 	['iron-stick'] = {
-- 		overallWeight = 1,
-- 		minLambda = 0,
-- 		maxLambda = 1,
-- 		shape = 'uniform',
-- 		condition = function(x) return x == 'ironIsland' end,
-- 	},
-- }
	local raffle = {}

	for k, v in pairs(data) do
		if (not v.shape) or (v.shape == 'uniform' or v.shape == 'flat') then
			if (not v.minLambda) or (lambda >= v.minLambda) then
				if (not v.maxLambda) or (lambda <= v.maxLambda) then
					if (not v.condition) or (extraConditionParameter and v.condition(extraConditionParameter)) then
						raffle[k] = v.overallWeight
					end
				end
			end
		elseif (v.shape == 'density') then
			if v.minLambda and v.maxLambda and v.maxLambda ~= v.minLambda and lambda >= v.minLambda and lambda <= v.maxLambda then
				if (not v.condition) or (extraConditionParameter and v.condition(extraConditionParameter)) then
					raffle[k] = v.overallWeight / (v.maxLambda - v.minLambda)
				end
			end
		elseif (v.shape == 'bump') then
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


return Public