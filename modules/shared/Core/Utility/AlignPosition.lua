---
-- @classmod AlignPosition
-- @author

local AlignPosition = {}

function AlignPosition.new(att0, att1)
    local obj = Instance.new("AlignPosition")

    obj.Enabled = false
    if not att1 then
        obj.Mode = Enum.PositionAlignmentMode.OneAttachment
    end
    obj.Attachment0 = att0
    obj.Attachment1 = att1

    return obj
end

return AlignPosition