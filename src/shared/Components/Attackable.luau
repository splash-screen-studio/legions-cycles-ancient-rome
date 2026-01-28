--!strict
--[[
    Attackable Component - Provides attack capabilities to entities
    Part of OOP Composition system - mix into classes that can deal damage
    Based on BRicey Composition Over Inheritance tutorial
]]

local _Damageable = require(script.Parent.Damageable) -- For type reference

export type AttackableData = {
    damage: number,
    attackRange: number?,
    attackCooldown: number?,
}

export type AttackableTarget = {
    takeDamage: (self: any, amount: number) -> number,
    position: Vector3?,
}

export type Attackable = {
    damage: number,
    attackRange: number,
    attackCooldown: number,
    lastAttackTime: number,
    position: Vector3?,
    attack: (self: Attackable, target: AttackableTarget) -> boolean,
    canAttack: (self: Attackable, target: AttackableTarget?) -> boolean,
    isInRange: (self: Attackable, target: AttackableTarget) -> boolean,
    getDamage: (self: Attackable) -> number,
    setDamage: (self: Attackable, amount: number) -> (),
}

local Attackable = {}

local DEFAULT_DAMAGE = 10
local DEFAULT_ATTACK_RANGE = 5
local DEFAULT_ATTACK_COOLDOWN = 1

--- Initialize attackable data on an object
function Attackable.init(target: any, config: AttackableData?): ()
    local cfg = config or {} :: AttackableData
    target.damage = cfg.damage or DEFAULT_DAMAGE
    target.attackRange = cfg.attackRange or DEFAULT_ATTACK_RANGE
    target.attackCooldown = cfg.attackCooldown or DEFAULT_ATTACK_COOLDOWN
    target.lastAttackTime = 0
end

--- Attack a target, returns true if attack was successful
function Attackable.attack(self: Attackable, target: AttackableTarget): boolean
    if not self:canAttack(target) then
        return false
    end

    if not self:isInRange(target) then
        return false
    end

    target:takeDamage(self.damage)
    self.lastAttackTime = os.clock()

    return true
end

--- Check if can attack (cooldown elapsed)
function Attackable.canAttack(self: Attackable, _target: AttackableTarget?): boolean
    local currentTime = os.clock()
    return (currentTime - self.lastAttackTime) >= self.attackCooldown
end

--- Check if target is within attack range
function Attackable.isInRange(self: Attackable, target: AttackableTarget): boolean
    if not self.position or not target.position then
        -- If either doesn't have position, assume in range
        return true
    end

    local distance = (target.position - self.position).Magnitude
    return distance <= self.attackRange
end

--- Get current damage value
function Attackable.getDamage(self: Attackable): number
    return self.damage
end

--- Set damage value
function Attackable.setDamage(self: Attackable, amount: number): ()
    self.damage = amount
end

--- Mix attackable methods into a target table
function Attackable.mixin(target: any): ()
    target.attack = Attackable.attack
    target.canAttack = Attackable.canAttack
    target.isInRange = Attackable.isInRange
    target.getDamage = Attackable.getDamage
    target.setDamage = Attackable.setDamage
end

return Attackable
