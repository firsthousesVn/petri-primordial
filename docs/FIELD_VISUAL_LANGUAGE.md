# Field Visual Language

This document defines the active visual stack for energetic behavior in `petri-primordial`.

It is a rendering-language document, not a gameplay rewrite.

For the canonical system vocabulary and legacy-name mapping, see
`docs/FIELD_SYSTEM_ONTOLOGY.md`.

## Vocabulary

### Cell-Field
- the energetic field projected or reshaped by an individual cell
- local, role-specific, and responsive to nearby cells
- strongest around Spheres, but present as shaping behavior across all cell types

### Ambient Field
- the dish-wide background frequency / medium
- biases motion, bend, and lane formation
- acts on cell-fields rather than replacing them

### Plasma Sheath
- close bright surface energy hugging a cell body
- thin, luminous, and readable at the body edge
- should not be mistaken for the whole cell-field

### Field Arcs
- clean organized projected cell-field lines / loops
- smoother and more coherent than the flame-like plasma haze
- animated continuously and biased by ambient field + nearby attractors

### Plasma Bridge
- intense conduit between bonded or strongly resolving cells
- connection-specific, brighter, and narrower than general field arcs
- should read as a resolved link, not a generic aura

### Ambient Field Reveal
- visible dish-scale reveal of the ambient field plus total large-scale field shaping
- broader and softer than cell-local arcs
- provides the background medium that cell-fields live inside
- legacy docs/code may still call this the `macro field`

## Visual Stack

The runtime field stack should read in this order:
- cell body
- plasma sheath close to the body
- flame / local energetic haze
- clean field arcs
- plasma bridge when a connection resolves
- ambient field reveal as the broader dish-scale medium

The flame layer and the field-arc layer are not the same thing:
- flame = local energized atmosphere
- arcs = organized cell-field geometry

## Per-Cell Expression

### Sphere
- strongest field projector
- largest and cleanest outward arcs
- broad attraction corridors
- can merge into shared lobes and plasma bridges with nearby Spheres

### Coil
- rotor / helper expression
- shorter curling or torsion-biased arcs
- visibly reacts to ambient flow and nearby cell-fields

### Crescent
- reflector / protector / aperture expression
- does not need a large projected aura
- bends, funnels, or shelters nearby field flow around its curve and opening

### Triangle
- weak projector
- minimal broad arcs
- field expression concentrates near points and edges
- tension should brighten tips / edges rather than creating a Sphere-like lobe

### Line
- legacy geometry path
- not a truth source for current field art direction
- kept only as maintenance compatibility until it is fully retired

## Active Runtime Intent

- Every cell can contribute to the local cell-field overlay.
- Spheres remain the strongest projectors.
- Ambient field should bend and bias arcs instead of competing with them.
- Plasma bridges should intensify only when attraction resolves into a connection.
- Legacy magnetic diagrams, studded halos, and hard cable visuals are not the target language.
