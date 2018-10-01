-- read session file names
local dirname = '"scenarios/ComfyFactorio/session_data"'
local f = io.popen('dir /b ' .. dirname)
local session_filenames = {}
for filename in f:lines() do
	local str = string.sub(filename, 1, -5)
	table.insert(session_filenames, str)
end

--write new session index file
local file = io.open("scenarios/ComfyFactorio/session_data.lua", "w")
file:write("local index = {\n")
for x = 1, #session_filenames, 1 do
	if string.len(session_filenames[x]) == 16 then
		file:write('"' .. session_filenames[x] .. '"')
		if session_filenames[x + 1] then file:write(',') end
	end
end

file:write("\n }\n\n")
file:write("local data = {}\n")
file:write("for _, i in pairs(index) do\n")
file:write('	table.insert(data, require ("session_data." .. i))\n')
file:write("end\n")
file:write("return data\n")
file:close()



	

