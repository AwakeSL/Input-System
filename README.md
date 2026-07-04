# SimpleInputSystem

A modular input handling framework for Roblox, built on native `InputActionService`. It separates raw key presses from game actions using **Contexts** (e.g. Combat, Menu) and input behavior **Detectors** (e.g. DoubleTap, HeldFor).

Created by AwakeSL.

Two ways to use it:

1. **`SimpleInputManager`** — high-level wrapper with an integrated output stream, for quick binding.
2. **`InputManager` engine** — the core `InputActionService` wrapper, for when you want to run your own output pipeline instead of the default one.

---

## Contexts

Contexts map directly to Roblox's `InputContext` (`Priority`, `Sink`, etc. via `InputActionService`) — refer to Roblox's docs if you're unfamiliar with those. Define your contexts and their defaults in one place to avoid conflicts:

```lua
local Contexts = {
    Combat = "Combat",
    Menu = "Menu",
    Movement = "Movement",
}

Contexts.Defaults = {
    [Contexts.Combat]   = { Priority = 0,  Sink = false },
    [Contexts.Menu]     = { Priority = 10, Sink = true }, -- e.g. closing a menu shouldn't also trigger a world interaction
    [Contexts.Movement] = { Priority = 0,  Sink = false },
}

return Contexts
```

---

## Quick Start (`SimpleInputManager`)

### Binding inputs

```lua
local SimpleInputManager = require(path.to.SimpleInputManager)
local Contexts = SimpleInputManager.Contexts
local Detectors = SimpleInputManager.Detectors

SimpleInputManager.enableContext(Contexts.Combat)

local attackBinds = SimpleInputManager.bind(Contexts.Combat, "MeleeAttack", Enum.UserInputType.MouseButton1, {
    [Detectors.Pressed] = function()
        print("Basic attack executed!")
    end,

    [Detectors.DoubleTap] = {
        window = 0.25,
        on = function()
            print("Heavy spin attack executed via Double Tap!")
        end
    }
})
```

### Checking held state

```lua
if SimpleInputManager.isHeld("MeleeAttack") then
    print("Player is holding down the attack button!")
end
```

---

## Detectors

| Detector | Behavior | Config |
| --- | --- | --- |
| `Pressed` | Fires on key down. | — |
| `Released` | Fires on key up. | — |
| `Tap` | Fires on quick press + release. | `window` (default 0.3s) |
| `SingleTap` | Fires only if a double-tap didn't occur. | `window` (default 0.3s) |
| `DoubleTap` | Fires on two rapid presses. | `window` (default 0.3s) |
| `Held` | Fires every frame while held. | — |
| `HeldFor` | Fires once after a minimum hold duration. | `time` (default 0.5s) |

```lua
SimpleInputManager.bind(Contexts.Movement, "ChargeSuper", Enum.KeyCode.E, {
    [SimpleInputManager.Detectors.HeldFor] = {
        time = 1.5,
        on = function()
            print("Super charge complete!")
        end
    }
})
```

---

## `SimpleInputManager` API

- **`enableContext(contextName: string)`** — enables a context; its bound actions start evaluating.
- **`disableContext(contextName: string)`** — disables a context; its bound actions are ignored.
- **`setContextPriority(contextName: string, priority: number)`** — sets evaluation order (higher = evaluated first).
- **`setContextSink(contextName: string, sink: boolean)`** — sets whether the context blocks input from lower-priority contexts.
- **`bind(contextName: string, connectionName: string, keyCode: Enum.KeyCode | Enum.UserInputType, detectors: table)`** — binds a key to an action name with detector callbacks/config. Returns a table of disconnect functions.
- **`isHeld(connectionName: string): boolean`** — whether the given action's key is currently held.

---

## `InputManager` Engine API

The lower-level wrapper around Roblox's `InputContext` / `InputAction` / `InputBinding` objects. Use this if you want to replace the default output layer.

- **`InputManager.new(output: table)`** — creates a new engine instance. `output` must implement `:trigger(connectionName, detectorType, additionalData)`.
- **`:enableContext(contextName: string)`**
- **`:disableContext(contextName: string)`**
- **`:getContext(contextName: string): InputContext?`** — looks up the existing context instance, or `nil`.
- **`:addContext(contextName: string, existingInstance: Instance?)`** — finds or creates a context instance.
- **`:setContextPriority(contextName: string, priority: number)`**
- **`:setContextSink(contextName: string, sink: boolean)`**
- **`:bind(contextName: string, connectionName: string, keyCode: Enum.KeyCode, actionType: Enum.InputActionType?, detectorSettings: table?): InputBinding`**
- **`:unbind(contextName: string | Instance, connectionName: string?, keyCode: Enum.KeyCode?, actionType: Enum.InputActionType?)`** — removes a binding. Pass an `InputBinding` directly to destroy it immediately.
- **`:clearAction(contextName: string, connectionName: string)`** — destroys an action and all its bindings.
- **`:update(dt: number)`** — called on `RunService.Heartbeat`; feeds delta time to continuous detectors (`Held`, `HeldFor`).
- **`:Destroy()`** — disconnects updates and clears context references.

---

## Custom Output Handlers

`InputManager` can be used standalone, without `SimpleInputManager`, by supplying your own output object. It only needs to implement `:trigger(connectionName, detectorType, additionalData)`:

```lua
-- MyCustomOutput.lua
local MyCustomOutput = {}
MyCustomOutput.__index = MyCustomOutput

function MyCustomOutput.new()
    return setmetatable({
        CustomEvent = Instance.new("BindableEvent")
    }, MyCustomOutput)
end

function MyCustomOutput:trigger(connectionName, detectorType, additionalData)
    self.CustomEvent:Fire(connectionName, detectorType, additionalData)
end

return MyCustomOutput
```

```lua
local InputManager = require(path.to.InputSystem.InputManager)
local MyCustomOutput = require(path.to.MyCustomOutput)

local myOutput = MyCustomOutput.new()
local coreEngine = InputManager.new(myOutput)

coreEngine:enableContext("Combat")
coreEngine:bind(
    "Combat",
    "DodgeRoll",
    Enum.KeyCode.LeftShift,
    Enum.InputActionType.Bool,
    {
        [InputManager.Detectors.DoubleTap] = { window = 0.2 }
    }
)

myOutput.CustomEvent.Event:Connect(function(action, detector)
    if action == "DodgeRoll" and detector == "DoubleTap" then
        print("Player executed a double-tap dodge roll via custom processing!")
    end
end)
```