# Micro Life Ontology

Current ontology snapshot for `petri-primordial`.

This is a maintainer document, not a feature roadmap. It describes what the codebase should currently mean so cleanup work can remove contradiction without inventing new gameplay.

For the canonical field-system vocabulary covering `ambient field`,
`ambient field reveal`, `cell-field`, `plasma sheath`, and `plasma bridge`,
see `docs/FIELD_SYSTEM_ONTOLOGY.md`.

For the active rendering-language glossary, see
`docs/FIELD_VISUAL_LANGUAGE.md`.

## Core Roles

### Sphere
- charged core
- reservoir
- egg matter
- field source
- can be still while emitting a field
- movement is not required to prove field existence

### Crescent
- reflector
- protector
- aperture
- field shaper
- bounces triangles
- future: a crescent-sphere bond should reflect sphere energy inward and create a directional aperture

### Triangle
- heavy shard
- puncture hazard
- tool material
- should not behave like a self-propelled missile
- can wound spheres by impact
- bounces off crescents
- does not puncture crescents
- can eventually be grabbed by coils on the flat side only

### Coil
- rotor
- helper
- future grabber
- can spin from fields
- future: a coil on a crescent-sphere aperture becomes a super motor
- future: a coil can grab triangle flat sides

### Line
- deprecated as a player-facing cell
- its conceptual role should eventually be replaced by plasma bridges
- do not delete it casually while legacy code still depends on it
- any remaining `line` code path should be treated as legacy maintenance debt, not ontology truth

### Plasma Bridge
- future sphere-to-sphere energetic connection
- not implemented as a standalone cell

### Seedlings
- currently premature
- should be treated as debug / experimental until bonding and ontology stabilize
- current classifier still reflects older assumptions, especially around legacy `Line`

### Disease
- future chaotic / self-sustaining magnetic pattern
- not implemented now

## Current Internal Name Mapping

Current code still uses older geometry strings in several places:
- `round` => Sphere
- `wedge` or `triangle` => Triangle
- `spiral` => Coil
- `line` => Legacy Line
- `crescent` => Crescent

This naming debt is known.
Do not perform a risky global rename until runtime behavior is verified and cleanup work has reduced the surrounding slop.

## Maintenance Rules

- Favor small, mechanical cleanup over feature invention.
- Do not treat dormant legacy paths as proof that a concept is still part of the intended design.
- Do not treat visual debug representations as ontology truth when the simulation model disagrees.
- If code and ontology disagree, document the mismatch first, then change one layer at a time.
