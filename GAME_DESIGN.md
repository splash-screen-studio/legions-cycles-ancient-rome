# Legions & Cycles: Ancient Rome - Game Design Document

## Genre
**Simulator/Tycoon** - Build and manage a Roman civilization

---

## Core Experience
Build your own piece of Ancient Rome. Place structures, watch your settlement grow, explore the Mediterranean landscape, and create a thriving Roman community.

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
- Rolling Mediterranean hills
- A single fountain (water feature demo)
- Clear sky, warm lighting
- **Implicit message**: "This empty land needs Roman civilization"

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

### Structures (Explorable)
| Category | Examples | Key Feature |
|----------|----------|-------------|
| Landmarks | Colosseum, Pantheon, Forum | Grand scale, tourist attractions |
| Residential | Domus, Insula | Multiple rooms, atriums |
| Commercial | Taberna, Thermae | Generate income |
| Religious | Temple | Community gathering |
| Infrastructure | Aqueducts, Roads, Arches | Connect everything |

**All structures have:**
- Multiple doorways (2+ entrances)
- Explorable interiors
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
| Zone | Terrain | Structures | Unlock |
|------|---------|------------|--------|
| Starting Hill | Grassy valley | Basic structures | Free |
| Forum District | Flat, paved | Shops, Temple | Level 5 |
| Palatine Heights | Elevated | Villas, Palace | Level 10 |
| Circus Valley | Long flat | Circus Maximus | Level 15 |
| Colosseum Grounds | Arena area | Colosseum | Level 20 |

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
Level 1-5:   Basic structures (Taberna, small Domus)
Level 6-10:  Medium structures (Temple, Insula)
Level 11-15: Large structures (Forum, Thermae)
Level 16-20: Landmarks (Colosseum, Pantheon)
Level 21+:   Legendary structures, customization
```

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
> "Build your own Ancient Rome - place structures, explore interiors, grow your civilization."

**Target audience:**
> 8-16 year olds who enjoy building games, history fans, Bloxburg/Tycoon players

**Session length:**
> 15-30 minutes casual, 1+ hours dedicated builders

**Key differentiator:**
> Explorable Roman structures with authentic interiors - not just decorations, but places to BE

---

*This document defines the creative vision. All implementation should align with these principles.*
