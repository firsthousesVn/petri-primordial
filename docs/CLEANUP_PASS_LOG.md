# Cleanup Pass Log

Date: 2026-04-29
Repo: `petri-primordial`
Pass type: maintainer cleanup / quarantine pass

## Start Git Status

```text
 M project.godot
 M scenes/petri/PetriDish.tscn
 M scripts/petri/PetriDish.gd
?? docs/
?? icon.svg.import
?? resources/cells/CoilRotorCell.tres
?? resources/cells/CrescentSoftCell.tres
?? resources/cells/LineGlassCell.tres
?? resources/cells/RoundPearlCell.tres
?? resources/cells/SpiralSoftCell.tres
?? resources/cells/WedgeGlassCell.tres
?? scenes/petri/CellBody.tscn
?? scripts/petri/Bond.gd
?? scripts/petri/Bond.gd.uid
?? scripts/petri/CellBody.gd
?? scripts/petri/CellBody.gd.uid
?? scripts/petri/CellHotbar.gd
?? scripts/petri/CellHotbar.gd.uid
?? scripts/petri/CellPort.gd
?? scripts/petri/CellPort.gd.uid
?? scripts/petri/CellSignature.gd
?? scripts/petri/CellSignature.gd.uid
?? scripts/petri/MagneticFieldOverlay.gd
?? scripts/petri/MagneticFieldOverlay.gd.uid
?? scripts/petri/MediumField.gd
?? scripts/petri/MediumField.gd.uid
?? scripts/petri/PetriDish.gd.uid
```

## Headless Godot Load

Known binary:
- `/mnt/c/Users/kxixg/Downloads/Godot_v4.6.1-stable_win64.exe`

Command run:
```bash
/mnt/c/Users/kxixg/Downloads/Godot_v4.6.1-stable_win64.exe --headless --path . --quit-after 3 --verbose
```

Result:
- initial baseline run: passed, exit code `0`
- final verification run after cleanup: passed, exit code `0`
- no script parse/load errors observed in the headless output
- no claim is made here about visual correctness or gameplay feel

## What This Pass Was Allowed To Touch

- readability-oriented cleanup with no intended functionality change
- explicit maintenance flags and guardrails
- stale-wrapper removal when references were provably absent in code
- project docs that clarify ontology and risk
- comments that mark naming debt and legacy paths

## What This Pass Was Forbidden To Touch

- gameplay redesign
- magnetic sampler redesign
- magnetic visual redesign
- bonding mechanics changes
- new simulation systems
- new cell types
- new organism / disease / progression features

## Files Changed In This Pass

Code and project-facing docs changed by this pass:
- `scripts/petri/PetriDish.gd`
- `scripts/petri/CellBody.gd`
- `docs/MICRO_LIFE_ONTOLOGY.md`
- `docs/BOND_RISK_MAP.md`
- `docs/CLEANUP_PASS_LOG.md`

## Flags Added / Changed

Added in `scripts/petri/PetriDish.gd`:
- `ENABLE_EXPERIMENTAL_GUIDANCE = true`
- `ENABLE_SEEDLING_CLASSIFICATION = false`
- `ENABLE_MAG_LEGACY_VISUALS = false`
- `ENABLE_STARTUP_AUTOSPAWN = false`
- `MAG_FIELD_SIM_MODEL = "radial_charge_centers"`

Existing defaults preserved:
- `ENABLE_BONDS` remains runtime-togglable and visible in HUD
- `ENABLE_LEGACY_LINE_CELL = false`
- `MAG_FIELD_VIS_STYLE = "sphere_attached"`

## Legacy Systems Quarantined

- seedling classification is now explicitly treated as experimental and disabled by default
- seedling draw path is gated behind `ENABLE_SEEDLING_CLASSIFICATION`
- startup autospawn is explicit and off by default
- startup spawn roster now follows the active hotbar roster, so hidden legacy `Line` does not leak into default spawn pools
- magnetic sampled-streamline / contour / pole-marker branches now require `ENABLE_MAG_LEGACY_VISUALS`
- Line-specific bond grammar, ports, tuning, and rendering now carry `LEGACY_LINE_CELL_PATH` comments
- internal geometry naming debt is now documented in code comments and ontology docs

## Small Dead-Code Cleanup

Provably unreferenced wrapper functions removed from `scripts/petri/PetriDish.gd`:
- `_draw_magnetic_field()`
- `_draw_textbook_field_loops()`
- `_draw_textbook_field_loops_on()`
- `_draw_textbook_arc_ticks()`
- `_draw_textbook_arc_ticks_on()`
- `_draw_visual_pole_marks()`
- `_draw_field_line_ticks()`
- `_draw_magnetic_contours()`
- `_bezier_arc_polyline()`

This was a readability cleanup only. No remaining code references to those wrappers were found after removal.

## Systems Intentionally Not Touched

- `sample_magnetic_field()` behavior
- magnetic superposition math
- active sphere-attached magnetic loop style
- bond formation logic
- bond seating and collision correction math
- triangle impulse behavior
- coil spin behavior
- round homeostasis behavior
- legacy Line resource files

## Small Dead-File Quarantine

Reference scan result for `resources/cells/SpiralSoftCell.tres`:
- no code or scene references found in the repo scan
- only audit docs mention it

Recommendation:
- mark for deletion in a later pass after one more editor-side reference check
- do not delete it blindly in a mixed cleanup pass

## Online Research Used For This Pass

Cleanup priorities were guided by:
- GitHub Docs, “Review AI-generated code”: human review, maintainability checks, and skepticism toward AI-specific pitfalls
- Google documentation/code health guidance: write for humans first, use meaningful names, comments should explain why
- Martin Fowler on code smells and YAGNI/simple design: remove duplication and unnecessary flexibility, keep intention clear

## Next Recommended Prompt

`Do a no-behavior-change readability pass on PetriDish.gd only: extract one or two obviously repeated HUD/debug formatting or legacy-flag helper blocks into small helpers, and keep the diff surgical.`

## Follow-Up Readability Pass

Additional behavior-safe cleanup completed after the initial quarantine pass:
- extracted `_reset_magnetic_debug_state()` so magnetic overlay state reset is explicit in one place
- extracted `_legacy_magnetic_visuals_enabled()` so the legacy magnetic branch gate reads as a named policy instead of inline boolean noise
- extracted `_seedling_classification_enabled()` and `_seedling_debug_enabled()` so seedling gating is consistent across draw/classification paths
- extracted `_magnetic_debug_hud_lines()` so the main HUD builder no longer inlines a second large debug-only string block
- refreshed `docs/MAGNETIC_FIELD_AUDIT.md` to match the current code exactly after wrapper removal
- refreshed `docs/CURRENT_PETRI_STATE.md` so it no longer points at removed magnetic wrappers or stale spawn/seedling defaults

Files changed in this follow-up:
- `scripts/petri/PetriDish.gd`
- `docs/MAGNETIC_FIELD_AUDIT.md`
- `docs/CURRENT_PETRI_STATE.md`

Verification for the follow-up readability pass:
- headless Godot load rerun from the project directory with `--path .`
- exit code: `0`
- no parse/load errors observed
- one attempted `--path /mnt/...` invocation failed because the Windows Godot binary rejected the WSL-style absolute path; this was a tooling/path issue, not a project load failure
