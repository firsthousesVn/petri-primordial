# Bond Risk Map

Current bond mechanics map for `petri-primordial`.

This document is descriptive only. It does not propose a rewrite and it does not claim the current behavior is correct.

## Where Bonds Form

Primary functions:
- `scripts/petri/PetriDish.gd` `_update_guidance()`
- `scripts/petri/PetriDish.gd` `_evaluate_pair_interaction()`
- `scripts/petri/PetriDish.gd` `_classify_contact()`
- `scripts/petri/PetriDish.gd` `_can_capture_now()`
- `scripts/petri/PetriDish.gd` `_try_capture_request()`
- `scripts/petri/PetriDish.gd` `_scan_for_bonds()`
- `scripts/petri/PetriDish.gd` `_classify_and_form()`
- `scripts/petri/PetriDish.gd` `_form_bond()`

Notes:
- Guidance and capture run every frame.
- Bond scan also runs on its own cadence.
- This means bond creation pressure comes from more than one place.

## Where Capture Starts

Primary functions:
- `scripts/petri/PetriDish.gd` `_apply_interaction_candidate()`
- `scripts/petri/PetriDish.gd` `_can_capture_now()`
- `scripts/petri/PetriDish.gd` `_try_capture_request()`
- `scripts/petri/PetriDish.gd` `_mark_capture_cells()`

Notes:
- Capture modifies velocity and angular velocity before the persistent bond settles.
- Capture timers and hold timers then influence later bond damping and seating.

## Where Direct Position Correction Happens

Primary functions:
- `scripts/petri/PetriDish.gd` `_seat_anchors()`
- `scripts/petri/PetriDish.gd` `_resolve_cell_collisions()`

Direct writes:
- `_seat_anchors()` writes `bond.a.position += ...` and `bond.b.position -= ...`
- `_resolve_cell_collisions()` writes `a.position -= ...` and `b.position += ...`

Why this matters:
- position projection is effective for stabilization
- it also creates the main risk of visible snap or teleport if the correction magnitude is too large relative to the frame

## Where Velocity / Rotation Is Damped

Primary functions:
- `scripts/petri/PetriDish.gd` `_update_bonds()`
- `scripts/petri/PetriDish.gd` `_apply_bonded_angular_damp()`
- `scripts/petri/CellBody.gd` `stabilize_external_motion()`
- `scripts/petri/CellBody.gd` `_apply_motion_damping()`
- `scripts/petri/CellBody.gd` `_limit_motion_change()`

Notes:
- there is per-bond spring damping
- there is shared-velocity / shared-angular damping inside `_update_bonds()`
- there is extra bonded angular damping at the dish level
- there is cell-local damping after external forces are applied

## Where Brownian / Random Forces Affect Bonded Cells

Primary functions:
- `scripts/petri/PetriDish.gd` `_apply_cluster_brownian()`
- `scripts/petri/PetriDish.gd` `_apply_cluster_coupling()`
- `scripts/petri/CellBody.gd` `_step_motion()`
- `scripts/petri/CellBody.gd` `_maybe_wedge_impulse()`

Notes:
- cluster Brownian is reduced for bonded groups, but it still exists
- cluster coupling then tries to pull members back toward a shared motion state
- triangle impulse behavior is independent from the bond solver and can still inject conflict into settled structures

## Why Teleporting May Happen

Main reasons:
- `_seat_anchors()` performs direct positional correction after bond creation and during bond maintenance
- newly formed bonds can begin with a large error between anchor distance and rest distance
- the frame then applies seating after spring/capture forces, so the visual correction can read as a jump
- collision separation can stack on top of bond seating in the same frame

## Why Jitter May Happen

Main reasons:
- bond spring forces, seating projection, collision separation, cluster Brownian, cluster coupling, and cell-local damping all act in the same frame
- relative velocity damping and angular damping fight to settle structures, but other forces can keep re-injecting contradiction
- triangle impulse behavior and noisy / erratic cells can keep disturbing partially settled bonds
- round homeostasis and other cell-local movement logic still continue while bonded

## Safest Future Fix Order

1. Audit and constrain direct position correction in `_seat_anchors()`.
2. Audit interaction between `_seat_anchors()` and `_resolve_cell_collisions()` in the same frame.
3. Audit which cell-local motion behaviors should be reduced or suspended while strongly bonded.
4. Audit triangle impulse behavior against bonded-cluster stability.
5. Only after those are understood, simplify or retune damping layers.

## What Not To Do First

- do not rewrite the whole bond system at once
- do not mix bond solver changes with ontology changes
- do not change magnetic simulation and bond stabilization in the same pass
- do not trust seedling behavior as a quality signal until bond motion is stable enough to observe clearly
