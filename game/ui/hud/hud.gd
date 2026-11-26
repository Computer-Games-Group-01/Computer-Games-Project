class_name Hud
extends Control
## Display and buttons. Does not know the game logic: listens to Events and emits its own signals.

signal split_requested
signal merge_requested
signal next_swarm_requested
## The player clicked ability slot [param index].
signal ability_pressed(index: int)

@onready var _info: Label = %InfoLabel
@onready var _field: Label = %FieldLabel
@onready var _message: Label = %MessageLabel

var _flash_tween: Tween
var _swarm_count: int = 0
var _boid_count: int = 0
var _active_text: String = "–"
var _result := RoundResult.new()
## Field type shown in the field line. null = no field types are configured.
var _shown_type: FieldType
## Fields left (x) and maximum (y) per type. x = -1: unlimited.
var _field_counts: Dictionary[FieldType, Vector2i] = {}


func _ready() -> void:
	%SplitButton.pressed.connect(func() -> void: split_requested.emit())
	%MergeButton.pressed.connect(func() -> void: merge_requested.emit())
	%NextButton.pressed.connect(func() -> void: next_swarm_requested.emit())
	%AbilityBar.slot_pressed.connect(ability_pressed.emit)
	_message.modulate.a = 0.0
	Events.swarm_stats_changed.connect(_on_swarm_stats_changed)
	Events.round_progress.connect(_on_round_progress)
	Events.field_type_changed.connect(set_field_type)
	Events.field_count_changed.connect(_on_field_count_changed)
	Events.message.connect(flash)
	Events.level_won.connect(_on_level_won)
	Events.level_lost.connect(_on_level_lost)


## Shows the selected field type and how many of it are left.
## null = no field types are configured.
func set_field_type(type: FieldType) -> void:
	_shown_type = type
	_update_field_line()


func _on_field_count_changed(type: FieldType, remaining: int, maximum: int) -> void:
	_field_counts[type] = Vector2i(remaining, maximum)
	if type == _shown_type:
		_update_field_line()


func _update_field_line() -> void:
	var type_name := _shown_type.display_name if _shown_type != null else "–"
	var count := Vector2i(-1, -1)
	if _shown_type != null:
		count = _field_counts.get(_shown_type, count)
	var left := "" if count.x < 0 else "  ·  %d / %d" % [count.x, count.y]
	_field.text = "Feldtyp: %s%s  [F]" % [type_name, left]


## Short message that fades out by itself.
func flash(text: String) -> void:
	_message.text = text
	if _flash_tween != null:
		_flash_tween.kill()
	_message.modulate.a = 1.0
	_flash_tween = create_tween()
	_flash_tween.tween_interval(1.2)
	_flash_tween.tween_property(_message, "modulate:a", 0.0, 0.6)


func _on_swarm_stats_changed(swarm_count: int, boid_count: int, active_text: String) -> void:
	_swarm_count = swarm_count
	_boid_count = boid_count
	_active_text = active_text
	_update_info()


func _on_round_progress(result: RoundResult) -> void:
	_result = result
	_update_info()


func _update_info() -> void:
	_info.text = "Schwärme: %d  ·  Boids: %d  ·  FPS: %d\nAktiver Schwarm: %s\nGerettet: %d / %d  (Ziel: %d)" % [
			_swarm_count, _boid_count, Engine.get_frames_per_second(), _active_text,
			_result.rescued, _result.total, _result.required]


func _on_level_won(result: RoundResult) -> void:
	flash("Level geschafft! %d / %d Fische gerettet (R = Neustart)" % [result.rescued, result.total])


func _on_level_lost(result: RoundResult) -> void:
	flash("Zu wenige Fische gerettet (%d / %d) – R = Neustart" % [result.rescued, result.required])
