class_name GravityField
extends Influencer
## Gravitationsfeld: zieht Boids an und lässt sie auf Wunsch umkreisen.
##
## Verhalten innerhalb von `radius`:
##   * orbit_ratio = 0, swirl = 0   -> reine Anziehung (Boids ballen sich zusammen)
##   * orbit_ratio > 0, swirl > 0   -> Boids sammeln sich auf einem Ring
##                                     (Radius = radius * orbit_ratio) und kreisen dort
## Der Einfluss blendet zum Rand hin weich aus.

const MIN_RADIUS := 60.0
const MAX_RADIUS := 1400.0

## Größe des Wirkbereichs (px). Zur Laufzeit per Maus/Q/E änderbar.
@export var radius: float = 300.0:
	set = set_radius
## Max. Beschleunigung (px/s²), mit der das Feld an Boids zieht.
@export var strength: float = 900.0
## Ringradius als Anteil von `radius`, auf dem Boids kreisen (0 = zum Zentrum).
@export_range(0.0, 0.9, 0.01) var orbit_ratio: float = 0.35
## 0 = nur anziehen, 1 = überwiegend kreisen.
@export_range(0.0, 1.0, 0.01) var swirl: float = 0.7
@export var clockwise: bool = true
## > 0: Feld verschwindet nach dieser Zeit (z. B. Zerreiß-Felder). 0 = dauerhaft.
@export var lifetime: float = 0.0
## Darf der Spieler dieses Feld per Rechtsklick entfernen?
@export var removable: bool = true
@export var color: Color = Color(0.35, 0.7, 1.0)
## Deckkraft der Flächenfüllung (0 = nur Umriss).
@export_range(0.0, 0.3, 0.005) var fill_alpha: float = 0.05

var _age: float = 0.0
var _time: float = 0.0
var _scale_factor: float = 1.0  # 0..1, für Ein-/Ausblenden temporärer Felder


func set_radius(value: float) -> void:
	radius = clampf(value, MIN_RADIUS, MAX_RADIUS)
	queue_redraw()


func contains_point(world_point: Vector2) -> bool:
	return global_position.distance_to(world_point) <= radius


func get_reach() -> float:
	return radius


func _process(delta: float) -> void:
	_time += delta
	if lifetime > 0.0:
		_age += delta
		if _age >= lifetime:
			queue_free()
			return
		_scale_factor = clampf(minf(_age / 0.25, (lifetime - _age) / 0.5), 0.0, 1.0)
	queue_redraw()


func get_force_on(boid: Boid) -> Vector2:
	var offset := global_position - boid.global_position
	var dist := offset.length()
	if dist >= radius or dist < 0.001:
		return Vector2.ZERO

	# Weicher Rand: volle Stärke bis 75 % des Radius, dann Ausblenden.
	var t := clampf((radius - dist) / (radius * 0.25), 0.0, 1.0)
	var falloff := t * t * (3.0 - 2.0 * t)

	var inward := offset / dist
	# Im Uhrzeigersinn (Bildschirm, y nach unten) = inward.orthogonal()
	var tangent := inward.orthogonal() if clockwise else -inward.orthogonal()

	# Zum Ring hin ziehen (von innen nach außen, von außen nach innen)
	var ring := radius * orbit_ratio
	var radial_factor := clampf((dist - ring) / maxf(radius * 0.3, 1.0), -1.0, 1.0)
	# Kreisen erst nahe am Ring: weit draußen zieht das Feld direkt hinein,
	# sonst würde der Schwarm am schwachen Feldrand "vorbeikreisen".
	var near_ring := 1.0 - clampf((dist - ring) / maxf(radius * 0.4, 1.0), 0.0, 1.0)
	var s := swirl * near_ring

	var desired := (inward * radial_factor * (1.0 - s) + tangent * s).limit_length(1.0) \
			* boid.max_speed
	var accel := (desired - boid.velocity) * 3.0
	return accel.limit_length(strength) * falloff * _scale_factor


func _draw() -> void:
	var px := screen_px()
	var a := _scale_factor
	draw_circle(Vector2.ZERO, radius, Color(color, fill_alpha * a))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, Color(color, 0.45 * a), 2.0 * px, true)

	# rotierende Bögen auf dem Orbit-Ring zeigen die Kreisrichtung
	var ring_r := maxf(radius * orbit_ratio, radius * 0.08)
	var dir := 1.0 if clockwise else -1.0
	var base := _time * 0.8 * dir
	for i in 3:
		var from := base + i * TAU / 3.0
		draw_arc(Vector2.ZERO, ring_r, from, from + 0.9, 24, Color(color, 0.75 * a), 3.0 * px, true)
	draw_circle(Vector2.ZERO, 5.0 * px, Color(color, a))
