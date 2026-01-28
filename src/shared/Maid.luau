--!strict
--[[
    Maid - Cleanup module to prevent memory leaks
    Properly destroys connections, instances, and tasks when cleanup is called.
    Based on BRicey Maid, Trove, Janitor cleanup modules tutorial

    Usage:
        local maid = Maid.new()

        -- Track a connection
        maid:give(part.Touched:Connect(function(hit)
            print("Touched by", hit.Name)
        end))

        -- Track a spawned instance
        local effect = Instance.new("Part")
        effect.Parent = workspace
        maid:give(effect)

        -- Track a running task (thread)
        maid:give(task.spawn(function()
            while true do
                task.wait(1)
                print("Running...")
            end
        end))

        -- When done with everything
        maid:destroy()  -- All connections, instances, and tasks cleaned up
]]

local Maid = {}
Maid.__index = Maid

export type Task = RBXScriptConnection | Instance | () -> () | thread
export type Maid = typeof(setmetatable({} :: { _tasks: { Task } }, Maid))

--- Creates a new Maid instance for tracking cleanup tasks
function Maid.new(): Maid
    local self = setmetatable({
        _tasks = {} :: { Task },
    }, Maid)
    return self
end

--- Adds a task to be cleaned up later
--- Returns the task so it can be used inline
function Maid:give<T>(taskToTrack: T): T
    table.insert(self._tasks, taskToTrack :: any)
    return taskToTrack
end

--- Cleans up all tracked tasks
--- Connections are disconnected, Instances are destroyed, functions are called, threads are cancelled
function Maid:cleanup(): ()
    for _, taskItem in self._tasks do
        local taskType = typeof(taskItem)

        if taskType == "RBXScriptConnection" then
            (taskItem :: RBXScriptConnection):Disconnect()
        elseif taskType == "Instance" then
            (taskItem :: Instance):Destroy()
        elseif taskType == "function" then
            (taskItem :: () -> ())()
        elseif taskType == "thread" then
            task.cancel(taskItem :: thread)
        end
    end
    table.clear(self._tasks)
end

--- Alias for cleanup - destroys the maid and all tracked tasks
function Maid:destroy(): ()
    self:cleanup()
end

--- Returns the number of tasks currently being tracked
function Maid:getTaskCount(): number
    return #self._tasks
end

return Maid
