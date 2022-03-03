
local Math = require 'maps.pirates.math'
local inspect = require 'utils.inspect'.inspect
local simplex_noise = require 'utils.simplex_noise'.d2 --rms ~ 0.1925
local perlin_noise = require 'utils.perlin_noise'
local Memory = require 'maps.pirates.memory'
local CoreData = require 'maps.pirates.coredata'
local NoisePregen = require 'maps.pirates.noise_pregen.noise_pregen'

local Public = {}

-- Lua 5.2 compatibility
-- local unpack = unpack or table.unpack


function Public.rgb_from_hsv(h, s, v)
	-- 0 ≤ H < 360, 0 ≤ S ≤ 1 and 0 ≤ V ≤ 1
	local r, g, b
	local c = v * s
	local x = c * (1 - Math.abs(((h/60) % 2) - 1))
	local m = v - c
	if h < 60 then
		r=c+m
		g=x+m
		b=m
	elseif h < 120 then
		r=x+m
		g=c+m
		b=m
	elseif h < 180 then
		r=m
		g=c+m
		b=x+m
	elseif h < 240 then
		r=m
		g=x+m
		b=c+m
	elseif h < 300 then
		r=x+m
		g=m
		b=c+m
	else
		r=c+m
		g=m
		b=x+m
	end
	return {r = 255*r, g = 255*g, b = 255*b}
end

function Public.stable_sort(list, comp) --sorts but preserves ordering of equals
	comp = comp or function (a, b) return a < b end

    local num = 0
    for k, v in ipairs(list) do
        num = num + 1
    end

    if num <= 1 then
        return
    end

    local sorted = false
    local n = num
    while not sorted do
        sorted = true
        for i = 1, n - 1 do
            if comp(list[i+1], list[i]) then
                local tmp = list[i]
                list[i] = list[i+1]
                list[i+1] = tmp

                sorted = false
            end
        end
        n = n - 1
    end
end

function Public.psum(plist)
	local totalx, totaly = 0, 0
	for i = 1, #plist do
		if plist[i][1] then --multiplier
			if plist[i][2] and plist[i][2].x and plist[i][2].y then
				totalx = totalx + plist[i][1] * plist[i][2].x
				totaly = totaly + plist[i][1] * plist[i][2].y
			end
		elseif plist[i].x and plist[i].y then
			totalx = totalx + plist[i].x
			totaly = totaly + plist[i].y
		end
	end
	return {x = totalx, y = totaly}
end

function Public.interpolate(vector1, vector2, param)
	return {x = vector1.x * (1-param) + vector2.x * param, y = vector1.y * (1-param) + vector2.y * param}
end

function Public.split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function Public.contains(table, element)
	if not table then return false end
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end

function Public.snap_coordinates_for_rails(p)
	return {x = p.x + (p.x % 2) - 1, y = p.y + (p.y % 2)}
end

function Public.spritepath_to_richtext(spritepath)
	return '[' .. spritepath:gsub("/", "=") .. ']'
end

function Public.nonrepeating_join_dict(t1, t2)
	t1 = t1 or {}
	t2 = t2 or {}
	local t3 = {}
	for k, i1 in pairs(t1) do
		t3[k] = i1
	end
	for k, i2 in pairs(t2) do
		t3[k] = i2
	end
	return t3
end

function Public.nonrepeating_join(t1, t2)
	t1 = t1 or {}
	t2 = t2 or {}
	local t3 = {}
	for _, i1 in pairs(t1) do
		t3[#t3 + 1] = i1
	end
	for _, i2 in pairs(t2) do
		if not Public.contains(t3, i2) then
			t3[#t3 + 1] = i2
		end
	end
	return t3
end

function Public.exclude(t, t_exclude)
	t_exclude = t_exclude or {}
	local t2 = {}
	for _, i in pairs(t) do
		if not Public.contains(t_exclude, i) then
			t2[#t2 + 1] = i
		end
	end
	return t2
end

function Public.exclude_position_arrays(a, b_exclude)
	b_exclude = b_exclude or {}
	local a2 = {}
	for x, xtab in pairs(a) do
		for y, _ in pairs(xtab) do
			if not (b_exclude[x] and b_exclude[x][y]) then
				if not a2[x] then a2[x] = {} end
				a2[x][y] = true
			end
		end
	end
	return a2
end

function Public.unordered_table_with_values_removed(tbl, val)
	local to_keep = {}
	for k, v in pairs(tbl) do
		if v ~= val then to_keep[k] = v end
	end
	return to_keep
end

function Public.ordered_table_with_values_removed(tbl, val)
	local to_keep = {}
	local j = 1
	for i = 1, #tbl do
		if tbl[i] ~= val then
			to_keep[j] = tbl[i]
			j = j + 1
		end
	end
	return to_keep
end

function Public.ordered_table_with_single_value_removed(tbl, val)
	local to_keep = {}
	local j = 1
	local taken_one = false
	for i = 1, #tbl do
		if (tbl[i] ~= val) or taken_one then
			to_keep[j] = tbl[i]
			j = j + 1
		else
			taken_one = true
		end
	end
	return to_keep
end

function Public.ordered_table_with_index_removed(tbl, index)
	local to_keep = {}
	local j = 1
	for i = 1, #tbl do
		if i ~= index then
			to_keep[j] = tbl[i]
			j = j + 1
		end
	end
	return to_keep
end

function Public.length(tbl)
	local count = 0
	for k, _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

function Public.standard_string_form_of_time_in_seconds(time)
	local time2, str1
	if time >= 0 then
		time2 = time
		str1 = ''
	else
		time2 = - time
		str1 = '-'
	end
	local str2 = ''
	local hours = Math.floor(Math.ceil(time2) / 3600)
	local minutes = Math.floor(Math.ceil(time2) / 60)
	local seconds = Math.ceil(time2)
	if hours >= 1 then
		str2 = string.format('%.0fh%.0fm%.0fs', hours, minutes % 60, seconds % 60)
	elseif minutes >= 1 then
		str2 = string.format('%.0fm%.0fs', minutes, seconds % 60)
	else
		str2 = string.format('%.0fs', seconds)
	end
	return str1 .. str2
end

function Public.time_longform(seconds)
	local seconds2, str1
	if seconds >= 0 then
		seconds2 = seconds
		str1 = ''
	else
		seconds2 = - seconds
		str1 = '-'
	end
	local str2
	if seconds2 < 60 - 1 then
		str2 = string.format('%.0f seconds', Math.ceil(seconds2))
	elseif seconds2 < 60 * 60 - 1 then
		str2 = string.format('%.0f mins, %.0f seconds', Math.floor(Math.ceil(seconds2) / 60), Math.ceil(seconds2) % 60)
	elseif seconds2 < 60 * 60 * 24 - 1 then
		str2 = string.format('%.0f hours, %.0f mins, %.0f seconds', Math.floor(Math.ceil(seconds2) / (60*60)), Math.floor(Math.ceil(seconds2) / 60) % 60, Math.ceil(seconds2) % 60)
	else
		str2 = string.format('%.0fdays, %.0f hours, %.0f mins, %.0f seconds', Math.floor(Math.ceil(seconds2) / (24*60*60)), Math.floor(Math.ceil(seconds2) / (60*60)) % 24, Math.floor(Math.ceil(seconds2) / 60) % 60, Math.ceil(seconds2) % 60)
	end
	return str1 .. str2
end

function Public.time_mediumform(seconds)
	local seconds2, str1
	if seconds >= 0 then
		seconds2 = seconds
		str1 = ''
	else
		seconds2 = - seconds
		str1 = '-'
	end
	local str2
	local seconds3 = Math.floor(seconds2)
	if seconds3 < 60 - 1 then
		str2 = string.format('%.0fs', seconds3)
	elseif seconds3 < 60 * 60 - 1 then
		str2 = string.format('%.0fm%.0fs', Math.floor(seconds3 / 60), seconds3 % 60)
	elseif seconds3 < 60 * 60 * 24 - 1 then
		str2 = string.format('%.0fh%.0fm%.0fs', Math.floor(seconds3 / (60*60)), Math.floor(seconds3 / 60) % 60, seconds3 % 60)
	else
		str2 = string.format('%.0fd%.0fh%.0fm%.0fs', Math.floor(seconds3 / (24*60*60)), Math.floor(seconds3 / (60*60)) % 24, Math.floor(seconds3 / 60) % 60, seconds3 % 60)
	end
	return str1 .. str2
end

function Public.deepcopy(obj) --doesn't copy metatables
	if type(obj) ~= 'table' then return obj end
	local res = {}
	for k, v in pairs(obj) do res[Public.deepcopy(k)] = Public.deepcopy(v) end
	return res
end


function Public.bignumber_abbrevform(number) --e.g. 516, 1.2k, 21.4k, 137k
	local str1, str2, number2
	if number >= 0 then
		number2 = number
		str1 = ''
	else
		number2 = - number
		str1 = '-'
	end

	if number2 == 0 then
		str2 = '0'
	elseif number2 < 1000 then
		str2 = string.format('%.0d', Math.floor(number2))
	elseif number2 < 100000 then
		str2 = string.format('%.1fk', Math.floor(number2/100)/10)
	else
		str2 = string.format('%.0dk', Math.floor(number2/1000))
	end

	return str1 .. str2
end
function Public.bignumber_abbrevform2(number) --e.g. 516, 1.2k, 21k, 136k
	local str1, str2, number2
	if number >= 0 then
		number2 = number
		str1 = ''
	else
		number2 = - number
		str1 = '-'
	end

	if number2 == 0 then
		str2 = '0'
	elseif number2 < 1000 then
		str2 = string.format('%.0d', Math.floor(number2))
	elseif number2 < 10000 then
		str2 = string.format('%.1fk', Math.floor(number2/100)/10)
	else
		str2 = string.format('%.0dk', Math.floor(number2/1000))
	end

	return str1 .. str2
end
function Public.negative_rate_abbrevform(number)
	local str1, str2, number2
	if number > 0 then
		number2 = number
		str1 = ''
	else
		number2 = - number
		str1 = '-'
	end
	if number2 == 0 then
		str2 = '0'
	elseif number2 < 10 then
		str2 = string.format('%.1f', Math.ceil(number2*10)/10)
	else
		str2 = string.format('%.0d', Math.ceil(number2))
	end

	return str1 .. str2 .. '/s'
end


function Public.noise_field_simplex_2d(noise_data, seed, normalised)
	normalised = normalised or false

	local f = function(position)
		local noise, _seed, weight_sum = 0, seed, 0
		for i = 1, #noise_data do
			local n = noise_data[i]
			local toadd = n.amplitude
			if n.wavelength > 0 then --=0 codes for infinite
				toadd = toadd * simplex_noise(position.x / n.wavelength, position.y / n.wavelength, _seed)
				_seed = _seed + 12345 --some deficiencies
			end

			if normalised then weight_sum = weight_sum + n.amplitude end
			noise = noise + toadd
		end
		if normalised then noise = noise / weight_sum end
		return noise
	end
	return f
end



function Public.hardcoded_noise_field_decompress(fieldtype, noise_data, seed, normalised)
	normalised = normalised or false

	local hardcoded_upperscale = NoisePregen[fieldtype].upperscale
	local hardcoded_boxsize = NoisePregen[fieldtype].boxsize
	local hardcoded_wordlength = NoisePregen[fieldtype].wordlength
	local factor = NoisePregen[fieldtype].factor

	local f = function(position)
		local noise, weight_sum, _seed = 0, 0, seed
		for i = 1, #noise_data do
			local n = noise_data[i]
			local toadd = n.amplitude
			local seedfactor = n.seedfactor or 1

			if n.upperscale > 0 then --=0 codes for infinite
				local scale = n.upperscale / 100

				local seed2 = seed * seedfactor

				local x2 = position.x / scale
				local y2 = position.y / scale

				local x2remainder = x2%1
				local y2remainder = y2%1
	
				local x2floor = x2 - x2remainder
				local y2floor = y2 - y2remainder

				local topleftnoiseindex = seed2 % (1000*1000)
	
				local relativeindex00 = x2floor + y2floor * 1000

				local totalindex00 = (topleftnoiseindex + relativeindex00) % (1000*1000)
				local totalindex10 = (1 + topleftnoiseindex + relativeindex00) % (1000*1000)
				local totalindex01 = (1000 + topleftnoiseindex + relativeindex00) % (1000*1000)

				local strindex00 = 1 + totalindex00 * hardcoded_wordlength
				local strindex10 = 1 + totalindex10 * hardcoded_wordlength
				local strindex01 = 1 + totalindex01 * hardcoded_wordlength

				local str00 = NoisePregen[fieldtype].Data:sub(strindex00, strindex00 + (hardcoded_wordlength - 1))
				local str10 = NoisePregen[fieldtype].Data:sub(strindex10, strindex10 + (hardcoded_wordlength - 1))
				local str01 = NoisePregen[fieldtype].Data:sub(strindex01, strindex01 + (hardcoded_wordlength - 1))
				local noise00, noise10, noise01 = 0, 0, 0
				for j = 0, hardcoded_wordlength-1 do
					noise00 = noise00 + NoisePregen.dec[str00:sub(hardcoded_wordlength - j, hardcoded_wordlength - j)] * (NoisePregen.encoding_length ^ j)
					noise10 = noise10 + NoisePregen.dec[str10:sub(hardcoded_wordlength - j, hardcoded_wordlength - j)] * (NoisePregen.encoding_length ^ j)
					noise01 = noise01 + NoisePregen.dec[str01:sub(hardcoded_wordlength - j, hardcoded_wordlength - j)] * (NoisePregen.encoding_length ^ j)
				end

				if noise00 % 2 == 1 then noise00 = -noise00 end
				noise00 = noise00 / (NoisePregen.encoding_length ^ (hardcoded_wordlength-1))

				if noise10 % 2 == 1 then noise10 = -noise10 end
				noise10 = noise10 / (NoisePregen.encoding_length ^ (hardcoded_wordlength-1))

				if noise01 % 2 == 1 then noise01 = -noise01 end
				noise01 = noise01 / (NoisePregen.encoding_length ^ (hardcoded_wordlength-1))
	
				-- local hardnoise00 = tonumber(strsub00:sub(2,6))/10000
				-- if strsub00:sub(1,1) == '-' then hardnoise00 = -hardnoise00 end
				-- local hardnoise10 = tonumber(strsub10:sub(2,6))/10000
				-- if strsub10:sub(1,1) == '-' then hardnoise10 = -hardnoise10 end
				-- local hardnoise01 = tonumber(strsub01:sub(2,6))/10000
				-- if strsub01:sub(1,1) == '-' then hardnoise01 = -hardnoise01 end

				-- log(inspect{topleftnoiseindex, topleftnoiseindex2, relativeindex00, relativeindex10, relativeindex01})
				-- log(inspect{strindex00, strindex10, strindex01, hardnoise1, hardnoise2, hardnoise3})
	
				local interpolatedhardnoise = noise00 + x2remainder*(noise10-noise00) + y2remainder*(noise01-noise00)
	
				toadd = toadd * factor * tonumber(interpolatedhardnoise)
				_seed = _seed + 12345
			end

			if normalised then weight_sum = weight_sum + n.amplitude end
			noise = noise + toadd
		end
		if normalised then noise = noise / weight_sum end
		return noise
	end
	return f
end



function Public.hardcoded_noise_field(fieldtype, noise_data, seed, normalised)
	normalised = normalised or false

	local hardcoded_upperscale = NoisePregen[fieldtype].upperscale --100
	local hardcoded_boxsize = NoisePregen[fieldtype].boxsize --1000
	local hardcoded_wordlength = NoisePregen[fieldtype].wordlength
	local factor = NoisePregen[fieldtype].factor

	local f = function(position)
		local noise, weight_sum, _seed = 0, 0, seed
		for i = 1, #noise_data do
			local n = noise_data[i]
			local toadd = n.amplitude
			local seedfactor = n.seedfactor or 1

			if n.upperscale > 0 then --=0 codes for infinite
				local scale = n.upperscale / 100

				local seed2 = seed * seedfactor

				local x2 = position.x / scale
				local y2 = position.y / scale

				local x2remainder = x2%1
				local y2remainder = y2%1
	
				local x2floor = x2 - x2remainder
				local y2floor = y2 - y2remainder

				local seedindex = seed2 % (1000*1000)
	
				local relativeindex00 = x2floor + y2floor * 1000

				local noiseindex1 = seedindex + relativeindex00

				local totalindex00 = noiseindex1 % (1000*1000)
				local totalindex10 = (1 + noiseindex1) % (1000*1000)
				local totalindex01 = (1000 + noiseindex1) % (1000*1000)

				local strindex00 = 1 + totalindex00 * hardcoded_wordlength
				local strindex10 = 1 + totalindex10 * hardcoded_wordlength
				local strindex01 = 1 + totalindex01 * hardcoded_wordlength

				local str00 = NoisePregen[fieldtype].Data:sub(strindex00, strindex00 + (hardcoded_wordlength - 1))
				local str10 = NoisePregen[fieldtype].Data:sub(strindex10, strindex10 + (hardcoded_wordlength - 1))
				local str01 = NoisePregen[fieldtype].Data:sub(strindex01, strindex01 + (hardcoded_wordlength - 1))

				local noise00 = tonumber(str00:sub(2,6))/10000
				if str00:sub(1,1) == '-' then noise00 = -noise00 end
				local noise10 = tonumber(str10:sub(2,6))/10000
				if str10:sub(1,1) == '-' then noise10 = -noise10 end
				local noise01 = tonumber(str01:sub(2,6))/10000
				if str01:sub(1,1) == '-' then noise01 = -noise01 end

				-- log(inspect{topleftnoiseindex, topleftnoiseindex2, relativeindex00, relativeindex10, relativeindex01})
				-- log(inspect{strindex00, strindex10, strindex01, hardnoise1, hardnoise2, hardnoise3})
	
				local interpolatedhardnoise = noise00 + x2remainder*(noise10-noise00) + y2remainder*(noise01-noise00)
	
				toadd = toadd * factor * tonumber(interpolatedhardnoise)
				_seed = _seed + 12345 --some deficiencies
			end

			if normalised then weight_sum = weight_sum + n.amplitude end
			noise = noise + toadd
		end
		if normalised then noise = noise / weight_sum end
		return noise
	end
	return f
end



function Public.noise_generator(noiseparams, seed)
	--memoizes locally
	local noiseparams = noiseparams or {}
	local seed = seed or 0

	local ret = {}
	for k, v in pairs(noiseparams) do
		local fn
		if v.type == 'simplex_2d' then
			fn = Public.noise_field_simplex_2d(v.params, seed, v.normalised)
		elseif v.type == 'perlin_1d_circle' then
			fn = Public.noise_field_perlin_1d_circle(v.params, seed, v.normalised)
		else
			fn = Public.hardcoded_noise_field(v.type, v.params, seed, v.normalised)
		end
		ret[k] = Public.memoize(fn)
	end

	function ret:addNoise(key, new_noise_function)
		if self[key] then return
		else
			self[key] = Public.memoize(new_noise_function)
		end
	end
	ret.seed = seed
	-- ret.noiseparams = noiseparams
	return ret
end


local function cache_get(cache, params)
  local node = cache
  for i=1, #params do
    node = node.children and node.children[params[i]]
    if not node then return nil end
  end
  return node.results
end

local function cache_put(cache, params, results)
  local node = cache
  local param
  for i=1, #params do
    param = params[i]
    node.children = node.children or {}
    node.children[param] = node.children[param] or {}
    node = node.children[param]
  end
  node.results = results
end



-- The following functions were adapted from https://github.com/kikito/memoize.lua/blob/master/memoize.lua, under the MIT License:
-- [[
--     MIT LICENSE
--     Copyright (c) 2018 Enrique García Cota
--     Permission is hereby granted, free of charge, to any person obtaining a
--     copy of this software and associated documentation files (the
--     "Software"), to deal in the Software without restriction, including
--     without limitation the rights to use, copy, modify, merge, publish,
--     distribute, sublicense, and/or sell copies of the Software, and to
--     permit persons to whom the Software is furnished to do so, subject to
--     the following conditions:
--     The above copyright notice and this permission notice shall be included
--     in all copies or substantial portions of the Software.
--     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
--     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
--     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
--     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
--     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
--     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
--     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--   ]]

local function is_callable(f)
	local tf = type(f)
	if tf == 'function' then return true end
	if tf == 'table' then
	  local mt = getmetatable(f)
	  return type(mt) == 'table' and is_callable(mt.__call)
	end
	return false
  end
  
-- == memoization
-- memoize takes in a function and outputs an auto-memoizing version of the same
-- e.g. local memoized_f = memoize(f, <cache>), explicit cache is optional
function Public.memoize(f, cache)
  cache = cache or {}

  if not is_callable(f) then
    log(string.format(
        "Only functions and callable tables are memoizable. Received %s (a %s)",
        tostring(f), type(f)))
  end

  return function (...)
    local params = {...}

    local results = cache_get(cache, params)
    if not results then
      results = { f(...) }
      cache_put(cache, params, results)
    end

    return table.unpack(results)
  end
end

return Public