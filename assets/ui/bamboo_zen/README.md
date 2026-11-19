# RotateRings — One Bamboo UI Asset Pack

Use the exact assets in `background/`, `header/`, `hud/`, and `boosters/` as the active UI kit. The `optional/` folder contains **alternatives**. Do not render all alternatives together.

The single header PNG is **one continuous natural bamboo pole**, with four natural nodes/segments that serve the Level, Steps, Coins, and Settings zones. Treat this as **one TextureRect**. Overlay separate Godot Control nodes for dynamic values and click targets. Do NOT cut the header into different cards or place floating panels over it.

Background is intentionally empty (no baked header, buttons, puzzle rings or panda). `optional/background_with_panda.png` is a variant with a *baked-in panda*; do not add a second panda if this variant is chosen.

Asset status: generated artwork with cropped transparent alpha sprites; inspect import edges for residual halos. Buttons and text shown during gameplay must be actual Godot UI nodes. These are not yet implemented or runtime-tested.

Proposed responsive layout on a 720 x 1280 reference: top HUD inset about 16 px from sides, around y=42 to 180 (adjust for system safe area), while puzzle gameplay stays unobstructed. Header zone center fractions (across header width): Level 0.135, Moves 0.410, Coins 0.690, Settings 0.911. Fine tune by viewing actual source pixels and real runtime. Coin icon and plus icon overlay inside the third segment. The rightmost settings segment is clickable with a transparent Button. Hit targets ~44dp or larger. Booster row anchored above bottom safe area.

Use existing Godot game systems for labels and data bindings; never hardcode level=1, steps=0, coins=775. Use live game state. Existing puzzle rules/cuffs/motion and save data must be preserved. 
