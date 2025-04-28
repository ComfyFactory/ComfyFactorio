local Public = {}
Public.__index = Public

function Public:new(limit)
	return setmetatable({ count = limit, limit = limit }, self)
end

function Public:acquire()
	if self.count > 0 then
		self.count = self.count - 1
		return true
	else
		return false
	end
end

function Public:release()
	if self.count < self.limit then
		self.count = self.count + 1
	end
end

return Public
