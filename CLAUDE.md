# Legions & Cycles: Ancient Rome

## Project Overview

A Roblox game set in Ancient Rome, implementing techniques from [BRicey's YouTube tutorials](https://www.youtube.com/@BRicey/videos) adapted to the Roman theme.

**Key constraint**: The terrain is undulating (rolling hills). ALL placed objects must query terrain height at their X,Z position. Water terrain must ONLY exist within part-built pool walls.

## BRicey Module Architecture (CRITICAL)

This project follows the **BRicey module pattern** - the standard Roblox architecture taught across BRicey's tutorials:

```
Entry Points (Scripts)  →  require()  →  ModuleScripts (Logic)
```

### File Structure

```
src/
├── server/
│   ├── init.server.luau        # SERVER ENTRY POINT - bootstraps server systems
│   ├── TerrainManager.luau     # ModuleScript - terrain generation logic
│   └── GameManager.luau        # ModuleScript - game state logic
├── client/
│   ├── init.client.luau        # CLIENT ENTRY POINT - bootstraps client systems
│   ├── MusicManager.luau       # ModuleScript - music playback logic
│   └── InputHandler.luau       # ModuleScript - input handling logic
└── shared/
    ├── TerrainUtils.luau       # Shared ModuleScript - terrain utilities
    ├── Constants.luau          # Shared ModuleScript - game constants
    ├── Maid.luau               # Shared ModuleScript - cleanup utility
    └── Components/             # Shared ModuleScripts - OOP components
        ├── init.luau
        ├── Movable.luau
        └── Damageable.luau
```

### Rojo File Extension Rules

| Extension | Becomes | Purpose |
|-----------|---------|---------|
| `init.server.luau` | Script | Server entry point (auto-runs) |
| `init.client.luau` | LocalScript | Client entry point (auto-runs) |
| `Name.luau` | ModuleScript | Logic module (must be required) |
| `init.luau` | ModuleScript | Folder's module entry point |

**NEVER use `.server.luau` or `.client.luau` for non-init files in src/server or src/client folders.** They become ModuleScripts anyway due to Rojo's init file rules, causing confusion.

### Entry Point Pattern

```lua
-- src/server/init.server.luau (SERVER ENTRY POINT)
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared")

-- Require and initialize server modules
local TerrainManager = require(script.TerrainManager)
local GameManager = require(script.GameManager)

-- Bootstrap the server
local terrainManager = TerrainManager.new()
terrainManager:generate()

local gameManager = GameManager.new()
gameManager:start()

print("[Server] All systems initialized")
```

```lua
-- src/client/init.client.luau (CLIENT ENTRY POINT)
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared")

-- Require and initialize client modules
local MusicManager = require(script.MusicManager)

-- Bootstrap the client
local musicManager = MusicManager.new()
musicManager:playPlaylist()

print("[Client] All systems initialized")
```

### ModuleScript Pattern (BRicey OOP)

```lua
-- src/server/TerrainManager.luau (ModuleScript)
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local TerrainUtils = require(Shared:WaitForChild("TerrainUtils"))

local TerrainManager = {}
TerrainManager.__index = TerrainManager

function TerrainManager.new()
    local self = setmetatable({}, TerrainManager)
    self.terrain = workspace.Terrain
    return self
end

function TerrainManager:generate()
    print("[TerrainManager] Generating terrain...")
    -- Generation logic here
end

return TerrainManager  -- ModuleScripts MUST return their table
```

**Key points:**
- ModuleScripts contain logic but do NOT auto-initialize
- Entry points `require()` modules and call initialization methods
- ModuleScripts return their class/table at the end
- NO standalone code at module bottom (no `init()` calls)

## Documentation

| Document | Purpose |
|----------|---------|
| `IMPLEMENTATION_PLAN.md` | Complete feature list, 43 GitHub issues, prioritized implementation order |
| `.claude-workers/README.md` | Multi-agent workflow system overview |
| `.claude-workers/manager-commands.md` | Commands reference for manager role |

## Multi-Agent Roles

| Role | File | Description |
|------|------|-------------|
| Planner | `CLAUDE_PLANNER.md` | Creates issues, sets priorities, designs architecture |
| Manager | `CLAUDE_MANAGER.md` | Monitors workers, reviews PRs, merges code |
| Worker | `CLAUDE_WORKER.md` | Implements single issues, runs tests, opens PRs |
| Judge | GitHub App | Reviews PRs via `@claude` mentions |

**If you are unsure which role you are, you are likely a Manager in an interactive session.**

## Tech Stack

- **Platform**: Roblox Studio
- **Language**: Luau (`.luau` files, NOT `.lua`)
- **Sync Tool**: Rojo (`rojo serve`)
- **Version Control**: Git with feature branches + worktrees

## Critical Rules

### 1. Terrain-Adaptive Y Positioning
```lua
-- CORRECT: Query terrain height
local y = TerrainUtils.getHeightAt(terrain, x, z)
object:PivotTo(CFrame.new(x, y, z))

-- WRONG: Hardcoded Y
object:PivotTo(CFrame.new(x, 10, z))  -- NEVER DO THIS
```

### 2. Water Within Pool Walls Only
```lua
-- CORRECT: Water inside part-built pool
local poolWalls = createPoolStructure(position, size)
fillInteriorWithWater(poolWalls)

-- WRONG: Water directly in terrain
terrain:FillBlock(cf, size, Enum.Material.Water)  -- NEVER DO THIS
```

### 3. File Extensions
| Location | Extension | Result |
|----------|-----------|--------|
| `src/server/init.server.luau` | `.server.luau` | Script (entry point) |
| `src/server/SomeModule.luau` | `.luau` | ModuleScript |
| `src/client/init.client.luau` | `.client.luau` | LocalScript (entry point) |
| `src/client/SomeModule.luau` | `.luau` | ModuleScript |
| `src/shared/Anything.luau` | `.luau` | ModuleScript |

**NEVER use `.lua` extension.**

### 4. Part Anchoring
```lua
part.Anchored = true  -- ALWAYS for static objects
```

### 5. Subsystem Versioning

Every module must have a VERSION constant and log it on initialization:

```lua
local MyModule = {}
MyModule.__index = MyModule
MyModule.VERSION = "1.0.0"

function MyModule.new()
    print(string.format("[MyModule v%s] Initializing...", MyModule.VERSION))
    -- ...
end
```

Entry points must log their version and all subsystem versions:
```lua
print(string.format("[Server v%s] Starting...", VERSION))
print(string.format("[Server] Loaded TerrainManager v%s", TerrainManager.VERSION))
```

### 6. ModuleScript Structure
```lua
-- ModuleScripts must:
-- 1. Define a table
-- 2. Add methods to the table
-- 3. Return the table
-- 4. NOT have auto-executing code at the bottom

local MyModule = {}
MyModule.__index = MyModule

function MyModule.new()
    return setmetatable({}, MyModule)
end

function MyModule:doSomething()
    -- Logic here
end

return MyModule  -- Required!
```

## Roman Theme Guidelines

- **Names**: Use Latin where appropriate (Thermae, Impluvium, Castra, Via)
- **Colors**: Terracotta, marble white, bronze, olive green, sand
- **Materials**: Marble, Brick, Concrete, Wood, Sand, Slate
- **Architecture**: Columns (Doric, Corinthian), arches, atriums, forums

## Code Quality Requirements

**Every PR must pass lint, typecheck, and tests.**

### Tools (via Aftman)
```bash
aftman install  # Install all tools
```

| Tool | Command | Purpose |
|------|---------|---------|
| Selene | `selene src/` | Linting |
| Luau | `luau-analyze src/` | Type checking |
| Lune | `lune run tests/init.luau` | Unit tests |

### PR Checks (must all pass)
1. **Lint**: `selene src/` - no errors
2. **Typecheck**: `luau-analyze src/` - no errors
3. **Tests**: `lune run tests/init.luau` - all pass

## Testing Requirements

**Every PR must include tests.** We use [Lune](https://github.com/lune-org/lune) for offline Luau testing.

### Running Tests
```bash
lune run tests/init.luau
```

### Test File Naming
- Tests go in `tests/` directory
- Test files: `ModuleName.spec.luau`
- Example: `tests/shared/TerrainUtils.spec.luau`

### PR Requirements
- [ ] All new modules must have corresponding `.spec.luau` test file
- [ ] All tests must pass before merge
- [ ] Test coverage for new functions/methods

### What to Test
1. Module has VERSION constant
2. Module exports expected functions
3. Functions return expected types
4. Edge cases and error handling

## Git Workflow

1. **Branch naming**: `issue-{number}-brief-description`
2. **Commit format**: `Implement #22: Brief description`
3. **PR body**: Must include `Closes #{number}`
4. **PR checklist**: Must include test verification
5. **Review**: Wait for `@claude` review before merge

## BRicey Techniques Reference

Key techniques from the 100 BRicey tutorials adapted for this project:

| Technique | Roman Application |
|-----------|-------------------|
| Procedural trees (recursion + CFrame) | Cypress, Olive, Stone Pine |
| Grid snapping placement | Roman grid (Castra, Insulae) |
| Pivot point management | Structure foundations on terrain |
| FastCast projectiles | Ballista, Pilum, Scorpio |
| Finite State Machines | Guard AI (PATROL→ALERT→PURSUE) |
| Hinge/Spring constraints | Gates, catapults, doors |
| DataStore persistence | Player progress saving |
| RemoteEvents + sanity checks | Secure client-server |

See `IMPLEMENTATION_PLAN.md` for the complete mapping of all 43 issues.
