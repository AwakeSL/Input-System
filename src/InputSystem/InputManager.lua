local RunService = game:GetService("RunService")

local InputManager = {}
InputManager.__index = InputManager

local Detectors = require(script.Parent.Config.InputDetectors)
local ContextsFolder = game:GetService("ReplicatedStorage"):WaitForChild("InputSystem"):WaitForChild("Contexts")

local AllowedContexts = require(script.Parent.Config.InputContexts)
InputManager.InputContexts = AllowedContexts

function InputManager.new(output)
	local self = setmetatable({}, InputManager)
	self.output = output

	self.contexts = {} -- Key: ContextInstance, Value: { [ActionName] = {connectionName, detectorStates} }
	self.activeContext = nil

	for _, contextName in pairs(AllowedContexts) do
		self:addContext(contextName)
	end

	self._updateConnection = RunService.Heartbeat:Connect(function(dt)
		self:update(dt)
	end)

	return self
end

function InputManager:addContext(contextName, existingInstance)
	local context = existingInstance or self.contexts[contextName]
	if context then return context end

	local existingFolder = ContextsFolder:FindFirstChild(contextName)
	context = existingFolder or Instance.new("InputContext")

	if not existingFolder then
		context.Name = contextName
		context.Parent = ContextsFolder
	end

	if not self.contexts[context] then
		self.contexts[context] = {}
	end

	return context
end

function InputManager:setContext(contextName)
	for context, _ in pairs(self.contexts) do
		context.Enabled = false
	end

	local targetContext
	for context, _ in pairs(self.contexts) do
		if context.Name == contextName then
			targetContext = context
			break
		end
	end

	assert(targetContext, "InputManager: context not found: " .. tostring(contextName))

	targetContext.Enabled = true
	self.activeContext = targetContext 
end

-- Context name, ConnectionName, KeyCode, ActionType
function InputManager:bind(contextName, connectionName, keyCode, actionType)
	local context = self:addContext(contextName)
	assert(context, "InputManager: context not found: " .. tostring(contextName))

	local action = context:FindFirstChild(connectionName)
	if not action then
		action = Instance.new("InputAction")
		action.Name = connectionName
		action.Type = actionType or Enum.InputActionType.Bool
		action.Parent = context
		self:_registerAction(action, connectionName, context)
	end

	local binding = Instance.new("InputBinding")
	binding.KeyCode = keyCode
	binding.Parent = action
end

function InputManager:_registerAction(action, connectionName, context)
	local detectorStates = {}
	for detectorType, _ in pairs(Detectors.detectors) do
		detectorStates[detectorType] = {}
	end

	local actionData = {
		connectionName = connectionName,
		detectorStates = detectorStates
	}

	self.contexts[context][action.Name] = actionData

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
			end, actionData.detectorStates[detectorType])
		end
	end
end

function InputManager:update(dt)
	if not self.activeContext then return end

	local activeActions = self.contexts[self.activeContext]
	if not activeActions then return end

	for _, actionData in pairs(activeActions) do
		for detectorType, detector in pairs(Detectors.detectors) do
			if detector.onUpdate then
				detector.onUpdate(function(additionalData)
					self.output:trigger(actionData.connectionName, detectorType, additionalData or {})
				end, actionData.detectorStates[detectorType], dt)
			end
		end
	end
end

function InputManager:Destroy()
	if self._updateConnection then
		self._updateConnection:Disconnect()
		self._updateConnection = nil
	end
	self.contexts = nil
	self.activeContext = nil
end

return InputManager