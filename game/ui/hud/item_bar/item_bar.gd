class_name ItemBar
extends SlotBar
## Bar of the collected items: one slot per slot of the [ItemInventory].
##
## Shows icon, amount and the remaining duration of a running effect. Empty slots and slots
## with a running effect are disabled. A click uses the item; the HUD passes
## [signal SlotBar.slot_pressed] on to the PlayerController.


func _ready() -> void:
	Events.item_capacity_changed.connect(_build)
	Events.item_slot_changed.connect(_on_item_slot_changed)
	Events.item_activated.connect(_on_item_activated)
	Events.item_expired.connect(_on_item_expired)


func _slot_action(index: int) -> StringName:
	return InputActions.item_slot(index)


func _on_item_slot_changed(slot: int, type: ItemType, amount: int) -> void:
	var view := _slot(slot)
	if view == null:
		return
	view.show_item(type, str(amount) if amount > 1 else "")
	view.disabled = type == null or view.is_cooling_down()


func _on_item_activated(slot: int, _type: ItemType, lifetime: Lifetime) -> void:
	var view := _slot(slot)
	if view != null and lifetime != null:
		view.start_cooldown(lifetime)
		view.disabled = true


## [signal Events.item_slot_changed] follows and enables the slot again if items are left.
func _on_item_expired(slot: int, _type: ItemType) -> void:
	var view := _slot(slot)
	if view != null:
		view.stop_cooldown()
