--!strict
--[[
    Interactable Component - Provides player interaction capabilities to entities
    Part of OOP Composition system - mix into classes that players can interact with
    Based on BRicey Composition Over Inheritance tutorial
]]

export type InteractableData = {
    interactionRange: number?,
    interactionPrompt: string?,
    interactionEnabled: boolean?,
}

export type Interactable = {
    interactionRange: number,
    interactionPrompt: string,
    interactionEnabled: boolean,
    position: Vector3?,
    onInteract: ((self: Interactable, player: Player) -> ())?,
    interact: (self: Interactable, player: Player) -> boolean,
    canInteract: (self: Interactable, playerPosition: Vector3?) -> boolean,
    setInteractionCallback: (self: Interactable, callback: (self: Interactable, player: Player) -> ()) -> (),
    enableInteraction: (self: Interactable) -> (),
    disableInteraction: (self: Interactable) -> (),
    getInteractionPrompt: (self: Interactable) -> string,
    setInteractionPrompt: (self: Interactable, prompt: string) -> (),
}

local Interactable = {}

local DEFAULT_INTERACTION_RANGE = 10
local DEFAULT_INTERACTION_PROMPT = "Press E to interact"

--- Initialize interactable data on an object
function Interactable.init(target: any, config: InteractableData?): ()
    local cfg = config or {} :: InteractableData
    target.interactionRange = cfg.interactionRange or DEFAULT_INTERACTION_RANGE
    target.interactionPrompt = cfg.interactionPrompt or DEFAULT_INTERACTION_PROMPT
    target.interactionEnabled = if cfg.interactionEnabled ~= nil then cfg.interactionEnabled else true
    target.onInteract = nil
end

--- Attempt to interact with this object
function Interactable.interact(self: Interactable, player: Player): boolean
    if not self.interactionEnabled then
        return false
    end

    -- Check range if player has a character
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if humanoidRootPart and not self:canInteract(humanoidRootPart.Position) then
            return false
        end
    end

    -- Call the interaction callback if set
    if self.onInteract then
        self.onInteract(self, player)
    end

    return true
end

--- Check if interaction is possible from a position
function Interactable.canInteract(self: Interactable, playerPosition: Vector3?): boolean
    if not self.interactionEnabled then
        return false
    end

    if not playerPosition or not self.position then
        -- If positions not available, assume can interact
        return true
    end

    local distance = (playerPosition - self.position).Magnitude
    return distance <= self.interactionRange
end

--- Set the callback function for when interaction occurs
function Interactable.setInteractionCallback(
    self: Interactable,
    callback: (self: Interactable, player: Player) -> ()
): ()
    self.onInteract = callback
end

--- Enable interaction
function Interactable.enableInteraction(self: Interactable): ()
    self.interactionEnabled = true
end

--- Disable interaction
function Interactable.disableInteraction(self: Interactable): ()
    self.interactionEnabled = false
end

--- Get the interaction prompt text
function Interactable.getInteractionPrompt(self: Interactable): string
    return self.interactionPrompt
end

--- Set the interaction prompt text
function Interactable.setInteractionPrompt(self: Interactable, prompt: string): ()
    self.interactionPrompt = prompt
end

--- Mix interactable methods into a target table
function Interactable.mixin(target: any): ()
    target.interact = Interactable.interact
    target.canInteract = Interactable.canInteract
    target.setInteractionCallback = Interactable.setInteractionCallback
    target.enableInteraction = Interactable.enableInteraction
    target.disableInteraction = Interactable.disableInteraction
    target.getInteractionPrompt = Interactable.getInteractionPrompt
    target.setInteractionPrompt = Interactable.setInteractionPrompt
end

return Interactable
