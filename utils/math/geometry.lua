local Public = {}

function Public.snap_to_grid(point)
	return { x = Public.ceil(point.x), y = Public.ceil(point.x) }
end

-- Given an area marked by integer coordinates, returns an array of all the half-integer positions bounded by that area. Useful for constructing tiles.
function Public.all_central_positions_within_area(area, offset)
	local offsetx = offset.x or 0
	local offsety = offset.y or 0
	local xr1, xr2, yr1, yr2 =
		offsetx + Math.ceil(area[1][1] - 0.5),
		offsetx + Math.floor(area[2][1] + 0.5),
		offsety + Math.ceil(area[1][2] - 0.5),
		offsety + Math.floor(area[2][2] + 0.5)

	local positions = {}
	for y = yr1 + 0.5, yr2 - 0.5, 1 do
		for x = xr1 + 0.5, xr2 - 0.5, 1 do
			positions[#positions + 1] = { x = x, y = y }
		end
	end
	return positions
end

-- *** *** --
--*** VECTORS ***--
-- *** *** --

function Public.vector_length(vec)
	return Public.sqrt(vec.x * vec.x + vec.y * vec.y)
end

function Public.vector_sum(...)
	local result = { x = 0, y = 0 }
	for _, vec in ipairs({ ... }) do
		result.x = result.x + vec.x
		result.y = result.y + vec.y
	end
	return result
end

function Public.vector_scaled(vec, scalar)
	return { x = vec.x * scalar, y = vec.y * scalar }
end

function Public.vector_distance(vec1, vec2)
	local vecx = vec2.x - vec1.x
	local vecy = vec2.y - vec1.y
	return Public.sqrt(vecx * vecx + vecy * vecy)
end

-- normalises vector to unit vector (length 1)
-- if vector length is 0, returns {x = 0, y = 1} vector
function Public.vector_norm(vec)
	local vec_copy = { x = vec.x, y = vec.y }
	local vec_length = Public.sqrt(vec_copy.x ^ 2 + vec_copy.y ^ 2)
	if vec_length == 0 then
		vec_copy.x = 0
		vec_copy.y = 1
	else
		vec_copy.x = vec_copy.x / vec_length
		vec_copy.y = vec_copy.y / vec_length
	end
	return { x = vec_copy.x, y = vec_copy.y }
end

-- Returns vector in random direction.
-- scalar: returned vector length. If nil, 1 will be chosen.
function Public.random_vector(scalar)
	scalar = scalar or 1
	local random_angle = Public.random_float_in_range(0, 2 * Public.pi)
	return {
		x = Public.cos(random_angle) * scalar,
		y = Public.sin(random_angle) * scalar,
	}
end

return Public
