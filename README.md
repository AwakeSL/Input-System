# SimpleInputSystem 

`SimpleInputSystem` is a modular input handling framework for Roblox built directly on top of native **`InputActionService`** engine instances. It decouples raw key presses from game actions by introducing **Contexts** (e.g., Combat, Menus) and custom input behavior **Detectors** (e.g., DoubleTap, HeldFor).

Created by: AwakeSL (AwakeSL on Discord) boiii

The library provides two ways to use it:

1. **`SimpleInputManager`**: A high-level wrapper designed for quick, hassle-free binding with an integrated output stream.
2. **`InputManager` Engine**: The core underlying `InputActionService` wrapper, allowing you to ditch the default output setup and run completely custom event pipelines.

---

##  Quick Core Concepts Reference

If you aren't familiar with contextual input architectures, here is what the settings mean:

* **Context:** A state or mode your game is currently in (e.g., `Menu`, `Combat`, `Driving`). Actions inside a context only look for input when that context is explicitly **enabled**.
* **Priority:** A number that dictates which Context takes precedence when multiple contexts are active at the same time and bound to the exact same keys. **Higher numbers evaluate first**.
* **Sink:** A boolean flag (`true`/`false`). When a context captures an input and has `Sink = true`, it **consumes** that input completely. Lower-priority contexts won't receive it at all. For example, pressing `E` to close an inventory menu will "sink" the input so your character doesn't accidentally trigger a world interaction simultaneously.

---

##  Quick Start (Using SimpleInputManager)

The `SimpleInputManager` wrapper handles instantiating managers and exposes an easy-to-use API for standard code structures.

### 1. Context Configuration (`InputContexts.lua`)

Define your action states and their relative properties to avoid conflicts.

```lua
local Contexts = {
    Combat = "Combat",
    Menu = "Menu",
    Movement = "Movement",
}

Contexts.Defaults = {
    [Contexts.Combat]   = { Priority = 0,  Sink = false },
    [Contexts.Menu]     = { Priority = 10, Sink = true }, -- Evaluates first; blocks lower priorities when active
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

## Out-of-the-Box Detectors Reference

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

## SimpleInputManager API Reference

This is the high-level singleton-style wrapper used for quick bindings with an integrated `OutputManager`.

* **`SimpleInputManager.enableContext(contextName: string)`**
Enables an input context. Inputs bound under this context will begin evaluating.
* **`SimpleInputManager.disableContext(contextName: string)`**
Disables an input context. Inputs bound under this context are ignored.
* **`SimpleInputManager.setContextPriority(contextName: string, priority: number)`**
Changes the evaluation order weight of a context. Higher numbers evaluate first.
* **`SimpleInputManager.setContextSink(contextName: string, sink: boolean)`**
Sets whether an active context blocks inputs from being seen by lower-priority active contexts.
* **`SimpleInputManager.bind(contextName: string, connectionName: string, keyCode: Enum.KeyCode | Enum.UserInputType, detectors: table)`**
Binds a physical key to an abstract action name, mapping detector types to callback functions or configuration tables. Returns a dictionary of disconnect functions for cleanup.
* **`SimpleInputManager.isHeld(connectionName: string)`**
Queries the integrated output state to check if a specific action key is currently being physically held down. Returns a `boolean`.

---

## ⚙️ Core InputManager Engine API Reference

This is the underlying wrapper managing Roblox `InputActionService` (`InputContext`, `InputAction`, `InputBinding`) objects. Use this when bypassing the simple wrapper to run a **custom output layer**.

* **`InputManager.new(output: table)`**
Instantiates a new instance of the input manager engine. Expects an output listener object containing a `.trigger` method.
* **`InputManager:enableContext(contextName: string)`**
Enables the specified context instance internally and adds it to the active update cycle.
* **`InputManager:disableContext(contextName: string)`**
Disables the specified context and removes it from active frame tracking.
* **`InputManager:getContext(contextName: string)`**
Looks up and returns the underlying `InputContext` instance from the game hierarchy if it exists. Returns `nil` if not found.
* **`InputManager:addContext(contextName: string, existingInstance: Instance?)`**
Finds or explicitly generates a brand new `InputContext` object in the system tree.
* **`InputManager:setContextPriority(contextName: string, priority: number)`**
Updates the internal `Priority` integer directly on the active context.
* **`InputManager:setContextSink(contextName: string, sink: boolean)`**
Updates the internal `Sink` boolean directly on the active context.
* **`InputManager:bind(contextName: string, connectionName: string, keyCode: Enum.KeyCode, actionType: Enum.InputActionType?, detectorSettings: table?)`**
Generates a new internal `InputAction` and attaches a new physical `InputBinding` object to it. Registers the action configuration data directly into the core engine update pipeline. Returns the `InputBinding` instance.
* **`InputManager:unbind(contextName: string | Instance, connectionName: string?, keyCode: Enum.KeyCode?, actionType: Enum.InputActionType?)`**
Removes a specific physical key binding. If passed an `InputBinding` instance directly as the first argument, it destroys that specific binding immediately.
* **`InputManager:clearAction(contextName: string, connectionName: string)`**
Completely clears out an entire abstract action and destroys its native `InputAction` instance along with all associated bindings.
* **`InputManager:update(dt: number)`**
Fires every frame via `RunService.Heartbeat`. Loops through all active contexts to feed delta-time tracking ticks straight into specialized continuous detectors (like `Held` and `HeldFor`).
* **`InputManager:Destroy()`**
Disconnects internal frame updates and flushes out all active memory context references cleanly.

---

## ⏭️ Skipping Simple Input: Custom Engine & Custom Outputs

Because the core `InputManager` framework is essentially a clean wrapper designed to manipulate Roblox's internal `InputAction`, `InputContext`, and `InputBinding` instances via **`InputActionService`**, you can bypass `SimpleInputManager` entirely.

This lets you use the engine directly while **swapping out the default OutputManager for your own custom output handling pipeline** (e.g., custom Signal modules, UI state routers, or direct network replicators).

### Writing a Custom Output Handler

Your custom output object must implement a `.trigger(self, connectionName, detectorType, additionalData)` method, which the `InputManager` wrapper hooks up and fires into directly from the engine's internal listeners:

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