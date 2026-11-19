# Changelog

All notable changes to Ring Run are recorded here.

## [Unreleased]

### Added
- `ui/RingTheme.gd` — the shared style kit: bamboo background, banner header
  with stage badge / budget pill / coin pill, bamboo booster cards, card
  styles and chunky cream-and-green buttons.
- Bamboo garden background behind the board and every menu.
- Bamboo banner header on the board: stage badge on the left, the move budget
  in the middle, coins on the right.
- Bamboo booster cards along the bottom of the board, with the tool icon and a
  charge badge, replacing the plain text buttons.
- Perk cards now show the real tool icon, the rarity badge and a
  rarity-coloured border.
- `tests/test_run.gd` and `tests/test_ui.gd` — headless proofs of the run loop
  and of every screen building cleanly.

### Changed
- All screens rebuilt on the Rotate Rings look: cream surfaces, warm ink,
  bamboo background, tactile buttons.
- The board is centred and scaled to the space it actually gets, and is
  recomputed whenever the layout resizes.
- Modals are centred on their content instead of stretching to the screen.
- The stage banner no longer covers the header.

### Fixed
- **The board HUD was laid out with a container chain** (`MarginContainer` →
  `VBoxContainer`). A container only re-sorts when its parent re-sorts, and the
  gameplay screen changes size when the window settles, so the whole HUD stayed
  at its minimum width: the labels collapsed to one pixel wide and their text
  spilled across the screen. The HUD is now anchored to the screen directly.
- **The stage and boss banners sat on top of the hint row**, so the mechanic
  hint and the banner text were printed on top of each other. Both banners now
  sit below the header, and only one of them shows at a time.
- **Banners floated over the menus.** A stage banner left over from a run used
  to stay on screen over the home screen and clip the tagline. Screen changes
  now go through one helper that puts every other screen away.
- **The hint and par labels were unreadable** over the dark bamboo. They now
  sit on translucent cream pills.
- **The power card title was clipped** by the bamboo frame art, and an empty
  slot showed a text label instead of a padlock.

### Added
- **Bamboo tube rendering for the rings.** The rings were flat outlines; they
  are now layered like the Rotate Rings ones - drop shadow, dark contour rim,
  lacquered body, golden node bands, embossed crests, specular sheen and a
  wooden end cap at each gap edge.
- **Ring release effects.** A released ring falls away, shatters into bamboo
  shards and pops a ring of stars, with a praise word floating up on top.
- **Ring drop-in.** Rings fall in when a puzzle loads, biggest first.
- **Animated release gate.** The target the player aligns to now breathes.
- **Real panda sprite** with idle, celebrating, panicking and boss moods.
- **Confetti** on a puzzle clear, and coins that fly to the counter.
- **Screen transitions**: the board slides in, modals pop in, overlays fade.
- **A live puzzle diorama on the home screen** - three bamboo rings turning
  in the middle, so the screen is not dead space.
- **A proper Ring Run wordmark.** The Rotate Rings logo art is not used; this
  is a different game and must not carry its branding.
- **Status cards on the home screen**: best depth, streak and coins.
- **Bamboo vine and celebrating panda** draped over the modals.

### Changed
- The home screen is laid out with anchors rather than a container chain, for
  the same reason the board HUD is: a chain does not re-sort when the window
  settles and the layout collapses.
- Modals use the parchment card with the thick bamboo-wood border, and the
  buttons are extruded slabs with outlined text.
- Perk cards show the tool icon in a recessed bamboo well, with the rarity
  and charge as chips on the right.
- The overlays live on their own CanvasLayer. The board draws its rings as
  Node2D children, which do not respect a Control's z_index.

### Added
- **An illustrated "RING RUN" wordmark** (`art/home/ring_run_logo.png`): a
  bamboo ring, green leaves and the name, drawn for this game. The Rotate
  Rings logo art is not used anywhere - this is a different game and must not
  carry its branding.
- The home screen is now built like the Rotate Rings one: the wordmark up
  top on the bamboo garden, a live colourful puzzle turning in the middle, a
  coin pill in the corner, status cards and the run buttons at the bottom.
- A bamboo button plate for the run button.

### Added
- **The Zen Bamboo UI asset pack** (`assets/ui/ring_run_zen/`): 32 production PNGs
  across `backgrounds/`, `branding/`, `rings/`, `ui/`, `icons/` and `effects/`,
  plus `tools/build_zen_assets.py` which regenerates the whole pack.
- **The home screen rebuilt on the pack**: the garden background, the RING RUN
  logo plaque, the stone board with three independently rotating ring arcs, the
  gold stat panels, the glossy green START RUN button and three nav tabs. Every
  number on it is live text.
- The three ring arcs turn around one fixed centre at the specified speeds:
  outer purple 9s clockwise, middle orange 12s counter-clockwise, inner blue
  7s clockwise. The motion stops when the menu is hidden or the app is
  backgrounded, and resumes where it left off.
- `tests/test_home.gd`: proves the home screen reads live saved state, uses
  every asset it should, centres the rings on one pivot, actually turns them,
  and fires all five actions.

### Changed
- Godot 4.7 removed `Button.texture_normal`, so the skinned buttons are now a
  TextureRect with a transparent Button over it, and the pressed state swaps
  the skin.

### Changed
- **Every screen is now on the Zen Bamboo pack.** The collection, shop, daily
  run and settings screens were still on the old flat style; they are now gold
  parchment cards with the bamboo button skins and the supplied icons.
- The card is a nine-patch, so a tall panel keeps its gold corners and only
  the middle stretches. A stretched texture distorted the rim.
- The card hugs its content and is centred on the screen. It used to fill the
  whole screen with the content floating in the middle of it, which read as a
  big empty slab.
- The card has inner padding, so text no longer sits under the gold rim.
- Every card has a minimum width. Without one it collapsed to the width of its
  narrowest child and the page became a column.

### Fixed
- **The rings were drawn as a flat polyline with circles bolted on the ends**,
  which read as beads stuck to the arcs. They are now filled stadium polygons:
  one outline per layer, traced in a single direction, so the caps continue
  the tube's own shading. Each ring is a dark rim, the lacquered body, a broad
  sheen up and to the left, a tight specular and a darker underside.
- **The stone board drew 26 engraved grooves** and read as a target. It is now
  a smooth sanded disc with a soft rim and a single light across the top.
- **The button skins smeared into a pale stripe.** The gloss band was drawn
  across the nine-patch's stretching region. It now lives in the corner
  patches, and the patch margins match the art's corner radius, so the round
  ends stay round.
- **The stat cards were a gold outline around a translucent panel.** They are
  now solid ivory cards with a controlled gold border and inner padding.
- **The logo was flat and small.** It is now a dimensional jade-and-gold plaque
  with bevelled, shadowed lettering, and it sits in a centred, aspect-locked
  box so it is never squashed.
- **The coin pill covered the logo.** The logo now has a narrow centred box and
  the pill sits clear of it.
- **The board was re-laid out only when the window settled**, so a resized
  viewport kept the old composition. The layout now follows the viewport's
  `size_changed` signal.
- **The rings are now 76% of the screen width on a narrow phone** and capped
  at 86% so a tall phone stays comfortable.

### Fixed
- **Ring-release particles appeared in the top-left corner of the screen.** The
  shard, star and praise-word effects set `global_position` but were handed a
  coordinate relative to their parent. The rings are concentric, so a ring sits
  at the board's origin - which wrote the effects to screen (0, 0), right on
  top of the Stage panel.
- The Snip and Pop effects spawned at a hardcoded `Vector2.ZERO` instead of at
  the ring they act on.
- The floating praise text used a global point as a local position.
- The danger-zone pulse mixed two coordinate spaces and was doubly offset.
- The reward coins flew to **hardcoded pixels** instead of the real currency
  counter. They now fly from the board the reward was won on to the measured
  position of the coin label in the HUD.

### Added
- **`gameplay/vfx.gd`** - the one place an effect is allowed to be placed. The
  caller passes a global position; Vfx converts it into the parent's local
  space. Every effect now goes through it.
- `tests/test_vfx.gd` - asserts that effects land on their ring, that nothing
  lands on the Stage panel or at the screen origin, that the coordinate
  round trip does not drift, and that effects clean themselves up.
- Development-only debug markers (`Vfx.DEBUG_MARKERS`, off by default) that
  show the emitter centre, the parent-local spawn position and the intended
  direction.

### Changed
- Confetti chunks were 48px hexagons that covered the puzzle; they are now
  small torn-paper pieces that fade and shrink, with a sideways drift so the
  burst never travels as one column.
- Sparks now slow down as they fly and leave a short trail.

### Fixed
- **Touching a square, oval or triangle ring grabbed the wrong ring.** The
  hit test compared the distance from the board centre with the ring's
  radius, which is only right for a circle. It now follows the same outline
  the ring is drawn from, and the gap is open, so a touch in the exit
  channel does not grab a ring.
- **Two different board-scale calculations were fighting**, so the board
  ended up a different size depending on which ran last. There is now one,
  applied after the new ring specs are known.
- **Every connector pin was drawn as an open cream pin**, which falsely showed
  an unlock. The pin is now drawn closed while the ring is still waiting on
  another one.
- **The ring end caps were two stacked discs**, which read as beads on the
  arc. They are now one cap filled with the tube's own colour.
- **The grab sound and haptic played twice**, from both the drag controller
  and the gameplay screen. The duplicate is gone and the near-alignment
  chime is edge-triggered.
- **The button skins were squashed.** A nine-patch cannot scale a pill's
  rounded caps, so a 56px button built from a 112px texture with 42px margins
  had 84px of vertical patch in a 56px box, and its gloss smeared into a
  stripe. Buttons, the coin pill, the stat cards and the modal card are drawn
  with styleboxes now, which are correct at any size.
- **The gameplay HUD row overflowed the screen.** The hint and par labels
  were inside PanelContainers, and a container takes its minimum size from
  its child - a Label's minimum width is the width of its text. The row is a
  flow now and the labels are not in containers.
- **The modal widths were fixed pixel values** (500px for the perk modal,
  wider than a small phone). They are viewport-aware now.
- **Only the modal card animates.** The full-screen scrim fades on its own,
  so the celebration behind the modal is not hidden by a panel that is also
  fading. The panda sits on the card's corner, and the board's panda steps
  aside while a modal is up.
- **A screen sliding in fought the anchor system.** The slide wrote
  `position.x` on a full-rect anchored Control, which left the screen
  narrower than the screen and shifted if the tween was interrupted. It
  slides the offsets now.
- **The settings toggles rendered as empty slabs**, because a button only
  got a caption when it was built with text.

### Added
- `tests/test_layout.gd` - measures real geometry: nothing overflows, the
  board does not collide with the header or the power bar, every button is a
  usable tap target and no text is clipped. It checks 31 buttons across all
  eight screens.
- `tests/test_responsive.gd` now covers every screen, not just the home
  screen, on a narrow phone, a standard portrait phone, a tall phone and a
  tablet.

### Known issues
- Rewind spends its charge without undoing the move.
- One-Way and Locked Ring curses are shown but not enforced.
- The puzzle pool is finite; endless play needs runtime generation.
