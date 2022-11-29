--- Various lerp functions not found in vanilla rlua
-- @classmod Lerp
-- @author frick

local Lerp = {}

function Lerp.lerp(from, to, alpha)
    return  (1 - alpha) * from + alpha * to
end

function Lerp.slerp(angleFrom, angleTo, alpha)
    local xOffset = Lerp.lerp(math.sin(angleFrom), math.sin(angleTo), alpha)
    local yOffset = Lerp.lerp(math.cos(angleFrom), math.cos(angleTo), alpha)

    return math.atan2(xOffset, yOffset)
end

function Lerp.cframeSlerp()

end

return Lerp