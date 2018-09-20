local index = {
"blkCUwDfFaRxezkA", "PEVkYcsbVwnnKWKm", "RmApKqaHBnDdjlUf", "eovuYGvdICGhruuU"
}

local data = {}
for _, i in pairs(index) do
	table.insert(data, require ("session_data." .. i))	
end
return data