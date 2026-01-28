--!strict
--[[
    CFrameUtils - CFrame manipulation utilities for segment connection and transforms
    Based on BRicey CFrame Transforms techniques
]]

local CFrameUtils = {}

--- Chain a child CFrame to a parent CFrame (parent-relative offset)
function CFrameUtils.chain(parent: CFrame, offset: CFrame): CFrame
    return parent * offset
end

--- Convert a world-space CFrame to local space relative to another CFrame
function CFrameUtils.toLocal(worldCFrame: CFrame, relativeTo: CFrame): CFrame
    return relativeTo:ToObjectSpace(worldCFrame)
end

--- Convert a local-space CFrame to world space relative to another CFrame
function CFrameUtils.toWorld(localCFrame: CFrame, relativeTo: CFrame): CFrame
    return relativeTo:ToWorldSpace(localCFrame)
end

--- Rotate a CFrame around the Y axis
function CFrameUtils.rotateY(cf: CFrame, radians: number): CFrame
    return cf * CFrame.Angles(0, radians, 0)
end

--- Rotate a CFrame around the X axis
function CFrameUtils.rotateX(cf: CFrame, radians: number): CFrame
    return cf * CFrame.Angles(radians, 0, 0)
end

--- Rotate a CFrame around the Z axis
function CFrameUtils.rotateZ(cf: CFrame, radians: number): CFrame
    return cf * CFrame.Angles(0, 0, radians)
end

--- Get the forward vector (LookVector) of a CFrame
function CFrameUtils.getForward(cf: CFrame): Vector3
    return cf.LookVector
end

--- Get the up vector of a CFrame
function CFrameUtils.getUp(cf: CFrame): Vector3
    return cf.UpVector
end

--- Get the right vector of a CFrame
function CFrameUtils.getRight(cf: CFrame): Vector3
    return cf.RightVector
end

--- Create a CFrame that looks from one position to another
function CFrameUtils.lookAt(from: Vector3, target: Vector3, up: Vector3?): CFrame
    return CFrame.lookAt(from, target, up or Vector3.yAxis)
end

--- Linearly interpolate between two CFrames
function CFrameUtils.lerp(a: CFrame, b: CFrame, alpha: number): CFrame
    return a:Lerp(b, alpha)
end

--- Create a CFrame at a position with optional rotation angles (in radians)
function CFrameUtils.fromPositionAndAngles(position: Vector3, rx: number?, ry: number?, rz: number?): CFrame
    return CFrame.new(position) * CFrame.Angles(rx or 0, ry or 0, rz or 0)
end

return CFrameUtils
