--- Various utility functions for tables
-- @classmod TableUtils
-- @author frick

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Compliance"))

local TableUtils = {}

function TableUtils.swapArrange(t)
    local newTable = {}
    for i, v in pairs(t) do
        newTable[v] = i
    end

    return newTable
end

function TableUtils.count(t)
    local count = 0
    for _ in pairs(t) do
        count += 1
    end

    return count
end

function TableUtils.getRandomDictKey(dict)
    local keyTable = {}
    for key, _ in pairs(dict) do
        table.insert(keyTable, key)
    end

    return keyTable[math.random(1, #keyTable)]
end

function TableUtils.shallowCopy(t)
    local copy = {}
    for i, v in pairs(t) do
        copy[i] = v
    end
    return copy
end

function TableUtils.deepCopy(t)
    local copy = {}
	for key, value in pairs(t) do
		if type(value) == "table" then
			copy[key] = TableUtils.deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

function TableUtils.shuffle(t)
    local j, temp
	for i = #t, 1, -1 do
		j = math.random(i)
		temp = t[i]
		t[i] = t[j]
		t[j] = temp
	end
end

return TableUtils