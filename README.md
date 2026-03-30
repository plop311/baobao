🐢 Bao-bao: Barangay Pursuit

A top-down 2D driving action game built in Godot 4.

Navigate the streets of the barangay in your trusty "Bao-bao" tricycle while evading the persistent (and sometimes frustrated) LTO units.

🛠️ AAAA+ Technical Specifications

1. The World Engine

Engine: Godot 4.x (2D)

The "Golden Offset": Vector2(-660, -48)

Critical for syncing the JSON-generated map with the Tilemap system.

Map Infrastructure: Roads are defined by Path2D nodes belonging to the "Roads" group.

2. The LTO (Police) AI Logic

The LTO units operate on a deterministic State Machine to ensure challenging but fair gameplay.

States:

PATROL: Follows road "rails" at 220.0 speed.

PURSUIT: Aggressive chase at 380.0 speed using friction-based steering.

RECOVERING: Triggered when the unit is stuck; performs a reverse "wiggle."

BUSTED: Triggered on player collision; leads to a scene reset.

"Smarter Popo" Stuck Detection:

Check Interval: Every 1.0 second.

Stuck Threshold: If distance moved is < 25.0px, stuck_timer increases.

The Wiggle Rule: After 2.0s of being stuck, the unit attempts a 1.5s recovery wiggle.

Emergency Respawn: If the unit fails to break free after 2 wiggle attempts, it teleports to the nearest valid road point.

3. The Chaos Meter (Scoring System)

Dynamic Scoring: Points are awarded in real-time based on your velocity.

Backfire Bonus: Every mechanical exhaust pop adds a flat +50 to your Chaos Score.

UI Integration: A bright yellow HUD (Heads-Up Display) tracked via a high-priority CanvasLayer (Layer 10) ensures your score is always visible.

4. PIP GPS Navigation (Minimap)

SubViewport Architecture: A high-altitude "Spy Camera" renders a real-time 250x250 minimap.

Independent World Sync: Uses a "Magic Link" script to render the main game world without hijacking the player's primary camera.

Dynamic Speed Zoom: The GPS automatically pulls back as you reach high speeds, zooming in for precision during slow crawls.

5. Audio Aesthetic: Industrial Rhythmic Avant-Garde Noise

The Happy Accident: A fusion of Amiga 500-era crunchy sampling and heavy mechanical foley.

Sound Profile: * Engine Idle: Low-fi 8-bit chugging.

Gear Shifts: Sharp, resonant metallic clunks.

Backfires: Rapid-fire white noise bursts modeled after a machine gun.

🗺️ Development Roadmap

✅ Phase 1: Foundations (Completed)

[x] Top-down driving physics for Bao-bao.

[x] JSON-based map generation with precise offsets.

[x] Road-following "Rail System" for LTO patrol.

[x] Advanced Stuck-Detection and Emergency Respawn for AI.

🏎️ Phase 2: The "Juice" (In Progress)

[x] Muffler Pops: Random backfire sounds and fire particles wired to throttle release.

[x] New Genre: Custom Industrial soundtrack and foley effects.

[ ] Screen Shake: Dynamic camera rattle during high-speed chases.

[ ] Tire Smoke: Drift particles and skid marks.

[ ] Siren Restoration: Bug-free, state-locked siren logic.

🌟 Phase 3: The Game Loop (In Progress)

[x] PIP Navigation: Functional SubViewport GPS minimap.

[x] Wanted Level UI: High-visibility Chaos Meter tracking pursuit intensity.

[ ] Barangay Props: Destructible fruit stands, trash cans, and wandering chickens.

[ ] Objectives: Deliveries or time trials while avoiding the LTO.

📂 Asset Registry

Audio: EngineAudio, HornSound, BackfireSound, GearShiftSound.

Nodes: SubViewportContainer (Minimap), ScoreLabel (Chaos Meter), DetectionZone.

Scripts: player.gd, minimap_camera.gd, scoreboard.gd, world.gd.

Created with 🧠 by the Bao-bao Dev Team.
Developed with Gemini 3.1-Flash-lite-Preview – "Where the mouse meets the bucket of milk." 🧀🐭🥛
