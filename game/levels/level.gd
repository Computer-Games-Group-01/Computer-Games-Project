class_name Level
extends Node2D
## Basis-Level: verbindet Welt, Schwärme, Felder, Kamera und HUD.
## Neue Level = diese Szene duplizieren (oder erben) und Inhalte austauschen.

@export var world_rect: Rect2 = Rect2(0, 0, 6400, 3600)
@export var boids_per_swarm: int = 60
@export var spawn_radius: float = 160.0

@export_group("Schwarm teilen")
@export var tear_scene: PackedScene
@export var tear_distance: float = 520.0
@export var tear_duration: float = 2.4
@export var tear_strength: float = 1500.0

@export_group("Schwärme vereinen")
@export var merge_distance: float = 700.0

@onready var flock: FlockManager = $FlockManager
@onready var fields: Node2D = $Fields
@onready var camera: CameraController = $Camera
@onready var placer: FieldPlacer = $FieldPlacer
@onready var hud: Hud = $Hud

var _info_timer: float = 0.0


func _ready() -> void:
	flock.world_rect = world_rect
	camera.set_world_rect(world_rect)

	for spawn in $SwarmSpawns.get_children():
		flock.spawn_swarm((spawn as Node2D).global_position, boids_per_swarm, spawn_radius)

	hud.split_requested.connect(split_active_swarm)
	hud.merge_requested.connect(merge_nearby_swarms)
	hud.next_swarm_requested.connect(select_next_swarm)
	flock.swarm_fragmented.connect(_on_swarm_fragmented)
	placer.field_type_changed.connect(hud.set_field_type)
	hud.set_field_type(placer.current_type_name())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Schwarm teilen"):
		split_active_swarm()
	elif event.is_action_pressed("Schwarm vereinen"):
		merge_nearby_swarms()
	elif event.is_action_pressed("Schwarm wechseln"):
		select_next_swarm()
	elif event.is_action_pressed("debug overlay"):
		flock.debug_draw = not flock.debug_draw


func _process(delta: float) -> void:
	_info_timer -= delta
	if _info_timer <= 0.0:
		_info_timer = 0.2
		var active := flock.active_swarm
		var active_text := "–"
		if active != null:
			active_text = "#%d (%d Boids)" % [active.id, active.size()]
		hud.set_info("Schwärme: %d  ·  Boids: %d  ·  FPS: %d\nAktiver Schwarm: %s" % [
				flock.swarms.size(), flock.boid_count(), Engine.get_frames_per_second(), active_text])


## Wählt den nächsten Schwarm aus und fährt die Kamera dorthin.
func select_next_swarm() -> void:
	flock.select_next_swarm()
	if flock.active_swarm != null:
		camera.focus_on(flock.active_swarm.centroid())


## Teilt den aktiven Schwarm in zwei Hälften. Zwei kurzlebige Gravitationsfelder
## auf gegenüberliegenden Seiten ziehen die Hälften auseinander.
func split_active_swarm() -> void:
	var swarm := flock.active_swarm
	if swarm == null or swarm.size() < 4:
		hud.flash("Schwarm ist zu klein zum Teilen")
		return

	var center := swarm.centroid()
	var spread := swarm.radius()
	var heading := swarm.average_velocity()
	# Schnitt quer zur Flugrichtung -> Hälften fliegen nach links/rechts auseinander.
	var axis := heading.orthogonal().normalized() if heading.length() > 5.0 \
			else Vector2.from_angle(randf() * TAU)

	var halves := flock.split_swarm(swarm, axis)
	if halves.size() < 2:
		return
	_spawn_tear_field(halves[0], center + axis * tear_distance, spread)
	_spawn_tear_field(halves[1], center - axis * tear_distance, spread)
	hud.flash("Schwarm #%d geteilt" % swarm.id)


func _on_swarm_fragmented(original: Swarm, new_swarms: Array[Swarm]) -> void:
	hud.flash("Schwarm #%d zerfallen in %d Teile" % [original.id, new_swarms.size() + 1])


func merge_nearby_swarms() -> void:
	var count := flock.merge_nearby(merge_distance)
	if count > 0:
		hud.flash("%d Schwarm/Schwärme vereint" % count)
	else:
		hud.flash("Kein Schwarm in Reichweite zum Vereinen")


func _spawn_tear_field(target: Swarm, pos: Vector2, spread: float) -> void:
	var field := tear_scene.instantiate() as GravityField
	fields.add_child(field)
	field.global_position = pos
	field.radius = tear_distance + spread + 250.0
	field.strength = tear_strength
	field.orbit_ratio = 0.0
	field.swirl = 0.0
	field.lifetime = tear_duration
	field.removable = false
	field.color = target.color
	field.fill_alpha = 0.02
	field.target_swarm = target  # wirkt nur auf "seine" Hälfte


# Hintergrund + Weltgrenze (Raster hilft beim Orientieren in der großen Welt)
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
