class_name Level
extends Node2D
## Basis-Level: verbindet Welt, Schwärme, Felder, Kamera und HUD.
## Neue Level = diese Szene duplizieren (oder erben) und Inhalte austauschen.
##
## Erwarteter Szenenaufbau:
##   FlockManager, Fields, Camera, FieldPlacer, Hud
##   SwarmSpawns  -> Kinder mit SwarmSpawn-Skript (Startpunkte)
##   Goals        -> Kinder mit GoalZone-Skript (Ziele)
##   Enemies      -> Kinder mit Enemy-Skript (Gegner, optional)

@export var world_rect: Rect2 = Rect2(0, 0, 6400, 3600)
@export var boids_per_swarm: int = 60
@export var spawn_radius: float = 160.0
## Anteil der Boids, der mindestens gerettet werden muss.
@export_range(0.1, 1.0, 0.05) var required_rescue_ratio: float = 0.5

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
var _total_boids: int = 0
var _rescued_boids: int = 0
var _level_finished: bool = false
var _required_reached: bool = false


func _ready() -> void:
	flock.world_rect = world_rect
	camera.set_world_rect(world_rect)

	# --- Start: Schwärme an den Spawn-Punkten erzeugen ---
	var spawns := $SwarmSpawns.get_children()
	for spawn in spawns:
		var spawn_node := spawn as Node2D
		if spawn_node == null:
			continue
		var r: float = spawn.radius if "radius" in spawn else spawn_radius
		var n: int = spawn.boid_count if "boid_count" in spawn and spawn.boid_count > 0 \
				else boids_per_swarm
		flock.spawn_swarm(spawn_node.global_position, n, r)
		_total_boids += n

	if not spawns.is_empty():
		camera.focus_on((spawns[0] as Node2D).global_position)

	# --- Ziele ---
	if has_node("Goals"):
		for node in $Goals.get_children():
			var goal := node as GoalZone
			if goal == null:
				push_warning("%s unter Goals hat kein GoalZone-Skript!" % node.name)
				continue
			goal.flock = flock
			goal.boids_rescued.connect(_on_boids_rescued)

	# --- Gegner (jeder Node mit einer "flock"-Variable bekommt den FlockManager) ---
	if has_node("Enemies"):
		for node in $Enemies.get_children():
			if "flock" in node:
				node.flock = flock

	hud.split_requested.connect(split_active_swarm)
	hud.merge_requested.connect(merge_nearby_swarms)
	hud.next_swarm_requested.connect(select_next_swarm)
	flock.swarm_fragmented.connect(_on_swarm_fragmented)
	flock.boid_died.connect(_on_boid_died)
	placer.field_type_changed.connect(hud.set_field_type)
	hud.set_field_type(placer.current_type_name())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.SWARM_SPLIT):
		split_active_swarm()
	elif event.is_action_pressed(InputActions.SWARM_MERGE):
		merge_nearby_swarms()
	elif event.is_action_pressed(InputActions.SWARM_NEXT):
		select_next_swarm()
	elif event.is_action_pressed(InputActions.DEBUG_OVERLAY):
		flock.debug_draw = not flock.debug_draw
	elif event.is_action_pressed(InputActions.ROUND_RESTART):
		get_tree().reload_current_scene()
	elif event.is_action_pressed(InputActions.ROUND_FINISH):
		finish_round()


func _process(delta: float) -> void:
	_info_timer -= delta
	if _info_timer <= 0.0:
		_info_timer = 0.2
		var active := flock.active_swarm
		var active_text := "–"
		if active != null:
			active_text = "#%d (%d Boids)" % [active.id, active.size()]
		hud.set_info("Schwärme: %d  ·  Boids: %d  ·  FPS: %d\nAktiver Schwarm: %s\nGerettet: %d / %d  (Ziel: %d)" % [
				flock.swarms.size(), flock.boid_count(), Engine.get_frames_per_second(), active_text,
				_rescued_boids, _total_boids, _required_boids()])


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


# --------------------------------------------------------------------------
# Rettung / Level-Ende
# --------------------------------------------------------------------------

func _required_boids() -> int:
	return ceili(_total_boids * required_rescue_ratio)


## Ein Ziel hat Boids gerettet (die GoalZone ruft dafür boid.kill() auf).
func _on_boids_rescued(amount: int) -> void:
	_rescued_boids += amount
	_check_level_state()


## Kommt vom FlockManager, NACHDEM der Boid aus der Liste entfernt wurde
## -> flock.boid_count() stimmt hier. Deckt auch Tode durch Gegner ab.
func _on_boid_died(_boid: Boid) -> void:
	_check_level_state()


func _check_level_state() -> void:
	if _level_finished:
		return

	var required := _required_boids()
	var remaining := flock.boid_count()

	if remaining == 0:
		_finish(_rescued_boids >= required)
		return

	if _rescued_boids >= required:
		if not _required_reached:
			_required_reached = true
			hud.flash("Mindestziel erreicht! Rette noch mehr oder beende die Runde (Enter).")
	elif _rescued_boids + remaining < required:
		# Das Mindestziel ist rechnerisch nicht mehr erreichbar.
		_finish(false)


## Runde vorzeitig beenden (Enter): Erfolg, wenn das Mindestziel erreicht ist.
func finish_round() -> void:
	if not _level_finished:
		_finish(_rescued_boids >= _required_boids())


func _finish(success: bool) -> void:
	_level_finished = true
	if success:
		hud.flash("Level geschafft! %d / %d Fische gerettet (R = Neustart)" % [_rescued_boids, _total_boids])
	else:
		hud.flash("Zu wenige Fische gerettet (%d / %d) – R = Neustart" % [_rescued_boids, _required_boids()])


# --------------------------------------------------------------------------
# Hintergrund + Weltgrenze (Raster hilft beim Orientieren in der großen Welt)
# --------------------------------------------------------------------------

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
