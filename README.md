# 🐢 Bao-bao: Barangay Pursuit
**A top-down 2D driving action game built in Godot 4.**

Navigate the streets of the barangay in your trusty "Bao-bao" tricycle while evading the persistent (and sometimes frustrated) LTO units.

---

## 🛠️ AAAA+ Technical Specifications

### 1. The World Engine
* **Engine:** Godot 4.x (2D)
* **The "Golden Offset":** `Vector2(-660, -48)` 
  * *Critical for syncing the JSON-generated map with the Tilemap system.*
* **Map Infrastructure:** Roads are defined by `Path2D` nodes belonging to the `"Roads"` group.

### 2. The LTO (Police) AI Logic
The LTO units operate on a deterministic State Machine to ensure challenging but fair gameplay.

* **States:**
  * `PATROL`: Follows road "rails" at `220.0` speed.
  * `PURSUIT`: Aggressive chase at `380.0` speed using friction-based steering.
  * `RECOVERING`: Triggered when the unit is stuck; performs a reverse "wiggle."
  * `BUSTED`: Triggered on player collision; leads to a scene reset.

* **"Smarter Popo" Stuck Detection:**
  * **Check Interval:** Every 1.0 second.
  * **Stuck Threshold:** If distance moved is `< 25.0px`, `stuck_timer` increases.
  * **The Wiggle Rule:** After 2.0s of being stuck, the unit attempts a `1.5s` recovery wiggle.
  * **Emergency Respawn:** If the unit fails to break free after **2 wiggle attempts**, it teleports to the nearest valid road point.

* **Acoustics & Visuals:**
  * **Engine:** Dynamic pitch shifting (`0.8` to `1.4`) based on velocity.
  * **Sirens:** Currently **DISABLED** (Silent Patrol Mode) to ensure neighborhood peace during development.
  * **Radar Sync:** `detection_range` automatically matches the radius of the `DetectionZone` circle in the Godot Editor.

---

## 🗺️ Development Roadmap

### ✅ Phase 1: Foundations (Completed)
- [x] Top-down driving physics for Bao-bao.
- [x] JSON-based map generation with precise offsets.
- [x] Road-following "Rail System" for LTO patrol.
- [x] Advanced Stuck-Detection and Emergency Respawn for AI.

### 🏎️ Phase 2: The "Juice" (In Progress)
- [ ] **Muffler Pops:** Random backfire sounds and fire particles for the tricycle.
- [ ] **Screen Shake:** Dynamic camera rattle during high-speed chases.
- [ ] **Tire Smoke:** Drift particles and skid marks.
- [ ] **Siren Restoration:** Bug-free, state-locked siren logic.

### 🌟 Phase 3: The Game Loop
- [ ] **Wanted Level UI:** Classic HUD to track pursuit intensity.
- [ ] **Barangay Props:** Destructible fruit stands, trash cans, and wandering chickens.
- [ ] **Objectives:** Deliveries or time trials while avoiding the LTO.

---

## 📂 Asset Registry
* **Audio:** `EngineAudio` (Looping), `SirenAudio` (Looping/Deactivated).
* **Nodes:** `SirenRed`, `SirenBlue` (PointLight2D), `DetectionZone` (Area2D).

---
*Created with 🧠 by the Bao-bao Dev Team.*
