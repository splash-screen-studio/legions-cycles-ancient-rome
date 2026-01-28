--!strict
--[[
    Damageable Component - Provides health and damage capabilities to entities
    Part of OOP Composition system - mix into classes that can take damage
    Based on BRicey Composition Over Inheritance tutorial
]]

export type DamageableData = {
    health: number,
    maxHealth: number,
    armor: number?,
}

export type Damageable = {
    health: number,
    maxHealth: number,
    armor: number,
    isDead: boolean,
    takeDamage: (self: Damageable, amount: number) -> number,
    heal: (self: Damageable, amount: number) -> number,
    getHealth: (self: Damageable) -> number,
    getMaxHealth: (self: Damageable) -> number,
    getHealthPercent: (self: Damageable) -> number,
    isAlive: (self: Damageable) -> boolean,
    die: (self: Damageable) -> (),
}

local Damageable = {}

local DEFAULT_HEALTH = 100
local DEFAULT_ARMOR = 0

--- Initialize damageable data on an object
function Damageable.init(target: any, config: DamageableData?): ()
    local cfg = config or {} :: DamageableData
    target.maxHealth = cfg.maxHealth or cfg.health or DEFAULT_HEALTH
    target.health = cfg.health or target.maxHealth
    target.armor = cfg.armor or DEFAULT_ARMOR
    target.isDead = false
end

--- Take damage (reduced by armor), returns actual damage dealt
function Damageable.takeDamage(self: Damageable, amount: number): number
    if self.isDead then
        return 0
    end

    -- Armor reduces damage (simple percentage reduction)
    local reduction = self.armor / 100
    local actualDamage = math.max(0, amount * (1 - reduction))

    self.health = math.max(0, self.health - actualDamage)

    if self.health <= 0 then
        self:die()
    end

    return actualDamage
end

--- Heal by an amount, returns actual amount healed
function Damageable.heal(self: Damageable, amount: number): number
    if self.isDead then
        return 0
    end

    local oldHealth = self.health
    self.health = math.min(self.maxHealth, self.health + amount)

    return self.health - oldHealth
end

--- Get current health
function Damageable.getHealth(self: Damageable): number
    return self.health
end

--- Get maximum health
function Damageable.getMaxHealth(self: Damageable): number
    return self.maxHealth
end

--- Get health as a percentage (0-1)
function Damageable.getHealthPercent(self: Damageable): number
    if self.maxHealth <= 0 then
        return 0
    end
    return self.health / self.maxHealth
end

--- Check if still alive
function Damageable.isAlive(self: Damageable): boolean
    return not self.isDead
end

--- Called when health reaches 0
function Damageable.die(self: Damageable): ()
    self.isDead = true
    self.health = 0
end

--- Mix damageable methods into a target table
function Damageable.mixin(target: any): ()
    target.takeDamage = Damageable.takeDamage
    target.heal = Damageable.heal
    target.getHealth = Damageable.getHealth
    target.getMaxHealth = Damageable.getMaxHealth
    target.getHealthPercent = Damageable.getHealthPercent
    target.isAlive = Damageable.isAlive
    target.die = Damageable.die
end

return Damageable
