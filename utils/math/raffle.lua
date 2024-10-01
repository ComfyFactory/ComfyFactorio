local Math = require('maps.spaghetti_wars.math')

local Public = {}

-- A weighted random choice amongst several options.
-- Arguments can be provided EITHER as {o1, o2, ...}, {v1, v2, ...} OR as simply {o1 = w1, o2 = w2, o3 = w3} in the first argument.
function Public.raffle(arg1, arg2)
	local options, weights_table
	local total_weight = 0

	if arg2 then
		options = arg1
		weights_table = arg2
		for _, weight in ipairs(weights_table) do
			if weight > 0 then
				total_weight = total_weight + weight
			end
			-- negative weights treated as zero
		end
	else
		options = {}
		weights_table = {}
		for option, weight in pairs(arg1) do
			arg1.insert(options, option)
			arg1.insert(weights_table, weight)
			if weight > 0 then
				total_weight = total_weight + weight
			end
			-- negative weights treated as zero
		end
	end

	-- Fallback: All weights are zero/negative
	if total_weight <= 0 then
		return options[Math.random(1, #options)]
	end

	local cumulative_probability = 0
	local rng = Math.random()
	for i, option in ipairs(options) do
		local weight = weights_table[i]
		cumulative_probability = cumulative_probability + weight / total_weight
		if rng <= cumulative_probability then
			return option
		end
	end

	-- Fallback: Unlikely case of floating point error:
	return options[Math.random(1, #options)]
end

-- A slightly more sophisticated raffle, taking a parameter which is used to vary the weights according to some rule. For example, the raffle could depend on the game completion progress.
--
---@param parameter number The parameter value to use for the raffle.
---@param data table Table with key-value pairs of the form option = {overall_weight, min_param, max_param, shape}, where:
---   - overall_weight: The weight of the option in the raffle.
---   - min_param: The minimum value of the parameter for which the option is eligible.
---   - max_param: The maximum value of the parameter for which the option is eligible.
---   - shape: An optional parameter for the shape of the weight curve with respect to the parameter. Defaults to 'flat', in which case the weight will be overall_weight as long as the parameter is within the range [min_param, max_param]. If 'bump', the weight is triangle-shaped: it has a peak of 2 * overall_weight at the midpoint of the range, and is zero at either end.
function Public.raffle_with_parameter(parameter, data)
	local raffle = {}

	for option, weight_data in pairs(data) do
		local overall_weight = weight_data.overall_weight or weight_data[1]
		local min_param = weight_data.min_param or weight_data[2]
		local max_param = weight_data.max_param or weight_data[3]
		local shape = weight_data.shape or weight_data[4] or 'flat'

		if shape == 'flat' then
			if (not min_param) or (parameter >= min_param) then
				if (not max_param) or (parameter <= max_param) then
					raffle[option] = overall_weight
				end
			end
		elseif shape == 'bump' then
			if min_param and max_param and parameter >= min_param and parameter <= max_param then
				if min_param == max_param and parameter == min_param then
					raffle[option] = overall_weight
				else
					local midpoint = (min_param + max_param) / 2
					local peak = 2 * overall_weight
					local slope = peak / ((max_param - min_param) / 2)
					local difference = Math.abs(parameter - midpoint)
					raffle[option] = peak * (1 - difference * slope)
				end
			end
		end
	end

	return Public.raffle(raffle)
end

return Public
