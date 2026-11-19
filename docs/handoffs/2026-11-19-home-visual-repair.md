# Handoff — Home screen visual repair, 19 Nov 2026

## What changed

The home screen was rebuilt for the premium look. Every defect was in the
**generated artwork**, not the layout code:

| Symptom | Cause | Fix |
|---|---|---|
| Beads at the ring ends | A flat polyline with circles drawn on top | Filled stadium polygons, one outline per layer |
| 26 concentric lines on the board | 26 engraved grooves in the stone art | A smooth sanded disc with a soft rim |
| Pale stripe across START RUN | The gloss band sat in the nine-patch's stretching region | The gloss moved into the corner patches |
| Gold outline around nothing | `panel_stat.png` was a translucent pill, scaled | A solid ivory card with a gold border |
| Flat, small logo | Plain text on a flat plaque | Bevelled, shadowed lettering on a dimensional plaque |
| Coin pill over the logo | The logo spanned the full screen width | The logo got a centred, aspect-locked box |
| Stale composition after a resize | The layout only ran on the control's own `resized` | It now follows the viewport's `size_changed` |

## The two rules worth keeping

- **A nine-patch margin must sit just past the art's corner radius.** A margin
  larger than the radius stretches the round end into an oval. The buttons use
  a 38px radius and a 42px margin; the cards use 30px and 34px.
- **Nothing decorative may span a nine-patch's stretching region.** Highlights
  go in the corner patches, or they smear into a stripe.

## The ring geometry

`tools/build_zen_assets.py` builds each ring as one filled polygon per layer,
traced in a single direction:

    outer edge forward -> cap -> inner edge back -> cap

The caps are derived from the arc's own endpoints, so they continue the tube's
shading. The lighting is consistent: the sheen and specular sit up and to the
left of the tube on every ring.

The three rings share one 1024x1024 canvas and one centre, with different
radii (0.415 / 0.325 / 0.235) so they nest rather than overlap. All three
TextureRects are the same size with the pivot at the same point, so they turn
as one assembly.

## Verified

- `test_home.gd` → `HOME_OK` (live stats, every asset present, one shared
  pivot, the rings actually turn, all five actions fire)
- `test_responsive.gd` → `RESPONSIVE_OK` (narrow 76%, standard 67%, tall 86%,
  tablet 44% of the width; no collisions with the logo, cards or nav)
- `test_run.gd` → `RUN_OK`, `test_ui.gd` → `UI_OK`
- Boot clean; `tests/screenshot_all.gd` captures all eight screens at once.

## Still needing professional artwork

The logo is the one asset that cannot reach the reference's quality from
procedural art: a premium game wordmark is drawn, not generated. The slot is
`assets/ui/ring_run_zen/branding/ring_run_logo.png`, 1024x560 RGBA, transparent,
centre-weighted so it can be placed in the centred box. Dropping in a
finished wordmark needs no code change.

The rings, stone board, buttons and icons are all generated at 9-patch-safe
sizes and are good enough to ship, but a real artist's set would still be an
upgrade.
