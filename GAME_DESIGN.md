# Legions & Cycles: Ancient Rome - Game Design Document

## Genre
**Simulator/Tycoon** - Build and manage a Roman civilization

---

## Core Experience
Rome already exists - grand landmarks, crumbling ruins, ancient aqueducts. You build YOUR piece of it. Place homes, shops, and baths in the shadow of the Colosseum. Explore the Mediterranean landscape and create a thriving Roman community.

---

## Similar Games
| Game | Similarity |
|------|------------|
| Theme Park Tycoon 2 | Build structures, expand, manage |
| Bloxburg | Build houses, explore, social |
| Islands | Resource gathering, building progression |
| Brookhaven | Explorable town, roleplay elements |
| Build A Boat | Creative building with purpose |

---

## Core Loop (One Sentence)

**Build → Expand → Manage**

| Phase | Player Action | Reward |
|-------|---------------|--------|
| Build | Place Roman structures (Domus, Taberna, Temple) | See your creation appear |
| Expand | Unlock new areas, add roads connecting buildings | Growing settlement |
| Manage | Maintain structures, optimize layout, progress | Coins, unlocks, achievements |

---

## The First 10 Seconds

### Spawn Location
- **Where**: Southeast hilltop (400, terrain_height, 400)
- **Facing**: Northwest toward map center
- **Vibe**: Overlooking YOUR land - "This is yours to build"

### First Thing You See
- **Colosseum** in the distance (east)
- **Aqueduct** spanning the valley (some sections ruined)
- **Fallen columns** and ruins scattered on nearby hills
- Rolling Mediterranean terrain with warm lighting
- A fountain nearby (water demo)
- **Implicit message**: "Rome exists. Build YOUR place in it."

### UI/Interface (Mobile-First)
| Element | Purpose | Position |
|---------|---------|----------|
| Coins/Currency | What you can spend | Top-left |
| Build Button | Primary action | Bottom-center (large, thumb-friendly) |
| Menu | Settings, inventory | Top-right |
| Mini-map | Navigation | Bottom-right corner |

### First Interaction
- **Tap anywhere on ground** → Build placement mode
- **First free structure**: Small Taberna (shop) - teaches build mechanic
- **Reward**: Coins start generating

### Sound/Music
- Ambient Roman music (already implemented)
- **Feel**: Chill, atmospheric, grand but relaxing
- Not intense - this is a building game, not combat

---

## World Building Elements

### Terrain
- **Size**: 1024x1024 studs (large, explorable)
- **Style**: Mediterranean - rolling hills, valleys
- **Materials**: Balanced grass, rock, sand, ground (issue #70)
- **Feel**: Authentic Italian peninsula landscape

### World Content (Pre-Built)
Impressive from the start - players don't build these:

| Category | Examples | Purpose |
|----------|----------|---------|
| **Landmarks** | Colosseum, Pantheon, Forum, Circus Maximus | Exploration, backdrop, NPC hubs |
| **Ruins** | Fallen columns, crumbling walls, debris | Atmosphere, history |
| **Aqueduct** | Functional + ruined sections | Iconic engineering, water source |

### Player-Built Structures
What players actually build on their plots:

| Category | Examples | Progression |
|----------|----------|-------------|
| **Commercial** | Taberna (shop) | Level 1 (free starter) |
| **Residential** | Domus (house), Insula (apartments) | Level 2-10 |
| **Religious** | Small temple, shrine | Level 5-15 |
| **Civic** | Thermae (baths), Triumphal arch | Level 10-20 |

**All explorable structures have:**
- Multiple doorways (2+ entrances, no doors blocking)
- Explorable interiors with directional lighting
- Stairs for multi-story
- Rooftop access where appropriate

### Spawn
- Hilltop vantage point
- Overlooks build area
- Near starting resources/tutorial

### Boundaries
- Tall glass walls (200 studs) - can see out, can't fall off
- Creates contained play area
- Roman "edge of the known world" feeling

### Places/Zones
| Zone | What's There | Player Activity |
|------|--------------|-----------------|
| **Player Plots** | Empty buildable land | Build your structures |
| **Forum District** | Pre-built Roman Forum | Explore, NPC hub |
| **Colosseum Area** | Pre-built Colosseum | Explore, events |
| **Palatine Hill** | Pre-built palaces | Explore, roleplay |
| **Aqueduct Valley** | Aqueduct (functional + ruins) | Explore, water source |
| **Ruin Fields** | Scattered ruins | Explore, atmosphere |

**All zones accessible from start.** Progression unlocks what you can BUILD, not where you can GO.

---

## Technical Elements

| Element | Implementation | Feel Without It |
|---------|----------------|-----------------|
| Physics | Anchored parts, terrain collision | Floaty, broken |
| 3D Models | Procedural structures, detailed interiors | Empty, boring |
| Animations | Character movement, doors opening | Stiff, dead |
| Sound Effects | Build placement, footsteps, water | Silent, no feedback |
| Music | Ambient Roman soundtrack ✓ | Empty, lifeless |
| Lighting | Day/night cycle, torches | Flat, unimmersive |

---

## Multiplayer Design

**Primary Mode: PARALLEL**
- Same server, separate goals
- Each player builds their own Roman settlement
- Can visit each other's builds
- Shared world, personal progression

**Secondary: SOCIAL**
- Show off builds to friends
- Trading resources/decorations
- Group building projects
- Roleplay in completed structures

**Future: COOPERATIVE**
- Guild/faction system (Roman houses)
- Collaborative mega-structures
- Shared economy

---

## What Makes Players Come Back

| Motivation | Implementation | Hook Strength |
|------------|----------------|---------------|
| **Progression** | Unlock new structure types, expand territory | PRIMARY |
| **Collection** | Build every structure type, achievements | STRONG |
| **Social** | Friends playing, showing off builds | MEDIUM |
| **Completion** | Fill the entire map, perfect city | STRONG |
| **Updates** | New structures, seasonal events | RETENTION |

### Progression System
```
Level 1:     Free Taberna (tutorial)
Level 2-5:   Small Domus, basic decorations
Level 6-10:  Medium Domus, Insula, small Temple
Level 11-15: Large Domus, Thermae, shops variety
Level 16-20: Grand Temple, Triumphal Arch, luxury villa
Level 21+:   Cosmetic unlocks, prestige decorations
```

**Note:** Major landmarks (Colosseum, Pantheon, etc.) are PRE-BUILT world content, not player-buildable. Players build homes and businesses, not rebuild Rome.

---

## Monetization (Optional)

| Type | Examples | Player Perception |
|------|----------|-------------------|
| **Cosmetic** | Marble colors, column styles, banners | Acceptable |
| **Time Skip** | Speed up construction | Acceptable if reasonable |
| **Expansion** | Extra build plots | Acceptable |
| **Pay-to-Win** | ❌ Exclusive powerful structures | AVOID |

### Recommended Model
- **Free to play** with cosmetic Robux shop
- **Game Pass**: "Roman Architect" - bonus decorations, custom colors
- **Developer Products**: Extra coins (reasonable amounts)

---

## Leaderboards

| Leaderboard | Metric | Encourages |
|-------------|--------|------------|
| Richest Romans | Total coins earned | Active play |
| Master Builders | Structures placed | Building |
| Explorers | Structures fully explored | Exploration |
| Collectors | Unique structure types owned | Completion |
| Veterans | Days played | Retention |

---

## Design Validation Checklist

- [x] **Genre clear?** Simulator/Tycoon
- [x] **Core loop simple?** Build → Expand → Manage
- [x] **First 10 seconds planned?** Hilltop spawn, see land, build button
- [x] **Retention hooks?** Progression, collection, social
- [x] **Feel defined?** Chill, grand, immersive Roman
- [x] **Mobile-first?** Large touch targets, simple controls
- [x] **Multiplayer considered?** Parallel with social elements

---

## Quick Reference

**One-liner pitch:**
> "Explore ancient Rome's landmarks and ruins, then build your own corner of the empire."

**Target audience:**
> 8-16 year olds who enjoy building games, history fans, Bloxburg/Tycoon players

**Session length:**
> 15-30 minutes casual, 1+ hours dedicated builders

**Key differentiator:**
> Explorable Roman structures with authentic interiors - not just decorations, but places to BE

---

*This document defines the creative vision. All implementation should align with these principles.*
