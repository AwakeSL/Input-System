local Contexts = {
	Combat = "Combat",
	Menu = "Menu",
	Vehicle = "Vehicle",
	Movement = "Movement",
	-- Add more as needed
}
export type Context = typeof(Contexts[string])

Contexts.Defaults = {
	[Contexts.Combat]   = { Priority = 0,  Sink = false },
	[Contexts.Menu]     = { Priority = 10, Sink = true },
	[Contexts.Vehicle]  = { Priority = 0,  Sink = false },
	[Contexts.Movement] = { Priority = 0,  Sink = false },
}

return Contexts