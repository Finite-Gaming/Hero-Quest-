--- Used to validate/sanitize various datatypes
-- @classmod SanitizeUtils
-- @author frick

local SanitizeUtils = {}

function SanitizeUtils.validate(num)
    return type(num) == "number" and num == num
end

function SanitizeUtils.sanitizeCFrame(cframe)
    for _, component in ipairs({cframe:GetComponents()}) do
        if not SanitizeUtils.validate(component) then
            return false
        end
    end

    return true
end

return SanitizeUtils