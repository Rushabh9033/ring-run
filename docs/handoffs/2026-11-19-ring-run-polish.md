# Handoff — Ring Run polish pass, 19 Nov 2026

## Where this stands

Both copies are in sync and green:

- `/Users/radhikamac/Desktop/RingRun` — the working build
- `/Users/radhikamac/Desktop/RingRun 2` — the same build, and the folder
  Godot has open

`./run_headless.sh tests/test_run.gd` → `RUN_OK`
`./run_headless.sh tests/test_ui.gd` → `UI_OK`
The game boots clean.

## What the polish pass added

**Rendering.** The rings were flat outlines. They are now layered like the
Rotate Rings ones: drop shadow, dark contour rim, lacquered body, golden node
bands, specular sheen, wooden end caps at the gap edges.

**Effects.** A released ring falls away, shatters into bamboo shards and pops
a ring of stars, with a praise word floating up. Confetti on a clear, coins
flying to the counter, a spark when a ring is grabbed, a pulse in the danger
zone.

**Motion.** Rings drop in biggest-first when a puzzle loads. The release gate
breathes. The board slides in from the right, modals pop in. The panda is a
real sprite now with idle, celebrating, panicking and boss moods.

**Home screen.** It was a title card and a lot of empty sand. Now: an
illustrated wordmark, a live three-ring puzzle turning in the garden in the
board's own colours, a coin pill, status cards for depth and streak, and the
run buttons in the lower half.

**Modals.** The parchment card with the thick bamboo-wood border, the bamboo
vine draped over the top, the celebrating panda peeking over it, tool icons in
recessed bamboo wells, rarity and charge chips, and extruded slab buttons with
outlined text.

## Things that will bite the next person

- **A container chain does not re-sort when the window settles.** The board
  HUD and the home screen both collapsed to their minimum width because of
  this, and it looked like a font bug. Anything that must fill the screen is
  anchored now. Containers are only used inside a fixed-size box.
- **The overlays live on their own CanvasLayer.** The board draws its rings as
  Node2D children, and those do not respect a Control's `z_index` - a modal
  on the same canvas was drawn *under* the puzzle.
- **A tween made before a node has a parent never runs.** The ring drop-in
  silently did nothing until the tween was created on the node itself.
- **Headless renders frames as fast as it can.** Waiting on `process_frame` in
  a test or a screenshot script is not waiting for game time - use
  `await create_timer(1.6).timeout`.
- **A `Label` with autowrap inside a squeezed box becomes a one-character
  column.** Use `AUTOWRAP_OFF` plus `clip_text` for single-line labels.
- **An `await` inside a signal handler stalls the caller.** The modal dressing
  is deferred with a timer for that reason.
- **A decoration added to a `Container` gets laid out by it.** The bamboo
  vine and the panda have to be added to a plain `Control`, and positioned
  manually.

## Branding note

This game must not carry Rotate Rings' identity. The wordmark, the ring art
style and the mascot art are shared - the bamboo, the panda and the look are
the art direction - but the **logo** is drawn for Ring Run and the reference
game's logo image is used nowhere.

## Still missing

- Rewind spends its charge without undoing the move.
- One-Way and Locked Ring curses are shown but not enforced.
- Ads, IAP and Game Center need real plugins.
- The puzzle pool is finite; endless play needs runtime generation.
