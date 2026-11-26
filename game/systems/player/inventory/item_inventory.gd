class_name ItemInventory
extends Node
## The items the player has collected, in a fixed number of slots.
##
## Only stores items. The PlayerController decides when items are added or used, the item bar
## shows them. Every change is reported through [Events], so the HUD never reads this node.

## Number of item slots. Takes effect at the next level start.
@export_range(0, 9, 1, "or_greater") var capacity: int = 3


## One item slot.
class ItemStack:
	## null = the slot is free.
	var type: ItemType
	var amount: int = 0


var _slots: Array[ItemStack] = []


## Starts a new level: creates [member capacity] free slots and reports them.
func reset() -> void:
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


func _report(slot: int) -> void:
	var stack := _slots[slot]
	Events.item_slot_changed.emit(slot, stack.type, stack.amount)
