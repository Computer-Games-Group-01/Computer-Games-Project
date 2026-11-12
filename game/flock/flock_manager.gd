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

const CHUNK := 32  # so viele Boids bearbeitet ein Thread-Auftrag am Stück

var _all: Array[Boid] = []
var _dead: Array[Boid] = []
var _next_swarm_id: int = 1
var _frame: int = 0

# --- Simulationsdaten als Packed-Arrays (viel schneller als Node-Eigenschaften) ---
var _n: int = 0
var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _sid := PackedInt32Array()          # Schwarm-ID je Boid
var _acc := PackedVector2Array()        # Ergebnis der Schwarm-Regeln dieses Frames
var _boid_cell := PackedInt32Array()
var _swarm_center := PackedVector2Array()  # Schwerpunkt je Schwarm-Slot
# Raster per "Counting Sort": die Boids einer Zelle liegen hintereinander in _cell_items,
# und die Zellen einer Rasterzeile liegen direkt nebeneinander -> 3 Bereiche pro Boid.
var _cell_start := PackedInt32Array()
var _cell_items := PackedInt32Array()
var _cell_fill := PackedInt32Array()
var _cols: int = 1
var _rows: int = 1
var _inv_cell: float = 1.0
var _origin := Vector2.ZERO

# Parameter-Kopien (werden von Threads gelesen)
var _perc2: float = 0.0
var _sep_r: float = 1.0
var _sep2: float = 0.0
var _inv_sep: float = 1.0
var _sep_gain: float = 0.0
var _ali_gain: float = 0.0
var _coh_gain: float = 0.0
var _max_force: float = 0.0
var _stride: int = 1
var _bond_gain: float = 0.0
var _bond_r: float = 1.0


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
## Nutzt das Raster des letzten Frames, ist also höchstens einen Frame alt.
func get_boids_in_circle(center: Vector2, radius: float) -> Array[Boid]:
	var found: Array[Boid] = []
	if _n == 0:
		return found
	var x0 := clampi(floori((center.x - radius - _origin.x) * _inv_cell), 0, _cols - 1)
	var x1 := clampi(floori((center.x + radius - _origin.x) * _inv_cell), 0, _cols - 1)
	var y0 := clampi(floori((center.y - radius - _origin.y) * _inv_cell), 0, _rows - 1)
	var y1 := clampi(floori((center.y + radius - _origin.y) * _inv_cell), 0, _rows - 1)
	var r2 := radius * radius
	for cy in range(y0, y1 + 1):
		for k in range(_cell_start[cy * _cols + x0], _cell_start[cy * _cols + x1 + 1]):
			var j := _cell_items[k]
			if j < _all.size() and _pos[j].distance_squared_to(center) <= r2 and _all[j].alive:
				found.append(_all[j])
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
# Ablauf pro Frame:
#   1. Daten in Packed-Arrays kopieren + Raster bauen
#   2. Schwarm-Regeln (Separation/Alignment/Cohesion) für alle Boids – ggf. auf mehreren Threads
#   3. Pro Boid auf dem Hauptthread: Felder/Hindernisse/Gegner + Weltgrenze, bewegen, kollidieren

func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	_purge_dead()
	_frame += 1
	_build_arrays()
	_compute_flock_rules()
	_apply_forces_and_move(delta)
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


func _build_arrays() -> void:
	_n = _all.size()
	_pos.resize(_n)
	_vel.resize(_n)
	_sid.resize(_n)
	_acc.resize(_n)
	_boid_cell.resize(_n)
	_cell_items.resize(_n)

	var cell := settings.perception_radius
	_inv_cell = 1.0 / cell
	_origin = world_rect.position
	_cols = int(ceil(world_rect.size.x / cell)) + 1
	_rows = int(ceil(world_rect.size.y / cell)) + 1
	var cells := _cols * _rows
	if _cell_start.size() != cells + 1:
		_cell_start.resize(cells + 1)
		_cell_fill.resize(cells)
	_cell_start.fill(0)

	var slots := swarms.size()
	var center_sum := PackedVector2Array()
	var center_cnt := PackedInt32Array()
	center_sum.resize(slots)
	center_cnt.resize(slots)
	_swarm_center.resize(slots)
	for si in slots:
		swarms[si].slot = si

	for i in _n:
		var b := _all[i]
		var p := b.position
		var slot := b.swarm.slot
		_pos[i] = p
		_vel[i] = b.velocity
		_sid[i] = slot
		center_sum[slot] += p
		center_cnt[slot] += 1
		var cx := clampi(floori((p.x - _origin.x) * _inv_cell), 0, _cols - 1)
		var cy := clampi(floori((p.y - _origin.y) * _inv_cell), 0, _rows - 1)
		var c := cy * _cols + cx
		_boid_cell[i] = c
		_cell_start[c + 1] += 1
	for si in slots:
		if center_cnt[si] > 0:
			_swarm_center[si] = center_sum[si] / center_cnt[si]
	for c in cells:
		_cell_start[c + 1] += _cell_start[c]
		_cell_fill[c] = _cell_start[c]
	for i in _n:
		var c := _boid_cell[i]
		_cell_items[_cell_fill[c]] = i
		_cell_fill[c] += 1


func _compute_flock_rules() -> void:
	if _n == 0:
		return
	var s := settings
	_perc2 = s.perception_radius * s.perception_radius
	_sep_r = s.separation_radius
	_sep2 = _sep_r * _sep_r
	_inv_sep = 1.0 / _sep_r
	_sep_gain = s.separation_weight * s.max_force
	_ali_gain = s.alignment_weight * s.steer_gain
	_coh_gain = s.cohesion_weight * s.max_force / s.perception_radius
	_max_force = s.max_force
	_stride = maxi(s.steering_stride, 1)
	_bond_gain = s.swarm_bond_weight * s.max_force
	_bond_r = s.swarm_bond_radius

	var chunks := ceili(float(_n) / CHUNK)
	if s.use_threads and chunks > 1:
		var group := WorkerThreadPool.add_group_task(_compute_chunk, chunks, -1, true, "boid rules")
		WorkerThreadPool.wait_for_group_task_completion(group)
	else:
		for c in chunks:
			_compute_chunk(c)


## Läuft ggf. auf einem Worker-Thread: liest nur Arrays und schreibt nur _acc[i] des eigenen Boids.
func _compute_chunk(chunk: int) -> void:
	var first := chunk * CHUNK
	var last := mini(first + CHUNK, _n)
	for i in range(first, last):
		if _stride == 1 or (i + _frame) % _stride == 0:
			_acc[i] = _flock_rules(i)


func _flock_rules(i: int) -> Vector2:
	var pos := _pos
	var vel := _vel
	var sid := _sid
	var items := _cell_items
	var starts := _cell_start
	var p: Vector2 = pos[i]
	var my_sid: int = sid[i]
	var cell: int = _boid_cell[i]
	var cx: int = cell % _cols
	var cy: int = (cell - cx) / _cols
	var x0 := maxi(cx - 1, 0)
	var x1 := mini(cx + 1, _cols - 1)
	var y0 := maxi(cy - 1, 0)
	var y1 := mini(cy + 1, _rows - 1)

	var sep := Vector2.ZERO
	var ali := Vector2.ZERO
	var coh := Vector2.ZERO
	var mates := 0
	var perc2 := _perc2
	var sep2 := _sep2
	var inv_sep := _inv_sep

	for ny in range(y0, y1 + 1):
		var row := ny * _cols
		for k in range(starts[row + x0], starts[row + x1 + 1]):
			var j: int = items[k]
			if j == i:
				continue
			var off: Vector2 = pos[j] - p
			var d2 := off.length_squared()
			if d2 > perc2:
				continue
			# Separation (von ALLEN Boids): Gewicht wächst weich von 0 am Rand auf 1 bei Berührung.
			if d2 < sep2 and d2 > 0.0001:
				var d := sqrt(d2)
				sep -= off * ((1.0 - d * inv_sep) / d)
			# Alignment + Cohesion nur mit dem eigenen Schwarm.
			if sid[j] == my_sid:
				ali += vel[j]
				coh += pos[j]
				mates += 1

	var accel := sep * _sep_gain
	if mates > 0:
		var inv := 1.0 / mates
		accel += (ali * inv - vel[i]) * _ali_gain   # an mittlere Geschwindigkeit angleichen
		accel += (coh * inv - p) * _coh_gain        # Feder zum Schwerpunkt
	# Schwarm-Bindung: Ausreißer weit weg vom Schwerpunkt sanft zurückholen.
	var to_swarm: Vector2 = _swarm_center[my_sid] - p
	var dist2 := to_swarm.length_squared()
	if dist2 > _bond_r * _bond_r:
		var dist := sqrt(dist2)
		accel += to_swarm / dist * (_bond_gain * clampf((dist - _bond_r) / (_bond_r * 2.0), 0.0, 1.0))
	return accel.limit_length(_max_force)


func _apply_forces_and_move(delta: float) -> void:
	# Influencer einmal pro Frame einsammeln (Felder, schwarze Löcher, Hindernisse, Gegner …)
	var infs: Array[Influencer] = []
	var ipos := PackedVector2Array()
	var ireach2 := PackedFloat32Array()
	var solids: Array[int] = []
	for node in get_tree().get_nodes_in_group(&"influencers"):
		var inf := node as Influencer
		if inf == null or not inf.enabled:
			continue
		var reach := inf.get_reach()
		infs.append(inf)
		ipos.append(inf.global_position)
		ireach2.append(reach * reach)
		if inf.solid:
			solids.append(infs.size() - 1)

	var s := settings
	var turn_t := 1.0 - exp(-s.turn_smoothing * delta) if s.turn_smoothing > 0.0 else 1.0

	for i in _n:
		var boid := _all[i]
		if not boid.alive:
			continue
		if _stride == 1 or (i + _frame) % _stride == 0:
			boid.flock_accel = _acc[i]
		var pos := boid.position

		var external := Vector2.ZERO
		for k in infs.size():
			if pos.distance_squared_to(ipos[k]) > ireach2[k]:
				continue
			if infs[k].affects(boid):
				external += infs[k].get_force_on(boid)
		boid.acceleration = boid.flock_accel + _boundary_force(pos) \
				+ external.limit_length(s.max_external_force)

		# Bewegen
		var v := boid.velocity + boid.acceleration * delta
		var speed := v.length()
		if speed > boid.max_speed:
			v = v / speed * boid.max_speed
		elif speed < boid.min_speed:
			v = v / speed * boid.min_speed if speed > 0.001 \
					else Vector2.from_angle(randf() * TAU) * boid.min_speed
		boid.velocity = v

		var p := pos + v * delta
		# harte Weltgrenze als Sicherheitsnetz
		if p.x < world_rect.position.x or p.x > world_rect.end.x:
			boid.velocity.x = -boid.velocity.x
		if p.y < world_rect.position.y or p.y > world_rect.end.y:
			boid.velocity.y = -boid.velocity.y
		boid.position = p.clamp(world_rect.position, world_rect.end)

		# Harte Kollisionen (Hindernisse)
		for k in solids:
			if boid.position.distance_squared_to(ipos[k]) <= ireach2[k]:
				infs[k].constrain(boid)

		boid.rotation = lerp_angle(boid.rotation, boid.velocity.angle(), turn_t)


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
