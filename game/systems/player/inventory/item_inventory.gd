class_name ItemInventory
extends Node
## The items the player has collected, in a fixed number of slots.
##
## Stores items and runs the time of their effects. The PlayerController decides when items are
## added or used, the item bar shows them, and effects listen to [signal Events.item_activated]
## and [signal Events.item_expired]. Every change is reported through [Events], so nobody needs
## to read this node.

## Number of item slots. Takes effect at the next level start.
@export_range(0, 9, 1, "or_greater") var capacity: int = 3


## One item slot.
class ItemStack:
	## null = the slot is free. Stays set while an effect runs, even if no item is left.
	var type: ItemType
	var amount: int = 0
	## Runs while the effect of the last used item lasts. null = no effect is running.
	var lifetime: Lifetime


var _slots: Array[ItemStack] = []


## Starts a new level: ends running effects, creates [member capacity] free slots
## and reports them.
func reset() -> void:
	for i in _slots.size():
		_end_effect(i)
	_slots.clear()
	for i in capacity:
		_slots.append(ItemStack.new())
	Events.item_capacity_changed.emit(capacity)
	for i in capacity:
		_report(i)


## Adds [param amount] items of [param type]: first onto slots that already hold this type,
## then into free slots. Returns how many did not fit, 0 = all were added.
func add(type: ItemType, amount: int = 1) -> int:
	if type == null or amount <= 0:
		return 0
	var left := _fill(type, amount, false)
	return _fill(type, left, true)


## Uses one item from [param slot]. Returns false if the slot is empty or its effect still runs.
## An instant item ([member ItemType.duration] 0) is used up at once. A timed item keeps
## its slot until the effect has ended, so the slot works as a cooldown.
func use(slot: int) -> bool:
	if slot < 0 or slot >= _slots.size():
		return false
	var stack := _slots[slot]
	if stack.type == null or stack.amount <= 0 or stack.lifetime != null:
		return false
	var type := stack.type
	stack.amount -= 1
	if type.duration > 0.0:
		stack.lifetime = _start_lifetime(slot, type.duration)
	elif stack.amount == 0:
		stack.type = null
	Events.item_used.emit(type.id)
	Events.item_activated.emit(slot, type, stack.lifetime)
	_report(slot)
	return true


## Puts up to [param amount] items into matching slots and returns how many are left.
## [param into_free] off = slots that already hold [param type], on = free slots.
func _fill(type: ItemType, amount: int, into_free: bool) -> int:
	for i in _slots.size():
		if amount <= 0:
			break
		var stack := _slots[i]
		var fits: bool = (stack.type == null) if into_free else (stack.type == type)
		var moved := mini(amount, type.max_stack - stack.amount)
		if not fits or moved <= 0:
			continue
		stack.type = type
		stack.amount += moved
		amount -= moved
		_report(i)
	return amount


func _start_lifetime(slot: int, duration: float) -> Lifetime:
	var lifetime := Lifetime.new()
	lifetime.wait_time = duration
	lifetime.timeout.connect(_on_lifetime_timeout.bind(slot))
	add_child(lifetime)  # Lifetime starts by itself when it enters the tree.
	return lifetime


func _on_lifetime_timeout(slot: int) -> void:
	if slot >= _slots.size():
		return
	var stack := _slots[slot]
	_end_effect(slot)
	if stack.amount <= 0:
		stack.type = null
	_report(slot)


## Ends the effect in [param slot], if one runs, and reports [signal Events.item_expired].
func _end_effect(slot: int) -> void:
	var stack := _slots[slot]
	if stack.lifetime == null:
		return
	# stop() first: a stopped Timer does not send timeout any more.
	stack.lifetime.stop()
	stack.lifetime.queue_free()
	stack.lifetime = null
	Events.item_expired.emit(slot, stack.type)


func _report(slot: int) -> void:
	var stack := _slots[slot]
	Events.item_slot_changed.emit(slot, stack.type, stack.amount)
