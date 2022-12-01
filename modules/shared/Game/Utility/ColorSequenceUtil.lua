local ColorSequenceUtil = {}

-- Adapted from https://developer.roblox.com/en-us/api-reference/datatype/ColorSequence
function ColorSequenceUtil:ValueAt(colorSequence: ColorSequence, index: number): Color3
	index = math.clamp(index, 0, 1)
	
	-- If we are at 0 or 1, return the first or last value respectively
	if index == 0 then return colorSequence.Keypoints[1].Value end
	if index == 1 then return colorSequence.Keypoints[#colorSequence.Keypoints].Value end
	-- Step through each sequential pair of keypoints and see if alpha
	-- lies between the points' index values.
	for i = 1, #colorSequence.Keypoints - 1 do
		local this = colorSequence.Keypoints[i]
		local next = colorSequence.Keypoints[i + 1]
		if index >= this.Time and index < next.Time then
			-- Calculate how far alpha lies between the points
			local alpha = (index - this.Time) / (next.Time - this.Time)
			-- Evaluate the real value between the points using alpha
			return Color3.new(
				(next.Value.R - this.Value.R) * alpha + this.Value.R,
				(next.Value.G - this.Value.G) * alpha + this.Value.G,
				(next.Value.B - this.Value.B) * alpha + this.Value.B
			)
		end
	end
	return Color3.new()
end

return ColorSequenceUtil