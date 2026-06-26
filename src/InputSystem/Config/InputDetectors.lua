local Detectors = {}

Detectors.Pressed = "Pressed"
Detectors.Released = "Released"
Detectors.DoubleTap = "DoubleTap"
Detectors.Hold = "Hold"

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
	[Detectors.DoubleTap] = {
		onPressed = function(fire, state)
			local now = tick()
			if state.lastPress and (now - state.lastPress) < 0.3 then
				fire()
				state.lastPress = nil
			else
				state.lastPress = now
			end
		end
	},
	[Detectors.Hold] = {
		onPressed = function(fire, state)
			state.holding = true
			state.elapsed = 0
		end,
		onReleased = function(fire, state)
			state.holding = false
		end,
		onUpdate = function(fire, state, dt)
			if state.holding then
				state.elapsed = (state.elapsed or 0) + dt
				if state.elapsed >= 0.5 then
					fire()
					state.holding = false
				end
			end
		end
	},
}

return Detectors