class_name CameraController
extends Camera2D
## Kamera für die große Welt: WASD = verschieben, Mausrad = Zoom (zum Mauszeiger hin).
## Nutzt die vorhandenen Input-Actions: hoch/links/runter/rechts, "zoom rein", "zoom raus".

@export var pan_speed: float = 1100.0   # Bildschirm-Pixel pro Sekunde
@export var zoom_step: float = 1.15
@export var min_zoom: float = 0.25
@export var max_zoom: float = 2.0

var _world_rect: Rect2 = Rect2(0, 0, 6400, 3600)


func set_world_rect(rect: Rect2) -> void:
	_world_rect = rect
	limit_left = int(rect.position.x)
	limit_top = int(rect.position.y)
	limit_right = int(rect.end.x)
	limit_bottom = int(rect.end.y)


## Kamera sanft auf einen Weltpunkt fahren.
func focus_on(world_pos: Vector2, duration: float = 0.4) -> void:
	var target := world_pos.clamp(_world_rect.position, _world_rect.end)
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	var dir := Input.get_vector("links", "rechts", "hoch", "runter")
	if dir != Vector2.ZERO:
		global_position += dir * pan_speed * delta / zoom.x
		global_position = global_position.clamp(_world_rect.position, _world_rect.end)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom rein"):
		_zoom_at_mouse(zoom_step)
	elif event.is_action_pressed("zoom raus"):
		_zoom_at_mouse(1.0 / zoom_step)


func _zoom_at_mouse(factor: float) -> void:
	var view := get_viewport_rect().size
	# Kleinster sinnvoller Zoom: Welt füllt den Bildschirm (man sieht nie "Außerhalb").
	var lowest := maxf(min_zoom, maxf(view.x / _world_rect.size.x, view.y / _world_rect.size.y))
	var new_zoom := clampf(zoom.x * factor, lowest, max_zoom)
	if is_equal_approx(new_zoom, zoom.x):
		return
	# Weltpunkt unter der Maus soll unter der Maus bleiben.
	var mouse_offset := get_viewport().get_mouse_position() - view * 0.5
	var world_under_mouse := get_screen_center_position() + mouse_offset / zoom.x
	zoom = Vector2(new_zoom, new_zoom)
	global_position = (world_under_mouse - mouse_offset / new_zoom).clamp(
			_world_rect.position, _world_rect.end)
