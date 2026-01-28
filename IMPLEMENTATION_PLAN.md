# Legions & Cycles: Ancient Rome - Implementation Plan

This document outlines all features to be implemented, adapted from BRicey Roblox development techniques to the Ancient Roman theme.

---

## Target Platform: MOBILE-FIRST

**Primary**: iPhone/iPad (smaller touchscreen, no physical keyboard)
**Secondary**: Desktop (development testing)

### Mobile Design Requirements
- Touch-friendly UI (large tap targets, minimal precision)
- No keyboard shortcuts required for core gameplay
- Single and two-finger gestures (tap, drag, pinch)
- On-screen virtual controls where needed
- Mobile-optimized performance
- Responsive layout for various screen sizes

### Prioritization Strategy
1. **Foundational features** - Features that other features depend on
2. **Project setup & tooling** - Development infrastructure
3. **Core game experience** - What makes the game playable and fun
4. **Roman theme alignment** - What makes it feel like Ancient Rome

---

## Phase 1: Foundation - Terrain System

### 1.1 Undulating Terrain Generation
**Priority: CRITICAL (Foundation for all other features)**

Generate authentic Italian peninsula terrain using Roblox's terrain system with rolling hills, valleys, and elevation changes characteristic of the Roman landscape.

**Technical Approach:**
- Use `workspace.Terrain` API for terrain manipulation
- Implement Perlin noise or similar algorithms for natural undulation
- Create height utility function: `getTerrainHeightAt(x, z)` that all other systems will use
- Support multiple biomes: Grassland, Rock, Sand, Ground materials
- Elevation range: Sea level to hillside fortifications

**Terrain Materials:**
- Grass (primary lowlands)
- Rock (hillsides, cliffs)
- Ground (paths, worn areas)
- Sand (near water, arena floors)

**Key Functions:**
```lua
-- Core terrain height query (all features depend on this)
function TerrainManager:getHeightAt(x: number, z: number): number

-- Terrain generation with noise
function TerrainManager:generateTerrain(regionSize: Vector3, seed: number)

-- Flatten area for structures
function TerrainManager:flattenForStructure(position: Vector3, size: Vector3)
```

---

### 1.2 Roman Water Features (Pool-Wall System)
**Priority: HIGH**

Create water features (baths, fountains, impluvium) using part-built walls containing water terrain. Water terrain is NEVER placed directly in open terrain - always within constructed basins.

**Water Feature Types:**
- **Thermae (Roman Baths)**: Large public bathing pools with marble walls
- **Impluvium**: Household rainwater collection pools
- **Nymphaeum**: Decorative fountain structures
- **Aqueduct Basins**: Water collection points

**Technical Approach:**
- Create part-based pool walls/basins first
- Fill interior with Water terrain material
- Pool floor slightly below surrounding terrain
- Wall tops at or above water level
- Support for stepped pools (frigidarium, tepidarium, caldarium)

**Key Functions:**
```lua
function WaterFeature:createPool(position: Vector3, dimensions: Vector3, wallMaterial: string)
function WaterFeature:fillWithWater(poolModel: Model)
function WaterFeature:createStepped(levels: {{height: number, size: Vector3}})
```

---

## Phase 2: Procedural Vegetation

### 2.1 Procedural Mediterranean Trees
**Based on: BRicey Procedural Tree Generation**

Generate authentic Roman-era vegetation using recursive CFrame-based branching algorithms.

**Tree Types:**
- **Cypress Trees** (Cupressus sempervirens): Tall, narrow, columnar - iconic Roman landscape
- **Olive Trees** (Olea europaea): Gnarled trunks, silver-green foliage
- **Stone Pine** (Pinus pinea): Umbrella-shaped canopy
- **Laurel Trees**: Sacred to Apollo, used for victory wreaths

**Technical Approach (from BRicey):**
- Recursive `generateTree(parentBranch, iteration)` function
- MAX_ITERATIONS controls tree complexity
- CFrame transforms for branch positioning
- Pivot points at branch bases for proper stacking
- Branch tapering: 70% width, 90% length per iteration
- Droop angle interpolation using `math.lerp()`
- Randomized branching probability decreasing with height

**Tree-Specific Parameters:**
```lua
CYPRESS = {
    maxIterations = 8,
    branchAngle = 15,  -- narrow spread
    droopFactor = 0.1,
    widthTaper = 0.85,
    lengthTaper = 0.92
}

OLIVE = {
    maxIterations = 5,
    branchAngle = 45,  -- wide spread
    droopFactor = 0.3,
    widthTaper = 0.7,
    lengthTaper = 0.85,
    trunkGnarled = true
}

STONE_PINE = {
    maxIterations = 6,
    branchAngle = 60,  -- umbrella shape
    droopFactor = -0.1,  -- upward curve
    canopyOnlyAtTop = true
}
```

**Y-Position Adaptation:**
- All trees query `TerrainManager:getHeightAt(x, z)` for base position
- Tree roots anchor to terrain surface

---

### 2.2 Foliage and Ground Cover
**Based on: BRicey Randomized Object Sizing**

Scatter Mediterranean ground vegetation adapting to terrain height.

**Vegetation Types:**
- Grape vines (vineyard rows)
- Wheat fields
- Flowering herbs (rosemary, lavender)
- Grass tufts
- Fallen leaves/debris

**Technical Approach:**
- Clone from ServerStorage templates
- Randomized sizing: `math.max(0.3, math.random() * 1.5)`
- Position at terrain height + small offset
- Rotation randomization for natural appearance

---

## Phase 3: Placement Systems

### 3.1 Roman Grid Placement System
**Based on: BRicey Grid Snapping Placement System**

Implement grid-based construction for Roman architectural precision.

**Grid Types:**
- **Castra Grid** (Military Camp): Strict rectangular layout
- **Insulae Grid** (City Blocks): Urban building placement
- **Villa Grid** (Estate Layout): Looser residential grid
- **Forum Grid** (Public Space): Ceremonial precision

**Technical Approach:**
- Toggle grid with keyboard (G key)
- Snap function: `math.round(pos / gridSize) * gridSize`
- X/Z snapping only - Y adapts to terrain
- Multiple grid sizes: 1, 2, 4, 8 studs

**Key Functions:**
```lua
function snapToGrid(position: Vector3, gridSize: number): Vector3
    return Vector3.new(
        math.round(position.X / gridSize) * gridSize,
        TerrainManager:getHeightAt(position.X, position.Z),  -- Terrain-adaptive Y
        math.round(position.Z / gridSize) * gridSize
    )
end
```

**Input Binding:**
- G key: Cycle grid sizes (0 → 1 → 2 → 4 → 8 → 0)
- ContextActionService for binding/unbinding

---

### 3.2 Structure Foundation System
**Based on: BRicey Pivot Point Management**

Place Roman structures with proper foundation adaptation to terrain.

**Structure Types:**
- Domus (Roman house)
- Taberna (Shop)
- Temple
- Fortification walls
- Aqueduct segments

**Technical Approach:**
- Pivot points at structure base
- Query terrain height at all corners
- Option: Level foundation (cut into hillside) or stepped foundation
- PivotTo() for precise placement

---

## Phase 4: CFrame Transform Systems

### 4.1 Aqueduct Segment Chaining
**Based on: BRicey CFrame Transforms and Local Space Positioning**

Create connected aqueduct systems using CFrame multiplication for seamless segment joining.

**Technical Approach:**
- Each segment has pivot at connection point
- `nextSegment:PivotTo(currentSegment:GetPivot() * connectionOffset)`
- Segments adapt to terrain slope
- Support for arched sections over valleys

**Segment Types:**
- Straight channel
- Arched bridge section
- Corner/turn section
- Castellum divisorium (distribution tank)

---

### 4.2 Roman Road Construction
**Based on: BRicey Vector3 Math for Offset Calculations**

Build Roman roads that follow terrain contours.

**Road Layers (historically accurate):**
1. Statumen (foundation stones)
2. Rudus (rubble)
3. Nucleus (cement/gravel)
4. Summum dorsum (paving stones)

**Technical Approach:**
- Road segments follow terrain Y at intervals
- Slight crown (center higher than edges) for drainage
- CFrame rotation to follow terrain slope
- Milestone placement at regular intervals

---

## Phase 5: Animation and Effects

### 5.1 Torch and Fire Lighting
**Based on: BRicey Randomized Object Sizing (for flame particles)**

Create authentic Roman lighting with torches, braziers, and oil lamps.

**Light Sources:**
- Wall-mounted torches
- Standing braziers
- Oil lamps (lucerna)
- Ceremonial fires

**Technical Approach:**
- PointLight with flickering intensity
- Particle emitters for flame effect
- Randomized particle sizing for natural fire
- Light color: warm orange (Color3.fromRGB(255, 147, 41))

---

### 5.2 Water Animation
Animate water features within pool structures.

**Effects:**
- Subtle surface ripples (texture offset animation)
- Fountain spray particles
- Steam for heated baths (caldarium)

---

### 5.3 Ambient Music System
**GitHub Issue: #49**
**Priority: HIGH**

Implement ambient music with Roman-themed soundtrack for immersive atmosphere.

**Soundtrack (6 tracks):**
| Track | Asset ID | Duration |
|-------|----------|----------|
| 01-dawn | `123517555949581` | 4:13 |
| 02-forum | `92805060343276` | 5:16 |
| 03-march | `139982351033320` | 6:19 |
| 04-colosseum | `94282741928731` | 6:19 |
| 05-caesar | `83679996557602` | 6:19 |
| 06-eternal | `122383615563909` | 4:13 |

**Features:**
- Playlist playback with shuffle
- Smooth crossfade between tracks
- Volume control
- Optional: context-aware music (time-of-day, area-based)

**Files:**
- `src/client/MusicManager.client.luau`
- `src/shared/MusicConfig.luau`

---

## Phase 6: Probability-Based Spawning

### 6.1 Decorative Element Distribution
**Based on: BRicey Probability-Based Feature Triggers**

Scatter decorative elements with decreasing probability from focal points.

**Element Types:**
- Statues and busts
- Potted plants
- Amphorae
- Market goods
- Military equipment (in castra)

**Technical Approach:**
```lua
local chance = math.max(0.1, 1.2 - distanceFromCenter * 0.01)
while math.random() < chance do
    spawnDecoration()
    chance *= 0.5
end
```

---

### 6.2 NPC Population Zones
Populate areas with Roman citizens, soldiers, and slaves based on zone type.

**Population Types by Zone:**
- Forum: Merchants, citizens, orators
- Castra: Legionaries, officers
- Thermae: Bathers, slaves
- Villa: Family members, servants

---

## Phase 7: UI and Input Systems

### 7.1 Construction Mode UI
**Based on: BRicey Keyboard Input Binding**

Player interface for building and placement.

**Controls:**
- E: Enter/exit construction mode
- G: Toggle grid snap
- R: Rotate object
- Mouse1: Place object
- Mouse2: Cancel

**Technical Approach:**
- ContextActionService for key bindings
- Unbind all actions on mode exit
- Visual preview of placement

---

### 7.2 Object Cycling System
Cycle through available construction objects.

**Categories:**
- Structures
- Vegetation
- Decorations
- Military

**Controls:**
- Q/E or scroll wheel to cycle
- Category tabs in UI

---

## Utility Functions Reference

### Terrain Height Query (Used by ALL systems)
```lua
-- This is the foundational function all other systems depend on
function TerrainManager:getHeightAt(x: number, z: number): number
    local ray = Ray.new(
        Vector3.new(x, 10000, z),
        Vector3.new(0, -20000, 0)
    )
    local _, hitPosition = workspace.Terrain:Raycast(ray)
    return hitPosition and hitPosition.Y or 0
end
```

### Grid Snapping (Terrain-Adaptive)
```lua
function snapToGrid(position: Vector3, gridSize: number): Vector3
    local snappedX = math.round(position.X / gridSize) * gridSize
    local snappedZ = math.round(position.Z / gridSize) * gridSize
    local terrainY = TerrainManager:getHeightAt(snappedX, snappedZ)
    return Vector3.new(snappedX, terrainY, snappedZ)
end
```

### CFrame Chaining
```lua
function chainSegment(parent: BasePart, offset: CFrame): BasePart
    local newSegment = parent:Clone()
    newSegment:PivotTo(parent:GetPivot() * offset)
    return newSegment
end
```

---

## Implementation Order

1. **Terrain System** (Foundation - required by all other systems)
   - Undulating terrain generation
   - Height query utility function
   - Terrain material distribution

2. **Water Pool System** (Requires terrain)
   - Part-based pool walls
   - Water terrain filling
   - Basic Roman bath structure

3. **Procedural Trees** (Requires terrain height)
   - Cypress tree generation
   - Olive tree generation
   - Stone pine generation

4. **Grid Placement** (Requires terrain height)
   - Snap-to-grid function
   - Keyboard toggle
   - Visual grid overlay

5. **Structure Placement** (Requires grid + terrain)
   - Foundation adaptation
   - Basic Roman structures

6. **Aqueduct System** (Requires CFrame chaining + terrain)
   - Segment types
   - Terrain-following

7. **Roman Roads** (Requires terrain)
   - Road segment generation
   - Terrain-following paths

8. **Lighting System** (Independent)
   - Torch implementation
   - Brazier implementation

9. **Decoration Distribution** (Requires terrain + placement)
   - Probability-based spawning
   - Zone-based population

10. **UI Systems** (Final layer)
    - Construction mode
    - Object cycling

---

## File Structure (Rojo Project)

Using `rojo serve` for development workflow. Scripts sync to Roblox Studio via Rojo.

```
legions-cycles-ancient-rome/
├── default.project.json            -- Rojo project configuration
├── src/
│   ├── server/                     -- ServerScriptService
│   │   ├── TerrainManager.server.luau
│   │   ├── WaterFeatures.server.luau
│   │   ├── TreeGenerator.server.luau
│   │   ├── StructurePlacer.server.luau
│   │   ├── AqueductBuilder.server.luau
│   │   └── RoadBuilder.server.luau
│   ├── client/                     -- StarterPlayerScripts
│   │   ├── PlacementController.client.luau
│   │   ├── ConstructionUI.client.luau
│   │   └── InputManager.client.luau
│   └── shared/                     -- ReplicatedStorage
│       ├── GridUtils.luau
│       ├── CFrameUtils.luau
│       ├── TerrainUtils.luau
│       └── Constants.luau
├── assets/                         -- Model/mesh references
│   └── templates/
│       ├── trees/
│       ├── structures/
│       └── decorations/
└── IMPLEMENTATION_PLAN.md
```

**Rojo Workflow:**
1. Run `rojo serve` in project root
2. Connect Roblox Studio via Rojo plugin
3. Edit `.lua` files locally - changes sync automatically
4. Test in Studio, commit to git

---

## Phase 8: Physics and Constraints

### 8.1 Hinge and Spring Mechanisms
**Based on:** BRicey HingeConstraints and Spring Constraints tutorials

Roman interactive mechanisms using physics constraints.

**Applications:**
- City gates (hinged doors)
- Catapult arms (spring-loaded)
- Temple doors (bronze hinges)
- Drawbridges

### 8.2 Prismatic Mechanisms
**Based on:** BRicey Prismatic Constraints / Elevator tutorial

Sliding mechanisms for Roman engineering.

**Applications:**
- Portcullis gates (vertical sliding)
- Arena platforms (rising/lowering)
- Mine elevators
- Siege tower ramps

### 8.3 Model Tweening with AlignPosition
**Based on:** BRicey Tween a Model using Align Position tutorial

Smooth model movement for ships, vehicles, siege equipment.

---

## Phase 9: Combat and Projectiles

### 9.1 FastCast Projectile System
**Based on:** BRicey FastCast Gun series

Realistic projectiles with travel time and drop.

**Roman Weapons:**
- Ballista bolts
- Pilum (javelins)
- Scorpio bolts
- Onager stones
- Sling projectiles

### 9.2 Raycasting for Detection
**Based on:** BRicey NEW Raycasting Functions tutorial

Line-of-sight, targeting, and surface detection.

---

## Phase 10: AI and Behavior

### 10.1 Finite State Machines
**Based on:** BRicey Delivery Drone with FSM series

NPC behavior structured as states with transitions.

**Guard States:** PATROL → ALERT → PURSUE → ATTACK
**Merchant States:** IDLE → GREETING → TRADING
**Citizen States:** WANDERING → DESTINATION → ACTIVITY

### 10.2 CFrame.lookAt for Orientation
**Based on:** BRicey CFrame.lookAt() tutorial

Make NPCs and turrets face targets.

---

## Phase 11: Data Persistence

### 11.1 DataStore System
**Based on:** BRicey Data Saving and Serialization tutorials

Save player progress, structures, and resources.

### 11.2 Serialization
Convert complex data structures for storage.

---

## Phase 12: Camera Systems

### 12.1 Third Person Camera
**Based on:** BRicey Third Person Camera tutorial

Over-the-shoulder view with collision handling.

### 12.2 Camera Shake
**Based on:** BRicey Camera Shake Effect tutorial

Recoil and impact feedback.

### 12.3 Bezier Curve Cutscenes
**Based on:** BRicey Bezier Curves Camera Cutscene tutorial

Cinematic camera movements.

---

## Phase 13: Networking

### 13.1 RemoteEvents with Sanity Checks
**Based on:** BRicey Remote Events & Functions tutorial

Secure client-server communication.

**Key Principle:** Never trust the client!

---

## Phase 14: Architecture Patterns

### 14.1 OOP with Composition
**Based on:** BRicey Composition Over Inheritance tutorial

Flexible component-based entities.

### 14.2 Maid/Trove Cleanup
**Based on:** BRicey Cleanup Modules tutorial

Memory leak prevention.

### 14.3 Attributes and Tags
**Based on:** BRicey Attributes and CollectionService tutorials

Custom properties and object organization.

---

## BRicey Technique Mapping (Complete)

| BRicey Technique | Roman Implementation | Issue # |
|------------------|---------------------|---------|
| Procedural Tree Generation | Mediterranean trees | #3-5, #17-19 |
| CFrame Transforms | Aqueduct chaining, roads | #8, #20 |
| CFrame.lookAt() | NPC/turret orientation | #28 |
| Grid Snapping | Roman grid placement | #6 |
| Pivot Point Management | Structure foundations | #7, #17 |
| Branch Tapering | Tree recursion | #17 |
| Random Branch Generation | Vegetation variety | #19 |
| Linear Interpolation | Smooth transitions | #18 |
| Randomized Object Sizing | Foliage variety | #11, #12 |
| Server Storage Pattern | Template storage | #16 |
| Keyboard Input Binding | Construction controls | #13 |
| Euler Angle Rotations | Object orientation | #20 |
| Probability-Based Triggers | Decoration distribution | #11 |
| Hinge Constraints | Gates, doors, catapults | #25 |
| Spring Constraints | Catapult mechanisms | #25 |
| Prismatic Constraints | Elevators, portcullis | #26 |
| AlignPosition/Orientation | Model tweening | #27 |
| FastCast Projectiles | Ballista, pilum | #29 |
| Finite State Machines | NPC AI behavior | #30 |
| DataStore | Player persistence | #31 |
| Third Person Camera | Combat view | #32 |
| Camera Shake | Weapon recoil | #33 |
| Bezier Curves | Cutscenes | #42 |
| RemoteEvents | Networking | #34 |
| Sanity Checks | Exploit prevention | #23, #34 |
| Maid/Trove Cleanup | Memory management | #35 |
| Attributes | Custom properties | #36 |
| CollectionService Tags | Object organization | #37 |
| Perlin Noise | Terrain generation | #38 |
| VectorForce | Physics effects | #39 |
| workspace:Raycast() | Detection, targeting | #40 |
| Composition Pattern | Entity architecture | #41 |
| Region3 | Zone detection | #43 |
| Normal Vectors | Surface placement | #24 |
| Placement Validation | Server-side checks | #23 |

---

## GitHub Issues Reference (43 Total)

### Foundation (Start Here)
- **#22**: Rojo Project Configuration
- **#1**: Undulating Terrain Generation System (CRITICAL)
- **#15**: Shared Utility Modules
- **#16**: Template Assets Setup in ServerStorage
- **#38**: Perlin Noise for Procedural Terrain Details

### Terrain & Water
- **#2**: Roman Water Pools with Part-Built Walls

### Procedural Trees
- **#3**: Procedural Mediterranean Cypress Tree Generator
- **#4**: Procedural Mediterranean Olive Tree Generator
- **#5**: Procedural Mediterranean Stone Pine Generator
- **#17**: Branch Tapering and Pivot Offset System
- **#18**: Linear Interpolation for Progressive Angles
- **#19**: Recursive Branch Generation with Probability

### Placement Systems
- **#6**: Grid Snapping Placement System
- **#7**: Structure Foundation Placement System
- **#23**: Placement Validation System
- **#24**: Normal Vector Surface Placement

### Physics & Constraints
- **#25**: Physics Constraints: Hinges and Springs
- **#26**: Prismatic Constraints: Elevators and Gates
- **#27**: AlignPosition and AlignOrientation for Model Tweening
- **#39**: VectorForce for Physics Effects

### Infrastructure
- **#8**: Aqueduct Segment Chaining System
- **#9**: Roman Road Construction System

### Combat & Projectiles
- **#29**: FastCast Projectile System for Ballista and Pilum
- **#40**: Workspace:Raycast() for Detection and Targeting

### AI & NPCs
- **#30**: Finite State Machine for NPC Behavior
- **#28**: CFrame.lookAt() for Object Orientation
- **#43**: Region3 for Area Detection

### Atmosphere & Effects
- **#10**: Torch and Fire Lighting System
- **#33**: Camera Shake and Recoil Effects

### Decoration & Foliage
- **#11**: Decorative Element Distribution System
- **#12**: Mediterranean Ground Cover and Foliage

### Camera Systems
- **#32**: Third Person Camera System
- **#42**: Bezier Curves for Camera Cutscenes

### UI & Controls
- **#13**: Construction Mode UI System
- **#14**: Object Cycling and Selection System

### Data & Networking
- **#31**: DataStore Persistence for Player Progress
- **#34**: RemoteEvent and RemoteFunction Networking

### Architecture & Patterns
- **#20**: Euler Angle Rotations with CFrame.Angles
- **#21**: Part Anchoring for Static Objects
- **#35**: Maid/Trove Cleanup Pattern
- **#36**: Attributes for Custom Properties
- **#37**: CollectionService Tags for Object Organization
- **#41**: OOP with Composition Over Inheritance

### Recommended Implementation Order (Prioritized)

---

## TIER 1: PROJECT SETUP & TOOLING (Do First)
*These must be completed before any development begins.*

| Order | Issue | Description | Why First? |
|-------|-------|-------------|------------|
| 1 | #22 | Rojo Project Configuration | Required for any code to sync |
| 2 | #15 | Shared Utility Modules | Foundation for all other code |
| 3 | #41 | OOP with Composition | Architecture pattern for all entities |
| 4 | #35 | Maid/Trove Cleanup Pattern | Prevents memory leaks from start |

---

## TIER 2: CORE FOUNDATION (Critical Path)
*The terrain system is the foundation ALL other features build upon.*

| Order | Issue | Description | Why Critical? |
|-------|-------|-------------|---------------|
| 5 | #1 | **Undulating Terrain Generation** | **ALL features depend on terrain height** |
| 6 | #38 | Perlin Noise for Terrain | Makes terrain look natural |
| 7 | #40 | Workspace:Raycast() | Core detection used everywhere |
| 8 | #21 | Part Anchoring | Prevents physics chaos |
| 9 | #20 | Euler Angle Rotations | Core math for positioning |
| 10 | #28 | CFrame.lookAt() | Orientation for NPCs, objects |

---

## TIER 3: ROMAN ATMOSPHERE (Theme Essential)
*Features that make it FEEL like Ancient Rome.*

| Order | Issue | Description | Roman Theme Impact |
|-------|-------|-------------|-------------------|
| 11 | #2 | Roman Water Pools | Thermae, impluvium - iconic Roman |
| 12 | #10 | Torch and Fire Lighting | Atmospheric Roman lighting |
| 13 | #3 | Cypress Tree Generator | Iconic Roman landscape |
| 14 | #17-19 | Tree Techniques (tapering, lerp, recursion) | Support for #3-5 |
| 15 | #4, #5 | Olive and Stone Pine Trees | Mediterranean vegetation |
| 16 | #12 | Ground Cover and Foliage | Landscape filling |
| 17 | #9 | Roman Road Construction | Via - essential Roman infrastructure |
| 18 | #8 | Aqueduct Segment Chaining | Iconic Roman engineering |

---

## TIER 4: CORE GAMEPLAY MECHANICS
*Features that enable actual gameplay.*

| Order | Issue | Description | Gameplay Impact |
|-------|-------|-------------|-----------------|
| 19 | #6 | Grid Snapping Placement | Building system foundation |
| 20 | #7 | Structure Foundation System | Place buildings on terrain |
| 21 | #23 | Placement Validation | Prevent exploits/bugs |
| 22 | #24 | Normal Vector Surface Placement | Wall decorations, torches |
| 23 | #16 | Template Assets in ServerStorage | Building blocks for placement |
| 24 | #36 | Attributes for Custom Properties | Data on placed objects |
| 25 | #37 | CollectionService Tags | Organize game objects |

---

## TIER 5: INTERACTIVITY & PHYSICS
*Make the world feel alive and interactive.*

| Order | Issue | Description | Interactivity |
|-------|-------|-------------|---------------|
| 26 | #25 | Hinges and Springs | Gates, catapults, doors |
| 27 | #26 | Prismatic Constraints | Portcullis, elevators |
| 28 | #27 | AlignPosition/Orientation | Moving ships, siege equipment |
| 29 | #39 | VectorForce | Catapult physics, explosions |
| 30 | #11 | Decorative Element Distribution | Populate the world |
| 31 | #43 | Region3 for Area Detection | Zone-based gameplay |

---

## TIER 6: COMBAT SYSTEM
*Roman military gameplay.*

| Order | Issue | Description | Combat Feature |
|-------|-------|-------------|----------------|
| 32 | #29 | FastCast Projectile System | Ballista, pilum, scorpio |
| 33 | #30 | Finite State Machine for NPCs | Guard AI, patrols |
| 34 | #33 | Camera Shake | Weapon feedback |

---

## TIER 7: PLAYER EXPERIENCE
*Camera, UI, and user interaction.*

| Order | Issue | Description | UX Impact |
|-------|-------|-------------|-----------|
| 35 | #32 | Third Person Camera | Core player view |
| 36 | #13 | Construction Mode UI | Building interface |
| 37 | #14 | Object Cycling System | Select what to build |
| 38 | #42 | Bezier Curve Cutscenes | Cinematic moments |

---

## TIER 8: NETWORKING & PERSISTENCE
*Multiplayer and saving (can be added later).*

| Order | Issue | Description | Online Feature |
|-------|-------|-------------|----------------|
| 39 | #34 | RemoteEvent Networking | Client-server communication |
| 40 | #31 | DataStore Persistence | Save player progress |

---

## Quick Reference: Issue Priority Labels

**CRITICAL (Must Have):**
#22, #15, #1, #38, #40, #21, #34

**HIGH (Core Experience):**
#2, #3, #6, #7, #10, #20, #28, #29, #30

**MEDIUM (Enhanced Experience):**
#4, #5, #8, #9, #11, #12, #16, #17-19, #23-27, #32, #36, #37

**LOW (Polish):**
#13, #14, #31, #33, #35, #39, #41-43

---

*This implementation plan adapts all 100 BRicey tutorial techniques to create an authentic Ancient Roman experience in "Legions & Cycles."*
