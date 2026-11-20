@tool
class_name LevelRoot
extends Node2D
## Root of every level. A level only provides content and data;
## simulation, camera, rules and HUD come from World.

const MAIN_SCENE := "res://main/main.tscn"

## Level data: name, scene, minimum goal.
@export var info: LevelInfo
## Play area in world coordinates. Camera and boids stay inside it.
@export var world_rect: Rect2 = Rect2(0, 0, 6400, 3600):
	set(v):
		world_rect = v
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Started directly with F6: restart through Main so that World and HUD exist.
	if get_tree().current_scene == self:
		GameState.start_at(info)
		get_tree().change_scene_to_file.call_deferred(MAIN_SCENE)


func get_bounds() -> Rect2:
	return world_rect


## Position of the first spawn point, for the camera at level start.
func get_start_position() -> Vector2:
	var spawns := get_node_or_null(^"Spawns")
	if spawns != null and spawns.get_child_count() > 0:
		return (spawns.get_child(0) as Node2D).global_position
	return world_rect.get_center()


## Background and grid.
func _draw() -> void:
	draw_rect(world_rect, Color(0.05, 0.065, 0.12))
	var step := 400.0
	var grid_color := Color(1, 1, 1, 0.04)
	var x := world_rect.position.x + step
	while x < world_rect.end.x:
		draw_line(Vector2(x, world_rect.position.y), Vector2(x, world_rect.end.y), grid_color, 2.0)
		x += step
	var y := world_rect.position.y + step
	while y < world_rect.end.y:
		draw_line(Vector2(world_rect.position.x, y), Vector2(world_rect.end.x, y), grid_color, 2.0)
		y += step
	draw_rect(world_rect, Color(0.35, 0.45, 0.8, 0.7), false, 8.0)
