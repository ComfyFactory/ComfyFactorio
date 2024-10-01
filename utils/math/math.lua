local Public = {}

-- Importing localized math functions from this file has better performance than importing from the global scope:
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

function Public.clamp(min, max, number)
	if number < min then
		return min
	elseif number > max then
		return max
	else
		return number
	end
end

function Public.sgn(number)
	return number > 0 and 1 or (number == 0 and 0 or -1)
end

return Public
