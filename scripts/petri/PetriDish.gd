extends Node2D
class_name PetriDish

const DISH_RADIUS: float = 320.0
const SURFACE_COLOR: Color = Color(0.018, 0.020, 0.038, 1.0)
const SURFACE_INNER_TINT: Color = Color(0.045, 0.040, 0.075, 1.0)
const RIM_OUTER: Color = Color(0.55, 0.70, 0.95, 0.55)
const RIM_INNER: Color = Color(0.85, 0.92, 1.00, 0.85)
const DUST_COUNT: int = 110
var ENABLE_BONDS: bool = true
# Readability / maintenance flags. Keep legacy and experimental paths explicit
# so they do not silently define the default project behavior.
const ENABLE_EXPERIMENTAL_GUIDANCE: bool = true
# Legacy player-facing cell types. When false, Line is hidden from the hotbar
# and number keys, but every Line code path (signature, bonds, classifier,
# rendering) remains intact for backward compatibility and dev/debug spawns.
const ENABLE_LEGACY_LINE_CELL: bool = false
const ENABLE_SEEDLING_CLASSIFICATION: bool = false
const ENABLE_MAG_LEGACY_VISUALS: bool = false
const ENABLE_STARTUP_AUTOSPAWN: bool = false

const SPAWN_COUNT: int = 0
const SPAWN_MARGIN: float = 24.0
const SPAWN_SPEED_MAX: float = 8.0
const SPAWN_INPUT_DEDUP_MS: int = 120
const SPAWN_INPUT_DEDUP_DIST: float = 18.0
const DELETE_PICK_PAD: float = 12.0
const CAMERA_ZOOM_MIN: float = 0.45
const CAMERA_ZOOM_MAX: float = 2.20
const CAMERA_ZOOM_STEP: float = 0.12
const CAMERA_ZOOM_SMOOTH: float = 12.0
const CAMERA_PAN_SMOOTH: float = 14.0
const CAMERA_PAN_KEYBOARD_SPEED: float = 460.0
const CAMERA_PAN_FAST_MULTIPLIER: float = 2.0
const CAMERA_PAN_SLOW_MULTIPLIER: float = 0.45
const CAMERA_PAN_LIMIT: float = DISH_RADIUS * 1.85
const FIELD_GRID: int = 64
const MAG_FIELD_STRENGTH: float = 900.0
const MAG_FIELD_ROUND_WEIGHT: float = 1.0
const MAG_FIELD_OTHER_WEIGHT: float = 0.18
const MAG_FIELD_SOFTEN_RADIUS: float = 18.0
const MAG_FIELD_MAX_STRENGTH: float = 64.0
const MAG_FIELD_SIM_MODEL: String = "radial_charge_centers"
# Canonical field ontology:
# - ambient field = dish-wide medium
# - ambient field reveal = visible macro overlay
# - cell-field = base property of every CellBody (polarity axis, strength,
#   reach, arcs); shared system, per-type expression
# - cell-field arcs = visual expression of cell-field
# - plasma sheath = cell body surface energy (separate layer)
# - plasma bridge = connection conduit (only for actual bonds)
# Do not introduce separate "macro field" or "arc field" systems, and the
# cell-field is NOT a sphere-only effect.
const AMBIENT_FIELD_ENABLED: bool = true
const AMBIENT_FIELD_STRENGTH: float = 18.0
const AMBIENT_FIELD_SCALE: float = 0.0085
const AMBIENT_FIELD_TIME_SPEED: float = 0.10
const AMBIENT_FIELD_VORTEX_GAIN: float = 0.72
const AMBIENT_FIELD_FLOW_GAIN: float = 1.00
const AMBIENT_FIELD_PULSE_GAIN: float = 0.12
const AMBIENT_FIELD_PULSE_SPEED: float = 0.24
const AMBIENT_FIELD_REVEAL_ENABLED: bool = true
const AMBIENT_FIELD_REVEAL_KEY: String = ";"
const TOTAL_FIELD_ENABLED: bool = true
const TOTAL_FIELD_AMBIENT_WEIGHT: float = 1.0
const TOTAL_FIELD_MAGNETIC_WEIGHT: float = 1.0
const TOTAL_FIELD_MAX_STRENGTH: float = 80.0
# LEGACY ALIAS: "macro field" means the visible ambient-field reveal overlay,
# not a separate simulation system.
const MACRO_FIELD_ENABLED: bool = AMBIENT_FIELD_ENABLED
const MACRO_FIELD_REVEAL_ENABLED: bool = AMBIENT_FIELD_REVEAL_ENABLED
const MACRO_FIELD_REVEAL_KEY: String = AMBIENT_FIELD_REVEAL_KEY
const MACRO_FIELD_LINE_COUNT: int = 12
# Streamlines are integrated forward + backward from each persistent seed.
# STEP_COUNT is the total path length in segments; STEP_SIZE is per-segment
# integration distance in dish-local pixels. step_count * step_size sets the
# visual streamline length (~80 * 6 = ~480 px ≈ 1.5 dish radii).
const MACRO_FIELD_STEP_COUNT: int = 80
const MACRO_FIELD_STEP_SIZE: float = 6.0
const MACRO_FIELD_WIDTH: float = 1.4
const MACRO_FIELD_GLOW_WIDTH: float = 5.6
const MACRO_FIELD_ALPHA: float = 0.085
# Drift/spring: each seed advects along the field at this speed (px/sec) and
# is gently pulled back to its anchor so it never wanders out of the dish.
# This is the only "advection" mechanic — there is no reseeding.
const MACRO_FIELD_ADVECTION_SPEED: float = 18.0
const MACRO_FIELD_ANCHOR_SPRING: float = 0.55
const MACRO_FIELD_DISTORTION_GAIN: float = 1.10
const MACRO_FIELD_GRADIENT_BRIGHTNESS: float = 1.40
const MACRO_FIELD_CLUSTER_DISTORTION_GAIN: float = 1.30
# Calm fade: alpha multiplier in regions with negligible total field.
# 0 = lines vanish in calm zones; 1 = always full alpha. 0.18 keeps a hint
# of presence without lighting up the whole dish.
const MACRO_FIELD_CALM_FADE: float = 0.18
# Per-line shimmer phase rate (subtle width breathe, NOT studded ticks).
const MACRO_FIELD_SHIMMER_SPEED: float = 0.55
# Reseed interval in seconds. 0 disables reseeding (preferred — seeds drift
# under spring/advection forever). Kept as escape hatch only.
const MACRO_FIELD_RESEED_INTERVAL: float = 0.0
# Max distance from line sample to a bonded sphere bond midpoint that still
# counts as "near a plasma bridge" for the cluster distortion brightening.
const MACRO_FIELD_CLUSTER_PROXIMITY_RADIUS: float = 36.0
# --- Cell-field overlay (legacy file name: local plasma) ---
# Active runtime path for per-cell energetic presence:
# - plasma sheath close to the body
# - local energetic atmosphere close to the body
# - bond bridge throat for strong resolved connections
# Legacy file / constant names are retained to avoid a risky broad rename,
# but this overlay is now the support layer under the main polarity-arc
# cell-field path, not a Sphere-only aura.
const PLASMA_SHEATH_ENABLED: bool = true
const LOCAL_PLASMA_SHADER_ENABLED: bool = PLASMA_SHEATH_ENABLED
# Master gate for the legacy primitive plasma layers (per-cell polyline halo
# in CellBody, cluster sheath contour in this script). Off by default —
# kept available for A/B comparison and rollback only.
const LOCAL_PLASMA_LEGACY_DRAW: bool = false
const LOCAL_PLASMA_MAX_SOURCES: int = 24
const LOCAL_PLASMA_INNER_WIDTH: float = 0.55
const LOCAL_PLASMA_OUTER_WIDTH: float = 1.85
const LOCAL_PLASMA_CORE_ALPHA: float = 0.48
const LOCAL_PLASMA_GLOW_ALPHA: float = 0.32
const LOCAL_PLASMA_BRIGHTNESS: float = 0.95
const LOCAL_PLASMA_EDGE_SOFTNESS: float = 0.30
const LOCAL_PLASMA_COLOR_CORE: Color = Color(0.92, 0.97, 1.00, 1.0)
const LOCAL_PLASMA_COLOR_MID: Color = Color(0.30, 0.65, 1.00, 1.0)
const LOCAL_PLASMA_COLOR_OUTER: Color = Color(0.10, 0.18, 0.55, 1.0)
const LOCAL_PLASMA_NOISE_SCALE: float = 0.0150
const LOCAL_PLASMA_NOISE_SPEED: float = 0.45
const LOCAL_PLASMA_FBM_OCTAVES: int = 4
const LOCAL_PLASMA_WARP_SCALE: float = 0.018
const LOCAL_PLASMA_WARP_GAIN: float = 32.0
const LOCAL_PLASMA_WARP_SPEED: float = 0.30
const LOCAL_PLASMA_FLOW_SPEED: float = 0.55
# Legacy internal shader-arc controls. Disabled in the canonical runtime:
# visible cell-field arcs are drawn by the cell-field overlay path below.
const CELL_FIELD_ARC_ENABLED: bool = false
const LOCAL_PLASMA_SHADER_ARC_BASE_ALPHA: float = 0.36
const LOCAL_PLASMA_SHADER_ARC_BASE_WIDTH: float = 0.088
const LOCAL_PLASMA_SHADER_ARC_GLOW_ALPHA: float = 0.24
const LOCAL_PLASMA_SHADER_ARC_MOTION_SPEED: float = 0.72
const LOCAL_PLASMA_SHADER_ARC_MOTION_AMPLITUDE: float = 0.085
const LOCAL_PLASMA_SHADER_AMBIENT_BEND_GAIN: float = 0.40
const LOCAL_PLASMA_SHADER_ATTRACTION_BEND_GAIN: float = 1.08
const SPHERE_CELL_FIELD_REACH_MULTIPLIER: float = 1.28
const COIL_CELL_FIELD_TORSION_GAIN: float = 0.92
const CRESCENT_CELL_FIELD_FUNNEL_GAIN: float = 0.82
const TRIANGLE_CELL_FIELD_EDGE_GAIN: float = 0.58
const SPHERE_FIELD_ARC_MULTIPLIER: float = SPHERE_CELL_FIELD_REACH_MULTIPLIER
const COIL_FIELD_TORSION_GAIN: float = COIL_CELL_FIELD_TORSION_GAIN
const CRESCENT_FIELD_FUNNEL_GAIN: float = CRESCENT_CELL_FIELD_FUNNEL_GAIN
const TRIANGLE_FIELD_EDGE_GAIN: float = TRIANGLE_CELL_FIELD_EDGE_GAIN
const LOCAL_PLASMA_TERRITORY_REACH: float = 5.80
const LOCAL_PLASMA_TENDRIL_DENSITY: float = 1.25
const LOCAL_PLASMA_TENDRIL_SOFTNESS: float = 0.62
const LOCAL_PLASMA_TENDRIL_FLOW_SPEED: float = 0.82
const LOCAL_PLASMA_ATTRACTION_BEND_GAIN: float = 1.05
const LOCAL_PLASMA_LOBE_GAIN: float = 0.52
const LOCAL_PLASMA_BONDED_UNIFICATION_GAIN: float = 1.12
const LOCAL_PLASMA_ATTRACTION_RANGE: float = 8.20
# Half-extent of the overlay rect. The shader discards pixels far from any
# source, so making this larger than the dish only costs a few cheap fragment
# evals at the screen edges.
const LOCAL_PLASMA_OVERLAY_EXTENT: float = 1024.0
# Lower bound on intensity passed to the shader so even depleted cells still
# retain a faint local field presence. Keeps the overlay from popping in/out
# as charge wobbles.
const LOCAL_PLASMA_MIN_INTENSITY: float = 0.18

# --- Bonded sphere shared field ---
# When two spheres are bonded the local plasma shader fuses their kernels
# via a per-bond capsule term that brightens the throat between them. The
# transition from "two separate halos" to "one shared sheath" must ramp
# smoothly with bond stability so freshly captured bonds do not visually
# pop. These constants drive that ramp and the visual character of the
# resulting plasma bridge.
const PLASMA_MERGE_STABILITY_THRESHOLD: float = 0.55  # bond age (sec) at which merge factor approaches 1.0
const PLASMA_MERGE_TRANSITION_SPEED: float = 3.5      # 1/s lerp rate toward target merge factor
const PLASMA_MERGE_STRAIN_SUPPRESSION: float = 0.85   # how strongly strain pulls the throat apart
const PLASMA_MERGE_NOISE_SUPPRESSION: float = 0.55    # how strongly cell noise resists a clean merge
# Implicit field tunables (passed through to the shader's per-source kernel
# via softness; values here are the GDScript-side ramp controls so we do not
# rely on shader recompiles for tuning).
const PLASMA_IMPLICIT_FIELD_GAIN: float = 1.0
const PLASMA_IMPLICIT_FIELD_THRESHOLD: float = 0.10
const PLASMA_IMPLICIT_FIELD_SOFTNESS: float = 0.55
# Capsule (bridge) tunables.
const PLASMA_CLUSTER_SHARED_GAIN: float = 1.20
const PLASMA_BRIDGE_CORE_WIDTH: float = 0.85   # capsule radius as fraction of avg sphere radius
const PLASMA_BRIDGE_GLOW_WIDTH: float = 1.40   # capsule radius for outer glow component (multiplier)
const PLASMA_BRIDGE_ALPHA: float = 0.95
const PLASMA_BRIDGE_BRIGHTNESS: float = 1.20   # forwarded to shader bridge_gain
const PLASMA_BRIDGE_FLOW_SPEED: float = 0.65
const PLASMA_BRIDGE_STRESS_FLICKER: float = 0.55
# Suppress per-source intensity for cells that are bonded into a shared
# field so the cores do not overpower the merged sheath. 0 = no
# suppression (separate cores stay bright), 1 = sources fully replaced by
# the bridge term (cores vanish).
const PLASMA_CLUSTER_MEMBER_SUPPRESSION: float = 0.45

const PLASMA_BRIDGE_ENABLED: bool = true
const PLASMA_CONNECTION_ENABLED: bool = PLASMA_BRIDGE_ENABLED
const PLASMA_CONNECTION_WIDTH: float = 2.3
const PLASMA_CONNECTION_GLOW_WIDTH: float = 6.2
const PLASMA_CONNECTION_ALPHA: float = 0.34
const PLASMA_CONNECTION_BRIGHTNESS_GAIN: float = 0.58
const PLASMA_CONNECTION_FLOW_SPEED: float = 0.42
const PLASMA_CONNECTION_PULSE_GAIN: float = 0.28
const PLASMA_CONNECTION_DISTORTION_GAIN: float = 7.0
const PLASMA_CONNECTION_STRAIN_FLICKER_GAIN: float = 0.36
const PLASMA_CONNECTION_STABLE_SMOOTHING: float = 0.72
# Shared cluster sheath. Bonded cells (cluster size >= 2) are wrapped by a
# single smooth metaball-style outline so the plasma reads as one continuous
# field with necks at contact zones, not a stack of per-cell rings. The per-cell
# sheath in CellBody fades out with bond count to leave room for this layer.
const CLUSTER_SHEATH_ENABLED: bool = true
const CLUSTER_SHEATH_SAMPLES: int = 96
const CLUSTER_SHEATH_BISECT_STEPS: int = 16
const CLUSTER_SHEATH_THICKNESS: float = 1.18    # cell.radius multiplier feeding the metaball blob
const CLUSTER_SHEATH_ISO: float = 1.0           # iso-value for the metaball field
const CLUSTER_SHEATH_BREATHE_SPEED: float = 0.35
const CLUSTER_SHEATH_BREATHE_GAIN: float = 0.04 # ±4% iso modulation
const CLUSTER_SHEATH_GLOW_WIDTH: float = 5.0
const CLUSTER_SHEATH_CORE_WIDTH: float = 1.6
const CLUSTER_SHEATH_GLOW_ALPHA: float = 0.13
const CLUSTER_SHEATH_CORE_ALPHA: float = 0.30
const CLUSTER_SHEATH_BRIGHTNESS_GAIN: float = 1.10
# LEGACY_VISUAL_PATH: sampled streamlines, contours, and pole markers are kept
# for inspection only. The default runtime visual path is the projected
# polarity-arc cell-field overlay.
const MAG_FIELD_DRAW_STEP: float = 10.0
const MAG_FIELD_DRAW_STEPS: int = 40
const MAG_FIELD_DRAW_MIN: float = 0.12
const MAG_FIELD_DRAW_MAX_LINES: int = 52
const MAG_FIELD_DRAW_SEED_PAD: float = 14.0  # used by debug probe placement
const MAG_FIELD_DRAW_EDGE_PAD: float = 6.0
const MAG_FIELD_DRAW_GLOW_ALPHA: float = 0.38
const MAG_FIELD_DRAW_CORE_ALPHA: float = 0.88
const MAG_FIELD_DRAW_GLOW_WIDTH: float = 6.0
const MAG_FIELD_DRAW_CORE_WIDTH: float = 2.7
const MAG_FIELD_SHOW_SAMPLED_STREAMLINES: bool = false
# Direction ticks along each streamline. Small chevrons pointing along the
# local field tangent so the diagram reads as oriented flow, not just curves.
const MAG_FIELD_TICK_EVERY_N_POINTS: int = 5
const MAG_FIELD_TICK_LENGTH: float = 4.0
const MAG_FIELD_TICK_ALPHA: float = 0.55
const MAG_FIELD_TICK_WIDTH: float = 1.0
# --- Polarity arc cell-field layer (legacy magnetic naming retained) ---
# The live local cell-field arcs use a polarity-style visualization model:
# every projected cell-field is treated as having two field sides / poles.
# Spheres remain the strongest projectors; other cell types inherit the same
# two-sided arc logic with weaker and more shape-biased expression.
# The simulation sampler `sample_magnetic_field` is unchanged.
const CELL_FIELD_ENABLED: bool = true
const CELL_FIELD_POLARITY_ARCS_ENABLED: bool = CELL_FIELD_ENABLED
# --- Base cell-field controls (shared across every cell) ---
# Every cell expresses the same base field of effect: two polarity lobes and a
# clean arc family bent by ambient + nearby cell-fields. These constants drive
# the shared system; per-type *_MULT constants below scale individual cell
# types without bypassing the base path.
const CELL_FIELD_BASE_STRENGTH: float = 1.0
const CELL_FIELD_BASE_REACH: float = 1.0
# Canonical generic-field controls. Aliases of the existing CELL_FIELD_ARC_*
# names, exposed under the shorter base names so the same vocabulary applies
# to every cell type. Don't expand this list unless a new control is real.
const CELL_FIELD_AMBIENT_BEND_GAIN: float = CELL_FIELD_ARC_AMBIENT_BEND_GAIN
const CELL_FIELD_NEIGHBOR_BEND_GAIN: float = CELL_FIELD_ARC_NEIGHBOR_BEND_GAIN
const CELL_FIELD_PHASE_SPEED: float = CELL_FIELD_ARC_PHASE_SPEED
const CELL_FIELD_BREATH_GAIN: float = CELL_FIELD_ARC_BREATH_GAIN
const CELL_FIELD_FADE_POWER: float = CELL_FIELD_ARC_FADE_POWER
const SPHERE_FIELD_STRENGTH_MULT: float = 1.00
const SPHERE_FIELD_REACH_MULT: float = SPHERE_CELL_FIELD_REACH_MULTIPLIER
const COIL_FIELD_STRENGTH_MULT: float = 0.65
const COIL_FIELD_TORSION_MULT: float = COIL_CELL_FIELD_TORSION_GAIN
const CRESCENT_FIELD_STRENGTH_MULT: float = 0.55
const CRESCENT_FIELD_FUNNEL_MULT: float = CRESCENT_CELL_FIELD_FUNNEL_GAIN
const TRIANGLE_FIELD_STRENGTH_MULT: float = 0.42
const TRIANGLE_FIELD_REACH_MULT: float = 0.78
const TRIANGLE_FIELD_EDGE_MULT: float = TRIANGLE_CELL_FIELD_EDGE_GAIN
const MAG_FIELD_VIS_POLE_OFFSET_RATIO: float = 1.03  # pole offset from sphere center, fraction of radius
const MAG_FIELD_VIS_POLE_SOFTEN: float = 7.0          # px Plummer soften per visualization pole
const MAG_FIELD_VIS_LINES_PER_POLE: int = 5           # streamlines seeded per source (+) pole
const MAG_FIELD_VIS_SEED_PAD: float = 4.0             # px from pole position before seeding
const MAG_FIELD_VIS_SEED_SPREAD: float = 1.30         # rad max angular spread of seeds per pole
const MAG_FIELD_VIS_TERMINATE_RADIUS: float = 4.5     # px; line ends when this close to opposite pole
const MAG_FIELD_VIS_FOCUS_TIP_SCALE: float = 0.55     # crescent tip virtual-pole strength relative to sphere
const MAG_FIELD_VIS_FOCUS_TIP_OFFSET: float = 0.85    # tip distance as fraction of crescent radius
const MAG_FIELD_VIS_POLE_MARK_RADIUS: float = 4.8     # +/- glyph radius drawn at each pole
const MAG_FIELD_VIS_POLE_N_COLOR: Color = Color(1.00, 0.60, 0.45, 0.95)
const MAG_FIELD_VIS_POLE_S_COLOR: Color = Color(0.45, 0.78, 1.00, 0.95)
const MAG_FIELD_VIS_STYLE: String = "sphere_attached"
const MAG_FIELD_SHOW_POLE_MARKERS: bool = false
const MAG_FIELD_SHOW_CONTOURS: bool = false
const CELL_FIELD_ARC_COUNT: int = 1
const CELL_FIELD_ARC_MIN_LENGTH: float = 2.60
const CELL_FIELD_ARC_MAX_LENGTH: float = 6.40
const CELL_FIELD_ARC_STEP_COUNT: int = 16
const CELL_FIELD_ARC_WIDTH: float = 1.18
const CELL_FIELD_ARC_ALPHA: float = 0.42
const CELL_FIELD_ARC_GLOW_ALPHA: float = 0.20
const CELL_FIELD_ARC_FADE_POWER: float = 1.18
const CELL_FIELD_ARC_AMBIENT_BEND_GAIN: float = 0.82
const CELL_FIELD_ARC_NEIGHBOR_BEND_GAIN: float = 1.55
const CELL_FIELD_ARC_PHASE_SPEED: float = 1.12
const CELL_FIELD_ARC_BREATH_GAIN: float = 0.18
const CELL_ARC_COUNT: int = CELL_FIELD_ARC_COUNT
const CELL_ARC_WIDTH: float = CELL_FIELD_ARC_WIDTH
const CELL_ARC_GLOW_WIDTH: float = 2.90
const CELL_ARC_ALPHA: float = CELL_FIELD_ARC_ALPHA
const CELL_ARC_GLOW_ALPHA: float = CELL_FIELD_ARC_GLOW_ALPHA
const CELL_ARC_TAPER: float = CELL_FIELD_ARC_FADE_POWER
const CELL_ARC_MOTION_SPEED: float = CELL_FIELD_ARC_PHASE_SPEED
const CELL_ARC_PULSE_GAIN: float = 0.08
const CELL_ARC_AMBIENT_BEND_GAIN: float = CELL_FIELD_ARC_AMBIENT_BEND_GAIN
const CELL_ARC_NEIGHBOR_BEND_GAIN: float = CELL_FIELD_ARC_NEIGHBOR_BEND_GAIN
const MAG_FILAMENT_COUNT: int = CELL_ARC_COUNT
const MAG_FILAMENT_CORE_WIDTH: float = CELL_ARC_WIDTH
const MAG_FILAMENT_GLOW_WIDTH: float = CELL_ARC_GLOW_WIDTH
const MAG_FILAMENT_CORE_ALPHA: float = CELL_ARC_ALPHA
const MAG_FILAMENT_GLOW_ALPHA: float = CELL_ARC_GLOW_ALPHA
const MAG_FILAMENT_TAPER: float = CELL_ARC_TAPER
const MAG_FILAMENT_INTERACTION_BRIGHTNESS: float = 0.26
const MAG_FILAMENT_PULSE_SPEED: float = CELL_ARC_MOTION_SPEED
const MAG_FILAMENT_PULSE_GAIN: float = CELL_ARC_PULSE_GAIN
const MAG_FIELD_CONTOUR_ALPHA: float = 0.045
# Legacy compact-loop tunables retained for rollback/reference only.
const MAG_FIELD_SPHERE_LOOP_LATERAL_MIN: float = 1.05
const MAG_FIELD_SPHERE_LOOP_LATERAL_MAX: float = 2.15
const MAG_FIELD_SPHERE_LOOP_AXIS_PUSH_MIN: float = 0.92
const MAG_FIELD_SPHERE_LOOP_AXIS_PUSH_MAX: float = 1.95
const MAG_FIELD_SPHERE_LOOP_ENDPOINT_SPREAD: float = 0.48
const MAG_FIELD_SPHERE_LOOP_SEGMENTS: int = 40
# Scalar equipotential contours per round cell. Radii are multiples of the
# Plummer soften radius (max(MAG_FIELD_SOFTEN_RADIUS, cell.radius * 0.85)).
const MAG_FIELD_CONTOUR_LEVELS := [0.7, 1.1, 1.7, 2.6, 4.0, 6.0]
const MAG_FIELD_CONTOUR_SEGMENTS: int = 64
const MAG_FIELD_CONTOUR_BASE_ALPHA: float = 0.06
const MAG_FIELD_CONTOUR_CHARGE_GAIN: float = 0.18
const MAG_FIELD_CONTOUR_STRENGTH_GAIN: float = 0.22
const MAG_FIELD_CONTOUR_ALPHA_CAP: float = MAG_FIELD_CONTOUR_ALPHA
const MAG_FIELD_CONTOUR_WIDTH: float = 1.4
const MAG_FIELD_CONTOUR_DEPLETED_TINT: Color = Color(0.45, 0.78, 1.00, 1.0)
const MAG_FIELD_CONTOUR_HEALTHY_TINT: Color = Color(0.66, 0.92, 1.00, 1.0)
const MAG_FIELD_CONTOUR_OVERCHARGED_TINT: Color = Color(1.00, 0.62, 0.86, 1.0)

# --- bond limits ---
const MAX_TOTAL_BONDS: int = 60
const MAX_BONDS_PER_CELL: int = 4

# --- bond formation ---
const BOND_SCAN_HZ: float = 12.0
const BOND_CENTER_RANGE: float = 30.0          # extra px beyond combined radii to consider
const ANCHOR_PROXIMITY: float = 30.0           # max anchor-to-anchor distance to consider
const FACE_DOT_MAX: float = -0.10              # normals must oppose at least this much
const BOND_MIN_CHARGE_RATIO: float = 0.12
const BOND_FORM_COST_RATIO: float = 0.04
const BOND_NOISE_LIMIT: float = 1.8

# --- bond physics (per-type spring multipliers) ---
const BOND_SPRING_BASE: float = 80.0
const BOND_DAMP_BASE: float = 22.0          # near-critical damping with a stronger capture settle
const BOND_SUBSTEPS: int = 2                # substep bond physics for stiff-spring stability
const MAX_FRAME_DELTA: float = 1.0 / 30.0   # clamp dt so a hitch can't blow up integration

# --- cell-cell soft collision (PBD-style position projection) ---
const COLLISION_PADDING: float = 0.0
const COLLISION_VEL_DAMP: float = 0.50      # fraction of closing velocity removed on contact
const COLLISION_SLOP: float = 0.5           # ignore penetration smaller than this (prevents micro-jitter)

# --- cluster-coherent motion (bonded cells move together) ---
const CLUSTER_VEL_COUPLING: float = 18.0    # rate at which member velocity blends toward cluster mean
const CLUSTER_ANG_COUPLING: float = 22.0    # same for angular velocity
const CLUSTER_BROWNIAN_SCALE: float = 0.14  # cluster Brownian relative to free-cell Brownian
# Rigid-body cluster motion: how the shared cluster angular velocity is
# composed from translational angular momentum vs. average per-cell spin.
# Weights should sum to ~1.0; lower trans weight = looser rotational coupling.
const CLUSTER_OMEGA_TRANS_WEIGHT: float = 0.65
const CLUSTER_OMEGA_SPIN_WEIGHT: float = 0.35
const CLUSTER_INERTIA_FLOOR: float = 1.0    # px²; below this we skip omega_trans (members are coincident)
const FREE_BROWNIAN_BASE: float = 1.6       # free-cell drift; seeking should dominate over this

# --- anchor seating (PBD position projection toward bond rest distance) ---
# Tuned conservatively so the spring-damper system in _update_bonds owns the
# motion. Seating used to apply up to 6 px/frame of position correction with a
# 0.30 rate, which produced visible "lurches" each time a settled bond drifted
# slightly past the deadzone. Smaller deadzone+rate+cap keeps PBD as a stiff
# stability backstop rather than a primary motion driver, so bonded clusters
# settle and breathe rather than micro-snapping.
const BOND_ANCHOR_DEADZONE: float = 3.5     # px of stretch error tolerated before seating fires
const SEAT_RATE_BASE: float = 0.12          # fraction of error corrected per frame
const SEAT_RATE_CAPTURE: float = 0.45       # capture seating fraction; sub-1 to avoid overshoot
# Per-frame relative-motion damping between bonded endpoints. These run in
# addition to the per-bond-type linear damp so settled bonds stop fighting each
# other once the spring is at rest. Values are 1/s (used as lerp(rel, mean, k*dt)).
const BOND_RELATIVE_VELOCITY_DAMPING: float = 6.0
const BOND_RELATIVE_ANGULAR_DAMPING: float = 8.0
# Scales down random Brownian impulses on bonded clusters in addition to
# CLUSTER_BROWNIAN_SCALE. 1.0 = no extra suppression, 0.0 = no random force.
const BONDED_RANDOM_FORCE_MULTIPLIER: float = 0.20

# --- sustained-strain bond breakage ---
const STRAIN_BREAK_DURATION: float = 0.60   # bond must be over BREAK threshold this long to actually break
const BOND_STRAIN_DEADZONE: float = 0.0025  # ignore micro-jitter strain below this per second

# --- seedling classification ---
const SEEDLING_HZ: float = 1.0
const SEEDLING_MIN_CELLS: int = 2
const SEEDLING_COHERENCE_MIN: float = 0.26
const CORE_ROUND_RATIO_MIN: float = 0.50
const CORE_STORAGE_MIN: float = 0.55
const CORE_NOISE_MAX: float = 0.35
const MOTOR_PUNCTURE_RATIO_MIN: float = 0.18
const MOTOR_BURST_MIN: float = 0.40
const MOTOR_ASYM_MIN: float = 0.18
const CONDUIT_LINE_RATIO_MIN: float = 0.45
const CONDUIT_CONDUCT_MIN: float = 0.42
const SHELL_TRIANGLE_RATIO_MIN: float = 0.50
const SHELL_PLATE_RATIO_MIN: float = 0.45
const BEND_CRESCENT_RATIO_MIN: float = 0.20
const BEND_POTENTIAL_MIN: float = 0.40
const HYBRID_SEED_MIN: float = 0.32
const SEEDLING_HALO_PAD: float = 14.0

# --- strain ---
const BOND_STRAIN_BREAK: float = 1.0
const BOND_STRAIN_RECOVERY: float = 0.05
const BOND_STRETCH_TOL: float = 5.0
const BOND_STRETCH_GAIN: float = 0.10
const BOND_NOISE_FLOOR: float = 1.0
const BOND_NOISE_GAIN: float = 0.55
const BOND_BREAK_FIELD_NOISE: float = 0.7
const BOND_BREAK_SELF_NOISE: float = 0.4

# --- triangle dash effect on attached weak bonds ---
const DASH_STRAIN_GAIN: float = 1.4

# --- triangle flat-plate alignment ---
const FLAT_PLATE_FACE_MAX: float = -0.85    # require near-antiparallel flat normals
const FLAT_PLATE_TWIST_GAIN: float = 0.9    # strain accumulation per second when twisted
const ANCHOR_TORQUE_GAIN: float = 0.030

# --- pre-bond guidance (charge-powered short-range field) ---
const GUIDANCE_RANGE: float = 86.0          # max anchor-pair distance to consider for guidance
const GUIDANCE_CAPTURE_RADIUS: float = 11.0 # close-range snap/capture threshold for valid contact
const GUIDANCE_ATTRACT_MAX: float = 58.0    # max attraction accel (px/s²) at full strength
const GUIDANCE_ALIGN_MAX: float = 12.0      # alignment torque coefficient
const GUIDANCE_REPEL_MAX: float = 96.0      # max repulsion accel for invalid contact
const GUIDANCE_REPEL_RANGE: float = 34.0    # below this anchor distance, invalid contact pushes
const GUIDANCE_INVALID_SLIDE: float = 22.0  # tangential slide added while invalid contacts peel apart
const GUIDANCE_CHARGE_MIN: float = 0.05     # ratio below which a cell mostly stops active seeking
const GUIDANCE_CHARGE_COST: float = 0.018   # charge spent per second on active guidance
const GUIDANCE_FAIL_NOISE: float = 0.18     # internal noise added per second on invalid close contact
const GUIDANCE_NEAR_CUTOFF: float = 2.5     # below this anchor distance, attraction tapers to zero
const GUIDANCE_CAPTURE_PULL: float = 160.0
const GUIDANCE_CAPTURE_ALIGN: float = 22.0
const GUIDANCE_CAPTURE_VEL_DAMP: float = 12.0
const GUIDANCE_CAPTURE_ANG_DAMP: float = 14.0
const GUIDANCE_ROUND_FIELD: float = 0.40
const GUIDANCE_TRIANGLE_ROUND_BONUS: float = 0.75
const GUIDANCE_TRIANGLE_LINE_BONUS: float = 0.35
const GUIDANCE_LINE_CHAIN_BONUS: float = 0.55
const GUIDANCE_CRESCENT_CRADLE_BONUS: float = 0.60
const GUIDANCE_PLATE_BONUS: float = 0.42

# --- capture state on bond formation ---
const CAPTURE_DURATION: float = 0.60
const CAPTURE_MIN_HOLD: float = 0.40
const CAPTURE_SPRING_MULT: float = 2.4
const CAPTURE_DAMP_MULT: float = 6.0
const CAPTURE_TORQUE_MULT: float = 3.8
const CAPTURE_ANGULAR_BLEED: float = 9.0    # per-second angular velocity bleed during capture
# Per-tick caps so a freshly formed bond seats over multiple frames instead of
# snapping. Linear caps are pixels per _seat_anchors call; angular caps are
# radians/sec per bond substep applied on top of the spring torque path.
const MAX_CAPTURE_LINEAR_CORRECTION: float = 2.4
const MAX_BASE_LINEAR_CORRECTION: float = 2.0
const MAX_CAPTURE_ANGULAR_CORRECTION: float = 0.30
const MAX_BASE_ANGULAR_CORRECTION: float = 0.40
const CAPTURE_REL_VEL_DAMP: float = 14.0    # relative velocity bleed between bond endpoints during capture
const CAPTURE_REL_ANG_DAMP: float = 16.0    # relative angular velocity bleed during capture

# --- post-capture jitter reduction ---
const BONDED_ANGULAR_DAMP: float = 2.0      # extra angular damp per bond per second

# --- charge flow rates per second (proportional to ratio diff) ---
const FLOW_LINE: float = 0.50
const FLOW_ROUND: float = 0.18
const FLOW_CRADLE: float = 0.08
const FLOW_HOOK: float = 0.10
const FLOW_PLATE: float = 0.12
const FLOW_PUNCTURE_DRAIN: float = 0.40       # only during dash; drains punctured cell
const FLOW_WEAK: float = 0.04

# --- clash transient ---
const CLASH_NOISE: float = 0.35
const CLASH_COOLDOWN: float = 0.6
const FX_CLASH_TTL: float = 0.18
const FX_CAPTURE_TTL: float = 0.24
const FX_BREAK_TTL: float = 0.22

const CellBodyScene: PackedScene = preload("res://scenes/petri/CellBody.tscn")
const SIG_ROUND: CellSignature = preload("res://resources/cells/RoundPearlCell.tres")
const SIG_TRIANGLE: CellSignature = preload("res://resources/cells/WedgeGlassCell.tres")
const SIG_LINE: CellSignature = preload("res://resources/cells/LineGlassCell.tres")
const SIG_CRESCENT: CellSignature = preload("res://resources/cells/CrescentSoftCell.tres")
const SIG_COIL: CellSignature = preload("res://resources/cells/CoilRotorCell.tres")
const MediumFieldScript: Script = preload("res://scripts/petri/MediumField.gd")
const MagneticFieldOverlayScript: Script = preload("res://scripts/petri/MagneticFieldOverlay.gd")
const LocalPlasmaOverlayScript: Script = preload("res://scripts/petri/LocalPlasmaOverlay.gd")
const LocalPlasmaShader: Shader = preload("res://resources/shaders/local_plasma.gdshader")

@onready var debug_label: Label = $HUD/DebugLabel
@onready var hotbar: CellHotbar = $HUD/Hotbar
@onready var camera: Camera2D = $Camera2D

var cells: Array[CellBody] = []
var bonds: Array[Bond] = []
var field: MediumField
var selected_cell_type: int = 0
var simulation_paused: bool = false
var hotbar_visible: bool = true
var debug_text_visible: bool = true
var _camera_pan_target: Vector2 = Vector2.ZERO
var _camera_zoom_target: float = 1.0
var _camera_dragging: bool = false
var _camera_drag_last_screen: Vector2 = Vector2.ZERO

var _bonded_pairs: Dictionary = {}      # pair_key -> Bond
var _bonded_anchors: Dictionary = {}    # anchor_key -> Bond
var _cell_bond_count: Dictionary = {}   # instance_id -> int
var _clash_cooldowns: Dictionary = {}   # pair_key -> seconds remaining
var _bond_scan_accum: float = 0.0
var _seedling_accum: float = 0.0
var _hud_accum: float = 0.0
var _clusters_snapshot: Array = []          # Array of Array[CellBody], rebuilt each frame
var _seedlings: Array = []                  # Array of Dictionary signatures, rebuilt at SEEDLING_HZ
var debug_seedlings: bool = false
var debug_magnetic_field: bool = false  # Legacy/internal debug toggle for field diagnostics.
var macro_field_reveal: bool = false    # LEGACY NAME: visible ambient-field reveal toggle.
var _debug_threads: Array = []
var _fx_pulses: Array = []
var _dust: PackedVector2Array = PackedVector2Array()
var _dust_size: PackedFloat32Array = PackedFloat32Array()
var _dust_alpha: PackedFloat32Array = PackedFloat32Array()
var _drift_phase: float = 0.0
var _simulation_time: float = 0.0
var _last_spawn_press_ms: int = -1000000
var _last_spawn_press_pos: Vector2 = Vector2(1e9, 1e9)
var _mag_debug_seed_count: int = 0
var _mag_debug_line_count: int = 0
var _mag_debug_point_count: int = 0
var _mag_debug_probe_strength: float = 0.0
var _mag_debug_probe_pos: Vector2 = Vector2.ZERO
var _mag_debug_sphere_sources: int = 0
var _mag_debug_nearest_sphere_charge: float = 0.0
var _mag_debug_mouse_contributors: int = 0
var _mag_debug_mouse_strength: float = 0.0
var _mag_debug_mouse_pos: Vector2 = Vector2.ZERO
var _mag_debug_mouse_vector: Vector2 = Vector2.ZERO
var _mag_debug_nearest_source_strength: float = 0.0
var _mag_debug_nearest_source_vector: Vector2 = Vector2.ZERO
var _mag_debug_primitive_count: int = 0
var _mag_debug_contour_count: int = 0
var _ambient_debug_mouse_strength: float = 0.0
var _ambient_debug_mouse_vector: Vector2 = Vector2.ZERO
var _ambient_debug_mouse_curl: float = 0.0
var _ambient_debug_mouse_calm: float = 1.0
var _total_debug_mouse_strength: float = 0.0
var _total_debug_mouse_vector: Vector2 = Vector2.ZERO
var _total_debug_mouse_gradient: Vector2 = Vector2.ZERO
var _ambient_debug_cell_label: String = "-"
var _ambient_debug_cell_vector: Vector2 = Vector2.ZERO
var _ambient_debug_cell_strength: float = 0.0
var _ambient_debug_cell_mode: String = "idle"
var _macro_field_primitive_count: int = 0
# Macro-field streamline state. Anchors are fixed at init; seeds drift
# slowly along the field with a spring back toward their anchor so the
# layout breathes without ever needing to reseed.
var _macro_field_anchors: PackedVector2Array = PackedVector2Array()
var _macro_field_seeds: PackedVector2Array = PackedVector2Array()
var _macro_field_phases: PackedFloat32Array = PackedFloat32Array()
var _macro_field_reseed_accum: float = 0.0
# Per-frame cache of bonded-sphere bond midpoints so streamline drawing can
# brighten where they pass through a plasma bridge without re-walking the
# bonds list inside the inner loop.
var _macro_field_bridge_midpoints: PackedVector2Array = PackedVector2Array()
var _plasma_connection_debug_count: int = 0
var _cluster_sheath_debug_count: int = 0
var _magnetic_overlay: Node2D
var _local_plasma_overlay: Node2D
# Per-frame cache for the magnetic source list. _collect_magnetic_sources()
# previously rebuilt a fresh Array[Dictionary] (one Dictionary per cell) on
# every sampler call. The streamline tracer + macro-field reveal call the
# samplers thousands of times per frame, which produced thousands of GC
# allocations and dominated frame time. Now built once at the start of
# _process via _refresh_magnetic_source_cache(), and any internal sampler
# that needs the source list reads _cached_magnetic_sources directly.
var _cached_magnetic_sources: Array[Dictionary] = []
var _cached_magnetic_sources_frame: int = -1
# Reusable buffers for per-frame uniform push so we do not allocate.
# Old code allocated a fresh Dictionary per cell + sort_custom lambda
# every frame. These typed parallel arrays replace that — fill in place,
# no GC churn.
var _local_plasma_positions: Array = []
var _local_plasma_radii: Array = []
var _local_plasma_intensities: Array = []
var _local_plasma_phases: Array = []
var _local_plasma_fields: Array = []
var _local_plasma_styles: Array = []
var _lp_weights: PackedFloat32Array = PackedFloat32Array()
var _lp_max_merges: PackedFloat32Array = PackedFloat32Array()
var _lp_cell_ids: PackedInt64Array = PackedInt64Array()
var _lp_cells: Array = []
var _lp_cell_to_idx: Dictionary = {}
var _lp_bond_segs: Array = []
var _lp_bond_prms: Array = []
# Reusable buffers for trail rendering. The old path did N-1 antialiased
# draw_line calls per cell; per Godot's polyline-batching benchmarks this
# was 40-50x slower than a single draw_polyline_colors call.
var _trail_points_buf: PackedVector2Array = PackedVector2Array()
var _trail_colors_buf: PackedColorArray = PackedColorArray()
const HUD_INTERVAL: float = 0.25

# Cluster snapshot
var _cluster_count: int = 0
var _largest_cluster: int = 0
var _best_coherence: float = 0.0
var _perf_monitors_registered: bool = false
var _perf_frame_ms: float = 0.0
var _perf_cluster_ms: float = 0.0
var _perf_bond_scan_ms: float = 0.0
var _perf_bond_update_ms: float = 0.0
var _perf_local_plasma_ms: float = 0.0
var _perf_macro_draw_ms: float = 0.0
var _perf_magnetic_draw_ms: float = 0.0
var _perf_cell_ambient_ms: float = 0.0
var _perf_ambient_field_samples: int = 0
var _perf_ambient_calm_samples: int = 0
var _perf_ambient_curl_samples: int = 0
var _perf_cell_ambient_us_accum: int = 0
var _perf_ambient_field_samples_accum: int = 0
var _perf_ambient_calm_samples_accum: int = 0
var _perf_ambient_curl_samples_accum: int = 0


func _ready() -> void:
	# Run after all child CellBody nodes so we have the final word on positions
	# (PBD anchor seating + cell-cell separation must come last each frame).
	process_priority = 100
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE
	_camera_pan_target = camera.position
	_camera_zoom_target = camera.zoom.x
	camera.make_current()
	debug_label.visible = debug_text_visible
	queue_redraw()
	_init_field()
	_init_magnetic_overlay()
	_init_local_plasma_overlay()
	_init_macro_field_seeds()
	_register_perf_monitors()
	if ENABLE_STARTUP_AUTOSPAWN and SPAWN_COUNT > 0:
		_spawn_cells(SPAWN_COUNT)
	_init_dust()
	_refresh_hotbar()
	_apply_pause_state()
	_update_debug()


func _exit_tree() -> void:
	_unregister_perf_monitors()


func _active_cell_kinds() -> Array[Dictionary]:
	# Single source of truth for player-spawnable cell types. Line is gated by
	# ENABLE_LEGACY_LINE_CELL; when false, Line is hidden from this list. All
	# Line-aware code (signatures, bond classifier, draw paths) is unchanged.
	var kinds: Array[Dictionary] = [
		{"label": "Sphere", "kind": "round", "sig": SIG_ROUND},
		{"label": "Triangle", "kind": "triangle", "sig": SIG_TRIANGLE},
	]
	if ENABLE_LEGACY_LINE_CELL:
		kinds.append({"label": "Line", "kind": "line", "sig": SIG_LINE})
	kinds.append({"label": "Crescent", "kind": "crescent", "sig": SIG_CRESCENT})
	kinds.append({"label": "Coil", "kind": "spiral", "sig": SIG_COIL})
	return kinds


func _hotbar_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var kinds: Array[Dictionary] = _active_cell_kinds()
	for i in kinds.size():
		var k: Dictionary = kinds[i]
		entries.append({
			"key": str(i + 1),
			"label": k["label"],
			"kind": k["kind"],
		})
	return entries


func _selected_cell_name() -> String:
	var kinds: Array[Dictionary] = _active_cell_kinds()
	if selected_cell_type < 0 or selected_cell_type >= kinds.size():
		return str(kinds[0]["label"])
	return str(kinds[selected_cell_type]["label"])


func _selected_signature_template() -> CellSignature:
	var kinds: Array[Dictionary] = _active_cell_kinds()
	if selected_cell_type < 0 or selected_cell_type >= kinds.size():
		return kinds[0]["sig"] as CellSignature
	return kinds[selected_cell_type]["sig"] as CellSignature


func _refresh_hotbar() -> void:
	if hotbar == null:
		return
	hotbar.visible = hotbar_visible
	hotbar.set_entries(_hotbar_entries(), selected_cell_type)


func _set_selected_cell_type(index: int) -> void:
	var max_index: int = maxi(0, _active_cell_kinds().size() - 1)
	if index < 0 or index > max_index:
		# Out-of-range key (e.g. KEY_4 with only 3 active kinds): no-op.
		return
	selected_cell_type = index
	_refresh_hotbar()
	_update_debug()


func _apply_pause_state() -> void:
	for cell in cells:
		cell.set_process(not simulation_paused)
	_update_debug()


func _set_bonds_enabled(enabled: bool) -> void:
	if ENABLE_BONDS == enabled:
		return
	ENABLE_BONDS = enabled
	if not ENABLE_BONDS:
		_clear_all_bonds()
		for cell in cells:
			cell.bonded_count = 0
			cell.capture_strength = 0.0
	_invalidate_cluster_cache()
	_bond_scan_accum = 0.0
	_seedling_accum = 0.0
	_sync_bonded_counts()
	_update_debug()
	queue_redraw()


func _init_dust() -> void:
	_dust.resize(DUST_COUNT)
	_dust_size.resize(DUST_COUNT)
	_dust_alpha.resize(DUST_COUNT)
	for i in DUST_COUNT:
		var ang: float = randf() * TAU
		var rad: float = sqrt(randf()) * (DISH_RADIUS - 6.0)
		_dust[i] = Vector2(cos(ang), sin(ang)) * rad
		_dust_size[i] = randf_range(0.4, 1.4)
		_dust_alpha[i] = randf_range(0.05, 0.22)


func _init_field() -> void:
	field = MediumFieldScript.new()
	field.configure(DISH_RADIUS, FIELD_GRID)
	add_child(field)
	move_child(field, 0)


func _init_magnetic_overlay() -> void:
	_magnetic_overlay = MagneticFieldOverlayScript.new()
	_magnetic_overlay.name = "MagneticFieldOverlay"
	_magnetic_overlay.set("dish", self)
	_magnetic_overlay.z_as_relative = false
	_magnetic_overlay.z_index = 100
	add_child(_magnetic_overlay)


func ambient_field_reveal_active() -> bool:
	return AMBIENT_FIELD_ENABLED and AMBIENT_FIELD_REVEAL_ENABLED and macro_field_reveal


func set_ambient_field_reveal(enabled: bool) -> void:
	macro_field_reveal = enabled


func cell_field_enabled() -> bool:
	return CELL_FIELD_ENABLED and CELL_FIELD_POLARITY_ARCS_ENABLED and _cell_field_visual_mode_active()


func plasma_sheath_enabled() -> bool:
	return PLASMA_SHEATH_ENABLED and LOCAL_PLASMA_SHADER_ENABLED and CellBody.LOCAL_PLASMA_ENABLED


func plasma_bridge_enabled() -> bool:
	return PLASMA_BRIDGE_ENABLED and PLASMA_CONNECTION_ENABLED


func _cell_field_visual_mode_active() -> bool:
	return MAG_FIELD_VIS_STYLE == "sphere_attached"


func _cell_field_visual_mode_label() -> String:
	if _cell_field_visual_mode_active():
		return "polarity_arcs"
	return "legacy:%s" % MAG_FIELD_VIS_STYLE


func _cell_field_sim_label() -> String:
	return MAG_FIELD_SIM_MODEL


func should_redraw_cell_field_overlay() -> bool:
	return cell_field_enabled() or ambient_field_reveal_active() or debug_magnetic_field


func should_redraw_magnetic_overlay() -> bool:
	return should_redraw_cell_field_overlay()


func perf_monitors_enabled() -> bool:
	return _perf_monitors_registered


func perf_note_cell_ambient_time(duration_us: int) -> void:
	_perf_cell_ambient_us_accum += maxi(duration_us, 0)


func perf_note_ambient_field_samples(count: int = 1) -> void:
	_perf_ambient_field_samples_accum += maxi(count, 0)


func perf_note_ambient_calm_samples(count: int = 1) -> void:
	_perf_ambient_calm_samples_accum += maxi(count, 0)


func perf_note_ambient_curl_samples(count: int = 1) -> void:
	_perf_ambient_curl_samples_accum += maxi(count, 0)


func _register_perf_monitors() -> void:
	_perf_monitors_registered = true
	_register_perf_monitor("Petri/Frame Time", "_perf_monitor_frame_time", Performance.MONITOR_TYPE_TIME)
	_register_perf_monitor("Petri/Cell Ambient Time", "_perf_monitor_cell_ambient_time", Performance.MONITOR_TYPE_TIME)
	_register_perf_monitor("Petri/Cluster Time", "_perf_monitor_cluster_time", Performance.MONITOR_TYPE_TIME)
	_register_perf_monitor("Petri/Bond Scan Time", "_perf_monitor_bond_scan_time", Performance.MONITOR_TYPE_TIME)
	_register_perf_monitor("Petri/Bond Update Time", "_perf_monitor_bond_update_time", Performance.MONITOR_TYPE_TIME)
	_register_perf_monitor("Petri/Local Plasma Time", "_perf_monitor_local_plasma_time", Performance.MONITOR_TYPE_TIME)
	_register_perf_monitor("Petri/Macro Draw Time", "_perf_monitor_macro_draw_time", Performance.MONITOR_TYPE_TIME)
	_register_perf_monitor("Petri/Magnetic Draw Time", "_perf_monitor_magnetic_draw_time", Performance.MONITOR_TYPE_TIME)
	_register_perf_monitor("Petri/Ambient Field Samples", "_perf_monitor_ambient_field_samples")
	_register_perf_monitor("Petri/Ambient Calm Samples", "_perf_monitor_ambient_calm_samples")
	_register_perf_monitor("Petri/Ambient Curl Samples", "_perf_monitor_ambient_curl_samples")


func _unregister_perf_monitors() -> void:
	if not _perf_monitors_registered:
		return
	_perf_monitors_registered = false
	for monitor_name in [
		"Petri/Frame Time",
		"Petri/Cell Ambient Time",
		"Petri/Cluster Time",
		"Petri/Bond Scan Time",
		"Petri/Bond Update Time",
		"Petri/Local Plasma Time",
		"Petri/Macro Draw Time",
		"Petri/Magnetic Draw Time",
		"Petri/Ambient Field Samples",
		"Petri/Ambient Calm Samples",
		"Petri/Ambient Curl Samples",
	]:
		if Performance.has_custom_monitor(monitor_name):
			Performance.remove_custom_monitor(monitor_name)


func _register_perf_monitor(id: StringName, method_name: StringName, monitor_type: int = Performance.MONITOR_TYPE_QUANTITY) -> void:
	if Performance.has_custom_monitor(id):
		Performance.remove_custom_monitor(id)
	Performance.add_custom_monitor(id, Callable(self, method_name), [], monitor_type)


func _perf_monitor_frame_time() -> float:
	return _perf_frame_ms * 0.001


func _perf_monitor_cell_ambient_time() -> float:
	return _perf_cell_ambient_ms * 0.001


func _perf_monitor_cluster_time() -> float:
	return _perf_cluster_ms * 0.001


func _perf_monitor_bond_scan_time() -> float:
	return _perf_bond_scan_ms * 0.001


func _perf_monitor_bond_update_time() -> float:
	return _perf_bond_update_ms * 0.001


func _perf_monitor_local_plasma_time() -> float:
	return _perf_local_plasma_ms * 0.001


func _perf_monitor_macro_draw_time() -> float:
	return _perf_macro_draw_ms * 0.001


func _perf_monitor_magnetic_draw_time() -> float:
	return _perf_magnetic_draw_ms * 0.001


func _perf_monitor_ambient_field_samples() -> int:
	return _perf_ambient_field_samples


func _perf_monitor_ambient_calm_samples() -> int:
	return _perf_ambient_calm_samples


func _perf_monitor_ambient_curl_samples() -> int:
	return _perf_ambient_curl_samples


func _perf_reset_frame_metrics() -> void:
	_perf_cluster_ms = 0.0
	_perf_bond_scan_ms = 0.0
	_perf_bond_update_ms = 0.0
	_perf_local_plasma_ms = 0.0
	if not should_redraw_cell_field_overlay():
		_perf_macro_draw_ms = 0.0
		_perf_magnetic_draw_ms = 0.0


func _perf_commit_frame_metrics(frame_us: int) -> void:
	_perf_frame_ms = float(maxi(frame_us, 0)) * 0.001
	_perf_cell_ambient_ms = float(maxi(_perf_cell_ambient_us_accum, 0)) * 0.001
	_perf_ambient_field_samples = maxi(_perf_ambient_field_samples_accum, 0)
	_perf_ambient_calm_samples = maxi(_perf_ambient_calm_samples_accum, 0)
	_perf_ambient_curl_samples = maxi(_perf_ambient_curl_samples_accum, 0)
	_perf_cell_ambient_us_accum = 0
	_perf_ambient_field_samples_accum = 0
	_perf_ambient_calm_samples_accum = 0
	_perf_ambient_curl_samples_accum = 0


func update_plasma_sheath_shader(delta: float) -> void:
	# Canonical wrapper: the legacy local-plasma shader now serves as the
	# plasma-sheath support layer plus bridge throat support.
	_update_local_plasma(delta)


func _init_local_plasma_overlay() -> void:
	if not plasma_sheath_enabled():
		return
	var overlay: Node2D = LocalPlasmaOverlayScript.new()
	overlay.name = "LocalPlasmaOverlay"
	add_child(overlay)
	_local_plasma_overlay = overlay
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = LocalPlasmaShader
	# Static tunables. Per-frame data (sources, plasma_time) is pushed via
	# push_sources() in _update_local_plasma().
	mat.set_shader_parameter("inner_width", LOCAL_PLASMA_INNER_WIDTH)
	mat.set_shader_parameter("outer_width", LOCAL_PLASMA_OUTER_WIDTH)
	mat.set_shader_parameter("core_alpha", LOCAL_PLASMA_CORE_ALPHA)
	mat.set_shader_parameter("glow_alpha", LOCAL_PLASMA_GLOW_ALPHA)
	mat.set_shader_parameter("brightness", LOCAL_PLASMA_BRIGHTNESS)
	mat.set_shader_parameter("edge_softness", LOCAL_PLASMA_EDGE_SOFTNESS)
	mat.set_shader_parameter("color_core", LOCAL_PLASMA_COLOR_CORE)
	mat.set_shader_parameter("color_mid", LOCAL_PLASMA_COLOR_MID)
	mat.set_shader_parameter("color_outer", LOCAL_PLASMA_COLOR_OUTER)
	mat.set_shader_parameter("noise_scale", LOCAL_PLASMA_NOISE_SCALE)
	mat.set_shader_parameter("noise_speed", LOCAL_PLASMA_NOISE_SPEED)
	mat.set_shader_parameter("fbm_octaves", LOCAL_PLASMA_FBM_OCTAVES)
	mat.set_shader_parameter("warp_scale", LOCAL_PLASMA_WARP_SCALE)
	mat.set_shader_parameter("warp_gain", LOCAL_PLASMA_WARP_GAIN)
	mat.set_shader_parameter("warp_speed", LOCAL_PLASMA_WARP_SPEED)
	mat.set_shader_parameter("cell_field_arc_enabled", 1.0 if CELL_FIELD_ARC_ENABLED else 0.0)
	mat.set_shader_parameter("cell_field_arc_base_alpha", LOCAL_PLASMA_SHADER_ARC_BASE_ALPHA)
	mat.set_shader_parameter("cell_field_arc_base_width", LOCAL_PLASMA_SHADER_ARC_BASE_WIDTH)
	mat.set_shader_parameter("cell_field_arc_glow_alpha", LOCAL_PLASMA_SHADER_ARC_GLOW_ALPHA)
	mat.set_shader_parameter("cell_field_arc_motion_speed", LOCAL_PLASMA_SHADER_ARC_MOTION_SPEED)
	mat.set_shader_parameter("cell_field_arc_motion_amplitude", LOCAL_PLASMA_SHADER_ARC_MOTION_AMPLITUDE)
	mat.set_shader_parameter("flow_speed", LOCAL_PLASMA_FLOW_SPEED)
	mat.set_shader_parameter("territory_reach", LOCAL_PLASMA_TERRITORY_REACH)
	mat.set_shader_parameter("tendril_density", LOCAL_PLASMA_TENDRIL_DENSITY)
	mat.set_shader_parameter("tendril_softness", LOCAL_PLASMA_TENDRIL_SOFTNESS)
	mat.set_shader_parameter("tendril_flow_speed", LOCAL_PLASMA_TENDRIL_FLOW_SPEED)
	mat.set_shader_parameter("attraction_bend_gain", LOCAL_PLASMA_ATTRACTION_BEND_GAIN)
	mat.set_shader_parameter("lobe_gain", LOCAL_PLASMA_LOBE_GAIN)
	mat.set_shader_parameter("bonded_unification_gain", LOCAL_PLASMA_BONDED_UNIFICATION_GAIN)
	mat.set_shader_parameter("coil_field_torsion_gain", COIL_FIELD_TORSION_GAIN)
	mat.set_shader_parameter("crescent_field_funnel_gain", CRESCENT_FIELD_FUNNEL_GAIN)
	mat.set_shader_parameter("triangle_field_edge_gain", TRIANGLE_FIELD_EDGE_GAIN)
	mat.set_shader_parameter("bridge_gain", PLASMA_BRIDGE_BRIGHTNESS)
	mat.set_shader_parameter("bridge_flow_speed", PLASMA_BRIDGE_FLOW_SPEED)
	mat.set_shader_parameter("bridge_stress_flicker", PLASMA_BRIDGE_STRESS_FLICKER)
	overlay.call("set_shader_material", mat)
	overlay.call("set_extent", LOCAL_PLASMA_OVERLAY_EXTENT)
	# Pre-size the per-frame buffers.
	_local_plasma_positions.resize(LOCAL_PLASMA_MAX_SOURCES)
	_local_plasma_radii.resize(LOCAL_PLASMA_MAX_SOURCES)
	_local_plasma_intensities.resize(LOCAL_PLASMA_MAX_SOURCES)
	_local_plasma_phases.resize(LOCAL_PLASMA_MAX_SOURCES)
	_local_plasma_fields.resize(LOCAL_PLASMA_MAX_SOURCES)
	_local_plasma_styles.resize(LOCAL_PLASMA_MAX_SOURCES)
	_lp_weights.resize(LOCAL_PLASMA_MAX_SOURCES)
	_lp_max_merges.resize(LOCAL_PLASMA_MAX_SOURCES)
	_lp_cell_ids.resize(LOCAL_PLASMA_MAX_SOURCES)
	_lp_cells.resize(LOCAL_PLASMA_MAX_SOURCES)
	_lp_bond_segs.resize(LocalPlasmaOverlay.MAX_BONDS)
	_lp_bond_prms.resize(LocalPlasmaOverlay.MAX_BONDS)
	for i in LOCAL_PLASMA_MAX_SOURCES:
		_local_plasma_positions[i] = Vector2.ZERO
		_local_plasma_fields[i] = Vector4.ZERO
		_local_plasma_styles[i] = Vector4.ZERO
		_lp_cells[i] = null
	for j in LocalPlasmaOverlay.MAX_BONDS:
		_lp_bond_segs[j] = Vector4.ZERO
		_lp_bond_prms[j] = Vector4.ZERO


func _cell_field_geom(cell: CellBody) -> String:
	if cell == null or cell.signature == null:
		return ""
	var geom: String = cell.signature.geometry_type
	if geom == "wedge":
		return "triangle"
	return geom


func _cell_field_style_mode(geom: String) -> float:
	match geom:
		"round":
			return 0.0
		"spiral":
			return 1.0
		"crescent":
			return 2.0
		"triangle":
			return 3.0
		"line":
			return 4.0
	return 4.0


func _cell_field_projector_gain(geom: String) -> float:
	match geom:
		"round":
			return 1.00
		"spiral":
			return 0.72
		"crescent":
			return 0.52
		"triangle":
			return 0.30
		"line":
			return 0.24
	return 0.20


func _cell_field_arc_multiplier(geom: String) -> float:
	match geom:
		"round":
			return SPHERE_FIELD_ARC_MULTIPLIER
		"spiral":
			return 0.72
		"crescent":
			return 0.54
		"triangle":
			return 0.24
		"line":
			return 0.18
	return 0.18


func _update_local_plasma_source_fields(lp_count: int) -> void:
	for i in lp_count:
		var cell: CellBody = _lp_cells[i] as CellBody
		if cell == null or cell.signature == null:
			_local_plasma_fields[i] = Vector4.ZERO
			continue
		var pos: Vector2 = _local_plasma_positions[i]
		var charge_ratio: float = clampf(cell.charge_ratio_value(), 0.0, 1.0)
		var reach: float = maxf(float(_local_plasma_radii[i]) * LOCAL_PLASMA_ATTRACTION_RANGE, 1.0)
		var accum: Vector2 = Vector2.ZERO
		var strongest: float = 0.0
		var total_weight: float = 0.0
		for j in lp_count:
			if i == j:
				continue
			var other: CellBody = _lp_cells[j] as CellBody
			if other == null or other.signature == null:
				continue
			var offset: Vector2 = _local_plasma_positions[j] - pos
			var dist: float = offset.length()
			if dist <= 0.001 or dist >= reach:
				continue
			var proximity: float = 1.0 - clampf(dist / reach, 0.0, 1.0)
			var charge_mix: float = sqrt(charge_ratio * clampf(other.charge_ratio_value(), 0.0, 1.0))
			var weight: float = proximity * charge_mix
			if weight <= 0.0001:
				continue
			accum += (offset / dist) * weight
			total_weight += weight
			strongest = maxf(strongest, weight)
		var ambient_vec: Vector2 = sample_ambient_field(to_global(pos))
		var ambient_strength: float = clampf(
			ambient_vec.length() / maxf(AMBIENT_FIELD_STRENGTH, 0.001),
			0.0,
			1.0
		)
		var ambient_dir: Vector2 = Vector2.ZERO
		if ambient_vec.length_squared() > 0.000001:
			ambient_dir = ambient_vec.normalized()
		var bias_accum: Vector2 = (
			accum * LOCAL_PLASMA_SHADER_ATTRACTION_BEND_GAIN
			+ ambient_dir * ambient_strength * LOCAL_PLASMA_SHADER_AMBIENT_BEND_GAIN
		)
		var bias_dir: Vector2 = Vector2.ZERO
		if bias_accum.length_squared() > 0.000001:
			bias_dir = bias_accum.normalized()
		var attraction: float = clampf(
				maxf(strongest, total_weight * 0.52) * LOCAL_PLASMA_SHADER_ATTRACTION_BEND_GAIN
				+ ambient_strength * LOCAL_PLASMA_SHADER_AMBIENT_BEND_GAIN * 0.35,
			0.0,
			1.0
		)
		var shared: float = clampf(float(_lp_max_merges[i]), 0.0, 1.0)
		_local_plasma_fields[i] = Vector4(bias_dir.x, bias_dir.y, attraction, shared)
	for j in range(lp_count, LOCAL_PLASMA_MAX_SOURCES):
		_local_plasma_fields[j] = Vector4.ZERO
		_local_plasma_styles[j] = Vector4.ZERO
		_lp_cells[j] = null


# Build the active cell-field source list for the shader. Every cell can
# project or reshape a local field, but not equally:
# - Sphere: strongest projector / cleanest arcs
# - Coil: shorter torsion arcs
# - Crescent: funnel / aperture shaper
# - Triangle: weak projector, mostly edge/tip concentration
# Capped at LOCAL_PLASMA_MAX_SOURCES; if the cap is exceeded we keep the
# strongest cell-field contributors by weighted reach.
#
# Also computes per-bond plasma_merge_factor (smoothed toward a target
# derived from age/strain/noise) and pushes bond capsule data to the shader.
# The capsule term is what fuses bonded sphere kernels into one continuous
# merged field with a bright throat; without it bonded spheres render as
# touching-but-separate halos because each per-source kernel decays before
# its neighbor's contribution can fill the midline.
func _update_local_plasma(delta: float) -> void:
	if not plasma_sheath_enabled() or _local_plasma_overlay == null:
		return
	# 1) Pick cell-field sources directly into preallocated parallel arrays.
	# When the cap is exceeded, keep the highest-weight sources by tracking
	# the lowest-weight slot and replacing it. No Dictionary allocation,
	# no sort_custom lambda — we used to allocate one Dictionary per cell
	# every frame plus a closure for sorting.
	var lp_count: int = 0
	var min_w_idx: int = -1
	var min_w: float = INF
	var max_sources: int = LOCAL_PLASMA_MAX_SOURCES
	for cell in cells:
		if cell == null or cell.signature == null:
			continue
		var geom: String = _cell_field_geom(cell)
		var projector_gain: float = _cell_field_projector_gain(geom)
		if projector_gain <= 0.0:
			continue
		var ratio: float = cell.charge_ratio_value()
		var inten: float = (
			LOCAL_PLASMA_MIN_INTENSITY
			+ (1.0 - LOCAL_PLASMA_MIN_INTENSITY) * ratio
		) * projector_gain
		var arc_mult: float = _cell_field_arc_multiplier(geom)
		var weight: float = inten * cell.radius * (0.85 + arc_mult * 0.55)
		var slot: int = -1
		if lp_count < max_sources:
			slot = lp_count
			lp_count += 1
		elif weight > min_w:
			slot = min_w_idx
		else:
			continue
		_local_plasma_positions[slot] = cell.position
		_local_plasma_radii[slot] = cell.radius
		_local_plasma_intensities[slot] = inten
		_local_plasma_phases[slot] = cell._plasma_seed
		_local_plasma_fields[slot] = Vector4.ZERO
		var axis: Vector2 = cell.polarity_axis()
		_local_plasma_styles[slot] = Vector4(
			axis.x,
			axis.y,
			_cell_field_style_mode(geom),
			arc_mult
		)
		_lp_weights[slot] = weight
		_lp_max_merges[slot] = 0.0
		_lp_cell_ids[slot] = cell.get_instance_id()
		_lp_cells[slot] = cell
		# Update the running min. For a fresh fill we just compare; after
		# replacement we rescan because the previous min is now gone.
		if lp_count <= max_sources and slot == lp_count - 1:
			if weight < min_w:
				min_w = weight
				min_w_idx = slot
		else:
			min_w = INF
			min_w_idx = -1
			for i in lp_count:
				var w: float = _lp_weights[i]
				if w < min_w:
					min_w = w
					min_w_idx = i

	# Build cell_id -> source_index lookup. .clear() reuses the Dictionary's
	# allocated buckets — no per-frame allocation.
	_lp_cell_to_idx.clear()
	for i in lp_count:
		_lp_cell_to_idx[_lp_cell_ids[i]] = i

	# AABB seed: source positions expanded by ~5.5x radius (the radius at
	# which the shader's per-source kernel decays below the discard
	# threshold of 0.04 with intensity 1.0). Bond capsules extend it
	# further during the bond pass.
	var aabb_min: Vector2 = Vector2.ZERO
	var aabb_max: Vector2 = Vector2.ZERO
	var has_bb: bool = false
	for i in lp_count:
		var p: Vector2 = _local_plasma_positions[i]
		var rr: float = float(_local_plasma_radii[i]) * LOCAL_PLASMA_TERRITORY_REACH
		var lo: Vector2 = Vector2(p.x - rr, p.y - rr)
		var hi: Vector2 = Vector2(p.x + rr, p.y + rr)
		if not has_bb:
			aabb_min = lo
			aabb_max = hi
			has_bb = true
		else:
			aabb_min.x = minf(aabb_min.x, lo.x)
			aabb_min.y = minf(aabb_min.y, lo.y)
			aabb_max.x = maxf(aabb_max.x, hi.x)
			aabb_max.y = maxf(aabb_max.y, hi.y)

	# 2) Walk bonds. Sphere-sphere bonds whose endpoints both made the
	# source cap contribute capsule data to the shared-field shader.
	var bond_count: int = 0
	var max_bonds: int = LocalPlasmaOverlay.MAX_BONDS
	for bond in bonds:
		if bond == null or bond.a == null or bond.b == null:
			continue
		if bond.a.signature == null or bond.b.signature == null:
			continue
		var ga: String = bond.a.signature.geometry_type
		var gb: String = bond.b.signature.geometry_type
		if ga == "wedge":
			ga = "triangle"
		if gb == "wedge":
			gb = "triangle"
		if ga != "round" or gb != "round":
			continue
		var ida: int = bond.a.get_instance_id()
		var idb: int = bond.b.get_instance_id()
		if not _lp_cell_to_idx.has(ida) or not _lp_cell_to_idx.has(idb):
			continue

		var age_t: float = clampf(bond.age / maxf(PLASMA_MERGE_STABILITY_THRESHOLD, 0.0001), 0.0, 1.0)
		age_t = smoothstep(0.0, 1.0, age_t)
		var strain_t: float = clampf(bond.strain, 0.0, 1.0)
		var noise_t: float = clampf(maxf(bond.a.signature.noise, bond.b.signature.noise), 0.0, 1.0)
		var target_merge: float = age_t
		target_merge *= clampf(1.0 - strain_t * PLASMA_MERGE_STRAIN_SUPPRESSION, 0.0, 1.0)
		target_merge *= clampf(1.0 - noise_t * PLASMA_MERGE_NOISE_SUPPRESSION, 0.0, 1.0)
		var blend: float = clampf(PLASMA_MERGE_TRANSITION_SPEED * delta, 0.0, 1.0)
		bond.plasma_merge_factor = lerpf(bond.plasma_merge_factor, target_merge, blend)

		# Bond cap: silently skip overflow. With MAX_BONDS=32 this is rare
		# and the visual cost of dropping the 33rd capsule is negligible.
		# Removing the previous sort_custom lambda + Dictionary path here
		# was ~30 dict allocations per bond per frame in the worst case.
		if bond_count >= max_bonds:
			continue

		var idx_a: int = int(_lp_cell_to_idx[ida])
		var idx_b: int = int(_lp_cell_to_idx[idb])
		var pa: Vector2 = bond.a.position
		var pb: Vector2 = bond.b.position
		var avg_radius: float = (bond.a.radius + bond.b.radius) * 0.5
		var merge: float = bond.plasma_merge_factor
		var capsule_r: float = avg_radius * PLASMA_BRIDGE_CORE_WIDTH * (0.7 + 0.3 * merge)
		var bond_phase: float = float(hash(bond.get_instance_id())) * 0.0001
		_lp_bond_segs[bond_count] = Vector4(pa.x, pa.y, pb.x, pb.y)
		_lp_bond_prms[bond_count] = Vector4(capsule_r, merge * PLASMA_BRIDGE_ALPHA, strain_t, bond_phase)
		bond_count += 1
		# Track strongest merge per source for cluster-core suppression.
		if merge > _lp_max_merges[idx_a]:
			_lp_max_merges[idx_a] = merge
		if merge > _lp_max_merges[idx_b]:
			_lp_max_merges[idx_b] = merge
		# AABB extension for capsule reach.
		var br: float = capsule_r * 5.5
		var bx_lo: float = minf(pa.x, pb.x) - br
		var bx_hi: float = maxf(pa.x, pb.x) + br
		var by_lo: float = minf(pa.y, pb.y) - br
		var by_hi: float = maxf(pa.y, pb.y) + br
		if has_bb:
			aabb_min.x = minf(aabb_min.x, bx_lo)
			aabb_min.y = minf(aabb_min.y, by_lo)
			aabb_max.x = maxf(aabb_max.x, bx_hi)
			aabb_max.y = maxf(aabb_max.y, by_hi)
		else:
			aabb_min = Vector2(bx_lo, by_lo)
			aabb_max = Vector2(bx_hi, by_hi)
			has_bb = true

	# 3) Apply cluster-member suppression in place.
	_update_local_plasma_source_fields(lp_count)
	for i in lp_count:
		var supp: float = _lp_max_merges[i] * PLASMA_CLUSTER_MEMBER_SUPPRESSION
		_local_plasma_intensities[i] = float(_local_plasma_intensities[i]) * clampf(1.0 - supp, 0.0, 1.0)

	_local_plasma_overlay.call(
		"push_sources",
		_local_plasma_positions,
		_local_plasma_radii,
		_local_plasma_intensities,
		_local_plasma_phases,
		_local_plasma_fields,
		_local_plasma_styles,
		lp_count,
		_simulation_time,
	)
	_local_plasma_overlay.call(
		"push_bonds",
		_lp_bond_segs,
		_lp_bond_prms,
		bond_count,
	)
	# Push the tight rasterization rect to the overlay. Empty rect when
	# there are no sources suppresses the overlay draw entirely.
	if has_bb:
		var bounds: Rect2 = Rect2(aabb_min, aabb_max - aabb_min)
		_local_plasma_overlay.call("set_bounds", bounds)
	else:
		_local_plasma_overlay.call("set_bounds", Rect2(0.0, 0.0, 0.0, 0.0))


func _camera_speed_multiplier() -> float:
	var speed_mult: float = 1.0
	if Input.is_key_pressed(KEY_SHIFT):
		speed_mult *= CAMERA_PAN_FAST_MULTIPLIER
	if Input.is_key_pressed(KEY_CTRL):
		speed_mult *= CAMERA_PAN_SLOW_MULTIPLIER
	return speed_mult


func _clamp_camera_target_position(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, -CAMERA_PAN_LIMIT, CAMERA_PAN_LIMIT),
		clampf(pos.y, -CAMERA_PAN_LIMIT, CAMERA_PAN_LIMIT)
	)


func _reset_camera_view() -> void:
	_camera_pan_target = Vector2.ZERO
	_camera_zoom_target = 1.0


func _screen_to_world_with_camera(screen_pos: Vector2, cam_pos: Vector2, zoom_scalar: float) -> Vector2:
	var viewport_center: Vector2 = get_viewport_rect().size * 0.5
	return cam_pos + (screen_pos - viewport_center) * zoom_scalar


func _zoom_camera_at(screen_pos: Vector2, direction: float) -> void:
	if camera == null:
		return
	var step_scale: float = CAMERA_ZOOM_STEP * (0.45 if Input.is_key_pressed(KEY_CTRL) else 1.0)
	var zoom_factor: float = 1.0 - direction * step_scale
	var new_zoom: float = clampf(_camera_zoom_target * zoom_factor, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)
	if is_equal_approx(new_zoom, _camera_zoom_target):
		return
	var world_anchor: Vector2 = _screen_to_world_with_camera(screen_pos, camera.position, camera.zoom.x)
	var viewport_center: Vector2 = get_viewport_rect().size * 0.5
	var anchored_pos: Vector2 = world_anchor - (screen_pos - viewport_center) * new_zoom
	_camera_zoom_target = new_zoom
	_camera_pan_target = _clamp_camera_target_position(anchored_pos)


func _pan_camera_by_screen_delta(screen_delta: Vector2) -> void:
	var zoom_scalar: float = _camera_zoom_target if camera == null else camera.zoom.x
	_camera_pan_target = _clamp_camera_target_position(_camera_pan_target - screen_delta * zoom_scalar)


func _update_camera_keyboard_pan(delta: float) -> void:
	var pan_dir: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		pan_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		pan_dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		pan_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		pan_dir.y += 1.0
	if pan_dir == Vector2.ZERO:
		return
	pan_dir = pan_dir.normalized()
	var zoom_scalar: float = _camera_zoom_target if camera == null else camera.zoom.x
	var pan_speed: float = CAMERA_PAN_KEYBOARD_SPEED * zoom_scalar * _camera_speed_multiplier()
	_camera_pan_target = _clamp_camera_target_position(_camera_pan_target + pan_dir * pan_speed * delta)


func _update_camera(delta: float) -> void:
	if camera == null:
		return
	_update_camera_keyboard_pan(delta)
	var blend_pos: float = clampf(CAMERA_PAN_SMOOTH * delta, 0.0, 1.0)
	var blend_zoom: float = clampf(CAMERA_ZOOM_SMOOTH * delta, 0.0, 1.0)
	camera.position = camera.position.lerp(_camera_pan_target, blend_pos)
	var next_zoom: float = lerpf(camera.zoom.x, _camera_zoom_target, blend_zoom)
	camera.zoom = Vector2.ONE * next_zoom


func _process(delta: float) -> void:
	var frame_start_us: int = Time.get_ticks_usec()
	delta = minf(delta, MAX_FRAME_DELTA)
	_perf_reset_frame_metrics()
	# Invalidate the per-frame magnetic source cache. The first sampler
	# call this frame will rebuild it; later calls reuse it.
	_invalidate_magnetic_source_cache()
	_update_camera(delta)
	if simulation_paused:
		_perf_commit_frame_metrics(Time.get_ticks_usec() - frame_start_us)
		_hud_accum += delta
		if _hud_accum >= HUD_INTERVAL:
			_hud_accum = 0.0
			_update_debug()
		return
	var motion_baselines: Dictionary = _capture_motion_baselines()
	if field != null:
		field.step(delta)
	_simulation_time += delta
	_drift_phase += delta * 0.15
	_step_fx(delta)
	_decay_clash_cooldowns(delta)
	_begin_interaction_frame()
	if ENABLE_EXPERIMENTAL_GUIDANCE:
		_update_guidance(delta)
	_mark_capture_cells()
	_sync_bonded_counts()
	# Connected-component snapshot for cluster motion + seedling classification.
	var cluster_start_us: int = Time.get_ticks_usec()
	_clusters_snapshot = _compute_clusters_lite()
	_apply_cluster_brownian(delta)
	_apply_cluster_coupling(delta)
	_perf_cluster_ms = float(Time.get_ticks_usec() - cluster_start_us) * 0.001
	_bond_scan_accum += delta
	if _bond_scan_accum >= 1.0 / BOND_SCAN_HZ:
		var bond_scan_start_us: int = Time.get_ticks_usec()
		_bond_scan_accum = 0.0
		_scan_for_bonds()
		_perf_bond_scan_ms = float(Time.get_ticks_usec() - bond_scan_start_us) * 0.001
	# Substep bond physics so stiff springs (high k * dt) stay stable.
	var bond_update_start_us: int = Time.get_ticks_usec()
	var sub_dt: float = delta / float(BOND_SUBSTEPS)
	for _s in BOND_SUBSTEPS:
		_update_bonds(sub_dt)
	_perf_bond_update_ms = float(Time.get_ticks_usec() - bond_update_start_us) * 0.001
	# PBD final pass: anchor seating first, then cell-cell separation.
	_seat_anchors()
	_resolve_cell_collisions()
	_stabilize_cells_post_forces(motion_baselines, delta)
	if ENABLE_SEEDLING_CLASSIFICATION:
		_seedling_accum += delta
		if _seedling_accum >= 1.0 / SEEDLING_HZ:
			_seedling_accum = 0.0
			_classify_seedlings()
	var plasma_start_us: int = Time.get_ticks_usec()
	update_plasma_sheath_shader(delta)
	_perf_local_plasma_ms = float(Time.get_ticks_usec() - plasma_start_us) * 0.001
	update_ambient_field_reveal(delta)
	queue_redraw()
	_perf_commit_frame_metrics(Time.get_ticks_usec() - frame_start_us)
	_hud_accum += delta
	if _hud_accum >= HUD_INTERVAL:
		_hud_accum = 0.0
		_update_debug()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			_zoom_camera_at(mouse_event.position, 1.0)
			return
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			_zoom_camera_at(mouse_event.position, -1.0)
			return
		if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			_camera_dragging = mouse_event.pressed
			_camera_drag_last_screen = mouse_event.position
			return
		if not mouse_event.pressed:
			return
		if _is_screen_pos_over_ui(mouse_event.position):
			return
		var dish_pos: Vector2 = _screen_to_dish_position(mouse_event.position)
		match mouse_event.button_index:
			MOUSE_BUTTON_LEFT:
				_try_spawn_selected_cell_at(dish_pos)
			MOUSE_BUTTON_RIGHT:
				_delete_nearest_cell_at(dish_pos)
		return
	if event is InputEventMouseMotion:
		var motion_event: InputEventMouseMotion = event
		if _camera_dragging:
			_pan_camera_by_screen_delta(motion_event.position - _camera_drag_last_screen)
			_camera_drag_last_screen = motion_event.position
		return
	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if not touch_event.pressed:
			return
		_try_spawn_selected_cell_at(_screen_to_dish_position(touch_event.position))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if not key_event.pressed or key_event.echo:
			return
		match key_event.keycode:
			KEY_1:
				_set_selected_cell_type(0)
			KEY_2:
				_set_selected_cell_type(1)
			KEY_3:
				_set_selected_cell_type(2)
			KEY_4:
				_set_selected_cell_type(3)
			KEY_5:
				_set_selected_cell_type(4)
			KEY_C:
				_clear_dish()
			KEY_SPACE:
				simulation_paused = not simulation_paused
				_apply_pause_state()
			KEY_H:
				hotbar_visible = not hotbar_visible
				_refresh_hotbar()
			KEY_B:
				_set_bonds_enabled(not ENABLE_BONDS)
			KEY_TAB:
				debug_text_visible = not debug_text_visible
				debug_label.visible = debug_text_visible
			KEY_EQUAL:
				debug_magnetic_field = not debug_magnetic_field
				queue_redraw()
				_update_debug()
			KEY_SEMICOLON:
				set_ambient_field_reveal(not macro_field_reveal)
				queue_redraw()
				_update_debug()
			KEY_F1:
				field.toggle_debug_charge()
			KEY_F2:
				field.toggle_debug_noise()
			KEY_F3:
				field.toggle_debug_light()
			KEY_F4:
				CellBody.debug_ports = not CellBody.debug_ports
				for c in cells:
					c.queue_redraw()
			KEY_F5:
				debug_seedlings = not debug_seedlings
				queue_redraw()
			KEY_0:
				_reset_camera_view()
		return
	return


# --- drawing ---

func _draw() -> void:
	for i in 3:
		var t: float = float(i) / 3.0
		var aura_r: float = DISH_RADIUS + 6.0 + t * 14.0
		draw_circle(Vector2.ZERO, aura_r, Color(0.30, 0.40, 0.65, 0.05 * (1.0 - t)))
	draw_circle(Vector2.ZERO, DISH_RADIUS, SURFACE_COLOR)
	draw_circle(Vector2.ZERO, DISH_RADIUS * 0.85, SURFACE_INNER_TINT)
	draw_circle(Vector2.ZERO, DISH_RADIUS * 0.55, Color(0.060, 0.055, 0.090, 1.0))
	_draw_dust()
	_draw_debug_threads()
	_draw_fx()
	_draw_seedlings()
	_draw_trails()
	_draw_bonds()
	# Cluster sheath is a legacy contour-ring renderer for the bonded-cluster
	# plasma. The shader-driven local plasma layer merges bonded spheres
	# automatically (their kernels add into one continuous field), so the
	# sheath is not needed alongside it. Kept for rollback / A-B comparison.
	if LOCAL_PLASMA_LEGACY_DRAW:
		_draw_cluster_plasma()
	_draw_glass_rim()


func _draw_dust() -> void:
	for i in DUST_COUNT:
		var base: Vector2 = _dust[i]
		var wob: Vector2 = Vector2(
			sin(_drift_phase * 0.7 + base.y * 0.013),
			cos(_drift_phase * 0.5 + base.x * 0.011),
		) * 1.8
		var p: Vector2 = base + wob
		var twk: float = 0.6 + 0.4 * sin(_drift_phase * 1.3 + float(i) * 0.7)
		draw_circle(p, _dust_size[i], Color(0.85, 0.92, 1.00, _dust_alpha[i] * twk))


func _bond_supports_plasma_connection(bond: Bond) -> bool:
	if bond == null:
		return false
	match bond.bond_type:
		"line_chain", "line_parallel", "crescent_cradle", "crescent_hook", "round_soft_overlap", "triangle_flat_plate":
			return true
	return false


func _bond_visual_polyline(bond: Bond, pa: Vector2, pb: Vector2) -> PackedVector2Array:
	if bond != null and bond.bond_type == "crescent_cradle":
		var mid: Vector2 = (pa + pb) * 0.5
		var perp: Vector2 = (pb - pa).orthogonal().normalized() * 5.0
		return _bezier_arc_polyline_steps(pa, pa.lerp(mid, 0.55) + perp, pb.lerp(mid, 0.55) + perp, pb, 24)
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(13):
		var t: float = float(i) / 12.0
		pts.append(pa.lerp(pb, t))
	return pts


func _plasma_connection_state(bond: Bond) -> Dictionary:
	var age_ratio: float = clampf(bond.age / 0.9, 0.0, 1.0)
	var hold_ratio: float = clampf(bond.hold_timer / maxf(CAPTURE_MIN_HOLD, 0.001), 0.0, 1.0)
	var capture_ratio: float = clampf(bond.capture_timer / maxf(CAPTURE_DURATION, 0.001), 0.0, 1.0)
	var strain: float = clampf(bond.strain, 0.0, 1.0)
	var stability: float = clampf((age_ratio * 0.60 + hold_ratio * 0.40) * (1.0 - strain * 0.75), 0.0, 1.0)
	var throughput: float = clampf(absf(bond.a.charge_ratio_value() - bond.b.charge_ratio_value()) * 0.75 + bond.strength * 0.45, 0.0, 1.3)
	var agitation: float = clampf((1.0 - stability) * 0.55 + strain * 0.70 + capture_ratio * 0.45, 0.0, 1.4)
	return {
		"stability": stability,
		"throughput": throughput,
		"agitation": agitation,
	}


func _sample_plasma_connection_influence(world_pos: Vector2) -> Vector2:
	if not plasma_bridge_enabled():
		return Vector2.ZERO
	var influence: Vector2 = Vector2.ZERO
	for bond in bonds:
		if not _bond_supports_plasma_connection(bond):
			continue
		var pa: Vector2 = bond.endpoint_a()
		var pb: Vector2 = bond.endpoint_b()
		var segment: Vector2 = pb - pa
		var len_sq: float = segment.length_squared()
		if len_sq <= 0.0001:
			continue
		var t: float = clampf((world_pos - pa).dot(segment) / len_sq, 0.0, 1.0)
		var closest: Vector2 = pa + segment * t
		var offset: Vector2 = world_pos - closest
		var dist: float = offset.length()
		var reach: float = 34.0 + sqrt(len_sq) * 0.22
		if dist >= reach:
			continue
		var state: Dictionary = _plasma_connection_state(bond)
		var falloff: float = 1.0 - clampf(dist / reach, 0.0, 1.0)
		var tangent: Vector2 = segment.normalized()
		var pull: Vector2 = Vector2.ZERO if dist <= 0.0001 else -offset / dist
		var curl: Vector2 = tangent.orthogonal() * signf(offset.dot(tangent.orthogonal()))
		var stability: float = float(state["stability"])
		var throughput: float = float(state["throughput"])
		influence += (
			tangent * (0.22 + throughput * 0.18)
			+ pull * (0.30 + stability * 0.20)
			+ curl * (0.10 + float(state["agitation"]) * 0.12)
		) * falloff * PLASMA_CONNECTION_DISTORTION_GAIN
	if not influence.is_finite():
		return Vector2.ZERO
	return influence


func _init_macro_field_seeds() -> void:
	# Persistent anchors + seeds. Seeds drift each frame along the total
	# field; anchors stay fixed and pull seeds back via a soft spring so
	# the streamline layout slowly breathes without ever needing reseeds.
	_macro_field_anchors.resize(MACRO_FIELD_LINE_COUNT)
	_macro_field_seeds.resize(MACRO_FIELD_LINE_COUNT)
	_macro_field_phases.resize(MACRO_FIELD_LINE_COUNT)
	var inner: float = DISH_RADIUS * 0.78
	for i in MACRO_FIELD_LINE_COUNT:
		var ang: float = randf() * TAU
		var rad: float = sqrt(randf()) * inner
		var pos: Vector2 = Vector2(cos(ang), sin(ang)) * rad
		_macro_field_anchors[i] = pos
		_macro_field_seeds[i] = pos
		_macro_field_phases[i] = randf() * TAU


func update_ambient_field_reveal(delta: float) -> void:
	# Canonical wrapper: legacy "macro field" code is the visible reveal of the
	# ambient field, not a second field simulation.
	_update_macro_field_seeds(delta)


func _update_macro_field_seeds(delta: float) -> void:
	if not ambient_field_reveal_active():
		return
	var keepalive: float = DISH_RADIUS - 12.0
	for i in _macro_field_seeds.size():
		var seed_pos: Vector2 = _macro_field_seeds[i]
		var anchor: Vector2 = _macro_field_anchors[i]
		var f: Vector2 = sample_total_field(seed_pos)
		var fmag: float = f.length()
		var dir: Vector2 = Vector2.ZERO
		if fmag > 0.0001:
			dir = f / fmag
		var advect: Vector2 = dir * MACRO_FIELD_ADVECTION_SPEED * delta
		var spring: Vector2 = (anchor - seed_pos) * MACRO_FIELD_ANCHOR_SPRING * delta
		seed_pos = seed_pos + advect + spring
		if seed_pos.length() > keepalive:
			seed_pos = seed_pos.normalized() * keepalive
		_macro_field_seeds[i] = seed_pos
		_macro_field_phases[i] += delta * MACRO_FIELD_SHIMMER_SPEED
	# Reseed escape hatch — disabled by default (interval=0 means never).
	if MACRO_FIELD_RESEED_INTERVAL > 0.0:
		_macro_field_reseed_accum += delta
		if _macro_field_reseed_accum >= MACRO_FIELD_RESEED_INTERVAL:
			_macro_field_reseed_accum = 0.0
			_init_macro_field_seeds()


func _build_macro_field_bridge_midpoints() -> void:
	# Cache once per draw frame so the streamline inner loop can do a cheap
	# distance test instead of re-walking bonds for each path sample.
	_macro_field_bridge_midpoints.clear()
	for bond in bonds:
		if bond == null or bond.a == null or bond.b == null:
			continue
		if bond.a.signature == null or bond.b.signature == null:
			continue
		if bond.a.signature.geometry_type != "round" or bond.b.signature.geometry_type != "round":
			continue
		_macro_field_bridge_midpoints.append((bond.a.position + bond.b.position) * 0.5)


func _macro_field_cluster_proximity(pos: Vector2) -> float:
	# Returns 0..1 boost for samples within MACRO_FIELD_CLUSTER_PROXIMITY_RADIUS
	# of any sphere-sphere bond midpoint. Smooth falloff so bridges glow
	# brighter where streamlines pass through them but the rest of the line
	# isn't disturbed.
	if _macro_field_bridge_midpoints.is_empty():
		return 0.0
	var r: float = MACRO_FIELD_CLUSTER_PROXIMITY_RADIUS
	var r2: float = r * r
	var best: float = 0.0
	for mid in _macro_field_bridge_midpoints:
		var d2: float = pos.distance_squared_to(mid)
		if d2 >= r2:
			continue
		var t: float = 1.0 - sqrt(d2) / r
		if t > best:
			best = t
	return best


# RK2 streamline tracer through sample_total_field. Builds one polyline by
# tracing backward N/2 steps from the seed, then forward N/2 steps. Each
# point also carries the local field magnitude and gradient magnitude so the
# draw pass can modulate width/alpha by distortion energy.
func _trace_macro_streamline(start_pos: Vector2) -> Array:
	var path: Array = []
	var step_count: int = MACRO_FIELD_STEP_COUNT
	var step_size: float = MACRO_FIELD_STEP_SIZE
	var half: int = step_count / 2
	var keepalive: float = DISH_RADIUS - 4.0
	var grad_norm: float = maxf(TOTAL_FIELD_MAX_STRENGTH * 0.05, 0.0001)
	var back: Array = []
	var p: Vector2 = start_pos
	for _i in half:
		var f: Vector2 = sample_total_field(p)
		var fmag: float = f.length()
		if fmag < 0.0001:
			break
		var dir: Vector2 = -f / fmag
		var mid: Vector2 = p + dir * step_size * 0.5
		var f_mid: Vector2 = sample_total_field(mid)
		var fmid_mag: float = f_mid.length()
		if fmid_mag > 0.0001:
			dir = -f_mid / fmid_mag
		p = p + dir * step_size
		if p.length() > keepalive:
			break
		var gmag: float = sample_total_field_gradient(p).length()
		back.append({"pos": p, "mag": fmag, "grad": gmag / grad_norm})
	back.reverse()
	for entry in back:
		path.append(entry)
	var grad_start: float = sample_total_field_gradient(start_pos).length() / grad_norm
	path.append({"pos": start_pos, "mag": sample_total_field(start_pos).length(), "grad": grad_start})
	p = start_pos
	for _i in half:
		var f: Vector2 = sample_total_field(p)
		var fmag: float = f.length()
		if fmag < 0.0001:
			break
		var dir: Vector2 = f / fmag
		var mid: Vector2 = p + dir * step_size * 0.5
		var f_mid: Vector2 = sample_total_field(mid)
		var fmid_mag: float = f_mid.length()
		if fmid_mag > 0.0001:
			dir = f_mid / fmid_mag
		p = p + dir * step_size
		if p.length() > keepalive:
			break
		var gmag: float = sample_total_field_gradient(p).length()
		path.append({"pos": p, "mag": fmag, "grad": gmag / grad_norm})
	return path


func _draw_macro_field_on(target: CanvasItem) -> void:
	var draw_start_us: int = Time.get_ticks_usec()
	_macro_field_primitive_count = 0
	if not ambient_field_reveal_active():
		_perf_macro_draw_ms = float(Time.get_ticks_usec() - draw_start_us) * 0.001
		return
	# Lazy init: if the seed buffers were never populated (e.g. _ready ran
	# before MACRO_FIELD_LINE_COUNT had any meaningful effect), seed now.
	if _macro_field_seeds.size() != MACRO_FIELD_LINE_COUNT:
		_init_macro_field_seeds()
	_build_macro_field_bridge_midpoints()
	var mag_norm: float = maxf(TOTAL_FIELD_MAX_STRENGTH, 0.0001)
	# The streamline is rendered as TWO polylines (glow + core) per seed,
	# NOT 80 separate draw_line calls. The previous per-segment path drew
	# 80 antialiased line quads with square (BUTT) endcaps. Where line
	# width ≥ segment length (6 px), and adjacent segments turn sharply —
	# precisely what happens around a sphere, since field magnitude AND
	# gradient both spike there and drive glow width to its peak — the
	# stacked endcap quads accumulated into a visible axis-aligned
	# "boxed radial disk" footprint. draw_polyline / draw_polyline_colors
	# uses miter joints between segments, so endcap squares only exist at
	# the streamline's two ends, where the alpha taper has already faded
	# the line to nothing.
	#
	# Width is uniform per polyline call (one glow width, one core width
	# computed from peak energy along the path); per-vertex alpha is
	# preserved via draw_polyline_colors so the per-sample energy /
	# bridge-proximity / calm-fade modulation still reads.
	var width_cap: float = MACRO_FIELD_STEP_SIZE * 1.2
	for i in _macro_field_seeds.size():
		var seed_pos: Vector2 = _macro_field_seeds[i]
		var phase: float = _macro_field_phases[i]
		var path: Array = _trace_macro_streamline(seed_pos)
		var n: int = path.size()
		if n < 2:
			continue
		var pts: PackedVector2Array = PackedVector2Array()
		var glow_colors: PackedColorArray = PackedColorArray()
		var core_colors: PackedColorArray = PackedColorArray()
		pts.resize(n)
		glow_colors.resize(n)
		core_colors.resize(n)
		var peak_energy: float = 0.0
		for k in n:
			var entry: Dictionary = path[k]
			var pos: Vector2 = entry["pos"]
			var seg_t: float = float(k) / float(maxi(n - 1, 1))
			var taper: float = pow(maxf(sin(PI * seg_t), 0.0), 0.6)
			var mag_ratio: float = clampf(float(entry["mag"]) / mag_norm, 0.0, 1.0)
			var grad_ratio: float = clampf(float(entry["grad"]), 0.0, 1.0)
			var energy: float = clampf(
				mag_ratio + grad_ratio * MACRO_FIELD_GRADIENT_BRIGHTNESS,
				0.0, 1.6
			)
			peak_energy = maxf(peak_energy, energy)
			var calm_fade: float = lerpf(MACRO_FIELD_CALM_FADE, 1.0, smoothstep(0.0, 0.45, energy))
			var bridge_boost: float = _macro_field_cluster_proximity(pos) * MACRO_FIELD_CLUSTER_DISTORTION_GAIN
			var alpha: float = MACRO_FIELD_ALPHA * taper * calm_fade * (1.0 + bridge_boost)
			alpha = clampf(alpha, 0.0, 0.95)
			pts[k] = pos
			glow_colors[k] = Color(0.30, 0.62, 1.00, alpha * 0.45)
			core_colors[k] = Color(0.78, 0.94, 1.00, alpha)
		# Slow per-streamline shimmer (width breathe, NOT brightness ticks).
		var shimmer: float = 0.85 + 0.15 * sin(phase)
		var width: float = MACRO_FIELD_WIDTH * shimmer * (0.70 + 0.50 * peak_energy)
		var glow_w: float = MACRO_FIELD_GLOW_WIDTH * shimmer * (0.65 + 0.55 * peak_energy)
		# Hard width cap: glow width cannot exceed ~step_size, so even the
		# residual square endcap at the streamline's tip cannot overhang
		# beyond a single segment footprint.
		glow_w = minf(glow_w, width_cap)
		width = minf(width, width_cap * 0.5)
		target.draw_polyline_colors(pts, glow_colors, glow_w, true)
		target.draw_polyline_colors(pts, core_colors, width, true)
		_macro_field_primitive_count += 1
	_perf_macro_draw_ms = float(Time.get_ticks_usec() - draw_start_us) * 0.001


func draw_ambient_field_reveal_on(target: CanvasItem) -> void:
	# LEGACY NAME: _draw_macro_field_on draws the visible ambient-field reveal.
	_draw_macro_field_on(target)


func _draw_magnetic_field_on(target: CanvasItem) -> void:
	var draw_start_us: int = Time.get_ticks_usec()
	# Legacy magnetic function name retained. The sphere_attached polarity arcs
	# are now the main readable local cell-field path; extra streamline/contour
	# diagnostics remain debug-only.
	_reset_magnetic_debug_state()
	var primitive_count: int = 0
	if cell_field_enabled():
		primitive_count = _draw_sphere_attached_filaments_on(target)
	_mag_debug_primitive_count = primitive_count
	if not debug_magnetic_field:
		_perf_magnetic_draw_ms = float(Time.get_ticks_usec() - draw_start_us) * 0.001
		return
	_update_magnetic_debug_probe()
	var legacy_visuals_enabled: bool = _legacy_magnetic_visuals_enabled()
	var poles: Array = _build_visual_poles() if legacy_visuals_enabled else []
	var lines_drawn: int = 0
	if ENABLE_MAG_LEGACY_VISUALS and MAG_FIELD_SHOW_SAMPLED_STREAMLINES:
		var seeds: Array[Vector2] = _build_visual_seeds(poles)
		_mag_debug_seed_count = seeds.size()
		for seed in seeds:
			if lines_drawn >= MAG_FIELD_DRAW_MAX_LINES:
				break
			var line: PackedVector2Array = _trace_visual_field_line(seed, poles)
			if line.size() < 3:
				continue
			var strength_ratio: float = _visual_line_strength(seed, poles)
			var glow_alpha: float = MAG_FIELD_DRAW_GLOW_ALPHA + 0.060 * strength_ratio
			var core_alpha: float = MAG_FIELD_DRAW_CORE_ALPHA + 0.110 * strength_ratio
			var glow_width: float = MAG_FIELD_DRAW_GLOW_WIDTH + 1.40 * strength_ratio
			var core_width: float = MAG_FIELD_DRAW_CORE_WIDTH + 0.60 * strength_ratio
			var tint: float = 0.14 * strength_ratio
			target.draw_polyline(
				line,
				Color(0.28 + tint * 0.2, 0.70 + tint * 0.25, 1.00, glow_alpha),
				glow_width,
				true
			)
			var core_color: Color = Color(0.90 + tint * 0.08, 0.97, 1.00, core_alpha)
			target.draw_polyline(line, core_color, core_width, true)
			_draw_field_line_ticks_on(target, line, core_color, strength_ratio)
			lines_drawn += 1
			_mag_debug_point_count += line.size()
		_mag_debug_line_count = lines_drawn
		_mag_debug_primitive_count = primitive_count + lines_drawn
		_mag_debug_contour_count = _draw_magnetic_contours_on(target) if (ENABLE_MAG_LEGACY_VISUALS and MAG_FIELD_SHOW_CONTOURS) else 0
		_mag_debug_primitive_count += _mag_debug_contour_count
		if ENABLE_MAG_LEGACY_VISUALS and MAG_FIELD_SHOW_POLE_MARKERS:
			_draw_visual_pole_marks_on(target, poles)
		_perf_magnetic_draw_ms = float(Time.get_ticks_usec() - draw_start_us) * 0.001


func draw_cell_field_arcs_on(target: CanvasItem) -> void:
	# LEGACY NAME: _draw_magnetic_field_on now draws the visible cell-field arcs.
	_draw_magnetic_field_on(target)


func _reset_magnetic_debug_state() -> void:
	_mag_debug_seed_count = 0
	_mag_debug_line_count = 0
	_mag_debug_point_count = 0
	_mag_debug_probe_strength = 0.0
	_mag_debug_probe_pos = Vector2.ZERO
	_mag_debug_sphere_sources = 0
	_mag_debug_nearest_sphere_charge = 0.0
	_mag_debug_mouse_contributors = 0
	_mag_debug_mouse_strength = 0.0
	_mag_debug_mouse_pos = Vector2.ZERO
	_mag_debug_mouse_vector = Vector2.ZERO
	_mag_debug_nearest_source_strength = 0.0
	_mag_debug_nearest_source_vector = Vector2.ZERO
	_mag_debug_primitive_count = 0
	_mag_debug_contour_count = 0


func _legacy_magnetic_visuals_enabled() -> bool:
	return ENABLE_MAG_LEGACY_VISUALS and (
		MAG_FIELD_SHOW_SAMPLED_STREAMLINES
		or MAG_FIELD_SHOW_CONTOURS
		or MAG_FIELD_SHOW_POLE_MARKERS
	)


# --- ambient / background field ---

func _ambient_field_sample_time(time: float) -> float:
	return _simulation_time if time < 0.0 else time


func _ambient_field_flow_basis(local_pos: Vector2, sim_time: float) -> Vector2:
	var x: float = local_pos.x * AMBIENT_FIELD_SCALE
	var y: float = local_pos.y * AMBIENT_FIELD_SCALE
	var t: float = sim_time * AMBIENT_FIELD_TIME_SPEED
	var lane_a: Vector2 = Vector2(cos(0.55 * t + 0.65), sin(0.42 * t - 0.35))
	var lane_b: Vector2 = Vector2(cos(-0.38 * t + 2.10), sin(0.33 * t + 1.30))
	var lane_mix_a: float = 0.5 + 0.5 * sin(0.92 * x + 0.37 * y + 0.70 * t)
	var lane_mix_b: float = 0.5 + 0.5 * cos(-0.58 * x + 0.82 * y - 0.48 * t)
	return lane_a * lane_mix_a + lane_b * lane_mix_b


func _ambient_field_vortex_basis(local_pos: Vector2, sim_time: float) -> Vector2:
	var x: float = local_pos.x * AMBIENT_FIELD_SCALE
	var y: float = local_pos.y * AMBIENT_FIELD_SCALE
	var t: float = sim_time * AMBIENT_FIELD_TIME_SPEED
	var arg_a: float = 1.25 * x - 0.55 * y + 0.60 * t
	var arg_b: float = -0.74 * x + 1.08 * y - 0.42 * t + 1.70
	var grad_a: Vector2 = Vector2(1.25 * cos(arg_a), -0.55 * cos(arg_a))
	var grad_b: Vector2 = Vector2(-0.74 * 0.72 * cos(arg_b), 1.08 * 0.72 * cos(arg_b))
	var gradient: Vector2 = grad_a + grad_b
	return Vector2(-gradient.y, gradient.x)


func _ambient_field_strength_envelope(local_pos: Vector2, sim_time: float) -> float:
	var x: float = local_pos.x * AMBIENT_FIELD_SCALE
	var y: float = local_pos.y * AMBIENT_FIELD_SCALE
	var t: float = sim_time * AMBIENT_FIELD_TIME_SPEED
	var weather: float = sin(0.54 * x - 0.86 * y + 0.22 * t + 1.10) * cos(0.78 * x + 0.34 * y - 0.18 * t - 0.60)
	var weather01: float = 0.5 + 0.5 * weather
	var radius_ratio: float = clampf(local_pos.length() / maxf(DISH_RADIUS, 0.001), 0.0, 1.0)
	var edge_taper: float = lerpf(1.0, 0.82, radius_ratio * radius_ratio)
	return clampf((0.32 + 0.68 * weather01) * edge_taper, 0.0, 1.0)


func sample_ambient_field(world_pos: Vector2, time: float = -1.0) -> Vector2:
	if not AMBIENT_FIELD_ENABLED:
		return Vector2.ZERO
	var sim_time: float = _ambient_field_sample_time(time)
	var local_pos: Vector2 = to_local(world_pos)
	var flow: Vector2 = _ambient_field_flow_basis(local_pos, sim_time) * AMBIENT_FIELD_FLOW_GAIN
	var vortex: Vector2 = _ambient_field_vortex_basis(local_pos, sim_time) * AMBIENT_FIELD_VORTEX_GAIN
	var envelope: float = _ambient_field_strength_envelope(local_pos, sim_time)
	var pulse: float = 1.0 + AMBIENT_FIELD_PULSE_GAIN * sin(sim_time * AMBIENT_FIELD_PULSE_SPEED)
	var field_vec: Vector2 = (flow + vortex) * (AMBIENT_FIELD_STRENGTH * envelope * pulse)
	if not field_vec.is_finite():
		return Vector2.ZERO
	return field_vec.limit_length(AMBIENT_FIELD_STRENGTH * 1.6)


func sample_ambient_field_magnitude(world_pos: Vector2, time: float = -1.0) -> float:
	return sample_ambient_field(world_pos, time).length()


func sample_ambient_field_direction(world_pos: Vector2, time: float = -1.0) -> Vector2:
	var field_vec: Vector2 = sample_ambient_field(world_pos, time)
	var strength: float = field_vec.length()
	if strength <= 0.00001:
		return Vector2.ZERO
	return field_vec / strength


func sample_ambient_field_calm_metric(world_pos: Vector2, time: float = -1.0) -> float:
	if not AMBIENT_FIELD_ENABLED:
		return 1.0
	var sim_time: float = _ambient_field_sample_time(time)
	var envelope: float = _ambient_field_strength_envelope(to_local(world_pos), sim_time)
	return clampf(1.0 - envelope, 0.0, 1.0)


func sample_ambient_field_curl_hint(world_pos: Vector2, time: float = -1.0) -> float:
	if not AMBIENT_FIELD_ENABLED:
		return 0.0
	var sim_time: float = _ambient_field_sample_time(time)
	var eps: float = 16.0
	var left: Vector2 = sample_ambient_field(world_pos + Vector2.LEFT * eps, sim_time)
	var right: Vector2 = sample_ambient_field(world_pos + Vector2.RIGHT * eps, sim_time)
	var up: Vector2 = sample_ambient_field(world_pos + Vector2.UP * eps, sim_time)
	var down: Vector2 = sample_ambient_field(world_pos + Vector2.DOWN * eps, sim_time)
	var d_fy_dx: float = (right.y - left.y) / (2.0 * eps)
	var d_fx_dy: float = (down.x - up.x) / (2.0 * eps)
	return d_fy_dx - d_fx_dy


# Total energetic field composition layer.
# Ambient field = dish weather.
# Magnetic field = local cell/source field.
# Total field = composed energetic field used by future behavior and cluster work.
func sample_total_field(world_pos: Vector2) -> Vector2:
	if not TOTAL_FIELD_ENABLED:
		return Vector2.ZERO
	var ambient_vec: Vector2 = sample_ambient_field(world_pos) * TOTAL_FIELD_AMBIENT_WEIGHT
	var magnetic_vec: Vector2 = sample_cell_field(world_pos) * TOTAL_FIELD_MAGNETIC_WEIGHT
	# Future extension point: bonded/cluster distortions should be composed here
	# instead of bypassing the total-field API.
	var total_vec: Vector2 = ambient_vec + magnetic_vec
	if not total_vec.is_finite():
		return Vector2.ZERO
	return total_vec.limit_length(TOTAL_FIELD_MAX_STRENGTH)


func sample_total_field_strength(world_pos: Vector2) -> float:
	return sample_total_field(world_pos).length()


func sample_total_field_direction(world_pos: Vector2) -> Vector2:
	var field_vec: Vector2 = sample_total_field(world_pos)
	var strength: float = field_vec.length()
	if strength <= 0.00001:
		return Vector2.ZERO
	return field_vec / strength


func sample_total_field_gradient(world_pos: Vector2) -> Vector2:
	var eps: float = 16.0
	var left: float = sample_total_field_strength(world_pos + Vector2.LEFT * eps)
	var right: float = sample_total_field_strength(world_pos + Vector2.RIGHT * eps)
	var up: float = sample_total_field_strength(world_pos + Vector2.UP * eps)
	var down: float = sample_total_field_strength(world_pos + Vector2.DOWN * eps)
	return Vector2(
		(right - left) / (2.0 * eps),
		(down - up) / (2.0 * eps)
	)


# --- pole-based visualization helpers ---
# LEGACY_VISUAL_PATH: explicit poles and visual-only field sampling remain for
# inspection and future unification work. They are not the simulation truth.

func _build_visual_poles() -> Array:
	# Returns a list of {pos, charge, soften, kind, owner} dictionaries. Each
	# Sphere contributes a + and − pole along its polarity axis. A Sphere that
	# is bonded by `crescent_cradle` to a Crescent also contributes two virtual
	# focus poles at the Crescent's tips, producing a horseshoe flux pattern.
	var poles: Array = []
	for cell in cells:
		if cell == null or cell.signature == null:
			continue
		if _canonical_geom(cell.signature.geometry_type) != "round":
			continue
		var charge: float = cell.signature.charge
		if absf(charge) <= 0.00001:
			continue
		var axis: Vector2 = _visual_polarity_axis(cell)
		var offset: float = cell.radius * MAG_FIELD_VIS_POLE_OFFSET_RATIO
		var q: float = absf(charge)
		if charge < 0.0:
			q = -q
		poles.append({
			"pos": cell.position + axis * offset,
			"charge": q,
			"soften": MAG_FIELD_VIS_POLE_SOFTEN,
			"kind": "N",
			"owner": cell,
			"is_focus": false,
		})
		poles.append({
			"pos": cell.position - axis * offset,
			"charge": -q,
			"soften": MAG_FIELD_VIS_POLE_SOFTEN,
			"kind": "S",
			"owner": cell,
			"is_focus": false,
		})
		var crescent: CellBody = _find_visual_focus_partner(cell)
		if crescent != null:
			# Crescent tips: virtual sinks/sources placed perpendicular to the
			# bond axis at the crescent's mid-curve, each opposite to the
			# nearer sphere pole. Lines exit one sphere pole, route through
			# the corresponding crescent tip, and return to the other pole.
			var bond_dir: Vector2 = (crescent.position - cell.position).normalized()
			var perp: Vector2 = Vector2(-bond_dir.y, bond_dir.x)
			var tip_a: Vector2 = crescent.position + perp * crescent.radius * MAG_FIELD_VIS_FOCUS_TIP_OFFSET
			var tip_b: Vector2 = crescent.position - perp * crescent.radius * MAG_FIELD_VIS_FOCUS_TIP_OFFSET
			# tip_a sits on the +axis side relative to the sphere (where N is),
			# so it acts as a sink; tip_b sits on −axis side, acts as source.
			poles.append({
				"pos": tip_a,
				"charge": -q * MAG_FIELD_VIS_FOCUS_TIP_SCALE,
				"soften": MAG_FIELD_VIS_POLE_SOFTEN * 0.7,
				"kind": "tipS",
				"owner": crescent,
				"is_focus": true,
			})
			poles.append({
				"pos": tip_b,
				"charge": q * MAG_FIELD_VIS_FOCUS_TIP_SCALE,
				"soften": MAG_FIELD_VIS_POLE_SOFTEN * 0.7,
				"kind": "tipN",
				"owner": crescent,
				"is_focus": true,
			})
	return poles


func _visual_polarity_axis(cell: CellBody) -> Vector2:
	# Default polarity axis is local +Y rotated by cell.rotation, so the
	# inspector / debug shows orientation. If the sphere is cradled by a
	# crescent, the axis snaps perpendicular to the bond direction so flux
	# exits broadside through the crescent's aperture instead of along the
	# bond line.
	var crescent: CellBody = _find_visual_focus_partner(cell)
	if crescent != null:
		var bond_dir: Vector2 = (crescent.position - cell.position).normalized()
		if bond_dir != Vector2.ZERO:
			return Vector2(-bond_dir.y, bond_dir.x)
	return Vector2.UP.rotated(cell.rotation)


func _find_visual_focus_partner(sphere: CellBody) -> CellBody:
	if not ENABLE_BONDS:
		return null
	for bond in bonds:
		if bond.bond_type != "crescent_cradle":
			continue
		var other: CellBody = null
		if bond.a == sphere:
			other = bond.b
		elif bond.b == sphere:
			other = bond.a
		if other == null or other.signature == null:
			continue
		if _canonical_geom(other.signature.geometry_type) == "crescent":
			return other
	return null


func _sample_visual_field(world_pos: Vector2, poles: Array) -> Vector2:
	# Pole-monopole sum with Plummer soften per pole. Visualization-only.
	var v: Vector2 = Vector2.ZERO
	for p in poles:
		var pole_pos: Vector2 = p["pos"] as Vector2
		var off: Vector2 = world_pos - pole_pos
		var soften: float = float(p["soften"])
		var d2: float = off.length_squared() + soften * soften
		v += off * (MAG_FIELD_STRENGTH * float(p["charge"]) / d2)
	if not v.is_finite():
		return Vector2.ZERO
	return v.limit_length(MAG_FIELD_MAX_STRENGTH)


func _visual_line_strength(seed_local: Vector2, poles: Array) -> float:
	var s: float = _sample_visual_field(to_global(seed_local), poles).length()
	return clampf(pow(s / maxf(MAG_FIELD_MAX_STRENGTH, 0.001), 0.55), 0.0, 1.0)


func _build_visual_seeds(poles: Array) -> Array[Vector2]:
	# Seed only from positive (source) poles: the tracer integrates forward and
	# backward, so each source seed produces one full curved line. A small
	# angular spread is applied so each pole emits multiple lines fanning out
	# in the outward radial direction relative to its owner cell.
	var seeds: Array[Vector2] = []
	var edge_limit: float = DISH_RADIUS - MAG_FIELD_DRAW_EDGE_PAD
	var per_pole: int = MAG_FIELD_VIS_LINES_PER_POLE
	for p in poles:
		if seeds.size() >= MAG_FIELD_DRAW_MAX_LINES:
			break
		if float(p["charge"]) <= 0.0:
			continue  # only seed from +
		if bool(p.get("is_focus", false)):
			continue  # virtual focus poles are shapers, not sources
		var pole_pos: Vector2 = p["pos"] as Vector2
		var owner: CellBody = p["owner"] as CellBody
		var outward: Vector2 = Vector2.RIGHT
		if owner != null:
			var d: Vector2 = pole_pos - owner.position
			if d != Vector2.ZERO:
				outward = d.normalized()
		for i in per_pole:
			if seeds.size() >= MAG_FIELD_DRAW_MAX_LINES:
				break
			var t: float = (float(i) - float(per_pole - 1) * 0.5) / float(maxi(1, per_pole - 1))
			var ang: float = t * MAG_FIELD_VIS_SEED_SPREAD
			var seed: Vector2 = pole_pos + outward.rotated(ang) * MAG_FIELD_VIS_SEED_PAD
			if seed.length() > edge_limit:
				continue
			seeds.append(seed)
	return seeds


func _trace_visual_field_line(seed_local: Vector2, poles: Array) -> PackedVector2Array:
	var back: PackedVector2Array = _trace_visual_branch(seed_local, poles, -1.0)
	var forward: PackedVector2Array = _trace_visual_branch(seed_local, poles, 1.0)
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(back.size() - 1, -1, -1):
		points.append(back[i])
	points.append(seed_local)
	for p in forward:
		points.append(p)
	return points


func _trace_visual_branch(seed_local: Vector2, poles: Array, direction_sign: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var current_local: Vector2 = seed_local
	var prev_dir_world: Vector2 = Vector2.ZERO
	var edge_limit: float = DISH_RADIUS - MAG_FIELD_DRAW_EDGE_PAD
	for _i in MAG_FIELD_DRAW_STEPS:
		var current_world: Vector2 = to_global(current_local)
		# Termination: snap onto a pole of the appropriate sign so the line
		# visually lands on the pole instead of just stopping in space.
		if _close_to_terminator(current_local, poles, direction_sign):
			break
		var field_vec: Vector2 = _sample_visual_field(current_world, poles)
		var strength: float = field_vec.length()
		if strength < MAG_FIELD_DRAW_MIN:
			break
		var dir_world: Vector2 = (field_vec / strength) * direction_sign
		if prev_dir_world != Vector2.ZERO:
			dir_world = (prev_dir_world * 0.35 + dir_world * 0.65).normalized()
			if dir_world == Vector2.ZERO:
				dir_world = prev_dir_world
		var next_world: Vector2 = current_world + dir_world * MAG_FIELD_DRAW_STEP
		var next_local: Vector2 = to_local(next_world)
		if next_local.length() > edge_limit:
			break
		if next_local.distance_to(current_local) < 0.4:
			break
		points.append(next_local)
		current_local = next_local
		prev_dir_world = dir_world
	return points


func _close_to_terminator(local_pos: Vector2, poles: Array, dir_sign: float) -> bool:
	# Forward tracing (dir_sign > 0) flows from + to −, so terminate near any
	# negative pole. Backward tracing terminates near a positive pole.
	var want_negative: bool = dir_sign > 0.0
	for p in poles:
		var q: float = float(p["charge"])
		if want_negative and q >= 0.0:
			continue
		if (not want_negative) and q <= 0.0:
			continue
		if local_pos.distance_to(p["pos"] as Vector2) < MAG_FIELD_VIS_TERMINATE_RADIUS:
			return true
	return false


func _cell_field_pole_data(cell: CellBody) -> Dictionary:
	if cell == null or cell.signature == null:
		return {}
	var geom: String = _cell_field_geom(cell)
	var projector_gain: float = _cell_field_projector_gain(geom)
	var arc_mult: float = _cell_field_arc_multiplier(geom)
	if not cell.field_enabled or projector_gain <= 0.0 or arc_mult <= 0.0:
		return {}
	# Polarity axis comes from the cell. Sphere stays special-cased through
	# _visual_polarity_axis for the crescent-cradle visual focus snap; every
	# other geometry uses the base CellBody.polarity_axis() helper so the same
	# system covers them all.
	var axis: Vector2
	if geom == "round":
		axis = _visual_polarity_axis(cell)
	else:
		axis = cell.polarity_axis()
	if axis.length_squared() <= 0.000001:
		axis = Vector2.UP
	else:
		axis = axis.normalized()
	var surface_offset: float = cell.radius * MAG_FIELD_VIS_POLE_OFFSET_RATIO
	return {
		"center": cell.position,
		"radius": cell.radius,
		"axis": axis,
		"north": cell.position + axis * surface_offset,
		"south": cell.position - axis * surface_offset,
		"charge_ratio": clampf(cell.charge_ratio_value(), 0.05, 1.0),
		"geom": geom,
		"projector_gain": projector_gain,
		"arc_mult": arc_mult,
	}


func _cell_field_arc_family_count(cell: CellBody) -> int:
	# Family count per polarity side. Driven by CellBody.field_arc_count so
	# every cell type uses the same base system; per-type defaults shape it.
	if cell == null:
		return 1
	return clampi(cell.field_arc_count, 1, 2)


func _cell_field_arc_pole_signs(cell: CellBody) -> Array:
	# Two polarity sides for every cell. Polarity is a base property of
	# CellBody, not a sphere-only effect.
	if cell == null or not cell.field_enabled:
		return []
	return [1.0, -1.0]


func _cell_field_arc_lane(family: int, family_count: int) -> float:
	if family_count <= 1:
		return 0.0
	return lerpf(-0.42, 0.42, float(family) / float(family_count - 1))


func _cell_field_arc_reach(geom: String, radius: float, charge_ratio: float, arc_mult: float) -> float:
	var length_scale: float = lerpf(CELL_FIELD_ARC_MIN_LENGTH, CELL_FIELD_ARC_MAX_LENGTH, clampf(charge_ratio, 0.0, 1.0))
	var geom_mult: float = 1.0
	match geom:
		"spiral":
			geom_mult = 0.95
		"crescent":
			geom_mult = 0.72
		"triangle":
			geom_mult = 0.46
	return radius * length_scale * maxf(0.20, arc_mult) * geom_mult


# Removed: sphere-only renderer path (_sphere_field_lane,
# _integrate_sphere_field_arc, _draw_round_cell_field_arcs_on). The unified
# base cell-field renderer in _draw_sphere_attached_filaments_on now handles
# every cell type through one integrator with per-type bias, so polarity arcs
# are no longer a sphere-only visual.


func _integrate_projected_cell_field_arc(
	cell: CellBody,
	center: Vector2,
	radius: float,
	axis: Vector2,
	geom: String,
	start: Vector2,
	start_dir: Vector2,
	arc_length: float,
	lane: float,
	pole_sign: float,
	phase: float,
) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	points.append(start)
	var current_pos: Vector2 = start
	var current_dir: Vector2 = start_dir.normalized()
	if current_dir.length_squared() <= 0.000001:
		current_dir = axis.normalized()
	var edge_limit: float = DISH_RADIUS - 8.0
	var step_count: int = maxi(CELL_FIELD_ARC_STEP_COUNT, 6)
	var step_len: float = arc_length / float(step_count)
	var pole_axis: Vector2 = axis * pole_sign
	if pole_axis.length_squared() <= 0.000001:
		pole_axis = axis
	for i in range(step_count):
		var t: float = float(i + 1) / float(step_count)
		var world_pos: Vector2 = to_global(current_pos)
		var ambient_vec: Vector2 = sample_ambient_field(world_pos)
		var ambient_strength: float = clampf(
			ambient_vec.length() / maxf(AMBIENT_FIELD_STRENGTH, 0.001),
			0.0,
			1.0
		)
		var ambient_dir: Vector2 = ambient_vec.normalized() if ambient_vec.length_squared() > 0.000001 else Vector2.ZERO
		var neighbor_vec: Vector2 = sample_neighbor_cell_field(cell, world_pos)
		var neighbor_strength: float = clampf(
			neighbor_vec.length() / maxf(MAG_FIELD_MAX_STRENGTH, 0.001),
			0.0,
			1.0
		)
		var neighbor_dir: Vector2 = neighbor_vec.normalized() if neighbor_vec.length_squared() > 0.000001 else Vector2.ZERO
		var env_vec: Vector2 = ambient_vec * TOTAL_FIELD_AMBIENT_WEIGHT + neighbor_vec * TOTAL_FIELD_MAGNETIC_WEIGHT
		var env_strength: float = clampf(
			env_vec.length() / maxf(TOTAL_FIELD_MAX_STRENGTH, 0.001),
			0.0,
			1.0
		)
		var env_dir: Vector2 = env_vec.normalized() if env_vec.length_squared() > 0.000001 else Vector2.ZERO
		var radial_dir: Vector2 = current_pos - center
		if radial_dir.length_squared() <= 0.000001:
			radial_dir = pole_axis
		else:
			radial_dir = radial_dir.normalized()
		var lane_gain: float = 1.0 - absf(lane) * 0.32
		var desired: Vector2 = (
			start_dir * lerpf(1.28, 0.34, t) * lane_gain
			+ radial_dir * lerpf(0.86, 0.22, t)
			+ current_dir * 0.42
		)
		if env_dir != Vector2.ZERO:
			desired += env_dir * ((0.16 + env_strength * 0.54) * (0.32 + t * 0.68))
		if ambient_dir != Vector2.ZERO:
			desired += ambient_dir * (
				CELL_FIELD_ARC_AMBIENT_BEND_GAIN
				* (0.08 + ambient_strength * 0.78)
				* (0.24 + t * 0.76)
			)
		if neighbor_dir != Vector2.ZERO:
			desired += neighbor_dir * (
				CELL_FIELD_ARC_NEIGHBOR_BEND_GAIN
				* (0.06 + neighbor_strength * 0.94)
				* (0.18 + t * 0.82)
			)
		var breathe: float = sin(
			phase + t * TAU * (0.78 + absf(lane) * 0.22) + lane * 1.7
		) * CELL_FIELD_ARC_BREATH_GAIN * (0.58 + ambient_strength * 0.42)
		desired += current_dir.orthogonal() * breathe
		match geom:
			"round":
				# Sphere: broad rounded lobes. Bend the desired direction back
				# toward the radial so arcs sweep cleanly out of the surface
				# instead of clipping along the pole axis.
				var radial_perp: Vector2 = Vector2(-radial_dir.y, radial_dir.x)
				desired = desired.lerp(radial_dir, 0.10) + radial_perp * lane * 0.06
				var arch_pull: float = smoothstep(0.40, 1.0, t) * 0.18
				desired -= pole_axis * arch_pull
			"spiral":
				desired += current_dir.orthogonal() * pole_sign * COIL_FIELD_TORSION_MULT * (0.18 + 0.16 * (1.0 - t))
			"crescent":
				var funnel_axis: Vector2 = pole_axis.lerp(axis, 0.65).normalized()
				desired = desired.lerp(funnel_axis, 0.26 * CRESCENT_FIELD_FUNNEL_MULT)
				desired += axis.orthogonal() * (-lane) * 0.10 * CRESCENT_FIELD_FUNNEL_MULT
			"triangle":
				desired = desired.lerp(pole_axis, 0.40 + 0.20 * TRIANGLE_FIELD_EDGE_MULT)
				desired += current_dir.orthogonal() * lane * 0.04 * TRIANGLE_FIELD_EDGE_MULT
		if desired.length_squared() <= 0.000001:
			desired = current_dir
		else:
			desired = desired.normalized()
		if desired.dot(radial_dir) < 0.04:
			desired = desired.lerp(radial_dir, 0.72).normalized()
		elif t < 0.24 and desired.dot(pole_axis) < 0.16:
			desired = desired.lerp(pole_axis, 0.60).normalized()
		current_dir = current_dir.lerp(desired, 0.34 + t * 0.22).normalized()
		var next_pos: Vector2 = current_pos + current_dir * step_len
		if next_pos.distance_to(center) < radius * 0.86:
			next_pos = center + radial_dir * radius * 0.86
		if next_pos.length() > edge_limit:
			next_pos = next_pos.normalized() * edge_limit
			if next_pos.distance_to(current_pos) > 0.30:
				points.append(next_pos)
			break
		if next_pos.distance_to(current_pos) < 0.35:
			break
		points.append(next_pos)
		current_pos = next_pos
	return points


func _draw_sphere_attached_filaments_on(target: CanvasItem) -> int:
	# Unified base cell-field renderer. Every cell expresses the same two-lobe
	# polarity field through the same arc integrator; per-type bias (sphere
	# breadth, coil torsion, crescent funnel, triangle edge pinning) lives in
	# the start-position match and the integrator's bend gains. Function name
	# is legacy — there is no separate sphere-only path.
	var filaments_drawn: int = 0
	for cell in cells:
		if cell == null or cell.signature == null:
			continue
		var pole_data: Dictionary = _cell_field_pole_data(cell)
		if pole_data.is_empty():
			continue
		var center: Vector2 = pole_data["center"] as Vector2
		var axis: Vector2 = pole_data["axis"] as Vector2
		var radius: float = float(pole_data["radius"])
		var charge_ratio: float = float(pole_data["charge_ratio"])
		var geom: String = pole_data["geom"] as String
		var projector_gain: float = float(pole_data["projector_gain"])
		var arc_mult: float = float(pole_data["arc_mult"])
		var perp: Vector2 = Vector2(-axis.y, axis.x)
		var interaction: float = _magnetic_interaction_activity(cell)
		var ambient_vec: Vector2 = sample_ambient_field(to_global(center))
		var ambient_strength: float = clampf(
			ambient_vec.length() / maxf(AMBIENT_FIELD_STRENGTH, 0.001),
			0.0,
			1.0
		)
		var pulse_phase: float = (
			_simulation_time * CELL_FIELD_ARC_PHASE_SPEED
			+ cell.polarity_phase
			+ cell.field_seed * 0.071
		)
		var pulse: float = 1.0 + sin(pulse_phase) * MAG_FILAMENT_PULSE_GAIN * (0.45 + 0.55 * charge_ratio)
		var alpha_scale: float = (0.48 + 0.42 * charge_ratio) * pulse * projector_gain
		alpha_scale *= 0.92 + interaction * 0.30 + ambient_strength * 0.18
		var width_gain: float = 0.88 + arc_mult * 0.22
		var filament_tint: Color = cell.glow_color().lerp(Color(0.38, 0.76, 1.00, 1.0), 0.28)
		var family_count: int = _cell_field_arc_family_count(cell)
		var pole_signs: Array = _cell_field_arc_pole_signs(cell)
		var arc_length: float = _cell_field_arc_reach(geom, radius, charge_ratio, arc_mult)
		for family in family_count:
			var lane: float = _cell_field_arc_lane(family, family_count)
			var family_fade: float = 1.0 - absf(lane) * 0.16
			var glow_alpha: float = MAG_FILAMENT_GLOW_ALPHA * alpha_scale * family_fade
			var core_alpha: float = MAG_FILAMENT_CORE_ALPHA * alpha_scale * family_fade
			var glow_color: Color = Color(filament_tint.r * 0.85, filament_tint.g * 0.94, 1.00, glow_alpha)
			var core_color: Color = Color(
				minf(1.0, filament_tint.r * 0.90 + 0.10),
				minf(1.0, filament_tint.g * 0.96 + 0.06),
				1.00,
				core_alpha
			)
			for pole_sign_value in pole_signs:
				var pole_sign: float = float(pole_sign_value)
				var pole_axis: Vector2 = axis * pole_sign
				var start: Vector2 = center
				var start_dir: Vector2 = pole_axis
				match geom:
					"round":
						start = center + pole_axis * radius * 0.96 + perp * lane * radius * 0.28
						start_dir = (pole_axis + perp * lane * 0.44).normalized()
					"spiral":
						start = center + pole_axis * radius * 0.92 + perp * lane * radius * 0.24
						start_dir = (
							pole_axis
							+ perp * lane * 0.48
							+ pole_axis.orthogonal() * pole_sign * 0.18 * COIL_CELL_FIELD_TORSION_GAIN
						).normalized()
					"crescent":
						start = center + axis * radius * 0.84 + perp * lane * radius * 0.26
						start_dir = (axis + perp * lane * 0.34).normalized()
					"triangle":
						start = center + axis * radius * 1.02 + perp * lane * radius * 0.10
						start_dir = axis.normalized()
				var arc: PackedVector2Array = _integrate_projected_cell_field_arc(
					cell,
					center,
					radius,
					axis,
					geom,
					start,
					start_dir,
					arc_length,
					lane,
					pole_sign,
					pulse_phase + lane * 1.7 + pole_sign * 0.9
				)
				if arc.size() < 3:
					continue
				var segment_phase: float = pulse_phase + lane * 1.7 + pole_sign * 0.8
				var filament_alpha_scale: float = 0.94 + interaction * 0.22 + ambient_strength * 0.16
				_draw_filament_path_on(target, arc, glow_color, core_color, segment_phase, filament_alpha_scale, width_gain)
				filaments_drawn += 1
	return filaments_drawn


func _bezier_arc_polyline_steps(p0: Vector2, c1: Vector2, c2: Vector2, p1: Vector2, segs: int) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(segs + 1):
		var t: float = float(i) / float(segs)
		var u: float = 1.0 - t
		var b: Vector2 = (
			p0 * (u * u * u)
			+ c1 * (3.0 * u * u * t)
			+ c2 * (3.0 * u * t * t)
			+ p1 * (t * t * t)
		)
		pts.append(b)
	return pts


func _draw_filament_path_on(
	target: CanvasItem,
	arc: PackedVector2Array,
	glow_color: Color,
	core_color: Color,
	pulse_phase: float,
	alpha_scale: float,
	width_gain: float = 1.0,
	fade_power: float = CELL_FIELD_ARC_FADE_POWER
) -> void:
	if arc.size() < 2:
		return
	var point_count: int = arc.size()
	var glow_colors: PackedColorArray = PackedColorArray()
	var core_colors: PackedColorArray = PackedColorArray()
	glow_colors.resize(point_count)
	core_colors.resize(point_count)
	var pulse_head: float = fposmod(pulse_phase * 0.10, 1.0)
	var pulse_tail: float = fposmod(pulse_head + 0.28, 1.0)
	for i in range(point_count):
		var t: float = float(i) / float(maxi(point_count - 1, 1))
		var outward_fade: float = pow(maxf(1.0 - t, 0.0), fade_power)
		var pulse_a: float = exp(-pow((t - pulse_head) / 0.16, 2.0))
		var pulse_b: float = exp(-pow((t - pulse_tail) / 0.21, 2.0))
		var pulse_mix: float = maxf(pulse_a, pulse_b)
		var brightness: float = 0.90 + 0.10 * pulse_mix
		var alpha_profile: float = 0.06 + 0.94 * outward_fade
		glow_colors[i] = Color(
			minf(1.0, glow_color.r * (0.96 + 0.04 * pulse_mix)),
			minf(1.0, glow_color.g * brightness),
			1.0,
			glow_color.a * alpha_scale * (0.84 + 0.16 * pulse_mix) * alpha_profile
		)
		core_colors[i] = Color(
			minf(1.0, core_color.r * (0.98 + 0.02 * pulse_mix)),
			minf(1.0, core_color.g * brightness),
			1.0,
			core_color.a * alpha_scale * (0.90 + 0.10 * pulse_mix) * alpha_profile
		)
	var local_glow_width: float = MAG_FILAMENT_GLOW_WIDTH * width_gain
	var local_core_width: float = MAG_FILAMENT_CORE_WIDTH * width_gain
	target.draw_polyline_colors(arc, glow_colors, local_glow_width, true)
	target.draw_polyline_colors(arc, core_colors, local_core_width, true)


func _magnetic_interaction_activity(cell: CellBody) -> float:
	var activity: float = 0.0
	for other in cells:
		if other == cell or other == null or other.signature == null:
			continue
		var other_geom: String = _cell_field_geom(other)
		var other_projector: float = _cell_field_projector_gain(other_geom)
		if other_projector <= 0.0 or other_geom == "line":
			continue
		var dist: float = cell.position.distance_to(other.position)
		var range_max: float = (cell.radius + other.radius) * 5.8
		if dist <= 0.001 or dist >= range_max:
			continue
		var proximity: float = 1.0 - clampf(dist / range_max, 0.0, 1.0)
		var charge_mix: float = sqrt(maxf(cell.charge_ratio_value(), 0.0) * maxf(other.charge_ratio_value(), 0.0))
		activity = maxf(activity, proximity * charge_mix * (0.52 + 0.48 * other_projector))
	return clampf(activity, 0.0, 1.0)


func _magnetic_interaction_vector(cell: CellBody) -> Vector2:
	var interaction_vec: Vector2 = Vector2.ZERO
	for other in cells:
		if other == cell or other == null or other.signature == null:
			continue
		var other_geom: String = _cell_field_geom(other)
		var other_projector: float = _cell_field_projector_gain(other_geom)
		if other_projector <= 0.0 or other_geom == "line":
			continue
		var offset: Vector2 = other.position - cell.position
		var dist: float = offset.length()
		var range_max: float = (cell.radius + other.radius) * 5.8
		if dist <= 0.001 or dist >= range_max:
			continue
		var proximity: float = 1.0 - clampf(dist / range_max, 0.0, 1.0)
		var charge_mix: float = sqrt(maxf(cell.charge_ratio_value(), 0.0) * maxf(other.charge_ratio_value(), 0.0))
		interaction_vec += (offset / dist) * proximity * charge_mix * (0.52 + 0.48 * other_projector)
	if interaction_vec.length_squared() <= 0.000001:
		return Vector2.ZERO
	return interaction_vec.normalized()


func _draw_visual_pole_marks_on(target: CanvasItem, poles: Array) -> void:
	for p in poles:
		var pos: Vector2 = p["pos"] as Vector2
		var q: float = float(p["charge"])
		var is_focus: bool = bool(p.get("is_focus", false))
		var col: Color = MAG_FIELD_VIS_POLE_N_COLOR if q > 0.0 else MAG_FIELD_VIS_POLE_S_COLOR
		var r: float = MAG_FIELD_VIS_POLE_MARK_RADIUS
		if is_focus:
			r *= 0.75
			col = Color(col.r, col.g, col.b, col.a * 0.70)
		# Base disc.
		target.draw_circle(pos, r * 0.90, Color(col.r, col.g, col.b, 0.24))
		target.draw_circle(pos, r * 0.62, Color(col.r, col.g, col.b, 0.46))
		# Glyph: '+' for source, horizontal bar for sink.
		if q > 0.0:
			target.draw_line(pos + Vector2(-r, 0.0), pos + Vector2(r, 0.0), col, 2.0, true)
			target.draw_line(pos + Vector2(0.0, -r), pos + Vector2(0.0, r), col, 2.0, true)
		else:
			target.draw_line(pos + Vector2(-r, 0.0), pos + Vector2(r, 0.0), col, 2.0, true)


func _update_magnetic_debug_probe() -> void:
	var magnetic_sources: Array[Dictionary] = _magnetic_sources_cached()
	var best_sphere: CellBody = null
	var best_charge_abs: float = 0.0
	var best_charge_signed: float = 0.0
	for cell in cells:
		if cell == null or cell.signature == null:
			continue
		if _canonical_geom(cell.signature.geometry_type) != "round":
			continue
		var q: float = cell.signature.charge
		if best_sphere == null or absf(q) > best_charge_abs:
			best_sphere = cell
			best_charge_abs = absf(q)
			best_charge_signed = q
	_mag_debug_sphere_sources = magnetic_sources.size()
	_mag_debug_nearest_sphere_charge = best_charge_signed
	var mouse_local: Vector2 = get_local_mouse_position()
	_mag_debug_mouse_pos = mouse_local
	var mouse_sample: Dictionary = _sample_magnetic_field_superposed(to_global(mouse_local), magnetic_sources)
	_mag_debug_mouse_contributors = int(mouse_sample["contributor_count"])
	_mag_debug_mouse_vector = mouse_sample["field_vec"] as Vector2
	_mag_debug_mouse_strength = _mag_debug_mouse_vector.length()
	_mag_debug_nearest_source_vector = mouse_sample["nearest_contribution"] as Vector2
	_mag_debug_nearest_source_strength = _mag_debug_nearest_source_vector.length()
	if best_sphere == null:
		return
	var probe_local: Vector2 = best_sphere.position + Vector2.RIGHT.rotated(best_sphere.rotation) * (best_sphere.radius + MAG_FIELD_DRAW_SEED_PAD)
	_mag_debug_probe_pos = probe_local
	var probe_sample: Dictionary = _sample_magnetic_field_superposed(to_global(probe_local), magnetic_sources)
	_mag_debug_probe_strength = (probe_sample["field_vec"] as Vector2).length()


func _update_ambient_debug_probe() -> void:
	var mouse_local: Vector2 = get_local_mouse_position()
	var mouse_world: Vector2 = to_global(mouse_local)
	_ambient_debug_mouse_vector = sample_ambient_field(mouse_world)
	_ambient_debug_mouse_strength = _ambient_debug_mouse_vector.length()
	_ambient_debug_mouse_curl = sample_ambient_field_curl_hint(mouse_world)
	_ambient_debug_mouse_calm = sample_ambient_field_calm_metric(mouse_world)
	_total_debug_mouse_vector = sample_total_field(mouse_world)
	_total_debug_mouse_strength = _total_debug_mouse_vector.length()
	_total_debug_mouse_gradient = sample_total_field_gradient(mouse_world)
	_ambient_debug_cell_label = "-"
	_ambient_debug_cell_vector = Vector2.ZERO
	_ambient_debug_cell_strength = 0.0
	_ambient_debug_cell_mode = "idle"
	var best_cell: CellBody = null
	var best_dist_sq: float = INF
	for cell in cells:
		if cell == null or cell.signature == null:
			continue
		var d2: float = mouse_local.distance_squared_to(cell.position)
		if d2 < best_dist_sq:
			best_dist_sq = d2
			best_cell = cell
	if best_cell == null:
		return
	var snapshot: Dictionary = best_cell.ambient_debug_snapshot()
	_ambient_debug_cell_label = _debug_cell_label(best_cell)
	_ambient_debug_cell_vector = snapshot.get("vector", Vector2.ZERO) as Vector2
	_ambient_debug_cell_strength = float(snapshot.get("strength", 0.0))
	_ambient_debug_cell_mode = str(snapshot.get("mode", "idle"))


func _draw_field_line_ticks_on(target: CanvasItem, line: PackedVector2Array, base_color: Color, strength_ratio: float) -> void:
	# Chevron arrow ticks along a streamline so the diagram reads as oriented
	# flow. Tick is a small "V" pointing along the local tangent (the direction
	# of integration), so the user can tell which way the field is going.
	if line.size() < 3:
		return
	var stride: int = maxi(MAG_FIELD_TICK_EVERY_N_POINTS, 2)
	var tick_alpha: float = MAG_FIELD_TICK_ALPHA * (0.35 + 0.65 * strength_ratio)
	var tick_color: Color = Color(base_color.r, base_color.g, base_color.b, tick_alpha)
	var i: int = stride
	while i < line.size() - 1:
		var here: Vector2 = line[i]
		var next: Vector2 = line[i + 1]
		var tangent: Vector2 = next - here
		var t_len: float = tangent.length()
		if t_len < 0.001:
			i += stride
			continue
		tangent /= t_len
		# Chevron points: a small V opening backward along the tangent.
		var back: Vector2 = -tangent * MAG_FIELD_TICK_LENGTH
		var perp: Vector2 = Vector2(-tangent.y, tangent.x) * MAG_FIELD_TICK_LENGTH * 0.55
		var p_left: Vector2 = here + back + perp
		var p_right: Vector2 = here + back - perp
		target.draw_line(here, p_left, tick_color, MAG_FIELD_TICK_WIDTH, true)
		target.draw_line(here, p_right, tick_color, MAG_FIELD_TICK_WIDTH, true)
		i += stride


func _draw_magnetic_contours_on(target: CanvasItem) -> int:
	# Equipotential rings around each round (Sphere) cell. Each ring radius is a
	# multiple of the Plummer soften radius used by sample_magnetic_field(), so
	# the visualization shares parameters with the simulation field.
	var rings_drawn: int = 0
	for cell in cells:
		if cell == null or cell.signature == null:
			continue
		if _canonical_geom(cell.signature.geometry_type) != "round":
			continue
		var charge: float = cell.signature.charge
		if absf(charge) <= 0.00001:
			continue
		var capacity: float = maxf(cell.signature.charge_capacity, 0.0001)
		var charge_ratio: float = clampf(absf(charge) / capacity, 0.0, 2.0)
		var soften: float = maxf(MAG_FIELD_SOFTEN_RADIUS, cell.radius * 0.85)
		var center: Vector2 = cell.position
		# State tint: depleted -> healthy -> overcharged.
		var base_tint: Color = MAG_FIELD_CONTOUR_DEPLETED_TINT
		if charge_ratio >= 0.30:
			var t_healthy: float = clampf((charge_ratio - 0.30) / 0.55, 0.0, 1.0)
			base_tint = MAG_FIELD_CONTOUR_DEPLETED_TINT.lerp(MAG_FIELD_CONTOUR_HEALTHY_TINT, t_healthy)
		if charge_ratio > 0.85:
			var t_over: float = clampf((charge_ratio - 0.85) / 0.30, 0.0, 1.0)
			base_tint = base_tint.lerp(MAG_FIELD_CONTOUR_OVERCHARGED_TINT, t_over)
		# Depleted spheres render only the inner contours so the layer fades
		# alongside their actual emission radius rather than vanishing entirely.
		var max_level_index: int = MAG_FIELD_CONTOUR_LEVELS.size()
		if charge_ratio < 0.30:
			max_level_index = mini(max_level_index, 3)
		var charge_alpha_gain: float = 0.5 + 0.5 * clampf(charge_ratio, 0.0, 1.5)
		for li in max_level_index:
			var level: float = float(MAG_FIELD_CONTOUR_LEVELS[li] as float)
			var r: float = soften * level
			# Sample at the ring radius. Field is rotationally symmetric for a
			# single sphere; for multi-sphere cases this still gives a valid
			# local strength reading per ring.
			var sample_world: Vector2 = to_global(center + Vector2.RIGHT * r)
			var strength: float = sample_magnetic_field(sample_world).length()
			var s_ratio: float = clampf(strength / maxf(MAG_FIELD_MAX_STRENGTH, 0.001), 0.0, 1.0)
			var alpha: float = (
				MAG_FIELD_CONTOUR_BASE_ALPHA
				+ MAG_FIELD_CONTOUR_CHARGE_GAIN * charge_alpha_gain * (1.0 - float(li) / float(MAG_FIELD_CONTOUR_LEVELS.size()))
				+ MAG_FIELD_CONTOUR_STRENGTH_GAIN * s_ratio
			)
			alpha = clampf(alpha, 0.0, MAG_FIELD_CONTOUR_ALPHA_CAP)
			if alpha <= 0.01:
				continue
			var col: Color = Color(base_tint.r, base_tint.g, base_tint.b, alpha)
			target.draw_arc(center, r, 0.0, TAU, MAG_FIELD_CONTOUR_SEGMENTS, col, MAG_FIELD_CONTOUR_WIDTH, true)
			rings_drawn += 1
	return rings_drawn


func _draw_debug_threads() -> void:
	if not CellBody.debug_ports:
		return
	for item in _debug_threads:
		var a: Vector2 = item["from"]
		var b: Vector2 = item["to"]
		var strength: float = float(item["strength"])
		var valid: bool = bool(item["valid"])
		var col: Color = Color(0.70, 0.90, 1.00, 0.10 + 0.10 * strength)
		if not valid:
			col = Color(1.00, 0.45, 0.35, 0.08 + 0.10 * strength)
		draw_line(a, b, col, 0.8 + strength * 0.8, true)


func _draw_fx() -> void:
	for fx in _fx_pulses:
		var pos: Vector2 = fx["pos"]
		var age: float = fx["age"]
		var ttl: float = fx["ttl"]
		var kind: String = str(fx["kind"])
		var strength: float = float(fx["strength"])
		var t: float = clampf(age / maxf(ttl, 0.001), 0.0, 1.0)
		var fade: float = 1.0 - t
		match kind:
			"capture":
				draw_circle(pos, 2.0 + strength * (5.0 + 2.0 * t), Color(1.0, 0.92, 0.75, 0.22 * fade))
				draw_circle(pos, 1.0 + strength * 1.4, Color(1.0, 1.0, 1.0, 0.45 * fade))
			"break":
				draw_arc(pos, 5.0 + 6.0 * t, 0.0, TAU, 18, Color(1.0, 0.52, 0.35, 0.28 * fade), 1.2, true)
			_:
				draw_arc(pos, 3.0 + 7.0 * t, 0.0, TAU, 14, Color(1.0, 0.50, 0.38, 0.34 * fade), 1.0, true)
				draw_circle(pos, 0.9 + strength * 0.8, Color(1.0, 0.86, 0.76, 0.35 * fade))


func _draw_seedlings() -> void:
	if not _seedling_debug_enabled():
		return
	for seedling in _seedlings:
		var members: Array = seedling["members"] as Array
		if members.is_empty():
			continue
		var center: Vector2 = _cluster_centroid(members)
		var halo_r: float = _cluster_halo_radius(members, center) + SEEDLING_HALO_PAD
		var halo: Color = _seedling_color(str(seedling["seedling_type"]))
		var pulse: float = 0.85 + 0.15 * sin(_drift_phase * 1.8 + halo_r * 0.02)
		draw_circle(center, halo_r + 5.0, Color(halo.r, halo.g, halo.b, 0.030 * pulse))
		draw_arc(center, halo_r, 0.0, TAU, 72, Color(halo.r, halo.g, halo.b, 0.24 * pulse), 1.4, true)
		draw_arc(center, halo_r + 4.0, PI * 0.08, PI * 0.92, 24, Color(1.0, 1.0, 1.0, 0.10 * pulse), 0.8, true)


func _draw_trails() -> void:
	for c in cells:
		var trail: PackedVector2Array = c._trail
		var n: int = trail.size()
		if n < 2:
			continue
		var glow: Color = c.glow_color()
		for k in range(n - 1):
			var t1: float = float(k + 1) / float(n - 1)
			var a: float = lerpf(0.05, 0.22, t1)
			var w: float = lerpf(0.6, 1.4, t1)
			draw_line(trail[k], trail[k + 1], Color(glow.r, glow.g, glow.b, a), w, true)
		var last: Vector2 = trail[n - 1]
		draw_line(last, c.position, Color(glow.r, glow.g, glow.b, 0.28), 1.6, true)


func _draw_glass_rim() -> void:
	draw_arc(Vector2.ZERO, DISH_RADIUS + 1.5, 0.0, TAU, 128, RIM_OUTER, 1.4, true)
	draw_arc(Vector2.ZERO, DISH_RADIUS - 0.5, 0.0, TAU, 128, RIM_INNER, 0.9, true)
	draw_arc(Vector2.ZERO, DISH_RADIUS + 0.5, PI * 1.05, PI * 1.55, 32, Color(1.0, 1.0, 1.0, 0.55), 1.6, true)
	draw_arc(Vector2.ZERO, DISH_RADIUS - 3.0, 0.0, TAU, 96, Color(0.10, 0.14, 0.22, 0.65), 0.8, true)


func _draw_plasma_connection_on_bond(bond: Bond, path: PackedVector2Array) -> void:
	if not plasma_bridge_enabled() or path.size() < 2 or not _bond_supports_plasma_connection(bond):
		return
	var state: Dictionary = _plasma_connection_state(bond)
	var stability: float = float(state["stability"])
	var throughput: float = float(state["throughput"])
	var agitation: float = float(state["agitation"])
	var phase: float = _simulation_time * TAU * PLASMA_CONNECTION_FLOW_SPEED + float(bond.a.get_instance_id() % 17) * 0.13
	var pulse_head: float = fposmod(phase * 0.11, 1.0)
	var pulse_tail: float = fposmod(pulse_head + 0.36, 1.0)
	var flicker: float = 1.0
	if agitation > 0.0:
		flicker = 1.0 - 0.14 * agitation + 0.14 * sin(phase * (1.5 + agitation * 1.8))
	var base_col: Color = bond.a.glow_color().lerp(bond.b.glow_color(), 0.5).lerp(Color(0.92, 0.98, 1.00, 1.0), 0.20)
	for i in range(path.size() - 1):
		var p0: Vector2 = path[i]
		var p1: Vector2 = path[i + 1]
		var t0: float = float(i) / float(path.size() - 1)
		var t1: float = float(i + 1) / float(path.size() - 1)
		var mid_t: float = (t0 + t1) * 0.5
		var envelope: float = pow(maxf(sin(PI * mid_t), 0.0), 0.85 * PLASMA_CONNECTION_STABLE_SMOOTHING + 0.25)
		var packet_a: float = exp(-pow((mid_t - pulse_head) / 0.10, 2.0))
		var packet_b: float = exp(-pow((mid_t - pulse_tail) / 0.14, 2.0))
		var packet_mix: float = maxf(packet_a, packet_b)
		var stress_mix: float = 1.0 + agitation * PLASMA_CONNECTION_STRAIN_FLICKER_GAIN * sin(phase * 2.2 + mid_t * TAU * 2.0)
		var alpha: float = PLASMA_CONNECTION_ALPHA * (0.50 + stability * 0.50 + throughput * 0.22) * flicker * stress_mix
		var glow_width: float = PLASMA_CONNECTION_GLOW_WIDTH * (0.55 + envelope * 0.45 + throughput * 0.08)
		var core_width: float = PLASMA_CONNECTION_WIDTH * (0.65 + envelope * 0.35 + throughput * 0.10)
		var bright_gain: float = 0.80 + packet_mix * PLASMA_CONNECTION_PULSE_GAIN + throughput * PLASMA_CONNECTION_BRIGHTNESS_GAIN
		var glow_col: Color = Color(
			minf(1.0, base_col.r * bright_gain),
			minf(1.0, base_col.g * (0.92 + 0.08 * bright_gain)),
			1.0,
			alpha * (0.36 + packet_mix * 0.22) * envelope
		)
		var core_col: Color = Color(
			minf(1.0, 0.88 + base_col.r * 0.18 * bright_gain),
			minf(1.0, 0.94 + base_col.g * 0.08 * bright_gain),
			1.0,
			alpha * (0.72 + packet_mix * 0.28) * envelope
		)
		draw_line(p0, p1, glow_col, glow_width, true)
		draw_line(p0, p1, core_col, core_width, true)


func draw_plasma_bridge_on_bond(bond: Bond, path: PackedVector2Array) -> void:
	# LEGACY NAME: plasma_connection is the visible plasma-bridge conduit layer.
	_draw_plasma_connection_on_bond(bond, path)


func _cluster_metaball_field(p: Vector2, members: Array) -> float:
	# Sum-of-blobs implicit field. Each cell contributes (R / dist)^2 with a
	# small epsilon to avoid singularities. The CLUSTER_SHEATH_THICKNESS
	# multiplier on R inflates the iso surface so it sits a little outside the
	# cell radii, leaving room for visible necks at contact zones.
	var f: float = 0.0
	for m in members:
		var c: CellBody = m
		if c == null:
			continue
		var diff: Vector2 = p - c.position
		var d2: float = diff.length_squared() + 1.0
		var blob_r: float = c.radius * CLUSTER_SHEATH_THICKNESS
		f += (blob_r * blob_r) / d2
	return f


func _trace_cluster_contour(centroid: Vector2, members: Array, iso: float, max_radius: float) -> PackedVector2Array:
	# For each angular sample, binary-search the radius along the ray from
	# centroid where the metaball field crosses the iso value. Produces a
	# closed smooth contour around the cluster's union shape.
	var pts: PackedVector2Array = PackedVector2Array()
	if max_radius <= 0.0:
		return pts
	for i in CLUSTER_SHEATH_SAMPLES:
		var ang: float = (float(i) / float(CLUSTER_SHEATH_SAMPLES)) * TAU
		var dir: Vector2 = Vector2(cos(ang), sin(ang))
		var lo: float = 0.5
		var hi: float = max_radius
		# Centroid is inside the union (field > iso); push hi until outside.
		var safety: int = 0
		while _cluster_metaball_field(centroid + dir * hi, members) > iso and safety < 6:
			hi *= 1.5
			safety += 1
		for _step in CLUSTER_SHEATH_BISECT_STEPS:
			var mid: float = (lo + hi) * 0.5
			var f: float = _cluster_metaball_field(centroid + dir * mid, members)
			if f > iso:
				lo = mid
			else:
				hi = mid
		pts.append(centroid + dir * (lo + hi) * 0.5)
	return pts


func _cluster_sheath_color(members: Array) -> Color:
	var avg: Color = Color(0.0, 0.0, 0.0, 0.0)
	var n: int = 0
	for m in members:
		var c: CellBody = m
		if c == null:
			continue
		avg += c.glow_color()
		n += 1
	if n == 0:
		return Color(0.85, 0.95, 1.0, 1.0)
	avg /= float(n)
	return avg.lerp(Color(0.94, 0.99, 1.00, 1.0), 0.22)


func _draw_cluster_plasma() -> void:
	_cluster_sheath_debug_count = 0
	if not CLUSTER_SHEATH_ENABLED or _clusters_snapshot.is_empty():
		return
	for cluster in _clusters_snapshot:
		var members: Array = cluster as Array
		if members.size() < 2:
			continue
		var centroid: Vector2 = Vector2.ZERO
		var live: int = 0
		for m in members:
			var c: CellBody = m
			if c == null:
				continue
			centroid += c.position
			live += 1
		if live < 2:
			continue
		centroid /= float(live)
		var max_radius: float = 0.0
		for m in members:
			var c2: CellBody = m
			if c2 == null:
				continue
			var span: float = (c2.position - centroid).length() + c2.radius * (CLUSTER_SHEATH_THICKNESS + 1.0)
			max_radius = maxf(max_radius, span)
		if max_radius <= 0.0:
			continue
		# Subtle breathe: iso wobbles slowly so the union shape feels alive
		# without ever resetting. The phase is keyed to centroid so different
		# clusters breathe at different beats.
		var breathe_phase: float = _simulation_time * TAU * CLUSTER_SHEATH_BREATHE_SPEED + (centroid.x + centroid.y) * 0.013
		var iso: float = CLUSTER_SHEATH_ISO * (1.0 + sin(breathe_phase) * CLUSTER_SHEATH_BREATHE_GAIN)
		var contour: PackedVector2Array = _trace_cluster_contour(centroid, members, iso, max_radius)
		if contour.size() < 4:
			continue
		var base_col: Color = _cluster_sheath_color(members)
		_draw_cluster_sheath_path(contour, base_col, breathe_phase)
		_cluster_sheath_debug_count += 1


func _draw_cluster_sheath_path(points: PackedVector2Array, base_col: Color, breathe_phase: float) -> void:
	var n: int = points.size()
	for i in n:
		var p0: Vector2 = points[i]
		var p1: Vector2 = points[(i + 1) % n]
		var mid_t: float = (float(i) + 0.5) / float(n)
		var shimmer: float = 0.7 + 0.3 * sin(breathe_phase + mid_t * TAU * 1.4)
		var glow_col: Color = Color(
			minf(1.0, base_col.r * CLUSTER_SHEATH_BRIGHTNESS_GAIN),
			minf(1.0, base_col.g * (0.95 + 0.05 * shimmer)),
			1.0,
			CLUSTER_SHEATH_GLOW_ALPHA * shimmer,
		)
		var core_col: Color = Color(
			minf(1.0, 0.92 + base_col.r * 0.12),
			minf(1.0, 0.96 + base_col.g * 0.06),
			1.0,
			CLUSTER_SHEATH_CORE_ALPHA * shimmer,
		)
		draw_line(p0, p1, glow_col, CLUSTER_SHEATH_GLOW_WIDTH, true)
		draw_line(p0, p1, core_col, CLUSTER_SHEATH_CORE_WIDTH, true)


func _draw_bonds() -> void:
	if not ENABLE_BONDS:
		return
	_plasma_connection_debug_count = 0
	var frame: int = Engine.get_frames_drawn()
	for bond in bonds:
		var pa: Vector2 = bond.endpoint_a()
		var pb: Vector2 = bond.endpoint_b()
		_draw_bond_styled(bond, pa, pb, frame)


func _draw_bond_styled(bond: Bond, pa: Vector2, pb: Vector2, frame: int) -> void:
	var stress: float = clampf(bond.strain, 0.0, 1.0)
	var base_alpha: float = lerpf(0.85, 0.30, stress)
	var width: float = 0.8 + bond.strength * 1.4
	var plasma_path: PackedVector2Array = _bond_visual_polyline(bond, pa, pb)
	# Sphere-sphere bonds are now bridged by the local plasma shader's
	# capsule term. Fade the legacy line + plasma_connection rope as the
	# merge factor ramps in so we do not stack a hard polyline on top of
	# the merged shared field.
	var sphere_pair: bool = (
		plasma_sheath_enabled()
		and bond.a != null and bond.b != null
		and bond.a.signature != null and bond.b.signature != null
		and (bond.a.signature.geometry_type == "round")
		and (bond.b.signature.geometry_type == "round")
	)
	var legacy_bridge_alpha: float = 1.0
	if sphere_pair:
		legacy_bridge_alpha = clampf(1.0 - bond.plasma_merge_factor, 0.0, 1.0)
		base_alpha *= legacy_bridge_alpha
		if _bond_supports_plasma_connection(bond) and not sphere_pair:
			draw_plasma_bridge_on_bond(bond, plasma_path)
			_plasma_connection_debug_count += 1
			base_alpha *= 0.58
	if bond.capture_timer > 0.0:
		var cap_t: float = bond.capture_timer / CAPTURE_DURATION
		var glow: Color = Color(1.0, 0.92, 0.75, 0.16 + 0.18 * cap_t)
		draw_line(pa, pb, glow, width * 2.2, true)
		draw_circle(pa, 1.5 + 2.0 * cap_t, Color(1.0, 0.96, 0.82, 0.26 + 0.22 * cap_t))
		draw_circle(pb, 1.5 + 2.0 * cap_t, Color(1.0, 0.96, 0.82, 0.26 + 0.22 * cap_t))
	# Per-type styling
	match bond.bond_type:
		"triangle_tip_puncture":
			# Tiny bright puncture/thread, with a small bright kernel at the puncture point
			var col: Color = Color(1.00, 0.55, 0.30, base_alpha)
			draw_line(pa, pb, col, width, true)
			draw_circle(pb, 1.8, Color(1.0, 0.85, 0.55, base_alpha))
			# Faint thread along
			draw_line(pa, pb, Color(1.0, 0.95, 0.75, base_alpha * 0.4), width * 2.0, true)
		"triangle_flat_plate":
			# Calm seam: thin pale line, no flicker, slight thickening
			var col2: Color = Color(0.85, 0.95, 1.00, base_alpha * 0.95)
			draw_line(pa, pb, col2, width * 1.4, true)
		"line_chain", "line_parallel":
			# Conductive link: bright luminous filament, pulses with charge of either end
			var glow: Color = bond.a.glow_color().lerp(bond.b.glow_color(), 0.5)
			draw_line(pa, pb, Color(glow.r, glow.g, glow.b, base_alpha * 0.45), width * 3.0, true)
			draw_line(pa, pb, Color(1.0, 0.98, 0.85, base_alpha), width, true)
		"crescent_cradle":
			# Curved holding thread: slight perpendicular offset midpoint
			var mid: Vector2 = (pa + pb) * 0.5
			var perp: Vector2 = (pb - pa).orthogonal().normalized() * 4.0
			var col3: Color = Color(0.95, 0.55, 0.85, base_alpha)
			# Simple 3-point polyline as a curved thread
			draw_polyline(PackedVector2Array([pa, mid + perp, pb]), col3, width * 1.2, true)
		"crescent_hook":
			var col4: Color = Color(1.00, 0.70, 0.40, base_alpha)
			draw_line(pa, pb, col4, width, true)
			draw_circle(pb, 1.6, Color(1.0, 0.85, 0.55, base_alpha))
		"weak_sliding_contact":
			# Flickery and dim
			var a: float = base_alpha
			if (frame % 6) < 3:
				a *= 0.35
			draw_line(pa, pb, Color(0.65, 0.70, 0.85, a * 0.6), width * 0.7, true)
		"round_soft_overlap":
			var col5: Color = Color(0.85, 0.92, 1.00, base_alpha * 0.7)
			draw_line(pa, pb, col5, width, true)
		_:
			draw_line(pa, pb, Color(0.85, 0.92, 1.00, base_alpha), width, true)
	# Strain veil (red wash) when stressed
	if stress > 0.30:
		var veil: float = base_alpha * 0.4 * stress
		if (frame % 4) < 2:
			veil *= 0.4
		draw_line(pa, pb, Color(1.0, 0.40, 0.35, veil), width * 1.5, true)


# --- spawning ---

func _spawn_cells(n: int) -> void:
	# Startup autospawn follows the same player-facing roster as the hotbar, so
	# legacy Line stays quarantined when `ENABLE_LEGACY_LINE_CELL` is false.
	var pool: Array[CellSignature] = []
	for kind in _active_cell_kinds():
		pool.append(kind["sig"] as CellSignature)
	if pool.is_empty():
		return
	var spawn_radius: float = DISH_RADIUS - SPAWN_MARGIN
	for i in n:
		var pos: Vector2 = _random_point_in_disc(spawn_radius)
		var cell: CellBody = _create_cell(pool[i % pool.size()], pos)
		cell.signature.charge = randf_range(0.0, cell.signature.charge_capacity)


func _create_cell(template: CellSignature, spawn_pos: Vector2) -> CellBody:
	var cell: CellBody = CellBodyScene.instantiate() as CellBody
	cell.set_signature(template)
	_finish_spawned_cell(cell, spawn_pos)
	return cell


func _spawn_selected_cell_at(local_pos: Vector2) -> void:
	var template: CellSignature = _selected_signature_template()
	var cell: CellBody = CellBodyScene.instantiate() as CellBody
	cell.set_signature(template)
	if not _is_spawn_position_valid(local_pos):
		cell.free()
		return
	_finish_spawned_cell(cell, local_pos)
	_invalidate_cluster_cache()
	_update_debug()
	queue_redraw()


func _try_spawn_selected_cell_at(local_pos: Vector2) -> void:
	if not _is_spawn_position_valid(local_pos):
		return
	if _should_ignore_duplicate_spawn(local_pos):
		return
	_spawn_selected_cell_at(local_pos)


func _finish_spawned_cell(cell: CellBody, spawn_pos: Vector2) -> void:
	cell.position = _clamp_point_inside_dish(spawn_pos, cell.radius + 2.0)
	cell.rotation = randf() * TAU
	cell.velocity = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, SPAWN_SPEED_MAX)
	cell.field = field
	add_child(cell)
	cells.append(cell)
	cell.set_process(not simulation_paused)


func _is_spawn_position_valid(local_pos: Vector2) -> bool:
	return local_pos.length() <= DISH_RADIUS


func _clamp_point_inside_dish(local_pos: Vector2, pad: float) -> Vector2:
	var max_dist: float = maxf(0.0, DISH_RADIUS - pad)
	var dist: float = local_pos.length()
	if dist <= max_dist or dist <= 0.0:
		return local_pos
	return local_pos * (max_dist / dist)


func _is_screen_pos_over_ui(_screen_pos: Vector2) -> bool:
	var hovered: Control = get_viewport().gui_get_hovered_control()
	if hovered == null:
		return false
	return hovered.is_visible_in_tree()


func _screen_to_dish_position(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos


func _should_ignore_duplicate_spawn(local_pos: Vector2) -> bool:
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _last_spawn_press_ms <= SPAWN_INPUT_DEDUP_MS and _last_spawn_press_pos.distance_to(local_pos) <= SPAWN_INPUT_DEDUP_DIST:
		return true
	_last_spawn_press_ms = now_ms
	_last_spawn_press_pos = local_pos
	return false


func _find_nearest_cell(local_pos: Vector2) -> CellBody:
	var best: CellBody = null
	var best_dist: float = INF
	for cell in cells:
		var dist: float = cell.position.distance_to(local_pos)
		var limit: float = cell.radius + DELETE_PICK_PAD
		if dist > limit or dist >= best_dist:
			continue
		best = cell
		best_dist = dist
	return best


func _delete_nearest_cell_at(local_pos: Vector2) -> void:
	var victim: CellBody = _find_nearest_cell(local_pos)
	if victim == null:
		return
	_remove_cell(victim)
	_sync_bonded_counts()
	_invalidate_cluster_cache()
	_update_debug()
	queue_redraw()


func _remove_cell(cell: CellBody) -> void:
	var attached: Array[Bond] = []
	for bond in bonds:
		if bond.a == cell or bond.b == cell:
			attached.append(bond)
	for bond in attached:
		_erase_bond(bond, false)
	cells.erase(cell)
	cell.queue_free()


func _clear_dish() -> void:
	for cell in cells:
		cell.queue_free()
	cells.clear()
	_clear_all_bonds()
	bonds.clear()
	_bonded_pairs.clear()
	_bonded_anchors.clear()
	_cell_bond_count.clear()
	_clash_cooldowns.clear()
	_debug_threads.clear()
	_fx_pulses.clear()
	if field != null:
		field.clear_dynamic_state()
	_sync_bonded_counts()
	_invalidate_cluster_cache()
	_bond_scan_accum = 0.0
	_seedling_accum = 0.0
	_apply_pause_state()
	queue_redraw()


func _clear_all_bonds() -> void:
	while not bonds.is_empty():
		_erase_bond(bonds[bonds.size() - 1], false)


func _invalidate_cluster_cache() -> void:
	_clusters_snapshot.clear()
	_seedlings.clear()
	_cluster_count = 0
	_largest_cluster = 0
	_best_coherence = 0.0


func _random_point_in_disc(r: float) -> Vector2:
	var ang: float = randf() * TAU
	var rad: float = sqrt(randf()) * r
	return Vector2(cos(ang), sin(ang)) * rad


func _step_fx(delta: float) -> void:
	if _fx_pulses.is_empty():
		return
	var kept: Array = []
	for fx in _fx_pulses:
		var next_fx: Dictionary = fx.duplicate()
		next_fx["age"] = float(next_fx["age"]) + delta
		if float(next_fx["age"]) < float(next_fx["ttl"]):
			kept.append(next_fx)
	_fx_pulses = kept


func _push_fx(pos: Vector2, kind: String, ttl: float, strength: float = 1.0) -> void:
	_fx_pulses.append({
		"pos": pos,
		"kind": kind,
		"ttl": ttl,
		"age": 0.0,
		"strength": strength,
	})


# --- bond formation ---

func _pair_key(a: CellBody, b: CellBody) -> int:
	var ida: int = a.get_instance_id()
	var idb: int = b.get_instance_id()
	if ida > idb:
		var tmp: int = ida; ida = idb; idb = tmp
	return hash(str(ida) + ":" + str(idb))


func _anchor_key(c: CellBody, idx: int) -> int:
	return hash(str(c.get_instance_id()) + "/" + str(idx))


func _charge_ratio(c: CellBody) -> float:
	return c.signature.charge / maxf(c.signature.charge_capacity, 0.0001)


func _magnetic_sources_cached() -> Array[Dictionary]:
	# Lazy-rebuild: any caller this frame triggers a single refresh; later
	# callers reuse the same list. Avoids per-call Dictionary allocations
	# (used to be ~5,000+/frame from streamline tracing alone).
	var frame: int = Engine.get_process_frames()
	if _cached_magnetic_sources_frame != frame:
		_cached_magnetic_sources = _collect_magnetic_sources()
		_cached_magnetic_sources_frame = frame
	return _cached_magnetic_sources


func _invalidate_magnetic_source_cache() -> void:
	_cached_magnetic_sources_frame = -1


func _collect_magnetic_sources() -> Array[Dictionary]:
	# Cell-field superposition source list. Source weight comes from each
	# cell's base CellField properties (field_strength × field_reach), so the
	# field of effect is universal — every cell contributes, with per-type
	# multipliers baked into CellBody._apply_cell_field_defaults. Sphere stays
	# the strongest broad projector; triangle stays a weak edge emitter.
	var sources: Array[Dictionary] = []
	for cell in cells:
		if not is_instance_valid(cell) or cell.signature == null:
			continue
		if not cell.field_enabled:
			continue
		var weight: float = CELL_FIELD_BASE_STRENGTH * cell.field_strength
		if weight <= 0.0:
			continue
		var capacity: float = maxf(cell.signature.charge_capacity, 0.0001)
		var charge: float = clampf(cell.signature.charge, -capacity, capacity)
		if absf(charge) <= 0.00001:
			continue
		var geom: String = _canonical_geom(cell.signature.geometry_type)
		var soften: float = maxf(MAG_FIELD_SOFTEN_RADIUS, cell.radius * 0.85)
		soften /= maxf(cell.field_reach * CELL_FIELD_BASE_REACH, 0.30)
		sources.append({
			"kind": geom,
			"owner": cell,
			"position": cell.global_position,
			"charge": charge,
			"weight": weight,
			"soften_radius": soften,
		})
	return sources


func _magnetic_source_contribution(world_pos: Vector2, source: Dictionary) -> Vector2:
	var source_pos: Vector2 = source["position"] as Vector2
	var offset: Vector2 = world_pos - source_pos
	var soften_radius: float = float(source["soften_radius"])
	# Plummer soften: r² + r_s². This keeps the contribution finite and smooth
	# even when sampling directly on top of a source center.
	var softened_dist_sq: float = offset.length_squared() + soften_radius * soften_radius
	if softened_dist_sq <= 0.000001:
		return Vector2.ZERO
	var contribution: Vector2 = offset * (
		MAG_FIELD_STRENGTH
		* float(source["weight"])
		* float(source["charge"])
		/ softened_dist_sq
	)
	if not contribution.is_finite():
		return Vector2.ZERO
	return contribution


func _sample_magnetic_field_superposed(world_pos: Vector2, sources: Array[Dictionary]) -> Dictionary:
	var raw_field_vec: Vector2 = Vector2.ZERO
	var contributor_count: int = 0
	var nearest_dist_sq: float = INF
	var nearest_contribution: Vector2 = Vector2.ZERO
	for source in sources:
		var contribution: Vector2 = _magnetic_source_contribution(world_pos, source)
		if contribution.length_squared() > 0.00000001:
			contributor_count += 1
			raw_field_vec += contribution
		var source_pos: Vector2 = source["position"] as Vector2
		var d2: float = world_pos.distance_squared_to(source_pos)
		if d2 < nearest_dist_sq:
			nearest_dist_sq = d2
			nearest_contribution = contribution
	if not raw_field_vec.is_finite():
		raw_field_vec = Vector2.ZERO
	var clamped_field_vec: Vector2 = raw_field_vec.limit_length(MAG_FIELD_MAX_STRENGTH)
	return {
		"field_vec": clamped_field_vec,
		"raw_field_vec": raw_field_vec,
		"contributor_count": contributor_count,
		"nearest_contribution": nearest_contribution,
	}


func sample_magnetic_field(world_pos: Vector2) -> Vector2:
	var sample: Dictionary = _sample_magnetic_field_superposed(world_pos, _magnetic_sources_cached())
	return sample["field_vec"] as Vector2


func sample_neighbor_cell_field(cell: CellBody, world_pos: Vector2) -> Vector2:
	# Neighbor-only cell-field sample for projected arc bending. This uses the
	# same underlying source model as `sample_cell_field`, but excludes the
	# current cell so the rendered arc responds to the surrounding field
	# environment instead of collapsing back into its own source.
	var raw_field_vec: Vector2 = Vector2.ZERO
	for source in _magnetic_sources_cached():
		var owner: Variant = source.get("owner", null)
		if owner == cell:
			continue
		raw_field_vec += _magnetic_source_contribution(world_pos, source)
	if not raw_field_vec.is_finite():
		return Vector2.ZERO
	return raw_field_vec.limit_length(MAG_FIELD_MAX_STRENGTH)


func sample_cell_field(world_pos: Vector2) -> Vector2:
	# LEGACY NAME: sample_magnetic_field is the current cell-field superposition
	# sampler. Keep the old name for compatibility, but prefer this wrapper in
	# new code and docs.
	return sample_magnetic_field(world_pos)


func sample_cell_field_at(world_pos: Vector2, exclude_cell: CellBody = null) -> Vector2:
	# Generic base cell-field sampler. Sums every cell's contribution using its
	# field_strength/field_reach (set via CellBody._apply_cell_field_defaults),
	# softened with Plummer to avoid singularities, clamped at the field max.
	# Renderers and behaviors should prefer this over sample_cell_field/
	# sample_neighbor_cell_field — the latter remain for legacy callers.
	if exclude_cell == null:
		return sample_magnetic_field(world_pos)
	return sample_neighbor_cell_field(exclude_cell, world_pos)


func _decay_clash_cooldowns(delta: float) -> void:
	if _clash_cooldowns.is_empty():
		return
	var to_drop: Array = []
	for k in _clash_cooldowns.keys():
		var v: float = (_clash_cooldowns[k] as float) - delta
		if v <= 0.0:
			to_drop.append(k)
		else:
			_clash_cooldowns[k] = v
	for k in to_drop:
		_clash_cooldowns.erase(k)


func _bond_count_for(c: CellBody) -> int:
	if not ENABLE_BONDS:
		return 0
	var k: int = c.get_instance_id()
	return int(_cell_bond_count.get(k, 0))


func _sync_bonded_counts() -> void:
	# Push the authoritative per-cell bond count onto each cell so its motion code
	# can suppress Brownian/flicker without needing to query the dish dictionary.
	for c in cells:
		c.bonded_count = _bond_count_for(c)


func _capture_motion_baselines() -> Dictionary:
	var baselines: Dictionary = {}
	for cell in cells:
		baselines[cell.get_instance_id()] = {
			"velocity": cell.velocity,
			"angular_velocity": cell.angular_velocity,
		}
	return baselines


func _stabilize_cells_post_forces(baselines: Dictionary, delta: float) -> void:
	for cell in cells:
		var key: int = cell.get_instance_id()
		if not baselines.has(key):
			continue
		var state: Dictionary = baselines[key] as Dictionary
		var prev_velocity: Vector2 = state["velocity"]
		var prev_angular_velocity: float = float(state["angular_velocity"])
		cell.stabilize_external_motion(prev_velocity, prev_angular_velocity, delta)


func _begin_interaction_frame() -> void:
	_debug_threads.clear()
	for c in cells:
		c.begin_interaction_frame()


func _mark_capture_cells() -> void:
	if not ENABLE_BONDS:
		return
	for bond in bonds:
		var capture_ratio: float = 0.0
		if CAPTURE_DURATION > 0.0:
			capture_ratio = maxf(capture_ratio, bond.capture_timer / CAPTURE_DURATION)
		if CAPTURE_MIN_HOLD > 0.0:
			capture_ratio = maxf(capture_ratio, bond.hold_timer / CAPTURE_MIN_HOLD)
		if capture_ratio <= 0.0:
			continue
		bond.a.note_capture(capture_ratio)
		bond.b.note_capture(capture_ratio)


# --- cluster motion ---

func _compute_clusters_lite() -> Array:
	# Returns Array of Array[CellBody]; one entry per connected component (singletons included).
	if not ENABLE_BONDS:
		var free_clusters: Array = []
		for cell in cells:
			free_clusters.append([cell])
		return free_clusters
	var n: int = cells.size()
	if n == 0:
		return []
	var parent: Array[int] = []
	parent.resize(n)
	for i in n:
		parent[i] = i
	var index_of: Dictionary = {}
	for i in n:
		index_of[cells[i].get_instance_id()] = i
	for bond in bonds:
		var ia: int = int(index_of.get(bond.a.get_instance_id(), -1))
		var ib: int = int(index_of.get(bond.b.get_instance_id(), -1))
		if ia < 0 or ib < 0:
			continue
		_union(parent, ia, ib)
	var roots: Dictionary = {}
	for i in n:
		var r: int = _find(parent, i)
		if not roots.has(r):
			roots[r] = []
		(roots[r] as Array).append(cells[i])
	return roots.values()


func _apply_cluster_brownian(delta: float) -> void:
	# One Brownian impulse per cluster (or per free cell). Cluster impulses are
	# weaker than free-cell impulses so that bonded structures drift coherently
	# instead of being shaken apart.
	for cluster in _clusters_snapshot:
		var sz: int = (cluster as Array).size()
		var scale: float = CLUSTER_BROWNIAN_SCALE if sz > 1 else 1.0
		# Bonded clusters get an extra suppression on random impulses so settled
		# pairs/structures drift very little compared to free cells.
		if sz > 1:
			scale *= BONDED_RANDOM_FORCE_MULTIPLIER
		# Average calmness/erratic across cluster (or use single cell's value if free).
		var calm_sum: float = 0.0
		var err_sum: float = 0.0
		var drift_scale: float = 0.0
		for c in cluster:
			var cb: CellBody = c
			var charge_ratio: float = cb.signature.charge / maxf(cb.signature.charge_capacity, 0.0001)
			var starve: float = 0.0
			if charge_ratio < CellBody.LOW_CHARGE_THRESHOLD:
				starve = 1.0 - (charge_ratio / CellBody.LOW_CHARGE_THRESHOLD)
			var eff_stab: float = cb.signature.stability * (1.0 - starve * CellBody.LOW_CHARGE_STABILITY_PENALTY)
			calm_sum += clampf(1.0 - eff_stab * 0.6, 0.2, 1.4)
			err_sum += 1.0 + CellBody.ERRATIC_MULTIPLIER * maxf(0.0, cb.signature.noise - cb._baseline_noise)
			drift_scale += cb.brownian_scale()
		var mean_calm: float = calm_sum / float(sz)
		var mean_err: float = err_sum / float(sz)
		var mean_drift_scale: float = drift_scale / float(sz)
		var brown_mag: float = FREE_BROWNIAN_BASE * mean_calm * mean_err * scale * mean_drift_scale
		if brown_mag <= 0.0:
			continue
		var brown: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * brown_mag
		var d_v: Vector2 = brown * delta
		for c in cluster:
			(c as CellBody).apply_velocity_delta(d_v)


func _apply_cluster_coupling(delta: float) -> void:
	# Treat each bonded cluster as a soft rigid body: compute centroid, shared
	# linear velocity, and a shared angular velocity that combines translational
	# angular momentum (members moving tangentially around the CoM) with the
	# average per-cell spin. Each member's velocity is then damped toward the
	# rigid-body target v_cm + omega x r, which removes internal contradiction
	# (cells on opposite sides of the CoM no longer fight) without freezing the
	# cluster — external forces still move v_cm and the cluster as a whole.
	var v_factor: float = clampf(CLUSTER_VEL_COUPLING * delta, 0.0, 0.95)
	var w_factor: float = clampf(CLUSTER_ANG_COUPLING * delta, 0.0, 0.95)
	for cluster in _clusters_snapshot:
		var sz: int = (cluster as Array).size()
		if sz < 2:
			continue
		var com: Vector2 = Vector2.ZERO
		var sum_v: Vector2 = Vector2.ZERO
		var sum_w: float = 0.0
		for c in cluster:
			var cb: CellBody = c
			com += cb.position
			sum_v += cb.velocity
			sum_w += cb.angular_velocity
		var inv_n: float = 1.0 / float(sz)
		com *= inv_n
		var mean_v: Vector2 = sum_v * inv_n
		var mean_spin: float = sum_w * inv_n
		# Translational angular momentum / moment of inertia about the CoM.
		# omega_trans is the rigid rotation rate that best explains the
		# tangential component of (v_i - v_cm) across all members.
		var l_trans: float = 0.0
		var i_total: float = 0.0
		for c in cluster:
			var cb_i: CellBody = c
			var r: Vector2 = cb_i.position - com
			var v_rel: Vector2 = cb_i.velocity - mean_v
			l_trans += r.x * v_rel.y - r.y * v_rel.x
			i_total += r.length_squared()
		var omega_trans: float = 0.0
		if i_total > CLUSTER_INERTIA_FLOOR:
			omega_trans = l_trans / i_total
		var omega_cluster: float = omega_trans * CLUSTER_OMEGA_TRANS_WEIGHT + mean_spin * CLUSTER_OMEGA_SPIN_WEIGHT
		for c in cluster:
			var cb_t: CellBody = c
			var rt: Vector2 = cb_t.position - com
			# 2D cross product omega x r = (-omega*r.y, omega*r.x). This is the
			# tangential velocity each member would have under rigid rotation.
			var target_v: Vector2 = mean_v + Vector2(-omega_cluster * rt.y, omega_cluster * rt.x)
			cb_t.velocity = cb_t.velocity.lerp(target_v, v_factor)
			cb_t.angular_velocity = lerpf(cb_t.angular_velocity, omega_cluster, w_factor)


# --- anchor seating: PBD position projection toward bond rest distance ---

func _seat_anchors() -> void:
	if not ENABLE_BONDS:
		return
	for bond in bonds:
		if bond.bond_type == "weak_sliding_contact":
			continue  # sliding contacts shouldn't snap
		var pa: Vector2 = bond.endpoint_a()
		var pb: Vector2 = bond.endpoint_b()
		var diff: Vector2 = pb - pa
		var dist: float = diff.length()
		if dist < 0.001:
			continue
		var error: float = dist - bond.rest_distance
		if absf(error) < BOND_ANCHOR_DEADZONE:
			continue
		var capturing: bool = bond.capture_timer > 0.0
		var rate: float = SEAT_RATE_CAPTURE if capturing else SEAT_RATE_BASE
		var max_corr: float = MAX_CAPTURE_LINEAR_CORRECTION if capturing else MAX_BASE_LINEAR_CORRECTION
		# Cap the per-tick correction so a freshly formed bond resolves over many
		# frames. error * rate can be large (legacy scan accepts ANCHOR_PROXIMITY=30
		# with rest 0..6); without this clamp each cell would jump up to ~error*rate*0.5
		# px in a single frame, which reads as a teleport.
		var corr_mag: float = minf(absf(error) * rate, max_corr)
		var corr: Vector2 = (diff / dist) * (corr_mag * sign(error))
		bond.a.position += corr * 0.5
		bond.b.position -= corr * 0.5


func _resolve_cell_collisions() -> void:
	# Position-Based Dynamics soft separation. Runs once per frame after bond physics.
	# Skips bonded pairs (their bond owns their spacing) and applies a small velocity
	# damp so cells settle into contact instead of bouncing off each other.
	var n: int = cells.size()
	for i in n:
		var a: CellBody = cells[i]
		for j in range(i + 1, n):
			var b: CellBody = cells[j]
			if ENABLE_BONDS and _bonded_pairs.has(_pair_key(a, b)):
				continue
			var diff: Vector2 = b.position - a.position
			var dist: float = diff.length()
			if dist < 0.001:
				continue
			var min_dist: float = a.radius + b.radius + COLLISION_PADDING
			var penetration: float = min_dist - dist
			if penetration <= COLLISION_SLOP:
				continue
			var n_dir: Vector2 = diff / dist
			var corr: Vector2 = n_dir * (penetration * 0.5)
			a.position -= corr
			b.position += corr
			var rel_v: Vector2 = b.velocity - a.velocity
			var closing: float = rel_v.dot(n_dir)
			if closing < 0.0:
				var imp: Vector2 = n_dir * closing * COLLISION_VEL_DAMP
				a.apply_velocity_delta(imp * 0.5)
				b.apply_velocity_delta(-imp * 0.5)


# --- pre-bond guidance (every frame) ---

func _update_guidance(delta: float) -> void:
	var best_by_cell: Dictionary = {}
	var capture_requests: Dictionary = {}
	var n: int = cells.size()
	for i in n:
		var a: CellBody = cells[i]
		var ports_a: Array[Dictionary] = a.get_world_ports()
		for j in range(i + 1, n):
			var b: CellBody = cells[j]
			if ENABLE_BONDS and _bonded_pairs.has(_pair_key(a, b)):
				continue
			var center_dist: float = a.position.distance_to(b.position)
			if center_dist > GUIDANCE_RANGE + a.radius + b.radius:
				continue
			var ports_b: Array[Dictionary] = b.get_world_ports()
			var evaluation: Dictionary = _evaluate_pair_interaction(a, b, ports_a, ports_b)
			if evaluation.is_empty():
				continue
			if bool(evaluation.get("has_valid", false)):
				_store_best_candidate(best_by_cell, a, _make_valid_candidate(a, b, evaluation, true))
				_store_best_candidate(best_by_cell, b, _make_valid_candidate(b, a, evaluation, false))
				if _can_capture_now(a, b, evaluation):
					var pk: int = _pair_key(a, b)
					if not capture_requests.has(pk) or float((capture_requests[pk] as Dictionary)["score"]) < float(evaluation["valid_score"]):
						capture_requests[pk] = {
							"a": a,
							"b": b,
							"a_anchor": int(evaluation["a_anchor"]),
							"b_anchor": int(evaluation["b_anchor"]),
							"info": evaluation["info"],
							"score": float(evaluation["valid_score"]),
						}
			if bool(evaluation.get("has_invalid", false)):
				_store_best_candidate(best_by_cell, a, _make_invalid_candidate(a, b, evaluation, true))
				_store_best_candidate(best_by_cell, b, _make_invalid_candidate(b, a, evaluation, false))
				if float(evaluation["invalid_dist"]) < GUIDANCE_REPEL_RANGE * 0.55:
					_emit_clash(a, b)
	for c in cells:
		var key: int = c.get_instance_id()
		if best_by_cell.has(key):
			_apply_interaction_candidate(best_by_cell[key] as Dictionary, delta)
	for request in capture_requests.values():
		_try_capture_request(request as Dictionary)


func _evaluate_pair_interaction(a: CellBody, b: CellBody, ports_a: Array[Dictionary], ports_b: Array[Dictionary]) -> Dictionary:
	var best_valid_score: float = 0.0
	var best_info: Dictionary = {}
	var best_a_anchor: int = -1
	var best_b_anchor: int = -1
	var best_a_pos: Vector2 = Vector2.ZERO
	var best_b_pos: Vector2 = Vector2.ZERO
	var best_a_dir: Vector2 = Vector2.ZERO
	var best_b_dir: Vector2 = Vector2.ZERO
	var best_face: float = 1.0
	var min_invalid_dist: float = 1e9
	var invalid_score: float = 0.0
	var invalid_a_pos: Vector2 = Vector2.ZERO
	var invalid_b_pos: Vector2 = Vector2.ZERO
	var invalid_a_dir: Vector2 = Vector2.ZERO
	var invalid_b_dir: Vector2 = Vector2.ZERO
	for pa_idx in ports_a.size():
		var port_a: Dictionary = ports_a[pa_idx]
		for pb_idx in ports_b.size():
			var port_b: Dictionary = ports_b[pb_idx]
			var a_pos: Vector2 = port_a.position
			var b_pos: Vector2 = port_b.position
			var d: float = a_pos.distance_to(b_pos)
			if d > GUIDANCE_RANGE:
				continue
			var a_dir: Vector2 = port_a.direction
			var b_dir: Vector2 = port_b.direction
			var face: float = a_dir.dot(b_dir)
			var info: Dictionary = _classify_contact(
				a.signature.geometry_type,
				b.signature.geometry_type,
				port_a.zone as String,
				port_b.zone as String,
				face,
			)
			var kind: String = str(info["type"])
			if kind != "clash_noise" and kind != "weak_sliding_contact":
				var score: float = _pair_valid_score(a, b, port_a, port_b, info, d, face)
				if score > best_valid_score:
					best_valid_score = score
					best_info = info
					best_a_anchor = pa_idx
					best_b_anchor = pb_idx
					best_a_pos = a_pos
					best_b_pos = b_pos
					best_a_dir = a_dir
					best_b_dir = b_dir
					best_face = face
			else:
				var repel_score: float = _pair_invalid_score(a, b, port_a, port_b, d, face)
				if repel_score > 0.0 and d < min_invalid_dist:
					min_invalid_dist = d
					invalid_score = repel_score
					invalid_a_pos = a_pos
					invalid_b_pos = b_pos
					invalid_a_dir = a_dir
					invalid_b_dir = b_dir
	if _canonical_geom(a.signature.geometry_type) == "round" and _canonical_geom(b.signature.geometry_type) == "round":
		var center_dist: float = a.position.distance_to(b.position)
		if center_dist < GUIDANCE_REPEL_RANGE + a.radius + b.radius:
			var round_invalid: float = _round_pair_invalid_score(a, b, center_dist)
			if round_invalid > invalid_score:
				invalid_score = round_invalid
				min_invalid_dist = center_dist
				invalid_a_pos = a.position
				invalid_b_pos = b.position
				invalid_a_dir = (b.position - a.position).normalized() if center_dist > 0.001 else Vector2.RIGHT
				invalid_b_dir = -invalid_a_dir
	if best_valid_score <= 0.0 and invalid_score <= 0.0:
		return {}
	return {
		"has_valid": best_valid_score > 0.0,
		"valid_score": best_valid_score,
		"info": best_info,
		"a_anchor": best_a_anchor,
		"b_anchor": best_b_anchor,
		"a_pos": best_a_pos,
		"b_pos": best_b_pos,
		"a_dir": best_a_dir,
		"b_dir": best_b_dir,
		"face": best_face,
		"valid_dist": best_a_pos.distance_to(best_b_pos),
		"has_invalid": invalid_score > 0.0,
		"invalid_score": invalid_score,
		"invalid_dist": min_invalid_dist,
		"invalid_a_pos": invalid_a_pos,
		"invalid_b_pos": invalid_b_pos,
		"invalid_a_dir": invalid_a_dir,
		"invalid_b_dir": invalid_b_dir,
	}


func _round_pair_invalid_score(a: CellBody, b: CellBody, center_dist: float) -> float:
	var prox: float = 1.0 - clampf(center_dist / (GUIDANCE_REPEL_RANGE + a.radius + b.radius), 0.0, 1.0)
	var score: float = 0.0
	if a.is_round_overcharged() and b.charge_ratio_value() >= CellBody.ROUND_HEALTHY_MIN_RATIO:
		score = maxf(score, prox * (0.65 + 0.35 * a.round_overcharge_factor()))
	if b.is_round_overcharged() and a.charge_ratio_value() >= CellBody.ROUND_HEALTHY_MIN_RATIO:
		score = maxf(score, prox * (0.65 + 0.35 * b.round_overcharge_factor()))
	if a.is_round_healthy() and b.round_noise_excess() > 0.12:
		score = maxf(score, prox * (0.32 + 0.25 * clampf(b.round_noise_excess(), 0.0, 1.0)))
	if b.is_round_healthy() and a.round_noise_excess() > 0.12:
		score = maxf(score, prox * (0.32 + 0.25 * clampf(a.round_noise_excess(), 0.0, 1.0)))
	return score


func _pair_valid_score(a: CellBody, b: CellBody, port_a: Dictionary, port_b: Dictionary, info: Dictionary, dist: float, face: float) -> float:
	var face_factor: float = clampf((-face - FACE_DOT_MAX) / (1.0 - FACE_DOT_MAX), 0.0, 1.0)
	var prox: float = 1.0 - clampf(dist / GUIDANCE_RANGE, 0.0, 1.0)
	var score: float = float(info["strength"]) * (0.28 + 0.72 * prox) * (0.24 + 0.76 * face_factor)
	score *= _pair_role_bonus(a, b, port_a.zone as String, port_b.zone as String, str(info["type"]))
	return score


func _pair_role_bonus(a: CellBody, b: CellBody, zone_a: String, zone_b: String, bond_type: String) -> float:
	var ga: String = _canonical_geom(a.signature.geometry_type)
	var gb: String = _canonical_geom(b.signature.geometry_type)
	var ra: float = _charge_ratio(a)
	var rb: float = _charge_ratio(b)
	match bond_type:
		"triangle_tip_puncture":
			if ga == "triangle" and gb == "round":
				return 1.10 + GUIDANCE_TRIANGLE_ROUND_BONUS * (1.0 - ra) + GUIDANCE_ROUND_FIELD * rb
			if gb == "triangle" and ga == "round":
				return 1.10 + GUIDANCE_TRIANGLE_ROUND_BONUS * (1.0 - rb) + GUIDANCE_ROUND_FIELD * ra
			return 1.05 + GUIDANCE_TRIANGLE_LINE_BONUS
		"line_chain":
			if zone_a == "end" and zone_b == "end":
				return 1.05 + GUIDANCE_LINE_CHAIN_BONUS
			return 1.0 + GUIDANCE_ROUND_FIELD * maxf(ra, rb) * 0.30
		"line_parallel":
			return 1.0 + GUIDANCE_LINE_CHAIN_BONUS * 0.40
		"crescent_cradle":
			return 1.08 + GUIDANCE_CRESCENT_CRADLE_BONUS + GUIDANCE_ROUND_FIELD * maxf(ra, rb) * 0.25
		"crescent_hook":
			return 1.04 + GUIDANCE_CRESCENT_CRADLE_BONUS * 0.55
		"triangle_flat_plate":
			return 1.0 + GUIDANCE_PLATE_BONUS
		"round_soft_overlap":
			if ga == "round" and gb == "round":
				var dep_a: float = a.round_depletion_factor()
				var dep_b: float = b.round_depletion_factor()
				var healthy_a: float = a.round_healthy_factor()
				var healthy_b: float = b.round_healthy_factor()
				var over_a: float = a.round_overcharge_factor()
				var over_b: float = b.round_overcharge_factor()
				var noisy_a: float = a.round_noise_excess()
				var noisy_b: float = b.round_noise_excess()
				if over_a > 0.0 and rb >= CellBody.ROUND_HEALTHY_MIN_RATIO:
					return 0.18
				if over_b > 0.0 and ra >= CellBody.ROUND_HEALTHY_MIN_RATIO:
					return 0.18
				if dep_a > 0.0 and rb >= CellBody.ROUND_HEALTHY_MIN_RATIO:
					return 0.72 + dep_a * 0.55 + rb * 0.20
				if dep_b > 0.0 and ra >= CellBody.ROUND_HEALTHY_MIN_RATIO:
					return 0.72 + dep_b * 0.55 + ra * 0.20
				if healthy_a > 0.0 and healthy_b > 0.0 and noisy_a < 0.14 and noisy_b < 0.14:
					return 0.34 + 0.18 * minf(healthy_a, healthy_b)
				if noisy_a > 0.12 or noisy_b > 0.12:
					return 0.22
			return 0.88 + maxf(ra, rb) * 0.22
	return 1.0


func _pair_invalid_score(a: CellBody, b: CellBody, port_a: Dictionary, port_b: Dictionary, dist: float, face: float) -> float:
	if dist > GUIDANCE_REPEL_RANGE:
		return 0.0
	var prox: float = 1.0 - clampf(dist / GUIDANCE_REPEL_RANGE, 0.0, 1.0)
	var score: float = prox * (0.55 + 0.45 * clampf(1.0 - maxf(0.0, -face), 0.0, 1.0))
	if port_a.zone == "tip_sharp" or port_b.zone == "tip_sharp":
		score *= 1.35
	if port_a.zone == "outer_curve" or port_b.zone == "outer_curve":
		score *= 1.25
	if _canonical_geom(a.signature.geometry_type) == "triangle" and _canonical_geom(b.signature.geometry_type) == "triangle":
		score *= 1.30
	return score


func _make_valid_candidate(cell: CellBody, other: CellBody, evaluation: Dictionary, cell_is_a: bool) -> Dictionary:
	var from_pos: Vector2 = Vector2.ZERO
	var to_pos: Vector2 = Vector2.ZERO
	var from_dir: Vector2 = Vector2.ZERO
	var self_anchor: int = -1
	var other_anchor: int = -1
	if cell_is_a:
		from_pos = evaluation["a_pos"]
		to_pos = evaluation["b_pos"]
		from_dir = evaluation["a_dir"]
		self_anchor = int(evaluation["a_anchor"])
		other_anchor = int(evaluation["b_anchor"])
	else:
		from_pos = evaluation["b_pos"]
		to_pos = evaluation["a_pos"]
		from_dir = evaluation["b_dir"]
		self_anchor = int(evaluation["b_anchor"])
		other_anchor = int(evaluation["a_anchor"])
	var zone_self: String = cell.ports[self_anchor].zone_type
	var zone_other: String = other.ports[other_anchor].zone_type
	var drive: float = _cell_seek_drive(cell, other, zone_self, zone_other, str((evaluation["info"] as Dictionary)["type"]))
	return {
		"kind": "valid",
		"cell": cell,
		"other": other,
		"from": from_pos,
		"to": to_pos,
		"normal": from_dir,
		"score": float(evaluation["valid_score"]) * drive,
		"distance": float(evaluation["valid_dist"]),
		"bond_type": str((evaluation["info"] as Dictionary)["type"]),
	}


func _make_invalid_candidate(cell: CellBody, other: CellBody, evaluation: Dictionary, cell_is_a: bool) -> Dictionary:
	var from_pos: Vector2 = Vector2.ZERO
	var to_pos: Vector2 = Vector2.ZERO
	if cell_is_a:
		from_pos = evaluation["invalid_a_pos"]
		to_pos = evaluation["invalid_b_pos"]
	else:
		from_pos = evaluation["invalid_b_pos"]
		to_pos = evaluation["invalid_a_pos"]
	var drive: float = _cell_invalid_drive(cell, other, from_pos, to_pos)
	return {
		"kind": "invalid",
		"cell": cell,
		"other": other,
		"from": from_pos,
		"to": to_pos,
		"score": float(evaluation["invalid_score"]) * drive,
		"distance": float(evaluation["invalid_dist"]),
	}


func _cell_seek_drive(cell: CellBody, other: CellBody, zone_self: String, zone_other: String, bond_type: String) -> float:
	var geom_self: String = _canonical_geom(cell.signature.geometry_type)
	var geom_other: String = _canonical_geom(other.signature.geometry_type)
	var self_charge: float = _charge_ratio(cell)
	var other_charge: float = _charge_ratio(other)
	var low_energy_gate: float = 1.0
	if geom_self != "triangle" and self_charge < GUIDANCE_CHARGE_MIN:
		low_energy_gate = 0.55
	match geom_self:
		"triangle":
			if bond_type == "triangle_tip_puncture" and geom_other == "round":
				return 0.95 + (1.0 - self_charge) * 1.25 + other_charge * 0.35
			if bond_type == "triangle_tip_puncture":
				return 0.95 + (1.0 - self_charge) * 0.75
			if bond_type == "triangle_flat_plate":
				return 0.90
		"line":
			if bond_type == "line_chain" and zone_self == "end" and zone_other == "end":
				return 1.25 * low_energy_gate
			if bond_type == "line_parallel":
				return 0.95 * low_energy_gate
			return 1.05 * low_energy_gate
		"crescent":
			if bond_type == "crescent_cradle" and geom_other == "round":
				return (1.18 + other_charge * 0.18) * low_energy_gate
			if bond_type == "crescent_hook" and geom_other == "line":
				return 1.08 * low_energy_gate
		"round":
			if geom_other == "round":
				if cell.is_round_overcharged() and other.charge_ratio_value() >= CellBody.ROUND_HEALTHY_MIN_RATIO:
					return 0.10
				if cell.is_round_depleted() and other.charge_ratio_value() >= CellBody.ROUND_HEALTHY_MIN_RATIO:
					return 0.82 + cell.round_depletion_factor() * 0.48
				if cell.is_round_healthy() and other.is_round_healthy() and other.round_noise_excess() < 0.14:
					return 0.30 + 0.12 * minf(cell.round_healthy_factor(), other.round_healthy_factor())
				if other.round_noise_excess() > 0.12:
					return 0.14
			if geom_other == "triangle":
				return 0.48 + self_charge * 0.40
			if geom_other == "line":
				return 0.58 + self_charge * 0.32
			if geom_other == "crescent":
				return 0.54 + self_charge * 0.30
	return 1.0 * low_energy_gate


func _cell_invalid_drive(cell: CellBody, other: CellBody, from_pos: Vector2, to_pos: Vector2) -> float:
	var geom_self: String = _canonical_geom(cell.signature.geometry_type)
	var geom_other: String = _canonical_geom(other.signature.geometry_type)
	var drive: float = 1.0
	if geom_self == "triangle":
		drive += 0.22
	if geom_self == "round" and geom_other == "round":
		if cell.is_round_overcharged() and other.charge_ratio_value() >= CellBody.ROUND_HEALTHY_MIN_RATIO:
			drive += 0.55 + cell.round_overcharge_factor() * 0.45
		if cell.is_round_healthy() and other.round_noise_excess() > 0.12:
			drive += 0.35
	if geom_self == "round" and geom_other != "round":
		drive -= 0.18
	if geom_self == "crescent":
		drive += 0.12
	if from_pos.distance_to(to_pos) < GUIDANCE_REPEL_RANGE * 0.45:
		drive += 0.22
	return drive


func _store_best_candidate(best_by_cell: Dictionary, cell: CellBody, candidate: Dictionary) -> void:
	if candidate.is_empty():
		return
	var key: int = cell.get_instance_id()
	if not best_by_cell.has(key) or float((best_by_cell[key] as Dictionary)["score"]) < float(candidate["score"]):
		best_by_cell[key] = candidate


func _apply_interaction_candidate(candidate: Dictionary, delta: float) -> void:
	var cell: CellBody = candidate["cell"] as CellBody
	var other: CellBody = candidate["other"] as CellBody
	var from_pos: Vector2 = candidate["from"]
	var to_pos: Vector2 = candidate["to"]
	var score: float = clampf(float(candidate["score"]), 0.0, 2.0)
	var diff: Vector2 = to_pos - from_pos
	var dist: float = diff.length()
	if dist < 0.001 or score <= 0.0:
		return
	var dir: Vector2 = diff / dist
	var seek_strength: float = clampf(score, 0.0, 1.0)
	cell.note_seek(seek_strength)
	if CellBody.debug_ports:
		_debug_threads.append({
			"from": from_pos,
			"to": to_pos,
			"strength": seek_strength,
			"valid": candidate["kind"] == "valid",
		})
	if candidate["kind"] == "valid":
		var from_normal: Vector2 = candidate["normal"]
		var prox: float = 1.0 - clampf(dist / GUIDANCE_RANGE, 0.0, 1.0)
		var near_cap: float = clampf(dist / GUIDANCE_NEAR_CUTOFF, 0.0, 1.0)
		var direct_scale: float = 1.0
		var tangent_scale: float = 0.0
		if _canonical_geom(cell.signature.geometry_type) == "round" and _canonical_geom(other.signature.geometry_type) == "round":
			if cell.is_round_healthy() and other.is_round_healthy():
				direct_scale = 0.35
				tangent_scale = 0.22
			elif cell.is_round_depleted() and other.charge_ratio_value() >= CellBody.ROUND_HEALTHY_MIN_RATIO:
				direct_scale = 0.80
				tangent_scale = 0.14
		cell.apply_field_velocity_delta(dir * GUIDANCE_ATTRACT_MAX * score * prox * maxf(near_cap, 0.22) * direct_scale * delta)
		if tangent_scale > 0.0:
			var orbit_sign: float = 1.0 if cell.get_instance_id() < other.get_instance_id() else -1.0
			cell.apply_field_velocity_delta(dir.orthogonal() * orbit_sign * GUIDANCE_ATTRACT_MAX * score * prox * tangent_scale * delta)
		_apply_align_torque(cell, from_pos, from_normal, to_pos, GUIDANCE_ALIGN_MAX * score, delta)
		cell.signature.charge = maxf(0.0, cell.signature.charge - GUIDANCE_CHARGE_COST * score * delta)
		if dist <= GUIDANCE_CAPTURE_RADIUS:
			var capture: float = 1.0 - clampf(dist / GUIDANCE_CAPTURE_RADIUS, 0.0, 1.0)
			cell.note_capture(capture)
			cell.apply_field_velocity_delta(dir * GUIDANCE_CAPTURE_PULL * score * maxf(0.25, capture) * delta)
			_apply_align_torque(cell, from_pos, from_normal, to_pos, GUIDANCE_CAPTURE_ALIGN * score * (0.5 + capture), delta)
			var v_lerp: float = clampf(GUIDANCE_CAPTURE_VEL_DAMP * delta * (0.4 + capture), 0.0, 0.88)
			var w_lerp: float = clampf(GUIDANCE_CAPTURE_ANG_DAMP * delta * (0.4 + capture), 0.0, 0.92)
			cell.velocity = cell.velocity.lerp(other.velocity, v_lerp)
			cell.angular_velocity = lerpf(cell.angular_velocity, other.angular_velocity, w_lerp)
	else:
		var prox_invalid: float = 1.0 - clampf(dist / GUIDANCE_REPEL_RANGE, 0.0, 1.0)
		var away: Vector2 = -dir
		cell.apply_field_velocity_delta(away * GUIDANCE_REPEL_MAX * score * prox_invalid * delta)
		var tangent: Vector2 = away.orthogonal()
		var rel_v: Vector2 = other.velocity - cell.velocity
		var slide_sign: float = sign(rel_v.dot(tangent))
		if is_zero_approx(slide_sign):
			slide_sign = 1.0 if cell.get_instance_id() < other.get_instance_id() else -1.0
		cell.apply_field_velocity_delta(tangent * slide_sign * GUIDANCE_INVALID_SLIDE * score * prox_invalid * delta)
		cell.angular_velocity *= exp(-GUIDANCE_CAPTURE_ANG_DAMP * 0.35 * delta)
		cell.signature.noise = clampf(cell.signature.noise + GUIDANCE_FAIL_NOISE * 0.08 * prox_invalid * delta, 0.0, CellBody.NOISE_MAX)


func _can_capture_now(a: CellBody, b: CellBody, evaluation: Dictionary) -> bool:
	if not _cell_can_bond(a) or not _cell_can_bond(b):
		return false
	if float(evaluation["valid_dist"]) > GUIDANCE_CAPTURE_RADIUS:
		return false
	if _canonical_geom(a.signature.geometry_type) == "round" and _canonical_geom(b.signature.geometry_type) == "round":
		if _round_pair_invalid_score(a, b, a.position.distance_to(b.position)) >= float(evaluation["valid_score"]):
			return false
	if not _capture_face_ok(str((evaluation["info"] as Dictionary)["type"]), float(evaluation["face"])):
		return false
	if field.sample_noise((a.position + b.position) * 0.5) > BOND_NOISE_LIMIT:
		return false
	return true


func _capture_face_ok(bond_type: String, face: float) -> bool:
	match bond_type:
		"triangle_flat_plate":
			return face <= FLAT_PLATE_FACE_MAX
		"line_chain":
			return face <= 0.15
		"line_parallel":
			return face <= -0.20
		"triangle_tip_puncture", "crescent_cradle":
			return face <= 0.10
		"crescent_hook":
			return face <= 0.25
		"round_soft_overlap":
			return true
	return face <= FACE_DOT_MAX


func _cell_can_bond(cell: CellBody) -> bool:
	if not ENABLE_BONDS:
		return false
	if _bond_count_for(cell) >= MAX_BONDS_PER_CELL:
		return false
	return _charge_ratio(cell) >= BOND_MIN_CHARGE_RATIO


func _try_capture_request(request: Dictionary) -> void:
	if not ENABLE_BONDS:
		return
	var a: CellBody = request["a"] as CellBody
	var b: CellBody = request["b"] as CellBody
	if bonds.size() >= MAX_TOTAL_BONDS:
		return
	if _bonded_pairs.has(_pair_key(a, b)):
		return
	if not _cell_can_bond(a) or not _cell_can_bond(b):
		return
	var pa: int = int(request["a_anchor"])
	var pb: int = int(request["b_anchor"])
	if _bonded_anchors.has(_anchor_key(a, pa)) or _bonded_anchors.has(_anchor_key(b, pb)):
		return
	_form_bond(a, b, pa, pb, request["info"] as Dictionary)


# Rotate `cell` so the anchor at `anchor_pos` (with current world normal `anchor_normal`)
# points toward `target_pos`.
func _apply_align_torque(cell: CellBody, anchor_pos: Vector2, anchor_normal: Vector2, target_pos: Vector2, gain: float, delta: float) -> void:
	var desired: Vector2 = target_pos - anchor_pos
	var dl: float = desired.length()
	if dl < 0.001:
		return
	desired /= dl
	# 2D cross product = sin(angle from anchor_normal to desired).
	var sn: float = anchor_normal.x * desired.y - anchor_normal.y * desired.x
	cell.apply_angular_delta(sn * gain * delta)


func _scan_for_bonds() -> void:
	if not ENABLE_BONDS:
		return
	if bonds.size() >= MAX_TOTAL_BONDS:
		return
	var n: int = cells.size()
	for i in n:
		var a: CellBody = cells[i]
		if _bond_count_for(a) >= MAX_BONDS_PER_CELL:
			continue
		if _charge_ratio(a) < BOND_MIN_CHARGE_RATIO:
			continue
		var ports_a: Array[Dictionary] = a.get_world_ports()
		for j in range(i + 1, n):
			var b: CellBody = cells[j]
			if _bond_count_for(b) >= MAX_BONDS_PER_CELL:
				continue
			if ENABLE_BONDS and _bonded_pairs.has(_pair_key(a, b)):
				continue
			var center_dist: float = a.position.distance_to(b.position)
			if center_dist > BOND_CENTER_RANGE + a.radius + b.radius:
				continue
			if _charge_ratio(b) < BOND_MIN_CHARGE_RATIO:
				continue
			if field.sample_noise((a.position + b.position) * 0.5) > BOND_NOISE_LIMIT:
				continue
			_classify_and_form(a, b, ports_a, b.get_world_ports())
			if bonds.size() >= MAX_TOTAL_BONDS:
				return


# Returns clash_noise/empty for non-bonding combos, otherwise a contact dict.
func _zone_priority(z: String) -> int:
	match z:
		"tip_sharp": return 3
		"tip_hook": return 2
		"inner_curve": return 1
	return 0


# Classify a contact between two zones. Returns a contact dict with type=clash_noise
# for any combination that should not become a persistent bond.
func _classify_contact(geom_a: String, geom_b: String, zone_a: String, zone_b: String, face_dot: float) -> Dictionary:
	var ga: String = geom_a; var gb: String = geom_b
	var za: String = zone_a; var zb: String = zone_b
	if _zone_priority(zb) > _zone_priority(za):
		var ts: String = ga; ga = gb; gb = ts
		ts = za; za = zb; zb = ts

	# --- Triangle <-> Triangle: ONLY flat-flat plate, with strict alignment.
	if ga == "triangle" and gb == "triangle":
		if za != "flat" or zb != "flat":
			return {"type": "clash_noise", "strength": 0.0, "rest": 0.0, "overlap": 0.0}
		if face_dot > FLAT_PLATE_FACE_MAX:
			return {"type": "clash_noise", "strength": 0.0, "rest": 0.0, "overlap": 0.0}
		return {"type": "triangle_flat_plate", "strength": 0.95, "rest": 1.0, "overlap": 1.0}

	# --- Triangle <-> Crescent: invalid for now (no triangle traps).
	if (ga == "triangle" and gb == "crescent") or (ga == "crescent" and gb == "triangle"):
		return {"type": "clash_noise", "strength": 0.0, "rest": 0.0, "overlap": 0.0}

	# --- Triangle tip puncture: only into round/line.
	if za == "tip_sharp":
		match zb:
			"surface":
				return {"type": "triangle_tip_puncture", "strength": 0.80, "rest": 4.0, "overlap": 4.0}
			"side":
				return {"type": "triangle_tip_puncture", "strength": 0.70, "rest": 3.0, "overlap": 3.0}
			"end":
				return {"type": "triangle_tip_puncture", "strength": 0.60, "rest": 3.0, "overlap": 3.0}
			_:
				return {"type": "clash_noise", "strength": 0.0, "rest": 0.0, "overlap": 0.0}

	# --- Crescent tip_hook: only LINE ends/sides are valid hook targets.
	if za == "tip_hook":
		match zb:
			"end":
				return {"type": "crescent_hook", "strength": 0.75, "rest": 2.0, "overlap": 2.0}
			"side":
				return {"type": "crescent_hook", "strength": 0.60, "rest": 3.0, "overlap": 1.0}
			_:
				return {"type": "clash_noise", "strength": 0.0, "rest": 0.0, "overlap": 0.0}

	# --- Crescent inner_curve: cradle ROUND surface, weakly accept LINE side.
	if za == "inner_curve":
		match zb:
			"surface":
				return {"type": "crescent_cradle", "strength": 0.85, "rest": 0.0, "overlap": 4.0}
			"side":
				return {"type": "crescent_cradle", "strength": 0.65, "rest": 1.0, "overlap": 2.0}
			_:
				return {"type": "clash_noise", "strength": 0.0, "rest": 0.0, "overlap": 0.0}

	# --- Crescent outer curve against anything = weak sliding.
	if za == "outer_curve" or zb == "outer_curve":
		return {"type": "weak_sliding_contact", "strength": 0.25, "rest": 6.0, "overlap": 0.0}

	# --- Round soft overlap.
	if za == "surface" and zb == "surface":
		return {"type": "round_soft_overlap", "strength": 0.55, "rest": 2.0, "overlap": 0.0}

	# LEGACY_LINE_CELL_PATH: preserved until plasma bridge replacement exists.
	# --- Round bead on line side (conducts as line_chain).
	if (za == "surface" and zb == "side") or (za == "side" and zb == "surface"):
		return {"type": "line_chain", "strength": 0.55, "rest": 2.0, "overlap": 2.0}

	# LEGACY_LINE_CELL_PATH: preserved until plasma bridge replacement exists.
	# --- Line ends chain.
	if za == "end" and zb == "end":
		return {"type": "line_chain", "strength": 0.85, "rest": 1.0, "overlap": 1.0}

	# LEGACY_LINE_CELL_PATH: preserved until plasma bridge replacement exists.
	# --- Line side-to-side parallel rail.
	if za == "side" and zb == "side":
		return {"type": "line_parallel", "strength": 0.75, "rest": 4.0, "overlap": 0.0}

	# Anything else = clash.
	return {"type": "clash_noise", "strength": 0.0, "rest": 0.0, "overlap": 0.0}


func _classify_and_form(a: CellBody, b: CellBody, ports_a: Array[Dictionary], ports_b: Array[Dictionary]) -> void:
	var best: Dictionary = {}
	var best_pa: int = -1
	var best_pb: int = -1
	var best_strength: float = 0.0
	var clash_seen: bool = false
	for pa_idx in ports_a.size():
		if _bonded_anchors.has(_anchor_key(a, pa_idx)):
			continue
		var port_a: Dictionary = ports_a[pa_idx]
		for pb_idx in ports_b.size():
			if _bonded_anchors.has(_anchor_key(b, pb_idx)):
				continue
			var port_b: Dictionary = ports_b[pb_idx]
			var pd: float = (port_a.position as Vector2).distance_to(port_b.position as Vector2)
			if pd > ANCHOR_PROXIMITY:
				continue
			var face: float = (port_a.direction as Vector2).dot(port_b.direction as Vector2)
			var result: Dictionary = _classify_contact(
				a.signature.geometry_type,
				b.signature.geometry_type,
				port_a.zone as String,
				port_b.zone as String,
				face,
			)
			if result.is_empty():
				continue
			if (result.type as String) == "clash_noise" or (result.type as String) == "weak_sliding_contact":
				clash_seen = true
				continue
			if not _capture_face_ok(result.type as String, face):
				clash_seen = true
				continue
			# Score: classifier strength, weighted slightly by anchor proximity.
			var score: float = (result.strength as float) * (1.0 - clampf(pd / ANCHOR_PROXIMITY, 0.0, 1.0) * 0.25)
			if (result.type as String) == "round_soft_overlap":
				if _round_pair_invalid_score(a, b, a.position.distance_to(b.position)) >= score:
					clash_seen = true
					continue
			if score > best_strength:
				best_strength = score
				best_pa = pa_idx
				best_pb = pb_idx
				best = result
	if best_pa >= 0:
		_form_bond(a, b, best_pa, best_pb, best)
	elif clash_seen:
		_emit_clash(a, b)


func _emit_clash(a: CellBody, b: CellBody) -> void:
	var pk: int = _pair_key(a, b)
	if _clash_cooldowns.has(pk):
		return
	_clash_cooldowns[pk] = CLASH_COOLDOWN
	var mid: Vector2 = (a.position + b.position) * 0.5
	field.add_noise(mid, CLASH_NOISE)
	a.signature.noise = clampf(a.signature.noise + 0.15, 0.0, CellBody.NOISE_MAX)
	b.signature.noise = clampf(b.signature.noise + 0.15, 0.0, CellBody.NOISE_MAX)
	a.trigger_clash_flash()
	b.trigger_clash_flash()
	_push_fx(mid, "clash", FX_CLASH_TTL, 1.0)


func _form_bond(a: CellBody, b: CellBody, pa: int, pb: int, info: Dictionary) -> void:
	if not ENABLE_BONDS:
		return
	var bond: Bond = Bond.new(
		a, b, pa, pb,
		info.type as String,
		info.strength as float,
		info.rest as float,
		info.overlap as float,
	)
	bond.capture_timer = CAPTURE_DURATION
	bond.hold_timer = CAPTURE_MIN_HOLD
	a.signature.charge = maxf(0.0, a.signature.charge - a.signature.charge_capacity * BOND_FORM_COST_RATIO)
	b.signature.charge = maxf(0.0, b.signature.charge - b.signature.charge_capacity * BOND_FORM_COST_RATIO)
	bonds.append(bond)
	_bonded_pairs[_pair_key(a, b)] = bond
	_bonded_anchors[_anchor_key(a, pa)] = bond
	_bonded_anchors[_anchor_key(b, pb)] = bond
	_inc_bond_count(a)
	_inc_bond_count(b)
	a.note_capture(1.0)
	b.note_capture(1.0)
	a.trigger_snap_flash()
	b.trigger_snap_flash()
	_push_fx(bond.midpoint(), "capture", FX_CAPTURE_TTL, bond.strength)


func _inc_bond_count(c: CellBody) -> void:
	var k: int = c.get_instance_id()
	_cell_bond_count[k] = int(_cell_bond_count.get(k, 0)) + 1


func _dec_bond_count(c: CellBody) -> void:
	var k: int = c.get_instance_id()
	_cell_bond_count[k] = maxi(0, int(_cell_bond_count.get(k, 0)) - 1)


# --- bond physics & charge flow tables ---

func _spring_for(t: String) -> float:
	match t:
		"triangle_flat_plate": return BOND_SPRING_BASE * 1.4
		"triangle_tip_puncture": return BOND_SPRING_BASE * 1.1
		"line_chain": return BOND_SPRING_BASE * 1.2
		"line_parallel": return BOND_SPRING_BASE * 0.9
		"crescent_cradle": return BOND_SPRING_BASE * 0.7
		"crescent_hook": return BOND_SPRING_BASE * 0.85
		"round_soft_overlap": return BOND_SPRING_BASE * 0.5
		"weak_sliding_contact": return BOND_SPRING_BASE * 0.30
	return BOND_SPRING_BASE


func _damp_for(t: String) -> float:
	match t:
		"triangle_flat_plate": return BOND_DAMP_BASE * 1.8
		"triangle_tip_puncture": return BOND_DAMP_BASE * 1.4
		"crescent_cradle": return BOND_DAMP_BASE * 1.5
		"crescent_hook": return BOND_DAMP_BASE * 1.1
		"line_chain", "line_parallel": return BOND_DAMP_BASE * 1.3
		"weak_sliding_contact": return BOND_DAMP_BASE * 0.4
		"round_soft_overlap": return BOND_DAMP_BASE * 0.9
	return BOND_DAMP_BASE


func _torque_for(t: String) -> float:
	match t:
		"triangle_flat_plate": return ANCHOR_TORQUE_GAIN * 1.8
		"triangle_tip_puncture": return ANCHOR_TORQUE_GAIN * 1.1
		"line_chain": return ANCHOR_TORQUE_GAIN * 1.2
		"line_parallel": return ANCHOR_TORQUE_GAIN * 1.0
		"crescent_cradle": return ANCHOR_TORQUE_GAIN * 0.9
		"crescent_hook": return ANCHOR_TORQUE_GAIN * 0.7
		"round_soft_overlap": return 0.0
		"weak_sliding_contact": return 0.0
	return 0.0


func _baseline_strain_for(t: String) -> float:
	match t:
		"triangle_tip_puncture": return 0.10
		"weak_sliding_contact": return 0.20
		"crescent_hook": return 0.05
	return 0.0


func _flow_for(t: String) -> float:
	match t:
		"line_chain", "line_parallel": return FLOW_LINE
		"round_soft_overlap": return FLOW_ROUND
		"crescent_cradle": return FLOW_CRADLE
		"crescent_hook": return FLOW_HOOK
		"triangle_flat_plate": return FLOW_PLATE
		"weak_sliding_contact": return FLOW_WEAK
	return 0.0


# --- bond update ---

func _update_bonds(delta: float) -> void:
	if not ENABLE_BONDS:
		return
	if bonds.is_empty():
		_apply_bonded_angular_damp(delta)
		return
	var to_break: Array[Bond] = []
	for bond in bonds:
		bond.age += delta
		var capturing: bool = bond.capture_timer > 0.0
		if capturing:
			bond.capture_timer = maxf(0.0, bond.capture_timer - delta)
		if bond.hold_timer > 0.0:
			bond.hold_timer = maxf(0.0, bond.hold_timer - delta)
		var k_mult: float = CAPTURE_SPRING_MULT if capturing else 1.0
		var d_mult: float = CAPTURE_DAMP_MULT if capturing else 1.0
		var tq_mult: float = CAPTURE_TORQUE_MULT if capturing else 1.0

		var pa: Vector2 = bond.endpoint_a()
		var pb: Vector2 = bond.endpoint_b()
		var diff: Vector2 = pb - pa
		var dist: float = diff.length()
		if dist < 0.001:
			continue
		var dir: Vector2 = diff / dist
		var stretch: float = dist - bond.rest_distance

		# Spring + damp
		var k: float = _spring_for(bond.bond_type) * bond.strength * k_mult
		var force_mag: float = k * stretch
		var force_a: Vector2 = dir * force_mag
		bond.a.apply_velocity_delta(force_a * delta)
		bond.b.apply_velocity_delta(-force_a * delta)

		# Torque from spring force applied at offset anchor (so anchors align, not just centers)
		var tq_gain: float = _torque_for(bond.bond_type) * tq_mult
		if tq_gain > 0.0:
			var ra: Vector2 = pa - bond.a.position
			var rb: Vector2 = pb - bond.b.position
			var torque_a: float = ra.x * force_a.y - ra.y * force_a.x
			var torque_b: float = rb.x * (-force_a.y) - rb.y * (-force_a.x)
			var dw_a: float = torque_a * tq_gain * delta
			var dw_b: float = torque_b * tq_gain * delta
			# Cap per-substep angular kick so a freshly formed bond does not spin
			# its members violently while seating.
			var max_dw: float = MAX_CAPTURE_ANGULAR_CORRECTION if capturing else MAX_BASE_ANGULAR_CORRECTION
			dw_a = clampf(dw_a, -max_dw, max_dw)
			dw_b = clampf(dw_b, -max_dw, max_dw)
			bond.a.apply_angular_delta(dw_a)
			bond.b.apply_angular_delta(dw_b)

		var rel_v: Vector2 = bond.b.velocity - bond.a.velocity
		var rel_along: float = rel_v.dot(dir)
		var dmp: float = _damp_for(bond.bond_type) * d_mult
		var damp_imp: Vector2 = dir * rel_along * dmp * delta
		bond.a.apply_velocity_delta(damp_imp * 0.5)
		bond.b.apply_velocity_delta(-damp_imp * 0.5)

		# Relative-motion damping. Strong during capture/hold; gentler but always-on
		# afterwards to keep settled bonds from buzzing. Mean-lerp converges both
		# endpoints toward a shared velocity / angular velocity rather than letting
		# them fight along the bond axis.
		var v_share: float
		var w_share: float
		if capturing or bond.hold_timer > 0.0:
			var bleed: float = exp(-CAPTURE_ANGULAR_BLEED * delta)
			bond.a.angular_velocity *= bleed
			bond.b.angular_velocity *= bleed
			v_share = clampf(CAPTURE_REL_VEL_DAMP * delta, 0.0, 0.9)
			w_share = clampf(CAPTURE_REL_ANG_DAMP * delta, 0.0, 0.9)
		else:
			v_share = clampf(BOND_RELATIVE_VELOCITY_DAMPING * delta, 0.0, 0.6)
			w_share = clampf(BOND_RELATIVE_ANGULAR_DAMPING * delta, 0.0, 0.6)
		if v_share > 0.0 or w_share > 0.0:
			var mean_v: Vector2 = (bond.a.velocity + bond.b.velocity) * 0.5
			var mean_w: float = (bond.a.angular_velocity + bond.b.angular_velocity) * 0.5
			bond.a.velocity = bond.a.velocity.lerp(mean_v, v_share)
			bond.b.velocity = bond.b.velocity.lerp(mean_v, v_share)
			bond.a.angular_velocity = lerpf(bond.a.angular_velocity, mean_w, w_share)
			bond.b.angular_velocity = lerpf(bond.b.angular_velocity, mean_w, w_share)

		# Charge flow
		_apply_charge_flow(bond, delta)

		# Strain accumulation (suppressed during capture so newly seated bonds don't immediately tear)
		if not capturing:
			var stretch_strain: float = maxf(0.0, absf(stretch) - BOND_STRETCH_TOL) * BOND_STRETCH_GAIN
			var noise_here: float = field.sample_noise(bond.midpoint())
			var noise_strain: float = maxf(0.0, noise_here - BOND_NOISE_FLOOR) * BOND_NOISE_GAIN
			var base_strain: float = _baseline_strain_for(bond.bond_type)
			var dash_strain: float = 0.0
			if bond.bond_type == "weak_sliding_contact" or bond.bond_type == "triangle_tip_puncture" or bond.bond_type == "crescent_hook":
				var dp: float = maxf(bond.a.dash_pulse, bond.b.dash_pulse)
				dash_strain = dp * DASH_STRAIN_GAIN

			var twist_strain: float = 0.0
			if bond.bond_type == "triangle_flat_plate":
				var na: Vector2 = bond.a.ports[bond.anchor_a].local_normal.rotated(bond.a.rotation)
				var nb: Vector2 = bond.b.ports[bond.anchor_b].local_normal.rotated(bond.b.rotation)
				var alignment: float = na.dot(nb)  # ideal seam: -1
				twist_strain = maxf(0.0, alignment - FLAT_PLATE_FACE_MAX) * FLAT_PLATE_TWIST_GAIN

			var total_rate: float = stretch_strain + noise_strain + base_strain + dash_strain + twist_strain
			# Dead zone: ignore micro-jitter strain so a settled bond doesn't slowly accrue from numerical noise.
			if total_rate > BOND_STRAIN_DEADZONE:
				bond.strain += total_rate * delta
		bond.strain = maxf(0.0, bond.strain - BOND_STRAIN_RECOVERY * delta)
		# Sustained-strain check: bond must be over BREAK threshold for STRAIN_BREAK_DURATION
		if bond.hold_timer <= 0.0 and bond.strain >= BOND_STRAIN_BREAK:
			bond.over_strain_time += delta
			if bond.over_strain_time >= STRAIN_BREAK_DURATION:
				to_break.append(bond)
		else:
			bond.over_strain_time = maxf(0.0, bond.over_strain_time - delta * 2.0)

	_apply_bonded_angular_damp(delta)

	for bond in to_break:
		_break_bond(bond)


func _apply_bonded_angular_damp(delta: float) -> void:
	# Reduce angular jitter on bonded cells. Damping scales with bond count so
	# heavily-bonded cells settle, but free cells remain free.
	for c in cells:
		var n: int = _bond_count_for(c)
		if n <= 0:
			continue
		c.angular_velocity *= exp(-BONDED_ANGULAR_DAMP * float(n) * delta)


func _apply_charge_flow(bond: Bond, delta: float) -> void:
	var rate: float = _flow_for(bond.bond_type)
	# Puncture-during-dash: drain charge from punctured cell into dashing triangle.
	if bond.bond_type == "triangle_tip_puncture":
		var triangle_is_a: bool = bond.a.signature.geometry_type == "triangle"
		var tri: CellBody = bond.a if triangle_is_a else bond.b
		var victim: CellBody = bond.b if triangle_is_a else bond.a
		if tri.dash_pulse > 0.0 and victim.signature.charge > 0.0:
			var amount: float = FLOW_PUNCTURE_DRAIN * tri.dash_pulse * delta
			amount = minf(amount, victim.signature.charge)
			amount = minf(amount, tri.signature.charge_capacity - tri.signature.charge)
			victim.signature.charge -= amount
			tri.signature.charge += amount
		return
	if rate <= 0.0:
		return
	var ra: float = _charge_ratio(bond.a)
	var rb: float = _charge_ratio(bond.b)
	var diff_ratio: float = ra - rb
	if absf(diff_ratio) < 0.001:
		return
	# Transfer proportional to ratio diff and source capacity.
	var source: CellBody = bond.a if diff_ratio > 0.0 else bond.b
	var dest: CellBody = bond.b if diff_ratio > 0.0 else bond.a
	var amt: float = absf(diff_ratio) * rate * delta * source.signature.charge_capacity
	amt = minf(amt, source.signature.charge)
	amt = minf(amt, dest.signature.charge_capacity - dest.signature.charge)
	if amt <= 0.0:
		return
	source.signature.charge -= amt
	dest.signature.charge += amt


func _break_bond(bond: Bond) -> void:
	_erase_bond(bond, true)


func _erase_bond(bond: Bond, emit_break_fx: bool) -> void:
	if not bonds.has(bond):
		return
	if emit_break_fx:
		field.add_noise(bond.midpoint(), BOND_BREAK_FIELD_NOISE * bond.strength)
		bond.a.signature.noise = clampf(bond.a.signature.noise + BOND_BREAK_SELF_NOISE * bond.strength, 0.0, CellBody.NOISE_MAX)
		bond.b.signature.noise = clampf(bond.b.signature.noise + BOND_BREAK_SELF_NOISE * bond.strength, 0.0, CellBody.NOISE_MAX)
		bond.a.trigger_clash_flash(0.8)
		bond.b.trigger_clash_flash(0.8)
		_push_fx(bond.midpoint(), "break", FX_BREAK_TTL, bond.strength)
	bond.broken = true
	bonds.erase(bond)
	_bonded_pairs.erase(_pair_key(bond.a, bond.b))
	_bonded_anchors.erase(_anchor_key(bond.a, bond.anchor_a))
	_bonded_anchors.erase(_anchor_key(bond.b, bond.anchor_b))
	_dec_bond_count(bond.a)
	_dec_bond_count(bond.b)


# --- seedling classification ---
# Experimental only. This classifier still depends on legacy Line assumptions
# and should not be treated as ontology truth until bonding stabilizes.

func _classify_seedlings() -> void:
	_seedlings.clear()
	_cluster_count = 0
	_largest_cluster = 0
	_best_coherence = 0.0
	if not _seedling_classification_enabled():
		return
	for cluster in _clusters_snapshot:
		var members: Array = cluster as Array
		var cc: int = members.size()
		if cc < SEEDLING_MIN_CELLS:
			continue
		_cluster_count += 1
		_largest_cluster = maxi(_largest_cluster, cc)
		var member_ids: Dictionary = {}
		for c in members:
			var cb: CellBody = c
			member_ids[cb.get_instance_id()] = true
		var member_bonds: Array[Bond] = []
		var bond_hist: Dictionary = {}
		for bond in bonds:
			if not member_ids.has(bond.a.get_instance_id()) or not member_ids.has(bond.b.get_instance_id()):
				continue
			member_bonds.append(bond)
			bond_hist[bond.bond_type] = int(bond_hist.get(bond.bond_type, 0)) + 1
		var summary: Dictionary = _summarize_seedling(members, member_bonds, bond_hist)
		var coherence: float = float(summary["coherence"])
		_best_coherence = maxf(_best_coherence, coherence)
		if coherence < SEEDLING_COHERENCE_MIN:
			continue
		var seedling_type: String = _resolve_seedling_type(summary)
		if seedling_type == "":
			continue
		summary["seedling_type"] = seedling_type
		summary["members"] = members.duplicate()
		_seedlings.append(summary)


func _summarize_seedling(members: Array, member_bonds: Array[Bond], bond_hist: Dictionary) -> Dictionary:
	var cc: int = members.size()
	var bc: int = member_bonds.size()
	var counts: Dictionary = {
		"round": 0,
		"triangle": 0,
		"line": 0,
		"crescent": 0,
		"spiral": 0,
	}
	var total_charge: float = 0.0
	var total_capacity: float = 0.0
	var total_noise: float = 0.0
	var total_storage_bias: float = 0.0
	var center: Vector2 = _cluster_centroid(members)
	var sxx: float = 0.0
	var syy: float = 0.0
	var sxy: float = 0.0
	for c in members:
		var cb: CellBody = c
		var geom: String = _canonical_geom(cb.signature.geometry_type)
		counts[geom] = int(counts.get(geom, 0)) + 1
		total_charge += cb.signature.charge
		total_capacity += cb.signature.charge_capacity
		total_noise += cb.signature.noise
		total_storage_bias += cb.signature.storage_bias
		var dx: float = cb.position.x - center.x
		var dy: float = cb.position.y - center.y
		sxx += dx * dx
		syy += dy * dy
		sxy += dx * dy
	sxx /= float(cc)
	syy /= float(cc)
	sxy /= float(cc)
	var trace: float = sxx + syy
	var det: float = sxx * syy - sxy * sxy
	var disc: float = maxf(0.0, trace * trace * 0.25 - det)
	var root_disc: float = sqrt(disc)
	var lam_max: float = trace * 0.5 + root_disc
	var lam_min: float = trace * 0.5 - root_disc
	var isotropy: float = 0.0
	if lam_max > 0.0001:
		isotropy = clampf(lam_min / lam_max, 0.0, 1.0)
	var asymmetry: float = 1.0 - isotropy
	var avg_noise: float = total_noise / float(cc)
	var avg_strain: float = 0.0
	for bond in member_bonds:
		avg_strain += bond.strain
	if bc > 0:
		avg_strain /= float(bc)
	var density: float = float(bc) / float(maxi(1, cc - 1))
	var coherence: float = clampf(
		clampf(density * 0.5, 0.0, 1.0)
		* (1.0 - clampf(avg_strain, 0.0, 1.0))
		* (1.0 - clampf(avg_noise * 0.5, 0.0, 1.0))
		* (0.5 + 0.5 * isotropy),
		0.0,
		1.0
	)
	var charge_fill: float = total_charge / maxf(total_capacity, 0.0001)
	var mean_storage_bias: float = total_storage_bias / float(cc)
	var round_ratio: float = float(int(counts["round"])) / float(cc)
	var triangle_ratio: float = float(int(counts["triangle"])) / float(cc)
	var line_ratio: float = float(int(counts["line"])) / float(cc)
	var crescent_ratio: float = float(int(counts["crescent"])) / float(cc)
	var puncture_ratio: float = float(int(bond_hist.get("triangle_tip_puncture", 0))) / float(maxi(1, bc))
	var line_bond_ratio: float = float(int(bond_hist.get("line_chain", 0)) + int(bond_hist.get("line_parallel", 0))) / float(maxi(1, bc))
	var plate_ratio: float = float(int(bond_hist.get("triangle_flat_plate", 0))) / float(maxi(1, bc))
	var bend_ratio: float = float(int(bond_hist.get("crescent_cradle", 0)) + int(bond_hist.get("crescent_hook", 0))) / float(maxi(1, bc))
	var conductivity: float = clampf(line_ratio * 0.55 + line_bond_ratio * 0.45, 0.0, 1.0)
	var storage_potential: float = clampf(round_ratio * 0.55 + mean_storage_bias * 0.30 + charge_fill * 0.15, 0.0, 1.0)
	var burst_potential: float = clampf(
		(triangle_ratio * 0.35 + puncture_ratio * 0.35 + charge_fill * 0.20 + asymmetry * 0.10)
		* (0.4 + 0.6 * clampf(round_ratio + conductivity, 0.0, 1.0)),
		0.0,
		1.0
	)
	var bend_potential: float = clampf(crescent_ratio * 0.50 + bend_ratio * 0.35 + asymmetry * 0.15, 0.0, 1.0)
	var shell_potential: float = clampf(triangle_ratio * 0.45 + plate_ratio * 0.40 + (1.0 - clampf(avg_strain, 0.0, 1.0)) * 0.15, 0.0, 1.0)
	return {
		"seedling_type": "",
		"cell_total": cc,
		"cell_counts": counts,
		"dominant_bond_types": _top_hist_keys(bond_hist, 3),
		"total_charge": total_charge,
		"average_noise": avg_noise,
		"average_strain": avg_strain,
		"coherence": coherence,
		"asymmetry": asymmetry,
		"conductivity": conductivity,
		"puncture_ratio": puncture_ratio,
		"plate_ratio": plate_ratio,
		"burst_potential": burst_potential,
		"bend_potential": bend_potential,
		"storage_potential": storage_potential,
		"shell_potential": shell_potential,
	}


func _resolve_seedling_type(summary: Dictionary) -> String:
	var counts: Dictionary = summary["cell_counts"] as Dictionary
	var cc: int = int(summary["cell_total"])
	var round_ratio: float = float(int(counts.get("round", 0))) / float(cc)
	var triangle_ratio: float = float(int(counts.get("triangle", 0))) / float(cc)
	var line_ratio: float = float(int(counts.get("line", 0))) / float(cc)
	var crescent_ratio: float = float(int(counts.get("crescent", 0))) / float(cc)
	var avg_noise: float = float(summary["average_noise"])
	var avg_strain: float = float(summary["average_strain"])
	var asymmetry: float = float(summary["asymmetry"])
	var conductivity: float = float(summary["conductivity"])
	var puncture_ratio: float = float(summary["puncture_ratio"])
	var plate_ratio: float = float(summary["plate_ratio"])
	var burst_potential: float = float(summary["burst_potential"])
	var bend_potential: float = float(summary["bend_potential"])
	var storage_potential: float = float(summary["storage_potential"])
	var shell_potential: float = float(summary["shell_potential"])
	if round_ratio >= CORE_ROUND_RATIO_MIN and storage_potential >= CORE_STORAGE_MIN and avg_noise <= CORE_NOISE_MAX and avg_strain <= 0.35:
		return "CORE_SEED"
	if round_ratio > 0.0 and triangle_ratio > 0.0 and puncture_ratio >= MOTOR_PUNCTURE_RATIO_MIN and burst_potential >= MOTOR_BURST_MIN and asymmetry >= MOTOR_ASYM_MIN:
		return "MOTOR_SEED"
	if line_ratio >= CONDUIT_LINE_RATIO_MIN and conductivity >= CONDUIT_CONDUCT_MIN:
		return "CONDUIT_SEED"
	if triangle_ratio >= SHELL_TRIANGLE_RATIO_MIN and plate_ratio >= SHELL_PLATE_RATIO_MIN and shell_potential >= 0.50:
		return "SHELL_SEED"
	if crescent_ratio >= BEND_CRESCENT_RATIO_MIN and bend_potential >= BEND_POTENTIAL_MIN and (int(counts.get("round", 0)) + int(counts.get("line", 0))) > 0:
		return "BEND_SEED"
	if float(summary["coherence"]) >= HYBRID_SEED_MIN:
		return "HYBRID_SEED"
	return ""


func _canonical_geom(geom: String) -> String:
	# Internal naming debt: round=Sphere, triangle/wedge=Triangle,
	# spiral=Coil, line=legacy Line, crescent=Crescent.
	if geom == "wedge":
		return "triangle"
	return geom


func _debug_cell_label(cell: CellBody) -> String:
	if cell == null or cell.signature == null:
		return "-"
	match _canonical_geom(cell.signature.geometry_type):
		"round":
			return "Sphere"
		"triangle":
			return "Triangle"
		"crescent":
			return "Crescent"
		"spiral":
			return "Coil"
		"line":
			return "Line"
	return _canonical_geom(cell.signature.geometry_type)


func _top_hist_keys(hist: Dictionary, limit: int) -> Array[String]:
	var pending: Dictionary = hist.duplicate()
	var out: Array[String] = []
	while out.size() < limit and not pending.is_empty():
		var best_key: String = ""
		var best_val: int = -1
		for key in pending.keys():
			var key_str: String = key as String
			var val: int = int(pending[key])
			if val > best_val:
				best_key = key_str
				best_val = val
		if best_val <= 0:
			break
		out.append(best_key)
		pending.erase(best_key)
	return out


func _cluster_centroid(members: Array) -> Vector2:
	var center: Vector2 = Vector2.ZERO
	if members.is_empty():
		return center
	for c in members:
		center += (c as CellBody).position
	return center / float(members.size())


func _cluster_halo_radius(members: Array, center: Vector2) -> float:
	var radius: float = 0.0
	for c in members:
		var cb: CellBody = c
		radius = maxf(radius, center.distance_to(cb.position) + cb.radius)
	return radius


func _seedling_color(seedling_type: String) -> Color:
	match seedling_type:
		"CORE_SEED":
			return Color(0.48, 0.88, 0.86, 1.0)
		"MOTOR_SEED":
			return Color(1.00, 0.62, 0.30, 1.0)
		"CONDUIT_SEED":
			return Color(0.42, 0.72, 1.00, 1.0)
		"SHELL_SEED":
			return Color(0.86, 0.92, 1.00, 1.0)
		"BEND_SEED":
			return Color(0.95, 0.56, 0.78, 1.0)
		"HYBRID_SEED":
			return Color(0.74, 0.84, 0.58, 1.0)
	return Color(0.80, 0.85, 0.95, 1.0)


func _seedling_debug_summary(limit: int) -> String:
	if _seedlings.is_empty() or limit <= 0:
		return ""
	var out: String = ""
	var shown: int = mini(limit, _seedlings.size())
	for i in shown:
		var seedling: Dictionary = _seedlings[i]
		if i > 0:
			out += " | "
		out += "%s q%.2f c%.2f" % [
			seedling["seedling_type"],
			seedling["total_charge"],
			seedling["coherence"],
		]
	return out


func _find(parent: Array[int], i: int) -> int:
	while parent[i] != i:
		parent[i] = parent[parent[i]]
		i = parent[i]
	return i


func _union(parent: Array[int], a: int, b: int) -> void:
	var ra: int = _find(parent, a)
	var rb: int = _find(parent, b)
	if ra != rb:
		parent[ra] = rb


# --- HUD ---

func _seedling_classification_enabled() -> bool:
	return ENABLE_BONDS and ENABLE_SEEDLING_CLASSIFICATION


func _seedling_debug_enabled() -> bool:
	return _seedling_classification_enabled() and debug_seedlings


func _magnetic_debug_hud_lines() -> String:
	if not debug_magnetic_field:
		return ""
	var hud: String = ""
	hud += "\ncell-field sources: %d  nearest sphere q: %.3f" % [
		_mag_debug_sphere_sources,
		_mag_debug_nearest_sphere_charge,
	]
	hud += "\ncell-field@mouse: %.4f @ (%.1f, %.1f)  contributors: %d" % [
		_mag_debug_mouse_strength,
		_mag_debug_mouse_pos.x,
		_mag_debug_mouse_pos.y,
		_mag_debug_mouse_contributors,
	]
	hud += "\nmouse cell-field vec: (%.3f, %.3f)  nearest contrib: %.4f" % [
		_mag_debug_mouse_vector.x,
		_mag_debug_mouse_vector.y,
		_mag_debug_nearest_source_strength,
	]
	hud += "\nnearest cell-field contrib vec: (%.3f, %.3f)" % [
		_mag_debug_nearest_source_vector.x,
		_mag_debug_nearest_source_vector.y,
	]
	hud += "\ncell-field@probe: %.4f @ (%.1f, %.1f)" % [
		_mag_debug_probe_strength,
		_mag_debug_probe_pos.x,
		_mag_debug_probe_pos.y,
	]
	hud += "\nseeds: %d  lines: %d  points: %d  contours: %d  primitives: %d" % [
		_mag_debug_seed_count,
		_mag_debug_line_count,
		_mag_debug_point_count,
		_mag_debug_contour_count,
		_mag_debug_primitive_count,
	]
	return hud


func _cell_field_debug_hud_lines() -> String:
	return _magnetic_debug_hud_lines()


func _ambient_debug_hud_lines() -> String:
	_update_ambient_debug_probe()
	var hud: String = ""
	hud += "\nAMBIENT FIELD: %s  AMBIENT REVEAL: %s (%s)" % [
		"ON" if AMBIENT_FIELD_ENABLED else "OFF",
		"ON" if ambient_field_reveal_active() else "OFF",
		AMBIENT_FIELD_REVEAL_KEY,
	]
	hud += "\nCELL-FIELD: %s  PLASMA SHEATH: %s  PLASMA BRIDGE: %s" % [
		"ON" if cell_field_enabled() else "OFF",
		"ON" if plasma_sheath_enabled() else "OFF",
		"ON" if plasma_bridge_enabled() else "OFF",
	]
	hud += "\nambient reveal primitives: %d  plasma bridges: %d  legacy sheaths: %d" % [
		_macro_field_primitive_count,
		_plasma_connection_debug_count,
		_cluster_sheath_debug_count,
	]
	hud += "\nambient source: dish medium"
	hud += "\nambient@mouse: %.4f  vec: (%.3f, %.3f)" % [
		_ambient_debug_mouse_strength,
		_ambient_debug_mouse_vector.x,
		_ambient_debug_mouse_vector.y,
	]
	hud += "\nambient calm: %.3f  ambient curl: %.4f" % [
		_ambient_debug_mouse_calm,
		_ambient_debug_mouse_curl,
	]
	hud += "\nambient cell: %s  cell-field: %.4f  mode: %s" % [
		_ambient_debug_cell_label,
		_ambient_debug_cell_strength,
		_ambient_debug_cell_mode,
	]
	hud += "\nambient cell vec: (%.3f, %.3f)" % [
		_ambient_debug_cell_vector.x,
		_ambient_debug_cell_vector.y,
	]
	hud += "\nTOTAL FIELD: %s  weights a/m: %.2f / %.2f" % [
		"ON" if TOTAL_FIELD_ENABLED else "OFF",
		TOTAL_FIELD_AMBIENT_WEIGHT,
		TOTAL_FIELD_MAGNETIC_WEIGHT,
	]
	hud += "\ntotal@mouse: %.4f  vec: (%.3f, %.3f)" % [
		_total_debug_mouse_strength,
		_total_debug_mouse_vector.x,
		_total_debug_mouse_vector.y,
	]
	hud += "\ntotal grad@mouse: (%.4f, %.4f)" % [
		_total_debug_mouse_gradient.x,
		_total_debug_mouse_gradient.y,
	]
	hud += "\nperf ms frame/ambient/cluster: %.2f / %.2f / %.2f" % [
		_perf_frame_ms,
		_perf_cell_ambient_ms,
		_perf_cluster_ms,
	]
	hud += "\nperf ms bond scan/update/sheath: %.2f / %.2f / %.2f" % [
		_perf_bond_scan_ms,
		_perf_bond_update_ms,
		_perf_local_plasma_ms,
	]
	hud += "\ndraw ms ambient reveal/cell-field: %.2f / %.2f  ambient samples f/c/curl: %d / %d / %d" % [
		_perf_macro_draw_ms,
		_perf_magnetic_draw_ms,
		_perf_ambient_field_samples,
		_perf_ambient_calm_samples,
		_perf_ambient_curl_samples,
	]
	return hud


func _camera_debug_hud_lines() -> String:
	var mouse_world: Vector2 = _screen_to_dish_position(get_viewport().get_mouse_position())
	return "\ncamera zoom: %.3f  camera pos: (%.1f, %.1f)\nmouse world: (%.1f, %.1f)" % [
		camera.zoom.x,
		camera.position.x,
		camera.position.y,
		mouse_world.x,
		mouse_world.y,
	]

func _update_debug() -> void:
	var count: int = cells.size()
	var avg_charge: float = 0.0
	var avg_noise: float = 0.0
	if count > 0:
		var sum_c: float = 0.0
		var sum_n: float = 0.0
		for c in cells:
			sum_c += c.signature.charge
			sum_n += c.signature.noise
		avg_charge = sum_c / count
		avg_noise = sum_n / count
	var state_text: String = "paused" if simulation_paused else "running"
	var hud: String = "selected: %s\ncells: %d  bonds: %d\nstate: %s  fps: %d\nBONDS: %s  LEGACY LINE: %s  SEEDLINGS: %s\nFIELD DEBUG: %s  CELL-FIELD VIS: %s  FIELD SIM: %s\nclusters: %d  largest: %d  coh: %.2f\nseedlings: %d\navg charge: %.3f  avg noise: %.3f\n[LMB] spawn  [RMB] delete  [C] clear  [Space] pause\n[H] hotbar  [Tab] debug  [B] bonds  [=] field debug  [1-4] select  [F1-F5] viz" % [
		_selected_cell_name(),
		count, bonds.size(),
		state_text, Engine.get_frames_per_second(),
		"ON" if ENABLE_BONDS else "OFF",
		"ON" if ENABLE_LEGACY_LINE_CELL else "OFF",
		"ON" if ENABLE_SEEDLING_CLASSIFICATION else "OFF",
		"ON" if debug_magnetic_field else "OFF",
		_cell_field_visual_mode_label(),
		_cell_field_sim_label(),
		_cluster_count, _largest_cluster, _best_coherence,
		_seedlings.size(),
		avg_charge, avg_noise,
	]
	hud += _cell_field_debug_hud_lines()
	if debug_seedlings:
		var summary: String = _seedling_debug_summary(2)
		if summary != "":
			hud += "\n" + summary
	hud += _ambient_debug_hud_lines()
	hud += _camera_debug_hud_lines()
	debug_label.text = hud
