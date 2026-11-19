# Handoff — Particle / VFX coordinate repair, 19 Nov 2026

## The bug

A cluster of particles appeared in the **top-left corner of the screen, on top
of the Stage panel**, during the puzzle-clear celebration, while a second set
appeared correctly on the rings.

## Root cause

Three effect scripts placed themselves with **`global_position`** but were
handed a coordinate that was **relative to their parent**:

```gdscript
# gameplay/ring_shard_burst.gd, c_arc_star_burst.gd, floating_text.gd
func setup(center_pos: Vector2, ...) -> void:
    global_position = center_pos      # <- global, but fed a local value
```

The rings are concentric, so a ring's position inside `board_root` is the
board's **origin** `(0, 0)`. Writing that into `global_position` therefore put
the shards, the stars and the praise word at **screen `(0, 0)`** — the corner.

Two more instances of the same class of mistake:

| Where | Problem |
|---|---|
| `hammer_animator.gd`, `rocket_animator.gd` | The Snip and Pop effects were told to spawn at a hardcoded `Vector2.ZERO` instead of at the ring they act on |
| `GameplayScreen._spawn_floating_text` | Took a `global_pt` and used it as a local `position` |
| `GameplayScreen` danger pulse | Mixed `board_root.position` (parent space) with a board-local point — a doubled offset |
| `PerkChoiceModal._fly_coins` | The coin flight used **hardcoded pixels** for its destination instead of the real currency counter |

## The fix

**`gameplay/vfx.gd` — one place where an effect is allowed to be placed.**

The rule is now single and enforced:

> The caller always passes a **global (canvas) position**.
> Vfx converts it into the parent's local space.

```gdscript
VfxLib.spawn_at(parent, global_pos, effect)   # add + place
VfxLib.place_at_self(node, global_pos)        # place an existing node
VfxLib.to_parent_local(parent, global_pos)    # global -> parent local
VfxLib.to_global(parent, local_pos)           # parent local -> global
VfxLib.global_centre(node)                    # a Control's rect centre or a Node2D's position
```

Every effect places itself with `VfxLib.place_at_self(self, global_pos)`, so
it works whether or not the spawner also placed it. Calling it twice with the
same point is harmless.

**Call sites updated:**

- `RingReleaseFX.play / pickup_spark / danger_pulse` now take a **global**
  position; `GameplayScreen` passes `ring_nodes[i].global_position`.
- `ConfettiBurst.fire` takes a global position and spawns through Vfx.
- `GameplayScreen` confetti now fires from `VfxLib.global_centre(board_root)`
  — the solved puzzle's centre.
- Snip and Pop spawn at `ring_nodes[ring_idx].position` — the ring they act on.
- `_spawn_floating_text` converts the global point into the screen's local
  space before positioning the label.
- The danger pulse uses `VfxLib.to_global(board_root, ...)`.

## Coin rewards

`PerkChoiceModal.present_cards` now takes a measured `coin_origin` and
`coin_target`. `MainController` supplies them from the live layout:

```gdscript
var origin: Vector2 = VfxLib.global_centre(gameplay_screen.board_root)
var target: Vector2 = gameplay_screen.get_coin_counter_global_pos()
```

`get_coin_counter_global_pos()` reads the coin label's actual global rect —
no hardcoded pixels. The coins keep the existing curved Bezier flight, and the
counter still pulses on arrival.

## Particle quality

- **Confetti**: the chunk texture was a 48px hexagon, which rendered as big
  coloured polygons covering the puzzle. It is now a 20px torn-paper shape,
  with fewer chunks, a wider spread, a per-colour sideways drift so the burst
  never travels as one column, damping for natural deceleration, a shrink
  curve and an alpha fade.
- **Sparks**: radial with per-spark speed variation, drag so they slow down, a
  short trail, and a fade.

## Debug markers

`Vfx.DEBUG_MARKERS` (a `const`, **false** in a normal build) draws a marker
at every spawn point: a ring at the emitter centre, a cross at the parent-local
position and an arrow for the intended direction. `gameplay/vfx_debug_marker.gd`
is the overlay. Flip the constant to compare the markers against the visible
particles.

## Verified

`tests/test_vfx.gd` → **VFX_OK**. It asserts that:

- a release burst lands **on the ring** (within 60px),
- **no effect lands on the Stage panel** or at the screen origin,
- the global → local → global round trip does not drift,
- the puzzle-clear confetti comes from the board's centre,
- effects **clean themselves up** (none leak after 3.2s).

Also green: `HOME_OK`, `RUN_OK`, `UI_OK`, `RESPONSIVE_OK`. Boot clean.

## Note

`Vfx` is a global class name, so a `const Vfx = preload(...)` in another
script **collides with it** and fails to parse. The alias used everywhere is
`const VfxLib = preload("res://gameplay/vfx.gd")`.
