local InputManager = require(script.Parent.InputSystem.InputManager)
local OutputManager = require(script.Parent.OutputSystem.OutputManager)
local Detectors = InputManager.Detectors

local output = OutputManager.new()
local instance = InputManager.new(output)

local InputService = {}

function InputService.enableContext(contextName)
	instance:enableContext(contextName)
end

function InputService.disableContext(contextName)
	instance:disableContext(contextName)
end

function InputService.setContextPriority(contextName, priority)
	instance:setContextPriority(contextName, priority)
end

function InputService.setContextSink(contextName, sink)
	instance:setContextSink(contextName, sink)
end

function InputService.bind(contextName, connectionName, keyCode, detectors)
	detectors = detectors or {}
	
	local detectorSettings = {}
	local connections = {}

	for detector, value in pairs(detectors) do
		if type(value) == "function" then
			connections[detector] = output:on(connectionName, detector, value)

		elseif type(value) == "table" then
			local settings = table.clone(value)
			local fn = settings.on
			settings.on = nil

			detectorSettings[detector] = settings

			if fn then
				connections[detector] = output:on(connectionName, detector, fn)
			end
		else
			error(("Invalid value for detector '%s'"):format(tostring(detector)))
		end
	end

	instance:bind(contextName, connectionName, keyCode, detectorSettings)

	return connections
end

function InputService.isHeld(connectionName)
	return output:isHeld(connectionName)
end

InputService.Contexts = InputManager.Contexts
InputService.Detectors = InputManager.Detectors

return InputService