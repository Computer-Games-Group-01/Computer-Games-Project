class_name World
extends Node2D
## Holds the current level and every system each level needs:
## BoidWorld, PlayerController, CameraRig and RoundRules.

@onready var level_slot: Node2D = %LevelSlot
@onready var player_fields: Node2D = %PlayerFields
@onready var boid_world: BoidWorld = %BoidWorld
@onready var player_controller: PlayerController = %PlayerController
@onready var camera: CameraRig = %CameraRig
@onready var round_rules: RoundRules = %RoundRules


## Adds a level, hands the simulation to all building blocks and starts the round.
func load_level(level: LevelRoot) -> void:
	level_slot.add_child(level)
	boid_world.world_rect = level.get_bounds()
	camera.set_bounds(level.get_bounds())
	get_tree().call_group(&"uses_boids", &"setup", boid_world)
	camera.focus_on(level.get_start_position())
	player_controller.reset(level.info.field_rules)
	round_rules.start(level.info)
	Events.level_started.emit(level.info)


## Removes the level, placed fields and all boids.
func unload_level() -> void:
	for level in level_slot.get_children():
		level_slot.remove_child(level)  # out of the tree and its groups right away (E50)
		level.queue_free()
	for field in player_fields.get_children():
		player_fields.remove_child(field)
		field.queue_free()
	boid_world.clear()
