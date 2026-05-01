# Magnetic Field Audit

Audit date: 2026-04-29
Scope: magnetic-field system only. This document maps the current code exactly. It does not propose a redesign.

## Classification Legend

- `ACTIVE_RUNTIME`: live in the current project path and participates in runtime behavior or debug flow with current configuration.
- `ACTIVE_VISUAL_ONLY`: live draw/debug path; affects magnetic visuals only.
- `ACTIVE_SIMULATION_ONLY`: live simulation path; does not draw visuals.
- `LEGACY_OR_DEAD`: currently gated off, replaced, or effectively dormant under present constants.
- `UNKNOWN_NEEDS_RUNTIME_CHECK`: wired in code, but practical cost or adequacy still needs live inspection.

## Executive Summary

Simulation source of truth:
- `scripts/petri/PetriDish.gd::sample_magnetic_field(world_pos)`
- Backend: `_sample_magnetic_field_superposed()` over sources from `_collect_magnetic_sources()`
- Model: center-based softened charge superposition

Visualization source of truth:
- `scripts/petri/MagneticFieldOverlay.gd::_draw()`
- `scripts/petri/PetriDish.gd::_draw_magnetic_field_on(target)`
- Default renderer: `_draw_sphere_attached_field_loops_on()`
- Model: sphere-attached dipole-style loops derived from `_visual_polarity_axis()` and `_sphere_surface_poles()`

Core mismatch:
- Simulation samples radial center sources.
- Visualization draws oriented pole-based loops.
- Coil spin and sphere homeostasis consume simulation samples, not the visual dipole model.

## 1. Current Magnetic Call Graph

### Simulation

`CellBody._apply_coil_field_spin()`
-> `CellBody._sample_round_magnetic_strength()`
-> `PetriDish.sample_magnetic_field()`
-> `PetriDish._sample_magnetic_field_superposed()`
-> `PetriDish._magnetic_source_contribution()`
with sources from `PetriDish._collect_magnetic_sources()`

`CellBody._apply_round_homeostasis()`
-> `CellBody._sample_round_magnetic_strength()`
-> `PetriDish.sample_magnetic_field()`
-> same sampler stack above

`PetriDish._update_magnetic_debug_probe()`
-> `PetriDish._collect_magnetic_sources()`
-> `PetriDish._sample_magnetic_field_superposed()`

`PetriDish._draw_magnetic_contours_on()`
-> `PetriDish.sample_magnetic_field()`
-> same sampler stack above

### Visualization

`MagneticFieldOverlay._draw()`
-> `PetriDish._draw_magnetic_field_on()`

Inside `_draw_magnetic_field_on()` with current defaults:
- reset magnetic debug counters via `_reset_magnetic_debug_state()`
- return early unless `debug_magnetic_field` is on
- update real sampler telemetry via `_update_magnetic_debug_probe()`
- draw sphere-attached loops when `MAG_FIELD_VIS_STYLE == "sphere_attached"`
- keep legacy pole/streamline/contour/marker branches behind `ENABLE_MAG_LEGACY_VISUALS`

Legacy visual subgraph, currently default-off:
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

## 2. Which Function Actually Answers “What Is The Field At This Point?”

Primary answer:
- `PetriDish.sample_magnetic_field(world_pos)` -> `ACTIVE_SIMULATION_ONLY`

Calculation backend:
- `PetriDish._sample_magnetic_field_superposed(world_pos, sources)` -> `ACTIVE_SIMULATION_ONLY`

Source construction:
- `PetriDish._collect_magnetic_sources()` -> `ACTIVE_SIMULATION_ONLY`

Per-source contribution:
- `PetriDish._magnetic_source_contribution(world_pos, source)` -> `ACTIVE_SIMULATION_ONLY`

Important caveat:
- `PetriDish._sample_visual_field(world_pos, poles)` also computes a field-like vector, but only for the dormant visualization-only pole model. It is not the simulation truth.

## 3. Which Functions Only Draw Visuals

Overlay orchestration:
- `MagneticFieldOverlay._draw()` -> `ACTIVE_VISUAL_ONLY`
- `PetriDish._draw_magnetic_field_on()` -> `ACTIVE_VISUAL_ONLY`
- `PetriDish._legacy_magnetic_visuals_enabled()` -> `ACTIVE_VISUAL_ONLY`

Default active renderer:
- `PetriDish._draw_sphere_attached_field_loops_on()` -> `ACTIVE_VISUAL_ONLY`
- `PetriDish._sphere_surface_poles()` -> `ACTIVE_VISUAL_ONLY`
- `PetriDish._visual_polarity_axis()` -> `ACTIVE_VISUAL_ONLY`
- `PetriDish._draw_sphere_field_arc_ticks_on()` -> `ACTIVE_VISUAL_ONLY`
- `PetriDish._magnetic_interaction_activity()` -> `ACTIVE_VISUAL_ONLY`
- `PetriDish._bezier_arc_polyline_steps()` -> `ACTIVE_VISUAL_ONLY`

Legacy visual layers, default-off:
- `PetriDish._build_visual_poles()` -> `LEGACY_OR_DEAD`
- `PetriDish._sample_visual_field()` -> `LEGACY_OR_DEAD`
- `PetriDish._visual_line_strength()` -> `LEGACY_OR_DEAD`
- `PetriDish._build_visual_seeds()` -> `LEGACY_OR_DEAD`
- `PetriDish._trace_visual_field_line()` -> `LEGACY_OR_DEAD`
- `PetriDish._trace_visual_branch()` -> `LEGACY_OR_DEAD`
- `PetriDish._close_to_terminator()` -> `LEGACY_OR_DEAD`
- `PetriDish._draw_field_line_ticks_on()` -> `LEGACY_OR_DEAD`
- `PetriDish._draw_visual_pole_marks_on()` -> `LEGACY_OR_DEAD`
- `PetriDish._draw_magnetic_contours_on()` -> `LEGACY_OR_DEAD`

## 4. Which Functions Create Sphere Poles / Axes

Active pole/axis helpers:
- `PetriDish._visual_polarity_axis(cell)`
  - default axis: `Vector2.UP.rotated(cell.rotation)`
  - if a sphere is crescent-cradled, axis can align to that visual relationship
- `PetriDish._sphere_surface_poles(cell)`
  - returns north/south positions attached to the sphere surface

Legacy pole builder:
- `PetriDish._build_visual_poles()`
  - creates explicit dictionaries for the dormant streamline path
  - can add crescent focus poles for visual shaping

## 5. Which Functions Still Treat Spheres As Radial Charge Sources

Core simulation model:
- `PetriDish._collect_magnetic_sources()`
  - sources are stored at `cell.global_position`
  - `round` gets full weight, non-round gets reduced weight
- `PetriDish._magnetic_source_contribution()`
  - radial contribution from source center with softened inverse falloff
- `PetriDish._sample_magnetic_field_superposed()`
  - vector sum of all source contributions, then clamp
- `PetriDish.sample_magnetic_field()`

Simulation consumers:
- `CellBody._sample_round_magnetic_strength()`
- `CellBody._apply_coil_field_spin()`
- `CellBody._apply_round_homeostasis()`
- `PetriDish._update_magnetic_debug_probe()`
- `PetriDish._draw_magnetic_contours_on()` when legacy contours are enabled

## 6. Which Functions Treat Spheres As Dipoles

Default active visual dipole-style path:
- `PetriDish._visual_polarity_axis()`
- `PetriDish._sphere_surface_poles()`
- `PetriDish._draw_sphere_attached_field_loops_on()`

Dormant dipole/pole path:
- `PetriDish._build_visual_poles()`
- `PetriDish._sample_visual_field()`
- streamline helpers listed above

## 7. Which Paths Cause The Ontology Mismatch

### Mismatch A: center-charge simulation vs pole-based visuals

Simulation side:
- `_collect_magnetic_sources()`
- `_magnetic_source_contribution()`
- `_sample_magnetic_field_superposed()`
- `sample_magnetic_field()`

Visual side:
- `_visual_polarity_axis()`
- `_sphere_surface_poles()`
- `_draw_sphere_attached_field_loops_on()`
- dormant `_build_visual_poles()` and `_sample_visual_field()`

### Mismatch B: simulation consumers use magnitude, not visual directionality

- `CellBody._sample_round_magnetic_strength()` converts the vector field to magnitude ratio
- `CellBody._apply_coil_field_spin()` uses that scalar strength, not vector direction
- `CellBody._apply_round_homeostasis()` samples scalar magnitude around the sphere

### Mismatch C: crescents shape visuals more than simulation

Visual side:
- `_find_visual_focus_partner()`
- `_visual_polarity_axis()`
- dormant `_build_visual_poles()` can create crescent focus poles

Simulation side:
- `_collect_magnetic_sources()` gives non-round cells only reduced scalar weight
- no reflector/aperture model exists in `sample_magnetic_field()`

### Mismatch D: contours would mix models if re-enabled

- `_draw_magnetic_contours_on()` samples the simulation field
- `_draw_sphere_attached_field_loops_on()` uses the dipole-style visual model

## 8. Which Paths Should Be Frozen

Freeze until the target magnetic ontology is agreed and runtime behavior is verified:
- `PetriDish.sample_magnetic_field()`
- `PetriDish._sample_magnetic_field_superposed()`
- `PetriDish._collect_magnetic_sources()`
- `CellBody._sample_round_magnetic_strength()`
- `CellBody._apply_coil_field_spin()`
- `CellBody._apply_round_homeostasis()`
- `PetriDish._draw_magnetic_field_on()`
- `PetriDish._draw_sphere_attached_field_loops_on()`

Reason:
- These are the real meeting points between simulation, debug truth, and visible magnetic grammar.

## 9. Which Paths Are Safe To Disable Later

Likely safe to disable later after one visual path is chosen:
- `_build_visual_poles()` and the streamline helpers
- `_draw_field_line_ticks_on()`
- `_draw_magnetic_contours_on()`
- `_draw_visual_pole_marks_on()`
- constants that exist only for those gated branches

Caution:
- Safe to disable later is not the same as safe to delete now.
- These branches still preserve intent for future unification work.

## 10. Function / Path Classification Table

Simulation truth:
- `MAG_FIELD_STRENGTH` -> `ACTIVE_SIMULATION_ONLY`
- `MAG_FIELD_ROUND_WEIGHT` -> `ACTIVE_SIMULATION_ONLY`
- `MAG_FIELD_OTHER_WEIGHT` -> `ACTIVE_SIMULATION_ONLY`
- `MAG_FIELD_SOFTEN_RADIUS` -> `ACTIVE_SIMULATION_ONLY`
- `MAG_FIELD_MAX_STRENGTH` -> `ACTIVE_SIMULATION_ONLY`
- `MAG_FIELD_SIM_MODEL` -> `ACTIVE_RUNTIME`
- `_collect_magnetic_sources()` -> `ACTIVE_SIMULATION_ONLY`
- `_magnetic_source_contribution()` -> `ACTIVE_SIMULATION_ONLY`
- `_sample_magnetic_field_superposed()` -> `ACTIVE_SIMULATION_ONLY`
- `sample_magnetic_field()` -> `ACTIVE_SIMULATION_ONLY`

Runtime debug truth:
- `debug_magnetic_field` -> `ACTIVE_RUNTIME`
- `_reset_magnetic_debug_state()` -> `ACTIVE_RUNTIME`
- `_update_magnetic_debug_probe()` -> `ACTIVE_RUNTIME`
- `_magnetic_debug_hud_lines()` -> `ACTIVE_RUNTIME`
- `_mag_debug_*` counters -> `ACTIVE_RUNTIME`
- `_update_debug()` magnetic HUD section -> `ACTIVE_RUNTIME`

Overlay entry and default renderer:
- `MagneticFieldOverlay` node/script -> `ACTIVE_VISUAL_ONLY`
- `_init_magnetic_overlay()` -> `ACTIVE_RUNTIME`
- `_magnetic_overlay` -> `ACTIVE_RUNTIME`
- `_draw_magnetic_field_on()` -> `ACTIVE_VISUAL_ONLY`
- `MAG_FIELD_VIS_STYLE` -> `ACTIVE_VISUAL_ONLY`
- `MAG_FIELD_PLASMA_*` -> `ACTIVE_VISUAL_ONLY`
- `MAG_FIELD_SPHERE_LOOP_*` -> `ACTIVE_VISUAL_ONLY`
- `MAG_FIELD_SPHERE_TICK_*` -> `ACTIVE_VISUAL_ONLY`
- `_visual_polarity_axis()` -> `ACTIVE_VISUAL_ONLY`
- `_find_visual_focus_partner()` -> `ACTIVE_VISUAL_ONLY`
- `_sphere_surface_poles()` -> `ACTIVE_VISUAL_ONLY`
- `_draw_sphere_attached_field_loops_on()` -> `ACTIVE_VISUAL_ONLY`
- `_draw_sphere_field_arc_ticks_on()` -> `ACTIVE_VISUAL_ONLY`
- `_magnetic_interaction_activity()` -> `ACTIVE_VISUAL_ONLY`
- `_bezier_arc_polyline_steps()` -> `ACTIVE_VISUAL_ONLY`

Gated legacy visuals:
- `ENABLE_MAG_LEGACY_VISUALS` -> `ACTIVE_RUNTIME`
- `_legacy_magnetic_visuals_enabled()` -> `ACTIVE_VISUAL_ONLY`
- `MAG_FIELD_SHOW_SAMPLED_STREAMLINES` -> `LEGACY_OR_DEAD`
- `MAG_FIELD_SHOW_CONTOURS` -> `LEGACY_OR_DEAD`
- `MAG_FIELD_SHOW_POLE_MARKERS` -> `LEGACY_OR_DEAD`
- `MAG_FIELD_DRAW_*` -> `LEGACY_OR_DEAD` except shared debug-only counts
- `MAG_FIELD_TICK_*` -> `LEGACY_OR_DEAD`
- `MAG_FIELD_VIS_POLE_*` and related focus constants -> mixed: active for pole-based loop geometry, legacy for old pole markers/streamlines
- `_build_visual_poles()` -> `LEGACY_OR_DEAD`
- `_sample_visual_field()` -> `LEGACY_OR_DEAD`
- `_visual_line_strength()` -> `LEGACY_OR_DEAD`
- `_build_visual_seeds()` -> `LEGACY_OR_DEAD`
- `_trace_visual_field_line()` -> `LEGACY_OR_DEAD`
- `_trace_visual_branch()` -> `LEGACY_OR_DEAD`
- `_close_to_terminator()` -> `LEGACY_OR_DEAD`
- `_draw_field_line_ticks_on()` -> `LEGACY_OR_DEAD`
- `_draw_magnetic_contours_on()` -> `LEGACY_OR_DEAD`
- `_draw_visual_pole_marks_on()` -> `LEGACY_OR_DEAD`

Consumers:
- `CellBody._sample_round_magnetic_strength()` -> `ACTIVE_SIMULATION_ONLY`
- `CellBody._apply_coil_field_spin()` -> `ACTIVE_SIMULATION_ONLY`
- `CellBody._apply_round_homeostasis()` -> `ACTIVE_SIMULATION_ONLY`

Runtime-check candidates:
- `MagneticFieldOverlay._process()` -> `UNKNOWN_NEEDS_RUNTIME_CHECK`
- `_draw_sphere_attached_field_loops_on()` -> `UNKNOWN_NEEDS_RUNTIME_CHECK` for on-screen adequacy only
- `_magnetic_interaction_activity()` -> `UNKNOWN_NEEDS_RUNTIME_CHECK` for visual impact only

## 11. Any Field Values Used By Motion / Coil Spin / Sphere Homeostasis

Generic movement:
- General movement does not directly integrate the magnetic field vector.
- Pair guidance and bond mechanics are separate systems.

Coil spin:
- `CellBody._apply_coil_field_spin()` uses normalized field magnitude from `_sample_round_magnetic_strength()`.
- It does not use visual poles or field-vector direction.

Sphere homeostasis:
- `CellBody._apply_round_homeostasis()` samples magnetic magnitude around the sphere and mixes that with `MediumField` charge/noise/flow.
- It does not use visual poles or the dormant visualization sampler.

## 12. Smallest Safe Next Implementation Plan

1. Freeze the current simulation sampler and its consumers.
2. Decide whether the intended magnetic ontology is center-charge or dipole-oriented.
3. If dipole-oriented is the target, change the simulation-side model under `sample_magnetic_field()` first.
4. Keep the current overlay as a reference renderer until simulation and visualization share the same ontology.
5. Only after that, disable the dormant streamline/contour/marker branches and remove their constants.
