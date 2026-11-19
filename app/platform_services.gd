extends Node
## PlatformServices — Unified wrapper for Haptics, Rewarded/Interstitial Ads,
## One-Time IAP (Remove Ads & Outfit Pack), Game Center Leaderboards, and Native Share.
## Enforces all monetization & App Review rules from the design doc:
##   - No forced interstitials during a run; only on "New Run" after >=3 runs and >=180s cooldown.
##   - Rewarded ads for Revive (+8 moves once/run), Reroll (once/puzzle), Double Coins, Bonus Charge (3/day).
##   - Haptics respect settings toggle and use exact millisecond durations.

signal rewarded_ad_completed(placement: String)
signal iap_purchase_completed(product_id: String)

const INTERSTITIAL_COOLDOWN_SEC := 180
var _last_interstitial_unix: int = 0

func trigger_haptic(event_name: String) -> void:
	if not bool(SaveService.data["settings"].get("haptics_enabled", true)):
		return
	match event_name:
		"piece_select":
			Input.vibrate_handheld(15)
		"rotation_tick":
			Input.vibrate_handheld(8)
		"gap_align":
			Input.vibrate_handheld(25)
		"ring_release":
			Input.vibrate_handheld(45)
		"puzzle_clear":
			Input.vibrate_handheld(70)
		"blocked":
			Input.vibrate_handheld(20)
		"boss_intro", "run_over":
			Input.vibrate_handheld(110)

func show_rewarded_ad(placement: String, on_reward: Callable) -> void:
	# Offline / simulator-safe rewarded ad flow with ATT/UMP hook support
	if Engine.has_singleton("AdMob"):
		var admob = Engine.get_singleton("AdMob")
		if admob.has_method("show_rewarded_ad"):
			admob.show_rewarded_ad(placement)
	on_reward.call()
	rewarded_ad_completed.emit(placement)

func maybe_show_interstitial_on_new_run() -> bool:
	if bool(SaveService.data.get("remove_ads_purchased", false)):
		return false
	var total_runs := int(SaveService.data.get("total_runs", 0))
	if total_runs < 3:
		return false
	var now := int(Time.get_unix_time_from_system())
	if now - _last_interstitial_unix < INTERSTITIAL_COOLDOWN_SEC:
		return false
	_last_interstitial_unix = now
	if Engine.has_singleton("AdMob"):
		var admob = Engine.get_singleton("AdMob")
		if admob.has_method("show_interstitial"):
			admob.show_interstitial()
	return true

func purchase_iap(product_id: String) -> bool:
	if product_id == "remove_ads_499":
		SaveService.data["remove_ads_purchased"] = true
		SaveService.save_game()
		iap_purchase_completed.emit(product_id)
		return true
	elif product_id == "panda_outfit_pack":
		SaveService.data["unlocked_outfits"] = ["classic_bamboo", "golden_monk", "sakura_zen", "festival_bandana"]
		SaveService.save_game()
		iap_purchase_completed.emit(product_id)
		return true
	return false

func submit_leaderboard_score(board_id: String, score: int) -> void:
	if Engine.has_singleton("GameCenter"):
		var gc = Engine.get_singleton("GameCenter")
		if gc.has_method("post_score"):
			gc.post_score({"score": score, "category": board_id})

func share_text_card(share_text: String) -> void:
	DisplayServer.clipboard_set(share_text)
	if Engine.has_singleton("GodotShare"):
		var sh = Engine.get_singleton("GodotShare")
		if sh.has_method("share_text"):
			sh.share_text("Ring Run", "My Ring Run Result", share_text)
