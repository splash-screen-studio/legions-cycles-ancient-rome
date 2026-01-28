--!strict
--[[
    Components Module - Entry point for OOP composition system
    Provides utilities for mixing components into classes
    Based on BRicey Composition Over Inheritance tutorial

    Usage Example:
    ```lua
    local Components = require(ReplicatedStorage.Components)

    -- Create a Guard class with multiple components
    local Guard = {}
    Guard.__index = Guard

    function Guard.new(config)
        local self = setmetatable({}, Guard)

        -- Initialize component data
        Components.Movable.init(self, { speed = 12 })
        Components.Damageable.init(self, { health = 100 })
        Components.Attackable.init(self, { damage = 15 })

        -- Mix in component methods
        Components.compose(self, {
            Components.Movable,
            Components.Damageable,
            Components.Attackable,
        })

        return self
    end
    ```
]]

local Movable = require(script.Movable)
local Damageable = require(script.Damageable)
local Attackable = require(script.Attackable)
local Interactable = require(script.Interactable)
local Ownable = require(script.Ownable)

export type Component = {
    init: (target: any, config: any?) -> (),
    mixin: (target: any) -> (),
}

local Components = {
    Movable = Movable,
    Damageable = Damageable,
    Attackable = Attackable,
    Interactable = Interactable,
    Ownable = Ownable,
}

--- Compose multiple components into a target object
--- This mixes in all methods from each component
function Components.compose(target: any, components: { Component }): ()
    for _, component in ipairs(components) do
        component.mixin(target)
    end
end

--- Initialize and compose components in one call
--- Each entry should be { component, config? }
function Components.build(target: any, componentConfigs: { { Component | any } }): ()
    for _, entry in ipairs(componentConfigs) do
        local component = entry[1] :: Component
        local config = entry[2]
        component.init(target, config)
        component.mixin(target)
    end
end

return Components
