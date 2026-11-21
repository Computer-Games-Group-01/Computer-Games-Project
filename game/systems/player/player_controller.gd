class_name PlayerController
extends Node2D
## All player input in the game world:
##   Left click            place a field (default size)
##   Left click + drag     place a field, size = distance to the click point
##   Right click           remove the field under the mouse cursor
##   Q / E                 shrink/grow the field under the cursor (otherwise the last one placed)
##   F                     switch field type
##   Space, M, Tab         split swarm, merge nearby swarms, select next swarm
##   F3                    BoidWorld debug overlay

## The simulation. Placed fields are registered here.
@export var boid_world: BoidWorld
## Moves to the new swarm when the swarm changes.
@export var camera: CameraRig
## Placed fields are added here.
@export var fields_root: Node2D

@export_group("Fields")
## Field types the player cycles through with F.
@export var field_types: Array[FieldType] = []
@export var default_radius: float = 280.0
@export var drag_threshold: float = 14.0
## Share per second while Q or E is held.
@export var resize_rate: float = 1.2

@export_group("Swarm split")
## Field that pulls the halves apart.
@export var tear_scene: PackedScene
@export var tear_distance: float = 520.0

@export_group("Swarm merge")
@export var merge_distance: float = 700.0

var _type_index: int = 0
var _dragging: GravityField = null
var _drag_origin: Vector2 = Vector2.ZERO
var _last_field: GravityField = null


func _ready() -> void:
	boid_world.swarm_fragmented.connect(_on_swarm_fragmented)


## Resets the input. World calls this when a level is loaded.
func reset() -> void:
	_type_index = 0
	_dragging = null
	_last_field = null
	Events.field_type_changed.emit(current_type_name())


func current_type_name() -> String:
	if _type_index < field_types.size():
		return field_types[_type_index].display_name
	return "Feld"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.FIELD_PLACE):
		_begin_place()
	elif event.is_action_released(InputActions.FIELD_PLACE):
		_dragging = null
	elif event is InputEventMouseMotion and _dragging != null:
		var d := get_global_mouse_position().distance_to(_drag_origin)
		if d > drag_threshold:
			_dragging.radius = d
	elif event.is_action_pressed(InputActions.FIELD_REMOVE):
		var f := _field_under_cursor()
		if f != null and f.removable:
			f.queue_free()
	elif event.is_action_pressed(InputActions.FIELD_TYPE_NEXT) and not field_types.is_empty():
		_type_index = (_type_index + 1) % field_types.size()
		Events.field_type_changed.emit(current_type_name())
	elif event.is_action_pressed(InputActions.SWARM_SPLIT):
		split_active_swarm()
	elif event.is_action_pressed(InputActions.SWARM_MERGE):
		merge_nearby_swarms()
	elif event.is_action_pressed(InputActions.SWARM_NEXT):
		select_next_swarm()
	elif event.is_action_pressed(InputActions.DEBUG_OVERLAY):
		boid_world.debug_draw = not boid_world.debug_draw


func _process(delta: float) -> void:
	var axis := Input.get_axis(InputActions.FIELD_SHRINK, InputActions.FIELD_GROW)
	if axis == 0.0:
		return
	var f := _field_under_cursor()
	if f == null and is_instance_valid(_last_field):
		f = _last_field
	if f != null:
		f.radius *= 1.0 + axis * resize_rate * delta


## Selects the next swarm and moves the camera there.
func select_next_swarm() -> void:
	boid_world.select_next_swarm()
	if boid_world.active_swarm != null:
		camera.focus_on(boid_world.active_swarm.centroid())


## Splits the active swarm into two halves. Two short-lived fields
## on opposite sides pull the halves apart.
func split_active_swarm() -> void:
	var swarm := boid_world.active_swarm
	if swarm == null or swarm.size() < 4:
		Events.message.emit("Schwarm ist zu klein zum Teilen")
		return
	var center := swarm.centroid()
	var spread := swarm.radius()
	var heading := swarm.average_velocity()
	# Cut across the direction of travel, so the halves fly apart sideways.
	var axis := heading.orthogonal().normalized() if heading.length() > 5.0 \
			else Vector2.from_angle(randf() * TAU)
	var halves := boid_world.split_swarm(swarm, axis)
	if halves.size() < 2:
		return
	_spawn_tear_field(halves[0], center + axis * tear_distance, spread)
	_spawn_tear_field(halves[1], center - axis * tear_distance, spread)
	Events.message.emit("Schwarm #%d geteilt" % swarm.id)


func merge_nearby_swarms() -> void:
	var count := boid_world.merge_nearby(merge_distance)
	if count > 0:
		Events.message.emit("%d Schwarm/Schwärme vereint" % count)
	else:
		Events.message.emit("Kein Schwarm in Reichweite zum Vereinen")


func _on_swarm_fragmented(original: Swarm, new_swarms: Array[Swarm]) -> void:
	Events.message.emit("Schwarm #%d zerfallen in %d Teile" % [original.id, new_swarms.size() + 1])


func _spawn_tear_field(target: Swarm, pos: Vector2, spread: float) -> void:
	var field := tear_scene.instantiate() as GravityField
	fields_root.add_child(field)
	field.global_position = pos
	field.radius = tear_distance + spread + 250.0
	field.color = target.color
	field.target_swarm = target  # affects only its own half
	field.setup(boid_world)


func _begin_place() -> void:
	if field_types.is_empty() or fields_root == null:
		return
	var field := field_types[_type_index].scene.instantiate() as GravityField
	fields_root.add_child(field)
	field.global_position = get_global_mouse_position()
	field.radius = default_radius
	field.setup(boid_world)
	_drag_origin = field.global_position
	_dragging = field
	_last_field = field


## The field whose area contains the mouse cursor (if several: the one with the nearest centre).
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
