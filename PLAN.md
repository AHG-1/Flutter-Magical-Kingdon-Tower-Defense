# Implementation Plan

**Goal:** Add full feature set as requested:
1. Map/layout redesign with choke points and visual style matching *Sir, We Have an Orc Problem*.
2. Separate dwarf resource zone where dwarves mine gold/wood/stone continuously.
3. Massive horde system with fluid‑like crowd physics and object‑pooling for performance.
4. Active‑skill bar with four AoE spells (Meteor, Frost, Storm, Nuclear) including UI, cooldowns, mouse aiming, screen‑shake and knock‑back.
5. Endless‑wave generator with scaling difficulty and roguelite meta‑progression (persistent resources, permanent upgrades).

**Main files to touch**
- `lib/game.dart` – path data, wave manager, dwarf logic, meta persistence, spell handling.
- `lib/painter.dart` – road drawing, terrain, choke‑points, dwarf zone visuals.
- `lib/visuals.dart` – dwarf sprite, spell UI, skill bar widget.
- `lib/pool.dart` (new) – generic object pool for enemies.
- `lib/skill_bar.dart` (new) – widget for active skills.

**High‑level steps**
1. Define new `static const List<List<int>> waypoints` with variable width sections & choke points.
2. Add helper `isPath` / `isChokepoint` methods.
3. Update `BoardPainter._drawTerrain` to use the new waypoints and render a wide road with organic curves.
4. Create `Site` struct and `sites` list (gold, wood, stone) and spawn dwarf workers.
5. Add dwarf drawing in `MineScenePainter` (already exists) and update resource increment each tick.
6. Implement `ObjectPool<Enemy>` in `pool.dart` and modify enemy creation/spawning to use it.
7. Add simple boids‑style lateral offset to enemies for fluid movement.
8. Extend `Game` with `Skill` enum, cooldown timers, `armed` handling, and mouse input to cast spells.
9. Add `SkillBar` widget in `skill_bar.dart` and include it in the UI hierarchy (probably in `main.dart`).
10. Replace fixed wave logic with `nextWave()` that scales enemy count, hp, speed.
11. Add persistent meta data (`metaRes`, `unlockedTowers`) saved via `storage_io.dart`.
12. Update UI to show permanent upgrades and resource counts.

We will now apply these changes step by step, starting with the map redesign.