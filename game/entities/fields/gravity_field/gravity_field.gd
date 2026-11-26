class_name GravityField
extends BoidZone
## Gravity field: pulls boids in and lets them orbit if wanted.
##
## Behaviour inside [member radius]:
## [br]- orbit_ratio = 0, swirl = 0: pure attraction, boids clump together.
## [br]- orbit_ratio > 0, swirl > 0: boids gather on a ring (radius * orbit_ratio) and circle it.
## [br]The influence fades out softly towards the edge.
## [br][br]Optional child components:
## [br]- [Lifetime], linked in [member lifetime]: the field expires and frees itself.
## Without it the field is permanent.
## [br]- [DecayVisual]: the field fades and pulses while its lifetime runs out.
## [br][br]Subclasses override [method _compute_force] and [method _draw]. Fade-in and decay are
## applied in [method get_force_on], so every field type gets them automatically.

const MIN_RADIUS := 60.0
const MAX_RADIUS := 1400.0

## Size of the area of effect (px). Can be changed at runtime with the mouse and Q/E.
@export var radius: float = 300.0:
	set = set_radius
## Maximum acceleration (px/s²) the field applies to boids.
@export var strength: float = 900.0
## Radius of the orbit ring as a share of [member radius] (0 = pull to the centre).
@export_range(0.0, 0.9, 0.01) var orbit_ratio: float = 0.15
## 0 = attract only, 1 = mostly orbit.
@export_range(0.0, 1.0, 0.01) var swirl: float = 0.7
@export var clockwise: bool = true
## Whether the player may remove this field with a right click.
@export var removable: bool = true
@export var color: Color = Color(0.35, 0.7, 1.0)
## Opacity of the filled area (0 = outline only).
@export_range(0.0, 0.3, 0.005) var fill_alpha: float = 0.05
## Seconds the field needs to fade in after it was placed.
@export_range(0.0, 2.0, 0.05, "suffix:s") var fade_in_time: float = 0.25

@export_group("Lifetime")
## Child node that ends the field. Empty = the field is permanent.
@export var lifetime: Lifetime
## Strength over the lifetime: x = progress (0 to 1), y = factor (0 to 1).
## Keep the curve's default domain of 0 to 1. Empty = full strength until the end.
@export var strength_over_life: Curve
## Seconds over which the strength fades out right before the field expires.
@export_range(0.0, 2.0, 0.05, "suffix:s") var fade_out_time: float = 0.3

## Seconds since the field entered the scene.
var _age: float = 0.0
## Running time for animations in _draw().
var _time: float = 0.0


func _ready() -> void:
	super()
	if lifetime != null:
		lifetime.timeout.connect(queue_free)


func set_radius(value: float) -> void:
	radius = clampf(value, MIN_RADIUS, MAX_RADIUS)
	queue_redraw()


func contains_point(world_point: Vector2) -> bool:
	return global_position.distance_to(world_point) <= radius


func get_reach() -> float:
	return radius


func _process(delta: float) -> void:
	_age += delta
	_time += delta
	queue_redraw()


## Acceleration (px/s²) this field applies to [param boid], including fade-in and decay.
## Do not override; override [method _compute_force] instead.
func get_force_on(boid: Boid) -> Vector2:
	var factor := presence()
	if factor <= 0.0:
		return Vector2.ZERO
	return _compute_force(boid) * factor


## How strongly the field is present right now, 0 to 1: fade-in,
## [member strength_over_life] and the fade-out right before it expires.
func presence() -> float:
	var factor := spawn_alpha()
	if lifetime == null or lifetime.is_stopped():
		return factor
	if strength_over_life != null:
		factor *= clampf(strength_over_life.sample(lifetime.progress()), 0.0, 1.0)
	if fade_out_time > 0.0:
		factor *= clampf(lifetime.time_left / fade_out_time, 0.0, 1.0)
	return factor


## Opacity while the field fades in after it was placed, 0 to 1. Use it in [method _draw].
func spawn_alpha() -> float:
	if fade_in_time <= 0.0:
		return 1.0
	return clampf(_age / fade_in_time, 0.0, 1.0)


## Raw acceleration of this field type, before fade-in and decay. Override in subclasses.
func _compute_force(boid: Boid) -> Vector2:
	var offset := global_position - boid.global_position
	var dist := offset.length()
	if dist >= radius or dist < 0.001:
		return Vector2.ZERO

	# Soft edge: full strength up to 75 % of the radius, then fade out.
	var t := clampf((radius - dist) / (radius * 0.25), 0.0, 1.0)
	var falloff := t * t * (3.0 - 2.0 * t)

	var inward := offset / dist
	# Clockwise on screen (y points down) = inward.orthogonal()
	var tangent := inward.orthogonal() if clockwise else -inward.orthogonal()

	# Pull towards the ring (from inside outwards, from outside inwards).
	var ring := radius * orbit_ratio
	var radial_factor := clampf((dist - ring) / maxf(radius * 0.3, 1.0), -1.0, 1.0)
	# Only orbit close to the ring: far out the field pulls straight in, otherwise
	# the swarm would circle past the weak edge of the field.
	var near_ring := 1.0 - clampf((dist - ring) / maxf(radius * 0.4, 1.0), 0.0, 1.0)
	var s := swirl * near_ring

	var desired := (inward * radial_factor * (1.0 - s) + tangent * s).limit_length(1.0) \
			* boid.max_speed
	var accel := (desired - boid.velocity) * 3.0
	return accel.limit_length(strength) * falloff


func _draw() -> void:
	var px := screen_px()
	var a := spawn_alpha()
	draw_circle(Vector2.ZERO, radius, Color(color, fill_alpha * a))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, Color(color, 0.45 * a), 2.0 * px, true)

	# Rotating arcs on the orbit ring show the direction of rotation.
	var ring_r := maxf(radius * orbit_ratio, radius * 0.08)
	var dir := 1.0 if clockwise else -1.0
	var base := _time * 0.8 * dir
	for i in 3:
		var from := base + i * TAU / 3.0
		draw_arc(Vector2.ZERO, ring_r, from, from + 0.9, 24, Color(color, 0.75 * a), 3.0 * px, true)
	draw_circle(Vector2.ZERO, 5.0 * px, Color(color, a))
