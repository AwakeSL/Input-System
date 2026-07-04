# Simple Input System

`SimpleInputSystem` is a modular input handling framework for Roblox built directly on top of native **`InputActionService`** instances. It decouples raw key presses from game actions by introducing custom input behavior **Detectors** (e.g., DoubleTap, HeldFor).

Created by: AwakeSL (AwakeSL on Discord) boiii

The library provides two ways to use it:

1. **`SimpleInputManager`**: A high-level wrapper designed for quick, hassle-free binding with an integrated output stream.
2. **`InputManager` Engine**: The core underlying `InputActionService` wrapper, allowing you to ditch the default output setup and run completely custom event pipelines.

---

## Quick Start (Using SimpleInputManager)

The `SimpleInputManager` wrapper handles instantiating managers and exposes an easy-to-use API for standard code structures.

### 1. Context Configuration (`InputContexts.lua`)

Define your action states and their relative priorities to avoid conflicts (like opening an inventory screen while attacking).

```lua
local Contexts = {
    Combat = "Combat",
    Menu = "Menu",
    Movement = "Movement",
}

Contexts.Defaults = {
    [Contexts.Combat]   = { Priority = 0,  Sink = false },
    [Contexts.Menu]     = { Priority = 10, Sink = true }, -- Sinks inputs from lower-priority contexts
    [Contexts.Movement] = { Priority = 0,  Sink = false },
}

return Contexts

```

### 2. Binding Inputs

Use `SimpleInputManager.bind` to bind keys to connections and map specific behaviors (Detectors).

```lua
local SimpleInputManager = require(path.to.SimpleInputManager)
local Contexts = SimpleInputManager.Contexts
local Detectors = SimpleInputManager.Detectors

-- Ensure your context is enabled!
SimpleInputManager.enableContext(Contexts.Combat)

-- Bind Left-Click (Button1) to an attack action
local attackBinds = SimpleInputManager.bind(Contexts.Combat, "MeleeAttack", Enum.UserInputType.MouseButton1, {
    -- Basic Pressed detector
    [Detectors.Pressed] = function()
        print("Basic attack executed!")
    end,
    
    -- Passing specific configuration settings to a detector
    [Detectors.DoubleTap] = {
        window = 0.25, -- Customize double tap timing window
        on = function()
            print("Heavy spin attack executed via Double Tap!")
        end
    }
})

```

### 3. Checking Held States

```lua
-- Dynamically query if an action connection is currently held down
if SimpleInputManager.isHeld("MeleeAttack") then
    print("Player is holding down the attack button!")
end

```

---

## Out-of-the-Box Detectors

You can utilize the following built-in detectors inside your bind configuration tables:

| Detector | Behavior | Custom Config Options |
| --- | --- | --- |
| `Detectors.Pressed` | Fires instantly when key is pressed. | None |
| `Detectors.Released` | Fires instantly when key is released. | None |
| `Detectors.Tap` | Fires if pressed and released quickly. | `window` (default: 0.3s) |
| `Detectors.SingleTap` | Fires *only* if a double-tap didn't occur. | `window` (default: 0.3s) |
| `Detectors.DoubleTap` | Fires when key is pressed twice rapidly. | `window` (default: 0.3s) |
| `Detectors.Held` | Continuous ticking fire every frame while held. | None |
| `Detectors.HeldFor` | Fires once *after* being held for a minimum duration. | `time` (default: 0.5s) |

An example using `HeldFor`:

```lua
SimpleInputManager.bind(Contexts.Movement, "ChargeSuper", Enum.KeyCode.E, {
    [SimpleInputManager.Detectors.HeldFor] = {
        time = 1.5, -- Must hold for 1.5 seconds
        on = function()
            print("Super charge complete!")
        end
    }
})

```

---

## Skipping Simple Input: Custom Engine & Custom Outputs

Because the core `InputManager` framework is essentially a clean wrapper designed to manipulate Roblox's internal `InputAction`, `InputContext`, and `InputBinding` instances, you can bypass `SimpleInputManager` entirely.

This lets you use the engine directly while **swapping out the default OutputManager for your own custom output handling pipeline** (e.g., custom Signal modules, UI state routers, or direct network replicators).

### Writing a Custom Output Handler

Your custom output object must implement a `.trigger(self, connectionName, detectorType, additionalData)` method, which the `InputManager` wrapper hooks up and fires into directly from the engine's `StateChanged`, `Pressed`, and `Released` listeners:

```lua
-- MyCustomOutput.lua
local MyCustomOutput = {}
MyCustomOutput.__index = MyCustomOutput

function MyCustomOutput.new()
    return setmetatable({
        CustomEvent = Instance.new("BindableEvent") -- Or use your favorite custom Signal class
    }, MyCustomOutput)
end

-- The core InputManager requires this specific interface method to feed data out
function MyCustomOutput:trigger(connectionName, detectorType, additionalData)
    print(("Custom Output Intercepted! Action: %s | Mode: %s"):format(connectionName, detectorType))
    
    -- Do whatever you want here: Fire a custom signal, process state machine, route to UI, etc.
    self.CustomEvent:Fire(connectionName, detectorType, additionalData)
end

return MyCustomOutput

```

### Initializing the Core Engine with Your Custom Output

```lua
local InputManager = require(path.to.InputSystem.InputManager)
local MyCustomOutput = require(path.to.MyCustomOutput)

-- 1. Instantiate your custom handler
local myOutput = MyCustomOutput.new()

-- 2. Inject your custom output directly into the core InputManager engine
local coreEngine = InputManager.new(myOutput)

-- 3. Configure contexts and actions manually
coreEngine:enableContext("Combat")
coreEngine:bind(
    "Combat", 
    "DodgeRoll", 
    Enum.KeyCode.LeftShift, 
    Enum.InputActionType.Bool, -- Directly configuring underlying Roblox InputAction properties
    {
        [InputManager.Detectors.DoubleTap] = { window = 0.2 }
    }
)

-- Your core engine runs seamlessly, completely bypassed and independent of OutputManager!
myOutput.CustomEvent.Event:Connect(function(action, detector)
    if action == "DodgeRoll" and detector == "DoubleTap" then
        print("Player executed a double-tap dodge roll via custom processing!")
    end
end)

```