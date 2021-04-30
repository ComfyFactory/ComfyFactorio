local Public = {}


--- Turns seconds into a fancy table, each index being a different modulos (second, minute, etc.)
---@param seconds <number>
---@param short <boolean> - True if strings should be kept as short as possible
function Public.seconds_to_fancy(seconds, short)
	short = short or false
	local time_left = seconds

	if time_left < 1 then
		return {"0 seconds"}
	end

	local names = {
		{"second", "s"},
		{"minute", "min"},
		{"hour", "h"},
		{"day", "d"},
		{"week", "w"},
		{"month", "m"},
		{"year", "y"}
	}
	local modulos = {
		1,
		60,
		3600,
		3600*24,
		3600*24*7,
		3660*24*30,
		3660*24*365.25
	}

	local values = {}
	local pretty = {}

	-- Iterates modulos in reverse
	-- Adds fitting time to values 
	-- Subtracts time_left with added time
	for i = #modulos, 1, -1 do
		local fit_time = math.floor(time_left/modulos[i])
        table.insert(values, fit_time)
		time_left = time_left - fit_time*modulos[i]
    end

	local internal_name_index = nil
	if not short then
		internal_name_index = 1
	else
		internal_name_index = 2
	end

	-- Connects name with index value
	-- #values-i+1 because the values array is flipped upside down and this converts the indices back!
	for i = #names, 1, -1 do
		if values[#values-i+1] > 0 then
			local _name = names[i][internal_name_index]
			-- Adds 's' to name if applicable. Example: 2 minute -> 2 minutes
			if values[#values-i+1] > 1 and not short then
				_name = _name .. "s"
			end
			table.insert(pretty, values[#values-i+1] .." ".._name)
		end
    end

	return pretty
end

--- Turns a fancy table into a fancy string
---@param fancy_array <table>
function Public.fancy_time_formatting(fancy_array)
	if #fancy_array == 0 then return end
	local fancy_string = ""
	if #fancy_array > 1 then
		for i = 1, #fancy_array, 1 do
			if i == 1 then 
				fancy_string = fancy_array[1] 
			else
				fancy_string = fancy_string .. ", " .. fancy_array[i]
			end
		end
		return fancy_string
	else
		return fancy_array[1]
	end
end


--- Filters a fancy table for specific words. Entries within will be purged or kept based on the content and the filter mode
---@param mode <boolean> - True acts as whitelist, only time data in the filter will be kept. False acts a blacklist
function Public.filter_time(fancy_array, filter_words, mode)
	local filtered_array = {}
	for i=1, #fancy_array, 1 do
		local _subject = fancy_array[i]
		for fi=1, #filter_words, 1 do
			local result = string.find(_subject, filter_words[fi]) -- nil if not found
			result = type(result) ~= type(nil) -- true if words contained in string
			if result == true and mode == true then 
				table.insert(filtered_array, _subject)
				break
			elseif result == true and mode == false then
			    break
			elseif result == false and mode == false and fi == #filter_words then
				table.insert(filtered_array, _subject)
			end
		end		
	end
	return filtered_array
end


--- Quick function to turn seconds into a full string of time
--- Example: short_fancy_time(1803) --> "30 minutes, 3 seconds"
---@param seconds <number>
function Public.fancy_time(seconds)
	local fancy = Public.seconds_to_fancy(seconds,false)
	fancy = Public.fancy_time_formatting(fancy)
	return fancy
end


--- Quick function to turn seconds into a shortend string of time, excluding seconds
--- Example: short_fancy_time(1803) --> "30 min"
---@param seconds <number>	
function Public.short_fancy_time(seconds)
	local fancy = Public.seconds_to_fancy(seconds,true)
	fancy = Public.filter_time(fancy, {"seconds","s"}, false)
	fancy = Public.fancy_time_formatting(fancy)
	return fancy
end	


return Public
