# Petri Primordial — Field Ecology Implementation Spec

Companion to `FIELD_ECOLOGY_VISUAL_CONTRACT.md`. The contract defines what
the player sees and what is forbidden. This spec defines the code modules
that produce that result and where the math lives.

The honesty rule is non-negotiable: a visible field effect MUST correspond
to cached simulation state. Renderers express cached state. They do not
invent interaction.

## Module map

```
PetriDish              coordinator, update order, spawning, hotbar, selection, bonds
├── FieldModel         pure math: ambient sample, field radius, overlap, compatibility
├── FieldInteractionSystem
│                      per-frame: neighbor walk, overlap, compatibility,
│                      attraction, compression/repulsion, polarity torque,
│                      bond pressure, ambient drift
├── CellFieldRenderer  per-cell broad dipole/plasma lobes deformed by cached state
└── AmbientGridRenderer
                       wavy grid blanket, shallow wells, subtle pair saddles
```

Each module owns exactly its responsibilities below. No module reaches into
another module's job. Renderers never compute interaction. The interaction
system never draws. The dish never inlines field math.

---

## 1. FieldModel

Owns the pure math. No state, no per-frame work, no drawing. Functions are
deterministic in their inputs.

Responsibilities:
- ambient field sampling at `(local_pos, sim_time, dish_radius)`
- per-cell field radius
- pair overlap (raw + smoothstepped)
- polarity compatibility ∈ [0, 1]

Current implementations: `scripts/petri/fields/AmbientField.gd` (ambient
math is already isolated and pure). The radius / overlap / compatibility
helpers currently live inline in `_compute_field_overlap_pass` and should
migrate here when the dish is split further. Move them with these signatures:

```gdscript
static func field_radius(cell) -> float:
    return cell.radius * cell.field_reach * FIELD_RADIUS_GAIN

static func overlap_raw(a, b) -> float:
    return field_radius(a) + field_radius(b) - a.position.distance_to(b.position)

static func overlap(a, b) -> float:
    return smoothstep(0.0, OVERLAP_BAND, overlap_raw(a, b))

static func compatibility(a, b, dir_ab: Vector2) -> float:
    var a_face: float = a.polarity_axis().dot(dir_ab)
    var b_face: float = b.polarity_axis().dot(-dir_ab)
    # opposite signs → compatible. Smooth, not binary.
    var raw: float = -a_face * b_face          # ∈ [-1, +1]; positive = compatible
    return clampf(0.5 + 0.5 * raw, 0.0, 1.0)
```

Constants: `FIELD_RADIUS_GAIN`, `OVERLAP_BAND`. No others belong here.

FieldModel must NOT:
- read or write cell velocity, bond pressure, or any other cached state
- own any cluster aggregate or "shared envelope" function

---

## 2. FieldInteractionSystem

Owns the per-frame walk over cell pairs and the forces/pressure produced
from FieldModel outputs. Currently lives inside
`PetriDish._compute_field_overlap_pass` (line ~2052). That function is the
canonical implementation; it will be lifted into its own module when the
dish is decomposed further. Its responsibilities, in order, per frame:

1. **Reset** `field_overlap_energy`, `field_neighbor_dir`,
   `field_bond_pressure` (decayed, not zeroed), `field_compression`,
   `field_overlap_count` on every cell.
2. **Neighbor walk** over candidate pairs (broadphase or O(n²) for small N).
3. **Per pair**:
   - `dir_ab`, `distance`
   - `overlap = FieldModel.overlap(a, b)`; skip if `overlap <= 0`
   - `compatibility = FieldModel.compatibility(a, b, dir_ab)`
   - **Attraction force** (only when overlap > 0):
     ```
     attraction = dir_ab * overlap * compatibility * FIELD_ATTRACTION_GAIN
     a.velocity += attraction * delta
     b.velocity -= attraction * delta
     ```
   - **Compression / repulsion** (only when overlap > 0 and compatibility < 1):
     ```
     compression = -dir_ab * overlap * (1.0 - compatibility) * FIELD_REPULSION_GAIN
     a.velocity += compression * delta
     b.velocity -= compression * delta
     a.field_compression = max(a.field_compression, overlap * (1.0 - compatibility))
     ```
   - **Polarity torque** (gradual axis rotation; never instant):
     ```
     # incompatible overlap nudges A's axis toward an opposite-facing config
     torque_a = signed_angle(a.polarity_axis(), -dir_ab) * overlap * (1.0 - compatibility) * POLARITY_TORQUE_GAIN
     a.angular_velocity += torque_a * delta
     # symmetric for b
     ```
   - **Bond pressure**:
     ```
     rel_speed_factor = 1.0 - smoothstep(0.0, BOND_REL_SPEED_MAX, (a.velocity - b.velocity).length())
     turbulence = max(a.field_compression, b.field_compression)
     stability = rel_speed_factor * (1.0 - turbulence)
     dp = overlap * compatibility * stability * BOND_PRESSURE_GAIN * delta
     a.field_bond_pressure += dp
     b.field_bond_pressure += dp
     ```
   - Cache `field_neighbor_dir` (overlap-weighted) on both cells for the
     renderer's lobe-bend lookup.
4. **Ambient drift** (per cell, after pair walk):
   ```
   amb = FieldModel.sample_ambient(cell.position, sim_time, dish_radius)
   cell.velocity += amb * AMBIENT_DRIFT_GAIN * delta
   ```
   Strictly weaker than overlap attraction. The grid is the medium, not
   the prime mover.
5. **Damping / caps** to keep motion organic. Velocity changes are biases,
   not snaps.

Forbidden in this system:
- nearest-neighbor seek that ignores overlap
- always-on magnetism at any distance
- any "cluster field" that sums envelope vectors and feeds them back as a
  shared kernel (this was the wrapper-shell violation; it has been
  hard-disabled — see `CLUSTER_FIELD_ENABLED = false`)
- instantaneous axis rotation
- bond pressure rising while cells separate fast or compression is high

---

## 3. CellFieldRenderer

Owns the per-cell visual: a compact dipole/plasma lobe pair built from the
analytic loop `r(θ) = L · sin²(θ)`. Implementation:
`scripts/petri/render/PolarityArcRenderer.gd`. The dipole is the starting
state; an isolated cell renders the canonical lobes from frame zero.

Responsibilities:
- broad three-pass lobe (haze / glow / core) per cell, per side
- read `cell.field_neighbor_dir`, `cell.field_overlap_energy`,
  `cell.field_bond_pressure`, `cell.field_compression` and use them to:
  - bend the lobe toward an overlapping neighbor (proportional to overlap
    + bond pressure, biased to the near-side vertices)
  - boost near-side vertex glow when the lobe faces an overlap
  - fade the inward lobe when bond_pressure is high (coupling), so the
    pair reads as a shared field unit instead of two stacked ovals

Honesty hooks (the renderer must early-out when these are zero):
- `field_overlap_energy ≤ 0` → no lobe bend
- `field_bond_pressure ≤ 0` → no coupling fade, no shared-zone boost
- `field_neighbor_dir == ZERO` → no neighbor exists; canonical dipole only

Forbidden:
- streamline tracing, bisection, iso-contour walking
- metaballs, polygon hulls, blob shells
- wrapper rings around groups of cells
- separate cluster halos
- decorative lobes that ignore other cells
- spider legs, whiskers, tentacles, ribbons, open streamlines

---

## 4. AmbientGridRenderer

Owns the wavy grid blanket. Implementation:
`scripts/petri/render/AmbientFieldRenderer.gd`. The grid IS the ambient
visual. There is no alternate ambient mode.

Responsibilities:
- two stacks of polylines (constant-Y, constant-X) over the dish
- displace each grid vertex by:
  - ambient flow displacement (sample of `AmbientField.sample_local`)
  - shallow per-cell well (Gaussian dimple toward each cell center)
  - per-cell dipole-flow contribution (saturated; produces saddles
    between pairs and bridges between coupled pairs, for free)
- alpha breath, edge fade at dish rim

Forbidden:
- any streamline ambient mode
- any alternate ambient field visualization
- debug streamlines as default
- decorative loops that don't track real cell state

The grid is secondary to cell polarity lobes. If the grid out-shouts the
lobes, dial down `GRID_AMBIENT_DISPLACEMENT`, `GRID_WELL_DEPTH`, or
`GRID_DIPOLE_GAIN`.

---

## 5. PetriDish

Coordinator. Implementation: `scripts/petri/PetriDish.gd`. Trends toward
"call sites only"; field math, interaction, and rendering live in their
own modules.

Per-frame order (currently inside `_process`):

```
1. _begin_interaction_frame()           # reset cached interaction state
2. _compute_field_overlap_pass(delta)   # FieldInteractionSystem
3. (optional) _update_guidance(delta)
4. _mark_capture_cells, _sync_bonded_counts
5. _compute_clusters_lite               # connected components for bonds only
                                         # (NOT a shared field; cluster field is OFF)
6. _scan_for_bonds (rate-limited)
7. _update_bonds (substepped)
8. _seat_anchors, _resolve_cell_collisions, _stabilize_cells_post_forces
9. update_ambient_field_reveal, queue_redraw
```

Preserved (do not strip):
- spawning, hotbar, selection, cell types
- existing bond formation / physics (`_scan_for_bonds`, `_update_bonds`,
  capture, strain, breakage)
- cell-cell collision separation
- camera, debug HUD, useful gated debug
- short-lived FX pulses (`capture`, `break`, `clash`) — bond events, not
  decorative field

Stripped (this pass) or already dead:
- **Cluster field kernel** — `CLUSTER_FIELD_ENABLED` set to `false`. The
  kernel summed an outward-radial + axis-modulated envelope around every
  bonded cluster and fed it back into `sample_total_field` and
  `sample_total_ecological_field_at`. That is the "wrapper shells around
  smaller fields" / "separate cluster halos" violation in the visual
  contract. Coupling now lives entirely in per-cell field overlap +
  `field_bond_pressure`, which the lobe renderer reads to fade the inward
  lobe and brighten the shared zone.
- **Streamline ambient mode** — already deleted (see "Phase-1" comments).
- **Cell motion trails** — already disabled; `_draw_trails` is a no-op.
- **Seedling classification + halo** — `ENABLE_SEEDLING_CLASSIFICATION`
  is `false`; `_draw_seedlings` is gated off. Code retained for possible
  future debug use, but no longer runs or draws.
- **Debug threads** — `_draw_debug_threads` only fires when
  `CellBody.debug_ports` is on (off by default).
- **Marching-squares / iso-contour cell-field renderer** — already
  removed; the analytic dipole lobe is the only cell-field visual.

---

## Active render path

Per frame, in order:

```
PetriDish._draw
  └─ background, dust, debug_threads (gated), fx, seedlings (gated),
     bonds, glass rim

MagneticFieldOverlay._draw (separate Node2D, drawn on top)
  ├─ PetriDish.draw_ambient_field_reveal_on  → AmbientGridRenderer.draw_on
  └─ PetriDish.draw_cell_field_arcs_on       → PolarityArcRenderer.draw_on

CellBody._draw (per cell)
  └─ body geometry only (round/wedge/spiral/line/crescent), ports, halo
```

No other field visual exists. If a new visual is added, it MUST cite a
specific cached-state field on the cell or bond it expresses.

---

## Honesty checklist (apply before merging any field-visual change)

- If a lobe bends → `field_overlap_energy` is nonzero.
- If a shared zone brightens → `field_bond_pressure` or
  `field_overlap_energy` is nonzero.
- If a cell moves toward another → an interaction force was integrated
  this frame.
- If the grid flows → ambient drift was applied to cells in the same
  region.
- If anything wraps multiple cells in a shared shell → reject the change.
- If anything adds a separate cluster halo → reject the change.
