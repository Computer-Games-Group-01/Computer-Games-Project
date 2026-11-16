class_name Hud
extends CanvasLayer
## Anzeige + Buttons. Die HUD kennt die Spiellogik nicht – sie sendet nur Signale.

signal split_requested
signal merge_requested
signal next_swarm_requested

@onready var _info: Label = %InfoLabel
@onready var _field: Label = %FieldLabel
@onready var _message: Label = %MessageLabel

var _flash_tween: Tween


func _ready() -> void:
	%SplitButton.pressed.connect(func() -> void: split_requested.emit())
	%MergeButton.pressed.connect(func() -> void: merge_requested.emit())
	%NextButton.pressed.connect(func() -> void: next_swarm_requested.emit())
	_message.modulate.a = 0.0


func set_info(text: String) -> void:
	_info.text = text


func set_field_type(type_name: String) -> void:
	_field.text = "Feldtyp: %s  [F]" % type_name


## Kurze Meldung, die sich selbst ausblendet.
func flash(text: String) -> void:
	_message.text = text
	if _flash_tween != null:
		_flash_tween.kill()
	_message.modulate.a = 1.0
	_flash_tween = create_tween()
	_flash_tween.tween_interval(1.2)
	_flash_tween.tween_property(_message, "modulate:a", 0.0, 0.6)
