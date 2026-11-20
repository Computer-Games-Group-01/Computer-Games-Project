class_name RoundRules
extends Node
## Counts rescued boids and decides between win and loss.
## Reports everything through Events; knows neither the HUD nor the level.

## The simulation, assigned in world.tscn.
@export var boid_world: BoidWorld

var _result := RoundResult.new()
var _required_reached := false


func _ready() -> void:
	Events.boids_rescued.connect(_on_boids_rescued)
	boid_world.boid_died.connect(_on_boid_died)


## Starts counting. World calls this after the spawn points have created their swarms.
func start(info: LevelInfo) -> void:
	_result = RoundResult.new()
	_result.total = boid_world.boid_count()
	_result.remaining = _result.total
	_result.required = ceili(_result.total * info.required_rescue_ratio)
	_required_reached = false
	Events.round_progress.emit(_result)


## Ends the round early: success if the minimum goal has been reached.
func finish_round() -> void:
	if not _result.finished:
		_finish(_result.rescued >= _result.required)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.ROUND_FINISH):
		finish_round()


func _on_boids_rescued(count: int) -> void:
	_result.rescued += count
	_check()


func _on_boid_died(_boid: Boid) -> void:
	_check()


func _check() -> void:
	if _result.finished:
		return
	_result.remaining = boid_world.boid_count()
	Events.round_progress.emit(_result)
	if _result.remaining == 0:
		_finish(_result.rescued >= _result.required)
	elif _result.rescued >= _result.required:
		if not _required_reached:
			_required_reached = true
			Events.message.emit("Mindestziel erreicht! Rette noch mehr oder beende die Runde (Enter).")
	elif _result.rescued + _result.remaining < _result.required:
		_finish(false)


func _finish(success: bool) -> void:
	_result.finished = true
	_result.success = success
	Events.round_progress.emit(_result)
	if success:
		Events.level_won.emit(_result)
	else:
		Events.level_lost.emit(_result)
