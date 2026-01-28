# Legions & Cycles: Ancient Rome

## Project Overview

A Roblox game set in Ancient Rome, implementing techniques from [BRicey's YouTube tutorials](https://www.youtube.com/@BRicey/videos) adapted to the Roman theme.

**Key constraint**: The terrain is undulating (rolling hills). ALL placed objects must query terrain height at their X,Z position. Water terrain must ONLY exist within part-built pool walls.

## Documentation

| Document | Purpose |
|----------|---------|
| `IMPLEMENTATION_PLAN.md` | Complete feature list, 43 GitHub issues, prioritized implementation order |
| `.claude-workers/README.md` | Multi-agent workflow system overview |
| `.claude-workers/manager-commands.md` | Commands reference for manager role |

## Multi-Agent Roles

This project uses a multi-agent workflow with four roles:

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

## File Structure

```
legions-cycles-ancient-rome/
├── CLAUDE.md                    # This file (auto-read by Claude Code)
├── CLAUDE_PLANNER.md           # Planner role context
├── CLAUDE_MANAGER.md           # Manager role context
├── CLAUDE_WORKER.md            # Worker role context
├── IMPLEMENTATION_PLAN.md      # All 43 issues, priorities, BRicey mappings
├── default.project.json        # Rojo configuration
├── src/
│   ├── server/                 # ServerScriptService (*.server.luau)
│   ├── client/                 # StarterPlayerScripts (*.client.luau)
│   └── shared/                 # ReplicatedStorage (*.luau)
├── assets/
│   └── ServerStorage/
│       └── Templates/          # Cloneable templates
└── .claude-workers/            # Multi-agent management
    ├── spawn-worker.sh         # Spawn worker for an issue
    ├── check-status.sh         # Check worker statuses
    ├── status/                 # Worker status JSON files
    ├── logs/                   # Worker output logs
    └── worktrees/              # Git worktree directories
```

## Critical Rules (All Roles)

### 1. Terrain-Adaptive Y Positioning
```lua
-- CORRECT: Query terrain height
local y = TerrainUtils.getHeightAt(x, z)
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
- Server scripts: `Name.server.luau`
- Client scripts: `Name.client.luau`
- Shared modules: `Name.luau`
- **NEVER use `.lua`**

### 4. Part Anchoring
All procedurally generated/placed parts must be anchored:
```lua
part.Anchored = true
```

## Coding Standards

```lua
--!strict
local ModuleName = {}
ModuleName.__index = ModuleName

local MAX_ITERATIONS = 10  -- UPPER_SNAKE_CASE for constants

type Config = {             -- Type definitions
    value: number,
    name: string
}

function ModuleName.new(config: Config)
    local self = setmetatable({}, ModuleName)
    self.value = config.value
    return self
end

function ModuleName:doThing(): boolean  -- camelCase for methods
    return true
end

return ModuleName
```

## Roman Theme Guidelines

- **Names**: Use Latin where appropriate (Thermae, Impluvium, Castra, Via)
- **Colors**: Terracotta, marble white, bronze, olive green, sand
- **Materials**: Marble, Brick, Concrete, Wood, Sand, Slate
- **Architecture**: Columns (Doric, Corinthian), arches, atriums, forums

## Git Workflow

1. **Branch naming**: `issue-{number}-brief-description`
2. **Commit format**: `Implement #22: Brief description`
3. **PR body**: Must include `Closes #{number}`
4. **Review**: Wait for `@claude` review before merge

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
