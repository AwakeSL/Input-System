--!strict

-- debug output for input actions
local DebugOutput = {}
DebugOutput.__index = DebugOutput

function DebugOutput.new()
	local self = setmetatable({}, DebugOutput)
	return self
end

function DebugOutput:trigger(connectionName: string, detectorType: string, additionalData: { [any]: any })
	local dataString = ""
	if next(additionalData) ~= nil then
		local parts = {}
		for key, value in pairs(additionalData) do
			table.insert(parts, string.format("%s = %s", tostring(key), tostring(value)))
		end
		dataString = string.format(" ➔ { %s }", table.concat(parts, ", "))
	end

	print(string.format(
		"[INPUT DEBUG] Action: %-5s | Detector: %-12s%s",
		"'" .. connectionName .. "'",
		"[" .. detectorType .. "]",
		dataString
		))
end

return DebugOutput