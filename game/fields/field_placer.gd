class_name FieldPlacer
extends Node2D
## Mausbedienung für Felder:
##   Linksklick            Feld setzen (Standardgröße)
##   Linksklick + ziehen   Feld setzen, Größe = Abstand zum Klickpunkt
##   Rechtsklick           Feld unter dem Mauszeiger entfernen
##   Q / E                 Feld unter dem Mauszeiger (sonst das zuletzt gesetzte) verkleinern/vergrößern
##   F                     Feldtyp wechseln (Gravitation, Schwarzes Loch, …)

signal field_type_changed(type_name: String)

## Neue Feldtypen = einfach Szene + Name hier eintragen.
@export var field_scenes: Array[PackedScene] = []
@export var field_names: PackedStringArray = []
## Hierhin werden die Felder eingefügt.
@export var fields_root: Node2D
@export var default_radius: float = 280.0
@export var drag_threshold: float = 14.0
@export var resize_rate: float = 1.2  # Anteil pro Sekunde beim Halten von Q/E

var _type_index: int = 0
var _dragging: GravityField = null
var _drag_origin: Vector2 = Vector2.ZERO
var _last_field: GravityField = null


func current_type_name() -> String:
	if _type_index < field_names.size():
		return field_names[_type_index]
	return "Feld"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Feld setzen"):
		_begin_place()
	elif event.is_action_released("Feld setzen"):
		_dragging = null
	elif event is InputEventMouseMotion and _dragging != null:
		var d := get_global_mouse_position().distance_to(_drag_origin)
		if d > drag_threshold:
			_dragging.radius = d
	elif event.is_action_pressed("Feld entfernen"):
		var f := _field_under_cursor()
		if f != null and f.removable:
			f.queue_free()
	elif event.is_action_pressed("Feldtyp wechseln") and not field_scenes.is_empty():
		_type_index = (_type_index + 1) % field_scenes.size()
		field_type_changed.emit(current_type_name())


func _process(delta: float) -> void:
	var axis := Input.get_axis("Feld kleiner", "Feld größer")
	if axis == 0.0:
		return
	var f := _field_under_cursor()
	if f == null and is_instance_valid(_last_field):
		f = _last_field
	if f != null:
		f.radius *= 1.0 + axis * resize_rate * delta


func _begin_place() -> void:
	if field_scenes.is_empty() or fields_root == null:
		return
	var field := field_scenes[_type_index].instantiate() as GravityField
	fields_root.add_child(field)
	field.global_position = get_global_mouse_position()
	field.radius = default_radius
	_drag_origin = field.global_position
	_dragging = field
	_last_field = field


## Das Feld, in dessen Wirkbereich der Mauszeiger liegt (bei mehreren: das mit dem nächsten Zentrum).
func _field_under_cursor() -> GravityField:
	if fields_root == null:
		return null
	var mouse := get_global_mouse_position()
	var best: GravityField = null
	var best_d := INF
	for child in fields_root.get_children():
		var f := child as GravityField
		if f != null and f.contains_point(mouse):
			var d := f.global_position.distance_to(mouse)
			if d < best_d:
				best_d = d
				best = f
	return best
