local Detectors = {}

Detectors.Pressed = "Pressed"
Detectors.Released = "Released"
Detectors.Tap = "Tap"
Detectors.SingleTap = "DoubleTap"
Detectors.DoubleTap = "DoubleTap"
Detectors.Held = "Held"

export type Bind = typeof(Detectors[string])

Detectors.detectors = {
	[Detectors.Pressed] = {
		onPressed = function(fire, state)
			fire()
		end
	},
	[Detectors.Released] = {
		onReleased = function(fire, state)
			fire()
		end
	},
	[Detectors.Tap] = {
		onPressed = function(fire, state)
			state.pressedAt = tick()
		end,
		onReleased = function(fire, state, settings)
			if state.pressedAt and (tick() - state.pressedAt) < (settings.window or 0.3) then
				fire()
			end
			state.pressedAt = nil
		end
	},
	[Detectors.SingleTap] = {
		onPressed = function(fire, state, settings)
			local now = tick()
			state.tapCount = (state.tapCount or 0) + 1
			local currentTap = state.tapCount

			task.delay(settings.window or 0.3, function()
				if state.tapCount == currentTap then
					state.tapCount = 0
					fire()
				end
			end)
		end
	},
	[Detectors.DoubleTap] = {
		onPressed = function(fire, state, settings)
			local now = tick()
			if state.lastPress and (now - state.lastPress) < (settings.window or 0.3) then
				fire()
				state.lastPress = nil
			else
				state.lastPress = now
			end
		end
	},
	[Detectors.Held] = {
		onPressed = function(fire, state)
			state.holding = true
		end,
		onReleased = function(fire, state)
			state.holding = false
		end,
		onUpdate = function(fire, state, dt)
			if state.holding then
					fire()
			end
		end
	},
}

return Detectors