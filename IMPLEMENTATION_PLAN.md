# Legions & Cycles: Ancient Rome - Implementation Plan

## Game Design Summary
- **Genre**: Simulator/Tycoon
- **Core Loop**: Build → Expand → Manage
- **Platform**: Mobile-first (iPhone/iPad, touch)
- **Feel**: Chill, grand, immersive Roman

See `GAME_DESIGN.md` for full design document.

---

## Priority Tiers

### TIER 0: DONE ✅
*Completed and merged*

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

---

### TIER 1: FIRST 10 SECONDS 🎯
*What players experience immediately - HIGHEST PRIORITY*

| Order | Issue | Title | Why Critical |
|-------|-------|-------|--------------|
| 1 | #60 | Water Features (Fountain) | First visual landmark |
| 2 | #82 | Atmosphere System | Sets visual mood immediately |
| 3 | #78 | Mobile Build UI | Primary interaction method |
| 4 | #81 | First-Time Tutorial | Hook players in 60 seconds |
| 5 | #70 | Mediterranean Terrain Materials | Visual authenticity |

---

### TIER 2: CORE BUILDING SYSTEM 🏗️
*The BUILD phase of core loop*

| Order | Issue | Title | Why Critical |
|-------|-------|-------|--------------|
| 6 | #6 | Grid Snapping Placement | Foundation of building |
| 7 | #7 | Structure Foundation System | Place structures on terrain |
| 8 | #16 | Template Assets Setup | Building blocks to place |
| 9 | #85 | Spatial Coordination System | Systems work together |
| 10 | #23 | Placement Validation | Prevent invalid placements |
| 11 | #73 | Taberna (First Structure) | Free starter structure |

---

### TIER 3: ECONOMY & PROGRESSION 💰
*The MANAGE phase - keeps players engaged*

| Order | Issue | Title | Why Critical |
|-------|-------|-------|--------------|
| 12 | #79 | Currency System | Buy structures |
| 13 | #80 | Progression System | Unlock new structures |
| 14 | #31 | DataStore Persistence | Save progress |
| 15 | #34 | RemoteEvent Networking | Client-server communication |

---

### TIER 4: ATMOSPHERE & IMMERSION 🌅
*Makes it FEEL like Ancient Rome*

| Order | Issue | Title | Why Critical |
|-------|-------|-------|--------------|
| 16 | #83 | Interior Lighting | Structures feel real |
| 17 | #84 | Player Lantern | Night exploration |
| 18 | #10 | Torch and Fire Lighting | Roman atmosphere |
| 19 | #3 | Cypress Trees | Iconic Roman landscape |
| 20 | #9 | Roman Roads | Connect everything |

---

### TIER 5: EXPAND CONTENT 🏛️
*More structures to build*

| Order | Issue | Title | Category |
|-------|-------|-------|----------|
| 21 | #72 | Domus (House) | Residential |
| 22 | #74 | Insula (Apartments) | Residential |
| 23 | #75 | Temple | Religious |
| 24 | #76 | Thermae (Baths) | Commercial |
| 25 | #77 | Triumphal Arch | Infrastructure |
| 26 | #63 | Large Structure System | Foundation for landmarks |
| 27 | #8 | Aqueduct System | Infrastructure |

---

### TIER 6: LANDMARKS 🏟️
*Major attractions - unlocked at higher levels*

| Order | Issue | Title | Unlock Level |
|-------|-------|-------|--------------|
| 28 | #65 | Roman Forum | Level 5 |
| 29 | #66 | Pantheon | Level 10 |
| 30 | #64 | Colosseum | Level 20 |
| 31 | #68 | Circus Maximus | Level 15 |
| 32 | #67 | Palatine Hill | Level 10 |
| 33 | #69 | Appian Way | Level 8 |

---

### TIER 7: WORLD LIFE 👥
*NPCs, navigation, polish*

| Order | Issue | Title | Purpose |
|-------|-------|-------|---------|
| 34 | #86 | NPC Foundation System | City feels alive |
| 35 | #87 | Signpost System | Navigation |
| 36 | #12 | Ground Cover & Foliage | Visual polish |
| 37 | #4 | Olive Trees | Vegetation variety |
| 38 | #5 | Stone Pine Trees | Vegetation variety |
| 39 | #11 | Decorative Distribution | Fill empty spaces |

---

### TIER 8: ADVANCED FEATURES 🔧
*Nice to have, lower priority*

| Issue | Title | Priority |
|-------|-------|----------|
| #32 | Third Person Camera | Medium |
| #36 | Attributes System | Medium |
| #37 | CollectionService Tags | Medium |
| #42 | Bezier Camera Cutscenes | Low |
| #43 | Region3 Detection | Low |

---

### TIER 9: COMBAT (DEPRIORITIZED) ⚔️
*Not core to tycoon - implement later if at all*

| Issue | Title | Notes |
|-------|-------|-------|
| #29 | FastCast Projectiles | For ballista mini-game? |
| #30 | NPC State Machine | Already covered in #86 |
| #33 | Camera Shake | Combat feedback |

---

## System Dependencies

```
                    ┌─────────────────┐
                    │  Terrain (#1)   │ ✅ DONE
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
       ┌──────────┐   ┌──────────┐   ┌──────────┐
       │ Water    │   │ Spatial  │   │ Atmosphere│
       │ (#60)    │   │ (#85)    │   │ (#82)    │
       └────┬─────┘   └────┬─────┘   └────┬─────┘
            │              │              │
            │              ▼              │
            │    ┌─────────────────┐      │
            └───►│ Grid Placement  │◄─────┘
                 │ (#6, #7)        │
                 └────────┬────────┘
                          │
              ┌───────────┼───────────┐
              │           │           │
              ▼           ▼           ▼
       ┌──────────┐ ┌──────────┐ ┌──────────┐
       │Structures│ │  Roads   │ │ Interior │
       │(#72-77)  │ │  (#9)    │ │ Lighting │
       └──────────┘ └──────────┘ │ (#83)    │
                                 └──────────┘
```

---

## Coordination Rules

All systems use **SpatialManager (#85)** for awareness:

| Query | Used By |
|-------|---------|
| `canPlaceStructure()` | Build UI, Structure placement |
| `canPlaceRoad()` | Road construction |
| `isNearRoad()` | Structure placement hints |
| `isPlayerIndoors()` | Lantern, lighting |
| `getZoneAt()` | Unlocks, NPCs |

**Rule**: Systems MUST NOT import each other directly. Use SpatialManager.

---

## Sprint Suggestions

### Sprint 1: Playable Demo (Issues 1-11)
Goal: Player can spawn, see world, place one structure
- Water fountain visible
- Build button works
- Can place Taberna
- Tutorial guides player

### Sprint 2: Economy Loop (Issues 12-15)
Goal: Earn coins, buy more structures
- Coins earned from structures
- Can buy new structures
- Progress saves

### Sprint 3: Atmosphere (Issues 16-20)
Goal: World feels like Rome
- Day/night cycle
- Interior lighting
- Torches at night
- Roads connect structures

### Sprint 4: Content Expansion (Issues 21-33)
Goal: Full structure variety
- All small structures
- All landmarks
- Zone unlocking

### Sprint 5: Polish (Issues 34-39)
Goal: World feels alive
- NPCs populate city
- Vegetation fills gaps
- Navigation aids

---

## Mobile-First Checklist

Every feature must pass:
- [ ] Works with touch only (no keyboard)
- [ ] UI elements thumb-accessible
- [ ] Performance acceptable on iPad
- [ ] No tiny tap targets
- [ ] Clear visual feedback

---

## Historical Accuracy Notes

| Element | Authentic | Avoid |
|---------|-----------|-------|
| Architecture | Columns, arches, atriums | Medieval castles |
| Materials | Marble, brick, terracotta | Steel, glass |
| Climate | Mediterranean, arid | Lush forests, snow |
| Colors | Warm earth tones | Neon, bright colors |
| Names | Latin (Via, Thermae) | English names |

---

*Last updated: Based on GAME_DESIGN.md decisions*
