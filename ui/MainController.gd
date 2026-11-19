extends Control
## MainController — Root scene orchestrator connecting GameplayScreen, HomeScreen,
## PerkChoiceModal, ShrineModal, RunOverScreen, Stage/Boss banners, and sub-screens.

var home_screen: HomeScreen
var gameplay_screen: GameplayScreen
var perk_modal: PerkChoiceModal
var stage_banner: StageIntroBanner
var boss_banner: BossCurseBanner
var shrine_modal: ShrineModal
var run_over_screen: RunOverScreen
var daily_screen: DailyRunScreen
var collection_screen: CollectionScreen
var shop_modal: ShopModal
var settings_modal: SettingsPauseModal
var last_cleared_was_boss: bool = false
var overlay_layer: CanvasLayer = null

## Show one screen and put the rest away, banners included - a stage banner
## left over from a run must never float over the home screen.
func _show_screen(target: Control) -> void:
	for node in [home_screen, gameplay_screen, daily_screen, collection_screen,
			perk_modal, shrine_modal, run_over_screen, shop_modal, settings_modal,
			stage_banner, boss_banner]:
		if node == null:
			continue
		node.visible = (node == target)
	if target == gameplay_screen:
		# The board slides in from the right so the handover reads as movement.
		RingTheme.slide_in(gameplay_screen, true, 70.0)
	elif target == home_screen:
		RingTheme.slide_in(home_screen, false, 60.0)
	elif target != null:
		RingTheme.fade_in(target, 0.16)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Warm cream background fill across the entire viewport
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = RingTheme.CREAM
	add_child(bg)

	home_screen = HomeScreen.new()
	gameplay_screen = GameplayScreen.new()
	perk_modal = PerkChoiceModal.new()
	stage_banner = StageIntroBanner.new()
	boss_banner = BossCurseBanner.new()
	shrine_modal = ShrineModal.new()
	run_over_screen = RunOverScreen.new()
	daily_screen = DailyRunScreen.new()
	collection_screen = CollectionScreen.new()
	shop_modal = ShopModal.new()
	settings_modal = SettingsPauseModal.new()

	# The screens that live on the board level.
	for node in [home_screen, gameplay_screen, stage_banner, boss_banner]:
		add_child(node)
		node.visible = false

	# The overlays go on their own CanvasLayer. The board draws its rings as
	# Node2D children, and those do not respect a Control's z_index - a modal
	# on the same canvas would be drawn under the puzzle. A separate layer
	# always wins.
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 10
	add_child(overlay_layer)

	for node in [
		perk_modal, shrine_modal, run_over_screen, daily_screen,
		collection_screen, shop_modal, settings_modal
	]:
		overlay_layer.add_child(node)
		node.visible = false

	# Connect Home Screen buttons
	home_screen.start_run_pressed.connect(func(): _start_run(false))
	home_screen.daily_run_pressed.connect(func():
		daily_screen.refresh_view()
		_show_screen(daily_screen)
	)
	home_screen.collection_pressed.connect(func(): _show_screen(collection_screen))
	home_screen.shop_pressed.connect(func(): _show_screen(shop_modal))
	home_screen.settings_pressed.connect(func(): _show_screen(settings_modal))

	# Connect Sub-Screens
	daily_screen.start_daily_pressed.connect(func(): _start_run(true))
	daily_screen.back_pressed.connect(func(): _show_screen(home_screen))
	collection_screen.back_pressed.connect(func(): _show_screen(home_screen))
	shop_modal.close_pressed.connect(func():
		home_screen.refresh_stats()
		_show_screen(home_screen)
	)

	# Connect Gameplay & Modals
	gameplay_screen.pause_requested.connect(func(): settings_modal.visible = true)
	settings_modal.quit_to_home_pressed.connect(func():
		home_screen.refresh_stats()
		_show_screen(home_screen)
	)

	RunController.puzzle_started.connect(_on_puzzle_started)
	RunController.puzzle_cleared.connect(_on_puzzle_cleared)
	RunController.run_over_triggered.connect(_on_run_over)

	perk_modal.card_selected.connect(_on_perk_card_selected)
	shrine_modal.shrine_completed.connect(_on_shrine_completed)

	run_over_screen.revive_pressed.connect(func():
		gameplay_screen.visible = true
	)
	run_over_screen.new_run_pressed.connect(func():
		_start_run(RunController.is_daily_run)
	)
	run_over_screen.home_pressed.connect(func():
		home_screen.refresh_stats()
		_show_screen(home_screen)
	)

	# Reviewer first-60-seconds rule (page 16): on fresh install, launch directly
	# into the 3-puzzle mini-run with the Move Budget gauge and interactive rings
	# immediately visible on screen!
	if not bool(SaveService.data.get("tutorial_completed", false)):
		_start_run(false)
	else:
		_show_screen(home_screen)

func _start_run(daily: bool) -> void:
	_show_screen(gameplay_screen)
	RunController.start_new_run(daily)

func _on_puzzle_started(spec: Dictionary) -> void:
	var p_num := int(spec.get("puzzle_number", 1))
	var stage_num := int(spec.get("stage", 1))
	var stage_name := str(spec.get("stage_name", "Garden"))
	var is_boss := bool(spec.get("is_boss", false))
	var curses: Array = spec.get("curses", [])

	# The board draws its own stage / curse banner, so the overlay banners are
	# no longer needed and would float over the menus.
	stage_banner.visible = false
	boss_banner.visible = false

func _on_puzzle_cleared(summary: Dictionary) -> void:
	last_cleared_was_boss = bool(summary.get("is_boss", false))
	var cards := PerkSystem.draw_cards(RunController.rng, last_cleared_was_boss, false)
	var tw := create_tween()
	tw.tween_interval(0.55)
	tw.tween_callback(func():
		perk_modal.present_cards(cards, summary)
	)

func _on_perk_card_selected(_card: Dictionary) -> void:
	if last_cleared_was_boss and RunController.can_use_shrine():
		shrine_modal.show_shrine()
	else:
		RunController.advance_to_next_puzzle()

func _on_shrine_completed(claimed_cards: Array[Dictionary]) -> void:
	if not claimed_cards.is_empty():
		last_cleared_was_boss = false
		perk_modal.present_cards(claimed_cards, {})
	else:
		RunController.advance_to_next_puzzle()

func _on_run_over(summary: Dictionary) -> void:
	run_over_screen.show_summary(summary)
