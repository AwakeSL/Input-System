local RunService = game:GetService("RunService")

local InputManager = {}
InputManager.__index = InputManager

local Detectors        = require(script.Parent.Config.InputDetectors)
local Contexts         = require(script.Parent.Config.InputContexts)
InputManager.Contexts  = Contexts
InputManager.Detectors = Detectors
local ContextsFolder   = script.Parent.Contexts

function InputManager.new(output)
	local self = setmetatable({}, InputManager)
	self.output = output

	self._contexts = {}
	self._activeContexts = {} -- Key: contextInstance, Value: true
	
	for _, contextName in pairs(Contexts) do
		if typeof(contextName) == "string" then 
			local context = self:addContext(contextName)
			context.Enabled = false

			local defaults = Contexts.Defaults[contextName]
			if defaults then
				context.Priority = defaults.Priority or 0
				context.Sink = defaults.Sink or false
			end
		end
	end

	self._updateConnection = RunService.Heartbeat:Connect(function(dt)
		self:update(dt)
	end)

	return self
end

function InputManager:enableContext(contextName)
	local context = self:getContext(contextName)
	assert(context, "InputManager: context not found: " .. tostring(contextName))

	context.Enabled = true
	self._activeContexts[context] = true
end

function InputManager:disableContext(contextName)
	local context = self:getContext(contextName)
	assert(context, "InputManager: context not found: " .. tostring(contextName))

	context.Enabled = false
	self._activeContexts[context] = nil
end

function InputManager:getContext(contextName)
	local existingFolder = ContextsFolder:FindFirstChild(contextName)
	if existingFolder and self._contexts[existingFolder] then
		return existingFolder
	end
	return nil
end

function InputManager:addContext(contextName, existingInstance)
	local context = existingInstance or self:getContext(contextName)
	if context then
		if not self._contexts[context] then
			self._contexts[context] = {}
		end
		return context
	end

	context = Instance.new("InputContext")
	context.Name = contextName
	context.Parent = ContextsFolder
	self._contexts[context] = {}

	return context
end

function InputManager:setContextPriority(contextName, priority)
	local context = self:getContext(contextName)
	assert(context, "InputManager: context not found: " .. tostring(contextName))
	assert(typeof(priority) == "number", "InputManager: priority must be a number")

	context.Priority = priority
end

function InputManager:setContextSink(contextName, sink)
	local context = self:getContext(contextName)
	assert(context, "InputManager: context not found: " .. tostring(contextName))
	assert(typeof(sink) == "boolean", "InputManager: sink must be a boolean")

	context.Sink = sink
end

function InputManager:bind(contextName, connectionName, keyCode, actionType, detectorSettings)
	if typeof(actionType) == "table" then
		local temp = detectorSettings
		detectorSettings = actionType
		actionType = temp
	end

	local context = self:addContext(contextName)
	assert(context, "InputManager: context not found: " .. tostring(contextName))

	local action = context:FindFirstChild(connectionName)
	if not action then
		action = Instance.new("InputAction")
		action.Name = connectionName
		action.Type = actionType or Enum.InputActionType.Bool
		action.Parent = context

		self:_registerAction(
			action,
			connectionName,
			context,
			detectorSettings or {}
		)
	end

	local binding = Instance.new("InputBinding")
	binding.KeyCode = keyCode
	binding.Parent = action

	return binding
end
function InputManager:clearAction(contextName, connectionName)
	local context = self:getContext(contextName)
	local action = context and context:FindFirstChild(connectionName)
	if action then
		if self._contexts[context] then
			self._contexts[context][connectionName] = nil
		end
		action:Destroy()
	end
end

-- ContextName (or a bind reference), ConnectionName, KeyCode, ActionType
function InputManager:unbind(contextName, connectionName, keyCode, actionType)
	if typeof(contextName) == "Instance" and contextName:IsA("InputBinding") then
		local binding = contextName
		local action = binding.Parent
		binding:Destroy()
		if action and action:IsA("InputAction") and #action:GetChildren() == 0 then
			local context = action.Parent
			if context and self._contexts[context] then
				self._contexts[context][action.Name] = nil
			end
			action:Destroy()
		end
		return
	end

	local context = self:getContext(contextName)
	if not context then return end

	local action = context:FindFirstChild(connectionName)
	if not action then return end 

	if actionType and action.Type ~= actionType then
		return 
	end

	if keyCode == nil then
		self:clearAction(context.Name, connectionName)
		return
	end

	for _, binding in ipairs(action:GetChildren()) do
		if binding:IsA("InputBinding") and binding.KeyCode == keyCode then
			binding:Destroy()
			break
		end
	end

	if #action:GetChildren() == 0 then
		self._contexts[context][connectionName] = nil
		action:Destroy()
	end
end

function InputManager:_registerAction(action, connectionName, context, detectorSettings)
	local detectorStates = {}

	for detectorType in pairs(Detectors.detectors) do
		detectorStates[detectorType] = {}
	end

	local actionData = {
		connectionName = connectionName,
		detectorStates = detectorStates,
		detectorSettings = detectorSettings or {},
	}

	self._contexts[context][action.Name] = actionData
	
	action.Pressed:Connect(function()
		self:_onTrigger(actionData, "onPressed")
	end)

	action.Released:Connect(function()
		self:_onTrigger(actionData, "onReleased")
	end)
	action.StateChanged:Connect(function(value)
		self:_onTrigger(actionData, "onTriggered", value) 
	end)
end

function InputManager:_onTrigger(actionData, engineCallback)
	for detectorType, detector in pairs(Detectors.detectors) do
		if detector[engineCallback] then
			detector[engineCallback](function(additionalData)
				self.output:trigger(actionData.connectionName, detectorType, additionalData or {})
			end, actionData.detectorStates[detectorType], actionData.detectorSettings[detectorType] or {})
		end
	end
end

function InputManager:update(dt)
	for context, _ in pairs(self._activeContexts) do
		local activeActions = self._contexts[context]
		if activeActions then
			for _, actionData in pairs(activeActions) do
				for detectorType, detector in pairs(Detectors.detectors) do
					if detector.onUpdate then
						detector.onUpdate(function(additionalData)
							self.output:trigger(actionData.connectionName, detectorType, additionalData or {})
						end, actionData.detectorStates[detectorType], dt, actionData.detectorSettings[detectorType] or {})
					end
				end
			end
		end
	end
end

function InputManager:Destroy()
	if self._updateConnection then
		self._updateConnection:Disconnect()
		self._updateConnection = nil
	end
	self._contexts = nil
	self._activeContexts = nil
end

return InputManager