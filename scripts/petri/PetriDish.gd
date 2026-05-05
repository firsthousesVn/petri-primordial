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
const MAG_FIELD_MAX_STRENGTH: float = 64.0
const MAG_FIELD_SIM_MODEL: String = "polarity_dipole"
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
# Phase-1: real ambient tuning lives in `fields/AmbientField.gd` (SCALE,
# TIME_SPEED, VORTEX_GAIN, FLOW_GAIN, PULSE_GAIN, PULSE_SPEED). These mirror
# the AmbientField module values for legacy reads only — DO NOT edit here.
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
# --- Field-overlap interaction pass (real ecology, runs once per frame) ---
# A cell's effective field reach is `radius * FIELD_OVERLAP_REACH_MULT`. Two
# cells "overlap" when the gap between their reach disks is closed; the closer
# they are, the higher the overlap factor (0..1). All overlap-driven values
# (force, bond pressure, polarity bias, compression) are derived from that
# single scalar so the system stays coherent.
const FIELD_OVERLAP_ENABLED: bool = true
const FIELD_OVERLAP_BUCKET_SIZE: float = 96.0       # spatial-hash cell size (px); tuned to typical field reach
const FIELD_OVERLAP_REACH_MULT: float = 3.4         # field radius = cell.radius * this * cell.field_reach
const FIELD_OVERLAP_MIN_RATIO: float = 0.04         # below this overlap, the pair is skipped (saves work)
const FIELD_OVERLAP_FORCE_GAIN: float = 38.0        # px/s² at overlap=1 between two unit-strength cells; raised so attraction reads from overlap onset.
const FIELD_OVERLAP_REPEL_DEPTH: float = 0.78       # overlap fraction above which compression dominates over attraction
const FIELD_OVERLAP_REPEL_GAIN: float = 38.0        # px/s² compression push at overlap=1
const FIELD_OVERLAP_BOND_PRESSURE_GAIN: float = 1.85
# Polarity torque: cells slowly rotate so their polarity axis aligns toward
# overlapping compatible neighbors. Pure overlap × compatibility weighting,
# applied via `apply_angular_delta`. Uncompatible neighbors contribute a
# weaker repulsive twist.
const FIELD_POLARITY_TORQUE_GAIN: float = 1.40        # rad/s² peak at overlap=1, compat=1
const FIELD_POLARITY_TORQUE_MAX_DW: float = 1.10      # absolute angular delta-velocity cap per second
const FIELD_POLARITY_TORQUE_REPEL_GAIN: float = 0.45  # how much incompatibility twists axis away from neighbor
const FIELD_OVERLAP_GUIDANCE_BIAS: float = 0.55     # bond_pressure multiplier added to guidance score
const FIELD_OVERLAP_BOND_SCAN_BIAS: float = 0.40    # bond_pressure multiplier added to bond-scan score
const FIELD_OVERLAP_AMBIENT_DRIFT_GAIN: float = 6.40  # dish weather: clearly carries cells over time, but still subordinate to close-pair attraction.
const FIELD_OVERLAP_AMBIENT_DRIFT_MAX_DV: float = 56.0  # raised cap matches the stronger gain
const FIELD_OVERLAP_NEIGHBOR_OFFSETS: Array = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1,  0), Vector2i(0,  0), Vector2i(1,  0),
	Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1),
]
# Plasma render constants moved into `render/PolarityArcRenderer.gd`.
# LEGACY ALIAS: "macro field" means the visible ambient-field reveal overlay,
# not a separate simulation system.
const MACRO_FIELD_ENABLED: bool = AMBIENT_FIELD_ENABLED
const MACRO_FIELD_REVEAL_ENABLED: bool = AMBIENT_FIELD_REVEAL_ENABLED
const MACRO_FIELD_REVEAL_KEY: String = AMBIENT_FIELD_REVEAL_KEY
# Phase-1: streamline-based ambient reveal deleted. Tuning lives in
# `render/AmbientFieldRenderer.gd` (GRID_SPACING, GRID_AMBIENT_DISPLACEMENT,
# GRID_WELL_DEPTH, etc).
# Per-type cell-field reach / shape multipliers, used by the dipole math.
const SPHERE_CELL_FIELD_REACH_MULTIPLIER: float = 1.28
const COIL_CELL_FIELD_TORSION_GAIN: float = 0.92
const CRESCENT_CELL_FIELD_FUNNEL_GAIN: float = 0.82
const TRIANGLE_CELL_FIELD_EDGE_GAIN: float = 0.58
const SPHERE_FIELD_ARC_MULTIPLIER: float = SPHERE_CELL_FIELD_REACH_MULTIPLIER
const COIL_FIELD_TORSION_GAIN: float = COIL_CELL_FIELD_TORSION_GAIN
const CRESCENT_FIELD_FUNNEL_GAIN: float = CRESCENT_CELL_FIELD_FUNNEL_GAIN
const TRIANGLE_FIELD_EDGE_GAIN: float = TRIANGLE_CELL_FIELD_EDGE_GAIN
# Single source of truth for "are arcs visible" is `cell_field_visible`.
# --- Polarity arc cell-field layer (legacy magnetic naming retained) ---
# The live local cell-field arcs use a polarity-style visualization model:
# every projected cell-field is treated as having two field sides / poles.
# Spheres remain the strongest projectors; other cell types inherit the same
# two-sided arc logic with weaker and more shape-biased expression.
# The simulation sampler `sample_magnetic_field` is unchanged.
# Single source of truth for visibility lives in the runtime variable
# `cell_field_visible` declared near the other runtime state below. The
# legacy `CELL_FIELD_ENABLED` and `CELL_FIELD_POLARITY_ARCS_ENABLED`
# constants were removed because they were always-true aliases that
# disguised the absence of a real toggle. Use `cell_field_enabled()` as
# the only public predicate for "are the polarity arcs visible right now".
const CELL_FIELD_BASE_STRENGTH: float = 1.0
const CELL_FIELD_BASE_REACH: float = 1.0

# --- Bonded cluster field (cluster contribution to total ψ / total field) ---
const CLUSTER_FIELD_ENABLED: bool = false  # STRIPPED: cluster wrapper-shell field summed an axis-modulated halo around bonded clusters → "wrapper shells / cluster halos" violation in FIELD_ECOLOGY_VISUAL_CONTRACT.md. Coupling now lives entirely in per-cell field overlap + bond_pressure (see FieldInteractionSystem section in IMPLEMENTATION_SPEC).
const CLUSTER_FIELD_MIN_MEMBERS: int = 2
const CLUSTER_FIELD_STRENGTH_GAIN: float = 0.55
const CLUSTER_FIELD_REACH_GAIN: float = 1.45
const CLUSTER_FIELD_KERNEL_SOFTEN: float = 24.0
const CLUSTER_FIELD_MAX_STRENGTH: float = 96.0

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
# Phase-1 extracted modules. The rest (cell/cluster renderers, interaction
# system, cluster system, debug hud) are flagged for extraction but still
# live inline in this file for now.
const AmbientFieldScript: Script = preload("res://scripts/petri/fields/AmbientField.gd")
const AmbientFieldRendererScript: Script = preload("res://scripts/petri/render/AmbientFieldRenderer.gd")
const PolarityArcRendererScript: Script = preload("res://scripts/petri/render/PolarityArcRenderer.gd")

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
# Per-frame cluster-field cache. One Dictionary per bonded component with
# size >= CLUSTER_FIELD_MIN_MEMBERS. Built immediately after
# `_clusters_snapshot` so streamlines, polarity arcs, envelopes and HUD
# probes all read the same data. Singletons live in `_clusters_snapshot`
# but never enter this cache — they have no shared field.
var _cluster_field_cache: Array = []
var _cluster_envelope_primitive_count: int = 0
var _seedlings: Array = []                  # Array of Dictionary signatures, rebuilt at SEEDLING_HZ
var debug_seedlings: bool = false
var debug_magnetic_field: bool = false  # Legacy/internal debug toggle for field diagnostics.
var macro_field_reveal: bool = true     # LEGACY NAME: visible ambient-field reveal toggle. Grid blanket is the canonical ambient visual; on by default.
# Runtime single source of truth for the visible polarity-arc cell-field
# overlay. Toggled by F6. Cell-field *simulation* (sample_cell_field,
# polarity axis, neighbor sampling) is independent of this and always
# active — this flag governs visualization only. `cell_field_enabled()`
# is the only public predicate that reads it.
var cell_field_visible: bool = true
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
var _mag_debug_cluster_envelope_count: int = 0
var _mag_debug_cluster_count: int = 0
var _mag_debug_largest_cluster_members: int = 0
var _mag_debug_largest_cluster_radius: float = 0.0
var _mag_debug_largest_cluster_strength: float = 0.0
var _mag_debug_mouse_total: Dictionary = {}
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
# Phase-1: streamline state has been deleted. The ambient reveal is now a
# wavy grid blanket (`AmbientFieldRenderer`). The macro_field_* names below
# are kept as legacy aliases pointing at the grid renderer's primitive
# count so existing HUD readouts keep working.
# Untyped on purpose: Godot resolves `class_name` symbols lazily and dynamic
# property access (e.g. `_ambient_field.enabled`) requires a non-strict type.
var _ambient_field
var _ambient_renderer
var _arc_renderer
var _magnetic_overlay: Node2D
# Per-frame cache for the magnetic source list. _collect_magnetic_sources()
# previously rebuilt a fresh Array[Dictionary] (one Dictionary per cell) on
# every sampler call. The streamline tracer + macro-field reveal call the
# samplers thousands of times per frame, which produced thousands of GC
# allocations and dominated frame time. Now built once at the start of
# _process via _refresh_magnetic_source_cache(), and any internal sampler
# that needs the source list reads _cached_magnetic_sources directly.
var _cached_magnetic_sources: Array[Dictionary] = []
var _cached_magnetic_sources_frame: int = -1
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
var _perf_macro_draw_ms: float = 0.0
var _perf_magnetic_draw_ms: float = 0.0
var _perf_field_overlap_ms: float = 0.0
var _field_overlap_pair_checks: int = 0
var _field_overlap_active_pairs: int = 0
var _field_overlap_avg_overlap: float = 0.0
var _field_overlap_avg_pressure: float = 0.0
var _field_overlap_avg_ambient_drift: float = 0.0
var _field_overlap_avg_force: float = 0.0
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
	_ambient_field = AmbientFieldScript.new()
	_ambient_field.enabled = AMBIENT_FIELD_ENABLED
	_ambient_renderer = AmbientFieldRendererScript.new(self, _ambient_field)
	_arc_renderer = PolarityArcRendererScript.new(self, _ambient_field)
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
	# The ONE predicate every consumer should ask: GDScript polarity-arc
	# draw paths, the overlay redraw gate, and the HUD all read this.
	return cell_field_visible and _cell_field_visual_mode_active()


func set_cell_field_visible(enabled: bool) -> void:
	if cell_field_visible == enabled:
		return
	cell_field_visible = enabled
	if _magnetic_overlay != null:
		_magnetic_overlay.queue_redraw()
	queue_redraw()
	_update_debug()


func _cell_field_visual_mode_active() -> bool:
	return true


func _cell_field_visual_mode_label() -> String:
	return "polarity_arcs"


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
	_perf_field_overlap_ms = 0.0
	_field_overlap_pair_checks = 0
	_field_overlap_active_pairs = 0
	_field_overlap_avg_overlap = 0.0
	_field_overlap_avg_pressure = 0.0
	_field_overlap_avg_ambient_drift = 0.0
	_field_overlap_avg_force = 0.0
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
	# Field-overlap pass runs *before* guidance so guidance can read the cached
	# bond pressure (overlap escalates bond scoring) and so the velocity delta
	# from overlap interaction is integrated alongside any port-based attraction.
	_compute_field_overlap_pass(delta)
	if ENABLE_EXPERIMENTAL_GUIDANCE:
		_update_guidance(delta)
	_mark_capture_cells()
	_sync_bonded_counts()
	# Connected-component snapshot for cluster motion + seedling classification.
	var cluster_start_us: int = Time.get_ticks_usec()
	_clusters_snapshot = _compute_clusters_lite()
	_refresh_cluster_field_cache()
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
			KEY_F6:
				set_cell_field_visible(not cell_field_visible)
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
	# Cell motion trails disabled: the visual contract forbids loose ribbons /
	# long open streamlines as decorative cell-field elements. The wavy grid
	# blanket is the only ambient visual; cell motion expression must come from
	# the dipole arcs and grid distortion, not trailing ribbons.
	# _draw_trails()
	_draw_bonds()
	# Phase-1: legacy cluster-sheath / metaball rendering deleted. The
	# bonded-cluster envelope renderer (`_draw_bonded_cluster_field_envelopes_on`)
	# is now the canonical cluster plasma path.
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


func update_ambient_field_reveal(delta: float) -> void:
	# Phase-1: ambient reveal is the wavy grid blanket. There's no per-frame
	# state to advance — the renderer reads `_simulation_time` directly.
	pass


func draw_ambient_field_reveal_on(target: CanvasItem) -> void:
	# Phase-1 grid blanket. Streamlines deleted; the renderer renders a wavy
	# space-time-like grid distorted by ambient flow + cell wells.
	var draw_start_us: int = Time.get_ticks_usec()
	if _ambient_renderer == null:
		_perf_macro_draw_ms = float(Time.get_ticks_usec() - draw_start_us) * 0.001
		_macro_field_primitive_count = 0
		return
	_ambient_renderer.draw_on(
		target,
		_simulation_time,
		DISH_RADIUS,
		cells,
		ambient_field_reveal_active()
	)
	_macro_field_primitive_count = _ambient_renderer.primitive_count
	_perf_macro_draw_ms = float(Time.get_ticks_usec() - draw_start_us) * 0.001


func _draw_magnetic_field_on(target: CanvasItem) -> void:
	var draw_start_us: int = Time.get_ticks_usec()
	_reset_magnetic_debug_state()
	var primitive_count: int = 0
	if cell_field_enabled() and _arc_renderer != null:
		_arc_renderer.draw_on(target, _simulation_time, DISH_RADIUS, cells, true)
		primitive_count = _arc_renderer.primitive_count
	_mag_debug_cluster_count = _cluster_field_cache.size()
	for entry in _cluster_field_cache:
		_mag_debug_largest_cluster_strength = maxf(
			_mag_debug_largest_cluster_strength, float(entry["strength"])
		)
	_mag_debug_primitive_count = primitive_count
	if debug_magnetic_field:
		_update_magnetic_debug_probe()
	_perf_magnetic_draw_ms = float(Time.get_ticks_usec() - draw_start_us) * 0.001


func draw_cell_field_arcs_on(target: CanvasItem) -> void:
	_draw_magnetic_field_on(target)


func _reset_magnetic_debug_state() -> void:
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
	_mag_debug_cluster_count = 0
	_mag_debug_largest_cluster_members = 0
	_mag_debug_largest_cluster_radius = 0.0
	_mag_debug_largest_cluster_strength = 0.0


# --- ambient / background field (math lives in fields/AmbientField.gd) ---

func _ambient_field_sample_time(time: float) -> float:
	return _simulation_time if time < 0.0 else time


func sample_ambient_field(world_pos: Vector2, time: float = -1.0) -> Vector2:
	if _ambient_field == null or not AMBIENT_FIELD_ENABLED:
		return Vector2.ZERO
	return _ambient_field.sample_local(to_local(world_pos), _ambient_field_sample_time(time), DISH_RADIUS)


func sample_ambient_field_magnitude(world_pos: Vector2, time: float = -1.0) -> float:
	return sample_ambient_field(world_pos, time).length()


func sample_ambient_field_direction(world_pos: Vector2, time: float = -1.0) -> Vector2:
	var v: Vector2 = sample_ambient_field(world_pos, time)
	var s: float = v.length()
	if s <= 0.00001:
		return Vector2.ZERO
	return v / s


func sample_ambient_field_calm_metric(world_pos: Vector2, time: float = -1.0) -> float:
	if _ambient_field == null or not AMBIENT_FIELD_ENABLED:
		return 1.0
	return _ambient_field.sample_calm_local(to_local(world_pos), _ambient_field_sample_time(time), DISH_RADIUS)


func sample_ambient_field_curl_hint(world_pos: Vector2, time: float = -1.0) -> float:
	if _ambient_field == null or not AMBIENT_FIELD_ENABLED:
		return 0.0
	return _ambient_field.sample_curl_local(to_local(world_pos), _ambient_field_sample_time(time), DISH_RADIUS)


# Total energetic field composition layer.
# Ambient field = dish weather.
# Magnetic field = local cell/source field.
# Total field = composed energetic field used by future behavior and cluster work.
func sample_total_field(world_pos: Vector2) -> Vector2:
	if not TOTAL_FIELD_ENABLED:
		return Vector2.ZERO
	var ambient_vec: Vector2 = sample_ambient_field(world_pos) * TOTAL_FIELD_AMBIENT_WEIGHT
	var magnetic_vec: Vector2 = sample_cell_field(world_pos) * TOTAL_FIELD_MAGNETIC_WEIGHT
	var cluster_vec: Vector2 = sample_cluster_field(world_pos)
	var total_vec: Vector2 = ambient_vec + magnetic_vec + cluster_vec
	if not total_vec.is_finite():
		return Vector2.ZERO
	return total_vec.limit_length(TOTAL_FIELD_MAX_STRENGTH)


func sample_cluster_field(world_pos: Vector2) -> Vector2:
	# Sum of every bonded-cluster's composite kernel. The cache is rebuilt
	# once per frame from `_clusters_snapshot`; this sampler is read-only.
	# Returns Vector2.ZERO whenever no bonded clusters exist, so the rest of
	# the field stack continues to work in single-cell scenarios.
	if not CLUSTER_FIELD_ENABLED or _cluster_field_cache.is_empty():
		return Vector2.ZERO
	var local_pos: Vector2 = to_local(world_pos)
	var summed: Vector2 = Vector2.ZERO
	for entry in _cluster_field_cache:
		var center: Vector2 = entry["center"]
		var reach: float = float(entry["reach"])
		var strength: float = float(entry["strength"])
		var axis: Vector2 = entry["axis"]
		var offset: Vector2 = local_pos - center
		var dist: float = offset.length()
		if dist >= reach:
			continue
		var soften: float = CLUSTER_FIELD_KERNEL_SOFTEN
		var falloff: float = (reach * reach) / (dist * dist + soften * soften + reach * 0.5)
		falloff = clampf(falloff, 0.0, 1.0)
		var radial: Vector2 = (offset / maxf(dist, 0.0001))
		var polarity: float = clampf(radial.dot(axis), -1.0, 1.0)
		# Composite vector: outward radial + polarity-axis modulation, so the
		# cluster reads as "this group has a charged envelope" rather than a
		# uniform blob.
		var contribution: Vector2 = (radial * 0.65 + axis * polarity * 0.45) * strength * falloff
		summed += contribution
	if not summed.is_finite():
		return Vector2.ZERO
	return summed.limit_length(CLUSTER_FIELD_MAX_STRENGTH)


func sample_total_ecological_field_at(
	world_pos: Vector2,
	exclude_cell: CellBody = null,
	dampen_self: float = 0.0
) -> Dictionary:
	# Canonical per-point sampler. The polarity-arc renderer, cluster envelope
	# renderer, and HUD probes all read this so the visuals are guaranteed to
	# match the simulation. `dampen_self` subtracts that fraction of the
	# excluded cell's own contribution — used by lobe arcs so they're shaped
	# by the *environment* instead of frozen into a self-orbit.
	var ambient_vec: Vector2 = Vector2.ZERO
	if AMBIENT_FIELD_ENABLED:
		ambient_vec = sample_ambient_field(world_pos)
	var cell_vec: Vector2 = sample_magnetic_field(world_pos)
	if exclude_cell != null and dampen_self > 0.0:
		var self_vec: Vector2 = _cell_only_contribution(world_pos, exclude_cell)
		cell_vec -= self_vec * clampf(dampen_self, 0.0, 1.0)
	var cluster_vec: Vector2 = sample_cluster_field(world_pos)
	var weighted_vec: Vector2 = (
		ambient_vec * TOTAL_FIELD_AMBIENT_WEIGHT
		+ cell_vec * TOTAL_FIELD_MAGNETIC_WEIGHT
		+ cluster_vec
	)
	if not weighted_vec.is_finite():
		weighted_vec = Vector2.ZERO
	weighted_vec = weighted_vec.limit_length(TOTAL_FIELD_MAX_STRENGTH)
	var strength: float = weighted_vec.length()
	var direction: Vector2 = Vector2.ZERO
	if strength > 0.00001:
		direction = weighted_vec / strength
	return {
		"vector": weighted_vec,
		"direction": direction,
		"strength": strength,
		"strength_norm": clampf(strength / maxf(TOTAL_FIELD_MAX_STRENGTH, 0.001), 0.0, 1.0),
		"ambient_strength": ambient_vec.length(),
		"ambient_strength_norm": clampf(
			ambient_vec.length() / maxf(AMBIENT_FIELD_STRENGTH, 0.001), 0.0, 1.0
		),
		"cell_strength": cell_vec.length(),
		"cell_strength_norm": clampf(
			cell_vec.length() / maxf(MAG_FIELD_MAX_STRENGTH, 0.001), 0.0, 1.0
		),
		"cluster_strength": cluster_vec.length(),
		"cluster_strength_norm": clampf(
			cluster_vec.length() / maxf(CLUSTER_FIELD_MAX_STRENGTH, 0.001), 0.0, 1.0
		),
		"curl": sample_ambient_field_curl_hint(world_pos),
	}


func _cell_only_contribution(world_pos: Vector2, cell: CellBody) -> Vector2:
	# Isolate the contribution of a single cell out of the cached source list.
	# Used by `sample_total_ecological_field_at` to dampen self-bias.
	if cell == null:
		return Vector2.ZERO
	var summed: Vector2 = Vector2.ZERO
	for source in _magnetic_sources_cached():
		var owner: Variant = source.get("owner", null)
		if owner != cell:
			continue
		summed += _magnetic_source_contribution(world_pos, source)
	if not summed.is_finite():
		return Vector2.ZERO
	return summed


func _refresh_cluster_field_cache() -> void:
	_cluster_field_cache.clear()
	if not CLUSTER_FIELD_ENABLED or _clusters_snapshot.is_empty():
		return
	for cluster in _clusters_snapshot:
		var members: Array = cluster as Array
		if members.size() < CLUSTER_FIELD_MIN_MEMBERS:
			continue
		var center: Vector2 = Vector2.ZERO
		var charge_sum: float = 0.0
		var axis_sum: Vector2 = Vector2.ZERO
		var strength_sum: float = 0.0
		for m in members:
			var cb: CellBody = m
			center += cb.position
			charge_sum += cb.charge_ratio_value()
			axis_sum += cb.polarity_axis() * (0.4 + 0.6 * cb.charge_ratio_value())
			strength_sum += cb.field_strength
		var n: float = float(members.size())
		center /= n
		var bound_radius: float = 0.0
		for m in members:
			var cb2: CellBody = m
			bound_radius = maxf(bound_radius, center.distance_to(cb2.position) + cb2.radius)
		var axis_n: Vector2 = Vector2.UP
		if axis_sum.length_squared() > 0.000001:
			axis_n = axis_sum.normalized()
		_cluster_field_cache.append({
			"members": members,
			"center": center,
			"radius": bound_radius,
			"reach": bound_radius * CLUSTER_FIELD_REACH_GAIN,
			"axis": axis_n,
			"charge": charge_sum / n,
			"strength": minf(strength_sum * CLUSTER_FIELD_STRENGTH_GAIN, CLUSTER_FIELD_MAX_STRENGTH),
		})


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


func _visual_polarity_axis(cell: CellBody) -> Vector2:
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


func _cell_field_geom(cell: CellBody) -> String:
	if cell == null or cell.signature == null:
		return ""
	var geom: String = cell.signature.geometry_type
	if geom == "wedge":
		return "triangle"
	return geom


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



# Cell-field polarity-contour renderer.
#
# This is the canonical visible cell-field path. Every cell expresses two
# polarity lobes; each lobe is a *partial contour orbiting the cell* (not a
# strand emitted from a surface anchor). The previous renderer
# (`_draw_sphere_attached_filaments_on` + `_integrate_projected_cell_field_arc`)
# stepped a polyline outward from a point on the sphere, producing a
# whisker / tentacle look that no amount of bend-tuning could fix. It is gone.
#
# Generation principle, per lobe:
#   Cell-level data sampled ONCE in _build_cell_field_lobe_arc_points:
#     ambient_dir  = sample_ambient_field(center).normalized()
#     neighbor_dir = cell.field_neighbor_dir       (cached by overlap pass)
#     overlap_str  = clamp(cell.field_overlap_energy * gain)
#     compression  = cell.field_compression
#   Per arc point: cheap trig only — radial wobble, ambient bend, neighbor
#   bend/squeeze (asymmetric: tighter on the side facing overlap), and a small
#   compression jitter when fields are too deep. The visuals are now a direct
#   consequence of the overlap-pass simulation; no per-point full-field
#   sampling, so cost is O(N · arc_points) instead of O(N² · arc_points).

# --- Removed: merged-density iso-polygon renderer + all per-cell-lobe and
# cluster-envelope renderers. The visible cell-field layer now lives in
# `render/PolarityArcRenderer.gd` — streamline tracing through one shared
# dipole field. Bonded cells unify because field lines naturally bridge
# from a pole on cell A to the opposite pole on cell B; no wrapper, no hull.



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
	# Snapshot the canonical ecological field at the mouse so the HUD shows
	# the same numbers every other system reads.
	_mag_debug_mouse_total = sample_total_ecological_field_at(to_global(mouse_local))
	if best_sphere == null:
		return
	var probe_local: Vector2 = best_sphere.position + Vector2.RIGHT.rotated(best_sphere.rotation) * (best_sphere.radius + 14.0)
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
	# DISABLED legacy path. Trails produced loose ribbon / open streamline
	# visuals that the field-ecology visual contract forbids. The function is
	# kept as a no-op so any straggling caller compiles; it is not called from
	# `_draw()` anymore.
	pass


func _draw_glass_rim() -> void:
	draw_arc(Vector2.ZERO, DISH_RADIUS + 1.5, 0.0, TAU, 128, RIM_OUTER, 1.4, true)
	draw_arc(Vector2.ZERO, DISH_RADIUS - 0.5, 0.0, TAU, 128, RIM_INNER, 0.9, true)
	draw_arc(Vector2.ZERO, DISH_RADIUS + 0.5, PI * 1.05, PI * 1.55, 32, Color(1.0, 1.0, 1.0, 0.55), 1.6, true)
	draw_arc(Vector2.ZERO, DISH_RADIUS - 3.0, 0.0, TAU, 96, Color(0.10, 0.14, 0.22, 0.65), 0.8, true)


func _draw_bonds() -> void:
	if not ENABLE_BONDS:
		return
	var frame: int = Engine.get_frames_drawn()
	for bond in bonds:
		var pa: Vector2 = bond.endpoint_a()
		var pb: Vector2 = bond.endpoint_b()
		_draw_bond_styled(bond, pa, pb, frame)


func _draw_bond_styled(bond: Bond, pa: Vector2, pb: Vector2, frame: int) -> void:
	var stress: float = clampf(bond.strain, 0.0, 1.0)
	var base_alpha: float = lerpf(0.85, 0.30, stress)
	var width: float = 0.8 + bond.strength * 1.4
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
	_cluster_field_cache.clear()
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
	# Dipole source list. Each cell contributes a 2D magnetic dipole with
	# moment m = sign(charge) * field_strength * radius² * field_reach along
	# its polarity axis. This is the same model PolarityArcRenderer and
	# AmbientFieldRenderer integrate, so simulation and visualization agree.
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
		var charge_sign: float = 1.0 if charge >= 0.0 else -1.0
		var axis: Vector2 = cell.polarity_axis()
		if axis.length_squared() < 0.000001:
			continue
		axis = axis.normalized()
		var moment_mag: float = (
			weight * cell.radius * cell.radius
			* maxf(cell.field_reach * CELL_FIELD_BASE_REACH, 0.30)
		)
		sources.append({
			"kind": _canonical_geom(cell.signature.geometry_type),
			"owner": cell,
			"position": cell.global_position,
			"moment": axis * (moment_mag * charge_sign),
			"charge": charge,
		})
	return sources


# 2D magnetic dipole field at offset r from a dipole with moment m:
#   B(r) = (1/r²)(2(m·r̂)r̂ - m)
# Plummer-softened so a sample on the source returns a finite vector.
const _MAG_DIPOLE_EPS: float = 4.0


func _magnetic_source_contribution(world_pos: Vector2, source: Dictionary) -> Vector2:
	var source_pos: Vector2 = source["position"] as Vector2
	var moment: Vector2 = source["moment"] as Vector2
	var r: Vector2 = world_pos - source_pos
	var r2: float = r.length_squared() + _MAG_DIPOLE_EPS * _MAG_DIPOLE_EPS
	if r2 < 0.000001:
		return Vector2.ZERO
	var rl: float = sqrt(r2)
	var rhat: Vector2 = r / rl
	var contribution: Vector2 = (rhat * (2.0 * moment.dot(rhat)) - moment) / r2
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


# --- Field-overlap pass (the ecological core) ---
#
# Once per frame, walk a spatial bucket grid and evaluate every pair of cells
# whose field reaches actually overlap. From the single scalar `overlap` we
# derive: an attraction/compression force, an aggregate "bond pressure"
# (compatibility × overlap), a polarity-axis bias, and a per-cell average
# direction toward overlapping neighbors. All four numbers are cached on the
# CellBody so motion, bond logic, and the contour renderer all read the same
# data — no separate "seek" rule, no draw-only sampler.
func _compute_field_overlap_pass(delta: float) -> void:
	_field_overlap_pair_checks = 0
	_field_overlap_active_pairs = 0
	if not FIELD_OVERLAP_ENABLED or cells.is_empty():
		return
	var t_start_us: int = Time.get_ticks_usec()
	# 1. Bucket every cell by integer-quantized position so we only consider
	#    pairs whose centers live in the same or adjacent cells of the grid.
	var bucket_size: float = maxf(FIELD_OVERLAP_BUCKET_SIZE, 16.0)
	var inv_bucket: float = 1.0 / bucket_size
	var buckets: Dictionary = {}
	for cell in cells:
		if cell == null or cell.signature == null:
			continue
		var key: Vector2i = Vector2i(int(floor(cell.position.x * inv_bucket)), int(floor(cell.position.y * inv_bucket)))
		if not buckets.has(key):
			buckets[key] = []
		(buckets[key] as Array).append(cell)
	# 2. For each cell, scan its bucket plus the 8 neighbors. Use cell A's
	#    instance id as the lower bound so each pair is visited exactly once.
	var checks: int = 0
	var active: int = 0
	var sum_overlap: float = 0.0
	var sum_pressure: float = 0.0
	for cell in cells:
		if cell == null or cell.signature == null:
			continue
		var a: CellBody = cell
		var a_key: Vector2i = Vector2i(int(floor(a.position.x * inv_bucket)), int(floor(a.position.y * inv_bucket)))
		var a_id: int = a.get_instance_id()
		var ra: float = a.radius
		var Ra: float = ra * FIELD_OVERLAP_REACH_MULT * maxf(a.field_reach, 0.1)
		var qa: float = a.signature.charge
		var sa: float = maxf(a.field_strength, 0.0) * (0.4 + 0.6 * a.charge_ratio_value())
		var axis_a: Vector2 = a.polarity_axis()
		var sign_a: float = 1.0 if qa >= 0.0 else -1.0
		for off in FIELD_OVERLAP_NEIGHBOR_OFFSETS:
			var bk: Vector2i = a_key + off
			if not buckets.has(bk):
				continue
			for other in buckets[bk] as Array:
				var b: CellBody = other
				if b == null or b == a or b.signature == null:
					continue
				if b.get_instance_id() <= a_id:
					continue
				checks += 1
				var rb: float = b.radius
				var Rb: float = rb * FIELD_OVERLAP_REACH_MULT * maxf(b.field_reach, 0.1)
				var sum_R: float = Ra + Rb
				var diff: Vector2 = b.position - a.position
				var d2: float = diff.length_squared()
				if d2 >= sum_R * sum_R:
					continue
				var d: float = sqrt(d2)
				# Smooth overlap: 0 when d >= sum_R, 1 when centers coincide.
				var raw_overlap: float = 1.0 - d / maxf(sum_R, 0.001)
				var overlap: float = raw_overlap * raw_overlap   # ease-in
				if overlap < FIELD_OVERLAP_MIN_RATIO:
					continue
				active += 1
				var n: Vector2 = Vector2.RIGHT
				if d > 0.001:
					n = diff / d
				var qb: float = b.signature.charge
				var sb: float = maxf(b.field_strength, 0.0) * (0.4 + 0.6 * b.charge_ratio_value())
				var axis_b: Vector2 = b.polarity_axis()
				var sign_b: float = 1.0 if qb >= 0.0 else -1.0
				# Charge product: opposite charges attract, same repel.
				var charge_factor: float = -sign_a * sign_b
				# Polarity alignment: -1 (anti-parallel poles facing) is the most
				# bondable; +1 (parallel poles) interferes.
				var alignment: float = clampf(axis_a.dot(axis_b), -1.0, 1.0)
				# Compatibility for bond pressure: opposite charge, anti-aligned poles.
				var compat: float = clampf(0.5 + 0.5 * charge_factor, 0.0, 1.0)
				compat *= clampf(0.5 - 0.5 * alignment, 0.0, 1.0) + 0.25
				var pair_strength: float = sa * sb
				# Attraction component proportional to overlap × charge factor.
				var attract_mag: float = overlap * pair_strength * FIELD_OVERLAP_FORCE_GAIN * charge_factor
				# Compression: kicks in when fields are too deeply overlapped, regardless of sign.
				var depth: float = clampf((overlap - FIELD_OVERLAP_REPEL_DEPTH) / maxf(1.0 - FIELD_OVERLAP_REPEL_DEPTH, 0.001), 0.0, 1.0)
				var compress_mag: float = depth * pair_strength * FIELD_OVERLAP_REPEL_GAIN
				# Net per-pair force: attractive along +n on A (towards B) when charges oppose,
				# minus a compression push when they're too deep regardless of sign.
				var net_force: Vector2 = n * (attract_mag - compress_mag)
				a.field_interaction_vec += net_force
				b.field_interaction_vec -= net_force
				# Cached neighbor direction (weighted by overlap) for the contour renderer.
				a.field_neighbor_dir += n * overlap
				b.field_neighbor_dir -= n * overlap
				var energy: float = overlap * pair_strength
				a.field_overlap_energy += energy
				b.field_overlap_energy += energy
				var pressure: float = overlap * compat * FIELD_OVERLAP_BOND_PRESSURE_GAIN
				a.field_bond_pressure += pressure
				b.field_bond_pressure += pressure
				a.field_polarity_bias += alignment * overlap
				b.field_polarity_bias += alignment * overlap
				a.field_overlap_count += 1
				b.field_overlap_count += 1
				a.field_compression = maxf(a.field_compression, depth)
				b.field_compression = maxf(b.field_compression, depth)
				sum_overlap += overlap
				sum_pressure += pressure
	# 3. Apply the accumulated interaction force as a velocity delta. This is
	#    the real "attraction emerges from overlap" path: motion comes from the
	#    summed pairwise overlap, never from a separate seek/target rule. We
	#    also apply a per-cell *ambient drift* here, sampled once per cell — this
	#    is the dish's plasma current, deliberately weaker than pair attraction.
	var counted: int = 0
	var sum_drift: float = 0.0
	var sum_force: float = 0.0
	var force_counted: int = 0
	var ambient_inv_strength: float = 1.0 / maxf(AMBIENT_FIELD_STRENGTH, 0.001)
	for cell in cells:
		if cell == null or cell.signature == null:
			continue
		var c: CellBody = cell
		var force_mag: float = c.field_interaction_vec.length()
		if force_mag > 0.001:
			c.apply_field_velocity_delta(c.field_interaction_vec * delta)
			sum_force += force_mag
			force_counted += 1
		# Normalize the cached neighbor direction so renderers can use it as a unit vector.
		if c.field_neighbor_dir.length_squared() > 0.000001:
			c.field_neighbor_dir = c.field_neighbor_dir.normalized()
			# Polarity torque: align the cell's polarity axis toward overlapping
			# compatible neighbors. The accumulated `field_bond_pressure` is the
			# compat-weighted overlap, so it's already a usable scalar weight for
			# alignment. Incompatible-but-overlapping cells (high overlap_energy,
			# low bond_pressure) get a small *repulsive* twist.
			var axis_now: Vector2 = c.polarity_axis()
			if axis_now.length_squared() > 0.000001:
				var attract_weight: float = clampf(c.field_bond_pressure * 0.40, 0.0, 1.0)
				var incompat_weight: float = clampf(c.field_overlap_energy * 0.10 - attract_weight, 0.0, 1.0)
				var desired: Vector2 = c.field_neighbor_dir
				var cross_z: float = axis_now.x * desired.y - axis_now.y * desired.x
				var torque: float = cross_z * (
					attract_weight * FIELD_POLARITY_TORQUE_GAIN
					- incompat_weight * FIELD_POLARITY_TORQUE_REPEL_GAIN
				)
				var dw: float = torque * delta
				var dw_cap: float = FIELD_POLARITY_TORQUE_MAX_DW * delta
				if dw > dw_cap:
					dw = dw_cap
				elif dw < -dw_cap:
					dw = -dw_cap
				if absf(dw) > 0.00001:
					c.apply_angular_delta(dw)
		# Ambient drift: the dish-wide medium gently pushes every cell along the
		# ambient flow. Scaled by the cell's own field_reach so larger cells
		# catch more current. This is "dish weather", not propulsion.
		if AMBIENT_FIELD_ENABLED:
			var ambient_vec: Vector2 = sample_ambient_field(c.global_position)
			if ambient_vec.length_squared() > 0.000001:
				var drift: Vector2 = ambient_vec * (FIELD_OVERLAP_AMBIENT_DRIFT_GAIN * maxf(c.field_reach, 0.1) * delta)
				var dv_cap: float = FIELD_OVERLAP_AMBIENT_DRIFT_MAX_DV * delta
				if drift.length_squared() > dv_cap * dv_cap:
					drift = drift.normalized() * dv_cap
				c.apply_field_velocity_delta(drift)
				sum_drift += ambient_vec.length() * ambient_inv_strength
				counted += 1
	_field_overlap_pair_checks = checks
	_field_overlap_active_pairs = active
	if active > 0:
		_field_overlap_avg_overlap = sum_overlap / float(active)
		_field_overlap_avg_pressure = sum_pressure / float(active)
	else:
		_field_overlap_avg_overlap = 0.0
		_field_overlap_avg_pressure = 0.0
	_field_overlap_avg_ambient_drift = sum_drift / float(maxi(counted, 1))
	_field_overlap_avg_force = sum_force / float(maxi(force_counted, 1))
	_perf_field_overlap_ms = float(Time.get_ticks_usec() - t_start_us) * 0.001


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
	# Field-overlap escalation: pressure built up by overlapping fields makes
	# bonding more likely. Bond pressure is per-cell (already accumulated this
	# frame); we use the smaller of the two so a single hot cell can't drag a
	# cold neighbor into a bond.
	var pressure: float = minf(a.field_bond_pressure, b.field_bond_pressure)
	score *= 1.0 + FIELD_OVERLAP_GUIDANCE_BIAS * clampf(pressure, 0.0, 2.0)
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
			# Field-overlap bias: cells whose fields are already pressing into
			# each other are preferred bond candidates over cells that just
			# happened to graze ports without a real ecological interaction.
			var pressure: float = minf(a.field_bond_pressure, b.field_bond_pressure)
			score *= 1.0 + FIELD_OVERLAP_BOND_SCAN_BIAS * clampf(pressure, 0.0, 2.0)
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
	hud += "\nbonded clusters: %d  envelope primitives: %d  largest: %d members r=%.1f s=%.2f" % [
		_mag_debug_cluster_count,
		_mag_debug_cluster_envelope_count,
		_mag_debug_largest_cluster_members,
		_mag_debug_largest_cluster_radius,
		_mag_debug_largest_cluster_strength,
	]
	hud += "\nfield-overlap: pairs=%d active=%d  sim=%.2fms  draw=%.2fms" % [
		_field_overlap_pair_checks,
		_field_overlap_active_pairs,
		_perf_field_overlap_ms,
		_perf_magnetic_draw_ms,
	]
	hud += "\n  avg overlap=%.3f  avg pressure=%.3f  avg ambient drift=%.3f  avg force=%.2f" % [
		_field_overlap_avg_overlap,
		_field_overlap_avg_pressure,
		_field_overlap_avg_ambient_drift,
		_field_overlap_avg_force,
	]
	if not _mag_debug_mouse_total.is_empty():
		hud += "\necol@mouse: total=%.3f ambient=%.3f cell=%.3f cluster=%.3f" % [
			float(_mag_debug_mouse_total.get("strength", 0.0)),
			float(_mag_debug_mouse_total.get("ambient_strength", 0.0)),
			float(_mag_debug_mouse_total.get("cell_strength", 0.0)),
			float(_mag_debug_mouse_total.get("cluster_strength", 0.0)),
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
	hud += "\nCELL-FIELD: %s" % [
		"ON" if cell_field_enabled() else "OFF",
	]
	hud += "\nambient grid primitives: %d  arc primitives: %d" % [
		_macro_field_primitive_count,
		_mag_debug_primitive_count,
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
	hud += "\nperf ms bond scan/update: %.2f / %.2f" % [
		_perf_bond_scan_ms,
		_perf_bond_update_ms,
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
	var hud: String = "selected: %s\ncells: %d  bonds: %d\nstate: %s  fps: %d\nBONDS: %s  LEGACY LINE: %s  SEEDLINGS: %s\nFIELD DEBUG: %s  CELL-FIELD VIS: %s (mode=%s)  FIELD SIM: %s\nclusters: %d  largest: %d  coh: %.2f\nseedlings: %d\navg charge: %.3f  avg noise: %.3f\n[LMB] spawn  [RMB] delete  [C] clear  [Space] pause\n[H] hotbar  [Tab] debug  [B] bonds  [=] field debug  [1-4] select  [F1-F5] viz  [F6] cell-field" % [
		_selected_cell_name(),
		count, bonds.size(),
		state_text, Engine.get_frames_per_second(),
		"ON" if ENABLE_BONDS else "OFF",
		"ON" if ENABLE_LEGACY_LINE_CELL else "OFF",
		"ON" if ENABLE_SEEDLING_CLASSIFICATION else "OFF",
		"ON" if debug_magnetic_field else "OFF",
		"ON" if cell_field_enabled() else "OFF",
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
