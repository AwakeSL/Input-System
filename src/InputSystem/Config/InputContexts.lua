local Contexts = {
	Combat = "Combat",
	Menu = "Menu",
	Vehicle = "Vehicle",
	Movement = "Movement",
	-- Add more as needed
}

export type Context = typeof(Contexts[string])

return Contexts