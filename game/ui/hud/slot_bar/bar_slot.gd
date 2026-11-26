class_name BarSlot
extends Button
## One slot of a [SlotBar]: a button with icon, counter, key hint and the remaining duration
## of an item effect.
##
## Shows only what its bar passes in; clicks arrive as [signal BaseButton.pressed].
## Size and the position of the parts are set in bar_slot.tscn, the look comes from the
## type variations in the HUD theme. So pixel art replaces the lines without code changes.

@export_group("Used up")
## Type variation of the slot when nothing is left, e.g. a faded icon. Defined in the HUD theme.
@export var used_up_variation: StringName = &"HotbarSlotUsedUp"
## Type variation of the counter when nothing is left, e.g. a red number.
@export var used_up_counter_variation: StringName = &"HotbarCounterUsedUp"

## Runs while an item effect from this slot lasts. null = none.
var _lifetime: Lifetime
## Type variations set in the scene, used while something is left.
var _variation: StringName
var _counter_variation: StringName

## ProgressBar or TextureProgressBar, both work.
@onready var _cooldown: Range = %Cooldown
@onready var _key_hint: Label = %KeyHint
@onready var _counter: Label = %Counter


func _ready() -> void:
	_variation = theme_type_variation
	_counter_variation = _counter.theme_type_variation
	_cooldown.visible = false
	set_process(false)


## Shows [param key] in the corner, e.g. "1" or "X". Empty = no hint.
func set_key_hint(key: String) -> void:
	_key_hint.text = key


## Shows [param item] with [param count_text] in the corner. item null = empty slot.
## [param used_up] = nothing left: slot and counter switch to their used-up type variations.
func show_item(item: ItemDefinition, count_text: String = "", used_up: bool = false) -> void:
	icon = item.icon if item != null else null
	tooltip_text = item.display_name if item != null else ""
	_counter.text = count_text
	theme_type_variation = used_up_variation if used_up else _variation
	_counter.theme_type_variation = used_up_counter_variation if used_up else _counter_variation


## Shows how much of [param lifetime] is left, as a fill that shrinks towards the bottom.
func start_cooldown(lifetime: Lifetime) -> void:
	_lifetime = lifetime
	_cooldown.visible = true
	set_process(true)
	_update_cooldown()


## Hides the fill, e.g. when the effect has ended.
func stop_cooldown() -> void:
	_lifetime = null
	_cooldown.visible = false
	set_process(false)


## Whether the fill of an item effect is shown.
func is_cooling_down() -> bool:
	return is_instance_valid(_lifetime)


func _process(_delta: float) -> void:
	_update_cooldown()


func _update_cooldown() -> void:
	if not is_instance_valid(_lifetime):
		stop_cooldown()
		return
	# Full at the start, empty at the end. ratio ignores min and max of the bar.
	_cooldown.ratio = 1.0 - _lifetime.progress()
