# Handoff — Ring Run UI rebuild, 18 Nov 2026

## Where this stands

`/Users/radhikamac/Desktop/RingRun` is the Ring Run prototype with the whole
UI rebuilt in the Rotate Rings visual language. Both headless suites pass
(`RUN_OK`, `UI_OK`).

## The correction

The first attempt at this task replaced the puzzle model with the real Rotate
Rings connector engine and wrote a new generator to feed it. That was the wrong
call: the Ring Run 2 prototype's own board model (nested rings, a release gate,
eight-step rotation, the pre-verified puzzle pool) is the game that was asked
for. All of that code is back in place, untouched:

- `gameplay/puzzle_rules.gd`, `ring_piece_2d.gd`, `drag_rotation_controller.gd`
- `data/puzzle_pool.json` (1 MB, solver-verified) and `data/campaign_board.gd`
- `gameplay/run_controller.gd`, `gameplay/perk_system.gd`
- `app/save_service.gd`, `app/audio_service.gd`, `app/platform_services.gd`

What is new is the UI layer.

## What was built

`ui/RingTheme.gd` is the whole style system in one file:

- `bamboo_background()` — the zen garden plus a warm scrim so text stays legible
- `build_header()` — the bamboo banner: stage badge, budget pill, coin pill
- `power_card()` — a bamboo booster card with tool icon, lock and charge badge
- `card_style()`, `label()`, `button()`, `perk_pill()`, `rarity_color()`

Every screen was rewritten on top of it: home, board, perk choice, run over,
shrine, daily run, collection, shop, settings, stage and boss banners.

## The bug that cost the most time

The gameplay HUD was built as `MarginContainer → VBoxContainer → rows`. In
Godot a container only re-sorts when its parent re-sorts, and the gameplay
screen changes size when the window settles - so the VBox kept its **minimum**
width (490px) instead of filling the screen. Every label inside collapsed to
one pixel wide and its text spilled out across the board. It looked like a
font problem ("the alphabet is broken") and it was not: nothing was wrong with
the font, the labels simply had no room.

**The HUD is anchored to the screen now, not stacked in containers.** Anything
that must fill the screen should be anchored. Containers are fine for rows
inside a fixed-size box.

Two more that showed up in the same pass:

- **Overlays must hide each other.** The stage banner and the boss banner
  were both drawn for one puzzle, and both sat exactly where the hint row was.
- **A label that autowraps inside a squeezed box turns into a one-character
  column** and blows the layout up. Use `AUTOWRAP_OFF` plus `clip_text` for
  single-line labels.

## Things that will bite the next person

- **`UITheme` (the old prototype theme) and `RingTheme` both exist.** The old
  one is still used by `ui/UITheme.gd` and a couple of scripts; the new one is
  the style system. Do not mix them in new code.
- **A `Control` inside a `VBoxContainer` gets freed by a "free all children"
  sweep.** `HomeScreen.build_ui()` did that and it silently deleted the
  background it had just added. The background is now re-added at the end of
  the build and moved to the back with `move_child`.
- **A `Label` with `AUTOWRAP_WORD_SMART` inside a squeezed HBox turns into a
  one-character-per-line column** and blows the layout up. The perk card
  rarity tag did exactly this; fixed with `AUTOWRAP_OFF` plus a minimum width.
- **Overlays must sit above the board.** The board draws its rings at
  `z_index` 2 and up, so every overlay is pushed to `z_index = 100` in
  `MainController`.
- **A stale `.godot/global_script_class_cache.cfg` shadows autoloads.** If a
  script once had `class_name SaveService` and then lost it, every
  `SaveService.data` fails to parse. Delete the cache and re-run `--import`.
- **Autoloads are not global identifiers in `--script` mode.** Tests must use
  `root.get_node("/root/RunController")`.
- **A test that returns early without `quit()` hangs forever.** `run_headless.sh`
  has a timeout for exactly this.

## Next steps, in the order they are worth doing

1. **Rewind needs a board undo stack.** The charge is spent and nothing
   happens.
2. **Enforce the One-Way and Locked Ring curses.** One guard in the board
   controller each.
3. **Endless puzzles.** The pool is finite. Making it endless means generating
   at runtime, which needs the solver taught the eight-step model first.
4. **Ads / Game Center / IAP plugins.** `PlatformServices` already has the call
   sites and safe fallbacks.
5. **Playtest the numbers.** Budget 30, cap 45, refill 120/100/90/80%, drop
   odds 70/25/5 are the design doc's starting values, not tuned ones.

## Running things

```bash
cd /Users/radhikamac/Desktop/RingRun
/Applications/Godot.app/Contents/MacOS/Godot --path .        # play
./run_headless.sh tests/test_run.gd                         # run loop
./run_headless.sh tests/test_ui.gd                          # every screen
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/screenshot.gd
```
