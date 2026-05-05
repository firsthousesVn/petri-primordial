# Petri Primordial — Field Ecology Visual Contract

## Project identity

Petri Primordial is a medium-first artificial-life ecosystem.

The cells do not live on a black background. They live inside a visible energetic medium.

The ambient medium is a wavy grid blanket. This grid is the literal environment. It is both visual language and mechanical substrate.

Cells are luminous dipole-like organisms embedded in that medium. They slightly distort the grid like shallow gravity/plasma wells. Their fields interact through overlap, deformation, attraction, bond pressure, and eventual coupling.

The target feel is:

- spacetime grid blanket
- shallow gravity-like wells
- compact magnetic dipole topology
- magnetic reconnection behavior
- hot plasma material
- biological/artificial-life behavior

Gravity-like, but not pure gravity.
Magnetic-like, but not textbook line art.
Plasma-like, but not random flame/noise.

## Non-negotiable negative examples

Never produce these as the primary cell-field visual:

- spider legs
- whiskers
- tentacles
- long open streamlines
- loose ribbons
- broken contour geometry
- polygon hulls
- metaball blobs
- wrapper shells around smaller fields
- separate cluster halos around independent cell fields
- static decorative loops that ignore other cells

If any implementation produces those shapes, revert or replace that rendering path.

## Ambient medium

The ambient field visual is only the wavy grid blanket.

No streamline ambient mode.
No alternate ambient field visualization.
No debug streamlines as default.

The grid should:

- move like a subtle wave/current
- show shallow wells around cells
- show saddle distortion between interacting cells
- show stronger distortion around coupled/bonded cells
- agree with cell drift direction

## Isolated sphere target

One isolated sphere should show:

- luminous core
- compact stable dipole/plasma field
- organized polarity lobes/arcs
- contained energy
- no long lines leaving the sphere
- no spider/ribbon behavior

The dipole state is the starting state, not something traced into existence.

## Nearby sphere target

Two nearby spheres should show:

- near-side field deformation first
- shared saddle/pressure zone between them
- attraction beginning from overlap
- field arcs/lobes bending through the shared field

Do not draw two static independent dipoles side by side.

## Bonded/coupled sphere target

Bonded or strongly interacting cells should show:

- one coupled shared field configuration
- still based on polarity/dipole/plasma arc language
- no separate outer wrapper
- no blob hull
- no two independent fields trapped inside a bigger ring

The fields themselves couple. Nothing extra wraps them.

## Mechanics rule

Field overlap is the beginning of interaction.

No overlap: little or no attraction.
Shallow overlap: weak pull and slight deformation.
Moderate compatible overlap: stronger pull and bond pressure.
Incompatible overlap: compression, turbulence, possible repulsion.
Bonded overlap: stabilized coupled field.

Attraction must not be a nearest-cell seek hack. It should emerge from field overlap and compatibility.

## Code rule

There should be one shared field model used by mechanics and rendering where practical.

Avoid duplicate field ontologies.
Avoid visual-only plasma hacks.
Avoid keeping failed renderers as fallbacks.

PetriDish.gd should trend toward coordinator responsibilities. Field math, interaction, rendering, and debug should be separated when practical.
