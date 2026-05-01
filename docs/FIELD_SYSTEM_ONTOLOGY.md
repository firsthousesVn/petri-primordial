# Field System Ontology

This document defines the canonical field vocabulary for `petri-primordial`.

It is a maintenance document for code and HUD language. It does not introduce new gameplay, new visuals, or new field math.

## Main Field Systems

### A. Ambient Field
- `ambient_field` is the dish-wide energetic medium.
- It is the simulation system previously blurred together with “macro field.”
- It biases motion, field bend, lane formation, and large-scale dish behavior.
- If enabled, it exists whether or not it is currently visible.

### Ambient Field Reveal
- `ambient_field_reveal` is the visible overlay for seeing the ambient field.
- This is the same thing older code/docs called the “macro field.”
- It is not a separate physics system.
- Correct interpretation:
  - ambient field = simulation medium
  - ambient field reveal = visible overlay for that medium

### B. Cell-Field
- `cell_field` is the projected or reshaped field contribution from cells.
- It is the attraction / influence / tension / negotiation layer between cells.
- It is strongest around Spheres, but other cells can project or reshape it too.

### Cell-Field Arcs
- `cell_field_arcs` are the visible expression of the cell-field.
- They are not decorative lines layered on top of a different cell-field system.
- Correct interpretation:
  - cell-field = the system
  - cell-field arcs = its readable visual form

## Separate Layers

### C. Plasma Sheath
- `plasma_sheath` is the contained plasma energy on the cell body itself.
- It is body/surface energy.
- It is not the projected field territory.

### D. Plasma Bridge
- `plasma_bridge` is the intensified conduit between cells when attraction/bonding resolves.
- It is connection-specific.
- It is not ordinary cell-field arc behavior.

## Legacy Naming

- `macro field` = `ambient field reveal`
- `field arcs` = visible `cell-field`
- `magnetic field` = legacy/internal name; do not use for new HUD/doc language unless referring to old code paths
- `local plasma` = legacy/internal shader name for the plasma-sheath support layer and bridge-throat support
- `plasma connection` = legacy/internal name for the plasma-bridge conduit path

## Current Name Audit

Current names found in the codebase:
- `AMBIENT_FIELD_*`
- `MACRO_FIELD_*`
- `CELL_FIELD_*`
- `MAG_FIELD_*`
- `LOCAL_PLASMA_*`
- `PLASMA_CONNECTION_*`
- `PLASMA_BRIDGE_*`
- `macro_field_reveal`
- `sample_magnetic_field(...)`
- `_draw_macro_field_on(...)`
- `_draw_magnetic_field_on(...)`

Canonical names to use going forward:
- `AMBIENT_FIELD_ENABLED`
- `AMBIENT_FIELD_REVEAL_ENABLED`
- `AMBIENT_FIELD_REVEAL_KEY`
- `CELL_FIELD_ENABLED`
- `PLASMA_SHEATH_ENABLED`
- `PLASMA_BRIDGE_ENABLED`
- `sample_ambient_field(...)`
- `sample_cell_field(...)`
- `draw_ambient_field_reveal_on(...)`
- `draw_cell_field_arcs_on(...)`
- `update_ambient_field_reveal(...)`
- `update_plasma_sheath_shader(...)`

Legacy aliases intentionally kept for compatibility:
- `MACRO_FIELD_ENABLED`
- `MACRO_FIELD_REVEAL_ENABLED`
- `MACRO_FIELD_REVEAL_KEY`
- `CELL_FIELD_POLARITY_ARCS_ENABLED`
- `LOCAL_PLASMA_SHADER_ENABLED`
- `PLASMA_CONNECTION_ENABLED`
- `sample_magnetic_field(...)`
- `_draw_macro_field_on(...)`
- `_draw_magnetic_field_on(...)`
- `macro_field_reveal`

Names that should eventually be renamed later, but were not globally changed in this pass:
- `MAG_FIELD_*` constants and debug counters
- `MAG_FIELD_VIS_STYLE`
- `MagneticFieldOverlay.gd`
- `LocalPlasmaOverlay.gd`
- `_update_macro_field_seeds(...)`
- `_draw_plasma_connection_on_bond(...)`

## Maintenance Rules

- Do not treat ambient field and macro field as separate systems.
- Do not treat cell-field and field arcs as separate systems.
- Keep plasma sheath distinct from projected cell-field.
- Keep plasma bridge distinct from ordinary cell-field arcs.
- Prefer canonical wrapper names in new code and docs.
- Keep legacy names only where compatibility or staged cleanup requires them.
