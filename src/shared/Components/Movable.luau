--!strict
--[[
    Movable Component - Provides movement capabilities to entities
    Part of OOP Composition system - mix into classes that need movement
    Based on BRicey Composition Over Inheritance tutorial
]]

export type MovableData = {
    position: Vector3,
    speed: number,
}

export type Movable = {
    position: Vector3,
    speed: number,
    move: (self: Movable, direction: Vector3) -> (),
    moveTo: (self: Movable, targetPosition: Vector3) -> (),
    setPosition: (self: Movable, newPosition: Vector3) -> (),
    getPosition: (self: Movable) -> Vector3,
}

local Movable = {}

local DEFAULT_SPEED = 16

--- Initialize movable data on an object
function Movable.init(target: any, config: MovableData?): ()
    local cfg = config or {} :: MovableData
    target.position = cfg.position or Vector3.new(0, 0, 0)
    target.speed = cfg.speed or DEFAULT_SPEED
end

--- Move in a direction (normalized, scaled by speed)
function Movable.move(self: Movable, direction: Vector3): ()
    if direction.Magnitude > 0 then
        local normalizedDir = direction.Unit
        self.position = self.position + normalizedDir * self.speed
    end
end

--- Move towards a target position by one speed unit
function Movable.moveTo(self: Movable, targetPosition: Vector3): ()
    local delta = targetPosition - self.position
    if delta.Magnitude <= self.speed then
        self.position = targetPosition
    else
        self.position = self.position + delta.Unit * self.speed
    end
end

--- Set position directly
function Movable.setPosition(self: Movable, newPosition: Vector3): ()
    self.position = newPosition
end

--- Get current position
function Movable.getPosition(self: Movable): Vector3
    return self.position
end

--- Mix movable methods into a target table
function Movable.mixin(target: any): ()
    target.move = Movable.move
    target.moveTo = Movable.moveTo
    target.setPosition = Movable.setPosition
    target.getPosition = Movable.getPosition
end

return Movable
