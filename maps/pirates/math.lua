
local Public = {}

Public.random = math.random
Public.randomseed = math.randomseed
Public.sqrt = math.sqrt
Public.min = math.min
Public.max = math.max
Public.rad = math.rad
Public.floor = math.floor
Public.abs = math.abs
Public.ceil = math.ceil
Public.log = math.log
Public.atan = math.atan
Public.sin = math.sin
Public.cos = math.cos
Public.pi = math.pi
Public.deg = math.deg
Public.round = math.round




--- SCALING CURVES ---

function Public.sloped(x, slope)
	return 1 + ((x - 1) * slope)
end
-- SLOPE GUIDE
-- slope 1 -> {0.25, 0.50, 0.75, 1.00, 1.50, 3.00, 5.00}
-- slope 4/5 -> {0.40, 0.60, 0.80, 1.00, 1.40, 2.60, 4.20}
-- slope 3/5 -> {0.55, 0.70, 0.85, 1.00, 1.30, 2.20, 3.40}
-- slope 2/5 -> {0.70, 0.80, 0.90, 1.00, 1.20, 1.80, 2.40}

-- EXPONENT GUIDE
-- exponent 1 -> {0.25, 0.50, 0.75, 1.00, 1.50, 3.00, 5.00}
-- exponent 1.5 -> {0.13, 0.35, 0.65, 1.00, 1.84, 5.20, 11.18}
-- exponent 2 -> {0.06, 0.25, 0.56, 1.00, 2.25, 9.00, 25.00}
-- exponent -1.2 -> {5.28, 2.30, 1.41, 1.00, 0.61, 0.27, 0.14}


function Public.sgn(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end

function Public.length(vec)
	return Public.sqrt(vec.x * vec.x + vec.y * vec.y)
end

function Public.slopefromto(x, from, to)
	return Public.max(0,Public.min(1,
	(x - from) / (to - from)
	))
end

function Public.distance(vec1, vec2)
	local vecx = vec2.x - vec1.x
	local vecy = vec2.y - vec1.y
		return Public.sqrt(vecx * vecx + vecy * vecy)
end

function Public.vector_sum(vec1, vec2)
	return {x = vec1.x + vec2.x, y = vec1.y + vec2.y}
end


function Public.shuffle(tbl)
	local size = #tbl
		for i = size, 2, -1 do
			local rand = Public.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function is_closer(pos1, pos2, pos)
    return ((pos1.x - pos.x) ^ 2 + (pos1.y - pos.y) ^ 2) < ((pos2.x - pos.x) ^ 2 + (pos2.y - pos.y) ^ 2)
end
function Public.shuffle_distancebiased(tbl, position)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = Public.random(i)
        if is_closer(tbl[i].position, tbl[rand].position, position) and i > rand then
            tbl[i], tbl[rand] = tbl[rand], tbl[i]
        end
    end
    return tbl
end

function Public.raffle(values, weights) --arguments of the form {[a] = A, [b] = B, ...} and {[a] = a_weight, [b] = b_weight, ...} or just {a,b,c,...} and {1,2,3...}

	local total_weight = 0
	for k,w in pairs(weights) do
		assert(values[k])
		if w > 0 then
			total_weight = total_weight + w
		end
		-- negative weights treated as zero
	end
	assert(total_weight > 0)

	local cumulative_probability = 0
	local rng = Public.random()
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
	assert(total_weight > 0)

	local cumulative_probability = 0
	local rng = Public.random()
	for k,v in pairs(table) do
		cumulative_probability = cumulative_probability + v/total_weight
		if rng <= cumulative_probability then
			return k
		end
	end
end

return Public