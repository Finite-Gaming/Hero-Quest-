local Queue = {}
Queue.__index = Queue

function Queue.new(queue)
	local self = setmetatable({}, Queue)

	self._queue = {}

	return self
end

function Queue:Push(data)
	table.insert(self._queue, data)
end

function Queue:Pop()
	return table.remove(self._queue, 1)
end

function Queue:IsEmpty()
	return #self._queue == 0
end

return Queue