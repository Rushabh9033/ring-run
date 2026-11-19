# Handoff — repository-grounded UI / VFX repair, 19 Nov 2026

Repo: `https://github.com/Rushabh9033/ring-run`

## Where this stands

The audited base revision was `542591d`. Three commits landed on top of it:

| Commit | What |
|---|---|
| `40736e6` | Particle spawn coordinates and directions |
| `39b854a` | Touch accuracy, board scale, connector truth, duplicate audio |
| `fdac0ff` | Nine-patch distortion, responsive layout, modal staging |
| `0f84c5d` | Real layout verification |

Godot 4.7.2, GL Compatibility renderer, 720 × 1280 base viewport with
`canvas_items` stretch and `expand` aspect. Branch `main`.

## Verified

| Test | Result |
|---|---|
| `test_layout.gd` | **LAYOUT_OK** — 31 buttons across 8 screens |
| `test_responsive.gd` | **RESPONSIVE_OK** — 4 sizes × 8 screens |
| `test_vfx.gd` | **VFX_OK** |
| `test_home.gd` | **HOME_OK** |
| `test_run.gd` | **RUN_OK** |
| `test_ui.gd` | **UI_OK** |

Boot clean. `tests/screenshot_all.gd` captures all eight screens;
`tests/record_vfx.gd` records the celebration — the GIF is in
`screenshots/puzzle-clear-vfx.gif`.

## The root causes, in the order they were found

### 1. Particles in the top-left corner

`ring_shard_burst.gd`, `c_arc_star_burst.gd` and `floating_text.gd` set
**`global_position`** but were handed a **parent-local** coordinate. The rings
are concentric, so a ring sits at the board's origin, and writing that into
`global_position` put every effect at **screen (0, 0)** — on the Stage panel.

Fixed by `gameplay/vfx.gd`: the caller passes a global position, Vfx converts
it into the parent's local space.

### 2. Touching the wrong ring

`_pick_ring_at` compared `|point|` with the ring's radius. That is only
correct for a circle — a square's radius depends on the angle, and an oval
and a triangle are not round at all. Now `PieceGeometry.distance_to_ring()`
follows the same outline the ring is drawn from, and the gap is open.

### 3. Two board scales

`_layout_board()` and `_rebuild_ring_nodes()` each computed a scale. Whichever
ran last won. There is now one, applied after the ring specs are known.

### 4. A false unlock

Every connector pin was drawn as an open cream pin.
`PuzzleRules.dependency_state()` is now the single source of that state, and
the board draws a closed pin while a ring is still waiting on another one.

### 5. Squashed buttons

The button skins were 256 × 112 textures with 42px patch margins, so a 56px
button had 84px of vertical patch in a 56px box. **A nine-patch cannot scale
a pill's rounded caps** — the cap pixels never shrink. Buttons, the coin pill,
the stat cards, the modal card and the collection cards are drawn with
`StyleBoxFlat` now.

### 6. A screen that fought the anchors

`slide_in` wrote `position.x` on a full-rect anchored Control. The screen
ended up narrower than the screen, and stayed shifted if the tween was
interrupted. It slides the offsets now.

### 7. Two pandas

The celebrating panda on the modal and the idle panda on the board were both
on screen. The board's panda now steps aside while a modal is up.

## Gotchas worth keeping

- **A `PanelContainer` takes its minimum size from its child, and a Label's
  minimum width is the width of its text.** `clip_text` does not change that.
  Labels that must not drive a layout go in a plain `Control`, not a
  container.
- **A nine-patch margin must sit just past the art's corner radius**, and
  the total of the top and bottom margins must be **less than the widget's
  height** or there is no stretchable middle left.
- **`Vfx` is a global class name**, so `const Vfx = preload(...)` in another
  script collides with it and fails to parse. The alias is
  `const VfxLib = preload("res://gameplay/vfx.gd")`.
- **A `Label`'s `autowrap_mode` defaults to `WORD_SMART`** in
  `RingTheme.label()`. Inside an HBox that turns a heading into a
  one-letter-per-line column.
- **`global_position` on a `Control` is not a thing.** `Control` has
  `get_global_transform()`; only `Node2D` has `to_global` / `to_local`.

## Debug markers

`Vfx.DEBUG_MARKERS` (a `const`, **false** in a normal build) draws a marker
at every spawn point: a ring at the emitter centre, a cross at the
parent-local position and an arrow for the intended direction. The overlay is
`gameplay/vfx_debug_marker.gd`.

## What is still missing

See `docs/asset-gaps.md`. In short: the **wordmark** and the **board ring
arcs** need an artist; the mascot needs a dedicated celebrating pose. The
card, buttons, board, icons and particles are good enough to ship.
