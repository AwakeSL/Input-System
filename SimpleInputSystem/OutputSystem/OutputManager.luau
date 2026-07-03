local OutputManager = {}
OutputManager.__index = OutputManager

local Detectors = require(script.Parent.Parent.InputSystem.Config.InputDetectors)

function OutputManager.new()
	local self = setmetatable({}, OutputManager)
	self._listeners = {} -- [connectionName] = { [detectorType] = { callbacks } }
	self._heldStates = {} -- [connectionName] = boolean
	return self
end

function OutputManager:on(connectionName: string, detectorType: string, callback: (additionalData: {[any]:any}) -> ())
	if not self._listeners[connectionName] then
		self._listeners[connectionName] = {}
	end
	if not self._listeners[connectionName][detectorType] then
		self._listeners[connectionName][detectorType] = {}
	end
	table.insert(self._listeners[connectionName][detectorType], callback)
	return function()
		local list = self._listeners[connectionName][detectorType]
		if not list then return end
		local index = table.find(list, callback)
		if index then
			table.remove(list, index)
		end
	end
end

function OutputManager:trigger(connectionName: string, detectorType: string, additionalData: {[any]:any})
	if detectorType == Detectors.Pressed then
		self._heldStates[connectionName] = true
	elseif detectorType == Detectors.Released then
		self._heldStates[connectionName] = false
	end

	local action = self._listeners[connectionName]
	if not action then return end
	local callbacks = action[detectorType]
	if not callbacks then return end
	for _, callback in ipairs(callbacks) do
		callback(additionalData)
	end
end

function OutputManager:isHeld(connectionName: string)
	return self._heldStates[connectionName] == true
end

return OutputManager