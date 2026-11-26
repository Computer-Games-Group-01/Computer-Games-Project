@tool
class_name RescueZone
extends BoidZone
## Goal: every boid inside the circle counts as rescued and disappears.
##
## An optional child [GravityField] named "GoalPull" pulls nearby boids in. It has no
## [Lifetime], so it is permanent, and it is not under PlayerFields, so the player can
## neither remove it nor does it count against the field limits.
## Configure it through the "Pull" settings of this node.

@export var radius: float = 240.0:
	set(v):
		radius = v
		queue_redraw()
@export var color: Color = Color("81c784")

@export_group("Pull")
## Off = the goal does not pull boids in.
@export var pull_enabled: bool = true
## Radius of the pull as a multiple of [member radius]. Must be greater than 1,
## otherwise it only reaches boids that are rescued anyway.
@export_range(1.0, 4.0, 0.05) var pull_radius_factor: float = 1.6
## Maximum acceleration (px/s²) of the pull.
@export var pull_strength: float = 400.0
## Whether the area of the pull is drawn.
@export var pull_visible: bool = true


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		_configure_pull()


func _process(_delta: float) -> void:
	if boids == null:
		return
	var caught := boids.query_circle(global_position, radius)
	if not caught.is_empty():
		boids.rescue(caught)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(color, 0.12))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(color, 0.8), 4.0, true)


## Applies the "Pull" settings to the GoalPull child.
func _configure_pull() -> void:
	var pull := get_node_or_null(^"GoalPull") as GravityField
	if pull == null:
		return
	pull.enabled = pull_enabled
	pull.visible = pull_enabled and pull_visible
	pull.radius = radius * pull_radius_factor
	pull.strength = pull_strength
