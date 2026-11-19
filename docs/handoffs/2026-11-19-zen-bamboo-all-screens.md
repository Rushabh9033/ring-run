# Handoff — Zen Bamboo across every screen, 19 Nov 2026

## Where this stands

All eight screens are on the Zen Bamboo pack now: home, board, perk choice, run
over, collection, shop, daily run, settings.

`test_home.gd` → `HOME_OK`, `test_run.gd` → `RUN_OK`, `test_ui.gd` → `UI_OK`.
The game boots clean. `tests/screenshot_all.gd` captures all eight screens in
one go, which is how the layout bugs below were found.

## The shared page layout

`RingTheme.zen_page(title, icon_path, scroll_height)` builds every full page:
the bamboo background, a centred gold card, a title row with the real icon, a
status line, a scrolling body and the action buttons below it. `RingTheme.gold_panel()`
and `RingTheme.zen_button(kind, text)` are the pieces it is made of.

The four rules that made the difference:

- **The card hugs its content.** Nothing in the chain may expand vertically:
  the panel, the padding and the content VBox all use `SIZE_SHRINK_CENTER`,
  and the scroll area has a fixed height instead of expanding.
- **The card has a minimum width** (420px). Without one it collapses to the
  width of its narrowest child and the page becomes a one-word column.
- **The card is a NinePatchRect.** A stretched TextureRect distorts the gold
  rim; a nine-patch keeps the corners and stretches only the middle.
- **The card is inside a CenterContainer**, not a MarginContainer. A
  MarginContainer always stretches its child, so the card filled the screen and
  the content floated in the middle of it.

## Traps in this codebase

- **A Label with autowrap inside an HBox becomes a one-character column.**
  Every header label sets `autowrap_mode = TextServer.AUTOWRAP_OFF`.
- **Godot 4.7 removed `Button.texture_normal`.** A skinned button is a
  NinePatchRect with a transparent Button over it; the pressed state swaps the
  skin.
- **Do not sync this project's `ui/` into Rotate Rings.** That project has its
  own `scenes/home/HomeScreen.gd` and `scenes/gameplay/GameplayScreen.gd`, and
  the class names collide.

## Still missing

- Rewind spends its charge without undoing the move.
- One-Way and Locked Ring curses are shown but not enforced.
- Ads, IAP and Game Center need real plugins.
- The puzzle pool is finite; endless play needs runtime generation.
