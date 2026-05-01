# AI Slop Audit

Audit date: 2026-04-29
Repo: `petri-primordial`
Scope: architecture audit only. No gameplay behavior was changed in this pass.

## Current Repository State

### Git state

Modified:
- `project.godot`
- `scenes/petri/PetriDish.tscn`
- `scripts/petri/PetriDish.gd`

Untracked:
- `docs/CURRENT_PETRI_STATE.md`
- `icon.svg.import`
- `resources/cells/CoilRotorCell.tres`
- `resources/cells/CrescentSoftCell.tres`
- `resources/cells/LineGlassCell.tres`
- `resources/cells/RoundPearlCell.tres`
- `resources/cells/SpiralSoftCell.tres`
- `resources/cells/WedgeGlassCell.tres`
- `scenes/petri/CellBody.tscn`
- `scripts/petri/Bond.gd`
- `scripts/petri/CellBody.gd`
- `scripts/petri/CellHotbar.gd`
- `scripts/petri/CellPort.gd`
- `scripts/petri/CellSignature.gd`
- `scripts/petri/MagneticFieldOverlay.gd`
- `scripts/petri/MediumField.gd`
- companion `*.gd.uid` files

### Diff concentration

`git diff --stat` shows almost all tracked churn concentrated in one file:
- `scripts/petri/PetriDish.gd`: `+3058/-?` scale growth, now 3089 lines
- `scenes/petri/PetriDish.tscn`: small scene wiring edits
- `project.godot`: small config edits

Interpretation:
- The architecture is not evolving through small integrated commits.
- The project is currently a large controller script plus a pile of not-yet-committed support files.

### Main petri files

- `scenes/petri/PetriDish.tscn`
- `scenes/petri/CellBody.tscn`
- `scripts/petri/PetriDish.gd`
- `scripts/petri/CellBody.gd`
- `scripts/petri/Bond.gd`
- `scripts/petri/CellPort.gd`
- `scripts/petri/CellSignature.gd`
- `scripts/petri/CellHotbar.gd`
- `scripts/petri/MediumField.gd`
- `scripts/petri/MagneticFieldOverlay.gd`
- `resources/cells/*.tres`

### Largest files by line count

- `scripts/petri/PetriDish.gd`: 3089
- `scripts/petri/CellBody.gd`: 1041
- `scripts/petri/MediumField.gd`: 242
- `docs/CURRENT_PETRI_STATE.md`: 238
- `scripts/petri/CellHotbar.gd`: 133
- `scripts/petri/Bond.gd`: 53

### Files most likely created by AI in previous passes

Strong indicators:
- all currently untracked support scripts/resources under `scripts/petri/`, `resources/cells/`, and `scenes/petri/CellBody.tscn`
- `docs/CURRENT_PETRI_STATE.md`
- `scripts/petri/MagneticFieldOverlay.gd`
- the huge one-shot expansion of `scripts/petri/PetriDish.gd`

Reasons:
- generic but plausible naming
- large prompt-shaped comments
- compatibility wrappers left behind
- untracked helper assets created around a single monolithic controller instead of integrated incrementally

## System Map

| System | File(s) | Main functions / classes | State |
|---|---|---|---|
| Hotbar / spawning | `scripts/petri/PetriDish.gd`, `scripts/petri/CellHotbar.gd` | `_active_cell_kinds()`, `_hotbar_entries()`, `_selected_signature_template()`, `_spawn_cells()`, `_spawn_selected_cell_at()`, `CellHotbar` | Active, but contains legacy `Line` assumptions and a stale startup pool |
| Cell type data / signatures | `scripts/petri/CellSignature.gd`, `resources/cells/*.tres` | `CellSignature`, per-cell `.tres` resources | Active, but naming/ontology drift exists: `Coil` is still geometry `spiral`; extra `SpiralSoftCell.tres` appears unused |
| Cell rendering | `scripts/petri/CellBody.gd` | `_draw()`, `_draw_round()`, `_draw_wedge()`, `_draw_spiral_coil()`, `_draw_line()`, `_draw_crescent()` | Active |
| Cell movement / internal state | `scripts/petri/CellBody.gd` | `_process()`, `_step_motion()`, `_interact_with_field()`, `_apply_round_homeostasis()`, `_apply_coil_field_spin()`, `_maybe_wedge_impulse()` | Active, behavior-heavy, partially contradicts current ontology |
| Magnetic field sampling | `scripts/petri/PetriDish.gd` | `_collect_magnetic_sources()`, `_magnetic_source_contribution()`, `_sample_magnetic_field_superposed()`, `sample_magnetic_field()` | Active, but still a center-radial scalar-charge field, not polarity-aware |
| Magnetic field visualization | `scripts/petri/PetriDish.gd`, `scripts/petri/MagneticFieldOverlay.gd` | `_draw_magnetic_field_on()`, `_draw_sphere_attached_field_loops_on()`, `_build_visual_poles()`, `_trace_visual_field_line()`, `_draw_magnetic_contours_on()` | Active plus multiple disabled/legacy branches |
| Bonding / capture / seating | `scripts/petri/PetriDish.gd`, `scripts/petri/Bond.gd`, `scripts/petri/CellPort.gd` | `_update_guidance()`, `_evaluate_pair_interaction()`, `_classify_contact()`, `_form_bond()`, `_update_bonds()`, `_seat_anchors()`, `_resolve_cell_collisions()` | Active, high-risk for jitter/teleporting due direct position correction |
| Cluster / seedling classification | `scripts/petri/PetriDish.gd` | `_compute_clusters_lite()`, `_classify_seedlings()`, `_summarize_seedling()`, `_resolve_seedling_type()` | Active, but conceptually premature and still line-dependent |
| Debug HUD / toggles | `scripts/petri/PetriDish.gd`, `scripts/petri/MediumField.gd` | `_update_debug()`, `_unhandled_input()`, `MediumField.toggle_debug_*()` | Active, but cluttered by many dev-only toggles and stale counters |

### Active / disabled / legacy summary

Active:
- field grid
- spawn/delete/hotbar
- per-cell motion and render
- guidance/capture/bonds
- seedling classification
- magnetic overlay render
- sampled magnetic field for gameplay

Disabled or effectively off by constants:
- sampled magnetic streamlines: `MAG_FIELD_SHOW_SAMPLED_STREAMLINES = false`
- contour rings: `MAG_FIELD_SHOW_CONTOURS = false`
- pole markers: `MAG_FIELD_SHOW_POLE_MARKERS = false`
- startup spawn pool: `SPAWN_COUNT = 0`

Legacy or unclear:
- `Line` gameplay path remains wired almost everywhere while hidden from the hotbar
- `_draw_textbook_field_loops_on()` is now a compatibility wrapper
- `_draw_magnetic_field()` is just a wrapper and no longer the real overlay entrypoint
- `SpiralSoftCell.tres` appears to be a dead variant asset
- `docs/CURRENT_PETRI_STATE.md` is already partially stale

## Ontology Contradictions

### 1. `Line` is deprecated in UI only, not in behavior

Exact locations:
- `scripts/petri/PetriDish.gd:14` `ENABLE_LEGACY_LINE_CELL = false`
- `scripts/petri/PetriDish.gd:333` `Line` only hidden from active hotbar list
- `scripts/petri/PetriDish.gd:1293` startup spawn pool still includes `SIG_LINE`
- `scripts/petri/PetriDish.gd:2402-2412` line-specific bond types remain first-class
- `scripts/petri/PetriDish.gd:2927-2928` `CONDUIT_SEED` still depends on line ratio/conductivity
- `scripts/petri/CellBody.gd:197-200` line ports are still generated
- `scripts/petri/CellBody.gd:273-279` line-specific physics tuning remains active
- `scripts/petri/CellBody.gd:803-804` line rendering remains active

Assessment:
- Current ontology says `Line` is conceptually deprecated.
- Current code says `Line` is hidden from player input, but still structurally central to bond taxonomy and seedling typing.

### 2. Coil is still encoded as `spiral`

Exact locations:
- `resources/cells/CoilRotorCell.tres:7` `geometry_type = "spiral"`
- `scripts/petri/PetriDish.gd:335` hotbar label `Coil` maps to kind `spiral`
- `scripts/petri/CellBody.gd:622-651` rotor behavior is implemented under `_apply_coil_field_spin()` but gated by `_canonical_geom() != "spiral"`
- `scripts/petri/CellBody.gd:962` render path is `_draw_spiral_coil()`

Assessment:
- Player-facing ontology says `Coil`.
- internal ontology still says `spiral`.
- That mismatch leaks into resources, rendering, motion tuning, and classification.

### 3. Triangle still behaves like an active dart/missile, not just a heavy shard

Exact locations:
- `scripts/petri/CellBody.gd:724-759` `_maybe_wedge_impulse()` gives random self-propelled forward impulses
- `resources/cells/WedgeGlassCell.tres:14-17` high `impulse_bias`, low `stability`
- `scripts/petri/PetriDish.gd:2713-2723` puncture bonds actively drain charge during dash
- `scripts/petri/PetriDish.gd:2925` `MOTOR_SEED` depends on triangle puncture behavior

Assessment:
- Current ontology calls Triangle a heavy shard / puncture hazard / tool material.
- Current implementation still makes it an intermittently self-propelled striker.

### 4. Sphere field simulation is still center-radial, not polarity-aware

Exact locations:
- `scripts/petri/PetriDish.gd:1480-1507` `_collect_magnetic_sources()` only records center position, charge, weight, soften radius
- `scripts/petri/PetriDish.gd:1510-1528` `_magnetic_source_contribution()` computes contribution from center offset only
- `scripts/petri/PetriDish.gd:1530-1554` total field is just vector sum of these center-radial contributions
- `scripts/petri/PetriDish.gd:853-925` polarity is only introduced in the visualization layer

Assessment:
- Current visual language implies a dipole/pole axis in the sphere.
- Actual gameplay sampler has no orientation or pole axis at all.
- The field used by homeostasis and coil spin is not the same ontology as the field being drawn.

### 5. Crescent is mostly contact geometry plus visualization hack, not a real reflector/aperture in simulation

Exact locations:
- `scripts/petri/PetriDish.gd:2374-2390` crescent contact logic is hook/cradle based
- `scripts/petri/PetriDish.gd:646-684` crescent affects magnetic field only through visualization-only focus poles
- `scripts/petri/PetriDish.gd:1480-1507` magnetic simulation does not model reflector/aperture behavior for crescents; it just treats non-round shapes as weak scalar sources
- `scripts/petri/CellBody.gd:1022-1040` crescent rendering is active, but no separate functional aperture model exists

Assessment:
- The “reflector/protector/aperture/field shaper” ontology is only partially represented.
- Functional shaping exists in draw-only helpers, not in the real field model.

### 6. Coil is mostly a rotor visual + spin force, not a helper/grabber system

Exact locations:
- `scripts/petri/CellBody.gd:622-651` comment explicitly says “No bond/grab logic — this is purely an angular force.”
- `scripts/petri/PetriDish.gd` has no coil-specific bonding/capture path beyond generic contact roles

Assessment:
- Rotor part exists.
- helper/grabber part does not exist yet.

### 7. Seedling classification still encodes deprecated line-cell ontology

Exact locations:
- `scripts/petri/PetriDish.gd:157-158` `CONDUIT_*` thresholds
- `scripts/petri/PetriDish.gd:2811-2815` seedling summary counts `line`
- `scripts/petri/PetriDish.gd:2873-2877` conductivity is partly line ratio + line bond ratio
- `scripts/petri/PetriDish.gd:2927-2928` `CONDUIT_SEED`
- `scripts/petri/PetriDish.gd:2930-2931` `BEND_SEED` also still allows round+line combinations

Assessment:
- This is a direct mismatch with the current ontology direction.
- Seedling typing is being built on a contact grammar the project already claims is deprecated.

### 8. Triangle-to-crescent bonding is explicitly blocked, not contradictory

Exact location:
- `scripts/petri/PetriDish.gd:2358-2360`

Assessment:
- This is not currently a contradiction.
- The code explicitly returns `clash_noise` for triangle-crescent contact.

## AI Slop Patterns

### 1. Monolithic controller owns too many systems

- Symbol: `_process()`, `_update_guidance()`, `_classify_contact()`, `_update_bonds()`, `_classify_seedlings()`, `_update_debug()`
- File: `scripts/petri/PetriDish.gd`
- Why suspicious: one file owns input, spawning, magnetic rendering, field sampling, guidance, bond physics, cluster motion, seedling typing, FX, and HUD. This is architectural slop, not just file size.
- Action: needs investigation and staged extraction. Do not broad-refactor before behavior is verified.

### 2. Magnetic overlay keeps multiple conflicting systems alive

- Symbols: `_draw_magnetic_field_on()`, `_build_visual_poles()`, `_trace_visual_field_line()`, `_draw_sphere_attached_field_loops_on()`, `_draw_magnetic_contours_on()`, `_draw_textbook_field_loops_on()`
- File: `scripts/petri/PetriDish.gd`
- Why suspicious: one active renderer plus several disabled/legacy visual pipelines still coexist. This is exactly how prompt residue accumulates.
- Action: disable or delete later, but only after one visual path is chosen and runtime-verified.

### 3. “Real sampler” and visual field are different ontologies

- Symbols: `sample_magnetic_field()`, `_sample_visual_field()`, `_visual_polarity_axis()`
- File: `scripts/petri/PetriDish.gd`
- Why suspicious: gameplay field is a center-radial scalar-charge sum; visual field is a dipole/pole abstraction with optional crescent focus poles. The code claims coherence but the models disagree.
- Action: needs investigation before further magnetism work.

### 4. Legacy wrappers remain even when the system changed

- Symbols: `_draw_magnetic_field()`, `_draw_textbook_field_loops()`, `_draw_textbook_field_loops_on()`, `_draw_visual_pole_marks()`, `_draw_magnetic_contours()`
- File: `scripts/petri/PetriDish.gd`
- Why suspicious: wrappers kept “for compatibility” with no obvious remaining caller value. This is classic AI patch layering.
- Action: safe to disable later after reference audit; not urgent for runtime.

### 5. Hidden but active `Line` system

- Symbols: `ENABLE_LEGACY_LINE_CELL`, `SIG_LINE`, `line_chain`, `line_parallel`, `CONDUIT_SEED`
- File: `scripts/petri/PetriDish.gd`, `scripts/petri/CellBody.gd`
- Why suspicious: player-facing deprecation without systemic removal creates contradictory behavior and makes later cleanup harder.
- Action: needs design decision first; likely disable/remove later.

### 6. Dead or duplicate asset variant

- Symbol: `SpiralSoftCell.tres`
- File: `resources/cells/SpiralSoftCell.tres`
- Why suspicious: no live reference found in code or scene, only in stale docs.
- Action: safe to remove later if confirmed unused in editor.

### 7. Startup spawn path is stale and contradicts active roster

- Symbol: `_spawn_cells()`
- File: `scripts/petri/PetriDish.gd`
- Why suspicious: startup pool uses `[SIG_ROUND, SIG_TRIANGLE, SIG_LINE, SIG_CRESCENT]`, omits `SIG_COIL`, includes hidden `SIG_LINE`, and is currently masked only by `SPAWN_COUNT = 0`.
- Action: safe to adjust later, but it proves the codebase is relying on a dormant path instead of removing it.

### 8. Direct position projection still underpins bond settling

- Symbols: `_seat_anchors()`, `_resolve_cell_collisions()`
- File: `scripts/petri/PetriDish.gd`
- Why suspicious: both functions write positions directly. Comments admit these corrections are there to stop teleports and jitter, which means the issue is known but not eliminated.
- Action: investigate before changing bonding behavior.

### 9. Independent impulse behavior still exists inside bonded ecology

- Symbol: `_maybe_wedge_impulse()`
- File: `scripts/petri/CellBody.gd`
- Why suspicious: triangle impulse is randomized and not cluster-aware beyond weak gating. This can fight bond settling and blur the intended “heavy shard” role.
- Action: needs investigation.

### 10. Seedling classification is likely premature

- Symbols: `_classify_seedlings()`, `_summarize_seedling()`, `_resolve_seedling_type()`
- File: `scripts/petri/PetriDish.gd`
- Why suspicious: classification is running on top of unstable bond behavior, deprecated line assumptions, and unverified cluster motion. It produces ontology labels before the ontology is stable.
- Action: freeze or disable for design work until runtime behavior is trustworthy.

### 11. Overly generic or misleading names

- Symbols: `round`, `spiral`, `wedge`, `_classify_contact()`, `_draw_magnetic_field_on()`
- File: `scripts/petri/PetriDish.gd`, `scripts/petri/CellBody.gd`, resources
- Why suspicious: project-facing ontology says Sphere / Crescent / Triangle / Coil, but internal names still mix geometry, old shapes, and role names. This causes conceptual drift.
- Action: needs investigation. Rename only after behavior freeze.

### 12. Silent no-op and toggle clutter

- Symbols: `KEY_5`, `MAG_FIELD_VIS_STYLE`, `MAG_FIELD_SHOW_SAMPLED_STREAMLINES`, `MAG_FIELD_SHOW_CONTOURS`, `MAG_FIELD_SHOW_POLE_MARKERS`
- File: `scripts/petri/PetriDish.gd`
- Why suspicious: many states exist where input or config appears meaningful but effectively does nothing or leaves dead code resident.
- Action: safe to simplify later.

### 13. Stale internal documentation already exists in-tree

- File: `docs/CURRENT_PETRI_STATE.md`
- Why suspicious: it still documents old line numbers and references textbook-loop behavior as though it were the current path. It is useful as a handoff note, not as authoritative documentation.
- Action: keep as historical note only. Do not treat as source of truth.

### 14. Unused / suspicious constants in `CellBody.gd`

- Symbols: `BROWNIAN_BASE`, `MAX_LINEAR_SPEED`
- File: `scripts/petri/CellBody.gd`
- Why suspicious: appear defined but not used.
- Action: safe to remove later after a full constant sweep.

## Risky Code Paths

### High-risk runtime behavior

- `scripts/petri/PetriDish.gd:434-471` `_process()`
  - central orchestrator with many ordered side effects
- `scripts/petri/PetriDish.gd:1755-1780` `_seat_anchors()`
  - direct position projection on bond endpoints
- `scripts/petri/PetriDish.gd:1783-1805` `_resolve_cell_collisions()`
  - direct position projection for collisions
- `scripts/petri/PetriDish.gd:2580-2699` `_update_bonds()`
  - long mixed responsibility function: spring, torque, damping, capture bleed, charge flow, strain, breakage
- `scripts/petri/CellBody.gd:503-549` `_step_motion()`
  - movement, boundary correction, round homeostasis, dash impulse consequences mixed together

### High-risk conceptual drift

- `scripts/petri/PetriDish.gd:1480-1556` magnetic simulation vs `scripts/petri/PetriDish.gd:643-1024` magnetic visualization
- `scripts/petri/PetriDish.gd:2769-2933` seedling classifier
- `scripts/petri/PetriDish.gd:2333-2415` contact taxonomy

## Runtime Verification

### What was actually verified

Godot binary found:
- `/mnt/c/Users/kxixg/Downloads/Godot_v4.6.1-stable_win64.exe`

Command run:
```bash
/mnt/c/Users/kxixg/Downloads/Godot_v4.6.1-stable_win64.exe --headless --path . --quit-after 3 --verbose
```

Result:
- exit code `0`
- main scene loaded
- primary petri scripts/resources loaded
- no script parse/load errors in that headless run

### What was not verified

- no interactive Windows play session was observed
- no visual confirmation of magnetic overlay correctness
- no verification of bond jitter / teleport feel in motion
- no verification of seedling labels against actual stable gameplay

### Static checks

- No test suite or CI workflow files were found under the repo root within a cheap scan.
- No dedicated static checker scripts were found.
- Practical cheap check available right now is the headless Godot load only.

## Suspected Dead / Legacy Code

Likely safe to remove later after verification:
- `resources/cells/SpiralSoftCell.tres` if no editor-only reference exists
- compatibility wrappers around `_draw_textbook_field_loops*`, `_draw_visual_pole_marks()`, `_draw_magnetic_contours()`
- stale magnetic sampled-streamline helpers if that path remains permanently disabled
- `KEY_5` mapping if a fifth hotbar slot is not returning

Likely should be disabled first, not deleted immediately:
- seedling classification and display
- legacy `Line` startup spawn inclusion
- extra magnetic debug visualization branches
- stale docs as authority

Needs deeper investigation before any removal:
- `_classify_contact()` taxonomy
- `_update_bonds()`
- `_seat_anchors()` and `_resolve_cell_collisions()`
- `_apply_round_homeostasis()`
- `_maybe_wedge_impulse()`

## Top 10 Cleanup Priorities

1. Freeze `PetriDish.gd` behavior and stop adding new subsystems into it until runtime behavior is verified.
2. Choose one magnetic visualization path and delete the other dormant branches afterward.
3. Decide whether `Line` is actually deprecated; if yes, remove it from bond grammar and seedling typing, not just the hotbar.
4. Decide whether `Coil` remains internally `spiral`; unify naming across resources, rendering, and logic.
5. Audit direct position correction in `_seat_anchors()` and `_resolve_cell_collisions()` before any bond tweaks.
6. Freeze seedling classification until bonding and cluster behavior are visually verified.
7. Remove or quarantine dead assets and wrapper functions after a reference sweep.
8. Split runtime truth from debug/visualization truth in magnetism; right now the models disagree.
9. Reduce comment claims that imply design coherence where only a prompt-driven patch chain exists.
10. Commit or discard the untracked support layer intentionally; the current state hides architecture behind an uncommitted pile.

## Recommended Next 5 Small Codex Prompts

1. `Audit only the bond seating and collision correction paths. Identify every direct position write and every velocity bleed, with no behavior changes.`
2. `Remove only dead magnetic wrapper paths that are provably unreachable with current constants. Do not change visuals.`
3. `Audit only seedling classification against the current Sphere/Crescent/Triangle/Coil ontology. Do not modify behavior.`
4. `Map every remaining Line-dependent rule and propose a removal order without editing code.`
5. `Audit only Coil semantics. Compare current 'spiral' implementation to intended helper/grabber role and list the gaps.`

## What Must Be Manually Verified In Godot

- single-sphere magnetic overlay readability on the actual Windows desktop
- whether drawn field lines actually track cell geometry during movement and rotation
- whether bond capture still produces teleporting or visible snap artifacts
- whether bonded clusters jitter under triangle impulses or round homeostasis forces
- whether seedling labels correspond to stable, readable structures rather than transient tangles
- whether Coil behavior is meaningfully legible as a helper/rotor and not just a spinning ornament
- whether hidden `Line` code still leaks into debug-spawn or classification in practice

## Bottom Line

The main problem is not one bug. It is architectural accumulation:
- a monolithic controller script
- a hidden-but-still-active deprecated cell type
- magnetic simulation and magnetic visualization using different ontologies
- seedling classification built on unstable and partly deprecated behavior
- compatibility wrappers and disabled branches left behind after prompt-driven changes

The project should be treated as runtime-fragile until the bond/magnetism stack is verified in Godot with deliberate scenarios.
