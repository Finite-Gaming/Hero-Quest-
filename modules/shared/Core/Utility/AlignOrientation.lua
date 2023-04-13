---
-- @classmod AlignOrientation
-- @author

local AlignOrientation = {}

function AlignOrientation.new(att0, att1)
    local obj = Instance.new("AlignOrientation")

    obj.Enabled = false
    if not att1 then
        obj.Mode = Enum.OrientationAlignmentMode.OneAttachment
    end
    obj.Attachment0 = att0
    obj.Attachment1 = att1

    return obj
end

return AlignOrientation