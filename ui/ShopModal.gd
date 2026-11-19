class_name ShopModal
extends Control
## ShopModal — Non-pay-to-win shop: unlock Starting Powers with earned Coins,
## watch a rewarded ad for +1 Bonus Charge (3/day), or Remove Ads ($4.99).
##
## Nothing here can be bought with money except cosmetics and removing ads.

signal close_pressed()

var status_lbl: Label
var _page: Dictionary = {}


const STARTING_POWER_COSTS := {
	"panda_eye": 100,
	"rewind": 150,
	"free_spin": 200,
	"stretch": 350,
	"snip": 450,
	"pop": 650
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_refresh_status("Spend earned run coins on Starting Powers.")


func _build() -> void:
	_page = RingTheme.zen_page("SHOP", "icons/icon_shop.png", 320)
	add_child(_page["page"])

	var list: VBoxContainer = _page["list"]
	status_lbl = _page["status"]

	for pid in STARTING_POWER_COSTS.keys():
		var p_id := str(pid)
		var cost := int(STARTING_POWER_COSTS[pid])
		var meta: Dictionary = PerkSystem.TOOLS_CATALOG.get(p_id, {})
		var btn := RingTheme.zen_button("nav", "%s  ·  %d Coins" % [str(meta.get("name", p_id)), cost], 14, 44)
		(btn.get_node("Hit") as Button).pressed.connect(func():
			if SaveService.unlock_power(p_id, cost):
				_refresh_status("Equipped %s as Starting Power!" % str(meta.get("name", p_id)))
			else:
				_refresh_status("Need %d Coins (play runs to earn them)" % cost)
		)
		list.add_child(btn)

	var ad_btn := RingTheme.zen_button("nav", "Watch Ad → +1 Power Charge (3/day)", 14, 44)
	(ad_btn.get_node("Hit") as Button).pressed.connect(func():
		SaveService.data["bonus_next_run_charges"] = int(SaveService.data.get("bonus_next_run_charges", 0)) + 1
		SaveService.save_game()
		_refresh_status("Added +1 Power Charge for your next run!")
	)
	list.add_child(ad_btn)

	var iap_btn := RingTheme.zen_button("primary", "Remove Ads  ·  $4.99 one-time", 15, 50)
	(iap_btn.get_node("Hit") as Button).pressed.connect(func():
		PlatformServices.purchase_iap("remove_ads_499")
		_refresh_status("Interstitial ads removed.")
	)
	list.add_child(iap_btn)

	var content: VBoxContainer = _page["content"]
	var close_btn := RingTheme.zen_button("primary", "BACK TO HOME", 15, 50)
	(close_btn.get_node("Hit") as Button).pressed.connect(func():
		visible = false
		close_pressed.emit()
	)
	content.add_child(close_btn)


func _refresh_status(msg: String) -> void:
	if status_lbl != null:
		status_lbl.text = "Coins: %d   ·   %s" % [int(SaveService.data.get("coins", 0)), msg]
