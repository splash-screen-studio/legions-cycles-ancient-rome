# Legions & Cycles: Ancient Rome - Implementation Plan

## Game Design Summary
- **Genre**: Simulator/Tycoon
- **Core Loop**: Build → Expand → Manage
- **Platform**: Mobile-first (iPhone/iPad, touch)
- **Feel**: Chill, grand, immersive Roman
- **First Impression**: Landmarks + ruins visible immediately

See `GAME_DESIGN.md` for full design document.

---

## Architecture: Source of Truth Chain

**The key insight:** Systems need partial knowledge of each other without tight coupling.

```
┌─────────────────────────────────────────────────────────────┐
│                    WORLD PLAN (#91)                         │
│         (Single Source of Truth - Created FIRST)            │
│                                                             │
│  • River path          • Zone boundaries                    │
│  • Landmark positions  • Road network                       │
│  • Player plot areas                                        │
└─────────────────────────┬───────────────────────────────────┘
                          │ QUERIES
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ Terrain  │    │  River   │    │Landmarks │
    │ (#1,#93) │    │  (#92)   │    │  (#88)   │
    │          │    │          │    │          │
    │ Lowers   │    │ Fills    │    │ Places   │
    │ river    │    │ path     │    │ pre-built│
    │ corridor │    │          │    │ structs  │
    └────┬─────┘    └──────────┘    └──────────┘
         │
         ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │Materials │    │ Fountains│    │  Ruins   │
    │  (#93)   │    │  (#94)   │    │  (#89)   │
    └──────────┘    └──────────┘    └──────────┘
         │
         ▼
    ┌──────────────────────────────────────────┐
    │           SPATIAL MANAGER (#85)          │
    │      (Runtime registry of placed items)  │
    └──────────────────────────────────────────┘
         │
         ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │Player    │    │  Roads   │    │  NPCs    │
    │Structures│    │  (#9)    │    │  (#86)   │
    └──────────┘    └──────────┘    └──────────┘
```

### Source of Truth Table

| Fact | Source | Consumers |
|------|--------|-----------|
| River location | WorldPlan | Terrain, River, Materials |
| Zone boundaries | WorldPlan | Materials, NPCs, Structures |
| Landmark positions | WorldPlan | Terrain, Structures |
| Terrain height | TerrainManager | Everything |
| What's placed | SpatialManager | Structures, NPCs |

---

## Priority Tiers

### TIER 0: DONE ✅

| Issue | Title | PR |
|-------|-------|-----|
| #1 | Undulating Terrain Generation | #50 |
| #15 | Shared Utility Modules | #46 |
| #22 | Rojo Project Configuration | #45 |
| #35 | Maid/Trove Cleanup Pattern | #47 |
| #41 | OOP with Composition | #48 |
| #49 | Ambient Music System | #51 |
| #54 | BRicey Module Pattern Restructure | #55 |
| #58 | Lune Test Framework | #62 |
| #59 | Player Spawn System | #61 |
| #60 | Water Features (Demo) | #71 |

---

### TIER 1: WORLD FOUNDATION 🗺️
*Must be done FIRST - everything else depends on this*

| Order | Issue | Title | Why First |
|-------|-------|-------|-----------|
| 1 | **#91** | **World Plan System** | Source of truth for ALL placement |
| 2 | #92 | River System | Single structure across map |
| 3 | #93 | Terrain Materials | Context-aware surfaces |
| 4 | #94 | Fountain System | Multiple deep fountains |

**Generation Order:**
1. WorldPlan created (river path, zones, landmarks)
2. Terrain generated (queries WorldPlan → lowers river corridor)
3. River built (follows WorldPlan path)
4. Fountains placed (at WorldPlan positions)
5. Materials applied (queries zones, altitude, proximity)

---

### TIER 2: IMPRESSIVE FIRST VIEW 🏛️
*What players see in first 10 seconds*

| Order | Issue | Title | Visual Impact |
|-------|-------|-------|---------------|
| 5 | #88 | Pre-Built Landmarks | Colosseum, Forum visible |
| 6 | #89 | Ruins System | Fallen columns, atmosphere |
| 7 | #90 | Aqueduct System | Spanning valley, partially ruined |
| 8 | #82 | Atmosphere System | Day/night, weather, fog |

**First view includes:**
- Colosseum in distance
- Aqueduct across valley (some ruined)
- Fallen columns on hills
- River winding through landscape
- Mediterranean lighting

---

### TIER 3: CORE GAMEPLAY 🎮
*The Build → Expand → Manage loop*

| Order | Issue | Title | Loop Phase |
|-------|-------|-------|------------|
| 9 | #78 | Mobile Build UI | BUILD |
| 10 | #6 | Grid Snapping | BUILD |
| 11 | #7 | Structure Foundation | BUILD |
| 12 | #85 | Spatial Manager | BUILD (validation) |
| 13 | #73 | Taberna (First Structure) | BUILD |
| 14 | #79 | Currency System | MANAGE |
| 15 | #80 | Progression System | EXPAND |
| 16 | #81 | Tutorial | Onboarding |

---

### TIER 4: ATMOSPHERE & IMMERSION 🌅

| Order | Issue | Title |
|-------|-------|-------|
| 17 | #83 | Interior Lighting |
| 18 | #84 | Player Lantern |
| 19 | #10 | Torch and Fire |
| 20 | #3 | Cypress Trees |
| 21 | #9 | Roman Roads |

---

### TIER 5: PLAYER STRUCTURES 🏠

| Order | Issue | Title | Type |
|-------|-------|-------|------|
| 22 | #72 | Domus | Residential |
| 23 | #74 | Insula | Residential |
| 24 | #75 | Temple | Religious |
| 25 | #76 | Thermae | Commercial |
| 26 | #77 | Triumphal Arch | Civic |

---

### TIER 6: WORLD LIFE 👥

| Order | Issue | Title |
|-------|-------|-------|
| 27 | #86 | NPC Foundation |
| 28 | #87 | Signpost System |
| 29 | #12 | Ground Cover |

---

### TIER 7: PERSISTENCE & NETWORK 💾

| Order | Issue | Title |
|-------|-------|-------|
| 30 | #31 | DataStore |
| 31 | #34 | RemoteEvents |

---

## Closed/Superseded Issues

| Issue | Reason |
|-------|--------|
| #8 | Superseded by #90 (Aqueduct with ruins) |
| #60 | Demo only, superseded by #92, #94 |
| #70 | Merged into #93 (Terrain Materials) |

---

## Worker Guidance

When implementing any system:

1. **Check WorldPlan first** - Does this system need world layout info?
2. **Query, don't import** - Use SpatialManager/WorldPlan, not direct imports
3. **Register placements** - Tell SpatialManager what you placed
4. **Clear terrain in water** - NO terrain inside part-walled water
5. **Test in isolation** - Module should work without others loaded

---

## Sprint Plan

### Sprint 1: World Foundation
Issues: #91, #92, #93, #94
Goal: River flows, terrain varies, fountains work

### Sprint 2: Impressive View
Issues: #88, #89, #90, #82
Goal: First view is "wow" - landmarks, ruins, atmosphere

### Sprint 3: Core Gameplay
Issues: #78, #6, #7, #73, #79
Goal: Can place Taberna, earn coins

### Sprint 4: Polish
Issues: #83, #84, #86, #87
Goal: World feels alive

---

*Architecture is the foundation. Get WorldPlan right, everything else follows.*
