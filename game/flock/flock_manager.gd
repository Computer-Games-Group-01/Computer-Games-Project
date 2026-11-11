class_name FlockManager
extends Node2D
## Simuliert alle Boids.
##
## Pro Frame:
##   1. Boids in ein Raster (Spatial Hash) einsortieren
##   2. für jeden Boid: Separation + Alignment + Cohesion aus den Nachbarn
##   3. + Weltgrenzen + alle "influencers" (Gravitationsfelder usw.)
##   4. alle Boids gemeinsam bewegen
##
## Der FlockManager bleibt bei Position (0,0) – Boid-Positionen sind Weltkoordinaten.

signal swarm_created(swarm: Swarm)
signal swarm_removed(swarm: Swarm)
signal boid_died(boid: Boid)

@export var settings: FlockSettings
@export var boid_scene: PackedScene
@export var swarm_colors: Array[Color] = [
	Color("4fc3f7"), Color("ffb74d"), Color("81c784"),
	Color("ba68c8"), Color("f06292"), Color("fff176"),
]

var world_rect: Rect2 = Rect2(0, 0, 6400, 3600)
var swarms: Array[Swarm] = []
var active_swarm: Swarm = null
var debug_draw: bool = false

var _all: Array[Boid] = []
var _grid: Dictionary = {}
var _dead: Array[Boid] = []
var _next_swarm_id: int = 1
var _frame: int = 0


func _ready() -> void:
	transform = Transform2D.IDENTITY
	if settings == null:
		settings = FlockSettings.new()


# --------------------------------------------------------------------------
# Schwärme erzeugen / verwalten
# --------------------------------------------------------------------------

func spawn_swarm(center: Vector2, count: int, spawn_radius: float) -> Swarm:
	var swarm := _create_swarm(swarm_colors[(_next_swarm_id - 1) % swarm_colors.size()])
	var heading := randf() * TAU
	for i in count:
		var boid: Boid = boid_scene.instantiate()
		add_child(boid)
		boid.position = center + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * spawn_radius
		boid.max_speed = settings.max_speed * randf_range(0.9, 1.1)
		boid.min_speed = settings.min_speed
		boid.velocity = Vector2.from_angle(heading + randf_range(-0.6, 0.6)) \
				* randf_range(boid.min_speed, boid.max_speed)
		boid.rotation = boid.velocity.angle()
		boid.died.connect(_on_boid_died)
		swarm.add(boid)
		_all.append(boid)
	if active_swarm == null:
		active_swarm = swarm
	return swarm


## Teilt einen Schwarm exakt in zwei Hälften entlang von `axis`.
## Rückgabe: [Hälfte auf der +axis-Seite (= der ursprüngliche Schwarm),
##            Hälfte auf der -axis-Seite (= neuer Schwarm)]. Leer, wenn zu klein.
func split_swarm(swarm: Swarm, axis: Vector2) -> Array[Swarm]:
	var result: Array[Swarm] = []
	if swarm.size() < 4:
		return result
	var center := swarm.centroid()
	var sorted: Array[Boid] = swarm.boids.duplicate()
	sorted.sort_custom(func(a: Boid, b: Boid) -> bool:
		return (a.position - center).dot(axis) < (b.position - center).dot(axis))

	var half := _create_swarm(_shift_hue(swarm.color, 0.12))
	@warning_ignore("integer_division")
	var half_count := sorted.size() / 2
	for i in half_count:
		half.add(sorted[i])  # die Boids der -axis-Seite wechseln in den neuen Schwarm
	result.append(swarm)
	result.append(half)
	return result


func merge_swarms(into: Swarm, other: Swarm) -> void:
	if into == other:
		return
	for boid in other.boids.duplicate():
		into.add(boid)
	_remove_swarm(other)


## Vereint alle Schwärme, deren Schwerpunkte näher als `max_distance` beieinander liegen.
## Rückgabe: Anzahl durchgeführter Vereinigungen.
func merge_nearby(max_distance: float) -> int:
	var merges := 0
	var changed := true
	while changed:
		changed = false
		for i in swarms.size():
			for j in range(i + 1, swarms.size()):
				if swarms[i].centroid().distance_to(swarms[j].centroid()) <= max_distance:
					merge_swarms(swarms[i], swarms[j])
					merges += 1
					changed = true
					break
			if changed:
				break
	return merges


func select_next_swarm() -> void:
	if swarms.is_empty():
		active_swarm = null
		return
	var i := swarms.find(active_swarm)
	active_swarm = swarms[(i + 1) % swarms.size()]


## Alle lebenden Boids im Kreis (für Ziele, Rätsel, Gegner-Treffer …).
func get_boids_in_circle(center: Vector2, radius: float) -> Array[Boid]:
	var found: Array[Boid] = []
	var cell_size := settings.perception_radius
	var min_c := Vector2i(floori((center.x - radius) / cell_size), floori((center.y - radius) / cell_size))
	var max_c := Vector2i(floori((center.x + radius) / cell_size), floori((center.y + radius) / cell_size))
	var r2 := radius * radius
	for cx in range(min_c.x, max_c.x + 1):
		for cy in range(min_c.y, max_c.y + 1):
			var bucket = _grid.get(Vector2i(cx, cy))
			if bucket == null:
				continue
			for b: Boid in bucket:
				if b.alive and b.position.distance_squared_to(center) <= r2:
					found.append(b)
	return found


func boid_count() -> int:
	return _all.size()


func _create_swarm(color: Color) -> Swarm:
	var swarm := Swarm.new()
	swarm.id = _next_swarm_id
	swarm.color = color
	_next_swarm_id += 1
	swarms.append(swarm)
	swarm_created.emit(swarm)
	return swarm


func _remove_swarm(swarm: Swarm) -> void:
	swarms.erase(swarm)
	if active_swarm == swarm:
		active_swarm = swarms[0] if not swarms.is_empty() else null
	swarm_removed.emit(swarm)


func _shift_hue(c: Color, amount: float) -> Color:
	return Color.from_hsv(fposmod(c.h + amount, 1.0), c.s, c.v)


func _on_boid_died(boid: Boid) -> void:
	_dead.append(boid)


# --------------------------------------------------------------------------
# Simulation
# --------------------------------------------------------------------------

func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	_purge_dead()
	_build_grid()
	var influencers := get_tree().get_nodes_in_group(&"influencers")

	_frame += 1
	var stride := maxi(settings.steering_stride, 1)
	for i in _all.size():
		if stride == 1 or (i + _frame) % stride == 0:
			_all[i].acceleration = _compute_acceleration(_all[i], influencers)
	for boid in _all:
		_integrate(boid, delta)

	queue_redraw()


func _purge_dead() -> void:
	if _dead.is_empty():
		return
	for boid in _dead:
		_all.erase(boid)
		var swarm := boid.swarm
		if swarm != null:
			swarm.boids.erase(boid)
			if swarm.is_empty():
				_remove_swarm(swarm)
		boid_died.emit(boid)
		boid.queue_free()
	_dead.clear()


func _build_grid() -> void:
	_grid.clear()
	var inv := 1.0 / settings.perception_radius
	for boid in _all:
		var key := Vector2i(floori(boid.position.x * inv), floori(boid.position.y * inv))
		var bucket = _grid.get(key)
		if bucket == null:
			bucket = []
			_grid[key] = bucket
		bucket.append(boid)


func _compute_acceleration(boid: Boid, influencers: Array[Node]) -> Vector2:
	var s := settings
	var pos := boid.position
	var cell := Vector2i(floori(pos.x / s.perception_radius), floori(pos.y / s.perception_radius))
	var perception2 := s.perception_radius * s.perception_radius
	var separation2 := s.separation_radius * s.separation_radius

	var separation_sum := Vector2.ZERO
	var alignment_sum := Vector2.ZERO
	var cohesion_sum := Vector2.ZERO
	var separation_n := 0
	var mates_n := 0

	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var bucket = _grid.get(Vector2i(cell.x + dx, cell.y + dy))
			if bucket == null:
				continue
			for other: Boid in bucket:
				if other == boid:
					continue
				var offset := other.position - pos
				var d2 := offset.length_squared()
				if d2 > perception2:
					continue
				# Separation: von ALLEN zu nahen Boids weg, stärker je näher.
				if d2 < separation2 and d2 > 0.0001:
					separation_sum -= offset / d2
					separation_n += 1
				# Alignment + Cohesion: nur mit dem eigenen Schwarm.
				if other.swarm == boid.swarm:
					alignment_sum += other.velocity
					cohesion_sum += other.position
					mates_n += 1

	var steer := Vector2.ZERO
	if separation_n > 0:
		steer += _steer_to(boid, separation_sum.normalized() * boid.max_speed) * s.separation_weight
	if mates_n > 0:
		steer += _steer_to(boid, (alignment_sum / mates_n).normalized() * boid.max_speed) * s.alignment_weight
		var to_center := cohesion_sum / mates_n - pos
		steer += _steer_to(boid, to_center.normalized() * boid.max_speed) * s.cohesion_weight

	var accel := (steer * s.steer_gain).limit_length(s.max_force)
	accel += _boundary_force(pos)

	# Felder, schwarze Löcher, Hindernisse, Gegner … (alles was Influencer ist)
	var external := Vector2.ZERO
	for node in influencers:
		var inf := node as Influencer
		if inf == null or not inf.affects(boid):
			continue
		var reach := inf.get_reach()
		if pos.distance_squared_to(inf.global_position) > reach * reach:
			continue
		external += inf.get_force_on(boid)
	accel += external.limit_length(s.max_external_force)
	return accel


func _steer_to(boid: Boid, desired_velocity: Vector2) -> Vector2:
	return desired_velocity - boid.velocity


func _boundary_force(pos: Vector2) -> Vector2:
	var m := settings.boundary_margin
	var r := world_rect
	var push := Vector2.ZERO
	if pos.x < r.position.x + m:
		push.x = (r.position.x + m - pos.x) / m
	elif pos.x > r.end.x - m:
		push.x = -(pos.x - (r.end.x - m)) / m
	if pos.y < r.position.y + m:
		push.y = (r.position.y + m - pos.y) / m
	elif pos.y > r.end.y - m:
		push.y = -(pos.y - (r.end.y - m)) / m
	return push * settings.boundary_force


func _integrate(boid: Boid, delta: float) -> void:
	var v := boid.velocity + boid.acceleration * delta
	var speed := v.length()
	if speed > boid.max_speed:
		v = v / speed * boid.max_speed
	elif speed < boid.min_speed:
		v = v / speed * boid.min_speed if speed > 0.001 else Vector2.from_angle(randf() * TAU) * boid.min_speed
	boid.velocity = v

	var p := boid.position + v * delta
	# harte Grenze als Sicherheitsnetz
	if p.x < world_rect.position.x or p.x > world_rect.end.x:
		boid.velocity.x = -boid.velocity.x
	if p.y < world_rect.position.y or p.y > world_rect.end.y:
		boid.velocity.y = -boid.velocity.y
	boid.position = p.clamp(world_rect.position, world_rect.end)
	boid.rotation = boid.velocity.angle()


# --------------------------------------------------------------------------
# Visualisierung (aktiver Schwarm, Debug-Overlay)
# --------------------------------------------------------------------------

func _draw() -> void:
	var px := 1.0 / maxf(get_canvas_transform().get_scale().x, 0.001)

	if active_swarm != null and not active_swarm.is_empty():
		var c := active_swarm.centroid()
		var ring_color := Color(active_swarm.color, 0.55)
		draw_arc(c, active_swarm.radius() + 45.0, 0.0, TAU, 64, ring_color, 2.5 * px, true)

	if not debug_draw:
		return

	var font := ThemeDB.fallback_font
	for swarm in swarms:
		if swarm.is_empty():
			continue
		var c := swarm.centroid()
		draw_circle(c, 6.0 * px, swarm.color)
		draw_string(font, c + Vector2(10, -10) * px, "#%d (%d)" % [swarm.id, swarm.size()],
				HORIZONTAL_ALIGNMENT_LEFT, -1, int(18.0 * px), swarm.color)
		var v := swarm.average_velocity()
		draw_line(c, c + v, swarm.color, 2.0 * px)

	# Wahrnehmungs- und Separationsradius eines Beispiel-Boids
	if active_swarm != null and not active_swarm.is_empty():
		var sample := active_swarm.boids[0]
		draw_arc(sample.position, settings.perception_radius, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 1.5 * px, true)
		draw_arc(sample.position, settings.separation_radius, 0.0, TAU, 32, Color(1, 0.4, 0.4, 0.5), 1.5 * px, true)
