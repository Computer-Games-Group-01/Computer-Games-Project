extends Node2D

@export var boid_scene: PackedScene
@export var total_boids: int = 80
@export var spawn_radius: float = 120.0

var boids: Array = []
var gravity_points: Array[Node2D] = []

func _ready() -> void:
	spawn_swarm()

func spawn_swarm() -> void:
	if not boid_scene:
		return
	for i in range(total_boids):
		var boid = boid_scene.instantiate()
		boid.global_position = global_position + Vector2(
			randf_range(-spawn_radius, spawn_radius), 
			randf_range(-spawn_radius, spawn_radius)
		)
		boid.manager = self
		boid.swarm_group = i % 2 
		get_tree().current_scene.call_deferred("add_child", boid)
		boids.append(boid)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			place_gravity_point(get_global_mouse_position(), 0)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			place_gravity_point(get_global_mouse_position(), 1)

func place_gravity_point(pos: Vector2, group_id: int) -> void:
	var existing = get_gravity_points_for_group(group_id)
	if not existing.is_empty():
		existing[0].global_position = pos
		return
		
	var marker = Node2D.new()
	marker.global_position = pos
	marker.set_meta("group_id", group_id)
	marker.set_meta("strength", 500.0)
	get_tree().current_scene.add_child(marker)
	gravity_points.append(marker)
	
	var vis = Polygon2D.new()
	vis.polygon = PackedVector2Array([Vector2(-5,-5), Vector2(5,-5), Vector2(5,5), Vector2(-5,5)])
	if group_id == 0:
		vis.color = Color(1, 0, 0, 0.5)
	else:
		vis.color = Color(0, 1, 0, 0.5)
	marker.add_child(vis)

func get_gravity_points_for_group(group_id: int) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for p in gravity_points:
		if is_instance_valid(p) and p.get_meta("group_id", 0) == group_id:
			result.append(p)
	return result

func _on_split_button_pressed() -> void:
	for i in range(boids.size()):
		boids[i].swarm_group = i % 2
