--!strict
--[[
    Ownable Component - Provides ownership tracking to entities
    Part of OOP Composition system - mix into classes that can be owned
    Based on BRicey Composition Over Inheritance tutorial
]]

export type OwnableData = {
    ownerId: number?,
    ownerName: string?,
    transferable: boolean?,
}

export type Ownable = {
    ownerId: number?,
    ownerName: string?,
    transferable: boolean,
    setOwner: (self: Ownable, player: Player?) -> (),
    setOwnerById: (self: Ownable, playerId: number?, playerName: string?) -> (),
    getOwnerId: (self: Ownable) -> number?,
    getOwnerName: (self: Ownable) -> string?,
    hasOwner: (self: Ownable) -> boolean,
    isOwnedBy: (self: Ownable, player: Player) -> boolean,
    isOwnedById: (self: Ownable, playerId: number) -> boolean,
    clearOwner: (self: Ownable) -> (),
    canTransfer: (self: Ownable) -> boolean,
    transfer: (self: Ownable, newOwner: Player) -> boolean,
}

local Ownable = {}

--- Initialize ownable data on an object
function Ownable.init(target: any, config: OwnableData?): ()
    local cfg = config or {} :: OwnableData
    target.ownerId = cfg.ownerId
    target.ownerName = cfg.ownerName
    target.transferable = if cfg.transferable ~= nil then cfg.transferable else true
end

--- Set owner from a Player object
function Ownable.setOwner(self: Ownable, player: Player?): ()
    if player then
        self.ownerId = player.UserId
        self.ownerName = player.Name
    else
        self.ownerId = nil
        self.ownerName = nil
    end
end

--- Set owner by player ID and optional name
function Ownable.setOwnerById(self: Ownable, playerId: number?, playerName: string?): ()
    self.ownerId = playerId
    self.ownerName = playerName
end

--- Get the owner's player ID
function Ownable.getOwnerId(self: Ownable): number?
    return self.ownerId
end

--- Get the owner's name
function Ownable.getOwnerName(self: Ownable): string?
    return self.ownerName
end

--- Check if this object has an owner
function Ownable.hasOwner(self: Ownable): boolean
    return self.ownerId ~= nil
end

--- Check if owned by a specific player
function Ownable.isOwnedBy(self: Ownable, player: Player): boolean
    return self.ownerId == player.UserId
end

--- Check if owned by a specific player ID
function Ownable.isOwnedById(self: Ownable, playerId: number): boolean
    return self.ownerId == playerId
end

--- Clear the owner
function Ownable.clearOwner(self: Ownable): ()
    self.ownerId = nil
    self.ownerName = nil
end

--- Check if ownership can be transferred
function Ownable.canTransfer(self: Ownable): boolean
    return self.transferable
end

--- Transfer ownership to a new player
function Ownable.transfer(self: Ownable, newOwner: Player): boolean
    if not self.transferable then
        return false
    end

    self:setOwner(newOwner)
    return true
end

--- Mix ownable methods into a target table
function Ownable.mixin(target: any): ()
    target.setOwner = Ownable.setOwner
    target.setOwnerById = Ownable.setOwnerById
    target.getOwnerId = Ownable.getOwnerId
    target.getOwnerName = Ownable.getOwnerName
    target.hasOwner = Ownable.hasOwner
    target.isOwnedBy = Ownable.isOwnedBy
    target.isOwnedById = Ownable.isOwnedById
    target.clearOwner = Ownable.clearOwner
    target.canTransfer = Ownable.canTransfer
    target.transfer = Ownable.transfer
end

return Ownable
