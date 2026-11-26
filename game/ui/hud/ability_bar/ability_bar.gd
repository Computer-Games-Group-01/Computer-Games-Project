class_name AbilityBar
extends SlotBar
## Bar of the abilities that are always available: one slot per field type.
##
## Shows how many fields of each type are left. The selected ability is the pressed button of
## a ButtonGroup. A click selects the ability; the HUD passes [signal SlotBar.slot_pressed] on
## to the PlayerController, and the bar follows [signal Events.field_type_changed].

var _types: Array[FieldType] = []
var _selected: FieldType
## Fields left per type. -1 = unlimited.
var _fields_left: Dictionary[FieldType, int] = {}
## Made here, not in the slot scene: a ButtonGroup is local to its scene,
## so every slot instance would get a group of its own.
var _group := ButtonGroup.new()


func _ready() -> void:
	Events.abilities_changed.connect(_on_abilities_changed)
	Events.field_type_changed.connect(_on_field_type_changed)
	Events.field_count_changed.connect(_on_field_count_changed)


func _slot_action(index: int) -> StringName:
	return InputActions.ability_slot(index)


func _on_abilities_changed(types: Array[FieldType]) -> void:
	_types = types
	_build(types.size())
	for i in types.size():
		_slots[i].toggle_mode = true
		_slots[i].button_group = _group
		_show(i)


func _on_field_type_changed(type: FieldType) -> void:
	_selected = type
	for i in _slots.size():
		_slots[i].set_pressed_no_signal(_types[i] == type)


func _on_field_count_changed(type: FieldType, remaining: int, _maximum: int) -> void:
	_fields_left[type] = remaining
	var i := _types.find(type)
	if _slot(i) != null:
		_show(i)


func _show(i: int) -> void:
	var type := _types[i]
	var left: int = _fields_left.get(type, -1)
	_slots[i].show_item(type, "" if left < 0 else str(left), left == 0)
	_slots[i].set_pressed_no_signal(type == _selected)
