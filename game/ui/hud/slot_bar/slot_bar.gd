class_name SlotBar
extends HBoxContainer
## Base class of the ability bar and the item bar: builds the slots and reports clicks.
##
## Subclasses decide how many slots there are and what they show; they only listen to
## [Events]. Where a bar sits is set in the HUD scene and how it looks in the HUD theme,
## so the bars can be moved apart, rearranged or reskinned without code changes.

## The player clicked slot [param index] of this bar. 0 = first slot.
signal slot_pressed(index: int)

## Scene of one slot. Its root must be a BarSlot.
@export var slot_scene: PackedScene

var _slots: Array[BarSlot] = []


## Input action of slot [param _index], used for its key hint. Subclasses override this.
func _slot_action(_index: int) -> StringName:
	return &""


## Replaces all slots with [param count] new ones.
func _build(count: int) -> void:
	for slot: BarSlot in _slots:
		remove_child(slot)
		slot.queue_free()
	_slots.clear()
	for i in count:
		var slot := slot_scene.instantiate() as BarSlot
		add_child(slot)
		slot.set_key_hint(InputActions.key_label(_slot_action(i)))
		slot.pressed.connect(slot_pressed.emit.bind(i))
		_slots.append(slot)


## Slot [param index]. null = there is none.
func _slot(index: int) -> BarSlot:
	return _slots[index] if index >= 0 and index < _slots.size() else null
