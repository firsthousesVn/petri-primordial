# Petri-Primordial — Current State

Snapshot date: 2026-04-29
Scope: current repository/runtime state. This file is descriptive only.

## Working Tree

### Modified tracked files
- `project.godot`
- `scenes/petri/PetriDish.tscn`
- `scripts/petri/PetriDish.gd`

### Untracked project files
- `docs/*`
- `resources/cells/*.tres`
- `scenes/petri/CellBody.tscn`
- `scripts/petri/Bond.gd`
- `scripts/petri/CellBody.gd`
- `scripts/petri/CellHotbar.gd`
- `scripts/petri/CellPort.gd`
- `scripts/petri/CellSignature.gd`
- `scripts/petri/MagneticFieldOverlay.gd`
- `scripts/petri/MediumField.gd`
- companion `*.uid` files

## Main Files And Responsibilities

- `scripts/petri/PetriDish.gd`
  - main controller for draw order, input, spawning, HUD, magnetic overlay orchestration, guidance, bonding, clusters, and seedling classification
- `scripts/petri/CellBody.gd`
  - per-cell motion, angular motion, charge/noise state, homeostasis, ports, and geometry-specific behavior
- `scripts/petri/Bond.gd`
  - bond data container
- `scripts/petri/CellSignature.gd`
  - resource schema for geometry/material/charge/rhythm/storage tags
- `scripts/petri/MediumField.gd`
  - ambient dish field and F1/F2/F3 debug overlays
- `scripts/petri/CellHotbar.gd`
  - player-facing roster strip and selection state
- `scripts/petri/MagneticFieldOverlay.gd`
  - separate overlay node that draws magnetic visuals above cells

## Current Player-Facing Roster

Signatures preloaded in `PetriDish.gd`:
- `SIG_ROUND` -> Sphere
- `SIG_TRIANGLE` -> Triangle
- `SIG_LINE` -> legacy Line
- `SIG_CRESCENT` -> Crescent
- `SIG_COIL` -> Coil

Current active roster comes from `_active_cell_kinds()`.
Current defaults:
- `ENABLE_LEGACY_LINE_CELL = false`
- `ENABLE_STARTUP_AUTOSPAWN = false`

That means the hotbar / number-key order is:
1. `Sphere`
2. `Triangle`
3. `Crescent`
4. `Coil`

`Line` code paths still exist, but `Line` is hidden from normal player selection while the legacy flag is false.

## Spawning

Main functions in `scripts/petri/PetriDish.gd`:
- `_active_cell_kinds()`
- `_hotbar_entries()`
- `_selected_signature_template()`
- `_spawn_cells(n)`
- `_create_cell(template, spawn_pos)`
- `_spawn_selected_cell_at(local_pos)`
- `_try_spawn_selected_cell_at(local_pos)`
- `_finish_spawned_cell(cell, spawn_pos)`
- `_is_spawn_position_valid(local_pos)`
- `_should_ignore_duplicate_spawn(local_pos)`
- `_delete_nearest_cell_at(local_pos)`

Current defaults:
- `SPAWN_COUNT = 0`
- `ENABLE_STARTUP_AUTOSPAWN = false`

Important detail:
- `_spawn_cells()` now follows `_active_cell_kinds()`, so hidden legacy `Line` does not leak into the default startup pool.

## Magnetic Field

### Simulation truth

Main functions in `scripts/petri/PetriDish.gd`:
- `_collect_magnetic_sources()`
- `_magnetic_source_contribution()`
- `_sample_magnetic_field_superposed()`
- `sample_magnetic_field(world_pos)`

Current model:
- `MAG_FIELD_SIM_MODEL = "radial_charge_centers"`
- charged cells contribute center-based softened radial field vectors
- `round` cells contribute at full weight
- non-round cells contribute at reduced weight
- final vector is clamped by `MAG_FIELD_MAX_STRENGTH`

### Visualization truth

Overlay path:
- `scripts/petri/MagneticFieldOverlay.gd::_draw()`
- `scripts/petri/PetriDish.gd::_draw_magnetic_field_on(target)`

Current default visual path:
- `MAG_FIELD_VIS_STYLE = "sphere_attached"`
- `_draw_sphere_attached_field_loops_on()`
- `_visual_polarity_axis()`
- `_sphere_surface_poles()`

Important detail:
- simulation and visualization are not yet unified
- the active overlay is a visual model, not the simulation source of truth

### Legacy magnetic visual branches

Kept for inspection only:
- `ENABLE_MAG_LEGACY_VISUALS = false`
- sampled streamline path
- contour path
- pole-marker path

These helpers still exist but are default-off:
- `_build_visual_poles()`
- `_sample_visual_field()`
- `_visual_line_strength()`
- `_build_visual_seeds()`
- `_trace_visual_field_line()`
- `_trace_visual_branch()`
- `_close_to_terminator()`
- `_draw_field_line_ticks_on()`
- `_draw_magnetic_contours_on()`
- `_draw_visual_pole_marks_on()`

### Magnetic HUD/debug telemetry

When `debug_magnetic_field` is enabled, the HUD shows:
- source count
- nearest sphere charge
- total field strength at mouse
- contributor count at mouse
- total field vector at mouse
- nearest source contribution at mouse
- probe sample near a strong source
- visual primitive counts

## Bonds, Guidance, And Seedlings

Guidance and bond lifecycle live primarily in `scripts/petri/PetriDish.gd`.
Current maintenance defaults:
- `ENABLE_BONDS` is runtime-toggleable
- `ENABLE_EXPERIMENTAL_GUIDANCE = true`
- `ENABLE_SEEDLING_CLASSIFICATION = false`

Seedling classification remains in the codebase, but is now treated as experimental and disabled by default.

## Naming Debt

Current internal geometry names:
- `round` => Sphere
- `wedge` / `triangle` => Triangle
- `spiral` => Coil
- `line` => legacy Line
- `crescent` => Crescent

## Runtime Verification Status

Headless project load was run with:
- `/mnt/c/Users/kxixg/Downloads/Godot_v4.6.1-stable_win64.exe --headless --path . --quit-after 3 --verbose`

Result:
- exit code `0`
- main scene loaded
- no parse/load errors were observed in that headless check

Still unverified:
- visual correctness on the Windows desktop
- player-visible bonding feel
- player-visible magnetic overlay adequacy
- player-visible seedling behavior
