# Handoff — Zen Bamboo home screen, 19 Nov 2026

## Where this stands

`/Users/radhikamac/Desktop/RingRun 2` is the live project (the folder Godot
has open). `/Users/radhikamac/Desktop/RotateRings` is the reference game, and
`/Users/radhikamac/Desktop/RotateRings` also holds a copy of the build.

`test_home.gd` → `HOME_OK`, `test_run.gd` → `RUN_OK`, `test_ui.gd` → `UI_OK`.
The game boots clean.

## The asset pack

`assets/ui/ring_run_zen/` holds the 32 PNGs, in the folder layout the design
asked for: `backgrounds/`, `branding/`, `rings/`, `ui/`, `icons/`, `effects/`.

**They are generated, not hand-drawn.** `tools/build_zen_assets.py` draws every
one of them with PIL, using the same chunky LilitaOne font as the rest of the
game and a jade / gold / ivory palette. Re-run it to regenerate the pack:

```bash
python3 tools/build_zen_assets.py
```

The `bamboo_garden_menu.png` background is the Rotate Rings zen garden with a
shade pass on top; `bamboo_garden_clean.png` is the same garden unshaded.

**If the real pack arrives**, drop it into `assets/ui/ring_run_zen/` with the
same filenames and the code needs no change - it references paths, not pixels.

## The ring assembly

The three arcs are separate 1024x1024 canvases with the same centre and the
same displayed size, so they nest and turn as one assembly. The radii differ
inside the canvas (purple 0.415, orange 0.325, blue 0.235) - that is what makes
them nest rather than overlap.

Rotation is constant angular velocity, not frame-stepped:
outer purple 9s clockwise, middle orange 12s counter-clockwise, inner blue 7s
clockwise. The motion pauses on `NOTIFICATION_APPLICATION_PAUSED` and when the
menu is hidden, and resumes from the same angle.

These are decoration. They are TextureRects on their own layer, they never
touch the puzzle state, and the layer ignores input so it cannot steal a tap.

## Things that will bite the next person

- **Godot 4.7 removed `Button.texture_normal`.** A skinned button is a
  TextureRect with a transparent Button over it; the pressed state swaps the
  skin texture.
- **A TextureRect child of a Control does not fill it** unless it is anchored
  to full rect. Every skin in this screen does that.
- **A Container re-sorts its children when its own size changes.** The nav
  captions are positioned against the laid-out row, so they are placed in a
  second pass after a frame, not during the first layout.
- **A PanelContainer with an empty stylebox shows nothing.** The stat panels
  and the coin pill are PanelContainers with a TextureRect skin behind their
  content.
- **Do not sync this project's `ui/` into Rotate Rings.** That project has
  its own `scenes/home/HomeScreen.gd` and `scenes/gameplay/GameplayScreen.gd`,
  and the class names collide.
- **The disk was full** while the asset pack was being sent, which is why it
  never arrived and had to be rebuilt from the reference sheet. There is now
  space, but check `df -h` before a big import.

## Still missing

- Rewind spends its charge without undoing the move.
- One-Way and Locked Ring curses are shown but not enforced.
- Ads, IAP and Game Center need real plugins.
- The puzzle pool is finite; endless play needs runtime generation.
